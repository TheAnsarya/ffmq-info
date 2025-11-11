#!/usr/bin/env python3
"""
Analyze unknown bytes in decoded dialogs to identify control codes
"""

import sys
import re
from pathlib import Path
from collections import Counter

# Add parent directories to path
sys.path.insert(0, str(Path(__file__).parent))
sys.path.insert(0, str(Path(__file__).parent / 'tools' / 'map-editor'))

from utils.dialog_database import DialogDatabase

def main():
    """Analyze unknown bytes"""
    
    rom_path = Path("roms/Final Fantasy - Mystic Quest (U) (V1.1).sfc")
    
    if not rom_path.exists():
        print(f"ERROR: ROM not found at {rom_path}")
        return False
    
    print("=== Unknown Byte Analysis ===\n")
    
    # Load database and extract dialogs
    db = DialogDatabase(rom_path)
    db.extract_all_dialogs()
    
    # Find all unknown bytes and their contexts
    unknown_contexts = {}
    
    for dialog_id, dialog in db.dialogs.items():
        # Find all unknown bytes in text
        matches = list(re.finditer(r'<([0-9A-F]{2})>', dialog.text))
        
        for match in matches:
            byte_hex = match.group(1)
            byte_val = int(byte_hex, 16)
            
            # Get context (20 chars before and after)
            start = max(0, match.start() - 20)
            end = min(len(dialog.text), match.end() + 20)
            context = dialog.text[start:end]
            
            if byte_val not in unknown_contexts:
                unknown_contexts[byte_val] = []
            
            unknown_contexts[byte_val].append({
                'dialog_id': dialog_id,
                'context': context,
                'position': match.start()
            })
    
    # Analyze patterns
    print(f"Found {len(unknown_contexts)} unique unknown bytes\n")
    
    # Group by range
    ranges = {
        '0x00-0x0F': [],
        '0x10-0x1F': [],
        '0x20-0x2F': [],
        '0x30-0x3F': [],
        '0x80-0x8F': [],
        '0xE0-0xFF': [],
    }
    
    for byte_val in sorted(unknown_contexts.keys()):
        if 0x00 <= byte_val <= 0x0F:
            ranges['0x00-0x0F'].append(byte_val)
        elif 0x10 <= byte_val <= 0x1F:
            ranges['0x10-0x1F'].append(byte_val)
        elif 0x20 <= byte_val <= 0x2F:
            ranges['0x20-0x2F'].append(byte_val)
        elif 0x30 <= byte_val <= 0x3F:
            ranges['0x30-0x3F'].append(byte_val)
        elif 0x80 <= byte_val <= 0x8F:
            ranges['0x80-0x8F'].append(byte_val)
        elif 0xE0 <= byte_val <= 0xFF:
            ranges['0xE0-0xFF'].append(byte_val)
    
    print("Unknown bytes by range:")
    for range_name, bytes_in_range in ranges.items():
        if bytes_in_range:
            print(f"\n{range_name}: {len(bytes_in_range)} bytes")
            print(f"  {', '.join(f'0x{b:02X}' for b in bytes_in_range)}")
    
    # Show most common unknown bytes
    frequency = Counter()
    for byte_val, contexts in unknown_contexts.items():
        frequency[byte_val] = len(contexts)
    
    print(f"\n\nMost common unknown bytes:")
    for byte_val, count in frequency.most_common(15):
        print(f"\n0x{byte_val:02X}: {count} occurrences")
        
        # Show a few example contexts
        examples = unknown_contexts[byte_val][:3]
        for ex in examples:
            # Clean context for display
            ctx_clean = ex['context'].replace('\n', '\\n')
            print(f"  Dialog 0x{ex['dialog_id']:02X}: ...{ctx_clean}...")
    
    # Check if bytes appear at specific positions (start/end of text)
    print("\n\nPosition analysis:")
    
    start_bytes = set()
    end_bytes = set()
    mid_bytes = set()
    
    for byte_val, contexts in unknown_contexts.items():
        for ctx in contexts:
            if ctx['position'] < 10:
                start_bytes.add(byte_val)
            elif ctx['position'] > len(ctx['context']) - 10:
                end_bytes.add(byte_val)
            else:
                mid_bytes.add(byte_val)
    
    print(f"Bytes appearing at start: {', '.join(f'0x{b:02X}' for b in sorted(start_bytes)[:10])}")
    print(f"Bytes appearing at end:   {', '.join(f'0x{b:02X}' for b in sorted(end_bytes)[:10])}")
    
    return True

if __name__ == '__main__':
    success = main()
    sys.exit(0 if success else 1)
