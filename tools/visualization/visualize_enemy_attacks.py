#!/usr/bin/env python3
"""
Enemy Attack Network Visualization

Creates network graph showing relationships between enemies and their available attacks.
Reads data from extracted enemy attack links and generates visual network diagrams.

Output formats: PNG, SVG, GraphML
"""

import json
import sys
from pathlib import Path
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import networkx as nx
from collections import defaultdict

# Add project root to path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))


def load_data():
	"""Load enemy, attack, and link data."""
	data_dir = project_root / "data" / "extracted"

	# Load enemies
	with open(data_dir / "enemies" / "enemies.json", "r") as f:
		enemies_data = json.load(f)
		enemies = {e["id"]: e for e in enemies_data["enemies"]}

	# Load attacks
	with open(data_dir / "attacks" / "attacks.json", "r") as f:
		attacks_data = json.load(f)
		attacks = {a["id"]: a for a in attacks_data["attacks"]}

	# Load enemy attack links
	with open(data_dir / "enemy_attack_links" / "enemy_attack_links.json", "r") as f:
		links_data = json.load(f)
		links = links_data["attack_links"]

	return enemies, attacks, links


def create_network_graph(enemies, attacks, links):
	"""Create network graph with enemies and attacks as nodes."""
	G = nx.Graph()

	# Add enemy nodes
	for enemy_id, enemy in enemies.items():
		G.add_node(f"E{enemy_id}",
				   type="enemy",
				   name=enemy["name"],
				   hp=enemy["hp"])

	# Add attack nodes and edges
	attack_usage = defaultdict(int)  # Track how many enemies use each attack

	for link in links:
		enemy_id = link["enemy_id"]
		enemy_node = f"E{enemy_id}"

		# Extract attack IDs from attack1-6 fields
		attack_ids = [
			link.get("attack1", 0),
			link.get("attack2", 0),
			link.get("attack3", 0),
			link.get("attack4", 0),
			link.get("attack5", 0),
			link.get("attack6", 0)
		]

		for attack_id in attack_ids:
			if attack_id == 0:  # Skip empty slots
				continue

			attack_node = f"A{attack_id}"
			attack_usage[attack_id] += 1

			# Add attack node if not exists
			if attack_node not in G:
				attack_info = attacks.get(attack_id, {})
				G.add_node(attack_node,
						  type="attack",
						  name=attack_info.get("name", f"Unknown_{attack_id}"),
						  power=attack_info.get("power", 0))

			# Add edge from enemy to attack
			G.add_edge(enemy_node, attack_node)

	return G, attack_usage


def visualize_full_network(G, output_path):
	"""Create full network visualization."""
	plt.figure(figsize=(20, 20))

	# Separate nodes by type
	enemy_nodes = [n for n, d in G.nodes(data=True) if d.get("type") == "enemy"]
	attack_nodes = [n for n, d in G.nodes(data=True) if d.get("type") == "attack"]

	# Use spring layout for better positioning
	pos = nx.spring_layout(G, k=0.5, iterations=50, seed=42)

	# Draw enemy nodes (blue circles)
	nx.draw_networkx_nodes(G, pos, nodelist=enemy_nodes,
						  node_color='lightblue', node_size=300,
						  node_shape='o', alpha=0.8, label='Enemies')

	# Draw attack nodes (red squares)
	nx.draw_networkx_nodes(G, pos, nodelist=attack_nodes,
						  node_color='lightcoral', node_size=200,
						  node_shape='s', alpha=0.8, label='Attacks')

	# Draw edges
	nx.draw_networkx_edges(G, pos, alpha=0.2, width=0.5)

	# Draw labels (small font)
	labels = {n: d.get("name", n) for n, d in G.nodes(data=True)}
	nx.draw_networkx_labels(G, pos, labels, font_size=6)

	plt.title("Enemy-Attack Relationship Network\n(Enemies=Blue Circles, Attacks=Red Squares)",
			  fontsize=16, pad=20)
	plt.legend(loc='upper right', fontsize=12)
	plt.axis('off')
	plt.tight_layout()

	plt.savefig(output_path, dpi=150, bbox_inches='tight')
	print(f"✅ Created full network: {output_path}")
	plt.close()


def visualize_attack_popularity(attack_usage, attacks, output_path):
	"""Create bar chart of most-used attacks."""
	# Get top 20 most-used attacks
	sorted_attacks = sorted(attack_usage.items(), key=lambda x: x[1], reverse=True)[:20]

	attack_names = []
	usage_counts = []

	for attack_id, count in sorted_attacks:
		attack_info = attacks.get(attack_id, {})
		name = attack_info.get("name", f"Attack_{attack_id}")
		attack_names.append(name)
		usage_counts.append(count)

	# Create horizontal bar chart
	fig, ax = plt.subplots(figsize=(12, 10))

	y_pos = range(len(attack_names))
	colors = plt.cm.RdYlGn_r([(c - min(usage_counts)) / (max(usage_counts) - min(usage_counts))
							   for c in usage_counts])

	ax.barh(y_pos, usage_counts, color=colors, alpha=0.8)
	ax.set_yticks(y_pos)
	ax.set_yticklabels(attack_names)
	ax.invert_yaxis()
	ax.set_xlabel('Number of Enemies Using This Attack', fontsize=12)
	ax.set_title('Top 20 Most Common Enemy Attacks', fontsize=14, pad=15)
	ax.grid(axis='x', alpha=0.3)

	# Add value labels
	for i, v in enumerate(usage_counts):
		ax.text(v + 0.1, i, str(v), va='center', fontsize=9)

	plt.tight_layout()
	plt.savefig(output_path, dpi=150, bbox_inches='tight')
	print(f"✅ Created attack popularity chart: {output_path}")
	plt.close()


def visualize_bipartite_layout(G, output_path):
	"""Create bipartite layout with enemies on left, attacks on right."""
	plt.figure(figsize=(16, 20))

	# Separate nodes by type
	enemy_nodes = [n for n, d in G.nodes(data=True) if d.get("type") == "enemy"]
	attack_nodes = [n for n, d in G.nodes(data=True) if d.get("type") == "attack"]

	# Create bipartite layout
	pos = {}

	# Position enemies on left
	for i, node in enumerate(sorted(enemy_nodes)):
		pos[node] = (0, i * 2)

	# Position attacks on right
	for i, node in enumerate(sorted(attack_nodes)):
		pos[node] = (10, i * 0.8)

	# Draw enemy nodes (left side - blue)
	nx.draw_networkx_nodes(G, pos, nodelist=enemy_nodes,
						  node_color='lightblue', node_size=400,
						  node_shape='o', alpha=0.8)

	# Draw attack nodes (right side - red)
	nx.draw_networkx_nodes(G, pos, nodelist=attack_nodes,
						  node_color='lightcoral', node_size=250,
						  node_shape='s', alpha=0.8)

	# Draw edges
	nx.draw_networkx_edges(G, pos, alpha=0.15, width=0.5)

	# Draw labels
	enemy_labels = {n: G.nodes[n].get("name", n) for n in enemy_nodes}
	attack_labels = {n: G.nodes[n].get("name", n) for n in attack_nodes}

	nx.draw_networkx_labels(G, pos, enemy_labels, font_size=8,
						   horizontalalignment='right')
	nx.draw_networkx_labels(G, pos, attack_labels, font_size=7,
						   horizontalalignment='left')

	# Add legend
	enemy_patch = mpatches.Patch(color='lightblue', label='Enemies (83)')
	attack_patch = mpatches.Patch(color='lightcoral', label='Attacks (145 unique)')
	plt.legend(handles=[enemy_patch, attack_patch], loc='upper center',
			  bbox_to_anchor=(0.5, 1.02), fontsize=12)

	plt.title("Enemy-Attack Bipartite Network\n(Enemies ← → Attacks)",
			  fontsize=14, pad=20)
	plt.axis('off')
	plt.tight_layout()

	plt.savefig(output_path, dpi=150, bbox_inches='tight')
	print(f"✅ Created bipartite network: {output_path}")
	plt.close()


def export_graphml(G, output_path):
	"""Export network to GraphML format for use in other tools."""
	nx.write_graphml(G, output_path)
	print(f"✅ Exported GraphML: {output_path}")


def generate_statistics(enemies, attacks, links, attack_usage):
	"""Generate and print network statistics."""
	print("\n" + "="*70)
	print("ENEMY-ATTACK NETWORK STATISTICS")
	print("="*70)

	print(f"\n📊 Node Counts:")
	print(f"  • Enemies: {len(enemies)}")
	print(f"  • Total Attacks in ROM: {len(attacks)}")
	print(f"  • Unique Attacks Used by Enemies: {len(attack_usage)}")

	print(f"\n🔗 Edge Statistics:")
	total_connections = sum(len([1 for aid in [
		link.get("attack1", 0), link.get("attack2", 0), link.get("attack3", 0),
		link.get("attack4", 0), link.get("attack5", 0), link.get("attack6", 0)
	] if aid != 0]) for link in links)
	print(f"  • Total Enemy→Attack Connections: {total_connections}")
	print(f"  • Average Attacks per Enemy: {total_connections / len(links):.1f}")

	print(f"\n🎯 Attack Usage:")
	most_common = max(attack_usage.items(), key=lambda x: x[1])
	least_common = min(attack_usage.items(), key=lambda x: x[1])

	most_attack = attacks.get(most_common[0], {}).get("name", f"Attack_{most_common[0]}")
	least_attack = attacks.get(least_common[0], {}).get("name", f"Attack_{least_common[0]}")

	print(f"  • Most Common: {most_attack} ({most_common[1]} enemies)")
	print(f"  • Least Common: {least_attack} ({least_common[1]} enemy)")
	print(f"  • Average Usage per Attack: {total_connections / len(attack_usage):.1f} enemies")

	print("\n" + "="*70 + "\n")


def main():
	"""Main visualization workflow."""
	print("🎨 Enemy-Attack Network Visualization Tool")
	print("=" * 70)

	# Create output directory
	output_dir = project_root / "reports" / "visualizations"
	output_dir.mkdir(parents=True, exist_ok=True)

	print("\n📂 Loading data...")
	enemies, attacks, links = load_data()

	print("🔨 Building network graph...")
	G, attack_usage = create_network_graph(enemies, attacks, links)

	print(f"✅ Graph created: {G.number_of_nodes()} nodes, {G.number_of_edges()} edges")

	# Generate statistics
	generate_statistics(enemies, attacks, links, attack_usage)

	print("🎨 Creating visualizations...")

	# 1. Full network visualization
	visualize_full_network(G, output_dir / "enemy_attack_network.png")

	# 2. Bipartite layout
	visualize_bipartite_layout(G, output_dir / "enemy_attack_bipartite.png")

	# 3. Attack popularity chart
	visualize_attack_popularity(attack_usage, attacks,
								output_dir / "attack_popularity.png")

	# 4. Export to GraphML
	export_graphml(G, output_dir / "enemy_attack_network.graphml")

	print("\n" + "="*70)
	print("✨ Visualization Complete!")
	print("="*70)
	print(f"\n📁 Output directory: {output_dir}")
	print("\nFiles created:")
	print("  • enemy_attack_network.png - Full network graph")
	print("  • enemy_attack_bipartite.png - Bipartite layout")
	print("  • attack_popularity.png - Top 20 attacks chart")
	print("  • enemy_attack_network.graphml - Network data (import to Gephi, etc.)")
	print()


if __name__ == "__main__":
	main()
