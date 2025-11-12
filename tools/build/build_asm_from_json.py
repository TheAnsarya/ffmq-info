"""
Build ASM Source from JSON Data
================================

This tool reads structured JSON data and generates proper ASM source code,
replacing all placeholder comments with actual data.

Usage:
	python tools/build_asm_from_json.py data/map_tilemaps.json src/asm/bank_06_data.asm
"""

import sys
import json
import os
from pathlib import Path
from typing import List, Dict, Any

# Add tools directory to path
sys.path.insert(0, str(Path(__file__).parent))

from ffmq_data_structures import Metatile, CollisionData


def load_json_data(filepath: str) -> Dict[str, Any]:
	"""Load JSON data file."""
	with open(filepath, 'r', encoding='utf-8') as f:
		return json.load(f)


def generate_metatile_asm(metatiles_json: List[Dict], set_name: str, start_addr: str) -> str:
	"""
	Generate ASM code for metatile set.
	
	Args:
		metatiles_json: List of metatile dictionaries
		set_name: Name of metatile set
		start_addr: Starting address label
		
	Returns:
		ASM source code
	"""
	asm_lines = []
	
	# Header
	asm_lines.append("; " + "="*76)
	asm_lines.append(f"; {set_name}")
	asm_lines.append("; " + "="*76)
	asm_lines.append(f"; Format: 16x16 metatiles (4 bytes each: TL, TR, BL, BR)")
	asm_lines.append(f"; Count: {len(metatiles_json)} metatiles")
	asm_lines.append("; " + "="*76)
	asm_lines.append("")
	asm_lines.append(f"{start_addr}:")
	
	# Generate metatile data
	for meta_dict in metatiles_json:
		metatile = Metatile.from_dict(meta_dict)
		
		# Add comment separator every 8 metatiles
		if metatile.metatile_id is not None and metatile.metatile_id % 8 == 0:
			asm_lines.append("")
			asm_lines.append(f"	; Metatiles ${metatile.metatile_id:02X}-${min(metatile.metatile_id + 7, len(metatiles_json)-1):02X}")
		
		asm_lines.append(metatile.to_asm())
	
	asm_lines.append("")
	return "\n".join(asm_lines)


def generate_collision_asm(collision_json: List[Dict], start_addr: str) -> str:
	"""
	Generate ASM code for collision data.
	
	Args:
		collision_json: List of collision dictionaries
		start_addr: Starting address label
		
	Returns:
		ASM source code
	"""
	asm_lines = []
	
	# Header
	asm_lines.append("; " + "="*76)
	asm_lines.append("; Collision Data")
	asm_lines.append("; " + "="*76)
	asm_lines.append("; Format: 1 byte bitfield per tile")
	asm_lines.append("; Bit 0: Blocked (0=passable, 1=blocked)")
	asm_lines.append("; Bit 1: Water tile (requires Float)")
	asm_lines.append("; Bit 2: Lava tile (damages player)")
	asm_lines.append("; Bit 3: Event trigger (door, chest, NPC)")
	asm_lines.append("; Bit 4-7: Special properties")
	asm_lines.append(f"; Count: {len(collision_json)} entries")
	asm_lines.append("; " + "="*76)
	asm_lines.append("")
	asm_lines.append(f"{start_addr}:")
	
	# Generate collision data (16 bytes per line)
	for i in range(0, len(collision_json), 16):
		chunk = collision_json[i:i+16]
		
		# Build hex values
		hex_vals = []
		for coll_dict in chunk:
			collision = CollisionData.from_dict(coll_dict)
			hex_vals.append(f"${collision.flags:02X}")
		
		# Format as db statement
		asm_line = "	db " + ",".join(hex_vals)
		
		# Add comment for first tile in line
		first_coll = CollisionData.from_dict(chunk[0])
		properties = []
		if first_coll.is_blocked:
			properties.append("blk")
		if first_coll.is_water:
			properties.append("water")
		if first_coll.is_lava:
			properties.append("lava")
		if first_coll.is_trigger:
			properties.append("trig")
		
		if properties:
			asm_line += f"  ; Tile ${i:02X}: " + ",".join(properties)
		else:
			asm_line += f"  ; Tile ${i:02X}"
		
		asm_lines.append(asm_line)
	
	asm_lines.append("")
	return "\n".join(asm_lines)


def build_bank06_asm(json_path: str, output_path: str):
	"""
	Build complete Bank $06 ASM file from JSON data.
	
	Args:
		json_path: Path to map_tilemaps.json
		output_path: Path to output ASM file
	"""
	print(f"Loading JSON data: {json_path}")
	data = load_json_data(json_path)
	
	asm_lines = []
	
	# File header
	asm_lines.append("; " + "="*76)
	asm_lines.append("; BANK $06 - Map Tilemap Data (AUTO-GENERATED)")
	asm_lines.append("; " + "="*76)
	asm_lines.append("; Generated from: " + os.path.basename(json_path))
	asm_lines.append("; DO NOT EDIT MANUALLY - Edit JSON and regenerate")
	asm_lines.append(";")
	asm_lines.append(f"; Description: {data.get('description', 'N/A')}")
	asm_lines.append(f"; Metatile Format: {data.get('metatile_format', 'N/A')}")
	asm_lines.append(f"; Total Metatiles: {data.get('total_metatiles', 0)}")
	asm_lines.append(f"; Total Collision Entries: {data.get('total_collision_entries', 0)}")
	asm_lines.append("; " + "="*76)
	asm_lines.append("")
	asm_lines.append("				   ORG $068000")
	asm_lines.append("")
	
	# Generate metatile sets
	metatile_sets = data.get('metatile_sets', {})
	
	if 'set_1_overworld' in metatile_sets:
		set1 = metatile_sets['set_1_overworld']
		asm_lines.append(generate_metatile_asm(
			set1['metatiles'],
			"Metatile Set 1 - Overworld/Outdoor Locations",
			"DATA8_068000"
		))
	
	if 'set_2_indoor' in metatile_sets:
		set2 = metatile_sets['set_2_indoor']
		asm_lines.append(generate_metatile_asm(
			set2['metatiles'],
			"Metatile Set 2 - Indoor/Building Floors",
			"DATA8_068400"  # Estimated address
		))
	
	if 'set_3_dungeon' in metatile_sets:
		set3 = metatile_sets['set_3_dungeon']
		asm_lines.append(generate_metatile_asm(
			set3['metatiles'],
			"Metatile Set 3 - Dungeon/Cave Tiles",
			"DATA8_068800"  # Estimated address
		))
	
	# Generate collision data
	if 'collision' in data:
		collision = data['collision']
		asm_lines.append(generate_collision_asm(
			collision['entries'],
			f"DATA8_{collision['start_address'].replace('$', '')}"
		))
	
	# Footer
	asm_lines.append("; " + "="*76)
	asm_lines.append("; END OF BANK $06 AUTO-GENERATED DATA")
	asm_lines.append("; " + "="*76)
	asm_lines.append("; To rebuild this file:")
	asm_lines.append(";   python tools/build_asm_from_json.py data/map_tilemaps.json " + output_path)
	asm_lines.append("; " + "="*76)
	
	# Write output
	output_file = Path(output_path)
	output_file.parent.mkdir(parents=True, exist_ok=True)
	
	print(f"Writing ASM output: {output_path}")
	with open(output_file, 'w', encoding='utf-8') as f:
		f.write("\n".join(asm_lines))
	
	print(f"✓ Successfully generated ASM file")
	print(f"  Lines: {len(asm_lines)}")
	print(f"  Metatiles: {data.get('total_metatiles', 0)}")
	print(f"  Collision entries: {data.get('total_collision_entries', 0)}")


def main():
	if len(sys.argv) < 3:
		print("Usage: python build_asm_from_json.py <json_file> <output_asm>")
		print("Example: python build_asm_from_json.py data/map_tilemaps.json src/asm/bank_06_data.asm")
		sys.exit(1)
	
	json_path = sys.argv[1]
	output_path = sys.argv[2]
	
	if not os.path.exists(json_path):
		print(f"Error: JSON file not found: {json_path}")
		sys.exit(1)
	
	build_bank06_asm(json_path, output_path)
	print("\nDone!")


if __name__ == "__main__":
	main()
