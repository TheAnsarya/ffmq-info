#!/usr/bin/env python3
"""
FFMQ Compression/Decompression Tools
Based on algorithms from https://github.com/TheAnsarya/logsmall

Implements:
1. ExpandSecondHalfWithZeros - 3bpp → 4bpp graphics
2. SimpleTailWindowCompression - LZ-style tilemap compression  
3. ExpandNibblesMasked - Palette index compression
"""

import sys
from typing import List, Tuple

class ExpandSecondHalfWithZeros:
	"""
	Used in FFMQ for graphics data.
	Writes 16 bytes, then next 8 bytes each followed by a zero.
	Used for 3bpp graphics to be displayed in 4bpp mode.
	Input must be in $18 byte chunks.
	
	Example:
	Input:  50 51 52 53 54 55 56 57 58 59 5a 5b 5c 5d 5e 5f 60 61 62 63 64 65 66 67
	Output: 50 51 52 53 54 55 56 57 58 59 5a 5b 5c 5d 5e 5f 60 00 61 00 62 00 63 00 64 00 65 00 66 00 67 00
	"""
	
	@staticmethod
	def decompress(source: bytes) -> bytes:
		"""Decompress 3bpp → 4bpp graphics data"""
		if len(source) % 0x18 != 0:
			raise ValueError(f"Source size ({len(source):04x}) must be in $18 byte chunks")
		
		output = bytearray()
		for i, byte in enumerate(source):
			output.append(byte)
			# Insert zero after every byte in second half of each $18 chunk
			if (i % 0x18) >= 0x10:
				output.append(0)
		
		return bytes(output)
	
	@staticmethod
	def compress(target: bytes) -> bytes:
		"""Compress 4bpp → 3bpp graphics data"""
		if len(target) % 0x20 != 0:
			raise ValueError(f"Target size ({len(target):04x}) must be in $20 byte chunks")
		
		output = bytearray()
		i = 0
		while i < len(target):
			output.append(target[i])
			i += 1
			# Skip the zero bytes in second half of each chunk
			if (i % 0x20) >= 0x11:  # After byte 16 in each 32-byte chunk
				zero = target[i]
				if zero != 0:
					raise ValueError(f"Byte at {i:04x} should be zero, got {zero:02x}")
				i += 1  # Skip the zero byte
		
		return bytes(output)


class SimpleTailWindowCompression:
	"""
	LZ-style compression with 256-byte sliding window.
	Used by FFMQ for tilemap and other data.
	
	Format:
	- Word: offset to start of data[] array
	- Command stream:
		- If 0: end decompression
		- Low nibble != 0: copy that many bytes from data[] to output[]
		- High nibble != 0: copy (high nibble + 2) bytes from output[] to output[]
		  Source address = current output address - byte#2 - 1
	- Data array
	"""
	
	@staticmethod
	def decompress(source: bytes, output_size: int = 0x2000) -> bytes:
		"""Decompress data"""
		if len(source) < 2:
			raise ValueError("Source too small")
		
		# Read data offset
		data_offset = source[0] | (source[1] << 8)
		cmd_pos = 2
		data_pos = data_offset + 2
		
		output = bytearray()
		
		while cmd_pos < len(source):
			command = source[cmd_pos]
			cmd_pos += 1
			
			if command == 0:
				break  # End of decompression
			
			# Low nibble: copy from data array
			if command & 0x0f:
				length = command & 0x0f
				for _ in range(length):
					if data_pos >= len(source):
						break
					output.append(source[data_pos])
					data_pos += 1
			
			# High nibble: copy from output (LZ back-reference)
			if command & 0xf0:
				length = ((command & 0xf0) >> 4) + 2
				if cmd_pos >= len(source):
					break
				offset = source[cmd_pos] + 1
				cmd_pos += 1
				
				src_addr = len(output) - offset
				if src_addr < 0:
					raise ValueError(f"Invalid back-reference: offset={offset}, output_len={len(output)}")
				
				for _ in range(length):
					output.append(output[src_addr])
					src_addr += 1
		
		return bytes(output)
	
	@staticmethod
	def compress(target: bytes) -> bytes:
		"""Compress data"""
		commands = bytearray()
		data = bytearray()
		copy_data = 0
		pos = 0
		
		while pos < len(target):
			# Try to find longest match in previous 256 bytes
			max_match_len = 0
			max_match_offset = 0
			window_start = max(0, pos - 256)
			
			for test_len in range(min(17, len(target) - pos), 2, -1):
				if pos + test_len > len(target):
					continue
				pattern = target[pos:pos + test_len]
				
				# Search backwards in window
				for search_pos in range(pos - 1, window_start - 1, -1):
					if target[search_pos:search_pos + test_len] == pattern:
						max_match_len = test_len
						max_match_offset = pos - search_pos - 1
						break
				
				if max_match_len > 0:
					break
			
			if max_match_len >= 3:
				# Found a match - emit copy command
				if copy_data > 0:
					commands.append(copy_data)
					copy_data = 0
				
				copy_output = max_match_len - 2
				commands.append((copy_output << 4) + copy_data)
				commands.append(max_match_offset)
				pos += max_match_len
			else:
				# No match - add to data stream
				if copy_data == 0xf:
					commands.append(copy_data)
					copy_data = 1
				else:
					copy_data += 1
				
				data.append(target[pos])
				pos += 1
		
		# Add final data count if any
		if copy_data > 0:
			commands.append(copy_data)
		
		# Add terminator
		commands.append(0)
		
		# Build output
		output = bytearray()
		data_offset = len(commands)
		output.append(data_offset & 0xff)
		output.append((data_offset >> 8) & 0xff)
		output.extend(commands)
		output.extend(data)
		
		return bytes(output)


class ExpandNibblesMasked:
	"""
	Used in FFMQ for palette indices.
	Splits each byte into two nibbles, masked with 0x07 (bottom three bits).
	"""
	
	@staticmethod
	def decompress(source: bytes) -> bytes:
		"""Decompress nibble data"""
		output = bytearray()
		for byte in source:
			output.append(byte & 0x07)  # Low nibble
			output.append((byte >> 4) & 0x07)  # High nibble
		return bytes(output)
	
	@staticmethod
	def compress(target: bytes) -> bytes:
		"""Compress nibble data"""
		if len(target) % 2 != 0:
			raise ValueError("Target must be even length")
		
		output = bytearray()
		for i in range(0, len(target), 2):
			low = target[i] & 0x07
			high = target[i + 1] & 0x07
			output.append(low | (high << 4))
		
		return bytes(output)


def hex_dump(data: bytes, width: int = 16) -> str:
	"""Create a hex dump of binary data"""
	lines = []
	for i in range(0, len(data), width):
		chunk = data[i:i+width]
		hex_part = ' '.join(f'{b:02x}' for b in chunk)
		ascii_part = ''.join(chr(b) if 32 <= b < 127 else '.' for b in chunk)
		lines.append(f'{i:08x}  {hex_part:<{width*3}}  {ascii_part}')
	return '\n'.join(lines)


def test_expand_second_half():
	"""Test ExpandSecondHalfWithZeros"""
	print("Testing ExpandSecondHalfWithZeros...")
	input_data = bytes(range(0x50, 0x68))  # 24 bytes (0x18)
	expected = bytes([
		0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57,
		0x58, 0x59, 0x5a, 0x5b, 0x5c, 0x5d, 0x5e, 0x5f,
		0x60, 0x00, 0x61, 0x00, 0x62, 0x00, 0x63, 0x00,
		0x64, 0x00, 0x65, 0x00, 0x66, 0x00, 0x67, 0x00
	])
	
	result = ExpandSecondHalfWithZeros.decompress(input_data)
	assert result == expected, f"Decompression failed!\nExpected: {expected.hex()}\nGot: {result.hex()}"
	
	compressed = ExpandSecondHalfWithZeros.compress(result)
	assert compressed == input_data, "Compression failed!"
	
	print("✅ ExpandSecondHalfWithZeros tests passed!")


def test_expand_nibbles():
	"""Test ExpandNibblesMasked"""
	print("Testing ExpandNibblesMasked...")
	input_data = bytes([0x21, 0x43, 0x65])  # (2,1), (4,3), (6,5)
	expected = bytes([0x01, 0x02, 0x03, 0x04, 0x05, 0x06])
	
	result = ExpandNibblesMasked.decompress(input_data)
	assert result == expected, f"Decompression failed!\nExpected: {expected.hex()}\nGot: {result.hex()}"
	
	compressed = ExpandNibblesMasked.compress(result)
	assert compressed == input_data, "Compression failed!"
	
	print("✅ ExpandNibblesMasked tests passed!")


if __name__ == '__main__':
	print("FFMQ Compression Tools")
	print("=" * 60)
	
	# Run tests
	test_expand_second_half()
	test_expand_nibbles()
	
	print("\nAll tests passed! ✅")
	print("\nUsage:")
	print("  from ffmq_compression import ExpandSecondHalfWithZeros, SimpleTailWindowCompression")
	print("  decompressed = ExpandSecondHalfWithZeros.decompress(compressed_data)")
