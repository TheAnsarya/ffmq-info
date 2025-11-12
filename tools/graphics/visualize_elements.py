#!/usr/bin/env python3
"""
FFMQ Element Type Matrix Visualizer

Creates matrix visualizations showing enemy resistances and weaknesses
to different element types. Generates heatmap-style outputs.
"""

import json
import sys
from pathlib import Path
from typing import Dict, List


class ElementMatrixVisualizer:
	"""Generate element type resistance/weakness matrices"""
	
	# Element type bitflags (from FFMQ Randomizer)
	ELEMENTS = {
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
		
	def load_data(self):
		"""Load enemy data"""
		print("📊 Loading enemy data...")
		
		enemies_file = self.data_dir / "extracted" / "enemies" / "enemies.json"
		with open(enemies_file, 'r', encoding='utf-8') as f:
			enemies_data = json.load(f)
			self.enemies = enemies_data['enemies']
		
		print(f"   ✅ Loaded {len(self.enemies)} enemies")
	
	def parse_elements(self, bitfield: int) -> List[str]:
		"""Parse element bitfield into list of element names"""
		elements = []
		for bit, name in self.ELEMENTS.items():
			if bitfield & bit:
				elements.append(name)
		return elements
	
	def generate_csv_matrix(self, output_file: Path, matrix_type: str):
		"""Generate CSV matrix for resistances or weaknesses"""
		print(f"\n📊 Generating {matrix_type} matrix...")
		
		# Prepare header
		element_names = [name for _, name in sorted(self.ELEMENTS.items())]
		header = ["Enemy_ID", "Enemy_Name"] + element_names
		
		# Prepare rows
		rows = []
		for enemy in self.enemies:
			enemy_id = enemy['id']
			enemy_name = enemy.get('enemy_name', f'Enemy_{enemy_id}')
			
			# Get resistance or weakness bitfield
			if matrix_type == "resistances":
				bitfield = enemy.get('resistances', 0)
			else:  # weaknesses
				bitfield = enemy.get('weaknesses', 0)
			
			# Create row with 1/0 for each element
			row = [str(enemy_id), enemy_name]
			for bit, _ in sorted(self.ELEMENTS.items()):
				has_element = "1" if (bitfield & bit) else "0"
				row.append(has_element)
			
			rows.append(row)
		
		# Write CSV
		with open(output_file, 'w', encoding='utf-8') as f:
			f.write(','.join(header) + '\n')
			for row in rows:
				f.write(','.join(row) + '\n')
		
		print(f"   ✅ Generated {matrix_type} matrix: {output_file}")
		print(f"   📊 Matrix size: {len(rows)} enemies × {len(element_names)} elements")
	
	def generate_ascii_heatmap(self, output_file: Path):
		"""Generate ASCII heatmap of resistances and weaknesses"""
		print("\n🎨 Generating ASCII heatmap...")
		
		lines = []
		lines.append("FFMQ Enemy Element Resistances/Weaknesses Heatmap")
		lines.append("=" * 100)
		lines.append("")
		lines.append("Legend: R=Resistant, W=Weak, .=Normal")
		lines.append("")
		
		# Header with element abbreviations
		element_abbrev = {
			"Silence": "Sil",
			"Blind": "Bld",
			"Poison": "Psn",
			"Confusion": "Cnf",
			"Sleep": "Slp",
			"Paralysis": "Par",
			"Stone": "Stn",
			"Doom": "Doo",
			"Projectile": "Prj",
			"Bomb": "Bom",
			"Axe": "Axe",
			"Zombie": "Zmb",
			"Air": "Air",
			"Fire": "Fir",
			"Water": "Wat",
			"Earth": "Ear"
		}
		
		element_names = [name for _, name in sorted(self.ELEMENTS.items())]
		header = "  ID | Enemy Name		  | " + " ".join(element_abbrev[name] for name in element_names)
		lines.append(header)
		lines.append("-" * 100)
		
		# Generate rows
		for enemy in self.enemies[:30]:  # Show first 30 enemies
			enemy_id = enemy['id']
			enemy_name = enemy.get('enemy_name', f'Enemy_{enemy_id}')
			resistances = enemy.get('resistances', 0)
			weaknesses = enemy.get('weaknesses', 0)
			
			# Build element cells
			cells = []
			for bit, _ in sorted(self.ELEMENTS.items()):
				if resistances & bit:
					cells.append(" R ")
				elif weaknesses & bit:
					cells.append(" W ")
				else:
					cells.append(" . ")
			
			row = f"{enemy_id:4d} | {enemy_name:20s} | " + "".join(cells)
			lines.append(row)
		
		if len(self.enemies) > 30:
			lines.append(f"... and {len(self.enemies) - 30} more enemies")
		
		# Write file
		with open(output_file, 'w', encoding='utf-8') as f:
			f.write('\n'.join(lines))
		
		print(f"   ✅ Generated ASCII heatmap: {output_file}")
	
	def generate_element_statistics(self, output_file: Path):
		"""Generate element usage statistics"""
		print("\n📊 Generating element statistics...")
		
		# Count element usage
		resistance_counts = {name: 0 for name in self.ELEMENTS.values()}
		weakness_counts = {name: 0 for name in self.ELEMENTS.values()}
		
		for enemy in self.enemies:
			resistances = enemy.get('resistances', 0)
			weaknesses = enemy.get('weaknesses', 0)
			
			for bit, name in self.ELEMENTS.items():
				if resistances & bit:
					resistance_counts[name] += 1
				if weaknesses & bit:
					weakness_counts[name] += 1
		
		# Write statistics
		lines = []
		lines.append("FFMQ Element Type Statistics")
		lines.append("=" * 60)
		lines.append("")
		
		lines.append(f"Total Enemies: {len(self.enemies)}")
		lines.append("")
		
		lines.append("Element Resistance Distribution:")
		lines.append("-" * 60)
		sorted_resistances = sorted(resistance_counts.items(), key=lambda x: x[1], reverse=True)
		for element, count in sorted_resistances:
			percentage = (count / len(self.enemies)) * 100
			bar = "█" * int(percentage / 2)
			lines.append(f"{element:12s}: {count:3d} enemies ({percentage:5.1f}%) {bar}")
		
		lines.append("")
		lines.append("Element Weakness Distribution:")
		lines.append("-" * 60)
		sorted_weaknesses = sorted(weakness_counts.items(), key=lambda x: x[1], reverse=True)
		for element, count in sorted_weaknesses:
			percentage = (count / len(self.enemies)) * 100
			bar = "█" * int(percentage / 2)
			lines.append(f"{element:12s}: {count:3d} enemies ({percentage:5.1f}%) {bar}")
		
		lines.append("")
		lines.append("Most Common Resistances:")
		lines.append("-" * 60)
		for i, (element, count) in enumerate(sorted_resistances[:5], 1):
			lines.append(f"{i}. {element}: {count} enemies")
		
		lines.append("")
		lines.append("Most Common Weaknesses:")
		lines.append("-" * 60)
		for i, (element, count) in enumerate(sorted_weaknesses[:5], 1):
			lines.append(f"{i}. {element}: {count} enemies")
		
		# Write file
		with open(output_file, 'w', encoding='utf-8') as f:
			f.write('\n'.join(lines))
		
		print(f"   ✅ Generated element statistics: {output_file}")
	
	def run(self, output_dir: Path):
		"""Run complete visualization generation"""
		print("=" * 80)
		print("FFMQ Element Type Matrix Visualizer")
		print("=" * 80)
		
		self.load_data()
		
		output_dir.mkdir(parents=True, exist_ok=True)
		
		# Generate outputs
		self.generate_csv_matrix(output_dir / "enemy_resistances_matrix.csv", "resistances")
		self.generate_csv_matrix(output_dir / "enemy_weaknesses_matrix.csv", "weaknesses")
		self.generate_ascii_heatmap(output_dir / "element_heatmap.txt")
		self.generate_element_statistics(output_dir / "element_statistics.txt")
		
		print("\n✅ Element matrix visualization complete!")
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
	
	visualizer = ElementMatrixVisualizer(data_dir)
	visualizer.run(output_dir)
	
	return 0


if __name__ == "__main__":
	sys.exit(main())
