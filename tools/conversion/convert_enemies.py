#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Enemy Data JSON-to-ASM Converter
=================================

Converts extracted enemy data JSON back to assembly format for inclusion
in the ROM build process.

This enables the full data pipeline:
  ROM → JSON (extract_enemies.py)
  JSON → ASM (this tool)
  ASM → ROM (asar assembler)

Usage:
	python tools/conversion/convert_enemies.py

Input:
	data/extracted/enemies/enemies.json

Output:
	data/converted/enemies/enemies_data.asm
	data/converted/enemies/enemies_level_data.asm

Structure:
	Bank $02, ROM $C275 - Enemy Stats (14 bytes × 83 enemies)
	  Bytes 0-1: HP (16-bit little-endian)
	  Byte 2: Attack
	  Byte 3: Defense
	  Byte 4: Speed
	  Byte 5: Magic
	  Bytes 6-7: Resistances (16-bit bitfield)
	  Byte 8: Magic Defense
	  Byte 9: Magic Evade
	  Byte 10: Accuracy
	  Byte 11: Evade
	  Bytes 12-13: Weaknesses (16-bit bitfield)

	Bank $02, ROM $C17C - Enemy Level/Multiplier (3 bytes × 83 enemies)
	  Byte 0: Level
	  Byte 1: XP Multiplier
	  Byte 2: GP Multiplier

Author: FFMQ Disassembly Project
Date: 2025-11-02
"""

import json
import sys
import io
from pathlib import Path
from typing import List, Dict

# Fix Windows console encoding issues
if sys.platform == 'win32':
	sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
	sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')



ENEMY_STATS_ROM_ADDR = 0xC275
ENEMY_LEVEL_ROM_ADDR = 0xC17C


def load_enemy_data(json_path: str) -> Dict:
	"""Load enemy data from JSON file."""
	with open(json_path, 'r') as f:
		return json.load(f)


def generate_enemy_stats_asm(enemies: List[Dict]) -> str:
	"""
	Generate assembly for enemy stats table.

	Args:
		enemies: List of enemy dictionaries from JSON

	Returns:
		ASM source code string
	"""
	asm_lines = []

	# Header
	asm_lines.append(";==============================================================================")
	asm_lines.append("; Final Fantasy Mystic Quest - Enemy Stats Data")
	asm_lines.append("; AUTO-GENERATED from data/extracted/enemies/enemies.json")
	asm_lines.append(";==============================================================================")
	asm_lines.append("; DO NOT EDIT MANUALLY - Edit JSON and regenerate")
	asm_lines.append(";")
	asm_lines.append("; Location: Bank $02, ROM $C275")
	asm_lines.append("; Structure: 14 bytes per enemy, 83 enemies")
	asm_lines.append(";")
	asm_lines.append("; To rebuild this file:")
	asm_lines.append(";   python tools/conversion/convert_enemies.py")
	asm_lines.append(";==============================================================================")
	asm_lines.append("; NOTE: No ORG directive - this file is included inline in bank_02.asm")
	asm_lines.append(";       The assembler's current address is already set correctly")
	asm_lines.append(";==============================================================================")
	asm_lines.append("")
	asm_lines.append("enemy_stats_table:")
	asm_lines.append("")

	# Generate enemy data
	for enemy in enemies:
		enemy_id = enemy['id']
		name = enemy['name']

		asm_lines.append(f"; Enemy {enemy_id:03d}: {name}")
		asm_lines.append(f"enemy_{enemy_id:03d}_stats:")

		# Bytes 0-1: HP (16-bit little-endian)
		hp = enemy['hp']
		hp_lo = hp & 0xFF
		hp_hi = (hp >> 8) & 0xFF
		asm_lines.append(f"  dw ${hp:04X}           ; HP: {hp}")

		# Bytes 2-5: Stats
		asm_lines.append(f"  db ${enemy['attack']:02X}             ; Attack: {enemy['attack']}")
		asm_lines.append(f"  db ${enemy['defense']:02X}             ; Defense: {enemy['defense']}")
		asm_lines.append(f"  db ${enemy['speed']:02X}             ; Speed: {enemy['speed']}")
		asm_lines.append(f"  db ${enemy['magic']:02X}             ; Magic: {enemy['magic']}")

		# Bytes 6-7: Resistances (16-bit bitfield)
		resist = enemy['resistances']
		resist_names = ', '.join(enemy['resistances_decoded']) if enemy['resistances_decoded'] else 'None'
		asm_lines.append(f"  dw ${resist:04X}           ; Resistances: {resist_names}")

		# Bytes 8-11: More stats
		asm_lines.append(f"  db ${enemy['magic_defense']:02X}             ; Magic Defense: {enemy['magic_defense']}")
		asm_lines.append(f"  db ${enemy['magic_evade']:02X}             ; Magic Evade: {enemy['magic_evade']}")
		asm_lines.append(f"  db ${enemy['accuracy']:02X}             ; Accuracy: {enemy['accuracy']}")
		asm_lines.append(f"  db ${enemy['evade']:02X}             ; Evade: {enemy['evade']}")

		# Bytes 12-13: Weaknesses (16-bit bitfield)
		weak = enemy['weaknesses']
		weak_names = ', '.join(enemy['weaknesses_decoded']) if enemy['weaknesses_decoded'] else 'None'
		asm_lines.append(f"  dw ${weak:04X}           ; Weaknesses: {weak_names}")

		asm_lines.append("")

	return "\n".join(asm_lines)


def generate_enemy_level_asm(enemies: List[Dict]) -> str:
	"""
	Generate assembly for enemy level/multiplier table.

	Args:
		enemies: List of enemy dictionaries from JSON

	Returns:
		ASM source code string
	"""
	asm_lines = []

	# Header
	asm_lines.append(";==============================================================================")
	asm_lines.append("; Final Fantasy Mystic Quest - Enemy Level/Multiplier Data")
	asm_lines.append("; AUTO-GENERATED from data/extracted/enemies/enemies.json")
	asm_lines.append(";==============================================================================")
	asm_lines.append("; DO NOT EDIT MANUALLY - Edit JSON and regenerate")
	asm_lines.append(";")
	asm_lines.append("; Location: Bank $02, ROM $C17C")
	asm_lines.append("; Structure: 3 bytes per enemy, 83 enemies")
	asm_lines.append(";")
	asm_lines.append("; To rebuild this file:")
	asm_lines.append(";   python tools/conversion/convert_enemies.py")
	asm_lines.append(";==============================================================================")
	asm_lines.append("; NOTE: No ORG directive - this file is included inline in bank_02.asm")
	asm_lines.append(";       The assembler's current address is already set correctly")
	asm_lines.append(";==============================================================================")
	asm_lines.append("")
	asm_lines.append("enemy_level_table:")
	asm_lines.append("")

	# Generate level data
	for enemy in enemies:
		enemy_id = enemy['id']
		name = enemy['name']

		asm_lines.append(f"; Enemy {enemy_id:03d}: {name}")
		asm_lines.append(f"enemy_{enemy_id:03d}_level:")
		asm_lines.append(f"  db ${enemy['level']:02X}             ; Level: {enemy['level']}")
		asm_lines.append(f"  db ${enemy['xp_mult']:02X}             ; XP Multiplier: {enemy['xp_mult']}")
		asm_lines.append(f"  db ${enemy['gp_mult']:02X}             ; GP Multiplier: {enemy['gp_mult']}")
		asm_lines.append("")

	return "\n".join(asm_lines)


def main():
	"""Main conversion routine."""
	print("="*80)
	print("Enemy Data JSON-to-ASM Converter")
	print("="*80)
	print()

	# Load JSON data
	json_path = Path("data/extracted/enemies/enemies.json")
	if not json_path.exists():
		print(f"[ERROR] JSON file not found: {json_path}")
		print("   Run tools/extraction/extract_enemies.py first")
		return 1

	print(f"[INFO] Loading JSON data: {json_path}")
	data = load_enemy_data(str(json_path))
	enemies = data['enemies']
	print(f"[OK] Loaded {len(enemies)} enemies")
	print()

	# Create output directory
	output_dir = Path("data/converted/enemies")
	output_dir.mkdir(parents=True, exist_ok=True)

	# Generate stats ASM
	print("[INFO] Generating enemy stats assembly...")
	stats_asm = generate_enemy_stats_asm(enemies)
	stats_path = output_dir / "enemies_stats.asm"
	with open(stats_path, 'w') as f:
		f.write(stats_asm)
	print(f"[OK] Created: {stats_path}")

	# Generate level ASM
	print("[INFO] Generating enemy level assembly...")
	level_asm = generate_enemy_level_asm(enemies)
	level_path = output_dir / "enemies_level.asm"
	with open(level_path, 'w') as f:
		f.write(level_asm)
	print(f"[OK] Created: {level_path}")

	print()
	print("="*80)
	print("[SUCCESS] Conversion Complete!")
	print("="*80)
	print()
	print("Generated files:")
	print(f"  - {stats_path}")
	print(f"  - {level_path}")
	print()
	print("Next steps:")
	print("  1. Include these files in your ROM build")
	print("  2. Verify with tools/verify_data_roundtrip.py")
	print()

	return 0


if __name__ == '__main__':
	sys.exit(main())
