# FFMQ Python Tools Documentation

> **Last Updated:** 2025-11-07  
> **Total Scripts:** 130+ Python files  
> **Categories:** 12 major categories

This document provides a comprehensive reference for all Python scripts in the tools directory.

## 📖 Quick Navigation

- [Battle Data Tools](#battle-data-tools) - Enemy editing, stats, attacks
- [Build Tools](#build-tools) - ROM building, comparison, verification
- [Extraction Tools](#extraction-tools) - Extract data from ROM
- [Graphics Tools](#graphics-tools) - Graphics conversion, palettes, tiles
- [Analysis Tools](#analysis-tools) - Code analysis, spell research
- [Testing Tools](#testing-tools) - Test framework, verification
- [Tracking Tools](#tracking-tools) - Project tracking, logging
- [Conversion Tools](#conversion-tools) - Format conversion
- [Validation Tools](#validation-tools) - Data validation
- [Import Tools](#import-tools) - Import external data
- [Visualization Tools](#visualization-tools) - Data visualization
- [GitHub Tools](#github-tools) - Issue management (PowerShell)

---

## ⚔️ Battle Data Tools

Tools for editing and managing battle-related data.

### enemy_editor_gui.py ⭐
**Purpose:** Visual GUI editor for all 83 enemies  
**Usage:** `python tools/enemy_editor_gui.py` or `enemy_editor.bat`  
**Features:**
- Visual editing with sliders/spinboxes
- Element resistance/weakness editor
- Undo/redo support (Ctrl+Z/Y)
- GameFAQs validation
- Search and filtering
- JSON export for build integration

**Documentation:** [docs/ENEMY_EDITOR_GUIDE.md](../docs/ENEMY_EDITOR_GUIDE.md)

### view_enemy.py
**Purpose:** Command-line enemy stats viewer  
**Usage:**
```bash
python tools/view_enemy.py Brownie          # View specific enemy
python tools/view_enemy.py --list           # List all enemies
python tools/view_enemy.py --search slime   # Search enemies
python tools/view_enemy.py 0 --brief        # Brief output
```

### generate_attack_table.py
**Purpose:** Generate attack data tables from enemy JSON  
**Usage:** `python tools/generate_attack_table.py`

### analyze_spell_flags.py
**Purpose:** Analyze spell flag patterns  
**Usage:** `python tools/analyze_spell_flags.py`

### analyze_spell_structure.py
**Purpose:** Analyze spell data structure  
**Usage:** `python tools/analyze_spell_structure.py`

### analyze_spell_unknown_bytes.py
**Purpose:** Research unknown bytes in spell data  
**Usage:** `python tools/analyze_spell_unknown_bytes.py`

### find_spell_data.py
**Purpose:** Locate spell data in ROM  
**Usage:** `python tools/find_spell_data.py`

### spell_research_report.py
**Purpose:** Generate comprehensive spell research report  
**Usage:** `python tools/spell_research_report.py`

### test_spell_learning_hypothesis.py
**Purpose:** Test spell learning mechanics hypotheses  
**Usage:** `python tools/test_spell_learning_hypothesis.py`

---

## 🔨 Build Tools

ROM building, comparison, and verification tools.

### build_rom.py
**Purpose:** Main ROM build script  
**Usage:** `python tools/build_rom.py`  
**Features:**
- Assembles ROM from ASM sources
- Validates build output
- Generates symbol files

### build_and_compare.py
**Purpose:** Build ROM and compare with original  
**Usage:** `python tools/build_and_compare.py`  
**Features:**
- Automated build workflow
- Byte-by-byte comparison
- Difference reporting

### compare_roms.py
**Purpose:** Compare two ROM files  
**Usage:**
```bash
python tools/compare_roms.py rom1.sfc rom2.sfc
python tools/compare_roms.py rom1.sfc rom2.sfc --verbose
python tools/compare_roms.py rom1.sfc rom2.sfc --output diff.txt
```

### build_integration.py
**Purpose:** Integrate battle data into build process  
**Usage:** `python tools/build_integration.py`

### build_integration_helper.py
**Purpose:** Helper functions for build integration  
**Library:** Imported by build_integration.py

### build_asm_from_json.py
**Purpose:** Generate ASM files from JSON data  
**Usage:** `python tools/build_asm_from_json.py`

### verify_build_integration.py
**Purpose:** Verify battle data integration in ROM  
**Usage:** `python tools/verify_build_integration.py`  
**Features:**
- Reads enemy data from built ROM
- Compares with source JSON
- Validates LoROM addressing

### quick_verify.py
**Purpose:** Quick verification of ROM build  
**Usage:** `python tools/quick_verify.py`

### verify_roundtrip.py
**Purpose:** Verify roundtrip build produces identical ROM  
**Usage:** `python tools/verify_roundtrip.py`

### rom_integrity.py
**Purpose:** Check ROM integrity and structure  
**Usage:** `python tools/rom_integrity.py rom.sfc`

---

## 📦 Extraction Tools

Extract various data types from ROM.

### extract_all_assets.py
**Purpose:** Master extraction script for all assets  
**Usage:** `python tools/extract_all_assets.py rom.sfc`

### extract_data.py
**Purpose:** Generic data extraction  
**Usage:** `python tools/extract_data.py`

### extract_graphics.py
**Purpose:** Extract graphics data from ROM  
**Usage:** `python tools/extract_graphics.py rom.sfc`

### extract_graphics_v2.py ⭐
**Purpose:** Enhanced graphics extraction with PNG conversion  
**Usage:**
```bash
python tools/extract_graphics_v2.py rom.sfc
python tools/extract_graphics_v2.py rom.sfc --output assets/
```

### extract_palettes.py
**Purpose:** Extract color palettes  
**Usage:** `python tools/extract_palettes.py rom.sfc`

### extract_text.py
**Purpose:** Extract text strings from ROM  
**Usage:** `python tools/extract_text.py rom.sfc`

### extract_text_enhanced.py
**Purpose:** Enhanced text extraction with DTE support  
**Usage:** `python tools/extract_text_enhanced.py rom.sfc`

### extract_music.py
**Purpose:** Extract music data  
**Usage:** `python tools/extract_music.py rom.sfc`

### extract_effects.py
**Purpose:** Extract special effects data  
**Usage:** `python tools/extract_effects.py`

### extract_maps_enhanced.py
**Purpose:** Extract map and tilemap data  
**Usage:** `python tools/extract_maps_enhanced.py rom.sfc`

### extract_overworld.py
**Purpose:** Extract overworld map data  
**Usage:** `python tools/extract_overworld.py rom.sfc`

### extract_bank06_data.py
**Purpose:** Extract Bank $06 data structures  
**Usage:** `python tools/extract_bank06_data.py`

### extract_bank08_data.py
**Purpose:** Extract Bank $08 data structures  
**Usage:** `python tools/extract_bank08_data.py`

### track_extraction.py
**Purpose:** Track data extraction progress  
**Usage:** `python tools/track_extraction.py`

---

## 🎨 Graphics Tools

Graphics format conversion and palette management.

### snes_graphics.py ⭐
**Purpose:** Core SNES graphics codec library (450+ lines)  
**Library:** Imported by other graphics tools  
**Features:**
- 2bpp/4bpp tile encoding/decoding
- 15-bit RGB555 palette conversion
- Raw binary ↔ PNG conversion
- Tile organization (8×8 pixels)

### convert_graphics.py ⭐
**Purpose:** Convert between PNG and SNES formats (440+ lines)  
**Usage:**
```bash
# PNG to SNES
python tools/convert_graphics.py to-snes input.png output.bin --format 4bpp

# SNES to PNG
python tools/convert_graphics.py to-png input.bin output.png --format 4bpp --palette palette.bin

# Batch conversion
python tools/convert_graphics.py batch assets/graphics/
```

### graphics_converter.py
**Purpose:** Alternative graphics converter  
**Usage:** `python tools/graphics_converter.py`

### palette_manager.py
**Purpose:** Palette editing and management  
**Usage:** `python tools/palette_manager.py`

### inventory_graphics.py
**Purpose:** Catalog all graphics in ROM  
**Usage:** `python tools/inventory_graphics.py rom.sfc`

### generate_graphics_asm.py
**Purpose:** Generate ASM includes for graphics data  
**Usage:** `python tools/generate_graphics_asm.py`

### generate_bank06_metatiles.py
**Purpose:** Generate Bank $06 metatile definitions  
**Usage:** `python tools/generate_bank06_metatiles.py`

---

## 🔬 Analysis Tools

Code analysis and research tools.

### code_label_analyzer.py
**Purpose:** Analyze label usage in code  
**Usage:** `python tools/code_label_analyzer.py`

### analyze_doc_coverage.py
**Purpose:** Analyze documentation coverage  
**Usage:** `python tools/analyze_doc_coverage.py`

### doc_coverage_analyzer.py
**Purpose:** Detailed doc coverage analysis  
**Usage:** `python tools/doc_coverage_analyzer.py`

### analyze_project_priorities.py
**Purpose:** Analyze project task priorities  
**Usage:** `python tools/analyze_project_priorities.py`

---

## ✅ Testing Tools

Testing framework and verification.

### run_tests.py ⭐
**Purpose:** Run individual test files  
**Usage:**
```bash
python tools/run_tests.py tests/test_enemies.py
python tools/run_tests.py tests/test_pipeline.py
python tools/run_tests.py tests/ --verbose
```

### run_all_tests.py ⭐
**Purpose:** Master test runner for entire suite  
**Usage:**
```bash
python tools/run_all_tests.py
python tools/run_all_tests.py --verbose
python tools/run_all_tests.py --coverage
```

### test_pipeline.py
**Purpose:** Test battle data pipeline  
**Usage:** `python tools/test_pipeline.py`

### test_graphics_pipeline.py
**Purpose:** Test graphics pipeline  
**Usage:** `python tools/test_graphics_pipeline.py`

### verify_addresses.py
**Purpose:** Verify ROM address mappings  
**Usage:** `python tools/verify_addresses.py`

### verify_gamefaqs_data.py
**Purpose:** Verify enemy data against GameFAQs  
**Usage:** `python tools/verify_gamefaqs_data.py`

### verify_spell_data.py
**Purpose:** Verify spell data integrity  
**Usage:** `python tools/verify_spell_data.py`

### check_rom_data.py
**Purpose:** Check ROM data consistency  
**Usage:** `python tools/check_rom_data.py rom.sfc`

---

## 📊 Tracking Tools

Project progress tracking and logging.

### update_chat_log.py ⭐
**Purpose:** Update session chat logs  
**Usage:**
```bash
python tools/update_chat_log.py --change "Description"
python tools/update_chat_log.py --question "Question text"
python tools/update_chat_log.py --note "Note text"
python tools/update_chat_log.py --summary
```

**VS Code Tasks:**
- 📊 View Chat Log Summary
- 🔄 Quick Log Change
- ❓ Quick Log Question
- 💭 Quick Log Note

### disassembly_tracker.py
**Purpose:** Track disassembly progress  
**Usage:** `python tools/disassembly_tracker.py`

### project_status.py
**Purpose:** Generate project status report  
**Usage:** `python tools/project_status.py`

### auto_tracker.py
**Purpose:** Automatic change tracking (background)  
**Usage:** Run via `start-tracking.ps1`

---

## 🔄 Conversion Tools

Format conversion utilities.

### conversion/ directory
Collection of specialized conversion tools.

### convert_diztinguish.py
**Purpose:** Convert Diztinguish output to ASM  
**Usage:** `python tools/convert_diztinguish.py input.asm output.asm`

### normalize_case.py
**Purpose:** Normalize ASM case conventions  
**Usage:** `python tools/normalize_case.py file.asm`

### normalize_case_original.py
**Purpose:** Original case normalization (preserved)  
**Usage:** `python tools/normalize_case_original.py file.asm`

### normalize_indentation.py
**Purpose:** Fix ASM indentation  
**Usage:** `python tools/normalize_indentation.py file.asm`

### normalize_spacing.py
**Purpose:** Normalize spacing in ASM  
**Usage:** `python tools/normalize_spacing.py file.asm`

### fix_windows_encoding.py
**Purpose:** Fix Windows encoding issues  
**Usage:** `python tools/fix_windows_encoding.py file.asm`

### fix_duplicate_labels.py
**Purpose:** Remove duplicate label definitions  
**Usage:** `python tools/fix_duplicate_labels.py file.asm`

---

## 🔍 Validation Tools

Data validation and verification.

### validation/ directory
Collection of validation scripts.

---

## 📥 Import Tools

Import external data sources.

### import/ directory
Tools for importing reference data.

### import_data.py
**Purpose:** Import generic data  
**Usage:** `python tools/import_data.py`

### import_graphics.py
**Purpose:** Import graphics from external sources  
**Usage:** `python tools/import_graphics.py`

---

## 📈 Visualization Tools

Data visualization and reporting.

### visualization/ directory
Visualization scripts.

### visualize_elements.py
**Purpose:** Visualize element resistance matrix  
**Usage:** `python tools/visualization/visualize_elements.py`

### visualize_enemy_attacks.py
**Purpose:** Visualize enemy attack patterns  
**Usage:** `python tools/visualization/visualize_enemy_attacks.py`

### visualize_spell_effectiveness.py
**Purpose:** Visualize spell effectiveness data  
**Usage:** `python tools/visualization/visualize_spell_effectiveness.py`

---

## 🐙 GitHub Integration Tools (PowerShell)

GitHub issue and project management (PowerShell scripts).

### create_github_issues.ps1
**Purpose:** Create GitHub issues from templates  
**Usage:** `.\tools\create_github_issues.ps1`

### create_github_sub_issues.ps1
**Purpose:** Create sub-issues for epics  
**Usage:** `.\tools\create_github_sub_issues.ps1`

### create_github_granular_issues.ps1
**Purpose:** Create granular task issues  
**Usage:** `.\tools\create_github_granular_issues.ps1`

### add_children_to_parent_checklists.ps1
**Purpose:** Add child issue checklists to parents  
**Usage:** `.\tools\add_children_to_parent_checklists.ps1`

### add_tasks_to_child_issues.ps1
**Purpose:** Add task lists to child issues  
**Usage:** `.\tools\add_tasks_to_child_issues.ps1`

### link_child_issues_to_parents.ps1
**Purpose:** Link child issues to parent epics  
**Usage:** `.\tools\link_child_issues_to_parents.ps1`

### setup_project_board.ps1
**Purpose:** Set up GitHub project board  
**Usage:** `.\tools\setup_project_board.ps1`

### apply_labels.ps1
**Purpose:** Apply labels to GitHub issues  
**Usage:** `.\tools\apply_labels.ps1`

---

## 🛠️ Utility Scripts

### ffmq_compression.py
**Purpose:** SNES compression/decompression library  
**Library:** Compression codec

### ffmq_data_structures.py
**Purpose:** Data structure definitions  
**Library:** Imported by various tools

### rom_extractor.py
**Purpose:** Extract specific ROM regions  
**Usage:** `python tools/rom_extractor.py rom.sfc offset length`

### rom_compare.py
**Purpose:** Advanced ROM comparison  
**Usage:** `python tools/rom_compare.py rom1.sfc rom2.sfc`

### rom_diff.py
**Purpose:** Generate ROM diff reports  
**Usage:** `python tools/rom_diff.py rom1.sfc rom2.sfc`

### rom_tester.py
**Purpose:** ROM testing utilities  
**Usage:** `python tools/rom_tester.py rom.sfc`

### setup_rom.py
**Purpose:** Initial ROM setup and validation  
**Usage:** `python tools/setup_rom.py rom.sfc`

### mesen_integration.py
**Purpose:** MesenS emulator integration  
**Usage:** `python tools/mesen_integration.py`

---

## 📂 Asset Tools

Tools in subdirectories.

### tools/assets/
Asset-specific tools and data files.

### tools/conversion/
Format conversion utilities.

### tools/extraction/
Specialized extraction tools.

### tools/import/
Import tool collection.

### tools/injection/
Data injection tools.

### tools/mods/
Modding utilities.

### tools/validation/
Validation script collection.

### tools/visualization/
Visualization tools.

---

## 🔧 Build System Integration Tools

### Build-System.ps1
**Purpose:** PowerShell build system orchestrator  
**Usage:** `.\tools\Build-System.ps1`

### Build-Validator.ps1
**Purpose:** Validate build output  
**Usage:** `.\tools\Build-Validator.ps1`

### Build-Watch.ps1
**Purpose:** Watch files and rebuild automatically  
**Usage:** `.\tools\Build-Watch.ps1`

### dev-watch.ps1
**Purpose:** Development file watcher  
**Usage:** `.\tools\dev-watch.ps1`

---

## 🗂️ Disassembly Tools

### Aggressive-Disassemble.ps1
**Purpose:** Aggressive disassembly script  
**Usage:** `.\tools\Aggressive-Disassemble.ps1`

### Import-Reference-Disassembly.ps1
**Purpose:** Import reference disassembly  
**Usage:** `.\tools\Import-Reference-Disassembly.ps1`

### mass_disassemble.py
**Purpose:** Batch disassembly processing  
**Usage:** `python tools/mass_disassemble.py`

---

## 📋 Formatting & Standards Tools

### format_asm.ps1 ⭐
**Purpose:** Format ASM files to coding standards  
**Usage:**
```powershell
.\tools\format_asm.ps1 -Path file.asm              # Format file
.\tools\format_asm.ps1 -Path file.asm -DryRun      # Preview changes
```

**VS Code Tasks:**
- ✨ Format ASM File
- 🔍 Verify ASM Formatting

### fix_indentation.ps1
**Purpose:** Fix ASM indentation issues  
**Usage:** `.\tools\fix_indentation.ps1 file.asm`

### test_format_validation.ps1
**Purpose:** Test formatting validation  
**Usage:** `.\tools\test_format_validation.ps1`

### standardize_registers.ps1
**Purpose:** Standardize register naming  
**Usage:** `.\tools\standardize_registers.ps1`

### convert_to_lowercase.ps1
**Purpose:** Convert labels to lowercase  
**Usage:** `.\tools\convert_to_lowercase.ps1`

### rename_instruction_labels.ps1
**Purpose:** Rename instruction labels  
**Usage:** `.\tools\rename_instruction_labels.ps1`

---

## 📝 Data Cataloging Tools

### scan_addresses.ps1
**Purpose:** Scan for raw memory addresses  
**Usage:** `.\tools\scan_addresses.ps1`  
**Output:** Reports all raw $XXXX addresses in ASM files

### catalog_rom_data.ps1
**Purpose:** Catalog DATA8/DATA16/ADDR labels  
**Usage:** `.\tools\catalog_rom_data.ps1`  
**Output:** Complete catalog of data labels

---

## 🎯 Dependencies

### Core Libraries

**Python Standard Library:**
- `json`, `struct`, `os`, `sys`, `argparse`, `pathlib`

**External Libraries (requirements.txt):**
- `Pillow` (PIL) - Image processing for graphics tools
- `tkinter` - GUI framework (usually included with Python)

### Installation

```bash
# Install Python dependencies
pip install -r requirements.txt

# Or manually
pip install Pillow
```

---

## 📖 Usage Patterns

### Common Workflows

**Battle Data Modding:**
```bash
# 1. Edit enemies visually
python tools/enemy_editor_gui.py

# 2. Or view stats
python tools/view_enemy.py Brownie

# 3. Build ROM with changes
python tools/build_rom.py

# 4. Verify integration
python tools/verify_build_integration.py
```

**Graphics Extraction:**
```bash
# 1. Extract all graphics
python tools/extract_graphics_v2.py rom.sfc

# 2. Convert specific graphic
python tools/convert_graphics.py to-png input.bin output.png --format 4bpp

# 3. Edit in external program (Photoshop, GIMP, etc.)

# 4. Convert back
python tools/convert_graphics.py to-snes output.png input.bin --format 4bpp
```

**Testing:**
```bash
# Run all tests
python tools/run_all_tests.py

# Run specific test
python tools/run_tests.py tests/test_enemies.py

# With coverage
python tools/run_all_tests.py --coverage
```

**Build Workflow:**
```bash
# Quick build
python tools/build_rom.py

# Build and compare
python tools/build_and_compare.py

# Full verification
python tools/verify_roundtrip.py
```

---

## 🔗 Related Documentation

- **[Enemy Editor Guide](../docs/ENEMY_EDITOR_GUIDE.md)** - Complete GUI tutorial
- **[Battle Data Pipeline](../docs/BATTLE_DATA_PIPELINE.md)** - Data workflow
- **[Graphics Quickstart](../docs/graphics-quickstart.md)** - Graphics tools guide
- **[Build Guide](../docs/guides/BUILD_GUIDE.md)** - Build system documentation
- **[Testing Framework](../docs/TESTING_FRAMEWORK.md)** - Testing documentation

---

## 💡 Contributing

When adding new tools:

1. Add proper docstrings to functions
2. Update this documentation
3. Add usage examples
4. Update requirements.txt if adding dependencies
5. Add tests if applicable
6. Document in relevant guides

---

## 📧 Questions?

If you need help with a specific tool:

1. Check the tool's docstrings (`python tools/script.py --help`)
2. Review related documentation
3. Check examples in this file
4. Create a GitHub issue

---

**Happy modding! 🎮**
