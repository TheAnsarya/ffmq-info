#!/usr/bin/env python3
"""
FFMQ ROM Build Orchestrator
Manages incremental builds, asset change detection, and ROM verification
"""

import sys
import os
import subprocess
import hashlib
import json
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from datetime import datetime

class ROMBuilder:
	"""Orchestrate ROM building with asset tracking and verification"""
	
	EXPECTED_ROM_HASH = "F71817F55FEBD32FD1DCE617A326A77B6B062DD0D4058ECD289F64AF1B7A1D05"
	
	def __init__(self, project_root: str = "."):
		self.project_root = Path(project_root)
		self.build_dir = self.project_root / 'build'
		self.src_dir = self.project_root / 'src'
		self.data_dir = self.project_root / 'data'
		self.assets_dir = self.project_root / 'assets'
		self.cache_file = self.build_dir / 'build_cache.json'
		self.cache = {}
		
	def load_cache(self) -> bool:
		"""Load build cache to track file changes"""
		if not self.cache_file.exists():
			return False
			
		try:
			with open(self.cache_file, 'r', encoding='utf-8') as f:
				self.cache = json.load(f)
			return True
		except Exception as e:
			print(f"⚠️  Error loading cache: {e}")
			return False
	
	def save_cache(self) -> bool:
		"""Save build cache"""
		try:
			self.build_dir.mkdir(parents=True, exist_ok=True)
			with open(self.cache_file, 'w', encoding='utf-8') as f:
				json.dump(self.cache, f, indent=2)
			return True
		except Exception as e:
			print(f"⚠️  Error saving cache: {e}")
			return False
	
	def calculate_file_hash(self, file_path: Path) -> str:
		"""Calculate SHA256 hash of a file"""
		if not file_path.exists():
			return ""
			
		try:
			with open(file_path, 'rb') as f:
				return hashlib.sha256(f.read()).hexdigest()
		except Exception as e:
			print(f"⚠️  Error hashing {file_path}: {e}")
			return ""
	
	def scan_source_files(self) -> Dict[str, str]:
		"""Scan all source files and calculate hashes"""
		file_hashes = {}
		
		# Scan ASM files
		if self.src_dir.exists():
			for asm_file in self.src_dir.rglob('*.asm'):
				rel_path = str(asm_file.relative_to(self.project_root))
				file_hashes[rel_path] = self.calculate_file_hash(asm_file)
		
		# Scan data files
		if self.data_dir.exists():
			for data_file in self.data_dir.rglob('*'):
				if data_file.is_file() and not data_file.suffix == '.bak':
					rel_path = str(data_file.relative_to(self.project_root))
					file_hashes[rel_path] = self.calculate_file_hash(data_file)
		
		# Scan assets
		if self.assets_dir.exists():
			for asset_file in self.assets_dir.rglob('*'):
				if asset_file.is_file():
					rel_path = str(asset_file.relative_to(self.project_root))
					file_hashes[rel_path] = self.calculate_file_hash(asset_file)
		
		return file_hashes
	
	def detect_changes(self) -> Tuple[List[str], List[str], List[str]]:
		"""Detect changed, added, and removed files
		
		Returns:
			(changed, added, removed)
		"""
		current_files = self.scan_source_files()
		cached_files = self.cache.get('file_hashes', {})
		
		changed = []
		added = []
		removed = []
		
		# Check for changes and additions
		for file_path, current_hash in current_files.items():
			if file_path in cached_files:
				if cached_files[file_path] != current_hash:
					changed.append(file_path)
			else:
				added.append(file_path)
		
		# Check for removals
		for file_path in cached_files:
			if file_path not in current_files:
				removed.append(file_path)
		
		return changed, added, removed
	
	def needs_rebuild(self, force: bool = False) -> bool:
		"""Check if ROM needs to be rebuilt"""
		if force:
			return True
			
		# Check if ROM exists
		rom_file = self.build_dir / 'ffmq-rebuilt.sfc'
		if not rom_file.exists():
			return True
		
		# Load cache
		if not self.load_cache():
			# No cache = rebuild needed
			return True
		
		# Check for file changes
		changed, added, removed = self.detect_changes()
		
		if changed or added or removed:
			return True
		
		return False
	
	def run_build_script(self) -> bool:
		"""Run the PowerShell build script"""
		build_script = self.project_root / 'build.ps1'
		
		if not build_script.exists():
			print(f"❌ Build script not found: {build_script}")
			return False
		
		print("🔨 Running build script...")
		
		try:
			# Run PowerShell build script
			result = subprocess.run(
				['pwsh', '-File', str(build_script)],
				cwd=str(self.project_root),
				capture_output=True,
				text=True
			)
			
			# Show output
			if result.stdout:
				print(result.stdout)
			
			if result.returncode != 0:
				print(f"❌ Build failed with exit code {result.returncode}")
				if result.stderr:
					print(result.stderr)
				return False
			
			print("✅ Build completed successfully")
			return True
			
		except Exception as e:
			print(f"❌ Error running build script: {e}")
			return False
	
	def verify_rom(self) -> bool:
		"""Verify built ROM matches expected hash"""
		rom_file = self.build_dir / 'ffmq-rebuilt.sfc'
		
		if not rom_file.exists():
			print(f"❌ ROM file not found: {rom_file}")
			return False
		
		print("🔍 Verifying ROM hash...")
		
		rom_hash = self.calculate_file_hash(rom_file).upper()
		
		if rom_hash == self.EXPECTED_ROM_HASH:
			print(f"✅ ROM hash verified: {rom_hash}")
			return True
		else:
			print(f"❌ ROM hash mismatch!")
			print(f"   Expected: {self.EXPECTED_ROM_HASH}")
			print(f"   Got:      {rom_hash}")
			return False
	
	def update_cache(self) -> bool:
		"""Update build cache with current file states"""
		print("💾 Updating build cache...")
		
		self.cache = {
			'last_build': datetime.now().isoformat(),
			'file_hashes': self.scan_source_files(),
			'rom_hash': self.calculate_file_hash(self.build_dir / 'ffmq-rebuilt.sfc').upper()
		}
		
		return self.save_cache()
	
	def clean_build(self) -> bool:
		"""Clean build directory"""
		print("🧹 Cleaning build directory...")
		
		if self.build_dir.exists():
			# Remove specific build artifacts, keep cache
			artifacts = [
				'ffmq-rebuilt.sfc',
				'symbols.sym',
				'*.o',
				'*.obj'
			]
			
			for pattern in artifacts:
				for file_path in self.build_dir.glob(pattern):
					if file_path.is_file():
						file_path.unlink()
						print(f"  Removed: {file_path.name}")
		
		return True
	
	def build(self, force: bool = False, clean: bool = False, verify: bool = True) -> bool:
		"""Main build orchestration"""
		print("="*80)
		print(" FFMQ ROM Build Orchestrator")
		print("="*80)
		print()
		
		# Clean if requested
		if clean:
			self.clean_build()
			print()
		
		# Check if rebuild needed
		if not self.needs_rebuild(force):
			print("✅ ROM is up to date (no changes detected)")
			print()
			
			# Still verify if requested
			if verify:
				if self.verify_rom():
					return True
				else:
					print("⚠️  ROM verification failed, rebuilding...")
			else:
				return True
		
		# Show what changed
		if not force and self.load_cache():
			changed, added, removed = self.detect_changes()
			
			if changed:
				print(f"📝 Changed files: {len(changed)}")
				for f in changed[:5]:
					print(f"  • {f}")
				if len(changed) > 5:
					print(f"  ... and {len(changed) - 5} more")
				print()
			
			if added:
				print(f"➕ Added files: {len(added)}")
				for f in added[:5]:
					print(f"  • {f}")
				if len(added) > 5:
					print(f"  ... and {len(added) - 5} more")
				print()
			
			if removed:
				print(f"➖ Removed files: {len(removed)}")
				for f in removed[:5]:
					print(f"  • {f}")
				if len(removed) > 5:
					print(f"  ... and {len(removed) - 5} more")
				print()
		
		# Run build
		if not self.run_build_script():
			return False
		
		print()
		
		# Verify ROM
		if verify:
			if not self.verify_rom():
				return False
			print()
		
		# Update cache
		self.update_cache()
		
		print("="*80)
		print("✅ Build complete!")
		print("="*80)
		
		return True

def main():
	"""Main entry point"""
	import argparse
	
	parser = argparse.ArgumentParser(
		description='FFMQ ROM Build Orchestrator',
		formatter_class=argparse.RawDescriptionHelpFormatter,
		epilog="""
Examples:
  python build_rom.py              # Incremental build (build if needed)
  python build_rom.py --force      # Force rebuild
  python build_rom.py --clean      # Clean and rebuild
  python build_rom.py --no-verify  # Skip ROM verification
		"""
	)
	
	parser.add_argument('--force', '-f', action='store_true',
					   help='Force rebuild even if no changes detected')
	parser.add_argument('--clean', '-c', action='store_true',
					   help='Clean build directory before building')
	parser.add_argument('--no-verify', action='store_true',
					   help='Skip ROM hash verification')
	
	args = parser.parse_args()
	
	builder = ROMBuilder()
	success = builder.build(
		force=args.force,
		clean=args.clean,
		verify=not args.no_verify
	)
	
	sys.exit(0 if success else 1)

if __name__ == '__main__':
	main()
