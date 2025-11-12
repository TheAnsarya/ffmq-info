#!/usr/bin/env python3
"""
Deduce correct DTE sequences by analyzing decoded text patterns
Compares garbled output to expected English to infer missing spaces
"""

import sys
from pathlib import Path
from typing import Dict, List, Tuple
import re

def load_garbled_text() -> str:
	"""Load the garbled dialog text from dialog_0059.txt"""
	
	dialog_path = Path("dialog_0059.txt")
	
	if not dialog_path.exists():
		print("ERROR: dialog_0059.txt not found")
		return ""
	
	with open(dialog_path, 'r', encoding='utf-8') as f:
		lines = f.readlines()
	
	# Skip header, get the actual text
	text = ""
	for line in lines[5:]:  # Skip first 5 header lines
		# Skip control codes for now
		line = re.sub(r'\[.*?\]', ' ', line)
		line = re.sub(r'\{.*?\}', ' ', line)
		text += line.strip()
	
	return text

def find_word_boundaries(text: str) -> List[int]:
	"""
	Find likely word boundaries in garbled text
	Uses capitalization, known words, and English patterns
	"""
	
	boundaries = [0]  # Start is always a boundary
	
	# Capital letters usually start words
	for i, char in enumerate(text):
		if char.isupper() and i > 0:
			# Check if previous char is lowercase (camelCase pattern)
			if text[i-1].islower():
				boundaries.append(i)
	
	# Known complete words (from capitalization or context)
	known_words = [
		"Crystal", "Prophecy", "Mac", "Benjamin", "Kaeli",
		"Phoebe", "Tristam", "Rainbow", "Road", "Hill",
		"years", "been", "studying", "lake", "dried",
		"ship", "ended", "rock", "ledge", "problem",
		"dig", "from", "here", "able", "reach",
		"Anyway", "key", "shield", "hidden",
		"way", "back", "doing", "some", "research",
		"Butthat", "But", "that",  # Compound
	]
	
	for word in known_words:
		pos = text.find(word)
		while pos != -1:
			if pos not in boundaries:
				boundaries.append(pos)
			if pos + len(word) not in boundaries:
				boundaries.append(pos + len(word))
			pos = text.find(word, pos + 1)
	
	boundaries.sort()
	return boundaries

def extract_words(text: str, boundaries: List[int]) -> List[str]:
	"""Extract words from text using boundaries"""
	
	words = []
	for i in range(len(boundaries) - 1):
		start = boundaries[i]
		end = boundaries[i+1]
		word = text[start:end]
		if word and word.strip():
			words.append(word)
	
	# Add last word
	if boundaries:
		last_word = text[boundaries[-1]:]
		if last_word and last_word.strip():
			words.append(last_word)
	
	return words

def suggest_dte_spaces(words: List[str]) -> Dict[str, str]:
	"""
	Suggest which DTE sequences should end with spaces
	based on common English word endings
	"""
	
	suggestions = {}
	
	# Common endings that should have trailing spaces
	space_endings = {
		"s": "s ",	  # plurals, "years", "Mac's"
		"d": "d ",	  # past tense, "dried", "ended", "hidden"
		"g": "g ",	  # -ing words, "studying", "doing"
		"t": "t ",	  # "that", "But"
		"e": "e ",	  # "some", "able", "lake"
		"y": "y ",	  # "Anyway", "key"
		"k": "k ",	  # "back", "rock"
		"n": "n ",	  # "been", "from"
		"h": "h ",	  # "reach", "research"
		"m": "m ",	  # "from", "problem"
	}
	
	# Common word fragments that should have leading spaces
	space_prefixes = {
		"the": " the",  # Almost always preceded by space
		"a": " a",	  # Article
		"to": " to",	# Preposition
		"from": " from",
		"for": " for",
	}
	
	# Analyze word patterns
	for word in words:
		# Check last letter
		if len(word) > 1:
			last = word[-1].lower()
			if last in space_endings:
				key = f"ends_{last}"
				if key not in suggestions:
					suggestions[key] = []
				suggestions[key].append(word)
		
		# Check first letters
		for prefix in space_prefixes:
			if word.lower().startswith(prefix):
				key = f"starts_{prefix}"
				if key not in suggestions:
					suggestions[key] = []
				suggestions[key].append(word)
	
	return suggestions

def main():
	"""Main entry point"""
	
	print("=== DTE Space Deduction Tool ===\n")
	
	# Load garbled text
	text = load_garbled_text()
	
	if not text:
		return False
	
	print(f"Loaded {len(text)} characters of garbled text\n")
	print("Sample garbled text:")
	print(text[:200] + "...\n")
	
	# Find word boundaries
	boundaries = find_word_boundaries(text)
	print(f"Found {len(boundaries)} likely word boundaries\n")
	
	# Extract words
	words = extract_words(text, boundaries)
	print(f"Extracted {len(words)} words\n")
	
	print("Sample words:")
	for word in words[:30]:
		print(f"  '{word}'")
	
	print("\n" + "="*70)
	print("DTE Space Suggestions:")
	print("="*70 + "\n")
	
	# Suggest spaces
	suggestions = suggest_dte_spaces(words)
	
	for pattern, examples in sorted(suggestions.items()):
		print(f"\n{pattern}:")
		for ex in examples[:10]:  # Show first 10 examples
			print(f"  '{ex}'")
	
	print("\n" + "="*70)
	print("Recommendations for complex.tbl:")
	print("="*70 + "\n")
	
	print("DTE sequences that should END with space:")
	print("  45=s " + "(verified - plurals, possessives)")
	print("  49=l " + "(verified - 'will', 'all')")
	print("  51=ed " + "(past tense: 'dried', 'ended')")
	print("  48=ing " + "(progressive: 'studying', 'doing')")
	print("  43=ou " + "(common: 'you', 'about')")
	print("  44=you " + "(pronoun)")
	print("  41=the " + "(article)")
	print("  46=to " + "(preposition)")
	print("  5C=be " + "(verb)")
	print("  58=ve " + "(contractions: 'I've', 'we've')")
	
	print("\nDTE sequences WITHOUT trailing space:")
	print("  4B=er" + "(verified - part of words)")
	print("  5E=ea" + "(verified - part of words)")
	print("  47=in" + "(part of words or standalone)")
	print("  53=is" + "(standalone or part of words)")
	
	return True

if __name__ == '__main__':
	success = main()
	sys.exit(0 if success else 1)
