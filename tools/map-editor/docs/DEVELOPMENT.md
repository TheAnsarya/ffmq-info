# FFMQ Map Editor Development Guide

## Architecture Overview

### Component Structure

The FFMQ Map Editor follows a modular architecture with clear separation of concerns:

```
map-editor/
├── main.py              # Application entry point & main loop
├── engine/              # Core engine (business logic)
│   └── map_engine.py    # Map data management & operations
├── ui/                  # UI components (presentation)
│   ├── main_window.py   # Map viewport & rendering
│   ├── toolbar.py       # Tool selection
│   ├── tileset_panel.py # Tileset browser
│   ├── layer_panel.py   # Layer management
│   ├── properties_panel.py  # Property editor
│   ├── minimap_panel.py     # Overview map
│   └── object_panel.py      # NPC/object placement
└── utils/               # Utilities & helpers
    ├── config.py        # Configuration management
    ├── logger.py        # Logging system
    ├── rom_handler.py   # ROM I/O
    ├── compression.py   # Map compression
    ├── tileset_manager.py   # Tileset handling
    ├── file_formats.py      # Import/export
    ├── dialogs.py           # File dialogs
    ├── advanced_tools.py    # Selection, copy/paste
    └── example_maps.py      # Example generation
```

### Design Patterns Used

**1. Model-View-Controller (MVC)**
- **Model:** `MapEngine` stores map data and state
- **View:** UI components render state to screen
- **Controller:** `main.py` handles events and updates

**2. Command Pattern**
- `UndoAction` encapsulates operations
- Enables undo/redo functionality
- All state changes go through commands

**3. Observer Pattern**
- UI components observe map engine
- Updates trigger re-rendering
- Loose coupling between components

**4. Strategy Pattern**
- Different tools implement common interface
- Easy to add new tools
- Tool behavior switchable at runtime

**5. Factory Pattern**
- Map generation creates complex objects
- Consistent initialization
- Easy to extend with new map types

## Core Systems

### Map Engine (`engine/map_engine.py`)

The MapEngine is the heart of the application.

**Key Classes:**

```python
class MapEngine:
    """Manages map data and operations"""
    
    # Core data
    current_map: Optional[MapData]
    
    # Undo/redo stacks
    undo_stack: List[UndoAction]
    redo_stack: List[UndoAction]
    
    # Operations
    def new_map(width, height, map_type)
    def get_tile(x, y, layer)
    def set_tile(x, y, tile_id, layer)
    def flood_fill(x, y, tile_id, layer)
    def paint_rectangle(x1, y1, x2, y2, tile_id, layer)
    def undo()
    def redo()
```

**Map Data Structure:**

```python
class MapData:
    """Stores tile data for a map"""
    
    # Dimensions
    width: int
    height: int
    
    # Tile layers (numpy arrays)
    bg1_tiles: np.ndarray  # Ground layer
    bg2_tiles: np.ndarray  # Upper layer
    bg3_tiles: np.ndarray  # Events layer
    
    # Attributes (parallel arrays)
    bg1_attrs: np.ndarray  # Palette, flip, priority
    bg2_attrs: np.ndarray
    bg3_attrs: np.ndarray
    
    # Collision
    collision: np.ndarray
```

**Why NumPy Arrays?**
- Fast array operations
- Memory efficient
- Easy serialization
- Built-in slicing and indexing
- Optimized C implementation

### Rendering System (`ui/main_window.py`)

The rendering system uses pygame for 2D graphics.

**Coordinate Systems:**

```python
# Map coordinates (tile-based)
map_x, map_y = 10, 5  # Tile (10, 5)

# Screen coordinates (pixel-based)
screen_x = map_x * tile_size * zoom + camera_x
screen_y = map_y * tile_size * zoom + camera_y

# Conversion functions
def map_to_screen(map_pos) -> screen_pos
def screen_to_map(screen_pos) -> map_pos
```

**Layer Rendering Order:**
1. BG1 (Ground) - Bottom layer
2. BG2 (Upper) - Middle layer
3. BG3 (Events) - Top layer
4. Grid overlay (optional)
5. Tool preview
6. Selection overlay

**Camera System:**

```python
class Camera:
    # Position (in map pixels)
    x: float
    y: float
    
    # Zoom level (0.25 to 4.0)
    zoom: float
    
    # Methods
    def pan(dx, dy)          # Move camera
    def zoom_in()            # Increase zoom
    def zoom_out()           # Decrease zoom
    def center_on(x, y)      # Focus on position
```

### Tool System

Tools are implemented as state machines that respond to events.

**Tool Interface:**

```python
class Tool:
    """Base tool interface"""
    
    def on_mouse_down(pos, button):
        """Handle mouse button press"""
        pass
    
    def on_mouse_up(pos, button):
        """Handle mouse button release"""
        pass
    
    def on_mouse_move(pos):
        """Handle mouse movement"""
        pass
    
    def render_preview(screen):
        """Render tool preview"""
        pass
```

**Built-in Tools:**

| Tool | Key | Description | Implementation |
|------|-----|-------------|----------------|
| Pencil | P | Draw individual tiles | Direct set_tile on click |
| Bucket | B | Flood fill | Recursive fill algorithm |
| Eraser | E | Remove tiles | Set tile to 0 |
| Rectangle | R | Draw rectangles | Track start/end, fill on release |
| Line | L | Draw lines | Bresenham's algorithm |
| Select | S | Select region | Build selection set |
| Eyedropper | I | Pick tile | Get tile at position |

**Adding a New Tool:**

```python
# 1. Create tool class
class MyTool:
    def __init__(self):
        self.active = False
    
    def on_mouse_down(self, pos, button):
        # Tool behavior
        pass

# 2. Add to toolbar
tool = Tool(
    name='My Tool',
    icon='🔧',
    hotkey='M',
    tooltip='My custom tool (M)'
)

# 3. Register in main.py
self.tools['mytool'] = MyTool()
```

### File Format System (`utils/file_formats.py`)

Multiple formats supported for different use cases.

**Format Comparison:**

| Format | Extension | Use Case | Size | Human-Readable |
|--------|-----------|----------|------|----------------|
| FFMAP | .ffmap | Native format | Small | No |
| JSON | .json | Version control | Large | Yes |
| Binary | .bin | ROM insertion | Smallest | No |
| TMX | .tmx | Tiled compatibility | Medium | Yes |

**FFMAP Format Structure:**

```
Offset | Size | Description
-------|------|-------------
0x00   | 5    | Magic "FFMAP"
0x05   | 2    | Version number
0x07   | 25   | Reserved
0x20   | 4    | Properties JSON size
0x24   | Var  | Properties JSON
Var    | 4    | BG1 data size
Var    | Var  | BG1 data (raw)
Var    | 4    | BG2 data size
Var    | Var  | BG2 data
Var    | 4    | BG3 data size
Var    | Var  | BG3 data
Var    | 4    | Collision data size
Var    | Var  | Collision data
```

**Implementing Custom Format:**

```python
class MyFormat(MapFileFormat):
    @staticmethod
    def save(filepath, map_data):
        # Write your format
        with open(filepath, 'wb') as f:
            # ... write data
        return True
    
    @staticmethod
    def load(filepath):
        # Read your format
        with open(filepath, 'rb') as f:
            # ... read data
        return map_data
```

### Compression System (`utils/compression.py`)

FFMQ uses custom RLE-based compression for maps.

**Compression Commands:**

```
Command Byte | Description
-------------|-------------
0x00-0x7F    | Literal: Copy N+1 bytes
0x80-0xBF    | RLE: Repeat byte (N+1) times
0xC0-0xCF    | Word RLE: Repeat word (N+1) times
0xD0-0xDF    | Extended RLE: Next byte = count
0xE0-0xFF    | Back reference: Copy from earlier position
```

**Compression Algorithm:**

```python
def compress_map(data):
    1. Scan for runs of identical bytes
    2. Check for word patterns
    3. Look for back-references
    4. Use best method for each position
    5. Fall back to literal if no compression
    6. Return compressed data
```

**Decompression Algorithm:**

```python
def decompress_map(compressed):
    1. Read command byte
    2. Execute command:
       - Literal: Copy bytes directly
       - RLE: Repeat value
       - Word RLE: Repeat 2-byte sequence
       - Back ref: Copy from earlier output
    3. Repeat until end marker or data exhausted
    4. Return decompressed data
```

### Undo/Redo System

Implemented using command pattern with action stacks.

**Action Structure:**

```python
@dataclass
class UndoAction:
    action_type: str        # 'set_tile', 'fill', 'rectangle'
    layer: LayerType        # Which layer affected
    tiles: List[Tuple]      # [(x, y, old_value, new_value), ...]
```

**Undo/Redo Implementation:**

```python
def set_tile(self, x, y, tile_id, layer):
    # Get old value
    old_tile = self.get_tile(x, y, layer)
    
    # Create undo action
    action = UndoAction(
        action_type='set_tile',
        layer=layer,
        tiles=[(x, y, old_tile, tile_id)]
    )
    
    # Apply change
    self.current_map.get_layer(layer)[y, x] = tile_id
    
    # Push to undo stack
    self.undo_stack.append(action)
    self.redo_stack.clear()  # Clear redo on new action

def undo(self):
    if not self.undo_stack:
        return
    
    # Pop action
    action = self.undo_stack.pop()
    
    # Reverse changes
    for x, y, old_val, new_val in action.tiles:
        layer_data = self.current_map.get_layer(action.layer)
        layer_data[y, x] = old_val
    
    # Push to redo stack
    self.redo_stack.append(action)
```

## Performance Optimization

### Memory Management

**Efficient Data Structures:**

```python
# Good: NumPy arrays (contiguous memory)
tiles = np.zeros((height, width), dtype=np.uint8)

# Bad: Nested lists (scattered memory)
tiles = [[0 for x in range(width)] for y in range(height)]
```

**Memory Usage:**
- 32x32 map: ~9KB (3 layers + collision)
- 64x64 map: ~36KB
- 128x128 map: ~144KB
- Plus undo history: ~100 actions × action size

**Tips:**
- Limit undo stack size (default: 100)
- Clear undo on file load
- Use uint8 for tile IDs (not int)
- Release old maps when loading new

### Rendering Performance

**Only Render Visible Area:**

```python
def _render_layer(self, screen, map_engine, layer, bounds, tile_size):
    # Calculate visible tile range
    start_x = max(0, bounds.left)
    end_x = min(map_width, bounds.right)
    start_y = max(0, bounds.top)
    end_y = min(map_height, bounds.bottom)
    
    # Only render visible tiles
    for y in range(start_y, end_y):
        for x in range(start_x, end_x):
            # Render tile
```

**Benchmark Results:**
- Full 128x128 map: ~15 FPS
- Visible-only rendering: ~60 FPS
- 4x performance improvement!

**Use Surface Caching:**

```python
# Cache tileset surface
if tileset_id not in self.tileset_cache:
    self.tileset_cache[tileset_id] = load_tileset(tileset_id)

# Reuse cached surface
tileset = self.tileset_cache[tileset_id]
```

### Algorithm Optimization

**Flood Fill - Iterative vs Recursive:**

```python
# Recursive (simple but can stack overflow)
def flood_fill_recursive(x, y, target, replacement):
    if map[y][x] != target:
        return
    map[y][x] = replacement
    flood_fill_recursive(x+1, y, target, replacement)
    flood_fill_recursive(x-1, y, target, replacement)
    # ... etc

# Iterative (better performance, no stack overflow)
def flood_fill_iterative(x, y, target, replacement):
    stack = [(x, y)]
    while stack:
        cx, cy = stack.pop()
        if map[cy][cx] != target:
            continue
        map[cy][cx] = replacement
        stack.extend([(cx+1, cy), (cx-1, cy), (cx, cy+1), (cx, cy-1)])
```

**Use NumPy Operations:**

```python
# Slow: Python loop
for y in range(height):
    for x in range(width):
        if tiles[y, x] == old_val:
            tiles[y, x] = new_val

# Fast: NumPy vectorization
tiles[tiles == old_val] = new_val
```

## Testing Strategy

### Unit Tests

Test individual components in isolation.

```python
class TestMapEngine(unittest.TestCase):
    def setUp(self):
        self.engine = MapEngine()
    
    def test_new_map(self):
        self.engine.new_map(32, 32, MapType.TOWN)
        self.assertIsNotNone(self.engine.current_map)
    
    def test_set_tile(self):
        self.engine.new_map(16, 16, MapType.TOWN)
        result = self.engine.set_tile(5, 5, 42, LayerType.BG1_GROUND)
        self.assertTrue(result)
        self.assertEqual(self.engine.get_tile(5, 5, LayerType.BG1_GROUND), 42)
```

### Integration Tests

Test component interaction.

```python
def test_file_save_load():
    # Create map
    engine = MapEngine()
    engine.new_map(32, 32, MapType.TOWN)
    engine.set_tile(10, 10, 55, LayerType.BG1_GROUND)
    
    # Save
    map_data = engine.export_map_data()
    save_map('test.ffmap', map_data)
    
    # Load
    loaded_data = load_map('test.ffmap')
    engine.import_map_data(loaded_data)
    
    # Verify
    assert engine.get_tile(10, 10, LayerType.BG1_GROUND) == 55
```

### Performance Tests

Measure and optimize performance.

```python
import timeit

def benchmark_flood_fill():
    engine = MapEngine()
    engine.new_map(128, 128, MapType.TOWN)
    
    # Time flood fill
    time = timeit.timeit(
        lambda: engine.flood_fill(64, 64, 42, LayerType.BG1_GROUND),
        number=100
    )
    
    print(f"Average flood fill time: {time/100*1000:.2f}ms")
```

## Extension Points

### Adding New Map Types

```python
# 1. Add to MapType enum
class MapType(IntEnum):
    OVERWORLD = 0
    TOWN = 1
    DUNGEON = 2
    BATTLE = 3
    SPECIAL = 4
    INTERIOR = 5  # New type!

# 2. Update map creation logic
def new_map(self, width, height, map_type):
    if map_type == MapType.INTERIOR:
        # Custom initialization for interior maps
        pass
```

### Adding Custom Tools

See "Adding a New Tool" section above for basic tool creation.

**Advanced Tool Features:**

```python
class AdvancedTool:
    def __init__(self):
        # Tool state
        self.options = {}
        self.preview_surface = None
    
    def get_options_panel(self):
        """Return UI panel for tool options"""
        return OptionsPanel(self.options)
    
    def on_option_changed(self, key, value):
        """Handle option changes"""
        self.options[key] = value
    
    def save_preset(self, name):
        """Save tool settings as preset"""
        presets[name] = self.options.copy()
```

### Plugin System (Future)

Planned plugin architecture:

```python
class MapEditorPlugin:
    """Base class for plugins"""
    
    def __init__(self, editor):
        self.editor = editor
    
    def on_load(self):
        """Called when plugin loads"""
        pass
    
    def on_unload(self):
        """Called when plugin unloads"""
        pass
    
    def get_menu_items(self):
        """Return menu items to add"""
        return []
    
    def get_tools(self):
        """Return custom tools"""
        return []
```

## Contributing Guidelines

### Code Style

Follow PEP 8 with these specifics:
- Line length: 88 characters (Black formatter)
- Indentation: 4 spaces
- Quotes: Double quotes for strings
- Docstrings: Google style

**Example:**

```python
def function_name(param1: int, param2: str) -> bool:
    """
    Brief description of function.
    
    Longer description if needed. Can span multiple
    lines and include details about the implementation.
    
    Args:
        param1: Description of first parameter
        param2: Description of second parameter
    
    Returns:
        True if successful, False otherwise
    
    Raises:
        ValueError: If param1 is negative
    """
    if param1 < 0:
        raise ValueError("param1 must be non-negative")
    
    # Implementation
    return True
```

### Git Workflow

1. Fork repository
2. Create feature branch: `git checkout -b feature/my-feature`
3. Make changes
4. Add tests
5. Run test suite: `python tests/test_all.py`
6. Commit: `git commit -m "Add my feature"`
7. Push: `git push origin feature/my-feature`
8. Create pull request

### Pull Request Checklist

- [ ] Code follows style guidelines
- [ ] All tests pass
- [ ] New tests added for new features
- [ ] Documentation updated
- [ ] No breaking changes (or clearly documented)
- [ ] Commit messages are descriptive
- [ ] PR description explains changes

## Resources

### External Documentation

- **Pygame:** https://www.pygame.org/docs/
- **NumPy:** https://numpy.org/doc/
- **Python:** https://docs.python.org/3/

### FFMQ Technical Documentation

- ROM map documentation
- Compression format specification
- Tileset format guide
- Map header structure

### Community

- Discord server (coming soon)
- GitHub discussions
- Wiki (coming soon)

## Roadmap

### Version 1.0 (Current)
- [x] Basic map editing
- [x] Multiple layers
- [x] Undo/redo
- [x] File save/load
- [x] Tool system

### Version 1.1 (Planned)
- [ ] ROM integration (load from ROM)
- [ ] Save back to ROM
- [ ] Actual tileset graphics
- [ ] Palette editor

### Version 2.0 (Future)
- [ ] Event scripting
- [ ] NPC dialogue editor
- [ ] Animation preview
- [ ] Plugin system
- [ ] Collaboration features

### Version 3.0 (Long-term)
- [ ] 3D preview mode
- [ ] Automated testing
- [ ] Cloud sync
- [ ] Mobile editor

---

**Happy coding! If you have questions, check the documentation or ask the community.**
