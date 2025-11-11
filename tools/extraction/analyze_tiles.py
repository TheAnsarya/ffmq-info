"""
Analyze tile data in FFMQ ROM to identify sprite boundaries and patterns.

This tool scans Bank 04 to detect non-empty tiles, clusters them into
sprite groups, and generates a visual map of tile usage.

Helps identify actual sprite locations vs estimated offsets.
"""

import os
import sys
from pathlib import Path
from typing import List, Dict, Tuple, Set
from dataclasses import dataclass
import struct

sys.path.insert(0, str(Path(__file__).parent.parent))

from extraction.extract_graphics import GraphicsExtractor


@dataclass
class TileCluster:
	"""A cluster of consecutive non-empty tiles."""
	start_offset: int
	end_offset: int
	tile_count: int
	density: float  # % of non-empty bytes
	category: str = "unknown"


class TileAnalyzer:
	"""Analyze tile patterns in ROM."""

	def __init__(self, rom_path: str):
		"""Initialize analyzer."""
		with open(rom_path, 'rb') as f:
			self.rom_data = f.read()
		self.extractor = GraphicsExtractor(rom_path)

	def is_empty_tile_4bpp(self, offset: int) -> bool:
		"""Check if a 4BPP tile is empty (all zeros)."""
		tile_data = self.rom_data[offset:offset + 32]
		return all(b == 0 for b in tile_data)

	def is_empty_tile_2bpp(self, offset: int) -> bool:
		"""Check if a 2BPP tile is empty (all zeros)."""
		tile_data = self.rom_data[offset:offset + 16]
		return all(b == 0 for b in tile_data)

	def get_tile_density(self, offset: int, size: int) -> float:
		"""Get percentage of non-zero bytes in tile."""
		tile_data = self.rom_data[offset:offset + size]
		if not tile_data:
			return 0.0
		non_zero = sum(1 for b in tile_data if b != 0)
		return (non_zero / len(tile_data)) * 100

	def scan_bank04_4bpp(self, start_offset: int = 0x028000,
						 end_offset: int = 0x030000) -> List[TileCluster]:
		"""
		Scan Bank 04 for 4BPP tile clusters.

		Returns list of clusters with consecutive non-empty tiles.
		"""
		clusters = []
		current_cluster = None
		tile_size = 32  # 4BPP

		offset = start_offset
		while offset < end_offset:
			is_empty = self.is_empty_tile_4bpp(offset)
			density = self.get_tile_density(offset, tile_size)

			if not is_empty and density > 5.0:  # At least 5% non-zero
				if current_cluster is None:
					# Start new cluster
					current_cluster = TileCluster(
						start_offset=offset,
						end_offset=offset + tile_size,
						tile_count=1,
						density=density
					)
				else:
					# Extend current cluster
					current_cluster.end_offset = offset + tile_size
					current_cluster.tile_count += 1
					current_cluster.density = (
						current_cluster.density + density) / 2
			else:
				# Empty tile - close current cluster if exists
				if current_cluster is not None and current_cluster.tile_count >= 4:
					# Only save clusters with 4+ tiles (ignore stray data)
					clusters.append(current_cluster)
				current_cluster = None

			offset += tile_size

		# Close final cluster
		if current_cluster is not None and current_cluster.tile_count >= 4:
			clusters.append(current_cluster)

		return clusters

	def categorize_cluster(self, cluster: TileCluster) -> str:
		"""
		Categorize cluster based on size and density.

		Heuristics:
		- 4-16 tiles: Small enemy or UI element
		- 16-64 tiles: Character sprite or medium enemy
		- 64-256 tiles: Large enemy, boss, or tile set
		- 256+ tiles: Font or large tile collection
		"""
		count = cluster.tile_count

		if count < 16:
			return "small_sprite"
		elif count < 64:
			return "character_or_medium_enemy"
		elif count < 256:
			return "large_enemy_or_tileset"
		else:
			return "font_or_collection"

	def print_cluster_report(self, clusters: List[TileCluster]):
		"""Print detailed cluster report."""
		print("\n" + "=" * 80)
		print(f"Found {len(clusters)} tile clusters in Bank 04 (4BPP)")
		print("=" * 80)
		print()

		total_tiles = 0
		for i, cluster in enumerate(clusters):
			category = self.categorize_cluster(cluster)
			cluster.category = category

			print(f"Cluster #{i + 1}: {category}")
			print(
				f"  ROM Offset: 0x{cluster.start_offset:06X} - 0x{cluster.end_offset:06X}")
			print(f"  Tiles: {cluster.tile_count}")
			print(
				f"  Size: {cluster.end_offset - cluster.start_offset} bytes")
			print(f"  Density: {cluster.density:.1f}% non-zero")

			# Estimate dimensions (assume square-ish sprites)
			if cluster.tile_count == 4:
				dims = "2x2"
			elif cluster.tile_count == 16:
				dims = "4x4"
			elif cluster.tile_count == 64:
				dims = "8x8"
			elif cluster.tile_count >= 96:
				dims = f"~{int((cluster.tile_count ** 0.5) + 0.5)}x{int((cluster.tile_count ** 0.5) + 0.5)}"
			else:
				dims = "irregular"
			print(f"  Estimated: {dims} tiles")
			print()

			total_tiles += cluster.tile_count

		print("=" * 80)
		print(f"Total: {total_tiles} tiles across {len(clusters)} clusters")
		print("=" * 80)

	def generate_sprite_definitions(self, clusters: List[TileCluster]) -> str:
		"""Generate Python sprite definitions from clusters."""
		lines = []
		lines.append("# Auto-generated sprite definitions from ROM analysis")
		lines.append("# Review and adjust as needed\n")

		for i, cluster in enumerate(clusters):
			# Estimate dimensions
			if cluster.tile_count == 4:
				w, h = 2, 2
			elif cluster.tile_count == 16:
				w, h = 4, 4
			elif cluster.tile_count == 64:
				w, h = 8, 8
			else:
				dim = int((cluster.tile_count ** 0.5) + 0.5)
				w, h = dim, dim

			category_map = {
				"small_sprite": "enemy",
				"character_or_medium_enemy": "character",
				"large_enemy_or_tileset": "enemy",
				"font_or_collection": "ui"
			}
			category = category_map.get(cluster.category, "unknown")

			lines.append("SpriteDefinition(")
			lines.append(f'    name="sprite_{i:03d}",')
			lines.append(f'    tile_offset=0x{cluster.start_offset:06X},')
			lines.append(f'    num_tiles={cluster.tile_count},')
			lines.append(f'    width_tiles={w},')
			lines.append(f'    height_tiles={h},')
			lines.append(f'    palette_index=0,  # TODO: Determine')
			lines.append(f'    format="4BPP",')
			lines.append(f'    category="{category}",')
			lines.append(
				f'    notes="Auto-detected {cluster.category}, {cluster.density:.0f}% density"')
			lines.append("),\n")

		return "\n".join(lines)


def main():
	"""Main analysis routine."""
	print("=" * 80)
	print("FFMQ Tile Range Analysis")
	print("=" * 80)

	rom_path = "roms/Final Fantasy - Mystic Quest (U) (V1.1).sfc"

	print(f"\nLoading ROM: {rom_path}")
	analyzer = TileAnalyzer(rom_path)
	print("✓ ROM loaded")

	print("\nScanning Bank 04 for tile clusters...")
	clusters = analyzer.scan_bank04_4bpp()

	analyzer.print_cluster_report(clusters)

	# Generate sprite definitions
	print("\nGenerating sprite definitions...")
	defs = analyzer.generate_sprite_definitions(clusters)

	output_path = Path("data/extracted/sprites/auto_sprite_defs.py")
	output_path.parent.mkdir(parents=True, exist_ok=True)
	with open(output_path, 'w') as f:
		f.write(defs)

	print(f"✓ Saved to: {output_path}")
	print()
	print("Next Steps:")
	print("  1. Review auto_sprite_defs.py")
	print("  2. Identify sprite purposes by visual inspection")
	print("  3. Map to character/enemy IDs from extracted data")
	print("  4. Update extract_sprites.py with accurate definitions")
	print("  5. Re-extract with correct offsets")

	return 0


if __name__ == '__main__':
	sys.exit(main())
