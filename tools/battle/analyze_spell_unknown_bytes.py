#!/usr/bin/env python3
"""
Final Fantasy Mystic Quest - Spell Unknown Bytes Analysis
Research the purpose of byte1 and byte2 in spell data structure

Issue #58: Research spell data unknown bytes (byte 1-2)
"""

import json
import csv
from pathlib import Path
from typing import Dict, List, Tuple
from collections import Counter

class SpellByteAnalyzer:
    """Analyze unknown bytes in FFMQ spell data"""

    def __init__(self):
        self.spells = []
        self.known_spells = [
            'Cure', 'Heal', 'Life', 'Exit',      # White Magic (0-3)
            'Fire', 'Blizzard', 'Thunder', 'Quake',  # Black Magic (4-7)
            'Meteor', 'Flare', 'Teleport'       # Wizard Magic (8-10)
        ]

    def load_spell_data(self, json_path: str = 'data/extracted/spells/spells.json'):
        """Load extracted spell data"""
        data_path = Path(json_path)
        if not data_path.exists():
            print(f"❌ Spell data not found: {data_path}")
            return False

        with open(data_path, 'r') as f:
            data = json.load(f)

        self.spells = data.get('spells', [])
        print(f"✓ Loaded {len(self.spells)} spells from {data_path}")
        return True

    def analyze_byte_patterns(self):
        """Analyze patterns in unknown bytes"""
        print("\n" + "="*70)
        print("SPELL UNKNOWN BYTES ANALYSIS")
        print("="*70)

        # Separate known vs unknown spells
        known_spells = [s for s in self.spells if s['name'] in self.known_spells]
        unknown_spells = [s for s in self.spells if s['name'] not in self.known_spells]

        print(f"\nSpell Categories:")
        print(f"  Known spells: {len(known_spells)} (IDs 0-10)")
        print(f"  Unknown spells: {len(unknown_spells)} (IDs 11-15)")

        # Analyze byte1 patterns
        self.analyze_byte1(known_spells, unknown_spells)

        # Analyze byte2 patterns
        self.analyze_byte2(known_spells, unknown_spells)

        # Look for correlations
        self.analyze_correlations()

    def analyze_byte1(self, known_spells: List[Dict], unknown_spells: List[Dict]):
        """Analyze byte1 patterns - hypothesis: level requirement"""
        print("\n" + "-"*50)
        print("BYTE1 ANALYSIS (Hypothesis: Level Requirement)")
        print("-"*50)

        # Collect byte1 values
        byte1_values = Counter()
        spell_by_byte1 = {}

        for spell in self.spells:
            byte1 = spell['byte1']
            byte1_values[byte1] += 1
            if byte1 not in spell_by_byte1:
                spell_by_byte1[byte1] = []
            spell_by_byte1[byte1].append(spell)

        print(f"Byte1 value distribution:")
        for value in sorted(byte1_values.keys()):
            count = byte1_values[value]
            spells_with_value = [s['name'] for s in spell_by_byte1[value]]
            print(f"  {value:2d}: {count} spell(s) - {', '.join(spells_with_value[:3])}")

        # Group by spell type
        print(f"\nByte1 by spell type:")
        for spell_type in ['White', 'Black', 'Wizard', 'Unknown']:
            spells_of_type = [s for s in self.spells if s['spell_type'] == spell_type]
            if spells_of_type:
                values = [s['byte1'] for s in spells_of_type]
                print(f"  {spell_type:7s}: {values} (avg: {sum(values)/len(values):.1f})")

        # Test level requirement hypothesis
        print(f"\nLevel Requirement Hypothesis Test:")
        print(f"  If byte1 = level requirement, expect:")
        print(f"    - Lower values for earlier/weaker spells")
        print(f"    - Higher values for advanced spells")
        print(f"    - Logical progression within spell types")

        # Show detailed progression
        for spell_type in ['White', 'Black', 'Wizard']:
            spells_of_type = [s for s in self.spells if s['spell_type'] == spell_type]
            if spells_of_type:
                spells_of_type.sort(key=lambda x: x['id'])
                print(f"\n  {spell_type} Magic progression:")
                for spell in spells_of_type:
                    print(f"    {spell['name']:8s} (ID {spell['id']:2d}): byte1={spell['byte1']:2d}, power={spell['power']:2d}")

    def analyze_byte2(self, known_spells: List[Dict], unknown_spells: List[Dict]):
        """Analyze byte2 patterns - purpose unknown"""
        print("\n" + "-"*50)
        print("BYTE2 ANALYSIS (Purpose Unknown)")
        print("-"*50)

        # Collect byte2 values
        byte2_values = Counter()
        spell_by_byte2 = {}

        for spell in self.spells:
            byte2 = spell['byte2']
            byte2_values[byte2] += 1
            if byte2 not in spell_by_byte2:
                spell_by_byte2[byte2] = []
            spell_by_byte2[byte2].append(spell)

        print(f"Byte2 value distribution:")
        for value in sorted(byte2_values.keys()):
            count = byte2_values[value]
            spells_with_value = [s['name'] for s in spell_by_byte2[value]]
            print(f"  {value:2d}: {count} spell(s) - {', '.join(spells_with_value[:3])}")

        # Group by spell type
        print(f"\nByte2 by spell type:")
        for spell_type in ['White', 'Black', 'Wizard', 'Unknown']:
            spells_of_type = [s for s in self.spells if s['spell_type'] == spell_type]
            if spells_of_type:
                values = [s['byte2'] for s in spells_of_type]
                print(f"  {spell_type:7s}: {values} (avg: {sum(values)/len(values):.1f})")

        # Look for patterns
        print(f"\nPossible patterns in byte2:")

        # Check if byte2 correlates with spell function
        healing_spells = ['Cure', 'Heal', 'Life']
        offensive_spells = ['Fire', 'Blizzard', 'Thunder', 'Quake', 'Meteor', 'Flare']
        utility_spells = ['Exit', 'Teleport']

        print(f"  Healing spells byte2: {[s['byte2'] for s in self.spells if s['name'] in healing_spells]}")
        print(f"  Offensive spells byte2: {[s['byte2'] for s in self.spells if s['name'] in offensive_spells]}")
        print(f"  Utility spells byte2: {[s['byte2'] for s in self.spells if s['name'] in utility_spells]}")

    def analyze_correlations(self):
        """Look for correlations between unknown bytes and known properties"""
        print("\n" + "-"*50)
        print("CORRELATION ANALYSIS")
        print("-"*50)

        # Correlate with power
        powers = [s['power'] for s in self.spells]
        byte1s = [s['byte1'] for s in self.spells]
        byte2s = [s['byte2'] for s in self.spells]

        print(f"Correlation with spell power:")
        print(f"  Byte1 vs Power: {self.simple_correlation(byte1s, powers):.3f}")
        print(f"  Byte2 vs Power: {self.simple_correlation(byte2s, powers):.3f}")

        # Show detailed data for manual analysis
        print(f"\nDetailed comparison (first 11 known spells):")
        print(f"{'Spell':<10} {'ID':<3} {'Type':<7} {'Power':<5} {'Byte1':<5} {'Byte2':<5}")
        print("-" * 40)

        for i, spell in enumerate(self.spells[:11]):
            print(f"{spell['name']:<10} {spell['id']:<3} {spell['spell_type']:<7} "
                  f"{spell['power']:<5} {spell['byte1']:<5} {spell['byte2']:<5}")

    def simple_correlation(self, x: List[int], y: List[int]) -> float:
        """Calculate simple correlation coefficient"""
        if len(x) != len(y) or len(x) < 2:
            return 0.0

        n = len(x)
        sum_x = sum(x)
        sum_y = sum(y)
        sum_xy = sum(x[i] * y[i] for i in range(n))
        sum_x2 = sum(x[i] * x[i] for i in range(n))
        sum_y2 = sum(y[i] * y[i] for i in range(n))

        numerator = n * sum_xy - sum_x * sum_y
        denominator = ((n * sum_x2 - sum_x * sum_x) * (n * sum_y2 - sum_y * sum_y)) ** 0.5

        if denominator == 0:
            return 0.0

        return numerator / denominator

    def generate_hypotheses(self):
        """Generate hypotheses about unknown bytes based on analysis"""
        print("\n" + "="*70)
        print("HYPOTHESES AND NEXT STEPS")
        print("="*70)

        print("\nByte1 Hypotheses:")
        print("  1. Level requirement for companion spell learning")
        print("  2. MP cost multiplier (though all spells cost 1 MP)")
        print("  3. Casting priority or speed modifier")
        print("  4. Animation timing parameter")

        print("\nByte2 Hypotheses:")
        print("  1. Spell category/function code")
        print("  2. Target selection behavior modifier")
        print("  3. Visual effect selection")
        print("  4. Success rate modifier")

        print("\nRecommended Next Steps:")
        print("  1. Search FFMQ community docs for spell learning progression")
        print("  2. Check companion level requirements for each spell")
        print("  3. ROM trace during spell casting to see byte usage")
        print("  4. Compare with similar RPG spell data structures")

def main():
    """Main analysis function"""
    analyzer = SpellByteAnalyzer()

    if not analyzer.load_spell_data():
        return

    analyzer.analyze_byte_patterns()
    analyzer.generate_hypotheses()

    print(f"\n✅ Analysis complete! Check output for patterns and hypotheses.")

if __name__ == '__main__':
    main()
