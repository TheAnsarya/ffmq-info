"""
Extract Bank $06 Map Tilemap Data
==================================

This tool extracts all metatile definitions, collision data, and screen layouts
from Bank $06 into structured JSON format.

Input:  ROM file (ffmq.sfc) or raw Bank $06 data
Output: data/map_tilemaps.json with all extracted structures

Usage:
    python tools/extract_bank06_data.py ffmq.sfc
"""

import sys
import os
from pathlib import Path

# Add tools directory to path for imports
sys.path.insert(0, str(Path(__file__).parent))

from ffmq_data_structures import Metatile, CollisionData, save_to_json


# Bank $06 memory map
BANK_06_START = 0x068000
BANK_06_SIZE = 0x008000  # 32KB

# Known data sections in Bank $06
METATILE_DATA_START = 0x068000  # All metatiles stored sequentially
METATILE_COUNT = 256  # Total metatiles in Bank $06 (256 * 4 bytes = 1024 bytes = $400)

# Collision data appears interleaved with tilemap data
# Starting around 0x06A000

def load_rom(filepath: str) -> bytes:
    """Load ROM file and return raw bytes."""
    with open(filepath, 'rb') as f:
        return f.read()


def extract_metatiles(rom_data: bytes, start_addr: int, count: int, offset_id: int = 0) -> list[Metatile]:
    """
    Extract metatile definitions from ROM.
    
    Args:
        rom_data: Full ROM data
        start_addr: Starting address (SNES $xx:xxxx format)
        count: Number of metatiles to extract
        offset_id: Starting ID for metatiles
        
    Returns:
        List of Metatile objects
    """
    metatiles = []
    
    for i in range(count):
        offset = start_addr + (i * 4)  # 4 bytes per metatile
        if offset + 4 > len(rom_data):
            break
        
        tile_data = rom_data[offset:offset+4]
        metatile = Metatile.from_bytes(tile_data, metatile_id=offset_id + i)
        
        # Add description based on patterns
        metatile.description = classify_metatile(metatile, offset_id + i)
        
        metatiles.append(metatile)
    
    return metatiles


def classify_metatile(metatile: Metatile, tile_id: int) -> str:
    """
    Attempt to classify metatile based on tile values.
    
    This is heuristic - actual meanings require reverse engineering.
    """
    tiles = [metatile.top_left, metatile.top_right, metatile.bottom_left, metatile.bottom_right]
    
    # Check for empty tiles
    if metatile.is_empty():
        return "Empty/transparent"
    
    # Check for common padding
    if all(t in [0x9A, 0x9B] for t in tiles):
        return "Padding/filler"
    
    # Check if all tiles are same (solid color/pattern)
    if len(set(tiles)) == 1:
        return f"Solid pattern (tile ${tiles[0]:02X})"
    
    # Check for symmetric patterns
    if tiles[0] == tiles[3] and tiles[1] == tiles[2]:
        return "Symmetric diagonal"
    if tiles[0] == tiles[1] and tiles[2] == tiles[3]:
        return "Horizontal split"
    if tiles[0] == tiles[2] and tiles[1] == tiles[3]:
        return "Vertical split"
    
    # Classify by tile ranges (heuristic)
    avg_tile = sum(tiles) // 4
    if avg_tile < 0x20:
        return "Ground/floor pattern"
    elif avg_tile < 0x40:
        return "Wall/building pattern"
    elif avg_tile < 0x60:
        return "Object/furniture"
    elif avg_tile < 0x80:
        return "Special graphics"
    else:
        return "Unknown pattern"


def extract_collision_data(rom_data: bytes, start_addr: int, count: int) -> list[CollisionData]:
    """
    Extract collision flags from ROM.
    
    Args:
        rom_data: Full ROM data
        start_addr: Starting address
        count: Number of collision bytes to extract
        
    Returns:
        List of CollisionData objects
    """
    collision_data = []
    
    for i in range(count):
        offset = start_addr + i
        if offset >= len(rom_data):
            break
        
        flags = rom_data[offset:offset+1]
        collision = CollisionData.from_bytes(flags, tile_id=i)
        collision_data.append(collision)
    
    return collision_data


def main():
    if len(sys.argv) < 2:
        print("Usage: python extract_bank06_data.py <rom_file>")
        print("Example: python extract_bank06_data.py ffmq.sfc")
        sys.exit(1)
    
    rom_path = sys.argv[1]
    if not os.path.exists(rom_path):
        print(f"Error: ROM file not found: {rom_path}")
        sys.exit(1)
    
    print(f"Loading ROM: {rom_path}")
    rom_data = load_rom(rom_path)
    print(f"ROM size: {len(rom_data):,} bytes")
    
    # Create output directory
    output_dir = Path(__file__).parent.parent / "data"
    output_dir.mkdir(exist_ok=True)
    
    print("\nExtracting Bank $06 data...")
    
    # Extract all metatiles sequentially
    print("  - Metatiles (all 256 tiles)...")
    all_metatiles = extract_metatiles(rom_data, METATILE_DATA_START, METATILE_COUNT, offset_id=0)
    
    print(f"  Total metatiles extracted: {len(all_metatiles)}")
    
    # Extract collision data (heuristic - actual location may vary)
    print("  - Collision data...")
    collision_start = 0x06A000  # Estimated based on ROM analysis
    collision_data = extract_collision_data(rom_data, collision_start, 256)
    
    print(f"  Total collision entries: {len(collision_data)}")
    
    # Build JSON structure
    print("\nBuilding JSON structure...")
    json_output = {
        "bank": "$06",
        "description": "Map tilemap and collision data",
        "metatile_format": "16x16 pixels (4x 8x8 tiles): [TL, TR, BL, BR]",
        "metatiles": {
            "start_address": f"${METATILE_DATA_START:06X}",
            "count": len(all_metatiles),
            "metatiles": [m.to_dict() for m in all_metatiles]
        },
        "collision": {
            "start_address": f"${collision_start:06X}",
            "count": len(collision_data),
            "entries": [c.to_dict() for c in collision_data]
        },
        "total_metatiles": len(all_metatiles),
        "total_collision_entries": len(collision_data)
    }
    
    # Save to JSON
    output_file = output_dir / "map_tilemaps.json"
    print(f"\nSaving to: {output_file}")
    
    import json
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(json_output, f, indent=2)
    
    print(f"✓ Successfully extracted {len(all_metatiles)} metatiles")
    print(f"✓ Successfully extracted {len(collision_data)} collision entries")
    print(f"✓ Output saved to: {output_file}")
    
    # Generate statistics
    print("\n" + "="*70)
    print("STATISTICS")
    print("="*70)
    
    # Metatile type distribution
    type_counts = {}
    for m in all_metatiles:
        desc = m.description.split('(')[0].strip()  # Get category
        type_counts[desc] = type_counts.get(desc, 0) + 1
    
    print("\nMetatile Types:")
    for mtype, count in sorted(type_counts.items(), key=lambda x: -x[1]):
        print(f"  {mtype:30s}: {count:3d} ({100*count/len(all_metatiles):.1f}%)")
    
    # Collision statistics
    passable = sum(1 for c in collision_data if c.is_passable)
    blocked = sum(1 for c in collision_data if c.is_blocked)
    water = sum(1 for c in collision_data if c.is_water)
    lava = sum(1 for c in collision_data if c.is_lava)
    trigger = sum(1 for c in collision_data if c.is_trigger)
    
    print("\nCollision Flags:")
    print(f"  Passable tiles: {passable:3d} ({100*passable/len(collision_data):.1f}%)")
    print(f"  Blocked tiles:  {blocked:3d} ({100*blocked/len(collision_data):.1f}%)")
    print(f"  Water tiles:    {water:3d} ({100*water/len(collision_data):.1f}%)")
    print(f"  Lava tiles:     {lava:3d} ({100*lava/len(collision_data):.1f}%)")
    print(f"  Trigger tiles:  {trigger:3d} ({100*trigger/len(collision_data):.1f}%)")
    
    print("\nDone!")


if __name__ == "__main__":
    main()
