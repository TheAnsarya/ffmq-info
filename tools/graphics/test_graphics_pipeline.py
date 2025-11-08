#!/usr/bin/env python3
"""
Graphics Pipeline Test
Tests the complete graphics workflow from extraction to ROM build.

This script demonstrates the full pipeline:
1. Extract graphics from ROM
2. Rebuild graphics (simulate edit)
3. Generate ASM includes
4. Verify ASM output

Usage:
	python test_graphics_pipeline.py
	python test_graphics_pipeline.py --full

Author: FFMQ Disassembly Project
Date: 2025-11-02
"""

import sys
import subprocess
from pathlib import Path


def run_command(cmd: list, description: str) -> bool:
	"""Run a command and report results."""
	print(f"\n{'='*60}")
	print(f"  {description}")
	print(f"{'='*60}")

	try:
		result = subprocess.run(
			cmd,
			cwd=Path.cwd(),
			capture_output=True,
			text=True
		)

		# Print output
		if result.stdout:
			print(result.stdout)

		if result.returncode != 0:
			print(f"\n❌ FAILED")
			if result.stderr:
				print(f"Error: {result.stderr}")
			return False

		print(f"\n✅ SUCCESS")
		return True

	except Exception as e:
		print(f"\n❌ ERROR: {e}")
		return False


def test_graphics_pipeline(full_test: bool = False):
	"""Test the complete graphics pipeline."""

	print("\n" + "="*60)
	print("  FFMQ Graphics Pipeline Test")
	print("="*60)
	print("\nThis test demonstrates the complete workflow:")
	print("  1. Extract graphics from ROM → PNG")
	print("  2. Rebuild graphics → Binary")
	print("  3. Generate ASM includes")
	print("  4. Verify output")

	project_root = Path.cwd()

	# Check if we have required files
	extracted_dir = project_root / 'data' / 'extracted' / 'sprites' / 'enemies'
	has_extracted = extracted_dir.exists() and list(extracted_dir.glob('*.png'))

	if not has_extracted and not full_test:
		print("\n⚠️  No extracted graphics found.")
		print("   Run with --full to extract graphics first.")
		print("   Or run: python tools/build_integration.py --extract")
		return False

	success = True

	# Test 1: Extract (if full test or no graphics)
	if full_test or not has_extracted:
		if not run_command(
			[sys.executable, 'tools/build_integration.py', '--extract'],
			'Test 1: Extract Graphics from ROM'
		):
			success = False
			print("\n⚠️  Extraction failed, but continuing...")
	else:
		print(f"\n✓ Skipping extraction (graphics already present)")

	# Test 2: Rebuild graphics
	if not run_command(
		[sys.executable, 'tools/build_integration.py', '--rebuild'],
		'Test 2: Rebuild Graphics (Incremental)'
	):
		success = False

	# Test 3: Generate ASM
	if not run_command(
		[sys.executable, 'tools/generate_graphics_asm.py'],
		'Test 3: Generate ASM Includes'
	):
		success = False

	# Test 4: Validate addresses
	if not run_command(
		[sys.executable, 'tools/generate_graphics_asm.py', '--validate'],
		'Test 4: Validate ROM Addresses'
	):
		success = False

	# Test 5: Validate graphics
	if not run_command(
		[sys.executable, 'tools/build_integration.py', '--validate'],
		'Test 5: Validate Graphics Files'
	):
		success = False

	# Report results
	print("\n" + "="*60)
	print("  TEST RESULTS")
	print("="*60)

	if success:
		print("\n✅ ALL TESTS PASSED!")
		print("\nThe graphics pipeline is fully operational:")
		print("  ✓ Extraction working")
		print("  ✓ Rebuild working")
		print("  ✓ ASM generation working")
		print("  ✓ Address validation working")
		print("  ✓ Graphics validation working")

		print("\n📁 Generated Files:")

		# Check for rebuilt files
		rebuilt_dir = project_root / 'data' / 'rebuilt' / 'sprites' / 'enemies'
		if rebuilt_dir.exists():
			bin_files = list(rebuilt_dir.glob('*.bin'))
			print(f"  • {len(bin_files)} binary files in data/rebuilt/sprites/enemies/")

		# Check for ASM files
		asm_dir = project_root / 'src' / 'asm' / 'graphics'
		if asm_dir.exists():
			asm_files = list(asm_dir.glob('*.asm'))
			print(f"  • {len(asm_files)} ASM files in src/asm/graphics/")
			for asm_file in sorted(asm_files):
				print(f"    - {asm_file.name}")

		# Check manifest
		manifest = project_root / 'build' / 'graphics_manifest.json'
		if manifest.exists():
			print(f"  • Build manifest: build/graphics_manifest.json")

		print("\n🎯 Next Steps:")
		print("  1. Edit any PNG in data/extracted/sprites/")
		print("  2. Run: make graphics-rebuild")
		print("  3. Run: make rom")
		print("  4. Test your modified ROM!")

	else:
		print("\n❌ SOME TESTS FAILED")
		print("\nCheck the errors above for details.")
		print("\nCommon issues:")
		print("  • Missing ROM file")
		print("  • Missing Python dependencies (pillow)")
		print("  • File permissions")

	return success


def main():
	"""Main function."""
	import argparse

	parser = argparse.ArgumentParser(
		description='Test the complete graphics pipeline'
	)
	parser.add_argument('--full', action='store_true',
						help='Full test including extraction')

	args = parser.parse_args()

	success = test_graphics_pipeline(full_test=args.full)

	return 0 if success else 1


if __name__ == '__main__':
	sys.exit(main())
