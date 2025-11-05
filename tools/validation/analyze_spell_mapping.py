#!/usr/bin/env python3
"""
FFMQ Spell Data Analysis and Validation

Analyzes the discrepancy between our spell data (16 total spell effects)
and FFMQ Randomizer data (12 learnable spells/books).

Creates corrected mapping and provides recommendations.
"""

import json
from pathlib import Path
from typing import Dict, List, Any


def analyze_spell_discrepancy():
	"""Analyze the spell data discrepancy and create mapping"""

	# Load our spell data
	data_dir = Path(__file__).parent.parent.parent / "data"
	spells_file = data_dir / "spells" / "spells.json"

	with open(spells_file, 'r', encoding='utf-8') as f:
		our_data = json.load(f)

	our_spells = our_data['spells']

	# FFMQ Randomizer learnable spells (from Items enum)
	randomizer_learnable_spells = {
		0x00: "Exit",		# ExitBook
		0x01: "Cure",		# CureBook
		0x02: "Heal",		# HealBook
		0x03: "Life",		# LifeBook
		0x04: "Quake",	 # QuakeBook
		0x05: "Blizzard",	# BlizzardBook
		0x06: "Fire",		# FireBook
		0x07: "Aero",		# AeroBook
		0x08: "Thunder",	 # ThunderSeal
		0x09: "White",	 # WhiteSeal
		0x0A: "Meteor",	# MeteorSeal
		0x0B: "Flare"		# FlareSeal
	}

	print("=" * 80)
	print("FFMQ SPELL DATA ANALYSIS")
	print("=" * 80)
	print()

	print("📊 OUR EXTRACTED SPELLS (16 total):")
	print("-" * 50)
	for spell in our_spells:
		print(f"ID {spell['id']:2d}: {spell['name']:<12} (Power: {spell['power']}, MP: {spell['mp_cost']})")
	print()

	print("📚 RANDOMIZER LEARNABLE SPELLS (12 total):")
	print("-" * 50)
	for spell_id, name in randomizer_learnable_spells.items():
		print(f"ID {spell_id:2d}: {name}")
	print()

	# Try to find matches between our spells and randomizer spells
	print("🔍 POTENTIAL MATCHES:")
	print("-" * 50)

	matches = []
	our_spell_names = [spell['name'] for spell in our_spells]

	for rand_id, rand_name in randomizer_learnable_spells.items():
		# Look for exact name matches
		exact_matches = [i for i, our_spell in enumerate(our_spells) if our_spell['name'] == rand_name]

		# Look for partial name matches
		partial_matches = [i for i, our_spell in enumerate(our_spells)
							if rand_name.lower() in our_spell['name'].lower() or
							 our_spell['name'].lower() in rand_name.lower()]

		if exact_matches:
			our_id = exact_matches[0]
			matches.append((rand_id, rand_name, our_id, our_spells[our_id]['name'], "EXACT"))
			print(f"✅ {rand_name:<10} (Rand ID {rand_id}) = {our_spells[our_id]['name']} (Our ID {our_id}) [EXACT]")
		elif partial_matches:
			our_id = partial_matches[0]
			matches.append((rand_id, rand_name, our_id, our_spells[our_id]['name'], "PARTIAL"))
			print(f"⚠️	{rand_name:<10} (Rand ID {rand_id}) ≈ {our_spells[our_id]['name']} (Our ID {our_id}) [PARTIAL]")
		else:
			print(f"❌ {rand_name:<10} (Rand ID {rand_id}) = NOT FOUND")

	print()

	# Analyze our extra spells
	matched_our_ids = [match[2] for match in matches]
	unmatched_our_spells = [spell for i, spell in enumerate(our_spells) if i not in matched_our_ids]

	print("🔍 OUR EXTRA SPELLS (not in randomizer):")
	print("-" * 50)
	for spell in unmatched_our_spells:
		print(f"ID {spell['id']:2d}: {spell['name']:<12} (Power: {spell['power']}, MP: {spell['mp_cost']})")
	print()

	# Create corrected mapping
	print("🔧 RECOMMENDED CORRECTIONS:")
	print("-" * 50)

	# Analysis of the discrepancy
	print("ANALYSIS:")
	print("• Our data appears to extract ALL spell-like effects in the game (16 total)")
	print("• FFMQ Randomizer only tracks learnable spells/books (12 total)")
	print("• Our data may include enemy abilities, status effects, or other non-learnable spells")
	print("• The ID mapping is different - our IDs 0-15 vs randomizer IDs 0x00-0x0B")
	print()

	print("RECOMMENDATIONS:")
	print("1. Create a separate 'learnable_spells.json' with only the 12 randomizer spells")
	print("2. Map our spell names to randomizer spell names where possible")
	print("3. Keep the full spell data as 'all_spell_effects.json' for completeness")
	print("4. Update validation to check against the learnable spells subset")
	print()

	# Generate corrected learnable spells data
	corrected_spells = []

	# Use best matches to create learnable spells mapping
	spell_name_corrections = {
		"Fire": "Fire",		 # Our Fire -> Randomizer Fire
		"Blizzard": "Blizzard", # Our Blizzard -> Randomizer Blizzard
		"Thunder": "Thunder",	 # Our Thunder -> Randomizer Thunder
		"Aero": "Aero",		 # Our Aero -> Randomizer Aero
		"Cure": "Cure",		 # Our Cure -> Randomizer Cure
		"Life": "Life",		 # Our Life -> Randomizer Life
		"Heal": "Heal",		 # Our Heal -> Randomizer Heal
		"Quake": "Quake",		 # Our Quake -> Randomizer Quake
		"Flare": "Flare",		 # Our Flare -> Randomizer Flare
		"White": "White",		 # Our White -> Randomizer White
		"Meteor": "Meteor",	 # Our Meteor -> Randomizer Meteor
		# Exit is missing from our data - need to investigate
	}

	for rand_id, rand_name in randomizer_learnable_spells.items():
		# Find our spell that matches this randomizer spell
		our_spell = None
		for spell in our_spells:
			if spell['name'] in spell_name_corrections and spell_name_corrections[spell['name']] == rand_name:
				our_spell = spell
				break

		if our_spell:
			corrected_spell = {
				"randomizer_id": rand_id,
				"randomizer_name": rand_name,
				"our_id": our_spell['id'],
				"our_name": our_spell['name'],
				"power": our_spell['power'],
				"mp_cost": our_spell['mp_cost'],
				"element": our_spell['element'],
				"address": our_spell['address']
			}
			corrected_spells.append(corrected_spell)

	# Save corrected mapping
	output_file = Path(__file__).parent / "learnable_spells_mapping.json"
	mapping_data = {
		"description": "Mapping between our extracted spells and FFMQ Randomizer learnable spells",
		"randomizer_source": "https://github.com/wildham0/FFMQRando",
		"total_randomizer_spells": 12,
		"total_our_spells": 16,
		"matched_spells": len(corrected_spells),
		"spells": corrected_spells
	}

	with open(output_file, 'w', encoding='utf-8') as f:
		json.dump(mapping_data, f, indent=2)

	print(f"📄 Corrected mapping saved to: {output_file}")
	print(f"✅ Successfully mapped {len(corrected_spells)}/12 randomizer spells")

	return corrected_spells


if __name__ == "__main__":
	analyze_spell_discrepancy()
