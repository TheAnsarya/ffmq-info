#!/usr/bin/env python3
"""
FFMQ Asset Extraction Progress Tracker
Tracks what has been extracted and what still needs work
"""

import json
from pathlib import Path
from typing import Dict, List

class ExtractionTracker:
    """Track extraction progress"""
    
    ASSETS = {
        'code': {
            'description': 'Game code (65816 assembly)',
            'status': 'complete',
            'source': 'Diztinguish disassembly',
            'location': 'src/asm/banks/',
            'files': 18,  # bank_00 through bank_0F + labels + main
            'coverage': 100.0
        },
        'graphics': {
            'description': 'Sprites, tiles, backgrounds',
            'status': 'needs_pillow',
            'source': 'extract_graphics_v2.py',
            'location': 'assets/graphics/',
            'files': 0,  # Need to install Pillow first
            'coverage': 0.0
        },
        'text_tables': {
            'description': 'Item/monster names, etc',
            'status': 'complete',
            'source': 'extract_text.py',
            'location': 'assets/text/',
            'files': 7,  # item, weapon, armor, accessory, spell, monster, location names
            'coverage': 85.0  # Missing dialog
        },
        'enemy_data': {
            'description': 'Enemy stats and properties',
            'status': 'complete',
            'source': 'extract_enemies.py',
            'location': 'assets/data/',
            'files': 3,  # JSON, CSV, ASM
            'coverage': 100.0
        },
        'item_data': {
            'description': 'Item/equipment stats',
            'status': 'not_started',
            'source': 'extract_items.py (TODO)',
            'location': 'assets/data/',
            'files': 0,
            'coverage': 0.0
        },
        'map_data': {
            'description': 'Level maps and layouts',
            'status': 'not_started',
            'source': 'extract_maps.py (TODO)',
            'location': 'assets/maps/',
            'files': 0,
            'coverage': 0.0
        },
        'palettes': {
            'description': 'Color palettes',
            'status': 'not_started',
            'source': 'extract_palettes.py (TODO)',
            'location': 'assets/palettes/',
            'files': 0,
            'coverage': 0.0
        },
        'audio': {
            'description': 'Music and sound effects',
            'status': 'not_started',
            'source': 'extract_audio.py (TODO)',
            'location': 'assets/audio/',
            'files': 0,
            'coverage': 0.0
        },
        'dialog': {
            'description': 'Game dialog text',
            'status': 'not_started',
            'source': 'extract_text.py (needs address research)',
            'location': 'assets/text/',
            'files': 0,
            'coverage': 0.0
        }
    }
    
    def __init__(self):
        self.assets = self.ASSETS.copy()
        self.update_from_filesystem()
        
    def update_from_filesystem(self):
        """Update status based on actual files"""
        # Check text files
        text_dir = Path('assets/text')
        if text_dir.exists():
            text_files = list(text_dir.glob('*.txt'))
            if text_files:
                self.assets['text_tables']['files'] = len(text_files)
                # Check if dialog exists
                if (text_dir / 'dialog.txt').exists():
                    self.assets['dialog']['status'] = 'complete'
                    self.assets['dialog']['files'] = 1
                    self.assets['dialog']['coverage'] = 100.0
                    # Update text_tables to 100% if dialog is found
                    self.assets['text_tables']['coverage'] = 100.0
                
        # Check enemy data
        enemy_json = Path('assets/data/enemies.json')
        if enemy_json.exists():
            with open(enemy_json) as f:
                data = json.load(f)
                enemy_count = len(data.get('enemies', []))
                if enemy_count > 0:
                    self.assets['enemy_data']['files'] = 3  # JSON, CSV, ASM
        
        # Check item data
        item_json = Path('assets/data/items.json')
        if item_json.exists():
            self.assets['item_data']['status'] = 'complete'
            self.assets['item_data']['files'] = 7  # JSON + 6 CSVs + ASM
            self.assets['item_data']['coverage'] = 100.0
                    
        # Check graphics
        graphics_dir = Path('assets/graphics')
        if graphics_dir.exists():
            png_files = list(graphics_dir.glob('*.png'))
            if png_files:
                self.assets['graphics']['status'] = 'complete'
                self.assets['graphics']['files'] = len(png_files)
                self.assets['graphics']['coverage'] = 100.0
                    
    def calculate_overall_progress(self) -> float:
        """Calculate overall extraction progress"""
        total_coverage = sum(asset['coverage'] for asset in self.assets.values())
        return total_coverage / len(self.assets)
        
    def get_status_emoji(self, status: str) -> str:
        """Get emoji for status"""
        return {
            'complete': '✅',
            'needs_pillow': '⚠️',
            'not_started': '❌'
        }.get(status, '🔧')
        
    def print_report(self):
        """Print extraction progress report"""
        print("=" * 80)
        print("FFMQ Asset Extraction Progress Report")
        print("=" * 80)
        print()
        
        overall = self.calculate_overall_progress()
        print(f"Overall Progress: {overall:.1f}%")
        print()
        
        print("Asset Extraction Status:")
        print("-" * 80)
        print(f"{'Asset':<15} {'Status':<8} {'Coverage':<10} {'Files':<6} {'Location':<25}")
        print("-" * 80)
        
        for name, asset in sorted(self.assets.items()):
            emoji = self.get_status_emoji(asset['status'])
            print(f"{name:<15} {emoji} {asset['status']:<6} "
                  f"{asset['coverage']:>6.1f}% "
                  f"{asset['files']:>5} "
                  f"{asset['location']:<25}")
                  
        print()
        print("Next Steps:")
        print("-" * 80)
        
        # Find assets that need work
        needs_work = [(name, asset) for name, asset in self.assets.items() 
                      if asset['coverage'] < 100.0]
        needs_work.sort(key=lambda x: -x[1]['coverage'])  # Start with highest coverage
        
        for i, (name, asset) in enumerate(needs_work[:5], 1):
            if asset['status'] == 'needs_pillow':
                print(f"{i}. {name}: Install Pillow (pip install Pillow)")
            elif asset['status'] == 'not_started':
                print(f"{i}. {name}: Create {asset['source']}")
            else:
                print(f"{i}. {name}: Complete remaining {100-asset['coverage']:.1f}%")
                
        print()
        print("=" * 80)
        
    def save_json(self, output_path: str):
        """Save progress as JSON"""
        data = {
            'overall_progress': self.calculate_overall_progress(),
            'assets': self.assets
        }
        
        with open(output_path, 'w') as f:
            json.dump(data, f, indent=2)
            
        print(f"Progress data saved: {output_path}")


def main():
    tracker = ExtractionTracker()
    tracker.print_report()
    tracker.save_json('reports/extraction_progress.json')


if __name__ == '__main__':
    main()
