#!/usr/bin/env python3
"""
Example Mod: Hard Mode

Creates a challenging "Hard Mode" by:
- Increasing enemy HP by 50%
- Boosting enemy attack/defense by 25%
- Reducing healing spell power by 30%
- Increasing spell MP costs by 20%

Usage:
	python tools/mods/hard_mode.py

After running:
	python build.ps1
	# Test roms/ffmq_rebuilt.sfc in your emulator
"""

import json
from pathlib import Path


def apply_hard_mode():
	"""Apply hard mode modifications"""
	project_dir = Path(__file__).parent.parent.parent

	print("=" * 60)
	print("FFMQ MOD: Hard Mode")
	print("=" * 60)

	# Modify enemies
	print("\n🔥 Making enemies tougher...")
	enemies_file = project_dir / "data" / "extracted" / "enemies" / "enemies.json"

	with open(enemies_file, 'r', encoding='utf-8') as f:
		enemy_data = json.load(f)

	for enemy in enemy_data['enemies']:
		# Increase HP by 50%
		enemy['hp'] = min(int(enemy['hp'] * 1.5), 65535)

		# Increase attack and defense by 25%
		enemy['attack'] = min(int(enemy['attack'] * 1.25), 255)
		enemy['defense'] = min(int(enemy['defense'] * 1.25), 255)
		enemy['magic'] = min(int(enemy['magic'] * 1.25), 255)
		enemy['magic_defense'] = min(int(enemy['magic_defense'] * 1.25), 255)

	with open(enemies_file, 'w', encoding='utf-8') as f:
		json.dump(enemy_data, f, indent=2)

	print(f"  ✅ Modified {len(enemy_data['enemies'])} enemies")

	# Modify spells
	print("\n⚡ Adjusting spell balance...")
	spells_file = project_dir / "data" / "spells" / "spells.json"

	with open(spells_file, 'r', encoding='utf-8') as f:
		spell_data = json.load(f)

	healing_spells = ['Cure', 'Heal', 'Life']
	modified_spells = 0

	for spell in spell_data['spells']:
		# Reduce healing power by 30%
		if spell['name'] in healing_spells:
			spell['power'] = max(int(spell['power'] * 0.7), 10)
			print(f"  🩹 {spell['name']:12} healing reduced to {spell['power']}")
			modified_spells += 1

		# Increase all MP costs by 20%
		if spell['mp_cost'] > 0:
			spell['mp_cost'] = min(int(spell['mp_cost'] * 1.2), 99)
			modified_spells += 1

	with open(spells_file, 'w', encoding='utf-8') as f:
		json.dump(spell_data, f, indent=2)

	print(f"  ✅ Modified {len(spell_data['spells'])} spells")

	print("\n" + "=" * 60)
	print("✅ SUCCESS! Hard Mode applied!")
	print("=" * 60)
	print("\nChanges:")
	print("  • Enemy HP: +50%")
	print("  • Enemy Attack/Defense: +25%")
	print("  • Healing Power: -30%")
	print("  • Spell MP Costs: +20%")
	print("\nNext steps:")
	print("  1. Run: python build.ps1")
	print("  2. Test: Open roms/ffmq_rebuilt.sfc in your emulator")
	print("  3. To revert: git restore data/extracted/enemies/enemies.json data/spells/spells.json")
	print("\nGood luck! You'll need it! 💀")
	print()


if __name__ == "__main__":
	apply_hard_mode()
