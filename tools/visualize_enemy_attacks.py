#!/usr/bin/env python3
"""
FFMQ Enemy Attack Network Visualizer

Creates network graph visualizations showing relationships between enemies and attacks.
Generates GraphML and DOT format outputs for further analysis.
"""

import json
import sys
from pathlib import Path
from typing import Dict, List, Set, Tuple


class EnemyAttackNetworkVisualizer:
	"""Generate network graph of enemy-attack relationships"""

	def __init__(self, data_dir: Path):
		self.data_dir = data_dir
		self.enemies = {}
		self.attacks = {}
		self.attack_links = []

	def load_data(self):
		"""Load enemy, attack, and link data"""
		print("📊 Loading data...")

		# Load enemies
		enemies_file = self.data_dir / "extracted" / "enemies" / "enemies.json"
		with open(enemies_file, 'r', encoding='utf-8') as f:
			enemies_data = json.load(f)
			self.enemies = {e['id']: e for e in enemies_data['enemies']}
		print(f"   ✅ Loaded {len(self.enemies)} enemies")

		# Load attacks
		attacks_file = self.data_dir / "extracted" / "attacks" / "attacks.json"
		with open(attacks_file, 'r', encoding='utf-8') as f:
			attacks_data = json.load(f)
			self.attacks = {a['id']: a for a in attacks_data['attacks']}
		print(f"   ✅ Loaded {len(self.attacks)} attacks")

		# Load attack links
		links_file = self.data_dir / "extracted" / "enemy_attack_links" / "enemy_attack_links.json"
		with open(links_file, 'r', encoding='utf-8') as f:
			links_data = json.load(f)
			self.attack_links = links_data['attack_links']
		print(f"   ✅ Loaded {len(self.attack_links)} attack link entries")

	def get_enemy_attacks(self, enemy_id: int) -> Set[int]:
		"""Get all attacks for a given enemy"""
		attacks = set()

		# Find link entry for this enemy
		for link in self.attack_links:
			if link['enemy_id'] == enemy_id:
				# Collect all attack IDs (attack1-attack6)
				for i in range(1, 7):
					attack_id = link.get(f'attack{i}', 255)
					if attack_id != 255 and attack_id < len(self.attacks):
						attacks.add(attack_id)
				break

		return attacks

	def generate_graphml(self, output_file: Path):
		"""Generate GraphML format network graph"""
		print("\n🔗 Generating GraphML network...")

		lines = []
		lines.append('<?xml version="1.0" encoding="UTF-8"?>')
		lines.append('<graphml xmlns="http://graphml.graphdrawing.org/xmlns"')
		lines.append('         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"')
		lines.append('         xsi:schemaLocation="http://graphml.graphdrawing.org/xmlns')
		lines.append('         http://graphml.graphdrawing.org/xmlns/1.0/graphml.xsd">')
		lines.append('')
		lines.append('  <!-- Node attributes -->')
		lines.append('  <key id="type" for="node" attr.name="type" attr.type="string"/>')
		lines.append('  <key id="name" for="node" attr.name="name" attr.type="string"/>')
		lines.append('  <key id="hp" for="node" attr.name="hp" attr.type="int"/>')
		lines.append('  <key id="power" for="node" attr.name="power" attr.type="int"/>')
		lines.append('')
		lines.append('  <graph id="FFMQ_EnemyAttacks" edgedefault="directed">')
		lines.append('')

		# Add enemy nodes
		lines.append('    <!-- Enemy nodes -->')
		for enemy_id, enemy in self.enemies.items():
			enemy_name = enemy.get('enemy_name', f'Enemy_{enemy_id}')
			hp = enemy.get('hp', 0)
			lines.append(f'    <node id="enemy_{enemy_id}">')
			lines.append(f'      <data key="type">enemy</data>')
			lines.append(f'      <data key="name">{enemy_name}</data>')
			lines.append(f'      <data key="hp">{hp}</data>')
			lines.append(f'    </node>')
		lines.append('')

		# Add attack nodes
		lines.append('    <!-- Attack nodes -->')
		for attack_id, attack in self.attacks.items():
			power = attack.get('power', 0)
			lines.append(f'    <node id="attack_{attack_id}">')
			lines.append(f'      <data key="type">attack</data>')
			lines.append(f'      <data key="name">Attack_{attack_id}</data>')
			lines.append(f'      <data key="power">{power}</data>')
			lines.append(f'    </node>')
		lines.append('')

		# Add edges (enemy -> attack relationships)
		lines.append('    <!-- Enemy-Attack edges -->')
		edge_count = 0
		for enemy_id in self.enemies.keys():
			attacks = self.get_enemy_attacks(enemy_id)
			for attack_id in attacks:
				lines.append(f'    <edge id="e{edge_count}" source="enemy_{enemy_id}" target="attack_{attack_id}"/>')
				edge_count += 1

		lines.append('')
		lines.append('  </graph>')
		lines.append('</graphml>')

		# Write file
		with open(output_file, 'w', encoding='utf-8') as f:
			f.write('\n'.join(lines))

		print(f"   ✅ Generated GraphML: {output_file}")
		print(f"   📊 Nodes: {len(self.enemies)} enemies + {len(self.attacks)} attacks")
		print(f"   🔗 Edges: {edge_count} enemy-attack links")

	def generate_dot(self, output_file: Path):
		"""Generate DOT format network graph"""
		print("\n🔗 Generating DOT graph...")

		lines = []
		lines.append('digraph FFMQ_EnemyAttacks {')
		lines.append('\trankdir=LR;')
		lines.append('\tnode [shape=box];')
		lines.append('')

		# Define enemy nodes
		lines.append('\t// Enemy nodes')
		lines.append('\tnode [style=filled, fillcolor=lightblue];')
		for enemy_id, enemy in self.enemies.items():
			enemy_name = enemy.get('enemy_name', f'Enemy_{enemy_id}')
			hp = enemy.get('hp', 0)
			label = f"{enemy_name}\\nHP: {hp}"
			lines.append(f'\tenemy_{enemy_id} [label="{label}"];')
		lines.append('')

		# Define attack nodes
		lines.append('\t// Attack nodes')
		lines.append('\tnode [style=filled, fillcolor=lightcoral];')
		for attack_id, attack in self.attacks.items():
			power = attack.get('power', 0)
			label = f"Attack {attack_id}\\nPower: {power}"
			lines.append(f'\tattack_{attack_id} [label="{label}"];')
		lines.append('')

		# Define edges
		lines.append('\t// Enemy-Attack relationships')
		edge_count = 0
		for enemy_id in self.enemies.keys():
			attacks = self.get_enemy_attacks(enemy_id)
			for attack_id in attacks:
				lines.append(f'\tenemy_{enemy_id} -> attack_{attack_id};')
				edge_count += 1

		lines.append('}')

		# Write file
		with open(output_file, 'w', encoding='utf-8') as f:
			f.write('\n'.join(lines))

		print(f"   ✅ Generated DOT: {output_file}")
		print(f"   🔗 Edges: {edge_count} enemy-attack links")

	def generate_statistics(self, output_file: Path):
		"""Generate network statistics"""
		print("\n📊 Generating statistics...")

		stats = {
			'total_enemies': len(self.enemies),
			'total_attacks': len(self.attacks),
			'enemy_attack_usage': {},
			'attack_user_counts': {},
			'most_used_attacks': [],
			'enemies_by_attack_count': {}
		}

		# Count attack usage
		attack_usage_count = {}
		for attack_id in self.attacks.keys():
			attack_usage_count[attack_id] = 0

		# Count attacks per enemy
		for enemy_id in self.enemies.keys():
			attacks = self.get_enemy_attacks(enemy_id)
			attack_count = len(attacks)

			# Track enemy attack count
			if attack_count not in stats['enemies_by_attack_count']:
				stats['enemies_by_attack_count'][attack_count] = []

			enemy_name = self.enemies[enemy_id].get('enemy_name', f'Enemy_{enemy_id}')
			stats['enemies_by_attack_count'][attack_count].append(enemy_name)

			# Count attack usage
			for attack_id in attacks:
				attack_usage_count[attack_id] += 1

		# Sort attacks by usage
		sorted_attacks = sorted(attack_usage_count.items(), key=lambda x: x[1], reverse=True)
		stats['most_used_attacks'] = [
			{
				'attack_id': attack_id,
				'usage_count': count,
				'power': self.attacks[attack_id].get('power', 0)
			}
			for attack_id, count in sorted_attacks[:20]  # Top 20
		]

		# Write statistics
		with open(output_file, 'w', encoding='utf-8') as f:
			f.write("FFMQ Enemy-Attack Network Statistics\n")
			f.write("=" * 50 + "\n\n")

			f.write(f"Total Enemies: {stats['total_enemies']}\n")
			f.write(f"Total Attacks: {stats['total_attacks']}\n\n")

			f.write("Enemies by Attack Count:\n")
			f.write("-" * 50 + "\n")
			for count in sorted(stats['enemies_by_attack_count'].keys(), reverse=True):
				enemies = stats['enemies_by_attack_count'][count]
				f.write(f"{count} attacks: {len(enemies)} enemies\n")
				for enemy in enemies[:5]:  # Show first 5
					f.write(f"  - {enemy}\n")
				if len(enemies) > 5:
					f.write(f"  ... and {len(enemies) - 5} more\n")
				f.write("\n")

			f.write("\nMost Used Attacks (Top 20):\n")
			f.write("-" * 50 + "\n")
			for i, attack_info in enumerate(stats['most_used_attacks'], 1):
				f.write(f"{i}. Attack {attack_info['attack_id']} - Used by {attack_info['usage_count']} enemies (Power: {attack_info['power']})\n")

		print(f"   ✅ Generated statistics: {output_file}")

	def run(self, output_dir: Path):
		"""Run complete visualization generation"""
		print("=" * 80)
		print("FFMQ Enemy-Attack Network Visualizer")
		print("=" * 80)

		self.load_data()

		output_dir.mkdir(parents=True, exist_ok=True)

		# Generate outputs
		self.generate_graphml(output_dir / "enemy_attack_network.graphml")
		self.generate_dot(output_dir / "enemy_attack_network.dot")
		self.generate_statistics(output_dir / "enemy_attack_statistics.txt")

		print("\n✅ Visualization generation complete!")
		print(f"📁 Output directory: {output_dir}")
		print("\nTo render DOT file to PNG:")
		print(f"  dot -Tpng {output_dir}/enemy_attack_network.dot -o {output_dir}/enemy_attack_network.png")


def main():
	"""Main visualization function"""
	script_dir = Path(__file__).parent
	project_dir = script_dir.parent
	data_dir = project_dir / "data"
	output_dir = project_dir / "reports" / "visualizations"

	if not data_dir.exists():
		print(f"❌ Data directory not found: {data_dir}")
		return 1

	visualizer = EnemyAttackNetworkVisualizer(data_dir)
	visualizer.run(output_dir)

	return 0


if __name__ == "__main__":
	sys.exit(main())
