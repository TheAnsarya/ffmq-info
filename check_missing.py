import json

# Load mapping
with open('tools/validation/learnable_spells_mapping.json', 'r') as f:
	data = json.load(f)

print("Mapped spells:")
mapped_ids = set()
for s in data['spells']:
	print(f"  {s['randomizer_id']}: {s['randomizer_name']}")
	mapped_ids.add(s['randomizer_id'])

print("\nMissing randomizer IDs:")
all_ids = set(range(12))  # 0-11
missing = all_ids - mapped_ids
print(f"  {missing}")

if missing:
	# Map missing IDs to spell names
	spell_names = {
		0: "Exit", 1: "Cure", 2: "Heal", 3: "Life", 4: "Quake", 5: "Blizzard",
		6: "Fire", 7: "Aero", 8: "Thunder", 9: "White", 10: "Meteor", 11: "Flare"
	}
	print("\nMissing spells:")
	for missing_id in missing:
		print(f"  ID {missing_id}: {spell_names[missing_id]}")
