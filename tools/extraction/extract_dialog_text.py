#!/usr/bin/env python3
"""
FFMQ Dialog Text Extractor
Extracts all dialog strings from ROM using DialogDatabase

Uses complex.tbl with DTE compression and control codes
Outputs to CSV, JSON, and text formats

Usage:
	python extract_dialog_text.py <rom_path> [--output-dir data/text_fixed]
"""

import sys
import csv
import json
from pathlib import Path
from datetime import datetime

# Add tools directory to path
sys.path.insert(0, str(Path(__file__).parent.parent / 'map-editor'))
from utils.dialog_database import DialogDatabase


class DialogTextExtractor:
	"""Extract all dialog text from FFMQ ROM"""
	
	def __init__(self, rom_path: Path):
		"""
		Initialize extractor
		
		Args:
			rom_path: Path to FFMQ ROM file
		"""
		self.rom_path = Path(rom_path)
		self.db = DialogDatabase(rom_path)
	
	def extract_all(self) -> dict:
		"""
		Extract all dialogs
		
		Returns:
			Dict with all extracted dialogs
		"""
		print("=" * 70)
		print("FFMQ Dialog Text Extraction")
		print("=" * 70)
		print(f"\nROM: {self.rom_path.name}")
		print("Decoder: DialogText (complex.tbl with DTE compression)")
		print()
		
		# Extract using DialogDatabase
		self.db.extract_all_dialogs()
		
		# Organize results
		dialogs = []
		for dialog_id, entry in sorted(self.db.dialogs.items()):
			if entry and entry.text:
				dialogs.append({
					'id': dialog_id,
					'text': entry.text,
					'address': entry.address,
					'pointer': entry.pointer,
					'length': entry.length
				})
		
		data = {
			'version': '3.0.0',
			'game': 'Final Fantasy Mystic Quest',
			'extraction_date': datetime.now().isoformat(),
			'rom_file': self.rom_path.name,
			'decoder': 'DialogText',
			'character_table': 'complex.tbl',
			'total_dialogs': len(dialogs),
			'dialogs': dialogs
		}
		
		print(f"✓ Extracted {len(dialogs)} dialogs")
		print("=" * 70)
		
		return data
	
	def save_csv(self, data: dict, output_path: Path):
		"""
		Save dialogs as CSV
		
		Args:
			data: Extracted dialog data
			output_path: Output CSV file path
		"""
		output_path = Path(output_path)
		output_path.parent.mkdir(parents=True, exist_ok=True)
		
		with open(output_path, 'w', encoding='utf-8', newline='') as f:
			writer = csv.writer(f)
			writer.writerow(['ID', 'Text', 'Address', 'Pointer', 'Length'])
			
			for entry in data['dialogs']:
				writer.writerow([
					entry['id'],
					entry['text'],
					f"${entry['address']:06X}",
					f"${entry['pointer']:04X}",
					entry['length']
				])
		
		print(f"\n✓ Saved CSV: {output_path}")
	
	def save_json(self, data: dict, output_path: Path):
		"""
		Save all data as JSON
		
		Args:
			data: Extracted dialog data
			output_path: Output file path
		"""
		output_path = Path(output_path)
		output_path.parent.mkdir(parents=True, exist_ok=True)
		
		with open(output_path, 'w', encoding='utf-8') as f:
			json.dump(data, f, indent=2, ensure_ascii=False)
		
		print(f"✓ Saved JSON: {output_path}")
	
	def save_text(self, data: dict, output_path: Path):
		"""
		Save dialogs as human-readable text
		
		Args:
			data: Extracted dialog data
			output_path: Output file path
		"""
		output_path = Path(output_path)
		output_path.parent.mkdir(parents=True, exist_ok=True)
		
		with open(output_path, 'w', encoding='utf-8') as f:
			f.write("DIALOG TEXT\n")
			f.write("=" * 70 + "\n")
			f.write(f"Extracted: {data['extraction_date']}\n")
			f.write(f"Total dialogs: {data['total_dialogs']}\n")
			f.write("=" * 70 + "\n\n")
			
			for entry in data['dialogs']:
				f.write(f"[{entry['id']:3d}] {entry['text']}\n")
				# Add extra line for long dialogs
				if len(entry['text']) > 60:
					f.write("\n")
		
		print(f"✓ Saved text: {output_path}")


def main():
	"""Main entry point"""
	import argparse
	
	parser = argparse.ArgumentParser(
		description='Extract dialog text from FFMQ ROM'
	)
	parser.add_argument(
		'rom_path',
		help='Path to FFMQ ROM file'
	)
	parser.add_argument(
		'--output-dir',
		default='data/text_fixed',
		help='Output directory (default: data/text_fixed)'
	)
	parser.add_argument(
		'--json',
		help='Output JSON file path (optional)'
	)
	
	args = parser.parse_args()
	
	# Extract
	extractor = DialogTextExtractor(Path(args.rom_path))
	data = extractor.extract_all()
	
	if not data or not data['dialogs']:
		print("ERROR: No dialogs extracted")
		return False
	
	# Save outputs
	output_dir = Path(args.output_dir)
	extractor.save_csv(data, output_dir / 'dialog.csv')
	extractor.save_text(data, output_dir / 'dialog.txt')
	
	if args.json:
		extractor.save_json(data, Path(args.json))
	
	print("\n✓ Dialog extraction complete!")
	return True


if __name__ == '__main__':
	success = main()
	sys.exit(0 if success else 1)
