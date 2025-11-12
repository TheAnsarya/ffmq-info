#!/usr/bin/env python3
"""
Dialog Statistics and Analysis Tool

Provides comprehensive statistics about FFMQ's dialog system:
- Size distribution
- Character usage
- Control code frequency
- Dictionary compression effectiveness
- Translation feasibility analysis

Author: FFMQ Disassembly Project
Date: 2025-01-24
"""

import sys
import os
from pathlib import Path
from collections import Counter, defaultdict

# Add parent to path
sys.path.insert(0, str(Path(__file__).parent.parent))

def analyze_dialog_sizes(rom_path):
	"""Analyze dialog size distribution."""
	print("\n" + "="*70)
	print("DIALOG SIZE ANALYSIS")
	print("="*70)
	
	# This is a placeholder - actual implementation would extract dialog sizes
	# from ROM pointer table
	
	# Example structure:
	sizes = []
	
	# Read pointer table at PC 0x01B835
	with open(rom_path, 'rb') as f:
		f.seek(0x01B835)
		
		# Read 117 dialog pointers (16-bit each)
		pointers = []
		for i in range(117):
			ptr_bytes = f.read(2)
			if len(ptr_bytes) < 2:
				break
			ptr = int.from_bytes(ptr_bytes, 'little')
			pointers.append(ptr)
		
		# Calculate sizes (difference between consecutive pointers)
		for i in range(len(pointers) - 1):
			size = pointers[i+1] - pointers[i]
			sizes.append(size)
		
		# Last dialog size (until dictionary start at ~0xBA35)
		if pointers:
			last_size = 0xBA35 - pointers[-1]
			sizes.append(last_size)
	
	if not sizes:
		print("❌ ERROR: Could not read dialog sizes")
		return
	
	# Statistics
	total_size = sum(sizes)
	avg_size = total_size / len(sizes)
	min_size = min(sizes)
	max_size = max(sizes)
	median_size = sorted(sizes)[len(sizes) // 2]
	
	print(f"Total Dialogs:	{len(sizes)}")
	print(f"Total Size:	   {total_size:,} bytes ({total_size/1024:.1f} KB)")
	print(f"Average Size:	 {avg_size:.1f} bytes")
	print(f"Median Size:	  {median_size} bytes")
	print(f"Min Size:		 {min_size} bytes (Dialog #{sizes.index(min_size)})")
	print(f"Max Size:		 {max_size} bytes (Dialog #{sizes.index(max_size)})")
	
	# Size distribution
	print("\nSize Distribution:")
	bins = [
		(0, 32, "Tiny"),
		(32, 64, "Small"),
		(64, 128, "Medium"),
		(128, 256, "Large"),
		(256, 512, "Very Large"),
		(512, float('inf'), "Huge")
	]
	
	for min_s, max_s, label in bins:
		count = sum(1 for s in sizes if min_s <= s < max_s)
		pct = count * 100 / len(sizes)
		bar = "█" * int(pct / 2)
		print(f"  {label:12} ({min_s:3}-{max_s if max_s != float('inf') else '∞':3}): {count:3} ({pct:5.1f}%) {bar}")
	
	# Largest dialogs
	print("\nLargest Dialogs:")
	indexed_sizes = [(i, s) for i, s in enumerate(sizes)]
	indexed_sizes.sort(key=lambda x: x[1], reverse=True)
	
	for i, (dialog_id, size) in enumerate(indexed_sizes[:10]):
		print(f"  #{i+1}: Dialog 0x{dialog_id:02X} - {size} bytes")
	
	return sizes

def analyze_character_usage(dialogs):
	"""Analyze character usage across all dialogs."""
	print("\n" + "="*70)
	print("CHARACTER USAGE ANALYSIS")
	print("="*70)
	
	# Count all characters
	char_counter = Counter()
	
	for dialog in dialogs:
		for char in dialog:
			if char not in ['[', ']', '{', '}']:  # Skip control code markers
				char_counter[char] += 1
	
	total_chars = sum(char_counter.values())
	
	print(f"Total Characters: {total_chars:,}")
	print(f"Unique Characters: {len(char_counter)}")
	
	# Most common characters
	print("\nMost Common Characters:")
	for char, count in char_counter.most_common(20):
		pct = count * 100 / total_chars
		if char == ' ':
			display = '<space>'
		elif char == '\n':
			display = '<newline>'
		else:
			display = char
		print(f"  '{display}': {count:,} ({pct:.1f}%)")
	
	# Special characters
	special_chars = [c for c in char_counter.keys() if ord(c) > 127 or not c.isprintable()]
	if special_chars:
		print(f"\nSpecial Characters Found: {len(special_chars)}")
		for char in sorted(special_chars):
			count = char_counter[char]
			pct = count * 100 / total_chars
			print(f"  U+{ord(char):04X} ({char}): {count} ({pct:.2f}%)")

def analyze_control_codes(dialogs):
	"""Analyze control code usage patterns."""
	print("\n" + "="*70)
	print("CONTROL CODE PATTERN ANALYSIS")
	print("="*70)
	
	# Extract all control codes
	code_counter = Counter()
	code_positions = defaultdict(list)  # Track where codes appear
	code_pairs = Counter()  # Track code sequences
	
	for dialog_id, dialog in enumerate(dialogs):
		# Find control codes (between [ ] or { })
		i = 0
		prev_code = None
		
		while i < len(dialog):
			if dialog[i] in ['[', '{']:
				# Extract control code
				end_marker = ']' if dialog[i] == '[' else '}'
				end_pos = dialog.find(end_marker, i)
				
				if end_pos != -1:
					code = dialog[i:end_pos+1]
					code_counter[code] += 1
					code_positions[code].append(dialog_id)
					
					# Track code pairs
					if prev_code:
						code_pairs[(prev_code, code)] += 1
					
					prev_code = code
					i = end_pos + 1
				else:
					i += 1
			else:
				i += 1
	
	# Show results
	print(f"Total Control Codes Used: {sum(code_counter.values())}")
	print(f"Unique Control Codes: {len(code_counter)}")
	
	print("\nMost Common Control Codes:")
	for code, count in code_counter.most_common(15):
		dialogs_using = len(set(code_positions[code]))
		print(f"  {code:20}: {count:5} uses in {dialogs_using:3} dialogs")
	
	print("\nMost Common Control Code Sequences:")
	for (code1, code2), count in code_pairs.most_common(10):
		print(f"  {code1:20} → {code2:20}: {count:4} times")

def analyze_dictionary_effectiveness(rom_path):
	"""Analyze dictionary compression effectiveness."""
	print("\n" + "="*70)
	print("DICTIONARY COMPRESSION ANALYSIS")
	print("="*70)
	
	# Read dictionary entries
	dictionary = {}
	
	with open(rom_path, 'rb') as f:
		f.seek(0x01BA35)  # Dictionary location
		
		for i in range(80):  # 80 dictionary entries (0x30-0x7F)
			length = f.read(1)[0]
			if length == 0:
				break
			
			data = f.read(length)
			dictionary[0x30 + i] = data
	
	print(f"Dictionary Entries: {len(dictionary)}")
	print(f"Average Entry Length: {sum(len(d) for d in dictionary.values()) / len(dictionary):.1f} bytes")
	
	# Show most valuable entries (longest)
	indexed = [(code, len(data), data) for code, data in dictionary.items()]
	indexed.sort(key=lambda x: x[1], reverse=True)
	
	print("\nLongest Dictionary Entries:")
	for i, (code, length, data) in enumerate(indexed[:10]):
		# Try to decode as ASCII
		try:
			decoded = ''.join(chr(b) if 32 <= b < 127 else f'\\x{b:02X}' for b in data)
		except:
			decoded = ' '.join(f'{b:02X}' for b in data)
		
		print(f"  0x{code:02X} ({length} bytes): {decoded}")
	
	# Estimate compression ratio
	# This is a rough estimate - actual implementation would scan dialogs
	total_dict_bytes = sum(len(d) for d in dictionary.values())
	estimated_saves = total_dict_bytes * 10  # Rough estimate: each entry used ~10 times
	
	print(f"\nEstimated Space Savings: ~{estimated_saves:,} bytes")
	print(f"Compression Ratio: ~{100 - (estimated_saves * 100 / (estimated_saves + total_dict_bytes)):.0f}% of original size")

def main():
	"""Main entry point."""
	if len(sys.argv) < 2:
		print("Usage: python dialog_statistics.py <rom_path>")
		print()
		print("Example:")
		print("  python tools/analysis/dialog_statistics.py roms/ffmq.sfc")
		return 1
	
	rom_path = sys.argv[1]
	
	if not os.path.exists(rom_path):
		print(f"❌ ERROR: ROM file not found: {rom_path}")
		return 1
	
	print("╔" + "="*68 + "╗")
	print("║" + " "*20 + "FFMQ Dialog Statistics" + " "*26 + "║")
	print("╚" + "="*68 + "╝")
	print(f"\nROM: {rom_path}")
	
	# Size analysis (from ROM)
	sizes = analyze_dialog_sizes(rom_path)
	
	# Dictionary analysis (from ROM)
	analyze_dictionary_effectiveness(rom_path)
	
	# For character/control code analysis, we'd need to extract dialogs first
	# This requires the extraction tools to be available
	try:
		from tools.extraction.extract_dictionary import extract_all_dialogs
		
		print("\n" + "="*70)
		print("EXTRACTING DIALOGS...")
		print("="*70)
		
		dialogs = extract_all_dialogs(rom_path)
		print(f"✅ Extracted {len(dialogs)} dialogs")
		
		# Character analysis
		analyze_character_usage(dialogs)
		
		# Control code analysis
		analyze_control_codes(dialogs)
		
	except ImportError as e:
		print(f"\n⚠️ SKIP: Character/control analysis requires extraction tools - {e}")
	
	print("\n" + "="*70)
	print("ANALYSIS COMPLETE")
	print("="*70)
	
	return 0

if __name__ == "__main__":
	sys.exit(main())
