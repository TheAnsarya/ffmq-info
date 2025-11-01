#!/usr/bin/env python3
"""
Final Fantasy Mystic Quest - Graphics Extractor
Extracts graphics data from FFMQ ROM for editing and analysis
"""

import os
import sys
import struct
from typing import BinaryIO, List, Tuple

class FFMQGraphicsExtractor:
    """Extract graphics from Final Fantasy Mystic Quest ROM"""
    
    def __init__(self, rom_path: str, output_dir: str):
        self.rom_path = rom_path
        self.output_dir = output_dir
        self.rom_data = None
        
        # Graphics locations in ROM (SNES addresses)
        self.graphics_locations = {
            'font': (0x80000, 0x2000),          # Font graphics
            'sprites': (0x85000, 0x8000),       # Character sprites  
            'tiles': (0x90000, 0x10000),        # Background tiles
            'portraits': (0xa0000, 0x8000),     # Character portraits
            'ui_elements': (0xa8000, 0x4000),   # UI graphics
            'enemies': (0xac000, 0x8000),       # Enemy sprites
            'effects': (0xb4000, 0x4000),       # Special effects
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
            # Remove header if present (check for 512-byte header)
            pc_addr = (snes_addr - 0x800000)
            if len(self.rom_data) % 1024 == 512:  # Header present
                pc_addr += 512
            return pc_addr
        else:
            return snes_addr
    
    def extract_raw_graphics(self, name: str, snes_addr: int, size: int) -> bool:
        """Extract raw graphics data from ROM"""
        pc_addr = self.snes_to_pc_address(snes_addr)
        
        if pc_addr + size > len(self.rom_data):
            print(f"Error: Address out of range for {name}")
            return False
        
        # Create output directory
        os.makedirs(self.output_dir, exist_ok=True)
        
        # Extract raw data
        data = self.rom_data[pc_addr:pc_addr + size]
        output_path = os.path.join(self.output_dir, f"{name}_raw.bin")
        
        with open(output_path, 'wb') as f:
            f.write(data)
        
        print(f"Extracted {name}: {size} bytes -> {output_path}")
        return True
    
    def decode_4bpp_tile(self, data: bytes, tile_offset: int) -> List[List[int]]:
        """Decode a single 4BPP SNES tile (8x8 pixels)"""
        tile = [[0 for _ in range(8)] for _ in range(8)]
        
        for y in range(8):
            # Each row is 2 bytes for planes 0&1, 2 bytes for planes 2&3
            plane01_offset = tile_offset + y * 2
            plane23_offset = tile_offset + y * 2 + 16
            
            if plane01_offset + 1 >= len(data) or plane23_offset + 1 >= len(data):
                continue
                
            plane0 = data[plane01_offset]
            plane1 = data[plane01_offset + 1]
            plane2 = data[plane23_offset] if plane23_offset < len(data) else 0
            plane3 = data[plane23_offset + 1] if plane23_offset + 1 < len(data) else 0
            
            for x in range(8):
                bit_mask = 1 << (7 - x)
                pixel = 0
                if plane0 & bit_mask: pixel |= 1
                if plane1 & bit_mask: pixel |= 2
                if plane2 & bit_mask: pixel |= 4
                if plane3 & bit_mask: pixel |= 8
                tile[y][x] = pixel
        
        return tile
    
    def decode_2bpp_tile(self, data: bytes, tile_offset: int) -> List[List[int]]:
        """Decode a single 2BPP SNES tile (8x8 pixels)"""
        tile = [[0 for _ in range(8)] for _ in range(8)]
        
        for y in range(8):
            if tile_offset + y * 2 + 1 >= len(data):
                continue
                
            plane0 = data[tile_offset + y * 2]
            plane1 = data[tile_offset + y * 2 + 1]
            
            for x in range(8):
                bit_mask = 1 << (7 - x)
                pixel = 0
                if plane0 & bit_mask: pixel |= 1
                if plane1 & bit_mask: pixel |= 2
                tile[y][x] = pixel
        
        return tile
    
    def extract_font_graphics(self) -> bool:
        """Extract and decode font graphics"""
        snes_addr, size = self.graphics_locations['font']
        pc_addr = self.snes_to_pc_address(snes_addr)
        
        if pc_addr + size > len(self.rom_data):
            print("Error: Font graphics out of range")
            return False
        
        data = self.rom_data[pc_addr:pc_addr + size]
        
        # Font is typically 2BPP, 8x8 tiles
        tiles_per_row = 16
        tile_count = size // 16  # 16 bytes per 2BPP tile
        
        # Create simple text representation
        output_path = os.path.join(self.output_dir, "font_analysis.txt")
        with open(output_path, 'w') as f:
            f.write("Font Graphics Analysis\n")
            f.write(f"Total tiles: {tile_count}\n")
            f.write(f"Data size: {size} bytes\n\n")
            
            for tile_idx in range(min(tile_count, 256)):  # Limit output
                tile_offset = tile_idx * 16
                tile = self.decode_2bpp_tile(data, tile_offset)
                
                f.write(f"Tile {tile_idx:02X}:\n")
                for row in tile:
                    line = ""
                    for pixel in row:
                        line += "██" if pixel else "  "
                    f.write(f"  {line}\n")
                f.write("\n")
        
        print(f"Font analysis saved to: {output_path}")
        return True
    
    def extract_palette_data(self) -> bool:
        """Extract palette data from ROM"""
        # Palette locations (estimated based on typical SNES layout)
        palette_locations = [
            (0x8d800, 0x200, "main_palette"),
            (0x8da00, 0x200, "battle_palette"),
            (0x8dc00, 0x200, "menu_palette"),
        ]
        
        os.makedirs(self.output_dir, exist_ok=True)
        
        for snes_addr, size, name in palette_locations:
            pc_addr = self.snes_to_pc_address(snes_addr)
            
            if pc_addr + size > len(self.rom_data):
                print(f"Skipping {name}: out of range")
                continue
            
            data = self.rom_data[pc_addr:pc_addr + size]
            
            # Save raw palette data
            raw_path = os.path.join(self.output_dir, f"{name}_raw.bin")
            with open(raw_path, 'wb') as f:
                f.write(data)
            
            # Convert to human-readable format
            txt_path = os.path.join(self.output_dir, f"{name}.txt")
            with open(txt_path, 'w') as f:
                f.write(f"Palette: {name}\n")
                f.write(f"Size: {size} bytes ({size // 2} colors)\n\n")
                
                for i in range(0, size, 2):
                    if i + 1 < len(data):
                        color_word = struct.unpack('<H', data[i:i+2])[0]
                        # SNES RGB555 format: 0BBBBBGGGGGRRRRR
                        r = (color_word & 0x1f) << 3
                        g = ((color_word >> 5) & 0x1f) << 3
                        b = ((color_word >> 10) & 0x1f) << 3
                        f.write(f"Color {i//2:02X}: RGB({r:02X},{g:02X},{b:02X}) SNES:${color_word:04X}\n")
            
            print(f"Palette extracted: {name}")
        
        return True
    
    def extract_all_graphics(self) -> bool:
        """Extract all graphics from the ROM"""
        if not self.load_rom():
            return False
        
        print("Extracting graphics from Final Fantasy Mystic Quest...")
        
        # Extract raw graphics data
        for name, (snes_addr, size) in self.graphics_locations.items():
            self.extract_raw_graphics(name, snes_addr, size)
        
        # Extract specific decoded graphics
        self.extract_font_graphics()
        self.extract_palette_data()
        
        print(f"\nGraphics extraction complete. Files saved to: {self.output_dir}")
        return True

def main():
    if len(sys.argv) != 3:
        print("Usage: python extract_graphics.py <rom_file> <output_directory>")
        print("Example: python extract_graphics.py 'Final Fantasy - Mystic Quest (U) (V1.1).sfc' graphics/")
        sys.exit(1)
    
    rom_file = sys.argv[1]
    output_dir = sys.argv[2]
    
    extractor = FFMQGraphicsExtractor(rom_file, output_dir)
    success = extractor.extract_all_graphics()
    
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()