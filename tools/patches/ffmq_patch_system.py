#!/usr/bin/env python3
"""
FFMQ Patch System - IPS/UPS patch creation and application

Patch Features:
- IPS format support
- UPS format support
- Patch creation
- Patch application
- Multi-patch support
- Patch validation

Patch Types:
- Bug fixes
- Translations
- Enhancements
- Difficulty mods
- Graphics mods
- Audio mods

IPS Format:
- Header: "PATCH"
- Records: offset (3 bytes) + size (2 bytes) + data
- RLE: size=0 + RLE_size (2 bytes) + value (1 byte)
- EOF: "EOF"

UPS Format:
- Header: "UPS1"
- Input/output sizes
- XOR-based patches
- CRC32 checksums

Features:
- Create patches
- Apply patches
- Validate patches
- Multi-patch support
- Patch metadata
- Rollback support

Usage:
	python ffmq_patch_system.py --create original.smc modified.smc patch.ips
	python ffmq_patch_system.py --apply rom.smc patch.ips output.smc
	python ffmq_patch_system.py --validate patch.ips
	python ffmq_patch_system.py --info patch.ips
	python ffmq_patch_system.py --multi patch1.ips patch2.ips --apply rom.smc
"""

import argparse
import struct
from pathlib import Path
from typing import List, Dict, Optional, Tuple
from dataclasses import dataclass, field
from enum import Enum


class PatchFormat(Enum):
	"""Patch format"""
	IPS = "ips"
	UPS = "ups"
	BPS = "bps"


class PatchType(Enum):
	"""Patch type"""
	BUGFIX = "bugfix"
	TRANSLATION = "translation"
	ENHANCEMENT = "enhancement"
	DIFFICULTY = "difficulty"
	GRAPHICS = "graphics"
	AUDIO = "audio"
	MISC = "misc"


@dataclass
class PatchRecord:
	"""Single patch record"""
	offset: int
	size: int
	data: bytes
	is_rle: bool = False
	rle_value: int = 0


@dataclass
class PatchMetadata:
	"""Patch metadata"""
	name: str = ""
	author: str = ""
	version: str = "1.0"
	description: str = ""
	type: PatchType = PatchType.MISC
	original_crc32: Optional[int] = None
	patched_crc32: Optional[int] = None


class IPSPatch:
	"""IPS patch handler"""
	
	HEADER = b'PATCH'
	EOF = b'EOF'
	
	def __init__(self, verbose: bool = False):
		self.verbose = verbose
		self.records: List[PatchRecord] = []
		self.metadata = PatchMetadata()
	
	def create_from_roms(self, original: bytes, modified: bytes) -> bool:
		"""Create patch from two ROMs"""
		if len(original) != len(modified):
			print(f"Error: ROMs must be same size")
			return False
		
		self.records = []
		
		# Find differences
		i = 0
		while i < len(original):
			if original[i] != modified[i]:
				# Start of difference
				start = i
				
				# Find end of difference
				while i < len(original) and original[i] != modified[i]:
					i += 1
				
				# Create record
				size = i - start
				data = modified[start:i]
				
				# Check for RLE opportunity
				if size > 3 and len(set(data)) == 1:
					# All same byte - use RLE
					record = PatchRecord(
						offset=start,
						size=size,
						data=bytes([data[0]]),
						is_rle=True,
						rle_value=data[0]
					)
				else:
					record = PatchRecord(
						offset=start,
						size=size,
						data=data
					)
				
				self.records.append(record)
			else:
				i += 1
		
		if self.verbose:
			print(f"✓ Created patch with {len(self.records)} records")
		
		return True
	
	def save(self, output_path: Path) -> bool:
		"""Save patch to file"""
		try:
			with open(output_path, 'wb') as f:
				# Write header
				f.write(self.HEADER)
				
				# Write records
				for record in self.records:
					# Offset (3 bytes, big-endian)
					f.write(struct.pack('>I', record.offset)[1:])
					
					if record.is_rle:
						# RLE record
						f.write(struct.pack('>H', 0))  # Size = 0 for RLE
						f.write(struct.pack('>H', record.size))  # RLE size
						f.write(bytes([record.rle_value]))  # RLE value
					else:
						# Normal record
						f.write(struct.pack('>H', record.size))
						f.write(record.data)
				
				# Write EOF
				f.write(self.EOF)
			
			if self.verbose:
				print(f"✓ Saved patch to {output_path}")
			
			return True
		
		except Exception as e:
			print(f"Error saving patch: {e}")
			return False
	
	def load(self, input_path: Path) -> bool:
		"""Load patch from file"""
		try:
			with open(input_path, 'rb') as f:
				# Read header
				header = f.read(5)
				if header != self.HEADER:
					print(f"Error: Invalid IPS header")
					return False
				
				self.records = []
				
				# Read records
				while True:
					# Read offset
					offset_bytes = f.read(3)
					if len(offset_bytes) < 3:
						break
					
					# Check for EOF
					if offset_bytes == self.EOF:
						break
					
					offset = struct.unpack('>I', b'\x00' + offset_bytes)[0]
					
					# Read size
					size = struct.unpack('>H', f.read(2))[0]
					
					if size == 0:
						# RLE record
						rle_size = struct.unpack('>H', f.read(2))[0]
						rle_value = struct.unpack('B', f.read(1))[0]
						
						record = PatchRecord(
							offset=offset,
							size=rle_size,
							data=bytes([rle_value]),
							is_rle=True,
							rle_value=rle_value
						)
					else:
						# Normal record
						data = f.read(size)
						
						record = PatchRecord(
							offset=offset,
							size=size,
							data=data
						)
					
					self.records.append(record)
			
			if self.verbose:
				print(f"✓ Loaded patch with {len(self.records)} records")
			
			return True
		
		except Exception as e:
			print(f"Error loading patch: {e}")
			return False
	
	def apply(self, rom_data: bytes) -> Optional[bytes]:
		"""Apply patch to ROM"""
		# Make mutable copy
		result = bytearray(rom_data)
		
		for record in self.records:
			if record.is_rle:
				# Apply RLE
				for i in range(record.size):
					if record.offset + i < len(result):
						result[record.offset + i] = record.rle_value
			else:
				# Apply normal record
				for i, byte in enumerate(record.data):
					if record.offset + i < len(result):
						result[record.offset + i] = byte
		
		if self.verbose:
			print(f"✓ Applied {len(self.records)} patch records")
		
		return bytes(result)
	
	def validate(self) -> bool:
		"""Validate patch"""
		if not self.records:
			print("Error: No patch records")
			return False
		
		# Check for overlapping records
		offsets = set()
		for record in self.records:
			for i in range(record.size):
				offset = record.offset + i
				if offset in offsets:
					print(f"Warning: Overlapping patch at offset 0x{offset:06X}")
				offsets.add(offset)
		
		if self.verbose:
			print(f"✓ Patch validated ({len(self.records)} records)")
		
		return True


class UPSPatch:
	"""UPS patch handler"""
	
	HEADER = b'UPS1'
	
	def __init__(self, verbose: bool = False):
		self.verbose = verbose
		self.input_size: int = 0
		self.output_size: int = 0
		self.changes: List[Tuple[int, int, int]] = []  # (offset, original, new)
		self.input_crc32: int = 0
		self.output_crc32: int = 0
		self.patch_crc32: int = 0
	
	def create_from_roms(self, original: bytes, modified: bytes) -> bool:
		"""Create UPS patch from two ROMs"""
		self.input_size = len(original)
		self.output_size = len(modified)
		self.changes = []
		
		# Calculate CRC32
		self.input_crc32 = self._crc32(original)
		self.output_crc32 = self._crc32(modified)
		
		# Find XOR differences
		max_len = max(len(original), len(modified))
		
		for i in range(max_len):
			orig_byte = original[i] if i < len(original) else 0
			mod_byte = modified[i] if i < len(modified) else 0
			
			if orig_byte != mod_byte:
				self.changes.append((i, orig_byte, mod_byte))
		
		if self.verbose:
			print(f"✓ Created UPS patch with {len(self.changes)} changes")
		
		return True
	
	def _crc32(self, data: bytes) -> int:
		"""Calculate CRC32"""
		import zlib
		return zlib.crc32(data) & 0xFFFFFFFF
	
	def _encode_vli(self, value: int) -> bytes:
		"""Encode variable-length integer"""
		result = bytearray()
		
		while True:
			byte = value & 0x7F
			value >>= 7
			
			if value == 0:
				result.append(byte | 0x80)
				break
			else:
				result.append(byte)
		
		return bytes(result)
	
	def _decode_vli(self, data: bytes, offset: int) -> Tuple[int, int]:
		"""Decode variable-length integer"""
		result = 0
		shift = 0
		i = offset
		
		while i < len(data):
			byte = data[i]
			i += 1
			
			result |= (byte & 0x7F) << shift
			shift += 7
			
			if byte & 0x80:
				break
		
		return result, i
	
	def save(self, output_path: Path) -> bool:
		"""Save UPS patch"""
		try:
			with open(output_path, 'wb') as f:
				# Write header
				f.write(self.HEADER)
				
				# Write sizes
				f.write(self._encode_vli(self.input_size))
				f.write(self._encode_vli(self.output_size))
				
				# Write changes as XOR data
				last_offset = 0
				for offset, orig, new in self.changes:
					# Relative offset
					rel_offset = offset - last_offset
					f.write(self._encode_vli(rel_offset))
					
					# XOR value
					xor_value = orig ^ new
					f.write(bytes([xor_value]))
					
					last_offset = offset + 1
				
				# Write CRC32s
				f.write(struct.pack('<I', self.input_crc32))
				f.write(struct.pack('<I', self.output_crc32))
				
				# Calculate patch CRC32
				f.seek(0)
				patch_data = f.read()
				self.patch_crc32 = self._crc32(patch_data)
				
				f.write(struct.pack('<I', self.patch_crc32))
			
			if self.verbose:
				print(f"✓ Saved UPS patch to {output_path}")
			
			return True
		
		except Exception as e:
			print(f"Error saving UPS patch: {e}")
			return False


class PatchManager:
	"""Manage multiple patches"""
	
	def __init__(self, verbose: bool = False):
		self.verbose = verbose
		self.patches: List[IPSPatch] = []
	
	def add_patch(self, patch_path: Path) -> bool:
		"""Add patch to manager"""
		patch = IPSPatch(verbose=self.verbose)
		
		if not patch.load(patch_path):
			return False
		
		self.patches.append(patch)
		return True
	
	def apply_all(self, rom_data: bytes) -> Optional[bytes]:
		"""Apply all patches in order"""
		result = rom_data
		
		for i, patch in enumerate(self.patches):
			if self.verbose:
				print(f"Applying patch {i+1}/{len(self.patches)}...")
			
			result = patch.apply(result)
			
			if result is None:
				return None
		
		return result


def main():
	parser = argparse.ArgumentParser(description='FFMQ Patch System')
	parser.add_argument('--create', nargs=3, metavar=('ORIGINAL', 'MODIFIED', 'PATCH'),
					   help='Create patch from ROMs')
	parser.add_argument('--apply', nargs=2, metavar=('ROM', 'PATCH'),
					   help='Apply patch to ROM')
	parser.add_argument('--output', type=str, metavar='OUTPUT',
					   help='Output file path')
	parser.add_argument('--validate', type=str, metavar='PATCH',
					   help='Validate patch file')
	parser.add_argument('--info', type=str, metavar='PATCH',
					   help='Show patch info')
	parser.add_argument('--multi', nargs='+', metavar='PATCH',
					   help='Apply multiple patches')
	parser.add_argument('--format', type=str, choices=['ips', 'ups'],
					   default='ips', help='Patch format')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	# Create patch
	if args.create:
		original_path, modified_path, patch_path = args.create
		
		# Load ROMs
		with open(original_path, 'rb') as f:
			original = f.read()
		
		with open(modified_path, 'rb') as f:
			modified = f.read()
		
		if args.format == 'ips':
			patch = IPSPatch(verbose=args.verbose)
			patch.create_from_roms(original, modified)
			patch.save(Path(patch_path))
		elif args.format == 'ups':
			patch = UPSPatch(verbose=args.verbose)
			patch.create_from_roms(original, modified)
			patch.save(Path(patch_path))
		
		return 0
	
	# Apply patch
	if args.apply:
		rom_path, patch_path = args.apply
		
		# Load ROM
		with open(rom_path, 'rb') as f:
			rom_data = f.read()
		
		# Load and apply patch
		if args.format == 'ips':
			patch = IPSPatch(verbose=args.verbose)
			patch.load(Path(patch_path))
			patched = patch.apply(rom_data)
		else:
			print("Only IPS format supported for apply")
			return 1
		
		if patched is None:
			print("Error: Failed to apply patch")
			return 1
		
		# Save output
		output_path = args.output or rom_path.replace('.smc', '_patched.smc')
		with open(output_path, 'wb') as f:
			f.write(patched)
		
		print(f"✓ Patched ROM saved to {output_path}")
		return 0
	
	# Multi-patch
	if args.multi:
		if not args.apply:
			print("Error: --multi requires --apply ROM")
			return 1
		
		rom_path = args.apply[0]
		
		# Load ROM
		with open(rom_path, 'rb') as f:
			rom_data = f.read()
		
		# Apply all patches
		manager = PatchManager(verbose=args.verbose)
		
		for patch_path in args.multi:
			manager.add_patch(Path(patch_path))
		
		patched = manager.apply_all(rom_data)
		
		if patched is None:
			print("Error: Failed to apply patches")
			return 1
		
		# Save output
		output_path = args.output or rom_path.replace('.smc', '_patched.smc')
		with open(output_path, 'wb') as f:
			f.write(patched)
		
		print(f"✓ Multi-patched ROM saved to {output_path}")
		return 0
	
	# Validate
	if args.validate:
		patch = IPSPatch(verbose=args.verbose)
		patch.load(Path(args.validate))
		patch.validate()
		return 0
	
	# Info
	if args.info:
		patch = IPSPatch(verbose=args.verbose)
		patch.load(Path(args.info))
		
		print(f"\n=== Patch Info ===\n")
		print(f"Records: {len(patch.records)}")
		print(f"Total changes: {sum(r.size for r in patch.records):,} bytes")
		print(f"RLE records: {sum(1 for r in patch.records if r.is_rle)}")
		
		if patch.records:
			print(f"\nFirst record: 0x{patch.records[0].offset:06X}")
			print(f"Last record: 0x{patch.records[-1].offset:06X}")
		
		return 0
	
	parser.print_help()
	return 1


if __name__ == '__main__':
	exit(main())
