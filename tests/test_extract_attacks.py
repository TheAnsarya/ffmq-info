#!/usr/bin/env python3
"""
Unit tests for extract_attacks.py

Tests attack data extraction from ROM:
- Correct attack count (169)
- Proper data structure
- Power values within valid ranges
- Target byte parsing
- JSON output format
"""

import sys
import json
import unittest
from pathlib import Path

# Add project root to path
project_dir = Path(__file__).parent.parent
sys.path.insert(0, str(project_dir / "tools"))


class TestAttackExtraction(unittest.TestCase):
	"""Test cases for attack data extraction"""

	@classmethod
	def setUpClass(cls):
		"""Load extracted attack data once for all tests"""
		attacks_file = project_dir / "data" / "extracted" / "attacks" / "attacks.json"

		if not attacks_file.exists():
			raise FileNotFoundError(f"Attack data not found: {attacks_file}")

		with open(attacks_file, 'r', encoding='utf-8') as f:
			cls.data = json.load(f)

		cls.attacks = cls.data.get('attacks', [])
		cls.metadata = cls.data.get('metadata', {})

	def test_attack_count(self):
		"""Test that exactly 169 attacks are extracted"""
		self.assertEqual(len(self.attacks), 169,
			f"Expected 169 attacks, found {len(self.attacks)}")

	def test_metadata_exists(self):
		"""Test that metadata is present"""
		self.assertIsNotNone(self.metadata, "Metadata should exist")
		self.assertIn('entry_count', self.metadata)
		self.assertEqual(self.metadata['entry_count'], 169)

	def test_attack_structure(self):
		"""Test that each attack has required fields"""
		required_fields = ['id', 'power', 'attack_type']

		for i, attack in enumerate(self.attacks):
			for field in required_fields:
				self.assertIn(field, attack,
					f"Attack {i} missing field: {field}")

	def test_power_values(self):
		"""Test that power values are within valid ranges (0-255)"""
		for attack in self.attacks:
			power = attack['power']
			self.assertIsInstance(power, int,
				f"Attack {attack['id']} power should be integer, got {type(power)}")
			self.assertGreaterEqual(power, 0,
				f"Attack {attack['id']} power should be >= 0")
			self.assertLessEqual(power, 255,
				f"Attack {attack['id']} power should be <= 255")

	def test_byte_values(self):
		"""Test that attack_type bytes are valid (0-255)"""
		for attack in self.attacks:
			attack_type = attack['attack_type']

			self.assertIsInstance(attack_type, int,
				f"Attack {attack['id']} attack_type should be integer")

			self.assertGreaterEqual(attack_type, 0,
				f"Attack {attack['id']} attack_type should be >= 0")
			self.assertLessEqual(attack_type, 255,
				f"Attack {attack['id']} attack_type should be <= 255")

	def test_unique_ids(self):
		"""Test that attack IDs are unique"""
		attack_ids = [a['id'] for a in self.attacks]
		unique_ids = set(attack_ids)

		self.assertEqual(len(attack_ids), len(unique_ids),
			f"Duplicate attack IDs found: {len(attack_ids)} total, {len(unique_ids)} unique")

	def test_sequential_ids(self):
		"""Test that attack IDs are sequential from 0"""
		attack_ids = sorted([a['id'] for a in self.attacks])
		expected_ids = list(range(169))

		self.assertEqual(attack_ids, expected_ids,
			"Attack IDs should be sequential from 0 to 168")

	def test_attack_ids_valid(self):
		"""Test that all attacks have valid IDs"""
		for attack in self.attacks:
			attack_id = attack['id']
			self.assertIsInstance(attack_id, int,
				f"Attack ID should be integer")
			self.assertGreaterEqual(attack_id, 0,
				f"Attack ID should be >= 0")

	def test_power_distribution(self):
		"""Test that attack powers have reasonable distribution"""
		powers = [a['power'] for a in self.attacks]

		# Should have some weak attacks
		weak_attacks = [p for p in powers if 0 < p < 30]
		self.assertGreater(len(weak_attacks), 5,
			"Should have some weak attacks (power < 30)")

		# Should have some strong attacks
		strong_attacks = [p for p in powers if p > 100]
		self.assertGreater(len(strong_attacks), 5,
			"Should have some strong attacks (power > 100)")

		# Should have zero-power attacks (status effects, etc)
		zero_power = [p for p in powers if p == 0]
		self.assertGreater(len(zero_power), 0,
			"Should have some zero-power attacks (status effects)")


class TestAttackDataConsistency(unittest.TestCase):
	"""Test data consistency across attacks"""

	@classmethod
	def setUpClass(cls):
		"""Load attack data"""
		attacks_file = project_dir / "data" / "extracted" / "attacks" / "attacks.json"

		with open(attacks_file, 'r', encoding='utf-8') as f:
			data = json.load(f)

		cls.attacks = data.get('attacks', [])

	def test_average_power(self):
		"""Test that average attack power is reasonable"""
		non_zero_powers = [a['power'] for a in self.attacks if a['power'] > 0]

		if len(non_zero_powers) > 0:
			avg_power = sum(non_zero_powers) / len(non_zero_powers)

			self.assertGreater(avg_power, 20,
				f"Average attack power ({avg_power}) seems too low")
			self.assertLess(avg_power, 150,
				f"Average attack power ({avg_power}) seems too high")

	def test_attack_power_distribution(self):
		"""Test that attack powers vary (not all the same)"""
		attack_powers = [a['power'] for a in self.attacks]
		unique_powers = set(attack_powers)

		# Should have variety of power values
		self.assertGreater(len(unique_powers), 10,
			f"Only {len(unique_powers)} unique power values - seems too few")
if __name__ == '__main__':
	unittest.main(verbosity=2)
