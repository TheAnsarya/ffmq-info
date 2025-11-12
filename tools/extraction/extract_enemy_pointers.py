"""
Extract enemy sprite pointer table from FFMQ ROM Bank 09.

Reads the sprite pointer table at $098460 to determine actual sprite
locations, sizes, and graphics data for all 83 enemies.
"""

import os
import sys
import struct
from pathlib import Path
from typing import List, Dict, Tuple
from dataclasses import dataclass

sys.path.insert(0, str(Path(__file__).parent.parent))


@dataclass
class EnemySpritePointer:
	"""Enemy sprite pointer entry (5 bytes)."""
	enemy_id: int
	address: int		# 16-bit address in bank
	bank: int		   # ROM bank number
	flags: int		  # Sprite type/size flags
	padding: int		# Always 0x00
	rom_offset: int	 # Calculated file offset


class EnemySpriteTableExtractor:
	"""Extract enemy sprite pointer table from ROM."""

	def __init__(self, rom_path: str):
		"""Load ROM data."""
		with open(rom_path, 'rb') as f:
			self.rom_data = f.read()

	def extract_sprite_pointers(self, num_enemies: int = 83) -> List[EnemySpritePointer]:
		"""
		Extract enemy sprite pointer table.

		Table is at $098460 in ROM (Bank 09 offset $0460).
		Each entry is 5 bytes: [addr_lo, addr_hi, bank, flags, padding]
		"""
		# Bank 09 starts at file offset 0x048000
		# Sprite pointer table at $098460 = file offset 0x048460
		table_offset = 0x048460

		pointers = []
		for enemy_id in range(num_enemies):
			offset = table_offset + (enemy_id * 5)

			# Read 5-byte entry
			entry = self.rom_data[offset:offset + 5]
			if len(entry) < 5:
				break

			# Parse: [addr_lo][addr_hi][bank][flags][padding]
			addr_lo = entry[0]
			addr_hi = entry[1]
			bank = entry[2]
			flags = entry[3]
			padding = entry[4]

			address = addr_lo | (addr_hi << 8)  # Combine to 16-bit address

			# Calculate actual ROM file offset
			# Address is in format $09XXXX (bank 09)
			# Convert LoROM: file_offset = (bank * 0x8000) + (address - 0x8000)
			if bank >= 0x80:
				# HiROM address
				bank_num = bank - 0x80
			else:
				bank_num = bank

			rom_offset = (bank_num * 0x8000) + (address - 0x8000)

			pointer = EnemySpritePointer(
				enemy_id=enemy_id,
				address=address,
				bank=bank,
				flags=flags,
				padding=padding,
				rom_offset=rom_offset
			)
			pointers.append(pointer)

		return pointers

	def analyze_sprite_sizes(self, pointers: List[EnemySpritePointer]) -> Dict:
		"""
		Analyze sprite sizes by looking at distance between pointers.

		Sprites with same offset share graphics data.
		Size = next different offset - current offset
		"""
		# Group by ROM offset
		offset_groups = {}
		for ptr in pointers:
			if ptr.rom_offset not in offset_groups:
				offset_groups[ptr.rom_offset] = []
			offset_groups[ptr.rom_offset].append(ptr)

		# Sort unique offsets
		unique_offsets = sorted(offset_groups.keys())

		# Calculate sizes
		sprite_info = []
		for i, offset in enumerate(unique_offsets):
			enemies = offset_groups[offset]

			# Size is distance to next sprite
			if i < len(unique_offsets) - 1:
				size = unique_offsets[i + 1] - offset
			else:
				# Last sprite - estimate based on average
				size = 512  # Default estimate

			# Estimate dimensions from flags
			avg_flags = sum(e.flags for e in enemies) // len(enemies)

			if avg_flags <= 1:
				dims = "2×2"  # Small (4 tiles)
				tile_count = 4
			elif avg_flags <= 3:
				dims = "3×3"  # Medium (9 tiles)
				tile_count = 9
			elif avg_flags <= 6:
				dims = "4×4"  # Standard (16 tiles)
				tile_count = 16
			elif avg_flags <= 12:
				dims = "6×6"  # Large (36 tiles)
				tile_count = 36
			else:
				dims = "8×8+"  # Boss (64+ tiles)
				tile_count = 64

			info = {
				'rom_offset': offset,
				'size_bytes': size,
				'enemy_ids': [e.enemy_id for e in enemies],
				'flags': [e.flags for e in enemies],
				'avg_flags': avg_flags,
				'estimated_dims': dims,
				'estimated_tiles': tile_count,
				'is_shared': len(enemies) > 1
			}
			sprite_info.append(info)

		return {
			'sprites': sprite_info,
			'total_unique': len(unique_offsets),
			'total_enemies': len(pointers),
			'sharing_count': sum(1 for s in sprite_info if s['is_shared'])
		}

	def print_sprite_table(self, pointers: List[EnemySpritePointer]):
		"""Print formatted sprite pointer table."""
		print("\n" + "=" * 100)
		print(f"Enemy Sprite Pointer Table ({len(pointers)} entries)")
		print("=" * 100)
		print(f"{'ID':<4} {'Name':<20} {'ROM Offset':<12} {'Bank':<6} {'Flags':<6} {'Shared'}")
		print("-" * 100)

		# Load enemy names
		import json
		enemies_path = Path("data/extracted/enemies/enemies.json")
		if enemies_path.exists():
			with open(enemies_path) as f:
				enemy_data = json.load(f)
				enemy_names = {e['id']: e['name'] for e in enemy_data['enemies']}
		else:
			enemy_names = {}

		# Track seen offsets for sharing detection
		offset_first_seen = {}

		for ptr in pointers:
			name = enemy_names.get(ptr.enemy_id, f"Enemy {ptr.enemy_id}")

			# Check if shared
			if ptr.rom_offset in offset_first_seen:
				shared = f"→ Same as ID {offset_first_seen[ptr.rom_offset]}"
			else:
				offset_first_seen[ptr.rom_offset] = ptr.enemy_id
				shared = "Unique"

			print(f"{ptr.enemy_id:<4} {name:<20} 0x{ptr.rom_offset:06X}	"
				  f"${ptr.bank:02X}	{ptr.flags:<6} {shared}")

	def print_analysis(self, analysis: Dict):
		"""Print sprite size analysis."""
		print("\n" + "=" * 100)
		print("Sprite Graphics Analysis")
		print("=" * 100)
		print(f"Total Enemies: {analysis['total_enemies']}")
		print(f"Unique Sprites: {analysis['total_unique']}")
		print(f"Shared Graphics: {analysis['sharing_count']} sprites used by multiple enemies")
		print()

		print(f"{'ROM Offset':<12} {'Size':<10} {'Dims':<8} {'Tiles':<8} {'Flags':<10} {'Enemy IDs'}")
		print("-" * 100)

		for sprite in analysis['sprites']:
			offset_str = f"0x{sprite['rom_offset']:06X}"
			size_str = f"{sprite['size_bytes']} B"
			flags_str = f"{sprite['avg_flags']:.1f}"
			enemy_ids = ', '.join(str(id) for id in sprite['enemy_ids'][:5])
			if len(sprite['enemy_ids']) > 5:
				enemy_ids += f" +{len(sprite['enemy_ids']) - 5} more"

			print(f"{offset_str:<12} {size_str:<10} {sprite['estimated_dims']:<8} "
				  f"{sprite['estimated_tiles']:<8} {flags_str:<10} {enemy_ids}")

	def export_sprite_definitions(self, pointers: List[EnemySpritePointer],
									analysis: Dict, output_path: str):
		"""Export sprite definitions for extract_sprites.py."""
		import json

		# Load enemy names
		enemies_path = Path("data/extracted/enemies/enemies.json")
		if enemies_path.exists():
			with open(enemies_path) as f:
				enemy_data = json.load(f)
				enemy_names = {e['id']: e['name'] for e in enemy_data['enemies']}
		else:
			enemy_names = {i: f"Enemy_{i:02d}" for i in range(len(pointers))}

		# Create sprite definitions
		sprite_defs = []

		# Track which sprites we've already defined
		defined_offsets = set()

		for sprite in analysis['sprites']:
			offset = sprite['rom_offset']

			# Get primary enemy for this sprite
			primary_id = sprite['enemy_ids'][0]
			primary_name = enemy_names.get(primary_id, f"enemy_{primary_id:02d}")

			# Sanitize name for Python identifier
			safe_name = primary_name.lower().replace(' ', '_').replace('-', '_')
			safe_name = ''.join(c for c in safe_name if c.isalnum() or c == '_')

			# Parse dimensions
			dims = sprite['estimated_dims']
			if '×' in dims:
				w_str, h_str = dims.split('×')
				width = int(w_str)
				height = int(h_str.replace('+', ''))
			else:
				width = height = 4  # Default

			# Estimate palette based on enemy ID ranges
			if primary_id < 20:
				palette = 4
			elif primary_id < 40:
				palette = 5
			elif primary_id < 60:
				palette = 6
			else:
				palette = 7

			sprite_def = {
				'name': safe_name,
				'tile_offset': f"0x{offset:06X}",
				'num_tiles': sprite['estimated_tiles'],
				'width_tiles': width,
				'height_tiles': height,
				'palette_index': palette,
				'format': '4BPP',
				'category': 'enemy',
				'enemy_ids': sprite['enemy_ids'],
				'flags': sprite['flags'],
				'notes': f"Enemy IDs: {sprite['enemy_ids']}"
			}

			sprite_defs.append(sprite_def)
			defined_offsets.add(offset)

		# Save as JSON
		output_data = {
			'metadata': {
				'source': 'Bank 09 sprite pointer table',
				'table_offset': '0x048460',
				'total_enemies': analysis['total_enemies'],
				'unique_sprites': analysis['total_unique']
			},
			'sprites': sprite_defs
		}

		with open(output_path, 'w') as f:
			json.dump(output_data, f, indent=2)

		print(f"\n✓ Exported {len(sprite_defs)} sprite definitions to: {output_path}")


def main():
	"""Main extraction routine."""
	print("=" * 100)
	print("FFMQ Enemy Sprite Pointer Table Extractor")
	print("=" * 100)

	rom_path = "roms/Final Fantasy - Mystic Quest (U) (V1.1).sfc"
	extractor = EnemySpriteTableExtractor(rom_path)

	print(f"\nLoading ROM: {rom_path}")
	print("✓ ROM loaded")

	print("\nExtracting sprite pointer table from Bank 09...")
	pointers = extractor.extract_sprite_pointers(83)
	print(f"✓ Extracted {len(pointers)} enemy sprite pointers")

	# Print table
	extractor.print_sprite_table(pointers)

	# Analyze sizes
	print("\nAnalyzing sprite sizes and sharing patterns...")
	analysis = extractor.analyze_sprite_sizes(pointers)

	extractor.print_analysis(analysis)

	# Export definitions
	output_path = "data/extracted/sprites/enemy_sprite_defs.json"
	extractor.export_sprite_definitions(pointers, analysis, output_path)

	print("\n" + "=" * 100)
	print("Extraction Complete!")
	print("=" * 100)
	print(f"\nNext Steps:")
	print(f"1. Review enemy_sprite_defs.json")
	print(f"2. Update extract_sprites.py to use these definitions")
	print(f"3. Run sprite extraction for all enemies")
	print(f"4. Verify sprites in visual catalog")
	print()

	return 0


if __name__ == '__main__':
	sys.exit(main())
