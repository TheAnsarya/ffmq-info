#!/usr/bin/env python3
"""
ROM Byte-Level Dialog Analyzer

Analyzes known dialogs at byte level to deduce correct DTE mappings.
Compares ROM bytes with expected English text to reverse-engineer the character table.

Strategy:
1. Extract known dialog bytes from ROM
2. Align with expected English text
3. Deduce byte→character mappings
4. Generate corrected complex.tbl

Usage:
	python tools/analysis/analyze_dialog_bytes.py <rom_path>

Output:
	- Byte-to-character frequency analysis
	- Suggested DTE table corrections
	- Updated complex.tbl file
"""

import sys
from pathlib import Path
from typing import Dict, List, Tuple, Optional
from collections import Counter, defaultdict

# Add map-editor utils to path (from tools/analysis/ → tools/map-editor/)
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root / 'tools' / 'map-editor'))
from utils.dialog_database import DialogDatabase
from utils.dialog_text import CharacterTable, DialogText


# Known dialog texts from game (verified in-game or from screenshots)
KNOWN_DIALOGS = {
	0x00: "Welcome to the world of Final Fantasy Mystic Quest!",
	0x21: "Go to the Focus Tower.",
	0x59: "For years Mac's been studying a Prophecy that speaks of a Knight who'll save the world from the Dark King.",
}


class DialogByteAnalyzer:
	"""Analyze dialog bytes to deduce DTE mappings"""
	
	def __init__(self, rom_path: Path):
		"""
		Initialize analyzer
		
		Args:
			rom_path: Path to ROM file
		"""
		self.rom_path = Path(rom_path)
		self.db = DialogDatabase(rom_path)
		self.char_table = CharacterTable()
		
		# Analysis results
		self.byte_counts = Counter()
		self.byte_contexts = defaultdict(list)
		self.deduced_mappings = {}
	
	def load_rom(self) -> bool:
		"""Load ROM and dialog database"""
		try:
			# DialogDatabase loads ROM in __init__ if path provided
			print(f"[OK] Loaded ROM: {self.rom_path.name}")
			
			# Load character table
			table_path = Path(__file__).parent.parent.parent / 'complex.tbl'
			self.char_table = CharacterTable(table_path, use_complex=True)
			self.db.dialog_text = DialogText(self.char_table)
			
			print(f"[OK] Loaded character table: {len(self.char_table.char_to_byte)} single + {len(self.char_table.multi_char_to_byte)} DTE")
			
			# Extract all dialogs
			self.db.extract_all_dialogs()
			print(f"[OK] Extracted {len(self.db.dialogs)} dialogs")
			
			return True
		except Exception as e:
			print(f"ERROR: Failed to load: {e}")
			import traceback
			traceback.print_exc()
			return False
	
	def extract_dialog_bytes(self, dialog_id: int) -> Optional[bytes]:
		"""
		Extract raw bytes for a dialog
		
		Args:
			dialog_id: Dialog ID
		
		Returns:
			Raw dialog bytes
		"""
		if dialog_id not in self.db.dialogs:
			print(f"  [WARN]  Dialog {dialog_id:02X} not found")
			return None
		
		return self.db.dialogs[dialog_id].raw_bytes
	
	def analyze_dialog(self, dialog_id: int, expected_text: str) -> None:
		"""
		Analyze a single known dialog
		
		Args:
			dialog_id: Dialog ID
			expected_text: Expected English text
		"""
		print(f"\n{'='*70}")
		print(f"Analyzing Dialog 0x{dialog_id:02X}")
		print(f"{'='*70}")
		
		# Extract bytes
		raw_bytes = self.extract_dialog_bytes(dialog_id)
		if raw_bytes is None:
			return
		
		print(f"Expected: {expected_text}")
		print(f"ROM bytes ({len(raw_bytes)}): {raw_bytes.hex()}")
		print()
		
		# Try current decoding
		current_text = self.db.dialog_text.decode(raw_bytes)
		print(f"Current decode: {current_text}")
		print()
		
		# Byte frequency analysis
		print("Byte frequency:")
		byte_freq = Counter(raw_bytes)
		for byte, count in byte_freq.most_common(10):
			hex_val = f"0x{byte:02X}"
			current_map = self.char_table.decode_byte(byte)
			print(f"  {hex_val}: {count:3d}x  ->  {current_map}")
			self.byte_counts[byte] += count
		
		# Character frequency in expected text
		print("\nExpected character frequency:")
		char_freq = Counter(expected_text.lower())
		for char, count in char_freq.most_common(10):
			print(f"  '{char}': {count:3d}x")
		
		# Try to align
		self.attempt_alignment(raw_bytes, expected_text)
	
	def attempt_alignment(self, raw_bytes: bytes, expected_text: str) -> None:
		"""
		Attempt to align ROM bytes with expected text
		
		Args:
			raw_bytes: ROM bytes
			expected_text: Expected text
		"""
		print("\nAttempting byte-to-character alignment...")
		
		# Look for obvious single-byte mappings
		# Strategy: Find repeating bytes and match to repeating characters
		
		byte_positions = defaultdict(list)
		for i, byte in enumerate(raw_bytes):
			byte_positions[byte].append(i)
		
		char_positions = defaultdict(list)
		expected_lower = expected_text.lower()
		for i, char in enumerate(expected_lower):
			char_positions[char].append(i)
		
		# Find bytes that appear in similar patterns to characters
		print("\nPotential single-byte mappings:")
		for byte, b_positions in sorted(byte_positions.items()):
			if len(b_positions) < 2:
				continue  # Skip single occurrences
			
			# Look for character with similar occurrence count
			for char, c_positions in char_positions.items():
				if len(b_positions) == len(c_positions):
					current_map = self.char_table.decode_byte(byte)
					if current_map != char:
						print(f"  0x{byte:02X} ({len(b_positions)}x) -> '{char}' (currently: {current_map})")
						self.deduced_mappings[byte] = char
	
	def analyze_all_known(self) -> None:
		"""Analyze all known dialogs"""
		print("\n" + "=" * 70)
		print("ROM BYTE-LEVEL DIALOG ANALYSIS")
		print("=" * 70)
		
		for dialog_id, expected_text in KNOWN_DIALOGS.items():
			self.analyze_dialog(dialog_id, expected_text)
		
		# Summary
		print("\n" + "=" * 70)
		print("SUMMARY")
		print("=" * 70)
		
		print("\nTop 20 bytes overall:")
		for byte, count in self.byte_counts.most_common(20):
			hex_val = f"0x{byte:02X}"
			current_map = self.char_table.decode_byte(byte)
			suggested = self.deduced_mappings.get(byte, None)
			if suggested:
				print(f"  {hex_val}: {count:4d}x  ->  {current_map}  (suggest: '{suggested}')")
			else:
				print(f"  {hex_val}: {count:4d}x  ->  {current_map}")
		
		# Deduced mappings
		if self.deduced_mappings:
			print(f"\nDeduced {len(self.deduced_mappings)} potential mapping corrections:")
			for byte, char in sorted(self.deduced_mappings.items()):
				current = self.char_table.decode_byte(byte)
				print(f"  0x{byte:02X}: {current} -> '{char}'")
		else:
			print("\n  [WARN]  Unable to deduce mappings automatically")
			print("	Manual ROM analysis required")
	
	def generate_corrected_table(self) -> None:
		"""Generate corrected complex.tbl file"""
		if not self.deduced_mappings:
			print("\nNo corrections to apply")
			return
		
		print(f"\nGenerating corrected complex.tbl...")
		
		output_path = Path(__file__).parent.parent.parent / 'complex_corrected.tbl'
		
		# TODO: Implement table generation
		print(f"  (Would write to {output_path})")
		print("  Manual correction required - see deduced mappings above")


def main():
	import argparse
	
	parser = argparse.ArgumentParser(
		description='Analyze dialog bytes to deduce DTE mappings'
	)
	parser.add_argument('rom', type=Path, help='ROM file path')
	
	args = parser.parse_args()
	
	if not args.rom.exists():
		print(f"ERROR: ROM not found: {args.rom}")
		return 1
	
	# Create analyzer
	analyzer = DialogByteAnalyzer(args.rom)
	
	if not analyzer.load_rom():
		return 1
	
	# Analyze known dialogs
	analyzer.analyze_all_known()
	
	# Generate corrected table
	analyzer.generate_corrected_table()
	
	return 0


if __name__ == '__main__':
	sys.exit(main())

