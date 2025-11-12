#!/usr/bin/env python3
"""
ROM Test Patcher for Final Fantasy Mystic Quest
================================================

Creates test ROM patches to validate control code behavior.
Allows empirical testing of hypotheses via emulator observation.

Author: TheAnsarya
Date: 2025-11-12
License: MIT
"""

import struct
import shutil
from pathlib import Path
from typing import Dict, List, Tuple, Optional


class ROMTestPatcher:
	"""Creates test ROM patches for control code validation."""
	
	def __init__(self, rom_path: str, output_dir: str = "roms/test"):
		"""
		Initialize ROM patcher.
		
		Args:
			rom_path: Path to source ROM file
			output_dir: Directory for test ROMs
		"""
		self.rom_path = Path(rom_path)
		self.output_dir = Path(output_dir)
		self.output_dir.mkdir(parents=True, exist_ok=True)
		
		self.rom: bytearray = bytearray()
		
		# Dialog storage locations (from disassembly)
		self.DIALOG_BASE = 0x03BA35  # Dictionary/dialog data start
		
		# Test dialog addresses (find unused space)
		self.TEST_DIALOG_ADDR = 0x03F000  # Safe area near end of bank
		
		# Character encoding (from simple.tbl)
		self.char_map = self._build_char_map()
	
	def _build_char_map(self) -> Dict[str, int]:
		"""Build character encoding map from simple.tbl."""
		char_map = {}
		
		# Basic ASCII mapping (0x80-0xFF range)
		# A-Z
		for i, c in enumerate("ABCDEFGHIJKLMNOPQRSTUVWXYZ"):
			char_map[c] = 0x80 + i
		
		# a-z
		for i, c in enumerate("abcdefghijklmnopqrstuvwxyz"):
			char_map[c] = 0x9A + i
		
		# 0-9
		for i, c in enumerate("0123456789"):
			char_map[c] = 0xB4 + i
		
		# Special characters
		char_map[' '] = 0xBE
		char_map[','] = 0xBF
		char_map['.'] = 0xC0
		char_map['!'] = 0xC1
		char_map['?'] = 0xC2
		char_map[':'] = 0xC3
		char_map[';'] = 0xC4
		char_map['-'] = 0xC5
		char_map['\''] = 0xC6
		char_map['"'] = 0xC7
		
		return char_map
	
	def load_rom(self) -> None:
		"""Load source ROM into memory."""
		with open(self.rom_path, 'rb') as f:
			self.rom = bytearray(f.read())
		
		print(f"Loaded ROM: {self.rom_path.name} ({len(self.rom)} bytes)")
	
	def encode_text(self, text: str) -> bytes:
		"""
		Encode text string to ROM format.
		
		Args:
			text: Text to encode
		
		Returns:
			Encoded bytes
		"""
		encoded = bytearray()
		
		for char in text:
			if char in self.char_map:
				encoded.append(self.char_map[char])
			else:
				# Unknown character - use space
				encoded.append(self.char_map.get(' ', 0xBE))
		
		return bytes(encoded)
	
	def create_test_dialog(self, text: str, control_codes: Optional[List[Tuple[int, bytes]]] = None) -> bytes:
		"""
		Create test dialog with specified control codes.
		
		Args:
			text: Dialog text
			control_codes: List of (position, code_bytes) tuples
		
		Returns:
			Complete dialog data
		"""
		dialog = bytearray()
		
		# Encode base text
		encoded_text = self.encode_text(text)
		
		# Insert control codes at specified positions
		if control_codes:
			text_list = list(encoded_text)
			
			# Sort by position (reverse to maintain positions)
			for pos, code_bytes in sorted(control_codes, reverse=True):
				if pos <= len(text_list):
					text_list[pos:pos] = code_bytes
			
			dialog.extend(text_list)
		else:
			dialog.extend(encoded_text)
		
		# Add END code (0x00)
		dialog.append(0x00)
		
		return bytes(dialog)
	
	def write_dialog_to_rom(self, dialog_data: bytes, address: int) -> None:
		"""
		Write dialog data to ROM at specified address.
		
		Args:
			dialog_data: Dialog bytes to write
			address: ROM address to write to
		"""
		if address + len(dialog_data) > len(self.rom):
			raise ValueError(f"Dialog too large for ROM space at 0x{address:06X}")
		
		self.rom[address:address + len(dialog_data)] = dialog_data
		
		print(f"  Wrote {len(dialog_data)} bytes to ROM at 0x{address:06X}")
	
	def patch_dialog_pointer(self, dialog_id: int, new_address: int) -> None:
		"""
		Redirect dialog pointer to test dialog.
		
		Args:
			dialog_id: Dialog ID to redirect (0-116)
			new_address: New dialog address
		"""
		# Dialog pointer table at 0x03B9C3 (117 entries x 3 bytes each)
		pointer_table_base = 0x03B9C3
		pointer_offset = pointer_table_base + (dialog_id * 3)
		
		# Convert to 24-bit SNES address
		bank = (new_address >> 16) & 0xFF
		addr = new_address & 0xFFFF
		
		# Write pointer (little-endian: low, high, bank)
		self.rom[pointer_offset] = addr & 0xFF
		self.rom[pointer_offset + 1] = (addr >> 8) & 0xFF
		self.rom[pointer_offset + 2] = bank
		
		print(f"  Redirected Dialog #{dialog_id} to 0x{new_address:06X}")
	
	def save_test_rom(self, output_name: str) -> Path:
		"""
		Save modified ROM to output directory.
		
		Args:
			output_name: Name for test ROM
		
		Returns:
			Path to saved ROM
		"""
		output_path = self.output_dir / output_name
		
		with open(output_path, 'wb') as f:
			f.write(self.rom)
		
		print(f"  Saved test ROM: {output_path}")
		return output_path
	
	# ============================================================================
	# Test Scenarios
	# ============================================================================
	
	def test_formatting_codes_0x1D_vs_0x1E(self) -> Path:
		"""
		Test difference between codes 0x1D and 0x1E.
		Both are used with dictionary entries 0x50 and 0x51.
		
		Hypothesis: Different formatting for equipment names.
		
		Returns:
			Path to test ROM
		"""
		print("\n" + "="*80)
		print("TEST: Formatting Codes 0x1D vs 0x1E")
		print("="*80)
		
		self.load_rom()
		
		# Test Dialog 1: Using 0x1D with dictionary 0x50
		test_addr_1 = self.TEST_DIALOG_ADDR
		dialog_1 = bytearray()
		dialog_1.extend(self.encode_text("Test 1D: "))
		dialog_1.append(0x1D)  # FORMAT_ITEM_E1
		dialog_1.append(0x00)  # Parameter
		dialog_1.append(0x50)  # Dictionary entry 0x50
		dialog_1.append(0x01)  # NEWLINE
		dialog_1.extend(self.encode_text("Test 1E: "))
		dialog_1.append(0x1E)  # FORMAT_ITEM_E2
		dialog_1.append(0x00)  # Parameter
		dialog_1.append(0x51)  # Dictionary entry 0x51
		dialog_1.append(0x00)  # END
		
		self.write_dialog_to_rom(bytes(dialog_1), test_addr_1)
		
		# Redirect Dialog #0 (opening dialog) to test
		self.patch_dialog_pointer(0, test_addr_1)
		
		output = self.save_test_rom("test_format_1d_vs_1e.sfc")
		
		print("\nEXPECTED RESULT:")
		print("  - Different formatting/display for 0x1D vs 0x1E")
		print("  - Check equipment name presentation")
		print("  - Note visual differences\n")
		
		return output
	
	def test_memory_write_0x0E(self) -> Path:
		"""
		Test Code 0x0E: Memory write operation.
		
		Hypothesis: Writes 16-bit value to memory address.
		
		Returns:
			Path to test ROM
		"""
		print("\n" + "="*80)
		print("TEST: Memory Write Code 0x0E")
		print("="*80)
		
		self.load_rom()
		
		# Test Dialog: Use 0x0E to write to visible memory
		test_addr = self.TEST_DIALOG_ADDR
		dialog = bytearray()
		dialog.extend(self.encode_text("Memory write test"))
		dialog.append(0x01)  # NEWLINE
		
		# Code 0x0E: Write 0xABCD to address 0x0100 (safe RAM area)
		dialog.append(0x0E)  # MEMORY_WRITE
		dialog.append(0x00)  # Address low
		dialog.append(0x01)  # Address high (0x0100)
		dialog.append(0xCD)  # Value low
		dialog.append(0xAB)  # Value high (0xABCD)
		
		dialog.extend(self.encode_text("Value written"))
		dialog.append(0x00)  # END
		
		self.write_dialog_to_rom(bytes(dialog), test_addr)
		self.patch_dialog_pointer(0, test_addr)
		
		output = self.save_test_rom("test_memory_write_0e.sfc")
		
		print("\nEXPECTED RESULT:")
		print("  - Dialog displays normally")
		print("  - Memory address 0x0100 contains 0xABCD")
		print("  - Use emulator memory viewer to verify\n")
		
		return output
	
	def test_subroutine_call_0x08(self) -> Path:
		"""
		Test Code 0x08: Dialog subroutine call.
		
		Hypothesis: Executes dialog fragment at pointer address.
		
		Returns:
			Path to test ROM
		"""
		print("\n" + "="*80)
		print("TEST: Subroutine Call Code 0x08")
		print("="*80)
		
		self.load_rom()
		
		# Create subroutine dialog
		subroutine_addr = self.TEST_DIALOG_ADDR + 0x100
		subroutine = bytearray()
		subroutine.extend(self.encode_text("SUBROUTINE TEXT"))
		subroutine.append(0x00)  # END (returns to caller)
		
		self.write_dialog_to_rom(bytes(subroutine), subroutine_addr)
		
		# Create main dialog that calls subroutine
		main_addr = self.TEST_DIALOG_ADDR
		dialog = bytearray()
		dialog.extend(self.encode_text("Before call: "))
		
		# Code 0x08: Call subroutine
		dialog.append(0x08)  # SUBROUTINE_CALL
		# 24-bit pointer to subroutine (little-endian)
		dialog.append((subroutine_addr >> 0) & 0xFF)   # Low byte
		dialog.append((subroutine_addr >> 8) & 0xFF)   # High byte
		
		dialog.append(0x01)  # NEWLINE
		dialog.extend(self.encode_text("After call"))
		dialog.append(0x00)  # END
		
		self.write_dialog_to_rom(bytes(dialog), main_addr)
		self.patch_dialog_pointer(0, main_addr)
		
		output = self.save_test_rom("test_subroutine_0x08.sfc")
		
		print("\nEXPECTED RESULT:")
		print("  - Dialog shows: 'Before call: SUBROUTINE TEXT'")
		print("  - Then: 'After call'")
		print("  - Confirms nested execution\n")
		
		return output
	
	def test_equipment_slot_detection(self) -> Path:
		"""
		Test equipment slot detection (0x10 vs 0x17 vs 0x18).
		
		Hypothesis: Different codes access different name tables.
		
		Returns:
			Path to test ROM
		"""
		print("\n" + "="*80)
		print("TEST: Equipment Slot Detection (0x10, 0x17, 0x18)")
		print("="*80)
		
		self.load_rom()
		
		test_addr = self.TEST_DIALOG_ADDR
		dialog = bytearray()
		
		# Test 0x10: General item
		dialog.extend(self.encode_text("Item 10: "))
		dialog.append(0x10)  # INSERT_ITEM_NAME
		dialog.append(0x00)  # Index 0
		dialog.append(0x01)  # NEWLINE
		
		# Test 0x17: Weapon
		dialog.extend(self.encode_text("Weapon 17: "))
		dialog.append(0x17)  # INSERT_WEAPON_NAME
		dialog.append(0x00)  # Index 0
		dialog.append(0x01)  # NEWLINE
		
		# Test 0x18: Armor
		dialog.extend(self.encode_text("Armor 18: "))
		dialog.append(0x18)  # INSERT_ARMOR_NAME
		dialog.append(0x00)  # Index 0 (uses register)
		
		dialog.append(0x00)  # END
		
		self.write_dialog_to_rom(bytes(dialog), test_addr)
		self.patch_dialog_pointer(0, test_addr)
		
		output = self.save_test_rom("test_equipment_slots.sfc")
		
		print("\nEXPECTED RESULT:")
		print("  - Three different item names displayed")
		print("  - 0x10: Consumable item name")
		print("  - 0x17: Weapon name")
		print("  - 0x18: Armor name")
		print("  - Confirms different table access\n")
		
		return output
	
	def test_unused_codes_0x15_0x19(self) -> Path:
		"""
		Test unused codes 0x15 and 0x19.
		
		Hypothesis: May still be functional but unused in game.
		
		Returns:
			Path to test ROM
		"""
		print("\n" + "="*80)
		print("TEST: Unused Codes 0x15 and 0x19")
		print("="*80)
		
		self.load_rom()
		
		test_addr = self.TEST_DIALOG_ADDR
		dialog = bytearray()
		
		dialog.extend(self.encode_text("Before 15"))
		dialog.append(0x01)  # NEWLINE
		
		# Test 0x15: INSERT_NUMBER?
		dialog.append(0x15)  # Unused code
		dialog.append(0x2A)  # Parameter low
		dialog.append(0x00)  # Parameter high (42 decimal)
		
		dialog.append(0x01)  # NEWLINE
		dialog.extend(self.encode_text("After 15"))
		dialog.append(0x01)  # NEWLINE
		
		dialog.extend(self.encode_text("Testing 19"))
		dialog.append(0x01)  # NEWLINE
		
		# Test 0x19: INSERT_ACCESSORY?
		dialog.append(0x19)  # Unused code
		
		dialog.append(0x01)  # NEWLINE
		dialog.extend(self.encode_text("Complete"))
		dialog.append(0x00)  # END
		
		self.write_dialog_to_rom(bytes(dialog), test_addr)
		self.patch_dialog_pointer(0, test_addr)
		
		output = self.save_test_rom("test_unused_codes.sfc")
		
		print("\nEXPECTED RESULT:")
		print("  - Code 0x15: May display number '42'")
		print("  - Code 0x19: May display accessory name")
		print("  - Or: May crash/freeze if truly non-functional")
		print("  - Or: May display garbage/nothing\n")
		
		return output
	
	def run_all_tests(self) -> None:
		"""Run all test scenarios and generate test ROMs."""
		print("="*80)
		print("ROM Test Suite - Generating All Test ROMs")
		print("="*80)
		
		tests = [
			self.test_formatting_codes_0x1D_vs_0x1E,
			self.test_memory_write_0x0E,
			self.test_subroutine_call_0x08,
			self.test_equipment_slot_detection,
			self.test_unused_codes_0x15_0x19,
		]
		
		test_roms = []
		for test_func in tests:
			try:
				rom_path = test_func()
				test_roms.append(rom_path)
			except Exception as e:
				print(f"\nERROR in {test_func.__name__}: {e}\n")
		
		print("\n" + "="*80)
		print("Test ROM Generation Complete")
		print("="*80)
		print(f"\nGenerated {len(test_roms)} test ROMs:")
		for rom in test_roms:
			print(f"  - {rom.name}")
		
		print("\nNEXT STEPS:")
		print("1. Load test ROMs in emulator (bsnes-plus, Mesen-S)")
		print("2. Observe dialog behavior at game start")
		print("3. Use memory viewer for code 0x0E test")
		print("4. Document findings in test results file")
		print("5. Update CONTROL_CODE_IDENTIFICATION.md with confirmed behaviors\n")


def main():
	"""Main entry point."""
	import argparse
	
	parser = argparse.ArgumentParser(
		description="Create ROM test patches for control code validation"
	)
	parser.add_argument(
		"rom",
		help="Path to source ROM file",
		nargs='?',
		default="roms/Final Fantasy - Mystic Quest (U) (V1.1).sfc"
	)
	parser.add_argument(
		"--output-dir",
		help="Directory for test ROMs",
		default="roms/test"
	)
	parser.add_argument(
		"--test",
		help="Run specific test (formatting, memory, subroutine, equipment, unused, all)",
		default="all"
	)
	
	args = parser.parse_args()
	
	patcher = ROMTestPatcher(args.rom, args.output_dir)
	
	if args.test == "all":
		patcher.run_all_tests()
	elif args.test == "formatting":
		patcher.test_formatting_codes_0x1D_vs_0x1E()
	elif args.test == "memory":
		patcher.test_memory_write_0x0E()
	elif args.test == "subroutine":
		patcher.test_subroutine_call_0x08()
	elif args.test == "equipment":
		patcher.test_equipment_slot_detection()
	elif args.test == "unused":
		patcher.test_unused_codes_0x15_0x19()
	else:
		print(f"Unknown test: {args.test}")
		print("Available tests: formatting, memory, subroutine, equipment, unused, all")


if __name__ == "__main__":
	main()
