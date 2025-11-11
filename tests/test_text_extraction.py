#!/usr/bin/env python3
"""
Unit tests for text extraction and import systems

Tests:
	- Simple text extraction (items, spells, monsters)
	- Simple text import (round-trip verification)
	- Character table loading
	- Text encoding/decoding
"""

import sys
import json
import unittest
import tempfile
import csv
from pathlib import Path

# Add project root to path
project_dir = Path(__file__).parent.parent
sys.path.insert(0, str(project_dir / "tools"))
sys.path.insert(0, str(project_dir / "tools" / "import"))

from text.simple_text_decoder import SimpleTextDecoder
from extraction.extract_simple_text import SimpleTextExtractor, TextTableConfig
from import_simple_text import SimpleTextImporter


class TestCharacterTable(unittest.TestCase):
	"""Test character table loading and validation"""
	
	def setUp(self):
		"""Initialize decoder"""
		self.decoder = SimpleTextDecoder()
	
	def test_table_loaded(self):
		"""Test that character table loaded successfully"""
		self.assertIsNotNone(self.decoder.char_map)
		self.assertGreater(len(self.decoder.char_map), 0)
	
	def test_digit_mappings(self):
		"""Test digit character mappings (0x90-0x99)"""
		# 0x90 = '0', 0x99 = '9'
		self.assertEqual(self.decoder.char_map.get(0x90), '0')
		self.assertEqual(self.decoder.char_map.get(0x99), '9')
	
	def test_uppercase_mappings(self):
		"""Test uppercase letter mappings (0x9A-0xB3)"""
		# 0x9A = 'A', 0xB3 = 'Z'
		self.assertEqual(self.decoder.char_map.get(0x9A), 'A')
		self.assertEqual(self.decoder.char_map.get(0xB3), 'Z')
	
	def test_lowercase_mappings(self):
		"""Test lowercase letter mappings (0xB4-0xCD)"""
		# 0xB4 = 'a', 0xCD = 'z'
		self.assertEqual(self.decoder.char_map.get(0xB4), 'a')
		self.assertEqual(self.decoder.char_map.get(0xCD), 'z')
	
	def test_special_chars(self):
		"""Test special character mappings"""
		# Apostrophe, period, etc.
		self.assertEqual(self.decoder.char_map.get(0xCE), "'")


class TestTextEncoding(unittest.TestCase):
	"""Test text encoding and decoding"""
	
	def setUp(self):
		"""Initialize decoder"""
		self.decoder = SimpleTextDecoder()
	
	def test_encode_simple_word(self):
		"""Test encoding simple words"""
		# "Fire" = 0x9F 0xC3 0xC8 0xC1 0x00 ...
		encoded = self.decoder.encode("Fire", 12)
		self.assertEqual(len(encoded), 12)
		self.assertEqual(encoded[0], 0x9F)  # F
		self.assertEqual(encoded[1], 0xC3)  # i
		self.assertEqual(encoded[2], 0xC8)  # r
		self.assertEqual(encoded[3], 0xC1)  # e
		self.assertEqual(encoded[4], 0x00)  # terminator
	
	def test_encode_with_apostrophe(self):
		"""Test encoding words with apostrophe"""
		# "Giant's" contains apostrophe
		encoded = self.decoder.encode("Giant's", 12)
		self.assertIn(0xCE, encoded)  # Apostrophe byte
	
	def test_decode_simple_word(self):
		"""Test decoding simple words"""
		# "Exit" = 0x9E 0xCC 0xC3 0xC7 0x00
		data = bytes([0x9E, 0xCC, 0xC3, 0xC7, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF])
		decoded, _ = self.decoder.decode(data, 12)
		self.assertEqual(decoded, "Exit")
	
	def test_roundtrip_encoding(self):
		"""Test encode → decode round-trip"""
		words = ["Fire", "Cure", "Exit", "Thunder", "Basilisk", "Brownie"]
		
		for word in words:
			encoded = self.decoder.encode(word, 16)
			decoded, _ = self.decoder.decode(encoded, 16)
			self.assertEqual(decoded, word, f"Round-trip failed for '{word}'")


class TestSimpleTextExtraction(unittest.TestCase):
	"""Test simple text extraction from ROM"""
	
	@classmethod
	def setUpClass(cls):
		"""Find ROM file"""
		rom_paths = [
			project_dir / "roms" / "Final Fantasy - Mystic Quest (U) (V1.1).sfc",
			project_dir / "rom.sfc",
			project_dir / "ffmq.sfc",
		]
		
		cls.rom_path = None
		for path in rom_paths:
			if path.exists():
				cls.rom_path = path
				break
		
		if cls.rom_path is None:
			cls.skipTest(cls, "ROM file not found")
	
	def test_extractor_initialization(self):
		"""Test extractor can be initialized"""
		extractor = SimpleTextExtractor(self.rom_path)
		self.assertEqual(extractor.rom_path, self.rom_path)
	
	def test_rom_loading(self):
		"""Test ROM file loads successfully"""
		extractor = SimpleTextExtractor(self.rom_path)
		success = extractor.load_rom()
		self.assertTrue(success)
		self.assertIsNotNone(extractor.rom_data)
		self.assertEqual(len(extractor.rom_data), 524288)  # 512KB
	
	def test_table_configs(self):
		"""Test table configurations are valid"""
		extractor = SimpleTextExtractor(self.rom_path)
		
		self.assertGreater(len(extractor.TABLES), 0)
		
		for config in extractor.TABLES:
			self.assertIsInstance(config, TextTableConfig)
			self.assertGreater(config.address, 0)
			self.assertGreater(config.count, 0)
			self.assertGreater(config.entry_length, 0)
	
	def test_extract_spells(self):
		"""Test spell name extraction"""
		extractor = SimpleTextExtractor(self.rom_path)
		extractor.load_rom()
		
		# Find spell config
		spell_config = next((c for c in extractor.TABLES if c.name == 'spell_names'), None)
		self.assertIsNotNone(spell_config)
		
		# Extract spells
		spells = extractor.extract_table(spell_config)
		
		# Verify count
		self.assertEqual(len(spells), 32)
		
		# Verify known spells
		spell_texts = [s['text'] for s in spells]
		self.assertIn('Exit', spell_texts)
		self.assertIn('Cure', spell_texts)
		self.assertIn('Fire', spell_texts)
		self.assertIn('Thunder', spell_texts)
		self.assertIn('Meteor', spell_texts)
	
	def test_extract_monsters(self):
		"""Test monster name extraction"""
		extractor = SimpleTextExtractor(self.rom_path)
		extractor.load_rom()
		
		# Find monster config
		monster_config = next((c for c in extractor.TABLES if c.name == 'monster_names'), None)
		self.assertIsNotNone(monster_config)
		
		# Extract monsters
		monsters = extractor.extract_table(monster_config)
		
		# Verify we got monsters
		self.assertGreater(len(monsters), 0)
		
		# Verify known monsters
		monster_texts = [m['text'] for m in monsters]
		self.assertIn('Brownie', monster_texts)
		self.assertIn('Basilisk', monster_texts)


class TestSimpleTextImport(unittest.TestCase):
	"""Test simple text import to ROM"""
	
	@classmethod
	def setUpClass(cls):
		"""Find ROM file"""
		rom_paths = [
			project_dir / "roms" / "Final Fantasy - Mystic Quest (U) (V1.1).sfc",
			project_dir / "rom.sfc",
			project_dir / "ffmq.sfc",
		]
		
		cls.rom_path = None
		for path in rom_paths:
			if path.exists():
				cls.rom_path = path
				break
		
		if cls.rom_path is None:
			cls.skipTest(cls, "ROM file not found")
	
	def test_importer_initialization(self):
		"""Test importer can be initialized"""
		with tempfile.NamedTemporaryFile(suffix='.sfc', delete=False) as tmp:
			tmp_path = Path(tmp.name)
		
		try:
			importer = SimpleTextImporter(tmp_path, dry_run=True)
			self.assertEqual(importer.rom_path, tmp_path)
		finally:
			tmp_path.unlink()
	
	def test_roundtrip_simple(self):
		"""Test extract → modify → import → extract round-trip"""
		with tempfile.TemporaryDirectory() as tmpdir:
			tmpdir = Path(tmpdir)
			
			# Extract original
			extractor = SimpleTextExtractor(self.rom_path)
			all_text = extractor.extract_all()
			extractor.save_csv(all_text, tmpdir)
			
			# Modify CSV
			csv_path = tmpdir / 'spell_names.csv'
			with open(csv_path, 'r', encoding='utf-8') as f:
				reader = csv.DictReader(f)
				rows = list(reader)
			
			# Modify first entry
			original_text = rows[0]['Text']
			rows[0]['Text'] = 'Test_X'
			
			modified_csv = tmpdir / 'modified.csv'
			with open(modified_csv, 'w', encoding='utf-8', newline='') as f:
				writer = csv.DictWriter(f, fieldnames=rows[0].keys())
				writer.writeheader()
				writer.writerows(rows)
			
			# Import to temp ROM
			import shutil
			temp_rom = tmpdir / 'test.sfc'
			shutil.copy2(self.rom_path, temp_rom)
			
			importer = SimpleTextImporter(temp_rom, dry_run=False, create_backup=False)
			importer.load_rom()
			importer.import_csv(modified_csv)
			importer.save_rom()
			
			# Re-extract
			extractor2 = SimpleTextExtractor(temp_rom)
			all_text2 = extractor2.extract_all()
			
			# Verify modification
			spell_data = all_text2['tables']['spell_names']['entries'][0]
			self.assertEqual(spell_data['text'], 'Test_X')


class TestCSVOutput(unittest.TestCase):
	"""Test CSV output format"""
	
	def test_csv_has_correct_columns(self):
		"""Test that extracted CSVs have required columns"""
		csv_files = list((project_dir / "data" / "text_fixed").glob("*.csv"))
		
		if not csv_files:
			self.skipTest("No CSV files found in data/text_fixed/")
		
		for csv_file in csv_files:
			with open(csv_file, 'r', encoding='utf-8') as f:
				reader = csv.DictReader(f)
				columns = reader.fieldnames
				
				self.assertIn('ID', columns)
				self.assertIn('Text', columns)
				self.assertIn('Address', columns)
				self.assertIn('Length', columns)


def run_tests():
	"""Run all tests"""
	unittest.main(argv=[''], verbosity=2, exit=False)


if __name__ == '__main__':
	run_tests()
