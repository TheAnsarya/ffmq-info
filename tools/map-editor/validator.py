"""
FFMQ ROM Data Validator

Validates all game data for consistency, correctness, and balance.
Checks for common errors, invalid values, and potential issues.
"""

import sys
from pathlib import Path
from typing import List, Dict, Tuple, Any
from dataclasses import dataclass

sys.path.insert(0, str(Path(__file__).parent.parent))

from utils.enemy_database import EnemyDatabase
from utils.spell_database import SpellDatabase
from utils.item_database import ItemDatabase
from utils.dungeon_map import DungeonMapDatabase
from utils.enemy_data import EnemyFlags
from utils.spell_data import SpellFlags
from utils.item_data import ItemFlags


@dataclass
class ValidationIssue:
	"""Represents a validation issue"""
	severity: str  # ERROR, WARNING, INFO
	category: str  # ENEMY, SPELL, ITEM, DUNGEON, BALANCE
	id: int
	name: str
	message: str
	
	def __str__(self) -> str:
		return f"[{self.severity}] {self.category} 0x{self.id:02X} '{self.name}': {self.message}"


class ROMValidator:
	"""Validates all ROM data"""
	
	def __init__(self):
		self.issues: List[ValidationIssue] = []
		self.enemy_db: EnemyDatabase = None
		self.spell_db: SpellDatabase = None
		self.item_db: ItemDatabase = None
		self.dungeon_db: DungeonMapDatabase = None
	
	def load_rom(self, rom_path: str):
		"""Load all databases from ROM"""
		print(f"Loading ROM: {rom_path}")
		
		self.enemy_db = EnemyDatabase()
		self.enemy_db.load_from_rom(rom_path)
		print(f"  Loaded {len(self.enemy_db.enemies)} enemies")
		
		self.spell_db = SpellDatabase()
		self.spell_db.load_from_rom(rom_path)
		print(f"  Loaded {len(self.spell_db.spells)} spells")
		
		self.item_db = ItemDatabase()
		self.item_db.load_from_rom(rom_path)
		print(f"  Loaded {len(self.item_db.items)} items")
		
		print()
	
	def add_issue(self, severity: str, category: str, id: int, name: str, message: str):
		"""Add validation issue"""
		self.issues.append(ValidationIssue(severity, category, id, name, message))
	
	def validate_all(self) -> bool:
		"""Run all validation checks"""
		print("Running validation checks...")
		print()
		
		self.validate_enemies()
		self.validate_spells()
		self.validate_items()
		self.validate_balance()
		
		return len([i for i in self.issues if i.severity == "ERROR"]) == 0
	
	def validate_enemies(self):
		"""Validate enemy data"""
		print("Validating enemies...")
		
		for enemy_id, enemy in self.enemy_db.enemies.items():
			# Check HP range
			if enemy.stats.hp == 0:
				self.add_issue("ERROR", "ENEMY", enemy_id, enemy.name,
							  "HP is 0")
			elif enemy.stats.hp > 65535:
				self.add_issue("ERROR", "ENEMY", enemy_id, enemy.name,
							  f"HP {enemy.stats.hp} exceeds maximum (65535)")
			
			# Check level range
			if enemy.level == 0:
				self.add_issue("WARNING", "ENEMY", enemy_id, enemy.name,
							  "Level is 0")
			elif enemy.level > 99:
				self.add_issue("ERROR", "ENEMY", enemy_id, enemy.name,
							  f"Level {enemy.level} exceeds maximum (99)")
			
			# Check stats
			for stat_name in ['attack', 'defense', 'magic', 'magic_def', 'speed']:
				value = getattr(enemy.stats, stat_name)
				if value > 255:
					self.add_issue("ERROR", "ENEMY", enemy_id, enemy.name,
								  f"{stat_name} {value} exceeds 255")
			
			# Check accuracy/evasion percentages
			if enemy.stats.accuracy > 100:
				self.add_issue("WARNING", "ENEMY", enemy_id, enemy.name,
							  f"Accuracy {enemy.stats.accuracy}% > 100%")
			
			if enemy.stats.evasion > 100:
				self.add_issue("WARNING", "ENEMY", enemy_id, enemy.name,
							  f"Evasion {enemy.stats.evasion}% > 100%")
			
			# Check resistances
			for element in ['fire', 'water', 'earth', 'wind', 'holy', 'dark', 'poison']:
				value = getattr(enemy.resistances, element)
				if value > 255:
					self.add_issue("ERROR", "ENEMY", enemy_id, enemy.name,
								  f"{element} resistance {value} > 255")
			
			# Check EXP
			if enemy.exp == 0 and not (enemy.flags & EnemyFlags.BOSS):
				self.add_issue("WARNING", "ENEMY", enemy_id, enemy.name,
							  "Gives 0 EXP (not a boss)")
			
			# Check gold
			if enemy.gold == 0 and not (enemy.flags & EnemyFlags.BOSS):
				self.add_issue("INFO", "ENEMY", enemy_id, enemy.name,
							  "Gives 0 gold (not a boss)")
			
			# Check boss stats
			if enemy.flags & EnemyFlags.BOSS:
				if enemy.stats.hp < 500:
					self.add_issue("WARNING", "ENEMY", enemy_id, enemy.name,
								  f"Boss with low HP ({enemy.stats.hp})")
				
				if enemy.exp < 1000:
					self.add_issue("WARNING", "ENEMY", enemy_id, enemy.name,
								  f"Boss with low EXP ({enemy.exp})")
			
			# Check undead + regeneration conflict
			if (enemy.flags & EnemyFlags.UNDEAD) and (enemy.flags & EnemyFlags.REGENERATES):
				self.add_issue("WARNING", "ENEMY", enemy_id, enemy.name,
							  "Undead enemy with regeneration (unusual)")
			
			# Check flying + aquatic conflict
			if (enemy.flags & EnemyFlags.FLYING) and (enemy.flags & EnemyFlags.AQUATIC):
				self.add_issue("WARNING", "ENEMY", enemy_id, enemy.name,
							  "Both flying and aquatic (unusual)")
			
			# Check difficulty vs level
			difficulty = enemy.calculate_difficulty()
			expected_difficulty = enemy.level * 10
			
			if difficulty < expected_difficulty * 0.5:
				self.add_issue("INFO", "ENEMY", enemy_id, enemy.name,
							  f"Difficulty {difficulty} low for level {enemy.level}")
			elif difficulty > expected_difficulty * 2:
				self.add_issue("INFO", "ENEMY", enemy_id, enemy.name,
							  f"Difficulty {difficulty} high for level {enemy.level}")
		
		print(f"  Validated {len(self.enemy_db.enemies)} enemies")
		print()
	
	def validate_spells(self):
		"""Validate spell data"""
		print("Validating spells...")
		
		for spell_id, spell in self.spell_db.spells.items():
			# Check MP cost
			if spell.mp_cost == 0 and not (spell.flags & SpellFlags.SILENT_CAST):
				self.add_issue("WARNING", "SPELL", spell_id, spell.name,
							  "MP cost is 0")
			elif spell.mp_cost > 99:
				self.add_issue("WARNING", "SPELL", spell_id, spell.name,
							  f"MP cost {spell.mp_cost} is very high")
			
			# Check power
			if spell.power == 0:
				self.add_issue("WARNING", "SPELL", spell_id, spell.name,
							  "Power is 0")
			elif spell.power > 255:
				self.add_issue("ERROR", "SPELL", spell_id, spell.name,
							  f"Power {spell.power} exceeds 255")
			
			# Check accuracy
			if spell.accuracy > 100:
				self.add_issue("WARNING", "SPELL", spell_id, spell.name,
							  f"Accuracy {spell.accuracy}% > 100%")
			
			if spell.accuracy < 50 and (spell.flags & SpellFlags.OFFENSIVE):
				self.add_issue("INFO", "SPELL", spell_id, spell.name,
							  f"Offensive spell with low accuracy ({spell.accuracy}%)")
			
			# Check healing spells
			if spell.flags & SpellFlags.HEALING:
				if spell.flags & SpellFlags.OFFENSIVE:
					self.add_issue("WARNING", "SPELL", spell_id, spell.name,
								  "Marked as both healing and offensive")
			
			# Check reflectable status
			if (spell.flags & SpellFlags.REFLECTABLE) and (spell.flags & SpellFlags.PIERCING):
				self.add_issue("WARNING", "SPELL", spell_id, spell.name,
							  "Marked as both reflectable and piercing")
			
			# Check level requirements
			if hasattr(spell, 'level_required') and spell.level_required > 99:
				self.add_issue("ERROR", "SPELL", spell_id, spell.name,
							  f"Level requirement {spell.level_required} > 99")
		
		print(f"  Validated {len(self.spell_db.spells)} spells")
		print()
	
	def validate_items(self):
		"""Validate item data"""
		print("Validating items...")
		
		for item_id, item in self.item_db.items.items():
			# Check prices
			if item.buy_price < 0:
				self.add_issue("ERROR", "ITEM", item_id, item.name,
							  f"Negative buy price ({item.buy_price})")
			
			if item.sell_price < 0:
				self.add_issue("ERROR", "ITEM", item_id, item.name,
							  f"Negative sell price ({item.sell_price})")
			
			if item.sell_price > item.buy_price:
				self.add_issue("WARNING", "ITEM", item_id, item.name,
							  f"Sell price ({item.sell_price}) > buy price ({item.buy_price})")
			
			# Check equipment stats
			if item.is_equipment():
				stats = item.equipment_stats
				
				if stats.attack > 255:
					self.add_issue("ERROR", "ITEM", item_id, item.name,
								  f"Attack {stats.attack} > 255")
				
				if stats.defense > 255:
					self.add_issue("ERROR", "ITEM", item_id, item.name,
								  f"Defense {stats.defense} > 255")
				
				# Check if equipment has no stats
				total_stats = item.get_total_stats_value()
				if total_stats == 0:
					self.add_issue("WARNING", "ITEM", item_id, item.name,
								  "Equipment with no stat bonuses")
				
				# Check restrictions
				if not item.restrictions:
					self.add_issue("WARNING", "ITEM", item_id, item.name,
								  "Equipment with no character restrictions")
			
			# Check cursed + quest item conflict
			if (item.flags & ItemFlags.CURSED) and (item.flags & ItemFlags.QUEST_ITEM):
				self.add_issue("WARNING", "ITEM", item_id, item.name,
							  "Both cursed and quest item")
			
			# Check stackable consumables
			if item.is_consumable() and not (item.flags & ItemFlags.STACKABLE):
				self.add_issue("INFO", "ITEM", item_id, item.name,
							  "Consumable not marked as stackable")
			
			# Check quest items for sale
			if (item.flags & ItemFlags.QUEST_ITEM) and item.buy_price > 0:
				self.add_issue("WARNING", "ITEM", item_id, item.name,
							  "Quest item has buy price (should be unsellable)")
		
		print(f"  Validated {len(self.item_db.items)} items")
		print()
	
	def validate_balance(self):
		"""Validate game balance"""
		print("Validating game balance...")
		
		# Check enemy HP scaling
		enemies_by_level = {}
		for enemy in self.enemy_db.enemies.values():
			if enemy.level not in enemies_by_level:
				enemies_by_level[enemy.level] = []
			enemies_by_level[enemy.level].append(enemy)
		
		for level in sorted(enemies_by_level.keys()):
			enemies = enemies_by_level[level]
			avg_hp = sum(e.stats.hp for e in enemies) / len(enemies)
			
			# Expected HP: roughly level * 20
			expected_hp = level * 20
			
			if avg_hp < expected_hp * 0.5:
				self.add_issue("INFO", "BALANCE", level, f"Level {level}",
							  f"Average HP {avg_hp:.0f} is low (expected ~{expected_hp})")
			elif avg_hp > expected_hp * 3:
				self.add_issue("INFO", "BALANCE", level, f"Level {level}",
							  f"Average HP {avg_hp:.0f} is high (expected ~{expected_hp})")
		
		# Check spell MP efficiency
		offensive_spells = self.spell_db.get_offensive_spells()
		for spell in offensive_spells:
			if spell.mp_cost > 0:
				efficiency = spell.power / spell.mp_cost
				
				# Good efficiency is around 5-10 power per MP
				if efficiency < 3:
					self.add_issue("INFO", "BALANCE", spell.spell_id, spell.name,
								  f"Low MP efficiency ({efficiency:.1f} power/MP)")
				elif efficiency > 20:
					self.add_issue("INFO", "BALANCE", spell.spell_id, spell.name,
								  f"High MP efficiency ({efficiency:.1f} power/MP)")
		
		# Check item prices vs stats
		weapons = self.item_db.get_weapons()
		for weapon in weapons:
			if weapon.buy_price > 0 and weapon.equipment_stats.attack > 0:
				price_per_attack = weapon.buy_price / weapon.equipment_stats.attack
				
				# Typical is 50-100 gold per attack point
				if price_per_attack < 20:
					self.add_issue("INFO", "BALANCE", weapon.item_id, weapon.name,
								  f"Very cheap for stats ({price_per_attack:.0f} gold/attack)")
				elif price_per_attack > 200:
					self.add_issue("INFO", "BALANCE", weapon.item_id, weapon.name,
								  f"Very expensive for stats ({price_per_attack:.0f} gold/attack)")
		
		print("  Balance checks complete")
		print()
	
	def print_report(self):
		"""Print validation report"""
		print("=" * 70)
		print("VALIDATION REPORT")
		print("=" * 70)
		print()
		
		# Count by severity
		errors = [i for i in self.issues if i.severity == "ERROR"]
		warnings = [i for i in self.issues if i.severity == "WARNING"]
		info = [i for i in self.issues if i.severity == "INFO"]
		
		print(f"Total Issues: {len(self.issues)}")
		print(f"  Errors:   {len(errors)}")
		print(f"  Warnings: {len(warnings)}")
		print(f"  Info:	 {len(info)}")
		print()
		
		# Print errors
		if errors:
			print("ERRORS:")
			print("-" * 70)
			for issue in errors:
				print(f"  {issue}")
			print()
		
		# Print warnings
		if warnings:
			print("WARNINGS:")
			print("-" * 70)
			for issue in warnings:
				print(f"  {issue}")
			print()
		
		# Print info (only first 20)
		if info:
			print(f"INFO ({len(info)} total, showing first 20):")
			print("-" * 70)
			for issue in info[:20]:
				print(f"  {issue}")
			if len(info) > 20:
				print(f"  ... and {len(info) - 20} more")
			print()
		
		# Summary by category
		by_category: Dict[str, List[ValidationIssue]] = {}
		for issue in self.issues:
			if issue.category not in by_category:
				by_category[issue.category] = []
			by_category[issue.category].append(issue)
		
		print("BY CATEGORY:")
		print("-" * 70)
		for category in sorted(by_category.keys()):
			issues = by_category[category]
			errors_count = len([i for i in issues if i.severity == "ERROR"])
			warnings_count = len([i for i in issues if i.severity == "WARNING"])
			info_count = len([i for i in issues if i.severity == "INFO"])
			
			print(f"  {category:10s}: {len(issues):3d} total "
				  f"({errors_count} errors, {warnings_count} warnings, {info_count} info)")
		print()
		
		print("=" * 70)
		
		if errors:
			print("VALIDATION FAILED - Errors found!")
			return False
		else:
			print("VALIDATION PASSED - No errors!")
			return True
	
	def export_report(self, output_path: str):
		"""Export validation report to file"""
		with open(output_path, 'w') as f:
			f.write("FFMQ ROM Validation Report\n")
			f.write("=" * 70 + "\n\n")
			
			# Summary
			errors = [i for i in self.issues if i.severity == "ERROR"]
			warnings = [i for i in self.issues if i.severity == "WARNING"]
			info = [i for i in self.issues if i.severity == "INFO"]
			
			f.write(f"Total Issues: {len(self.issues)}\n")
			f.write(f"  Errors:   {len(errors)}\n")
			f.write(f"  Warnings: {len(warnings)}\n")
			f.write(f"  Info:	 {len(info)}\n\n")
			
			# All issues
			for issue in self.issues:
				f.write(f"{issue}\n")
		
		print(f"Report exported to: {output_path}")


def main():
	"""Main entry point"""
	import sys
	
	if len(sys.argv) < 2:
		print("Usage: python validator.py <rom_file> [output_report.txt]")
		sys.exit(1)
	
	rom_path = sys.argv[1]
	output_path = sys.argv[2] if len(sys.argv) > 2 else None
	
	validator = ROMValidator()
	validator.load_rom(rom_path)
	validator.validate_all()
	
	success = validator.print_report()
	
	if output_path:
		validator.export_report(output_path)
	
	sys.exit(0 if success else 1)


if __name__ == '__main__':
	main()
