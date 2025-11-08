#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Build Integration Verification
===============================

Verifies that battle data is correctly integrated into the built ROM.

This script:
1. Extracts enemy data from the built ROM
2. Compares it with the source JSON data
3. Reports any discrepancies
"""

import json
from pathlib import Path
import sys
import io

# Fix Windows console encoding
if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

def read_rom_bytes(rom_path, address, size):
    """Read bytes from a ROM file at a specific address."""
    with open(rom_path, 'rb') as f:
        f.seek(address)
        return f.read(size)

def verify_enemy_stats(rom_path, json_path):
    """Verify enemy stats in the ROM match the JSON data."""

    # Read JSON data
    with open(json_path, 'r') as f:
        data = json.load(f)
        enemies = data['enemies']

    # Enemy stats start at SNES address $02:$C275
    # LoROM mapping: Bank $02 SNES $8000-$FFFF = PC $010000-$017FFF
    # $02:$C275 = PC $010000 + ($C275 - $8000) = $014275
    stats_addr = 0x014275

    print("="*80)
    print("Enemy Stats Verification")
    print("="*80)
    print()

    # Read ROM data
    rom_stats = read_rom_bytes(rom_path, stats_addr, 83 * 14)

    all_match = True
    mismatches = []

    for i, enemy in enumerate(enemies):
        offset = i * 14
        rom_data = rom_stats[offset:offset+14]

        # Compare HP (little-endian 16-bit)
        hp_rom = rom_data[0] | (rom_data[1] << 8)
        hp_json = enemy['hp']

        if hp_rom != hp_json:
            all_match = False
            mismatches.append({
                'enemy': enemy['name'],
                'field': 'HP',
                'rom': hp_rom,
                'json': hp_json
            })

        # Compare other stats (8-bit values)
        stats_map = [
            (2, 'attack', 'Attack'),
            (3, 'defense', 'Defense'),
            (4, 'speed', 'Speed'),
            (5, 'magic', 'Magic'),
        ]

        for idx, json_key, display_name in stats_map:
            rom_val = rom_data[idx]
            json_val = enemy[json_key]

            if rom_val != json_val:
                all_match = False
                mismatches.append({
                    'enemy': enemy['name'],
                    'field': display_name,
                    'rom': rom_val,
                    'json': json_val
                })

    if all_match:
        print(f"✅ All {len(enemies)} enemies verified successfully!")
        print()
        print("Enemy stats in ROM match JSON data exactly.")
        return True
    else:
        print(f"❌ Found {len(mismatches)} mismatches:")
        print()
        for m in mismatches[:10]:  # Show first 10
            print(f"  {m['enemy']} - {m['field']}: ROM={m['rom']}, JSON={m['json']}")

        if len(mismatches) > 10:
            print(f"  ... and {len(mismatches) - 10} more")

        return False

def verify_enemy_levels(rom_path, json_path):
    """Verify enemy levels in the ROM match the JSON data."""

    # Read JSON data
    with open(json_path, 'r') as f:
        data = json.load(f)
        enemies = data['enemies']

    # Enemy levels start at SNES address $02:$C17C
    # LoROM mapping: $02:$C17C = PC $010000 + ($C17C - $8000) = $01417C
    levels_addr = 0x01417C

    print("="*80)
    print("Enemy Levels Verification")
    print("="*80)
    print()

    # Read ROM data
    rom_levels = read_rom_bytes(rom_path, levels_addr, 83 * 3)

    all_match = True
    mismatches = []

    for i, enemy in enumerate(enemies):
        offset = i * 3
        rom_data = rom_levels[offset:offset+3]

        # Compare level
        level_rom = rom_data[0]
        level_json = enemy['level']

        if level_rom != level_json:
            all_match = False
            mismatches.append({
                'enemy': enemy['name'],
                'field': 'Level',
                'rom': level_rom,
                'json': level_json
            })

    if all_match:
        print(f"✅ All {len(enemies)} enemy levels verified successfully!")
        print()
        print("Enemy levels in ROM match JSON data exactly.")
        return True
    else:
        print(f"❌ Found {len(mismatches)} mismatches:")
        print()
        for m in mismatches[:10]:
            print(f"  {m['enemy']} - {m['field']}: ROM={m['rom']}, JSON={m['json']}")

        if len(mismatches) > 10:
            print(f"  ... and {len(mismatches) - 10} more")

        return False

def main():
    """Main entry point."""
    rom_path = Path("build/ffmq-rebuilt.sfc")
    json_path = Path("data/extracted/enemies/enemies.json")

    if not rom_path.exists():
        print(f"[ERROR] ROM not found: {rom_path}")
        print("        Run build.ps1 first")
        return False

    if not json_path.exists():
        print(f"[ERROR] JSON data not found: {json_path}")
        return False

    print("[INFO] Verifying battle data integration...")
    print(f"[INFO] ROM: {rom_path}")
    print(f"[INFO] JSON: {json_path}")
    print()

    stats_ok = verify_enemy_stats(rom_path, json_path)
    print()
    levels_ok = verify_enemy_levels(rom_path, json_path)
    print()

    if stats_ok and levels_ok:
        print("="*80)
        print("✅ BUILD INTEGRATION VERIFIED!")
        print("="*80)
        print()
        print("Your enemy data modifications are now integrated into the ROM!")
        print()
        print("You can now:")
        print("  1. Edit enemies using the GUI: enemy_editor.bat")
        print("  2. Convert changes to ASM: python tools/conversion/convert_all.py")
        print("  3. Rebuild ROM: pwsh -File build.ps1")
        print("  4. Test in emulator: mesen build/ffmq-rebuilt.sfc")
        return True
    else:
        print("="*80)
        print("❌ VERIFICATION FAILED")
        print("="*80)
        print()
        print("The ROM data doesn't match the JSON source.")
        print("This may indicate:")
        print("  • ASM files weren't regenerated after JSON changes")
        print("  • Build system integration has issues")
        print("  • ROM addresses are incorrect")
        return False

if __name__ == '__main__':
    import sys
    sys.exit(0 if main() else 1)
