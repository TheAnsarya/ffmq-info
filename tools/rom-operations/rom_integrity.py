#!/usr/bin/env python3
"""
FFMQ ROM Integrity Checker
Validates ROM integrity, checksums, header, and compatibility
"""

import sys
import hashlib
import struct
from pathlib import Path
from typing import Dict, Any, Optional, Tuple

class ROMIntegrityChecker:
	"""Verify ROM file integrity and compatibility"""

	# Known good ROM hashes (headerless)
	KNOWN_HASHES = {
		'sha256': {
			'F71817F55FEBD32FD1DCE617A326A77B6B062DD0D4058ECD289F64AF1B7A1D05': 'FFMQ (USA)',
		},
		'md5': {
			# Add known MD5 hashes here if needed
		}
	}

	# Expected ROM sizes
	VALID_SIZES = {
		524288: '512 KB (no header)',
		524800: '512 KB + 512 byte header',
		1048576: '1 MB (padded, no header)',
		1049088: '1 MB (padded) + 512 byte header',
	}

	# SNES header locations
	LOROM_HEADER_OFFSET = 0x7FC0  # LoROM header location (no SMC header)
	LOROM_HEADER_OFFSET_SMC = 0x81C0  # LoROM header with 512-byte SMC header

	def __init__(self, rom_path: str):
		self.rom_path = Path(rom_path)
		self.rom_data = None
		self.has_header = False
		self.header_offset = 0
		self.rom_size = 0

	def load_rom(self) -> bool:
		"""Load ROM file"""
		if not self.rom_path.exists():
			print(f"❌ Error: ROM file not found: {self.rom_path}")
			return False

		try:
			with open(self.rom_path, 'rb') as f:
				self.rom_data = f.read()
			self.rom_size = len(self.rom_data)
			print(f"✓ Loaded ROM: {self.rom_size:,} bytes ({self.rom_size / 1024:.1f} KB)")
			return True
		except Exception as e:
			print(f"❌ Error loading ROM: {e}")
			return False

	def detect_header(self) -> bool:
		"""Detect if ROM has SMC/copier header"""
		# Check if file size suggests a header
		if self.rom_size % 1024 == 512:
			self.has_header = True
			self.header_offset = 512
			print(f"✓ Detected 512-byte copier header")
			return True
		else:
			self.has_header = False
			self.header_offset = 0
			print(f"✓ No copier header detected")
			return False

	def calculate_hashes(self) -> Dict[str, str]:
		"""Calculate ROM hashes (without header)"""
		# Skip header if present
		rom_clean = self.rom_data[self.header_offset:]

		hashes = {
			'sha256': hashlib.sha256(rom_clean).hexdigest().upper(),
			'md5': hashlib.md5(rom_clean).hexdigest().upper(),
			'sha1': hashlib.sha1(rom_clean).hexdigest().upper(),
		}

		return hashes

	def verify_checksum(self) -> Tuple[bool, str]:
		"""Verify SNES internal checksum"""
		# Determine header location
		if self.has_header:
			header_loc = self.LOROM_HEADER_OFFSET_SMC
		else:
			header_loc = self.LOROM_HEADER_OFFSET

		if header_loc + 16 > len(self.rom_data):
			return False, "Header location out of range"

		# Read checksum and complement
		checksum_offset = header_loc + 0x1C
		complement_offset = header_loc + 0x1E

		checksum = struct.unpack('<H', self.rom_data[checksum_offset:checksum_offset+2])[0]
		complement = struct.unpack('<H', self.rom_data[complement_offset:complement_offset+2])[0]

		# Verify complement
		if (checksum ^ complement) != 0xFFFF:
			return False, f"Checksum/complement mismatch (Checksum: ${checksum:04X}, Complement: ${complement:04X})"

		return True, f"Checksum: ${checksum:04X}, Complement: ${complement:04X}"

	def read_header_info(self) -> Dict[str, Any]:
		"""Read SNES ROM header information"""
		if self.has_header:
			header_loc = self.LOROM_HEADER_OFFSET_SMC
		else:
			header_loc = self.LOROM_HEADER_OFFSET

		if header_loc + 32 > len(self.rom_data):
			return {}

		header_data = self.rom_data[header_loc:header_loc+32]

		# Parse header
		info = {
			'title': header_data[0:21].decode('ascii', errors='ignore').strip(),
			'map_mode': header_data[21],
			'rom_type': header_data[22],
			'rom_size': header_data[23],
			'sram_size': header_data[24],
			'country': header_data[25],
			'developer': header_data[26],
			'version': header_data[27],
			'checksum_complement': struct.unpack('<H', header_data[28:30])[0],
			'checksum': struct.unpack('<H', header_data[30:32])[0],
		}

		# Interpret values
		info['rom_size_kb'] = 1 << info['rom_size'] if info['rom_size'] < 16 else 0
		info['sram_size_kb'] = 1 << info['sram_size'] if info['sram_size'] < 16 else 0

		map_modes = {
			0x20: 'LoROM',
			0x21: 'HiROM',
			0x22: 'LoROM + S-DD1',
			0x23: 'LoROM + SA-1',
			0x30: 'LoROM + FastROM',
			0x31: 'HiROM + FastROM',
		}
		info['map_mode_name'] = map_modes.get(info['map_mode'], f"Unknown (${info['map_mode']:02X})")

		return info

	def check_size(self) -> Tuple[bool, str]:
		"""Check if ROM size is valid"""
		if self.rom_size in self.VALID_SIZES:
			return True, self.VALID_SIZES[self.rom_size]
		else:
			return False, f"Unexpected size: {self.rom_size:,} bytes"

	def verify(self) -> bool:
		"""Perform complete ROM verification"""
		print("\n" + "="*70)
		print(" FFMQ ROM Integrity Checker")
		print("="*70)
		print(f"\nROM File: {self.rom_path}")
		print()

		# Load ROM
		if not self.load_rom():
			return False

		# Detect header
		self.detect_header()

		# Check size
		size_valid, size_msg = self.check_size()
		if size_valid:
			print(f"✓ ROM Size: {size_msg}")
		else:
			print(f"⚠ ROM Size: {size_msg}")

		print()

		# Calculate hashes
		print("Calculating hashes...")
		hashes = self.calculate_hashes()

		print(f"  SHA256: {hashes['sha256']}")
		print(f"  MD5:	{hashes['md5']}")
		print(f"  SHA1:   {hashes['sha1']}")
		print()

		# Check against known good hashes
		is_known = False
		for known_hash, rom_name in self.KNOWN_HASHES['sha256'].items():
			if hashes['sha256'] == known_hash:
				print(f"✓ ROM Identified: {rom_name}")
				is_known = True
				break

		if not is_known:
			print(f"⚠ ROM hash not recognized (may be modified or different version)")
		print()

		# Read header
		header = self.read_header_info()
		if header:
			print("ROM Header Information:")
			print(f"  Title:	   {header['title']}")
			print(f"  Map Mode:	{header['map_mode_name']}")
			print(f"  ROM Size:	{header['rom_size_kb']} KB")
			print(f"  SRAM Size:   {header['sram_size_kb']} KB")
			print(f"  Country:	 ${header['country']:02X}")
			print(f"  Version:	 1.{header['version']}")
			print()

		# Verify checksum
		checksum_valid, checksum_msg = self.verify_checksum()
		if checksum_valid:
			print(f"✓ Internal Checksum Valid: {checksum_msg}")
		else:
			print(f"❌ Internal Checksum Invalid: {checksum_msg}")
		print()

		# Summary
		print("="*70)
		if is_known and checksum_valid:
			print("✅ ROM VERIFICATION PASSED")
			print("   This ROM is a known good dump and passes all integrity checks.")
		elif checksum_valid:
			print("✅ ROM APPEARS VALID")
			print("   Checksum is valid but hash is not recognized.")
			print("   This may be a modified ROM or different release.")
		else:
			print("❌ ROM VERIFICATION FAILED")
			print("   This ROM may be corrupted or improperly dumped.")
		print("="*70)
		print()

		return is_known and checksum_valid

def main():
	"""Main entry point"""
	if len(sys.argv) < 2:
		print("Usage: python rom_integrity.py <rom_file>")
		print()
		print("Example:")
		print("  python rom_integrity.py roms/ffmq.sfc")
		print("  python rom_integrity.py build/ffmq-rebuilt.sfc")
		sys.exit(1)

	rom_file = sys.argv[1]

	checker = ROMIntegrityChecker(rom_file)
	success = checker.verify()

	sys.exit(0 if success else 1)

if __name__ == '__main__':
	main()
