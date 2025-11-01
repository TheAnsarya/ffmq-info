"""
Extract Bank $08 Text/Dialog Data
==================================

This tool extracts text pointer tables and dialog strings from Bank $08
into structured JSON format.

Input:  ROM file (ffmq.sfc)
Output: data/text_data.json with pointers and strings

Usage:
    python tools/extract_bank08_data.py "roms/FFMQ.sfc"
"""

import sys
import os
from pathlib import Path

# Add tools directory to path for imports
sys.path.insert(0, str(Path(__file__).parent))

from ffmq_data_structures import TextPointer, DialogString, save_to_json


# Bank $08 memory map
BANK_08_START = 0x088000
BANK_08_SIZE = 0x008000  # 32KB

# Text data starts immediately (Bank $08 is ALL text data)
TEXT_DATA_START = 0x088000

# We'll extract raw bytes and decode them
# No pointer table extraction for now - just raw text data


def load_rom(filepath: str) -> bytes:
    """Load ROM file and return raw bytes."""
    with open(filepath, 'rb') as f:
        return f.read()


def load_character_encoding(tbl_path: str = "simple.tbl") -> dict:
    """
    Load character encoding table from .tbl file.
    
    Format: BYTE=CHARACTER
    Example: 20=<space>
    """
    encoding = {}
    
    if not os.path.exists(tbl_path):
        print(f"Warning: {tbl_path} not found, using ASCII fallback")
        # Fallback to basic ASCII
        for i in range(0x20, 0x7f):
            encoding[i] = chr(i)
        return encoding
    
    with open(tbl_path, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith(';'):
                continue
            
            if '=' in line:
                hex_val, char = line.split('=', 1)
                try:
                    byte_val = int(hex_val, 16)
                    encoding[byte_val] = char
                except ValueError:
                    continue
    
    return encoding


def extract_text_pointers(rom_data: bytes, start_addr: int, count: int) -> list[TextPointer]:
    """
    Extract text pointer table from ROM.
    
    Args:
        rom_data: Full ROM data
        start_addr: Starting address of pointer table
        count: Number of pointers to extract
        
    Returns:
        List of TextPointer objects
    """
    pointers = []
    
    for i in range(count):
        offset = start_addr + (i * 2)  # 2 bytes per pointer
        if offset + 2 > len(rom_data):
            break
        
        # Check if pointer is null (end of table)
        if rom_data[offset] == 0 and rom_data[offset+1] == 0:
            break
        
        pointer_data = rom_data[offset:offset+2]
        pointer = TextPointer.from_bytes(pointer_data, message_id=i)
        pointers.append(pointer)
    
    return pointers


def extract_dialog_strings(rom_data: bytes, pointers: list[TextPointer], 
                           bank_base: int, encoding: dict) -> list[DialogString]:
    """
    Extract dialog strings using pointer table.
    
    Args:
        rom_data: Full ROM data
        pointers: List of text pointers
        bank_base: Bank starting address ($088000)
        encoding: Character encoding table
        
    Returns:
        List of DialogString objects
    """
    strings = []
    
    for pointer in pointers:
        # Calculate ROM offset
        rom_offset = bank_base + pointer.address
        
        if rom_offset >= len(rom_data):
            print(f"Warning: Pointer {pointer.message_id:03X} offset ${rom_offset:06X} out of range")
            continue
        
        # Read until null terminator or max length
        max_length = 512  # Safety limit
        string_data = rom_data[rom_offset:rom_offset+max_length]
        
        # Find null terminator
        null_pos = string_data.find(b'\x00')
        if null_pos != -1:
            string_data = string_data[:null_pos]
        
        # Parse dialog string
        dialog = DialogString.from_bytes(string_data, 
                                         message_id=pointer.message_id,
                                         encoding_table=encoding)
        strings.append(dialog)
    
    return strings


def analyze_control_codes(strings: list[DialogString]) -> dict:
    """Analyze control code usage across all strings."""
    code_counts = {}
    
    for string in strings:
        for pos in string.control_codes:
            if pos < len(string.raw_bytes):
                code = string.raw_bytes[pos]
                code_counts[code] = code_counts.get(code, 0) + 1
    
    return code_counts


def main():
    if len(sys.argv) < 2:
        print("Usage: python extract_bank08_data.py <rom_file>")
        print('Example: python extract_bank08_data.py "roms/FFMQ.sfc"')
        sys.exit(1)
    
    rom_path = sys.argv[1]
    if not os.path.exists(rom_path):
        print(f"Error: ROM file not found: {rom_path}")
        sys.exit(1)
    
    print(f"Loading ROM: {rom_path}")
    rom_data = load_rom(rom_path)
    print(f"ROM size: {len(rom_data):,} bytes")
    
    # Load character encoding
    print("\nLoading character encoding table...")
    encoding = load_character_encoding()
    print(f"Loaded {len(encoding)} character mappings")
    
    # Create output directory
    output_dir = Path(__file__).parent.parent / "data"
    output_dir.mkdir(exist_ok=True)
    
    print("\nExtracting Bank $08 text data...")
    
    # Extract text pointers
    print("  - Text pointer table...")
    pointers = extract_text_pointers(rom_data, TEXT_POINTER_TABLE_START, TEXT_POINTER_TABLE_COUNT)
    print(f"  Found {len(pointers)} text pointers")
    
    # Extract dialog strings
    print("  - Dialog strings...")
    strings = extract_dialog_strings(rom_data, pointers, BANK_08_START, encoding)
    print(f"  Extracted {len(strings)} dialog strings")
    
    # Analyze control codes
    print("  - Analyzing control codes...")
    control_codes = analyze_control_codes(strings)
    
    # Build JSON structure
    print("\nBuilding JSON structure...")
    json_output = {
        "bank": "$08",
        "description": "Text and dialog data",
        "pointer_table": {
            "start_address": f"${TEXT_POINTER_TABLE_START:06X}",
            "count": len(pointers),
            "pointers": [p.to_dict() for p in pointers]
        },
        "dialog_strings": {
            "count": len(strings),
            "strings": [s.to_dict() for s in strings]
        },
        "control_codes_used": {
            f"${code:02X}": count for code, count in sorted(control_codes.items())
        },
        "encoding_table_entries": len(encoding)
    }
    
    # Save to JSON
    output_file = output_dir / "text_data.json"
    print(f"\nSaving to: {output_file}")
    
    import json
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(json_output, f, indent=2, ensure_ascii=False)
    
    print(f"✓ Successfully extracted {len(pointers)} pointers")
    print(f"✓ Successfully extracted {len(strings)} dialog strings")
    print(f"✓ Output saved to: {output_file}")
    
    # Generate statistics
    print("\n" + "="*70)
    print("STATISTICS")
    print("="*70)
    
    # String length distribution
    lengths = [len(s.raw_bytes) for s in strings]
    avg_length = sum(lengths) / len(lengths) if lengths else 0
    max_length = max(lengths) if lengths else 0
    
    print(f"\nDialog Strings:")
    print(f"  Total strings: {len(strings)}")
    print(f"  Average length: {avg_length:.1f} bytes")
    print(f"  Maximum length: {max_length} bytes")
    print(f"  Total text data: {sum(lengths):,} bytes")
    
    # Control codes
    print(f"\nControl Codes Used:")
    control_code_names = {
        0xf0: "END (close dialog)",
        0xf1: "NEWLINE",
        0xf2: "WAIT (for input)",
        0xf3: "CLEAR (screen)",
        0xf4: "VAR (insert variable)",
        0xf5: "ITEM (insert item name)",
        0xf6: "CHAR (insert character name)",
        0xf7: "NUM (format number)"
    }
    
    for code, count in sorted(control_codes.items()):
        name = control_code_names.get(code, "Unknown")
        print(f"  ${code:02X} ({name:20s}): {count:4d} uses")
    
    # Sample strings
    print(f"\nSample Dialog Strings:")
    for i, string in enumerate(strings[:5]):
        text_preview = string.text[:60] if string.text else "(binary data)"
        print(f"  Msg ${i:03X}: {text_preview}...")
    
    print("\nDone!")


if __name__ == "__main__":
    main()
