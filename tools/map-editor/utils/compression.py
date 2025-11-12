#!/usr/bin/env python3
"""
FFMQ Map Decompression/Compression Library

This module implements the compression algorithm used by Final Fantasy Mystic Quest
for storing map data in the ROM. FFMQ uses a custom RLE-based compression scheme
optimized for tilemap data.

Compression Format Analysis:
- Maps are stored compressed to save ROM space
- Decompression is done at runtime by the game
- Compression format is a variant of RLE (Run-Length Encoding)
- Optimized for patterns common in tile-based maps

Command Byte Format:
- Commands are 1-2 bytes
- High bit determines command type
- Various encoding schemes for efficiency
"""

from typing import List, Tuple
import struct


class FFMQCompression:
	"""Handles FFMQ map compression and decompression"""
	
	# Command types (based on high bits)
	CMD_LITERAL = 0x00	  # Copy literal bytes
	CMD_RLE = 0x80		  # Run-length encoding
	CMD_PATTERN = 0xC0	  # Repeating pattern
	
	@staticmethod
	def decompress_map(compressed_data: bytes) -> bytes:
		"""
		Decompress FFMQ map data
		
		The compression algorithm uses multiple encoding schemes:
		
		1. Literal Copy (00-7F):
		   Command byte N means copy next N+1 bytes literally
		   Example: 0x05 [data] = copy 6 bytes
		
		2. RLE - Single Byte (80-BF):
		   Command byte 0x80-0xBF followed by 1 byte
		   Repeat that byte (command & 0x3F) + 1 times
		   Example: 0x83 0x42 = repeat 0x42 four times
		
		3. RLE - Word (C0-CF):
		   Command byte 0xC0-0xCF followed by 2 bytes
		   Repeat those 2 bytes (command & 0x0F) + 1 times
		   Example: 0xC2 0x12 0x34 = repeat 0x1234 three times
		
		4. Extended RLE (D0-DF):
		   Command byte 0xD0-0xDF followed by 1 byte for count, 1 byte for value
		   Repeat value (count + 1) times
		   Example: 0xD0 0x0F 0x42 = repeat 0x42 sixteen times
		
		5. Back Reference (E0-FF):
		   Command byte 0xE0-0xFF followed by 1 byte for offset
		   Copy data from previous position
		   Distance = (command & 0x1F) + 1
		   Length determined by high bits
		
		Args:
			compressed_data: Compressed map data
		
		Returns:
			Decompressed byte array
		"""
		if not compressed_data:
			return bytes()
		
		result = bytearray()
		pos = 0
		
		while pos < len(compressed_data):
			cmd = compressed_data[pos]
			pos += 1
			
			# Check for end marker
			if cmd == 0xFF and pos >= len(compressed_data):
				break
			
			# Literal copy (0x00-0x7F)
			if cmd < 0x80:
				count = cmd + 1
				if pos + count > len(compressed_data):
					# Truncated data
					count = len(compressed_data) - pos
				result.extend(compressed_data[pos:pos + count])
				pos += count
			
			# RLE - Single byte (0x80-0xBF)
			elif cmd < 0xC0:
				count = (cmd & 0x3F) + 1
				if pos < len(compressed_data):
					value = compressed_data[pos]
					pos += 1
					result.extend([value] * count)
			
			# RLE - Word (0xC0-0xCF)
			elif cmd < 0xD0:
				count = (cmd & 0x0F) + 1
				if pos + 1 < len(compressed_data):
					word = compressed_data[pos:pos + 2]
					pos += 2
					for _ in range(count):
						result.extend(word)
			
			# Extended RLE (0xD0-0xDF)
			elif cmd < 0xE0:
				if pos + 1 < len(compressed_data):
					count = compressed_data[pos] + 1
					value = compressed_data[pos + 1]
					pos += 2
					result.extend([value] * count)
			
			# Back reference (0xE0-0xFF)
			else:
				if pos < len(compressed_data):
					offset_byte = compressed_data[pos]
					pos += 1
					
					# Calculate distance and length
					distance = ((cmd & 0x0F) << 8) | offset_byte
					length = ((cmd >> 4) & 0x01) + 2  # 2 or 3 bytes
					
					# Copy from earlier in the output
					if distance <= len(result):
						start_pos = len(result) - distance
						for i in range(length):
							if start_pos + i < len(result):
								result.append(result[start_pos + i])
		
		return bytes(result)
	
	@staticmethod
	def compress_map(data: bytes) -> bytes:
		"""
		Compress map data using FFMQ compression
		
		This uses a multi-pass approach to find the best compression:
		1. Identify runs of identical bytes (RLE)
		2. Identify repeating word patterns
		3. Identify back-references to earlier data
		4. Fill remaining gaps with literal copies
		
		Args:
			data: Uncompressed map data
		
		Returns:
			Compressed byte array
		"""
		if not data:
			return bytes()
		
		result = bytearray()
		pos = 0
		
		while pos < len(data):
			# Try to find the best compression method for current position
			best_method = None
			best_savings = 0
			
			# Method 1: Check for RLE (repeated bytes)
			if pos + 1 < len(data):
				run_length = 1
				while (pos + run_length < len(data) and 
					   data[pos + run_length] == data[pos] and 
					   run_length < 64):
					run_length += 1
				
				if run_length >= 3:  # RLE worth it for 3+ bytes
					savings = run_length - 2  # Cost: 2 bytes (cmd + value)
					if savings > best_savings:
						best_savings = savings
						best_method = ('rle', run_length, data[pos])
			
			# Method 2: Check for word RLE (repeated 2-byte patterns)
			if pos + 3 < len(data):
				word = data[pos:pos + 2]
				word_run = 1
				check_pos = pos + 2
				while (check_pos + 1 < len(data) and 
					   data[check_pos:check_pos + 2] == word and 
					   word_run < 16):
					word_run += 1
					check_pos += 2
				
				if word_run >= 2:  # Word RLE worth it for 2+ repetitions
					savings = (word_run * 2) - 3  # Cost: 3 bytes (cmd + word)
					if savings > best_savings:
						best_savings = savings
						best_method = ('word_rle', word_run, word)
			
			# Method 3: Check for back references
			if pos >= 1 and len(result) > 0:
				# Search for matching sequences in earlier output
				max_distance = min(0xFFF, pos)  # 12-bit distance
				best_match_len = 0
				best_match_dist = 0
				
				for dist in range(1, max_distance + 1):
					if dist > pos:
						break
					
					match_len = 0
					while (pos + match_len < len(data) and 
						   match_len < 3 and  # Max 3 bytes for this format
						   data[pos + match_len] == data[pos - dist + match_len]):
						match_len += 1
					
					if match_len >= 2 and match_len > best_match_len:
						best_match_len = match_len
						best_match_dist = dist
				
				if best_match_len >= 2:
					savings = best_match_len - 2  # Cost: 2 bytes (cmd + offset)
					if savings > best_savings:
						best_savings = savings
						best_method = ('backref', best_match_len, best_match_dist)
			
			# Apply best method or use literal
			if best_method:
				method_type = best_method[0]
				
				if method_type == 'rle':
					run_length = best_method[1]
					value = best_method[2]
					
					if run_length <= 64:
						# Standard RLE
						result.append(0x80 | (run_length - 1))
						result.append(value)
						pos += run_length
					else:
						# Extended RLE
						result.append(0xD0)
						result.append(run_length - 1)
						result.append(value)
						pos += run_length
				
				elif method_type == 'word_rle':
					word_run = best_method[1]
					word = best_method[2]
					result.append(0xC0 | (word_run - 1))
					result.extend(word)
					pos += word_run * 2
				
				elif method_type == 'backref':
					match_len = best_method[1]
					dist = best_method[2]
					
					# Encode back reference
					cmd = 0xE0 | ((dist >> 8) & 0x0F)
					if match_len == 3:
						cmd |= 0x10
					result.append(cmd)
					result.append(dist & 0xFF)
					pos += match_len
			
			else:
				# No good compression found, use literal
				# Collect consecutive literals
				literal_start = pos
				literal_len = 1
				
				# Look ahead to find literal run
				while (literal_len < 128 and 
					   pos + literal_len < len(data)):
					# Check if next position would benefit from compression
					check_pos = pos + literal_len
					
					# Simple check: if next 3 bytes are identical, stop literal
					if (check_pos + 2 < len(data) and 
						data[check_pos] == data[check_pos + 1] == data[check_pos + 2]):
						break
					
					literal_len += 1
				
				# Write literal command
				result.append(literal_len - 1)
				result.extend(data[pos:pos + literal_len])
				pos += literal_len
		
		# Add end marker
		result.append(0xFF)
		
		return bytes(result)
	
	@staticmethod
	def decompress_layer(compressed_data: bytes, 
						expected_size: int) -> bytes:
		"""
		Decompress a map layer with size validation
		
		Args:
			compressed_data: Compressed layer data
			expected_size: Expected decompressed size in bytes
		
		Returns:
			Decompressed data, padded/truncated to expected_size
		"""
		decompressed = FFMQCompression.decompress_map(compressed_data)
		
		if len(decompressed) < expected_size:
			# Pad with zeros
			decompressed = decompressed + bytes(expected_size - len(decompressed))
		elif len(decompressed) > expected_size:
			# Truncate
			decompressed = decompressed[:expected_size]
		
		return decompressed
	
	@staticmethod
	def get_compression_ratio(original: bytes, compressed: bytes) -> float:
		"""Calculate compression ratio"""
		if len(original) == 0:
			return 0.0
		return len(compressed) / len(original)
	
	@staticmethod
	def validate_compression(original: bytes) -> bool:
		"""
		Validate that compression/decompression is lossless
		
		Args:
			original: Original data
		
		Returns:
			True if round-trip compression works correctly
		"""
		try:
			compressed = FFMQCompression.compress_map(original)
			decompressed = FFMQCompression.decompress_map(compressed)
			return decompressed == original
		except Exception:
			return False


def test_compression():
	"""Test compression/decompression with sample data"""
	
	# Test 1: Simple RLE
	test1 = bytes([0x42] * 10)
	compressed1 = FFMQCompression.compress_map(test1)
	decompressed1 = FFMQCompression.decompress_map(compressed1)
	print(f"Test 1 (RLE): {len(test1)} -> {len(compressed1)} bytes")
	print(f"  Valid: {decompressed1 == test1}")
	
	# Test 2: Word pattern
	test2 = bytes([0x12, 0x34] * 8)
	compressed2 = FFMQCompression.compress_map(test2)
	decompressed2 = FFMQCompression.decompress_map(compressed2)
	print(f"Test 2 (Word RLE): {len(test2)} -> {len(compressed2)} bytes")
	print(f"  Valid: {decompressed2 == test2}")
	
	# Test 3: Mixed data
	test3 = bytes([i % 256 for i in range(100)])
	compressed3 = FFMQCompression.compress_map(test3)
	decompressed3 = FFMQCompression.decompress_map(compressed3)
	print(f"Test 3 (Mixed): {len(test3)} -> {len(compressed3)} bytes")
	print(f"  Valid: {decompressed3 == test3}")
	
	# Test 4: Repeating pattern (map-like data)
	test4 = bytearray()
	for _ in range(10):
		test4.extend([0x01, 0x02, 0x03, 0x04])
	test4 = bytes(test4)
	compressed4 = FFMQCompression.compress_map(test4)
	decompressed4 = FFMQCompression.decompress_map(compressed4)
	print(f"Test 4 (Pattern): {len(test4)} -> {len(compressed4)} bytes")
	print(f"  Valid: {decompressed4 == test4}")
	
	print("\nCompression Summary:")
	print(f"  Algorithm: FFMQ RLE-based compression")
	print(f"  Methods: Literal, RLE, Word RLE, Back Reference")
	print(f"  Average ratio: {(len(compressed1) + len(compressed2) + len(compressed3) + len(compressed4)) / (len(test1) + len(test2) + len(test3) + len(test4)):.2%}")


if __name__ == '__main__':
	test_compression()
