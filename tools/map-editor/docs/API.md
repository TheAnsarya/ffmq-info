# FFMQ Map Editor API Reference

## Module: engine.map_engine

### Class: MapEngine

The core map management class.

#### Constructor

```python
MapEngine()
```

Creates a new MapEngine instance with empty map.

**Example:**
```python
engine = MapEngine()
```

---

#### Methods

##### new_map

```python
new_map(width: int, height: int, map_type: MapType) -> bool
```

Create a new empty map.

**Parameters:**
- `width` (int): Map width in tiles (16-256)
- `height` (int): Map height in tiles (16-256)
- `map_type` (MapType): Type of map (OVERWORLD, TOWN, DUNGEON, etc.)

**Returns:**
- `bool`: True if successful, False on error

**Example:**
```python
success = engine.new_map(32, 32, MapType.TOWN)
if success:
    print("Map created!")
```

---

##### get_tile

```python
get_tile(x: int, y: int, layer: LayerType) -> int
```

Get tile ID at specified position.

**Parameters:**
- `x` (int): X coordinate (0-based)
- `y` (int): Y coordinate (0-based)
- `layer` (LayerType): Layer to read from

**Returns:**
- `int`: Tile ID (0-255), or 0 if out of bounds

**Example:**
```python
tile_id = engine.get_tile(10, 5, LayerType.BG1_GROUND)
print(f"Tile at (10, 5): {tile_id}")
```

---

##### set_tile

```python
set_tile(x: int, y: int, tile_id: int, layer: LayerType) -> bool
```

Set tile ID at specified position.

**Parameters:**
- `x` (int): X coordinate
- `y` (int): Y coordinate
- `tile_id` (int): Tile ID to set (0-255)
- `layer` (LayerType): Layer to write to

**Returns:**
- `bool`: True if successful, False if out of bounds

**Side Effects:**
- Creates undo action
- Clears redo stack

**Example:**
```python
if engine.set_tile(10, 5, 42, LayerType.BG1_GROUND):
    print("Tile set successfully")
```

---

##### flood_fill

```python
flood_fill(x: int, y: int, tile_id: int, layer: LayerType) -> bool
```

Fill connected area with specified tile.

**Parameters:**
- `x` (int): Starting X coordinate
- `y` (int): Starting Y coordinate
- `tile_id` (int): Tile ID to fill with
- `layer` (LayerType): Layer to operate on

**Returns:**
- `bool`: True if successful

**Algorithm:**
- Uses iterative flood fill
- Only fills tiles matching starting tile
- Respects map boundaries

**Example:**
```python
engine.flood_fill(5, 5, 1, LayerType.BG1_GROUND)
```

---

##### paint_rectangle

```python
paint_rectangle(x1: int, y1: int, x2: int, y2: int, 
               tile_id: int, layer: LayerType) -> bool
```

Paint filled rectangle.

**Parameters:**
- `x1`, `y1` (int): Top-left corner
- `x2`, `y2` (int): Bottom-right corner
- `tile_id` (int): Tile ID to paint
- `layer` (LayerType): Layer to operate on

**Returns:**
- `bool`: True if successful

**Example:**
```python
# Paint 10x10 rectangle starting at (5, 5)
engine.paint_rectangle(5, 5, 14, 14, 20, LayerType.BG2_UPPER)
```

---

##### undo

```python
undo() -> bool
```

Undo last action.

**Returns:**
- `bool`: True if action was undone, False if nothing to undo

**Example:**
```python
if engine.undo():
    print("Action undone")
else:
    print("Nothing to undo")
```

---

##### redo

```python
redo() -> bool
```

Redo previously undone action.

**Returns:**
- `bool`: True if action was redone, False if nothing to redo

**Example:**
```python
if engine.redo():
    print("Action redone")
```

---

##### can_undo

```python
can_undo() -> bool
```

Check if undo is available.

**Returns:**
- `bool`: True if undo stack is not empty

**Example:**
```python
if engine.can_undo():
    print(f"{len(engine.undo_stack)} actions can be undone")
```

---

##### can_redo

```python
can_redo() -> bool
```

Check if redo is available.

**Returns:**
- `bool`: True if redo stack is not empty

---

#### Properties

##### current_map

```python
current_map: Optional[MapData]
```

Currently loaded map data. None if no map loaded.

**Example:**
```python
if engine.current_map:
    print(f"Map size: {engine.current_map.width}x{engine.current_map.height}")
```

---

### Class: MapData

Stores map tile data.

#### Constructor

```python
MapData(width: int, height: int)
```

Create new map data with specified dimensions.

**Parameters:**
- `width` (int): Map width in tiles
- `height` (int): Map height in tiles

**Example:**
```python
map_data = MapData(32, 32)
```

---

#### Properties

##### width, height

```python
width: int
height: int
```

Map dimensions in tiles.

---

##### bg1_tiles, bg2_tiles, bg3_tiles

```python
bg1_tiles: np.ndarray  # Shape: (height, width), dtype: uint8
bg2_tiles: np.ndarray
bg3_tiles: np.ndarray
```

Tile ID arrays for each layer.

**Example:**
```python
# Direct array access
map_data.bg1_tiles[y, x] = tile_id

# Safer: Use get_tile/set_tile methods
```

---

##### collision

```python
collision: np.ndarray  # Shape: (height, width), dtype: uint8
```

Collision data array. 0 = passable, 1 = blocked.

---

#### Methods

##### get_layer

```python
get_layer(layer_type: LayerType) -> np.ndarray
```

Get reference to layer array.

**Parameters:**
- `layer_type` (LayerType): Which layer to get

**Returns:**
- `np.ndarray`: Layer data array

**Example:**
```python
ground_layer = map_data.get_layer(LayerType.BG1_GROUND)
ground_layer.fill(1)  # Fill entire layer with tile 1
```

---

### Enum: MapType

Map type enumeration.

```python
class MapType(IntEnum):
    OVERWORLD = 0
    TOWN = 1
    DUNGEON = 2
    BATTLE = 3
    SPECIAL = 4
```

**Usage:**
```python
if map_type == MapType.DUNGEON:
    encounter_rate = 30
```

---

### Enum: LayerType

Layer type enumeration.

```python
class LayerType(IntEnum):
    BG1_GROUND = 0
    BG2_UPPER = 1
    BG3_EVENTS = 2
```

---

## Module: utils.compression

### Class: FFMQCompression

FFMQ compression/decompression algorithms.

#### Methods

##### compress_map

```python
@staticmethod
compress_map(data: bytes) -> bytes
```

Compress map data using FFMQ compression.

**Parameters:**
- `data` (bytes): Uncompressed data

**Returns:**
- `bytes`: Compressed data

**Compression Ratio:**
- Typical: 30-50% of original size
- Best case: 10-20% (repetitive data)
- Worst case: 110% (random data)

**Example:**
```python
uncompressed = bytes([1] * 100)
compressed = FFMQCompression.compress_map(uncompressed)
print(f"Size: {len(uncompressed)} -> {len(compressed)}")
```

---

##### decompress_map

```python
@staticmethod
decompress_map(compressed_data: bytes) -> bytes
```

Decompress FFMQ compressed data.

**Parameters:**
- `compressed_data` (bytes): Compressed data

**Returns:**
- `bytes`: Decompressed data

**Example:**
```python
decompressed = FFMQCompression.decompress_map(compressed)
assert decompressed == original_data
```

---

##### validate_compression

```python
@staticmethod
validate_compression(original: bytes) -> bool
```

Test if compression is lossless.

**Parameters:**
- `original` (bytes): Original data

**Returns:**
- `bool`: True if round-trip successful

**Example:**
```python
test_data = bytes([i % 256 for i in range(1000)])
if FFMQCompression.validate_compression(test_data):
    print("Compression is lossless!")
```

---

## Module: utils.tileset_manager

### Class: TilesetManager

Manages tileset loading and rendering.

#### Constructor

```python
TilesetManager(cache_dir: str = 'data/tilesets')
```

Create tileset manager.

**Parameters:**
- `cache_dir` (str): Directory for tileset cache

---

#### Methods

##### load_tileset

```python
load_tileset(tileset_id: int, tile_data: Optional[bytes] = None,
            palette: Optional[list] = None) -> bool
```

Load tileset from data or generate placeholder.

**Parameters:**
- `tileset_id` (int): Tileset ID (0-15)
- `tile_data` (bytes, optional): Raw 4bpp tile data
- `palette` (list, optional): List of (R,G,B) tuples

**Returns:**
- `bool`: True if loaded successfully

**Example:**
```python
manager = TilesetManager()

# Load placeholder tileset
manager.load_tileset(0)

# Load from ROM data
tile_data = rom_handler.read_tileset_graphics(0)
palette = rom_handler.read_palette(0)
manager.load_tileset(0, tile_data, palette)
```

---

##### get_tile_surface

```python
get_tile_surface(tile_id: int, 
                size: Optional[Tuple[int, int]] = None) -> Optional[pygame.Surface]
```

Get pygame surface for a tile.

**Parameters:**
- `tile_id` (int): Tile ID (0-255)
- `size` (tuple, optional): (width, height) to scale tile

**Returns:**
- `pygame.Surface`: Tile surface, or None if invalid

**Example:**
```python
# Get 8x8 tile
tile = manager.get_tile_surface(42)

# Get scaled to 32x32
tile_large = manager.get_tile_surface(42, size=(32, 32))

# Render to screen
screen.blit(tile_large, (x, y))
```

---

### Function: decode_snes_palette

```python
decode_snes_palette(palette_data: bytes, num_colors: int = 16) -> list
```

Decode SNES 15-bit palette to RGB.

**Parameters:**
- `palette_data` (bytes): Raw palette data
- `num_colors` (int): Number of colors to decode

**Returns:**
- `list`: List of (R, G, B) tuples (0-255 range)

**SNES Format:**
- 2 bytes per color (little-endian)
- 15-bit color: -BBBBBGGGGGRRRRR
- 5 bits per channel

**Example:**
```python
# Palette data from ROM
palette_data = rom.read_bytes(palette_address, 32)

# Decode to RGB
palette = decode_snes_palette(palette_data, 16)

# Use colors
for i, (r, g, b) in enumerate(palette):
    print(f"Color {i}: RGB({r}, {g}, {b})")
```

---

## Module: utils.file_formats

### Function: save_map

```python
save_map(filepath: str, map_data: dict) -> bool
```

Save map in format determined by file extension.

**Parameters:**
- `filepath` (str): Output file path
- `map_data` (dict): Map data dictionary

**Returns:**
- `bool`: True if successful

**Supported Extensions:**
- `.ffmap`: Native FFMQ format
- `.json`: JSON format
- `.bin`: Raw binary
- `.tmx`: Tiled TMX format

**Example:**
```python
map_data = {
    'width': 32,
    'height': 32,
    'bg1_tiles': bg1_array,
    # ... more fields
}

save_map('town.ffmap', map_data)
```

---

### Function: load_map

```python
load_map(filepath: str) -> Optional[dict]
```

Load map from file, auto-detecting format.

**Parameters:**
- `filepath` (str): Input file path

**Returns:**
- `dict`: Map data dictionary, or None on error

**Example:**
```python
map_data = load_map('town.ffmap')
if map_data:
    print(f"Loaded {map_data['width']}x{map_data['height']} map")
```

---

## Module: utils.rom_handler

### Class: ROMHandler

Handles ROM file I/O operations.

#### Constructor

```python
ROMHandler(rom_path: Optional[str] = None)
```

Create ROM handler, optionally loading ROM.

**Parameters:**
- `rom_path` (str, optional): Path to ROM file

---

#### Methods

##### load_rom

```python
load_rom(rom_path: str) -> bool
```

Load ROM file into memory.

**Parameters:**
- `rom_path` (str): Path to ROM file

**Returns:**
- `bool`: True if loaded successfully

**Example:**
```python
handler = ROMHandler()
if handler.load_rom('ffmq.sfc'):
    print(f"ROM loaded: {len(handler.rom_data)} bytes")
```

---

##### read_map_header

```python
read_map_header(map_id: int) -> Optional[dict]
```

Read map header from ROM.

**Parameters:**
- `map_id` (int): Map ID (0-127)

**Returns:**
- `dict`: Map header data, or None on error

**Header Fields:**
- `map_id`: Map ID
- `map_type`: Type (0-4)
- `width`, `height`: Dimensions
- `tileset_id`, `palette_id`: Graphics
- `music_id`: Background music
- `encounter_rate`, `encounter_group`: Enemies
- `spawn_x`, `spawn_y`: Starting position
- `flags`: Map flags

**Example:**
```python
header = handler.read_map_header(1)
print(f"Map: {header['width']}x{header['height']}")
print(f"Music: {header['music_id']}")
```

---

##### read_map_layer

```python
read_map_layer(map_id: int, layer: int, 
              width: int, height: int) -> Optional[np.ndarray]
```

Read and decompress map layer.

**Parameters:**
- `map_id` (int): Map ID
- `layer` (int): Layer number (0-2)
- `width`, `height` (int): Map dimensions

**Returns:**
- `np.ndarray`: Tile data array, or None on error

**Example:**
```python
header = handler.read_map_header(1)
bg1 = handler.read_map_layer(
    1, 0, 
    header['width'], 
    header['height']
)
```

---

##### read_tileset_graphics

```python
read_tileset_graphics(tileset_id: int) -> Optional[bytes]
```

Read tileset graphics from ROM.

**Parameters:**
- `tileset_id` (int): Tileset ID (0-15)

**Returns:**
- `bytes`: Raw 4bpp tile data (8192 bytes), or None on error

**Format:**
- 256 tiles per tileset
- 32 bytes per tile (4bpp, 8x8 pixels)

**Example:**
```python
tile_data = handler.read_tileset_graphics(0)
if tile_data:
    print(f"Loaded {len(tile_data) // 32} tiles")
```

---

##### read_palette

```python
read_palette(palette_id: int) -> Optional[List[Tuple[int, int, int]]]
```

Read palette from ROM.

**Parameters:**
- `palette_id` (int): Palette ID (0-15)

**Returns:**
- `list`: List of 16 (R,G,B) tuples, or None on error

**Example:**
```python
palette = handler.read_palette(0)
for i, (r, g, b) in enumerate(palette):
    print(f"Color {i}: RGB({r}, {g}, {b})")
```

---

## Module: utils.dialogs

### Class: FileDialogs

Provides file dialog interface.

#### Constructor

```python
FileDialogs(config=None)
```

Create file dialog handler.

---

#### Methods

##### ask_open_rom

```python
ask_open_rom() -> Optional[str]
```

Show "Open ROM" dialog.

**Returns:**
- `str`: Selected file path, or None if cancelled

**Example:**
```python
dialogs = FileDialogs()
rom_path = dialogs.ask_open_rom()
if rom_path:
    rom.load(rom_path)
```

---

##### ask_save_map

```python
ask_save_map(default_name: str = "untitled.ffmap") -> Optional[str]
```

Show "Save Map" dialog.

**Parameters:**
- `default_name` (str): Default filename

**Returns:**
- `str`: Selected save path, or None if cancelled

---

##### show_error

```python
show_error(title: str, message: str)
```

Show error message dialog.

**Parameters:**
- `title` (str): Dialog title
- `message` (str): Error message

**Example:**
```python
try:
    load_map('invalid.ffmap')
except Exception as e:
    dialogs.show_error("Load Error", str(e))
```

---

## Module: utils.config

### Class: Config

Configuration management.

#### Constructor

```python
Config()
```

Create configuration with defaults.

---

#### Methods

##### get

```python
get(key: str, default=None) -> Any
```

Get configuration value.

**Parameters:**
- `key` (str): Configuration key
- `default` (any): Default value if key not found

**Returns:**
- Value for key, or default

**Example:**
```python
config = Config()
width = config.get('window.width', 1280)
```

---

##### set

```python
set(key: str, value: Any)
```

Set configuration value.

**Parameters:**
- `key` (str): Configuration key
- `value` (any): Value to set

---

##### save

```python
save() -> bool
```

Save configuration to file.

**Returns:**
- `bool`: True if successful

---

## Usage Examples

### Complete Example: Create and Save Map

```python
from engine.map_engine import MapEngine, MapType, LayerType
from utils.file_formats import save_map

# Create engine
engine = MapEngine()

# Create new town map
engine.new_map(32, 32, MapType.TOWN)

# Fill ground with grass
engine.flood_fill(0, 0, 1, LayerType.BG1_GROUND)

# Add some buildings
for x in range(5, 10):
    for y in range(5, 10):
        engine.set_tile(x, y, 20, LayerType.BG2_UPPER)

# Export and save
map_data = engine.export_map_data()
save_map('my_town.ffmap', map_data)
```

---

### Complete Example: Load from ROM

```python
from utils.rom_handler import ROMHandler
from utils.tileset_manager import TilesetManager

# Load ROM
rom = ROMHandler()
rom.load_rom('ffmq.sfc')

# Read map 0
header = rom.read_map_header(0)
bg1 = rom.read_map_layer(0, 0, header['width'], header['height'])

# Load tileset
tileset = TilesetManager()
tile_data = rom.read_tileset_graphics(header['tileset_id'])
palette = rom.read_palette(header['palette_id'])
tileset.load_tileset(header['tileset_id'], tile_data, palette)

# Render tile
tile_surface = tileset.get_tile_surface(bg1[0, 0], size=(32, 32))
```

---

For more examples, see:
- `examples/` directory
- `tests/test_all.py`
- `docs/TUTORIALS.md`
