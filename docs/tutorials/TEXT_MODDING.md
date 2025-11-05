# Text Modding Tutorial

Learn how to modify text and dialogue in Final Fantasy Mystic Quest, including enemy names, dialogue strings, menu text, and item names.

## Table of Contents

- [Overview](#overview)
- [Text System Architecture](#text-system-architecture)
- [Character Encoding](#character-encoding)
- [Basic Text Modifications](#basic-text-modifications)
- [Dialogue Editing](#dialogue-editing)
- [Advanced Text Editing](#advanced-text-editing)
- [Text Extraction Tools](#text-extraction-tools)
- [Best Practices](#best-practices)

---

## Overview

### What is Text Modding?

Text modding involves modifying the visible text in the game, including:
- **Enemy names** (e.g., "Brownie", "Dark King")
- **Dialogue** (NPC conversations, cutscenes)
- **Menu text** (commands, options)
- **Item/spell names**
- **Battle messages**
- **Location names**

### Prerequisites

- Python 3.9 or higher
- FFMQ ROM file
- Repository cloned and setup complete
- Basic understanding of character encoding

---

## Text System Architecture

### Text Storage in ROM

FFMQ stores text in multiple locations:

```
ROM Structure:
├── Enemy Names:    Bank $02, ~83 names (25 bytes each)
├── Item Names:     Bank $04, ~256 items (12 bytes each)
├── Spell Names:    Bank $04, ~64 spells (12 bytes each)
├── Dialogue:       Bank $03, pointer-based (variable length)
├── Menu Text:      Bank $0D, fixed locations
└── Location Names: Bank $05, ~128 names (20 bytes each)
```

### Character Encoding

FFMQ uses a custom character encoding table defined in `simple.tbl`:

```
Byte → Character mapping:
0x90-0x99 → Digits (0-9)
0x9A-0xB3 → Uppercase (A-Z)
0xB4-0xCD → Lowercase (a-z)
0x00      → String terminator
0x01      → Newline
0x02      → Wait for button press
0x03      → Clear text box
```

### Text Length Limitations

Different text types have different length restrictions:

| Text Type | Max Length | Notes |
|-----------|-----------|-------|
| Enemy Names | 25 bytes | Null-terminated |
| Item Names | 12 bytes | Fixed length |
| Spell Names | 12 bytes | Fixed length |
| Dialogue | 512 bytes | Variable, pointer-based |
| Menu Text | Varies | Context-dependent |

---

## Character Encoding

### Understanding the Character Table

The `simple.tbl` file maps byte values to characters:

```plaintext
90=0  91=1  92=2  93=3  94=4  95=5  96=6  97=7  98=8  99=9
9A=A  9B=B  9C=C  9D=D  9E=E  9F=F
A0=G  A1=H  A2=I  A3=J  A4=K  A5=L  A6=M  A7=N  A8=O  A9=P
AA=Q  AB=R  AC=S  AD=T  AE=U  AF=V
B0=W  B1=X  B2=Y  B3=Z
B4=a  B5=b  B6=c  B7=d  B8=e  B9=f  BA=g  BB=h  BC=i  BD=j
BE=k  BF=l  C0=m  C1=n  C2=o  C3=p  C4=q  C5=r  C6=s  C7=t
C8=u  C9=v  CA=w  CB=x  CC=y  CD=z
```

### Common Control Codes

```python
CTRL_END     = 0x00  # End of string (required)
CTRL_NEWLINE = 0x01  # Line break
CTRL_WAIT    = 0x02  # Wait for button press
CTRL_CLEAR   = 0x03  # Clear dialog box
CTRL_NAME    = 0x04  # Insert character name
CTRL_ITEM    = 0x05  # Insert item name
```

### Encoding Examples

**Text: "Fire"**
```
Bytes: 0x9F 0xBC 0xC5 0xB8 0x00
       F    i    r    e    END
```

**Text: "Dark King"**
```
Bytes: 0x9D 0xB4 0xC5 0xBE 0x06 0xA4 0xBC 0xC1 0xBA 0x00
       D    a    r    k    _    K    i    n    g    END
```

---

## Basic Text Modifications

### Example 1: Rename an Enemy

Let's rename "Brownie" to "Goblin":

```python
#!/usr/bin/env python3
"""Rename Brownie to Goblin"""

import json
from pathlib import Path

def rename_brownie_to_goblin():
	project_dir = Path(__file__).parent.parent.parent
	enemies_file = project_dir / "data" / "extracted" / "enemies" / "enemies.json"
	
	# Load enemy data
	with open(enemies_file, 'r', encoding='utf-8') as f:
		data = json.load(f)
	
	# Find and rename Brownie
	for enemy in data['enemies']:
		if enemy['name'] == 'Brownie':
			enemy['name'] = 'Goblin'
			print(f"✅ Renamed: Brownie → Goblin")
			break
	
	# Save changes
	with open(enemies_file, 'w', encoding='utf-8') as f:
		json.dump(data, f, indent=2)
	
	print("\nNext steps:")
	print("  1. Run: python build.ps1")
	print("  2. Test in emulator")

if __name__ == "__main__":
	rename_brownie_to_goblin()
```

**Length Warning**: Enemy names must fit within 25 bytes. ASCII characters use 1 byte each.

### Example 2: Rename Multiple Enemies

Give all slime-type enemies consistent names:

```python
#!/usr/bin/env python3
"""Rename slime enemies"""

import json
from pathlib import Path

def rename_slimes():
	project_dir = Path(__file__).parent.parent.parent
	enemies_file = project_dir / "data" / "extracted" / "enemies" / "enemies.json"
	
	# Slime renaming map
	slime_names = {
		'Slime': 'Green Slime',
		'Jelly': 'Blue Jelly',
		'Ooze': 'Red Ooze'
	}
	
	# Load enemy data
	with open(enemies_file, 'r', encoding='utf-8') as f:
		data = json.load(f)
	
	# Rename slimes
	for enemy in data['enemies']:
		if enemy['name'] in slime_names:
			old_name = enemy['name']
			enemy['name'] = slime_names[old_name]
			print(f"✅ {old_name:15} → {enemy['name']}")
	
	# Save changes
	with open(enemies_file, 'w', encoding='utf-8') as f:
		json.dump(data, f, indent=2)
	
	print("\nSlime enemies renamed successfully!")

if __name__ == "__main__":
	rename_slimes()
```

### Example 3: Create Themed Enemy Names

Add a prefix to all undead enemies:

```python
#!/usr/bin/env python3
"""Add 'Cursed' prefix to undead enemies"""

import json
from pathlib import Path

def add_cursed_prefix():
	project_dir = Path(__file__).parent.parent.parent
	enemies_file = project_dir / "data" / "extracted" / "enemies" / "enemies.json"
	
	# Undead enemy names
	undead = ['Skeleton', 'Red Bone', 'Skuldier', 'Zombie', 'Mummy']
	
	# Load enemy data
	with open(enemies_file, 'r', encoding='utf-8') as f:
		data = json.load(f)
	
	# Add prefix to undead
	for enemy in data['enemies']:
		if enemy['name'] in undead:
			old_name = enemy['name']
			new_name = f"Cursed {old_name}"
			
			# Check length (max 25 bytes)
			if len(new_name.encode('utf-8')) <= 25:
				enemy['name'] = new_name
				print(f"✅ {old_name:15} → {new_name}")
			else:
				print(f"⚠️  {old_name}: New name too long, skipping")
	
	# Save changes
	with open(enemies_file, 'w', encoding='utf-8') as f:
		json.dump(data, f, indent=2)

if __name__ == "__main__":
	add_cursed_prefix()
```

---

## Dialogue Editing

### Understanding Dialogue Structure

Dialogue in FFMQ uses a pointer-based system:

```
Pointer Table: Bank $01, ROM $00D636
Dialogue Data: Bank $03, various addresses
Format: Null-terminated strings with control codes
```

### Current State: Text Extraction

While full dialogue editing isn't yet implemented in the build system, you can extract and analyze dialogue:

```python
#!/usr/bin/env python3
"""Extract and display dialogue strings"""

import sys
from pathlib import Path

# Add tools directory to path
sys.path.insert(0, str(Path(__file__).parent.parent.parent / 'tools' / 'extraction'))

from extract_text import TextExtractor

def extract_dialogue():
	project_dir = Path(__file__).parent.parent.parent
	rom_file = project_dir / "roms" / "ffmq.sfc"
	output_dir = project_dir / "data" / "extracted" / "text"
	
	# Create extractor
	extractor = TextExtractor(str(rom_file))
	
	# Load ROM and character table
	if not extractor.load_rom():
		return
	if not extractor.load_character_table():
		return
	
	# Extract all text
	text_data = extractor.extract_all()
	
	# Save to files
	output_dir.mkdir(parents=True, exist_ok=True)
	extractor.save_text_files(str(output_dir), text_data)
	extractor.save_json(str(output_dir), text_data)
	
	print(f"\n✅ Text extracted to: {output_dir}")
	print(f"   - text_data.json (structured data)")
	print(f"   - *.txt files (human-readable)")

if __name__ == "__main__":
	extract_dialogue()
```

**Output Example**:
```
data/extracted/text/
├── dialog.txt           # All dialogue strings
├── item_names.txt       # Item name list
├── monster_names.txt    # Enemy name list
└── text_data.json       # All text data (JSON)
```

### Dialogue String Format

Extracted dialogue includes control codes:

```
String 001: "Welcome to[NEWLINE]the town!"
String 002: "Take this[WAIT][ITEM]."
String 003: "[NAME], you must[NEWLINE]save the world!"
```

Control codes provide formatting:
- `[NEWLINE]` - Start new line
- `[WAIT]` - Wait for player input
- `[CLEAR]` - Clear text box
- `[NAME]` - Insert character name
- `[ITEM]` - Insert item name

---

## Advanced Text Editing

### Example 4: Validate Text Lengths

Check that all enemy names fit within limits:

```python
#!/usr/bin/env python3
"""Validate enemy name lengths"""

import json
from pathlib import Path

def validate_enemy_names():
	project_dir = Path(__file__).parent.parent.parent
	enemies_file = project_dir / "data" / "extracted" / "enemies" / "enemies.json"
	
	# Load enemy data
	with open(enemies_file, 'r', encoding='utf-8') as f:
		data = json.load(f)
	
	print("Enemy Name Length Validation")
	print("=" * 60)
	
	max_length = 25  # Maximum bytes for enemy names
	issues_found = False
	
	for enemy in data['enemies']:
		name = enemy['name']
		byte_length = len(name.encode('utf-8'))
		
		if byte_length > max_length:
			print(f"❌ {name:25} {byte_length} bytes (EXCEEDS LIMIT)")
			issues_found = True
		elif byte_length > max_length - 3:
			print(f"⚠️  {name:25} {byte_length} bytes (close to limit)")
	
	if not issues_found:
		print("\n✅ All enemy names within length limits!")
	else:
		print(f"\n❌ Some names exceed {max_length} byte limit")

if __name__ == "__main__":
	validate_enemy_names()
```

### Example 5: Batch Rename with Pattern

Apply naming pattern to all enemies:

```python
#!/usr/bin/env python3
"""Apply difficulty indicator to enemy names"""

import json
from pathlib import Path

def add_difficulty_indicators():
	project_dir = Path(__file__).parent.parent.parent
	enemies_file = project_dir / "data" / "extracted" / "enemies" / "enemies.json"
	
	# Load enemy data
	with open(enemies_file, 'r', encoding='utf-8') as f:
		data = json.load(f)
	
	# Categorize by HP
	for enemy in data['enemies']:
		hp = enemy['hp']
		old_name = enemy['name']
		
		# Skip if name already has indicator
		if old_name.startswith(('★', '☆', '◆')):
			continue
		
		# Determine difficulty
		if hp < 500:
			prefix = "☆"  # Easy
		elif hp < 5000:
			prefix = "◆"  # Medium
		else:
			prefix = "★"  # Hard
		
		new_name = f"{prefix} {old_name}"
		
		# Check length
		if len(new_name.encode('utf-8')) <= 25:
			enemy['name'] = new_name
			print(f"{prefix} {old_name:22} (HP: {hp})")
		else:
			# Name too long, try without space
			new_name = f"{prefix}{old_name}"
			if len(new_name.encode('utf-8')) <= 25:
				enemy['name'] = new_name
				print(f"{prefix} {old_name:22} (HP: {hp})")
			else:
				print(f"⚠️  Skipped {old_name} (name too long)")
	
	# Save changes
	with open(enemies_file, 'w', encoding='utf-8') as f:
		json.dump(data, f, indent=2)

if __name__ == "__main__":
	add_difficulty_indicators()
```

### Example 6: Character Encoding Converter

Convert text to FFMQ byte encoding:

```python
#!/usr/bin/env python3
"""Convert text to FFMQ byte encoding"""

from pathlib import Path

# Character encoding map (based on simple.tbl)
CHAR_TO_BYTE = {
	# Digits
	'0': 0x90, '1': 0x91, '2': 0x92, '3': 0x93, '4': 0x94,
	'5': 0x95, '6': 0x96, '7': 0x97, '8': 0x98, '9': 0x99,
	# Uppercase
	'A': 0x9A, 'B': 0x9B, 'C': 0x9C, 'D': 0x9D, 'E': 0x9E, 'F': 0x9F,
	'G': 0xA0, 'H': 0xA1, 'I': 0xA2, 'J': 0xA3, 'K': 0xA4, 'L': 0xA5,
	'M': 0xA6, 'N': 0xA7, 'O': 0xA8, 'P': 0xA9, 'Q': 0xAA, 'R': 0xAB,
	'S': 0xAC, 'T': 0xAD, 'U': 0xAE, 'V': 0xAF, 'W': 0xB0, 'X': 0xB1,
	'Y': 0xB2, 'Z': 0xB3,
	# Lowercase
	'a': 0xB4, 'b': 0xB5, 'c': 0xB6, 'd': 0xB7, 'e': 0xB8, 'f': 0xB9,
	'g': 0xBA, 'h': 0xBB, 'i': 0xBC, 'j': 0xBD, 'k': 0xBE, 'l': 0xBF,
	'm': 0xC0, 'n': 0xC1, 'o': 0xC2, 'p': 0xC3, 'q': 0xC4, 'r': 0xC5,
	's': 0xC6, 't': 0xC7, 'u': 0xC8, 'v': 0xC9, 'w': 0xCA, 'x': 0xCB,
	'y': 0xCC, 'z': 0xCD,
	# Special
	' ': 0x06, '.': 0xCE, ',': 0xCF, '!': 0xD0, '?': 0xD1,
	# Control codes
	'\n': 0x01, '\0': 0x00
}

def text_to_bytes(text: str) -> list:
	"""Convert text string to FFMQ byte encoding"""
	bytes_out = []
	
	for char in text:
		if char in CHAR_TO_BYTE:
			bytes_out.append(CHAR_TO_BYTE[char])
		else:
			print(f"Warning: Unknown character '{char}', using space")
			bytes_out.append(0x06)  # Space
	
	# Add null terminator
	bytes_out.append(0x00)
	
	return bytes_out

def bytes_to_hex(byte_list: list) -> str:
	"""Convert byte list to hex string"""
	return ' '.join(f"{b:02X}" for b in byte_list)

def main():
	# Example usage
	test_strings = [
		"Dark King",
		"Fire",
		"Behemoth",
		"Cursed Skeleton"
	]
	
	print("FFMQ Text Encoder")
	print("=" * 60)
	
	for text in test_strings:
		bytes_data = text_to_bytes(text)
		hex_data = bytes_to_hex(bytes_data)
		print(f"\nText: \"{text}\"")
		print(f"Bytes: {hex_data}")
		print(f"Length: {len(bytes_data) - 1} bytes (excluding terminator)")

if __name__ == "__main__":
	main()
```

**Output**:
```
Text: "Dark King"
Bytes: 9D B4 C5 BE 06 A4 BC C1 BA 00
Length: 9 bytes (excluding terminator)
```

---

## Text Extraction Tools

### Using extract_text.py

Extract all text from the ROM:

```powershell
# Extract all text types
python tools/extraction/extract_text.py roms/ffmq.sfc data/extracted/text

# Extract with specific format
python tools/extraction/extract_text.py roms/ffmq.sfc data/extracted/text --format json

# Generate statistics
python tools/extraction/extract_text.py roms/ffmq.sfc data/extracted/text --stats
```

### Output Files

```
data/extracted/text/
├── text_data.json           # All text (JSON format)
├── text_data.csv            # All text (CSV format)
├── dialog.txt               # Dialogue strings
├── item_names.txt           # Item names
├── monster_names.txt        # Enemy names
├── spell_names.txt          # Spell names
└── text_statistics.txt      # Analysis report
```

### Text Statistics

The extraction tool generates useful statistics:

```
Text Statistics Report
======================

Dialog Strings:      256 entries
Item Names:          256 entries
Monster Names:        83 entries
Spell Names:          64 entries

Total Text Size:   24,576 bytes
Average Length:      12.4 bytes
Longest String:     128 bytes
Shortest String:      3 bytes

Control Code Usage:
  [NEWLINE]:         452 occurrences
  [WAIT]:            183 occurrences
  [NAME]:             89 occurrences
```

---

## Best Practices

### Length Management

**Always check text length before modifying**:

```python
def check_length(text: str, max_bytes: int = 25) -> bool:
	"""Verify text fits within byte limit"""
	byte_length = len(text.encode('utf-8'))
	return byte_length <= max_bytes
```

**Example**:
```python
new_name = "Super Ultra Mega Dragon"
if check_length(new_name, 25):
	enemy['name'] = new_name
else:
	print(f"Error: '{new_name}' is too long ({len(new_name)} bytes)")
```

### Character Support

**Stick to supported characters**:
- ✅ A-Z, a-z (uppercase and lowercase)
- ✅ 0-9 (digits)
- ✅ Space, period, comma, !, ?
- ❌ Most special characters (not in character table)
- ❌ Unicode characters (not supported)

### Testing Procedure

1. **Make Changes**: Modify JSON data files
2. **Validate**: Run length checks and encoding validation
3. **Build**: Run `python build.ps1`
4. **Test**: Load ROM in emulator
5. **Verify**: Check text appears correctly in-game
6. **Revert**: Use `git restore` if issues occur

### Version Control

**Always commit before text modding**:

```powershell
# Commit before changes
git add -A
git commit -m "Pre-text-mod checkpoint"

# Make your text changes
python your_text_mod.py
python build.ps1

# Test in emulator
# If problems occur:
git restore data/extracted/enemies/enemies.json
```

### Localization Considerations

If creating translations:

1. **Preserve control codes**: Keep `[NEWLINE]`, `[WAIT]` intact
2. **Maintain length**: Translated text must fit limits
3. **Test thoroughly**: Different languages have different lengths
4. **Document changes**: Keep translation notes

### Common Pitfalls

**❌ Don't:**
- Use characters not in the encoding table
- Exceed maximum text lengths
- Forget null terminators
- Remove control codes from dialogue

**✅ Do:**
- Validate lengths before saving
- Test all text changes in-game
- Keep backups of original data
- Document your modifications

---

## Troubleshooting

### Issue: Text appears garbled

**Cause**: Using characters not in the encoding table

**Solution**: Stick to A-Z, a-z, 0-9, and basic punctuation

### Issue: Text is truncated

**Cause**: Exceeds maximum length for text type

**Solution**: Shorten text or use abbreviations

### Issue: Build fails after text changes

**Cause**: Invalid character encoding or missing terminator

**Solution**:
```powershell
# Validate your JSON
python -c "import json; json.load(open('data/extracted/enemies/enemies.json'))"

# Restore and try again
git restore data/extracted/enemies/enemies.json
```

### Issue: Dialogue doesn't appear

**Cause**: Dialogue editing not yet fully integrated into build system

**Solution**: Currently, focus on enemy names, item names (data already extracted). Full dialogue editing coming in future updates.

---

## Next Steps

### Current Capabilities
- ✅ Enemy name editing (fully supported)
- ✅ Text extraction (all text types)
- ✅ Character encoding (documented)
- 🔄 Dialogue editing (extraction only, re-insertion in progress)

### Future Enhancements
- Full dialogue re-insertion system
- Menu text editing
- Item/spell description editing
- DTE (Dual Tile Encoding) support
- Text compression handling

### Related Tutorials
- [Enemy Modding Guide](ENEMY_MODDING.md) - Modify enemy stats
- [Spell Modding Guide](SPELL_MODDING.md) - Edit spell data
- [Advanced Modding](ADVANCED_MODDING.md) - Assembly-level changes

### Community Resources
- Share your text mods on FFMQ forums
- Create translation patches
- Document your findings

---

**Happy text modding! 📝**
