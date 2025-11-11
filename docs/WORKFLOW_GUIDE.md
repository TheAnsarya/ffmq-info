# FFMQ ROM Hacking Workflow Guide

Complete workflow documentation for common ROM hacking scenarios.

---

## Quick Start Workflows

### 1. First Time Setup (5 minutes)

```bash
# Windows
.\setup.ps1

# Linux/Mac
./setup.sh

# Verify setup
.\ffmq-tasks.ps1 -Task info
```

**What it does:**
- Checks Python version (3.8+)
- Creates virtual environment
- Installs dependencies
- Verifies ROM location
- Shows project statistics

---

### 2. Extract All Text (2 minutes)

```bash
# Extract everything
.\ffmq-tasks.ps1 -Task extract-text

# Output locations:
# - data/text/text_data.json       (main text data)
# - data/text/text_data.csv        (spreadsheet format)
# - data/text/text_readable.txt    (human-readable)
# - data/text/text_statistics.txt  (compression stats)
```

**What gets extracted:**
- 116 dialogs with proper DTE decoding
- 256 item names
- 64 weapon names
- 64 armor names
- 64 accessory names
- 64 spell names
- 256 monster names
- 150+ location names

**Formats:**
- **JSON**: For editing and re-import
- **CSV**: For spreadsheet editors (Excel, Google Sheets)
- **TXT**: For reading and searching
- **Statistics**: Compression analysis

---

### 3. Edit Dialog Text (Quick Method)

```bash
# List all dialogs
.\ffmq-tasks.ps1 -Task dialog-list

# Edit specific dialog
.\ffmq-tasks.ps1 -Task edit -Arg 5

# Validate changes
.\ffmq-tasks.ps1 -Task dialog-validate

# Auto-fix issues
.\ffmq-tasks.ps1 -Task dialog-fix
```

**In the editor:**
```
Old man: "Welcome, young [NAME]![WAIT]
The [CRYSTAL] of earth needs you![PAGE]
Take this [ITEM]![CLEAR]"
```

**Common edits:**
- Change dialog text (stay within length limits)
- Add/remove control codes ([WAIT], [PAGE], [CLEAR])
- Reference player name with [NAME]
- Reference items/crystals with [ITEM], [CRYSTAL]
- Break lines with [PARA]
- Clear screen with [PAGE] or [CLEAR]

---

### 4. Edit Text in Spreadsheet (Professional Method)

```bash
# Extract to CSV
.\ffmq-tasks.ps1 -Task extract-text

# Open in Excel/Sheets
# Edit: data/text/text_data.csv

# Important: Save as CSV (UTF-8)
# Keep control codes: [WAIT], [PAGE], [NAME], etc.

# Import changes
.\ffmq-tasks.ps1 -Task import-text

# Test in emulator
.\ffmq-tasks.ps1 -Task test
```

**CSV columns:**
- **Type**: dialog, item, weapon, armor, etc.
- **ID**: Numeric identifier
- **Text**: The actual text with control codes
- **Length**: Current length in bytes
- **Max**: Maximum allowed bytes

**Editing tips:**
- Excel: File → Save As → CSV UTF-8
- Google Sheets: File → Download → CSV
- Keep control codes intact: `[WAIT]`, `[PAGE]`, etc.
- Watch length limits (shown in Max column)
- Don't modify ID or Type columns

---

### 5. Check for Problems (Safety Check)

```bash
# Validate all dialogs
.\ffmq-tasks.ps1 -Task dialog-validate

# Check for overflow
.\ffmq-tasks.ps1 -Task check-overflow

# Analyze compression
.\ffmq-tasks.ps1 -Task analyze-dte

# Show statistics
.\ffmq-tasks.ps1 -Task text-stats
```

**What to look for:**
- ❌ **Length overflow**: Text too long for space
- ❌ **Invalid codes**: Malformed control codes
- ❌ **Encoding errors**: Invalid characters
- ✅ **Good compression**: High DTE usage
- ✅ **Valid structure**: All codes properly closed

---

### 6. Build and Test ROM

```bash
# Create backup first!
.\ffmq-tasks.ps1 -Task backup

# Build ROM
.\ffmq-tasks.ps1 -Task build

# Test in emulator
.\ffmq-tasks.ps1 -Task test

# If problems, restore backup
.\ffmq-tasks.ps1 -Task restore
```

**Build outputs:**
- `build/ffmq-rebuilt.sfc` - Modified ROM
- `build/ffmq.log` - Build log
- `build/ffmq.sym` - Symbol file

**Testing checklist:**
- ✅ ROM boots correctly
- ✅ Dialogs display properly
- ✅ Text doesn't overflow boxes
- ✅ Control codes work ([WAIT], [PAGE], etc.)
- ✅ Names and items display correctly
- ✅ No graphical glitches

---

## Advanced Workflows

### Translation Project

**Setup phase:**
```bash
# 1. Extract everything
.\ffmq-tasks.ps1 -Task extract-text

# 2. Copy to translation working directory
Copy-Item data/text/text_data.csv translation/ffmq_en.csv

# 3. Export dialogs for reference
.\ffmq-tasks.ps1 -Task dialog-export
```

**Translation phase:**
```bash
# Edit in spreadsheet editor
# - Keep control codes intact
# - Watch character limits
# - Test frequently

# Import and test
.\ffmq-tasks.ps1 -Task import-text
.\ffmq-tasks.ps1 -Task test
```

**Quality assurance:**
```bash
# Validate everything
.\ffmq-tasks.ps1 -Task dialog-validate

# Check overflow
.\ffmq-tasks.ps1 -Task check-overflow

# Optimize compression
.\ffmq-tasks.ps1 -Task analyze-dte
```

---

### Dialog Writing

**Writing workflow:**
```bash
# 1. Find dialog to edit
.\ffmq-tasks.ps1 -Task search -Arg "old man"

# 2. Edit dialog
.\ffmq-tasks.ps1 -Task edit -Arg 23

# 3. Validate
.\ffmq-tasks.ps1 -Task dialog-validate

# 4. Test immediately
.\ffmq-tasks.ps1 -Task build
.\ffmq-tasks.ps1 -Task test
```

**Dialog box constraints:**
- **Width**: 32 characters (proportional font)
- **Height**: 3 lines per page
- **Pages**: Maximum 4 pages per dialog
- **Total**: ~384 characters max (with pagination)

**Control code strategy:**
```
Page 1 (intro):
"Old man: Welcome, young [NAME]![WAIT]

Page 2 (explanation):
The [CRYSTAL] of earth is dying.[PARA]
We need a hero to save us![PAGE]

Page 3 (action):
Take this [ITEM] and go north.[PARA]
May the crystals guide you![CLEAR]"
```

---

### Compression Optimization

**When text is too long:**
```bash
# 1. Analyze current compression
.\ffmq-tasks.ps1 -Task analyze-dte

# 2. Find common phrases
python tools/map-editor/compression_optimizer.py --suggestions

# 3. Manually optimize text
# - Use shorter words
# - Leverage DTE sequences
# - Remove unnecessary words

# 4. Verify improvement
.\ffmq-tasks.ps1 -Task text-stats
```

**DTE optimization tips:**
- Common 2-char sequences auto-compress
- "th", "er", "on", "an", "in" = free compression
- " the " = 1 byte instead of 5
- "you" = 1 byte instead of 3
- Check `docs/DIALOG_COMMANDS.md` for full list

**Manual optimization example:**
```
Before (45 bytes):
"You should go to the town and talk to the elder."

After (32 bytes):
"Go to town and see the elder."

Saved: 13 bytes (28.9% reduction)
```

---

### Batch Operations

**Update all item names:**
```python
# Edit data/text/text_data.json
import json

with open('data/text/text_data.json', 'r') as f:
	data = json.load(f)

# Update all items
for item in data['items']:
	if item['name'] == 'Cure':
		item['name'] = 'Potion'

with open('data/text/text_data.json', 'w') as f:
	json.dump(data, f, indent=2)
```

```bash
# Import changes
.\ffmq-tasks.ps1 -Task import-text
```

**Search and replace:**
```bash
# Find all uses of "crystal"
.\ffmq-tasks.ps1 -Task search -Arg "crystal"

# Edit each dialog
# (Manual editing recommended for context)
```

---

## Safety and Backup Workflows

### Regular Backups

```bash
# Before major changes
.\ffmq-tasks.ps1 -Task backup

# Backups saved to: roms/FFMQ_backup_YYYYMMDD_HHMMSS.sfc
```

**Backup strategy:**
- Before bulk text import
- Before major dialog changes
- Before build/test cycles
- After successful milestones

### Restore from Backup

```bash
# List available backups
.\ffmq-tasks.ps1 -Task restore

# Manually copy back
Copy-Item roms/FFMQ_backup_20241111_143022.sfc roms/FFMQ.sfc

# Or restore via CLI
cd tools/map-editor
python dialog_cli.py restore ../../roms/FFMQ_backup_20241111_143022.sfc
```

---

## Git Integration Workflows

### Commit Text Changes

```bash
# Check what changed
git status

# Review changes
git diff data/text/text_data.json

# Commit with descriptive message
git add data/text/
git commit -m "dialog: Updated old man dialog for clarity"

# Push to remote
git push
```

**Commit message conventions:**
```
dialog: <description>     # Dialog-specific changes
text: <description>       # General text changes
extract: <description>    # Extraction improvements
import: <description>     # Import functionality
docs: <description>       # Documentation
fix: <description>        # Bug fixes
feat: <description>       # New features
```

### Collaborative Translation

```bash
# Pull latest changes
git pull

# Extract text
.\ffmq-tasks.ps1 -Task extract-text

# Create feature branch
git checkout -b translation/japanese

# Edit text
# ... make changes ...

# Commit and push
git add data/text/
git commit -m "translation: Japanese dialog for chapter 1"
git push origin translation/japanese

# Create pull request on GitHub
```

---

## Troubleshooting Workflows

### "Text too long" Error

```bash
# 1. Find the problem
.\ffmq-tasks.ps1 -Task check-overflow

# 2. View statistics
.\ffmq-tasks.ps1 -Task text-stats

# 3. Options:
#    A) Shorten text manually
#    B) Optimize DTE compression
#    C) Split into multiple pages

# 4. Validate fix
.\ffmq-tasks.ps1 -Task dialog-validate
```

### Invalid Control Code

```bash
# 1. Find errors
.\ffmq-tasks.ps1 -Task dialog-validate

# 2. Common mistakes:
#    - [WAIT] not [wait]      (case sensitive)
#    - [ITEM] not [item]
#    - [PARA not [PARA]       (missing closing bracket)

# 3. Auto-fix simple issues
.\ffmq-tasks.ps1 -Task dialog-fix

# 4. Manual fixes for complex issues
.\ffmq-tasks.ps1 -Task edit -Arg <dialog_id>
```

### Import Fails

```bash
# 1. Check file format
head data/text/text_data.json

# 2. Validate JSON
python -m json.tool data/text/text_data.json > /dev/null

# 3. Check file encoding (must be UTF-8)
file data/text/text_data.json

# 4. Verify ROM path
.\ffmq-tasks.ps1 -Task info

# 5. Try verbose import
cd tools/import
python import_all_text.py ../../data/text/text_data.json ../../roms/FFMQ_modified.sfc -v
```

### ROM Won't Boot

```bash
# 1. Restore last backup
.\ffmq-tasks.ps1 -Task restore

# 2. Check build log
Get-Content build/ffmq.log -Tail 50

# 3. Verify ROM size (should be 2MB)
(Get-Item roms/FFMQ.sfc).Length

# 4. Rebuild from clean state
.\ffmq-tasks.ps1 -Task clean
.\ffmq-tasks.ps1 -Task build
```

---

## Performance Workflows

### Fast Edit Cycle

For rapid iteration:
```bash
# 1. Keep emulator open
.\ffmq-tasks.ps1 -Task test

# 2. In another terminal:
.\ffmq-tasks.ps1 -Task edit -Arg 5
# Make changes, save

# 3. Quick rebuild
.\ffmq-tasks.ps1 -Task build

# 4. Reload ROM in emulator
# (Most emulators: File → Reload)
```

### Batch Validation

Check everything at once:
```bash
# Create validation script
.\ffmq-tasks.ps1 -Task dialog-validate
.\ffmq-tasks.ps1 -Task check-overflow
.\ffmq-tasks.ps1 -Task analyze-dte
.\ffmq-tasks.ps1 -Task text-stats
```

---

## Reference

### File Locations

```
Project Root/
├── roms/
│   ├── FFMQ.sfc                          # Original ROM
│   ├── FFMQ_modified.sfc                 # Modified ROM
│   └── FFMQ_backup_*.sfc                 # Backups
├── data/
│   └── text/
│       ├── text_data.json                # Main text data
│       ├── text_data.csv                 # Spreadsheet format
│       ├── text_readable.txt             # Human-readable
│       └── text_statistics.txt           # Stats
├── tools/
│   ├── extraction/
│   │   └── extract_all_text.py           # Extraction tool
│   ├── import/
│   │   └── import_all_text.py            # Import tool
│   └── map-editor/
│       ├── dialog_cli.py                 # Dialog CLI
│       ├── compression_optimizer.py      # DTE optimizer
│       └── text_overflow_detector.py     # Overflow checker
└── docs/
    ├── DIALOG_COMMANDS.md                # Control code reference
    ├── QUICK_REFERENCE.md                # Quick start guide
    └── WORKFLOW_GUIDE.md                 # This file
```

### Task Quick Reference

| Task | Command | Description |
|------|---------|-------------|
| Help | `.\ffmq-tasks.ps1 -Task help` | Show all tasks |
| Info | `.\ffmq-tasks.ps1 -Task info` | Show project info |
| Extract | `.\ffmq-tasks.ps1 -Task extract-text` | Extract all text |
| Import | `.\ffmq-tasks.ps1 -Task import-text` | Import text changes |
| List | `.\ffmq-tasks.ps1 -Task dialog-list` | List all dialogs |
| Edit | `.\ffmq-tasks.ps1 -Task edit -Arg 5` | Edit dialog #5 |
| Validate | `.\ffmq-tasks.ps1 -Task dialog-validate` | Check for errors |
| Fix | `.\ffmq-tasks.ps1 -Task dialog-fix` | Auto-fix errors |
| Backup | `.\ffmq-tasks.ps1 -Task backup` | Create backup |
| Build | `.\ffmq-tasks.ps1 -Task build` | Build ROM |
| Test | `.\ffmq-tasks.ps1 -Task test` | Launch emulator |

---

## Next Steps

1. **New users**: Start with [Quick Start Workflows](#quick-start-workflows)
2. **Translation**: See [Translation Project](#translation-project)
3. **Dialog writing**: See [Dialog Writing](#dialog-writing)
4. **Reference**: Read `docs/DIALOG_COMMANDS.md`
5. **Help**: Check `docs/QUICK_REFERENCE.md`

---

**Last Updated**: 2024-11-11  
**Version**: 2.0  
**Status**: Production Ready
