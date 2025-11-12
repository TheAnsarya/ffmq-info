#!/usr/bin/env python3
"""
FFMQ ROM Integrity Validation Tool

Validates that our rebuilt ROM matches the original ROM byte-for-byte.
Performs comprehensive analysis including:
- Byte-by-byte comparison
- Checksum validation
- Size verification
- Difference analysis and reporting
- Build system verification

Ensures our build pipeline produces accurate, authentic ROMs.
"""

import os
import sys
import hashlib
from pathlib import Path
from typing import Dict, List, Tuple, Optional
from dataclasses import dataclass
import json


@dataclass
class ROMInfo:
	"""Container for ROM information"""
	path: Path
	size: int
	md5: str
	sha1: str
	sha256: str
	name: str


@dataclass
class ComparisonResult:
	"""Container for ROM comparison results"""
	identical: bool
	size_match: bool
	total_differences: int
	different_regions: List[Tuple[int, int, str]]	# (start, end, description)
	checksum_match: bool
	details: str


class ROMIntegrityValidator:
	"""Validates ROM integrity and build system accuracy"""

	def __init__(self, roms_dir: Path):
		self.roms_dir = roms_dir
		self.results = {}

		# Expected ROM characteristics for FFMQ (U) V1.1
		self.expected_size = 524288	# 512KB
		self.expected_md5 = None	# Will calculate from original

		# Known ROM file patterns
		self.original_patterns = [
			"Final Fantasy - Mystic Quest (U) (V1.1).sfc",
			"ffmq_original.sfc",
			"original.sfc"
		]
		self.rebuilt_patterns = [
			"ffmq_rebuilt.sfc",
			"rebuilt.sfc",
			"output.sfc"
		]

	def calculate_checksums(self, rom_path: Path) -> Dict[str, str]:
		"""Calculate MD5, SHA1, and SHA256 checksums for ROM"""
		checksums = {'md5': '', 'sha1': '', 'sha256': ''}

		try:
			with open(rom_path, 'rb') as f:
				data = f.read()

				checksums['md5'] = hashlib.md5(data).hexdigest().upper()
				checksums['sha1'] = hashlib.sha1(data).hexdigest().upper()
				checksums['sha256'] = hashlib.sha256(data).hexdigest().upper()

		except Exception as e:
			print(f"❌ Error calculating checksums for {rom_path}: {e}")

		return checksums

	def get_rom_info(self, rom_path: Path) -> ROMInfo:
		"""Get comprehensive information about a ROM file"""
		if not rom_path.exists():
			raise FileNotFoundError(f"ROM file not found: {rom_path}")

		size = rom_path.stat().st_size
		checksums = self.calculate_checksums(rom_path)

		return ROMInfo(
			path=rom_path,
			size=size,
			md5=checksums['md5'],
			sha1=checksums['sha1'],
			sha256=checksums['sha256'],
			name=rom_path.name
		)

	def find_roms(self) -> Tuple[Optional[Path], Optional[Path]]:
		"""Find original and rebuilt ROM files"""
		original_rom = None
		rebuilt_rom = None

		# Look for ROM files in the roms directory
		for file_path in self.roms_dir.glob("*.sfc"):
			filename = file_path.name

			if any(pattern in filename for pattern in self.original_patterns):
				original_rom = file_path
			elif any(pattern in filename for pattern in self.rebuilt_patterns):
				rebuilt_rom = file_path

		return original_rom, rebuilt_rom

	def compare_roms_bytewise(self, rom1_path: Path, rom2_path: Path) -> ComparisonResult:
		"""Perform byte-by-byte comparison of two ROMs"""
		print(f"🔍 Comparing ROMs byte-by-byte...")

		rom1_info = self.get_rom_info(rom1_path)
		rom2_info = self.get_rom_info(rom2_path)

		# Check sizes first
		size_match = rom1_info.size == rom2_info.size
		if not size_match:
			return ComparisonResult(
				identical=False,
				size_match=False,
				total_differences=abs(rom1_info.size - rom2_info.size),
				different_regions=[],
				checksum_match=False,
				details=f"Size mismatch: {rom1_info.size} vs {rom2_info.size} bytes"
			)

		# Check checksums
		checksum_match = (rom1_info.md5 == rom2_info.md5 and
						 rom1_info.sha1 == rom2_info.sha1 and
						 rom1_info.sha256 == rom2_info.sha256)

		if checksum_match:
			return ComparisonResult(
				identical=True,
				size_match=True,
				total_differences=0,
				different_regions=[],
				checksum_match=True,
				details="ROMs are identical - all checksums match"
			)

		# Perform detailed byte comparison
		different_regions = []
		total_differences = 0
		current_region_start = None

		with open(rom1_path, 'rb') as f1, open(rom2_path, 'rb') as f2:
			position = 0
			chunk_size = 64 * 1024	# 64KB chunks

			while True:
				chunk1 = f1.read(chunk_size)
				chunk2 = f2.read(chunk_size)

				if not chunk1 and not chunk2:
					break

				# Compare bytes in chunk
				for i in range(len(chunk1)):
					if chunk1[i] != chunk2[i]:
						if current_region_start is None:
							current_region_start = position + i
						total_differences += 1
					else:
						# End of different region
						if current_region_start is not None:
							region_end = position + i - 1
							region_size = region_end - current_region_start + 1
							description = self.analyze_region(current_region_start, region_end)
							different_regions.append((current_region_start, region_end, description))
							current_region_start = None

				position += len(chunk1)

		# Handle case where difference extends to end of file
		if current_region_start is not None:
			region_end = position - 1
			description = self.analyze_region(current_region_start, region_end)
			different_regions.append((current_region_start, region_end, description))

		return ComparisonResult(
			identical=False,
			size_match=True,
			total_differences=total_differences,
			different_regions=different_regions,
			checksum_match=False,
			details=f"Found {total_differences} different bytes in {len(different_regions)} regions"
		)

	def analyze_region(self, start: int, end: int) -> str:
		"""Analyze what type of data might be in a different region"""
		region_size = end - start + 1

		# SNES ROM memory map analysis
		if start < 0x8000:
			return f"Low ROM area ({region_size} bytes)"
		elif 0x8000 <= start < 0x10000:
			return f"Bank 0 code/data ({region_size} bytes)"
		elif 0x10000 <= start < 0x80000:
			return f"ROM data banks ({region_size} bytes)"
		else:
			return f"Unknown region ({region_size} bytes)"

	def validate_build_system(self) -> bool:
		"""Validate that our build system can produce accurate ROMs"""
		print("🔧 Validating build system...")

		# Check if Makefile exists
		makefile_path = Path("Makefile")
		if not makefile_path.exists():
			print("❌ Makefile not found")
			return False

		# Check if build script exists
		build_script = Path("build.ps1")
		if not build_script.exists():
			print("❌ build.ps1 not found")
			return False

		print("✅ Build system files present")
		return True

	def run_validation(self) -> Dict:
		"""Run complete ROM integrity validation"""
		print("=" * 80)
		print("FFMQ ROM INTEGRITY VALIDATION")
		print("=" * 80)
		print()

		# Find ROM files
		print("🔍 Searching for ROM files...")
		original_rom, rebuilt_rom = self.find_roms()

		if not original_rom:
			print("❌ Original ROM not found!")
			print(f"	 Looking for: {', '.join(self.original_patterns)}")
			return {"status": "error", "message": "Original ROM not found"}

		if not rebuilt_rom:
			print("❌ Rebuilt ROM not found!")
			print(f"	 Looking for: {', '.join(self.rebuilt_patterns)}")
			return {"status": "error", "message": "Rebuilt ROM not found"}

		print(f"✅ Original ROM: {original_rom.name}")
		print(f"✅ Rebuilt ROM: {rebuilt_rom.name}")
		print()

		# Get ROM information
		print("📊 Analyzing ROM characteristics...")
		original_info = self.get_rom_info(original_rom)
		rebuilt_info = self.get_rom_info(rebuilt_rom)

		print(f"📁 Original ROM:")
		print(f"	 Size: {original_info.size:,} bytes ({original_info.size/1024:.1f} KB)")
		print(f"	 MD5:	{original_info.md5}")
		print(f"	 SHA1: {original_info.sha1}")
		print()

		print(f"📁 Rebuilt ROM:")
		print(f"	 Size: {rebuilt_info.size:,} bytes ({rebuilt_info.size/1024:.1f} KB)")
		print(f"	 MD5:	{rebuilt_info.md5}")
		print(f"	 SHA1: {rebuilt_info.sha1}")
		print()

		# Compare ROMs
		comparison = self.compare_roms_bytewise(original_rom, rebuilt_rom)

		# Report results
		print("🔍 COMPARISON RESULTS:")
		print("-" * 50)

		if comparison.identical:
			print("✅ ROMs are IDENTICAL!")
			print("	 ✅ Size matches")
			print("	 ✅ All checksums match")
			print("	 ✅ Byte-by-byte comparison passed")
			status = "success"
			message = "ROMs are identical - build system produces perfect output"
		else:
			print("❌ ROMs are DIFFERENT!")
			print(f"	 Size match: {'✅' if comparison.size_match else '❌'}")
			print(f"	 Checksum match: {'✅' if comparison.checksum_match else '❌'}")
			print(f"	 Total differences: {comparison.total_differences:,} bytes")
			print(f"	 Different regions: {len(comparison.different_regions)}")

			if comparison.different_regions:
				print("\n📍 DIFFERENT REGIONS:")
				for i, (start, end, desc) in enumerate(comparison.different_regions[:10]):	# Show first 10
					size = end - start + 1
					print(f"	 {i+1}. 0x{start:08X}-0x{end:08X} ({size:,} bytes) - {desc}")

				if len(comparison.different_regions) > 10:
					remaining = len(comparison.different_regions) - 10
					print(f"	 ... and {remaining} more regions")

			status = "differences_found"
			message = f"Found {comparison.total_differences} different bytes in {len(comparison.different_regions)} regions"

		print()

		# Validate build system
		build_system_ok = self.validate_build_system()

		# Final assessment
		print("🎯 FINAL ASSESSMENT:")
		print("-" * 50)

		if comparison.identical and build_system_ok:
			print("✅ EXCELLENT: Build system produces perfect, identical ROMs")
			assessment = "excellent"
		elif comparison.size_match and comparison.total_differences < 100:
			print("⚠️	GOOD: Minor differences found, likely acceptable")
			assessment = "good_with_minor_differences"
		elif comparison.size_match:
			print("⚠️	CONCERNING: Significant differences found")
			assessment = "concerning_differences"
		else:
			print("❌ CRITICAL: Major differences or size mismatch")
			assessment = "critical_issues"

		print()

		# Prepare results
		results = {
			"status": status,
			"message": message,
			"assessment": assessment,
			"original_rom": {
				"path": str(original_rom),
				"size": original_info.size,
				"md5": original_info.md5,
				"sha1": original_info.sha1,
				"sha256": original_info.sha256
			},
			"rebuilt_rom": {
				"path": str(rebuilt_rom),
				"size": rebuilt_info.size,
				"md5": rebuilt_info.md5,
				"sha1": rebuilt_info.sha1,
				"sha256": rebuilt_info.sha256
			},
			"comparison": {
				"identical": comparison.identical,
				"size_match": comparison.size_match,
				"checksum_match": comparison.checksum_match,
				"total_differences": comparison.total_differences,
				"different_regions_count": len(comparison.different_regions),
				"different_regions": [
					{
						"start": start,
						"end": end,
						"size": end - start + 1,
						"description": desc
					} for start, end, desc in comparison.different_regions
				]
			},
			"build_system_ok": build_system_ok
		}

		# Save results
		results_file = Path("tools/validation/rom_integrity_report.json")
		results_file.parent.mkdir(exist_ok=True)

		with open(results_file, 'w', encoding='utf-8') as f:
			json.dump(results, f, indent=2)

		print(f"📄 Detailed results saved to: {results_file}")

		return results


def main():
	"""Main ROM integrity validation function"""
	# Set up paths
	script_dir = Path(__file__).parent
	project_dir = script_dir.parent.parent
	roms_dir = project_dir / "roms"

	if not roms_dir.exists():
		print(f"❌ ROMs directory not found: {roms_dir}")
		return 1

	# Run validation
	validator = ROMIntegrityValidator(roms_dir)
	results = validator.run_validation()

	# Return appropriate exit code
	if results.get("status") == "success":
		return 0
	elif results.get("status") == "differences_found":
		return 2	# Warning level
	else:
		return 1	# Error level


if __name__ == "__main__":
	exit(main())
