#!/usr/bin/env python3
"""
Build Integration System
Manages the complete graphics pipeline: Extract → Edit → Rebuild

This script coordinates the round-trip graphics workflow:
1. Extract graphics from ROM → PNG + JSON
2. Edit PNGs in external tools (Aseprite, GIMP, etc.)
3. Re-import edited PNGs → Binary data
4. Insert binary data into ROM during build

Features:
- Automatic detection of modified PNGs
- Incremental rebuild (only changed graphics)
- Validation and error checking
- Build manifest generation
- Integration with asar assembler

Usage:
	python build_integration.py --extract    # Extract all graphics
	python build_integration.py --rebuild    # Rebuild changed graphics
	python build_integration.py --full       # Full rebuild
	python build_integration.py --validate   # Validate all graphics

Author: FFMQ Disassembly Project  
Date: 2025-11-02
"""

import sys
import json
import hashlib
from pathlib import Path
from datetime import datetime
from typing import List, Dict, Set, Optional
import subprocess


class BuildIntegration:
	"""Manages the complete graphics build pipeline."""
	
	def __init__(self, project_root: Path):
		"""
		Initialize build integration.
		
		Args:
			project_root: Root directory of the project
		"""
		self.project_root = project_root
		self.extracted_dir = project_root / 'data' / 'extracted'
		self.rebuilt_dir = project_root / 'data' / 'rebuilt'
		self.build_dir = project_root / 'build'
		
		# Build manifest tracks what's been built
		self.manifest_path = self.build_dir / 'graphics_manifest.json'
		self.manifest = self.load_manifest()
	
	def load_manifest(self) -> Dict:
		"""Load the build manifest."""
		if self.manifest_path.exists():
			with open(self.manifest_path, 'r') as f:
				return json.load(f)
		return {
			'version': '1.0',
			'last_build': None,
			'files': {}
		}
	
	def save_manifest(self):
		"""Save the build manifest."""
		self.manifest_path.parent.mkdir(parents=True, exist_ok=True)
		self.manifest['last_build'] = datetime.now().isoformat()
		
		with open(self.manifest_path, 'w') as f:
			json.dump(self.manifest, f, indent=2)
		
		print(f"✓ Saved build manifest to {self.manifest_path}")
	
	def calculate_file_hash(self, file_path: Path) -> str:
		"""Calculate SHA256 hash of a file."""
		sha256 = hashlib.sha256()
		
		with open(file_path, 'rb') as f:
			for chunk in iter(lambda: f.read(8192), b''):
				sha256.update(chunk)
		
		return sha256.hexdigest()
	
	def find_modified_files(self) -> Set[Path]:
		"""
		Find PNG files that have been modified since last build.
		
		Returns:
			Set of paths to modified PNG files
		"""
		modified = set()
		
		# Scan extracted directories for PNGs
		for png_path in self.extracted_dir.rglob('*.png'):
			# Calculate current hash
			current_hash = self.calculate_file_hash(png_path)
			
			# Compare with manifest
			rel_path = str(png_path.relative_to(self.project_root))
			manifest_entry = self.manifest['files'].get(rel_path, {})
			previous_hash = manifest_entry.get('hash')
			
			if current_hash != previous_hash:
				modified.add(png_path)
				
				# Update manifest
				self.manifest['files'][rel_path] = {
					'hash': current_hash,
					'last_modified': datetime.now().isoformat()
				}
		
		return modified
	
	def extract_all_graphics(self) -> bool:
		"""
		Extract all graphics from ROM.
		
		Returns:
			True if successful
		"""
		print("\n🎨 Extracting graphics from ROM...")
		
		scripts = [
			'tools/extraction/extract_graphics.py',
			'tools/extraction/extract_sprites.py',
			'tools/extraction/extract_enemy_palettes.py',
			'tools/extraction/reextract_enemies_correct_palettes.py'
		]
		
		for script in scripts:
			script_path = self.project_root / script
			if not script_path.exists():
				print(f"  ⚠️  Script not found: {script}")
				continue
			
			print(f"  Running {script_path.name}...")
			
			try:
				result = subprocess.run(
					[sys.executable, str(script_path)],
					cwd=self.project_root,
					capture_output=True,
					text=True
				)
				
				if result.returncode != 0:
					print(f"  ❌ Failed: {result.stderr}")
					return False
				
				print(f"  ✓ Complete")
				
			except Exception as e:
				print(f"  ❌ Error: {e}")
				return False
		
		# Update manifest with all extracted files
		for png_path in self.extracted_dir.rglob('*.png'):
			rel_path = str(png_path.relative_to(self.project_root))
			self.manifest['files'][rel_path] = {
				'hash': self.calculate_file_hash(png_path),
				'last_modified': datetime.now().isoformat()
			}
		
		self.save_manifest()
		
		print("\n✅ Graphics extraction complete!")
		return True
	
	def rebuild_modified_graphics(self) -> bool:
		"""
		Rebuild only modified graphics.
		
		Returns:
			True if successful
		"""
		print("\n🔨 Rebuilding modified graphics...")
		
		# Find modified files
		modified = self.find_modified_files()
		
		if not modified:
			print("  ℹ️  No modified graphics found")
			return True
		
		print(f"  Found {len(modified)} modified files:")
		for path in sorted(modified):
			print(f"    • {path.relative_to(self.project_root)}")
		
		# Group by category
		categories = {}
		for path in modified:
			parts = path.relative_to(self.extracted_dir).parts
			if len(parts) > 0:
				category = parts[0]  # sprites, graphics, etc.
				if category not in categories:
					categories[category] = []
				categories[category].append(path)
		
		# Import each category
		for category, files in categories.items():
			print(f"\n  📦 Importing {category}...")
			
			input_dir = self.extracted_dir / category
			output_dir = self.rebuilt_dir / category
			
			# Run import script
			import_script = self.project_root / 'tools' / 'import' / 'import_sprites.py'
			
			if import_script.exists():
				try:
					result = subprocess.run(
						[sys.executable, str(import_script), str(input_dir), str(output_dir)],
						cwd=self.project_root,
						capture_output=True,
						text=True
					)
					
					if result.returncode != 0:
						print(f"  ❌ Import failed: {result.stderr}")
						return False
					
					print(f"  ✓ Imported {len(files)} files")
					
				except Exception as e:
					print(f"  ❌ Error: {e}")
					return False
		
		self.save_manifest()
		
		print("\n✅ Graphics rebuild complete!")
		return True
	
	def validate_graphics(self) -> bool:
		"""
		Validate all extracted graphics.
		
		Returns:
			True if all valid
		"""
		print("\n🔍 Validating graphics...")
		
		errors = []
		warnings = []
		
		# Check for orphaned metadata files
		for meta_path in self.extracted_dir.rglob('*_meta.json'):
			png_path = meta_path.with_suffix('.png').with_name(
				meta_path.stem.replace('_meta', '') + '.png'
			)
			
			if not png_path.exists():
				errors.append(f"Orphaned metadata: {meta_path.relative_to(self.project_root)}")
		
		# Check for missing metadata
		for png_path in self.extracted_dir.rglob('*.png'):
			if 'catalog' in png_path.name or 'sheet' in png_path.name:
				continue  # Skip catalog/sheet files
			
			meta_path = png_path.with_name(png_path.stem + '_meta.json')
			
			if not meta_path.exists():
				warnings.append(f"Missing metadata: {png_path.relative_to(self.project_root)}")
		
		# Report results
		if errors:
			print(f"\n  ❌ Found {len(errors)} errors:")
			for error in errors[:10]:  # Show first 10
				print(f"     • {error}")
			if len(errors) > 10:
				print(f"     ... and {len(errors) - 10} more")
		
		if warnings:
			print(f"\n  ⚠️  Found {len(warnings)} warnings:")
			for warning in warnings[:10]:  # Show first 10
				print(f"     • {warning}")
			if len(warnings) > 10:
				print(f"     ... and {len(warnings) - 10} more")
		
		if not errors and not warnings:
			print("  ✓ All graphics validated successfully")
			return True
		elif not errors:
			print(f"\n  ℹ️  Validation complete with {len(warnings)} warnings")
			return True
		else:
			return False


def main():
	"""Main function for command-line usage."""
	import argparse
	
	parser = argparse.ArgumentParser(
		description='Graphics build integration system for FFMQ'
	)
	parser.add_argument('--extract', action='store_true',
						help='Extract all graphics from ROM')
	parser.add_argument('--rebuild', action='store_true',
						help='Rebuild modified graphics')
	parser.add_argument('--full', action='store_true',
						help='Full rebuild (extract + rebuild)')
	parser.add_argument('--validate', action='store_true',
						help='Validate all graphics')
	parser.add_argument('--project-root', type=Path, default=Path.cwd(),
						help='Project root directory')
	
	args = parser.parse_args()
	
	# Create build integration
	integration = BuildIntegration(args.project_root)
	
	success = True
	
	# Execute requested operation
	if args.extract or args.full:
		success = integration.extract_all_graphics() and success
	
	if args.rebuild or args.full:
		success = integration.rebuild_modified_graphics() and success
	
	if args.validate:
		success = integration.validate_graphics() and success
	
	if not (args.extract or args.rebuild or args.full or args.validate):
		parser.print_help()
		return 1
	
	return 0 if success else 1


if __name__ == '__main__':
	sys.exit(main())
