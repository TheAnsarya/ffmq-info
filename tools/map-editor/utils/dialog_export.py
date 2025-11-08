#!/usr/bin/env python3
"""
FFMQ Dialog Export/Import Tools
Export dialogs to spreadsheet/JSON for translation and reimport
"""

import json
import csv
from pathlib import Path
from typing import List, Dict, Optional, Tuple
from dataclasses import dataclass, asdict
import sys
from datetime import datetime

# Add utils directory to path
sys.path.insert(0, str(Path(__file__).parent.parent / 'utils'))

from dialog_text import DialogText, DialogMetrics
from dialog_database import DialogDatabase, DialogEntry


@dataclass
class TranslationEntry:
	"""Single translation entry for export/import"""
	id: int
	address: str
	original_text: str
	translated_text: str
	notes: str = ""
	char_count: int = 0
	byte_count: int = 0
	max_bytes: int = 512
	status: str = "untranslated"  # untranslated, in-progress, complete, needs-review
	translator: str = ""
	last_modified: str = ""


class DialogExporter:
	"""Export dialogs to various formats"""

	def __init__(self, database: DialogDatabase, dialog_text: DialogText):
		"""
		Initialize exporter

		Args:
			database: Dialog database
			dialog_text: Dialog text handler
		"""
		self.database = database
		self.dialog_text = dialog_text

	def export_to_csv(self, output_path: Path, include_metadata: bool = True) -> int:
		"""
		Export dialogs to CSV file

		Args:
			output_path: Output CSV file path
			include_metadata: Include metadata columns

		Returns:
			Number of dialogs exported
		"""
		with open(output_path, 'w', newline='', encoding='utf-8-sig') as f:
			if include_metadata:
				fieldnames = [
					'ID', 'Address', 'Original Text', 'Translated Text',
					'Notes', 'Char Count', 'Byte Count', 'Max Bytes',
					'Status', 'Translator', 'Last Modified'
				]
			else:
				fieldnames = ['ID', 'Original Text', 'Translated Text', 'Notes']

			writer = csv.DictWriter(f, fieldnames=fieldnames)
			writer.writeheader()

			count = 0
			for dialog_id in sorted(self.database.dialogs.keys()):
				dialog = self.database.dialogs[dialog_id]

				# Calculate metrics
				metrics = self.dialog_text.calculate_metrics(dialog.text)

				row = {
					'ID': f'{dialog_id:04X}',
					'Address': f'${dialog.address:06X}',
					'Original Text': dialog.text.replace('\n', '\\n'),
					'Translated Text': '',  # Empty for translator to fill
					'Notes': '',
				}

				if include_metadata:
					row.update({
						'Char Count': metrics.char_count,
						'Byte Count': metrics.byte_count,
						'Max Bytes': DialogText.MAX_DIALOG_LENGTH,
						'Status': 'untranslated',
						'Translator': '',
						'Last Modified': ''
					})

				writer.writerow(row)
				count += 1

		return count

	def export_to_json(self, output_path: Path, pretty: bool = True) -> int:
		"""
		Export dialogs to JSON file

		Args:
			output_path: Output JSON file path
			pretty: Use pretty printing

		Returns:
			Number of dialogs exported
		"""
		dialogs_data = []

		for dialog_id in sorted(self.database.dialogs.keys()):
			dialog = self.database.dialogs[dialog_id]
			metrics = self.dialog_text.calculate_metrics(dialog.text)

			dialog_data = {
				'id': f'{dialog_id:04X}',
				'address': f'${dialog.address:06X}',
				'snes_address': f'${dialog.snes_bank:02X}:{dialog.snes_address:04X}',
				'original_text': dialog.text,
				'translated_text': '',
				'notes': '',
				'metadata': {
					'char_count': metrics.char_count,
					'byte_count': metrics.byte_count,
					'line_count': metrics.line_count,
					'max_bytes': DialogText.MAX_DIALOG_LENGTH,
					'control_codes': list(metrics.control_codes.keys()),
					'warnings': metrics.warnings
				},
				'status': 'untranslated',
				'translator': '',
				'last_modified': ''
			}

			dialogs_data.append(dialog_data)

		export_data = {
			'version': '1.0',
			'game': 'Final Fantasy Mystic Quest (SNES)',
			'export_date': datetime.now().isoformat(),
			'total_dialogs': len(dialogs_data),
			'dialogs': dialogs_data
		}

		with open(output_path, 'w', encoding='utf-8') as f:
			if pretty:
				json.dump(export_data, f, indent=2, ensure_ascii=False)
			else:
				json.dump(export_data, f, ensure_ascii=False)

		return len(dialogs_data)

	def export_to_po(self, output_path: Path) -> int:
		"""
		Export dialogs to Gettext PO file format

		Args:
			output_path: Output .po file path

		Returns:
			Number of dialogs exported
		"""
		with open(output_path, 'w', encoding='utf-8') as f:
			# PO header
			f.write('# FFMQ Dialog Translation\n')
			f.write(f'# Generated: {datetime.now().isoformat()}\n')
			f.write('#\n')
			f.write('msgid ""\n')
			f.write('msgstr ""\n')
			f.write('"Content-Type: text/plain; charset=UTF-8\\n"\n')
			f.write('"Language: en\\n"\n')
			f.write('\n')

			count = 0
			for dialog_id in sorted(self.database.dialogs.keys()):
				dialog = self.database.dialogs[dialog_id]

				# Comment with metadata
				f.write(f'# Dialog ID: {dialog_id:04X}\n')
				f.write(f'# Address: ${dialog.address:06X}\n')

				# Source text
				msgid = dialog.text.replace('"', '\\"')
				f.write(f'msgid "{msgid}"\n')

				# Empty translation
				f.write('msgstr ""\n')
				f.write('\n')

				count += 1

		return count

	def export_to_excel_compatible_csv(self, output_path: Path) -> int:
		"""
		Export to CSV with Excel-compatible formatting

		Args:
			output_path: Output CSV file path

		Returns:
			Number of dialogs exported
		"""
		with open(output_path, 'w', newline='', encoding='utf-8-sig') as f:
			# UTF-8 BOM for Excel compatibility
			writer = csv.writer(f, dialect='excel')

			# Header
			writer.writerow([
				'ID', 'Address', 'Length', 'Original Text',
				'Translation', 'Notes', 'Status'
			])

			count = 0
			for dialog_id in sorted(self.database.dialogs.keys()):
				dialog = self.database.dialogs[dialog_id]

				# Convert newlines to visible format for Excel
				original = dialog.text.replace('\n', '↵')

				writer.writerow([
					f'{dialog_id:04X}',
					f'${dialog.address:06X}',
					dialog.length,
					original,
					'',  # Empty translation
					'',  # Empty notes
					'TODO'
				])

				count += 1

		return count


class DialogImporter:
	"""Import translated dialogs from various formats"""

	def __init__(self, database: DialogDatabase, dialog_text: DialogText):
		"""
		Initialize importer

		Args:
			database: Dialog database to update
			dialog_text: Dialog text handler
		"""
		self.database = database
		self.dialog_text = dialog_text

	def import_from_csv(self, input_path: Path) -> Tuple[int, List[str]]:
		"""
		Import translations from CSV file

		Args:
			input_path: Input CSV file path

		Returns:
			Tuple of (dialogs imported, error messages)
		"""
		errors = []
		count = 0

		with open(input_path, 'r', encoding='utf-8-sig') as f:
			reader = csv.DictReader(f)

			for row in reader:
				try:
					# Parse ID
					id_str = row.get('ID', row.get('id', ''))
					if id_str.startswith('$'):
						id_str = id_str[1:]
					dialog_id = int(id_str, 16)

					# Get translation
					translated = row.get('Translated Text', row.get('Translation', row.get('translated_text', '')))

					if not translated:
						continue  # Skip empty translations

					# Convert visible newlines back
					translated = translated.replace('\\n', '\n').replace('↵', '\n')

					# Validate
					is_valid, messages = self.dialog_text.validate(translated)
					if not is_valid:
						errors.append(f'Dialog {dialog_id:04X}: {", ".join(messages)}')
						continue

					# Update dialog
					if dialog_id in self.database.dialogs:
						dialog = self.database.dialogs[dialog_id]
						dialog.text = translated
						dialog.raw_bytes = self.dialog_text.encode(translated)
						dialog.length = len(dialog.raw_bytes)
						dialog.modified = True
						count += 1
					else:
						errors.append(f'Dialog {dialog_id:04X} not found in database')

				except Exception as e:
					errors.append(f'Error processing row: {str(e)}')

		return count, errors

	def import_from_json(self, input_path: Path) -> Tuple[int, List[str]]:
		"""
		Import translations from JSON file

		Args:
			input_path: Input JSON file path

		Returns:
			Tuple of (dialogs imported, error messages)
		"""
		errors = []
		count = 0

		with open(input_path, 'r', encoding='utf-8') as f:
			data = json.load(f)

		dialogs_data = data.get('dialogs', [])

		for dialog_data in dialogs_data:
			try:
				# Parse ID
				id_str = dialog_data.get('id', '')
				if id_str.startswith('$'):
					id_str = id_str[1:]
				dialog_id = int(id_str, 16)

				# Get translation
				translated = dialog_data.get('translated_text', '')

				if not translated:
					continue

				# Validate
				is_valid, messages = self.dialog_text.validate(translated)
				if not is_valid:
					errors.append(f'Dialog {dialog_id:04X}: {", ".join(messages)}')
					continue

				# Update dialog
				if dialog_id in self.database.dialogs:
					dialog = self.database.dialogs[dialog_id]
					dialog.text = translated
					dialog.raw_bytes = self.dialog_text.encode(translated)
					dialog.length = len(dialog.raw_bytes)
					dialog.modified = True

					# Update metadata if provided
					if 'notes' in dialog_data:
						dialog.notes = dialog_data['notes']

					count += 1
				else:
					errors.append(f'Dialog {dialog_id:04X} not found in database')

			except Exception as e:
				errors.append(f'Error processing dialog: {str(e)}')

		return count, errors

	def import_from_po(self, input_path: Path) -> Tuple[int, List[str]]:
		"""
		Import translations from Gettext PO file

		Args:
			input_path: Input .po file path

		Returns:
			Tuple of (dialogs imported, error messages)
		"""
		errors = []
		count = 0

		with open(input_path, 'r', encoding='utf-8') as f:
			lines = f.readlines()

		i = 0
		while i < len(lines):
			line = lines[i].strip()

			# Look for dialog ID comment
			if line.startswith('# Dialog ID:'):
				try:
					id_str = line.split(':')[1].strip()
					dialog_id = int(id_str, 16)

					# Find msgid (original)
					i += 1
					while i < len(lines) and not lines[i].strip().startswith('msgid'):
						i += 1

					if i >= len(lines):
						break

					# Skip msgid
					i += 1

					# Find msgstr (translation)
					while i < len(lines) and not lines[i].strip().startswith('msgstr'):
						i += 1

					if i >= len(lines):
						break

					# Parse msgstr
					msgstr_line = lines[i].strip()
					if msgstr_line.startswith('msgstr "') and msgstr_line.endswith('"'):
						translated = msgstr_line[8:-1]  # Remove msgstr " and "
						translated = translated.replace('\\"', '"')  # Unescape quotes

						if translated:  # Only process non-empty translations
							# Update dialog
							if dialog_id in self.database.dialogs:
								dialog = self.database.dialogs[dialog_id]
								dialog.text = translated
								dialog.raw_bytes = self.dialog_text.encode(translated)
								dialog.length = len(dialog.raw_bytes)
								dialog.modified = True
								count += 1

				except Exception as e:
					errors.append(f'Error processing PO entry: {str(e)}')

			i += 1

		return count, errors

	def validate_import(self, input_path: Path, format: str = 'auto') -> Tuple[bool, List[str], Dict]:
		"""
		Validate import file without actually importing

		Args:
			input_path: Input file path
			format: File format ('csv', 'json', 'po', or 'auto')

		Returns:
			Tuple of (is_valid, error messages, statistics dict)
		"""
		if format == 'auto':
			# Auto-detect format from extension
			ext = input_path.suffix.lower()
			if ext == '.csv':
				format = 'csv'
			elif ext == '.json':
				format = 'json'
			elif ext == '.po':
				format = 'po'
			else:
				return False, [f'Unknown file format: {ext}'], {}

		errors = []
		stats = {
			'total_entries': 0,
			'valid_translations': 0,
			'empty_translations': 0,
			'invalid_translations': 0,
			'unknown_ids': 0,
			'too_long': 0
		}

		# Read file based on format
		if format == 'csv':
			with open(input_path, 'r', encoding='utf-8-sig') as f:
				reader = csv.DictReader(f)
				for row in reader:
					stats['total_entries'] += 1

					try:
						id_str = row.get('ID', row.get('id', ''))
						if id_str.startswith('$'):
							id_str = id_str[1:]
						dialog_id = int(id_str, 16)

						translated = row.get('Translated Text', row.get('Translation', ''))

						if not translated:
							stats['empty_translations'] += 1
							continue

						translated = translated.replace('\\n', '\n').replace('↵', '\n')

						if dialog_id not in self.database.dialogs:
							stats['unknown_ids'] += 1
							errors.append(f'Unknown dialog ID: {dialog_id:04X}')
							continue

						is_valid, messages = self.dialog_text.validate(translated)
						if is_valid:
							stats['valid_translations'] += 1
						else:
							stats['invalid_translations'] += 1
							errors.extend([f'{dialog_id:04X}: {msg}' for msg in messages])

							if any('exceeds maximum' in msg for msg in messages):
								stats['too_long'] += 1

					except Exception as e:
						stats['invalid_translations'] += 1
						errors.append(f'Error in row: {str(e)}')

		is_valid = stats['invalid_translations'] == 0 and stats['unknown_ids'] == 0

		return is_valid, errors, stats


# Command-line interface
def main():
	"""Main CLI entry point"""
	import argparse

	parser = argparse.ArgumentParser(description='FFMQ Dialog Export/Import Tool')
	subparsers = parser.add_subparsers(dest='command', help='Command to execute')

	# Export command
	export_parser = subparsers.add_parser('export', help='Export dialogs')
	export_parser.add_argument('rom', type=Path, help='ROM file to export from')
	export_parser.add_argument('output', type=Path, help='Output file')
	export_parser.add_argument('--format', choices=['csv', 'json', 'po', 'excel'],
		default='json', help='Export format')
	export_parser.add_argument('--pretty', action='store_true', help='Pretty print JSON')

	# Import command
	import_parser = subparsers.add_parser('import', help='Import translations')
	import_parser.add_argument('rom', type=Path, help='ROM file to import into')
	import_parser.add_argument('input', type=Path, help='Translation file')
	import_parser.add_argument('--format', choices=['csv', 'json', 'po', 'auto'],
		default='auto', help='Import format')
	import_parser.add_argument('--output', type=Path, help='Output ROM file (optional)')
	import_parser.add_argument('--validate-only', action='store_true',
		help='Only validate, don\'t import')

	args = parser.parse_args()

	if args.command == 'export':
		print(f'Exporting dialogs from {args.rom}...')
		# TODO: Load ROM and create database
		db = DialogDatabase()
		dt = DialogText()
		exporter = DialogExporter(db, dt)

		if args.format == 'csv':
			count = exporter.export_to_csv(args.output, include_metadata=True)
		elif args.format == 'excel':
			count = exporter.export_to_excel_compatible_csv(args.output)
		elif args.format == 'po':
			count = exporter.export_to_po(args.output)
		else:  # json
			count = exporter.export_to_json(args.output, pretty=args.pretty)

		print(f'Exported {count} dialogs to {args.output}')

	elif args.command == 'import':
		print(f'Importing translations from {args.input}...')
		# TODO: Load ROM and create database
		db = DialogDatabase()
		dt = DialogText()
		importer = DialogImporter(db, dt)

		if args.validate_only:
			is_valid, errors, stats = importer.validate_import(args.input, args.format)
			print(f'\nValidation Results:')
			print(f'  Total entries: {stats["total_entries"]}')
			print(f'  Valid translations: {stats["valid_translations"]}')
			print(f'  Empty translations: {stats["empty_translations"]}')
			print(f'  Invalid translations: {stats["invalid_translations"]}')
			print(f'  Unknown IDs: {stats["unknown_ids"]}')
			print(f'  Too long: {stats["too_long"]}')

			if errors:
				print(f'\nErrors:')
				for error in errors[:10]:  # Show first 10 errors
					print(f'  - {error}')
				if len(errors) > 10:
					print(f'  ... and {len(errors) - 10} more')

			if is_valid:
				print('\n✓ Import file is valid!')
			else:
				print('\n✗ Import file has errors')
		else:
			# Perform import
			if args.format == 'csv':
				count, errors = importer.import_from_csv(args.input)
			elif args.format == 'po':
				count, errors = importer.import_from_po(args.input)
			else:  # json or auto
				count, errors = importer.import_from_json(args.input)

			print(f'Imported {count} translations')
			if errors:
				print(f'Errors: {len(errors)}')
				for error in errors[:10]:
					print(f'  - {error}')


if __name__ == '__main__':
	main()
