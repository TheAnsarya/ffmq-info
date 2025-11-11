"""
Create comprehensive sprite catalog from extracted graphics.

Generates visual reference documentation showing all extracted sprites,
palettes, and tile ranges organized by category.
"""

import os
import sys
from pathlib import Path
from typing import List, Dict, Optional
import json

sys.path.insert(0, str(Path(__file__).parent.parent))

try:
	from PIL import Image, ImageDraw, ImageFont
except ImportError:
	print("ERROR: Pillow required")
	sys.exit(1)


class SpriteCatalog:
	"""Generate visual sprite catalog."""

	def __init__(self, sprites_dir: str = "data/extracted/sprites"):
		"""Initialize catalog generator."""
		self.sprites_dir = Path(sprites_dir)
		self.output_dir = Path("docs/graphics_catalog")
		self.output_dir.mkdir(parents=True, exist_ok=True)

	def load_sprite_metadata(self, category: str) -> List[Dict]:
		"""Load all sprite metadata from a category."""
		metadata_list = []
		category_dir = self.sprites_dir / category

		if not category_dir.exists():
			return []

		for meta_file in category_dir.glob("*_meta.json"):
			with open(meta_file) as f:
				metadata_list.append(json.load(f))

		return metadata_list

	def create_category_catalog(self, category: str, scale: int = 4):
		"""
		Create visual catalog for a sprite category.

		Args:
			category: Category name (characters, enemies, ui, effects)
			scale: Upscale factor for visibility
		"""
		metadata_list = self.load_sprite_metadata(category)
		if not metadata_list:
			print(f"No sprites found in category: {category}")
			return

		print(f"\nCreating catalog for: {category}")
		print(f"  Sprites: {len(metadata_list)}")

		# Calculate catalog dimensions
		sprites_per_row = 4
		sprite_spacing = 8
		label_height = 60

		# Find max sprite dimensions
		max_width = max(m['dimensions']['width_pixels']
						for m in metadata_list)
		max_height = max(m['dimensions']['height_pixels']
						 for m in metadata_list)

		cell_width = (max_width + sprite_spacing) * scale
		cell_height = (max_height + label_height + sprite_spacing) * scale

		num_rows = (len(metadata_list) + sprites_per_row - 1) // sprites_per_row
		catalog_width = cell_width * sprites_per_row
		catalog_height = cell_height * num_rows

		# Create catalog image
		catalog = Image.new(
			'RGBA', (catalog_width, catalog_height), (40, 40, 50, 255))
		draw = ImageDraw.Draw(catalog)

		for idx, meta in enumerate(metadata_list):
			row = idx // sprites_per_row
			col = idx % sprites_per_row

			x = col * cell_width
			y = row * cell_height

			# Load sprite sheet or first frame
			sprite_name = meta['name']
			category_dir = self.sprites_dir / category

			sheet_path = category_dir / f"{sprite_name}_sheet.png"
			if sheet_path.exists():
				sprite_img = Image.open(sheet_path)
			else:
				frame_path = category_dir / f"{sprite_name}_frame0.png"
				if frame_path.exists():
					sprite_img = Image.open(frame_path)
				else:
					single_path = category_dir / f"{sprite_name}.png"
					if single_path.exists():
						sprite_img = Image.open(single_path)
					else:
						continue

			# Scale up sprite
			new_width = sprite_img.width * scale
			new_height = sprite_img.height * scale
			sprite_scaled = sprite_img.resize(
				(new_width, new_height), Image.NEAREST)

			# Center sprite in cell
			sprite_x = x + (cell_width - new_width) // 2
			sprite_y = y + sprite_spacing * scale

			catalog.paste(sprite_scaled, (sprite_x, sprite_y), sprite_scaled)

			# Draw label
			label = meta['name'].replace('_', ' ').title()
			label_y = sprite_y + new_height + 4

			# Draw text (using default font)
			text_bbox = draw.textbbox((0, 0), label)
			text_width = text_bbox[2] - text_bbox[0]
			text_x = x + (cell_width - text_width) // 2

			draw.text((text_x, label_y), label, fill=(255, 255, 255, 255))

			# Draw sprite info
			info = f"{meta['dimensions']['width_pixels']}x{meta['dimensions']['height_pixels']}px"
			# Handle both old and new metadata formats
			if 'animation' in meta and meta['animation']['num_frames'] > 1:
				info += f" • {meta['animation']['num_frames']} frames"

			info_bbox = draw.textbbox((0, 0), info)
			info_width = info_bbox[2] - info_bbox[0]
			info_x = x + (cell_width - info_width) // 2
			info_y = label_y + 16

			draw.text((info_x, info_y), info, fill=(180, 180, 180, 255))

		# Save catalog
		output_path = self.output_dir / f"{category}_catalog.png"
		catalog.save(output_path)
		print(f"  ✓ Saved: {output_path}")
		print(f"  Size: {catalog.width}x{catalog.height}px")

	def create_palette_catalog(self):
		"""Create visual catalog of all palettes."""
		palette_dir = Path("data/extracted/graphics/palettes")
		if not palette_dir.exists():
			print("No palettes found")
			return

		palette_files = sorted(palette_dir.glob("palette_*.json"))
		print(f"\nCreating palette catalog")
		print(f"  Palettes: {len(palette_files)}")

		# Catalog dimensions
		swatch_size = 32
		swatches_per_row = 16  # 16 colors per palette
		palette_spacing = 8
		label_width = 100

		catalog_width = label_width + \
			(swatches_per_row * swatch_size) + palette_spacing
		catalog_height = len(palette_files) * \
			(swatch_size + palette_spacing) + palette_spacing

		catalog = Image.new(
			'RGBA', (catalog_width, catalog_height), (40, 40, 50, 255))
		draw = ImageDraw.Draw(catalog)

		for idx, palette_file in enumerate(palette_files):
			with open(palette_file) as f:
				palette_data = json.load(f)

			y = idx * (swatch_size + palette_spacing) + palette_spacing

			# Draw palette label
			label = f"Palette {idx:02d}"
			draw.text((palette_spacing, y + swatch_size //
					  2 - 6), label, fill=(255, 255, 255, 255))

			# Draw color swatches
			# Extract RGB values from color objects
			colors = [c['hex'] for c in palette_data['colors_rgb555']]
			for color_idx, hex_color in enumerate(colors):
				# Convert hex to RGB
				hex_color = hex_color.lstrip('#')
				rgb = tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))

				x = label_width + (color_idx * swatch_size)

				# Draw swatch
				draw.rectangle(
					[x, y, x + swatch_size - 1, y + swatch_size - 1],
					fill=rgb,
					outline=(80, 80, 80, 255)
				)

		# Save catalog
		output_path = self.output_dir / "palettes_catalog.png"
		catalog.save(output_path)
		print(f"  ✓ Saved: {output_path}")
		print(f"  Size: {catalog.width}x{catalog.height}px")

	def create_index_html(self):
		"""Create HTML index for browsing catalogs."""
		html = """<!DOCTYPE html>
<html>
<head>
	<title>FFMQ Graphics Catalog</title>
	<style>
		body {
			font-family: Arial, sans-serif;
			background: #1e1e1e;
			color: #d4d4d4;
			margin: 0;
			padding: 20px;
		}
		h1 {
			color: #569cd6;
			border-bottom: 2px solid #569cd6;
			padding-bottom: 10px;
		}
		h2 {
			color: #4ec9b0;
			margin-top: 30px;
		}
		.catalog-section {
			margin: 20px 0;
			padding: 20px;
			background: #252526;
			border-radius: 8px;
		}
		img {
			max-width: 100%;
			border: 1px solid #3e3e42;
			border-radius: 4px;
			margin: 10px 0;
		}
		.info {
			background: #2d2d30;
			padding: 10px;
			border-left: 3px solid #007acc;
			margin: 10px 0;
		}
		a {
			color: #569cd6;
			text-decoration: none;
		}
		a:hover {
			text-decoration: underline;
		}
	</style>
</head>
<body>
	<h1>🎮 Final Fantasy Mystic Quest - Graphics Catalog</h1>

	<div class="info">
		<p><strong>Generated:</strong> Auto-extracted from ROM v1.1</p>
		<p><strong>Source:</strong> Banks 04 (tiles) and 05 (palettes)</p>
		<p><strong>Format:</strong> SNES 2BPP/4BPP tiles, RGB555 palettes</p>
	</div>

	<h2>📊 Color Palettes</h2>
	<div class="catalog-section">
		<p>16 color palettes extracted from Bank 05 (RGB555 → RGB888)</p>
		<img src="palettes_catalog.png" alt="Palettes Catalog">
	</div>

	<h2>👥 Character Sprites</h2>
	<div class="catalog-section">
		<p>Battle sprites for playable characters with animation frames</p>
		<img src="characters_catalog.png" alt="Characters Catalog">
	</div>

	<h2>👹 Enemy Sprites</h2>
	<div class="catalog-section">
		<p>Enemy battle sprites</p>
		<img src="enemies_catalog.png" alt="Enemies Catalog">
	</div>

	<h2>🎨 UI Elements</h2>
	<div class="catalog-section">
		<p>User interface graphics (fonts, borders, icons)</p>
		<img src="ui_catalog.png" alt="UI Catalog">
	</div>

	<h2>💫 Effects</h2>
	<div class="catalog-section">
		<p>Visual effects and spell animations</p>
		<img src="effects_catalog.png" alt="Effects Catalog">
	</div>

	<h2>📚 Documentation</h2>
	<div class="catalog-section">
		<ul>
			<li><a href="../../src/asm/bank_04_documented.asm">Bank 04 Documentation</a> - Tile format reference</li>
			<li><a href="../../src/asm/bank_05_documented.asm">Bank 05 Documentation</a> - Palette format reference</li>
			<li><a href="../../tools/extraction/extract_graphics.py">Graphics Extractor</a> - Extraction tool source</li>
			<li><a href="../../tools/extraction/extract_sprites.py">Sprite Extractor</a> - Sprite assembly tool</li>
		</ul>
	</div>
</body>
</html>
"""
		output_path = self.output_dir / "index.html"
		with open(output_path, 'w', encoding='utf-8') as f:
			f.write(html)
		print(f"\n✓ Created HTML index: {output_path}")

	def generate_all_catalogs(self):
		"""Generate all catalog types."""
		print("=" * 80)
		print("FFMQ Graphics Catalog Generator")
		print("=" * 80)

		categories = ["characters", "enemies", "ui", "effects"]
		for category in categories:
			self.create_category_catalog(category)

		self.create_palette_catalog()
		self.create_index_html()

		print("\n" + "=" * 80)
		print("Catalog Generation Complete!")
		print("=" * 80)
		print(f"Output: {self.output_dir}")
		print(f"\nView catalog: {self.output_dir / 'index.html'}")


def main():
	"""Main catalog generation."""
	catalog = SpriteCatalog()
	catalog.generate_all_catalogs()
	return 0


if __name__ == '__main__':
	sys.exit(main())
