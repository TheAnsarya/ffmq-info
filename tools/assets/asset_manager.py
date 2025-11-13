#!/usr/bin/env python3
"""
Asset Manager - Comprehensive asset management for ROM hacking projects
Manage graphics, music, data tables, and other game assets

Features:
- Asset cataloging and indexing
- Import/export in multiple formats
- Asset conversion pipelines
- Dependency tracking
- Version control integration
- Asset validation
- Compression handling
- Metadata management

Asset Types:
- Graphics: tiles, sprites, palettes, maps
- Music: SPC, MIDI, MML
- Text: dialog, menus, strings
- Data: tables, enemy stats, item data
- Binary: raw data blocks

Operations:
- Import from ROM
- Export to editable format
- Validate asset integrity
- Track asset dependencies
- Generate asset reports
- Batch operations

Usage:
	python asset_manager.py --index roms/game.sfc --output assets.json
	python asset_manager.py --extract graphics --offset 0x80000 --size 0x10000
	python asset_manager.py --import sprite.png --output assets/sprites/
	python asset_manager.py --validate assets/ --report validation.md
"""

import argparse
import hashlib
import struct
from pathlib import Path
from typing import Dict, List, Optional, Set, Tuple
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
import json


class AssetType(Enum):
	"""Asset type enumeration"""
	GRAPHICS = "graphics"
	SPRITE = "sprite"
	PALETTE = "palette"
	TILEMAP = "tilemap"
	MUSIC = "music"
	SOUND = "sound"
	TEXT = "text"
	DIALOG = "dialog"
	DATA_TABLE = "data_table"
	BINARY = "binary"
	UNKNOWN = "unknown"


class CompressionType(Enum):
	"""Compression formats"""
	NONE = "none"
	RLE = "rle"
	LZ77 = "lz77"
	LZSS = "lzss"
	CUSTOM = "custom"


@dataclass
class Asset:
	"""An asset in the project"""
	asset_id: str
	asset_type: AssetType
	name: str
	rom_offset: Optional[int] = None
	rom_size: Optional[int] = None
	file_path: Optional[Path] = None
	compression: CompressionType = CompressionType.NONE
	checksum: Optional[str] = None
	metadata: Dict = field(default_factory=dict)
	dependencies: List[str] = field(default_factory=list)
	last_modified: Optional[datetime] = None


@dataclass
class AssetCatalog:
	"""Catalog of all project assets"""
	project_name: str
	version: str
	base_rom: Optional[Path]
	assets: Dict[str, Asset] = field(default_factory=dict)
	asset_dirs: List[Path] = field(default_factory=list)


class AssetManager:
	"""Manage ROM hacking project assets"""

	def __init__(self, verbose: bool = False):
		self.verbose = verbose
		self.catalog = AssetCatalog(
			project_name="",
			version="1.0"
		)

	def calculate_checksum(self, data: bytes) -> str:
		"""Calculate SHA-256 checksum"""
		return hashlib.sha256(data).hexdigest()

	def detect_asset_type(self, data: bytes, offset: int = 0) -> AssetType:
		"""Detect asset type from data"""
		# Basic heuristics
		if len(data) == 32:
			# Might be palette (16 colors * 2 bytes)
			return AssetType.PALETTE

		elif len(data) % 32 == 0 and len(data) >= 256:
			# Might be 4bpp tile data
			return AssetType.GRAPHICS

		elif len(data) >= 4 and data[0:4] == b'MThd':
			# MIDI file
			return AssetType.MUSIC

		else:
			return AssetType.BINARY

	def detect_compression(self, data: bytes) -> CompressionType:
		"""Detect compression type"""
		if len(data) < 2:
			return CompressionType.NONE

		# Simple RLE detection
		if data[0] == 0xFF and data[1] in (0x00, 0xFF):
			return CompressionType.RLE

		# LZ77/LZSS detection (simplified)
		if data[0] in (0x10, 0x11, 0x40):
			return CompressionType.LZ77

		return CompressionType.NONE

	def extract_asset(self, rom_path: Path, offset: int, size: int,
					  asset_type: Optional[AssetType] = None) -> Asset:
		"""Extract asset from ROM"""
		with open(rom_path, 'rb') as f:
			f.seek(offset)
			data = f.read(size)

		# Detect type if not specified
		if asset_type is None:
			asset_type = self.detect_asset_type(data, offset)

		# Detect compression
		compression = self.detect_compression(data)

		# Create asset
		asset_id = f"asset_{offset:06X}"
		asset = Asset(
			asset_id=asset_id,
			asset_type=asset_type,
			name=f"{asset_type.value}_{offset:06X}",
			rom_offset=offset,
			rom_size=size,
			compression=compression,
			checksum=self.calculate_checksum(data),
			metadata={
				'extracted_from': str(rom_path),
				'extraction_date': datetime.now().isoformat()
			}
		)

		if self.verbose:
			print(f"Extracted {asset.name} (type: {asset_type.value}, size: {size} bytes)")

		return asset

	def index_rom(self, rom_path: Path) -> None:
		"""Index all assets in ROM"""
		if self.verbose:
			print(f"Indexing ROM: {rom_path}")

		self.catalog.base_rom = rom_path

		# Known asset locations (example for FFMQ)
		asset_locations = [
			(0x080000, 0x010000, AssetType.GRAPHICS),  # Graphics data
			(0x0C0000, 0x008000, AssetType.TILEMAP),   # Tilemaps
			(0x100000, 0x020000, AssetType.MUSIC),     # Music data
			(0x180000, 0x010000, AssetType.DIALOG),    # Dialog text
		]

		for offset, size, asset_type in asset_locations:
			try:
				asset = self.extract_asset(rom_path, offset, size, asset_type)
				self.catalog.assets[asset.asset_id] = asset
			except Exception as e:
				if self.verbose:
					print(f"  Error extracting asset at 0x{offset:06X}: {e}")

		if self.verbose:
			print(f"Indexed {len(self.catalog.assets)} assets")

	def scan_asset_directory(self, asset_dir: Path) -> None:
		"""Scan directory for asset files"""
		if self.verbose:
			print(f"Scanning directory: {asset_dir}")

		# Asset file patterns
		patterns = {
			'*.png': AssetType.GRAPHICS,
			'*.chr': AssetType.GRAPHICS,
			'*.spc': AssetType.MUSIC,
			'*.mid': AssetType.MUSIC,
			'*.txt': AssetType.TEXT,
			'*.bin': AssetType.BINARY,
			'*.pal': AssetType.PALETTE,
		}

		for pattern, asset_type in patterns.items():
			for file_path in asset_dir.rglob(pattern):
				asset_id = file_path.stem

				# Read file for checksum
				try:
					with open(file_path, 'rb') as f:
						data = f.read()

					asset = Asset(
						asset_id=asset_id,
						asset_type=asset_type,
						name=file_path.stem,
						file_path=file_path,
						checksum=self.calculate_checksum(data),
						metadata={
							'file_size': len(data),
							'scanned_date': datetime.now().isoformat()
						},
						last_modified=datetime.fromtimestamp(file_path.stat().st_mtime)
					)

					self.catalog.assets[asset_id] = asset

					if self.verbose:
						print(f"  Found {asset.name} ({asset_type.value})")

				except Exception as e:
					if self.verbose:
						print(f"  Error reading {file_path}: {e}")

	def validate_asset(self, asset: Asset) -> Tuple[bool, List[str]]:
		"""Validate asset integrity"""
		issues = []

		# Check if file exists
		if asset.file_path and not asset.file_path.exists():
			issues.append(f"File not found: {asset.file_path}")

		# Verify checksum
		if asset.file_path and asset.checksum:
			try:
				with open(asset.file_path, 'rb') as f:
					data = f.read()
				current_checksum = self.calculate_checksum(data)

				if current_checksum != asset.checksum:
					issues.append(f"Checksum mismatch (expected {asset.checksum[:8]}, got {current_checksum[:8]})")
			except Exception as e:
				issues.append(f"Error reading file: {e}")

		# Type-specific validation
		if asset.asset_type == AssetType.PALETTE:
			if asset.file_path:
				try:
					with open(asset.file_path, 'rb') as f:
						data = f.read()
					if len(data) != 32:
						issues.append(f"Invalid palette size: {len(data)} (expected 32)")
				except Exception:
					pass

		elif asset.asset_type == AssetType.GRAPHICS:
			if asset.file_path:
				try:
					with open(asset.file_path, 'rb') as f:
						data = f.read()
					if len(data) % 32 != 0:
						issues.append(f"Graphics data not aligned to 32 bytes")
				except Exception:
					pass

		return (len(issues) == 0, issues)

	def generate_asset_report(self) -> str:
		"""Generate asset inventory report"""
		lines = [
			"# Asset Inventory Report",
			"",
			f"**Project:** {self.catalog.project_name}",
			f"**Version:** {self.catalog.version}",
			f"**Base ROM:** {self.catalog.base_rom}",
			"",
			"## Summary",
			"",
			f"- Total Assets: {len(self.catalog.assets)}",
			""
		]

		# Count by type
		type_counts = {}
		for asset in self.catalog.assets.values():
			type_counts[asset.asset_type] = type_counts.get(asset.asset_type, 0) + 1

		lines.append("### Assets by Type")
		lines.append("")
		for asset_type, count in sorted(type_counts.items(), key=lambda x: x[1], reverse=True):
			lines.append(f"- **{asset_type.value}**: {count}")

		lines.append("")
		lines.append("## Asset Details")
		lines.append("")

		# Group by type
		for asset_type in AssetType:
			type_assets = [a for a in self.catalog.assets.values() if a.asset_type == asset_type]
			if not type_assets:
				continue

			lines.append(f"### {asset_type.value.title()}")
			lines.append("")
			lines.append("| ID | Name | Location | Size | Checksum |")
			lines.append("|----|------|----------|------|----------|")

			for asset in sorted(type_assets, key=lambda a: a.name):
				location = ""
				if asset.rom_offset is not None:
					location = f"ROM:0x{asset.rom_offset:06X}"
				elif asset.file_path:
					location = str(asset.file_path.name)

				size_str = ""
				if asset.rom_size:
					size_str = f"{asset.rom_size} bytes"
				elif asset.file_path and asset.file_path.exists():
					size_str = f"{asset.file_path.stat().st_size} bytes"

				checksum = asset.checksum[:8] if asset.checksum else "N/A"

				lines.append(f"| {asset.asset_id} | {asset.name} | {location} | {size_str} | {checksum} |")

			lines.append("")

		return '\n'.join(lines)

	def save_catalog(self, output_path: Path) -> None:
		"""Save asset catalog to JSON"""
		data = {
			'project_name': self.catalog.project_name,
			'version': self.catalog.version,
			'base_rom': str(self.catalog.base_rom) if self.catalog.base_rom else None,
			'assets': [
				{
					'asset_id': asset.asset_id,
					'asset_type': asset.asset_type.value,
					'name': asset.name,
					'rom_offset': asset.rom_offset,
					'rom_size': asset.rom_size,
					'file_path': str(asset.file_path) if asset.file_path else None,
					'compression': asset.compression.value,
					'checksum': asset.checksum,
					'metadata': asset.metadata,
					'dependencies': asset.dependencies,
					'last_modified': asset.last_modified.isoformat() if asset.last_modified else None
				}
				for asset in self.catalog.assets.values()
			]
		}

		with open(output_path, 'w') as f:
			json.dump(data, f, indent=2)

		if self.verbose:
			print(f"Saved catalog to {output_path}")

	def load_catalog(self, catalog_path: Path) -> None:
		"""Load asset catalog from JSON"""
		with open(catalog_path) as f:
			data = json.load(f)

		self.catalog.project_name = data['project_name']
		self.catalog.version = data['version']
		self.catalog.base_rom = Path(data['base_rom']) if data['base_rom'] else None

		for asset_data in data['assets']:
			asset = Asset(
				asset_id=asset_data['asset_id'],
				asset_type=AssetType(asset_data['asset_type']),
				name=asset_data['name'],
				rom_offset=asset_data.get('rom_offset'),
				rom_size=asset_data.get('rom_size'),
				file_path=Path(asset_data['file_path']) if asset_data.get('file_path') else None,
				compression=CompressionType(asset_data.get('compression', 'none')),
				checksum=asset_data.get('checksum'),
				metadata=asset_data.get('metadata', {}),
				dependencies=asset_data.get('dependencies', []),
				last_modified=datetime.fromisoformat(asset_data['last_modified']) if asset_data.get('last_modified') else None
			)
			self.catalog.assets[asset.asset_id] = asset

		if self.verbose:
			print(f"Loaded {len(self.catalog.assets)} assets from {catalog_path}")


def main():
	parser = argparse.ArgumentParser(description='Manage ROM hacking project assets')
	parser.add_argument('--index', type=Path, help='Index ROM file')
	parser.add_argument('--scan', type=Path, help='Scan asset directory')
	parser.add_argument('--extract', choices=['graphics', 'music', 'text', 'all'], help='Extract assets')
	parser.add_argument('--offset', type=lambda x: int(x, 0), help='ROM offset (hex)')
	parser.add_argument('--size', type=lambda x: int(x, 0), help='Asset size (hex)')
	parser.add_argument('--validate', type=Path, help='Validate assets in directory')
	parser.add_argument('--output', type=Path, help='Output file/directory')
	parser.add_argument('--report', type=Path, help='Generate asset report')
	parser.add_argument('--load', type=Path, help='Load asset catalog')
	parser.add_argument('--save', type=Path, help='Save asset catalog')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')

	args = parser.parse_args()

	manager = AssetManager(verbose=args.verbose)

	# Load existing catalog
	if args.load:
		manager.load_catalog(args.load)

	# Index ROM
	if args.index:
		manager.index_rom(args.index)

	# Scan directory
	if args.scan:
		manager.scan_asset_directory(args.scan)

	# Extract specific asset
	if args.extract and args.offset is not None and args.size is not None:
		if args.index:
			asset_type_map = {
				'graphics': AssetType.GRAPHICS,
				'music': AssetType.MUSIC,
				'text': AssetType.TEXT
			}
			asset_type = asset_type_map.get(args.extract)

			asset = manager.extract_asset(args.index, args.offset, args.size, asset_type)
			print(f"✓ Extracted {asset.name}")
			print(f"  Type: {asset.asset_type.value}")
			print(f"  Size: {asset.rom_size} bytes")
			print(f"  Checksum: {asset.checksum[:16]}")

	# Validate assets
	if args.validate:
		manager.scan_asset_directory(args.validate)

		print("\nValidating assets...")
		total = len(manager.catalog.assets)
		valid = 0

		for asset in manager.catalog.assets.values():
			is_valid, issues = manager.validate_asset(asset)
			if is_valid:
				valid += 1
			else:
				print(f"✗ {asset.name}:")
				for issue in issues:
					print(f"  - {issue}")

		print(f"\nValidation: {valid}/{total} assets valid")

	# Generate report
	if args.report:
		report = manager.generate_asset_report()
		with open(args.report, 'w') as f:
			f.write(report)
		print(f"✓ Asset report saved to {args.report}")

	# Save catalog
	if args.save:
		manager.save_catalog(args.save)

	# Print summary
	if manager.catalog.assets:
		print(f"\n=== Summary ===")
		print(f"Total assets: {len(manager.catalog.assets)}")

	return 0


if __name__ == '__main__':
	exit(main())
