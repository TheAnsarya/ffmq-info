#!/usr/bin/env python3
"""
FFMQ ROM Diff Tool
Compares two ROM files byte-by-byte and reports differences
"""

import sys
import hashlib
from pathlib import Path
from typing import List, Tuple, Dict, Optional

class ROMDiff:
	"""Compare two ROM files and report differences"""

	def __init__(self, rom1_path: str, rom2_path: str):
		self.rom1_path = Path(rom1_path)
		self.rom2_path = Path(rom2_path)
		self.rom1_data = None
		self.rom2_data = None

	def load_roms(self) -> bool:
		"""Load both ROM files"""
		if not self.rom1_path.exists():
			print(f"❌ Error: ROM 1 not found: {self.rom1_path}")
			return False

		if not self.rom2_path.exists():
			print(f"❌ Error: ROM 2 not found: {self.rom2_path}")
			return False

		try:
			with open(self.rom1_path, 'rb') as f:
				self.rom1_data = f.read()
			with open(self.rom2_path, 'rb') as f:
				self.rom2_data = f.read()

			print(f"✓ Loaded ROM 1: {self.rom1_path.name} ({len(self.rom1_data):,} bytes)")
			print(f"✓ Loaded ROM 2: {self.rom2_path.name} ({len(self.rom2_data):,} bytes)")
			return True
		except Exception as e:
			print(f"❌ Error loading ROMs: {e}")
			return False

	def calculate_hashes(self) -> Tuple[str, str]:
		"""Calculate SHA256 hashes for both ROMs"""
		hash1 = hashlib.sha256(self.rom1_data).hexdigest().upper()
		hash2 = hashlib.sha256(self.rom2_data).hexdigest().upper()
		return hash1, hash2

	def find_differences(self, max_diffs: int = 100) -> List[Tuple[int, int, int]]:
		"""Find all byte differences between ROMs

		Returns list of (offset, byte1, byte2) tuples
		"""
		diffs = []
		min_len = min(len(self.rom1_data), len(self.rom2_data))

		for offset in range(min_len):
			if self.rom1_data[offset] != self.rom2_data[offset]:
				diffs.append((offset, self.rom1_data[offset], self.rom2_data[offset]))
				if len(diffs) >= max_diffs:
					break

		return diffs

	def format_lorom_address(self, offset: int) -> str:
		"""Convert PC offset to SNES LoROM address"""
		# Simple LoROM conversion (assumes no header)
		# PC $000000-$007FFF -> $80:8000-$80:FFFF (bank 0)
		# PC $008000-$00FFFF -> $81:8000-$81:FFFF (bank 1)
		# etc.

		bank = (offset // 0x8000)
		address_in_bank = (offset % 0x8000) + 0x8000
		snes_addr = (0x80 + bank, address_in_bank)
		return f"${snes_addr[0]:02X}:{snes_addr[1]:04X}"

	def find_diff_regions(self, diffs: List[Tuple[int, int, int]]) -> List[Tuple[int, int, int]]:
		"""Group consecutive differences into regions

		Returns list of (start_offset, end_offset, count) tuples
		"""
		if not diffs:
			return []

		regions = []
		current_start = diffs[0][0]
		current_end = diffs[0][0]

		for offset, _, _ in diffs[1:]:
			if offset == current_end + 1:
				# Consecutive difference
				current_end = offset
			else:
				# Gap found, save current region and start new one
				regions.append((current_start, current_end, current_end - current_start + 1))
				current_start = offset
				current_end = offset

		# Add final region
		regions.append((current_start, current_end, current_end - current_start + 1))

		return regions

	def show_diff_context(self, offset: int, context: int = 8) -> str:
		"""Show hex dump context around a difference"""
		start = max(0, offset - context)
		end = min(len(self.rom1_data), offset + context + 1)

		lines = []
		lines.append(f"\n  Offset ${offset:06X} ({self.format_lorom_address(offset)}):")

		# ROM 1
		hex1 = ' '.join(f"{b:02X}" for b in self.rom1_data[start:end])
		lines.append(f"  ROM 1: {hex1}")

		# ROM 2
		hex2 = ' '.join(f"{b:02X}" for b in self.rom2_data[start:end])
		lines.append(f"  ROM 2: {hex2}")

		# Indicator
		indicator = '   ' * (offset - start) + ' ^^'
		lines.append(f"		{indicator}")

		return '\n'.join(lines)

	def compare(self, verbose: bool = False, max_diffs: int = 100) -> bool:
		"""Perform full ROM comparison"""
		print("\n" + "="*80)
		print(" ROM Comparison Tool")
		print("="*80)
		print()

		# Load ROMs
		if not self.load_roms():
			return False
		print()

		# Check sizes
		if len(self.rom1_data) != len(self.rom2_data):
			print(f"⚠️  WARNING: ROM sizes differ!")
			print(f"   ROM 1: {len(self.rom1_data):,} bytes")
			print(f"   ROM 2: {len(self.rom2_data):,} bytes")
			print()

		# Calculate hashes
		print("Calculating hashes...")
		hash1, hash2 = self.calculate_hashes()
		print(f"  ROM 1 SHA256: {hash1}")
		print(f"  ROM 2 SHA256: {hash2}")
		print()

		if hash1 == hash2:
			print("✅ ROMs are IDENTICAL - No differences found!")
			print("="*80)
			return True

		print("❌ ROMs are DIFFERENT - Analyzing differences...")
		print()

		# Find differences
		diffs = self.find_differences(max_diffs=max_diffs)

		if not diffs:
			print("⚠️  Hashes differ but no byte differences found in compared range.")
			print("   (ROMs may differ only in size)")
			return False

		total_diffs = len(diffs)
		if total_diffs >= max_diffs:
			print(f"⚠️  Found {max_diffs}+ differences (limit reached, more may exist)")
		else:
			print(f"Found {total_diffs} byte difference(s)")
		print()

		# Find regions
		regions = self.find_diff_regions(diffs)

		print(f"Differences grouped into {len(regions)} region(s):")
		print()

		for i, (start, end, count) in enumerate(regions, 1):
			print(f"  Region {i}: ${start:06X}-${end:06X} " +
				  f"({self.format_lorom_address(start)} to {self.format_lorom_address(end)})")
			print(f"		   {count} byte(s) differ")

			if verbose and count <= 16:
				# Show first few bytes of small regions
				for offset in range(start, min(start + 8, end + 1)):
					idx = next((i for i, (o, _, _) in enumerate(diffs) if o == offset), None)
					if idx is not None:
						_, b1, b2 = diffs[idx]
						print(f"			 ${offset:06X}: ${b1:02X} → ${b2:02X}")
			print()

		if verbose and total_diffs <= 20:
			print("\nDetailed diff:")
			for offset, byte1, byte2 in diffs[:20]:
				print(self.show_diff_context(offset))

		print("="*80)
		return False

def main():
	"""Main entry point"""
	if len(sys.argv) < 3:
		print("Usage: python rom_diff.py <rom1> <rom2> [--verbose]")
		print()
		print("Examples:")
		print("  python rom_diff.py original.sfc build/ffmq-rebuilt.sfc")
		print("  python rom_diff.py rom_v1.sfc rom_v2.sfc --verbose")
		print()
		print("Options:")
		print("  --verbose  Show detailed byte-by-byte differences")
		sys.exit(1)

	rom1_path = sys.argv[1]
	rom2_path = sys.argv[2]
	verbose = '--verbose' in sys.argv or '-v' in sys.argv

	differ = ROMDiff(rom1_path, rom2_path)
	identical = differ.compare(verbose=verbose)

	sys.exit(0 if identical else 1)

if __name__ == '__main__':
	main()
