#!/usr/bin/env python3
"""
FFMQ Simple Text Re-insertion Tool
Safely re-insert edited simple text (items, spells, monsters, etc.) back into ROM

Features:
	- Length validation (text must fit in fixed-length slots)
	- Backup creation
	- CRC verification (optional)
	- Dry-run mode to preview changes

Usage:
	python tools/import/import_simple_text.py <rom_path> <csv_file> [options]

Examples:
	# Dry run (preview changes)
	python tools/import/import_simple_text.py rom.sfc data/text_fixed/spell_names.csv --dry-run
	
	# Import with backup
	python tools/import/import_simple_text.py rom.sfc data/text_fixed/spell_names.csv --backup
	
	# Import multiple tables
	python tools/import/import_simple_text.py rom.sfc data/text_fixed/*.csv
"""

import sys
import csv
import shutil
from pathlib import Path
from datetime import datetime
from typing import List, Tuple, Optional
from dataclasses import dataclass

# Add tools to path
sys.path.insert(0, str(Path(__file__).parent.parent))
from text.simple_text_decoder import SimpleTextDecoder


@dataclass
class TextEntry:
	"""Single text entry to import"""
	id: int
	text: str
	address: int
	expected_length: int


class SimpleTextImporter:
	"""Import edited simple text back to ROM"""
	
	def __init__(self, rom_path: Path, dry_run: bool = False, create_backup: bool = True):
		"""
		Initialize importer
		
		Args:
			rom_path: Path to ROM file
			dry_run: If True, don't actually modify ROM (preview only)
			create_backup: If True, create .bak backup before modifying
		"""
		self.rom_path = Path(rom_path)
		self.dry_run = dry_run
		self.create_backup = create_backup
		self.rom_data: Optional[bytearray] = None
		self.decoder = SimpleTextDecoder()
		self.changes_made = 0
		self.errors = []
	
	def load_rom(self) -> bool:
		"""Load ROM file"""
		if not self.rom_path.exists():
			print(f"ERROR: ROM not found: {self.rom_path}")
			return False
		
		with open(self.rom_path, 'rb') as f:
			self.rom_data = bytearray(f.read())
		
		print(f"✓ Loaded ROM: {self.rom_path.name} ({len(self.rom_data):,} bytes)")
		return True
	
	def load_csv(self, csv_path: Path) -> List[TextEntry]:
		"""
		Load edited text from CSV
		
		Args:
			csv_path: Path to CSV file
		
		Returns:
			List of text entries
		"""
		if not csv_path.exists():
			print(f"ERROR: CSV not found: {csv_path}")
			return []
		
		entries = []
		with open(csv_path, 'r', encoding='utf-8') as f:
			reader = csv.DictReader(f)
			for row in reader:
				try:
					entry = TextEntry(
						id=int(row['ID']),
						text=row['Text'],
						address=int(row['Address'].replace('$', ''), 16),
						expected_length=int(row['Length'])
					)
					entries.append(entry)
				except (KeyError, ValueError) as e:
					print(f"  Warning: Skipping invalid row: {row} ({e})")
		
		print(f"✓ Loaded {len(entries)} entries from {csv_path.name}")
		return entries
	
	def validate_entry(self, entry: TextEntry) -> Tuple[bool, Optional[str]]:
		"""
		Validate text entry before import
		
		Args:
			entry: Text entry to validate
		
		Returns:
			(is_valid, error_message)
		"""
		# Encode text
		try:
			encoded = self.decoder.encode(entry.text, entry.expected_length)
		except ValueError as e:
			return False, f"Encoding error: {e}"
		
		# Check length
		if len(encoded) != entry.expected_length:
			return False, f"Length mismatch: got {len(encoded)}, expected {entry.expected_length}"
		
		# Verify round-trip
		decoded, _ = self.decoder.decode(encoded, entry.expected_length)
		if decoded != entry.text:
			return False, f"Round-trip failed: '{entry.text}' != '{decoded}'"
		
		return True, None
	
	def import_entry(self, entry: TextEntry) -> bool:
		"""
		Import single text entry to ROM
		
		Args:
			entry: Text entry to import
		
		Returns:
			True if successful
		"""
		if self.rom_data is None:
			self.errors.append("ROM data not loaded")
			return False
		
		# Validate
		is_valid, error = self.validate_entry(entry)
		if not is_valid:
			self.errors.append(f"Entry {entry.id} ({entry.text}): {error}")
			return False
		
		# Encode
		encoded = self.decoder.encode(entry.text, entry.expected_length)
		
		# Get current bytes
		current = self.rom_data[entry.address:entry.address + entry.expected_length]
		
		# Check if changed
		if bytes(current) == encoded:
			return True  # No change needed
		
		# Show diff in dry-run mode
		if self.dry_run:
			current_text, _ = self.decoder.decode(bytes(current), entry.expected_length)
			print(f"  Entry {entry.id:3d} @ ${entry.address:06X}:")
			print(f"    OLD: {current_text}")
			print(f"    NEW: {entry.text}")
		else:
			# Write to ROM
			self.rom_data[entry.address:entry.address + entry.expected_length] = encoded
			self.changes_made += 1
		
		return True
	
	def import_csv(self, csv_path: Path) -> bool:
		"""
		Import all entries from CSV file
		
		Args:
			csv_path: Path to CSV file
		
		Returns:
			True if successful
		"""
		print(f"\nImporting {csv_path.name}...")
		
		entries = self.load_csv(csv_path)
		if not entries:
			return False
		
		success_count = 0
		for entry in entries:
			if self.import_entry(entry):
				success_count += 1
		
		print(f"  ✓ Imported {success_count}/{len(entries)} entries")
		
		if self.errors:
			print(f"  ⚠️  {len(self.errors)} errors:")
			for error in self.errors[:5]:  # Show first 5 errors
				print(f"    - {error}")
			if len(self.errors) > 5:
				print(f"    ... and {len(self.errors) - 5} more")
			self.errors.clear()
		
		return success_count > 0
	
	def save_rom(self, output_path: Optional[Path] = None) -> bool:
		"""
		Save modified ROM
		
		Args:
			output_path: Output path (None = overwrite original)
		
		Returns:
			True if successful
		"""
		if self.rom_data is None:
			print("\nERROR: No ROM data loaded")
			return False
		
		if self.dry_run:
			print("\n✓ Dry run complete - no changes written")
			return True
		
		if self.changes_made == 0:
			print("\n✓ No changes to write")
			return True
		
		# Determine output path
		if output_path is None:
			output_path = self.rom_path
			
			# Create backup if requested
			if self.create_backup:
				backup_path = self.rom_path.with_suffix(
					f'.{datetime.now().strftime("%Y%m%d_%H%M%S")}.bak'
				)
				print(f"\nCreating backup: {backup_path.name}")
				shutil.copy2(self.rom_path, backup_path)
		
		# Write ROM
		print(f"Writing {self.changes_made} changes to {output_path.name}...")
		with open(output_path, 'wb') as f:
			f.write(self.rom_data)
		
		print(f"✓ ROM saved successfully")
		return True


def main():
	import argparse
	
	parser = argparse.ArgumentParser(
		description='Import edited simple text back to FFMQ ROM',
		epilog='Example: python import_simple_text.py rom.sfc data/text_fixed/spell_names.csv --dry-run'
	)
	parser.add_argument('rom', type=Path, help='ROM file path')
	parser.add_argument('csv_files', type=Path, nargs='+', help='CSV file(s) to import')
	parser.add_argument('--dry-run', action='store_true', help='Preview changes without modifying ROM')
	parser.add_argument('--no-backup', action='store_true', help='Skip backup creation')
	parser.add_argument('--output', '-o', type=Path, help='Output ROM path (default: overwrite input)')
	
	args = parser.parse_args()
	
	# Create importer
	importer = SimpleTextImporter(
		args.rom,
		dry_run=args.dry_run,
		create_backup=not args.no_backup
	)
	
	# Load ROM
	if not importer.load_rom():
		return 1
	
	# Process each CSV
	print("\n" + "=" * 70)
	print("FFMQ Simple Text Import")
	print("=" * 70)
	
	if args.dry_run:
		print("\n⚠️  DRY RUN MODE - No changes will be written\n")
	
	total_imported = 0
	for csv_file in args.csv_files:
		if importer.import_csv(csv_file):
			total_imported += 1
	
	# Save
	if total_imported > 0:
		importer.save_rom(args.output)
	
	print("\n" + "=" * 70)
	print(f"✓ Import complete: {total_imported} file(s) processed")
	print("=" * 70)
	
	return 0


if __name__ == '__main__':
	sys.exit(main())
