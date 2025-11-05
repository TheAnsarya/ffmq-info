#!/usr/bin/env python3
"""
Example Mod: Elemental Weaknesses

Gives all enemies at least one elemental weakness.
Makes strategic spell use more rewarding.

Usage:
	python tools/mods/add_elemental_weaknesses.py

After running:
	python build.ps1
	# Test roms/ffmq_rebuilt.sfc in your emulator
"""

import json
import random
from pathlib import Path


# Element bitfield values
ELEMENTS = {
	'Fire':  0x2000,
	'Water': 0x4000,
	'Earth': 0x8000,
	'Air':   0x1000,
}


def add_elemental_weaknesses():
	"""Give all enemies at least one elemental weakness"""
	project_dir = Path(__file__).parent.parent.parent
	enemies_file = project_dir / "data" / "extracted" / "enemies" / "enemies.json"

	print("=" * 60)
	print("FFMQ MOD: Elemental Weaknesses")
	print("=" * 60)

	# Load enemy data
	print(f"\n📂 Loading: {enemies_file}")
	with open(enemies_file, 'r', encoding='utf-8') as f:
		data = json.load(f)

	print(f"\n🔮 Adding elemental weaknesses...\n")

	modified_count = 0
	for enemy in data['enemies']:
		# If enemy has no weaknesses, give them 1-2 random ones
		if enemy['weaknesses'] == 0:
			# Pick 1-2 random elements
			num_weaknesses = random.randint(1, 2)
			chosen_elements = random.sample(list(ELEMENTS.items()), num_weaknesses)

			# Set weaknesses
			enemy['weaknesses'] = 0
			for element_name, element_value in chosen_elements:
				enemy['weaknesses'] |= element_value

			# Report
			weakness_names = [name for name, val in ELEMENTS.items()
			                  if enemy['weaknesses'] & val]
			print(f"  {enemy['name']:25} → Weak to: {', '.join(weakness_names)}")
			modified_count += 1
		else:
			# Enemy already has weaknesses
			weakness_names = [name for name, val in ELEMENTS.items()
			                  if enemy['weaknesses'] & val]
			if weakness_names:
				print(f"  {enemy['name']:25} (already weak to: {', '.join(weakness_names)})")

	# Save modified data
	print(f"\n💾 Saving modified data...")
	with open(enemies_file, 'w', encoding='utf-8') as f:
		json.dump(data, f, indent=2)

	print("\n" + "=" * 60)
	print(f"✅ SUCCESS! Added weaknesses to {modified_count} enemies!")
	print("=" * 60)
	print("\nNext steps:")
	print("  1. Run: python build.ps1")
	print("  2. Test: Open roms/ffmq_rebuilt.sfc in your emulator")
	print("  3. Use elemental spells strategically!")
	print("  4. To revert: git restore data/extracted/enemies/enemies.json")
	print()


if __name__ == "__main__":
	# Set random seed for reproducibility (optional)
	random.seed(42)
	add_elemental_weaknesses()
