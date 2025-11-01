"""
Round-Trip Verification Tool for FFMQ Data Pipeline
====================================================

Verifies that ROM → JSON → ASM → Binary produces byte-exact results.

Usage:
    python tools/verify_roundtrip.py "roms/FFMQ.sfc"
"""

import sys
import os
import json
from pathlib import Path

# Add tools directory to path
sys.path.insert(0, str(Path(__file__).parent))

from ffmq_data_structures import Metatile, CollisionData


def load_rom(filepath: str) -> bytes:
    """Load ROM file."""
    with open(filepath, 'rb') as f:
        return f.read()


def verify_bank06_metatiles(rom_data: bytes, json_path: str) -> dict:
    """
    Verify Bank $06 metatile data round-trip.
    
    Returns:
        dict with verification results
    """
    results = {
        'bank': '$06',
        'data_type': 'metatiles',
        'total_bytes': 0,
        'matching_bytes': 0,
        'mismatches': [],
        'success': True
    }
    
    # Load JSON
    with open(json_path, 'r') as f:
        data = json.load(f)
    
    # Get metatile data
    metatile_addr = int(data['metatiles']['start_address'].replace('$', ''), 16)
    all_metatiles = data['metatiles']['metatiles']
    
    for metatile_dict in all_metatiles:
        tile_id = metatile_dict['id']
        metatile = Metatile.from_dict(metatile_dict)
        
        # Get original ROM bytes
        offset = metatile_addr + (tile_id * 4)
        original = rom_data[offset:offset+4]
        
        # Regenerate bytes from JSON
        regenerated = metatile.to_bytes()
        
        results['total_bytes'] += 4
        
        if original == regenerated:
            results['matching_bytes'] += 4
        else:
            results['success'] = False
            results['mismatches'].append({
                'offset': f'${offset:06X}',
                'metatile_id': f'${tile_id:02X}',
                'original': original.hex().upper(),
                'regenerated': regenerated.hex().upper()
            })
    
    return results


def verify_bank06_collision(rom_data: bytes, json_path: str) -> dict:
    """
    Verify Bank $06 collision data round-trip.
    
    Returns:
        dict with verification results
    """
    results = {
        'bank': '$06',
        'data_type': 'collision',
        'total_bytes': 0,
        'matching_bytes': 0,
        'mismatches': [],
        'success': True
    }
    
    # Load JSON
    with open(json_path, 'r') as f:
        data = json.load(f)
    
    collision_addr = 0x06A000
    collision_data = data['collision']['entries']
    
    for entry_dict in collision_data:
        collision = CollisionData.from_dict(entry_dict)
        
        # Get original ROM byte
        offset = collision_addr + collision.tile_id
        original = rom_data[offset:offset+1]
        
        # Regenerate byte from JSON
        regenerated = collision.to_bytes()
        
        results['total_bytes'] += 1
        
        if original == regenerated:
            results['matching_bytes'] += 1
        else:
            results['success'] = False
            results['mismatches'].append({
                'offset': f'${offset:06X}',
                'tile_id': f'${collision.tile_id:02X}',
                'original': original.hex().upper(),
                'regenerated': regenerated.hex().upper()
            })
    
    return results


def print_verification_report(results: list[dict]):
    """Print human-readable verification report."""
    print("="*80)
    print("ROUND-TRIP VERIFICATION REPORT")
    print("="*80)
    print()
    
    total_tests = len(results)
    passed_tests = sum(1 for r in results if r['success'])
    
    for result in results:
        status = "✓ PASS" if result['success'] else "✗ FAIL"
        print(f"{status} - Bank {result['bank']} {result['data_type'].upper()}")
        print(f"  Bytes verified: {result['matching_bytes']}/{result['total_bytes']}")
        
        if not result['success']:
            print(f"  Mismatches: {len(result['mismatches'])}")
            print("  First 5 mismatches:")
            for i, mismatch in enumerate(result['mismatches'][:5]):
                print(f"    [{i+1}] Offset {mismatch['offset']}")
                print(f"        Original:    {mismatch['original']}")
                print(f"        Regenerated: {mismatch['regenerated']}")
        print()
    
    print("="*80)
    print(f"OVERALL: {passed_tests}/{total_tests} tests passed")
    
    if passed_tests == total_tests:
        print("✓ ALL VERIFICATIONS PASSED - Round-trip is byte-exact!")
    else:
        print("✗ VERIFICATION FAILED - Data does not match original ROM")
    print("="*80)
    
    return passed_tests == total_tests


def main():
    if len(sys.argv) < 2:
        print("Usage: python verify_roundtrip.py <rom_file>")
        print('Example: python verify_roundtrip.py "roms/FFMQ.sfc"')
        sys.exit(1)
    
    rom_path = sys.argv[1]
    if not os.path.exists(rom_path):
        print(f"Error: ROM file not found: {rom_path}")
        sys.exit(1)
    
    print(f"Loading ROM: {rom_path}")
    rom_data = load_rom(rom_path)
    print(f"ROM size: {len(rom_data):,} bytes")
    print()
    
    # Verify Bank $06 data
    json_path = Path(__file__).parent.parent / "data" / "map_tilemaps.json"
    
    if not json_path.exists():
        print(f"Error: JSON data not found: {json_path}")
        print("Run extract_bank06_data.py first!")
        sys.exit(1)
    
    print("Running verifications...")
    print()
    
    results = []
    
    # Verify metatiles
    print("Verifying Bank $06 metatiles...")
    metatile_results = verify_bank06_metatiles(rom_data, str(json_path))
    results.append(metatile_results)
    
    # Verify collision
    print("Verifying Bank $06 collision data...")
    collision_results = verify_bank06_collision(rom_data, str(json_path))
    results.append(collision_results)
    
    print()
    
    # Print report
    all_passed = print_verification_report(results)
    
    # Exit with appropriate code
    sys.exit(0 if all_passed else 1)


if __name__ == "__main__":
    main()
