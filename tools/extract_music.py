#!/usr/bin/env python3
"""
Final Fantasy Mystic Quest - Music Extractor
Extracts music and sound data from FFMQ ROM
"""

import os
import sys
import struct
from typing import BinaryIO, List, Dict, Optional

class FFMQMusicExtractor:
    """Extract music from Final Fantasy Mystic Quest ROM"""
    
    def __init__(self, rom_path: str, output_dir: str):
        self.rom_path = rom_path
        self.output_dir = output_dir
        self.rom_data = None
        
        # Music/sound locations in ROM (estimated)
        self.music_locations = {
            'spc_driver': (0xc8000, 0x2000),       # SPC-700 driver code
            'sample_table': (0xca000, 0x1000),     # Sample pointer table
            'instrument_data': (0xcb000, 0x2000),  # Instrument definitions
            'sequence_data': (0xcd000, 0x8000),    # Music sequences
            'sample_data': (0xd5000, 0x10000),     # Audio samples
        }
        
        # Known music track info (from game analysis)
        self.track_info = {
            0x00: "Title Theme",
            0x01: "Overworld",
            0x02: "Town Theme",
            0x03: "Dungeon Theme",
            0x04: "Battle Theme",
            0x05: "Boss Battle",
            0x06: "Victory Fanfare",
            0x07: "Game Over",
            0x08: "Crystal Theme",
            0x09: "Final Battle",
            0x0a: "Ending Theme",
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
        if snes_addr >= 0x800000:
            pc_addr = (snes_addr - 0x800000)
            if len(self.rom_data) % 1024 == 512:  # Header present
                pc_addr += 512
            return pc_addr
        else:
            return snes_addr
    
    def extract_raw_audio_data(self, name: str, snes_addr: int, size: int) -> bool:
        """Extract raw audio data from ROM"""
        pc_addr = self.snes_to_pc_address(snes_addr)
        
        if pc_addr + size > len(self.rom_data):
            print(f"Error: Address out of range for {name}")
            return False
        
        os.makedirs(self.output_dir, exist_ok=True)
        
        data = self.rom_data[pc_addr:pc_addr + size]
        output_path = os.path.join(self.output_dir, f"{name}_raw.bin")
        
        with open(output_path, 'wb') as f:
            f.write(data)
        
        print(f"Extracted {name}: {size} bytes -> {output_path}")
        return True
    
    def analyze_spc_driver(self) -> bool:
        """Analyze the SPC-700 audio driver"""
        snes_addr, size = self.music_locations['spc_driver']
        pc_addr = self.snes_to_pc_address(snes_addr)
        
        if pc_addr + size > len(self.rom_data):
            print("Error: SPC driver out of range")
            return False
        
        data = self.rom_data[pc_addr:pc_addr + size]
        
        output_path = os.path.join(self.output_dir, "spc_driver_analysis.txt")
        with open(output_path, 'w') as f:
            f.write("Final Fantasy Mystic Quest - SPC Driver Analysis\n")
            f.write("================================================\n\n")
            f.write(f"Driver Location: ${snes_addr:06X} (PC: ${pc_addr:06X})\n")
            f.write(f"Driver Size: {size} bytes\n\n")
            
            # Look for common SPC-700 patterns
            f.write("SPC-700 Code Patterns:\n")
            
            # Check for common opcodes at the start
            if len(data) >= 16:
                f.write("First 16 bytes (hex): ")
                f.write(" ".join(f"{b:02X}" for b in data[:16]))
                f.write("\n")
                
                f.write("Potential opcodes:\n")
                for i, byte in enumerate(data[:16]):
                    opcode_desc = self.get_spc_opcode_desc(byte)
                    if opcode_desc:
                        f.write(f"  ${i:04X}: ${byte:02X} - {opcode_desc}\n")
            
            # Look for jump tables or data structures
            f.write("\nLooking for data structures...\n")
            self.find_spc_data_structures(data, f)
        
        print(f"SPC driver analysis saved -> {output_path}")
        return True
    
    def get_spc_opcode_desc(self, opcode: int) -> Optional[str]:
        """Get description for SPC-700 opcode"""
        spc_opcodes = {
            0x00: "NOP",
            0x01: "TCALL 0",
            0x02: "SET1 dp.0",
            0x03: "BBS dp.0,rel",
            0x04: "OR A,dp",
            0x05: "OR A,abs",
            0x06: "OR A,(X)",
            0x07: "OR A,[dp+X]",
            0x08: "OR A,#imm",
            0x09: "OR dp,dp",
            0x0a: "OR1 C,mem.bit",
            0x0b: "ASL dp",
            0x0c: "ASL abs",
            0x0d: "PUSH PSW",
            0x0e: "TSET1 abs",
            0x0f: "BRK",
            0x20: "CLRP",
            0x40: "SETP",
            0x60: "CLRC",
            0x80: "SETC",
            0xcd: "MOV X,#imm",
            0xe8: "MOV A,#imm",
            0xf0: "BEQ rel",
            0xfc: "INC Y",
            0xfd: "MOV Y,A",
            0xfe: "DBNZ Y,rel",
            0xff: "STOP",
        }
        return spc_opcodes.get(opcode)
    
    def find_spc_data_structures(self, data: bytes, output_file) -> None:
        """Find potential data structures in SPC driver"""
        # Look for repeating patterns that might be tables
        pattern_counts = {}
        
        # Check for 16-bit pointer tables
        for i in range(0, len(data) - 1, 2):
            if i + 1 < len(data):
                word = struct.unpack('<H', data[i:i+2])[0]
                if 0x0200 <= word <= 0xffff:  # Valid SPC-700 address range
                    pattern_counts[f"ptr_{word:04X}"] = pattern_counts.get(f"ptr_{word:04X}", 0) + 1
        
        output_file.write("Potential pointer tables:\n")
        for pattern, count in sorted(pattern_counts.items()):
            if count > 1:
                output_file.write(f"  {pattern}: appears {count} times\n")
    
    def extract_sequence_data(self) -> bool:
        """Extract music sequence data"""
        snes_addr, size = self.music_locations['sequence_data']
        pc_addr = self.snes_to_pc_address(snes_addr)
        
        if pc_addr + size > len(self.rom_data):
            print("Error: Sequence data out of range")
            return False
        
        data = self.rom_data[pc_addr:pc_addr + size]
        
        output_path = os.path.join(self.output_dir, "music_sequences.txt")
        with open(output_path, 'w') as f:
            f.write("Final Fantasy Mystic Quest - Music Sequences\n")
            f.write("===========================================\n\n")
            f.write(f"Sequence Data Location: ${snes_addr:06X}\n")
            f.write(f"Size: {size} bytes\n\n")
            
            # Try to find sequence boundaries
            f.write("Analyzing sequence patterns...\n\n")
            
            # Look for common sequence start patterns
            sequence_starts = []
            for i in range(len(data) - 4):
                # Look for potential sequence headers
                if data[i] in [0xf0, 0xf1, 0xf2, 0xf3, 0xf4, 0xf5]:  # Common sequence commands
                    sequence_starts.append(i)
            
            f.write(f"Found {len(sequence_starts)} potential sequence starts\n\n")
            
            # Analyze each potential sequence
            for i, start in enumerate(sequence_starts[:20]):  # Limit output
                f.write(f"Sequence {i} at offset ${start:04X}:\n")
                end = min(start + 64, len(data))
                hex_data = " ".join(f"{b:02X}" for b in data[start:end])
                f.write(f"  Data: {hex_data}\n")
                
                # Try to identify sequence commands
                self.analyze_sequence_commands(data[start:end], f)
                f.write("\n")
        
        print(f"Sequence analysis saved -> {output_path}")
        return True
    
    def analyze_sequence_commands(self, data: bytes, output_file) -> None:
        """Analyze music sequence commands"""
        # Common music sequence commands in SNES games
        commands = {
            0xf0: "End of track",
            0xf1: "Jump",
            0xf2: "Call subroutine",
            0xf3: "Return",
            0xf4: "Set tempo",
            0xf5: "Set volume",
            0xf6: "Set instrument",
            0xf7: "Pan",
            0xf8: "Vibrato",
            0xf9: "Tremolo",
            0xfa: "Echo",
            0xfb: "Pitch bend",
            0xfc: "Note length",
            0xfd: "Transpose",
            0xfe: "Loop",
            0xff: "Special command",
        }
        
        output_file.write("  Commands found:\n")
        for i, byte in enumerate(data[:16]):
            if byte in commands:
                output_file.write(f"    ${i:02X}: ${byte:02X} - {commands[byte]}\n")
            elif 0x00 <= byte <= 0x7f:  # Potential note data
                note = byte & 0x7f
                output_file.write(f"    ${i:02X}: ${byte:02X} - Note {note}\n")
    
    def extract_sample_data(self) -> bool:
        """Extract audio sample data"""
        snes_addr, size = self.music_locations['sample_data']
        pc_addr = self.snes_to_pc_address(snes_addr)
        
        if pc_addr + size > len(self.rom_data):
            print("Error: Sample data out of range")
            return False
        
        data = self.rom_data[pc_addr:pc_addr + size]
        
        # Extract raw sample data
        output_path = os.path.join(self.output_dir, "audio_samples_raw.bin")
        with open(output_path, 'wb') as f:
            f.write(data)
        
        # Analyze sample structure
        analysis_path = os.path.join(self.output_dir, "sample_analysis.txt")
        with open(analysis_path, 'w') as f:
            f.write("Final Fantasy Mystic Quest - Audio Sample Analysis\n")
            f.write("==================================================\n\n")
            f.write(f"Sample Data Location: ${snes_addr:06X}\n")
            f.write(f"Size: {size} bytes\n\n")
            
            # Look for BRR-encoded samples (SNES audio format)
            f.write("BRR Sample Analysis:\n")
            self.analyze_brr_samples(data, f)
        
        print(f"Sample data extracted -> {output_path}")
        print(f"Sample analysis saved -> {analysis_path}")
        return True
    
    def analyze_brr_samples(self, data: bytes, output_file) -> None:
        """Analyze BRR (Bit Rate Reduction) audio samples"""
        output_file.write("Scanning for BRR sample blocks...\n\n")
        
        brr_blocks = []
        i = 0
        while i < len(data) - 9:
            # BRR blocks are 9 bytes each
            # First byte contains flags and filter info
            header = data[i]
            
            # Check if this looks like a BRR header
            range_val = (header >> 4) & 0x0f
            filter_val = (header >> 2) & 0x03
            loop_flag = (header >> 1) & 0x01
            end_flag = header & 0x01
            
            if range_val <= 12:  # Valid range values are 0-12
                brr_blocks.append({
                    'offset': i,
                    'header': header,
                    'range': range_val,
                    'filter': filter_val,
                    'loop': bool(loop_flag),
                    'end': bool(end_flag),
                })
                
                if end_flag:  # End of sample
                    i += 9
                    continue
            
            i += 9
        
        output_file.write(f"Found {len(brr_blocks)} potential BRR blocks\n\n")
        
        # Group blocks into samples
        current_sample = []
        sample_count = 0
        
        for block in brr_blocks[:100]:  # Limit output
            current_sample.append(block)
            
            if block['end']:
                output_file.write(f"Sample {sample_count}:\n")
                output_file.write(f"  Blocks: {len(current_sample)}\n")
                output_file.write(f"  Start offset: ${current_sample[0]['offset']:06X}\n")
                output_file.write(f"  End offset: ${block['offset']:06X}\n")
                output_file.write(f"  Size: {(block['offset'] - current_sample[0]['offset'] + 9)} bytes\n")
                
                if any(b['loop'] for b in current_sample):
                    output_file.write("  Contains loop point\n")
                
                output_file.write("\n")
                
                current_sample = []
                sample_count += 1
    
    def create_music_info_file(self) -> bool:
        """Create a music information reference file"""
        output_path = os.path.join(self.output_dir, "music_info.txt")
        
        with open(output_path, 'w') as f:
            f.write("Final Fantasy Mystic Quest - Music Information\n")
            f.write("=============================================\n\n")
            
            f.write("Known Music Tracks:\n")
            for track_id, name in self.track_info.items():
                f.write(f"  ${track_id:02X}: {name}\n")
            
            f.write("\nMusic System Overview:\n")
            f.write("- Uses SPC-700 sound processor\n")
            f.write("- BRR-compressed audio samples\n")
            f.write("- Sequence-based music system\n")
            f.write("- 8-channel polyphony\n")
            f.write("- Digital effects (reverb, echo)\n")
            
            f.write("\nFile Locations:\n")
            for name, (addr, size) in self.music_locations.items():
                f.write(f"  {name}: ${addr:06X} (${size:04X} bytes)\n")
        
        print(f"Music info saved -> {output_path}")
        return True
    
    def extract_all_music(self) -> bool:
        """Extract all music and sound data"""
        if not self.load_rom():
            return False
        
        print("Extracting music from Final Fantasy Mystic Quest...")
        
        # Create output directory
        os.makedirs(self.output_dir, exist_ok=True)
        
        # Extract raw data
        for name, (snes_addr, size) in self.music_locations.items():
            self.extract_raw_audio_data(name, snes_addr, size)
        
        # Detailed analysis
        self.analyze_spc_driver()
        self.extract_sequence_data()
        self.extract_sample_data()
        self.create_music_info_file()
        
        print(f"\nMusic extraction complete. Files saved to: {self.output_dir}")
        return True

def main():
    if len(sys.argv) != 3:
        print("Usage: python extract_music.py <rom_file> <output_directory>")
        print("Example: python extract_music.py 'Final Fantasy - Mystic Quest (U) (V1.1).sfc' music/")
        sys.exit(1)
    
    rom_file = sys.argv[1]
    output_dir = sys.argv[2]
    
    extractor = FFMQMusicExtractor(rom_file, output_dir)
    success = extractor.extract_all_music()
    
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()