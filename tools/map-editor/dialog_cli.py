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


def cmd_list(args):
	"""List all dialogs"""
	db = DialogDatabase()
	
	# Load database
	if args.file:
		print(f"Loading dialogs from {args.file}...")
		# Would load from file here
	
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
	db = DialogDatabase()
	
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
	db = DialogDatabase()
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
		args.query,
		mode,
		dialogs=db.dialogs,
		case_sensitive=args.case_sensitive,
		whole_words=args.whole_words,
		max_results=args.max_results
	)
	
	print(f"Found {len(results)} results for '{args.query}'")
	
	if results:
		print()
		for result in results:
			dialog = db.dialogs[result.dialog_id]
			print(f"0x{result.dialog_id:04X} (score: {result.score:.2f})")
			
			if args.verbose:
				print(f"  {dialog.text}")
				print()


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
	db = DialogDatabase()
	exporter = DialogExporter(db)
	
	format_map = {
		'csv': exporter.export_to_csv,
		'json': exporter.export_to_json,
		'tsv': exporter.export_to_tsv,
		'txt': exporter.export_to_txt,
		'xml': exporter.export_to_xml
	}
	
	if args.format not in format_map:
		print(f"Error: Unknown format '{args.format}'")
		print(f"Available formats: {', '.join(format_map.keys())}")
		return 1
	
	print(f"Exporting to {args.output}...")
	format_map[args.format](args.output, include_metadata=not args.no_metadata)
	print(f"✓ Exported {len(db.dialogs)} dialogs")


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


def main():
	"""Main entry point"""
	parser = argparse.ArgumentParser(
		description="FFMQ Dialog Manager - Command-line dialog database management",
		formatter_class=argparse.RawDescriptionHelpFormatter
	)
	
	subparsers = parser.add_subparsers(dest='command', help='Command to execute')
	
	# List command
	list_parser = subparsers.add_parser('list', help='List all dialogs')
	list_parser.add_argument('-f', '--file', help='Database file to load')
	list_parser.add_argument('-v', '--verbose', action='store_true', help='Show full text')
	list_parser.set_defaults(func=cmd_list)
	
	# Show command
	show_parser = subparsers.add_parser('show', help='Show specific dialog')
	show_parser.add_argument('id', help='Dialog ID (hex, e.g., 0x0001)')
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
