#!/usr/bin/env python3
"""
FFMQ Dialog System - Test Suite
Comprehensive tests for dialog text, database, and event scripts
"""

import unittest
import sys
from pathlib import Path
from typing import List

# Add utils to path
sys.path.insert(0, str(Path(__file__).parent.parent / 'utils'))

from dialog_text import (
	DialogText, CharacterTable, ControlCode,
	decode_dialog, encode_dialog, validate_dialog
)
from dialog_database import DialogDatabase, DialogEntry
from event_script import EventScriptEngine, EventScript, CommandCategory


class TestCharacterTable(unittest.TestCase):
	"""Test character encoding/decoding"""

	def setUp(self):
		"""Set up test character table"""
		self.char_table = CharacterTable()

	def test_default_mapping_created(self):
		"""Test that default character mapping is created"""
		self.assertTrue(self.char_table.loaded)
		self.assertGreater(len(self.char_table.byte_to_char), 0)

	def test_digit_encoding(self):
		"""Test digit encoding (0x90-0x99)"""
		for i in range(10):
			char = str(i)
			byte = self.char_table.encode_char(char)
			self.assertEqual(byte, 0x90 + i)
			self.assertEqual(self.char_table.decode_byte(byte), char)

	def test_uppercase_encoding(self):
		"""Test uppercase letter encoding (0x9A-0xB3)"""
		for i in range(26):
			char = chr(ord('A') + i)
			byte = self.char_table.encode_char(char)
			self.assertEqual(byte, 0x9A + i)
			self.assertEqual(self.char_table.decode_byte(byte), char)

	def test_lowercase_encoding(self):
		"""Test lowercase letter encoding (0xB4-0xCD)"""
		for i in range(26):
			char = chr(ord('a') + i)
			byte = self.char_table.encode_char(char)
			self.assertEqual(byte, 0xB4 + i)
			self.assertEqual(self.char_table.decode_byte(byte), char)

	def test_special_characters(self):
		"""Test special character encoding from complex.tbl"""
		# These are in complex.tbl with specific byte values
		specials = {
			' ': 0x06,    # Space
			'!': 0xCE,    # Exclamation
			'?': 0xCF,    # Question
			',': 0xD0,    # Comma
			"'": 0xD1,    # Apostrophe
			'.': 0xD2,    # Period
			'-': 0xDA,    # Dash
			'&': 0xDB,    # Ampersand
		}

		for char, expected_byte in specials.items():
			byte = self.char_table.encode_char(char)
			self.assertEqual(byte, expected_byte, f"Character '{char}' should encode to 0x{expected_byte:02X}")
			decoded = self.char_table.decode_byte(expected_byte)
			self.assertEqual(decoded, char, f"Byte 0x{expected_byte:02X} should decode to '{char}'")


class TestDialogText(unittest.TestCase):
	"""Test dialog text encoding/decoding"""

	def setUp(self):
		"""Set up dialog text handler"""
		self.dialog_text = DialogText()

	def test_simple_text_encode_decode(self):
		"""Test encoding and decoding simple text with punctuation"""
		original = "Hello, World!"
		encoded = self.dialog_text.encode(original)
		decoded = self.dialog_text.decode(encoded)
		self.assertEqual(decoded, original)

	def test_control_codes_encode_decode(self):
		"""Test encoding and decoding control codes"""
		original = "Welcome\nPress A to continue[WAIT]"
		encoded = self.dialog_text.encode(original)
		decoded = self.dialog_text.decode(encoded)
		self.assertEqual(decoded, original)

	def test_newline_conversion(self):
		"""Test newline to control code conversion"""
		original = "Line 1\nLine 2\nLine 3"
		encoded = self.dialog_text.encode(original)
		decoded = self.dialog_text.decode(encoded)

		# Newlines should be preserved
		self.assertIn('\n', decoded)
		self.assertEqual(decoded.count('\n'), 2)

	def test_end_terminator_added(self):
		"""Test that END terminator is added"""
		text = "Test"
		encoded = self.dialog_text.encode(text)

		# Should end with 0x00
		self.assertEqual(encoded[-1], ControlCode.END)

	def test_metrics_calculation(self):
		"""Test dialog metrics calculation"""
		text = "Hello, World![WAIT]"
		metrics = self.dialog_text.calculate_metrics(text)

		self.assertGreater(metrics.byte_count, 0)
		self.assertEqual(metrics.char_count, 13)  # "Hello, World!"
		self.assertEqual(metrics.line_count, 1)
		self.assertIn('[WAIT]', metrics.control_codes)

	def test_validation_too_long(self):
		"""Test validation catches too-long dialogs"""
		# Create very long text
		text = "A" * 600  # Over 512 byte limit
		is_valid, messages = self.dialog_text.validate(text)

		self.assertFalse(is_valid)
		self.assertTrue(any("exceeds maximum length" in msg for msg in messages))

	def test_validation_unmatched_brackets(self):
		"""Test validation catches unmatched control code brackets"""
		text = "Hello [WAIT"  # Missing closing bracket
		is_valid, messages = self.dialog_text.validate(text)

		self.assertFalse(is_valid)
		self.assertTrue(any("Unmatched" in msg for msg in messages))

	def test_format_for_display(self):
		"""Test text formatting for display"""
		text = "This is a very long line that should be wrapped to fit the display width properly."
		lines = self.dialog_text.format_for_display(text, max_width=32)

		# Should be split into multiple lines
		self.assertGreater(len(lines), 1)

		# No line should exceed max width
		for line in lines:
			self.assertLessEqual(len(line), 32)

	def test_insert_control_code(self):
		"""Test inserting control codes"""
		text = "Hello World"
		result = self.dialog_text.insert_control_code(text, 5, ControlCode.WAIT)

		self.assertEqual(result, "Hello[WAIT] World")

	def test_sound_control_code(self):
		"""Test sound control code with parameter"""
		text = "[SOUND:1F]Test"
		encoded = self.dialog_text.encode(text)
		decoded = self.dialog_text.decode(encoded)

		self.assertIn('[SOUND:1F]', decoded)


class TestDialogDatabase(unittest.TestCase):
	"""Test dialog database operations"""

	def setUp(self):
		"""Set up test database"""
		self.db = DialogDatabase()

	def test_snes_to_pc_conversion(self):
		"""Test SNES address to PC address conversion"""
		# Bank $03, $8000 → PC $018000
		pc_addr = self.db.snes_to_pc(0x8000, bank=0x03)
		self.assertEqual(pc_addr, 0x018000)

		# Bank $03, $FFFF → PC $01FFFF
		pc_addr = self.db.snes_to_pc(0xFFFF, bank=0x03)
		self.assertEqual(pc_addr, 0x01FFFF)

	def test_pc_to_snes_conversion(self):
		"""Test PC address to SNES address conversion"""
		# PC $018000 → Bank $03, $8000
		bank, snes_addr = self.db.pc_to_snes(0x018000)
		self.assertEqual(bank, 0x03)
		self.assertEqual(snes_addr, 0x8000)

	def test_dialog_entry_to_dict(self):
		"""Test DialogEntry serialization"""
		entry = DialogEntry(
			id=42,
			text="Test dialog",
			raw_bytes=bytearray([0x9A, 0xB8, 0xC6, 0x00]),
			pointer=0x8000,
			address=0x018000,
			length=4,
			tags={'test', 'example'},
			notes="Test note"
		)

		data = entry.to_dict()

		self.assertEqual(data['id'], 42)
		self.assertEqual(data['text'], "Test dialog")
		self.assertIn('test', data['tags'])

	def test_dialog_entry_from_dict(self):
		"""Test DialogEntry deserialization"""
		data = {
			'id': 42,
			'text': "Test dialog",
			'bytes': "0x9A,0xB8,0xC6,0x00",
			'length': 4,
			'pointer': "0x8000",
			'address': "0x018000",
			'tags': ['test'],
			'notes': "Test note"
		}

		entry = DialogEntry.from_dict(data)

		self.assertEqual(entry.id, 42)
		self.assertEqual(entry.text, "Test dialog")
		self.assertEqual(entry.length, 4)
		self.assertIn('test', entry.tags)

	def test_search_dialogs(self):
		"""Test dialog search functionality"""
		# Create test dialogs
		dialogs = [
			DialogEntry(0, "Hello World", bytearray(), 0, 0, 0, tags={'greeting'}),
			DialogEntry(1, "Goodbye Friend", bytearray(), 0, 0, 0, tags={'farewell'}),
			DialogEntry(2, "Welcome to town", bytearray(), 0, 0, 0, tags={'greeting'}),
		]

		self.db.dialogs = {d.id: d for d in dialogs}

		# Search by text
		results = self.db.search_dialogs("Hello")
		self.assertEqual(len(results), 1)
		self.assertEqual(results[0].id, 0)

		# Search by tag
		results = self.db.search_dialogs("greeting")
		self.assertEqual(len(results), 2)


class TestEventScript(unittest.TestCase):
	"""Test event script parsing and generation"""

	def setUp(self):
		"""Set up event script engine"""
		self.engine = EventScriptEngine()

	def test_command_definitions_loaded(self):
		"""Test that command definitions are loaded"""
		self.assertGreater(len(self.engine.commands), 0)

		# Check specific commands exist
		self.assertIn(0x00, self.engine.commands)  # SHOW_DIALOG
		self.assertIn(0x10, self.engine.commands)  # JUMP
		self.assertIn(0x20, self.engine.commands)  # SET_FLAG
		self.assertIn(0xFF, self.engine.commands)  # END_SCRIPT

	def test_get_command_by_name(self):
		"""Test getting command by name"""
		cmd = self.engine.get_command_by_name("SHOW_DIALOG")
		self.assertIsNotNone(cmd)
		self.assertEqual(cmd.opcode, 0x00)

	def test_get_commands_by_category(self):
		"""Test getting commands by category"""
		dialog_cmds = self.engine.get_commands_by_category(CommandCategory.DIALOG)
		self.assertGreater(len(dialog_cmds), 0)

		# All should be dialog category
		for cmd in dialog_cmds:
			self.assertEqual(cmd.category, CommandCategory.DIALOG)

	def test_parse_simple_script(self):
		"""Test parsing simple event script"""
		bytecode = bytearray([
			0x00, 0x2D,          # SHOW_DIALOG(45)
			0x20, 0x0A,          # SET_FLAG(10)
			0xFF                 # END_SCRIPT
		])

		script = self.engine.parse_bytecode(bytecode, start_address=0x10000)

		self.assertEqual(len(script.commands), 3)
		self.assertEqual(script.commands[0].name, "SHOW_DIALOG")
		self.assertEqual(script.commands[0].parameters, [0x2D])
		self.assertEqual(script.commands[1].name, "SET_FLAG")
		self.assertEqual(script.commands[2].name, "END_SCRIPT")

	def test_parse_branch_script(self):
		"""Test parsing script with branches"""
		bytecode = bytearray([
			0x13, 0x0A, 0x10, 0x00,  # IF_FLAG(10, @0x0010)
			0x00, 0x01,              # SHOW_DIALOG(1)
			0xFF                     # END_SCRIPT
		])

		script = self.engine.parse_bytecode(bytecode)

		self.assertEqual(len(script.commands), 3)
		self.assertEqual(script.commands[0].name, "IF_FLAG")
		self.assertEqual(script.commands[0].flow_type, "branch")
		self.assertEqual(script.commands[0].parameters, [10, 0x0010])

	def test_generate_bytecode(self):
		"""Test generating bytecode from script"""
		# Parse script
		original = bytearray([0x00, 0x2D, 0x20, 0x0A, 0xFF])
		script = self.engine.parse_bytecode(original)

		# Generate bytecode
		generated = self.engine.generate_bytecode(script)

		# Should match original
		self.assertEqual(len(generated), len(original))

	def test_script_validation_missing_end(self):
		"""Test validation catches missing END_SCRIPT"""
		bytecode = bytearray([
			0x00, 0x2D,  # SHOW_DIALOG(45)
			0x20, 0x0A   # SET_FLAG(10)
			# Missing END_SCRIPT
		])

		script = self.engine.parse_bytecode(bytecode)
		is_valid, errors = self.engine.validate_script(script)

		self.assertFalse(is_valid)
		self.assertTrue(any("missing END_SCRIPT" in err for err in errors))

	def test_script_variable_tracking(self):
		"""Test that script tracks variables used"""
		bytecode = bytearray([
			0x00, 0x2D,              # SHOW_DIALOG(45)
			0x20, 0x0A,              # SET_FLAG(10)
			0x13, 0x0B, 0x10, 0x00,  # IF_FLAG(11, @0x0010)
			0x30, 0x05, 0x01,        # GIVE_ITEM(5, 1)
			0xFF                     # END_SCRIPT
		])

		script = self.engine.parse_bytecode(bytecode)

		# Check tracked variables
		self.assertIn(45, script.dialogs_used)
		self.assertIn(10, script.flags_set)
		self.assertIn(11, script.flags_checked)
		self.assertIn(5, script.items_used)

	def test_disassemble_script(self):
		"""Test script disassembly"""
		bytecode = bytearray([
			0x00, 0x2D,  # SHOW_DIALOG(45)
			0xFF         # END_SCRIPT
		])

		script = self.engine.parse_bytecode(bytecode, start_address=0x10000)
		disassembly = self.engine.disassemble(script)

		# Should contain readable assembly
		self.assertIn("SHOW_DIALOG", disassembly)
		self.assertIn("@", disassembly)
		self.assertIn("END_SCRIPT", disassembly)


class TestIntegration(unittest.TestCase):
	"""Integration tests for complete workflows"""

	def test_dialog_edit_workflow(self):
		"""Test complete dialog editing workflow"""
		# Create database
		db = DialogDatabase()
		dialog_text = DialogText()

		# Create test dialog with punctuation
		original_text = "Hello, World![WAIT]"
		encoded = dialog_text.encode(original_text)

		entry = DialogEntry(
			id=0,
			text=original_text,
			raw_bytes=encoded,
			pointer=0x8000,
			address=0x018000,
			length=len(encoded)
		)

		db.dialogs[0] = entry

		# Modify dialog
		new_text = "Goodbye, friend!\nSee you later![WAIT]"

		# Validate
		is_valid, messages = dialog_text.validate(new_text)
		self.assertTrue(is_valid)

		# Encode
		new_encoded = dialog_text.encode(new_text)

		# Update entry
		entry.text = new_text
		entry.raw_bytes = new_encoded
		entry.length = len(new_encoded)
		entry.modified = True

		# Verify
		decoded = dialog_text.decode(entry.raw_bytes)
		self.assertEqual(decoded, new_text)

	def test_script_and_dialog_integration(self):
		"""Test event script using dialog IDs"""
		engine = EventScriptEngine()

		# Create script that shows dialogs
		bytecode = bytearray([
			0x00, 0x01,  # SHOW_DIALOG(1)
			0x00, 0x02,  # SHOW_DIALOG(2)
			0xFF         # END_SCRIPT
		])

		script = engine.parse_bytecode(bytecode)

		# Verify dialogs are tracked
		self.assertIn(1, script.dialogs_used)
		self.assertIn(2, script.dialogs_used)

		# Could cross-reference with dialog database
		self.assertEqual(len(script.dialogs_used), 2)


def run_tests():
	"""Run all tests"""
	# Create test suite
	loader = unittest.TestLoader()
	suite = unittest.TestSuite()

	# Add all test classes
	suite.addTests(loader.loadTestsFromTestCase(TestCharacterTable))
	suite.addTests(loader.loadTestsFromTestCase(TestDialogText))
	suite.addTests(loader.loadTestsFromTestCase(TestDialogDatabase))
	suite.addTests(loader.loadTestsFromTestCase(TestEventScript))
	suite.addTests(loader.loadTestsFromTestCase(TestIntegration))

	# Run tests
	runner = unittest.TextTestRunner(verbosity=2)
	result = runner.run(suite)

	# Print summary
	print("\n" + "=" * 70)
	print(f"Tests run: {result.testsRun}")
	print(f"Successes: {result.testsRun - len(result.failures) - len(result.errors)}")
	print(f"Failures: {len(result.failures)}")
	print(f"Errors: {len(result.errors)}")
	print("=" * 70)

	return result.wasSuccessful()


if __name__ == '__main__':
	success = run_tests()
	sys.exit(0 if success else 1)
