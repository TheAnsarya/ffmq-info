#!/usr/bin/env python3
"""
Final Fantasy Mystic Quest - Enemy Data Extractor
Extracts enemy stats, AI, graphics references, and attack patterns from ROM

ROM Data Locations (based on reverse engineering):
- Enemy Stats: Bank $06 starting around $068000
- Enemy AI Scripts: Bank $02  
- Enemy Graphics References: Bank $07
- Enemy Names: Stored in text tables

Output formats:
- JSON: Complete structured data
- CSV: Spreadsheet-compatible for easy editing
- ASM: Re-assemblable data tables
"""

import sys
import os
import json
import csv
import struct
from pathlib import Path
from typing import Dict, List, Any, Optional

# Enemy data structure based on reverse engineering
# Each enemy entry is typically 32-64 bytes with:
# - Stats (HP, Attack, Defense, Magic Defense, etc.)
# - Resistances (elemental, status effects)
# - Attack patterns
# - Graphics/sprite reference
# - AI script pointer
# - Drop items/exp/gold

class EnemyExtractor:
    """Extract and parse enemy data from FFMQ ROM"""
    
    # ROM addresses (LoROM format: bank:offset)
    ENEMY_STATS_BASE = 0x030000  # Bank $06 in LoROM = $030000 in file
    ENEMY_COUNT = 256             # Approximate number of enemy slots
    ENEMY_ENTRY_SIZE = 40         # Bytes per enemy entry (to be verified)
    
    # Enemy stat offsets within each entry
    OFFSET_HP_LOW = 0x00
    OFFSET_HP_HIGH = 0x01
    OFFSET_ATTACK = 0x02
    OFFSET_DEFENSE = 0x03
    OFFSET_MAGIC = 0x04
    OFFSET_MAGIC_DEF = 0x05
    OFFSET_SPEED = 0x06
    OFFSET_ACCURACY = 0x07
    OFFSET_EVADE = 0x08
    OFFSET_ELEM_RESIST = 0x09  # Bitfield
    OFFSET_STATUS_RESIST = 0x0a  # Bitfield
    OFFSET_EXP_LOW = 0x0c
    OFFSET_EXP_HIGH = 0x0d
    OFFSET_GOLD_LOW = 0x0e
    OFFSET_GOLD_HIGH = 0x0f
    OFFSET_DROP_ITEM = 0x10
    OFFSET_DROP_RATE = 0x11
    OFFSET_GRAPHICS_ID = 0x12
    OFFSET_PALETTE = 0x13
    OFFSET_AI_SCRIPT_LOW = 0x14
    OFFSET_AI_SCRIPT_HIGH = 0x15
    
    # Element bit flags
    ELEM_FIRE = 0x01
    ELEM_WATER = 0x02
    ELEM_WIND = 0x04
    ELEM_EARTH = 0x08
    ELEM_HOLY = 0x10
    ELEM_DARK = 0x20
    
    # Status effect bit flags
    STATUS_POISON = 0x01
    STATUS_SLEEP = 0x02
    STATUS_PARALYZE = 0x04
    STATUS_CONFUSE = 0x08
    STATUS_BLIND = 0x10
    STATUS_SILENCE = 0x20
    STATUS_CURSE = 0x40
    STATUS_STONE = 0x80
    
    def __init__(self, rom_path: str):
        """Initialize with ROM file path"""
        self.rom_path = Path(rom_path)
        self.rom_data = bytearray()
        self.enemies = []
        
    def load_rom(self) -> bool:
        """Load ROM file into memory"""
        if not self.rom_path.exists():
            print(f"ERROR: ROM file not found: {self.rom_path}")
            return False
            
        with open(self.rom_path, 'rb') as f:
            self.rom_data = bytearray(f.read())
            
        print(f"Loaded ROM: {self.rom_path.name} ({len(self.rom_data)} bytes)")
        return True
        
    def read_byte(self, address: int) -> int:
        """Read single byte from ROM"""
        if address >= len(self.rom_data):
            return 0
        return self.rom_data[address]
        
    def read_word(self, address: int) -> int:
        """Read 16-bit word (little-endian) from ROM"""
        if address + 1 >= len(self.rom_data):
            return 0
        return self.rom_data[address] | (self.rom_data[address + 1] << 8)
        
    def parse_element_resistance(self, flags: int) -> Dict[str, str]:
        """Parse element resistance bitfield"""
        elements = {}
        if flags & self.ELEM_FIRE:
            elements['fire'] = 'resist'
        if flags & self.ELEM_WATER:
            elements['water'] = 'resist'
        if flags & self.ELEM_WIND:
            elements['wind'] = 'resist'
        if flags & self.ELEM_EARTH:
            elements['earth'] = 'resist'
        if flags & self.ELEM_HOLY:
            elements['holy'] = 'resist'
        if flags & self.ELEM_DARK:
            elements['dark'] = 'resist'
        return elements
        
    def parse_status_resistance(self, flags: int) -> List[str]:
        """Parse status effect resistance bitfield"""
        resistances = []
        if flags & self.STATUS_POISON:
            resistances.append('poison')
        if flags & self.STATUS_SLEEP:
            resistances.append('sleep')
        if flags & self.STATUS_PARALYZE:
            resistances.append('paralyze')
        if flags & self.STATUS_CONFUSE:
            resistances.append('confuse')
        if flags & self.STATUS_BLIND:
            resistances.append('blind')
        if flags & self.STATUS_SILENCE:
            resistances.append('silence')
        if flags & self.STATUS_CURSE:
            resistances.append('curse')
        if flags & self.STATUS_STONE:
            resistances.append('stone')
        return resistances
        
    def extract_enemy(self, index: int) -> Optional[Dict[str, Any]]:
        """Extract single enemy data"""
        base_addr = self.ENEMY_STATS_BASE + (index * self.ENEMY_ENTRY_SIZE)
        
        # Read all bytes for this enemy
        hp = self.read_word(base_addr + self.OFFSET_HP_LOW)
        attack = self.read_byte(base_addr + self.OFFSET_ATTACK)
        defense = self.read_byte(base_addr + self.OFFSET_DEFENSE)
        magic = self.read_byte(base_addr + self.OFFSET_MAGIC)
        magic_def = self.read_byte(base_addr + self.OFFSET_MAGIC_DEF)
        speed = self.read_byte(base_addr + self.OFFSET_SPEED)
        accuracy = self.read_byte(base_addr + self.OFFSET_ACCURACY)
        evade = self.read_byte(base_addr + self.OFFSET_EVADE)
        
        elem_resist_flags = self.read_byte(base_addr + self.OFFSET_ELEM_RESIST)
        status_resist_flags = self.read_byte(base_addr + self.OFFSET_STATUS_RESIST)
        
        exp = self.read_word(base_addr + self.OFFSET_EXP_LOW)
        gold = self.read_word(base_addr + self.OFFSET_GOLD_LOW)
        drop_item = self.read_byte(base_addr + self.OFFSET_DROP_ITEM)
        drop_rate = self.read_byte(base_addr + self.OFFSET_DROP_RATE)
        
        graphics_id = self.read_byte(base_addr + self.OFFSET_GRAPHICS_ID)
        palette = self.read_byte(base_addr + self.OFFSET_PALETTE)
        ai_script = self.read_word(base_addr + self.OFFSET_AI_SCRIPT_LOW)
        
        # Skip empty entries (all zeros or 0xff)
        if hp == 0 or hp == 0xffff:
            return None
            
        enemy = {
            'id': index,
            'name': f"Enemy_{index:03d}",  # Placeholder - need to extract from text tables
            'stats': {
                'hp': hp,
                'attack': attack,
                'defense': defense,
                'magic': magic,
                'magic_defense': magic_def,
                'speed': speed,
                'accuracy': accuracy,
                'evade': evade
            },
            'resistances': {
                'elements': self.parse_element_resistance(elem_resist_flags),
                'status': self.parse_status_resistance(status_resist_flags)
            },
            'rewards': {
                'exp': exp,
                'gold': gold,
                'drop_item': drop_item,
                'drop_rate': drop_rate
            },
            'graphics': {
                'sprite_id': graphics_id,
                'palette': palette
            },
            'ai': {
                'script_address': f"${ai_script:04X}",
                'script_offset': ai_script
            },
            'rom_address': f"${base_addr:06X}"
        }
        
        return enemy
        
    def extract_all_enemies(self) -> List[Dict[str, Any]]:
        """Extract all enemy data from ROM"""
        print(f"\nExtracting enemy data from ${self.ENEMY_STATS_BASE:06X}...")
        print(f"Enemy entry size: {self.ENEMY_ENTRY_SIZE} bytes")
        print(f"Max enemies: {self.ENEMY_COUNT}")
        print()
        
        self.enemies = []
        for i in range(self.ENEMY_COUNT):
            enemy = self.extract_enemy(i)
            if enemy:
                self.enemies.append(enemy)
                if len(self.enemies) % 10 == 0:
                    print(f"Extracted {len(self.enemies)} enemies...")
                    
        print(f"\nTotal enemies extracted: {len(self.enemies)}")
        return self.enemies
        
    def save_json(self, output_path: str):
        """Save enemy data as JSON"""
        output_file = Path(output_path)
        output_file.parent.mkdir(parents=True, exist_ok=True)
        
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump({
                'enemies': self.enemies,
                'metadata': {
                    'source_rom': str(self.rom_path.name),
                    'enemy_count': len(self.enemies),
                    'base_address': f"${self.ENEMY_STATS_BASE:06X}",
                    'entry_size': self.ENEMY_ENTRY_SIZE
                }
            }, f, indent=2)
            
        print(f"Saved JSON: {output_file}")
        
    def save_csv(self, output_path: str):
        """Save enemy data as CSV for spreadsheet editing"""
        csv_file = Path(output_path).parent / (Path(output_path).stem + '.csv')
        csv_file.parent.mkdir(parents=True, exist_ok=True)
        
        with open(csv_file, 'w', newline='', encoding='utf-8') as f:
            fieldnames = [
                'ID', 'Name', 'HP', 'Attack', 'Defense', 'Magic', 'Magic_Def',
                'Speed', 'Accuracy', 'Evade', 'EXP', 'Gold', 'Drop_Item', 'Drop_Rate',
                'Graphics_ID', 'Palette', 'AI_Script', 'ROM_Address'
            ]
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            
            for enemy in self.enemies:
                writer.writerow({
                    'ID': enemy['id'],
                    'Name': enemy['name'],
                    'HP': enemy['stats']['hp'],
                    'Attack': enemy['stats']['attack'],
                    'Defense': enemy['stats']['defense'],
                    'Magic': enemy['stats']['magic'],
                    'Magic_Def': enemy['stats']['magic_defense'],
                    'Speed': enemy['stats']['speed'],
                    'Accuracy': enemy['stats']['accuracy'],
                    'Evade': enemy['stats']['evade'],
                    'EXP': enemy['rewards']['exp'],
                    'Gold': enemy['rewards']['gold'],
                    'Drop_Item': enemy['rewards']['drop_item'],
                    'Drop_Rate': enemy['rewards']['drop_rate'],
                    'Graphics_ID': enemy['graphics']['sprite_id'],
                    'Palette': enemy['graphics']['palette'],
                    'AI_Script': enemy['ai']['script_address'],
                    'ROM_Address': enemy['rom_address']
                })
                
        print(f"Saved CSV: {csv_file}")
        
    def save_asm(self, output_path: str):
        """Save enemy data as assembly source (for rebuilding)"""
        asm_file = Path(output_path).parent / (Path(output_path).stem + '.asm')
        asm_file.parent.mkdir(parents=True, exist_ok=True)
        
        with open(asm_file, 'w', encoding='utf-8') as f:
            f.write(";==============================================================================\n")
            f.write("; Final Fantasy Mystic Quest - Enemy Data\n")
            f.write("; Extracted and converted to assembly format\n")
            f.write(";==============================================================================\n\n")
            
            f.write(f"org ${self.ENEMY_STATS_BASE:06X}\n\n")
            f.write(f"; Enemy Count: {len(self.enemies)}\n")
            f.write(f"; Entry Size: {self.ENEMY_ENTRY_SIZE} bytes\n\n")
            
            for enemy in self.enemies:
                f.write(f"; {enemy['name']} (ID ${enemy['id']:02X})\n")
                f.write(f"enemy_{enemy['id']:03d}:\n")
                
                stats = enemy['stats']
                rewards = enemy['rewards']
                gfx = enemy['graphics']
                ai = enemy['ai']
                
                f.write(f"  dw ${stats['hp']:04X}        ; HP\n")
                f.write(f"  db ${stats['attack']:02X}          ; Attack\n")
                f.write(f"  db ${stats['defense']:02X}          ; Defense\n")
                f.write(f"  db ${stats['magic']:02X}          ; Magic\n")
                f.write(f"  db ${stats['magic_defense']:02X}          ; Magic Defense\n")
                f.write(f"  db ${stats['speed']:02X}          ; Speed\n")
                f.write(f"  db ${stats['accuracy']:02X}          ; Accuracy\n")
                f.write(f"  db ${stats['evade']:02X}          ; Evade\n")
                f.write(f"  db $00          ; Element Resist (TODO)\n")
                f.write(f"  db $00          ; Status Resist (TODO)\n")
                f.write(f"  db $00,$00      ; Reserved\n")
                f.write(f"  dw ${rewards['exp']:04X}        ; EXP\n")
                f.write(f"  dw ${rewards['gold']:04X}        ; Gold\n")
                f.write(f"  db ${rewards['drop_item']:02X}          ; Drop Item\n")
                f.write(f"  db ${rewards['drop_rate']:02X}          ; Drop Rate\n")
                f.write(f"  db ${gfx['sprite_id']:02X}          ; Graphics ID\n")
                f.write(f"  db ${gfx['palette']:02X}          ; Palette\n")
                f.write(f"  dw ${ai['script_offset']:04X}        ; AI Script\n")
                f.write(f"\n")
                
        print(f"Saved ASM: {asm_file}")


def main():
    """Main entry point"""
    if len(sys.argv) < 3:
        print("Usage: extract_enemies.py <rom_file> <output_file> [--format json|csv|asm|all] [--verbose]")
        print("\nExtracts enemy data from Final Fantasy Mystic Quest ROM")
        print("\nFormats:")
        print("  json - JSON format (default)")
        print("  csv  - CSV spreadsheet")
        print("  asm  - Assembly source")
        print("  all  - All formats")
        sys.exit(1)
        
    rom_file = sys.argv[1]
    output_file = sys.argv[2]
    
    # Parse options
    format_type = 'json'
    verbose = False
    
    for arg in sys.argv[3:]:
        if arg == '--verbose':
            verbose = True
        elif arg.startswith('--format'):
            if '=' in arg:
                format_type = arg.split('=')[1]
            elif len(sys.argv) > sys.argv.index(arg) + 1:
                format_type = sys.argv[sys.argv.index(arg) + 1]
                
    print("=" * 70)
    print("Final Fantasy Mystic Quest - Enemy Data Extractor")
    print("=" * 70)
    print()
    
    # Extract enemies
    extractor = EnemyExtractor(rom_file)
    
    if not extractor.load_rom():
        sys.exit(1)
        
    extractor.extract_all_enemies()
    
    if not extractor.enemies:
        print("\nWARNING: No enemy data found!")
        print("The ROM addresses may need to be adjusted.")
        sys.exit(1)
        
    # Save in requested format(s)
    print()
    if format_type == 'all':
        extractor.save_json(output_file)
        extractor.save_csv(output_file)
        extractor.save_asm(output_file)
    elif format_type == 'csv':
        extractor.save_csv(output_file)
    elif format_type == 'asm':
        extractor.save_asm(output_file)
    else:  # json
        extractor.save_json(output_file)
        
    print()
    print("=" * 70)
    print("Extraction complete!")
    print("=" * 70)


if __name__ == '__main__':
    main()
