# FFMQ Map Editor

A comprehensive pygame-based map editor for Final Fantasy Mystic Quest, supporting overworld, dungeon, and town maps.

## Features

### Core Editing
- **Multi-layer editing** - Edit ground (BG1), upper (BG2), and event (BG3) layers independently
- **Multiple tools** - Pencil, bucket fill, eraser, rectangle, line, select, and eyedropper
- **Undo/Redo** - Full undo/redo support for all operations (up to 100 steps)
- **Zoom** - Zoom in/out from 25% to 400% with mouse wheel or keyboard
- **Grid** - Toggle-able grid overlay for precise placement

### Map Management
- **Create new maps** - Custom dimensions (up to 256x256 tiles)
- **Load/Save maps** - Import from and export to FFMQ ROM format
- **Map properties** - Edit map type, tileset, music, encounter rate, etc.

### UI Features
- **Tileset panel** - Browse and select tiles from current tileset (256 tiles)
- **Layer panel** - Control layer visibility and lock/unlock layers
- **Properties panel** - View and edit map and tile properties
- **Toolbar** - Quick access to tools and common operations
- **Responsive design** - Resizable window with adaptive UI

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
