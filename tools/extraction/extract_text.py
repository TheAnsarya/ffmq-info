#!/usr/bin/env python3
"""
Final Fantasy Mystic Quest - Text/Dialog Extractor
Extracts all text strings, dialog, item names, monster names from ROM

Uses the character table (simple.tbl) to decode FFMQ's text encoding
Outputs to multiple formats for easy editing and re-insertion
"""

import sys
import os
from pathlib import Path
from typing import Dict, List, Tuple, Optional

class TextExtractor:
    """Extract text and dialog from FFMQ ROM"""
    
    # Known text table locations in ROM (LoROM addresses)
    TEXT_TABLES = {
        'item_names': {
            'address': 0x04f000,  # Approximate - needs verification
            'count': 256,
            'max_length': 12
        },
        'weapon_names': {
            'address': 0x04f800,
            'count': 64,
            'max_length': 12
        },
        'armor_names': {
            'address': 0x04fc00,
            'count': 64,
            'max_length': 12
        },
        'accessory_names': {
            'address': 0x04fd00,
            'count': 64,
            'max_length': 12
        },
        'spell_names': {
            'address': 0x04fe00,
            'count': 64,
            'max_length': 12
        },
        'monster_names': {
            'address': 0x050000,
            'count': 256,
            'max_length': 16
        },
        'location_names': {
            'address': 0x051000,
            'count': 128,
            'max_length': 20
        },
        # Dialog text - pointer-based system
        # Pointer table at $01d636 (PC address), points to strings in bank $03
        # See notes.txt: "$01d636 - start of a bank of text string pointers"
        'dialog': {
            'pointer_table': 0x00d636,  # PC address of 16-bit pointer table
            'count': 256,  # Number of dialog strings
            'bank': 0x03,  # Dialog stored in bank $03 (PC: $018000-$01ffff)
            'max_length': 512
        }
    }
    
    # Text control codes
    CTRL_END = 0x00      # End of string
    CTRL_NEWLINE = 0x01  # Newline
    CTRL_WAIT = 0x02     # Wait for button
    CTRL_CLEAR = 0x03    # Clear dialog box
    CTRL_NAME = 0x04     # Insert character name
    CTRL_ITEM = 0x05     # Insert item name
    
    def __init__(self, rom_path: str, tbl_path: Optional[str] = None):
        """Initialize with ROM and character table"""
        self.rom_path = Path(rom_path)
        self.rom_data = bytearray()
        self.char_table = {}
        self.reverse_table = {}
        
        # Default character table path
        if tbl_path is None:
            tbl_path = Path(__file__).parent.parent.parent / 'simple.tbl'
        self.tbl_path = Path(tbl_path)
        
    def load_rom(self) -> bool:
        """Load ROM file"""
        if not self.rom_path.exists():
            print(f"ERROR: ROM not found: {self.rom_path}")
            return False
            
        with open(self.rom_path, 'rb') as f:
            self.rom_data = bytearray(f.read())
            
        print(f"Loaded ROM: {self.rom_path.name} ({len(self.rom_data)} bytes)")
        return True
        
    def load_character_table(self) -> bool:
        """Load character encoding table (.tbl file)"""
        if not self.tbl_path.exists():
            print(f"WARNING: Character table not found: {self.tbl_path}")
            print("Using default ASCII mapping...")
            # Create basic ASCII mapping as fallback
            for i in range(32, 127):
                self.char_table[i] = chr(i)
                self.reverse_table[chr(i)] = i
            return True
            
        with open(self.tbl_path, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith('#'):
                    continue
                    
                # Parse: HH=C or HHHH=CC format
                if '=' in line:
                    parts = line.split('=', 1)
                    hex_val = int(parts[0], 16)
                    char = parts[1]
                    
                    # Handle escape sequences
                    if char.startswith('\\n'):
                        char = '\n'
                    elif char.startswith('\\r'):
                        char = '\r'
                    elif char.startswith('\\t'):
                        char = '\t'
                        
                    self.char_table[hex_val] = char
                    self.reverse_table[char] = hex_val
                    
        print(f"Loaded character table: {len(self.char_table)} characters")
        return True
        
    def decode_string(self, address: int, max_length: int = 256) -> Tuple[str, int]:
        """
        Decode a text string from ROM
        Returns: (decoded_string, bytes_read)
        """
        text = []
        offset = 0
        
        while offset < max_length:
            byte = self.rom_data[address + offset]
            offset += 1
            
            # Check for control codes
            if byte == self.CTRL_END:
                break
            elif byte == self.CTRL_NEWLINE:
                text.append('\n')
            elif byte == self.CTRL_WAIT:
                text.append('[WAIT]')
            elif byte == self.CTRL_CLEAR:
                text.append('[CLEAR]')
            elif byte == self.CTRL_NAME:
                text.append('[NAME]')
            elif byte == self.CTRL_ITEM:
                text.append('[ITEM]')
            elif byte in self.char_table:
                text.append(self.char_table[byte])
            else:
                # Unknown character - show hex
                text.append(f'<{byte:02X}>')
                
        return ''.join(text), offset
        
    def extract_text_table(self, name: str, config: Dict) -> List[Dict]:
        """Extract a table of text strings"""
        address = config['address']
        count = config['count']
        max_len = config['max_length']
        
        print(f"\nExtracting {name} from ${address:06X}...")
        
        strings = []
        current_addr = address
        
        for i in range(count):
            text, length = self.decode_string(current_addr, max_len)
            
            # Skip empty entries
            if text and text.strip():
                strings.append({
                    'id': i,
                    'text': text,
                    'address': f"${current_addr:06X}",
                    'length': length
                })
                
            current_addr += max_len  # Fixed-length entries
            
        print(f"  Extracted {len(strings)} strings")
        return strings
    
    def extract_pointer_based_text(self, name: str, config: Dict) -> List[Dict]:
        """Extract text using pointer table (for dialog)"""
        ptr_table = config['pointer_table']
        count = config['count']
        bank = config['bank']
        max_len = config['max_length']
        
        print(f"\nExtracting {name} from pointer table at ${ptr_table:06X}...")
        
        strings = []
        
        for i in range(count):
            # Read 16-bit pointer from table
            ptr_offset = ptr_table + (i * 2)
            if ptr_offset + 2 > len(self.rom_data):
                break
                
            # Little-endian 16-bit pointer
            ptr_low = self.rom_data[ptr_offset]
            ptr_high = self.rom_data[ptr_offset + 1]
            ptr_addr = (ptr_high << 8) | ptr_low
            
            # Convert SNES address to PC address
            # Bank $03 SNES address to PC: $03xxxx -> $01xxxx (PC)
            pc_addr = ((bank - 2) * 0x8000) + (ptr_addr & 0x7fff)
            
            # Bounds check
            if pc_addr >= len(self.rom_data):
                continue
                
            text, length = self.decode_string(pc_addr, max_len)
            
            # Skip empty entries
            if text and text.strip():
                strings.append({
                    'id': i,
                    'text': text,
                    'address': f"${pc_addr:06X}",
                    'pointer': f"${ptr_addr:04X}",
                    'length': length
                })
        
        print(f"  Extracted {len(strings)} dialog strings")
        return strings
        
    def extract_all(self) -> Dict[str, List[Dict]]:
        """Extract all text tables from ROM"""
        all_text = {}
        
        for table_name, config in self.TEXT_TABLES.items():
            # Check if this is pointer-based or direct address
            if 'pointer_table' in config:
                strings = self.extract_pointer_based_text(table_name, config)
            else:
                strings = self.extract_text_table(table_name, config)
            all_text[table_name] = strings
            
        return all_text
        
    def save_text_files(self, output_dir: str, text_data: Dict):
        """Save extracted text to individual files"""
        output_path = Path(output_dir)
        output_path.mkdir(parents=True, exist_ok=True)
        
        for table_name, strings in text_data.items():
            file_path = output_path / f"{table_name}.txt"
            
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(f"# {table_name.upper()}\n")
                f.write(f"# Extracted from FFMQ ROM\n")
                f.write(f"# Format: ID | Text\n")
                f.write("#" + "=" * 70 + "\n\n")
                
                for entry in strings:
                    # Format: ID | Text | (Address)
                    f.write(f"{entry['id']:04d} | {entry['text']} | {entry['address']}\n")
                    
            print(f"Saved: {file_path}")
            
    def save_asm_format(self, output_dir: str, text_data: Dict):
        """Save text in assembly source format for rebuilding"""
        output_path = Path(output_dir)
        output_path.mkdir(parents=True, exist_ok=True)
        
        for table_name, strings in text_data.items():
            asm_file = output_path / f"{table_name}.asm"
            
            with open(asm_file, 'w', encoding='utf-8') as f:
                f.write(f";==============================================================================\n")
                f.write(f"; {table_name.upper()} - Text Data\n")
                f.write(f";==============================================================================\n\n")
                
                if strings:
                    config = self.TEXT_TABLES[table_name]
                    
                    # Handle pointer-based vs direct address tables
                    if 'pointer_table' in config:
                        f.write(f"; Pointer table at ${config['pointer_table']:06X}\n")
                        f.write(f"; Strings in bank ${config['bank']:02X}\n\n")
                    else:
                        f.write(f"org ${config['address']:06X}\n\n")
                    
                    for entry in strings:
                        f.write(f"; {entry['id']:04d}: {entry['text'][:40]}\n")
                        f.write(f"{table_name}_{entry['id']:04d}:\n")
                        
                        # Convert text back to byte values
                        text_bytes = self.encode_string(entry['text'])
                        f.write(f"  db ")
                        
                        # Write bytes in groups of 16
                        for i, byte in enumerate(text_bytes):
                            if i > 0 and i % 16 == 0:
                                f.write(f"\n  db ")
                            f.write(f"${byte:02X}")
                            if i < len(text_bytes) - 1:
                                f.write(",")
                        f.write("\n\n")
                        
            print(f"Saved ASM: {asm_file}")
            
    def encode_string(self, text: str) -> List[int]:
        """Encode text string back to ROM bytes"""
        bytes_out = []
        
        i = 0
        while i < len(text):
            # Check for control codes
            if text[i:i+6] == '[WAIT]':
                bytes_out.append(self.CTRL_WAIT)
                i += 6
            elif text[i:i+7] == '[CLEAR]':
                bytes_out.append(self.CTRL_CLEAR)
                i += 7
            elif text[i:i+6] == '[NAME]':
                bytes_out.append(self.CTRL_NAME)
                i += 6
            elif text[i:i+6] == '[ITEM]':
                bytes_out.append(self.CTRL_ITEM)
                i += 6
            elif text[i] == '\n':
                bytes_out.append(self.CTRL_NEWLINE)
                i += 1
            elif text[i] in self.reverse_table:
                bytes_out.append(self.reverse_table[text[i]])
                i += 1
            else:
                # Unknown character - skip
                i += 1
                
        # Add terminator
        bytes_out.append(self.CTRL_END)
        return bytes_out


def main():
    """Main entry point"""
    if len(sys.argv) < 3:
        print("Usage: extract_text.py <rom_file> <output_dir> [--tbl character_table.tbl]")
        print("\nExtracts all text and dialog from FFMQ ROM")
        print("\nOutputs:")
        print("  - Text files (.txt) - Human-readable format")
        print("  - Assembly files (.asm) - Re-assemblable source")
        sys.exit(1)
        
    rom_file = sys.argv[1]
    output_dir = sys.argv[2]
    
    # Parse options
    tbl_file = None
    for i, arg in enumerate(sys.argv):
        if arg == '--tbl' and i + 1 < len(sys.argv):
            tbl_file = sys.argv[i + 1]
            
    print("=" * 70)
    print("Final Fantasy Mystic Quest - Text Extractor")
    print("=" * 70)
    print()
    
    # Extract text
    extractor = TextExtractor(rom_file, tbl_file)
    
    if not extractor.load_rom():
        sys.exit(1)
        
    if not extractor.load_character_table():
        sys.exit(1)
        
    print("\nExtracting all text tables...")
    text_data = extractor.extract_all()
    
    total_strings = sum(len(strings) for strings in text_data.values())
    print(f"\nTotal strings extracted: {total_strings}")
    
    print("\nSaving text files...")
    extractor.save_text_files(output_dir, text_data)
    
    print("\nSaving assembly source...")
    extractor.save_asm_format(output_dir, text_data)
    
    print()
    print("=" * 70)
    print("Text extraction complete!")
    print("=" * 70)


if __name__ == '__main__':
    main()
