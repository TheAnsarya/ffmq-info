#!/usr/bin/env python3
"""
Final Fantasy Mystic Quest - Text Extractor
Extracts text data from FFMQ ROM for translation and analysis
"""

import os
import sys
import struct
from typing import BinaryIO, List, Dict, Optional

class FFMQTextExtractor:
    """Extract text from Final Fantasy Mystic Quest ROM"""
    
    def __init__(self, rom_path: str, output_dir: str):
        self.rom_path = rom_path
        self.output_dir = output_dir
        self.rom_data = None
        
        # Text character table (basic ASCII mapping)
        self.char_table = {
            0x00: ' ',   0x01: '!',   0x02: '"',   0x03: '#',   0x04: '$',   0x05: '%',   0x06: '&',   0x07: "'",
            0x08: '(',   0x09: ')',   0x0A: '*',   0x0B: '+',   0x0C: ',',   0x0D: '-',   0x0E: '.',   0x0F: '/',
            0x10: '0',   0x11: '1',   0x12: '2',   0x13: '3',   0x14: '4',   0x15: '5',   0x16: '6',   0x17: '7',
            0x18: '8',   0x19: '9',   0x1A: ':',   0x1B: ';',   0x1C: '<',   0x1D: '=',   0x1E: '>',   0x1F: '?',
            0x20: '@',   0x21: 'A',   0x22: 'B',   0x23: 'C',   0x24: 'D',   0x25: 'E',   0x26: 'F',   0x27: 'G',
            0x28: 'H',   0x29: 'I',   0x2A: 'J',   0x2B: 'K',   0x2C: 'L',   0x2D: 'M',   0x2E: 'N',   0x2F: 'O',
            0x30: 'P',   0x31: 'Q',   0x32: 'R',   0x33: 'S',   0x34: 'T',   0x35: 'U',   0x36: 'V',   0x37: 'W',
            0x38: 'X',   0x39: 'Y',   0x3A: 'Z',   0x3B: '[',   0x3C: '\\',  0x3D: ']',   0x3E: '^',   0x3F: '_',
            0x40: '`',   0x41: 'a',   0x42: 'b',   0x43: 'c',   0x44: 'd',   0x45: 'e',   0x46: 'f',   0x47: 'g',
            0x48: 'h',   0x49: 'i',   0x4A: 'j',   0x4B: 'k',   0x4C: 'l',   0x4D: 'm',   0x4E: 'n',   0x4F: 'o',
            0x50: 'p',   0x51: 'q',   0x52: 'r',   0x53: 's',   0x54: 't',   0x55: 'u',   0x56: 'v',   0x57: 'w',
            0x58: 'x',   0x59: 'y',   0x5A: 'z',   0x5B: '{',   0x5C: '|',   0x5D: '}',   0x5E: '~',   0x5F: ' ',
            # Special characters and control codes
            0xFE: '[NEWLINE]',
            0xFF: '[END]',
            0xFD: '[WAIT]',
            0xFC: '[CLEAR]',
        }
        
        # Text section locations in ROM (estimated)
        self.text_locations = {
            'main_dialogue': (0xB0000, 0x8000),     # Main story dialogue
            'item_names': (0xB8000, 0x1000),       # Item names
            'spell_names': (0xB9000, 0x800),       # Spell names
            'character_names': (0xB9800, 0x400),   # Character names
            'location_names': (0xBA000, 0x800),    # Location names
            'menu_text': (0xBB000, 0x1000),        # Menu text
            'battle_text': (0xBC000, 0x1000),      # Battle messages
        }
    
    def load_rom(self) -> bool:
        """Load ROM file into memory"""
        try:
            with open(self.rom_path, 'rb') as f:
                self.rom_data = f.read()
            print(f"Loaded ROM: {len(self.rom_data)} bytes")
            return True
        except FileNotFoundError:
            print(f"Error: ROM file not found: {self.rom_path}")
            return False
        except Exception as e:
            print(f"Error loading ROM: {e}")
            return False
    
    def snes_to_pc_address(self, snes_addr: int) -> int:
        """Convert SNES address to PC file address"""
        # LoROM mapping conversion
        if snes_addr >= 0x800000:
            pc_addr = (snes_addr - 0x800000)
            if len(self.rom_data) % 1024 == 512:  # Header present
                pc_addr += 512
            return pc_addr
        else:
            return snes_addr
    
    def decode_text_string(self, data: bytes, start_offset: int, max_length: int = 256) -> tuple[str, int]:
        """Decode a single text string from ROM data"""
        text = ""
        offset = start_offset
        
        while offset < len(data) and offset < start_offset + max_length:
            byte = data[offset]
            
            # End of string
            if byte == 0xFF or byte == 0x00:
                break
            
            # Convert byte to character
            if byte in self.char_table:
                text += self.char_table[byte]
            else:
                text += f"[{byte:02X}]"
            
            offset += 1
        
        return text, offset - start_offset + 1
    
    def extract_text_table(self, data: bytes, start_offset: int = 0) -> List[str]:
        """Extract all text strings from a data block"""
        strings = []
        offset = start_offset
        
        while offset < len(data):
            # Skip null bytes
            if data[offset] == 0x00:
                offset += 1
                continue
            
            # Try to decode a string
            text, length = self.decode_text_string(data, offset)
            
            # Only add non-empty strings
            if text.strip() and length > 1:
                strings.append(text)
                offset += length
            else:
                offset += 1
        
        return strings
    
    def find_text_pointers(self, data: bytes, text_section_start: int) -> List[int]:
        """Find pointer table that references text strings"""
        pointers = []
        
        # Look for 16-bit pointers in the first part of each bank
        for i in range(0, min(0x2000, len(data)), 2):
            if i + 1 < len(data):
                pointer = struct.unpack('<H', data[i:i+2])[0]
                
                # Check if this looks like a valid text pointer
                if 0x8000 <= pointer <= 0xFFFF:
                    # Convert to offset within the text section
                    text_offset = pointer - 0x8000
                    if 0 <= text_offset < len(data) - text_section_start:
                        pointers.append(text_offset + text_section_start)
        
        return sorted(list(set(pointers)))  # Remove duplicates and sort
    
    def extract_structured_text(self, name: str, snes_addr: int, size: int) -> bool:
        """Extract text with structure detection"""
        pc_addr = self.snes_to_pc_address(snes_addr)
        
        if pc_addr + size > len(self.rom_data):
            print(f"Error: Address out of range for {name}")
            return False
        
        data = self.rom_data[pc_addr:pc_addr + size]
        
        # Try to find pointer table
        pointers = self.find_text_pointers(data, 0)
        
        output_path = os.path.join(self.output_dir, f"{name}.txt")
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(f"Text Section: {name}\n")
            f.write(f"SNES Address: ${snes_addr:06X}\n")
            f.write(f"PC Address: ${pc_addr:06X}\n")
            f.write(f"Size: {size} bytes\n\n")
            
            if pointers:
                f.write(f"Found {len(pointers)} potential text pointers:\n\n")
                
                for i, ptr in enumerate(pointers):
                    if ptr < len(data):
                        text, length = self.decode_text_string(data, ptr)
                        if text.strip():
                            f.write(f"String {i:03d} [@${ptr:04X}]: {text}\n")
                f.write("\n")
            
            # Also extract as continuous text
            f.write("Continuous text extraction:\n\n")
            strings = self.extract_text_table(data)
            
            for i, text in enumerate(strings):
                if len(text.strip()) > 2:  # Filter out very short strings
                    f.write(f"{i:03d}: {text}\n")
        
        print(f"Extracted {name}: {len(strings) if not pointers else len(pointers)} strings -> {output_path}")
        return True
    
    def extract_item_names(self) -> bool:
        """Extract item names with special formatting"""
        name = "item_names"
        snes_addr, size = self.text_locations[name]
        pc_addr = self.snes_to_pc_address(snes_addr)
        
        if pc_addr + size > len(self.rom_data):
            print(f"Error: Address out of range for {name}")
            return False
        
        data = self.rom_data[pc_addr:pc_addr + size]
        
        # Item names are typically fixed-length or use specific terminators
        output_path = os.path.join(self.output_dir, f"{name}_formatted.txt")
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write("Final Fantasy Mystic Quest - Item Names\n")
            f.write("=======================================\n\n")
            
            # Try fixed-length extraction (common in RPGs)
            item_name_length = 12  # Estimated
            offset = 0
            item_id = 0
            
            while offset + item_name_length <= len(data):
                name_data = data[offset:offset + item_name_length]
                text, _ = self.decode_text_string(name_data, 0, item_name_length)
                
                # Clean up the text
                clean_text = text.replace('[00]', '').strip()
                
                if clean_text and len(clean_text) > 1:
                    f.write(f"Item {item_id:02X}: {clean_text}\n")
                    item_id += 1
                
                offset += item_name_length
        
        print(f"Extracted formatted item names -> {output_path}")
        return True
    
    def create_character_table_file(self) -> bool:
        """Create a character table file for reference"""
        output_path = os.path.join(self.output_dir, "character_table.tbl")
        
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write("# Final Fantasy Mystic Quest Character Table\n")
            f.write("# Format: HEX=CHARACTER\n\n")
            
            for byte_val, char in self.char_table.items():
                if len(char) == 1:  # Single characters only
                    f.write(f"{byte_val:02X}={char}\n")
                else:  # Special codes
                    f.write(f"{byte_val:02X}={char}\n")
        
        print(f"Character table saved -> {output_path}")
        return True
    
    def analyze_text_patterns(self) -> bool:
        """Analyze text patterns across the ROM"""
        output_path = os.path.join(self.output_dir, "text_analysis.txt")
        
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write("Final Fantasy Mystic Quest - Text Analysis\n")
            f.write("==========================================\n\n")
            
            # Analyze each text section
            for section_name, (snes_addr, size) in self.text_locations.items():
                pc_addr = self.snes_to_pc_address(snes_addr)
                
                if pc_addr + size > len(self.rom_data):
                    continue
                
                data = self.rom_data[pc_addr:pc_addr + size]
                
                # Count character frequencies
                char_count = {}
                for byte in data:
                    char_count[byte] = char_count.get(byte, 0) + 1
                
                f.write(f"Section: {section_name}\n")
                f.write(f"Address: ${snes_addr:06X} (PC: ${pc_addr:06X})\n")
                f.write(f"Size: {size} bytes\n")
                
                # Show most common bytes
                sorted_chars = sorted(char_count.items(), key=lambda x: x[1], reverse=True)
                f.write("Most common bytes:\n")
                for byte_val, count in sorted_chars[:10]:
                    char = self.char_table.get(byte_val, f'[{byte_val:02X}]')
                    f.write(f"  {byte_val:02X} ({char}): {count} times\n")
                
                f.write("\n")
        
        print(f"Text analysis saved -> {output_path}")
        return True
    
    def extract_all_text(self) -> bool:
        """Extract all text from the ROM"""
        if not self.load_rom():
            return False
        
        print("Extracting text from Final Fantasy Mystic Quest...")
        
        # Create output directory
        os.makedirs(self.output_dir, exist_ok=True)
        
        # Extract text from each section
        for name, (snes_addr, size) in self.text_locations.items():
            self.extract_structured_text(name, snes_addr, size)
        
        # Extract special formatted sections
        self.extract_item_names()
        
        # Create reference files
        self.create_character_table_file()
        self.analyze_text_patterns()
        
        print(f"\nText extraction complete. Files saved to: {self.output_dir}")
        return True

def main():
    if len(sys.argv) != 3:
        print("Usage: python extract_text.py <rom_file> <output_directory>")
        print("Example: python extract_text.py 'Final Fantasy - Mystic Quest (U) (V1.1).sfc' text/")
        sys.exit(1)
    
    rom_file = sys.argv[1]
    output_dir = sys.argv[2]
    
    extractor = FFMQTextExtractor(rom_file, output_dir)
    success = extractor.extract_all_text()
    
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()