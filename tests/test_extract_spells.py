#!/usr/bin/env python3
"""
Unit tests for spell extraction

Tests spell data extraction:
- Correct spell count (16 total effects, 12 learnable)
- Proper data structure
- MP cost validity
- Element assignments
- JSON output format
"""

import sys
import json
import unittest
from pathlib import Path

# Add project root to path
project_dir = Path(__file__).parent.parent
sys.path.insert(0, str(project_dir / "tools"))


class TestSpellExtraction(unittest.TestCase):
	"""Test cases for spell data extraction"""

	@classmethod
	def setUpClass(cls):
		"""Load extracted spell data once for all tests"""
		spells_file = project_dir / "data" / "spells" / "spells.json"

		if not spells_file.exists():
			raise FileNotFoundError(f"Spell data not found: {spells_file}")

		with open(spells_file, 'r', encoding='utf-8') as f:
			cls.data = json.load(f)

		cls.spells = cls.data.get('spells', [])

	def test_spell_count(self):
		"""Test that 16 spell effects are extracted"""
		self.assertEqual(len(self.spells), 16,
			f"Expected 16 spell effects, found {len(self.spells)}")

	def test_learnable_spell_count(self):
		"""Test that 12 spells are learnable (books/seals)"""
		learnable_mapping_file = project_dir / "tools" / "validation" / "learnable_spells_mapping.json"

		if learnable_mapping_file.exists():
			with open(learnable_mapping_file, 'r', encoding='utf-8') as f:
				mapping = json.load(f)

			# Check spells array
			spells_array = mapping.get('spells', [])
			self.assertEqual(len(spells_array), 12,
				f"Expected 12 learnable spells, found {len(spells_array)}")

	def test_spell_structure(self):
		"""Test that each spell has required fields"""
		required_fields = ['id', 'name', 'power', 'mp_cost']

		for i, spell in enumerate(self.spells):
			for field in required_fields:
				self.assertIn(field, spell,
					f"Spell {i} missing field: {field}")

	def test_mp_cost_values(self):
		"""Test that MP costs are within valid ranges"""
		for spell in self.spells:
			mp_cost = spell['mp_cost']
			self.assertIsInstance(mp_cost, int,
				f"Spell '{spell['name']}' MP cost should be integer")
			self.assertGreaterEqual(mp_cost, 0,
				f"Spell '{spell['name']}' MP cost should be >= 0")
			self.assertLessEqual(mp_cost, 99,
				f"Spell '{spell['name']}' MP cost should be <= 99")

	def test_power_values(self):
		"""Test that power values are within valid ranges"""
		for spell in self.spells:
			power = spell['power']
			self.assertIsInstance(power, int,
				f"Spell '{spell['name']}' power should be integer")
			self.assertGreaterEqual(power, 0,
				f"Spell '{spell['name']}' power should be >= 0")
			self.assertLessEqual(power, 255,
				f"Spell '{spell['name']}' power should be <= 255")

	def test_unique_ids(self):
		"""Test that spell IDs are unique"""
		spell_ids = [s['id'] for s in self.spells]
		unique_ids = set(spell_ids)

		self.assertEqual(len(spell_ids), len(unique_ids),
			f"Duplicate spell IDs found")

	def test_spell_names_non_empty(self):
		"""Test that all spells have non-empty names"""
		for spell in self.spells:
			name = spell['name']
			self.assertIsInstance(name, str,
				f"Spell {spell['id']} name should be string")
			self.assertGreater(len(name), 0,
				f"Spell {spell['id']} should have non-empty name")

	def test_known_spells(self):
		"""Test that known spells exist with expected names"""
		spell_names = {s['name'] for s in self.spells}

		# These spells should definitely exist
		expected_spells = ['Fire', 'Blizzard', 'Thunder', 'Aero',
		                   'Cure', 'Life', 'Heal', 'Exit']

		for expected in expected_spells:
			self.assertIn(expected, spell_names,
				f"Expected spell '{expected}' not found")

	def test_mp_cost_reasonable(self):
		"""Test that MP costs are reasonable for spell types"""
		for spell in self.spells:
			name = spell['name']
			mp_cost = spell['mp_cost']

			# All spells should have some MP cost or be special
			self.assertIsInstance(mp_cost, int,
				f"Spell '{name}' MP cost should be integer")

			# Basic spells should have reasonable MP costs
			if name in ['Fire', 'Blizzard', 'Cure']:
				self.assertLess(mp_cost, 50,
					f"Basic spell '{name}' should have moderate MP cost")
class TestSpellMapping(unittest.TestCase):
	"""Test spell ID mapping to FFMQ Randomizer"""

	@classmethod
	def setUpClass(cls):
		"""Load spell mapping"""
		mapping_file = project_dir / "tools" / "validation" / "learnable_spells_mapping.json"

		if mapping_file.exists():
			with open(mapping_file, 'r', encoding='utf-8') as f:
				cls.mapping = json.load(f)
		else:
			cls.mapping = {}

	def test_mapping_completeness(self):
		"""Test that all 12 learnable spells are mapped"""
		if self.mapping:
			spells_array = self.mapping.get('spells', [])
			self.assertEqual(len(spells_array), 12,
				"Mapping should contain all 12 learnable spells")

	def test_mapping_structure(self):
		"""Test that mapping has correct structure"""
		if self.mapping:
			spells_array = self.mapping.get('spells', [])

			for spell_data in spells_array:
				# Check spell data has required fields
				required_fields = ['randomizer_id', 'randomizer_name', 'our_id', 'our_name']
				for field in required_fields:
					self.assertIn(field, spell_data,
						f"Mapping entry missing field: {field}")

				# Check randomizer ID is valid
				self.assertIn(spell_data['randomizer_id'], range(12),
					f"Randomizer ID {spell_data['randomizer_id']} should be 0-11")

	def test_no_duplicate_mappings(self):
		"""Test that no two randomizer IDs map to same spell"""
		if self.mapping:
			spells_array = self.mapping.get('spells', [])
			our_ids = [spell['our_id'] for spell in spells_array]
			unique_ids = set(our_ids)

			self.assertEqual(len(our_ids), len(unique_ids),
				"Mapping contains duplicate spell IDs")


if __name__ == '__main__':
	unittest.main(verbosity=2)
