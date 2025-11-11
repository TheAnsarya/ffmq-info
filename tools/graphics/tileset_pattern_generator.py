"""
Procedural Tileset Pattern Generator for SNES
Generate tileset patterns algorithmically with various styles.
"""

import pygame
import random
import math
from dataclasses import dataclass
from typing import List, Tuple, Callable, Optional
from enum import Enum
import json


class PatternType(Enum):
	"""Pattern generation types"""
	NOISE = "noise"
	GRADIENT = "gradient"
	CHECKERBOARD = "checkerboard"
	STRIPES = "stripes"
	CIRCLES = "circles"
	BRICK = "brick"
	DIAGONAL = "diagonal"
	WAVE = "wave"
	CELLULAR = "cellular"
	VORONOI = "voronoi"
	PERLIN = "perlin"
	MAZE = "maze"


class TileStyle(Enum):
	"""Tile visual styles"""
	FLAT = "flat"
	SHADED = "shaded"
	DITHERED = "dithered"
	OUTLINED = "outlined"
	EMBOSSED = "embossed"


@dataclass
class GeneratorParams:
	"""Parameters for pattern generation"""
	pattern_type: PatternType
	style: TileStyle
	colors: List[int]  # Palette indices 0-15
	scale: float = 1.0
	density: float = 0.5
	seed: int = 42
	octaves: int = 1
	persistence: float = 0.5
	lacunarity: float = 2.0

	def to_dict(self):
		return {
			'pattern_type': self.pattern_type.value,
			'style': self.style.value,
			'colors': self.colors,
			'scale': self.scale,
			'density': self.density,
			'seed': self.seed,
			'octaves': self.octaves,
			'persistence': self.persistence,
			'lacunarity': self.lacunarity
		}


class PerlinNoise:
	"""Perlin noise generator for natural patterns"""

	def __init__(self, seed: int = 42):
		random.seed(seed)
		self.perm = list(range(256))
		random.shuffle(self.perm)
		self.perm *= 2

	def fade(self, t: float) -> float:
		"""Fade function for smooth interpolation"""
		return t * t * t * (t * (t * 6 - 15) + 10)

	def lerp(self, t: float, a: float, b: float) -> float:
		"""Linear interpolation"""
		return a + t * (b - a)

	def grad(self, hash_val: int, x: float, y: float) -> float:
		"""Gradient function"""
		h = hash_val & 15
		u = x if h < 8 else y
		v = y if h < 4 else (x if h in (12, 14) else 0)
		return (u if (h & 1) == 0 else -u) + (v if (h & 2) == 0 else -v)

	def noise(self, x: float, y: float) -> float:
		"""2D Perlin noise (-1 to 1)"""
		xi = int(math.floor(x)) & 255
		yi = int(math.floor(y)) & 255
		xf = x - math.floor(x)
		yf = y - math.floor(y)

		u = self.fade(xf)
		v = self.fade(yf)

		aa = self.perm[self.perm[xi] + yi]
		ab = self.perm[self.perm[xi] + yi + 1]
		ba = self.perm[self.perm[xi + 1] + yi]
		bb = self.perm[self.perm[xi + 1] + yi + 1]

		x1 = self.lerp(u, self.grad(aa, xf, yf), self.grad(ba, xf - 1, yf))
		x2 = self.lerp(u, self.grad(ab, xf, yf - 1), self.grad(bb, xf - 1, yf - 1))

		return self.lerp(v, x1, x2)

	def octave_noise(self, x: float, y: float, octaves: int = 4,
					 persistence: float = 0.5, lacunarity: float = 2.0) -> float:
		"""Multi-octave Perlin noise for detail"""
		total = 0
		frequency = 1
		amplitude = 1
		max_value = 0

		for _ in range(octaves):
			total += self.noise(x * frequency, y * frequency) * amplitude
			max_value += amplitude
			amplitude *= persistence
			frequency *= lacunarity

		return total / max_value


class TilesetGenerator:
	"""Generate procedural tilesets"""

	def __init__(self, palette: List[Tuple[int, int, int]]):
		self.palette = palette  # RGB colors
		self.noise_gen = None

	def generate_tile(self, params: GeneratorParams) -> List[List[int]]:
		"""Generate 8x8 tile with given parameters"""
		self.noise_gen = PerlinNoise(params.seed)

		# Generate base pattern
		if params.pattern_type == PatternType.NOISE:
			tile = self._generate_noise(params)
		elif params.pattern_type == PatternType.GRADIENT:
			tile = self._generate_gradient(params)
		elif params.pattern_type == PatternType.CHECKERBOARD:
			tile = self._generate_checkerboard(params)
		elif params.pattern_type == PatternType.STRIPES:
			tile = self._generate_stripes(params)
		elif params.pattern_type == PatternType.CIRCLES:
			tile = self._generate_circles(params)
		elif params.pattern_type == PatternType.BRICK:
			tile = self._generate_brick(params)
		elif params.pattern_type == PatternType.DIAGONAL:
			tile = self._generate_diagonal(params)
		elif params.pattern_type == PatternType.WAVE:
			tile = self._generate_wave(params)
		elif params.pattern_type == PatternType.CELLULAR:
			tile = self._generate_cellular(params)
		elif params.pattern_type == PatternType.VORONOI:
			tile = self._generate_voronoi(params)
		elif params.pattern_type == PatternType.PERLIN:
			tile = self._generate_perlin(params)
		elif params.pattern_type == PatternType.MAZE:
			tile = self._generate_maze(params)
		else:
			tile = [[0] * 8 for _ in range(8)]

		# Apply style effects
		tile = self._apply_style(tile, params)

		return tile

	def _generate_noise(self, params: GeneratorParams) -> List[List[int]]:
		"""Random noise pattern"""
		random.seed(params.seed)
		tile = []
		for y in range(8):
			row = []
			for x in range(8):
				if random.random() < params.density:
					row.append(random.choice(params.colors))
				else:
					row.append(params.colors[0] if params.colors else 0)
			tile.append(row)
		return tile

	def _generate_gradient(self, params: GeneratorParams) -> List[List[int]]:
		"""Linear gradient pattern"""
		tile = []
		num_colors = len(params.colors)
		for y in range(8):
			row = []
			for x in range(8):
				# Diagonal gradient
				t = (x + y) / 14.0
				idx = min(num_colors - 1, int(t * num_colors))
				row.append(params.colors[idx])
			tile.append(row)
		return tile

	def _generate_checkerboard(self, params: GeneratorParams) -> List[List[int]]:
		"""Checkerboard pattern"""
		tile = []
		size = max(1, int(4 * params.scale))
		for y in range(8):
			row = []
			for x in range(8):
				if ((x // size) + (y // size)) % 2 == 0:
					row.append(params.colors[0] if params.colors else 0)
				else:
					row.append(params.colors[1] if len(params.colors) > 1
							   else params.colors[0])
			tile.append(row)
		return tile

	def _generate_stripes(self, params: GeneratorParams) -> List[List[int]]:
		"""Horizontal or vertical stripes"""
		tile = []
		width = max(1, int(2 * params.scale))
		for y in range(8):
			row = []
			for x in range(8):
				# Vertical stripes
				if (x // width) % 2 == 0:
					row.append(params.colors[0] if params.colors else 0)
				else:
					row.append(params.colors[1] if len(params.colors) > 1
							   else params.colors[0])
			tile.append(row)
		return tile

	def _generate_circles(self, params: GeneratorParams) -> List[List[int]]:
		"""Concentric circles"""
		tile = []
		cx, cy = 3.5, 3.5
		for y in range(8):
			row = []
			for x in range(8):
				dist = math.sqrt((x - cx)**2 + (y - cy)**2)
				ring = int(dist / params.scale) % len(params.colors)
				row.append(params.colors[ring])
			tile.append(row)
		return tile

	def _generate_brick(self, params: GeneratorParams) -> List[List[int]]:
		"""Brick wall pattern"""
		tile = []
		brick_h = max(1, int(2 * params.scale))
		for y in range(8):
			row = []
			brick_row = y // brick_h
			offset = (brick_row % 2) * 2
			for x in range(8):
				# Mortar lines
				if y % brick_h == 0 or (x + offset) % 4 == 0:
					row.append(params.colors[1] if len(params.colors) > 1
							   else params.colors[0])
				else:
					row.append(params.colors[0] if params.colors else 0)
			tile.append(row)
		return tile

	def _generate_diagonal(self, params: GeneratorParams) -> List[List[int]]:
		"""Diagonal stripes"""
		tile = []
		width = max(1, int(2 * params.scale))
		for y in range(8):
			row = []
			for x in range(8):
				if ((x + y) // width) % 2 == 0:
					row.append(params.colors[0] if params.colors else 0)
				else:
					row.append(params.colors[1] if len(params.colors) > 1
							   else params.colors[0])
			tile.append(row)
		return tile

	def _generate_wave(self, params: GeneratorParams) -> List[List[int]]:
		"""Sine wave pattern"""
		tile = []
		for y in range(8):
			row = []
			for x in range(8):
				wave_y = 3.5 + 3 * math.sin(x * params.scale * math.pi / 4)
				if abs(y - wave_y) < 1:
					row.append(params.colors[1] if len(params.colors) > 1
							   else params.colors[0])
				else:
					row.append(params.colors[0] if params.colors else 0)
			tile.append(row)
		return tile

	def _generate_cellular(self, params: GeneratorParams) -> List[List[int]]:
		"""Cellular automata pattern"""
		random.seed(params.seed)
		tile = [[random.choice([0, 1]) for _ in range(8)] for _ in range(8)]

		# Run cellular automata
		for _ in range(3):
			new_tile = [[0] * 8 for _ in range(8)]
			for y in range(8):
				for x in range(8):
					neighbors = sum(
						tile[(y + dy) % 8][(x + dx) % 8]
						for dy in (-1, 0, 1) for dx in (-1, 0, 1)
						if not (dx == 0 and dy == 0)
					)
					if tile[y][x] == 1:
						new_tile[y][x] = 1 if neighbors in (2, 3) else 0
					else:
						new_tile[y][x] = 1 if neighbors == 3 else 0
			tile = new_tile

		# Map to colors
		for y in range(8):
			for x in range(8):
				tile[y][x] = params.colors[1 if tile[y][x] else 0] if len(
					params.colors) > 1 else params.colors[0]

		return tile

	def _generate_voronoi(self, params: GeneratorParams) -> List[List[int]]:
		"""Voronoi diagram pattern"""
		random.seed(params.seed)
		points = [(random.randint(0, 7), random.randint(0, 7))
				  for _ in range(max(2, int(params.density * 8)))]

		tile = []
		for y in range(8):
			row = []
			for x in range(8):
				closest = min(points, key=lambda p: (x - p[0])**2 + (y - p[1])**2)
				idx = points.index(closest) % len(params.colors)
				row.append(params.colors[idx])
			tile.append(row)
		return tile

	def _generate_perlin(self, params: GeneratorParams) -> List[List[int]]:
		"""Perlin noise pattern"""
		tile = []
		for y in range(8):
			row = []
			for x in range(8):
				noise = self.noise_gen.octave_noise(
					x * params.scale / 8, y * params.scale / 8,
					params.octaves, params.persistence, params.lacunarity
				)
				# Map -1..1 to color index
				t = (noise + 1) / 2
				idx = min(len(params.colors) - 1, int(t * len(params.colors)))
				row.append(params.colors[idx])
			tile.append(row)
		return tile

	def _generate_maze(self, params: GeneratorParams) -> List[List[int]]:
		"""Maze pattern using recursive backtracking"""
		random.seed(params.seed)

		# Simplified 4x4 maze
		maze = [[1] * 4 for _ in range(4)]
		visited = [[False] * 4 for _ in range(4)]

		def carve(x, y):
			visited[y][x] = True
			maze[y][x] = 0
			dirs = [(0, 1), (1, 0), (0, -1), (-1, 0)]
			random.shuffle(dirs)
			for dx, dy in dirs:
				nx, ny = x + dx, y + dy
				if 0 <= nx < 4 and 0 <= ny < 4 and not visited[ny][nx]:
					carve(nx, ny)

		carve(0, 0)

		# Scale to 8x8
		tile = []
		for y in range(8):
			row = []
			for x in range(8):
				mx, my = x // 2, y // 2
				val = maze[my][mx]
				row.append(params.colors[val] if val < len(params.colors)
						   else params.colors[0])
			tile.append(row)
		return tile

	def _apply_style(self, tile: List[List[int]], params: GeneratorParams
					 ) -> List[List[int]]:
		"""Apply visual style effects"""
		if params.style == TileStyle.SHADED:
			return self._apply_shading(tile, params.colors)
		elif params.style == TileStyle.DITHERED:
			return self._apply_dithering(tile)
		elif params.style == TileStyle.OUTLINED:
			return self._apply_outline(tile, params.colors)
		elif params.style == TileStyle.EMBOSSED:
			return self._apply_emboss(tile, params.colors)
		return tile

	def _apply_shading(self, tile: List[List[int]], colors: List[int]
					   ) -> List[List[int]]:
		"""Add shading effect"""
		result = [row[:] for row in tile]
		for y in range(8):
			for x in range(8):
				if y > 0 and tile[y - 1][x] != tile[y][x]:
					# Lighter on top edge
					idx = colors.index(tile[y][x]) if tile[y][x] in colors else 0
					result[y][x] = colors[min(len(colors) - 1, idx + 1)]
		return result

	def _apply_dithering(self, tile: List[List[int]]) -> List[List[int]]:
		"""Add dithering pattern"""
		result = [row[:] for row in tile]
		for y in range(8):
			for x in range(8):
				if (x + y) % 2 == 1:
					result[y][x] = max(0, result[y][x] - 1)
		return result

	def _apply_outline(self, tile: List[List[int]], colors: List[int]
					   ) -> List[List[int]]:
		"""Add outline to distinct regions"""
		result = [row[:] for row in tile]
		outline_color = colors[-1] if colors else 0

		for y in range(8):
			for x in range(8):
				# Check neighbors
				is_edge = False
				for dy, dx in [(0, 1), (1, 0), (0, -1), (-1, 0)]:
					ny, nx = y + dy, x + dx
					if 0 <= ny < 8 and 0 <= nx < 8:
						if tile[ny][nx] != tile[y][x]:
							is_edge = True
							break
				if is_edge:
					result[y][x] = outline_color

		return result

	def _apply_emboss(self, tile: List[List[int]], colors: List[int]
					  ) -> List[List[int]]:
		"""Add emboss effect"""
		result = [row[:] for row in tile]
		for y in range(1, 7):
			for x in range(1, 7):
				if tile[y - 1][x - 1] != tile[y][x]:
					idx = colors.index(tile[y][x]) if tile[y][x] in colors else 0
					result[y][x] = colors[min(len(colors) - 1, idx + 1)]
		return result

	def generate_tileset(self, params_list: List[GeneratorParams], count: int = 16
						 ) -> List[List[List[int]]]:
		"""Generate multiple tiles as a tileset"""
		tiles = []
		for i in range(count):
			params = params_list[i % len(params_list)]
			params.seed = params.seed + i  # Vary seed
			tile = self.generate_tile(params)
			tiles.append(tile)
		return tiles

	def export_to_chr(self, tiles: List[List[List[int]]], filepath: str):
		"""Export tiles to CHR format (SNES 4bpp)"""
		with open(filepath, 'wb') as f:
			for tile in tiles:
				# Convert to 4bpp format
				for y in range(8):
					# Bitplane 0-1
					bp0, bp1 = 0, 0
					for x in range(8):
						color = tile[y][x]
						bp0 |= ((color & 1) << (7 - x))
						bp1 |= (((color >> 1) & 1) << (7 - x))
					f.write(bytes([bp0, bp1]))

				for y in range(8):
					# Bitplane 2-3
					bp2, bp3 = 0, 0
					for x in range(8):
						color = tile[y][x]
						bp2 |= (((color >> 2) & 1) << (7 - x))
						bp3 |= (((color >> 3) & 1) << (7 - x))
					f.write(bytes([bp2, bp3]))


def main():
	"""Test tileset generator"""
	pygame.init()

	# Create palette (simple grayscale)
	palette = [(i * 16, i * 16, i * 16) for i in range(16)]

	generator = TilesetGenerator(palette)

	# Test each pattern type
	pattern_types = list(PatternType)
	tiles = []

	for i, pattern in enumerate(pattern_types):
		params = GeneratorParams(
			pattern_type=pattern,
			style=TileStyle.FLAT,
			colors=list(range(min(4, 16))),
			scale=1.5,
			density=0.6,
			seed=42,
			octaves=3
		)
		tile = generator.generate_tile(params)
		tiles.append(tile)
		print(f"Generated {pattern.value} tile")

	# Export
	generator.export_to_chr(tiles, "generated_tileset.chr")
	print(f"Exported {len(tiles)} tiles to CHR format")

	# Export params
	params_data = {
		'patterns': [
			GeneratorParams(
				pattern_type=p,
				style=TileStyle.FLAT,
				colors=list(range(4)),
				scale=1.5
			).to_dict() for p in pattern_types
		]
	}
	with open("tileset_params.json", 'w') as f:
		json.dump(params_data, f, indent=2)


if __name__ == '__main__':
	main()
