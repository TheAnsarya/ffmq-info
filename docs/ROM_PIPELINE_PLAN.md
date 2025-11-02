# ROM Data Pipeline - Complete Implementation Plan

**Created:** November 1, 2025  
**Status:** Planning Phase  
**Project:** https://github.com/users/TheAnsarya/projects/3

## Overview

This document outlines the complete implementation plan for establishing a bidirectional ROM data pipeline that supports both extraction and rebuilding of FFMQ ROM data.

## Current State Analysis

### ✅ What We Have
1. **Extraction Tools (Partial)**
   - `extract_enemies.py` - 83 enemies ✅
   - `extract_attacks.py` - 169 attacks ✅
   - `extract_spells.py` - 16 spells ✅
   - `extract_characters.py` - Character data
   - `extract_text.py` - Text extraction
   - `extract_palettes_sprites.py` - Graphics extraction (partial)
   - `extract_maps.py` - Map data extraction

2. **ROM Configuration**
   - V1.1 ROM verified: `Final Fantasy - Mystic Quest (U) (V1.1).sfc`
   - MD5: `f7faeae5a847c098d677070920769ca2`
   - Build config: `build.config.json`

3. **Data Output**
   - CSV files in `data/extracted/`
   - JSON files with metadata
   - Some schema definitions in `data/schemas/`

### ❌ What's Missing

1. **Address Verification**
   - No systematic verification of ROM addresses against V1.1
   - Extraction scripts hardcode addresses without validation
   - No cross-reference with disassembly labels

2. **Binary Data Layer**
   - No `bin/` intermediate format
   - No binary serialization/deserialization
   - Extraction goes directly ROM → JSON/CSV

3. **Import/Rebuild Tools**
   - No tools to convert extracted data back to ROM format
   - No repackaging of edited JSON/CSV → binary
   - No integration with build system

4. **Build Process Integration**
   - Build doesn't use extracted data
   - No automatic data → .dat file generation
   - No include mechanisms for data files in assembly

5. **Disassembly Integration**
   - ROM addresses not cross-referenced with disassembly labels
   - No label extraction from `~historical/diztinguish-disassembly/`
   - Address constants hardcoded instead of using labels

## Pipeline Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        ROM DATA PIPELINE                            │
└─────────────────────────────────────────────────────────────────────┘

EXTRACTION PATH (Original ROM → Extracted Data)
─────────────────────────────────────────────────

  ┌──────────────┐
  │ Original ROM │  Final Fantasy - Mystic Quest (U) (V1.1).sfc
  │  (V1.1 SFC)  │  MD5: f7faeae5a847c098d677070920769ca2
  └──────┬───────┘
         │
         ▼
  ┌──────────────────┐
  │ Address Verify   │  Validate ROM addresses against:
  │ & Label Mapping  │  - Disassembly labels (.asm files)
  │                  │  - External references (FFMQRando)
  └──────┬───────────┘  - Known data structures
         │
         ▼
  ┌──────────────────┐
  │ Binary Extract   │  ROM bytes → binary data files
  │ (ROM → .bin)     │  Output: data/binary/*.bin
  └──────┬───────────┘
         │
         ├──────────────────┬──────────────────┬────────────────┐
         ▼                  ▼                  ▼                ▼
  ┌────────────┐     ┌────────────┐    ┌────────────┐  ┌────────────┐
  │ Graphics   │     │ Data       │    │ Text       │  │ Audio      │
  │ Decode     │     │ Decode     │    │ Decode     │  │ Decode     │
  │            │     │            │    │            │  │            │
  │ .bin→.png  │     │ .bin→.json │    │ .bin→.txt  │  │ .bin→.spc  │
  │      .chr  │     │      .csv  │    │            │  │            │
  └────────────┘     └────────────┘    └────────────┘  └────────────┘
         │                  │                  │                │
         └──────────────────┴──────────────────┴────────────────┘
                                   │
                                   ▼
                        ┌────────────────────┐
                        │ Extracted Assets   │
                        │  assets/graphics/  │
                        │  data/extracted/   │
                        │  assets/text/      │
                        │  assets/music/     │
                        └────────────────────┘

REBUILD PATH (Extracted Data → Built ROM)
──────────────────────────────────────────

  ┌────────────────────┐
  │ Modified Assets    │  User edits extracted files
  │  (JSON/PNG/TXT)    │  - Change enemy stats in JSON
  └──────┬─────────────┘  - Edit sprites in PNG
         │                - Modify text strings
         ▼
  ┌──────────────────┐
  │ Encode & Validate│  Convert back to binary format
  │ (JSON → .bin)    │  - JSON → binary data
  │ (PNG → .chr)     │  - PNG → CHR tiles
  │ (TXT → .bin)     │  - Text → encoded bytes
  └──────┬───────────┘
         │
         ▼
  ┌──────────────────┐
  │ Binary Data      │  Validated binary files
  │ (.bin/.chr/.dat) │  Output: src/data/*.dat
  └──────┬───────────┘          build/binary/*.bin
         │
         ▼
  ┌──────────────────┐
  │ Assembly Build   │  asar assembles main ROM
  │ (Include .dat)   │  - Includes binary data files
  │                  │  - Preserves original structure
  └──────┬───────────┘  - Links all components
         │
         ▼
  ┌──────────────────┐
  │ Built ROM        │  build/ffmq-rebuilt.sfc
  │ (Output SFC)     │  
  └──────┬───────────┘
         │
         ▼
  ┌──────────────────┐
  │ Verification     │  Compare against original
  │ & Testing        │  - Byte-level diff
  │                  │  - Emulator test
  └──────────────────┘  - Checksum validation
```

## Implementation Phases

### Phase 1: Address Verification & Disassembly Integration (HIGH PRIORITY)

**Issues to Create:**
1. **Verify all ROM data addresses against V1.1 reference**
   - Cross-check all extraction script addresses
   - Validate against FFMQ Randomizer addresses
   - Document any discrepancies
   - Create address validation utility

2. **Extract and map disassembly labels to ROM addresses**
   - Parse `~historical/diztinguish-disassembly/` labels
   - Create label → address mapping database
   - Generate constants file for extraction scripts
   - Replace hardcoded addresses with label references

3. **Create ROM structure documentation**
   - Document all known data structures
   - Map bank organization
   - Identify code vs data regions
   - Create memory map reference

### Phase 2: Binary Data Layer (HIGH PRIORITY)

**Issues to Create:**
4. **Implement binary extraction layer**
   - Create `tools/binary/extract_binary.py`
   - Extract ROM regions to `data/binary/*.bin`
   - Preserve exact byte sequences
   - Add checksums and validation

5. **Implement binary import layer**
   - Create `tools/binary/import_binary.py`
   - Convert `.bin` files back to ROM-ready format
   - Validate data integrity
   - Handle compression/encoding

### Phase 3: Data Format Converters (MEDIUM PRIORITY)

**Issues to Create:**
6. **Create data encoder/decoder tools**
   - `bin_to_json.py` - Binary → JSON conversion
   - `json_to_bin.py` - JSON → Binary conversion
   - Support all data types (enemies, attacks, spells, etc.)
   - Validate against schemas

7. **Create graphics encoder/decoder tools**
   - `chr_to_png.py` - CHR tiles → PNG
   - `png_to_chr.py` - PNG → CHR tiles
   - Palette handling
   - Compression support

8. **Create text encoder/decoder tools**
   - `text_extract.py` - Binary → readable text
   - `text_encode.py` - Text → binary format
   - Handle character table encoding
   - Support text compression

### Phase 4: Build System Integration (MEDIUM PRIORITY)

**Issues to Create:**
9. **Integrate extracted data into build process**
   - Modify `build.ps1` to include data pipeline
   - Auto-generate `.dat` files from extracted data
   - Update assembly includes
   - Add pre-build data processing

10. **Create data packaging system**
    - Package binary data for ROM inclusion
    - Generate `.incbin` directives
    - Organize `src/data/` structure
    - Automate data file generation

11. **Add build verification step**
    - Compare built ROM against original
    - Validate data integrity
    - Report discrepancies
    - Automated testing

### Phase 5: Complete Pipeline Automation (LOW PRIORITY)

**Issues to Create:**
12. **Create master extraction script**
    - One-command full ROM extraction
    - Parallel processing
    - Progress reporting
    - Error handling and logging

13. **Create master rebuild script**
    - One-command full ROM rebuild
    - Validate all inputs
    - Generate all intermediate files
    - Final ROM assembly

14. **Add continuous integration testing**
    - Automated pipeline testing
    - ROM verification
    - Regression testing
    - Build artifact generation

## Directory Structure

```
ffmq-info/
├── data/
│   ├── binary/              # NEW: Raw binary extracts
│   │   ├── enemies.bin
│   │   ├── attacks.bin
│   │   ├── spells.bin
│   │   └── ...
│   ├── extracted/           # EXISTING: Human-readable data
│   │   ├── enemies/
│   │   ├── attacks/
│   │   └── spells/
│   └── schemas/             # EXISTING: JSON schemas
│
├── src/
│   └── data/                # NEW: ROM-ready binary data
│       ├── enemies.dat
│       ├── attacks.dat
│       └── spells.dat
│
├── tools/
│   ├── binary/              # NEW: Binary layer tools
│   │   ├── extract_binary.py
│   │   ├── import_binary.py
│   │   └── validate_binary.py
│   ├── converters/          # NEW: Format converters
│   │   ├── bin_to_json.py
│   │   ├── json_to_bin.py
│   │   ├── chr_to_png.py
│   │   └── png_to_chr.py
│   ├── extraction/          # EXISTING: Enhanced
│   │   └── [uses binary layer]
│   └── disassembly/         # NEW: Disassembly integration
│       ├── extract_labels.py
│       ├── generate_constants.py
│       └── verify_addresses.py
│
└── build/
    └── binary/              # NEW: Build intermediate files
        └── *.bin
```

## Dependencies & Prerequisites

### Required Tools
- ✅ Python 3.8+ (already have)
- ✅ asar 1.90+ (already configured)
- ⚠️ Pillow (for graphics) - verify installed
- ⚠️ numpy (for data processing) - verify installed

### Required Data
- ✅ V1.1 ROM: `Final Fantasy - Mystic Quest (U) (V1.1).sfc`
- ✅ Diztinguish disassembly: `~historical/diztinguish-disassembly/`
- ✅ FFMQ Randomizer reference: documented in `EXTERNAL_REFERENCES.md`

## Success Criteria

### Phase 1 Complete When:
- [ ] All extraction script addresses verified against V1.1
- [ ] Disassembly labels mapped to addresses
- [ ] Address constants file generated
- [ ] ROM structure fully documented

### Phase 2 Complete When:
- [ ] Binary extraction working for all data types
- [ ] Binary import working for all data types
- [ ] Checksums validate successfully
- [ ] Round-trip binary conversion preserves data

### Phase 3 Complete When:
- [ ] All data converters implemented
- [ ] Graphics conversion bidirectional
- [ ] Text encoding/decoding working
- [ ] Schema validation integrated

### Phase 4 Complete When:
- [ ] Build system uses extracted data
- [ ] .dat files auto-generated
- [ ] Built ROM matches original (for unmodified data)
- [ ] Build verification passes

### Phase 5 Complete When:
- [ ] Full extraction automated
- [ ] Full rebuild automated
- [ ] CI/CD pipeline running
- [ ] All tests passing

## Timeline Estimates

- **Phase 1:** 8-12 hours (critical path)
- **Phase 2:** 6-8 hours
- **Phase 3:** 12-16 hours (parallelizable)
- **Phase 4:** 6-10 hours
- **Phase 5:** 4-6 hours

**Total:** ~36-52 hours of development work

## Notes

- Focus on Phase 1 first - address verification is critical
- Phase 2 and 3 can be developed in parallel for different data types
- Build integration (Phase 4) depends on Phases 1-3
- Keep existing extraction tools working during migration
- Add deprecation warnings to old scripts as new pipeline comes online

