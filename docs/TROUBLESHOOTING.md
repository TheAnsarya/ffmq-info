# FFMQ ROM Hacking - Troubleshooting Guide

Common problems and solutions for FFMQ ROM hacking tools.

---

## Table of Contents

1. [Installation Issues](#installation-issues)
2. [ROM Issues](#rom-issues)
3. [Text Editing Issues](#text-editing-issues)
4. [Dialog Issues](#dialog-issues)
5. [Build Issues](#build-issues)
6. [Emulator Issues](#emulator-issues)
7. [Python Issues](#python-issues)
8. [Git Issues](#git-issues)
9. [Performance Issues](#performance-issues)
10. [Error Messages](#error-messages)

---

## Installation Issues

### "Python not found" Error

**Symptoms:**
```
'python' is not recognized as an internal or external command
```

**Solutions:**

#### Windows
```powershell
# 1. Check if Python is installed
python --version

# 2. If not, download from python.org
# Make sure to check "Add Python to PATH" during installation

# 3. If already installed, add to PATH manually:
# System Properties → Environment Variables → Path → Edit
# Add: C:\Users\YourName\AppData\Local\Programs\Python\Python310\

# 4. Restart terminal and try again
```

#### Linux/Mac
```bash
# Try python3 instead
python3 --version

# If not installed:
# Ubuntu/Debian:
sudo apt install python3.10

# macOS:
brew install python@3.10
```

---

### "pip not found" Error

**Symptoms:**
```
'pip' is not recognized as an internal or external command
```

**Solutions:**
```bash
# Windows
python -m pip --version

# Linux/Mac
python3 -m pip --version

# If still not found, reinstall Python with pip included
```

---

### Setup Script Fails

**Symptoms:**
```
Error: Could not create virtual environment
Error: Could not install dependencies
```

**Solutions:**

#### Check Python Version
```bash
# Must be 3.8 or higher
python --version
```

#### Manual Setup
```bash
# 1. Create virtual environment
python -m venv venv

# 2. Activate
# Windows:
.\venv\Scripts\activate
# Linux/Mac:
source venv/bin/activate

# 3. Upgrade pip
python -m pip install --upgrade pip

# 4. Install dependencies
pip install -r requirements.txt

# 5. Verify
pip list
```

---

## ROM Issues

### ROM Not Found

**Symptoms:**
```
ROM Status: NOT FOUND
ERROR: Could not open ROM file
```

**Solutions:**

#### Check ROM Location
```bash
# ROM should be at: roms/FFMQ.sfc

# Windows:
Test-Path roms\FFMQ.sfc

# Linux/Mac:
ls -l roms/FFMQ.sfc
```

#### Check ROM Name
```bash
# Must be named exactly: FFMQ.sfc
# Not: ffmq.sfc, FFMQ.SMC, etc.

# Windows (rename):
Rename-Item roms\FFMQ.SMC roms\FFMQ.sfc

# Linux/Mac (rename):
mv roms/FFMQ.SMC roms/FFMQ.sfc
```

---

### Wrong ROM Size

**Symptoms:**
```
ROM size: 1048576 bytes (expected 2097152)
ERROR: Invalid ROM size
```

**Solutions:**

#### Verify ROM Size
```bash
# Should be exactly 2,097,152 bytes (2 MB)

# Windows:
(Get-Item roms\FFMQ.sfc).Length

# Linux/Mac:
ls -l roms/FFMQ.sfc
```

#### Common Causes
1. **SMC Header:** ROM has 512-byte header
   - Solution: Remove header using ROM tool
   - Or rename to .smc and tool will auto-detect

2. **Wrong ROM:** Not Final Fantasy Mystic Quest
   - Solution: Obtain correct ROM (USA version)

3. **Compressed ROM:** ROM is .zip or .7z
   - Solution: Extract ROM file first

---

### ROM Won't Boot After Editing

**Symptoms:**
- Emulator shows black screen
- Emulator crashes
- "Invalid ROM" error

**Solutions:**

#### Restore Backup
```bash
# List backups
# Windows:
Get-ChildItem roms\*backup*.sfc

# Linux/Mac:
ls -l roms/*backup*.sfc

# Restore
# Windows:
Copy-Item roms\FFMQ_backup_20241111_120000.sfc roms\FFMQ.sfc

# Linux/Mac:
cp roms/FFMQ_backup_20241111_120000.sfc roms/FFMQ.sfc
```

#### Verify ROM Checksum
```bash
# Check if ROM was corrupted during edit

# Windows (PowerShell):
Get-FileHash roms\FFMQ.sfc -Algorithm SHA256

# Linux/Mac:
sha256sum roms/FFMQ.sfc
```

#### Rebuild from Source
```bash
# Start fresh
ffmq clean
ffmq build
```

---

## Text Editing Issues

### "Text too long" Error

**Symptoms:**
```
ERROR: Dialog 5 text too long (450 bytes, max 384)
ERROR: Text overflow detected
```

**Solutions:**

#### Option 1: Shorten Text
```bash
# Original (45 bytes):
"You should go to the town and talk to the elder."

# Shortened (32 bytes):
"Go to town and see the elder."
```

#### Option 2: Use Pagination
```bash
# Split into multiple pages
"You should go to the town[PAGE]and talk to the elder."
```

#### Option 3: Optimize DTE
```bash
# Analyze current compression
ffmq analyze-dte

# Use DTE-friendly words
# "the" = 1 byte instead of 3
# "you" = 1 byte instead of 3
```

#### Option 4: Check Length
```bash
# Before editing, check max length
ffmq dialog-stats

# Dialog 5:
# Current: 120 bytes
# Max: 384 bytes
# Available: 264 bytes
```

---

### Invalid Control Code

**Symptoms:**
```
ERROR: Unknown control code [wait] at position 45
ERROR: Unclosed control code at position 23
```

**Solutions:**

#### Common Mistakes
```bash
# ❌ Wrong (lowercase)
"Hello[wait]"

# ✅ Correct (uppercase)
"Hello[WAIT]"

# ❌ Wrong (missing bracket)
"Hello[WAIT there"

# ✅ Correct (closed)
"Hello[WAIT] there"

# ❌ Wrong (typo)
"Hello[PAUSE]"

# ✅ Correct (correct name)
"Hello[WAIT]"
```

#### Auto-Fix
```bash
# Try auto-fix first
ffmq dialog-fix

# This fixes:
# - Double spaces
# - Trailing whitespace
# - Common typos
```

#### Manual Fix
```bash
# Edit dialog directly
ffmq edit 5

# Valid control codes:
# [PARA], [PAGE], [WAIT], [CLEAR]
# [NAME], [ITEM], [CRYSTAL], [NUMBER]
# See docs/DIALOG_COMMANDS.md for full list
```

---

### Text Doesn't Display Correctly

**Symptoms:**
- Garbage characters in ROM
- Text shows as boxes/symbols
- Control codes visible in game

**Solutions:**

#### Check Encoding
```bash
# JSON file must be UTF-8
# Check file encoding:

# Windows:
Get-Content data\text\text_data.json -Encoding utf8

# Linux/Mac:
file -i data/text/text_data.json
# Should show: charset=utf-8
```

#### Re-extract Text
```bash
# Extract fresh from ROM
ffmq extract-text

# Edit the new file
# Import back
ffmq import-text
```

#### Validate Before Import
```bash
# Check for errors first
ffmq dialog-validate

# Fix errors
ffmq dialog-fix

# Then import
ffmq import-text
```

---

## Dialog Issues

### Can't Edit Dialog

**Symptoms:**
```
ERROR: Could not open dialog 5
ERROR: Dialog database not found
```

**Solutions:**

#### Check ROM
```bash
# Make sure ROM is loaded
ffmq info

# Should show:
# ROM Status: FOUND
```

#### Verify Dialog ID
```bash
# List all dialogs
ffmq dialog-list

# Dialog IDs are 0-115
# Not 1-116!
```

#### Check File Paths
```bash
# Make sure you're in project root
pwd  # Should end in: ffmq-info

# Check if tools exist
ls tools/map-editor/dialog_cli.py
```

---

### Dialog Changes Don't Appear in ROM

**Symptoms:**
- Edited dialog, but ROM shows old text
- Changes in JSON but not in game

**Solutions:**

#### Import Changes
```bash
# After editing, you must import:
ffmq import-text

# Or for dialogs specifically:
cd tools/map-editor
python dialog_cli.py import ../../data/text/dialogs.json
```

#### Rebuild ROM
```bash
# If using source editing:
ffmq build

# Test
ffmq test
```

#### Check Modification Date
```bash
# Verify file was actually saved

# Windows:
(Get-Item data\text\text_data.json).LastWriteTime

# Linux/Mac:
ls -l data/text/text_data.json
```

---

## Build Issues

### Build Fails

**Symptoms:**
```
ERROR: Build failed
ERROR: Assembler returned error code 1
```

**Solutions:**

#### Check Build Log
```bash
# Windows:
Get-Content build\ffmq.log -Tail 50

# Linux/Mac:
tail -50 build/ffmq.log

# Look for actual error message
```

#### Clean and Rebuild
```bash
# Remove old build files
ffmq clean

# Rebuild
ffmq build
```

#### Check Assembler
```bash
# Make sure ca65/asar is installed

# Windows:
where ca65
where asar

# Linux/Mac:
which ca65
which asar

# If not found, install from:
# ca65: https://cc65.github.io/
# asar: https://github.com/RPGHacker/asar/
```

---

### Modified ROM Too Large

**Symptoms:**
```
ERROR: ROM size 2,500,000 bytes exceeds maximum 2,097,152
```

**Solutions:**

#### Check Text Length
```bash
# Text might be too long
ffmq check-overflow

# Fix overflows
ffmq dialog-fix
```

#### Optimize Assets
```bash
# Compress graphics
# Optimize dialog compression
ffmq analyze-dte

# Remove unused data
```

---

## Emulator Issues

### Emulator Not Found

**Symptoms:**
```
ERROR: Could not launch emulator
'mesen' is not recognized
```

**Solutions:**

#### Install Emulator
```bash
# Windows: Download from GitHub
# https://github.com/SourMesen/Mesen-S/releases

# macOS:
brew install --cask mesen-s

# Linux:
# Download AppImage from releases
```

#### Add to PATH
```bash
# Windows:
# System Properties → Environment Variables → Path
# Add emulator directory

# Linux/Mac:
export PATH="$HOME/mesen-s:$PATH"
```

#### Manual Launch
```bash
# Windows:
Start-Process "C:\Program Files\Mesen-S\Mesen.exe" -ArgumentList "build\ffmq-rebuilt.sfc"

# Linux/Mac:
mesen build/ffmq-rebuilt.sfc
```

---

### ROM Won't Load in Emulator

**Symptoms:**
- Black screen
- Error message
- Crash

**Solutions:**

#### Try Different Emulator
```bash
# Recommended: MesenS
# Alternative: Snes9x
# Alternative: bsnes
```

#### Check ROM Validity
```bash
# Verify size
# Windows:
(Get-Item build\ffmq-rebuilt.sfc).Length

# Should be 2,097,152 bytes
```

#### Reset Emulator Config
```bash
# Delete emulator config folder
# Windows: %APPDATA%\Mesen-S
# Linux: ~/.config/Mesen-S
# macOS: ~/Library/Application Support/Mesen-S
```

---

## Python Issues

### Module Not Found

**Symptoms:**
```
ModuleNotFoundError: No module named 'PIL'
ModuleNotFoundError: No module named 'tkinter'
```

**Solutions:**

#### Activate Virtual Environment
```bash
# Windows:
.\venv\Scripts\activate

# Linux/Mac:
source venv/bin/activate

# Your prompt should show: (venv)
```

#### Reinstall Dependencies
```bash
pip install -r requirements.txt
```

#### Install Missing Module
```bash
# For PIL (Pillow):
pip install Pillow

# For tkinter (Ubuntu/Debian):
sudo apt install python3-tk

# For tkinter (Fedora):
sudo dnf install python3-tkinter
```

---

### Python Version Mismatch

**Symptoms:**
```
ERROR: Python 3.7 detected, 3.8+ required
SyntaxError: invalid syntax (match/case statement)
```

**Solutions:**

#### Upgrade Python
```bash
# Windows: Download from python.org

# macOS:
brew upgrade python@3.10

# Ubuntu/Debian:
sudo apt install python3.10
```

#### Use Specific Version
```bash
# Create venv with specific Python
python3.10 -m venv venv

# Activate and install
source venv/bin/activate  # or .\venv\Scripts\activate
pip install -r requirements.txt
```

---

## Git Issues

### Can't Push Changes

**Symptoms:**
```
ERROR: Permission denied (publickey)
ERROR: Could not push to remote
```

**Solutions:**

#### Check Remote URL
```bash
git remote -v

# If showing HTTPS:
git remote set-url origin git@github.com:yourusername/ffmq-info.git

# Or if showing SSH but you want HTTPS:
git remote set-url origin https://github.com/yourusername/ffmq-info.git
```

#### Setup SSH Key
```bash
# Generate key
ssh-keygen -t ed25519 -C "your_email@example.com"

# Add to GitHub:
# Settings → SSH and GPG keys → New SSH key
# Paste contents of: ~/.ssh/id_ed25519.pub
```

---

### Merge Conflicts

**Symptoms:**
```
CONFLICT (content): Merge conflict in data/text/text_data.json
```

**Solutions:**

#### Option 1: Keep Your Changes
```bash
git checkout --ours data/text/text_data.json
git add data/text/text_data.json
git commit
```

#### Option 2: Keep Remote Changes
```bash
git checkout --theirs data/text/text_data.json
git add data/text/text_data.json
git commit
```

#### Option 3: Manual Merge
```bash
# Open file in editor
# Look for conflict markers:
# <<<<<<< HEAD
# your changes
# =======
# remote changes
# >>>>>>> branch

# Edit to keep desired changes
# Remove conflict markers
# Save file

git add data/text/text_data.json
git commit
```

---

## Performance Issues

### Slow Text Extraction

**Symptoms:**
- Extract takes > 1 minute
- High CPU usage
- Script hangs

**Solutions:**

#### Check ROM Size
```bash
# Should be 2 MB
# If much larger, wrong file
(Get-Item roms\FFMQ.sfc).Length
```

#### Close Other Programs
```bash
# Free up RAM
# Close unnecessary applications
```

#### Use Smaller Batch Size
```python
# Edit extract_all_text.py
# Reduce batch processing
```

---

### Slow Import

**Symptoms:**
- Import takes > 5 minutes
- Script appears frozen

**Solutions:**

#### Check File Size
```bash
# text_data.json should be < 500 KB
ls -lh data/text/text_data.json
```

#### Validate JSON First
```bash
# Make sure JSON is valid
python -m json.tool data/text/text_data.json > /dev/null

# Fix any JSON errors before import
```

---

## Error Messages

### "ValueError: Invalid DTE sequence"

**Cause:** Malformed DTE compression data

**Solution:**
```bash
# Re-extract from clean ROM
ffmq extract-text

# Don't manually edit DTE data
# Edit only the text field in JSON
```

---

### "IndexError: list index out of range"

**Cause:** Invalid dialog ID or array access

**Solution:**
```bash
# Check dialog ID
# IDs are 0-115, not 1-116

# Example:
ffmq edit 115  # ✅ Valid (last dialog)
ffmq edit 116  # ❌ Invalid (out of range)
```

---

### "FileNotFoundError: [Errno 2] No such file or directory"

**Cause:** Working directory wrong or file path incorrect

**Solution:**
```bash
# Make sure you're in project root
cd c:\Users\me\source\repos\ffmq-info

# Verify file exists
Test-Path roms\FFMQ.sfc

# Use absolute paths if needed
```

---

### "UnicodeDecodeError: 'utf-8' codec can't decode"

**Cause:** File encoding is not UTF-8

**Solution:**
```bash
# Convert file to UTF-8
# In editor: File → Save with Encoding → UTF-8

# Or use tool:
# Windows (PowerShell):
Get-Content file.txt | Set-Content -Encoding utf8 file_utf8.txt

# Linux/Mac:
iconv -f ISO-8859-1 -t UTF-8 file.txt > file_utf8.txt
```

---

## Getting More Help

### Check Documentation
1. [Quick Reference](../tools/map-editor/QUICK_REFERENCE.md)
2. [Workflow Guide](WORKFLOW_GUIDE.md)
3. [Dialog Commands](DIALOG_COMMANDS.md)
4. [Installation Guide](INSTALLATION.md)

### Search Issues
- GitHub Issues: https://github.com/yourusername/ffmq-info/issues
- Search for your error message
- Check closed issues too

### Ask for Help
1. **GitHub Discussions:**
   - Ask questions
   - Share solutions
   - Get community help

2. **Create Issue:**
   - Report bugs
   - Request features
   - Document problems

3. **Include Details:**
   - Full error message
   - Steps to reproduce
   - OS and Python version
   - What you've tried

### Diagnostic Info Template
```
**Problem:** [Brief description]

**Error Message:**
```
[Full error message here]
```

**Environment:**
- OS: [Windows 11 / macOS 14 / Ubuntu 22.04]
- Python: [version]
- ROM: [FFMQ.sfc, 2097152 bytes]

**Steps to Reproduce:**
1. [First step]
2. [Second step]
3. [Error occurs]

**What I've Tried:**
- [Solution 1]
- [Solution 2]
```

---

**Last Updated:** 2024-11-11  
**Version:** 2.0  
**Coverage:** All known issues documented
