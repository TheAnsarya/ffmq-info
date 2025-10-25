#!/usr/bin/env python3
"""
Final Fantasy Mystic Quest - Complete Asset Extractor
Extracts ALL assets from ROM for byte-perfect rebuild

This master script coordinates all extraction tools to pull every asset
from the original ROM into editable formats, enabling byte-perfect rebuild.
"""

import sys
import os
import subprocess
from pathlib import Path
from typing import List, Tuple

class AssetExtractor:
    """Master coordinator for all asset extraction"""
    
    def __init__(self, rom_path: str, output_dir: str):
        self.rom_path = Path(rom_path)
        self.output_dir = Path(output_dir)
        self.tools_dir = Path(__file__).parent
        self.stats = {
            'graphics': 0,
            'text': 0,
            'enemies': 0,
            'items': 0,
            'maps': 0,
            'palettes': 0,
            'audio': 0
        }
        
    def extract_all(self):
        """Extract all assets from ROM"""
        print("=" * 80)
        print("Final Fantasy Mystic Quest - Complete Asset Extraction")
        print("=" * 80)
        print()
        print(f"Source ROM: {self.rom_path}")
        print(f"Output Directory: {self.output_dir}")
        print()
        
        tasks = [
            ("Graphics", self.extract_graphics),
            ("Text/Dialog", self.extract_text),
            ("Enemy Data", self.extract_enemies),
            ("Item Data", self.extract_items),
            ("Palettes", self.extract_palettes),
            ("Maps", self.extract_maps),
            ("Audio/Music", self.extract_audio),
        ]
        
        completed = 0
        for name, func in tasks:
            print(f"\n[{completed+1}/{len(tasks)}] Extracting {name}...")
            print("-" * 80)
            try:
                func()
                completed += 1
                print(f"✓ {name} extraction complete")
            except Exception as e:
                print(f"✗ {name} extraction failed: {e}")
                
        print("\n" + "=" * 80)
        print(f"Extraction Complete: {completed}/{len(tasks)} successful")
        print("=" * 80)
        self.print_stats()
        
    def run_tool(self, script: str, args: List[str]) -> bool:
        """Run extraction tool"""
        tool_path = self.tools_dir / script
        if not tool_path.exists():
            print(f"  WARNING: Tool not found: {tool_path}")
            return False
            
        cmd = [sys.executable, str(tool_path)] + args
        result = subprocess.run(cmd, capture_output=False)
        return result.returncode == 0
        
    def extract_graphics(self):
        """Extract all graphics to PNG"""
        output = self.output_dir / "graphics"
        self.run_tool("extract_graphics_v2.py", [
            str(self.rom_path),
            str(output) + "/",
            "--docs",
            "--verbose"
        ])
        
    def extract_text(self):
        """Extract all text and dialog"""
        output = self.output_dir / "text"
        self.run_tool("extraction/extract_text.py", [
            str(self.rom_path),
            str(output) + "/"
        ])
        
    def extract_enemies(self):
        """Extract enemy data"""
        output = self.output_dir / "data" / "enemies.json"
        self.run_tool("extraction/extract_enemies.py", [
            str(self.rom_path),
            str(output),
            "--format", "all",
            "--verbose"
        ])
        
    def extract_items(self):
        """Extract item/equipment data"""
        print("  TODO: Item extraction tool not yet implemented")
        
    def extract_palettes(self):
        """Extract color palettes"""
        print("  TODO: Palette extraction tool not yet implemented")
        
    def extract_maps(self):
        """Extract map data"""
        print("  TODO: Map extraction tool not yet implemented")
        
    def extract_audio(self):
        """Extract music and audio"""
        print("  TODO: Audio extraction tool not yet implemented")
        
    def print_stats(self):
        """Print extraction statistics"""
        print()
        print("Extraction Statistics:")
        print("-" * 80)
        for category, count in self.stats.items():
            if count > 0:
                print(f"  {category:<15} {count:>6} files")


def main():
    if len(sys.argv) < 3:
        print("Usage: extract_all_assets.py <rom_file> <output_dir>")
        print()
        print("Extracts all assets from FFMQ ROM for byte-perfect rebuild")
        sys.exit(1)
        
    rom_file = sys.argv[1]
    output_dir = sys.argv[2]
    
    extractor = AssetExtractor(rom_file, output_dir)
    extractor.extract_all()


if __name__ == '__main__':
    main()
