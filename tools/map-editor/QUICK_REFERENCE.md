# Dialog Editing Quick Reference

## 🚀 Quick Start (5 Minutes)

```bash
# 1. View a dialog
cd tools/map-editor
python dialog_cli.py show 0

# 2. Search for text
python dialog_cli.py search "Crystal"

# 3. Edit a dialog
python dialog_cli.py edit 5

# 4. Save and test!
```

## 📝 Most Common Commands

### View & Search
```bash
python dialog_cli.py list                    # List all 116 dialogs
python dialog_cli.py show 5                  # Show dialog #5
python dialog_cli.py show 5 --raw            # Show raw bytes
python dialog_cli.py search "Crystal"        # Find text
python dialog_cli.py search "Crystal" -i     # Case-insensitive
```

### Edit & Modify
```bash
python dialog_cli.py edit 5                  # Interactive edit
python dialog_cli.py replace "old" "new"     # Batch replace
python dialog_cli.py replace "old" "new" --preview  # Preview first
python dialog_cli.py validate                # Check for errors
python dialog_cli.py validate --fix          # Auto-fix problems
```

### Export & Import
```bash
python dialog_cli.py export dialogs.json     # Export all
python dialog_cli.py export out.json -i 5 10 15  # Export specific IDs
python dialog_cli.py import dialogs.json     # Import changes
python dialog_cli.py import dialogs.json -y  # No confirmation
```

### Backup & Restore
```bash
python dialog_cli.py backup                  # Create backup
python dialog_cli.py backup --name "v1.0"    # Named backup
python dialog_cli.py restore backup_*.sfc    # Restore from backup
```

## 🎨 Control Codes Reference

### Text Layout
```
[PARA]       New paragraph (line break within page)
[PAGE]       New page (new dialog box)
{newline}    Simple line break
```

### Text Flow
```
[WAIT]       Wait for button press
[CLEAR]      Clear dialog box
[END]        End of string (required!)
```

### Dynamic Content
```
[NAME]       Insert player name
[ITEM]       Insert item name
[CRYSTAL]    Crystal-related text
```

### Spacing
```
_            Space (use in control code context)
```

## ✍️ Writing Dialog Text

### Good Example
```
[NAME], you must find the[PARA]Crystal of Fire to save[PARA]the world![WAIT][CLEAR]Use the [ITEM] wisely.[END]
```

**Breakdown:**
- `[NAME]` - Inserts player's name
- `[PARA]` - Line breaks within same dialog box
- `[WAIT]` - Player presses button to continue
- `[CLEAR]` - Clears box before next text
- `[ITEM]` - Inserts contextual item name
- `[END]` - Required terminator

### Dialog Box Layout
```
┌────────────────────────────────┐
│[NAME], you must find the       │  Line 1 (32 chars max)
│Crystal of Fire to save         │  Line 2
│the world!                      │  Line 3
└────────────────────────────────┘
         [Press button]            [WAIT]
         [Clear box]               [CLEAR]
┌────────────────────────────────┐
│Use the [ITEM] wisely.          │  New page starts
│                                │
│                                │
└────────────────────────────────┘
```

### Character Width Guide
**Narrow (0.5 width):** `.` `,` `!` `i` `l`
**Normal (1.0 width):** Most letters/numbers
**Wide (1.5 width):** `W` `M` `m` `@`

**Line limit:** ~32 characters (proportional font)
**Lines per page:** 3
**Max pages:** 4

## 🔧 Common Editing Tasks

### Task 1: Change Character Name Reference
```bash
# Before
python dialog_cli.py show 10
# Output: "Benjamin, you must go!"

# Edit
python dialog_cli.py edit 10
# Change to: "[NAME], you must go!"

# After
python dialog_cli.py show 10
# Output: "[NAME], you must go!"
```

### Task 2: Add Line Breaks
```bash
# Before: Long run-on text
"The Crystal of Fire is hidden deep in the volcano."

# Edit with [PARA]
"The Crystal of Fire is[PARA]hidden deep in the volcano."

# Result: Splits across 2 lines properly
```

### Task 3: Batch Replace
```bash
# Replace all instances of "thee" with "you"
python dialog_cli.py replace "thee" "you"

# Preview changes first
python dialog_cli.py replace "thee" "you" --preview

# Replace only in specific dialogs
python dialog_cli.py replace "thee" "you" -i 10 11 12
```

### Task 4: Fix Spacing Issues
```bash
# Auto-fix double spaces, trim whitespace
python dialog_cli.py validate --fix

# Check specific dialog
python dialog_cli.py show 15 --verbose
```

### Task 5: Translation Workflow
```bash
# 1. Export all dialogs
python dialog_cli.py export translation.json

# 2. Edit JSON file (use text editor)
# Change "text" fields to translated text

# 3. Import back
python dialog_cli.py import translation.json

# 4. Validate
python dialog_cli.py validate

# 5. Test in emulator!
```

## 📊 Statistics & Analysis

```bash
# Show overall stats
python dialog_cli.py stats

# Compare two ROMs
python dialog_cli.py compare rom1.sfc rom2.sfc

# Check specific dialog details
python dialog_cli.py show 5 --verbose
```

## ⚠️ Common Mistakes

### ❌ Mistake 1: Missing [END]
```
"Hello, world!"          # WRONG - missing [END]
"Hello, world![END]"     # CORRECT
```

### ❌ Mistake 2: Text Too Long
```
"This is a very long line that exceeds 32 characters and will overflow!"  # WRONG
"This is a very long[PARA]line that will fit properly![END]"  # CORRECT
```

### ❌ Mistake 3: Wrong Control Code Format
```
"New page [page]"        # WRONG - lowercase
"New page [PAGE]"        # CORRECT - uppercase
```

### ❌ Mistake 4: Double Spaces
```
"Hello,  world!"         # WRONG - double space
"Hello, world!"          # CORRECT
```

**Fix automatically:** `python dialog_cli.py validate --fix`

### ❌ Mistake 5: Unmatched Brackets
```
"Use [ITEM wisely"       # WRONG - no closing bracket
"Use [ITEM] wisely"      # CORRECT
```

## 🧪 Testing Your Changes

### Method 1: In-Tool Preview
```bash
python dialog_cli.py show 5              # View your changes
python dialog_cli.py show 5 --verbose    # See byte count
```

### Method 2: Overflow Detection
```bash
cd tools/map-editor
python text_overflow_detector.py         # Check all dialogs
```

### Method 3: Emulator Testing
```bash
# 1. Make sure ROM is modified
python dialog_cli.py show 5

# 2. Load in emulator
mesen roms/FFMQ.sfc

# 3. Trigger the dialog in-game
# 4. Verify it displays correctly
```

## 📈 Optimization Tips

### Tip 1: Use DTE Compression
FFMQ automatically compresses common phrases:
- `the` → 1 byte (instead of 3)
- `you` → 1 byte (instead of 3)
- `ing` → 1 byte (instead of 3)

**You don't need to do anything - it happens automatically!**

### Tip 2: Reuse Common Phrases
```bash
# Search for similar text
python dialog_cli.py search "Crystal of"

# Consider reusing exact phrasing for better compression
```

### Tip 3: Check Compression Stats
```bash
python dialog_cli.py stats

# Shows:
# - Average compression ratio (should be ~58%)
# - Bytes saved
# - Character counts
```

### Tip 4: Optimize Line Breaks
```bash
# Poor breaks (wastes space)
"The Crystal of[PARA]Fire is needed[PARA]now!"

# Better breaks (fills lines)
"The Crystal of Fire[PARA]is needed now!"
```

## 🆘 Troubleshooting

### Problem: "Text too long" error
**Solution:** Add [PARA] or [PAGE] breaks
```bash
python text_overflow_detector.py    # Find problem dialogs
```

### Problem: "Encoding failed" error
**Solution:** Check for invalid characters
```bash
python dialog_cli.py show 5 --verbose    # See raw bytes
python dialog_cli.py validate            # Check all dialogs
```

### Problem: Changes not appearing in game
**Solution:** Verify edit saved
```bash
python dialog_cli.py show 5              # Check dialog content
# Make sure you're testing the correct ROM file!
```

### Problem: Backup not working
**Solution:** Check ROM file path
```bash
python dialog_cli.py backup --verbose    # See detailed output
```

### Problem: Import fails
**Solution:** Validate JSON structure
```bash
# Check JSON syntax
python -m json.tool dialogs.json > /dev/null

# Try importing with verbose output
python dialog_cli.py import dialogs.json --verbose
```

## 📚 Advanced Techniques

### Batch Processing
```python
# Create batch command file
# commands.txt:
edit 5
replace "old" "new"
validate --fix
export backup.json

# Run batch
python dialog_cli.py batch commands.txt
```

### Scripting with Python
```python
from utils.dialog_database import DialogDatabase
from pathlib import Path

# Load ROM
rom_path = Path("roms/FFMQ.sfc")
db = DialogDatabase(rom_path)

# Get dialog
entry = db.get_dialog(5)
print(f"Dialog 5: {entry.text}")

# Modify
new_text = entry.text.replace("old", "new")
db.update_dialog(5, new_text)
print("Dialog updated!")
```

### Regular Expression Replace
```bash
# Replace multiple variations
python dialog_cli.py replace "thee|thou" "you" --regex

# Note: --regex flag may need to be implemented
```

## 🎯 Best Practices

1. **Always backup before editing**
   ```bash
   python dialog_cli.py backup
   ```

2. **Validate after changes**
   ```bash
   python dialog_cli.py validate --fix
   ```

3. **Test in emulator**
   - Don't trust the preview alone!
   - Play through the actual dialog in-game

4. **Use version control**
   ```bash
   git add data/dialogs/
   git commit -m "Updated dialog 5"
   ```

5. **Document your changes**
   - Keep notes on what you changed
   - Export JSON as backup: `dialog_cli.py export backup_$(date +%Y%m%d).json`

6. **Use consistent style**
   - Decide on naming conventions (e.g., always use [NAME] vs character name)
   - Be consistent with punctuation and spacing

## 📖 See Also

- [Dialog Commands Reference](../../docs/DIALOG_COMMANDS.md) - Complete control code catalog
- [Command Reference](COMMAND_REFERENCE.md) - All 15 CLI commands
- [Dialog System README](README.md) - Technical implementation guide
- [Session Summary](../../FINAL_SESSION_SUMMARY.md) - Development history

## 🔗 Quick Links

- **GitHub:** https://github.com/TheAnsarya/ffmq-info
- **Issues:** https://github.com/TheAnsarya/ffmq-info/issues
- **DataCrystal Wiki:** https://datacrystal.tcrf.net/wiki/Final_Fantasy:_Mystic_Quest

---

**Need help?** Open an issue on GitHub or check the comprehensive README!
