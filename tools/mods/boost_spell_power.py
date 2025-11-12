#!/usr/bin/env python3
"""
Example Mod: Boost Spell Power

Increases the power of all damage spells by 50%.
Makes magic more viable throughout the game.

Usage:
	python tools/mods/boost_spell_power.py

After running:
	python build.ps1
	# Test roms/ffmq_rebuilt.sfc in your emulator
"""

import json
from pathlib import Path


def boost_spell_power():
	"""Increase damage spell power by 50%"""
	# Get paths
	project_dir = Path(__file__).parent.parent.parent
	spells_file = project_dir / "data" / "spells" / "spells.json"

	print("=" * 60)
	print("FFMQ MOD: Boost Spell Power")
	print("=" * 60)

	# Load spell data
	print(f"\n📂 Loading: {spells_file}")
	with open(spells_file, 'r', encoding='utf-8') as f:
		data = json.load(f)

	# Define damage spells to boost
	damage_spells = ['Fire', 'Blizzard', 'Thunder', 'Aero', 'Quake',
					 'Flare', 'Meteor', 'White']

	print(f"\n⚡ Boosting spell power by 50%...\n")

	boosted_count = 0
	for spell in data['spells']:
		if spell['name'] in damage_spells:
			old_power = spell['power']
			spell['power'] = min(int(spell['power'] * 1.5), 255)  # Cap at 255

			# Also increase MP cost slightly
			old_mp = spell['mp_cost']
			spell['mp_cost'] = min(int(spell['mp_cost'] * 1.25), 99)  # Cap at 99

			# Show change
			print(f"  {spell['name']:12} Power: {old_power:3d} → {spell['power']:3d}  "
				  f"MP: {old_mp:2d} → {spell['mp_cost']:2d}")
			boosted_count += 1

	# Save modified data
	print(f"\n💾 Saving modified data...")
	with open(spells_file, 'w', encoding='utf-8') as f:
		json.dump(data, f, indent=2)

	print("\n" + "=" * 60)
	print(f"✅ SUCCESS! Boosted {boosted_count} spells!")
	print("=" * 60)
	print("\nNext steps:")
	print("  1. Run: python build.ps1")
	print("  2. Test: Open roms/ffmq_rebuilt.sfc in your emulator")
	print("  3. To revert: git restore data/spells/spells.json")
	print()


if __name__ == "__main__":
	boost_spell_power()
