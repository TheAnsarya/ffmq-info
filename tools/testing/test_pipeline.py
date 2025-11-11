#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
End-to-end test of the battle data pipeline.

Tests the complete workflow:
1. Extract enemy data from ROM
2. Modify JSON data
3. Convert JSON to ASM
4. Verify ASM output matches expected format

This validates the round-trip conversion without requiring a full ROM rebuild.
"""

import json
import os
import sys
import io

# Fix Windows console encoding
if sys.platform == 'win32':
	sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
	sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')
import sys
import subprocess
import tempfile
import shutil

def test_extraction():
	"""Test: Enemy data extraction from ROM."""
	print("=" * 80)
	print("TEST 1: Enemy Data Extraction")
	print("=" * 80)

	# Run extraction
	result = subprocess.run(
		[sys.executable, "tools/extraction/extract_enemies.py"],
		capture_output=True,
		text=True
	)

	if result.returncode != 0:
		print("[ERROR] FAILED: Extraction failed")
		print(result.stderr)
		return False

	# Check JSON exists
	json_path = "data/extracted/enemies/enemies.json"
	if not os.path.exists(json_path):
		print("[ERROR] FAILED: enemies.json not created")
		return False

	# Load and validate JSON
	with open(json_path, 'r') as f:
		data = json.load(f)

	if 'enemies' not in data or 'metadata' not in data:
		print("[ERROR] FAILED: JSON missing required fields")
		return False

	enemy_count = len(data['enemies'])
	if enemy_count != 83:
		print(f"[ERROR] FAILED: Expected 83 enemies, got {enemy_count}")
		return False

	# Check Brownie (enemy 0) has correct HP
	brownie = data['enemies'][0]
	if brownie['name'] != 'Brownie' or brownie['hp'] != 50:
		print(f"[ERROR] FAILED: Brownie data incorrect: {brownie}")
		return False

	print(f"[OK] PASSED: Extracted {enemy_count} enemies")
	print(f"[OK] PASSED: Brownie HP = {brownie['hp']} (expected 50)")
	return True

def test_json_modification():
	"""Test: Modify JSON data."""
	print()
	print("=" * 80)
	print("TEST 2: JSON Modification")
	print("=" * 80)

	json_path = "data/extracted/enemies/enemies.json"
	backup_path = json_path + ".backup"

	# Backup original
	shutil.copy(json_path, backup_path)

	try:
		# Load JSON
		with open(json_path, 'r') as f:
			data = json.load(f)

		# Modify Brownie HP: 50 → 100
		old_hp = data['enemies'][0]['hp']
		data['enemies'][0]['hp'] = 100

		# Save modified JSON
		with open(json_path, 'w') as f:
			json.dump(data, f, indent=2)

		# Verify modification
		with open(json_path, 'r') as f:
			modified = json.load(f)

		new_hp = modified['enemies'][0]['hp']
		if new_hp != 100:
			print(f"[ERROR] FAILED: Modification not saved (HP = {new_hp})")
			return False

		print(f"[OK] PASSED: Modified Brownie HP: {old_hp} → {new_hp}")
		return True

	finally:
		# Restore original
		shutil.move(backup_path, json_path)
		print("  (Restored original JSON)")

def test_conversion():
	"""Test: Convert JSON to ASM."""
	print()
	print("=" * 80)
	print("TEST 3: JSON to ASM Conversion")
	print("=" * 80)

	# Run conversion
	result = subprocess.run(
		[sys.executable, "tools/conversion/convert_all.py"],
		capture_output=True,
		text=True
	)

	if result.returncode != 0:
		print("[ERROR] FAILED: Conversion failed")
		print(result.stderr)
		return False

	# Check generated ASM files exist
	expected_files = [
		"data/converted/enemies/enemies_stats.asm",
		"data/converted/enemies/enemies_level.asm",
		"data/converted/attacks/attacks_data.asm",
		"data/converted/attacks/enemy_attack_links.asm",
	]

	for file_path in expected_files:
		if not os.path.exists(file_path):
			print(f"[ERROR] FAILED: {file_path} not created")
			return False

	# Validate enemies_stats.asm content
	stats_path = "data/converted/enemies/enemies_stats.asm"
	with open(stats_path, 'r') as f:
		content = f.read()

	# Check for Brownie data
	if "Enemy 000: Brownie" not in content:
		print("[ERROR] FAILED: Brownie comment not in ASM")
		return False

	# Check for HP value ($0032 = 50 decimal)
	if "dw $0032" not in content:
		print("[ERROR] FAILED: Brownie HP value ($0032) not in ASM")
		return False

	# Check for note about inline inclusion (we removed org directives)
	if "inline" not in content.lower():
		print("[ERROR] FAILED: Missing inline inclusion note")
		return False

	print("[OK] PASSED: All ASM files generated")
	print("[OK] PASSED: enemies_stats.asm contains Brownie data")
	print("[OK] PASSED: ASM configured for inline inclusion (no org directive)")
	return True

def test_complete_pipeline():
	"""Test: Complete pipeline with modification."""
	print()
	print("=" * 80)
	print("TEST 4: Complete Pipeline Test")
	print("=" * 80)

	json_path = "data/extracted/enemies/enemies.json"
	backup_path = json_path + ".backup"

	# Backup original
	shutil.copy(json_path, backup_path)

	try:
		# 1. Load and modify JSON
		with open(json_path, 'r') as f:
			data = json.load(f)

		data['enemies'][0]['hp'] = 999  # Super Brownie!

		with open(json_path, 'w') as f:
			json.dump(data, f, indent=2)

		print("  Modified Brownie HP → 999")

		# 2. Convert to ASM
		result = subprocess.run(
			[sys.executable, "tools/conversion/convert_all.py"],
			capture_output=True,
			text=True
		)

		if result.returncode != 0:
			print("[ERROR] FAILED: Conversion failed")
			return False

		# 3. Verify ASM has new value
		stats_path = "data/converted/enemies/enemies_stats.asm"
		with open(stats_path, 'r') as f:
			content = f.read()

		# $03E7 = 999 decimal
		if "dw $03E7" not in content:
			print("[ERROR] FAILED: Modified HP ($03E7 = 999) not in ASM")
			# Find what HP value is actually there
			for line in content.split('\n'):
				if "Enemy 000: Brownie" in line:
					idx = content.split('\n').index(line)
					print(f"  Found at line {idx}:")
					print(f"  {content.split(chr(10))[idx:idx+5]}")
			return False

		print("[OK] PASSED: Complete pipeline working!")
		print("[OK] PASSED: Modified HP value reflected in ASM")
		return True

	finally:
		# Restore original
		shutil.move(backup_path, json_path)
		# Re-convert to restore original ASM
		subprocess.run(
			[sys.executable, "tools/conversion/convert_all.py"],
			capture_output=True
		)
		print("  (Restored original data)")

def main():
	"""Run all tests."""
	print()
	print("=" * 80)
	print("  FFMQ Battle Data Pipeline - End-to-End Test Suite")
	print("=" * 80)
	print()

	tests = [
		("Extraction", test_extraction),
		("JSON Modification", test_json_modification),
		("Conversion", test_conversion),
		("Complete Pipeline", test_complete_pipeline),
	]

	results = []
	for name, test_func in tests:
		try:
			passed = test_func()
			results.append((name, passed))
		except Exception as e:
			print(f"[ERROR] ERROR: {e}")
			results.append((name, False))

	# Summary
	print()
	print("=" * 80)
	print("TEST SUMMARY")
	print("=" * 80)

	for name, passed in results:
		status = "[OK] PASS" if passed else "[ERROR] FAIL"
		print(f"{status}  {name}")

	passed_count = sum(1 for _, p in results if p)
	total_count = len(results)

	print()
	print(f"Results: {passed_count}/{total_count} tests passed")

	if passed_count == total_count:
		print()
		print("[SUCCESS] ALL TESTS PASSED! Battle data pipeline is fully functional!")
		return 0
	else:
		print()
		print("[WARNING] Some tests failed. Please review the output above.")
		return 1

if __name__ == '__main__':
	sys.exit(main())
