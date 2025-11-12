#!/usr/bin/env python3
"""
FFMQ Control Code Analyzer
Analyzes control code usage patterns across all dialogs to determine:
1. Which control codes are used
2. How many parameters each takes
3. What values those parameters have

This helps document the event command system.
"""

import sys
from pathlib import Path
from collections import defaultdict
from typing import Dict, List, Tuple, Set

class ControlCodeAnalyzer:
	"""Analyze control code usage in FFMQ dialogs"""

	POINTER_TABLE_PC = 0x22E00
	NUM_DIALOGS = 117

	def __init__(self, rom_path: str):
		"""Initialize with ROM path"""
		self.rom_path = Path(rom_path)
		self.rom: bytes = b''
		self.control_usage = defaultdict(list)  # control_code -> [(dialog_id, pos, context)]

	def load_rom(self):
		"""Load ROM data"""
		self.rom = self.rom_path.read_bytes()
		print(f"Loaded ROM: {self.rom_path.name} ({len(self.rom)} bytes)")

	def get_dialog_data(self, dialog_id: int) -> Tuple[int, bytes]:
		"""Get dialog data for a specific ID"""
		pointer_offset = self.POINTER_TABLE_PC + (dialog_id * 3)
		ptr_low = self.rom[pointer_offset]
		ptr_high = self.rom[pointer_offset + 1]
		ptr_bank = self.rom[pointer_offset + 2]

		snes_addr = (ptr_high << 8) | ptr_low
		pc_addr = ((ptr_bank - 0xC0) * 0x10000) + (snes_addr - 0x8000) if ptr_bank >= 0xC0 else -1

		if pc_addr < 0 or pc_addr >= len(self.rom):
			return pc_addr, b''

		# Read until 0x00 (end marker) or max 500 bytes
		dialog_bytes = []
		for i in range(500):
			if pc_addr + i >= len(self.rom):
				break
			b = self.rom[pc_addr + i]
			dialog_bytes.append(b)
			if b == 0x00:
				break

		return pc_addr, bytes(dialog_bytes)

	def analyze_all_dialogs(self):
		"""Scan all dialogs for control code usage"""
		print(f"\nAnalyzing {self.NUM_DIALOGS} dialogs for control code usage...")
		print("="*80)

		for dialog_id in range(self.NUM_DIALOGS):
			pc_addr, data = self.get_dialog_data(dialog_id)
			if not data:
				continue

			# Find all control codes (0x00-0x2F)
			for pos, byte in enumerate(data):
				if byte < 0x30:  # Control code
					# Get surrounding context (4 bytes before, 4 bytes after)
					start = max(0, pos - 4)
					end = min(len(data), pos + 5)
					context = data[start:end]

					self.control_usage[byte].append((dialog_id, pos, context))

		print(f"Found {len(self.control_usage)} unique control codes in use\n")

	def print_control_summary(self):
		"""Print summary of all control codes"""
		print("Control Code Usage Summary:")
		print("="*80)

		for code in sorted(self.control_usage.keys()):
			occurrences = self.control_usage[code]
			print(f"\n0x{code:02X}: {len(occurrences)} occurrences")

			# Show unique dialogs using this code
			unique_dialogs = set(occ[0] for occ in occurrences)
			print(f"	 In dialogs: {sorted(unique_dialogs)}")

			# Show first 3 contexts
			print(f"	 Sample contexts:")
			for dialog_id, pos, context in occurrences[:3]:
				hex_str = " ".join([f"{b:02X}" for b in context])
				print(f"	   Dialog 0x{dialog_id:02X} pos {pos:3d}: {hex_str}")

	def analyze_parameter_patterns(self):
		"""Analyze what bytes follow each control code to determine parameter count"""
		print("\n" + "="*80)
		print("Parameter Pattern Analysis:")
		print("="*80)

		for code in sorted(self.control_usage.keys()):
			occurrences = self.control_usage[code]

			# Look at bytes immediately following this control code
			following_bytes = defaultdict(int)  # byte_value -> count
			following_patterns = []  # (byte1, byte2, byte3) patterns

			for dialog_id, pos, context in occurrences:
				# Find position of control code in context
				code_pos = context.index(code) if code in context else -1
				if code_pos == -1 or code_pos == len(context) - 1:
					continue

				# Get next 3 bytes
				next1 = context[code_pos + 1] if code_pos + 1 < len(context) else None
				next2 = context[code_pos + 2] if code_pos + 2 < len(context) else None
				next3 = context[code_pos + 3] if code_pos + 3 < len(context) else None

				if next1 is not None:
					following_bytes[next1] += 1
					following_patterns.append((next1, next2, next3))

			if not following_bytes:
				continue

			print(f"\n0x{code:02X} ({len(occurrences)} uses):")

			# Analyze first following byte
			print(f"  Byte after 0x{code:02X}:")
			for byte_val, count in sorted(following_bytes.items(), key=lambda x: -x[1])[:5]:
				byte_type = self._classify_byte(byte_val)
				print(f"	0x{byte_val:02X} ({byte_type}): {count} times")

			# Try to determine parameter count
			param_count = self._estimate_param_count(code, following_patterns)
			print(f"  Estimated parameters: {param_count}")

	def _classify_byte(self, byte_val: int) -> str:
		"""Classify what type of byte this is"""
		if byte_val < 0x30:
			return "CONTROL"
		elif byte_val < 0x80:
			return "DICT"
		else:
			return "CHAR"

	def _estimate_param_count(self, code: int, patterns: List[Tuple]) -> str:
		"""Estimate how many parameter bytes this command takes"""
		if not patterns:
			return "0 (no following data)"

		# Count how many following bytes are consistently NOT control codes
		# Control codes usually start new commands, so parameters should be 0x30+

		first_bytes = [p[0] for p in patterns if p[0] is not None]
		second_bytes = [p[1] for p in patterns if p[1] is not None]
		third_bytes = [p[2] for p in patterns if p[2] is not None]

		# If first byte is often < 0x30, it's likely another control code (0 params)
		if first_bytes and sum(1 for b in first_bytes if b < 0x30) > len(first_bytes) * 0.7:
			return "0 (next byte is usually another control code)"

		# If first byte is always >= 0x30, check second byte
		if first_bytes and all(b >= 0x30 for b in first_bytes):
			if second_bytes and sum(1 for b in second_bytes if b < 0x30) > len(second_bytes) * 0.7:
				return "1 byte parameter"
			elif second_bytes and all(b >= 0x30 for b in second_bytes):
				if third_bytes and sum(1 for b in third_bytes if b < 0x30) > len(third_bytes) * 0.7:
					return "2 byte parameters"
				else:
					return "2+ byte parameters (needs manual review)"
			else:
				return "1+ bytes (mixed pattern - needs manual review)"

		return "UNKNOWN (mixed pattern)"

	def detailed_analysis(self, code: int):
		"""Show detailed analysis for a specific control code"""
		if code not in self.control_usage:
			print(f"Control code 0x{code:02X} not found in any dialogs")
			return

		occurrences = self.control_usage[code]
		print(f"\nDetailed Analysis: 0x{code:02X}")
		print("="*80)
		print(f"Total occurrences: {len(occurrences)}")

		for dialog_id, pos, context in occurrences:
			# Find code position in context
			code_pos = context.index(code) if code in context else -1
			if code_pos == -1:
				continue

			# Build display with code highlighted
			display = []
			for i, b in enumerate(context):
				if i == code_pos:
					display.append(f"[{b:02X}]")
				else:
					byte_type = self._classify_byte(b)
					if byte_type == "CONTROL":
						display.append(f"<{b:02X}>")
					elif byte_type == "DICT":
						display.append(f"D{b:02X}")
					else:
						display.append(f"{b:02X}")

			print(f"  Dialog 0x{dialog_id:02X} pos {pos:3d}: {' '.join(display)}")

def main():
	"""Main entry point"""
	if len(sys.argv) < 2:
		rom_path = r"roms\Final Fantasy - Mystic Quest (U) (V1.1).sfc"
		print(f"Using default ROM: {rom_path}")
	else:
		rom_path = sys.argv[1]

	analyzer = ControlCodeAnalyzer(rom_path)
	analyzer.load_rom()
	analyzer.analyze_all_dialogs()
	analyzer.print_control_summary()
	analyzer.analyze_parameter_patterns()

	# Show detailed analysis for most common codes
	print("\n" + "="*80)
	print("DETAILED ANALYSIS OF KEY CONTROL CODES:")
	print("="*80)

	# Analyze the most frequently used codes
	top_codes = sorted(analyzer.control_usage.keys(),
					  key=lambda c: len(analyzer.control_usage[c]),
					  reverse=True)[:10]

	for code in top_codes:
		analyzer.detailed_analysis(code)

if __name__ == '__main__':
	main()
