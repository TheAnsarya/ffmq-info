"""
FFMQ ROM Comparison Tool

Compares two ROM files to identify changes in game data.
Useful for tracking modifications, debugging, and patch analysis.
"""

import sys
from pathlib import Path
from typing import List, Dict, Tuple, Any, Optional
from dataclasses import dataclass

sys.path.insert(0, str(Path(__file__).parent.parent))

from utils.enemy_database import EnemyDatabase
from utils.spell_database import SpellDatabase
from utils.item_database import ItemDatabase


@dataclass
class DataChange:
	"""Represents a change between ROM versions"""
	category: str  # ENEMY, SPELL, ITEM
	id: int
	name: str
	field: str
	old_value: Any
	new_value: Any
	
	def __str__(self) -> str:
		return f"{self.category} 0x{self.id:02X} '{self.name}': {self.field} changed from {self.old_value} → {self.new_value}"


class ROMComparator:
	"""Compares two ROM files"""
	
	def __init__(self):
		self.changes: List[DataChange] = []
	
	def compare_roms(self, rom1_path: str, rom2_path: str):
		"""Compare two ROM files"""
		print(f"Comparing ROMs:")
		print(f"  Original: {rom1_path}")
		print(f"  Modified: {rom2_path}")
		print()
		
		self.compare_enemies(rom1_path, rom2_path)
		self.compare_spells(rom1_path, rom2_path)
		self.compare_items(rom1_path, rom2_path)
	
	def add_change(self, category: str, id: int, name: str, field: str, old_value: Any, new_value: Any):
		"""Add a detected change"""
		self.changes.append(DataChange(category, id, name, field, old_value, new_value))
	
	def compare_enemies(self, rom1_path: str, rom2_path: str):
		"""Compare enemy data"""
		print("Comparing enemies...")
		
		db1 = EnemyDatabase()
		db1.load_from_rom(rom1_path)
		
		db2 = EnemyDatabase()
		db2.load_from_rom(rom2_path)
		
		# Compare each enemy
		for enemy_id in db1.enemies.keys():
			if enemy_id not in db2.enemies:
				continue
			
			enemy1 = db1.enemies[enemy_id]
			enemy2 = db2.enemies[enemy_id]
			
			# Name
			if enemy1.name != enemy2.name:
				self.add_change("ENEMY", enemy_id, enemy1.name, "name",
							   enemy1.name, enemy2.name)
			
			# Level
			if enemy1.level != enemy2.level:
				self.add_change("ENEMY", enemy_id, enemy1.name, "level",
							   enemy1.level, enemy2.level)
			
			# Stats
			for stat in ['hp', 'attack', 'defense', 'magic', 'magic_def', 'speed', 'accuracy', 'evasion']:
				val1 = getattr(enemy1.stats, stat)
				val2 = getattr(enemy2.stats, stat)
				if val1 != val2:
					self.add_change("ENEMY", enemy_id, enemy1.name, stat, val1, val2)
			
			# Resistances
			for element in ['fire', 'water', 'earth', 'wind', 'holy', 'dark', 'poison']:
				val1 = getattr(enemy1.resistances, element)
				val2 = getattr(enemy2.resistances, element)
				if val1 != val2:
					self.add_change("ENEMY", enemy_id, enemy1.name, f"{element}_resistance",
								   val1, val2)
			
			# Rewards
			if enemy1.exp != enemy2.exp:
				self.add_change("ENEMY", enemy_id, enemy1.name, "exp",
							   enemy1.exp, enemy2.exp)
			
			if enemy1.gold != enemy2.gold:
				self.add_change("ENEMY", enemy_id, enemy1.name, "gold",
							   enemy1.gold, enemy2.gold)
			
			# Flags
			if enemy1.flags != enemy2.flags:
				self.add_change("ENEMY", enemy_id, enemy1.name, "flags",
							   hex(enemy1.flags), hex(enemy2.flags))
		
		print(f"  Found {len([c for c in self.changes if c.category == 'ENEMY'])} enemy changes")
		print()
	
	def compare_spells(self, rom1_path: str, rom2_path: str):
		"""Compare spell data"""
		print("Comparing spells...")
		
		db1 = SpellDatabase()
		db1.load_from_rom(rom1_path)
		
		db2 = SpellDatabase()
		db2.load_from_rom(rom2_path)
		
		# Compare each spell
		for spell_id in db1.spells.keys():
			if spell_id not in db2.spells:
				continue
			
			spell1 = db1.spells[spell_id]
			spell2 = db2.spells[spell_id]
			
			# Name
			if spell1.name != spell2.name:
				self.add_change("SPELL", spell_id, spell1.name, "name",
							   spell1.name, spell2.name)
			
			# Basic properties
			if spell1.mp_cost != spell2.mp_cost:
				self.add_change("SPELL", spell_id, spell1.name, "mp_cost",
							   spell1.mp_cost, spell2.mp_cost)
			
			if spell1.power != spell2.power:
				self.add_change("SPELL", spell_id, spell1.name, "power",
							   spell1.power, spell2.power)
			
			if spell1.accuracy != spell2.accuracy:
				self.add_change("SPELL", spell_id, spell1.name, "accuracy",
							   spell1.accuracy, spell2.accuracy)
			
			# Element
			if spell1.element != spell2.element:
				self.add_change("SPELL", spell_id, spell1.name, "element",
							   spell1.element.name, spell2.element.name)
			
			# Target
			if spell1.target != spell2.target:
				self.add_change("SPELL", spell_id, spell1.name, "target",
							   spell1.target.name, spell2.target.name)
			
			# Flags
			if spell1.flags != spell2.flags:
				self.add_change("SPELL", spell_id, spell1.name, "flags",
							   hex(spell1.flags), hex(spell2.flags))
		
		print(f"  Found {len([c for c in self.changes if c.category == 'SPELL'])} spell changes")
		print()
	
	def compare_items(self, rom1_path: str, rom2_path: str):
		"""Compare item data"""
		print("Comparing items...")
		
		db1 = ItemDatabase()
		db1.load_from_rom(rom1_path)
		
		db2 = ItemDatabase()
		db2.load_from_rom(rom2_path)
		
		# Compare each item
		for item_id in db1.items.keys():
			if item_id not in db2.items:
				continue
			
			item1 = db1.items[item_id]
			item2 = db2.items[item_id]
			
			# Name
			if item1.name != item2.name:
				self.add_change("ITEM", item_id, item1.name, "name",
							   item1.name, item2.name)
			
			# Prices
			if item1.buy_price != item2.buy_price:
				self.add_change("ITEM", item_id, item1.name, "buy_price",
							   item1.buy_price, item2.buy_price)
			
			if item1.sell_price != item2.sell_price:
				self.add_change("ITEM", item_id, item1.name, "sell_price",
							   item1.sell_price, item2.sell_price)
			
			# Equipment stats
			if item1.is_equipment() and item2.is_equipment():
				for stat in ['attack', 'defense', 'magic', 'magic_def', 'speed']:
					val1 = getattr(item1.equipment_stats, stat)
					val2 = getattr(item2.equipment_stats, stat)
					if val1 != val2:
						self.add_change("ITEM", item_id, item1.name, stat, val1, val2)
			
			# Flags
			if item1.flags != item2.flags:
				self.add_change("ITEM", item_id, item1.name, "flags",
							   hex(item1.flags), hex(item2.flags))
		
		print(f"  Found {len([c for c in self.changes if c.category == 'ITEM'])} item changes")
		print()
	
	def print_report(self):
		"""Print comparison report"""
		print("=" * 80)
		print("ROM COMPARISON REPORT")
		print("=" * 80)
		print()
		
		if not self.changes:
			print("No changes detected!")
			print()
			return
		
		print(f"Total Changes: {len(self.changes)}")
		print()
		
		# Group by category
		by_category: Dict[str, List[DataChange]] = {}
		for change in self.changes:
			if change.category not in by_category:
				by_category[change.category] = []
			by_category[change.category].append(change)
		
		# Print each category
		for category in sorted(by_category.keys()):
			changes = by_category[category]
			print(f"{category} CHANGES ({len(changes)}):")
			print("-" * 80)
			
			# Group by ID
			by_id: Dict[int, List[DataChange]] = {}
			for change in changes:
				if change.id not in by_id:
					by_id[change.id] = []
				by_id[change.id].append(change)
			
			# Print each entity
			for entity_id in sorted(by_id.keys()):
				entity_changes = by_id[entity_id]
				name = entity_changes[0].name
				
				print(f"\n  0x{entity_id:02X} '{name}':")
				for change in entity_changes:
					print(f"	{change.field}: {change.old_value} → {change.new_value}")
			
			print()
		
		print("=" * 80)
	
	def export_report(self, output_path: str):
		"""Export comparison report to file"""
		with open(output_path, 'w') as f:
			f.write("FFMQ ROM Comparison Report\n")
			f.write("=" * 80 + "\n\n")
			
			if not self.changes:
				f.write("No changes detected!\n")
				return
			
			f.write(f"Total Changes: {len(self.changes)}\n\n")
			
			# Group by category
			by_category: Dict[str, List[DataChange]] = {}
			for change in self.changes:
				if change.category not in by_category:
					by_category[change.category] = []
				by_category[change.category].append(change)
			
			# Write each category
			for category in sorted(by_category.keys()):
				changes = by_category[category]
				f.write(f"{category} CHANGES ({len(changes)}):\n")
				f.write("-" * 80 + "\n\n")
				
				for change in changes:
					f.write(f"{change}\n")
				
				f.write("\n")
		
		print(f"Report exported to: {output_path}")
	
	def export_csv(self, output_path: str):
		"""Export changes to CSV"""
		import csv
		
		with open(output_path, 'w', newline='') as f:
			writer = csv.writer(f)
			writer.writerow(['Category', 'ID', 'Name', 'Field', 'Old Value', 'New Value'])
			
			for change in self.changes:
				writer.writerow([
					change.category,
					f"0x{change.id:02X}",
					change.name,
					change.field,
					change.old_value,
					change.new_value
				])
		
		print(f"CSV exported to: {output_path}")
	
	def get_summary(self) -> Dict[str, int]:
		"""Get summary statistics"""
		summary = {
			'total': len(self.changes),
			'enemies': len([c for c in self.changes if c.category == 'ENEMY']),
			'spells': len([c for c in self.changes if c.category == 'SPELL']),
			'items': len([c for c in self.changes if c.category == 'ITEM'])
		}
		
		# Count affected entities
		enemy_ids = set(c.id for c in self.changes if c.category == 'ENEMY')
		spell_ids = set(c.id for c in self.changes if c.category == 'SPELL')
		item_ids = set(c.id for c in self.changes if c.category == 'ITEM')
		
		summary['affected_enemies'] = len(enemy_ids)
		summary['affected_spells'] = len(spell_ids)
		summary['affected_items'] = len(item_ids)
		
		return summary


def main():
	"""Main entry point"""
	import sys
	
	if len(sys.argv) < 3:
		print("Usage: python comparator.py <original_rom> <modified_rom> [output_report.txt] [--csv output.csv]")
		sys.exit(1)
	
	rom1_path = sys.argv[1]
	rom2_path = sys.argv[2]
	
	# Parse optional arguments
	output_txt = None
	output_csv = None
	
	i = 3
	while i < len(sys.argv):
		if sys.argv[i] == '--csv' and i + 1 < len(sys.argv):
			output_csv = sys.argv[i + 1]
			i += 2
		else:
			output_txt = sys.argv[i]
			i += 1
	
	# Run comparison
	comparator = ROMComparator()
	comparator.compare_roms(rom1_path, rom2_path)
	comparator.print_report()
	
	# Get summary
	summary = comparator.get_summary()
	print("\nSUMMARY:")
	print(f"  Total changes: {summary['total']}")
	print(f"  Affected enemies: {summary['affected_enemies']}")
	print(f"  Affected spells: {summary['affected_spells']}")
	print(f"  Affected items: {summary['affected_items']}")
	print()
	
	# Export reports
	if output_txt:
		comparator.export_report(output_txt)
	
	if output_csv:
		comparator.export_csv(output_csv)


if __name__ == '__main__':
	main()
