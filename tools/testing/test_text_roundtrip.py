#!/usr/bin/env python3
"""
Round-Trip Validation Testing for FFMQ Text System

Tests the complete workflow: extract → modify → re-insert → verify
Ensures text system works correctly without data corruption.

Author: FFMQ Disassembly Project
Date: 2025-01-24
"""

import os
import sys
import hashlib
from pathlib import Path

# Add tools to path
sys.path.insert(0, str(Path(__file__).parent.parent))

def md5_file(filepath):
	"""Calculate MD5 hash of file."""
	hash_md5 = hashlib.md5()
	with open(filepath, "rb") as f:
		for chunk in iter(lambda: f.read(4096), b""):
			hash_md5.update(chunk)
	return hash_md5.hexdigest()

def compare_rom_regions(original_rom, modified_rom, regions):
	"""
	Compare specific ROM regions between two files.
	
	Args:
		original_rom: Path to original ROM
		modified_rom: Path to modified ROM
		regions: List of (name, start_offset, end_offset) tuples
	
	Returns:
		dict: Comparison results for each region
	"""
	results = {}
	
	with open(original_rom, 'rb') as f1, open(modified_rom, 'rb') as f2:
		original_data = f1.read()
		modified_data = f2.read()
	
	for name, start, end in regions:
		original_region = original_data[start:end]
		modified_region = modified_data[start:end]
		
		identical = original_region == modified_region
		diff_bytes = sum(1 for a, b in zip(original_region, modified_region) if a != b)
		
		results[name] = {
			'identical': identical,
			'diff_bytes': diff_bytes,
			'size': end - start
		}
	
	return results

def test_simple_text_roundtrip():
	"""
	Test 1: Simple Text Round-Trip
	
	Extract all simple text, re-insert without changes, verify ROM identical.
	"""
	print("\n" + "="*70)
	print("TEST 1: Simple Text Round-Trip (No Modifications)")
	print("="*70)
	
	# Import extraction tools
	try:
		from tools.extraction.extract_simple_text import extract_simple_text
		from tools.extraction.import_simple_text import import_simple_text
	except ImportError as e:
		print(f"❌ SKIP: Missing tools - {e}")
		return False
	
	# Paths
	original_rom = "roms/ffmq.sfc"
	temp_rom = "build/temp_test_simple.sfc"
	output_txt = "build/simple_text_test.txt"
	
	if not os.path.exists(original_rom):
		print(f"❌ SKIP: Original ROM not found at {original_rom}")
		return False
	
	try:
		# Step 1: Extract simple text
		print("\n[1/4] Extracting simple text...")
		extract_simple_text(original_rom, output_txt)
		print(f"✅ Extracted to {output_txt}")
		
		# Step 2: Copy original ROM
		print("\n[2/4] Creating working copy...")
		import shutil
		shutil.copy(original_rom, temp_rom)
		print(f"✅ Copied to {temp_rom}")
		
		# Step 3: Re-insert unchanged text
		print("\n[3/4] Re-inserting unchanged text...")
		import_simple_text(output_txt, temp_rom)
		print(f"✅ Re-inserted to {temp_rom}")
		
		# Step 4: Compare ROMs
		print("\n[4/4] Comparing ROMs...")
		original_hash = md5_file(original_rom)
		modified_hash = md5_file(temp_rom)
		
		if original_hash == modified_hash:
			print(f"✅ PASS: ROMs identical (MD5: {original_hash[:8]}...)")
			return True
		else:
			print(f"❌ FAIL: ROMs differ!")
			print(f"   Original: {original_hash}")
			print(f"   Modified: {modified_hash}")
			
			# Show which regions changed
			regions = [
				("Simple Text Data", 0x06F000, 0x070000),  # Bank $06
				("Entire ROM", 0, os.path.getsize(original_rom))
			]
			results = compare_rom_regions(original_rom, temp_rom, regions)
			
			for name, result in results.items():
				print(f"   {name}: {result['diff_bytes']} bytes differ (size: {result['size']})")
			
			return False
		
	except Exception as e:
		print(f"❌ ERROR: {e}")
		import traceback
		traceback.print_exc()
		return False
	
	finally:
		# Cleanup
		if os.path.exists(temp_rom):
			os.remove(temp_rom)
		if os.path.exists(output_txt):
			os.remove(output_txt)

def test_complex_text_roundtrip():
	"""
	Test 2: Complex Text Round-Trip
	
	Extract all dialogs, re-insert without changes, verify ROM identical.
	"""
	print("\n" + "="*70)
	print("TEST 2: Complex Text Round-Trip (No Modifications)")
	print("="*70)
	
	# Import extraction tools
	try:
		from tools.extraction.extract_dictionary import extract_all_dialogs
		from tools.extraction.import_complex_text import insert_dialogs_into_rom
	except ImportError as e:
		print(f"❌ SKIP: Missing tools - {e}")
		return False
	
	# Paths
	original_rom = "roms/ffmq.sfc"
	temp_rom = "build/temp_test_complex.sfc"
	output_txt = "build/complex_text_test.txt"
	
	if not os.path.exists(original_rom):
		print(f"❌ SKIP: Original ROM not found at {original_rom}")
		return False
	
	try:
		# Step 1: Extract complex text
		print("\n[1/4] Extracting dialogs...")
		dialogs = extract_all_dialogs(original_rom)
		
		# Save to file
		with open(output_txt, 'w', encoding='utf-8') as f:
			for i, dialog in enumerate(dialogs):
				f.write(f"### Dialog 0x{i:02X}\n")
				f.write(dialog)
				f.write("\n\n")
		
		print(f"✅ Extracted {len(dialogs)} dialogs to {output_txt}")
		
		# Step 2: Copy original ROM
		print("\n[2/4] Creating working copy...")
		import shutil
		shutil.copy(original_rom, temp_rom)
		print(f"✅ Copied to {temp_rom}")
		
		# Step 3: Re-insert unchanged text
		print("\n[3/4] Re-inserting unchanged dialogs...")
		insert_dialogs_into_rom(output_txt, temp_rom)
		print(f"✅ Re-inserted to {temp_rom}")
		
		# Step 4: Compare dialog regions
		print("\n[4/4] Comparing dialog regions...")
		
		regions = [
			("Dialog Data", 0x01A000, 0x01B835),  # Main dialog data
			("Pointer Table", 0x01B835, 0x01B8FF),  # Dialog pointers
			("Dictionary", 0x01BA35, 0x01BBFF),  # Dictionary data
		]
		
		results = compare_rom_regions(original_rom, temp_rom, regions)
		
		all_identical = all(r['identical'] for r in results.values())
		
		if all_identical:
			print(f"✅ PASS: All dialog regions identical")
			for name, result in results.items():
				print(f"   {name}: ✅ {result['size']} bytes unchanged")
			return True
		else:
			print(f"❌ FAIL: Some regions differ!")
			for name, result in results.items():
				status = "✅" if result['identical'] else "❌"
				print(f"   {status} {name}: {result['diff_bytes']}/{result['size']} bytes differ")
			return False
		
	except Exception as e:
		print(f"❌ ERROR: {e}")
		import traceback
		traceback.print_exc()
		return False
	
	finally:
		# Cleanup
		if os.path.exists(temp_rom):
			os.remove(temp_rom)
		if os.path.exists(output_txt):
			os.remove(output_txt)

def test_dialog_modification():
	"""
	Test 3: Dialog Modification
	
	Extract dialog, modify (same size), re-insert, verify changes applied.
	"""
	print("\n" + "="*70)
	print("TEST 3: Dialog Modification (Same Size)")
	print("="*70)
	
	# Import extraction tools
	try:
		from tools.extraction.extract_dictionary import extract_dialog, extract_all_dialogs
		from tools.extraction.import_complex_text import insert_dialogs_into_rom
	except ImportError as e:
		print(f"❌ SKIP: Missing tools - {e}")
		return False
	
	# Paths
	original_rom = "roms/ffmq.sfc"
	temp_rom = "build/temp_test_modified.sfc"
	output_txt = "build/modified_dialog_test.txt"
	
	if not os.path.exists(original_rom):
		print(f"❌ SKIP: Original ROM not found at {original_rom}")
		return False
	
	try:
		# Step 1: Extract all dialogs
		print("\n[1/5] Extracting dialogs...")
		dialogs = extract_all_dialogs(original_rom)
		print(f"✅ Extracted {len(dialogs)} dialogs")
		
		# Step 2: Modify dialog 0x00 (keep same size)
		print("\n[2/5] Modifying dialog 0x00...")
		original_dialog = dialogs[0]
		modified_dialog = "TEST TEXT FOR VALIDATION[END]"
		
		print(f"   Original: {original_dialog[:50]}...")
		print(f"   Modified: {modified_dialog}")
		
		dialogs[0] = modified_dialog
		
		# Save modified dialogs
		with open(output_txt, 'w', encoding='utf-8') as f:
			for i, dialog in enumerate(dialogs):
				f.write(f"### Dialog 0x{i:02X}\n")
				f.write(dialog)
				f.write("\n\n")
		
		# Step 3: Copy ROM
		print("\n[3/5] Creating working copy...")
		import shutil
		shutil.copy(original_rom, temp_rom)
		
		# Step 4: Re-insert modified text
		print("\n[4/5] Re-inserting modified dialogs...")
		insert_dialogs_into_rom(output_txt, temp_rom)
		print(f"✅ Re-inserted to {temp_rom}")
		
		# Step 5: Verify modification
		print("\n[5/5] Verifying modification...")
		extracted_modified = extract_dialog(temp_rom, 0)
		
		if extracted_modified == modified_dialog:
			print(f"✅ PASS: Modification verified")
			print(f"   Expected: {modified_dialog}")
			print(f"   Got:      {extracted_modified}")
			return True
		else:
			print(f"❌ FAIL: Modification not applied correctly!")
			print(f"   Expected: {modified_dialog}")
			print(f"   Got:      {extracted_modified}")
			return False
		
	except Exception as e:
		print(f"❌ ERROR: {e}")
		import traceback
		traceback.print_exc()
		return False
	
	finally:
		# Cleanup
		if os.path.exists(temp_rom):
			os.remove(temp_rom)
		if os.path.exists(output_txt):
			os.remove(output_txt)

def test_dictionary_compression():
	"""
	Test 4: Dictionary Compression
	
	Verify dictionary compression works correctly.
	"""
	print("\n" + "="*70)
	print("TEST 4: Dictionary Compression")
	print("="*70)
	
	try:
		from tools.extraction.import_complex_text import encode_text, decode_bytes
		from tools.extraction.simple_table import SimpleTable
	except ImportError as e:
		print(f"❌ SKIP: Missing tools - {e}")
		return False
	
	try:
		# Load character table
		char_table = SimpleTable("simple.tbl")
		
		# Test cases
		test_cases = [
			("the the the", "Should compress 'the' (dict 0x41)"),
			("you you", "Should compress 'you' (dict 0x44)"),
			("Crystal", "Should compress 'Crystal' (dict 0x3D)"),
			("For years Mac's been studying a Prophecy", "Complex sentence"),
		]
		
		all_passed = True
		
		for text, description in test_cases:
			print(f"\n[Test] {description}")
			print(f"   Input:  {text}")
			
			# Encode
			encoded = encode_text(text, char_table)
			print(f"   Encoded: {len(encoded)} bytes - {' '.join(f'{b:02X}' for b in encoded)}")
			
			# Decode
			decoded = decode_bytes(encoded, char_table)
			print(f"   Decoded: {decoded}")
			
			# Verify
			if decoded == text:
				print(f"   ✅ PASS: Round-trip successful")
			else:
				print(f"   ❌ FAIL: Round-trip failed!")
				print(f"      Expected: {text}")
				print(f"      Got:      {decoded}")
				all_passed = False
		
		return all_passed
		
	except Exception as e:
		print(f"❌ ERROR: {e}")
		import traceback
		traceback.print_exc()
		return False

def test_size_validation():
	"""
	Test 5: Size Validation
	
	Verify size constraints are enforced.
	"""
	print("\n" + "="*70)
	print("TEST 5: Size Validation")
	print("="*70)
	
	try:
		from tools.extraction.import_complex_text import insert_dialogs_into_rom
	except ImportError as e:
		print(f"❌ SKIP: Missing tools - {e}")
		return False
	
	# Paths
	original_rom = "roms/ffmq.sfc"
	temp_rom = "build/temp_test_size.sfc"
	output_txt = "build/oversized_dialog_test.txt"
	
	if not os.path.exists(original_rom):
		print(f"❌ SKIP: Original ROM not found at {original_rom}")
		return False
	
	try:
		# Create oversized dialog
		print("\n[1/2] Creating oversized dialog...")
		oversized_text = "A" * 1000 + "[END]"  # Way too large
		
		with open(output_txt, 'w', encoding='utf-8') as f:
			f.write(f"### Dialog 0x00\n")
			f.write(oversized_text)
			f.write("\n\n")
		
		# Copy ROM
		print("\n[2/2] Attempting to insert oversized dialog...")
		import shutil
		shutil.copy(original_rom, temp_rom)
		
		# Try to insert (should fail or warn)
		try:
			insert_dialogs_into_rom(output_txt, temp_rom)
			print(f"⚠️ WARNING: No size validation detected!")
			print(f"   Tool should warn/error on oversized dialogs")
			return False
		except (ValueError, RuntimeError) as e:
			print(f"✅ PASS: Size validation working - {e}")
			return True
		
	except Exception as e:
		print(f"❌ ERROR: {e}")
		import traceback
		traceback.print_exc()
		return False
	
	finally:
		# Cleanup
		if os.path.exists(temp_rom):
			os.remove(temp_rom)
		if os.path.exists(output_txt):
			os.remove(output_txt)

def main():
	"""Run all round-trip validation tests."""
	print("╔" + "="*68 + "╗")
	print("║" + " "*16 + "FFMQ Text System Round-Trip Validation" + " "*14 + "║")
	print("╚" + "="*68 + "╝")
	
	# Ensure build directory exists
	os.makedirs("build", exist_ok=True)
	
	# Run all tests
	tests = [
		("Simple Text Round-Trip", test_simple_text_roundtrip),
		("Complex Text Round-Trip", test_complex_text_roundtrip),
		("Dialog Modification", test_dialog_modification),
		("Dictionary Compression", test_dictionary_compression),
		("Size Validation", test_size_validation),
	]
	
	results = {}
	for name, test_func in tests:
		try:
			results[name] = test_func()
		except Exception as e:
			print(f"\n❌ EXCEPTION in {name}: {e}")
			import traceback
			traceback.print_exc()
			results[name] = False
	
	# Summary
	print("\n" + "="*70)
	print("SUMMARY")
	print("="*70)
	
	passed = sum(1 for r in results.values() if r)
	total = len(results)
	
	for name, result in results.items():
		status = "✅ PASS" if result else "❌ FAIL"
		print(f"{status}: {name}")
	
	print(f"\nTotal: {passed}/{total} tests passed ({passed*100//total}%)")
	
	if passed == total:
		print("\n🎉 All tests passed! Text system is working correctly.")
		return 0
	else:
		print(f"\n⚠️ {total - passed} test(s) failed. Review output above.")
		return 1

if __name__ == "__main__":
	sys.exit(main())
