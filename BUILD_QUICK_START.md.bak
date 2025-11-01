# FFMQ Build System - Quick Reference

## Complete Workflow Example

### 1. Initial Setup (First Time Only)
```powershell
make -f Makefile.enhanced setup
make -f Makefile.enhanced install-deps
```

### 2. Extract Everything from ROM
```powershell
make -f Makefile.enhanced extract-all
```

This creates:
- `assets/graphics/*.png` - All graphics as editable PNG files
- `assets/text/*.txt` - All text/dialog (human-readable)
- `assets/data/enemies.json` - Enemy stats (JSON)
- `assets/data/enemies.csv` - Enemy stats (spreadsheet)

### 3. Make Your Modifications

**Edit Graphics:**
```powershell
# Open and edit PNG files in:
assets/graphics/

# Use any image editor (keep indexed color mode!)
```

**Edit Text:**
```powershell
# Edit text files:
assets/text/item_names.txt
assets/text/dialog.txt

# Format: ID | Text | Address
0001 | Cure           | $04F000
0002 | Mega Cure      | $04F00C  # <-- Changed this
```

**Edit Enemy Data:**
```powershell
# Edit in Excel/LibreOffice:
assets/data/enemies.csv

# Or edit JSON:
assets/data/enemies.json

# Change HP, attack, defense, resistances, etc.
```

### 4. Convert Modified Data
```powershell
# Convert PNG graphics back to SNES format
make -f Makefile.enhanced convert-graphics
```

### 5. Build ROM
```powershell
# Assemble code changes
make -f Makefile.enhanced build-rom
```

### 6. Inject Modifications
```powershell
# Inject all modified data into ROM
make -f Makefile.enhanced inject-all

# Or inject specific types:
make -f Makefile.enhanced inject-graphics
make -f Makefile.enhanced inject-text
make -f Makefile.enhanced inject-enemies
```

### 7. Test
```powershell
# Verify build
make -f Makefile.enhanced verify

# Test in emulator
make -f Makefile.enhanced test
```

---

## Quick Commands

| What You Want to Do | Command |
|---------------------|---------|
| Extract all data | `make -f Makefile.enhanced extract-all` |
| Extract just graphics | `make -f Makefile.enhanced extract-graphics` |
| Extract just text | `make -f Makefile.enhanced extract-text` |
| Extract just enemies | `make -f Makefile.enhanced extract-enemies` |
| Convert PNG → SNES | `make -f Makefile.enhanced convert-graphics` |
| Build ROM | `make -f Makefile.enhanced build-rom` |
| Inject everything | `make -f Makefile.enhanced inject-all` |
| Test ROM | `make -f Makefile.enhanced test` |
| See all commands | `make -f Makefile.enhanced help` |

---

## File Locations

### Original ROM
```
~roms/Final Fantasy - Mystic Quest (U) (V1.1).sfc
```

### Extracted Assets (EDITABLE)
```
assets/
├── graphics/           # PNG images (edit with any image editor)
├── text/               # Text files (edit with text editor)
└── data/
    ├── enemies.json    # Edit with text editor
    ├── enemies.csv     # Edit with Excel/LibreOffice
    ├── items.json
    └── palettes/
```

### Build Output
```
build/
├── ffmq-modified.sfc   # Your modified ROM (test this!)
├── ffmq-clean.sfc      # Clean reference
├── converted/          # PNG → SNES converted data
└── extracted/          # Raw extracted data
```

### Source Code
```
src/asm/
├── ffmq_complete.asm   # Main assembly file
├── banks/              # Actual buildable code
│   ├── bank_00.asm ... bank_0F.asm
│   └── main.asm
└── analyzed/           # Documentation (your reverse engineering work)
    ├── nmi_handler.asm
    ├── input_handler.asm
    ├── battle_system.asm
    └── ...
```

---

## One-Line Examples

### Example 1: Change Enemy HP
```powershell
# Extract, edit CSV, rebuild
make -f Makefile.enhanced extract-enemies
# Edit assets/data/enemies.csv (change HP values)
make -f Makefile.enhanced build-rom inject-enemies test
```

### Example 2: Edit Graphics
```powershell
# Extract, edit PNG, rebuild
make -f Makefile.enhanced extract-graphics
# Edit assets/graphics/hero_sprite.png
make -f Makefile.enhanced convert-graphics build-rom inject-graphics test
```

### Example 3: Change Dialog
```powershell
# Extract, edit text, rebuild
make -f Makefile.enhanced extract-text
# Edit assets/text/dialog.txt
make -f Makefile.enhanced build-rom inject-text test
```

### Example 4: Full Rebuild
```powershell
# Extract everything, make changes, rebuild everything
make -f Makefile.enhanced extract-all
# Make your edits...
make -f Makefile.enhanced convert-graphics build-rom inject-all test
```

---

## Troubleshooting

### "Python was not found"
Install Python 3.x from python.org, then:
```powershell
make -f Makefile.enhanced install-deps
```

### "asar not found"
Download asar from: https://github.com/RPGHacker/asar/releases
Put `asar.exe` in your PATH or in the project root.

### "Graphics look wrong"
- Make sure PNG files are in indexed color mode
- Don't change palette without updating palette files
- Check BPP setting (2/4/8) matches original

### "Build fails"
```powershell
# Clean and rebuild
make -f Makefile.enhanced clean
make -f Makefile.enhanced build-rom
```

---

## Documentation

Full documentation: `docs/BUILD_SYSTEM.md`

Topics covered:
- Complete workflow explanation
- Directory structure details  
- Tool reference
- Advanced techniques
- Troubleshooting guide

---

## What This Gives You

✅ **Seamless workflow:** ROM → extract → edit → rebuild → ROM  
✅ **Graphics editing:** PNG files instead of hex editing  
✅ **Text editing:** Plain text files instead of ROM hacking  
✅ **Data editing:** JSON/CSV instead of assembly  
✅ **Automated pipeline:** One command to extract, one to rebuild  
✅ **Integration:** Graphics tools automatically called during build  
✅ **Verification:** Compare with original to see what changed  
✅ **Testing:** Launch in emulator with one command  

---

## Current Status

**Reverse Engineering Analysis Complete:**
- 8 analysis files documenting game systems (2,510+ lines)
- NMI/VBlank interrupt handler fully documented
- Input/controller system fully documented  
- Battle, menu, DMA, boot systems analyzed
- Complete RAM variable map

**Build System Complete:**
- Enhanced Makefile with full pipeline (550+ lines)
- Data extraction tools (enemies, text)
- Graphics conversion integration
- Complete build documentation (450+ lines)

**Ready to Use:**
- Extract all data with one command
- Edit in familiar tools (image editors, text editors, Excel)
- Rebuild ROM with modifications
- Test immediately in emulator

---

## Next Steps

1. Try the workflow with a simple change
2. Create your mod/hack
3. Share with the community!

For detailed information, see: `docs/BUILD_SYSTEM.md`
