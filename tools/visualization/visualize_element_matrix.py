#!/usr/bin/env python3
"""
Element Type Matrix Visualization

Creates heatmap visualizations showing enemy resistances and weaknesses
to different element types. Helps understand combat strategies and
enemy vulnerabilities.

Output formats: PNG (heatmaps)
"""

import json
import sys
from pathlib import Path
import matplotlib.pyplot as plt
import seaborn as sns
import pandas as pd
import numpy as np

# Add project root to path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))


def load_data():
    """Load enemy and element type data."""
    data_dir = project_root / "data"

    # Load enemies
    with open(data_dir / "extracted" / "enemies" / "enemies.json", "r") as f:
        enemies_data = json.load(f)
        enemies = enemies_data["enemies"]

    # Load element types
    with open(data_dir / "element_types.json", "r", encoding="utf-8") as f:
        elements_data = json.load(f)
        element_types = {e["id"]: e for e in elements_data["element_types"]}

    return enemies, element_types


def create_resistance_matrix(enemies, element_types):
    """Create matrix of enemy resistances."""
    # Filter to only status effects and elements (skip damage types for clarity)
    relevant_elements = {
        eid: e for eid, e in element_types.items()
        if e["category"] in ["status_effect", "element"]
    }

    # Sort elements by bit position
    sorted_elements = sorted(relevant_elements.items(), key=lambda x: x[1]["bit_position"])

    # Create matrix
    matrix = []
    enemy_names = []

    for enemy in enemies:
        row = []
        enemy_names.append(enemy["name"])

        # Get resistances - could be list (unparsed) or int (bitfield)
        resistances_data = enemy.get("resistances", 0)
        if isinstance(resistances_data, list):
            # Empty or unparsed - treat as 0
            resistances = 0
        else:
            resistances = resistances_data

        for elem_id, elem in sorted_elements:
            bit_value = int(elem["bit_value"], 16)  # Convert hex string to int
            # Check if enemy has this resistance
            has_resistance = (resistances & bit_value) != 0
            row.append(1 if has_resistance else 0)

        matrix.append(row)

    # Create DataFrame
    element_names = [e["name"] for _, e in sorted_elements]
    df = pd.DataFrame(matrix, index=enemy_names, columns=element_names)

    return df


def create_weakness_matrix(enemies, element_types):
    """Create matrix of enemy weaknesses."""
    # Filter to only elements (weaknesses are typically elemental)
    relevant_elements = {
        eid: e for eid, e in element_types.items()
        if e["category"] == "element"
    }

    # Sort elements by bit position
    sorted_elements = sorted(relevant_elements.items(), key=lambda x: x[1]["bit_position"])

    # Create matrix
    matrix = []
    enemy_names = []

    for enemy in enemies:
        row = []
        enemy_names.append(enemy["name"])

        # Get weaknesses - could be list (unparsed) or int (bitfield)
        weaknesses_data = enemy.get("weaknesses", 0)
        if isinstance(weaknesses_data, list):
            # Empty or unparsed - treat as 0
            weaknesses = 0
        else:
            weaknesses = weaknesses_data

        for elem_id, elem in sorted_elements:
            bit_value = int(elem["bit_value"], 16)  # Convert hex string to int
            # Check if enemy has this weakness
            has_weakness = (weaknesses & bit_value) != 0
            row.append(1 if has_weakness else 0)

        matrix.append(row)

    # Create DataFrame
    element_names = [e["name"] for _, e in sorted_elements]
    df = pd.DataFrame(matrix, index=enemy_names, columns=element_names)

    return df


def visualize_resistance_heatmap(df, output_path):
    """Create heatmap of enemy resistances."""
    # Filter to enemies with at least one resistance
    df_filtered = df[df.sum(axis=1) > 0]

    if df_filtered.empty:
        print("⚠️  No resistance data found in extracted enemies")
        return

    # Create figure
    fig, ax = plt.subplots(figsize=(12, max(10, len(df_filtered) * 0.3)))

    # Create heatmap
    sns.heatmap(df_filtered, cmap=['white', 'steelblue'], cbar=False,
                linewidths=0.5, linecolor='gray', square=True,
                ax=ax, annot=False)

    ax.set_title('Enemy Element Resistances\n(Blue = Resistant, White = Normal)',
                fontsize=14, pad=15)
    ax.set_xlabel('Element Type', fontsize=12)
    ax.set_ylabel('Enemy', fontsize=12)

    # Rotate labels
    plt.setp(ax.get_xticklabels(), rotation=45, ha='right', fontsize=10)
    plt.setp(ax.get_yticklabels(), rotation=0, fontsize=8)

    plt.tight_layout()
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    print(f"✅ Created resistance heatmap: {output_path}")
    print(f"   • Enemies with resistances: {len(df_filtered)}/{len(df)}")
    plt.close()


def visualize_weakness_heatmap(df, output_path):
    """Create heatmap of enemy weaknesses."""
    # Filter to enemies with at least one weakness
    df_filtered = df[df.sum(axis=1) > 0]

    if df_filtered.empty:
        print("⚠️  No weakness data found in extracted enemies")
        return

    # Create figure
    fig, ax = plt.subplots(figsize=(10, max(10, len(df_filtered) * 0.3)))

    # Create heatmap
    sns.heatmap(df_filtered, cmap=['white', 'orangered'], cbar=False,
                linewidths=0.5, linecolor='gray', square=True,
                ax=ax, annot=False)

    ax.set_title('Enemy Element Weaknesses\n(Red = Weak, White = Normal)',
                fontsize=14, pad=15)
    ax.set_xlabel('Element Type', fontsize=12)
    ax.set_ylabel('Enemy', fontsize=12)

    # Rotate labels
    plt.setp(ax.get_xticklabels(), rotation=45, ha='right', fontsize=10)
    plt.setp(ax.get_yticklabels(), rotation=0, fontsize=8)

    plt.tight_layout()
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    print(f"✅ Created weakness heatmap: {output_path}")
    print(f"   • Enemies with weaknesses: {len(df_filtered)}/{len(df)}")
    plt.close()


def create_element_summary(df_resist, df_weak):
    """Create summary statistics for element types."""
    print("\n" + "="*70)
    print("ELEMENT TYPE STATISTICS")
    print("="*70)

    print("\n📊 Resistance Summary:")
    resist_counts = df_resist.sum(axis=0).sort_values(ascending=False)
    for elem, count in resist_counts.items():
        if count > 0:
            pct = (count / len(df_resist)) * 100
            print(f"  • {elem:15s}: {count:2d} enemies ({pct:5.1f}%)")

    print("\n🎯 Weakness Summary:")
    weak_counts = df_weak.sum(axis=0).sort_values(ascending=False)
    for elem, count in weak_counts.items():
        if count > 0:
            pct = (count / len(df_weak)) * 100
            print(f"  • {elem:15s}: {count:2d} enemies ({pct:5.1f}%)")

    print("\n📈 Coverage:")
    enemies_with_resist = (df_resist.sum(axis=1) > 0).sum()
    enemies_with_weak = (df_weak.sum(axis=1) > 0).sum()

    print(f"  • Enemies with ≥1 resistance: {enemies_with_resist}/{len(df_resist)} "
          f"({enemies_with_resist/len(df_resist)*100:.1f}%)")
    print(f"  • Enemies with ≥1 weakness: {enemies_with_weak}/{len(df_weak)} "
          f"({enemies_with_weak/len(df_weak)*100:.1f}%)")

    print("\n" + "="*70 + "\n")


def visualize_element_distribution(df_resist, df_weak, output_path):
    """Create bar chart comparing resistance vs weakness distribution."""
    resist_counts = df_resist.sum(axis=0)
    weak_counts = df_weak.sum(axis=0)

    # Only show elements that have data
    all_elements = set(resist_counts.index) | set(weak_counts.index)

    fig, ax = plt.subplots(figsize=(12, 6))

    x = np.arange(len(all_elements))
    width = 0.35

    elements = sorted(all_elements)
    resist_values = [resist_counts.get(e, 0) for e in elements]
    weak_values = [weak_counts.get(e, 0) for e in elements]

    ax.bar(x - width/2, resist_values, width, label='Resistances',
           color='steelblue', alpha=0.8)
    ax.bar(x + width/2, weak_values, width, label='Weaknesses',
           color='orangered', alpha=0.8)

    ax.set_xlabel('Element Type', fontsize=12)
    ax.set_ylabel('Number of Enemies', fontsize=12)
    ax.set_title('Element Type Distribution Across Enemies\n(Resistances vs Weaknesses)',
                fontsize=14, pad=15)
    ax.set_xticks(x)
    ax.set_xticklabels(elements, rotation=45, ha='right')
    ax.legend(fontsize=11)
    ax.grid(axis='y', alpha=0.3)

    plt.tight_layout()
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    print(f"✅ Created element distribution chart: {output_path}")
    plt.close()


def main():
    """Main visualization workflow."""
    print("🎨 Element Type Matrix Visualization Tool")
    print("=" * 70)

    # Create output directory
    output_dir = project_root / "reports" / "visualizations"
    output_dir.mkdir(parents=True, exist_ok=True)

    print("\n📂 Loading data...")
    enemies, element_types = load_data()

    print(f"✅ Loaded {len(enemies)} enemies, {len(element_types)} element types")

    print("\n🔨 Building resistance matrix...")
    df_resist = create_resistance_matrix(enemies, element_types)

    print("🔨 Building weakness matrix...")
    df_weak = create_weakness_matrix(enemies, element_types)

    # Generate statistics
    create_element_summary(df_resist, df_weak)

    print("🎨 Creating visualizations...")

    # 1. Resistance heatmap
    visualize_resistance_heatmap(df_resist,
                                 output_dir / "element_resistance_matrix.png")

    # 2. Weakness heatmap
    visualize_weakness_heatmap(df_weak,
                              output_dir / "element_weakness_matrix.png")

    # 3. Element distribution comparison
    visualize_element_distribution(df_resist, df_weak,
                                   output_dir / "element_distribution.png")

    # Export CSV files for further analysis
    csv_dir = output_dir / "csv"
    csv_dir.mkdir(exist_ok=True)

    df_resist.to_csv(csv_dir / "enemy_resistances.csv")
    df_weak.to_csv(csv_dir / "enemy_weaknesses.csv")
    print(f"\n📊 Exported CSV files to: {csv_dir}")

    print("\n" + "="*70)
    print("✨ Element Matrix Visualization Complete!")
    print("="*70)
    print(f"\n📁 Output directory: {output_dir}")
    print("\nFiles created:")
    print("  • element_resistance_matrix.png - Enemy resistances heatmap")
    print("  • element_weakness_matrix.png - Enemy weaknesses heatmap")
    print("  • element_distribution.png - Element usage comparison")
    print("  • csv/enemy_resistances.csv - Resistance data export")
    print("  • csv/enemy_weaknesses.csv - Weakness data export")
    print()


if __name__ == "__main__":
    main()
