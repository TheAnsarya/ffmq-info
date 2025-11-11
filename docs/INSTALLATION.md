# FFMQ ROM Hacking - Installation & Setup Guide

Complete installation guide for all platforms.

---

## System Requirements

### Minimum Requirements
- **OS:** Windows 10+, macOS 10.14+, or Linux (Ubuntu 20.04+)
- **Python:** 3.8 or higher
- **RAM:** 2 GB minimum, 4 GB recommended
- **Storage:** 500 MB free space
- **ROM:** Final Fantasy Mystic Quest (USA) ROM file

### Recommended
- **Python:** 3.10+ for best performance
- **Emulator:** MesenS (SNES emulator with debugging)
- **Editor:** VS Code or any text editor with JSON support
- **Git:** For version control (optional but recommended)

---

## Quick Installation

### Windows (PowerShell)

```powershell
# 1. Clone repository
git clone https://github.com/yourusername/ffmq-info.git
cd ffmq-info

# 2. Run setup
.\setup.ps1

# 3. Place ROM
# Copy FFMQ.sfc to roms/ folder

# 4. Verify installation
.\ffmq.bat info
```

### Linux/Mac (Bash)

```bash
# 1. Clone repository
git clone https://github.com/yourusername/ffmq-info.git
cd ffmq-info

# 2. Run setup
chmod +x setup.sh ffmq
./setup.sh

# 3. Place ROM
# Copy FFMQ.sfc to roms/ folder

# 4. Verify installation
./ffmq info
```

---

## Detailed Installation Steps

### Step 1: Install Prerequisites

#### Windows
```powershell
# Install Python 3.10+
# Download from: https://www.python.org/downloads/

# Verify installation
python --version  # Should show 3.10 or higher

# Install Git (optional)
# Download from: https://git-scm.com/download/win
```

#### macOS
```bash
# Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Python
brew install python@3.10

# Verify installation
python3 --version  # Should show 3.10 or higher

# Install Git (optional)
brew install git
```

#### Linux (Ubuntu/Debian)
```bash
# Update package list
sudo apt update

# Install Python 3.10+
sudo apt install python3.10 python3.10-venv python3-pip

# Verify installation
python3 --version  # Should show 3.10 or higher

# Install Git (optional)
sudo apt install git
```

#### Linux (Fedora/RHEL)
```bash
# Install Python 3.10+
sudo dnf install python3.10

# Verify installation
python3 --version  # Should show 3.10 or higher

# Install Git (optional)
sudo dnf install git
```

---

### Step 2: Clone Repository

#### Using Git
```bash
# Clone to current directory
git clone https://github.com/yourusername/ffmq-info.git
cd ffmq-info

# Or clone to specific directory
git clone https://github.com/yourusername/ffmq-info.git /path/to/your/folder
cd /path/to/your/folder
```

#### Without Git (Download ZIP)
1. Go to: https://github.com/yourusername/ffmq-info
2. Click "Code" → "Download ZIP"
3. Extract to your desired location
4. Open terminal/PowerShell in extracted folder

---

### Step 3: Run Setup Script

#### Windows
```powershell
# Navigate to project folder
cd ffmq-info

# Run setup script
.\setup.ps1

# What it does:
# - Checks Python version (must be 3.8+)
# - Creates virtual environment (venv)
# - Installs all dependencies
# - Verifies ROM location
# - Shows project information
```

#### Linux/Mac
```bash
# Navigate to project folder
cd ffmq-info

# Make scripts executable
chmod +x setup.sh ffmq

# Run setup script
./setup.sh

# What it does:
# - Checks Python version (must be 3.8+)
# - Creates virtual environment (venv)
# - Installs all dependencies
# - Verifies ROM location
# - Shows project information
```

---

### Step 4: Obtain ROM File

**IMPORTANT:** You must own a legal copy of Final Fantasy Mystic Quest.

#### ROM Requirements
- **Filename:** FFMQ.sfc (recommended) or FFMQ.smc
- **Size:** 2,097,152 bytes (2 MB) exactly
- **Format:** Super Nintendo ROM format
- **Region:** USA version recommended
- **Location:** Place in `roms/` folder

#### Verify ROM
```bash
# Windows
(Get-Item roms\FFMQ.sfc).Length  # Should show 2097152

# Linux/Mac
ls -l roms/FFMQ.sfc  # Size should be 2097152 bytes
```

---

### Step 5: Verify Installation

#### Windows
```powershell
# Test task runner
.\ffmq.bat info

# Expected output:
# ROM Status: FOUND (2097152 bytes)
# Dialogs: 116 total
# Control Codes: 77 mapped
# DTE Sequences: 116 compressed
```

#### Linux/Mac
```bash
# Test task runner
./ffmq info

# Or using make
make info

# Expected output:
# ROM Status: FOUND (2097152 bytes)
# Dialogs: 116 total
# Control Codes: 77 mapped
# DTE Sequences: 116 compressed
```

---

## Optional: Install Emulator

### MesenS (Recommended)

#### Windows
1. Download from: https://github.com/SourMesen/Mesen-S/releases
2. Extract to `C:\Program Files\Mesen-S\`
3. Add to PATH (optional):
   - System Properties → Environment Variables
   - Edit "Path"
   - Add: `C:\Program Files\Mesen-S\`

#### macOS
```bash
# Using Homebrew
brew install --cask mesen-s
```

#### Linux
```bash
# Download from releases page
wget https://github.com/SourMesen/Mesen-S/releases/latest/download/Mesen-S.Linux-x64.zip

# Extract
unzip Mesen-S.Linux-x64.zip -d ~/mesen-s

# Make executable
chmod +x ~/mesen-s/Mesen-S

# Add to PATH (optional)
echo 'export PATH="$HOME/mesen-s:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Testing with Emulator
```bash
# Windows
.\ffmq.bat test

# Linux/Mac
./ffmq test
# or
make test
```

---

## Optional: Install Development Tools

### VS Code (Recommended Editor)

#### All Platforms
1. Download from: https://code.visualstudio.com/
2. Install recommended extensions:
   - Python (Microsoft)
   - Makefile Tools
   - JSON Tools
   - Git Lens (optional)

### Assembly Tools (for disassembly work)

#### ca65 (CC65 Assembler)
```bash
# Windows
# Download from: https://cc65.github.io/
# Add to PATH

# Linux/Mac
# Ubuntu/Debian
sudo apt install cc65

# macOS
brew install cc65
```

#### asar (SNES Assembler)
```bash
# Download from: https://github.com/RPGHacker/asar/releases
# Extract and add to PATH
```

---

## Troubleshooting Installation

### Python Not Found

#### Windows
```powershell
# Check if Python is in PATH
python --version

# If not found, reinstall Python and check "Add to PATH" option
# Or manually add to PATH:
# System Properties → Environment Variables → Path
# Add: C:\Users\YourName\AppData\Local\Programs\Python\Python310\
```

#### Linux/Mac
```bash
# Try python3 instead
python3 --version

# If not found, reinstall using package manager
```

### Setup Script Fails

#### Check Python Version
```bash
# Must be 3.8 or higher
python --version
# or
python3 --version
```

#### Check Pip Installation
```bash
# Windows
python -m pip --version

# Linux/Mac
python3 -m pip --version
```

#### Manual Setup
```bash
# Create virtual environment
python -m venv venv

# Activate virtual environment
# Windows:
.\venv\Scripts\activate
# Linux/Mac:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### ROM Not Found

```bash
# Check ROM location
# Should be in: roms/FFMQ.sfc

# Verify size
# Windows:
(Get-Item roms\FFMQ.sfc).Length
# Linux/Mac:
ls -l roms/FFMQ.sfc

# Size should be exactly: 2,097,152 bytes
```

### Permission Denied (Linux/Mac)

```bash
# Make scripts executable
chmod +x setup.sh ffmq

# If still issues, check file ownership
ls -l setup.sh ffmq

# Fix ownership if needed
sudo chown $USER:$USER setup.sh ffmq
```

### Task Runner Not Working

#### Windows
```powershell
# Check PowerShell execution policy
Get-ExecutionPolicy

# If Restricted, run as admin:
Set-ExecutionPolicy RemoteSigned

# Or use batch wrapper:
.\ffmq.bat help
```

#### Linux/Mac
```bash
# Make sure ffmq script is executable
chmod +x ffmq

# Make sure Makefile.dialog exists
ls -l Makefile.dialog

# Try direct make command
make -f Makefile.dialog help
```

---

## Post-Installation Configuration

### Configure Python Path (Optional)

If tools can't find Python modules:

```bash
# Windows
$env:PYTHONPATH = "C:\path\to\ffmq-info\tools"

# Linux/Mac
export PYTHONPATH="/path/to/ffmq-info/tools"
```

### Configure ROM Path (If Different)

Edit task runner scripts to use custom ROM location:

#### ffmq-tasks.ps1 (Windows)
```powershell
# Change this line:
$RomPath = "roms\FFMQ.sfc"
# To:
$RomPath = "C:\path\to\your\FFMQ.sfc"
```

#### Makefile.dialog (Linux/Mac)
```makefile
# Change this line:
ROM_PATH = roms/FFMQ.sfc
# To:
ROM_PATH = /path/to/your/FFMQ.sfc
```

---

## Verification Checklist

After installation, verify everything works:

- [ ] Python version is 3.8 or higher
- [ ] Virtual environment created successfully
- [ ] Dependencies installed without errors
- [ ] ROM file in correct location (roms/FFMQ.sfc)
- [ ] ROM size is exactly 2,097,152 bytes
- [ ] Task runner shows project info
- [ ] Can list dialogs
- [ ] Can extract text
- [ ] Emulator installed (optional)
- [ ] Can test ROM (optional)

### Run Verification Commands

```bash
# Windows
python --version
.\ffmq.bat info
.\ffmq.bat dialog-list

# Linux/Mac
python3 --version
./ffmq info
./ffmq dialog-list
```

All commands should complete without errors.

---

## Next Steps

After successful installation:

1. **Read Quick Start Guide**
   - See: `tools/map-editor/QUICK_REFERENCE.md`
   - Time: 5 minutes

2. **Try First Workflow**
   - Extract text: `ffmq extract-text`
   - Edit dialog: `ffmq edit 1`
   - See: `docs/WORKFLOW_GUIDE.md`

3. **Explore Documentation**
   - Dialog commands: `docs/DIALOG_COMMANDS.md`
   - Command reference: `tools/map-editor/COMMAND_REFERENCE.md`
   - Workflow guide: `docs/WORKFLOW_GUIDE.md`

4. **Join Community**
   - GitHub Issues: Report bugs, request features
   - Discussions: Ask questions, share work
   - Discord: Real-time help (if available)

---

## Updating the Project

### Pull Latest Changes

```bash
# With Git
git pull origin master

# Reinstall dependencies if needed
# Windows:
.\venv\Scripts\activate
pip install -r requirements.txt

# Linux/Mac:
source venv/bin/activate
pip install -r requirements.txt
```

### Without Git

1. Download latest ZIP from GitHub
2. Extract to temporary location
3. Copy new files to your project folder
4. Reinstall dependencies: `pip install -r requirements.txt`

---

## Uninstallation

### Complete Removal

```bash
# 1. Deactivate virtual environment (if active)
deactivate

# 2. Delete project folder
# Windows:
Remove-Item -Recurse -Force ffmq-info

# Linux/Mac:
rm -rf ffmq-info
```

### Keep ROM and Data

```bash
# 1. Backup important files
# Copy from project:
# - roms/FFMQ.sfc (your ROM)
# - data/text/ (extracted text)
# - data/enemies/ (edited enemies)

# 2. Then delete project folder
```

---

## Getting Help

### Documentation
- **Quick Start:** `tools/map-editor/QUICK_REFERENCE.md`
- **Workflows:** `docs/WORKFLOW_GUIDE.md`
- **Commands:** `tools/map-editor/COMMAND_REFERENCE.md`
- **Control Codes:** `docs/DIALOG_COMMANDS.md`

### Community
- **GitHub Issues:** Bug reports and feature requests
- **GitHub Discussions:** Questions and help
- **Discord:** Real-time support (if available)

### Common Issues
- See "Troubleshooting Installation" section above
- Check GitHub Issues for known problems
- Search documentation for your specific issue

---

**Last Updated:** 2024-11-11  
**Version:** 2.0  
**Tested On:** Windows 11, macOS 14, Ubuntu 22.04
