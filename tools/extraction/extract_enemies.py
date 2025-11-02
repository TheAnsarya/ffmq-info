#!/usr/bin/env python3
# FFMQ Enemy Data Extractor
# Extracts enemy stats from ROM Bank 02 offset C275

import sys, struct, csv, json
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

def snes_to_pc(bank, offset):
    return ((bank & 0x3F) * 0x8000) + (offset & 0x7FFF)

def decode_elements(value):
    return [name for bit, name in ELEMENT_TYPES.items() if value & bit]

rom_path = Path("roms/Final Fantasy - Mystic Quest (U) (V1.1).sfc")
with open(rom_path, 'rb') as f:
    rom = f.read()

print(f"Loaded ROM: {len(rom):,} bytes")
print("Extracting 83 enemies...")

enemies = []
for i in range(83):
    stats_addr = snes_to_pc(0x02, 0xC275 + i * 14)
    level_addr = snes_to_pc(0x02, 0xC17C + i * 3)

    s = rom[stats_addr:stats_addr+14]
    l = rom[level_addr:level_addr+3]

    hp = struct.unpack('<H', s[0:2])[0]
    resist = struct.unpack('<H', s[6:8])[0]
    weak = s[12] * 0x100

    enemies.append({
        'id': i, 'name': ENEMY_NAMES[i], 'hp': hp,
        'attack': s[2], 'defense': s[3], 'speed': s[4], 'magic': s[5],
        'accuracy': s[10], 'evade': s[11], 'magic_defense': s[8], 'magic_evade': s[9],
        'level': l[0], 'xp_mult': l[1], 'gp_mult': l[2],
        'resistances': decode_elements(resist), 'weaknesses': decode_elements(weak)
    })

Path("data/extracted/enemies").mkdir(parents=True, exist_ok=True)

with open("data/extracted/enemies/enemies.json", 'w') as f:
    json.dump({'metadata': {'game': 'FFMQ', 'count': 83}, 'enemies': enemies}, f, indent=2)

with open("data/extracted/enemies/enemies.csv", 'w', newline='') as f:
    w = csv.DictWriter(f, ['id','name','hp','attack','defense','speed','magic','accuracy','evade',
                            'magic_defense','magic_evade','level','xp_mult','gp_mult','resistances','weaknesses'])
    w.writeheader()
    for e in enemies:
        e['resistances'] = ', '.join(e['resistances']) if e['resistances'] else 'None'
        e['weaknesses'] = ', '.join(e['weaknesses']) if e['weaknesses'] else 'None'
        w.writerow(e)

print(f"Extracted {len(enemies)} enemies")
print(f"HP range: {min(e['hp'] for e in enemies)} - {max(e['hp'] for e in enemies)}")
print(f"First 3: {enemies[0]['name']}, {enemies[1]['name']}, {enemies[2]['name']}")
print("Saved to data/extracted/enemies/")
