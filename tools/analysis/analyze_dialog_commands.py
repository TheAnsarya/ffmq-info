#!/usr/bin/env python3
"""
Analyze FFMQ Dialog Commands
Systematically extract and identify all control codes used in dialogs
"""

import struct
from pathlib import Path
from collections import Counter, defaultdict
from typing import Dict, List, Set, Tuple


class DialogCommandAnalyzer:
	"""Analyze control codes in FFMQ dialog data"""

	def __init__(self, rom_path: str):
		"""Initialize with ROM file path"""
		self.rom_path = Path(rom_path)
		with open(self.rom_path, 'rb') as f:
			self.rom_data = f.read()

		# Dialog pointer table at PC 0x0D636 (116 dialogs)
		self.pointer_table_pc = 0x0D636
		self.dialog_count = 116
		self.dialog_bank = 0x03

		# Control code ranges
		self.basic_control_range = range(0x00, 0x3D)  # 0x00-0x3C
		self.dte_range = range(0x3D, 0x7F)  # DTE sequences
		self.extended_control_range = range(0x80, 0x90)  # 0x80-0x8F

		# Track findings
		self.control_code_usage: Counter = Counter()
		self.control_code_contexts: defaultdict = defaultdict(list)
		self.byte_sequences: List[bytes] = []

	def extract_dialog_bytes(self, dialog_id: int) -> Tuple[int, int, bytes]:
		"""Extract raw bytes for a dialog"""
		# Read pointer (16-bit little-endian)
		ptr_offset = self.pointer_table_pc + (dialog_id * 2)
		snes_pointer = struct.unpack('<H', self.rom_data[ptr_offset:ptr_offset+2])[0]

		# Convert LoROM SNES address to PC address
		# Bank $03, SNES $8000-$FFFF → PC $018000-$01FFFF
		if snes_pointer >= 0x8000:
			pc_address = 0x018000 + (snes_pointer - 0x8000)
		else:
			pc_address = 0x018000 + snes_pointer

		# Read until 0x00 terminator
		dialog_bytes = bytearray()
		offset = pc_address
		while offset < len(self.rom_data):
			byte = self.rom_data[offset]
			dialog_bytes.append(byte)
			if byte == 0x00:  # END marker
				break
			offset += 1

		return dialog_id, pc_address, bytes(dialog_bytes)

	def analyze_dialog(self, dialog_id: int, dialog_bytes: bytes) -> Dict:
		"""Analyze control codes in a dialog"""
		results = {
			'dialog_id': dialog_id,
			'byte_count': len(dialog_bytes),
			'control_codes': [],
			'byte_histogram': Counter(),
			'sequences': []
		}

		i = 0
		while i < len(dialog_bytes):
			byte = dialog_bytes[i]
			results['byte_histogram'][byte] += 1

			# Track control codes
			if byte in self.basic_control_range or byte in self.extended_control_range:
				context_before = dialog_bytes[max(0, i-3):i]
				context_after = dialog_bytes[i+1:min(len(dialog_bytes), i+4)]

				self.control_code_usage[byte] += 1
				self.control_code_contexts[byte].append({
					'dialog_id': dialog_id,
					'position': i,
					'before': context_before.hex(),
					'after': context_after.hex()
				})

				results['control_codes'].append({
					'byte': byte,
					'position': i,
					'context': f"...{context_before.hex()} [{byte:02X}] {context_after.hex()}..."
				})

			i += 1

		self.byte_sequences.append(dialog_bytes)
		return results

	def find_command_patterns(self) -> Dict:
		"""Find patterns in control code usage"""
		patterns = {
			'always_followed_by': defaultdict(Counter),
			'always_preceded_by': defaultdict(Counter),
			'position_patterns': defaultdict(list),
			'byte_pair_patterns': Counter()
		}

		for dialog_bytes in self.byte_sequences:
			for i in range(len(dialog_bytes) - 1):
				byte = dialog_bytes[i]
				next_byte = dialog_bytes[i + 1] if i + 1 < len(dialog_bytes) else None
				prev_byte = dialog_bytes[i - 1] if i > 0 else None

				if byte in self.basic_control_range or byte in self.extended_control_range:
					if next_byte is not None:
						patterns['always_followed_by'][byte][next_byte] += 1
					if prev_byte is not None:
						patterns['always_preceded_by'][byte][prev_byte] += 1

					# Track byte pairs
					if next_byte is not None:
						patterns['byte_pair_patterns'][(byte, next_byte)] += 1

		return patterns

	def analyze_all_dialogs(self) -> Dict:
		"""Analyze all dialogs and generate report"""
		print(f"Analyzing {self.dialog_count} dialogs...")

		all_results = []
		for dialog_id in range(self.dialog_count):
			try:
				dialog_id, pc_addr, dialog_bytes = self.extract_dialog_bytes(dialog_id)
				results = self.analyze_dialog(dialog_id, dialog_bytes)
				all_results.append(results)

				if dialog_id % 10 == 0:
					print(f"  Analyzed {dialog_id}/{self.dialog_count}...")
			except Exception as e:
				print(f"  Error analyzing dialog {dialog_id}: {e}")

		print(f"\nControl code usage summary:")
		print(f"  Found {len(self.control_code_usage)} unique control codes")

		# Sort by frequency
		sorted_codes = sorted(self.control_code_usage.items(), key=lambda x: x[1], reverse=True)

		print(f"\nTop 20 most used control codes:")
		for byte_val, count in sorted_codes[:20]:
			print(f"  0x{byte_val:02X}: {count:4d} occurrences")

		# Find patterns
		patterns = self.find_command_patterns()

		return {
			'total_dialogs': len(all_results),
			'control_code_usage': dict(self.control_code_usage),
			'control_code_contexts': dict(self.control_code_contexts),
			'patterns': patterns,
			'dialog_results': all_results
		}

	def generate_report(self, output_path: str):
		"""Generate comprehensive control code report"""
		results = self.analyze_all_dialogs()

		with open(output_path, 'w', encoding='utf-8') as f:
			f.write("# FFMQ Dialog Control Code Analysis Report\n\n")
			f.write(f"Analyzed {results['total_dialogs']} dialogs\n\n")

			# Control code frequency table
			f.write("## Control Code Frequency\n\n")
			f.write("| Byte | Hex | Decimal | Count | Percentage |\n")
			f.write("|------|-----|---------|-------|------------|\n")

			total_uses = sum(results['control_code_usage'].values())
			sorted_codes = sorted(results['control_code_usage'].items(), key=lambda x: x[1], reverse=True)

			for byte_val, count in sorted_codes:
				pct = (count / total_uses * 100) if total_uses > 0 else 0
				f.write(f"| `{byte_val:02X}` | 0x{byte_val:02X} | {byte_val:3d} | {count:4d} | {pct:5.2f}% |\n")

			# Pattern analysis
			f.write("\n## Control Code Patterns\n\n")

			# Codes that always have specific followers
			f.write("### Commands with Consistent Following Bytes\n\n")
			f.write("These codes are likely multi-byte commands with parameters:\n\n")

			for byte_val, followers in results['patterns']['always_followed_by'].items():
				if len(followers) <= 3 and sum(followers.values()) >= 5:  # Consistent pattern
					f.write(f"\n**0x{byte_val:02X}** typically followed by:\n")
					for follow_byte, count in followers.most_common(5):
						f.write(f"  - 0x{follow_byte:02X} ({count} times)\n")

			# Context examples
			f.write("\n## Context Examples\n\n")
			f.write("Sample occurrences of each control code:\n\n")

			for byte_val in sorted(results['control_code_usage'].keys()):
				contexts = self.control_code_contexts[byte_val][:3]  # First 3 examples
				if contexts:
					f.write(f"\n### 0x{byte_val:02X}\n\n")
					for ctx in contexts:
						f.write(f"- Dialog {ctx['dialog_id']:3d} pos {ctx['position']:3d}: ")
						f.write(f"...{ctx['before']} **[{byte_val:02X}]** {ctx['after']}...\n")

			# Recommendations
			f.write("\n## Recommendations\n\n")
			f.write("Based on analysis, the following codes need investigation:\n\n")

			for byte_val, count in sorted_codes:
				if count >= 10:  # Focus on commonly used codes
					f.write(f"- **0x{byte_val:02X}**: {count} uses - ")
					if byte_val == 0x00:
						f.write("END marker (confirmed)\n")
					elif byte_val == 0x01:
						f.write("NEWLINE (confirmed)\n")
					elif byte_val == 0x02:
						f.write("WAIT (confirmed)\n")
					else:
						followers = results['patterns']['always_followed_by'].get(byte_val, {})
						if len(followers) <= 2:
							f.write(f"Likely multi-byte command (usually followed by {len(followers)} byte types)\n")
						else:
							f.write("Needs investigation\n")

		print(f"\nReport written to {output_path}")


def main():
	"""Main entry point"""
	rom_path = Path(__file__).parent.parent.parent / 'roms' / 'Final Fantasy - Mystic Quest (U) (V1.1).sfc'

	if not rom_path.exists():
		print(f"ERROR: ROM not found at {rom_path}")
		return

	analyzer = DialogCommandAnalyzer(str(rom_path))

	output_path = Path(__file__).parent.parent.parent / 'reports' / 'dialog_command_analysis.md'
	output_path.parent.mkdir(parents=True, exist_ok=True)

	analyzer.generate_report(str(output_path))

	print("\nAnalysis complete!")


if __name__ == '__main__':
	main()
