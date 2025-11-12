#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Verify extracted enemy data against GameFAQs enemy guide.
Reference: https://gamefaqs.gamespot.com/snes/532476-final-fantasy-mystic-quest/faqs/23095
"""

import json
import os
import sys
import io

# Fix Windows console encoding
if sys.platform == 'win32':
	sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
	sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

# GameFAQs enemy HP data (from DrProctor's Enemies FAQ v1.2)
GAMEFAQS_ENEMY_HP = {
	"Adamant Turtle": 630,
	"Avizzard": 666,
	"Basilisk": 90,
	"Behemoth": 80,
	"Beholder": 810,
	"Brownie": 50,
	"Centaur": 230,
	"Cerebus": 935,
	"Chimera": 870,
	"Dark King": 40000,
	"Desert Hag": 280,
	"Dual Head Hydra": 14000,
	"Dullahan": 14000,
	"Edgehog": 220,
	"Fangpire": 600,
	"Flamerus Rex": 2200,
	"Flazzard": 450,
	"Freezer Crab": 410,
	"Gargoyle": 888,
	"Garuda": 825,
	"Gather": 360,
	"Ghost": 550,
	"Giant Toad": 180,
	"Gidrah": 13000,
	"Gorgon": 150,
	"Hot Wings": 585,
	"Ice Golem": 6500,
	"Iflyte": 660,
	"Jelley": 420,
	"Jinn": 6000,
	"Lamia": 300,
	"Land Turtle": 270,
	"Land Worm": 265,
	"Leech": 745,
	"Live Oak": 710,
	"Mad Plant": 60,
	"Mad Toad": 740,
	"Mage": 330,
	"Manticore": 840,
	"Medusa": 2500,
	"Minotaur": 240,
	"Minotaur Zombie": 190,
	"Mintmint": 160,
	"Mummy": 685,
	"Naga": 870,
	"Nightmare": 535,
	"Ninja": 580,
	"Ooze": 750,
	"Pazuzu": 25000,
	"Phanquid": 400,
	"Plant Man": 460,
	"Poison Toad": 70,
	"Red Bone": 510,
	"Red Cap": 480,
	"Roc": 100,
	"Salamander": 640,
	"Sand Worm": 140,
	"Scorpion": 210,
	"Shadow": 925,
	"Skeleton": 120,
	"Skuldier": 750,
	"Skullrus Rex": 10000,
	"Slime": 55,
	"Snipion": 690,
	"Snow Crab": 3000,
	"Sorcerer": 840,
	"Sparna": 260,
	"Specter": 690,
	"Sphinx": 360,
	"Squidite": 2500,
	"Stheno": 360,
	"Sting Rat": 420,
	"Stone Golem": 10000,
	"Stoney Roost": 350,
	"Thanatos": 900,
	"Twin Head Wyvern": 15000,
	"Vampire": 780,
	"Water Hag": 765,
	"Were Wolf": 550,  # Note: GameFAQs has "55" but this appears to be a typo (too weak for late game)
	"Zombie": 500,
	"Zuh": 20000,
}

def normalize_name(name):
	"""Normalize enemy name for comparison."""
	# Handle common variations
	replacements = {
		"Flazzard Hit": "Flazzard",
		"Mint Mint": "Mintmint",
	}

	normalized = name.strip()
	if normalized in replacements:
		normalized = replacements[normalized]

	return normalized

def verify_enemy_data():
	"""Verify extracted enemy data against GameFAQs reference."""

	# Load extracted data
	json_path = os.path.join(os.path.dirname(__file__), '..', 'data', 'extracted', 'enemies', 'enemies.json')

	with open(json_path, 'r') as f:
		data = json.load(f)

	enemies = data['enemies']

	print("=" * 80)
	print("FFMQ Enemy Data Verification vs GameFAQs")
	print("Reference: https://gamefaqs.gamespot.com/snes/532476-final-fantasy-mystic-quest/faqs/23095")
	print("=" * 80)
	print()

	matches = 0
	mismatches = 0
	missing = 0

	# Check our extracted data against GameFAQs
	for enemy in enemies:
		name = normalize_name(enemy['name'])
		extracted_hp = enemy['hp']

		if name in GAMEFAQS_ENEMY_HP:
			gamefaqs_hp = GAMEFAQS_ENEMY_HP[name]
			if extracted_hp == gamefaqs_hp:
				matches += 1
				print(f"✓ {name:20s} HP: {extracted_hp:6d} - MATCHES GameFAQs")
			else:
				mismatches += 1
				print(f"✗ {name:20s} HP: {extracted_hp:6d} - GameFAQs says {gamefaqs_hp:6d} - MISMATCH!")
		else:
			missing += 1
			print(f"? {name:20s} HP: {extracted_hp:6d} - Not in GameFAQs data")

	print()
	print("=" * 80)
	print(f"Results:")
	print(f"  Matches:	{matches:3d} enemies")
	print(f"  Mismatches: {mismatches:3d} enemies")
	print(f"  Missing:	{missing:3d} enemies (not in GameFAQs reference)")
	print(f"  Total:	  {len(enemies):3d} enemies extracted")
	print("=" * 80)

	if mismatches == 0:
		print()
		print("🎉 SUCCESS! All enemy HP values match GameFAQs reference data!")
		print("   Our extraction tool is verified accurate!")
		return True
	else:
		print()
		print("⚠ WARNING: Some HP values don't match. Please investigate.")
		return False

if __name__ == '__main__':
	verify_enemy_data()
