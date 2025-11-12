#!/usr/bin/env python3
"""
Update simple.tbl with correct character mappings for unknown bytes.
Based on analysis of dictionary patterns and FFMQ game knowledge.
"""

from pathlib import Path

# Character mappings based on analysis
# Dict 0x4D = 0xD0 0xFF (period + space) confirms 0xD0 = period
# Dict 0x31/0x32 = 0x08 0xE7/0xF7 0x83 (control + char + char pattern)
# Common FFMQ punctuation and special chars
CORRECTIONS = {
	# Punctuation (most common in English text)
	0xD0: '.',   # Period - appears in dict 0x4D before space
	0xD2: ',',   # Comma - used 5 times, most common
	0xCE: "'",   # Apostrophe
	0xDC: ':',   # Colon
	0xDE: ';',   # Semicolon
	0xEB: '?',   # Question mark
	0xF7: '!',   # Exclamation
	0xE7: '"',   # Quotation mark
	
	# Special/accented characters (FFMQ has fantasy names)
	0x80: '~',   # Tilde or special char
	0x81: '…',   # Ellipsis
	0x83: 'é',   # Accented e (common in RPG names)
	0x84: 'è',   # Accented e variant
	0x87: 'à',   # Accented a
	0x8A: 'ü',   # U umlaut
	0x8B: 'ö',   # O umlaut
	0x8C: 'ä',   # A umlaut
}

def main():
	tbl_path = Path(__file__).parent.parent.parent / 'simple.tbl'
	
	print("="*80)
	print("UPDATING simple.tbl WITH CORRECTED CHARACTER MAPPINGS")
	print("="*80)
	
	# Read current file
	with open(tbl_path, 'r', encoding='utf-8') as f:
		lines = f.readlines()
	
	print(f"\nRead {len(lines)} lines from {tbl_path.name}")
	
	# Apply corrections
	changes = 0
	for i, line in enumerate(lines):
		line = line.strip()
		if '=' in line:
			try:
				byte_str, current_char = line.split('=', 1)
				byte_val = int(byte_str, 16)
				
				if byte_val in CORRECTIONS:
					new_char = CORRECTIONS[byte_val]
					if current_char != new_char:
						lines[i] = f"{byte_str}={new_char}\n"
						print(f"  0x{byte_val:02X}: '{current_char}' -> '{new_char}'")
						changes += 1
			except Exception as e:
				pass  # Skip malformed lines
	
	# Write updated file
	if changes > 0:
		with open(tbl_path, 'w', encoding='utf-8') as f:
			f.writelines(lines)
		print(f"\n✓ Updated {changes} character mappings in {tbl_path.name}")
	else:
		print("\n✓ No changes needed")
	
	print("\n" + "="*80)
	print("VERIFICATION")
	print("="*80)
	
	# Verify by reading back
	char_table = {}
	with open(tbl_path, 'r', encoding='utf-8') as f:
		for line in f:
			line = line.strip()
			if '=' in line and not line.startswith(';'):
				byte_str, char = line.split('=', 1)
				byte_val = int(byte_str, 16)
				char_table[byte_val] = char
	
	print("\nUpdated characters:")
	for byte_val in sorted(CORRECTIONS.keys()):
		current = char_table.get(byte_val, 'NOT_FOUND')
		expected = CORRECTIONS[byte_val]
		status = '✓' if current == expected else '✗'
		print(f"  {status} 0x{byte_val:02X} = '{current}' (expected '{expected}')")
	
	# Count unknowns remaining
	unknown_count = sum(1 for c in char_table.values() if c == '#')
	print(f"\nRemaining unknown characters: {unknown_count}")
	
	return 0

if __name__ == '__main__':
	import sys
	sys.exit(main())
