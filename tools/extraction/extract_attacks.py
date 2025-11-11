#!/usr/bin/env python3
"""
Extract attack/battle action data from FFMQ ROM.

ROM Address: Bank $02, ROM $BC78 (7 bytes each, 169 attacks)
LoROM file offset formula: bank * 0x8000 + (rom_addr - 0x8000)
File offset: 0x013C78
"""

import sys
import json
import csv
from pathlib import Path

# ROM Configuration
ROM_PATH = Path("roms/Final Fantasy - Mystic Quest (U) (V1.1).sfc")

# ROM Address (SNES CPU address - needs conversion)
ATTACK_DATA_BANK = 0x02
ATTACK_DATA_ROM = 0xBC78
ATTACK_COUNT = 169
ATTACK_SIZE = 7  # bytes per attack entry

# Output paths
OUTPUT_DIR = Path("data/extracted/attacks")
CSV_OUTPUT = OUTPUT_DIR / "attacks.csv"
JSON_OUTPUT = OUTPUT_DIR / "attacks.json"


def rom_to_file_offset(bank, rom_addr):
	"""Convert SNES ROM address to file offset (LoROM)."""
	return bank * 0x8000 + (rom_addr - 0x8000)


def read_attacks(rom_data):
	"""Extract all attack entries from ROM."""
	attacks = []
	file_offset = rom_to_file_offset(ATTACK_DATA_BANK, ATTACK_DATA_ROM)

	for i in range(ATTACK_COUNT):
		# Read 7 bytes for this attack
		offset = file_offset + (i * ATTACK_SIZE)
		attack_data = rom_data[offset:offset + ATTACK_SIZE]

		attack = {
			"id": i,
			"unknown1": attack_data[0],
			"unknown2": attack_data[1],
			"power": attack_data[2],
			"attack_type": attack_data[3],
			"attack_sound": attack_data[4],
			"unknown3": attack_data[5],
			"attack_target_animation": attack_data[6]
		}

		attacks.append(attack)
		offset += ATTACK_SIZE

	return attacks


def save_csv(attacks):
	"""Save attacks to CSV file."""
	OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

	with open(CSV_OUTPUT, 'w', newline='', encoding='utf-8') as f:
		fieldnames = ['id', 'unknown1', 'unknown2', 'power', 'attack_type',
					  'attack_sound', 'unknown3', 'attack_target_animation']
		writer = csv.DictWriter(f, fieldnames=fieldnames)

		writer.writeheader()
		for attack in attacks:
			writer.writerow(attack)

	print(f"✓ Saved {len(attacks)} attacks to {CSV_OUTPUT}")


def save_json(attacks):
	"""Save attacks to JSON file."""
	OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

	output = {
		"metadata": {
			"source": "Final Fantasy Mystic Quest (U) V1.1",
			"bank": f"${ATTACK_DATA_BANK:02X}",
			"rom_address": f"${ATTACK_DATA_ROM:04X}",
			"file_offset": f"${rom_to_file_offset(ATTACK_DATA_BANK, ATTACK_DATA_ROM):06X}",
			"entry_size": ATTACK_SIZE,
			"entry_count": len(attacks),
			"description": "Battle action data (player, companion, and enemy attacks)"
		},
		"attacks": attacks
	}

	with open(JSON_OUTPUT, 'w', encoding='utf-8') as f:
		json.dump(output, f, indent=2)

	print(f"✓ Saved {len(attacks)} attacks to {JSON_OUTPUT}")


def main():
	if not ROM_PATH.exists():
		print(f"✗ Error: ROM file not found at {ROM_PATH}")
		print(f"  Please ensure the ROM file exists at the specified location.")
		sys.exit(1)

	print(f"Reading ROM from: {ROM_PATH}")
	rom_data = ROM_PATH.read_bytes()

	file_offset = rom_to_file_offset(ATTACK_DATA_BANK, ATTACK_DATA_ROM)
	print(
		f"Extracting {ATTACK_COUNT} attacks from Bank ${
			ATTACK_DATA_BANK:02X}, ROM ${
			ATTACK_DATA_ROM:04X}")
	print(f"  File offset: ${file_offset:06X}")
	attacks = read_attacks(rom_data)

	save_csv(attacks)
	save_json(attacks)

	# Display some statistics
	powers = [a['power'] for a in attacks]
	print(f"\n📊 Attack Statistics:")
	print(f"   Total attacks: {len(attacks)}")
	print(f"   Power range: {min(powers)} - {max(powers)}")
	print(
		f"   Unique attack types: {len(set(a['attack_type'] for a in attacks))}")
	print(f"   Unique sounds: {len(set(a['attack_sound'] for a in attacks))}")
	print(f"\n✓ Extraction complete!")


if __name__ == "__main__":
	main()
