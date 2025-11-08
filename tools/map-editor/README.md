# FFMQ Map Editor & Game Data Tools

A comprehensive suite of pygame-based editors and tools for Final Fantasy Mystic Quest ROM hacking.

## 🎮 Editor Suite

### Map Editor
- **Multi-layer editing** - Edit ground (BG1), upper (BG2), and event (BG3) layers independently
- **Multiple tools** - Pencil, bucket fill, eraser, rectangle, line, select, and eyedropper
- **Undo/Redo** - Full undo/redo support for all operations (up to 100 steps)
- **Zoom** - Zoom in/out from 25% to 400% with mouse wheel or keyboard
- **Tileset panel** - Browse and select tiles from current tileset (256 tiles)

### Game Editor (`game_editor.py`) - NEW!
- **Unified 8-tab interface** - Maps, Dialogs, Enemies, Spells, Items, Dungeons, Events, Settings
- **Database integration** - Edit all game data from one application
- **Keyboard shortcuts** - Ctrl+S save, Ctrl+1-8 tab switching, F1 stats toggle
- **Export/Import** - JSON/CSV export for all data systems

### Enemy Editor (`ui/enemy_editor.py`) - NEW!
- **Visual editing** - 1200×800 window with enemy list + editor panel
- **Stat controls** - Numeric inputs with +/- buttons for HP, attack, defense, magic, speed
- **Resistance bars** - Drag visual sliders for elemental resistances (0-255)
- **Flag checkboxes** - Boss, undead, flying, regenerating, etc.
- **Difficulty calculation** - Real-time difficulty rating
- **Load from ROM** - 256 enemies at 0x0D0000

### Formation Editor (`ui/formation_editor.py`) - NEW!
- **Drag-and-drop** - Position up to 6 enemies on battle screen
- **Grid snapping** - 16px grid for precise placement
- **Visual preview** - See formation layout in real-time
- **Enemy selection** - Browse and add enemies from database

### Dialog Editor (integrated)
- **Text editing** - Edit all game dialog and NPC conversations
- **Multi-character encoding** - Edit "the ", "you", etc. sequences
- **Flow visualization** - See dialog branching and connections
- **Batch operations** - Find/replace across all dialogs

## 🗂️ Database Systems

### Enemy System (~1,560 lines)
- **256 enemies** × 256 bytes each (64KB total at 0x0D0000)
- **Complete stats** - HP, attack, defense, magic, speed, accuracy, evasion
- **9 resistances** - Fire, water, earth, wind, holy, dark, poison, status, physical
- **AI scripts** - 8 behavior types with HP-threshold actions
- **Item drops** - Up to 3 items with rarity (always/common/uncommon/rare)
- **12 flags** - Boss, undead, flying, aquatic, humanoid, mechanical, dragon, etc.

### Spell System (~750 lines)
- **128 spells** × 64 bytes each (8KB total at 0x0E0000)
- **8 damage formulas** - Fixed, magic-based, level-based, HP%, MP-based, pierce, hybrid, random
- **8 elements** - None, fire, water, earth, wind, holy, dark, poison
- **8 targeting modes** - Single enemy, all enemies, single ally, all allies, self, etc.
- **13 status effects** - Poison, sleep, paralysis, confusion, silence, blind, etc.
- **Spell progression** - Auto-generate Fire→Fira→Firaga tiers

### Item System (~600 lines)
- **256 items** × 32 bytes each (8KB total at 0x0F0000)
- **8 item types** - Consumable, weapon, armor, helmet, accessory, key item, coin, book
- **Equipment stats** - Attack, defense, magic, speed, HP/MP bonuses
- **Character restrictions** - Benjamin, Kaeli, Phoebe, Reuben, Tristam
- **9 flags** - Usable in battle/field, consumable, cursed, rare, two-handed, etc.

### Dungeon System (~470 lines)
- **Enemy formations** - Up to 6 enemies with precise positioning
- **Encounter tables** - Weighted random selection
- **Encounter zones** - Normal, high rate, boss area, safe zone
- **Terrain types** - Overworld, cave, dungeon, tower, forest, water, mountain, castle

## 🛠️ Utilities

### Validator (`validator.py`) - NEW!
- **Data validation** - Check all enemies, spells, items for errors
- **Range checking** - HP (0-65535), stats (0-255), levels (1-99)
- **Balance analysis** - HP scaling, MP efficiency, price/stat ratios
- **Error reporting** - ERROR/WARNING/INFO severity levels
- **Export reports** - Generate text reports of validation results

### Comparator (`comparator.py`) - NEW!
- **ROM comparison** - Compare original vs modified ROM files
- **Track changes** - See all stat, name, flag changes
- **CSV export** - Export changes to spreadsheet
- **Summary statistics** - Total changes, affected entities
- **Detailed reports** - Group changes by category and entity

### Dialog CLI (`dialog_cli.py`) - NEW!
- **Command-line** - Batch dialog operations
- **Import/Export** - Convert dialogs to/from JSON
- **Search** - Find dialog by text
- **Batch editing** - Find/replace across all dialogs

## Installation

### Prerequisites
- Python 3.8 or higher
- pip (Python package manager)

### Setup

1. **Clone the repository** (if not already done):
   ```bash
   cd tools/map-editor
   ```

2. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

   This will install:
   - pygame (2.5.0+) - Graphics and UI framework
   - numpy (1.24.0+) - Efficient map data handling

3. **Run the editor**:
   ```bash
   python main.py
   ```

## Usage

### Keyboard Shortcuts

#### File Operations
- `Ctrl+N` - New map
- `Ctrl+O` - Open map
- `Ctrl+S` - Save map
- `Ctrl+Z` - Undo
- `Ctrl+Y` - Redo

#### Tool Selection
- `P` - Pencil (paint individual tiles)
- `B` - Bucket (flood fill)
- `E` - Eraser (remove tiles)
- `R` - Rectangle (draw filled rectangles)
- `L` - Line (draw lines)
- `S` - Select (select and move tiles)
- `I` - Eyedropper (pick tile from map)

#### Layer Selection
- `1` - Ground layer (BG1)
- `2` - Upper layer (BG2)
- `3` - Event layer (BG3)

#### View Controls
- `+`/`=` - Zoom in
- `-` - Zoom out
- `0` - Reset zoom to 100%
- `G` - Toggle grid
- `Middle Mouse Button` - Pan view (hold and drag)

### Mouse Controls

#### In Map Area
- **Left Click** - Paint/use current tool
- **Right Click** - Pick tile (eyedropper)
- **Middle Click** - Pan view
- **Mouse Wheel** - Zoom in/out

#### In Tileset Panel
- **Left Click** - Select tile
- **Mouse Wheel** - Scroll tileset

#### In Layer Panel
- **Left Click** - Select layer
- **Eye Icon** - Toggle layer visibility
- **Lock Icon** - Lock/unlock layer for editing

## Map Data Structure

### Supported Map Types
- **Overworld** - Large outdoor maps with encounters
- **Town** - Safe zones with NPCs and shops
- **Dungeon** - Indoor areas with encounters and puzzles
- **Battle** - Battle backgrounds
- **Special** - Cutscenes and special events

### Layer System
1. **BG1 (Ground)** - Main walkable surface, walls, basic terrain
2. **BG2 (Upper)** - Roofs, elevated objects, decorative overlays
3. **BG3 (Events)** - Invisible collision, warp zones, event triggers

### Map Properties
- **Map ID** - Unique identifier (0-255)
- **Dimensions** - Width and height in tiles (max 256x256)
- **Tileset** - Graphics tileset ID (0-255)
- **Palette** - Color palette ID (0-7)
- **Music** - Background music track ID
- **Encounter Rate** - Random encounter frequency (0-255)
- **Encounter Group** - Enemy group for this map
- **Spawn Point** - Default player spawn X/Y coordinates
- **Flags** - Various map properties (encounters enabled, safe zone, etc.)

## File Formats

### Import/Export
The editor supports importing and exporting maps in FFMQ ROM format:
- Map headers (32 bytes per map)
- Tilemap data (2 bytes per tile: ID + attributes)
- Collision data (1 byte per tile)
- Event triggers

### Project Files
Maps can also be saved as standalone project files (.ffmqmap):
- JSON-based format for easy editing
- Includes all layers, properties, and metadata
- Human-readable and version-control friendly

## Architecture

### Directory Structure
```
map-editor/
├── main.py              # Application entry point
├── requirements.txt     # Python dependencies
├── config.json          # Editor configuration (auto-generated)
├── engine/              # Core map engine
│   ├── __init__.py
│   └── map_engine.py    # Map data and operations
├── ui/                  # UI components
│   ├── __init__.py
│   ├── main_window.py   # Main map view
│   ├── toolbar.py       # Tool selection toolbar
│   ├── tileset_panel.py # Tileset browser
│   ├── layer_panel.py   # Layer management
│   └── properties_panel.py # Property editor
├── utils/               # Utilities
│   ├── __init__.py
│   ├── config.py        # Configuration management
│   └── logger.py        # Logging utilities
├── data/                # Runtime data
│   ├── tilesets/        # Cached tileset graphics
│   └── exported_maps/   # Exported map files
└── logs/                # Application logs
```

### Core Components

#### MapEngine (engine/map_engine.py)
- Manages map data (3 layers + collision)
- Handles tile operations (get/set, fill, rectangle)
- Implements undo/redo stack
- Validates map bounds and operations

#### MainWindow (ui/main_window.py)
- Renders map view with zoom and pan
- Converts screen↔map coordinates
- Displays grid overlay
- Handles view-related mouse/keyboard input

#### Toolbar (ui/toolbar.py)
- Tool selection UI
- File operation buttons
- Displays tool tooltips and hotkeys

#### TilesetPanel (ui/tileset_panel.py)
- Displays all 256 tiles in current tileset
- Supports scrolling and tile selection
- Shows selected tile info and preview

#### LayerPanel (ui/layer_panel.py)
- Layer selection and switching
- Visibility toggles for each layer
- Lock/unlock layers to prevent editing

#### PropertiesPanel (ui/properties_panel.py)
- Displays map properties (dimensions, tileset, music, etc.)
- Shows tile-specific properties
- Future: Property editing

## Development

### Adding New Tools

1. Add tool to `Toolbar.TOOLS` list in `ui/toolbar.py`
2. Implement tool logic in `main.py` `paint_tile()` method
3. Add keyboard shortcut in `handle_key_press()`

Example:
```python
# In toolbar.py
Tool('my_tool', '🔧', 'M', 'My Custom Tool')

# In main.py handle_key_press()
elif key == pygame.K_m:
    self.current_tool = 'my_tool'

# In paint_tile()
elif self.current_tool == 'my_tool':
    # Implement tool logic
    pass
```

### Adding New Panels

1. Create new panel class in `ui/` directory
2. Initialize in `FFMQMapEditor.__init__()`
3. Handle events in `handle_events()`
4. Update in `update()`
5. Render in `render()`

### Configuration

Edit `config.json` (auto-generated on first run) to customize:
- Window size and FPS
- UI colors and layout
- Default paths
- Editor behavior

## Troubleshooting

### Import Errors
If you see "Import pygame could not be resolved":
```bash
pip install --upgrade pygame numpy
```

### Performance Issues
If the editor is slow:
- Reduce zoom level
- Disable grid (press `G`)
- Reduce `target_fps` in config.json
- Smaller maps perform better than larger ones

### Map Not Displaying
- Ensure map has been created with `Ctrl+N` or loaded with `Ctrl+O`
- Check that current layer has tiles (try layer 0/BG1)
- Verify camera is positioned correctly (zoom out with `-`)

## Future Enhancements

### Planned Features
- [ ] ROM import/export (read/write FFMQ map data)
- [ ] Actual tileset graphics loading from ROM
- [ ] Collision editing with visual indicators
- [ ] Event trigger placement and editing
- [ ] NPC placement tool
- [ ] Chest/item placement
- [ ] Warp zone editor
- [ ] Encounter zone painting
- [ ] Minimap preview
- [ ] Multi-tile brush (stamp tool)
- [ ] Copy/paste regions
- [ ] Auto-tile support
- [ ] Map testing in emulator
- [ ] Batch operations on multiple maps

### Advanced Features (Long-term)
- [ ] Tileset editor (edit 8x8 tiles directly)
- [ ] Palette editor
- [ ] Animation preview
- [ ] Scripting support for custom tools
- [ ] Plugin system
- [ ] Multi-user collaboration
- [ ] Map validation (check for errors)
- [ ] Statistics (tile usage, map size, etc.)

## Credits

- **FFMQ Disassembly Project** - Reverse engineering and documentation
- **pygame** - Python game framework
- **numpy** - Numerical computing library

## License

MIT License - See LICENSE file in repository root

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes with clear commit messages
4. Test thoroughly
5. Submit a pull request

For bug reports and feature requests, please open an issue on GitHub.

## Contact

For questions or support, please:
- Open an issue on GitHub
- Check the main project documentation
- Consult the FFMQ disassembly documentation in `docs/`

---

**Note**: This editor is currently in active development. Some features may be incomplete or change in future versions.
