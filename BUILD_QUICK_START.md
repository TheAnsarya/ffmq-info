# FFMQ Build System v2.0 - Quick Start Guide# FFMQ Build System - Quick Reference



## 🚀 Quick Start (30 seconds)## Complete Workflow Example



```powershell### 1. Initial Setup (First Time Only)

# 1. Build the ROM```powershell

.\build.ps1make -f Makefile.enhanced setup

make -f Makefile.enhanced install-deps

# 2. Watch for changes (auto-rebuild)```

.\tools\Build-Watch.ps1

### 2. Extract Everything from ROM

# 3. Validate the build```powershell

.\tools\Build-Validator.ps1 -RomPath "build\ffmq-rebuilt.sfc" -ReferencePath "roms\Final Fantasy - Mystic Quest (U) (V1.1).sfc"make -f Makefile.enhanced extract-all

``````



---This creates:

- `assets/graphics/*.png` - All graphics as editable PNG files

## 📋 Table of Contents- `assets/text/*.txt` - All text/dialog (human-readable)

- `assets/data/enemies.json` - Enemy stats (JSON)

1. [Initial Setup](#initial-setup)- `assets/data/enemies.csv` - Enemy stats (spreadsheet)

2. [Build System Architecture](#build-system-architecture)

3. [Common Workflows](#common-workflows)### 3. Make Your Modifications

4. [Build Configuration](#build-configuration)

5. [Development Mode](#development-mode)**Edit Graphics:**

6. [Troubleshooting](#troubleshooting)```powershell

# Open and edit PNG files in:

---assets/graphics/



## 🔧 Initial Setup# Use any image editor (keep indexed color mode!)

```

### First-Time Project Setup

**Edit Text:**

```powershell```powershell

# Run setup script# Edit text files:

.\setup.ps1assets/text/item_names.txt

assets/text/dialog.txt

# Install Python dependencies

python -m pip install -r requirements.txt# Format: ID | Text | Address

0001 | Cure           | $04f000

# Verify tools are installed0002 | Mega Cure      | $04f00c  # <-- Changed this

make check```

```

**Edit Enemy Data:**

### Required Tools```powershell

# Edit in Excel/LibreOffice:

| Tool | Version | Purpose | Download |assets/data/enemies.csv

|------|---------|---------|----------|

| **asar** | 1.90+ | SNES assembler | [GitHub](https://github.com/RPGHacker/asar/releases) |# Or edit JSON:

| **Python** | 3.8+ | Asset extraction tools | [python.org](https://www.python.org/) |assets/data/enemies.json

| **PowerShell** | 5.1+ | Build system scripts | Built into Windows |

| **Make** | 3.81+ | Build orchestration | [GnuWin32](http://gnuwin32.sourceforge.net/packages/make.htm) |# Change HP, attack, defense, resistances, etc.

```

---

### 4. Convert Modified Data

## 🏗️ Build System Architecture```powershell

# Convert PNG graphics back to SNES format

### New Build System v2.0make -f Makefile.enhanced convert-graphics

```

The build system has been completely rewritten for modern development:

### 5. Build ROM

``````powershell

build.config.json          ← Central configuration# Assemble code changes

├── tools/make -f Makefile.enhanced build-rom

│   ├── Build-System.ps1   ← Main build orchestrator```

│   ├── Build-Validator.ps1 ← ROM validation & comparison

│   ├── Build-Watch.ps1    ← Auto-rebuild on changes### 6. Inject Modifications

│   └── extract_*.py       ← Asset extraction tools```powershell

├── Makefile.v2            ← Cross-platform Make targets# Inject all modified data into ROM

└── build.ps1              ← Simple build wrappermake -f Makefile.enhanced inject-all

```

# Or inject specific types:

### Key Featuresmake -f Makefile.enhanced inject-graphics

make -f Makefile.enhanced inject-text

✅ **Configuration-Driven**: All settings in `build.config.json`make -f Makefile.enhanced inject-enemies

✅ **Comprehensive Validation**: Header checks, checksums, byte-by-byte comparison```

✅ **Watch Mode**: Auto-rebuild on file changes with debouncing

✅ **Progress Tracking**: Build statistics and timing information### 7. Test

✅ **Modern PowerShell**: Follows best practices with full documentation```powershell

✅ **Cross-Platform**: Works on Windows with PowerShell# Verify build

make -f Makefile.enhanced verify

---

# Test in emulator

## 📖 Common Workflowsmake -f Makefile.enhanced test

```

### Building the ROM

---

#### Using PowerShell (Recommended)

## Quick Commands

```powershell

# Simple build| What You Want to Do | Command |

.\build.ps1|---------------------|---------|

| Extract all data | `make -f Makefile.enhanced extract-all` |

# Build with verbose output| Extract just graphics | `make -f Makefile.enhanced extract-graphics` |

.\build.ps1 -Verbose| Extract just text | `make -f Makefile.enhanced extract-text` |

| Extract just enemies | `make -f Makefile.enhanced extract-enemies` |

# Build with symbol generation| Convert PNG → SNES | `make -f Makefile.enhanced convert-graphics` |

.\build.ps1 -Symbols| Build ROM | `make -f Makefile.enhanced build-rom` |

| Inject everything | `make -f Makefile.enhanced inject-all` |

# Clean build| Test ROM | `make -f Makefile.enhanced test` |

.\build.ps1 -Clean| See all commands | `make -f Makefile.enhanced help` |

```

---

#### Using Build System Directly

## File Locations

```powershell

# Standard build### Original ROM

.\tools\Build-System.ps1 -Target build```

~roms/Final Fantasy - Mystic Quest (U) (V1.1).sfc

# Clean and rebuild```

.\tools\Build-System.ps1 -Target rebuild

### Extracted Assets (EDITABLE)

# Complete pipeline (clean, build, validate, compare)```

.\tools\Build-System.ps1 -Target allassets/

├── graphics/           # PNG images (edit with any image editor)

# With verbose output├── text/               # Text files (edit with text editor)

.\tools\Build-System.ps1 -Target build -Verbose└── data/

```    ├── enemies.json    # Edit with text editor

	├── enemies.csv     # Edit with Excel/LibreOffice

#### Using Make    ├── items.json

	└── palettes/

```bash```

# Build ROM

make build### Build Output

```

# Clean and rebuildbuild/

make rebuild├── ffmq-modified.sfc   # Your modified ROM (test this!)

├── ffmq-clean.sfc      # Clean reference

# Complete pipeline├── converted/          # PNG → SNES converted data

make all└── extracted/          # Raw extracted data

```

# Show all available targets

make help### Source Code

``````

src/asm/

### Extracting Assets from Original ROM├── ffmq_complete.asm   # Main assembly file

├── banks/              # Actual buildable code

```powershell│   ├── bank_00.asm ... bank_0F.asm

# Extract all assets│   └── main.asm

.\tools\Build-System.ps1 -Target extract└── analyzed/           # Documentation (your reverse engineering work)

	├── nmi_handler.asm

# Or using Make    ├── input_handler.asm

make extract    ├── battle_system.asm

	└── ...

# Extract specific assets```

make extract-gfx      # Graphics only

make extract-text     # Text only---

make extract-music    # Music only

```## One-Line Examples



**Output Locations:**### Example 1: Change Enemy HP

- Graphics: `assets/graphics/*.png````powershell

- Text: `assets/text/*.txt`# Extract, edit CSV, rebuild

- Music: `assets/music/*.spc`make -f Makefile.enhanced extract-enemies

- Data: `assets/data/*.json`# Edit assets/data/enemies.csv (change HP values)

make -f Makefile.enhanced build-rom inject-enemies test

### Validating Built ROM```



```powershell### Example 2: Edit Graphics

# Quick validation```powershell

.\tools\Build-System.ps1 -Target validate# Extract, edit PNG, rebuild

make -f Makefile.enhanced extract-graphics

# Detailed comparison with report# Edit assets/graphics/hero_sprite.png

.\tools\Build-Validator.ps1 `make -f Makefile.enhanced convert-graphics build-rom inject-graphics test

	-RomPath "build\ffmq-rebuilt.sfc" ````

	-ReferencePath "roms\Final Fantasy - Mystic Quest (U) (V1.1).sfc" `

	-OutputReport "build\comparison-report.txt"### Example 3: Change Dialog

```powershell

# Using Make# Extract, edit text, rebuild

make validatemake -f Makefile.enhanced extract-text

make compare# Edit assets/text/dialog.txt

```make -f Makefile.enhanced build-rom inject-text test

```

### Generating Symbol Files

### Example 4: Full Rebuild

```powershell```powershell

# Symbols are generated automatically during build if enabled in config# Extract everything, make changes, rebuild everything

# Check build.config.json → build.options.generateSymbolsmake -f Makefile.enhanced extract-all

# Make your edits...

# Force symbol generationmake -f Makefile.enhanced convert-graphics build-rom inject-all test

.\tools\Build-System.ps1 -Target symbols```



# Or using build.ps1---

.\build.ps1 -Symbols

```## Troubleshooting



---### "Python was not found"

Install Python 3.x from python.org, then:

## ⚙️ Build Configuration```powershell

make -f Makefile.enhanced install-deps

### Configuration File: `build.config.json````



All build settings are centralized in this file:### "asar not found"

Download asar from: https://github.com/RPGHacker/asar/releases

```jsonPut `asar.exe` in your PATH or in the project root.

{

	"build": {### "Graphics look wrong"

		"mainSource": "src/asm/ffmq_working.asm",- Make sure PNG files are in indexed color mode

		"outputRom": "build/ffmq-rebuilt.sfc",- Don't change palette without updating palette files

		"symbolFile": "build/symbols.sym",- Check BPP setting (2/4/8) matches original

		"expectedSize": 1048576,

		"options": {### "Build fails"

			"generateSymbols": true,```powershell

			"verbose": false,# Clean and rebuild

			"checkSize": true,make -f Makefile.enhanced clean

			"compareOriginal": truemake -f Makefile.enhanced build-rom

		}```

	}

}---

```

## Documentation

### Key Settings

Full documentation: `docs/BUILD_SYSTEM.md`

| Setting | Purpose | Default |

|---------|---------|---------|Topics covered:

| `build.mainSource` | Main assembly entry point | `src/asm/ffmq_working.asm` |- Complete workflow explanation

| `build.outputRom` | Output ROM path | `build/ffmq-rebuilt.sfc` |- Directory structure details  

| `build.options.generateSymbols` | Create symbol file | `true` |- Tool reference

| `build.options.verbose` | Verbose assembler output | `false` |- Advanced techniques

| `validation.checksum.enabled` | Verify checksums | `true` |- Troubleshooting guide

| `watch.debounceMs` | Auto-rebuild delay (ms) | `500` |

---

### Modifying Configuration

## What This Gives You

```powershell

# Edit the configuration file✅ **Seamless workflow:** ROM → extract → edit → rebuild → ROM  

notepad build.config.json✅ **Graphics editing:** PNG files instead of hex editing  

✅ **Text editing:** Plain text files instead of ROM hacking  

# The build system will automatically reload on next build✅ **Data editing:** JSON/CSV instead of assembly  

```✅ **Automated pipeline:** One command to extract, one to rebuild  

✅ **Integration:** Graphics tools automatically called during build  

---✅ **Verification:** Compare with original to see what changed  

✅ **Testing:** Launch in emulator with one command  

## 💻 Development Mode

---

### Watch Mode (Auto-Rebuild)

## Current Status

Watch mode monitors source files and automatically rebuilds when changes are detected:

**Reverse Engineering Analysis Complete:**

```powershell- 8 analysis files documenting game systems (2,510+ lines)

# Start watch mode- NMI/VBlank interrupt handler fully documented

.\tools\Build-Watch.ps1- Input/controller system fully documented  

- Battle, menu, DMA, boot systems analyzed

# Watch with verbose output- Complete RAM variable map

.\tools\Build-Watch.ps1 -Verbose

**Build System Complete:**

# Watch with auto-launch in emulator- Enhanced Makefile with full pipeline (550+ lines)

.\tools\Build-Watch.ps1 -AutoLaunch- Data extraction tools (enemies, text)

- Graphics conversion integration

# Using Make- Complete build documentation (450+ lines)

make watch    # Standard watch mode

make dev      # Watch + auto-launch**Ready to Use:**

```- Extract all data with one command

- Edit in familiar tools (image editors, text editors, Excel)

**Features:**- Rebuild ROM with modifications

- 🔍 Monitors `src/asm/` directory for `.asm`, `.s`, `.inc` files- Test immediately in emulator

- ⏱️ Debouncing (500ms default) prevents excessive rebuilds

- 📊 Build statistics (success/fail counts)---

- 🎮 Optional auto-launch in emulator

## Next Steps

### Customizing Watch Behavior

1. Try the workflow with a simple change

Edit `build.config.json`:2. Create your mod/hack

3. Share with the community!

```json

{For detailed information, see: `docs/BUILD_SYSTEM.md`

	"watch": {
		"enabled": true,
		"paths": [
			"src/asm/**/*.asm",
			"src/asm/**/*.s",
			"src/include/**/*.inc"
		],
		"debounceMs": 500,
		"autoRebuild": true,
		"autoLaunch": false
	}
}
```

---

## 🔍 Validation & Comparison

### ROM Header Validation

The validator checks:
- ✅ ROM name in header
- ✅ Map mode (HiROM/LoROM)
- ✅ ROM speed (Fast/Slow)
- ✅ ROM size
- ✅ SRAM size
- ✅ Checksums and complements

### Byte-by-Byte Comparison

```powershell
.\tools\Build-Validator.ps1 `
	-RomPath "build\ffmq-rebuilt.sfc" `
	-ReferencePath "roms\Final Fantasy - Mystic Quest (U) (V1.1).sfc" `
	-OutputReport "build\comparison-report.txt" `
	-Verbose
```

**Output:**
```
✅ ROMs are byte-for-byte identical!
or
⚠️  Found 1234 differences
ℹ️  Match: 99.8803%

First 20 differences:
  Offset       Built   Original
  ─────────────────────────────
  0x008000    0xff    0x00
  0x008001    0xa5    0xc9
  ...
```

### Understanding Match Percentages

| Match % | Status | Meaning |
|---------|--------|---------|
| 100% | ✅ Perfect | Byte-for-byte identical |
| 99.99%+ | 🟢 Excellent | Minor differences (usually labels) |
| 95-99% | 🟡 Good | Partial disassembly, functional |
| <95% | 🔴 Incomplete | Major work needed |

---

## 🛠️ Troubleshooting

### Common Issues

#### "asar not found"

```powershell
# Solution 1: Add to PATH
# Download from https://github.com/RPGHacker/asar/releases
# Add asar.exe location to PATH

# Solution 2: Place in project root
# Copy asar.exe to project root folder
```

#### "Python not found"

```powershell
# Install Python 3.8 or later from python.org
# Ensure "Add to PATH" is checked during installation

# Verify installation
python --version
```

#### "Configuration file not found"

```powershell
# Ensure build.config.json exists in project root
# If missing, it should have been created during setup

# Verify current directory
pwd
# Should be: C:\Users\...\ffmq-info
```

#### Build fails with assembly errors

```powershell
# Run with verbose output to see detailed errors
.\build.ps1 -Verbose

# Check specific source file
notepad src\asm\ffmq_working.asm

# Look for:
# - Syntax errors
# - Missing include files
# - Label conflicts
```

#### Watch mode not detecting changes

```powershell
# Ensure you're editing files in src/asm/
# Only .asm, .s, and .inc files trigger rebuilds

# Try with verbose output
.\tools\Build-Watch.ps1 -Verbose

# Check configuration
notepad build.config.json
# Verify watch.paths setting
```

---

## 📊 Build System Comparison

### Old System vs New System

| Feature | Old System | New System v2.0 |
|---------|-----------|-----------------|
| Configuration | Hardcoded | `build.config.json` |
| Validation | Basic | Comprehensive |
| Watch Mode | Manual | Automated |
| Documentation | Minimal | Extensive |
| Error Handling | Basic | Robust |
| Logging | Console only | Console + file |
| Progress Tracking | None | Full statistics |
| Cross-Platform | Limited | Improved |

---

## 🎯 Next Steps

### For Disassembly Work

1. **Extract Assets**: `make extract`
2. **Study Structure**: Review `src/asm/` files
3. **Start Watch Mode**: `make watch`
4. **Edit Assembly**: Modify `.asm` files
5. **Auto-Rebuild**: Watch mode rebuilds automatically
6. **Validate**: Check differences with original

### For ROM Hacking

1. **Extract Assets**: `make extract`
2. **Modify Assets**: Edit PNG graphics, text files, etc.
3. **Rebuild ROM**: `make build`
4. **Test in Emulator**: Launch with MesenS
5. **Validate Changes**: `make validate`

### For Build System Development

1. **Study Code**: Review `tools/*.ps1` scripts
2. **Check Configuration**: `build.config.json` structure
3. **Run Tests**: Verify all targets work
4. **Extend Features**: Add new targets or validators
5. **Update Docs**: Keep documentation current

---

## 📚 Additional Resources

### Documentation
- [EditorConfig](.editorconfig) - Code formatting rules
- [Makefile.v2](Makefile.v2) - Make target reference
- [build.config.json](build.config.json) - Configuration schema

### Tools
- [Build-System.ps1](tools/Build-System.ps1) - Main build orchestrator
- [Build-Validator.ps1](tools/Build-Validator.ps1) - ROM validator
- [Build-Watch.ps1](tools/Build-Watch.ps1) - Watch mode script

### External Links
- [Asar Documentation](https://github.com/RPGHacker/asar/blob/master/README.md)
- [SNES Dev Wiki](https://snes.nesdev.org/)
- [PowerShell Documentation](https://docs.microsoft.com/en-us/powershell/)

---

## 💡 Tips & Best Practices

### Code Formatting
- ✅ Use **tabs** (size: 4), never spaces
- ✅ Use **CRLF** line endings
- ✅ Use **UTF-8** encoding
- ✅ Use **lowercase hexadecimal** (`0xff` not `0xFF`)
- ✅ Follow `.editorconfig` rules

### Build Workflow
- ✅ Use watch mode during active development
- ✅ Run full validation before commits
- ✅ Keep configuration in `build.config.json`
- ✅ Check build logs in `build/build.log`

### Version Control
- ✅ Commit working builds
- ✅ Update SESSION_LOG.md with changes
- ✅ Use descriptive commit messages
- ✅ Don't commit build artifacts (in `.gitignore`)

---

**Build System Version**: 2.0.0
**Last Updated**: October 30, 2025
**Maintainer**: Build System Team
