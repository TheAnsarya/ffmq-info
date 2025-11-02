#!/usr/bin/env python3
"""
Analyze spell data bytes 3-5 as enemy type flags
Based on user info: spells have "strong against" and "weak against" flags
"""

import sys
from pathlib import Path

# Hypothesized enemy type flags (similar to weapon/armor system)
# These are bit flags, so multiple types can be set
ENEMY_TYPE_FLAGS = {
    0x01: 'Beast',
    0x02: 'Plant',
    0x04: 'Undead',
    0x08: 'Dragon',
    0x10: 'Aquatic',
    0x20: 'Flying',
    0x40: 'Humanoid',
    0x80: 'Magical'
}

def decode_flags(byte_value):
    """Decode a byte into list of active flags"""
    flags = []
    for bit, name in ENEMY_TYPE_FLAGS.items():
        if byte_value & bit:
            flags.append(name)
    return flags if flags else ['None']

def analyze_spell_flags(rom_path):
    """Analyze spell data with focus on bytes 3-5 as enemy type flags"""

    with open(rom_path, 'rb') as f:
        rom = f.read()

    # Spell data location from previous research
    spell_addr = 0x060F36
    entry_size = 6
    spell_count = 16

    # Known spell names
    SPELL_NAMES = [
        'Cure', 'Heal', 'Life', 'Exit',
        'Fire', 'Blizzard', 'Thunder', 'Quake',
        'Meteor', 'Flare', 'Teleport',
        'Spell_11', 'Spell_12', 'Spell_13', 'Spell_14', 'Spell_15'
    ]

    print("="*80)
    print("Spell Enemy Type Flags Analysis")
    print("="*80)
    print()
    print("Hypothesis: Bytes 3-5 contain 'strong against' and 'weak against' flags")
    print("Testing if these bytes are enemy type bitfields...")
    print()

    print(f"{'ID':<3} {'Spell':<12} {'B3':>4} {'B4':>4} {'B5':>4} {'Byte3 Flags':<30} {'Byte4 Flags':<20} {'Byte5 Flags':<20}")
    print("-"*80)

    for i in range(spell_count):
        addr = spell_addr + (i * entry_size)
        data = rom[addr:addr + entry_size]

        power = data[0]
        byte1 = data[1]
        byte2 = data[2]
        byte3 = data[3]
        byte4 = data[4]
        byte5 = data[5]

        name = SPELL_NAMES[i] if i < len(SPELL_NAMES) else f'Spell_{i:02d}'

        flags3 = decode_flags(byte3)
        flags4 = decode_flags(byte4)
        flags5 = decode_flags(byte5)

        print(f"{i:<3} {name:<12} ${byte3:02X}  ${byte4:02X}  ${byte5:02X}  {', '.join(flags3):<30} {', '.join(flags4):<20} {', '.join(flags5):<20}")

    print()
    print("="*80)
    print("Pattern Analysis")
    print("="*80)
    print()

    # Analyze byte 3 (potential "strong against")
    print("Byte 3 Value Distribution:")
    byte3_values = {}
    for i in range(spell_count):
        addr = spell_addr + (i * entry_size)
        byte3 = rom[addr + 3]
        byte3_values[byte3] = byte3_values.get(byte3, 0) + 1

    for val in sorted(byte3_values.keys()):
        flags = decode_flags(val)
        print(f"  ${val:02X} ({val:3d}): {byte3_values[val]} spells - Flags: {', '.join(flags)}")

    print()
    print("Byte 4 Value Distribution:")
    byte4_values = {}
    for i in range(spell_count):
        addr = spell_addr + (i * entry_size)
        byte4 = rom[addr + 4]
        byte4_values[byte4] = byte4_values.get(byte4, 0) + 1

    for val in sorted(byte4_values.keys()):
        flags = decode_flags(val)
        print(f"  ${val:02X} ({val:3d}): {byte4_values[val]} spells - Flags: {', '.join(flags)}")

    print()
    print("Byte 5 Value Distribution:")
    byte5_values = {}
    for i in range(spell_count):
        addr = spell_addr + (i * entry_size)
        byte5 = rom[addr + 5]
        byte5_values[byte5] = byte5_values.get(byte5, 0) + 1

    for val in sorted(byte5_values.keys()):
        flags = decode_flags(val)
        print(f"  ${val:02X} ({val:3d}): {byte5_values[val]} spells - Flags: {', '.join(flags)}")

    print()
    print("="*80)
    print("Observations")
    print("="*80)
    print()
    print("If bytes 3-5 are enemy type flags:")
    print("  - Byte 3: Might be 'strong against' (extra damage)")
    print("  - Byte 4: Might be target type or range")
    print("  - Byte 5: Might be 'weak against' or status effects")
    print()
    print("Alternatively:")
    print("  - These could be single bytes with specific meanings")
    print("  - Or packed bitfields with multiple flags per byte")
    print()
    print("Next steps:")
    print("  1. Compare with weapon 'strong against' flag structure")
    print("  2. Test spell effectiveness against different enemy types in-game")
    print("  3. Search for spell damage calculation code in battle system")
    print()

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: analyze_spell_flags.py <rom_file>")
        sys.exit(1)

    rom_file = sys.argv[1]
    analyze_spell_flags(rom_file)
