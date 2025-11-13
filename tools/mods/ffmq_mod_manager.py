#!/usr/bin/env python3
"""
FFMQ Mod Manager - Mod installation and management

Mod Features:
- Mod installation
- Dependency resolution
- Conflict detection
- Load order management
- Mod configuration
- Asset replacement

Mod Types:
- Content mods
- Gameplay mods
- Graphics mods
- Audio mods
- UI mods
- Total conversions

Mod Structure:
- Manifest (JSON)
- Assets (graphics/audio/data)
- Patches (IPS/UPS)
- Scripts (custom code)
- Configuration

Features:
- Install/uninstall mods
- Manage dependencies
- Detect conflicts
- Configure load order
- Backup original files
- Mod profiles

Usage:
	python ffmq_mod_manager.py --list
	python ffmq_mod_manager.py --install mod.zip
	python ffmq_mod_manager.py --enable mod_id
	python ffmq_mod_manager.py --disable mod_id
	python ffmq_mod_manager.py --profile create "My Profile"
	python ffmq_mod_manager.py --export-config config.json
"""

import argparse
import json
import zipfile
import shutil
from pathlib import Path
from typing import List, Dict, Optional, Set
from dataclasses import dataclass, asdict, field
from enum import Enum


class ModType(Enum):
	"""Mod type"""
	CONTENT = "content"
	GAMEPLAY = "gameplay"
	GRAPHICS = "graphics"
	AUDIO = "audio"
	UI = "ui"
	TOTAL_CONVERSION = "total_conversion"


class ModStatus(Enum):
	"""Mod status"""
	INSTALLED = "installed"
	ENABLED = "enabled"
	DISABLED = "disabled"
	ERROR = "error"


@dataclass
class ModDependency:
	"""Mod dependency"""
	mod_id: str
	version: str = "*"
	optional: bool = False


@dataclass
class ModConflict:
	"""Mod conflict"""
	mod_id: str
	reason: str = ""


@dataclass
class ModManifest:
	"""Mod manifest"""
	mod_id: str
	name: str
	version: str
	author: str
	description: str
	type: ModType
	dependencies: List[ModDependency] = field(default_factory=list)
	conflicts: List[ModConflict] = field(default_factory=list)
	load_priority: int = 100
	assets: List[str] = field(default_factory=list)
	patches: List[str] = field(default_factory=list)
	scripts: List[str] = field(default_factory=list)
	
	def to_dict(self) -> dict:
		d = asdict(self)
		d['type'] = self.type.value
		return d


@dataclass
class Mod:
	"""Installed mod"""
	manifest: ModManifest
	install_path: Path
	status: ModStatus = ModStatus.INSTALLED
	enabled: bool = False
	
	def to_dict(self) -> dict:
		return {
			'manifest': self.manifest.to_dict(),
			'install_path': str(self.install_path),
			'status': self.status.value,
			'enabled': self.enabled
		}


@dataclass
class ModProfile:
	"""Mod profile"""
	profile_id: str
	name: str
	description: str = ""
	enabled_mods: List[str] = field(default_factory=list)
	load_order: List[str] = field(default_factory=list)


class ModManager:
	"""Mod manager"""
	
	def __init__(self, mods_dir: Path, verbose: bool = False):
		self.mods_dir = mods_dir
		self.verbose = verbose
		self.mods: Dict[str, Mod] = {}
		self.profiles: Dict[str, ModProfile] = {}
		self.active_profile: Optional[str] = None
		
		# Create directories
		self.mods_dir.mkdir(parents=True, exist_ok=True)
		self.backups_dir = self.mods_dir / "backups"
		self.backups_dir.mkdir(exist_ok=True)
		
		self._load_mods()
	
	def _load_mods(self) -> None:
		"""Load installed mods"""
		for mod_dir in self.mods_dir.iterdir():
			if not mod_dir.is_dir():
				continue
			
			if mod_dir.name in ['backups', 'profiles']:
				continue
			
			manifest_path = mod_dir / "manifest.json"
			if not manifest_path.exists():
				continue
			
			try:
				with open(manifest_path, 'r', encoding='utf-8') as f:
					manifest_data = json.load(f)
				
				# Parse dependencies
				deps = []
				for dep_data in manifest_data.get('dependencies', []):
					if isinstance(dep_data, dict):
						deps.append(ModDependency(**dep_data))
					else:
						deps.append(ModDependency(mod_id=dep_data))
				manifest_data['dependencies'] = deps
				
				# Parse conflicts
				conflicts = []
				for conflict_data in manifest_data.get('conflicts', []):
					if isinstance(conflict_data, dict):
						conflicts.append(ModConflict(**conflict_data))
					else:
						conflicts.append(ModConflict(mod_id=conflict_data))
				manifest_data['conflicts'] = conflicts
				
				# Parse type
				if isinstance(manifest_data['type'], str):
					manifest_data['type'] = ModType(manifest_data['type'])
				
				manifest = ModManifest(**manifest_data)
				
				mod = Mod(
					manifest=manifest,
					install_path=mod_dir,
					status=ModStatus.INSTALLED
				)
				
				self.mods[manifest.mod_id] = mod
			
			except Exception as e:
				if self.verbose:
					print(f"⚠ Error loading mod from {mod_dir}: {e}")
	
	def install_mod(self, mod_path: Path) -> bool:
		"""Install mod from zip file"""
		try:
			# Extract to temp directory
			temp_dir = self.mods_dir / f"_temp_{mod_path.stem}"
			temp_dir.mkdir(exist_ok=True)
			
			with zipfile.ZipFile(mod_path, 'r') as zf:
				zf.extractall(temp_dir)
			
			# Read manifest
			manifest_path = temp_dir / "manifest.json"
			if not manifest_path.exists():
				print("Error: No manifest.json in mod")
				shutil.rmtree(temp_dir)
				return False
			
			with open(manifest_path, 'r', encoding='utf-8') as f:
				manifest_data = json.load(f)
			
			# Parse manifest
			deps = []
			for dep_data in manifest_data.get('dependencies', []):
				if isinstance(dep_data, dict):
					deps.append(ModDependency(**dep_data))
				else:
					deps.append(ModDependency(mod_id=dep_data))
			manifest_data['dependencies'] = deps
			
			conflicts = []
			for conflict_data in manifest_data.get('conflicts', []):
				if isinstance(conflict_data, dict):
					conflicts.append(ModConflict(**conflict_data))
				else:
					conflicts.append(ModConflict(mod_id=conflict_data))
			manifest_data['conflicts'] = conflicts
			
			if isinstance(manifest_data['type'], str):
				manifest_data['type'] = ModType(manifest_data['type'])
			
			manifest = ModManifest(**manifest_data)
			
			# Move to mods directory
			install_dir = self.mods_dir / manifest.mod_id
			
			if install_dir.exists():
				print(f"Mod {manifest.mod_id} already installed")
				shutil.rmtree(temp_dir)
				return False
			
			temp_dir.rename(install_dir)
			
			# Create mod object
			mod = Mod(
				manifest=manifest,
				install_path=install_dir,
				status=ModStatus.INSTALLED
			)
			
			self.mods[manifest.mod_id] = mod
			
			if self.verbose:
				print(f"✓ Installed mod: {manifest.name} ({manifest.mod_id})")
			
			return True
		
		except Exception as e:
			print(f"Error installing mod: {e}")
			return False
	
	def uninstall_mod(self, mod_id: str) -> bool:
		"""Uninstall mod"""
		if mod_id not in self.mods:
			print(f"Mod {mod_id} not found")
			return False
		
		mod = self.mods[mod_id]
		
		# Disable first
		if mod.enabled:
			self.disable_mod(mod_id)
		
		# Remove directory
		try:
			shutil.rmtree(mod.install_path)
			del self.mods[mod_id]
			
			if self.verbose:
				print(f"✓ Uninstalled mod: {mod.manifest.name}")
			
			return True
		
		except Exception as e:
			print(f"Error uninstalling mod: {e}")
			return False
	
	def enable_mod(self, mod_id: str) -> bool:
		"""Enable mod"""
		if mod_id not in self.mods:
			print(f"Mod {mod_id} not found")
			return False
		
		mod = self.mods[mod_id]
		
		# Check dependencies
		for dep in mod.manifest.dependencies:
			if dep.optional:
				continue
			
			if dep.mod_id not in self.mods:
				print(f"Error: Missing dependency {dep.mod_id}")
				return False
			
			dep_mod = self.mods[dep.mod_id]
			if not dep_mod.enabled:
				print(f"Error: Dependency {dep.mod_id} not enabled")
				return False
		
		# Check conflicts
		for conflict in mod.manifest.conflicts:
			if conflict.mod_id in self.mods:
				conflict_mod = self.mods[conflict.mod_id]
				if conflict_mod.enabled:
					print(f"Error: Conflicts with {conflict.mod_id}: {conflict.reason}")
					return False
		
		mod.enabled = True
		mod.status = ModStatus.ENABLED
		
		if self.verbose:
			print(f"✓ Enabled mod: {mod.manifest.name}")
		
		return True
	
	def disable_mod(self, mod_id: str) -> bool:
		"""Disable mod"""
		if mod_id not in self.mods:
			print(f"Mod {mod_id} not found")
			return False
		
		mod = self.mods[mod_id]
		
		# Check if other mods depend on this
		for other_id, other_mod in self.mods.items():
			if not other_mod.enabled:
				continue
			
			for dep in other_mod.manifest.dependencies:
				if dep.mod_id == mod_id and not dep.optional:
					print(f"Error: {other_id} depends on this mod")
					return False
		
		mod.enabled = False
		mod.status = ModStatus.DISABLED
		
		if self.verbose:
			print(f"✓ Disabled mod: {mod.manifest.name}")
		
		return True
	
	def get_load_order(self) -> List[str]:
		"""Get mod load order"""
		enabled = [m for m in self.mods.values() if m.enabled]
		
		# Sort by priority
		sorted_mods = sorted(enabled, key=lambda m: m.manifest.load_priority)
		
		return [m.manifest.mod_id for m in sorted_mods]
	
	def create_profile(self, profile_id: str, name: str, description: str = "") -> bool:
		"""Create mod profile"""
		if profile_id in self.profiles:
			print(f"Profile {profile_id} already exists")
			return False
		
		profile = ModProfile(
			profile_id=profile_id,
			name=name,
			description=description
		)
		
		self.profiles[profile_id] = profile
		
		if self.verbose:
			print(f"✓ Created profile: {name}")
		
		return True
	
	def save_profile(self, profile_id: str) -> bool:
		"""Save current state to profile"""
		if profile_id not in self.profiles:
			print(f"Profile {profile_id} not found")
			return False
		
		profile = self.profiles[profile_id]
		profile.enabled_mods = [m.manifest.mod_id for m in self.mods.values() if m.enabled]
		profile.load_order = self.get_load_order()
		
		# Save to file
		profiles_dir = self.mods_dir / "profiles"
		profiles_dir.mkdir(exist_ok=True)
		
		profile_path = profiles_dir / f"{profile_id}.json"
		with open(profile_path, 'w', encoding='utf-8') as f:
			json.dump(asdict(profile), f, indent='\t')
		
		if self.verbose:
			print(f"✓ Saved profile: {profile.name}")
		
		return True
	
	def load_profile(self, profile_id: str) -> bool:
		"""Load profile"""
		profiles_dir = self.mods_dir / "profiles"
		profile_path = profiles_dir / f"{profile_id}.json"
		
		if not profile_path.exists():
			print(f"Profile {profile_id} not found")
			return False
		
		try:
			with open(profile_path, 'r', encoding='utf-8') as f:
				profile_data = json.load(f)
			
			profile = ModProfile(**profile_data)
			self.profiles[profile_id] = profile
			self.active_profile = profile_id
			
			# Disable all mods
			for mod in self.mods.values():
				mod.enabled = False
				mod.status = ModStatus.DISABLED
			
			# Enable mods from profile
			for mod_id in profile.enabled_mods:
				if mod_id in self.mods:
					self.enable_mod(mod_id)
			
			if self.verbose:
				print(f"✓ Loaded profile: {profile.name}")
			
			return True
		
		except Exception as e:
			print(f"Error loading profile: {e}")
			return False
	
	def export_config(self, output_path: Path) -> bool:
		"""Export manager configuration"""
		try:
			config = {
				'mods': {k: v.to_dict() for k, v in self.mods.items()},
				'profiles': {k: asdict(v) for k, v in self.profiles.items()},
				'active_profile': self.active_profile
			}
			
			with open(output_path, 'w', encoding='utf-8') as f:
				json.dump(config, f, indent='\t')
			
			if self.verbose:
				print(f"✓ Exported config to {output_path}")
			
			return True
		
		except Exception as e:
			print(f"Error exporting config: {e}")
			return False
	
	def print_mod_list(self) -> None:
		"""Print mod list"""
		print(f"\n=== Installed Mods ===\n")
		print(f"{'ID':<20} {'Name':<30} {'Version':<10} {'Status':<10}")
		print('-' * 70)
		
		for mod_id, mod in sorted(self.mods.items()):
			status = "✓" if mod.enabled else "-"
			print(f"{mod_id:<20} {mod.manifest.name:<30} "
				  f"{mod.manifest.version:<10} {status:<10}")
		
		print(f"\nTotal: {len(self.mods)} mods ({sum(1 for m in self.mods.values() if m.enabled)} enabled)")


def main():
	parser = argparse.ArgumentParser(description='FFMQ Mod Manager')
	parser.add_argument('--mods-dir', type=str, default='./mods',
					   help='Mods directory')
	parser.add_argument('--list', action='store_true', help='List mods')
	parser.add_argument('--install', type=str, metavar='ZIP',
					   help='Install mod from zip')
	parser.add_argument('--uninstall', type=str, metavar='MOD_ID',
					   help='Uninstall mod')
	parser.add_argument('--enable', type=str, metavar='MOD_ID',
					   help='Enable mod')
	parser.add_argument('--disable', type=str, metavar='MOD_ID',
					   help='Disable mod')
	parser.add_argument('--profile', type=str, nargs='+',
					   help='Profile command: create/save/load ID [NAME]')
	parser.add_argument('--export-config', type=str, metavar='OUTPUT',
					   help='Export configuration')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	manager = ModManager(Path(args.mods_dir), verbose=args.verbose)
	
	# Install
	if args.install:
		manager.install_mod(Path(args.install))
		return 0
	
	# Uninstall
	if args.uninstall:
		manager.uninstall_mod(args.uninstall)
		return 0
	
	# Enable
	if args.enable:
		manager.enable_mod(args.enable)
		return 0
	
	# Disable
	if args.disable:
		manager.disable_mod(args.disable)
		return 0
	
	# Profile
	if args.profile:
		cmd = args.profile[0]
		
		if cmd == 'create' and len(args.profile) >= 3:
			profile_id = args.profile[1]
			name = ' '.join(args.profile[2:])
			manager.create_profile(profile_id, name)
		
		elif cmd == 'save' and len(args.profile) >= 2:
			manager.save_profile(args.profile[1])
		
		elif cmd == 'load' and len(args.profile) >= 2:
			manager.load_profile(args.profile[1])
		
		return 0
	
	# Export config
	if args.export_config:
		manager.export_config(Path(args.export_config))
		return 0
	
	# List mods
	if args.list or not any([args.install, args.uninstall, args.enable, args.disable, args.profile]):
		manager.print_mod_list()
		return 0
	
	return 0


if __name__ == '__main__':
	exit(main())
