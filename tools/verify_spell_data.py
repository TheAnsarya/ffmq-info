#!/usr/bin/env python3
"""
Verify extracted spell data against known game facts
"""

import json
from pathlib import Path

# Known spell information from game documentation
KNOWN_SPELLS = {
    'Cure': {'type': 'White', 'element': 'None', 'power_range': (10, 20)},
    'Heal': {'type': 'White', 'element': 'None', 'power_range': (8, 15)},
    'Life': {'type': 'White', 'element': 'None', 'power_range': (10, 20)},
    'Exit': {'type': 'White', 'element': 'None', 'power_range': (10, 20)},
    'Fire': {'type': 'Black', 'element': 'Fire', 'power_range': (20, 40)},
    'Blizzard': {'type': 'Black', 'element': 'Water', 'power_range': (60, 80)},
    'Thunder': {'type': 'Black', 'element': 'Wind', 'power_range': (30, 50)},
    'Quake': {'type': 'Black', 'element': 'Earth', 'power_range': (70, 90)},
    'Meteor': {'type': 'Wizard', 'element': 'None', 'power_range': (40, 60)},
    'Flare': {'type': 'Wizard', 'element': 'Fire', 'power_range': (80, 100)},
    'Teleport': {'type': 'Wizard', 'element': 'None', 'power_range': (50, 70)},
}

def verify_spells():
    """Verify extracted spell data"""

    json_path = Path('data/extracted/spells/spells.json')

    if not json_path.exists():
        print("❌ Spell data not found at", json_path)
        return

    with open(json_path, 'r') as f:
        data = json.load(f)

    extracted_spells = data.get('spells', [])

    print("="*80)
    print("Spell Data Verification")
    print("="*80)
    print()

    issues = []

    for spell in extracted_spells[:11]:  # Only check first 11 (known spells)
        name = spell['name']

        if name not in KNOWN_SPELLS:
            continue

        known = KNOWN_SPELLS[name]
        print(f"\n{name} (ID {spell['id']}):")
        print(f"  Extracted type: {spell['spell_type']}")
        print(f"  Expected type:  {known['type']}")

        if spell['spell_type'] != known['type']:
            issues.append(f"  ❌ Type mismatch for {name}")
        else:
            print(f"  ✅ Type correct")

        print(f"  Extracted element: {spell['element']}")
        print(f"  Expected element:  {known['element']}")

        if spell['element'] != known['element']:
            issues.append(f"  ❌ Element mismatch for {name}")
        else:
            print(f"  ✅ Element correct")

        power = spell['power']
        min_power, max_power = known['power_range']
        print(f"  Extracted power: {power}")
        print(f"  Expected range:  {min_power}-{max_power}")

        if min_power <= power <= max_power:
            print(f"  ✅ Power in range")
        else:
            issues.append(f"  ❌ Power out of range for {name}")

    print("\n" + "="*80)
    print("Summary")
    print("="*80)

    if issues:
        print(f"\n⚠️  Found {len(issues)} issues:")
        for issue in issues:
            print(issue)
        print("\nConclusion: Data structure may be incorrect or address may be wrong")
    else:
        print("\n✅ All spell data verified successfully!")

    print()

if __name__ == '__main__':
    verify_spells()
