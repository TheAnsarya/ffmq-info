#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Attack Data JSON-to-ASM Converter
==================================

Converts extracted attack data JSON back to assembly format.

Usage:
    python tools/conversion/convert_attacks.py

Input:
    data/extracted/attacks/attacks.json

Output:
    data/converted/attacks/attacks_data.asm

Structure:
    Bank $02, ROM $BC78 - Attack Data (7 bytes × 169 attacks)
      Byte 0: Unknown1 (targeting?)
      Byte 1: Unknown2
      Byte 2: Power
      Byte 3: Attack Type (action routine)
      Byte 4: Attack Sound
      Byte 5: Unknown3
      Byte 6: Attack Target Animation

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


ATTACK_DATA_ROM_ADDR = 0xBC78


def load_attack_data(json_path: str) -> Dict:
    """Load attack data from JSON file."""
    with open(json_path, 'r') as f:
        return json.load(f)


def generate_attacks_asm(attacks: List[Dict]) -> str:
    """
    Generate assembly for attack data table.

    Args:
        attacks: List of attack dictionaries from JSON

    Returns:
        ASM source code string
    """
    asm_lines = []

    # Header
    asm_lines.append(";==============================================================================")
    asm_lines.append("; Final Fantasy Mystic Quest - Attack/Battle Action Data")
    asm_lines.append("; AUTO-GENERATED from data/extracted/attacks/attacks.json")
    asm_lines.append(";==============================================================================")
    asm_lines.append("; DO NOT EDIT MANUALLY - Edit JSON and regenerate")
    asm_lines.append(";")
    asm_lines.append("; Location: Bank $02, ROM $BC78")
    asm_lines.append("; Structure: 7 bytes per attack, 169 attacks")
    asm_lines.append(";")
    asm_lines.append("; To rebuild this file:")
    asm_lines.append(";   python tools/conversion/convert_attacks.py")
    asm_lines.append(";==============================================================================")
    asm_lines.append("; NOTE: No ORG directive - this file is included inline in bank_02.asm")
    asm_lines.append(";       The assembler's current address is already set correctly")
    asm_lines.append(";==============================================================================")
    asm_lines.append("")
    asm_lines.append("attack_data_table:")
    asm_lines.append("")

    # Generate attack data
    for attack in attacks:
        attack_id = attack['id']
        power = attack.get('power', 0)

        asm_lines.append(f"; Attack {attack_id:03d} (Power: {power})")
        asm_lines.append(f"attack_{attack_id:03d}:")
        asm_lines.append(f"  db ${attack.get('unknown1', 0):02X}             ; Unknown1")
        asm_lines.append(f"  db ${attack.get('unknown2', 0):02X}             ; Unknown2")
        asm_lines.append(f"  db ${power:02X}             ; Power: {power}")
        asm_lines.append(f"  db ${attack.get('attack_type', 0):02X}             ; Attack Type")
        asm_lines.append(f"  db ${attack.get('attack_sound', 0):02X}             ; Attack Sound")
        asm_lines.append(f"  db ${attack.get('unknown3', 0):02X}             ; Unknown3")
        asm_lines.append(f"  db ${attack.get('attack_target_animation', 0):02X}             ; Target Animation")
        asm_lines.append("")

    return "\n".join(asm_lines)


def main():
    """Main conversion routine."""
    print("="*80)
    print("Attack Data JSON-to-ASM Converter")
    print("="*80)
    print()

    # Load JSON data
    json_path = Path("data/extracted/attacks/attacks.json")
    if not json_path.exists():
        print(f"[ERROR] Error: JSON file not found: {json_path}")
        print("   Run tools/extraction/extract_attacks.py first")
        return 1

    print(f"[INFO] Loading JSON data: {json_path}")
    data = load_attack_data(str(json_path))
    attacks = data['attacks']
    print(f"[OK] Loaded {len(attacks)} attacks")
    print()

    # Create output directory
    output_dir = Path("data/converted/attacks")
    output_dir.mkdir(parents=True, exist_ok=True)

    # Generate ASM
    print("[INFO] Generating attack data assembly...")
    attacks_asm = generate_attacks_asm(attacks)
    output_path = output_dir / "attacks_data.asm"
    with open(output_path, 'w') as f:
        f.write(attacks_asm)
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

