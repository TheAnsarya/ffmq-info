#!/usr/bin/env python3
"""
Extract enemy attack link data from FFMQ ROM.

ROM Address: Bank $02, ROM $C6FF (9 bytes each, 82 entries)
LoROM file offset: bank * 0x8000 + (rom_addr - 0x8000)
File offset: 0x0146FF

This data links each enemy to their 6 possible attacks.
"""

import sys
import json
import csv
from pathlib import Path

# ROM Configuration
ROM_PATH = Path("roms/Final Fantasy - Mystic Quest (U) (V1.1).sfc")

# ROM Address (SNES CPU address - needs LoROM conversion)
ATTACK_LINKS_BANK = 0x02
ATTACK_LINKS_ROM = 0xC6FF
ENTRY_COUNT = 82  # One less than 83 enemies (no link for last enemy?)
ENTRY_SIZE = 9    # bytes per entry

# Output paths
OUTPUT_DIR = Path("data/extracted/enemy_attack_links")
CSV_OUTPUT = OUTPUT_DIR / "enemy_attack_links.csv"
JSON_OUTPUT = OUTPUT_DIR / "enemy_attack_links.json"

# Enemy names (from extract_enemies.py)
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


def read_attack_links(rom_data):
    """Extract all enemy attack link entries from ROM."""
    links = []
    file_offset = rom_to_file_offset(ATTACK_LINKS_BANK, ATTACK_LINKS_ROM)

    for i in range(ENTRY_COUNT):
        offset = file_offset + (i * ENTRY_SIZE)
        link_data = rom_data[offset:offset + ENTRY_SIZE]

        link = {
            "enemy_id": i,
            "enemy_name": ENEMY_NAMES[i] if i < len(ENEMY_NAMES) else f"Enemy_{
                i:02d}",
            "unknown1": link_data[0],
            "attack1": link_data[1],
            "attack2": link_data[2],
            "attack3": link_data[3],
            "attack4": link_data[4],
            "attack5": link_data[5],
            "attack6": link_data[6],
            "unknown2": link_data[7],
            "unknown3": link_data[8]}

        links.append(link)

    return links


def save_csv(links):
    """Save attack links to CSV file."""
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    with open(CSV_OUTPUT, 'w', newline='', encoding='utf-8') as f:
        fieldnames = [
            'enemy_id',
            'enemy_name',
            'unknown1',
            'attack1',
            'attack2',
            'attack3',
            'attack4',
            'attack5',
            'attack6',
            'unknown2',
            'unknown3']
        writer = csv.DictWriter(f, fieldnames=fieldnames)

        writer.writeheader()
        for link in links:
            writer.writerow(link)

    print(f"✓ Saved {len(links)} enemy attack links to {CSV_OUTPUT}")


def save_json(links):
    """Save attack links to JSON file."""
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    file_offset = rom_to_file_offset(ATTACK_LINKS_BANK, ATTACK_LINKS_ROM)

    output = {
        "metadata": {
            "source": "Final Fantasy Mystic Quest (U) V1.1",
            "bank": f"${ATTACK_LINKS_BANK:02X}",
            "rom_address": f"${ATTACK_LINKS_ROM:04X}",
            "file_offset": f"${file_offset:06X}",
            "entry_size": ENTRY_SIZE,
            "entry_count": len(links),
            "description": "Enemy attack links - maps enemies to their available attacks"
        },
        "attack_links": links
    }

    with open(JSON_OUTPUT, 'w', encoding='utf-8') as f:
        json.dump(output, f, indent=2)

    print(f"✓ Saved {len(links)} enemy attack links to {JSON_OUTPUT}")


def main():
    if not ROM_PATH.exists():
        print(f"✗ Error: ROM file not found at {ROM_PATH}")
        print(f"  Please ensure the ROM file exists at the specified location.")
        sys.exit(1)

    print(f"Reading ROM from: {ROM_PATH}")
    rom_data = ROM_PATH.read_bytes()

    file_offset = rom_to_file_offset(ATTACK_LINKS_BANK, ATTACK_LINKS_ROM)
    print(
        f"Extracting {ENTRY_COUNT} enemy attack links from Bank ${
            ATTACK_LINKS_BANK:02X}, ROM ${
            ATTACK_LINKS_ROM:04X}")
    print(f"  File offset: ${file_offset:06X}")
    links = read_attack_links(rom_data)

    save_csv(links)
    save_json(links)

    # Display some statistics
    all_attacks = []
    for link in links:
        attacks = [link[f'attack{i}'] for i in range(1, 7)]
        all_attacks.extend([a for a in attacks if a != 0])

    print(f"\n📊 Enemy Attack Link Statistics:")
    print(f"   Total enemies with attack data: {len(links)}")
    print(f"   Attack IDs used: {len(set(all_attacks))} unique")
    print(f"   Attack ID range: {min(all_attacks)} - {max(all_attacks)}")
    print(f"\n✓ Extraction complete!")


if __name__ == "__main__":
    main()
