#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Build and Compare Tool
======================

Build the ROM and automatically compare with the original to show what changed.

This is useful for verifying your modifications and understanding the impact
of your changes on the ROM.

Usage:
	python tools/build_and_compare.py
	python tools/build_and_compare.py --verbose
	python tools/build_and_compare.py --keep-temp
"""

import sys
import io
import subprocess
from pathlib import Path
import shutil

# Fix Windows console encoding
if sys.platform == 'win32':
	sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
	sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

def run_command(cmd, description):
	"""Run a command and return success status."""
	print(f"[INFO] {description}...")
	result = subprocess.run(cmd, shell=True, capture_output=True, text=True)

	if result.returncode != 0:
		print(f"[ERROR] {description} failed!")
		print(result.stderr)
		return False

	return True

def main():
	"""Main entry point."""
	import argparse

	parser = argparse.ArgumentParser(
		description='Build ROM and compare with original',
		formatter_class=argparse.RawDescriptionHelpFormatter,
		epilog="""
This tool:
1. Backs up the current built ROM (if it exists)
2. Rebuilds the ROM from source
3. Compares the new build with the backup
4. Shows what changed

This helps you verify that your modifications are working correctly.
		"""
	)

	parser.add_argument('--verbose', '-v', action='store_true',
					   help='Show detailed differences')
	parser.add_argument('--keep-temp', '-k', action='store_true',
					   help='Keep temporary backup file')

	args = parser.parse_args()

	print("=" * 80)
	print("Build and Compare Tool")
	print("=" * 80)
	print()

	rom_path = Path("build/ffmq-rebuilt.sfc")
	backup_path = Path("build/ffmq-rebuilt.sfc.backup")

	# Step 1: Backup current ROM
	if rom_path.exists():
		print("[INFO] Backing up current ROM...")
		shutil.copy2(rom_path, backup_path)
		print(f"	   Saved to: {backup_path}")
	else:
		print("[INFO] No existing ROM to backup")
		backup_path = None

	print()

	# Step 2: Convert data (if JSON changed)
	print("[INFO] Converting battle data to ASM...")
	result = subprocess.run(
		[sys.executable, "tools/conversion/convert_all.py"],
		capture_output=True,
		text=True
	)

	if result.returncode != 0:
		print("[ERROR] Data conversion failed!")
		print(result.stderr)
		return 1

	print("[OK] Data conversion complete")
	print()

	# Step 3: Build ROM
	if not run_command("pwsh -File build.ps1", "Building ROM"):
		return 1

	print("[OK] ROM build complete")
	print()

	# Step 4: Compare
	if backup_path and backup_path.exists():
		print("=" * 80)
		print("Comparing with Previous Build")
		print("=" * 80)
		print()

		compare_cmd = [
			sys.executable,
			"tools/compare_roms.py",
			str(backup_path),
			str(rom_path),
			"--regions"
		]

		if args.verbose:
			compare_cmd.append("--verbose")

		result = subprocess.run(compare_cmd)

		# Clean up backup unless --keep-temp
		if not args.keep_temp:
			print()
			print(f"[INFO] Removing backup: {backup_path}")
			backup_path.unlink()
		else:
			print()
			print(f"[INFO] Backup kept at: {backup_path}")
	else:
		print("[INFO] No previous build to compare with")
		print("	   This appears to be a fresh build")

	print()
	print("=" * 80)
	print("[SUCCESS] Build and compare complete!")
	print("=" * 80)
	print()
	print("Your ROM is ready:")
	print(f"  {rom_path.absolute()}")
	print()
	print("Test it:")
	print(f"  mesen {rom_path}")

	return 0

if __name__ == '__main__':
	sys.exit(main())
