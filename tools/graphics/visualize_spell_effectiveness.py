#!/usr/bin/env python3
"""
FFMQ Spell Effectiveness Visualizer

Creates visualizations showing which spells are effective against which enemies
based on element types, resistances, and weaknesses.
"""

import json
import sys
from pathlib import Path
from typing import Dict, List, Set


class SpellEffectivenessVisualizer:
	"""Generate spell effectiveness charts"""
	
	# Element mappings
	SPELL_ELEMENTS = {
		"Fire": 0x2000,
		"Blizzard": 0x4000,
		"Thunder": 0x1000 | 0x4000,  # Air + Water
		"Aero": 0x1000,
		"Quake": 0x8000,
		"Cure": 0x4000,
		"Heal": 0x1000,
		"Life": 0x8000,
		"White": 0x4000,
		"Meteor": 0x8000,
		"Flare": 0x2000,
		"Exit": 0x8000
	}
	
	ELEMENT_NAMES = {
		0x0001: "Silence",
		0x0002: "Blind",
		0x0004: "Poison",
		0x0008: "Confusion",
		0x0010: "Sleep",
		0x0020: "Paralysis",
		0x0040: "Stone",
		0x0080: "Doom",
		0x0100: "Projectile",
		0x0200: "Bomb",
		0x0400: "Axe",
		0x0800: "Zombie",
		0x1000: "Air",
		0x2000: "Fire",
		0x4000: "Water",
		0x8000: "Earth"
	}
	
	def __init__(self, data_dir: Path):
		self.data_dir = data_dir
		self.enemies = []
		self.spells = []
		
	def load_data(self):
		"""Load enemy and spell data"""
		print("📊 Loading data...")
		
		# Load enemies
		enemies_file = self.data_dir / "extracted" / "enemies" / "enemies.json"
		with open(enemies_file, 'r', encoding='utf-8') as f:
			enemies_data = json.load(f)
			self.enemies = enemies_data['enemies']
		print(f"   ✅ Loaded {len(self.enemies)} enemies")
		
		# Load spells
		spells_file = self.data_dir / "spells" / "spells.json"
		with open(spells_file, 'r', encoding='utf-8') as f:
			spells_data = json.load(f)
			self.spells = spells_data['spells']
		print(f"   ✅ Loaded {len(self.spells)} spells")
	
	def calculate_effectiveness(self, spell_name: str, enemy: Dict) -> str:
		"""Calculate spell effectiveness against enemy"""
		if spell_name not in self.SPELL_ELEMENTS:
			return "?"
		
		spell_element = self.SPELL_ELEMENTS[spell_name]
		resistances = enemy.get('resistances', 0)
		weaknesses = enemy.get('weaknesses', 0)
		
		# Check if enemy is weak to any element in the spell
		if spell_element & weaknesses:
			return "Strong"  # Super effective
		
		# Check if enemy resists any element in the spell
		if spell_element & resistances:
			return "Weak"  # Not very effective
		
		return "Normal"  # Normal effectiveness
	
	def generate_effectiveness_matrix(self, output_file: Path):
		"""Generate spell effectiveness matrix"""
		print("\n📊 Generating effectiveness matrix...")
		
		# Filter to learnable spells only
		learnable_spells = ["Exit", "Cure", "Heal", "Life", "Quake", "Blizzard", 
							"Fire", "Aero", "Thunder", "White", "Meteor", "Flare"]
		
		# Prepare header
		header = ["Enemy_ID", "Enemy_Name"] + learnable_spells
		
		# Prepare rows
		rows = []
		for enemy in self.enemies:
			enemy_id = enemy['id']
			enemy_name = enemy.get('enemy_name', f'Enemy_{enemy_id}')
			
			row = [str(enemy_id), enemy_name]
			for spell_name in learnable_spells:
				effectiveness = self.calculate_effectiveness(spell_name, enemy)
				row.append(effectiveness)
			
			rows.append(row)
		
		# Write CSV
		with open(output_file, 'w', encoding='utf-8') as f:
			f.write(','.join(header) + '\n')
			for row in rows:
				f.write(','.join(row) + '\n')
		
		print(f"   ✅ Generated effectiveness matrix: {output_file}")
		print(f"   📊 Matrix size: {len(rows)} enemies × {len(learnable_spells)} spells")
	
	def generate_spell_recommendations(self, output_file: Path):
		"""Generate spell recommendations for each enemy"""
		print("\n💡 Generating spell recommendations...")
		
		learnable_spells = ["Exit", "Cure", "Heal", "Life", "Quake", "Blizzard",
							"Fire", "Aero", "Thunder", "White", "Meteor", "Flare"]
		
		lines = []
		lines.append("FFMQ Spell Effectiveness Recommendations")
		lines.append("=" * 80)
		lines.append("")
		lines.append("Shows which spells are most effective against each enemy")
		lines.append("")
		
		for enemy in self.enemies[:30]:  # First 30 enemies
			enemy_id = enemy['id']
			enemy_name = enemy.get('enemy_name', f'Enemy_{enemy_id}')
			hp = enemy.get('hp', 0)
			
			lines.append(f"\n{enemy_name} (ID: {enemy_id}, HP: {hp})")
			lines.append("-" * 60)
			
			# Find best spells
			strong_spells = []
			normal_spells = []
			weak_spells = []
			
			for spell_name in learnable_spells:
				effectiveness = self.calculate_effectiveness(spell_name, enemy)
				if effectiveness == "Strong":
					strong_spells.append(spell_name)
				elif effectiveness == "Normal":
					normal_spells.append(spell_name)
				elif effectiveness == "Weak":
					weak_spells.append(spell_name)
			
			if strong_spells:
				lines.append(f"  ⭐ SUPER EFFECTIVE: {', '.join(strong_spells)}")
			if normal_spells:
				lines.append(f"  ✓  Normal: {', '.join(normal_spells)}")
			if weak_spells:
				lines.append(f"  ✗  Not effective: {', '.join(weak_spells)}")
			
			# Show resistances and weaknesses
			resistances = enemy.get('resistances', 0)
			weaknesses = enemy.get('weaknesses', 0)
			
			resist_elements = [name for bit, name in self.ELEMENT_NAMES.items() if resistances & bit]
			weak_elements = [name for bit, name in self.ELEMENT_NAMES.items() if weaknesses & bit]
			
			if resist_elements:
				lines.append(f"  Resists: {', '.join(resist_elements)}")
			if weak_elements:
				lines.append(f"  Weak to: {', '.join(weak_elements)}")
		
		if len(self.enemies) > 30:
			lines.append(f"\n... and {len(self.enemies) - 30} more enemies")
		
		# Write file
		with open(output_file, 'w', encoding='utf-8') as f:
			f.write('\n'.join(lines))
		
		print(f"   ✅ Generated recommendations: {output_file}")
	
	def generate_spell_statistics(self, output_file: Path):
		"""Generate spell effectiveness statistics"""
		print("\n📊 Generating spell statistics...")
		
		learnable_spells = ["Exit", "Cure", "Heal", "Life", "Quake", "Blizzard",
							"Fire", "Aero", "Thunder", "White", "Meteor", "Flare"]
		
		# Count effectiveness for each spell
		spell_stats = {spell: {"Strong": 0, "Normal": 0, "Weak": 0} for spell in learnable_spells}
		
		for enemy in self.enemies:
			for spell_name in learnable_spells:
				effectiveness = self.calculate_effectiveness(spell_name, enemy)
				if effectiveness in spell_stats[spell_name]:
					spell_stats[spell_name][effectiveness] += 1
		
		# Write statistics
		lines = []
		lines.append("FFMQ Spell Effectiveness Statistics")
		lines.append("=" * 80)
		lines.append("")
		lines.append(f"Total Enemies: {len(self.enemies)}")
		lines.append("")
		
		lines.append("Spell Effectiveness Distribution:")
		lines.append("-" * 80)
		lines.append(f"{'Spell':<12s} | {'Super Effective':<18s} | {'Normal':<18s} | {'Not Effective':<18s}")
		lines.append("-" * 80)
		
		for spell in learnable_spells:
			stats = spell_stats[spell]
			strong_pct = (stats["Strong"] / len(self.enemies)) * 100
			normal_pct = (stats["Normal"] / len(self.enemies)) * 100
			weak_pct = (stats["Weak"] / len(self.enemies)) * 100
			
			lines.append(f"{spell:<12s} | {stats['Strong']:3d} ({strong_pct:5.1f}%) {'':<5s} | "
						f"{stats['Normal']:3d} ({normal_pct:5.1f}%) {'':<5s} | "
						f"{stats['Weak']:3d} ({weak_pct:5.1f}%)")
		
		lines.append("")
		lines.append("Best General Purpose Spells (Most Normal/Strong):")
		lines.append("-" * 80)
		
		# Rank spells by utility (normal + strong effectiveness)
		spell_utility = [(spell, stats["Strong"] + stats["Normal"]) 
						for spell, stats in spell_stats.items()]
		spell_utility.sort(key=lambda x: x[1], reverse=True)
		
		for i, (spell, utility_count) in enumerate(spell_utility[:5], 1):
			utility_pct = (utility_count / len(self.enemies)) * 100
			lines.append(f"{i}. {spell}: Effective against {utility_count} enemies ({utility_pct:.1f}%)")
		
		# Write file
		with open(output_file, 'w', encoding='utf-8') as f:
			f.write('\n'.join(lines))
		
		print(f"   ✅ Generated spell statistics: {output_file}")
	
	def run(self, output_dir: Path):
		"""Run complete visualization generation"""
		print("=" * 80)
		print("FFMQ Spell Effectiveness Visualizer")
		print("=" * 80)
		
		self.load_data()
		
		output_dir.mkdir(parents=True, exist_ok=True)
		
		# Generate outputs
		self.generate_effectiveness_matrix(output_dir / "spell_effectiveness_matrix.csv")
		self.generate_spell_recommendations(output_dir / "spell_recommendations.txt")
		self.generate_spell_statistics(output_dir / "spell_statistics.txt")
		
		print("\n✅ Spell effectiveness visualization complete!")
		print(f"📁 Output directory: {output_dir}")


def main():
	"""Main visualization function"""
	script_dir = Path(__file__).parent
	project_dir = script_dir.parent
	data_dir = project_dir / "data"
	output_dir = project_dir / "reports" / "visualizations"
	
	if not data_dir.exists():
		print(f"❌ Data directory not found: {data_dir}")
		return 1
	
	visualizer = SpellEffectivenessVisualizer(data_dir)
	visualizer.run(output_dir)
	
	return 0


if __name__ == "__main__":
	sys.exit(main())
