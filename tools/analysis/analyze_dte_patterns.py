#!/usr/bin/env python3
"""
Analyze DTE patterns from extraction report to deduce mappings
Uses frequency analysis and context clues to identify DTE sequences
"""

import sys
import re
from pathlib import Path
from collections import defaultdict
from typing import Dict, List, Tuple

def load_report(report_path: Path) -> Dict:
	"""Load DTE extraction report and parse it"""
	
	with open(report_path, 'r', encoding='utf-8') as f:
		content = f.read()
	
	# Parse DTE entries
	dte_data = {}
	
	# Pattern: ### 0x3D (61)\n**Uses:** 5\n**Often preceded by:**
	entry_pattern = r'### (0x[0-9A-F]{2}) \((\d+)\)\s+\*\*Uses:\*\* (\d+)'
	preceded_pattern = r'\*\*Often preceded by:\*\* \'(.)\' \((\d+) times\)'
	followed_pattern = r'\*\*Often followed by:\*\* \'(.)\' \((\d+) times\)'
	
	entries = re.split(r'\n### 0x', content)
	
	for entry in entries[1:]:  # Skip intro
		# Add back the 0x prefix
		entry = '### 0x' + entry
		
		# Extract hex code and uses
		match = re.search(entry_pattern, entry)
		if not match:
			continue
		
		hex_code = match.group(1)
		decimal = int(match.group(2))
		uses = int(match.group(3))
		
		# Extract preceded by
		preceded = None
		preceded_match = re.search(preceded_pattern, entry)
		if preceded_match:
			preceded = (preceded_match.group(1), int(preceded_match.group(2)))
		
		# Extract followed by
		followed = None
		followed_match = re.search(followed_pattern, entry)
		if followed_match:
			followed = (followed_match.group(1), int(followed_match.group(2)))
		
		dte_data[decimal] = {
			'hex': hex_code,
			'uses': uses,
			'preceded': preceded,
			'followed': followed
		}
	
	return dte_data

def analyze_patterns(dte_data: Dict) -> None:
	"""Analyze DTE patterns to guess mappings"""
	
	print("=== DTE Pattern Analysis ===\n")
	
	# Known DTE sequences from TCRF/DataCrystal
	known = {
		0x45: "s ",   # Verified
		0x49: "l ",   # Verified  
		0x4B: "er",   # Verified
		0x5E: "ea",   # Verified
	}
	
	print("Known DTE sequences:")
	for byte, seq in sorted(known.items()):
		data = dte_data.get(byte, {})
		print(f"  {byte:3d} (0x{byte:02X}) = '{seq}' - {data.get('uses', 0)} uses")
	
	print("\n" + "="*70)
	print("High-frequency DTE candidates (likely common words/fragments):")
	print("="*70 + "\n")
	
	# Sort by usage
	by_frequency = sorted(dte_data.items(), key=lambda x: x[1]['uses'], reverse=True)
	
	# Top 30 high-frequency
	for byte, data in by_frequency[:30]:
		if byte in known:
			continue  # Skip known
		
		preceded = data.get('preceded')
		followed = data.get('followed')
		
		# Try to guess based on context
		guess = ""
		
		# Pattern: preceded by 'h', followed by 'e' → probably "er" or "ere"
		if preceded and preceded[0] == 'h' and followed and followed[0] == 'e':
			guess = " (guess: 'er' or 'ere')"
		
		# Pattern: preceded by 't', followed by space → probably "he" as in "the"
		elif preceded and preceded[0] == 't' and followed:
			guess = " (guess: 'he' as in 'the')"
		
		# Pattern: preceded by ' ', followed by consonant → probably start of common word
		elif preceded and preceded[0] == ' ':
			guess = " (guess: word start)"
		
		# Pattern: followed by ' ' → probably end of common word
		elif followed and followed[0] == ' ':
			guess = " (guess: word end with space)"
		
		print(f"{byte:3d} (0x{byte:02X}) - {data['uses']:3d} uses", end='')
		if preceded:
			print(f" | prec: '{preceded[0]}'({preceded[1]})", end='')
		if followed:
			print(f" | foll: '{followed[0]}'({followed[1]})", end='')
		print(guess)
	
	print("\n" + "="*70)
	print("Pattern-based guesses:")
	print("="*70 + "\n")
	
	# Pattern groups
	patterns = {
		"Likely ' the'": [],  # preceded by space, contains 'the'
		"Likely 'er'": [],    # preceded by consonants, common ending
		"Likely 'in' or 'on'": [],  # common prepositions
		"Likely word with space": [],  # followed by space
	}
	
	for byte, data in dte_data.items():
		if byte in known:
			continue
		
		preceded = data.get('preceded')
		followed = data.get('followed')
		
		# ' the' pattern (common in English)
		if preceded and preceded[0] in [' ', '\n'] and followed and followed[0] in ['e', 'a', 'i', 'o']:
			patterns["Likely ' the'"].append((byte, data))
		
		# 'er' pattern (common ending)
		elif preceded and preceded[0] in ['h', 't', 'v', 'n', 'w'] and followed and followed[0] == 'e':
			patterns["Likely 'er'"].append((byte, data))
		
		# 'in'/'on' pattern
		elif preceded and preceded[0] in [' ', '\n', ',', '.'] and followed and followed[0] in ['g', ' ', 'd']:
			patterns["Likely 'in' or 'on'"].append((byte, data))
		
		# Word endings with space
		elif followed and followed[0] == ' ' and data['uses'] > 15:
			patterns["Likely word with space"].append((byte, data))
	
	for pattern_name, items in patterns.items():
		if items:
			print(f"\n{pattern_name}:")
			for byte, data in sorted(items, key=lambda x: x[1]['uses'], reverse=True)[:10]:
				preceded = data.get('preceded')
				followed = data.get('followed')
				print(f"  {byte:3d} (0x{byte:02X}) - {data['uses']:3d} uses", end='')
				if preceded:
					print(f" | prec: '{preceded[0]}'", end='')
				if followed:
					print(f" | foll: '{followed[0]}'", end='')
				print()

def main():
	"""Main entry point"""
	
	report_path = Path("reports/dte_extraction.md")
	
	if not report_path.exists():
		print(f"ERROR: Report not found at {report_path}")
		return False
	
	print(f"Loading DTE report from {report_path}...\n")
	
	dte_data = load_report(report_path)
	
	print(f"Loaded {len(dte_data)} DTE entries\n")
	
	analyze_patterns(dte_data)
	
	return True

if __name__ == '__main__':
	success = main()
	sys.exit(0 if success else 1)
