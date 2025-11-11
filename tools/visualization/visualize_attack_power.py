#!/usr/bin/env python3
"""
Attack Power Distribution Visualization

Creates visualizations showing distribution of attack power values,
categorized by action routine types. Helps understand damage scaling
and attack balance.

Output formats: PNG (charts)
"""

import json
import sys
from pathlib import Path
import matplotlib.pyplot as plt
import pandas as pd
from collections import defaultdict

# Add project root to path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))


# Action routine names (from Battle Mechanics docs)
ACTION_ROUTINE_NAMES = {
	0x00: "None",
	0x01: "Punch",
	0x02: "Sword",
	0x03: "Axe",
	0x04: "Claw",
	0x05: "Bomb",
	0x06: "Projectile",
	0x07: "MagicDamage1",
	0x08: "MagicDamage2",
	0x09: "MagicDamage3",
	0x0A: "MagicStatsDebuff",
	0x0B: "MagicUnknown2",
	0x0C: "Life",
	0x0D: "Heal",
	0x0E: "Cure",
	0x0F: "PhysicalDamage1",
	0x10: "PhysicalDamage2",
	0x11: "PhysicalDamage3",
	0x12: "PhysicalDamage4",
	0x13: "Ailments1",
	0x14: "PhysicalDamage5",
	0x15: "PhysicalDamage6",
	0x16: "PhysicalDamage7",
	0x17: "PhysicalDamage8",
	0x18: "PhysicalDamage9",
	0x19: "SelfDestruct",
	0x1A: "Multiply",
	0x1B: "Seed",
	0x1C: "PureDamage1",
	0x1D: "PureDamage2",
}


def load_data():
	"""Load attack data."""
	data_dir = project_root / "data" / "extracted" / "attacks"

	with open(data_dir / "attacks.json", "r") as f:
		attacks_data = json.load(f)
		attacks = attacks_data["attacks"]

	return attacks


def categorize_attacks(attacks):
	"""Categorize attacks by action routine."""
	categories = defaultdict(list)

	for attack in attacks:
		routine_id = attack.get("attack_type", 0)
		routine_name = ACTION_ROUTINE_NAMES.get(routine_id, f"Unknown_{routine_id:02X}")

		categories[routine_name].append({
			"id": attack["id"],
			"power": attack["power"],
			"sound": attack.get("attack_sound", 0)
		})

	return categories


def visualize_power_distribution(attacks, output_path):
	"""Create histogram of attack power distribution."""
	powers = [a["power"] for a in attacks]

	fig, ax = plt.subplots(figsize=(14, 6))

	# Create histogram with custom bins
	bins = range(0, max(powers) + 20, 10)
	n, bins, patches = ax.hist(powers, bins=bins, edgecolor='black',
							   alpha=0.7, color='steelblue')

	# Color highest bars differently
	cm = plt.cm.RdYlGn_r
	norm = plt.Normalize(vmin=0, vmax=max(n))
	for patch, count in zip(patches, n):
		patch.set_facecolor(cm(norm(count)))

	ax.set_xlabel('Attack Power', fontsize=12)
	ax.set_ylabel('Number of Attacks', fontsize=12)
	ax.set_title('Attack Power Distribution (All 169 Attacks)',
				fontsize=14, pad=15)
	ax.grid(axis='y', alpha=0.3)

	# Add statistics text
	stats_text = f'Mean: {sum(powers)/len(powers):.1f}\n'
	stats_text += f'Median: {sorted(powers)[len(powers)//2]}\n'
	stats_text += f'Range: {min(powers)}-{max(powers)}'

	ax.text(0.98, 0.97, stats_text, transform=ax.transAxes,
		   fontsize=10, verticalalignment='top', horizontalalignment='right',
		   bbox=dict(boxstyle='round', facecolor='wheat', alpha=0.5))

	plt.tight_layout()
	plt.savefig(output_path, dpi=150, bbox_inches='tight')
	print(f"✅ Created power distribution: {output_path}")
	plt.close()


def visualize_power_by_routine(categories, output_path):
	"""Create box plot of power distribution by action routine."""
	# Filter to routines with meaningful power values
	data_for_plot = []
	labels = []

	for routine_name in sorted(categories.keys()):
		attacks = categories[routine_name]
		powers = [a["power"] for a in attacks]

		# Skip routines where all attacks have 0 power (healing, etc.)
		if max(powers) > 0:
			data_for_plot.append(powers)
			labels.append(f"{routine_name}\n(n={len(attacks)})")

	fig, ax = plt.subplots(figsize=(16, 8))

	bp = ax.boxplot(data_for_plot, labels=labels, patch_artist=True,
				   showmeans=True, meanline=True)

	# Color boxes
	colors = plt.cm.tab20(range(len(data_for_plot)))
	for patch, color in zip(bp['boxes'], colors):
		patch.set_facecolor(color)
		patch.set_alpha(0.6)

	ax.set_xlabel('Action Routine Type', fontsize=12)
	ax.set_ylabel('Attack Power', fontsize=12)
	ax.set_title('Attack Power Distribution by Action Routine Type\n'
				'(Box = IQR, Orange Line = Median, Green Line = Mean)',
				fontsize=14, pad=15)
	ax.grid(axis='y', alpha=0.3)

	plt.setp(ax.get_xticklabels(), rotation=45, ha='right', fontsize=9)
	plt.tight_layout()
	plt.savefig(output_path, dpi=150, bbox_inches='tight')
	print(f"✅ Created power by routine: {output_path}")
	plt.close()


def visualize_top_attacks(attacks, output_path, top_n=25):
	"""Create horizontal bar chart of most powerful attacks."""
	# Sort by power
	sorted_attacks = sorted(attacks, key=lambda x: x["power"], reverse=True)[:top_n]

	names = [f"Attack_{a['id']}" for a in sorted_attacks]
	powers = [a["power"] for a in sorted_attacks]

	fig, ax = plt.subplots(figsize=(12, 12))

	y_pos = range(len(names))
	colors = plt.cm.Reds_r([(p - min(powers)) / (max(powers) - min(powers))
							for p in powers])

	ax.barh(y_pos, powers, color=colors, alpha=0.8, edgecolor='black')
	ax.set_yticks(y_pos)
	ax.set_yticklabels(names, fontsize=9)
	ax.invert_yaxis()
	ax.set_xlabel('Attack Power', fontsize=12)
	ax.set_title(f'Top {top_n} Most Powerful Attacks', fontsize=14, pad=15)
	ax.grid(axis='x', alpha=0.3)

	# Add value labels
	for i, v in enumerate(powers):
		ax.text(v + 1, i, str(v), va='center', fontsize=8)

	plt.tight_layout()
	plt.savefig(output_path, dpi=150, bbox_inches='tight')
	print(f"✅ Created top attacks chart: {output_path}")
	plt.close()


def generate_statistics(attacks, categories):
	"""Generate and print attack statistics."""
	print("\n" + "="*70)
	print("ATTACK POWER STATISTICS")
	print("="*70)

	powers = [a["power"] for a in attacks]

	print(f"\n📊 Overall Statistics:")
	print(f"  • Total Attacks: {len(attacks)}")
	print(f"  • Power Range: {min(powers)} - {max(powers)}")
	print(f"  • Mean Power: {sum(powers) / len(powers):.1f}")
	print(f"  • Median Power: {sorted(powers)[len(powers)//2]}")

	print(f"\n🎯 Power Tiers:")
	power_tiers = [
		(0, 0, "Zero"),
		(1, 50, "Low"),
		(51, 100, "Medium"),
		(101, 150, "High"),
		(151, 200, "Very High"),
		(201, 999, "Extreme")
	]

	for min_p, max_p, tier_name in power_tiers:
		count = sum(1 for p in powers if min_p <= p <= max_p)
		if count > 0:
			pct = (count / len(powers)) * 100
			print(f"  • {tier_name:10s} ({min_p:3d}-{max_p:3d}): {count:3d} attacks ({pct:5.1f}%)")

	print(f"\n🔥 Top 5 Most Powerful:")
	sorted_attacks = sorted(attacks, key=lambda x: x["power"], reverse=True)[:5]
	for i, attack in enumerate(sorted_attacks, 1):
		print(f"  {i}. Attack_{attack['id']:03d} - Power {attack['power']:3d}")

	print(f"\n📋 Action Routine Distribution:")
	for routine_name in sorted(categories.keys()):
		count = len(categories[routine_name])
		pct = (count / len(attacks)) * 100
		print(f"  • {routine_name:20s}: {count:3d} attacks ({pct:5.1f}%)")

	print("\n" + "="*70 + "\n")


def main():
	"""Main visualization workflow."""
	print("🎨 Attack Power Distribution Visualization Tool")
	print("=" * 70)

	# Create output directory
	output_dir = project_root / "reports" / "visualizations"
	output_dir.mkdir(parents=True, exist_ok=True)

	print("\n📂 Loading data...")
	attacks = load_data()

	print(f"✅ Loaded {len(attacks)} attacks")

	print("\n🔨 Categorizing attacks by routine...")
	categories = categorize_attacks(attacks)

	# Generate statistics
	generate_statistics(attacks, categories)

	print("🎨 Creating visualizations...")

	# 1. Overall power distribution histogram
	visualize_power_distribution(attacks,
								 output_dir / "attack_power_distribution.png")

	# 2. Power distribution by action routine
	visualize_power_by_routine(categories,
							   output_dir / "attack_power_by_routine.png")

	# 3. Top 25 most powerful attacks
	visualize_top_attacks(attacks,
						 output_dir / "top_attacks.png", top_n=25)

	# Export categorized data to CSV
	csv_dir = output_dir / "csv"
	csv_dir.mkdir(exist_ok=True)

	# Create DataFrame with all attacks and their categories
	df_data = []
	for routine_name, routine_attacks in categories.items():
		for attack in routine_attacks:
			df_data.append({
				"ID": attack["id"],
				"Power": attack["power"],
				"Action Routine": routine_name
			})

	df = pd.DataFrame(df_data)
	df.to_csv(csv_dir / "attacks_by_routine.csv", index=False)
	print(f"\n📊 Exported CSV file to: {csv_dir / 'attacks_by_routine.csv'}")

	print("\n" + "="*70)
	print("✨ Attack Power Visualization Complete!")
	print("="*70)
	print(f"\n📁 Output directory: {output_dir}")
	print("\nFiles created:")
	print("  • attack_power_distribution.png - Overall power histogram")
	print("  • attack_power_by_routine.png - Box plot by action routine")
	print("  • top_attacks.png - Top 25 most powerful attacks")
	print("  • csv/attacks_by_routine.csv - Categorized attack data")
	print()


if __name__ == "__main__":
	main()
