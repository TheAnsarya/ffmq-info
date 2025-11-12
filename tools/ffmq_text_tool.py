#!/usr/bin/env python3
"""
FFMQ Text Toolkit - Unified CLI Tool
Comprehensive text extraction, insertion, and analysis for Final Fantasy Mystic Quest.

Features:
- Extract simple strings (item names, menus)
- Extract complex dialogs (dictionary-compressed)
- Insert modified text back into ROM
- Validate text integrity (round-trip testing)
- Analyze compression efficiency
- Batch processing capabilities

Usage:
	python ffmq_text_tool.py extract-simple <rom> <output.json>
	python ffmq_text_tool.py extract-complex <rom> <output.json>
	python ffmq_text_tool.py insert-simple <rom> <input.json> <output_rom>
	python ffmq_text_tool.py insert-complex <rom> <input.json> <output_rom>
	python ffmq_text_tool.py validate <rom> <json>
	python ffmq_text_tool.py analyze <rom>
	python ffmq_text_tool.py batch <commands.txt>

Author: FFMQ Disassembly Project
Date: 2025-11-12
"""

import sys
import json
import argparse
from pathlib import Path
from typing import Dict, List, Optional, Tuple

# Import our extraction/insertion modules
sys.path.insert(0, str(Path(__file__).parent / 'extraction'))
sys.path.insert(0, str(Path(__file__).parent / 'insertion'))

try:
	from extract_all_dialogs import DialogExtractor
except ImportError:
	DialogExtractor = None

try:
	from import_complex_text import ComplexTextInserter
except ImportError:
	ComplexTextInserter = None

try:
	from extract_simple_text import SimpleTextExtractor
except ImportError:
	SimpleTextExtractor = None


class FFMQTextTool:
	"""Main text toolkit class."""
	
	def __init__(self, rom_path: str, table_path: str = 'complex.tbl'):
		self.rom_path = Path(rom_path)
		self.table_path = table_path
		self.rom = None
		
	def extract_complex_dialogs(self, output_path: str, format: str = 'json'):
		"""Extract all dictionary-compressed dialogs."""
		print(f"{'='*80}")
		print(f"EXTRACTING COMPLEX DIALOGS")
		print(f"{'='*80}\n")
		
		if DialogExtractor is None:
			print("❌ Error: DialogExtractor module not found")
			return False
		
		extractor = DialogExtractor(str(self.rom_path))
		extractor.load_rom()
		extractor.load_char_table(self.table_path)
		extractor.load_dictionary()
		
		# Extract all dialogs
		dialogs = {}
		for i in range(117):
			text, raw_bytes = extractor.extract_dialog(i)
			dialogs[f"0x{i:02X}"] = {
				'id': i,
				'text': text,
				'length': len(raw_bytes),
				'raw_hex': raw_bytes.hex(' ')
			}
		
		# Save to file
		output = Path(output_path)
		
		if format == 'json':
			with output.open('w', encoding='utf-8') as f:
				json.dump(dialogs, f, indent='\t', ensure_ascii=False)
			print(f"✅ Saved {len(dialogs)} dialogs to {output_path} (JSON)")
		
		elif format == 'tsv':
			with output.open('w', encoding='utf-8') as f:
				f.write("ID\tHex\tLength\tText\n")
				for dialog_id, data in dialogs.items():
					text = data['text'].replace('\n', '\\n').replace('\t', '\\t')
					f.write(f"{data['id']}\t{dialog_id}\t{data['length']}\t{text}\n")
			print(f"✅ Saved {len(dialogs)} dialogs to {output_path} (TSV)")
		
		elif format == 'txt':
			with output.open('w', encoding='utf-8') as f:
				for dialog_id, data in dialogs.items():
					f.write(f"{'='*80}\n")
					f.write(f"Dialog {dialog_id} (ID: {data['id']}, Length: {data['length']} bytes)\n")
					f.write(f"{'='*80}\n")
					f.write(f"{data['text']}\n\n")
			print(f"✅ Saved {len(dialogs)} dialogs to {output_path} (TXT)")
		
		else:
			print(f"❌ Unknown format: {format}")
			return False
		
		return True
	
	def extract_simple_strings(self, output_path: str, format: str = 'json'):
		"""Extract simple (non-compressed) strings like item names."""
		print(f"{'='*80}")
		print(f"EXTRACTING SIMPLE STRINGS")
		print(f"{'='*80}\n")
		
		if SimpleTextExtractor is None:
			print("❌ Error: SimpleTextExtractor module not found")
			return False
		
		# Use the simple text extractor
		extractor = SimpleTextExtractor(self.rom_path)
		all_text = extractor.extract_all()
		
		if not all_text:
			print("❌ Failed to extract simple strings")
			return False
		
		# Save based on format
		output = Path(output_path)
		
		if format == 'json':
			extractor.save_json(all_text, output)
			print(f"✅ Extracted {all_text['total_entries']} strings to {output_path}")
		
		elif format == 'csv':
			output_dir = output.parent / 'simple_strings'
			extractor.save_csv(all_text, output_dir)
			print(f"✅ Extracted {all_text['total_entries']} strings to {output_dir}/")
		
		elif format == 'txt':
			output_dir = output.parent / 'simple_strings'
			extractor.save_text(all_text, output_dir)
			print(f"✅ Extracted {all_text['total_entries']} strings to {output_dir}/")
		
		else:
			print(f"❌ Unknown format: {format}")
			return False
		
		return True
	
	def insert_complex_dialogs(self, input_path: str, output_rom: str):
		"""Insert modified dialogs into ROM."""
		print(f"{'='*80}")
		print(f"INSERTING COMPLEX DIALOGS")
		print(f"{'='*80}\n")
		
		if ComplexTextInserter is None:
			print("❌ Error: ComplexTextInserter module not found")
			return False
		
		inserter = ComplexTextInserter(str(self.rom_path), self.table_path)
		inserter.run(input_path, output_rom)
		
		return True
	
	def validate_dialogs(self, json_path: str):
		"""Validate dialog integrity (round-trip test)."""
		print(f"{'='*80}")
		print(f"VALIDATING DIALOG INTEGRITY")
		print(f"{'='*80}\n")
		
		if DialogExtractor is None or ComplexTextInserter is None:
			print("❌ Error: Required modules not found")
			return False
		
		# Load dialogs from JSON
		with open(json_path, 'r', encoding='utf-8') as f:
			dialogs = json.load(f)
		
		# Setup inserter for compression testing
		inserter = ComplexTextInserter(str(self.rom_path), self.table_path)
		inserter.load_rom()
		inserter.load_character_table()
		inserter.load_dictionary()
		
		# Test each dialog
		passed = 0
		failed = 0
		
		for dialog_id, data in dialogs.items():
			dialog_num = data['id']
			original_text = data['text']
			
			if inserter.validate_round_trip(dialog_num, original_text):
				passed += 1
			else:
				failed += 1
		
		print(f"\n{'='*80}")
		print(f"VALIDATION RESULTS")
		print(f"{'='*80}")
		print(f"✅ Passed: {passed}")
		print(f"❌ Failed: {failed}")
		print(f"Total:	{passed + failed}")
		print(f"Success:  {passed * 100 / (passed + failed):.1f}%")
		
		return failed == 0
	
	def analyze_rom(self):
		"""Analyze ROM text compression and structure."""
		print(f"{'='*80}")
		print(f"ROM TEXT ANALYSIS")
		print(f"{'='*80}\n")
		
		if DialogExtractor is None:
			print("❌ Error: DialogExtractor module not found")
			return False
		
		extractor = DialogExtractor(str(self.rom_path))
		extractor.load_rom()
		extractor.load_char_table(self.table_path)
		extractor.load_dictionary()
		
		# Analyze dialogs
		total_text_length = 0
		total_compressed_length = 0
		
		for i in range(117):
			text, raw_bytes = extractor.extract_dialog(i)
			total_text_length += len(text)
			total_compressed_length += len(raw_bytes)
		
		compression_ratio = total_compressed_length / total_text_length if total_text_length > 0 else 0
		
		print("Dialog Statistics:")
		print(f"  Total dialogs:		117")
		print(f"  Total text length:	{total_text_length:,} characters")
		print(f"  Total compressed:	 {total_compressed_length:,} bytes")
		print(f"  Compression ratio:	{compression_ratio:.2f} ({compression_ratio * 100:.1f}%)")
		print(f"  Space saved:		  {total_text_length - total_compressed_length:,} bytes")
		
		# Analyze dictionary
		print(f"\nDictionary Statistics:")
		print(f"  Dictionary entries:   80")
		print(f"  Entry range:		  0x30-0x7F")
		
		# Count dictionary usage
		dict_usage = {i: 0 for i in range(0x30, 0x80)}
		for i in range(117):
			_, raw_bytes = extractor.extract_dialog(i)
			for byte in raw_bytes:
				if 0x30 <= byte < 0x80:
					dict_usage[byte] += 1
		
		most_used = sorted(dict_usage.items(), key=lambda x: x[1], reverse=True)[:10]
		print(f"\n  Most used dictionary entries:")
		for byte_val, count in most_used:
			entry_text = extractor.dictionary.get(byte_val, '???')[:20]
			print(f"	0x{byte_val:02X} ({count:4}×): {entry_text}")
		
		return True
	
	def batch_process(self, commands_file: str):
		"""Process multiple commands from a file."""
		print(f"{'='*80}")
		print(f"BATCH PROCESSING: {commands_file}")
		print(f"{'='*80}\n")
		
		with open(commands_file, 'r', encoding='utf-8') as f:
			commands = [line.strip() for line in f if line.strip() and not line.startswith('#')]
		
		for i, cmd in enumerate(commands, 1):
			print(f"\n[{i}/{len(commands)}] {cmd}")
			print("-" * 80)
			
			# Parse and execute command
			args = cmd.split()
			if not args:
				continue
			
			# Route to appropriate method
			action = args[0]
			if action == 'extract-complex':
				self.extract_complex_dialogs(args[2], args[3] if len(args) > 3 else 'json')
			elif action == 'extract-simple':
				self.extract_simple_strings(args[2])
			elif action == 'insert-complex':
				self.insert_complex_dialogs(args[2], args[3])
			elif action == 'validate':
				self.validate_dialogs(args[1])
			elif action == 'analyze':
				self.analyze_rom()
			else:
				print(f"⚠️  Unknown action: {action}")
		
		print(f"\n{'='*80}")
		print(f"✅ BATCH PROCESSING COMPLETE")
		print(f"{'='*80}")
		
		return True


def main():
	"""Main entry point with argument parsing."""
	parser = argparse.ArgumentParser(
		description='FFMQ Text Toolkit - Extract, insert, and analyze game text',
		formatter_class=argparse.RawDescriptionHelpFormatter,
		epilog="""
Examples:
  Extract all dialogs to JSON:
	python ffmq_text_tool.py extract-complex roms/ffmq.sfc data/dialogs.json

  Extract dialogs to TSV (spreadsheet-friendly):
	python ffmq_text_tool.py extract-complex roms/ffmq.sfc data/dialogs.tsv --format tsv

  Insert modified dialogs:
	python ffmq_text_tool.py insert-complex roms/ffmq.sfc data/dialogs_edited.json roms/ffmq_modified.sfc

  Validate text integrity:
	python ffmq_text_tool.py validate roms/ffmq.sfc data/dialogs.json

  Analyze ROM text:
	python ffmq_text_tool.py analyze roms/ffmq.sfc

  Batch processing:
	python ffmq_text_tool.py batch scripts/text_operations.txt
		"""
	)
	
	parser.add_argument('action', choices=[
		'extract-complex', 'extract-simple',
		'insert-complex', 'insert-simple',
		'validate', 'analyze', 'batch'
	], help='Action to perform')
	
	parser.add_argument('rom', help='Path to ROM file')
	parser.add_argument('args', nargs='*', help='Additional arguments for the action')
	parser.add_argument('--table', default='complex.tbl', help='Character table file (default: complex.tbl)')
	parser.add_argument('--format', choices=['json', 'tsv', 'txt'], default='json', help='Output format for extraction')
	
	args = parser.parse_args()
	
	# Create tool instance
	tool = FFMQTextTool(args.rom, args.table)
	
	# Execute action
	success = False
	
	if args.action == 'extract-complex':
		if len(args.args) < 1:
			print("❌ Error: Missing output file")
			print("Usage: extract-complex <rom> <output.json>")
			return 1
		success = tool.extract_complex_dialogs(args.args[0], args.format)
	
	elif args.action == 'extract-simple':
		if len(args.args) < 1:
			print("❌ Error: Missing output file")
			print("Usage: extract-simple <rom> <output.json>")
			return 1
		success = tool.extract_simple_strings(args.args[0], args.format)
	
	elif args.action == 'insert-complex':
		if len(args.args) < 2:
			print("❌ Error: Missing input or output file")
			print("Usage: insert-complex <rom> <input.json> <output_rom>")
			return 1
		success = tool.insert_complex_dialogs(args.args[0], args.args[1])
	
	elif args.action == 'validate':
		if len(args.args) < 1:
			print("❌ Error: Missing JSON file")
			print("Usage: validate <rom> <dialogs.json>")
			return 1
		success = tool.validate_dialogs(args.args[0])
	
	elif args.action == 'analyze':
		success = tool.analyze_rom()
	
	elif args.action == 'batch':
		if len(args.args) < 1:
			print("❌ Error: Missing batch commands file")
			print("Usage: batch <rom> <commands.txt>")
			return 1
		success = tool.batch_process(args.args[0])
	
	return 0 if success else 1


if __name__ == '__main__':
	sys.exit(main())
