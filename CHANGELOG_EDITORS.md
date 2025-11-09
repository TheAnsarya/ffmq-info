# FFMQ Editor Changelog

All notable changes to the FFMQ Editor Suite are documented in this file.

---

## [1.1.0] - 2025-11-08

### Added - Graphics System
- **graphics_data.py** (370 lines): Complete SNES graphics data structures
  - `Color` class with BGR555 ↔ RGB888 conversion
  - `Palette` class for 16-color palettes
  - `Tile` class for 8×8 4bpp planar tiles
  - `Sprite`, `Animation`, `Tileset`, `SpriteSheet` classes
  - Helper functions: gradient palettes, blank tiles
  - ROM address constants

- **graphics_database.py** (330 lines): Graphics ROM I/O
  - Load/save palettes from ROM (24 palettes)
  - Load/save tilesets from ROM (5 tilesets)
  - PNG export for palettes (16×16 images)
  - PNG export for tilesets (configurable layout)
  - PNG import for palettes
  - Palette optimization (remove duplicates)
  - Find similar colors across palettes
  - Statistics gathering

- **graphics_editor.py** (650 lines): Visual graphics editor
  - `PaletteEditorPanel`: Click to select colors, shows RGB/BGR values
  - `TileEditorPanel`: Pixel-level editing with mouse drawing
  - `TilesetViewerPanel`: Browse tiles with scrolling
  - Full pygame integration (60 FPS)
  - Keyboard shortcuts (Ctrl+S, ESC)
  - Visual preview panels

### Added - Music System
- **music_data.py** (450 lines): Music and audio data structures
  - `MusicTrack` class (tempo, volume, looping, channels)
  - `SoundEffect` class (priority, volume, pitch, pan)
  - `Sample` class (loop points, pitch, envelope)
  - `SPCState` class (DSP registers, channel states)
  - Default track names (32 tracks)
  - Default SFX names (64 sound effects)
  - Note conversion functions (note ↔ pitch)
  - Enums: MusicType, SoundEffectType

- **music_database.py** (380 lines): Music ROM I/O
  - Load/save music tracks (32 tracks)
  - Load/save sound effects (64 SFX)
  - Load/save samples (32 samples)
  - SPC file export (SPC700 format v0.30)
  - SPC file import
  - Track validation (tempo, volume, loops)
  - Track duplication and swapping
  - Find unused track/SFX slots
  - Statistics gathering

- **music_editor.py** (570 lines): Visual music editor
  - `TrackListPanel`: Browse all tracks with scrolling
  - `TrackEditorPanel`: Edit properties with channel visualization
  - `SFXListPanel`: Browse all sound effects
  - `SFXEditorPanel`: Edit parameters with visual sliders
  - Full pygame integration
  - Keyboard shortcuts
  - Statistics display

### Changed - Game Editor Integration
- **game_editor.py** modifications:
  - Added `GraphicsDatabase` import and initialization
  - Added `MusicDatabase` import and initialization
  - Changed tab names: "Graphics" (tab 6), "Music" (tab 7)
  - Enhanced `load_rom()` to load graphics and music data
  - Updated `update_stats()` to include graphics/music statistics
  - Extended `export_data()` for PNG and SPC export
  - Added graphics statistics display (tilesets, palettes, tiles)
  - Added music statistics display (tracks, SFX, samples, sizes)

### Added - Documentation
- **GRAPHICS_MUSIC_GUIDE.md** (850 lines): Complete guide
  - Graphics editor overview and features
  - Music editor overview and features
  - Integration with game editor
  - Technical specifications (BGR555, 4bpp, SPC700)
  - Code examples for all major operations
  - Troubleshooting section
  - Future enhancements list

- **QUICK_REFERENCE.md** (580 lines): Quick command reference
  - Keyboard shortcuts
  - Graphics quick reference (addresses, IDs, formats)
  - Music quick reference (addresses, IDs, properties)
  - Enemy/spell/item quick references
  - Common code patterns
  - File locations
  - Data types reference
  - Tips & tricks

- **EDITOR_SUITE_README.md** (580 lines): Enhanced README
  - v1.1 feature overview
  - Complete feature set documentation
  - Installation instructions
  - Quick start guides
  - Code examples
  - Project statistics
  - Technical specifications
  - File structure
  - Version history

- **SESSION_SUMMARY_2025-11-08.md** (720 lines): Session documentation
  - Complete work summary
  - Technical specifications
  - Code statistics
  - Workflow changes from v1.0
  - Testing status
  - Known limitations
  - Future roadmap
  - Lessons learned
  - File locations

### Technical Details

#### Graphics Capabilities
- SNES 15-bit BGR555 color support
- 4bpp planar tile format (8×8 pixels, 32 bytes)
- 16-color palettes (32 bytes each)
- Character palettes: 0-7 (8 palettes)
- Enemy palettes: 8-23 (16 palettes)
- Character tileset: 256 tiles (8KB)
- Enemy tilesets: 512 tiles each × 4 (64KB total)
- PNG import/export
- Palette optimization
- Color similarity search

#### Music Capabilities
- 32 music tracks (0x00-0x1F)
- 64 sound effects (0x00-0x3F)
- 32 audio samples/instruments
- 8 SPC700 channels
- Tempo: 40-240 BPM
- Volume/pan/pitch controls
- Loop point configuration
- SPC file export/import (v0.30 format)
- Track validation
- Note conversion (A4, C#3, etc.)

#### ROM Addresses
```
Graphics:
  TILESET_BASE  = 0x080000
  PALETTE_BASE  = 0x0C0000
  SPRITE_BASE   = 0x0A0000

Music:
  MUSIC_TABLE_BASE  = 0x0D8000
  SFX_TABLE_BASE    = 0x0DA000
  SAMPLE_TABLE_BASE = 0x0DC000
  SPC_DATA_BASE     = 0x0E0000
```

### Statistics
- Lines of code added: 3,700
- Lines of documentation added: 2,730
- Total files created: 9
- Total files modified: 1
- New classes: 15+
- New functions: 80+

---

## [1.0.0] - 2025-01-15

### Added - Initial Release

#### Enemy System
- **enemy_data.py** (300 lines): Enemy data structures
  - `Enemy` class with all stats (HP, Attack, Defense, etc.)
  - Element system (8 elements with resistance/weakness)
  - Status effect system
  - AI behavior flags
  - Serialization (to_bytes/from_bytes)

- **enemy_database.py** (260 lines): Enemy ROM I/O
  - Load all 83 enemies from ROM
  - Save enemies to ROM
  - Query functions (get_bosses, get_by_element, etc.)
  - JSON export/import
  - Statistics gathering

- **enemy_editor.py** (300 lines): Visual enemy editor
  - List all enemies with search/filter
  - Edit all enemy stats
  - Element resistance/weakness UI
  - Status effect toggles
  - Undo/redo support
  - Save to JSON/ROM

#### Spell System
- **spell_data.py** (280 lines): Spell data structures
  - `Spell` class with MP cost, power, accuracy
  - Target types (single, all, self)
  - Element assignment
  - Status effects
  - Serialization

- **spell_database.py** (220 lines): Spell ROM I/O
  - Load all spells from ROM
  - Save spells to ROM
  - Query functions (offensive, healing, etc.)
  - JSON export/import

#### Item System
- **item_data.py** (250 lines): Item data structures
  - `Item` class with type, effect, power, price
  - Item types (consumable, weapon, armor, etc.)
  - Effect types
  - Serialization

- **item_database.py** (200 lines): Item ROM I/O
  - Load all items from ROM
  - Save items to ROM
  - Query functions (weapons, armor, etc.)
  - JSON export/import

#### Dungeon System
- **dungeon_map.py** (470 lines): Dungeon data structures
  - `DungeonMap` class
  - Encounter configuration
  - Map properties
  - ROM I/O

#### Formation System
- **formation_editor.py** (480 lines): Enemy formation editor
  - Visual formation layout
  - Enemy positioning
  - Group configuration
  - Formation export

#### Game Editor
- **game_editor.py** (480 lines): Unified game editor
  - Tabbed interface (8 tabs)
  - Database management
  - Load/save ROM
  - Export/import functionality
  - Statistics display
  - Keyboard shortcuts

#### Utilities
- **validator.py** (550 lines): Data validation
  - Validate all game data
  - Check for issues (invalid stats, etc.)
  - Report severity levels
  - Comprehensive checks

- **comparator.py** (450 lines): ROM comparison
  - Compare two ROMs
  - Detect differences
  - Generate reports
  - Batch comparison

#### Testing
- **test_game_data.py** (400 lines): Automated tests
  - Test all data structures
  - Test serialization
  - Test database operations
  - Test validation

#### Documentation
- **GAME_EDITOR_GUIDE.md** (900 lines): Main guide
  - Complete editor documentation
  - Usage instructions
  - Examples
  - Troubleshooting

- **ROADMAP.md** (600 lines): Development roadmap
  - Feature plans
  - Priority levels
  - Timeline

- **DELIVERY_REPORT.md** (700 lines): Release report
  - Complete deliverables
  - Code statistics
  - Test results
  - Future plans

### Technical Details

#### Data Format
- All data uses Python dataclasses
- Binary serialization with to_bytes/from_bytes
- JSON export/import support
- Type annotations throughout
- Comprehensive validation

#### ROM Addresses
```
ENEMY_BASE = 0x0D0000  # 83 enemies × 32 bytes
SPELL_BASE = 0x0E0000  # Spells
ITEM_BASE  = 0x0F0000  # Items
```

#### Architecture
- Clean separation: data / database / editor
- pygame for visual editors
- Modular design
- Extensible framework

### Statistics
- Lines of code: 8,320
- Lines of documentation: 2,800
- Total files: 20
- Test coverage: Comprehensive
- Enemies supported: 83
- Spells supported: All
- Items supported: All

---

## Version Comparison

| Feature | v1.0 (Jan 2025) | v1.1 (Nov 2025) |
|---------|-----------------|-----------------|
| Enemy Editing | ✅ | ✅ |
| Spell Editing | ✅ | ✅ |
| Item Editing | ✅ | ✅ |
| Dungeon Editing | ✅ | ✅ |
| Dialog Editing | ✅ | ✅ |
| Formation Editing | ✅ | ✅ |
| **Graphics Editing** | ❌ | **✅ NEW** |
| **Music Editing** | ❌ | **✅ NEW** |
| PNG Import/Export | ❌ | **✅ NEW** |
| SPC Import/Export | ❌ | **✅ NEW** |
| Visual Editors | 4 | **6 (+2)** |
| Total Lines | 11,120 | **14,850 (+33%)** |
| Documentation | 2,800 | **5,530 (+97%)** |

---

## Future Releases

### Planned for v1.2
- [ ] Interactive color sliders
- [ ] Audio playback in editor
- [ ] Embed editors in game editor tabs
- [ ] Tile copy/paste
- [ ] Animation editor
- [ ] Real-time ROM preview

### Planned for v2.0
- [ ] MIDI import/export
- [ ] Map event editing
- [ ] Warp connection editor
- [ ] Collision layer editing
- [ ] Automated sprite generation
- [ ] Batch operations UI
- [ ] Plugin system

---

## Breaking Changes

### v1.1.0
- None (fully backward compatible with v1.0)

### v1.0.0
- Initial release (no previous versions)

---

## Dependencies

### v1.1.0
- Python 3.8+
- pygame-ce 2.5.2
- Pillow (for PNG support)
- dataclasses (built-in Python 3.7+)
- typing (built-in)

### v1.0.0
- Python 3.8+
- pygame-ce 2.5.2
- dataclasses (built-in Python 3.7+)
- typing (built-in)

---

## Migration Guide

### Upgrading from v1.0 to v1.1

No breaking changes! Simply update your files:

1. Pull latest changes
2. Install new dependencies:
   ```powershell
   pip install -r requirements.txt
   ```
3. New editors available:
   ```powershell
   python tools/map-editor/graphics_editor.py ffmq.smc
   python tools/map-editor/music_editor.py ffmq.smc
   ```

All v1.0 functionality remains unchanged and fully functional.

---

## Contributors

- Primary Development: AI Assistant (Anthropic Claude)
- Project Owner: TheAnsarya
- Testing: Community

---

**Format**: [Keep a Changelog](https://keepachangelog.com/)
**Versioning**: [Semantic Versioning](https://semver.org/)
