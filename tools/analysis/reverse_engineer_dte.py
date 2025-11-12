#!/usr/bin/env python3
"""
Reverse-engineer DTE table from ROM by analyzing known dialog text.

This script compares actual ROM bytes to expected English text to deduce
the correct DTE byte→string mappings.
"""

import sys
from pathlib import Path
from typing import Dict, List, Tuple, Set

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from tools.text.simple_text_decoder import SimpleTextDecoder


class DTEReverseEngineer:
	"""Reverse-engineer DTE mappings from ROM dialogs"""
	
	def __init__(self, rom_path: str):
		"""
		Initialize reverse engineer.
		
		Args:
			rom_path: Path to FFMQ ROM file
		"""
		self.rom_path = Path(rom_path)
		
		# Load ROM
		with open(self.rom_path, 'rb') as f:
			self.rom_data = bytearray(f.read())
		
		# Load simple character table for single-byte characters
		self.simple_decoder = SimpleTextDecoder()
		self.simple_chars = self.simple_decoder.char_table
		
		# Dialog pointer table
		self.pointer_table_addr = 0x00D636
		
		# Dialog data bank
		self.dialog_bank_start = 0x018000
		
		# Known dialogs (ID, expected text)
		self.known_dialogs = self._get_known_dialogs()
		
		# DTE findings
		self.dte_mappings: Dict[int, str] = {}
		self.dte_candidates: Dict[int, Set[str]] = {}
	
	def _get_known_dialogs(self) -> List[Tuple[int, str]]:
		"""
		Get list of known dialogs with verified English text.
		
		Returns:
			List of (dialog_id, expected_text) tuples
		"""
		# These are dialogs with known text from gameplay/videos
		return [
			# Opening dialog
			(0, "For years Mac has been"),
			
			# Common phrases
			(1, "Thank you"),
			(2, "Be careful"),
			
			# NPC dialogs
			# TODO: Add more known dialogs from gameplay footage
		]
	
	def get_dialog_address(self, dialog_id: int) -> int:
		"""
		Get ROM address for dialog by ID.
		
		Args:
			dialog_id: Dialog ID (0-116)
			
		Returns:
			ROM PC address of dialog data
		"""
		# Read pointer from table
		ptr_addr = self.pointer_table_addr + (dialog_id * 2)
		pointer = self.rom_data[ptr_addr] | (self.rom_data[ptr_addr + 1] << 8)
		
		# Convert SNES address to ROM PC address
		# Dialog data is in bank $03 ($018000-$01FFFF)
		pc_address = self.dialog_bank_start + (pointer & 0x7FFF)
		
		return pc_address
	
	def get_dialog_bytes(self, dialog_id: int, max_length: int = 100) -> bytes:
		"""
		Extract raw bytes for a dialog.
		
		Args:
			dialog_id: Dialog ID
			max_length: Maximum bytes to read
			
		Returns:
			Raw dialog bytes
		"""
		addr = self.get_dialog_address(dialog_id)
		
		# Read bytes until END marker (0x00) or max_length
		dialog_bytes = []
		for i in range(max_length):
			byte = self.rom_data[addr + i]
			dialog_bytes.append(byte)
			
			if byte == 0x00:  # END marker
				break
		
		return bytes(dialog_bytes)
	
	def analyze_dialog(self, dialog_id: int, expected_text: str) -> Dict[int, str]:
		"""
		Analyze a dialog to deduce DTE mappings.
		
		Args:
			dialog_id: Dialog ID
			expected_text: Known English text
			
		Returns:
			Dictionary of byte→string mappings deduced
		"""
		dialog_bytes = self.get_dialog_bytes(dialog_id)
		
		print(f"\nAnalyzing Dialog {dialog_id}:")
		print(f"Expected: '{expected_text}'")
		print(f"ROM bytes: {' '.join(f'{b:02X}' for b in dialog_bytes[:50])}")
		
		# Try to match bytes to expected text
		findings = {}
		
		# Simple approach: look for single-character matches
		text_pos = 0
		byte_pos = 0
		
		while text_pos < len(expected_text) and byte_pos < len(dialog_bytes):
			byte = dialog_bytes[byte_pos]
			expected_char = expected_text[text_pos]
			
			# Skip control codes (0x00-0x3F, 0x80-0x8F)
			if byte < 0x40 or (0x80 <= byte <= 0x8F):
				print(f"  Byte {byte_pos}: 0x{byte:02X} = [CONTROL CODE]")
				byte_pos += 1
				continue
			
			# Check if it's a known single character
			if byte in self.simple_chars:
				char = self.simple_chars[byte]
				
				if char == expected_char:
					print(f"  Byte {byte_pos}: 0x{byte:02X} = '{char}' ✓")
					text_pos += 1
					byte_pos += 1
				else:
					# Might be DTE sequence
					print(f"  Byte {byte_pos}: 0x{byte:02X} = '{char}' but expected '{expected_char}'")
					
					# Try to find DTE match
					# Look ahead in expected text for possible multi-char sequences
					for dte_len in range(2, 6):  # DTE sequences are 2-5 chars
						if text_pos + dte_len <= len(expected_text):
							dte_text = expected_text[text_pos:text_pos + dte_len]
							
							# Check if next byte matches next char (single char after DTE)
							if byte_pos + 1 < len(dialog_bytes):
								next_byte = dialog_bytes[byte_pos + 1]
								
								if next_byte in self.simple_chars:
									next_char = self.simple_chars[next_byte]
									
									if text_pos + dte_len < len(expected_text):
										expected_next = expected_text[text_pos + dte_len]
										
										if next_char == expected_next:
											# Found DTE match!
											print(f"	→ DTE: 0x{byte:02X} = '{dte_text}'")
											findings[byte] = dte_text
											text_pos += dte_len
											byte_pos += 1
											break
					else:
						# No DTE match found, skip byte
						byte_pos += 1
			else:
				# Unknown byte, assume DTE
				# Try to match multi-character sequences
				print(f"  Byte {byte_pos}: 0x{byte:02X} = [DTE?]")
				
				# Look for common DTE patterns
				for dte_len in range(2, 6):
					if text_pos + dte_len <= len(expected_text):
						dte_text = expected_text[text_pos:text_pos + dte_len]
						
						# Add as candidate
						if byte not in self.dte_candidates:
							self.dte_candidates[byte] = set()
						
						self.dte_candidates[byte].add(dte_text)
				
				byte_pos += 1
		
		return findings
	
	def analyze_all(self):
		"""Analyze all known dialogs"""
		print("=" * 70)
		print("DTE REVERSE ENGINEERING")
		print("=" * 70)
		
		all_findings = {}
		
		for dialog_id, expected_text in self.known_dialogs:
			findings = self.analyze_dialog(dialog_id, expected_text)
			
			# Merge findings
			for byte, text in findings.items():
				if byte in all_findings:
					if all_findings[byte] != text:
						print(f"\nWARNING: Conflicting DTE for 0x{byte:02X}:")
						print(f"  Previous: '{all_findings[byte]}'")
						print(f"  New:	  '{text}'")
				else:
					all_findings[byte] = text
		
		print("\n" + "=" * 70)
		print("DTE FINDINGS")
		print("=" * 70)
		
		# Sort by byte value
		for byte in sorted(all_findings.keys()):
			text = all_findings[byte]
			print(f"0x{byte:02X} = '{text}'")
		
		print(f"\nTotal DTE codes found: {len(all_findings)}")
		
		# Show candidates
		if self.dte_candidates:
			print("\n" + "=" * 70)
			print("DTE CANDIDATES (need verification)")
			print("=" * 70)
			
			for byte in sorted(self.dte_candidates.keys()):
				candidates = self.dte_candidates[byte]
				print(f"0x{byte:02X}: {', '.join(sorted(candidates))}")
		
		self.dte_mappings = all_findings
	
	def export_dte_table(self, output_path: str):
		"""
		Export DTE mappings to a table file.
		
		Args:
			output_path: Path to output .tbl file
		"""
		with open(output_path, 'w', encoding='utf-8') as f:
			f.write("# DTE mappings reverse-engineered from ROM\n")
			f.write("# Format: BYTE=TEXT\n\n")
			
			for byte in sorted(self.dte_mappings.keys()):
				text = self.dte_mappings[byte]
				f.write(f"{byte:02X}={text}\n")
		
		print(f"\nExported DTE table to: {output_path}")


def main():
	"""Main entry point"""
	import argparse
	
	parser = argparse.ArgumentParser(
		description='Reverse-engineer DTE table from ROM dialogs'
	)
	parser.add_argument(
		'rom_path',
		help='Path to FFMQ ROM file'
	)
	parser.add_argument(
		'--export',
		help='Export DTE findings to .tbl file'
	)
	
	args = parser.parse_args()
	
	# Check ROM exists
	rom_path = Path(args.rom_path)
	if not rom_path.exists():
		print(f"Error: ROM file not found: {rom_path}", file=sys.stderr)
		sys.exit(1)
	
	# Create reverse engineer
	engineer = DTEReverseEngineer(args.rom_path)
	
	# Analyze
	engineer.analyze_all()
	
	# Export if requested
	if args.export:
		engineer.export_dte_table(args.export)


if __name__ == '__main__':
	main()
