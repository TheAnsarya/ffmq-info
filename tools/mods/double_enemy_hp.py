#!/usr/bin/env python3
"""
Example Mod: Double Enemy HP

A simple mod that doubles the HP of all enemies in FFMQ.
This is a great starting point for learning how to mod the game.

Usage:
	python tools/mods/double_enemy_hp.py

After running:
	python build.ps1
	# Test roms/ffmq_rebuilt.sfc in your emulator
"""

import json
from pathlib import Path


def double_enemy_hp():
	"""Double all enemy HP values"""
	# Get paths
	project_dir = Path(__file__).parent.parent.parent
	enemies_file = project_dir / "data" / "extracted" / "enemies" / "enemies.json"

	print("=" * 60)
	print("FFMQ MOD: Double Enemy HP")
	print("=" * 60)

	# Load enemy data
	print(f"\n📂 Loading: {enemies_file}")
	with open(enemies_file, 'r', encoding='utf-8') as f:
		data = json.load(f)

	# Double all HP values
	print(f"\n💪 Doubling HP for {len(data['enemies'])} enemies...\n")

	for enemy in data['enemies']:
		old_hp = enemy['hp']
		enemy['hp'] = min(old_hp * 2, 65535)  # Cap at max 16-bit value

		# Show change
		change_pct = ((enemy['hp'] - old_hp) / max(old_hp, 1)) * 100
		print(f"  {enemy['name']:25} {old_hp:5d} → {enemy['hp']:5d} HP (+{change_pct:.0f}%)")

	# Save modified data
	print(f"\n💾 Saving modified data...")
	with open(enemies_file, 'w', encoding='utf-8') as f:
		json.dump(data, f, indent=2)

	print("\n" + "=" * 60)
	print("✅ SUCCESS! Enemy HP doubled!")
	print("=" * 60)
	print("\nNext steps:")
	print("  1. Run: python build.ps1")
	print("  2. Test: Open roms/ffmq_rebuilt.sfc in your emulator")
	print("  3. To revert: git restore data/extracted/enemies/enemies.json")
	print()


if __name__ == "__main__":
	double_enemy_hp()
