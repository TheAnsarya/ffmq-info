# Future Roadmap for FFMQ ROM Hacking Toolkit

**Current Status**: Phase 3 Complete ✅  
**Version**: v3.0-phase3-complete  
**Date**: November 2, 2025

---

## Phase 3 Achievements Recap

✅ **Text Editing Pipeline** - Complete (723 entries)  
✅ **Map Editing Pipeline** - Complete (20 maps in Tiled)  
✅ **Graphics Editing Pipeline** - Complete (87 sprites)  
✅ **Build System Integration** - Complete (15+ targets)  
✅ **Comprehensive Documentation** - Complete (2,150+ lines)

**Total Code**: 6,459 insertions across 14 files  
**Status**: Production-ready toolkit ✨

---

## Phase 4: Import Tools for Overworld & Effects

### Priority: High
**Goal**: Complete round-trip for all graphics types

### Tasks

#### 1. Overworld Graphics Import
- [ ] Create `tools/import/import_overworld.py`
- [ ] Support tileset reimport (4 tilesets)
- [ ] Support walking sprite reimport (4 characters)
- [ ] Support object sprite reimport (chests, doors, switches)
- [ ] Support NPC sprite reimport (old man, woman, guard)
- [ ] Validation (dimensions, palette constraints)
- [ ] Add to build_integration.py
- [ ] Add Makefile target: `overworld-rebuild`
- [ ] Documentation: Update or create OVERWORLD_EDITING.md

**Estimated Time**: 6-8 hours  
**Lines of Code**: ~400-500

#### 2. Effects Graphics Import
- [ ] Create `tools/import/import_effects.py`
- [ ] Support spell effect reimport (6 spells)
- [ ] Support attack animation reimport (3 attacks)
- [ ] Support status effect reimport (3 status)
- [ ] Support particle effect reimport (3 particles)
- [ ] RGBA transparency handling
- [ ] Frame animation validation
- [ ] Add to build_integration.py
- [ ] Add Makefile target: `effects-rebuild`
- [ ] Documentation: Create EFFECTS_EDITING.md

**Estimated Time**: 5-7 hours  
**Lines of Code**: ~350-450

---

## Phase 5: Data Table Editing

### Priority: Medium
**Goal**: Edit game stats and mechanics

### Tasks

#### 1. Item Stats Extraction & Import
- [ ] Create `tools/extract_items.py`
- [ ] Extract all item data (HP recovery, attack power, etc.)
- [ ] JSON/CSV format for editing
- [ ] Create `tools/import/import_items.py`
- [ ] Validation (stat ranges)
- [ ] Documentation

**Estimated Time**: 4-6 hours  
**Lines of Code**: ~300-400

#### 2. Spell Stats Extraction & Import
- [ ] Create `tools/extract_spells.py`
- [ ] Extract spell data (damage, MP cost, elements)
- [ ] JSON/CSV format
- [ ] Create `tools/import/import_spells.py`
- [ ] Validation
- [ ] Documentation

**Estimated Time**: 4-6 hours  
**Lines of Code**: ~300-400

#### 3. Enemy Stats Extraction & Import
- [ ] Create `tools/extract_enemies.py`
- [ ] Extract enemy data (HP, attack, defense, drops, exp)
- [ ] JSON/CSV format
- [ ] Create `tools/import/import_enemies.py`
- [ ] Validation (difficulty balance checking)
- [ ] Documentation

**Estimated Time**: 5-7 hours  
**Lines of Code**: ~400-500

---

## Phase 6: Music & Sound

### Priority: Low
**Goal**: Music editing support

### Tasks

#### 1. Enhanced Music Extraction
- [ ] Enhance `tools/extract_music.py`
- [ ] SPC to MIDI conversion
- [ ] Track organization
- [ ] Instrument bank extraction
- [ ] Documentation

**Estimated Time**: 8-10 hours  
**Lines of Code**: ~500-600

#### 2. Music Import
- [ ] Create `tools/import/import_music.py`
- [ ] MIDI to SPC conversion
- [ ] Music testing/validation
- [ ] Integration with build system
- [ ] Documentation

**Estimated Time**: 10-12 hours  
**Lines of Code**: ~600-700

**Note**: Music editing is complex and may require external tools (Addmusic, SPC700)

---

## Phase 7: Advanced Features

### Priority: Future
**Goal**: Advanced modding capabilities

### Tasks

#### 1. Event Script Editor
- [ ] Extract event scripts
- [ ] Visual script editor (GUI?)
- [ ] Script validation
- [ ] Reimport to ROM
- [ ] Documentation

**Estimated Time**: 20-30 hours  
**Lines of Code**: ~1,500-2,000

#### 2. Battle System Modding
- [ ] Damage formula editing
- [ ] Battle mechanics modification
- [ ] AI behavior editing
- [ ] Custom battle features
- [ ] Documentation

**Estimated Time**: 15-20 hours  
**Lines of Code**: ~1,000-1,500

#### 3. World Map Editor
- [ ] Extract overworld map
- [ ] Visual editor for world map
- [ ] Location placement
- [ ] Connection editing
- [ ] Documentation

**Estimated Time**: 12-15 hours  
**Lines of Code**: ~800-1,000

---

## Quick Wins (Near-Term)

### 1. Enhanced Validation
**Time**: 2-3 hours  
**Benefit**: Catch errors before ROM corruption

- [ ] Add comprehensive validation to all import tools
- [ ] Size limit checking
- [ ] Pointer validation
- [ ] Cross-reference validation (e.g., map IDs)

### 2. Batch Operations
**Time**: 3-4 hours  
**Benefit**: Speed up bulk editing

- [ ] Batch text find/replace
- [ ] Batch sprite recoloring
- [ ] Batch map property changes
- [ ] Command-line scripts

### 3. GUI Tools (Optional)
**Time**: 20-30 hours  
**Benefit**: User-friendly interface

- [ ] Text editor GUI (PyQt/Tkinter)
- [ ] Sprite viewer/editor GUI
- [ ] Map editor GUI (alternative to Tiled)
- [ ] Build system GUI

---

## Documentation Improvements

### 1. Video Tutorials
- [ ] Text editing tutorial (YouTube)
- [ ] Map editing tutorial
- [ ] Graphics editing tutorial
- [ ] Complete workflow tutorial

### 2. Example Projects
- [ ] Sample text translation project
- [ ] Sample difficulty hack
- [ ] Sample graphics hack
- [ ] Sample total conversion

### 3. Troubleshooting Database
- [ ] Common error messages
- [ ] Solutions and workarounds
- [ ] FAQ document

---

## Community Features

### 1. Mod Repository
- [ ] Set up mod sharing system
- [ ] Patch format (IPS/BPS)
- [ ] Mod browser/installer
- [ ] Version compatibility

### 2. Collaboration Tools
- [ ] Multi-user editing workflow
- [ ] Change tracking
- [ ] Merge conflict resolution
- [ ] Team project support

### 3. Testing Framework
- [ ] Automated testing scripts
- [ ] ROM verification
- [ ] Regression testing
- [ ] CI/CD integration

---

## Technical Debt & Refactoring

### 1. Code Quality
- [ ] Add comprehensive unit tests
- [ ] Add integration tests
- [ ] Code coverage reporting
- [ ] Performance profiling

### 2. Architecture Improvements
- [ ] Refactor common code into library
- [ ] Plugin system for extractors/importers
- [ ] API for external tools
- [ ] Configuration system

### 3. Cross-Platform Support
- [ ] Test on Linux
- [ ] Test on macOS
- [ ] Platform-specific installers
- [ ] Docker containers

---

## Timeline Estimates

### Near-Term (1-2 months)
- Phase 4: Overworld & Effects Import (11-15 hours)
- Quick Wins: Validation & Batch Operations (5-7 hours)
- **Total**: ~20 hours

### Medium-Term (3-6 months)
- Phase 5: Data Table Editing (13-19 hours)
- Documentation Improvements (10-15 hours)
- **Total**: ~30 hours

### Long-Term (6-12 months)
- Phase 6: Music & Sound (18-22 hours)
- Phase 7: Advanced Features (47-65 hours)
- Community Features (20-30 hours)
- **Total**: ~100 hours

---

## Success Metrics

### Current Metrics (Phase 3)
- ✅ 723 text entries editable
- ✅ 20 maps editable
- ✅ 87 sprites editable
- ✅ 3 comprehensive guides
- ✅ Single-command workflows

### Phase 4 Targets
- 🎯 All graphics editable (tilesets, effects)
- 🎯 Complete graphics pipeline
- 🎯 2 additional guides

### Phase 5 Targets
- 🎯 All game data editable (stats, mechanics)
- 🎯 Balance testing tools
- 🎯 Difficulty hack templates

### Phase 6 Targets
- 🎯 Music editing support
- 🎯 Custom music insertion
- 🎯 Sound effect editing

### Ultimate Goal
- 🎯 Complete disassembly
- 🎯 Full source code recreation
- 🎯 100% moddable game

---

## Contributing

If you want to contribute to future phases:

1. Pick a task from this roadmap
2. Create a feature branch
3. Implement the feature
4. Add documentation
5. Submit for review

**Contact**: See project repository for contribution guidelines

---

## Conclusion

Phase 3 delivered a **production-ready toolkit** that already enables comprehensive ROM hacking. Future phases will expand capabilities, but the current toolkit is fully functional and ready for the modding community.

**Current Status**: ⭐ Professional-grade toolkit achieved!

**Next Priority**: Phase 4 (Overworld & Effects Import) to complete all graphics workflows.

---

*Last Updated: November 2, 2025*  
*Current Version: v3.0-phase3-complete*  
*Status: Phase 3 Complete, Phase 4 Planned*
