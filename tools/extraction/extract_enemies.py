#!/usr/bin/env python3
# FFMQ Enemy Data Extractor
# Extracts enemy stats from ROM
#
# ROM Addresses (SNES CPU addresses, need conversion to file offsets):
#  - Enemy Stats: Bank $02, ROM $C275 (14 bytes each, 83 enemies)
#  - Enemy Level/Mult: Bank $02, ROM $C17C (3 bytes each, 83 enemies)
#
# LoROM file offset formula: bank * 0x8000 + (rom_addr - 0x8000)

import sys
import struct
import csv
import json
from pathlib import Path

ELEMENT_TYPES = {
	0x0001: 'Silence', 0x0002: 'Blind', 0x0004: 'Poison', 0x0008: 'Confusion',
	0x0010: 'Sleep', 0x0020: 'Paralysis', 0x0040: 'Stone', 0x0080: 'Doom',
	0x0100: 'Projectile', 0x0200: 'Bomb', 0x0400: 'Axe', 0x0800: 'Zombie',
	0x1000: 'Air', 0x2000: 'Fire', 0x4000: 'Water', 0x8000: 'Earth'
}

ENEMY_NAMES = [
	"Brownie", "Mintmint", "Red Cap", "Mad Plant", "Plant Man", "Live Oak",
	"Slime", "Jelly", "Ooze", "Poison Toad", "Giant Toad", "Mad Toad",
	"Basilisk", "Flazzard", "Salamand", "Sand Worm", "Land Worm", "Leech",
	"Skeleton", "Red Bone", "Skuldier", "Roc", "Sparna", "Garuda",
	"Zombie", "Mummy", "Desert Hag", "Water Hag", "Ninja", "Shadow",
	"Sphinx", "Manticor", "Centaur", "Nitemare", "Stoney Roost", "Hot Wings",
	"Ghost", "Spector", "Gather", "Beholder", "Fangpire", "Vampire",
	"Mage", "Sorcerer", "Land Turtle", "Sea Turtle", "Stone Man", "Lizard Man",
	"Wasp", "Fly Eye", "Minotaur", "Medusa", "Ice Golem", "Fire Golem",
	"Jinn", "Cockatrice", "Thunder Eye", "Doom Eye", "Succubus", "Freeze Crab",
	"Gemini Crest (L)", "Gemini Crest (R)", "Pazuzu", "Sky Beast",
	"Captain", "Hydra", "Squid Eye", "Libra Crest", "Dullahan", "Dark Lord",
	"Twinhead Wyvern", "Lamia", "Gargoyle", "Gargoyle Statue",
	"Dullahan (Phoebe)", "Dark Lord (Phoebe)", "Medusa (Quest)", "Stone Golem",
	"Gorgon Bull", "Minotaur (Quest)", "Skullrus Rex", "Dark King (Phase 1)",
	"Dark King Spider"
]


def rom_to_file_offset(bank, rom_addr):
	"""Convert SNES ROM address to file offset (LoROM)."""
	return bank * 0x8000 + (rom_addr - 0x8000)


# ROM addresses (SNES CPU addresses)
ENEMY_STATS_BANK = 0x02
ENEMY_STATS_ROM = 0xC275
ENEMY_LEVEL_BANK = 0x02
ENEMY_LEVEL_ROM = 0xC17C


def decode_elements(value):
	return [name for bit, name in ELEMENT_TYPES.items() if value & bit]


rom_path = Path("roms/Final Fantasy - Mystic Quest (U) (V1.1).sfc")
with open(rom_path, 'rb') as f:
	rom = f.read()

print(f"Loaded ROM: {len(rom):,} bytes")
print("Extracting 83 enemies...")

enemies = []
for i in range(83):
	stats_addr = rom_to_file_offset(ENEMY_STATS_BANK, ENEMY_STATS_ROM + i * 14)
	level_addr = rom_to_file_offset(ENEMY_LEVEL_BANK, ENEMY_LEVEL_ROM + i * 3)

	s = rom[stats_addr:stats_addr + 14]
	l = rom[level_addr:level_addr + 3]

	hp = struct.unpack('<H', s[0:2])[0]
	resist = struct.unpack('<H', s[6:8])[0]  # Bytes 6-7 as 16-bit word
	weak = struct.unpack('<H', s[12:14])[0]  # Bytes 12-13 as 16-bit word (was bug: s[12] * 0x100)

	enemies.append({'id': i,
					'name': ENEMY_NAMES[i],
					'hp': hp,
					'attack': s[2],
					'defense': s[3],
					'speed': s[4],
					'magic': s[5],
					'accuracy': s[10],
					'evade': s[11],
					'magic_defense': s[8],
					'magic_evade': s[9],
					'level': l[0],
					'xp_mult': l[1],
					'gp_mult': l[2],
					'resistances': resist,  # Store as integer, will decode later
					'weaknesses': weak})    # Store as integer, will decode later

Path("data/extracted/enemies").mkdir(parents=True, exist_ok=True)

# Create enriched enemy data for JSON with both raw values and decoded names
enemies_with_decoded = []
for e in enemies:
	enemy_entry = e.copy()
	# Add decoded element names
	enemy_entry['resistances_decoded'] = decode_elements(e['resistances'])
	enemy_entry['weaknesses_decoded'] = decode_elements(e['weaknesses'])
	enemies_with_decoded.append(enemy_entry)

with open("data/extracted/enemies/enemies.json", 'w') as f:
	json.dump({'metadata': {'game': 'FFMQ', 'count': 83,
						   'description': 'Enemy stats from Bank $02, ROM $C275 (14 bytes per enemy)',
						   'structure': {
							   'bytes_0_1': 'HP (16-bit little-endian)',
							   'byte_2': 'Attack',
							   'byte_3': 'Defense',
							   'byte_4': 'Speed',
							   'byte_5': 'Magic',
							   'bytes_6_7': 'Resistances (16-bit bitfield)',
							   'byte_8': 'Magic Defense',
							   'byte_9': 'Magic Evade',
							   'byte_10': 'Accuracy',
							   'byte_11': 'Evade',
							   'bytes_12_13': 'Weaknesses (16-bit bitfield)'
						   }},
			  'enemies': enemies_with_decoded}, f, indent=2)

with open("data/extracted/enemies/enemies.csv", 'w', newline='') as f:
	w = csv.DictWriter(f,
					   ['id',
						'name',
						'hp',
						'attack',
						'defense',
						'speed',
						'magic',
						'accuracy',
						'evade',
						'magic_defense',
						'magic_evade',
						'level',
						'xp_mult',
						'gp_mult',
						'resistances',
						'resistances_hex',
						'weaknesses',
						'weaknesses_hex'])
	w.writeheader()
	for e in enemies_with_decoded:
		# Create CSV row with decoded values
		csv_row = {
			'id': e['id'],
			'name': e['name'],
			'hp': e['hp'],
			'attack': e['attack'],
			'defense': e['defense'],
			'speed': e['speed'],
			'magic': e['magic'],
			'accuracy': e['accuracy'],
			'evade': e['evade'],
			'magic_defense': e['magic_defense'],
			'magic_evade': e['magic_evade'],
			'level': e['level'],
			'xp_mult': e['xp_mult'],
			'gp_mult': e['gp_mult'],
			'resistances': ', '.join(e['resistances_decoded']) if e['resistances_decoded'] else 'None',
			'resistances_hex': f"0x{e['resistances']:04X}",
			'weaknesses': ', '.join(e['weaknesses_decoded']) if e['weaknesses_decoded'] else 'None',
			'weaknesses_hex': f"0x{e['weaknesses']:04X}"
		}
		w.writerow(csv_row)

print(f"Extracted {len(enemies)} enemies")
print(
	f"HP range: {min(e['hp'] for e in enemies)} - {max(e['hp'] for e in enemies)}")
print(
	f"First 3: {
		enemies[0]['name']}, {
			enemies[1]['name']}, {
				enemies[2]['name']}")
print("Saved to data/extracted/enemies/")
