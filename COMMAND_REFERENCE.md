# FFMQ Dialog CLI - Command Reference

Quick reference for all 15 commands in the FFMQ Dialog CLI.

## Command List

| # | Command | Purpose | Example |
|---|---------|---------|---------|
| 1 | `list` | List all dialog IDs | `dialog_cli.py list` |
| 2 | `show` | Show specific dialog | `dialog_cli.py show 0x21` |
| 3 | `search` | Advanced text search | `dialog_cli.py search "Knight" -r` |
| 4 | `find` | Simple text search | `dialog_cli.py find "Crystal"` |
| 5 | `edit` | Edit dialog text | `dialog_cli.py edit 0x21 --text "New"` |
| 6 | `export` | Export all dialogs | `dialog_cli.py export dialogs.json` |
| 7 | `stats` | ROM statistics | `dialog_cli.py stats -v` |
| 8 | `count` | Count metrics | `dialog_cli.py count 0x59` |
| 9 | `diff` | Compare two ROMs | `dialog_cli.py diff rom1 rom2` |
| 10 | `extract` | Extract single dialog | `dialog_cli.py extract 0x59` |
| 11 | `replace` | Batch find/replace | `dialog_cli.py replace "old" "new"` |
| 12 | `verify` | Verify ROM integrity | `dialog_cli.py verify -s` |
| 13 | `backup` | Create backup | `dialog_cli.py backup -t -v` |
| 14 | `validate` | Validate dialogs | `dialog_cli.py validate -v` |
| 15 | `import` | Import from JSON | `dialog_cli.py import edited.json` |

---

## 1. list - List All Dialog IDs

Lists all dialog IDs in the ROM.

```bash
# Basic list (IDs only)
python dialog_cli.py list

# Verbose (show text)
python dialog_cli.py list -v
```

**Output:**
```
Found 116 dialogs
  0x0001  0x0002  0x0004  0x0007  0x000A  0x000B  0x000C  0x000D
  ...
```

---

## 2. show - Show Specific Dialog

Display dialog with full metadata.

```bash
python dialog_cli.py show 0x21
```

**Output:**
```
Dialog ID:  0x0021
Pointer:    0x00F8D0
Address:    0x01F8D0
Length:     302 bytes

Text:
----------------------------------------------------------------------
[P25][YELLOW][P26][P1A][C81]Look over there...
----------------------------------------------------------------------
```

---

## 3. search - Advanced Search

Search with regex, fuzzy matching, and filters.

```bash
# Text search
python dialog_cli.py search "Knight"

# Regex search
python dialog_cli.py search "K.*t" -r

# Case-sensitive
python dialog_cli.py search "Knight" -s

# Show full text
python dialog_cli.py search "prophecy" -v

# Limit results
python dialog_cli.py search "the" -m 10
```

---

## 4. find - Simple Find

Quick find - just shows matching dialog IDs.

```bash
# Find dialogs
python dialog_cli.py find "Crystal"

# Ignore case
python dialog_cli.py find "crystal" -i

# Count only
python dialog_cli.py find "prophecy" -c
```

**Output:**
```
Found 12 dialogs containing 'Crystal':
  0x0021  0x0023  0x0024  0x0025  0x0026  0x0027  0x0028  0x0029
```

---

## 5. edit - Edit Dialog

Edit dialog text and save to ROM.

```bash
# Interactive mode
python dialog_cli.py edit 0x21

# Inline mode
python dialog_cli.py edit 0x21 --text "New text[PARA]Paragraph 2"

# Auto-confirm
python dialog_cli.py edit 0x21 --text "New" --yes

# Save to different ROM
python dialog_cli.py edit 0x21 --text "New" --output patched.sfc
```

**Interactive Example:**
```
Editing Dialog 0x0021
Current text: [old text]

Enter new text: New dialog here

Validation: ✓ Valid
Encoded to 15 bytes (original: 302 bytes)
Save changes? [y/N]: y
✓ Dialog updated
```

---

## 6. export - Export Dialogs

Export all dialogs to file.

```bash
# JSON format (default)
python dialog_cli.py export dialogs.json

# Plain text
python dialog_cli.py export dialogs.txt --format txt

# CSV format
python dialog_cli.py export dialogs.csv --format csv
```

**Formats:**
- **JSON**: Full metadata, importable
- **TXT**: Human-readable
- **CSV**: Spreadsheet-compatible

---

## 7. stats - Statistics

Show ROM dialog statistics.

```bash
# Basic stats
python dialog_cli.py stats

# Detailed analysis
python dialog_cli.py stats -v
```

**Output:**
```
Dialog Count: 116 dialogs, 4,162 bytes
Size Range: 2-302 bytes
Control Code Usage: [ITEM]=78, [NORMAL]=69, [PAGE]=44
Text Analysis: 9,876 chars, 57.9% compression, 221 unique words
```

---

## 8. count - Count Metrics

Count characters, bytes, and words.

```bash
# Count all dialogs
python dialog_cli.py count

# Count specific dialog
python dialog_cli.py count 0x59
```

**Output (specific):**
```
Dialog 0x0059:
  Characters: 393
  Bytes: 233
  Compression: 40.7%
  Words: 24
  Control codes: 14
```

---

## 9. diff - Compare ROMs

Compare dialogs between two ROMs.

```bash
# Basic comparison
python dialog_cli.py diff rom1.sfc rom2.sfc

# Verbose (show changes)
python dialog_cli.py diff rom1.sfc rom2.sfc -v

# Limit differences shown
python dialog_cli.py diff rom1.sfc rom2.sfc -v -m 5
```

**Output:**
```
Summary:
  Changed: 2
  Added: 0
  Removed: 0
  Unchanged: 114

Changed dialogs:
  0x0021  0x0041
```

---

## 10. extract - Extract Dialog

Extract single dialog to text file.

```bash
# Default filename
python dialog_cli.py extract 0x59

# Custom filename
python dialog_cli.py extract 0x59 -o my_dialog.txt

# Include metadata
python dialog_cli.py extract 0x59 -m
```

**Output:**
```
✓ Extracted dialog 0x0059 to dialog_0059.txt
  Length: 258 bytes
```

---

## 11. replace - Batch Replace

Find and replace across all dialogs.

```bash
# Basic replace
python dialog_cli.py replace "old" "new"

# Dry run (preview)
python dialog_cli.py replace "old" "new" --dry-run

# Ignore case
python dialog_cli.py replace "OLD" "new" -i

# Verbose output
python dialog_cli.py replace "old" "new" -v

# Save to different ROM
python dialog_cli.py replace "old" "new" -o patched.sfc
```

**Output:**
```
Found 5 dialogs containing 'old'
Replacing 'old' with 'new'

Summary:
  Matched: 5
  Updated: 5
  Errors: 0
✓ Saved to ROM
```

---

## 12. verify - Verify ROM

Comprehensive ROM integrity check.

```bash
# Basic verification
python dialog_cli.py verify

# Verbose output
python dialog_cli.py verify -v

# Show stats
python dialog_cli.py verify -s

# Force continue on errors
python dialog_cli.py verify -f
```

**Output:**
```
[1/5] File size check: ✓ 524,288 bytes
[2/5] ROM loading: ✓ Loaded
[3/5] Dialog extraction: ✓ 116 dialogs
[4/5] Dialog validation: ✓ All valid
[5/5] Round-trip test: ✓ 9 dialogs tested

VERIFICATION COMPLETE ✓
```

---

## 13. backup - Create Backup

Create ROM backup with optional timestamp.

```bash
# Simple backup
python dialog_cli.py backup

# With timestamp
python dialog_cli.py backup -t

# Custom filename
python dialog_cli.py backup -o my_backup.sfc

# Overwrite existing
python dialog_cli.py backup -f

# Verify integrity
python dialog_cli.py backup -v
```

**Output:**
```
✓ Backup created: ROM_NAME.20251111_135418.bak
  Size: 524,288 bytes
  ✓ Backup verified (identical to original)
```

---

## 14. validate - Validate Dialogs

Validate all dialogs for errors.

```bash
# Basic validation
python dialog_cli.py validate

# Full report
python dialog_cli.py validate -r

# Show issues
python dialog_cli.py validate -v
```

**Output:**
```
Validation complete:
  Errors: 0
  Warnings: 5
  Info: 12
```

---

## 15. import - Import Dialogs

Import edited dialogs from JSON.

```bash
# Import from JSON
python dialog_cli.py import edited.json

# Force update unchanged
python dialog_cli.py import edited.json --force

# Save to different ROM
python dialog_cli.py import edited.json -o patched.sfc
```

*(Note: Currently shows stub - full implementation pending)*

---

## Common Workflows

### Translation Project
```bash
# 1. Export original
python dialog_cli.py export original.json

# 2. Edit JSON (mark "modified": true)

# 3. Import translated
python dialog_cli.py import original.json --output translated.sfc

# 4. Verify result
python dialog_cli.py verify --rom translated.sfc
```

### ROM Hacking
```bash
# 1. Create backup
python dialog_cli.py backup -t -v

# 2. Edit dialog
python dialog_cli.py edit 0x21 --text "Hacked text"

# 3. Verify changes
python dialog_cli.py verify -s

# 4. Compare with original
python dialog_cli.py diff original.sfc modified.sfc
```

### Batch Editing
```bash
# 1. Find all occurrences
python dialog_cli.py find "old text"

# 2. Preview replacement
python dialog_cli.py replace "old text" "new text" --dry-run

# 3. Apply changes
python dialog_cli.py replace "old text" "new text" -v

# 4. Verify ROM
python dialog_cli.py verify
```

### Analysis
```bash
# Statistics
python dialog_cli.py stats -v

# Find text
python dialog_cli.py search "prophecy" -v

# Count metrics
python dialog_cli.py count

# Extract for study
python dialog_cli.py extract 0x59 -m
```

---

## Global Options

All commands support:

- `--rom PATH` - Specify ROM file path
- `--help` - Show command help

**Example:**
```bash
python dialog_cli.py --rom "custom/path/rom.sfc" list
```

---

## Error Handling

### Common Errors

**"ROM file not found"**
```bash
# Solution: Specify ROM path
python dialog_cli.py --rom "path/to/rom.sfc" list
```

**"Dialog exceeds maximum length"**
```bash
# Solution: Shorten text or use more DTE sequences
python dialog_cli.py edit 0x21 --text "Shorter text"
```

**"Unknown control code"**
```bash
# Solution: Use only codes in complex.tbl
python dialog_cli.py edit 0x21 --text "Use [PARA] not [INVALID]"
```

**"Backup already exists"**
```bash
# Solution: Use --force or different name
python dialog_cli.py backup -f
python dialog_cli.py backup -o different_name.bak
```

---

## Tips & Tricks

### 1. Quick Backup Before Editing
```bash
python dialog_cli.py backup -t && python dialog_cli.py edit 0x21
```

### 2. Find and Edit Workflow
```bash
# Find dialogs with text
python dialog_cli.py find "old text"

# Edit each one
python dialog_cli.py edit 0x21 --text "new text"
```

### 3. Batch Replace with Verification
```bash
python dialog_cli.py replace "old" "new" --dry-run
python dialog_cli.py replace "old" "new"
python dialog_cli.py verify -s
```

### 4. Export for External Editing
```bash
# Export all
python dialog_cli.py export all.json

# Extract specific for focus
python dialog_cli.py extract 0x59 -m -o edit_me.txt
```

### 5. Compare Before/After
```bash
# Before changes
python dialog_cli.py backup -o before.sfc

# Make changes
python dialog_cli.py edit 0x21 --text "Modified"

# Compare
python dialog_cli.py diff before.sfc current.sfc -v
```

### 6. Translation Workflow with Import
```bash
# Step 1: Export all dialogs to JSON
python dialog_cli.py export dialogs.json --format json

# Step 2: Edit dialogs.json in your text editor or translation tool
# Edit the "text" field for any dialogs you want to change
# Example JSON structure:
# {
#   "dialogs": [
#     {
#       "id": 33,  # 0x21 in decimal
#       "text": "Welcome to the Crystal shrine.",
#       "bytes": "0x54,0x...",
#       "length": 32,
#       ...
#     }
#   ]
# }

# Step 3: Import edited JSON back to ROM
python dialog_cli.py import dialogs.json --verbose

# Step 4: Verify changes
python dialog_cli.py verify --stats

# Step 5: Test in emulator!
```

**Import Command Details:**

```bash
# Import edited JSON
python dialog_cli.py import edited_dialogs.json

# Import with confirmation prompt (default)
python dialog_cli.py import edited_dialogs.json

# Import without confirmation (auto-yes)
python dialog_cli.py import edited_dialogs.json --yes

# Import and save to different ROM
python dialog_cli.py import edited_dialogs.json -o modified.smc

# Import with verbose output
python dialog_cli.py import edited_dialogs.json --verbose
```

**Import Features:**
- **JSON validation** - Checks structure before processing
- **Dialog validation** - Validates text encoding for each dialog
- **Change tracking** - Only updates dialogs that changed
- **Error handling** - Aggregates and reports all errors
- **Confirmation** - Asks before writing to ROM (unless --yes)
- **Progress tracking** - Shows import progress
- **Summary statistics** - Reports processed/updated/error counts

**Import Validation:**
1. File exists and is valid JSON
2. Has required 'dialogs' key with list value
3. Each dialog has 'id' and 'text' fields
4. Dialog ID exists in ROM (0x00-0x73)
5. Text passes encoding validation
6. Encoded bytes don't exceed 255 bytes
7. All control codes are valid

**Import Safety:**
- Creates backup before writing (if not using -o)
- Validates all dialogs before any writes
- Only writes if validation passes
- Provides detailed error messages
- Allows saving to different file with -o

**Example Import Output:**
```
Loading ROM: Final Fantasy - Mystic Quest (U) (V1.1).smc
Importing 116 dialogs from edited_dialogs.json...

======================================================================
Import Summary
======================================================================
Processed: 116 dialogs
Updated:   23 dialogs
Errors:    0

Save changes to ROM (23 dialogs modified)? [y/N] y
✓ ROM saved to Final Fantasy - Mystic Quest (U) (V1.1).smc
✓ Successfully imported 23 dialogs
```

---

## Performance Notes

- **Loading**: ~0.5 seconds for ROM + extraction
- **Export**: ~0.2 seconds for 116 dialogs
- **Search**: ~0.1 seconds across all dialogs
- **Edit**: ~0.3 seconds (validate + encode + write)
- **Verify**: ~1 second (full integrity check)

---

## See Also

- `DIALOG_CLI_GUIDE.md` - Comprehensive user guide
- `DIALOG_SYSTEM_FEATURES.md` - Technical specifications
- `SESSION_SUMMARY.md` - Development summary
- `complex.tbl` - Character encoding table

---

**Quick Help:**
```bash
python tools/map-editor/dialog_cli.py --help
python tools/map-editor/dialog_cli.py COMMAND --help
```
