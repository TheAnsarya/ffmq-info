# FFMQ SNES Development - Coding Standards & Directives

**Version:** 1.0  
**Last Updated:** January 24, 2025  
**Applies To:** All code in ai-code-trial branch and beyond

## Overview

This document defines the coding standards, formatting rules, and development directives for the Final Fantasy Mystic Quest (FFMQ) SNES disassembly and development project.

## Code Formatting Standards

### EditorConfig
All formatting is enforced via `.editorconfig` in the project root.

**Key Settings:**
- **Line Endings:** CRLF (Windows standard)
- **Indentation:** Tabs with 4-space width
- **Encoding:** UTF-8 for all text files
- **Final Newline:** Required for all files
- **Trailing Whitespace:** Trimmed (except Markdown)

### File-Specific Rules

#### Assembly Files (`.asm`, `.s`, `.inc`)
```assembly
; Use tabs for indentation
; Lowercase hexadecimal: 0xff not 0xFF
; Comment every section and non-obvious instruction

	.code					; Tab indentation

	lda #0xff				; Lowercase hex
	sta $2100				; Hardware register access
```

#### Python Files (`.py`)
```python
# Tab indentation (4-space width)
# Maximum line length: 120 characters
# Comprehensive docstrings and comments

def extract_graphics(rom_data, offset):
	"""
	Extract graphics data from ROM at specified offset.
	
	Args:
		rom_data: Byte array containing ROM data
		offset: Starting offset for graphics data
	
	Returns:
		Extracted graphics as byte array
	
	See: https://problemkaputt.de/fullsnes.htm#snespictureprocessingunit
	"""
	# Validate offset is within ROM bounds
	if offset >= len(rom_data):
		raise ValueError("Offset exceeds ROM size")
	
	# Extract 4BPP tile data
	# Reference: https://www.smwiki.net/wiki/4bpp_Tile_Format
	return rom_data[offset:offset + 0x20]
```

#### Makefile
```makefile
# Must use tabs (required by Make)
# Clear comments for each target
# Organized into logical sections

# Build the ROM from source files
rom: $(OUTPUT_ROM)

$(OUTPUT_ROM): $(ASM_SOURCES) $(BASE_ROM) | $(BUILD_DIR)
	@echo "Building ROM..."
	$(ASM) -o $(BUILD_DIR)/main.o $(MAIN_ASM)
	$(LINK) -o $(OUTPUT_ROM) $(BUILD_DIR)/main.o
```

#### PowerShell Scripts (`.ps1`)
```powershell
# Tab indentation
# CRLF line endings (required for Windows)
# Comment each major section

function Test-RomIntegrity {
	<#
	.SYNOPSIS
		Validates ROM file integrity and structure
	
	.DESCRIPTION
		Performs comprehensive checks on SNES ROM files including
		header validation, checksum verification, and structure analysis
	
	.PARAMETER RomPath
		Path to the ROM file to validate
	
	.LINK
		https://snes.nesdev.org/wiki/ROM_file_formats
	#>
	param(
		[Parameter(Mandatory=$true)]
		[string]$RomPath
	)
	
	# Verify file exists
	if (-not (Test-Path $RomPath)) {
		Write-Error "ROM file not found: $RomPath"
		return $false
	}
	
	# Additional validation...
}
```

## SNES Assembly Standards

### Hexadecimal Notation
- **Always use lowercase:** `0xff`, `0x1234`, `$80`, `$c000`
- **Never use uppercase:** ~~0xFF~~, ~~0x1234~~, ~~$c000~~

### Comments
Every assembly file should include:

1. **File Header Comment**
```assembly
;===============================================================================
; Final Fantasy Mystic Quest (SNES)
; Filename: player_stats.asm
; Purpose: Player character statistics and management
; Author: [Name]
; Date: [Date]
; References:
;   - https://datacrystal.tcrf.net/wiki/Final_Fantasy:_Mystic_Quest
;   - FFMQ Memory Map documentation
;===============================================================================
```

2. **Section Comments**
```assembly
;-------------------------------------------------------------------------------
; Player HP Management
; Handles current/max HP tracking and damage calculation
;-------------------------------------------------------------------------------
```

3. **Subroutine Comments**
```assembly
;---------------------------------------
; ApplyDamage
; Applies damage to player character
;
; Input:
;   A = Damage amount (16-bit)
; Output:
;   A = Resulting HP (0 if dead)
; Affects: A, X, Y
; See: https://snes.nesdev.org/wiki/65816_reference
;---------------------------------------
ApplyDamage:
	pha						; Save damage amount
	lda PlayerHP			; Load current HP
	sec						; Set carry for subtraction
	pla						; Restore damage amount
	sbc						; Subtract damage from HP
	bcs .NotDead			; Branch if HP >= 0
	lda #0x0000				; HP = 0 (dead)
.NotDead:
	sta PlayerHP			; Store new HP
	rts
```

4. **Inline Comments**
```assembly
	lda #0x80				; Set forced blank bit
	sta $2100				; Write to INIDISP (screen display)
	
	; Wait for V-Blank before transferring graphics
	; Reference: https://www.nesdev.org/wiki/PPU_rendering
	jsr WaitForVBlank
```

### Memory Addresses
Use meaningful labels instead of magic numbers:

```assembly
; Good - uses named constants
lda PlayerLevel
cmp #MAX_LEVEL
bcs .AtMaxLevel

; Bad - uses magic numbers
lda $7e1010
cmp #0x29
bcs .AtMaxLevel
```

### Code Organization

1. **Constants and Definitions** (top of file)
2. **RAM Variables** (with .define or equates)
3. **Subroutines** (alphabetically or logically grouped)
4. **Data Tables** (at end of file)

Example:
```assembly
;===============================================================================
; Constants
;===============================================================================

.define MAX_HP				999
.define MAX_LEVEL			28

;===============================================================================
; RAM Variables
;===============================================================================

PlayerHP		= $7e1014	; Current HP (16-bit)
PlayerMaxHP		= $7e1016	; Maximum HP (16-bit)
PlayerLevel		= $7e1010	; Current level (8-bit)

;===============================================================================
; Subroutines
;===============================================================================

; ... subroutines here ...

;===============================================================================
; Data Tables
;===============================================================================

LevelUpExpTable:
	.word 100, 250, 500, 800	; Experience required for levels 2-5
	; ... more data ...
```

## Code Quality Standards

### Modern Practices
- Use latest stable versions of all tools (ca65, Python 3.x, etc.)
- Follow language-specific best practices and idioms
- Leverage modern features where appropriate
- Avoid deprecated functions and techniques

### Separation of Concerns
When files exceed ~500 lines or contain multiple distinct responsibilities:

1. **Split into logical components:**
```
Before:
	tools/extract_all.py (1200 lines)

After:
	tools/graphics/
		tile_extractor.py
		palette_extractor.py
		sprite_extractor.py
	tools/text/
		text_extractor.py
		encoding.py
	tools/music/
		sequence_extractor.py
		sample_extractor.py
```

2. **Each file has single responsibility**
3. **Related files grouped in subdirectories**
4. **Clear module/class hierarchy**

### Documentation Requirements

Every function/method must include:
- **Purpose:** What it does
- **Parameters:** What inputs it expects
- **Returns:** What it outputs
- **Side Effects:** Any state changes
- **References:** Links to relevant documentation

Example:
```python
def decode_4bpp_tile(tile_data: bytes) -> list[int]:
	"""
	Decode a single 4BPP SNES tile into pixel indices.
	
	A 4BPP tile is 32 bytes representing an 8x8 pixel tile with 16 colors.
	Each pixel is represented by 4 bits (bitplane format).
	
	Args:
		tile_data: 32-byte array containing 4BPP tile data
	
	Returns:
		List of 64 integers (0-15) representing pixel color indices
		Arranged in row-major order (left to right, top to bottom)
	
	Raises:
		ValueError: If tile_data is not exactly 32 bytes
	
	References:
		- https://www.smwiki.net/wiki/4bpp_Tile_Format
		- https://problemkaputt.de/fullsnes.htm#snespictureprocessingunitppuvram
	
	Example:
		>>> tile = rom_data[0x80000:0x80020]
		>>> pixels = decode_4bpp_tile(tile)
		>>> print(pixels[0])  # Color index of first pixel
		5
	"""
	# Validate input size
	if len(tile_data) != 32:
		raise ValueError(f"4BPP tile must be 32 bytes, got {len(tile_data)}")
	
	# Decode bitplanes into pixel indices
	# Each row is 2 bytes per bitplane (4 bitplanes = 8 bytes per row)
	pixels = []
	
	# Process each of 8 rows
	for row in range(8):
		row_offset = row * 2
		
		# Get bitplane bytes for this row
		bp0 = tile_data[row_offset + 0]		# Bitplane 0
		bp1 = tile_data[row_offset + 1]		# Bitplane 1
		bp2 = tile_data[row_offset + 16]	# Bitplane 2
		bp3 = tile_data[row_offset + 17]	# Bitplane 3
		
		# Decode each of 8 pixels in the row
		for bit in range(7, -1, -1):
			# Combine bits from all 4 bitplanes
			pixel = (
				((bp0 >> bit) & 1) |		# Bit 0
				(((bp1 >> bit) & 1) << 1) |	# Bit 1
				(((bp2 >> bit) & 1) << 2) |	# Bit 2
				(((bp3 >> bit) & 1) << 3)	# Bit 3
			)
			pixels.append(pixel)
	
	return pixels
```

### Testing Requirements

All code must be tested before committing:

1. **Unit Tests** for individual functions
2. **Integration Tests** for tool workflows
3. **ROM Validation** for assembly changes
4. **Manual Testing** in emulator for gameplay changes

Example test:
```python
def test_decode_4bpp_tile():
	"""Test 4BPP tile decoding with known data."""
	# Create a test tile: solid color 5 (0x5555...)
	test_tile = bytearray(32)
	
	# Set bitplane 0 to all 1s (0xFF)
	for i in range(0, 16, 2):
		test_tile[i] = 0xff
	
	# Set bitplane 2 to all 1s (0xFF)
	for i in range(16, 32, 2):
		test_tile[i] = 0xff
	
	# Decode tile
	pixels = decode_4bpp_tile(bytes(test_tile))
	
	# All pixels should be color index 5 (binary 0101)
	assert len(pixels) == 64, "Tile should have 64 pixels"
	assert all(p == 5 for p in pixels), "All pixels should be index 5"
```

### Blank Lines Between Stages

Use blank lines to separate logical sections:

```python
# Initialize variables
rom_path = "path/to/rom.sfc"
output_dir = "assets/graphics"

# Load ROM data
with open(rom_path, 'rb') as f:
	rom_data = f.read()

# Validate ROM header
if not validate_header(rom_data):
	raise ValueError("Invalid ROM header")

# Extract graphics
for i, offset in enumerate(graphics_offsets):
	tile_data = extract_tile(rom_data, offset)
	save_tile(tile_data, output_dir, i)

# Generate report
create_extraction_report(output_dir)
```

## Git Standards

### Commit Messages

**Format:**
```
Short summary (50 chars or less)

Detailed description of what changed and why. Wrap at 72 characters.
Use bullet points for multiple changes:
- First change with context
- Second change with rationale
- Third change with impact

Technical details can include code snippets, file paths, or references
to issues/documentation.
```

**Good Examples:**
```
Add 4BPP tile extraction tool with palette support

- Implemented decode_4bpp_tile() for bitplane conversion
- Added palette extraction from ROM offset 0xC0000
- Created export functionality to PNG format
- Comprehensive documentation and unit tests included

This enables extraction and editing of all FFMQ graphics data.
Tested with all 512 tiles in bank $07.
```

**Bad Examples:**
```
fixed stuff
```
```
update
```
```
wip
```

### Commit Frequency

- Commit after completing each logical unit of work
- Commit before switching tasks
- Commit after testing confirms functionality
- **Don't commit broken code** (except in feature branches)

### Chat Log Maintenance

Update chat logs:
- At end of each work session
- When completing major features
- Before long breaks from the project
- When making significant decisions

Format:
```markdown
## Session: [Date] - [Topic]

### What Was Done
- Bullet point summary
- Key accomplishments

### Files Modified
- List of changed files
- Purpose of each change

### Decisions Made
- Technical choices
- Rationale

### Next Steps
- What to work on next
- Open questions
```

## File Organization

### Namespace Alignment

File structure should match logical organization:

```
tools/
	graphics/				# Graphics tools namespace
		__init__.py
		tile_decoder.py		# graphics.tile_decoder
		palette_manager.py	# graphics.palette_manager
		sprite_extractor.py	# graphics.sprite_extractor
	text/					# Text tools namespace
		__init__.py
		extractor.py		# text.extractor
		encoder.py			# text.encoder
		compression.py		# text.compression
	music/					# Music tools namespace
		__init__.py
		sequence_parser.py	# music.sequence_parser
		brr_decoder.py		# music.brr_decoder
```

### Assembly Organization

```
src/
	asm/
		main.s				# Main entry point
		init/
			hardware.s		# Hardware initialization
			vectors.s		# Interrupt vectors
		game/
			player.s		# Player character code
			battle.s		# Battle system
			menu.s			# Menu system
		lib/
			math.s			# Math utilities
			memory.s		# Memory management
	include/
		snes.inc			# SNES hardware registers
		ffmq.inc			# FFMQ constants
		macros.inc			# Assembly macros
	data/
		graphics/
			tiles.bin		# Tile data
			palettes.bin	# Palette data
		text/
			strings.bin		# Text strings
		music/
			sequences.bin	# Music sequences
```

## Tools and Environment

### Required Tools
- **ca65/ld65** - Primary assembler/linker
- **asar** - Alternative assembler for compatibility
- **Python 3.11+** - Latest stable Python
- **MesenS** - Latest version for testing
- **Git** - Version control

### Recommended Tools
- **VS Code** - Editor with EditorConfig support
- **Prettier** - Code formatting (respects EditorConfig)
- **PyLint** - Python linting
- **GitHub Copilot** - AI assistance

### Environment Setup

Run `setup.ps1` to configure development environment:
```powershell
.\setup.ps1
```

This checks:
- Required tools installed
- Python packages available
- ROM files present
- Directory structure created

## References

### SNES Development
- [SNES Development Manual](https://problemkaputt.de/fullsnes.htm)
- [65816 Reference](https://www.nesdev.org/wiki/Programming_manual)
- [Super NES Graphics](https://www.smwiki.net/wiki/Graphics)

### FFMQ Specific
- [DataCrystal FFMQ](https://datacrystal.tcrf.net/wiki/Final_Fantasy:_Mystic_Quest)
- [FFMQ Game Info](https://github.com/TheAnsarya/GameInfo/tree/main/Final%20Fantasy%20Mystic%20Quest%20(SNES))

### Tools
- [ca65 Documentation](https://cc65.github.io/doc/ca65.html)
- [Python Style Guide](https://peps.python.org/pep-0008/)
- [EditorConfig](https://editorconfig.org/)

## Questions or Issues?

For questions about these standards:
1. Check this document first
2. Review existing code examples
3. Ask in project discussions
4. Update this document if clarification needed

---

**Document Version:** 1.0  
**Last Updated:** January 24, 2025  
**Maintained By:** Development Team
