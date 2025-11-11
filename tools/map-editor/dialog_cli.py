"""
FFMQ Dialog Manager - Command-line Interface

Comprehensive CLI tool for managing dialog databases.
"""

import argparse
import sys
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from utils.dialog_database import DialogDatabase
from utils.dialog_validator import DialogValidator
from utils.dialog_exporter import DialogExporter, DialogImporter
from utils.dialog_diff import DialogDiffer
from utils.character_table_optimizer import CharacterTableOptimizer
from utils.batch_dialog_editor import BatchDialogEditor
from utils.dialog_search import DialogSearchEngine, SearchMode


def get_rom_path(args):
	"""Get ROM path from args or use default"""
	if hasattr(args, 'rom') and args.rom:
		return Path(args.rom)

	# Try default locations
	default_paths = [
		Path("roms/Final Fantasy - Mystic Quest (U) (V1.1).sfc"),
		Path("roms/ffmq_rebuilt.sfc"),
		Path("../roms/Final Fantasy - Mystic Quest (U) (V1.1).sfc"),
	]

	for rom_path in default_paths:
		if rom_path.exists():
			return rom_path

	print("ERROR: No ROM file found. Please specify with --rom option")
	print(f"Searched: {', '.join(str(p) for p in default_paths)}")
	sys.exit(1)


def cmd_list(args):
	"""List all dialogs"""
	# Get ROM path
	rom_path = get_rom_path(args)
	db = DialogDatabase(rom_path)
	db.extract_all_dialogs()

	print(f"\nFound {len(db.dialogs)} dialogs")

	if args.verbose:
		for dialog_id, dialog in sorted(db.dialogs.items()):
			print(f"\n0x{dialog_id:04X}: {dialog.text}")
	else:
		# Just show IDs
		ids_per_line = 8
		ids = sorted(db.dialogs.keys())
		for i in range(0, len(ids), ids_per_line):
			line_ids = ids[i:i+ids_per_line]
			print("  " + "  ".join(f"0x{id:04X}" for id in line_ids))


def cmd_show(args):
	"""Show specific dialog"""
	# Get ROM path
	rom_path = get_rom_path(args)
	db = DialogDatabase(rom_path)
	db.extract_all_dialogs()

	dialog_id = int(args.id, 16)

	if dialog_id not in db.dialogs:
		print(f"Error: Dialog 0x{dialog_id:04X} not found")
		return 1

	dialog = db.dialogs[dialog_id]

	print(f"Dialog ID:  0x{dialog_id:04X}")
	print(f"Pointer:    0x{dialog.pointer:06X}")
	print(f"Address:    0x{dialog.address:06X}")
	print(f"Length:     {dialog.length} bytes")

	if dialog.tags:
		print(f"Tags:       {', '.join(sorted(dialog.tags))}")

	if dialog.notes:
		print(f"Notes:      {dialog.notes}")

	print()
	print("Text:")
	print("-" * 70)
	print(dialog.text)
	print("-" * 70)


def cmd_search(args):
	"""Search for dialogs"""
	# Get ROM path
	rom_path = get_rom_path(args)
	db = DialogDatabase(rom_path)
	db.extract_all_dialogs()

	engine = DialogSearchEngine()

	# Determine search mode
	if args.regex:
		mode = SearchMode.REGEX
	elif args.fuzzy:
		mode = SearchMode.FUZZY
	elif args.control_code:
		mode = SearchMode.CONTROL_CODE
	else:
		mode = SearchMode.TEXT

	results = engine.search(
		db.dialogs,
		args.query,
		mode
	)

	print(f"Found {len(results)} results for '{args.query}'")

	if results:
		print()
		for result in results[:args.max_results if hasattr(args, 'max_results') else 50]:
			dialog = db.dialogs[result.dialog_id]
			print(f"0x{result.dialog_id:04X} (score: {result.score:.2f})")

			if args.verbose:
				# Clean up text for display
				import re
				text_clean = re.sub(r'<[0-9A-F]{2}>', '', dialog.text)
				text_clean = re.sub(r'\[[A-Z:]+\]', '', text_clean)
			text_clean = re.sub(r'\s+', ' ', text_clean).strip()
			print(f"  {text_clean[:100]}")
			print()


def cmd_edit(args):
	"""Edit a dialog"""
	# Get ROM path
	rom_path = get_rom_path(args)
	db = DialogDatabase(rom_path)
	db.extract_all_dialogs()

	dialog_id = int(args.id, 16)

	if dialog_id not in db.dialogs:
		print(f"Error: Dialog 0x{dialog_id:04X} not found")
		return 1

	dialog = db.dialogs[dialog_id]

	# Show current text
	print(f"Editing Dialog 0x{dialog_id:04X}")
	print("-" * 70)
	print("Current text:")
	print(dialog.text)
	print("-" * 70)

	# Get new text
	if args.text:
		# Text provided on command line
		new_text = args.text
	else:
		# Interactive mode
		print("\nEnter new text (use [TAG] for control codes, empty line to cancel):")
		lines = []
		while True:
			try:
				line = input()
				if not line:
					if not lines:
						print("Edit cancelled")
						return 0
					break
				lines.append(line)
			except (EOFError, KeyboardInterrupt):
				print("\nEdit cancelled")
				return 0

		new_text = '\n'.join(lines)

	# Validate new text
	is_valid, messages = db.dialog_text.validate(new_text)

	if messages:
		print("\nValidation:")
		for msg in messages:
			print(f"  {msg}")

	if not is_valid:
		print("\nValidation failed - not saving")
		return 1

	# Show preview of encoded bytes
	encoded = db.dialog_text.encode(new_text)
	print(f"\nEncoded to {len(encoded)} bytes (original: {dialog.length} bytes)")

	# Confirm
	if not args.yes:
		response = input("\nSave changes? [y/N]: ")
		if response.lower() != 'y':
			print("Edit cancelled")
			return 0

	# Update dialog
	success = db.update_dialog(dialog_id, new_text)

	if success:
		# Save ROM
		output_path = args.output or rom_path
		if db.save_rom(Path(output_path)):
			print(f"\n✓ Dialog updated and saved to {output_path}")
			return 0
		else:
			print(f"\n✗ Failed to save ROM")
			return 1
	else:
		print(f"\n✗ Failed to update dialog")
		return 1


def cmd_validate(args):
	"""Validate dialog database"""
	db = DialogDatabase()

	# Character table (simplified for now)
	char_table = {i: chr(i) for i in range(128)}

	validator = DialogValidator(db, char_table)
	issues = validator.validate_all()

	if args.report:
		# Full report
		print(validator.generate_report())
	else:
		# Summary
		stats = validator.get_issues_by_severity()
		print(f"Validation complete:")
		print(f"  Errors:   {len(stats['error'])}")
		print(f"  Warnings: {len(stats['warning'])}")
		print(f"  Info:     {len(stats['info'])}")

		if args.verbose and issues:
			print("\nIssues:")
			for issue in issues[:20]:  # Show first 20
				severity_marker = {
					'error': '✗',
					'warning': '⚠',
					'info': 'ℹ'
				}.get(issue.severity, '•')

				print(f"  {severity_marker} 0x{issue.dialog_id:04X}: {issue.message}")


def cmd_export(args):
	"""Export dialog database"""
	import json

	# Get ROM path
	rom_path = get_rom_path(args)
	db = DialogDatabase(rom_path)
	db.extract_all_dialogs()

	print(f"Exporting {len(db.dialogs)} dialogs to {args.output}...")

	if args.format == 'json':
		# Export as JSON
		data = {
			'dialogs': [entry.to_dict() for entry in db.dialogs.values()],
			'count': len(db.dialogs),
			'rom': str(rom_path.name)
		}

		with open(args.output, 'w', encoding='utf-8') as f:
			json.dump(data, f, indent=2, ensure_ascii=False)

		print(f"✓ Exported to {args.output}")

	elif args.format == 'txt':
		# Export as plain text
		with open(args.output, 'w', encoding='utf-8') as f:
			for dialog_id, entry in sorted(db.dialogs.items()):
				f.write(f"Dialog 0x{dialog_id:04X}\n")
				f.write("=" * 70 + "\n")
				f.write(entry.text + "\n")
				f.write("\n")

		print(f"✓ Exported to {args.output}")

	elif args.format == 'csv':
		# Export as CSV
		import csv

		with open(args.output, 'w', newline='', encoding='utf-8') as f:
			writer = csv.writer(f)
			writer.writerow(['ID', 'Pointer', 'Address', 'Length', 'Text'])

			for dialog_id, entry in sorted(db.dialogs.items()):
				writer.writerow([
					f"0x{dialog_id:04X}",
					f"0x{entry.pointer:06X}",
					f"0x{entry.address:06X}",
					entry.length,
					entry.text
				])

		print(f"✓ Exported to {args.output}")

	else:
		print(f"Error: Format '{args.format}' not yet implemented")
		print("Available formats: json, txt, csv")
		return 1


def cmd_import(args):
	"""Import dialog database"""
	db = DialogDatabase()
	importer = DialogImporter(db)

	format_map = {
		'csv': importer.import_from_csv,
		'json': importer.import_from_json,
		'tsv': importer.import_from_tsv
	}

	# Detect format from extension if not specified
	if not args.format:
		ext = Path(args.input).suffix.lstrip('.')
		args.format = ext if ext in format_map else 'json'

	if args.format not in format_map:
		print(f"Error: Unknown format '{args.format}'")
		print(f"Available formats: {', '.join(format_map.keys())}")
		return 1

	print(f"Importing from {args.input}...")
	count = format_map[args.format](args.input, update_existing=not args.no_update)
	print(f"✓ Imported {count} dialogs")


def cmd_optimize(args):
	"""Optimize character table"""
	db = DialogDatabase()
	optimizer = CharacterTableOptimizer()

	# Extract texts
	texts = [dialog.text for dialog in db.dialogs.values()]

	print("Analyzing dialog corpus...")
	candidates = optimizer.analyze_corpus(texts, min_frequency=args.min_frequency)

	print(f"\nFound {len(candidates)} compression candidates")
	print(f"Top {args.top} candidates:")
	print()

	for i, candidate in enumerate(candidates[:args.top], 1):
		seq_display = candidate.sequence.replace(' ', '·').replace('\n', '\\n')
		print(
			f"{i:2}. '{seq_display}' - "
			f"{candidate.byte_savings} bytes saved "
			f"(freq: {candidate.frequency}, score: {candidate.priority_score:.2f})"
		)

	if not args.no_evaluation:
		print()
		eval_result = optimizer.evaluate_compression(texts)
		print(f"Expected compression: {eval_result['compression_ratio']:.1f}%")
		print(f"Bytes saved: {eval_result['bytes_saved']}")
		print(f"Original size: {eval_result['original_bytes']} bytes")
		print(f"Compressed size: {eval_result['compressed_bytes']} bytes")


def cmd_batch(args):
	"""Batch operations"""
	db = DialogDatabase()
	batch_editor = BatchDialogEditor()

	if args.operation == 'replace':
		if not args.find or not args.replace:
			print("Error: --find and --replace are required for replace operation")
			return 1

		print(f"Replacing '{args.find}' with '{args.replace}'...")
		result = batch_editor.find_and_replace(
			db.dialogs,
			args.find,
			args.replace,
			mode="text",
			whole_words=args.whole_words,
			case_sensitive=args.case_sensitive,
			dry_run=args.dry_run
		)

		print(f"Affected {len(result.affected_dialogs)} dialogs")
		print(f"Made {result.changes_made} changes")

		if args.dry_run:
			print("(Dry run - no changes made)")

	elif args.operation == 'reformat':
		if not args.operations:
			print("Error: --operations is required for reformat")
			return 1

		ops = args.operations.split(',')
		print(f"Reformatting with operations: {', '.join(ops)}")

		result = batch_editor.batch_reformat(
			db.dialogs,
			ops,
			dry_run=args.dry_run
		)

		print(f"Affected {len(result.affected_dialogs)} dialogs")

		if args.dry_run:
			print("(Dry run - no changes made)")

	elif args.operation == 'errors':
		errors = batch_editor.find_potential_errors(db.dialogs)

		print(f"Found errors in {len(errors)} dialogs")

		if errors and args.verbose:
			for dialog_id, issues in sorted(errors.items())[:20]:
				print(f"\n0x{dialog_id:04X}:")
			for issue in issues:
				print(f"  • {issue}")


def cmd_stats(args):
	"""Show ROM statistics"""
	# Get ROM path
	rom_path = get_rom_path(args)
	db = DialogDatabase(rom_path)
	db.extract_all_dialogs()

	print("=" * 70)
	print("FFMQ DIALOG DATABASE STATISTICS")
	print("=" * 70)

	# Basic stats
	total_dialogs = len(db.dialogs)
	total_bytes = sum(d.length for d in db.dialogs.values())
	avg_bytes = total_bytes / total_dialogs if total_dialogs > 0 else 0

	print(f"\nDialog Count:")
	print(f"  Total dialogs: {total_dialogs}")
	print(f"  Total bytes: {total_bytes:,}")
	print(f"  Average bytes per dialog: {avg_bytes:.1f}")

	# Size distribution
	sizes = [d.length for d in db.dialogs.values()]
	min_size = min(sizes) if sizes else 0
	max_size = max(sizes) if sizes else 0

	print(f"\nSize Range:")
	print(f"  Smallest dialog: {min_size} bytes")
	print(f"  Largest dialog: {max_size} bytes")

	# Find smallest and largest
	smallest = min(db.dialogs.items(), key=lambda x: x[1].length) if db.dialogs else None
	largest = max(db.dialogs.items(), key=lambda x: x[1].length) if db.dialogs else None

	if smallest:
		print(f"  Smallest: 0x{smallest[0]:04X} ({smallest[1].length} bytes)")
		if args.verbose:
			print(f"    {smallest[1].text[:60]}...")

	if largest:
		print(f"  Largest: 0x{largest[0]:04X} ({largest[1].length} bytes)")
		if args.verbose:
			preview = largest[1].text[:60].replace('\n', ' ')
			print(f"    {preview}...")

	# Control code usage
	print(f"\nControl Code Usage:")
	control_counts = {}

	for dialog in db.dialogs.values():
		# Count control codes in text
		import re
		codes = re.findall(r'\[([A-Z0-9_]+)\]', dialog.text)
		for code in codes:
			control_counts[code] = control_counts.get(code, 0) + 1

	# Top 10 control codes
	top_codes = sorted(control_counts.items(), key=lambda x: x[1], reverse=True)[:10]
	for code, count in top_codes:
		print(f"  [{code:12}]: {count:3} occurrences")

	# Text analysis
	if args.verbose:
		print(f"\nText Analysis:")
		total_chars = sum(len(d.text) for d in db.dialogs.values())
		print(f"  Total characters: {total_chars:,}")
		print(f"  Compression ratio: {(1 - total_bytes / total_chars) * 100:.1f}%")

		# Count unique words
		all_text = ' '.join(d.text for d in db.dialogs.values())
		words = re.findall(r'\b[a-zA-Z]+\b', all_text.lower())
		unique_words = len(set(words))
		print(f"  Unique words: {unique_words:,}")

	print()


def cmd_find(args):
	"""Simple find command - just lists matching dialog IDs"""
	# Get ROM path
	rom_path = get_rom_path(args)
	db = DialogDatabase(rom_path)
	db.extract_all_dialogs()

	search_text = args.text.lower() if args.ignore_case else args.text
	matches = []

	for dialog_id, dialog in db.dialogs.items():
		dialog_text = dialog.text.lower() if args.ignore_case else dialog.text
		if search_text in dialog_text:
			matches.append(dialog_id)

	if args.count_only:
		print(f"{len(matches)} dialogs found")
	else:
		if matches:
			print(f"Found {len(matches)} dialogs containing '{args.text}':")
			# Print in columns
			ids_per_line = 8
			for i in range(0, len(matches), ids_per_line):
				line_ids = matches[i:i+ids_per_line]
				print("  " + "  ".join(f"0x{id:04X}" for id in line_ids))
		else:
			print(f"No dialogs found containing '{args.text}'")


def cmd_count(args):
	"""Count characters/bytes/words in dialogs"""
	# Get ROM path
	rom_path = get_rom_path(args)
	db = DialogDatabase(rom_path)
	db.extract_all_dialogs()

	if args.id:
		# Count specific dialog
		dialog_id = int(args.id, 16)
		if dialog_id not in db.dialogs:
			print(f"Error: Dialog 0x{dialog_id:04X} not found")
			return 1

		dialog = db.dialogs[dialog_id]
		encoded = db.dialog_text.encode(dialog.text)

		print(f"Dialog 0x{dialog_id:04X}:")
		print(f"  Characters: {len(dialog.text)}")
		print(f"  Bytes: {len(encoded)}")
		print(f"  Compression: {(1 - len(encoded) / len(dialog.text)) * 100:.1f}%")

		# Count words
		import re
		words = re.findall(r'\b[a-zA-Z]+\b', dialog.text)
		print(f"  Words: {len(words)}")

		# Count control codes
		codes = re.findall(r'\[([A-Z0-9_]+)\]', dialog.text)
		print(f"  Control codes: {len(codes)}")

	else:
		# Count all dialogs
		total_chars = sum(len(d.text) for d in db.dialogs.values())
		total_bytes = sum(len(db.dialog_text.encode(d.text)) for d in db.dialogs.values())

		print("All dialogs:")
		print(f"  Total characters: {total_chars:,}")
		print(f"  Total bytes: {total_bytes:,}")
		print(f"  Compression: {(1 - total_bytes / total_chars) * 100:.1f}%")


def main():
	"""Main entry point"""
	parser = argparse.ArgumentParser(
		description="FFMQ Dialog Manager - Command-line dialog database management",
		formatter_class=argparse.RawDescriptionHelpFormatter
	)

	# Global options
	parser.add_argument('--rom', type=Path, help='Path to ROM file (default: roms/Final Fantasy - Mystic Quest (U) (V1.1).sfc)')

	subparsers = parser.add_subparsers(dest='command', help='Command to execute')

	# List command
	list_parser = subparsers.add_parser('list', help='List all dialogs')
	list_parser.add_argument('-v', '--verbose', action='store_true', help='Show full text')
	list_parser.set_defaults(func=cmd_list)

	# Show command
	show_parser = subparsers.add_parser('show', help='Show specific dialog')
	show_parser.add_argument('id', help='Dialog ID (hex, e.g., 0x0016)')
	show_parser.set_defaults(func=cmd_show)

	# Search command
	search_parser = subparsers.add_parser('search', help='Search for dialogs')
	search_parser.add_argument('query', help='Search query')
	search_parser.add_argument('-r', '--regex', action='store_true', help='Use regex mode')
	search_parser.add_argument('-f', '--fuzzy', action='store_true', help='Use fuzzy mode')
	search_parser.add_argument('-c', '--control-code', action='store_true', help='Search control codes')
	search_parser.add_argument('-s', '--case-sensitive', action='store_true', help='Case sensitive')
	search_parser.add_argument('-w', '--whole-words', action='store_true', help='Whole words only')
	search_parser.add_argument('-m', '--max-results', type=int, default=50, help='Max results')
	search_parser.add_argument('-v', '--verbose', action='store_true', help='Show full text')
	search_parser.set_defaults(func=cmd_search)

	# Edit command
	edit_parser = subparsers.add_parser('edit', help='Edit a dialog')
	edit_parser.add_argument('id', help='Dialog ID (hex, e.g., 0x0016)')
	edit_parser.add_argument('-t', '--text', help='New text (interactive if not specified)')
	edit_parser.add_argument('-o', '--output', help='Output ROM file (default: overwrite input)')
	edit_parser.add_argument('-y', '--yes', action='store_true', help='Skip confirmation')
	edit_parser.set_defaults(func=cmd_edit)

	# Stats command
	stats_parser = subparsers.add_parser('stats', help='Show ROM statistics')
	stats_parser.add_argument('-v', '--verbose', action='store_true', help='Show detailed analysis')
	stats_parser.set_defaults(func=cmd_stats)

	# Find command (simpler than search)
	find_parser = subparsers.add_parser('find', help='Find dialogs containing text')
	find_parser.add_argument('text', help='Text to find')
	find_parser.add_argument('-i', '--ignore-case', action='store_true', help='Ignore case')
	find_parser.add_argument('-c', '--count-only', action='store_true', help='Show count only')
	find_parser.set_defaults(func=cmd_find)

	# Count command
	count_parser = subparsers.add_parser('count', help='Count characters/bytes/words')
	count_parser.add_argument('id', nargs='?', help='Dialog ID (optional, counts all if omitted)')
	count_parser.set_defaults(func=cmd_count)

	# Validate command
	validate_parser = subparsers.add_parser('validate', help='Validate dialog database')
	validate_parser.add_argument('-r', '--report', action='store_true', help='Generate full report')
	validate_parser.add_argument('-v', '--verbose', action='store_true', help='Show issues')
	validate_parser.set_defaults(func=cmd_validate)

	# Export command
	export_parser = subparsers.add_parser('export', help='Export dialog database')
	export_parser.add_argument('output', help='Output file')
	export_parser.add_argument('-f', '--format', choices=['csv', 'json', 'tsv', 'txt', 'xml'],
	                           default='json', help='Export format')
	export_parser.add_argument('--no-metadata', action='store_true', help='Exclude metadata')
	export_parser.set_defaults(func=cmd_export)

	# Import command
	import_parser = subparsers.add_parser('import', help='Import dialog database')
	import_parser.add_argument('input', help='Input file')
	import_parser.add_argument('-f', '--format', choices=['csv', 'json', 'tsv'],
	                           help='Import format (auto-detect if not specified)')
	import_parser.add_argument('--no-update', action='store_true', help='Don\'t update existing dialogs')
	import_parser.set_defaults(func=cmd_import)

	# Optimize command
	optimize_parser = subparsers.add_parser('optimize', help='Optimize character table')
	optimize_parser.add_argument('-m', '--min-frequency', type=int, default=3,
	                             help='Minimum frequency for candidates')
	optimize_parser.add_argument('-t', '--top', type=int, default=20,
	                             help='Number of top candidates to show')
	optimize_parser.add_argument('--no-evaluation', action='store_true',
	                             help='Skip compression evaluation')
	optimize_parser.set_defaults(func=cmd_optimize)

	# Batch command
	batch_parser = subparsers.add_parser('batch', help='Batch operations')
	batch_parser.add_argument('operation', choices=['replace', 'reformat', 'errors'],
	                          help='Batch operation')
	batch_parser.add_argument('--find', help='Text to find (for replace)')
	batch_parser.add_argument('--replace', help='Replacement text (for replace)')
	batch_parser.add_argument('--operations', help='Reformat operations (comma-separated)')
	batch_parser.add_argument('-w', '--whole-words', action='store_true', help='Whole words only')
	batch_parser.add_argument('-s', '--case-sensitive', action='store_true', help='Case sensitive')
	batch_parser.add_argument('-d', '--dry-run', action='store_true', help='Dry run (no changes)')
	batch_parser.add_argument('-v', '--verbose', action='store_true', help='Verbose output')
	batch_parser.set_defaults(func=cmd_batch)

	args = parser.parse_args()

	if not args.command:
		parser.print_help()
		return 0

	try:
		return args.func(args) or 0
	except Exception as e:
		print(f"Error: {e}")
		import traceback
		traceback.print_exc()
		return 1


if __name__ == '__main__':
	sys.exit(main())
