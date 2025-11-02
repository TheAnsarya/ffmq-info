#!/usr/bin/env python3
"""
Analyze spell data structure with the knowledge that:
- MP cost is always 1
- There are 3 spell types: White, Black, Wizard
- FFMQ has ~12 known spells
"""

import sys
from pathlib import Path

# Known spells from the game
KNOWN_SPELLS = {
    'White Magic': ['Cure', 'Life', 'Heal', 'Seed'],
    'Black Magic': ['Fire', 'Blizzard', 'Thunder', 'Aero'],
    'Wizard Magic': ['Flare', 'Quake', 'White', 'Meteor']
}

def analyze_spell_structure(rom_path):
    """Analyze the spell data structure"""

    with open(rom_path, 'rb') as f:
        rom = f.read()

    # Address found by scanner
    addr = 0x060F36

    print("="*80)
    print("Spell Data Structure Analysis")
    print("="*80)
    print(f"\nAnalyzing data at ${addr:06X}")
    print("\nKnown facts:")
    print("- MP cost is always 1 (not a variable)")
    print("- 3 spell types: White (0), Black (1), Wizard (2)")
    print("- ~12 spells total")
    print()

    # Read 16 entries of 6 bytes each
    print("Spell Data (16 entries × 6 bytes):")
    print("="*80)
    print(f"{'ID':<4} {'B0':<4} {'B1':<4} {'B2':<4} {'B3':<4} {'B4':<4} {'B5':<4} {'Hex':<20} {'Notes'}")
    print("-"*80)

    for i in range(16):
        offset = addr + (i * 6)
        data = rom[offset:offset+6]
        b0, b1, b2, b3, b4, b5 = data

        hex_str = ' '.join(f'{b:02X}' for b in data)

        # Analyze patterns
        notes = []

        # B0: Power (seems consistent)
        if 10 <= b0 <= 100:
            notes.append(f"pwr={b0}")

        # B1: Could be spell type (0-2) or something else
        if b1 in [0, 1, 2]:
            spell_types = ['White', 'Black', 'Wizard']
            notes.append(f"type={spell_types[b1]}?")
        else:
            notes.append(f"b1={b1}")

        # B2: Element (1=Fire, 2=Water, 3=Wind, 4=Earth)
        elem_map = {0: 'None', 1: 'Fire', 2: 'Water', 3: 'Wind', 4: 'Earth'}
        if b2 in elem_map:
            notes.append(f"elem={elem_map[b2]}")

        note_str = '; '.join(notes)
        print(f"{i:<4} {b0:<4} {b1:<4} {b2:<4} {b3:<4} {b4:<4} {b5:<4} {hex_str:<20} {note_str}")

    print()
    print("="*80)
    print("Pattern Analysis")
    print("="*80)
    print()

    # Analyze byte 1 distribution
    print("Byte 1 (suspected spell type or level) distribution:")
    b1_values = []
    for i in range(16):
        offset = addr + (i * 6)
        b1_values.append(rom[offset + 1])

    from collections import Counter
    b1_counter = Counter(b1_values)
    for val, count in sorted(b1_counter.items()):
        print(f"  Value {val:2d}: {count} occurrences")

    print()
    print("Hypothesis 1: Byte 1 is spell level/tier")
    print("  - Would explain values like 2, 5, 6, 11, 12, 14, 20")
    print("  - Higher values = stronger spells?")
    print()
    print("Hypothesis 2: Byte 1 is related to casting requirements")
    print("  - Could be character level required")
    print("  - Could be magic level required")
    print()

    # Check if there's a pattern with byte 3, 4, 5
    print("Analyzing bytes 3-5 for patterns...")
    print()

    # Could bytes 3-5 encode spell type + other data?
    print("Checking if spell type might be encoded elsewhere:")
    for i in range(16):
        offset = addr + (i * 6)
        data = rom[offset:offset+6]
        b0, b1, b2, b3, b4, b5 = data

        # Check if any byte has values 0, 1, or 2 consistently
        if b4 in [0, 1, 2]:
            print(f"  Spell {i}: byte4={b4} (could be type?)")
        if b5 in [0, 1, 2, 3, 4, 5]:
            print(f"  Spell {i}: byte5={b5} (could be type?)")

def main():
    if len(sys.argv) < 2:
        print("Usage: analyze_spell_structure.py <rom_file>")
        sys.exit(1)

    rom_path = sys.argv[1]
    if not Path(rom_path).exists():
        print(f"Error: ROM file not found: {rom_path}")
        sys.exit(1)

    analyze_spell_structure(rom_path)

if __name__ == '__main__':
    main()
