#!/usr/bin/env python3
"""
FFMQ Data Validation Against Randomizer

Cross-validates our extracted data against the FFMQ Randomizer codebase data.
Validates spell IDs, enemy count, attack count, element type bitfields, and power values.

Based on wildham0/FFMQRando repository:
https://github.com/wildham0/FFMQRando
"""

import json
import csv
import os
import sys
from pathlib import Path
from typing import Dict, List, Any, Optional, Tuple
from dataclasses import dataclass
from enum import IntEnum


class SpellFlags(IntEnum):
	"""Spell IDs from FFMQ Randomizer - EnumsFlags.cs line 420"""
	ExitBook = 0x00
	CureBook = 0x01
	HealBook = 0x02
	LifeBook = 0x03
	QuakeBook = 0x04
	BlizzardBook = 0x05	# Blizzard
	FireBook = 0x06		# Fire
	AeroBook = 0x07		# Aero
	ThunderSeal = 0x08	 # Thunder
	WhiteSeal = 0x09	 # White
	MeteorSeal = 0x0A	# Meteor
	FlareSeal = 0x0B	 # Flare


class ElementsType(IntEnum):
	"""Element types from FFMQ Randomizer - Enemies.cs line 47"""
	Silence = 0x0001
	Blind = 0x0002
	Poison = 0x0004
	Confusion = 0x0008
	Sleep = 0x0010
	Paralysis = 0x0020
	Stone = 0x0040
	Doom = 0x0080
	Projectile = 0x0100
	Bomb = 0x0200
	Axe = 0x0400
	Zombie = 0x0800
	Air = 0x1000
	Fire = 0x2000
	Water = 0x4000
	Earth = 0x8000


@dataclass
class ValidationResult:
	"""Container for validation results"""
	category: str
	test_name: str
	passed: bool
	expected: Any
	actual: Any
	message: str = ""


class FFMQDataValidator:
	"""Validates FFMQ extracted data against randomizer constants"""

	def __init__(self, data_dir: Path):
		self.data_dir = data_dir
		self.results: List[ValidationResult] = []

		# Expected values from FFMQ Randomizer
		self.expected_spell_count = 12	# 0x00 through 0x0B
		self.expected_enemy_count = 83	# From metadata in enemies.json
		self.expected_attack_count = 169	# From metadata in attacks.json

		# Spell name mappings from randomizer
		self.randomizer_spell_names = {
			0x00: "Exit",		# ExitBook
			0x01: "Cure",		# CureBook
			0x02: "Heal",		# HealBook
			0x03: "Life",		# LifeBook
			0x04: "Quake",	 # QuakeBook
			0x05: "Blizzard",	# BlizzardBook
			0x06: "Fire",		# FireBook
			0x07: "Aero",		# AeroBook
			0x08: "Thunder",	 # ThunderSeal
			0x09: "White",	 # WhiteSeal
			0x0A: "Meteor",	# MeteorSeal
			0x0B: "Flare"		# FlareSeal
		}

		# Battle Actions from BattleSimulator.cs
		self.randomizer_battle_actions = {
			0x14: ("Exit Book", 0x14, 0, 100),		# Line 613
			0x15: ("Cure Book", 0x15, 0x32, 100),	 # Line 614
			0x16: ("Heal Book", 0x16, 0, 100),		# Line 615
			0x17: ("Life Book", 0x17, 0, 100),		# Line 616
			0x18: ("Earthquake Book", 0x18, 0x19, 100),	# Line 617
			0x19: ("Blizzard Book", 0x19, 0x87, 100),	# Line 618
			0x1A: ("Fire Book", 0x1A, 0x55, 100),		 # Line 619
			0x1B: ("Aero Book", 0x1B, 0xEB, 100),		 # Line 620
			0x1C: ("Thunder Seal", 0x1C, 0xB4, 100),	# Line 621
			0x1D: ("White Seal", 0x1D, 0x8C, 100),		# Line 622
			0x1E: ("Meteor Seal", 0x1E, 0x46, 100),	 # Would be next in sequence
			0x1F: ("Flare Seal", 0x1F, 0x5A, 100),		# Would be next in sequence
		}

	def load_our_data(self) -> Dict[str, Any]:
		"""Load our extracted data files"""
		data = {}

		# Load spell data
		spells_file = self.data_dir / "spells" / "spells.json"
		if spells_file.exists():
			with open(spells_file, 'r', encoding='utf-8') as f:
				data['spells'] = json.load(f)

		# Load enemy data
		enemies_file = self.data_dir / "extracted" / "enemies" / "enemies.json"
		if enemies_file.exists():
			with open(enemies_file, 'r', encoding='utf-8') as f:
				data['enemies'] = json.load(f)

		# Load attack data
		attacks_file = self.data_dir / "extracted" / "attacks" / "attacks.json"
		if attacks_file.exists():
			with open(attacks_file, 'r', encoding='utf-8') as f:
				data['attacks'] = json.load(f)

		return data

	def validate_spell_count(self, our_data: Dict[str, Any]) -> None:
		"""Validate spell count matches randomizer expectation"""
		if 'spells' not in our_data:
			self.results.append(ValidationResult(
				"Spells", "Spell Data Available", False,
				"spells.json file", "missing", "Spell data file not found"
			))
			return

		spell_count = len(our_data['spells']['spells'])
		self.results.append(ValidationResult(
			"Spells", "Spell Count",
			spell_count == self.expected_spell_count,
			self.expected_spell_count, spell_count,
			f"Expected {self.expected_spell_count} spells (0x00-0x0B), found {spell_count}"
		))

	def validate_spell_ids(self, our_data: Dict[str, Any]) -> None:
		"""Validate spell IDs match randomizer enum values"""
		if 'spells' not in our_data:
			return

		spells = our_data['spells']['spells']

		# Check ID range and sequence
		spell_ids = [spell['id'] for spell in spells]
		expected_ids = list(range(12))	# 0-11 (0x00-0x0B)

		missing_ids = set(expected_ids) - set(spell_ids)
		extra_ids = set(spell_ids) - set(expected_ids)

		self.results.append(ValidationResult(
			"Spells", "Spell ID Range",
			len(missing_ids) == 0 and len(extra_ids) == 0,
			f"IDs 0-11 (0x00-0x0B)", f"Missing: {missing_ids}, Extra: {extra_ids}",
			"All spell IDs should be in range 0x00-0x0B"
		))

		# Validate specific spell names against randomizer
		name_mismatches = []
		for spell in spells:
			spell_id = spell['id']
			our_name = spell['name']

			if spell_id in self.randomizer_spell_names:
				expected_name = self.randomizer_spell_names[spell_id]
				if our_name != expected_name:
					name_mismatches.append(f"ID {spell_id}: expected '{expected_name}', got '{our_name}'")

		self.results.append(ValidationResult(
			"Spells", "Spell Names",
			len(name_mismatches) == 0,
			"Names match randomizer", f"{len(name_mismatches)} mismatches",
			f"Name mismatches: {'; '.join(name_mismatches)}" if name_mismatches else "All spell names match"
		))

	def validate_enemy_count(self, our_data: Dict[str, Any]) -> None:
		"""Validate enemy count matches randomizer expectation"""
		if 'enemies' not in our_data:
			self.results.append(ValidationResult(
				"Enemies", "Enemy Data Available", False,
				"enemies.json file", "missing", "Enemy data file not found"
			))
			return

		metadata = our_data['enemies'].get('metadata', {})
		reported_count = metadata.get('count', 0)
		actual_count = len(our_data['enemies'].get('enemies', []))

		# Check metadata count
		self.results.append(ValidationResult(
			"Enemies", "Enemy Metadata Count",
			reported_count == self.expected_enemy_count,
			self.expected_enemy_count, reported_count,
			f"Metadata reports {reported_count} enemies, randomizer expects {self.expected_enemy_count}"
		))

		# Check actual count
		self.results.append(ValidationResult(
			"Enemies", "Enemy Actual Count",
			actual_count == self.expected_enemy_count,
			self.expected_enemy_count, actual_count,
			f"Found {actual_count} enemy entries, randomizer expects {self.expected_enemy_count}"
		))

	def validate_enemy_structure(self, our_data: Dict[str, Any]) -> None:
		"""Validate enemy data structure matches randomizer Enemy class"""
		if 'enemies' not in our_data:
			return

		enemies = our_data['enemies'].get('enemies', [])
		if not enemies:
			return

		# Expected fields from randomizer Enemy class (Enemies.cs line 280)
		expected_fields = {
			'HP': ['hp', 'health', 'hit_points'],
			'Attack': ['attack', 'att', 'atk'],
			'Defense': ['defense', 'def'],
			'Speed': ['speed', 'spd'],
			'Magic': ['magic', 'mag'],
			'Accuracy': ['accuracy', 'acc'],
			'Evade': ['evade', 'eva'],
			'MagicDefense': ['magic_defense', 'mdef', 'magic_def'],
			'MagicEvade': ['magic_evade', 'meva', 'magic_eva'],
		}

		sample_enemy = enemies[0]
		missing_concepts = []

		for concept, possible_fields in expected_fields.items():
			found = any(field in sample_enemy for field in possible_fields)
			if not found:
				missing_concepts.append(concept)

		self.results.append(ValidationResult(
			"Enemies", "Enemy Structure Fields",
			len(missing_concepts) == 0,
			"All enemy stat fields present", f"Missing: {missing_concepts}",
			f"Enemy structure validation: {len(missing_concepts)} missing concepts"
		))

	def validate_attack_count(self, our_data: Dict[str, Any]) -> None:
		"""Validate attack count matches randomizer expectation"""
		if 'attacks' not in our_data:
			self.results.append(ValidationResult(
				"Attacks", "Attack Data Available", False,
				"attacks.json file", "missing", "Attack data file not found"
			))
			return

		metadata = our_data['attacks'].get('metadata', {})
		reported_count = metadata.get('entry_count', 0)
		actual_count = len(our_data['attacks'].get('attacks', []))

		# Check metadata count
		self.results.append(ValidationResult(
			"Attacks", "Attack Metadata Count",
			reported_count == self.expected_attack_count,
			self.expected_attack_count, reported_count,
			f"Metadata reports {reported_count} attacks, randomizer expects {self.expected_attack_count}"
		))

		# Check actual count
		self.results.append(ValidationResult(
			"Attacks", "Attack Actual Count",
			actual_count == self.expected_attack_count,
			self.expected_attack_count, actual_count,
			f"Found {actual_count} attack entries, randomizer expects {self.expected_attack_count}"
		))

	def validate_element_bitfields(self, our_data: Dict[str, Any]) -> None:
		"""Validate element type bitfields match randomizer ElementsType enum"""
		if 'enemies' not in our_data:
			return

		enemies = our_data['enemies'].get('enemies', [])
		if not enemies:
			return

		# Look for resistance/weakness bitfields in enemy data
		bitfield_analysis = []

		for i, enemy in enumerate(enemies[:5]):	# Check first 5 enemies
			for field_name in enemy.keys():
				if 'resistance' in field_name.lower() or 'weakness' in field_name.lower():
					value = enemy[field_name]
					if isinstance(value, int) and value > 0:
						# Analyze bitfield against known element values
						matched_elements = []
						for element in ElementsType:
							if value & element.value:
								matched_elements.append(element.name)

						if matched_elements:
							bitfield_analysis.append({
								'enemy_id': i,
								'field': field_name,
								'value': hex(value),
								'elements': matched_elements
							})

		self.results.append(ValidationResult(
			"Elements", "Bitfield Analysis",
			len(bitfield_analysis) > 0,
			"Element bitfields found and parsed", f"Found {len(bitfield_analysis)} bitfields",
			f"Element bitfield validation: {len(bitfield_analysis)} bitfields analyzed"
		))

	def validate_power_values(self, our_data: Dict[str, Any]) -> None:
		"""Validate power values are reasonable ranges"""
		validations = []

		# Validate spell power values
		if 'spells' in our_data:
			spells = our_data['spells']['spells']
			spell_powers = [spell.get('power', 0) for spell in spells if 'power' in spell]

			if spell_powers:
				min_power, max_power = min(spell_powers), max(spell_powers)
				reasonable_range = 1 <= min_power <= 50 and 5 <= max_power <= 100

				self.results.append(ValidationResult(
					"Power", "Spell Power Range",
					reasonable_range,
					"Powers in reasonable range (1-100)", f"Min: {min_power}, Max: {max_power}",
					f"Spell power range validation: {min_power}-{max_power}"
				))

		# Validate attack power values
		if 'attacks' in our_data:
			attacks = our_data['attacks']['attacks']
			attack_powers = [attack.get('power', 0) for attack in attacks if 'power' in attack]

			if attack_powers:
				min_power, max_power = min(attack_powers), max(attack_powers)
				reasonable_range = 0 <= min_power <= 200 and max_power <= 255

				self.results.append(ValidationResult(
					"Power", "Attack Power Range",
					reasonable_range,
					"Powers in reasonable range (0-255)", f"Min: {min_power}, Max: {max_power}",
					f"Attack power range validation: {min_power}-{max_power}"
				))

	def run_validation(self) -> List[ValidationResult]:
		"""Run all validation tests"""
		print("🔍 Loading FFMQ data for validation...")
		our_data = self.load_our_data()

		print("🧪 Running validation tests...")

		# Run all validation tests
		self.validate_spell_count(our_data)
		self.validate_spell_ids(our_data)
		self.validate_enemy_count(our_data)
		self.validate_enemy_structure(our_data)
		self.validate_attack_count(our_data)
		self.validate_element_bitfields(our_data)
		self.validate_power_values(our_data)

		return self.results

	def generate_report(self, results: List[ValidationResult]) -> str:
		"""Generate validation report"""
		passed = sum(1 for r in results if r.passed)
		total = len(results)

		report = []
		report.append("=" * 80)
		report.append("FFMQ DATA VALIDATION REPORT")
		report.append("Cross-validation against FFMQ Randomizer")
		report.append("=" * 80)
		report.append(f"")
		report.append(f"SUMMARY: {passed}/{total} tests passed ({passed/total*100:.1f}%)")
		report.append(f"")

		# Group by category
		categories = {}
		for result in results:
			if result.category not in categories:
				categories[result.category] = []
			categories[result.category].append(result)

		for category, category_results in categories.items():
			category_passed = sum(1 for r in category_results if r.passed)
			category_total = len(category_results)

			report.append(f"📊 {category.upper()}: {category_passed}/{category_total} passed")
			report.append("-" * 50)

			for result in category_results:
				status = "✅ PASS" if result.passed else "❌ FAIL"
				report.append(f"{status} {result.test_name}")
				report.append(f"	 Expected: {result.expected}")
				report.append(f"	 Actual:	 {result.actual}")
				if result.message:
					report.append(f"	 Details:	{result.message}")
				report.append("")

		# Recommendations
		failed_tests = [r for r in results if not r.passed]
		if failed_tests:
			report.append("🔧 RECOMMENDATIONS:")
			report.append("-" * 50)

			for result in failed_tests:
				if "missing" in str(result.actual).lower():
					report.append(f"• Extract missing data: {result.test_name}")
				elif "count" in result.test_name.lower():
					report.append(f"• Verify extraction completeness: {result.test_name}")
				elif "name" in result.test_name.lower():
					report.append(f"• Update name mapping: {result.test_name}")
				else:
					report.append(f"• Review data format: {result.test_name}")
			report.append("")

		report.append("📚 REFERENCE:")
		report.append("-" * 50)
		report.append("• FFMQ Randomizer: https://github.com/wildham0/FFMQRando")
		report.append("• Spell IDs: EnumsFlags.cs SpellFlags enum (0x00-0x0B)")
		report.append("• Enemy data: Enemies.cs Enemy class (83 enemies)")
		report.append("• Attack data: BattleSimulator.cs (169 attacks)")
		report.append("• Element types: Enemies.cs ElementsType enum")
		report.append("")

		return "\n".join(report)


def main():
	"""Main validation function"""
	# Determine paths
	script_dir = Path(__file__).parent
	project_dir = script_dir.parent.parent
	data_dir = project_dir / "data"

	if not data_dir.exists():
		print(f"❌ Data directory not found: {data_dir}")
		return 1

	# Run validation
	validator = FFMQDataValidator(data_dir)
	results = validator.run_validation()

	# Generate and display report
	report = validator.generate_report(results)
	print(report)

	# Save report
	report_file = script_dir / "validation_report.txt"
	with open(report_file, 'w', encoding='utf-8') as f:
		f.write(report)

	print(f"📄 Full report saved to: {report_file}")

	# Return exit code based on results
	failed_count = sum(1 for r in results if not r.passed)
	return min(failed_count, 255)	# Cap at 255 for exit code


if __name__ == "__main__":
	exit(main())
