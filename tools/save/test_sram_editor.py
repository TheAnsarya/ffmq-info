#!/usr/bin/env python3
"""
FFMQ SRAM Editor - Test Suite

Comprehensive tests for SRAM save file editor functionality.

Tests:
- SRAM file loading/saving
- Slot extraction/insertion
- Checksum calculation/verification
- Character data encoding/decoding
- JSON export/import
- Data validation and limits
- Error handling

Usage:
	python test_sram_editor.py
	python test_sram_editor.py -v  # Verbose output
"""

import sys
import unittest
import tempfile
import struct
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent))

from ffmq_sram_editor import (
	SRAMEditor, CharacterData, SaveSlot, StatusEffect
)


class TestCharacterData(unittest.TestCase):
	"""Test character data structures"""
	
	def test_character_defaults(self):
		"""Test default character creation"""
		char = CharacterData()
		
		self.assertEqual(char.name, "Benjamin")
		self.assertEqual(char.level, 1)
		self.assertEqual(char.experience, 0)
		self.assertEqual(char.current_hp, 50)
		self.assertEqual(char.max_hp, 50)
		self.assertEqual(char.status, 0)
		self.assertEqual(len(char.raw_data), 0x50)
	
	def test_character_stats(self):
		"""Test character stat values"""
		char = CharacterData(
			level=50,
			current_attack=75,
			current_defense=70,
			current_speed=80,
			current_magic=85
		)
		
		self.assertEqual(char.level, 50)
		self.assertEqual(char.current_attack, 75)
		self.assertEqual(char.current_defense, 70)
		self.assertEqual(char.current_speed, 80)
		self.assertEqual(char.current_magic, 85)


class TestSaveSlot(unittest.TestCase):
	"""Test save slot structures"""
	
	def test_slot_defaults(self):
		"""Test default save slot creation"""
		slot = SaveSlot()
		
		self.assertEqual(slot.slot_id, 0)
		self.assertFalse(slot.valid)
		self.assertEqual(slot.checksum, 0)
		self.assertEqual(slot.gold, 0)
		self.assertEqual(len(slot.raw_data), 0x38C)
	
	def test_slot_party_data(self):
		"""Test party data fields"""
		slot = SaveSlot(
			gold=500000,
			player_x=128,
			player_y=64,
			player_facing=2,
			map_id=15
		)
		
		self.assertEqual(slot.gold, 500000)
		self.assertEqual(slot.player_x, 128)
		self.assertEqual(slot.player_y, 64)
		self.assertEqual(slot.player_facing, 2)
		self.assertEqual(slot.map_id, 15)


class TestSRAMEditor(unittest.TestCase):
	"""Test SRAM editor functionality"""
	
	def setUp(self):
		"""Create test editor instance"""
		self.editor = SRAMEditor(verbose=False)
	
	def test_checksum_calculation(self):
		"""Test checksum calculation"""
		# Create test slot data
		slot_data = bytearray(0x38C)
		slot_data[0:4] = b'FF0!'  # Header
		slot_data[6:10] = b'TEST'  # Some data
		
		checksum = self.editor.calculate_checksum(slot_data)
		
		# Checksum should be sum of bytes 6+ masked to 16-bit
		expected = sum(slot_data[6:]) & 0xFFFF
		self.assertEqual(checksum, expected)
	
	def test_character_packing(self):
		"""Test character data packing/unpacking"""
		# Create test character
		char = CharacterData(
			name="TestChar",
			level=25,
			experience=50000,
			current_hp=300,
			max_hp=350,
			current_attack=45,
			base_attack=30
		)
		
		# Pack to bytes
		packed = self.editor.pack_character(char)
		self.assertEqual(len(packed), 0x50)
		
		# Unpack and verify
		unpacked = self.editor.extract_character(packed)
		self.assertEqual(unpacked.name, "TestChar")
		self.assertEqual(unpacked.level, 25)
		self.assertEqual(unpacked.experience, 50000)
		self.assertEqual(unpacked.current_hp, 300)
		self.assertEqual(unpacked.max_hp, 350)
		self.assertEqual(unpacked.current_attack, 45)
		self.assertEqual(unpacked.base_attack, 30)
	
	def test_value_clamping(self):
		"""Test value limits are enforced"""
		char = CharacterData(
			level=150,  # Over max (99)
			experience=99999999,  # Over max (9,999,999)
			current_hp=99999,  # Over max (65535)
			current_attack=200  # Over max (99)
		)
		
		packed = self.editor.pack_character(char)
		unpacked = self.editor.extract_character(packed)
		
		self.assertEqual(unpacked.level, 99)
		self.assertLessEqual(unpacked.experience, 9999999)
		self.assertLessEqual(unpacked.current_hp, 65535)
		self.assertEqual(unpacked.current_attack, 99)
	
	def test_create_empty_sram(self):
		"""Test creating empty SRAM"""
		self.editor.sram_data = bytearray(0x1FEC)
		
		# Initialize slot 1A with valid header
		offset = self.editor.SLOT_OFFSETS['1A']
		self.editor.sram_data[offset:offset+4] = b'FF0!'
		
		# Verify slot detection
		slot = self.editor.extract_slot('1A')
		self.assertIsNotNone(slot)
		self.assertTrue(slot.valid)
	
	def test_slot_offsets(self):
		"""Test all slot offsets are correct"""
		expected_offsets = {
			'1A': 0x0000, '2A': 0x038C, '3A': 0x0718,
			'1B': 0x0AA4, '2B': 0x0E30, '3B': 0x11BC,
			'1C': 0x154B, '2C': 0x18D4, '3C': 0x1C60
		}
		
		for slot_name, expected_offset in expected_offsets.items():
			actual_offset = self.editor.SLOT_OFFSETS.get(slot_name)
			self.assertEqual(actual_offset, expected_offset,
						   f"Slot {slot_name} offset mismatch")
	
	def test_play_time_encoding(self):
		"""Test play time encoding/decoding"""
		slot = SaveSlot(
			play_time_hours=12,
			play_time_minutes=34,
			play_time_seconds=56
		)
		
		# Create minimal SRAM with this slot
		self.editor.sram_data = bytearray(0x1FEC)
		self.editor.insert_slot(slot, '1A')
		
		# Extract and verify
		extracted = self.editor.extract_slot('1A')
		self.assertEqual(extracted.play_time_hours, 12)
		self.assertEqual(extracted.play_time_minutes, 34)
		self.assertEqual(extracted.play_time_seconds, 56)
	
	def test_gold_encoding(self):
		"""Test gold 24-bit encoding"""
		test_values = [0, 100, 9999, 500000, 9999999]
		
		for gold_value in test_values:
			slot = SaveSlot(gold=gold_value)
			
			self.editor.sram_data = bytearray(0x1FEC)
			self.editor.insert_slot(slot, '1A')
			
			extracted = self.editor.extract_slot('1A')
			self.assertEqual(extracted.gold, gold_value,
						   f"Gold encoding failed for {gold_value}")
	
	def test_position_encoding(self):
		"""Test position data encoding"""
		slot = SaveSlot(
			player_x=123,
			player_y=234,
			player_facing=3
		)
		
		self.editor.sram_data = bytearray(0x1FEC)
		self.editor.insert_slot(slot, '1A')
		
		extracted = self.editor.extract_slot('1A')
		self.assertEqual(extracted.player_x, 123)
		self.assertEqual(extracted.player_y, 234)
		self.assertEqual(extracted.player_facing, 3)


class TestSRAMFileOperations(unittest.TestCase):
	"""Test file I/O operations"""
	
	def setUp(self):
		"""Create test editor and temp directory"""
		self.editor = SRAMEditor(verbose=False)
		self.temp_dir = tempfile.TemporaryDirectory()
		self.temp_path = Path(self.temp_dir.name)
	
	def tearDown(self):
		"""Clean up temp directory"""
		self.temp_dir.cleanup()
	
	def test_save_load_roundtrip(self):
		"""Test saving and loading SRAM"""
		# Create test SRAM
		self.editor.sram_data = bytearray(0x1FEC)
		
		# Add test slot
		slot = SaveSlot(
			gold=12345,
			map_id=42
		)
		slot.character1.name = "Test"
		slot.character1.level = 30
		
		self.editor.insert_slot(slot, '1A')
		
		# Save to file
		sram_file = self.temp_path / "test.srm"
		self.assertTrue(self.editor.save_sram(sram_file))
		self.assertTrue(sram_file.exists())
		
		# Load from file
		editor2 = SRAMEditor(verbose=False)
		self.assertTrue(editor2.load_sram(sram_file))
		
		# Verify data
		extracted = editor2.extract_slot('1A')
		self.assertEqual(extracted.gold, 12345)
		self.assertEqual(extracted.map_id, 42)
		self.assertEqual(extracted.character1.name, "Test")
		self.assertEqual(extracted.character1.level, 30)
	
	def test_json_export_import(self):
		"""Test JSON export/import"""
		# Create test slot
		slot = SaveSlot(
			slot_id=0,
			gold=999999,
			map_id=15,
			player_x=100,
			player_y=50,
			cure_count=25
		)
		slot.character1.name = "Benjamin"
		slot.character1.level = 50
		slot.character1.experience = 500000
		
		# Export to JSON
		json_file = self.temp_path / "test_slot.json"
		self.assertTrue(self.editor.export_slot_json(slot, json_file))
		self.assertTrue(json_file.exists())
		
		# Import from JSON
		imported = self.editor.import_slot_json(json_file)
		self.assertIsNotNone(imported)
		
		# Verify data
		self.assertEqual(imported.gold, 999999)
		self.assertEqual(imported.map_id, 15)
		self.assertEqual(imported.player_x, 100)
		self.assertEqual(imported.player_y, 50)
		self.assertEqual(imported.cure_count, 25)
		self.assertEqual(imported.character1.name, "Benjamin")
		self.assertEqual(imported.character1.level, 50)
		self.assertEqual(imported.character1.experience, 500000)
	
	def test_checksum_verification(self):
		"""Test checksum verification"""
		# Create SRAM with valid slot
		self.editor.sram_data = bytearray(0x1FEC)
		
		slot = SaveSlot(gold=5000)
		self.editor.insert_slot(slot, '1A')
		
		# Should verify correctly
		self.assertTrue(self.editor.verify_slot('1A'))
		
		# Corrupt checksum
		offset = self.editor.SLOT_OFFSETS['1A']
		self.editor.sram_data[offset + 4] = 0xFF
		self.editor.sram_data[offset + 5] = 0xFF
		
		# Should fail verification
		self.assertFalse(self.editor.verify_slot('1A'))
		
		# Fix checksum
		self.editor.fix_checksum('1A')
		
		# Should verify again
		self.assertTrue(self.editor.verify_slot('1A'))


class TestDataValidation(unittest.TestCase):
	"""Test data validation and edge cases"""
	
	def setUp(self):
		"""Create test editor"""
		self.editor = SRAMEditor(verbose=False)
	
	def test_character_name_encoding(self):
		"""Test character name encoding"""
		test_names = [
			("Ben", "Ben"),
			("Benjamin", "Benjamin"),
			("12345678", "12345678"),  # Max length
			("TooLongName", "TooLongN"),  # Truncated
			("Test\x00\x00\x00\x00", "Test")  # Null padded
		]
		
		for input_name, expected in test_names:
			char = CharacterData(name=input_name)
			packed = self.editor.pack_character(char)
			unpacked = self.editor.extract_character(packed)
			
			self.assertEqual(unpacked.name, expected,
						   f"Name encoding failed for '{input_name}'")
	
	def test_status_effects(self):
		"""Test status effect handling"""
		# Test individual status effects
		char = CharacterData(status=StatusEffect.POISON.value)
		self.assertEqual(char.status, 0x01)
		
		char = CharacterData(status=StatusEffect.FATAL.value)
		self.assertEqual(char.status, 0x80)
		
		# Test combined effects (Poison + Dark)
		char = CharacterData(status=0x01 | 0x02)
		self.assertEqual(char.status, 0x03)
	
	def test_empty_slot_handling(self):
		"""Test handling of empty/invalid slots"""
		# Create SRAM with invalid slot
		self.editor.sram_data = bytearray(0x1FEC)
		# Don't write header - leave empty
		
		slot = self.editor.extract_slot('1A')
		self.assertIsNotNone(slot)
		self.assertFalse(slot.valid)
	
	def test_experience_limits(self):
		"""Test experience value limits"""
		# Max experience is 9,999,999 (24-bit)
		char = CharacterData(experience=9999999)
		packed = self.editor.pack_character(char)
		unpacked = self.editor.extract_character(packed)
		
		self.assertEqual(unpacked.experience, 9999999)
		
		# Test over-limit (should clamp)
		char = CharacterData(experience=99999999)
		packed = self.editor.pack_character(char)
		unpacked = self.editor.extract_character(packed)
		
		self.assertLessEqual(unpacked.experience, 9999999)


class TestEdgeCases(unittest.TestCase):
	"""Test edge cases and error conditions"""
	
	def test_invalid_slot_names(self):
		"""Test invalid slot name handling"""
		editor = SRAMEditor(verbose=False)
		editor.sram_data = bytearray(0x1FEC)
		
		# Invalid slot names should return None/False
		self.assertIsNone(editor.extract_slot('XX'))
		self.assertIsNone(editor.extract_slot('4A'))
		self.assertFalse(editor.verify_slot('invalid'))
	
	def test_no_sram_loaded(self):
		"""Test operations without loaded SRAM"""
		editor = SRAMEditor(verbose=False)
		
		# Should fail gracefully
		self.assertIsNone(editor.extract_slot('1A'))
		self.assertFalse(editor.verify_slot('1A'))
		self.assertFalse(editor.fix_checksum('1A'))
	
	def test_corrupted_header(self):
		"""Test corrupted slot header handling"""
		editor = SRAMEditor(verbose=False)
		editor.sram_data = bytearray(0x1FEC)
		
		# Write invalid header
		offset = editor.SLOT_OFFSETS['1A']
		editor.sram_data[offset:offset+4] = b'XXXX'
		
		slot = editor.extract_slot('1A')
		self.assertFalse(slot.valid)


def run_tests(verbosity=1):
	"""Run all tests"""
	# Create test suite
	loader = unittest.TestLoader()
	suite = unittest.TestSuite()
	
	# Add all test cases
	suite.addTests(loader.loadTestsFromTestCase(TestCharacterData))
	suite.addTests(loader.loadTestsFromTestCase(TestSaveSlot))
	suite.addTests(loader.loadTestsFromTestCase(TestSRAMEditor))
	suite.addTests(loader.loadTestsFromTestCase(TestSRAMFileOperations))
	suite.addTests(loader.loadTestsFromTestCase(TestDataValidation))
	suite.addTests(loader.loadTestsFromTestCase(TestEdgeCases))
	
	# Run tests
	runner = unittest.TextTestRunner(verbosity=verbosity)
	result = runner.run(suite)
	
	return result.wasSuccessful()


if __name__ == '__main__':
	import argparse
	
	parser = argparse.ArgumentParser(description='Run SRAM Editor tests')
	parser.add_argument('-v', '--verbose', action='store_true',
					   help='Verbose test output')
	
	args = parser.parse_args()
	
	verbosity = 2 if args.verbose else 1
	success = run_tests(verbosity)
	
	sys.exit(0 if success else 1)
