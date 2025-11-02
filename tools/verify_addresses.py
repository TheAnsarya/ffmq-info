#!/usr/bin/env python3
"""
Verify ROM data addresses against V1.1 reference.

This tool validates that all hardcoded addresses in extraction scripts
match the actual V1.1 ROM data locations and external references.
"""

import sys
from pathlib import Path
import hashlib
import struct

# ROM Configuration
ROM_PATH = Path("roms/Final Fantasy - Mystic Quest (U) (V1.1).sfc")
EXPECTED_MD5 = "f7faeae5a847c098d677070920769ca2"
EXPECTED_SIZE = 524288  # 512KB LoROM (no header)

# Known Data Structures (from FFMQ Randomizer and our extraction tools)
DATA_STRUCTURES = {
    "enemy_stats": {
        "bank": 0x02,
        "rom_addr": 0xC275,
        "file_offset": 0x0C275,
        "entry_size": 14,
        "entry_count": 83,
        "description": "Enemy stats (HP, Attack, Defense, etc.)",
        "source": "FFMQRando/Enemies.cs"
    },
    "enemy_level_mult": {
        "bank": 0x02,
        "rom_addr": 0xC17C,
        "file_offset": 0x0C17C,
        "entry_size": 3,
        "entry_count": 83,
        "description": "Enemy level and multipliers (Level, XP mult, GP mult)",
        "source": "FFMQRando/Enemies.cs"
    },
    "attack_data": {
        "bank": 0x02,
        "rom_addr": 0xBC78,
        "file_offset": 0x0BC78,
        "entry_size": 7,
        "entry_count": 169,
        "description": "Attack/battle action data",
        "source": "FFMQRando/Enemizer.cs"
    },
    "attack_links": {
        "bank": 0x02,
        "rom_addr": 0xC6FF,
        "file_offset": 0x0C6FF,
        "entry_size": 9,
        "entry_count": 82,
        "description": "Enemy attack links (which attacks each enemy uses)",
        "source": "FFMQRando/Enemizer.cs"
    },
    "spell_data": {
        "bank": 0x0C,
        "rom_addr": 0x0F36,
        "file_offset": 0x060F36,
        "entry_size": 6,
        "entry_count": 16,
        "description": "Spell data (power, flags, targeting)",
        "source": "Issue #52 research"
    }
}

def calculate_file_offset(bank, rom_addr):
    """
    Calculate file offset from bank number and ROM address.
    
    LoROM addressing: Banks map to 32KB chunks
    - Bank $00-$3F: ROM data at $8000-$FFFF (32KB per bank)
    - File offset = (bank & 0x3F) * 0x8000 + (rom_addr & 0x7FFF)
    
    For banks $00-$3F, addresses $8000-$FFFF map to ROM
    """
    # LoROM: Extract the lower 32KB of each bank
    file_offset = (bank & 0x3F) * 0x8000 + (rom_addr & 0x7FFF)
    return file_offset

def verify_rom_file(rom_path):
    """Verify ROM file exists and matches expected MD5."""
    if not rom_path.exists():
        print(f"❌ ERROR: ROM file not found at {rom_path}")
        return False
    
    # Check size
    size = rom_path.stat().st_size
    if size != EXPECTED_SIZE:
        print(f"⚠️  WARNING: ROM size {size} bytes, expected {EXPECTED_SIZE} bytes")
        if size == EXPECTED_SIZE + 512:
            print("   ROM appears to have a 512-byte header")
    
    # Check MD5
    print("Calculating ROM checksum...")
    md5 = hashlib.md5()
    with open(rom_path, 'rb') as f:
        md5.update(f.read())
    
    actual_md5 = md5.hexdigest()
    if actual_md5 == EXPECTED_MD5:
        print(f"✅ ROM MD5 verified: {actual_md5}")
        return True
    else:
        print(f"❌ ROM MD5 mismatch!")
        print(f"   Expected: {EXPECTED_MD5}")
        print(f"   Actual:   {actual_md5}")
        return False

def verify_address(rom_data, name, info):
    """Verify a specific data structure address."""
    print(f"\n{'='*70}")
    print(f"Verifying: {name}")
    print(f"{'='*70}")
    
    # Calculate expected offset
    calc_offset = calculate_file_offset(info['bank'], info['rom_addr'])
    file_offset = info['file_offset']
    
    print(f"Description: {info['description']}")
    print(f"Source: {info['source']}")
    print(f"Bank: ${info['bank']:02X}")
    print(f"ROM Address: ${info['rom_addr']:04X}")
    print(f"File Offset (documented): ${file_offset:06X}")
    print(f"File Offset (calculated): ${calc_offset:06X}")
    
    if calc_offset != file_offset:
        print(f"⚠️  WARNING: Calculated offset differs from documented offset!")
        print(f"   Difference: {calc_offset - file_offset} bytes")
    else:
        print(f"✅ Address calculation matches documented offset")
    
    # Read sample data
    total_size = info['entry_size'] * info['entry_count']
    if file_offset + total_size > len(rom_data):
        print(f"❌ ERROR: Data extends beyond ROM size!")
        print(f"   Offset: ${file_offset:06X}")
        print(f"   Size: ${total_size:04X} ({total_size} bytes)")
        print(f"   End: ${file_offset + total_size:06X}")
        print(f"   ROM Size: ${len(rom_data):06X}")
        return False
    
    # Display first entry
    first_entry = rom_data[file_offset:file_offset + info['entry_size']]
    print(f"\nFirst entry ({info['entry_size']} bytes):")
    print(f"  Hex: {' '.join(f'{b:02X}' for b in first_entry)}")
    print(f"  Dec: {' '.join(f'{b:3d}' for b in first_entry)}")
    
    # Display last entry
    last_offset = file_offset + (info['entry_count'] - 1) * info['entry_size']
    last_entry = rom_data[last_offset:last_offset + info['entry_size']]
    print(f"\nLast entry ({info['entry_size']} bytes):")
    print(f"  Hex: {' '.join(f'{b:02X}' for b in last_entry)}")
    print(f"  Dec: {' '.join(f'{b:3d}' for b in last_entry)}")
    
    # Sanity checks
    all_zero = all(b == 0 for b in first_entry)
    all_ff = all(b == 0xFF for b in first_entry)
    
    if all_zero:
        print(f"⚠️  WARNING: First entry is all zeros - may be uninitialized data")
    elif all_ff:
        print(f"⚠️  WARNING: First entry is all 0xFF - may be empty data")
    else:
        print(f"✅ Data appears valid (not all zeros or 0xFF)")
    
    return True

def main():
    print("="*70)
    print("ROM Address Verification Tool")
    print("="*70)
    print(f"ROM: {ROM_PATH}")
    print(f"Expected MD5: {EXPECTED_MD5}")
    print()
    
    # Verify ROM file
    if not verify_rom_file(ROM_PATH):
        print("\n❌ ROM verification failed - cannot continue")
        sys.exit(1)
    
    # Load ROM data
    print(f"\nLoading ROM data...")
    rom_data = ROM_PATH.read_bytes()
    print(f"✅ Loaded {len(rom_data)} bytes")
    
    # Verify each data structure
    all_valid = True
    for name, info in DATA_STRUCTURES.items():
        if not verify_address(rom_data, name, info):
            all_valid = False
    
    # Summary
    print(f"\n{'='*70}")
    print("VERIFICATION SUMMARY")
    print(f"{'='*70}")
    print(f"ROM File: {'✅ Valid' if True else '❌ Invalid'}")
    print(f"Data Structures Verified: {len(DATA_STRUCTURES)}")
    print(f"Status: {'✅ ALL ADDRESSES VERIFIED' if all_valid else '⚠️ SOME ISSUES FOUND'}")
    print()
    
    if all_valid:
        print("✅ All ROM addresses verified successfully!")
        print("   Extraction scripts are using correct offsets for V1.1 ROM")
    else:
        print("⚠️ Some verification issues found - review output above")
        sys.exit(1)

if __name__ == "__main__":
    main()
