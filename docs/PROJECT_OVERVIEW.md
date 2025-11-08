# FFMQ Project Overview

> **Last Updated:** 2025-11-07  
> **Project Status:** Active Development - 30.5% Documented  
> **GitHub:** [TheAnsarya/ffmq-info](https://github.com/TheAnsarya/ffmq-info)

This document provides a high-level overview of the entire FFMQ (Final Fantasy Mystic Quest) disassembly and modding project.

## 🎯 Project Mission

Create a complete, well-documented disassembly of Final Fantasy Mystic Quest (SNES) that enables:
- **Preservation:** Preserve the game's code for future generations
- **Research:** Understand game mechanics and programming techniques
- **Modding:** Enable community ROM hacks and modifications
- **Education:** Teach SNES programming through real-world examples

## 📊 Current Status

### Documentation Coverage
- **Total Functions:** 2,486 documented
- **Coverage:** 30.5% (growing daily)
- **Recent Progress:** +183 functions in Update #37 (Bank $02)
- **Lines of Docs:** 18,000+ in FUNCTION_REFERENCE.md

### Major Milestones Achieved
✅ **Complete Diztinguish disassembly** (100% ROM coverage)  
✅ **Visual enemy editor** with GameFAQs validation  
✅ **Graphics pipeline** with PNG conversion  
✅ **Build system** producing byte-perfect ROMs  
✅ **Comprehensive documentation** structure  
✅ **130+ development tools** (Python/PowerShell)  

### Active Work Areas
🔄 **Bank $02 documentation** (controller, input, graphics systems)  
🔄 **Battle system research** (spells, attacks, mechanics)  
🔄 **Code analysis** (unreachable code, optimizations)  

## 🗂️ Project Structure

```
ffmq-info/
├── README.md              # Main project README
├── CONTRIBUTING.md        # Contribution guidelines
├── CHANGELOG.md           # Project changelog
│
├── docs/                  # Documentation (organized by category)
│   ├── INDEX.md          # Master documentation index
│   ├── guides/           # User guides (BUILD_GUIDE, FAQ, etc.)
│   ├── technical/        # Technical analysis (ROM structure, systems)
│   ├── status/           # Progress reports
│   ├── project-management/ # TODO lists, roadmaps, issues
│   ├── datacrystal/      # DataCrystal wiki integration
│   ├── historical/       # Session logs, completion reports
│   ├── FUNCTION_REFERENCE.md    # Complete function documentation (18K+ lines)
│   ├── TOOLS_REFERENCE.md       # Python tools documentation
│   └── POWERSHELL_REFERENCE.md  # PowerShell scripts documentation
│
├── src/                   # Source code
│   ├── asm/              # Assembly files (80K+ lines)
│   │   ├── bank_XX_documented.asm  # Documented bank files
│   │   └── ffmq_complete.asm       # Master assembly file
│   ├── include/          # Header files (constants, macros)
│   ├── data/             # Data tables (text, stats, etc.)
│   └── graphics/         # Binary graphics data
│
├── tools/                 # Development tools (130+ scripts)
│   ├── README.md         # Tools quick reference
│   ├── enemy_editor_gui.py        # Visual enemy editor
│   ├── extract_graphics_v2.py     # Graphics extraction
│   ├── build_rom.py               # ROM building
│   └── [130+ other tools]
│
├── assets/                # Extracted game assets
│   ├── graphics/         # PNG graphics files
│   ├── data/             # JSON data files (enemies, etc.)
│   └── text/             # Text strings
│
├── build/                 # Build output
│   └── ffmq-rebuilt.sfc  # Built ROM file
│
├── tests/                 # Test suite
│   ├── test_enemies.py
│   ├── test_pipeline.py
│   └── [other tests]
│
├── roms/                  # ROM files (not in git)
│   └── Final Fantasy - Mystic Quest (U) (V1.1).sfc
│
└── ~historical/           # Historical files (archived)
    ├── temp_cycles/      # Temporary work files
    └── original-code/    # Original disassembly attempts
```

## 🚀 Quick Start Paths

### For New Users
1. Read [README.md](../README.md) - Project overview
2. Run [setup.ps1](../setup.ps1) - Initial setup
3. Try [build.ps1](../build.ps1) - Build your first ROM
4. See [Quick Start Guide](guides/QUICK_START_GUIDE.md) - Getting started

### For Modders
1. Install Python and dependencies: `pip install -r requirements.txt`
2. Run enemy editor: `python tools/enemy_editor_gui.py`
3. Edit enemy stats, save JSON
4. Build ROM: `.\build.ps1`
5. Test in emulator: `mesen build/ffmq-rebuilt.sfc`

**See:** [Modding Quick Reference](guides/MODDING_QUICK_REFERENCE.md)

### For Developers
1. Fork and clone repository
2. Read [CONTRIBUTING.md](../CONTRIBUTING.md) - Standards and workflow
3. Review [ARCHITECTURE.md](ARCHITECTURE.md) - Project architecture
4. Check [GitHub Project #3](https://github.com/users/TheAnsarya/projects/3) - Current tasks
5. Pick an issue and start coding

### For Researchers
1. Browse [FUNCTION_REFERENCE.md](FUNCTION_REFERENCE.md) - Complete function docs
2. Read [Bank Classification](technical/BANK_CLASSIFICATION.md) - ROM structure
3. Study [Battle System](BATTLE_SYSTEM.md) - Game mechanics
4. Review [Technical Analysis](technical/TECHNICAL_ANALYSIS_2025-11-06.md) - Latest research

## 📚 Documentation System

### Master Index
**[docs/INDEX.md](INDEX.md)** - Complete documentation index organized by category

### By Category
- **Guides** - Step-by-step tutorials (BUILD_GUIDE, MODDING_GUIDE, FAQ)
- **Technical** - ROM structure, data formats, system analysis
- **Reference** - Function reference, labels, constants
- **Status** - Progress reports, campaign status
- **Management** - TODO lists, roadmaps, issues
- **Historical** - Session logs, completion reports

### By Audience
- **Users:** README → Quick Start Guide → FAQ
- **Modders:** Modding Guide → Enemy Editor Guide → Battle Data Pipeline
- **Developers:** CONTRIBUTING → ARCHITECTURE → Function Reference
- **Researchers:** ROM Data Map → Technical Analysis → Battle System

## 🛠️ Development Tools

### Python Tools (130+)
**Documented in:** [TOOLS_REFERENCE.md](TOOLS_REFERENCE.md)

**Categories:**
- Battle Data Tools (enemy editor, stats viewer)
- Build Tools (ROM building, comparison)
- Extraction Tools (graphics, text, data)
- Graphics Tools (PNG conversion, palettes)
- Analysis Tools (code analysis, research)
- Testing Tools (test framework)

**Star Tools:**
- `enemy_editor_gui.py` - Visual enemy editor
- `extract_graphics_v2.py` - Graphics extraction
- `snes_graphics.py` - Graphics codec library
- `run_all_tests.py` - Test suite

### PowerShell Scripts (30+)
**Documented in:** [POWERSHELL_REFERENCE.md](POWERSHELL_REFERENCE.md)

**Categories:**
- Build Scripts (build.ps1, modern-build.ps1)
- Tracking Scripts (start-tracking.ps1, update.ps1)
- Formatting Tools (format_asm.ps1)
- GitHub Integration (issue creation, project setup)

**Star Scripts:**
- `build.ps1` - Main ROM build
- `setup.ps1` - Initial setup
- `start-tracking.ps1` - Auto tracking
- `format_asm.ps1` - Code formatting

## 🎮 ROM Structure

### Banks Overview
**Documented in:** [Bank Classification](technical/BANK_CLASSIFICATION.md)

**Code Banks (8 banks = 256KB):**
- Bank $00: Main initialization, boot sequence
- Bank $01: Graphics/DMA engines
- Bank $02: Controller, input, graphics systems (current focus)
- Bank $03: Text data
- Banks $08-$0B: Game logic, battle system
- Banks $0C-$0E: Additional code
- Bank $0F: Additional code

**Data Banks (8 banks = 256KB):**
- Banks $04-$07: Graphics data
- Bank $09-$0A: Mixed code/data

### Address Mapping
**LoROM format:**
- ROM $000000-$007FFF → SNES $808000-$80FFFF (Bank $00)
- ROM $008000-$00FFFF → SNES $818000-$81FFFF (Bank $01)
- Etc. (see ROM_DATA_MAP.md for complete mapping)

## 💾 Data Formats

### Battle Data
**Documented in:** [Battle Data Pipeline](BATTLE_DATA_PIPELINE.md)

- **Enemies:** 83 total (Brownie to Dark King)
- **Attacks:** ~100 attacks with element types
- **Spells:** Magic system with learning mechanics
- **Format:** Binary in ROM → JSON in assets/ → ASM for building

### Graphics Data
**Documented in:** [Graphics Format](graphics-format.md)

- **Tile Format:** 2bpp/4bpp SNES format
- **Palettes:** 15-bit RGB555 color
- **Extraction:** Binary → PNG (tools/extract_graphics_v2.py)
- **Injection:** PNG → Binary (tools/convert_graphics.py)

### Text Data
**Documented in:** [Text System](TEXT_SYSTEM.md)

- **Format:** DTE (Dual Tile Encoding) compression
- **Character Table:** simple.tbl
- **Extraction:** tools/extract_text_enhanced.py

## 🧪 Testing System

### Test Suite
**Documented in:** [Testing Framework](TESTING_FRAMEWORK.md)

**Run all tests:**
```bash
python tools/run_all_tests.py
```

**Test categories:**
- Enemy data validation
- Graphics pipeline
- Build system
- Data extraction
- ROM comparison

**Coverage:**
- 90%+ test coverage for battle data pipeline
- GameFAQs data verification
- Roundtrip build tests

## 📈 Progress Tracking

### Automatic Tracking
**Run once:** `.\start-tracking.ps1`

System automatically logs:
- File modifications
- Build attempts
- Test runs
- Documentation updates

### Manual Logging
```powershell
# Log a change
.\update.ps1

# Or directly
python tools/update_chat_log.py --change "Description"
```

### Session Logs
**Location:** `docs/session-logs/`

Each session creates:
- Timestamped log file
- Change summary
- Question/note tracking

## 🔄 Build System

### Quick Build
```powershell
.\build.ps1
```

### Build Types
1. **Standard Build** - Normal ROM build
2. **Clean Build** - Remove old outputs first
3. **Verbose Build** - Detailed logging
4. **Symbol Build** - Generate debug symbols

### Verification
```powershell
# Quick check
.\quick-verify.ps1

# Full roundtrip test
.\test-roundtrip.ps1

# Detailed report
.\build-report.ps1
```

**Expected:** Byte-perfect match with original ROM

## 🌐 Community Integration

### DataCrystal Wiki
**Documented in:** [DataCrystal Integration](datacrystal/)

- ROM map documentation
- Data structure definitions
- Research findings
- Community contributions

### GitHub Project
**Project #3:** [GitHub Project Board](https://github.com/users/TheAnsarya/projects/3)

- Issue tracking
- Task organization
- Milestone planning
- Progress visualization

## 📋 Contribution Workflow

1. **Check issues** - Find something to work on
2. **Fork & clone** - Get local copy
3. **Create branch** - `feature/your-feature`
4. **Make changes** - Follow coding standards
5. **Test** - Run test suite
6. **Format** - Run format_asm.ps1
7. **Commit** - Descriptive message
8. **Push** - To your fork
9. **Pull request** - Detailed description

**See:** [CONTRIBUTING.md](../CONTRIBUTING.md) for complete guidelines

## 🎓 Learning Resources

### SNES Programming
- [SNES Development Manual](https://problemkaputt.de/fullsnes.htm)
- [65816 Instruction Set](https://softpixel.com/~cwright/sianse/docs/65816NFO.HTM)
- [Super Famicom Development Wiki](https://wiki.superfamicom.org/)

### ROM Hacking
- [ROMhacking.net](https://www.romhacking.net/)
- [SMW Central](https://www.smwcentral.net/) - SNES hacking community
- [DataCrystal](https://datacrystal.tcrf.net/wiki/Main_Page) - Game documentation

### Project-Specific
- [FUNCTION_REFERENCE.md](FUNCTION_REFERENCE.md) - In-code learning
- [Battle System](BATTLE_SYSTEM.md) - Game mechanics
- [Graphics Format](graphics-format.md) - SNES graphics

## 🔧 Troubleshooting

### Common Issues

**"Asar not found"**
- Download: https://github.com/RPGHacker/asar/releases
- Add to PATH or place in project root

**"Python not found"**
- Install Python 3.8+
- Ensure in PATH

**"Build doesn't match original"**
- Check src/asm/ files for modifications
- Run `.\test-roundtrip.ps1` for details
- Review build log

**"Scripts won't run"**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**See:** [Troubleshooting Guide](../TROUBLESHOOTING.md) for more

## 📊 Project Statistics

### Code
- **Assembly Lines:** 80,000+ (Diztinguish + documented)
- **Python Scripts:** 130+
- **PowerShell Scripts:** 30+
- **Documentation:** 18,000+ lines (FUNCTION_REFERENCE.md)

### Coverage
- **ROM:** 100% (via Diztinguish)
- **Functions:** 2,486 documented (30.5%)
- **Tests:** 90%+ for battle pipeline

### Activity
- **Commits:** 1,000+ (growing daily)
- **Contributors:** Active development
- **Issues:** Tracked in GitHub Project #3

## 🎯 Roadmap

### Short Term (Current)
- Continue Bank $02 documentation
- Complete spell system research
- Enhance graphics tools
- Expand test coverage

### Medium Term (Next 3 months)
- Bank $01 graphics/DMA documentation
- Complete battle system analysis
- Text editing tools
- Map editing tools

### Long Term (Future)
- 100% function documentation
- Complete ROM understanding
- Advanced modding framework
- Educational materials

**See:** [ROADMAP.md](project-management/ROADMAP.md) for detailed plan

## 📝 Recent Updates

### 2025-11-07: Major Project Organization
- ✅ Reorganized documentation into logical subdirectories
- ✅ Created master INDEX.md with complete navigation
- ✅ Documented all 130+ Python tools
- ✅ Documented all 30+ PowerShell scripts
- ✅ Removed 90+ obsolete .bak files
- ✅ Updated README.md and all cross-references

### 2025-11-07: Update #37 - Bank $02 Campaign
- ✅ Documented 183 Bank $02 functions (9 batches)
- ✅ Coverage: 28.5% → 30.5% (+2.0%)
- ✅ Systems: Controller, input, graphics, state management
- ✅ All commits pushed to origin/master

**See:** [CHANGELOG.md](../CHANGELOG.md) for complete history

## 💡 Tips for Success

### For All Contributors
1. **Read the docs** - Start with README and INDEX.md
2. **Ask questions** - Create GitHub issues
3. **Test everything** - Run test suite before committing
4. **Follow standards** - Use format_asm.ps1
5. **Document work** - Update relevant docs

### For Modders
1. Start small - Edit one enemy first
2. Use the GUI - enemy_editor_gui.py is friendly
3. Test in emulator - Verify changes work
4. Save backups - Keep original ROM safe

### For Developers
1. Review existing code first
2. Follow coding standards strictly
3. Add tests for new features
4. Update documentation
5. Commit often with good messages

## 📧 Getting Help

### Documentation
1. Check [INDEX.md](INDEX.md) - Find relevant docs
2. Search [FUNCTION_REFERENCE.md](FUNCTION_REFERENCE.md) - Code reference
3. Review [FAQ](guides/FAQ.md) - Common questions

### Community
1. Create GitHub issue - Technical questions
2. Check Project Board - Current work
3. Review existing issues - May already be answered

### Tools
1. Run with `--help` - Most tools have help
2. Check tool docs - TOOLS_REFERENCE.md
3. Review examples - In documentation

## 🎉 Acknowledgments

### Contributors
- Project maintainers and contributors
- SNES hacking community
- DataCrystal wiki editors

### Tools & Resources
- Diztinguish - Advanced disassembler
- Asar - SNES assembler
- MesenS - SNES emulator
- GameFAQs - Enemy data verification
- SNES development community

### Special Thanks
- Final Fantasy Mystic Quest development team
- ROM hacking community
- All project contributors

---

## 🔗 Quick Links

**Essential:**
- [README.md](../README.md) - Start here
- [INDEX.md](INDEX.md) - Documentation hub
- [CONTRIBUTING.md](../CONTRIBUTING.md) - Contribute

**Documentation:**
- [FUNCTION_REFERENCE.md](FUNCTION_REFERENCE.md) - Code reference
- [TOOLS_REFERENCE.md](TOOLS_REFERENCE.md) - Tool docs
- [POWERSHELL_REFERENCE.md](POWERSHELL_REFERENCE.md) - Script docs

**Guides:**
- [Build Guide](guides/BUILD_GUIDE.md) - Building ROMs
- [Modding Guide](guides/MODDING_QUICK_REFERENCE.md) - Modding
- [Enemy Editor Guide](ENEMY_EDITOR_GUIDE.md) - Enemy editing

**Technical:**
- [Bank Classification](technical/BANK_CLASSIFICATION.md) - ROM structure
- [Battle System](BATTLE_SYSTEM.md) - Game mechanics
- [ROM Data Map](ROM_DATA_MAP.md) - Address map

---

**Happy hacking! 🎮**

*Last updated: 2025-11-07 | Project version: Active Development*
