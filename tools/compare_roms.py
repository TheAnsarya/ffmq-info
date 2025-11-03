#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
ROM Comparison Tool
===================

Compare two SNES ROM files and report differences.
Useful for verifying modifications and understanding what changed.

Usage:
    python tools/compare_roms.py original.sfc modified.sfc
    python tools/compare_roms.py original.sfc modified.sfc --verbose
    python tools/compare_roms.py original.sfc modified.sfc --regions
"""

import sys
import io
from pathlib import Path
from typing import List, Tuple

# Fix Windows console encoding
if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

# Known FFMQ data regions (LoROM PC offsets)
KNOWN_REGIONS = {
    'Enemy Stats': (0x014275, 0x014275 + 1162),
    'Enemy Levels': (0x01417C, 0x01417C + 249),
    'Attack Data': (0x014678, 0x014678 + 1183),
    'Text Data': (0x0D8000, 0x0DFFFF),  # Approximate
    'Graphics': (0x080000, 0x0BFFFF),    # Approximate
}

def read_rom(path: Path) -> bytes:
    """Read ROM file."""
    with open(path, 'rb') as f:
        return f.read()

def find_differences(rom1: bytes, rom2: bytes) -> List[Tuple[int, int, int]]:
    """
    Find all byte differences between two ROMs.
    
    Returns:
        List of (offset, byte1, byte2) tuples
    """
    min_size = min(len(rom1), len(rom2))
    differences = []
    
    for i in range(min_size):
        if rom1[i] != rom2[i]:
            differences.append((i, rom1[i], rom2[i]))
    
    # Check for size differences
    if len(rom1) != len(rom2):
        print(f"[WARNING] ROM sizes differ: {len(rom1)} vs {len(rom2)} bytes")
    
    return differences

def identify_region(offset: int) -> str:
    """Identify which known region an offset belongs to."""
    for name, (start, end) in KNOWN_REGIONS.items():
        if start <= offset < end:
            return name
    return "Unknown"

def format_hex_dump(data: bytes, offset: int, width: int = 16) -> str:
    """Format bytes as hex dump."""
    lines = []
    for i in range(0, len(data), width):
        chunk = data[i:i+width]
        hex_str = ' '.join(f'{b:02X}' for b in chunk)
        ascii_str = ''.join(chr(b) if 32 <= b < 127 else '.' for b in chunk)
        lines.append(f"{offset+i:06X}  {hex_str:<48}  {ascii_str}")
    return '\n'.join(lines)

def compare_roms(rom1_path: Path, rom2_path: Path, verbose: bool = False, show_regions: bool = False):
    """Compare two ROM files and report differences."""
    
    print("=" * 80)
    print("ROM Comparison Tool")
    print("=" * 80)
    print()
    
    # Read ROMs
    print(f"[INFO] Reading ROM 1: {rom1_path.name}")
    rom1 = read_rom(rom1_path)
    print(f"       Size: {len(rom1):,} bytes ({len(rom1) / 1024:.1f} KB)")
    
    print(f"[INFO] Reading ROM 2: {rom2_path.name}")
    rom2 = read_rom(rom2_path)
    print(f"       Size: {len(rom2):,} bytes ({len(rom2) / 1024:.1f} KB)")
    print()
    
    # Find differences
    print("[INFO] Comparing ROMs...")
    differences = find_differences(rom1, rom2)
    
    if not differences:
        print("[OK] ROMs are identical!")
        return
    
    print(f"[INFO] Found {len(differences):,} byte differences")
    print()
    
    # Group differences by region
    if show_regions:
        print("=" * 80)
        print("Differences by Region")
        print("=" * 80)
        
        region_diffs = {}
        for offset, b1, b2 in differences:
            region = identify_region(offset)
            if region not in region_diffs:
                region_diffs[region] = []
            region_diffs[region].append((offset, b1, b2))
        
        for region in sorted(region_diffs.keys()):
            count = len(region_diffs[region])
            print(f"\n{region}: {count} bytes changed")
            
            if region in KNOWN_REGIONS:
                start, end = KNOWN_REGIONS[region]
                size = end - start
                percent = (count / size) * 100
                print(f"  Region: ${start:06X} - ${end:06X} ({size} bytes)")
                print(f"  Changed: {percent:.1f}% of region")
    
    # Show detailed differences
    if verbose:
        print()
        print("=" * 80)
        print("Detailed Differences")
        print("=" * 80)
        print()
        
        # Group consecutive differences
        groups = []
        current_group = [differences[0]]
        
        for diff in differences[1:]:
            if diff[0] == current_group[-1][0] + 1:
                current_group.append(diff)
            else:
                groups.append(current_group)
                current_group = [diff]
        groups.append(current_group)
        
        for group in groups[:20]:  # Show first 20 groups
            start_offset = group[0][0]
            end_offset = group[-1][0]
            region = identify_region(start_offset)
            
            print(f"Offset ${start_offset:06X} - ${end_offset:06X} ({region})")
            print(f"  Length: {len(group)} bytes")
            print()
            
            # Show hex comparison
            print("  ROM 1:")
            rom1_chunk = rom1[start_offset:end_offset+1]
            for line in format_hex_dump(rom1_chunk, start_offset).split('\n'):
                print(f"    {line}")
            
            print()
            print("  ROM 2:")
            rom2_chunk = rom2[start_offset:end_offset+1]
            for line in format_hex_dump(rom2_chunk, start_offset).split('\n'):
                print(f"    {line}")
            
            print()
        
        if len(groups) > 20:
            print(f"... and {len(groups) - 20} more difference groups")
    
    # Summary
    print()
    print("=" * 80)
    print("Summary")
    print("=" * 80)
    print(f"Total differences: {len(differences):,} bytes")
    print(f"ROM 1 size: {len(rom1):,} bytes")
    print(f"ROM 2 size: {len(rom2):,} bytes")
    
    if len(rom1) > 0:
        percent = (len(differences) / len(rom1)) * 100
        print(f"Difference: {percent:.3f}%")
    
    print()
    print("Likely modified regions:")
    region_diffs = {}
    for offset, b1, b2 in differences:
        region = identify_region(offset)
        region_diffs[region] = region_diffs.get(region, 0) + 1
    
    for region, count in sorted(region_diffs.items(), key=lambda x: -x[1]):
        if count > 10:  # Only show regions with significant changes
            print(f"  - {region}: {count} bytes")

def main():
    """Main entry point."""
    import argparse
    
    parser = argparse.ArgumentParser(
        description='Compare two SNES ROM files',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Basic comparison
  python tools/compare_roms.py original.sfc modified.sfc
  
  # Show detailed differences
  python tools/compare_roms.py original.sfc modified.sfc --verbose
  
  # Group by known regions
  python tools/compare_roms.py original.sfc modified.sfc --regions
  
  # Full analysis
  python tools/compare_roms.py original.sfc modified.sfc --verbose --regions
        """
    )
    
    parser.add_argument('rom1', type=Path, help='First ROM file (original)')
    parser.add_argument('rom2', type=Path, help='Second ROM file (modified)')
    parser.add_argument('--verbose', '-v', action='store_true', 
                       help='Show detailed byte-by-byte differences')
    parser.add_argument('--regions', '-r', action='store_true',
                       help='Group differences by known data regions')
    
    args = parser.parse_args()
    
    # Validate files
    if not args.rom1.exists():
        print(f"[ERROR] ROM 1 not found: {args.rom1}")
        return 1
    
    if not args.rom2.exists():
        print(f"[ERROR] ROM 2 not found: {args.rom2}")
        return 1
    
    compare_roms(args.rom1, args.rom2, args.verbose, args.regions)
    return 0

if __name__ == '__main__':
    sys.exit(main())
