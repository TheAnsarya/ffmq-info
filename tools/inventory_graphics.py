#!/usr/bin/env python3
"""
FFMQ Graphics Asset Inventory Tool
===================================

Scans extracted graphics assets, generates manifest, statistics, and documentation.
Creates comprehensive visual index and organization report.

Features:
- Scan assets/graphics/ for all extracted files
- Generate extraction_manifest.json master registry
- Create GRAPHICS_EXTRACTION_REPORT.md documentation
- Generate HTML visual asset index with thumbnails
- Calculate ROM coverage statistics
- Identify uncatalogued regions

Author: AI-assisted disassembly project
Date: November 1, 2025
"""

import sys
import os
import json
from pathlib import Path
from typing import List, Dict, Tuple, Optional
from dataclasses import dataclass, asdict
from datetime import datetime
import hashlib

try:
	from PIL import Image
except ImportError:
	print("ERROR: PIL (Pillow) not installed!")
	print("Install with: pip install Pillow")
	sys.exit(1)


# ============================================================================
# DATA STRUCTURES
# ============================================================================

@dataclass
class GraphicsAsset:
	"""Represents a single graphics asset"""
	filename: str
	filepath: str
	category: str  # tiles, sprites, palettes, ui, etc.
	file_type: str  # png, bin, txt, etc.
	size_bytes: int
	dimensions: Optional[Tuple[int, int]]  # For images
	md5_hash: str
	extracted_date: str
	rom_bank: Optional[str] = None
	rom_address: Optional[str] = None
	description: Optional[str] = None

	def to_dict(self) -> Dict:
		d = asdict(self)
		if self.dimensions:
			d['width'] = self.dimensions[0]
			d['height'] = self.dimensions[1]
			d.pop('dimensions')
		return d


# ============================================================================
# ASSET SCANNER
# ============================================================================

class GraphicsInventory:
	"""Manages graphics asset inventory and documentation"""

	def __init__(self, assets_dir: str = "assets/graphics"):
		self.assets_dir = Path(assets_dir)
		self.assets: List[GraphicsAsset] = []
		self.categories = {
			'tiles': [],
			'sprites': [],
			'palettes': [],
			'ui': [],
			'backgrounds': [],
			'fonts': [],
			'uncategorized': []
		}

	def scan_assets(self):
		"""Scan assets directory and catalog all files"""
		print(f"🔍 Scanning {self.assets_dir}...")

		if not self.assets_dir.exists():
			print(f"❌ Directory not found: {self.assets_dir}")
			return

		# Scan all files recursively
		for filepath in self.assets_dir.rglob('*'):
			if filepath.is_file() and not filepath.name.startswith('.'):
				asset = self._process_file(filepath)
				if asset:
					self.assets.append(asset)
					category = asset.category
					if category in self.categories:
						self.categories[category].append(asset)
					else:
						self.categories['uncategorized'].append(asset)

		print(f"✓ Found {len(self.assets)} assets")

	def _process_file(self, filepath: Path) -> Optional[GraphicsAsset]:
		"""Process individual file and create asset record"""
		try:
			# Calculate MD5 hash
			with open(filepath, 'rb') as f:
				file_hash = hashlib.md5(f.read()).hexdigest()

			# Get file info
			stat = filepath.stat()
			size_bytes = stat.st_size
			modified_date = datetime.fromtimestamp(stat.st_mtime).isoformat()

			# Determine category from filename/path
			category = self._categorize_file(filepath)

			# Get image dimensions if it's an image
			dimensions = None
			file_type = filepath.suffix.lower().lstrip('.')

			if file_type in ['png', 'bmp', 'gif', 'jpg', 'jpeg']:
				try:
					with Image.open(filepath) as img:
						dimensions = img.size
				except Exception:
					pass

			# Extract metadata from filename
			rom_bank, rom_address, description = self._extract_metadata(filepath)

			return GraphicsAsset(
				filename=filepath.name,
				filepath=str(filepath.relative_to(self.assets_dir.parent)),
				category=category,
				file_type=file_type,
				size_bytes=size_bytes,
				dimensions=dimensions,
				md5_hash=file_hash,
				extracted_date=modified_date,
				rom_bank=rom_bank,
				rom_address=rom_address,
				description=description
			)

		except Exception as e:
			print(f"  ⚠ Error processing {filepath.name}: {e}")
			return None

	def _categorize_file(self, filepath: Path) -> str:
		"""Categorize file based on name and location"""
		name_lower = filepath.name.lower()
		path_str = str(filepath).lower()

		if 'palette' in path_str:
			return 'palettes'
		elif 'sprite' in name_lower or 'character' in name_lower or 'enemy' in name_lower:
			return 'sprites'
		elif 'tile' in name_lower:
			return 'tiles'
		elif 'ui' in name_lower or 'menu' in name_lower:
			return 'ui'
		elif 'background' in name_lower or 'bg' in name_lower:
			return 'backgrounds'
		elif 'font' in name_lower or 'text' in name_lower:
			return 'fonts'
		else:
			return 'uncategorized'

	def _extract_metadata(self, filepath: Path) -> Tuple[Optional[str], Optional[str], Optional[str]]:
		"""Extract ROM bank/address metadata from filename"""
		# Look for patterns like bank_0B, 0x08a000, etc.
		name = filepath.stem

		bank = None
		address = None
		description = None

		# Check for bank pattern
		if 'bank_' in name.lower():
			parts = name.lower().split('bank_')
			if len(parts) > 1:
				bank_part = parts[1].split('_')[0]
				if len(bank_part) == 2:
					bank = f"${bank_part.upper()}"

		# Add basic description
		if 'main' in name.lower():
			description = "Main tileset"
		elif 'sprite' in name.lower():
			description = "Sprite graphics"
		elif 'extra' in name.lower():
			description = "Additional tiles"
		elif 'palette' in name.lower():
			description = "Color palette data"

		return bank, address, description

	def generate_manifest(self, output_path: Path):
		"""Generate JSON manifest of all assets"""
		manifest = {
			'generated': datetime.now().isoformat(),
			'total_assets': len(self.assets),
			'categories': {cat: len(assets) for cat, assets in self.categories.items()},
			'assets': [asset.to_dict() for asset in self.assets]
		}

		output_path.parent.mkdir(parents=True, exist_ok=True)
		with open(output_path, 'w') as f:
			json.dump(manifest, f, indent=2)

		print(f"✓ Generated manifest: {output_path}")

	def generate_statistics(self) -> Dict:
		"""Calculate statistics about extracted assets"""
		stats = {
			'total_assets': len(self.assets),
			'total_size_mb': sum(a.size_bytes for a in self.assets) / (1024 * 1024),
			'by_category': {},
			'by_file_type': {},
			'image_assets': 0,
			'binary_assets': 0,
			'total_pixels': 0
		}

		# Category breakdown
		for cat, assets in self.categories.items():
			if assets:
				stats['by_category'][cat] = {
					'count': len(assets),
					'size_mb': sum(a.size_bytes for a in assets) / (1024 * 1024)
				}

		# File type breakdown
		file_types = {}
		for asset in self.assets:
			ft = asset.file_type
			if ft not in file_types:
				file_types[ft] = 0
			file_types[ft] += 1
		stats['by_file_type'] = file_types

		# Image statistics
		for asset in self.assets:
			if asset.file_type in ['png', 'bmp', 'gif', 'jpg']:
				stats['image_assets'] += 1
				if asset.dimensions:
					stats['total_pixels'] += asset.dimensions[0] * asset.dimensions[1]
			elif asset.file_type in ['bin', 'dat']:
				stats['binary_assets'] += 1

		return stats

	def generate_report(self, output_path: Path):
		"""Generate markdown documentation report"""
		stats = self.generate_statistics()

		report = f"""# FFMQ Graphics Extraction Report

**Generated:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
**Total Assets:** {stats['total_assets']}
**Total Size:** {stats['total_size_mb']:.2f} MB

## Overview

This report catalogs all extracted graphics assets from Final Fantasy: Mystic Quest.

## Statistics

### Asset Breakdown by Category

| Category | Count | Size (MB) |
|----------|-------|-----------|
"""

		for cat, data in sorted(stats['by_category'].items()):
			report += f"| {cat.title()} | {data['count']} | {data['size_mb']:.2f} |\n"

		report += f"""
### File Type Distribution

| Type | Count |
|------|-------|
"""
		for file_type, count in sorted(stats['by_file_type'].items()):
			report += f"| {file_type.upper()} | {count} |\n"

		report += f"""

### Image Assets

- **Total Image Files:** {stats['image_assets']}
- **Total Binary Files:** {stats['binary_assets']}
- **Total Pixels:** {stats['total_pixels']:,}

## Asset Categories

"""

		for cat_name, cat_assets in sorted(self.categories.items()):
			if not cat_assets:
				continue

			report += f"\n### {cat_name.title()} ({len(cat_assets)} assets)\n\n"

			# Group by file type
			by_type = {}
			for asset in cat_assets:
				ft = asset.file_type
				if ft not in by_type:
					by_type[ft] = []
				by_type[ft].append(asset)

			for file_type, assets in sorted(by_type.items()):
				report += f"\n#### {file_type.upper()} Files\n\n"
				report += "| Filename | Size | Dimensions | Description |\n"
				report += "|----------|------|------------|-------------|\n"

				for asset in sorted(assets, key=lambda a: a.filename):
					size_kb = asset.size_bytes / 1024
					dims = f"{asset.dimensions[0]}x{asset.dimensions[1]}" if asset.dimensions else "N/A"
					desc = asset.description or ""
					report += f"| `{asset.filename}` | {size_kb:.1f} KB | {dims} | {desc} |\n"

		report += """

## Directory Structure

```
assets/graphics/
├── palettes/          # Extracted color palettes
├── tiles/             # Tile graphics (backgrounds, tilesets)
├── sprites/           # Character and enemy sprites
├── ui/                # User interface graphics
├── backgrounds/       # Background images
└── fonts/             # Font/text graphics
```

## Extraction Tools

- `tools/extract_graphics.py` - Main graphics extractor
- `tools/extract_palettes.py` - Palette extraction
- `tools/palette_manager.py` - Palette management CLI
- `tools/graphics_converter.py` - Format conversion utilities

## Related Documentation

- [ROM_DATA_MAP.md](ROM_DATA_MAP.md) - ROM data structure documentation
- [palette_book.html](../reports/palette_book.html) - Visual palette reference

## Uncatalogued Regions

Areas of the ROM that may contain graphics data but haven't been extracted yet:

- **Bank $0a:** Additional compressed graphics
- **Bank $0e:** Compressed tileset data
- **Bank $0f:** Unknown graphics regions

## Next Steps

- [ ] Extract remaining compressed graphics from Banks $0a, $0e, $0f
- [ ] Catalog all sprite animation frames
- [ ] Extract and document all UI elements
- [ ] Create sprite sheet assemblies
- [ ] Generate tile usage maps

---

**End of Graphics Extraction Report**
"""

		output_path.parent.mkdir(parents=True, exist_ok=True)
		with open(output_path, 'w', encoding='utf-8') as f:
			f.write(report)

		print(f"✓ Generated report: {output_path}")

	def generate_visual_index(self, output_path: Path):
		"""Generate HTML visual index with thumbnails"""
		html = """<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="UTF-8">
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
	<title>FFMQ Graphics Asset Index</title>
	<style>
		body {
			font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
			background: #1e1e1e;
			color: #d4d4d4;
			padding: 20px;
			max-width: 1600px;
			margin: 0 auto;
		}
		h1 { color: #569cd6; }
		h2 { color: #4ec9b0; border-bottom: 2px solid #4ec9b0; padding-bottom: 5px; margin-top: 30px; }
		h3 { color: #dcdcaa; }
		.stats {
			display: grid;
			grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
			gap: 15px;
			margin: 20px 0;
		}
		.stat-card {
			background: #252526;
			border: 1px solid #3e3e42;
			border-radius: 8px;
			padding: 15px;
			text-align: center;
		}
		.stat-value {
			font-size: 2em;
			font-weight: bold;
			color: #4ec9b0;
		}
		.stat-label {
			color: #858585;
			font-size: 0.9em;
			margin-top: 5px;
		}
		.asset-grid {
			display: grid;
			grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
			gap: 20px;
			margin: 20px 0;
		}
		.asset-card {
			background: #252526;
			border: 1px solid #3e3e42;
			border-radius: 8px;
			padding: 15px;
			transition: transform 0.2s;
		}
		.asset-card:hover {
			transform: translateY(-5px);
			border-color: #569cd6;
		}
		.asset-thumbnail {
			width: 100%;
			height: 150px;
			background: #1e1e1e;
			border: 1px solid #3e3e42;
			border-radius: 4px;
			display: flex;
			align-items: center;
			justify-content: center;
			margin-bottom: 10px;
			overflow: hidden;
		}
		.asset-thumbnail img {
			max-width: 100%;
			max-height: 100%;
			image-rendering: pixelated;
			image-rendering: crisp-edges;
		}
		.asset-thumbnail.binary {
			background: repeating-linear-gradient(
				45deg,
				#2a2a2a,
				#2a2a2a 10px,
				#1e1e1e 10px,
				#1e1e1e 20px
			);
		}
		.asset-name {
			font-weight: bold;
			color: #dcdcaa;
			margin-bottom: 5px;
			word-break: break-all;
			font-size: 0.9em;
		}
		.asset-info {
			font-size: 0.8em;
			color: #858585;
		}
		.asset-info div {
			margin: 3px 0;
		}
		.tag {
			display: inline-block;
			background: #3e3e42;
			color: #d4d4d4;
			padding: 2px 8px;
			border-radius: 3px;
			font-size: 0.75em;
			margin: 2px;
		}
		.tag.category {
			background: #264f78;
			color: #9cdcfe;
		}
	</style>
</head>
<body>
	<h1>🖼️ FFMQ Graphics Asset Index</h1>
	<p>Complete visual catalog of extracted graphics assets</p>
"""

		stats = self.generate_statistics()

		# Statistics cards
		html += '    <div class="stats">\n'
		html += f'        <div class="stat-card"><div class="stat-value">{stats["total_assets"]}</div><div class="stat-label">Total Assets</div></div>\n'
		html += f'        <div class="stat-card"><div class="stat-value">{stats["image_assets"]}</div><div class="stat-label">Image Files</div></div>\n'
		html += f'        <div class="stat-card"><div class="stat-value">{stats["binary_assets"]}</div><div class="stat-label">Binary Files</div></div>\n'
		html += f'        <div class="stat-card"><div class="stat-value">{stats["total_size_mb"]:.1f} MB</div><div class="stat-label">Total Size</div></div>\n'
		html += '    </div>\n'

		# Asset categories
		for cat_name, cat_assets in sorted(self.categories.items()):
			if not cat_assets:
				continue

			html += f'\n    <h2>{cat_name.title()} ({len(cat_assets)} assets)</h2>\n'
			html += '    <div class="asset-grid">\n'

			for asset in sorted(cat_assets, key=lambda a: a.filename):
				html += '        <div class="asset-card">\n'

				# Thumbnail
				if asset.file_type in ['png', 'bmp', 'gif', 'jpg']:
					# Relative path from reports/ to assets/
					rel_path = f"../{asset.filepath}"
					html += f'            <div class="asset-thumbnail"><img src="{rel_path}" alt="{asset.filename}"></div>\n'
				else:
					html += '            <div class="asset-thumbnail binary">\n'
					html += f'                <span style="color:#858585">{asset.file_type.upper()}</span>\n'
					html += '            </div>\n'

				# Info
				html += f'            <div class="asset-name">{asset.filename}</div>\n'
				html += '            <div class="asset-info">\n'

				if asset.dimensions:
					html += f'                <div>📏 {asset.dimensions[0]}x{asset.dimensions[1]} pixels</div>\n'

				size_kb = asset.size_bytes / 1024
				html += f'                <div>💾 {size_kb:.1f} KB</div>\n'

				if asset.rom_bank:
					html += f'                <div>🏦 Bank {asset.rom_bank}</div>\n'

				if asset.description:
					html += f'                <div>📝 {asset.description}</div>\n'

				html += f'                <div><span class="tag category">{cat_name}</span><span class="tag">{asset.file_type.upper()}</span></div>\n'

				html += '            </div>\n'
				html += '        </div>\n'

			html += '    </div>\n'

		html += """
</body>
</html>
"""

		output_path.parent.mkdir(parents=True, exist_ok=True)
		with open(output_path, 'w', encoding='utf-8') as f:
			f.write(html)

		print(f"✓ Generated visual index: {output_path}")


# ============================================================================
# CLI
# ============================================================================

def main():
	print("=" * 60)
	print("FFMQ Graphics Asset Inventory")
	print("=" * 60)

	inventory = GraphicsInventory()
	inventory.scan_assets()

	print("\n📊 Generating outputs...")

	# Generate manifest
	inventory.generate_manifest(Path("assets/extraction_manifest.json"))

	# Generate report
	inventory.generate_report(Path("docs/GRAPHICS_EXTRACTION_REPORT.md"))

	# Generate visual index
	inventory.generate_visual_index(Path("reports/graphics_asset_index.html"))

	# Print summary
	stats = inventory.generate_statistics()
	print(f"\n✅ Inventory Complete!")
	print(f"   Total Assets: {stats['total_assets']}")
	print(f"   Total Size: {stats['total_size_mb']:.2f} MB")
	print(f"   Categories: {len([c for c, a in inventory.categories.items() if a])}")

	return 0


if __name__ == '__main__':
	sys.exit(main())
