#!/usr/bin/env python3
"""
Build Integration System - Phase 3 Enhanced
Manages complete ROM hacking pipeline: Graphics, Text, Maps, Effects

This script coordinates all round-trip workflows:
1. Graphics: Extract → Edit → Rebuild (Phase 2)
2. Text: Extract → Edit → Import (Phase 3)
3. Maps: Extract → Edit in Tiled → Import (Phase 3)
4. Overworld: Extract → Edit → Rebuild (Phase 3)
5. Effects: Extract → Edit → Rebuild (Phase 3)

Features:
- Automatic detection of modified files
- Incremental rebuild (only changed data)
- Validation and error checking
- Build manifest generation
- Multi-format support (PNG, JSON, CSV, TMX)
- Integration with asar assembler

Usage:
	python build_integration.py --extract-all     # Extract everything
	python build_integration.py --rebuild-all     # Rebuild all changes
	python build_integration.py --full            # Full rebuild
	python build_integration.py --validate        # Validate all data
	python build_integration.py --graphics        # Graphics only
	python build_integration.py --text            # Text only
	python build_integration.py --maps            # Maps only

Author: FFMQ Modding Project
Date: 2025-11-02 (Phase 3 Enhanced)
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

		# Generate ASM includes
		print("\n  🔨 Generating ASM includes...")
		if not self.generate_asm_includes():
			print("  ⚠️  ASM generation failed (non-fatal)")

		print("\n✅ Graphics rebuild complete!")
		return True

	def generate_asm_includes(self) -> bool:
		"""
		Generate asar assembly include files for rebuilt graphics.

		Returns:
			True if successful
		"""
		# Run generate_graphics_asm.py
		asm_generator = self.project_root / 'tools' / 'generate_graphics_asm.py'

		if not asm_generator.exists():
			return False

		try:
			result = subprocess.run(
				[sys.executable, str(asm_generator)],
				cwd=self.project_root,
				capture_output=True,
				text=True
			)

			if result.returncode != 0:
				print(f"    ❌ Failed: {result.stderr}")
				return False

			# Print output
			for line in result.stdout.strip().split('\n'):
				if line.strip():
					print(f"    {line}")

			return True

		except Exception as e:
			print(f"    ❌ Error: {e}")
			return False

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

	# ========================================
	# Phase 3: Text Pipeline Methods
	# ========================================

	def extract_all_text(self) -> bool:
		"""Extract all text from ROM."""
		print("\n=== Extracting Text Data ===")

		rom_path = self.project_root / 'roms' / 'FFMQ.sfc'
		output_dir = self.extracted_dir / 'text'

		if not rom_path.exists():
			print(f"❌ ROM not found: {rom_path}")
			return False

		# Run text extraction
		cmd = [
			sys.executable,
			str(self.project_root / 'tools' / 'extract_text_enhanced.py'),
			str(rom_path),
			str(output_dir)
		]

		result = subprocess.run(cmd, capture_output=True, text=True)

		if result.returncode == 0:
			print("✓ Text extraction complete")
			return True
		else:
			print(f"❌ Text extraction failed: {result.stderr}")
			return False

	def rebuild_text(self) -> bool:
		"""Rebuild text data back to ROM."""
		print("\n=== Rebuilding Text Data ===")

		source_rom = self.project_root / 'roms' / 'FFMQ.sfc'
		text_json = self.extracted_dir / 'text' / 'text_complete.json'
		output_rom = self.build_dir / 'ffmq_text_modified.sfc'

		if not text_json.exists():
			print(f"❌ Text data not found: {text_json}")
			print("   Run --extract-text first")
			return False

		# Check if text was modified
		text_hash = self.compute_file_hash(text_json)
		manifest_hash = self.manifest.get('text', {}).get('hash')

		if text_hash == manifest_hash:
			print("  ℹ️  Text unchanged, skipping rebuild")
			return True

		# Run text import
		cmd = [
			sys.executable,
			str(self.project_root / 'tools' / 'import' / 'import_text.py'),
			str(source_rom),
			str(text_json),
			str(output_rom)
		]

		result = subprocess.run(cmd, capture_output=True, text=True)

		if result.returncode == 0:
			# Update manifest
			self.manifest['text'] = {
				'hash': text_hash,
				'timestamp': datetime.now().isoformat()
			}
			self.save_manifest()

			print("✓ Text rebuild complete")
			return True
		else:
			print(f"❌ Text rebuild failed: {result.stderr}")
			return False

	# ========================================
	# Phase 3: Map Pipeline Methods
	# ========================================

	def extract_all_maps(self) -> bool:
		"""Extract all maps to TMX format."""
		print("\n=== Extracting Map Data ===")

		rom_path = self.project_root / 'roms' / 'FFMQ.sfc'
		output_dir = self.extracted_dir / 'maps'

		if not rom_path.exists():
			print(f"❌ ROM not found: {rom_path}")
			return False

		# Run map extraction
		cmd = [
			sys.executable,
			str(self.project_root / 'tools' / 'extract_maps_enhanced.py'),
			str(rom_path),
			str(output_dir),
			'tmx,json'
		]

		result = subprocess.run(cmd, capture_output=True, text=True)

		if result.returncode == 0:
			print("✓ Map extraction complete")
			return True
		else:
			print(f"❌ Map extraction failed: {result.stderr}")
			return False

	def rebuild_maps(self) -> bool:
		"""Rebuild maps from TMX files."""
		print("\n=== Rebuilding Map Data ===")

		source_rom = self.project_root / 'roms' / 'FFMQ.sfc'
		maps_dir = self.extracted_dir / 'maps' / 'maps'
		output_rom = self.build_dir / 'ffmq_maps_modified.sfc'

		if not maps_dir.exists():
			print(f"❌ Maps directory not found: {maps_dir}")
			print("   Run --extract-maps first")
			return False

		# Check for modified TMX files
		modified_maps = []
		for tmx_file in maps_dir.glob('*.tmx'):
			file_hash = self.compute_file_hash(tmx_file)
			manifest_key = f'map_{tmx_file.stem}'
			manifest_hash = self.manifest.get('maps', {}).get(manifest_key)

			if file_hash != manifest_hash:
				modified_maps.append(tmx_file)

		if not modified_maps:
			print("  ℹ️  No maps modified, skipping rebuild")
			return True

		print(f"  Found {len(modified_maps)} modified maps")

		# Run map import
		cmd = [
			sys.executable,
			str(self.project_root / 'tools' / 'import' / 'import_maps.py'),
			str(source_rom),
			str(maps_dir),
			str(output_rom)
		]

		result = subprocess.run(cmd, capture_output=True, text=True)

		if result.returncode == 0:
			# Update manifest for all maps
			if 'maps' not in self.manifest:
				self.manifest['maps'] = {}

			for tmx_file in maps_dir.glob('*.tmx'):
				file_hash = self.compute_file_hash(tmx_file)
				manifest_key = f'map_{tmx_file.stem}'
				self.manifest['maps'][manifest_key] = file_hash

			self.manifest['maps']['timestamp'] = datetime.now().isoformat()
			self.save_manifest()

			print("✓ Map rebuild complete")
			return True
		else:
			print(f"❌ Map rebuild failed: {result.stderr}")
			return False

	# ========================================
	# Phase 3: Overworld Graphics Methods
	# ========================================

	def extract_overworld_graphics(self) -> bool:
		"""Extract overworld graphics (tilesets, sprites)."""
		print("\n=== Extracting Overworld Graphics ===")

		rom_path = self.project_root / 'roms' / 'FFMQ.sfc'
		output_dir = self.extracted_dir / 'overworld'

		if not rom_path.exists():
			print(f"❌ ROM not found: {rom_path}")
			return False

		# Run overworld extraction
		cmd = [
			sys.executable,
			str(self.project_root / 'tools' / 'extract_overworld.py'),
			str(rom_path),
			str(output_dir)
		]

		result = subprocess.run(cmd, capture_output=True, text=True)

		if result.returncode == 0:
			print("✓ Overworld extraction complete")
			return True
		else:
			print(f"❌ Overworld extraction failed: {result.stderr}")
			return False

	# ========================================
	# Phase 3: Effects Graphics Methods
	# ========================================

	def extract_effects_graphics(self) -> bool:
		"""Extract spell/battle effect graphics."""
		print("\n=== Extracting Effect Graphics ===")

		rom_path = self.project_root / 'roms' / 'FFMQ.sfc'
		output_dir = self.extracted_dir / 'effects'

		if not rom_path.exists():
			print(f"❌ ROM not found: {rom_path}")
			return False

		# Run effects extraction
		cmd = [
			sys.executable,
			str(self.project_root / 'tools' / 'extract_effects.py'),
			str(rom_path),
			str(output_dir)
		]

		result = subprocess.run(cmd, capture_output=True, text=True)

		if result.returncode == 0:
			print("✓ Effects extraction complete")
			return True
		else:
			print(f"❌ Effects extraction failed: {result.stderr}")
			return False

	# ========================================
	# Phase 3: Combined Operations
	# ========================================

	def extract_all_phase3(self) -> bool:
		"""Extract all Phase 3 data (text, maps, overworld, effects)."""
		print("\n=== Phase 3: Extracting All Data ===")

		success = True
		success = self.extract_all_text() and success
		success = self.extract_all_maps() and success
		success = self.extract_overworld_graphics() and success
		success = self.extract_effects_graphics() and success

		if success:
			print("\n✓ All Phase 3 extraction complete!")
		else:
			print("\n❌ Some Phase 3 extractions failed")

		return success

	def rebuild_all_phase3(self) -> bool:
		"""Rebuild all Phase 3 data."""
		print("\n=== Phase 3: Rebuilding All Data ===")

		success = True
		success = self.rebuild_text() and success
		success = self.rebuild_maps() and success

		if success:
			print("\n✓ All Phase 3 rebuild complete!")
		else:
			print("\n❌ Some Phase 3 rebuilds failed")

		return success

	def full_pipeline(self) -> bool:
		"""Execute complete pipeline: extract everything, rebuild everything."""
		print("\n" + "="*60)
		print("FFMQ Complete Build Pipeline")
		print("="*60)

		success = True

		# Phase 2: Graphics
		success = self.extract_all_graphics() and success
		success = self.rebuild_modified_graphics() and success

		# Phase 3: All data types
		success = self.extract_all_phase3() and success
		success = self.rebuild_all_phase3() and success

		if success:
			print("\n" + "="*60)
			print("✓ Complete pipeline executed successfully!")
			print("="*60)
		else:
			print("\n" + "="*60)
			print("❌ Pipeline completed with errors")
			print("="*60)

		return success


def main():
	"""Main function for command-line usage."""
	import argparse

	parser = argparse.ArgumentParser(
		description='Complete build integration system for FFMQ (Phase 2 + Phase 3)'
	)

	# Phase 2: Graphics operations
	parser.add_argument('--extract', action='store_true',
						help='Extract all graphics from ROM (Phase 2)')
	parser.add_argument('--rebuild', action='store_true',
						help='Rebuild modified graphics (Phase 2)')
	parser.add_argument('--full', action='store_true',
						help='Full rebuild (extract + rebuild)')
	parser.add_argument('--validate', action='store_true',
						help='Validate all graphics')

	# Phase 3: Individual operations
	parser.add_argument('--extract-text', action='store_true',
						help='Extract all text data')
	parser.add_argument('--rebuild-text', action='store_true',
						help='Rebuild text data')
	parser.add_argument('--extract-maps', action='store_true',
						help='Extract all maps (TMX/JSON)')
	parser.add_argument('--rebuild-maps', action='store_true',
						help='Rebuild maps from TMX')
	parser.add_argument('--extract-overworld', action='store_true',
						help='Extract overworld graphics')
	parser.add_argument('--extract-effects', action='store_true',
						help='Extract effect graphics')

	# Phase 3: Combined operations
	parser.add_argument('--extract-all', action='store_true',
						help='Extract everything (graphics + text + maps + overworld + effects)')
	parser.add_argument('--rebuild-all', action='store_true',
						help='Rebuild everything that changed')
	parser.add_argument('--pipeline', action='store_true',
						help='Full pipeline: extract all + rebuild all')

	# Utility operations
	parser.add_argument('--graphics', action='store_true',
						help='Graphics pipeline only (extract + rebuild)')
	parser.add_argument('--text', action='store_true',
						help='Text pipeline only (extract + rebuild)')
	parser.add_argument('--maps', action='store_true',
						help='Maps pipeline only (extract + rebuild)')

	parser.add_argument('--project-root', type=Path, default=Path.cwd(),
						help='Project root directory')

	args = parser.parse_args()

	# Create build integration
	integration = BuildIntegration(args.project_root)

	success = True

	# Execute requested operations

	# Pipeline mode: everything
	if args.pipeline:
		success = integration.full_pipeline() and success

	# Extract all mode
	elif args.extract_all:
		success = integration.extract_all_graphics() and success
		success = integration.extract_all_phase3() and success

	# Rebuild all mode
	elif args.rebuild_all:
		success = integration.rebuild_modified_graphics() and success
		success = integration.rebuild_all_phase3() and success

	# Individual pipeline shortcuts
	elif args.graphics:
		success = integration.extract_all_graphics() and success
		success = integration.rebuild_modified_graphics() and success

	elif args.text:
		success = integration.extract_all_text() and success
		success = integration.rebuild_text() and success

	elif args.maps:
		success = integration.extract_all_maps() and success
		success = integration.rebuild_maps() and success

	# Individual operations
	else:
		# Phase 2 graphics
		if args.extract or args.full:
			success = integration.extract_all_graphics() and success

		if args.rebuild or args.full:
			success = integration.rebuild_modified_graphics() and success

		if args.validate:
			success = integration.validate_graphics() and success

		# Phase 3 text
		if args.extract_text:
			success = integration.extract_all_text() and success

		if args.rebuild_text:
			success = integration.rebuild_text() and success

		# Phase 3 maps
		if args.extract_maps:
			success = integration.extract_all_maps() and success

		if args.rebuild_maps:
			success = integration.rebuild_maps() and success

		# Phase 3 overworld
		if args.extract_overworld:
			success = integration.extract_overworld_graphics() and success

		# Phase 3 effects
		if args.extract_effects:
			success = integration.extract_effects_graphics() and success

		# Show help if no operations specified
		if not any([args.extract, args.rebuild, args.full, args.validate,
					args.extract_text, args.rebuild_text, args.extract_maps,
					args.rebuild_maps, args.extract_overworld, args.extract_effects]):
			parser.print_help()
			print("\nExamples:")
			print("  python build_integration.py --pipeline          # Full workflow")
			print("  python build_integration.py --extract-all       # Extract everything")
			print("  python build_integration.py --rebuild-all       # Rebuild changes")
			print("  python build_integration.py --graphics          # Graphics only")
			print("  python build_integration.py --text              # Text only")
			print("  python build_integration.py --maps              # Maps only")
			return 1

	return 0 if success else 1


if __name__ == '__main__':
	sys.exit(main())
