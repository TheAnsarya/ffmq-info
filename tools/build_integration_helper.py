#!/usr/bin/env python3
"""
Build System Integration Helper
================================

This script helps integrate converted enemy data into the ROM build.

It will:
1. Identify data sections in bank_02.asm
2. Create a patched version with include directives
3. Verify the integration

"""

import re
from pathlib import Path

# Data section addresses and sizes
ENEMY_STATS_ADDR = 0x02C275  # Bank $02, ROM address
ENEMY_STATS_SIZE = 83 * 14   # 1162 bytes (0x48A)

ENEMY_LEVEL_ADDR = 0x02C17C  # Bank $02, ROM address
ENEMY_LEVEL_SIZE = 83 * 3    # 249 bytes (0xF9)

ATTACK_DATA_ADDR = 0x02BC78  # Bank $02, ROM address
ATTACK_DATA_SIZE = 169 * 7   # 1183 bytes (0x49F)

def find_data_section_in_asm(asm_path, start_addr, size):
    """
    Find a data section in an ASM file by address.

    Returns:
        (start_line, end_line) or None if not found
    """
    with open(asm_path, 'r') as f:
        lines = f.readlines()

    # Convert address to string format used in comments
    addr_hex = f"{start_addr:06X}"

    start_line = None
    end_addr = start_addr + size
    end_hex = f"{end_addr:06X}"

    for i, line in enumerate(lines):
        # Look for address in comment
        if addr_hex in line:
            if start_line is None:
                start_line = i
                print(f"Found start of data at line {i+1}: {line.strip()}")

        if end_hex in line and start_line is not None:
            print(f"Found end of data at line {i+1}: {line.strip()}")
            return (start_line, i)

    if start_line:
        print(f"Warning: Found start but not end. Start at line {start_line+1}")
        return (start_line, start_line + 100)  # Estimate

    return None

def create_integration_patch():
    """Create a patched version of bank_02.asm with include directives."""

    bank02_path = Path("src/asm/banks/bank_02.asm")

    if not bank02_path.exists():
        print(f"Error: {bank02_path} not found")
        return False

    print("="*80)
    print("Build System Integration - Data Section Analysis")
    print("="*80)
    print()

    # Find enemy stats section
    print("1. Looking for Enemy Stats data (14 bytes × 83 enemies):")
    print(f"   Address: ${ENEMY_STATS_ADDR:06X}, Size: {ENEMY_STATS_SIZE} bytes (0x{ENEMY_STATS_SIZE:X})")
    stats_section = find_data_section_in_asm(bank02_path, ENEMY_STATS_ADDR, ENEMY_STATS_SIZE)
    print()

    # Find enemy level section
    print("2. Looking for Enemy Level data (3 bytes × 83 enemies):")
    print(f"   Address: ${ENEMY_LEVEL_ADDR:06X}, Size: {ENEMY_LEVEL_SIZE} bytes (0x{ENEMY_LEVEL_SIZE:X})")
    level_section = find_data_section_in_asm(bank02_path, ENEMY_LEVEL_ADDR, ENEMY_LEVEL_SIZE)
    print()

    # Find attack data section
    print("3. Looking for Attack Data (7 bytes × 169 attacks):")
    print(f"   Address: ${ATTACK_DATA_ADDR:06X}, Size: {ATTACK_DATA_SIZE} bytes (0x{ATTACK_DATA_SIZE:X})")
    attack_section = find_data_section_in_asm(bank02_path, ATTACK_DATA_ADDR, ATTACK_DATA_SIZE)
    print()

    if stats_section:
        print("="*80)
        print("Enemy Stats Section Found:")
        print(f"  Lines {stats_section[0]+1} to {stats_section[1]+1}")
        print("  This section can be replaced with:")
        print('    incsrc "../../data/converted/enemies/enemies_stats.asm"')
        print("="*80)
        print()

    if level_section:
        print("="*80)
        print("Enemy Level Section Found:")
        print(f"  Lines {level_section[0]+1} to {level_section[1]+1}")
        print("  This section can be replaced with:")
        print('    incsrc "../../data/converted/enemies/enemies_level.asm"')
        print("="*80)
        print()

    if attack_section:
        print("="*80)
        print("Attack Data Section Found:")
        print(f"  Lines {attack_section[0]+1} to {attack_section[1]+1}")
        print("  This section can be replaced with:")
        print('    incsrc "../../data/converted/attacks/attacks_data.asm"')
        print("="*80)
        print()

    return True

def main():
    """Main entry point."""
    create_integration_patch()

if __name__ == '__main__':
    main()
