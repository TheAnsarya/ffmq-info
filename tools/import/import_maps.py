#!/usr/bin/env python3
"""
Map Import Tool for Final Fantasy Mystic Quest
Imports edited TMX/JSON map data back into ROM

Features:
- TMX file parsing (Tiled Map Editor format)
- JSON file parsing (custom format)
- Map tile data validation
- Collision layer import
- Event trigger import
- ROM bounds checking
- Automatic backup creation

Author: FFMQ Modding Project
Date: November 2, 2025
"""

import os
import sys
import json
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import List, Dict, Optional, Tuple
from dataclasses import dataclass
import shutil

@dataclass
class ImportStats:
    """Import statistics"""
    total_maps: int = 0
    imported_maps: int = 0
    skipped_maps: int = 0
    errors: int = 0
    
class FFMQMapImporter:
    """Import edited maps back to FFMQ ROM"""
    
    # SNES ROM addresses (matching extract_maps_enhanced.py)
    MAP_HEADER_BASE = 0x0E8000
    MAP_DATA_BASE = 0x0F0000
    MAP_EVENT_BASE = 0x0F8000
    
    # Event type mappings
    EVENT_TYPE_MAP = {
        'none': 0x00,
        'npc': 0x01,
        'chest': 0x02,
        'door': 0x03,
        'exit': 0x04,
        'trigger': 0x05,
        'enemy': 0x06,
        'switch': 0x07,
    }
    
    def __init__(self, rom_path: str):
        """Initialize map importer"""
        self.rom_path = rom_path
        self.rom_data = None
        self.has_header = False
        self.stats = ImportStats()
        
    def load_rom(self) -> bool:
        """Load ROM file into memory"""
        try:
            with open(self.rom_path, 'rb') as f:
                self.rom_data = bytearray(f.read())
            
            # Check for SMC header
            rom_size = len(self.rom_data)
            if rom_size % 1024 == 512:
                self.has_header = True
                print("Detected 512-byte SMC header")
            
            return True
            
        except Exception as e:
            print(f"Error loading ROM: {e}")
            return False
    
    def save_rom(self, output_path: str) -> bool:
        """Save modified ROM to file"""
        try:
            with open(output_path, 'wb') as f:
                f.write(self.rom_data)
            return True
            
        except Exception as e:
            print(f"Error saving ROM: {e}")
            return False
    
    def snes_to_pc(self, address: int) -> int:
        """Convert SNES address to PC file offset"""
        if address >= 0x800000:
            address -= 0x800000
        
        bank = (address >> 16) & 0xFF
        offset = address & 0xFFFF
        
        if offset >= 0x8000:
            pc_addr = (bank * 0x8000) + (offset - 0x8000)
        else:
            pc_addr = address
        
        if self.has_header:
            pc_addr += 0x200
            
        return pc_addr
    
    def write_byte(self, address: int, value: int):
        """Write byte to SNES address"""
        pc_addr = self.snes_to_pc(address)
        if 0 <= pc_addr < len(self.rom_data):
            self.rom_data[pc_addr] = value & 0xFF
    
    def write_word(self, address: int, value: int):
        """Write 16-bit word to SNES address (little-endian)"""
        self.write_byte(address, value & 0xFF)
        self.write_byte(address + 1, (value >> 8) & 0xFF)
    
    def parse_tmx(self, tmx_path: str) -> Optional[Dict]:
        """Parse TMX file into map data structure"""
        try:
            tree = ET.parse(tmx_path)
            root = tree.getroot()
            
            # Extract map properties
            width = int(root.get('width', 0))
            height = int(root.get('height', 0))
            
            map_data = {
                'width': width,
                'height': height,
                'layers': {},
                'events': [],
                'properties': {}
            }
            
            # Parse properties
            props_elem = root.find('properties')
            if props_elem is not None:
                for prop in props_elem.findall('property'):
                    name = prop.get('name')
                    value = prop.get('value')
                    prop_type = prop.get('type', 'string')
                    
                    if prop_type == 'int':
                        value = int(value)
                    
                    map_data['properties'][name] = value
            
            # Parse layers
            for layer in root.findall('layer'):
                layer_name = layer.get('name')
                layer_width = int(layer.get('width'))
                layer_height = int(layer.get('height'))
                
                # Parse tile data (CSV encoding)
                data_elem = layer.find('data')
                if data_elem is not None and data_elem.get('encoding') == 'csv':
                    csv_data = data_elem.text.strip()
                    tiles = [int(x) for x in csv_data.replace('\n', ',').split(',') if x.strip()]
                    
                    map_data['layers'][layer_name] = {
                        'width': layer_width,
                        'height': layer_height,
                        'data': tiles
                    }
            
            # Parse object layers (events)
            for objgroup in root.findall('objectgroup'):
                for obj in objgroup.findall('object'):
                    event = {
                        'type': obj.get('type', 'trigger'),
                        'x': int(float(obj.get('x', 0)) / 16),  # Convert pixels to tiles
                        'y': int(float(obj.get('y', 0)) / 16),
                        'properties': {}
                    }
                    
                    # Parse object properties
                    props_elem = obj.find('properties')
                    if props_elem is not None:
                        for prop in props_elem.findall('property'):
                            name = prop.get('name')
                            value = prop.get('value')
                            prop_type = prop.get('type', 'string')
                            
                            if prop_type == 'int':
                                value = int(value)
                            
                            event['properties'][name] = value
                    
                    map_data['events'].append(event)
            
            return map_data
            
        except Exception as e:
            print(f"Error parsing TMX file: {e}")
            return None
    
    def parse_json(self, json_path: str) -> Optional[Dict]:
        """Parse JSON file into map data structure"""
        try:
            with open(json_path, 'r') as f:
                data = json.load(f)
            
            # Restructure to match TMX format
            map_data = {
                'width': data['metadata']['width'],
                'height': data['metadata']['height'],
                'layers': {},
                'events': data.get('events', []),
                'properties': {
                    'map_id': data['metadata']['map_id'],
                    'music_id': data['metadata']['music_id'],
                    'encounter_group': data['metadata']['encounter_group'],
                    'palette_id': data['metadata']['palette_id'],
                }
            }
            
            # Convert layers
            for layer_name, layer_data in data.get('layers', {}).items():
                map_data['layers'][layer_name.capitalize()] = layer_data
            
            return map_data
            
        except Exception as e:
            print(f"Error parsing JSON file: {e}")
            return None
    
    def validate_map_data(self, map_data: Dict, map_id: int) -> Tuple[bool, str]:
        """Validate map data before import"""
        # Check required fields
        if 'width' not in map_data or 'height' not in map_data:
            return False, "Missing width or height"
        
        width = map_data['width']
        height = map_data['height']
        
        # Validate dimensions (FFMQ maps are typically 16x16 or 32x32)
        if width not in [16, 32, 64] or height not in [16, 32, 64]:
            return False, f"Invalid dimensions: {width}x{height} (expected 16, 32, or 64)"
        
        # Validate terrain layer exists
        if 'Terrain' not in map_data.get('layers', {}):
            return False, "Missing Terrain layer"
        
        terrain = map_data['layers']['Terrain']
        if len(terrain['data']) != width * height:
            return False, f"Terrain data size mismatch: {len(terrain['data'])} != {width * height}"
        
        # Validate tile IDs (should be 0-1023 for SNES, accounting for flip flags)
        for tile in terrain['data']:
            tile_id = tile & 0x3FF  # Mask out flip flags
            if tile_id > 1023:
                return False, f"Invalid tile ID: {tile_id} (max 1023)"
        
        # Validate events
        for event in map_data.get('events', []):
            x = event.get('x', 0)
            y = event.get('y', 0)
            
            if x < 0 or x >= width or y < 0 or y >= height:
                return False, f"Event out of bounds: ({x}, {y})"
        
        return True, "Valid"
    
    def import_terrain_layer(self, map_id: int, layer_data: Dict):
        """Import terrain/tile layer to ROM"""
        width = layer_data['width']
        height = layer_data['height']
        tiles = layer_data['data']
        
        # Calculate data address (simplified - matches extractor)
        data_addr = self.MAP_DATA_BASE + (map_id * width * height * 2)
        
        # Write tile data
        for i, gid in enumerate(tiles):
            # Convert TMX GID back to SNES format
            flip_x = bool(gid & 0x80000000)
            flip_y = bool(gid & 0x40000000)
            tile_id = gid & 0x3FF
            
            # Build SNES tile word
            tile_word = tile_id
            if flip_x:
                tile_word |= 0x4000
            if flip_y:
                tile_word |= 0x8000
            
            # Write to ROM
            self.write_word(data_addr + (i * 2), tile_word)
    
    def import_collision_layer(self, map_id: int, layer_data: Dict):
        """Import collision layer to ROM"""
        width = layer_data['width']
        height = layer_data['height']
        tiles = layer_data['data']
        
        # Collision data address
        collision_addr = self.MAP_DATA_BASE + 0x10000 + (map_id * width * height)
        
        # Write collision data
        for i, tile_id in enumerate(tiles):
            # Convert tile ID back to collision flags
            if tile_id == 1:
                collision_byte = 0x01  # Solid
            elif tile_id == 2:
                collision_byte = 0x02  # Water
            elif tile_id == 3:
                collision_byte = 0x04  # Damage
            else:
                collision_byte = 0x00  # Passable
            
            self.write_byte(collision_addr + i, collision_byte)
    
    def import_events(self, map_id: int, events: List[Dict]):
        """Import event triggers to ROM"""
        event_addr = self.MAP_EVENT_BASE + (map_id * 256)
        
        # Clear existing events
        for i in range(32 * 8):
            self.write_byte(event_addr + i, 0)
        
        # Write new events (max 32)
        for idx, event in enumerate(events[:32]):
            event_offset = event_addr + (idx * 8)
            
            # Get event type
            event_type_name = event.get('type', 'trigger')
            event_type = self.EVENT_TYPE_MAP.get(event_type_name, 0x05)
            
            x = event.get('x', 0)
            y = event.get('y', 0)
            props = event.get('properties', {})
            
            # Extract parameters based on event type
            event_id = props.get('event_id', 0)
            param1 = props.get('param1', 0)
            param2 = props.get('param2', 0)
            param3 = props.get('param3', 0)
            
            # Type-specific parameter extraction
            if event_type_name == 'npc':
                event_id = props.get('npc_id', event_id)
                param3 = props.get('dialogue_id', param3)
            elif event_type_name == 'chest':
                param1 = props.get('item_id', param1)
                param2 = props.get('opened', param2)
            elif event_type_name == 'door' or event_type_name == 'exit':
                param1 = props.get('destination_map', props.get('exit_map', param1))
                param2 = props.get('destination_x', props.get('exit_x', param2))
                param3 = props.get('destination_y', props.get('exit_y', param3))
            
            # Write event data
            self.write_byte(event_offset + 0, event_type)
            self.write_byte(event_offset + 1, x)
            self.write_byte(event_offset + 2, y)
            self.write_byte(event_offset + 3, event_id)
            self.write_byte(event_offset + 4, param1)
            self.write_byte(event_offset + 5, param2)
            self.write_word(event_offset + 6, param3)
    
    def import_map(self, map_path: str) -> bool:
        """Import a single map file"""
        path = Path(map_path)
        
        # Determine format
        if path.suffix == '.tmx':
            map_data = self.parse_tmx(map_path)
        elif path.suffix == '.json':
            map_data = self.parse_json(map_path)
        else:
            print(f"  Error: Unsupported file format: {path.suffix}")
            self.stats.errors += 1
            return False
        
        if not map_data:
            print(f"  Error: Failed to parse file")
            self.stats.errors += 1
            return False
        
        # Get map ID from properties or filename
        map_id = map_data.get('properties', {}).get('map_id')
        if map_id is None:
            # Try to extract from filename (e.g., "00_Hill_of_Destiny.tmx")
            try:
                map_id = int(path.stem.split('_')[0])
            except:
                print(f"  Error: Cannot determine map ID")
                self.stats.errors += 1
                return False
        
        # Validate map data
        valid, message = self.validate_map_data(map_data, map_id)
        if not valid:
            print(f"  Error: Validation failed - {message}")
            self.stats.errors += 1
            return False
        
        # Import layers
        if 'Terrain' in map_data['layers']:
            self.import_terrain_layer(map_id, map_data['layers']['Terrain'])
        
        if 'Collision' in map_data['layers']:
            self.import_collision_layer(map_id, map_data['layers']['Collision'])
        
        # Import events
        if map_data.get('events'):
            self.import_events(map_id, map_data['events'])
        
        self.stats.imported_maps += 1
        return True
    
    def import_all(self, input_dir: str, output_rom: str):
        """Import all maps from directory"""
        print(f"\n=== Importing FFMQ Maps ===")
        print(f"Input directory: {input_dir}")
        print(f"Output ROM: {output_rom}")
        print()
        
        input_path = Path(input_dir)
        
        # Find all map files
        map_files = list(input_path.glob('*.tmx')) + list(input_path.glob('*.json'))
        
        if not map_files:
            print("Error: No map files found")
            return False
        
        self.stats.total_maps = len(map_files)
        
        # Import each map
        for map_file in sorted(map_files):
            print(f"Importing: {map_file.name}")
            self.import_map(str(map_file))
        
        # Save modified ROM
        if self.save_rom(output_rom):
            print(f"\n✓ Saved modified ROM: {output_rom}")
        else:
            print(f"\n✗ Failed to save ROM")
            return False
        
        return True
    
    def print_summary(self):
        """Print import statistics"""
        print(f"\n{'='*50}")
        print("Import Summary")
        print(f"{'='*50}")
        print(f"Total maps: {self.stats.total_maps}")
        print(f"Imported: {self.stats.imported_maps}")
        print(f"Skipped: {self.stats.skipped_maps}")
        print(f"Errors: {self.stats.errors}")
        print(f"{'='*50}")

def create_backup(rom_path: str) -> str:
    """Create backup of ROM file"""
    backup_path = rom_path + '.backup'
    shutil.copy2(rom_path, backup_path)
    print(f"✓ Created backup: {backup_path}")
    return backup_path

def main():
    """Main entry point"""
    if len(sys.argv) < 4:
        print("Usage: python import_maps.py <source_rom> <maps_dir> <output_rom>")
        print("\nExample:")
        print("  python import_maps.py roms/FFMQ.sfc data/extracted/maps/maps roms/FFMQ_modified.sfc")
        print("\nSupported formats: .tmx (Tiled), .json (custom)")
        sys.exit(1)
    
    source_rom = sys.argv[1]
    maps_dir = sys.argv[2]
    output_rom = sys.argv[3]
    
    # Validate source ROM
    if not os.path.exists(source_rom):
        print(f"Error: Source ROM not found: {source_rom}")
        sys.exit(1)
    
    # Validate maps directory
    if not os.path.exists(maps_dir):
        print(f"Error: Maps directory not found: {maps_dir}")
        sys.exit(1)
    
    # Create backup
    create_backup(source_rom)
    
    # Create importer
    importer = FFMQMapImporter(source_rom)
    
    # Load ROM
    if not importer.load_rom():
        print("Failed to load ROM")
        sys.exit(1)
    
    # Import all maps
    success = importer.import_all(maps_dir, output_rom)
    
    # Print summary
    importer.print_summary()
    
    if success:
        print("\n✓ Map import complete!")
        print(f"\nTest the modified ROM in an emulator:")
        print(f"  {output_rom}")
    else:
        print("\n✗ Map import failed")
        sys.exit(1)

if __name__ == '__main__':
    main()
