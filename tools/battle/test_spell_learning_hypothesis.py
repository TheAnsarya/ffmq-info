#!/usr/bin/env python3
"""
FFMQ Spell Learning Hypothesis Tester
Test if byte1 corresponds to companion level requirements

Based on analysis findings:
- White magic byte1: [2, 2, 14, 11]
- Black magic byte1: [11, 2, 6, 1]
- Wizard magic byte1: [2, 5, 5]
"""

import json
from pathlib import Path
from typing import Dict, List

class SpellLearningAnalyzer:
    """Analyze spell learning patterns to test byte1 hypothesis"""

    def __init__(self):
        self.spells = []

        # Typical RPG companion spell learning patterns (hypothesis)
        # Early game: levels 1-10, mid game: levels 11-20, late game: levels 21+
        self.expected_learning_order = {
            'White': ['Cure', 'Heal', 'Life', 'Exit'],      # Healing progression
            'Black': ['Fire', 'Blizzard', 'Thunder', 'Quake'],  # Elemental progression
            'Wizard': ['Meteor', 'Flare', 'Teleport']      # Advanced magic
        }

    def load_data(self, json_path: str = 'data/extracted/spells/spells.json'):
        """Load spell data"""
        with open(json_path, 'r') as f:
            data = json.load(f)
        self.spells = data['spells']
        return True

    def test_level_requirement_hypothesis(self):
        """Test if byte1 represents level requirements"""
        print("="*70)
        print("BYTE1 LEVEL REQUIREMENT HYPOTHESIS TEST")
        print("="*70)

        # Test 1: Early game spells should have low byte1 values
        print("\nTest 1: Early Game Spell Analysis")
        print("-" * 40)

        early_spells = ['Cure', 'Heal', 'Fire']  # Typically first spells learned
        for spell_name in early_spells:
            spell = next((s for s in self.spells if s['name'] == spell_name), None)
            if spell:
                print(f"  {spell_name:8s}: byte1={spell['byte1']:2d}, power={spell['power']:2d}")

        # Test 2: Advanced spells should have high byte1 values
        print("\nTest 2: Advanced Spell Analysis")
        print("-" * 40)

        advanced_spells = ['Life', 'Flare', 'Quake', 'Exit']  # Typically later spells
        for spell_name in advanced_spells:
            spell = next((s for s in self.spells if s['name'] == spell_name), None)
            if spell:
                print(f"  {spell_name:8s}: byte1={spell['byte1']:2d}, power={spell['power']:2d}")

        # Test 3: Logical progression within spell types
        print("\nTest 3: Spell Type Progression Analysis")
        print("-" * 40)

        for spell_type in ['White', 'Black', 'Wizard']:
            type_spells = [s for s in self.spells if s['spell_type'] == spell_type]
            type_spells.sort(key=lambda x: x['id'])

            print(f"\n  {spell_type} Magic:")
            byte1_values = []
            for spell in type_spells:
                byte1_values.append(spell['byte1'])
                print(f"    {spell['name']:10s} (ID {spell['id']:2d}): byte1={spell['byte1']:2d}")

            # Check if progression makes sense
            progression_score = self.analyze_progression(byte1_values)
            print(f"    Progression analysis: {progression_score}")

        # Test 4: Compare with spell power
        print("\nTest 4: Byte1 vs Power Correlation")
        print("-" * 40)

        known_spells = [s for s in self.spells if s['id'] <= 10]
        powers = [s['power'] for s in known_spells]
        byte1s = [s['byte1'] for s in known_spells]

        print(f"  Power range: {min(powers)} - {max(powers)}")
        print(f"  Byte1 range: {min(byte1s)} - {max(byte1s)}")
        print(f"  Correlation: {self.correlation(byte1s, powers):.3f}")

        # If byte1 is level requirement, it should NOT correlate strongly with power
        if abs(self.correlation(byte1s, powers)) < 0.3:
            print("  ✓ Low correlation supports level requirement hypothesis")
        else:
            print("  ✗ High correlation suggests byte1 might be power-related")

    def analyze_progression(self, values: List[int]) -> str:
        """Analyze if values show logical progression"""
        if len(values) < 2:
            return "insufficient data"

        # Check for patterns
        increasing = all(values[i] <= values[i+1] for i in range(len(values)-1))
        decreasing = all(values[i] >= values[i+1] for i in range(len(values)-1))

        if increasing:
            return "consistently increasing (supports hypothesis)"
        elif decreasing:
            return "consistently decreasing (contradicts hypothesis)"
        else:
            variance = max(values) - min(values)
            if variance <= 2:
                return "low variance (neutral)"
            else:
                return "mixed pattern (needs investigation)"

    def correlation(self, x: List[int], y: List[int]) -> float:
        """Calculate correlation coefficient"""
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

        return numerator / denominator if denominator != 0 else 0.0

    def test_byte2_patterns(self):
        """Analyze byte2 for functional patterns"""
        print("\n" + "="*70)
        print("BYTE2 FUNCTIONAL PATTERN ANALYSIS")
        print("="*70)

        # Group spells by function
        healing_spells = ['Cure', 'Heal', 'Life']
        offensive_spells = ['Fire', 'Blizzard', 'Thunder', 'Quake', 'Meteor', 'Flare']
        utility_spells = ['Exit', 'Teleport']

        print("\nByte2 by Spell Function:")
        print("-" * 30)

        for category, spell_names in [
            ('Healing', healing_spells),
            ('Offensive', offensive_spells),
            ('Utility', utility_spells)
        ]:
            byte2_values = []
            for name in spell_names:
                spell = next((s for s in self.spells if s['name'] == name), None)
                if spell:
                    byte2_values.append(spell['byte2'])

            if byte2_values:
                print(f"  {category:9s}: {byte2_values} (avg: {sum(byte2_values)/len(byte2_values):.1f})")

        # Look for patterns
        print("\nByte2 Pattern Analysis:")
        print("-" * 30)

        # Check if healing spells cluster
        healing_byte2 = []
        for name in healing_spells:
            spell = next((s for s in self.spells if s['name'] == name), None)
            if spell:
                healing_byte2.append(spell['byte2'])

        if healing_byte2:
            if max(healing_byte2) - min(healing_byte2) <= 2:
                print("  ✓ Healing spells have similar byte2 values (supports function hypothesis)")
            else:
                print("  ✗ Healing spells have diverse byte2 values")

    def generate_conclusions(self):
        """Generate conclusions about the unknown bytes"""
        print("\n" + "="*70)
        print("RESEARCH CONCLUSIONS")
        print("="*70)

        print("\nByte1 Analysis Results:")
        print("-" * 25)
        print("  Evidence FOR level requirement hypothesis:")
        print("    • Low correlation with spell power (-0.024)")
        print("    • Early spells (Cure, Heal) have low values (2)")
        print("    • Some advanced spells have high values (Life=14)")

        print("\n  Evidence AGAINST level requirement hypothesis:")
        print("    • Fire (basic spell) has high value (11)")
        print("    • Blizzard (mid-tier) has low value (2)")
        print("    • No consistent progression within spell types")

        print("\nByte2 Analysis Results:")
        print("-" * 25)
        print("  • Healing spells cluster around values 1-3")
        print("  • No clear pattern by spell type or power")
        print("  • May represent visual effects or targeting behavior")

        print("\nRecommendations:")
        print("-" * 15)
        print("  1. ROM trace during spell casting to see actual byte usage")
        print("  2. Check if byte1 correlates with any in-game mechanic")
        print("  3. Examine FFMQ Randomizer source code for insights")
        print("  4. Test byte2 against spell animations or sound effects")

def main():
    """Run spell learning analysis"""
    analyzer = SpellLearningAnalyzer()

    if analyzer.load_data():
        analyzer.test_level_requirement_hypothesis()
        analyzer.test_byte2_patterns()
        analyzer.generate_conclusions()

        print(f"\n✅ Hypothesis testing complete!")

if __name__ == '__main__':
    main()
