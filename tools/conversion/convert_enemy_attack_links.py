#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Enemy-Attack Links JSON-to-ASM Converter
=========================================

Converts extracted enemy-attack link data JSON back to assembly format.

Usage:
    python tools/conversion/convert_enemy_attack_links.py

Input:
    data/extracted/attacks/enemy_attack_links.json

Output:
    data/converted/attacks/enemy_attack_links.asm

Structure:
    Bank $02, ROM $BE94 - Enemy Attack Links (6 bytes × 83 enemies)
      Each enemy has 6 attack ID slots (attack1 through attack6)

Author: FFMQ Disassembly Project
Date: 2025-11-02
"""

import json
import sys
import io

# Fix Windows console encoding issues
if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')
from pathlib import Path
from typing import List, Dict


ATTACK_LINKS_ROM_ADDR = 0xBE94


def load_attack_links_data(json_path: str) -> Dict:
    """Load enemy-attack link data from JSON file."""
    with open(json_path, 'r') as f:
        return json.load(f)


def generate_attack_links_asm(links: List[Dict]) -> str:
    """
    Generate assembly for enemy-attack links table.

    Args:
        links: List of attack link dictionaries from JSON

    Returns:
        ASM source code string
    """
    asm_lines = []

    # Header
    asm_lines.append(";==============================================================================")
    asm_lines.append("; Final Fantasy Mystic Quest - Enemy Attack Links")
    asm_lines.append("; AUTO-GENERATED from data/extracted/attacks/enemy_attack_links.json")
    asm_lines.append(";==============================================================================")
    asm_lines.append("; DO NOT EDIT MANUALLY - Edit JSON and regenerate")
    asm_lines.append(";")
    asm_lines.append("; Location: Bank $02, ROM $BE94")
    asm_lines.append("; Structure: 6 bytes per enemy, 83 enemies")
    asm_lines.append("; Each byte is an attack ID (0-168)")
    asm_lines.append(";")
    asm_lines.append("; To rebuild this file:")
    asm_lines.append(";   python tools/conversion/convert_enemy_attack_links.py")
    asm_lines.append(";==============================================================================")
    asm_lines.append("")
    asm_lines.append(f"org ${ATTACK_LINKS_ROM_ADDR:04X}")
    asm_lines.append("")
    asm_lines.append("enemy_attack_links_table:")
    asm_lines.append("")

    # Generate attack link data
    for link in links:
        enemy_id = link['enemy_id']

        # Get the 6 attack IDs
        attack1 = link.get('attack1', 0)
        attack2 = link.get('attack2', 0)
        attack3 = link.get('attack3', 0)
        attack4 = link.get('attack4', 0)
        attack5 = link.get('attack5', 0)
        attack6 = link.get('attack6', 0)

        asm_lines.append(f"; Enemy {enemy_id:03d} Attack Links")
        asm_lines.append(f"enemy_{enemy_id:03d}_attacks:")
        asm_lines.append(f"  db ${attack1:02X},${attack2:02X},${attack3:02X},${attack4:02X},${attack5:02X},${attack6:02X}  ; Attacks: {attack1},{attack2},{attack3},{attack4},{attack5},{attack6}")
        asm_lines.append("")

    return "\n".join(asm_lines)


def main():
    """Main conversion routine."""
    print("="*80)
    print("Enemy-Attack Links JSON-to-ASM Converter")
    print("="*80)
    print()

    # Load JSON data
    json_path = Path("data/extracted/enemy_attack_links/enemy_attack_links.json")
    if not json_path.exists():
        print(f"[ERROR] Error: JSON file not found: {json_path}")
        print("   Run tools/extraction/extract_enemy_attack_links.py first")
        return 1

    print(f"[INFO] Loading JSON data: {json_path}")
    data = load_attack_links_data(str(json_path))
    links = data['attack_links']
    print(f"[OK] Loaded {len(links)} enemy attack link entries")
    print()

    # Create output directory
    output_dir = Path("data/converted/attacks")
    output_dir.mkdir(parents=True, exist_ok=True)

    # Generate ASM
    print("[INFO] Generating enemy-attack links assembly...")
    links_asm = generate_attack_links_asm(links)
    output_path = output_dir / "enemy_attack_links.asm"
    with open(output_path, 'w') as f:
        f.write(links_asm)
    print(f"[OK] Created: {output_path}")

    print()
    print("="*80)
    print("[SUCCESS] Conversion Complete!")
    print("="*80)
    print()
    print("Generated files:")
    print(f"  - {output_path}")
    print()
    print("Next steps:")
    print("  1. Include this file in your ROM build")
    print("  2. Verify with tools/verify_data_roundtrip.py")
    print()

    return 0


if __name__ == '__main__':
    sys.exit(main())
