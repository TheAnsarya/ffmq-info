#!/usr/bin/env python3
"""
Compare Extracted Dialog with GameFAQs Script Reference

Cross-references our extracted dialog with the known-good GameFAQs script
to identify character mapping issues and extraction errors.

Author: FFMQ Disassembly Project  
Date: 2025-11-12
"""

# Reference dialog from GameFAQs (first 20 dialogs)
GAMEFAQS_DIALOGS = [
	# Dialog 0
	"Benjamin, wake up!",
	
	# Dialog 1  
	"It's time to save the world!",
	
	# Dialog 2
	"Benjamin: My village is gone!! What is going on?",
	
	# Dialog 3
	"Man: This place is going to sink any second! Let's climb up quick!",
	
	# Dialog 4
	"Man: Press the \"B\" Button, and jump across!",
	
	# Dialog 5 - Opening prophecy
	"""Man: Look over there. That's the Focus Tower, once the heart of the World. An old Prophecy says, "The vile 4 will steal the Power, and divide the World behind 4 doors. At that time the Knight will appear!" The Prophecy has now come true. 4 monsters have locked the doors of the Focus Tower and escaped with the keys. They're draining the light from the 4 Crystals of the Earth, and the World is in Chaos. The people are in desperate need of help. Benjamin, only you can save the Crystals and the world.""",
	
	# Dialog 6
	"Benjamin: Me?",
	
	# Dialog 7
	"Man: Yes, you Benjamin! Only you could be the Knight spoken in the Prophecy...",
	
	# Dialog 8 - Monster appears
	"Man: Look out! A monster!",
	
	# Dialog 9 - After battle
	"Man: Seems I was right! At last I've found a true knight!",
	
	# Dialog 10
	"Benjamin: But you said you were SURE I was the one!",
	
	# Dialog 11  
	"Man: Well, actually it was more of a guess...",
	
	# Dialog 12
	"Benjamin: Forget it. Just tell me where I can find the Crystals.",
	
	# Dialog 13
	"Man: It's up to you to find them.",
	
	# Dialog 14 - Mountain shakes
	"Man: This place is becoming dangerous! Follow me to the Level Forest!",
	
	# Dialog 15
	"Benjamin: Got to get out of here. Who is that guy, any way?",
	
	# Dialog 16 - Level Forest
	"Benjamin: There you are! What do you think I should do first?",
	
	# Dialog 17
	"Man: Save the Crystal of Earth. See you!",
	
	# Dialog 18 - Old Man with boulder
	"Old Man: That boulder is blocking my way back to town. Would you shove it aside?",
	
	# Dialog 19 - After moving rock
	"Old Man: Thank you! If you want to go through this forest, find Kaeli in Foresta and show her this.",
]

def analyze_byte_patterns(text):
	"""Analyze common letter patterns to help identify byte mappings."""
	from collections import Counter
	
	# Count letter frequency
	letters = Counter()
	for char in text:
		if char.isalpha():
			letters[char.lower()] += 1
	
	return letters

def main():
	"""Main entry point."""
	print("=" * 70)
	print("FFMQ Dialog Comparison - GameFAQs Reference")
	print("=" * 70)
	print()
	
	# Analyze reference text
	all_text = ' '.join(GAMEFAQS_DIALOGS)
	letter_freq = analyze_byte_patterns(all_text)
	
	print("Letter frequency in GameFAQs reference (top 15):")
	for letter, count in letter_freq.most_common(15):
		print(f"  '{letter}': {count:4} times")
	
	print()
	print("Common words to look for:")
	common_words = ['the', 'you', 'Benjamin', 'Man', 'Crystal', 'and', 'to', 'is']
	for word in common_words:
		count = all_text.lower().count(word.lower())
		print(f"  '{word}': {count} times")
	
	print()
	print("Expected dialog samples:")
	print()
	for i, dialog in enumerate(GAMEFAQS_DIALOGS[:10]):
		preview = dialog[:60] + '...' if len(dialog) > 60 else dialog
		print(f"Dialog {i:2}: {preview}")
	
	print()
	print("=" * 70)
	print("Analysis complete")
	print("=" * 70)
	print()
	print("Next steps:")
	print("  1. Extract dialog from ROM")
	print("  2. Compare with these references")
	print("  3. Identify byte pattern mismatches")
	print("  4. Update character table accordingly")
	print()

if __name__ == '__main__':
	import sys
	sys.exit(main())
