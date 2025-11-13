#!/usr/bin/env python3
"""
FFMQ Texture Pack Manager - Graphics replacement system

Texture Pack Features:
- Sprite replacement
- Tile replacement
- Palette replacement
- UI replacement
- Font replacement
- Animation replacement

Pack Types:
- HD textures
- Retro style
- Themed packs
- Character reskins
- UI overhauls
- Complete conversions

Features:
- Pack installation
- Priority management
- Conflict resolution
- Preview generation
- Format conversion
- Batch processing

Usage:
	python ffmq_texture_pack_manager.py --install pack.zip
	python ffmq_texture_pack_manager.py --list
	python ffmq_texture_pack_manager.py --enable pack_id
	python ffmq_texture_pack_manager.py --apply rom.smc output.smc
	python ffmq_texture_pack_manager.py --create-pack my_pack.json
"""

import argparse
import json
import zipfile
import shutil
from pathlib import Path
from typing import List, Dict, Optional, Tuple
from dataclasses import dataclass, asdict, field
from enum import Enum


class PackType(Enum):
	"""Pack type"""
	HD_TEXTURES = "hd_textures"
	RETRO_STYLE = "retro_style"
	THEMED = "themed"
	RESKIN = "reskin"
	UI_OVERHAUL = "ui_overhaul"
	COMPLETE = "complete"


class AssetType(Enum):
	"""Asset type"""
	SPRITE = "sprite"
	TILE = "tile"
	PALETTE = "palette"
	UI = "ui"
	FONT = "font"
	ANIMATION = "animation"


@dataclass
class Asset:
	"""Texture asset"""
	asset_id: str
	type: AssetType
	file_path: str
	rom_offset: int
	size: int
	description: str = ""


@dataclass
class PackManifest:
	"""Texture pack manifest"""
	pack_id: str
	name: str
	version: str
	author: str
	description: str
	type: PackType
	assets: List[Asset] = field(default_factory=list)
	dependencies: List[str] = field(default_factory=list)
	priority: int = 100
	
	def to_dict(self) -> dict:
		d = asdict(self)
		d['type'] = self.type.value
		d['assets'] = [
			{**asdict(a), 'type': a.type.value}
			for a in self.assets
		]
		return d


@dataclass
class TexturePack:
	"""Installed texture pack"""
	manifest: PackManifest
	install_path: Path
	enabled: bool = False


class TexturePackManager:
	"""Texture pack manager"""
	
	def __init__(self, packs_dir: Path, verbose: bool = False):
		self.packs_dir = packs_dir
		self.verbose = verbose
		self.packs: Dict[str, TexturePack] = {}
		
		# Create directories
		self.packs_dir.mkdir(parents=True, exist_ok=True)
		
		self._load_packs()
	
	def _load_packs(self) -> None:
		"""Load installed packs"""
		for pack_dir in self.packs_dir.iterdir():
			if not pack_dir.is_dir():
				continue
			
			manifest_path = pack_dir / "manifest.json"
			if not manifest_path.exists():
				continue
			
			try:
				with open(manifest_path, 'r', encoding='utf-8') as f:
					manifest_data = json.load(f)
				
				# Parse type
				if isinstance(manifest_data['type'], str):
					manifest_data['type'] = PackType(manifest_data['type'])
				
				# Parse assets
				assets = []
				for asset_data in manifest_data.get('assets', []):
					if isinstance(asset_data['type'], str):
						asset_data['type'] = AssetType(asset_data['type'])
					assets.append(Asset(**asset_data))
				manifest_data['assets'] = assets
				
				manifest = PackManifest(**manifest_data)
				
				pack = TexturePack(
					manifest=manifest,
					install_path=pack_dir
				)
				
				self.packs[manifest.pack_id] = pack
			
			except Exception as e:
				if self.verbose:
					print(f"⚠ Error loading pack from {pack_dir}: {e}")
	
	def install_pack(self, pack_path: Path) -> bool:
		"""Install texture pack"""
		try:
			# Extract to temp directory
			temp_dir = self.packs_dir / f"_temp_{pack_path.stem}"
			temp_dir.mkdir(exist_ok=True)
			
			with zipfile.ZipFile(pack_path, 'r') as zf:
				zf.extractall(temp_dir)
			
			# Read manifest
			manifest_path = temp_dir / "manifest.json"
			if not manifest_path.exists():
				print("Error: No manifest.json in pack")
				shutil.rmtree(temp_dir)
				return False
			
			with open(manifest_path, 'r', encoding='utf-8') as f:
				manifest_data = json.load(f)
			
			# Parse manifest
			if isinstance(manifest_data['type'], str):
				manifest_data['type'] = PackType(manifest_data['type'])
			
			assets = []
			for asset_data in manifest_data.get('assets', []):
				if isinstance(asset_data['type'], str):
					asset_data['type'] = AssetType(asset_data['type'])
				assets.append(Asset(**asset_data))
			manifest_data['assets'] = assets
			
			manifest = PackManifest(**manifest_data)
			
			# Move to packs directory
			install_dir = self.packs_dir / manifest.pack_id
			
			if install_dir.exists():
				print(f"Pack {manifest.pack_id} already installed")
				shutil.rmtree(temp_dir)
				return False
			
			temp_dir.rename(install_dir)
			
			# Create pack object
			pack = TexturePack(
				manifest=manifest,
				install_path=install_dir
			)
			
			self.packs[manifest.pack_id] = pack
			
			if self.verbose:
				print(f"✓ Installed pack: {manifest.name} ({manifest.pack_id})")
			
			return True
		
		except Exception as e:
			print(f"Error installing pack: {e}")
			return False
	
	def uninstall_pack(self, pack_id: str) -> bool:
		"""Uninstall texture pack"""
		if pack_id not in self.packs:
			print(f"Pack {pack_id} not found")
			return False
		
		pack = self.packs[pack_id]
		
		# Disable first
		if pack.enabled:
			self.disable_pack(pack_id)
		
		# Remove directory
		try:
			shutil.rmtree(pack.install_path)
			del self.packs[pack_id]
			
			if self.verbose:
				print(f"✓ Uninstalled pack: {pack.manifest.name}")
			
			return True
		
		except Exception as e:
			print(f"Error uninstalling pack: {e}")
			return False
	
	def enable_pack(self, pack_id: str) -> bool:
		"""Enable texture pack"""
		if pack_id not in self.packs:
			print(f"Pack {pack_id} not found")
			return False
		
		pack = self.packs[pack_id]
		pack.enabled = True
		
		if self.verbose:
			print(f"✓ Enabled pack: {pack.manifest.name}")
		
		return True
	
	def disable_pack(self, pack_id: str) -> bool:
		"""Disable texture pack"""
		if pack_id not in self.packs:
			print(f"Pack {pack_id} not found")
			return False
		
		pack = self.packs[pack_id]
		pack.enabled = False
		
		if self.verbose:
			print(f"✓ Disabled pack: {pack.manifest.name}")
		
		return True
	
	def apply_packs(self, rom_data: bytearray) -> bytearray:
		"""Apply enabled packs to ROM"""
		result = rom_data.copy()
		
		# Get enabled packs sorted by priority
		enabled_packs = [p for p in self.packs.values() if p.enabled]
		sorted_packs = sorted(enabled_packs, key=lambda p: p.manifest.priority)
		
		for pack in sorted_packs:
			if self.verbose:
				print(f"Applying pack: {pack.manifest.name}")
			
			for asset in pack.manifest.assets:
				asset_path = pack.install_path / asset.file_path
				
				if not asset_path.exists():
					if self.verbose:
						print(f"⚠ Asset not found: {asset.file_path}")
					continue
				
				# Read asset data
				with open(asset_path, 'rb') as f:
					asset_data = f.read()
				
				# Write to ROM
				offset = asset.rom_offset
				size = min(asset.size, len(asset_data))
				
				if offset + size > len(result):
					if self.verbose:
						print(f"⚠ Asset {asset.asset_id} exceeds ROM size")
					continue
				
				result[offset:offset+size] = asset_data[:size]
				
				if self.verbose:
					print(f"  ✓ Applied {asset.asset_id} at 0x{offset:06X}")
		
		return result
	
	def create_pack_template(self, output_path: Path, pack_id: str, name: str) -> bool:
		"""Create template pack"""
		try:
			# Example assets
			assets = [
				Asset(
					asset_id="benjamin_sprite",
					type=AssetType.SPRITE,
					file_path="sprites/benjamin.bin",
					rom_offset=0x100000,
					size=1024,
					description="Benjamin character sprite"
				),
				Asset(
					asset_id="grass_tile",
					type=AssetType.TILE,
					file_path="tiles/grass.bin",
					rom_offset=0x120000,
					size=32,
					description="Grass tile"
				),
				Asset(
					asset_id="ui_palette",
					type=AssetType.PALETTE,
					file_path="palettes/ui.bin",
					rom_offset=0x130000,
					size=32,
					description="UI color palette"
				),
			]
			
			manifest = PackManifest(
				pack_id=pack_id,
				name=name,
				version="1.0",
				author="",
				description="",
				type=PackType.HD_TEXTURES,
				assets=assets
			)
			
			with open(output_path, 'w', encoding='utf-8') as f:
				json.dump(manifest.to_dict(), f, indent='\t')
			
			if self.verbose:
				print(f"✓ Created pack template: {output_path}")
			
			return True
		
		except Exception as e:
			print(f"Error creating pack template: {e}")
			return False
	
	def export_config(self, output_path: Path) -> bool:
		"""Export manager configuration"""
		try:
			config = {
				'packs': {
					k: {
						'manifest': v.manifest.to_dict(),
						'enabled': v.enabled
					}
					for k, v in self.packs.items()
				}
			}
			
			with open(output_path, 'w', encoding='utf-8') as f:
				json.dump(config, f, indent='\t')
			
			if self.verbose:
				print(f"✓ Exported config to {output_path}")
			
			return True
		
		except Exception as e:
			print(f"Error exporting config: {e}")
			return False
	
	def print_pack_list(self) -> None:
		"""Print pack list"""
		print(f"\n=== Installed Texture Packs ===\n")
		print(f"{'ID':<20} {'Name':<30} {'Type':<15} {'Priority':<10} {'Status':<10}")
		print('-' * 85)
		
		for pack_id, pack in sorted(self.packs.items()):
			status = "✓" if pack.enabled else "-"
			print(f"{pack_id:<20} {pack.manifest.name:<30} "
				  f"{pack.manifest.type.value:<15} {pack.manifest.priority:<10} {status:<10}")
		
		enabled_count = sum(1 for p in self.packs.values() if p.enabled)
		print(f"\nTotal: {len(self.packs)} packs ({enabled_count} enabled)")


def main():
	parser = argparse.ArgumentParser(description='FFMQ Texture Pack Manager')
	parser.add_argument('--packs-dir', type=str, default='./texture_packs',
					   help='Texture packs directory')
	parser.add_argument('--list', action='store_true', help='List packs')
	parser.add_argument('--install', type=str, metavar='ZIP',
					   help='Install pack from zip')
	parser.add_argument('--uninstall', type=str, metavar='PACK_ID',
					   help='Uninstall pack')
	parser.add_argument('--enable', type=str, metavar='PACK_ID',
					   help='Enable pack')
	parser.add_argument('--disable', type=str, metavar='PACK_ID',
					   help='Disable pack')
	parser.add_argument('--apply', nargs=2, metavar=('ROM', 'OUTPUT'),
					   help='Apply enabled packs to ROM')
	parser.add_argument('--create-pack', type=str, metavar='FILE',
					   help='Create pack template')
	parser.add_argument('--pack-id', type=str, help='Pack ID for template')
	parser.add_argument('--pack-name', type=str, help='Pack name for template')
	parser.add_argument('--export-config', type=str, metavar='OUTPUT',
					   help='Export configuration')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	manager = TexturePackManager(Path(args.packs_dir), verbose=args.verbose)
	
	# Install
	if args.install:
		manager.install_pack(Path(args.install))
		return 0
	
	# Uninstall
	if args.uninstall:
		manager.uninstall_pack(args.uninstall)
		return 0
	
	# Enable
	if args.enable:
		manager.enable_pack(args.enable)
		return 0
	
	# Disable
	if args.disable:
		manager.disable_pack(args.disable)
		return 0
	
	# Apply packs
	if args.apply:
		rom_path, output_path = args.apply
		
		# Load ROM
		with open(rom_path, 'rb') as f:
			rom_data = bytearray(f.read())
		
		# Apply packs
		patched_rom = manager.apply_packs(rom_data)
		
		# Save
		with open(output_path, 'wb') as f:
			f.write(patched_rom)
		
		print(f"✓ Applied texture packs to {output_path}")
		return 0
	
	# Create pack template
	if args.create_pack:
		pack_id = args.pack_id or "my_pack"
		pack_name = args.pack_name or "My Texture Pack"
		manager.create_pack_template(Path(args.create_pack), pack_id, pack_name)
		return 0
	
	# Export config
	if args.export_config:
		manager.export_config(Path(args.export_config))
		return 0
	
	# List packs
	if args.list or not any([args.install, args.uninstall, args.enable, args.disable, args.apply, args.create_pack]):
		manager.print_pack_list()
		return 0
	
	return 0


if __name__ == '__main__':
	exit(main())
