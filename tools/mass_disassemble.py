#!/usr/bin/env python3
"""
Automated Mass Disassembly Script for FFMQ
Processes multiple banks in parallel to maximize progress
"""

import os
import re
import sys
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed

# Bank information
BANKS = {
    0x00: {"lines": 14017, "desc": "Main Game Engine", "priority": 1},
    0x01: {"lines": 15480, "desc": "Battle System", "priority": 2},
    0x02: {"lines": 2844, "desc": "Graphics/Sprites", "priority": 3},
    0x03: {"lines": 3912, "desc": "Sound/Music", "priority": 3},
    0x04: {"lines": 4567, "desc": "Menu System", "priority": 3},
    0x05: {"lines": 3324, "desc": "Map Engine", "priority": 3},
    0x06: {"lines": 2156, "desc": "Item System", "priority": 4},
    0x07: {"lines": 4891, "desc": "Enemy AI", "priority": 2},
    0x08: {"lines": 3445, "desc": "Text/Dialog", "priority": 4},
    0x09: {"lines": 2977, "desc": "Save System", "priority": 4},
    0x0a: {"lines": 3621, "desc": "Magic System", "priority": 3},
    0x0b: {"lines": 2845, "desc": "Equipment", "priority": 4},
    0x0c: {"lines": 4102, "desc": "Cutscenes", "priority": 4},
    0x0d: {"lines": 3856, "desc": "World Map", "priority": 3},
    0x0e: {"lines": 2498, "desc": "Shops/NPCs", "priority": 4},
    0x0f: {"lines": 3147, "desc": "Misc Systems", "priority": 4},
}

TOTAL_LINES = 74682

def convert_bank_section(bank_num: int, start_line: int, end_line: int, input_file: Path, output_file: Path):
    """Convert and document a section of a bank"""
    print(f"  [Bank ${bank_num:02X}] Processing lines {start_line}-{end_line}...")
    
    try:
        with open(input_file, 'r', encoding='utf-8', errors='ignore') as f:
            lines = f.readlines()
        
        if start_line >= len(lines):
            return 0
        
        section_lines = lines[start_line:min(end_line, len(lines))]
        documented_lines = []
        
        for line in section_lines:
            # Convert Diztinguish format
            line = re.sub(r';[0-9A-Fa-f]{6}\|[0-9A-Fa-f]{2}\|', '', line)  # Remove PC addresses
            line = re.sub(r'^([A-Z_][A-Z0-9_]*):$', r'\1:', line)  # Fix label format
            
            # Detect patterns and add basic comments
            if re.search(r'\b(JSR|JSL)\b', line):
                if 'TODO' not in line:
                    line = line.rstrip() + "    ; Call subroutine\n"
            elif re.search(r'\b(RTS|RTL)\b', line):
                if 'TODO' not in line:
                    line = line.rstrip() + "    ; Return\n"
            elif re.search(r'\bSTA\b.*SNES', line):
                if 'TODO' not in line:
                    line = line.rstrip() + "    ; Write to PPU register\n"
            
            documented_lines.append(line)
        
        # Append to output file
        with open(output_file, 'a', encoding='utf-8') as f:
            f.writelines(documented_lines)
        
        return len(section_lines)
    
    except Exception as e:
        print(f"  [Bank ${bank_num:02X}] ERROR: {e}")
        return 0

def process_bank(bank_num: int, bank_info: dict, base_path: Path):
    """Process an entire bank"""
    input_file = base_path / f"diztinguish/Disassembly/bank_{bank_num:02X}.asm"
    output_file = base_path / f"src/asm/bank_{bank_num:02X}_documented.asm"
    
    print(f"\n[Bank ${bank_num:02X}] {bank_info['desc']} - {bank_info['lines']} lines")
    
    if not input_file.exists():
        print(f"  [Bank ${bank_num:02X}] Source file not found: {input_file}")
        return 0
    
    # Create header
    header = f"""
; ==============================================================================
; Final Fantasy Mystic Quest - Bank ${bank_num:02X} - {bank_info['desc']}
; ==============================================================================
; Total Lines: {bank_info['lines']}
; Auto-generated with basic annotations - NEEDS MANUAL REVIEW
; ==============================================================================

arch 65816
lorom

org ${bank_num * 0x8000 + 0x8000:06X}

"""
    
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(header)
    
    # Process in chunks of 500 lines
    chunk_size = 500
    total_processed = 0
    
    for start in range(0, bank_info['lines'], chunk_size):
        end = min(start + chunk_size, bank_info['lines'])
        processed = convert_bank_section(bank_num, start, end, input_file, output_file)
        total_processed += processed
    
    percentage = (total_processed / bank_info['lines']) * 100 if bank_info['lines'] > 0 else 0
    print(f"  [Bank ${bank_num:02X}] ✅ Processed {total_processed}/{bank_info['lines']} lines ({percentage:.1f}%)")
    
    return total_processed

def main():
    base_path = Path(__file__).parent.parent
    
    print("=" * 80)
    print("FFMQ MASS DISASSEMBLY - PARALLEL BANK PROCESSING")
    print("=" * 80)
    print(f"Total code to process: {TOTAL_LINES} lines across {len(BANKS)} banks")
    print()
    
    # Process banks by priority
    for priority in [1, 2, 3, 4]:
        banks_to_process = [(num, info) for num, info in BANKS.items() if info['priority'] == priority]
        
        if not banks_to_process:
            continue
        
        print(f"\n{'='*80}")
        print(f"PRIORITY {priority} BANKS")
        print(f"{'='*80}")
        
        total_processed = 0
        
        # Process priority banks
        with ThreadPoolExecutor(max_workers=min(len(banks_to_process), 4)) as executor:
            futures = {
                executor.submit(process_bank, num, info, base_path): num 
                for num, info in banks_to_process
            }
            
            for future in as_completed(futures):
                bank_num = futures[future]
                try:
                    processed = future.result()
                    total_processed += processed
                except Exception as e:
                    print(f"[Bank ${bank_num:02X}] FAILED: {e}")
        
        print(f"\nPriority {priority} complete: {total_processed} lines processed")
    
    print(f"\n{'='*80}")
    print("DISASSEMBLY COMPLETE")
    print(f"{'='*80}")

if __name__ == '__main__':
    main()
