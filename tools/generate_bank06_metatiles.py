"""
Generate complete Bank $06 metatile ASM from extracted JSON data.
This replaces placeholders with actual ROM data.
"""

import json
import sys


def generate_metatile_asm(metatile_data: dict) -> str:
    """Generate ASM for a single metatile."""
    tiles = metatile_data['tiles']
    desc = metatile_data['description']
    tid = metatile_data['id']
    
    return f"                       db ${tiles['top_left']:02X},${tiles['top_right']:02X},${tiles['bottom_left']:02X},${tiles['bottom_right']:02X}  ; Metatile ${tid:02X}: {desc}"


def main():
    # Load the JSON data
    with open('data/map_tilemaps.json', 'r') as f:
        data = json.load(f)
    
    print("; " + "="*78)
    print("; BANK $06 - COMPLETE METATILE DATA (AUTO-GENERATED)")
    print("; " + "="*78)
    print()
    
    # All metatiles in one sequential block
    print("; " + "-"*78)
    print("; Map Tilemaps - All 256 Metatiles (Sequential)")
    print("; " + "-"*78)
    print()
    print("DATA8_068000:")
    
    all_metatiles = data['metatiles']['metatiles']
    for i, metatile in enumerate(all_metatiles):
        print(generate_metatile_asm(metatile))
        if (i + 1) % 16 == 0 and i < len(all_metatiles) - 1:
            print()  # Blank line every 16 entries for readability
    
    print()
    print("; " + "="*78)
    print(f"; TOTAL: {len(all_metatiles)} metatiles defined")
    print("; " + "="*78)


if __name__ == "__main__":
    main()
