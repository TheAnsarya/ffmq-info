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
	"""Import dialogs from JSON file"""
	import json
	from pathlib import Path

	# Get ROM path
	rom_path = get_rom_path(args)
	
	# Load the JSON file
	try:
		with open(args.input, 'r', encoding='utf-8') as f:
			data = json.load(f)
	except FileNotFoundError:
		print(f"Error: File not found: {args.input}")
		return 1
	except json.JSONDecodeError as e:
		print(f"Error: Invalid JSON file: {e}")
		return 1

	# Validate JSON structure
	if 'dialogs' not in data:
		print("Error: Invalid JSON format. Expected 'dialogs' key.")
		print("This file may not have been created by the export command.")
		return 1

	dialogs_data = data['dialogs']
	
	if not isinstance(dialogs_data, list):
		print("Error: 'dialogs' must be a list of dialog entries")
		return 1

	print(f"Loading ROM: {rom_path}")
	db = DialogDatabase(rom_path)
	db.extract_all_dialogs()

	# Track statistics
	imported_count = 0
	updated_count = 0
	error_count = 0
	errors = []

	print(f"Importing {len(dialogs_data)} dialogs from {args.input}...")
	print()

	for entry_data in dialogs_data:
		try:
			# Validate entry structure
			if 'id' not in entry_data or 'text' not in entry_data:
				error_msg = f"Skipping entry: missing 'id' or 'text' field"
				errors.append(error_msg)
				error_count += 1
				continue

			dialog_id = entry_data['id']
			
			# Check if this dialog exists in ROM
			if dialog_id not in db.dialogs:
				error_msg = f"Skipping 0x{dialog_id:04X}: not found in ROM"
				errors.append(error_msg)
				error_count += 1
				continue

			# Get the text to import
			new_text = entry_data['text']

			# Validate the new text
			is_valid, messages = db.dialog_text.validate(new_text)
			
			if not is_valid:
				error_msg = f"Skipping 0x{dialog_id:04X}: validation failed: {'; '.join(messages)}"
				errors.append(error_msg)
				error_count += 1
				continue

			# Encode the text
			try:
				encoded = db.dialog_text.encode(new_text)
			except Exception as e:
				error_msg = f"Skipping 0x{dialog_id:04X}: encoding failed: {e}"
				errors.append(error_msg)
				error_count += 1
				continue

			# Check if text has changed
			current_entry = db.dialogs[dialog_id]
			if current_entry.text == new_text:
				# No change, skip
				continue

			# Update the dialog in ROM
			success = db.update_dialog(dialog_id, encoded)
			
			if success:
				updated_count += 1
				if args.verbose:
					print(f"✓ Updated 0x{dialog_id:04X}: {len(encoded)} bytes")
			else:
				error_msg = f"Failed to update 0x{dialog_id:04X}"
				errors.append(error_msg)
				error_count += 1

			imported_count += 1

		except Exception as e:
			error_msg = f"Error processing entry: {e}"
			errors.append(error_msg)
			error_count += 1

	# Display results
	print()
	print("=" * 70)
	print("Import Summary")
	print("=" * 70)
	print(f"Processed: {imported_count} dialogs")
	print(f"Updated:   {updated_count} dialogs")
	print(f"Errors:    {error_count}")
	print()

	if errors and args.verbose:
		print("Errors:")
		for error in errors[:10]:  # Show first 10 errors
			print(f"  • {error}")
		if len(errors) > 10:
			print(f"  ... and {len(errors) - 10} more errors")
		print()

	if updated_count == 0:
		print("No dialogs were updated. Nothing to save.")
		return 0

	# Ask for confirmation before saving
	if not args.yes:
		response = input(f"Save changes to ROM ({updated_count} dialogs modified)? [y/N] ")
		if response.lower() != 'y':
			print("Import cancelled. ROM not modified.")
			return 0

	# Save the modified ROM
	output_path = args.output if args.output else rom_path
	
	try:
		db.save_rom(output_path)
		print(f"✓ ROM saved to {output_path}")
		print(f"✓ Successfully imported {updated_count} dialogs")
	except Exception as e:
		print(f"Error saving ROM: {e}")
		return 1

	return 0



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


def cmd_diff(args):
	"""Compare dialogs between two ROMs"""
	from pathlib import Path

	# Load both ROMs
	rom1_path = Path(args.rom1)
	rom2_path = Path(args.rom2)

	if not rom1_path.exists():
		print(f"Error: ROM 1 not found: {rom1_path}")
		return 1

	if not rom2_path.exists():
		print(f"Error: ROM 2 not found: {rom2_path}")
		return 1

	print(f"Comparing ROMs:")
	print(f"  ROM 1: {rom1_path.name}")
	print(f"  ROM 2: {rom2_path.name}")
	print()

	db1 = DialogDatabase(rom1_path)
	db1.extract_all_dialogs()

	db2 = DialogDatabase(rom2_path)
	db2.extract_all_dialogs()

	# Find differences
	changed = []
	added = []
	removed = []

	all_ids = set(db1.dialogs.keys()) | set(db2.dialogs.keys())

	for dialog_id in sorted(all_ids):
		if dialog_id not in db1.dialogs:
			added.append(dialog_id)
		elif dialog_id not in db2.dialogs:
			removed.append(dialog_id)
		elif db1.dialogs[dialog_id].text != db2.dialogs[dialog_id].text:
			changed.append(dialog_id)

	# Show summary
	print("Summary:")
	print(f"  Changed: {len(changed)}")
	print(f"  Added: {len(added)}")
	print(f"  Removed: {len(removed)}")
	print(f"  Unchanged: {len(all_ids) - len(changed) - len(added) - len(removed)}")
	print()

	# Show details if requested
	if args.verbose and changed:
		print("Changed dialogs:")
		for dialog_id in changed[:args.max_diff if args.max_diff else 10]:
			print(f"\n0x{dialog_id:04X}:")
			print(f"  ROM 1: {db1.dialogs[dialog_id].text[:60]}...")
			print(f"  ROM 2: {db2.dialogs[dialog_id].text[:60]}...")

	if not args.verbose and (changed or added or removed):
		print("Changed dialog IDs:")
		if changed:
			ids_per_line = 8
			for i in range(0, len(changed), ids_per_line):
				line_ids = changed[i:i+ids_per_line]
				print("  " + "  ".join(f"0x{id:04X}" for id in line_ids))


def cmd_extract(args):
	"""Extract dialog text to file"""
	# Get ROM path
	rom_path = get_rom_path(args)
	db = DialogDatabase(rom_path)
	db.extract_all_dialogs()

	dialog_id = int(args.id, 16)

	if dialog_id not in db.dialogs:
		print(f"Error: Dialog 0x{dialog_id:04X} not found")
		return 1

	dialog = db.dialogs[dialog_id]

	# Determine output file
	if args.output:
		output_file = args.output
	else:
		output_file = f"dialog_{dialog_id:04X}.txt"

	# Write to file
	with open(output_file, 'w', encoding='utf-8') as f:
		if args.with_metadata:
			f.write(f"Dialog ID: 0x{dialog_id:04X}\n")
			f.write(f"Pointer: 0x{dialog.pointer:06X}\n")
			f.write(f"Address: 0x{dialog.address:06X}\n")
			f.write(f"Length: {dialog.length} bytes\n")
			f.write("\n")

		f.write(dialog.text)

		if not dialog.text.endswith('\n'):
			f.write('\n')

	print(f"✓ Extracted dialog 0x{dialog_id:04X} to {output_file}")
	print(f"  Length: {dialog.length} bytes")


def cmd_replace(args):
	"""Find and replace text across all dialogs"""
	# Get ROM path
	rom_path = get_rom_path(args)
	db = DialogDatabase(rom_path)
	db.extract_all_dialogs()

	find_text = args.find
	replace_text = args.replace

	# Find matches
	matches = []
	for dialog_id, dialog in db.dialogs.items():
		if args.ignore_case:
			if find_text.lower() in dialog.text.lower():
				matches.append(dialog_id)
		else:
			if find_text in dialog.text:
				matches.append(dialog_id)

	if not matches:
		print(f"No dialogs found containing '{find_text}'")
		return 0

	print(f"Found {len(matches)} dialogs containing '{find_text}'")

	if args.dry_run:
		print("\n[DRY RUN - No changes will be made]")

	# Show preview
	print(f"\nReplacing '{find_text}' with '{replace_text}'")
	print()

	updated_count = 0
	error_count = 0

	for dialog_id in matches:
		dialog = db.dialogs[dialog_id]

		# Perform replacement
		if args.ignore_case:
			import re
			pattern = re.compile(re.escape(find_text), re.IGNORECASE)
			new_text = pattern.sub(replace_text, dialog.text)
		else:
			new_text = dialog.text.replace(find_text, replace_text)

		if new_text == dialog.text:
			continue  # No change

		# Validate
		is_valid, messages = db.dialog_text.validate(new_text)

		if not is_valid:
			print(f"✗ 0x{dialog_id:04X}: Validation failed")
			for msg in messages:
				print(f"    {msg}")
			error_count += 1
			continue

		# Show preview
		if args.verbose or args.dry_run:
			old_preview = dialog.text[:50].replace('\n', ' ')
			new_preview = new_text[:50].replace('\n', ' ')
			print(f"0x{dialog_id:04X}:")
			print(f"  Old: {old_preview}...")
			print(f"  New: {new_preview}...")

		# Update (unless dry run)
		if not args.dry_run:
			if db.update_dialog(dialog_id, new_text):
				updated_count += 1
			else:
				error_count += 1
				print(f"✗ 0x{dialog_id:04X}: Update failed")
		else:
			updated_count += 1

	print()
	print(f"Summary:")
	print(f"  Matched: {len(matches)}")
	print(f"  Updated: {updated_count}")
	print(f"  Errors: {error_count}")

	if not args.dry_run and updated_count > 0:
		# Save ROM
		output_path = args.output or rom_path
		if db.save_rom(Path(output_path)):
			print(f"\n✓ Saved to {output_path}")
			return 0
		else:
			print(f"\n✗ Failed to save ROM")
			return 1

	return 0


def cmd_verify(args):
	"""Verify ROM integrity"""
	# Get ROM path
	rom_path = get_rom_path(args)

	print(f"Verifying ROM: {rom_path.name}")
	print("=" * 70)

	# Check file exists
	if not rom_path.exists():
		print("✗ ROM file not found")
		return 1

	# Check file size
	rom_size = rom_path.stat().st_size
	expected_size = 524288  # 512 KiB

	print(f"\n[1/5] File size check:")
	if rom_size == expected_size:
		print(f"  ✓ ROM size correct: {rom_size:,} bytes (512 KiB)")
	else:
		print(f"  ✗ ROM size incorrect: {rom_size:,} bytes (expected {expected_size:,})")
		if not args.force:
			return 1

	# Load ROM
	print(f"\n[2/5] ROM loading:")
	try:
		db = DialogDatabase(rom_path)
		print(f"  ✓ ROM loaded successfully")
	except Exception as e:
		print(f"  ✗ Failed to load ROM: {e}")
		return 1

	# Extract dialogs
	print(f"\n[3/5] Dialog extraction:")
	try:
		db.extract_all_dialogs()
		dialog_count = len(db.dialogs)
		print(f"  ✓ Extracted {dialog_count} dialogs")

		if dialog_count < 100:
			print(f"  ⚠ Warning: Low dialog count (expected ~116)")
	except Exception as e:
		print(f"  ✗ Failed to extract dialogs: {e}")
		return 1

	# Validate dialogs
	print(f"\n[4/5] Dialog validation:")
	invalid_count = 0
	warning_count = 0

	for dialog_id, dialog in db.dialogs.items():
		is_valid, messages = db.dialog_text.validate(dialog.text)

		if not is_valid:
			invalid_count += 1
			if args.verbose:
				print(f"  ✗ 0x{dialog_id:04X}: {messages[0] if messages else 'Invalid'}")
		elif messages and args.verbose:
			# Has warnings
			warning_count += 1

	if invalid_count == 0:
		print(f"  ✓ All dialogs valid")
	else:
		print(f"  ✗ {invalid_count} invalid dialogs")
		if not args.force:
			return 1

	if warning_count > 0 and args.verbose:
		print(f"  ⚠ {warning_count} dialogs with warnings")

	# Round-trip test
	print(f"\n[5/5] Round-trip encoding test:")
	errors = 0
	skipped = 0

	for dialog_id, dialog in list(db.dialogs.items())[:10]:  # Test first 10
		# Skip dialogs with unknown bytes
		if '<' in dialog.text and '>' in dialog.text:
			skipped += 1
			if args.verbose:
				print(f"  ⚠ 0x{dialog_id:04X}: Skipped (contains unknown bytes)")
			continue

		encoded = db.dialog_text.encode(dialog.text, add_end=True)
		decoded = db.dialog_text.decode(encoded, include_end=True)

		# Compare (ignoring [END] differences)
		original_clean = dialog.text.replace('[END]', '').strip()
		decoded_clean = decoded.replace('[END]', '').strip()

		if original_clean != decoded_clean:
			errors += 1
			if args.verbose:
				print(f"  ✗ 0x{dialog_id:04X}: Round-trip failed")

	tested = min(10, len(db.dialogs)) - skipped

	if errors == 0:
		print(f"  ✓ Round-trip encoding successful (tested {tested} dialogs)")
		if skipped > 0:
			print(f"    Skipped {skipped} dialogs with unknown bytes")
	else:
		print(f"  ✗ {errors} round-trip failures")
		return 1	# Summary
	print(f"\n" + "=" * 70)
	print(f"VERIFICATION COMPLETE")
	print(f"✓ ROM is valid and working correctly")

	if args.stats:
		print(f"\nQuick Stats:")
		print(f"  Dialogs: {len(db.dialogs)}")
		print(f"  Total bytes: {sum(d.length for d in db.dialogs.values()):,}")
		print(f"  Average: {sum(d.length for d in db.dialogs.values()) / len(db.dialogs):.1f} bytes/dialog")

	return 0


def cmd_backup(args):
	"""Create a backup of the ROM"""
	import shutil
	from datetime import datetime

	# Get ROM path
	rom_path = get_rom_path(args)

	if not rom_path.exists():
		print(f"Error: ROM not found: {rom_path}")
		return 1

	# Determine backup path
	if args.output:
		backup_path = Path(args.output)
	else:
		# Auto-generate backup name with timestamp
		if args.timestamp:
			timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
			backup_path = rom_path.with_suffix(f".{timestamp}.bak")
		else:
			backup_path = rom_path.with_suffix(".bak")

	# Check if backup already exists
	if backup_path.exists() and not args.force:
		print(f"Error: Backup already exists: {backup_path}")
		print("Use --force to overwrite")
		return 1

	# Create backup
	try:
		shutil.copy2(rom_path, backup_path)
		print(f"✓ Backup created: {backup_path}")
		print(f"  Size: {backup_path.stat().st_size:,} bytes")

		if args.verify:
			# Verify backup
			import filecmp
			if filecmp.cmp(rom_path, backup_path, shallow=False):
				print(f"  ✓ Backup verified (identical to original)")
			else:
				print(f"  ✗ Warning: Backup differs from original")
				return 1

		return 0
	except Exception as e:
		print(f"✗ Failed to create backup: {e}")
		return 1


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

	# Diff command
	diff_parser = subparsers.add_parser('diff', help='Compare dialogs between two ROMs')
	diff_parser.add_argument('rom1', help='First ROM file')
	diff_parser.add_argument('rom2', help='Second ROM file')
	diff_parser.add_argument('-v', '--verbose', action='store_true', help='Show detailed changes')
	diff_parser.add_argument('-m', '--max-diff', type=int, help='Max differences to show')
	diff_parser.set_defaults(func=cmd_diff)

	# Extract command
	extract_parser = subparsers.add_parser('extract', help='Extract dialog text to file')
	extract_parser.add_argument('id', help='Dialog ID (hex)')
	extract_parser.add_argument('-o', '--output', help='Output file (default: dialog_XXXX.txt)')
	extract_parser.add_argument('-m', '--with-metadata', action='store_true', help='Include metadata in file')
	extract_parser.set_defaults(func=cmd_extract)

	# Replace command
	replace_parser = subparsers.add_parser('replace', help='Find and replace text across all dialogs')
	replace_parser.add_argument('find', help='Text to find')
	replace_parser.add_argument('replace', help='Replacement text')
	replace_parser.add_argument('-i', '--ignore-case', action='store_true', help='Ignore case')
	replace_parser.add_argument('-d', '--dry-run', action='store_true', help='Preview changes without saving')
	replace_parser.add_argument('-v', '--verbose', action='store_true', help='Show all changes')
	replace_parser.add_argument('-o', '--output', help='Output ROM file (default: overwrite input)')
	replace_parser.set_defaults(func=cmd_replace)

	# Verify command
	verify_parser = subparsers.add_parser('verify', help='Verify ROM integrity')
	verify_parser.add_argument('-v', '--verbose', action='store_true', help='Show detailed results')
	verify_parser.add_argument('-s', '--stats', action='store_true', help='Show quick stats')
	verify_parser.add_argument('-f', '--force', action='store_true', help='Continue despite errors')
	verify_parser.set_defaults(func=cmd_verify)

	# Backup command
	backup_parser = subparsers.add_parser('backup', help='Create ROM backup')
	backup_parser.add_argument('-o', '--output', help='Backup file path (default: ROM_NAME.bak)')
	backup_parser.add_argument('-t', '--timestamp', action='store_true', help='Add timestamp to backup name')
	backup_parser.add_argument('-f', '--force', action='store_true', help='Overwrite existing backup')
	backup_parser.add_argument('-v', '--verify', action='store_true', help='Verify backup integrity')
	backup_parser.set_defaults(func=cmd_backup)

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
	import_parser = subparsers.add_parser('import', help='Import dialogs from JSON file')
	import_parser.add_argument('input', help='Input JSON file (created by export command)')
	import_parser.add_argument('-o', '--output', help='Output ROM file (default: modify input ROM)')
	import_parser.add_argument('-y', '--yes', action='store_true', help='Skip confirmation prompt')
	import_parser.add_argument('-v', '--verbose', action='store_true', help='Show detailed progress')
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
