# FFMQ Interactive Editors - Complete Documentation

## Overview
This document provides comprehensive documentation for all 10 interactive editors created for Final Fantasy Mystic Quest ROM hacking. Each editor is a standalone pygame application with professional UI, keyboard shortcuts, and export capabilities.

---

## 1. Animation Editor
**File:** `tools/map-editor/animation_editor.py` (677 lines)

### Purpose
Create and edit tile animations with frame sequencing, timing control, and real-time playback preview.

### Features
- **TileSelectorPanel:** Browse tileset with scroll (350x700, 8 tiles/row, 48px display)
- **AnimationTimelinePanel:** Frame sequencer with 60px frames, playhead animation
- **AnimationPreviewPanel:** 128x128 real-time preview at 16x scale, 60 FPS playback
- **DraggableSlider:** Interactive frame duration control (1-120 frames)
- Add/remove frames with visual feedback
- Play/pause animation with Space key
- Test animation included (4 frames)

### Controls
| Key | Action |
|-----|--------|
| Space | Play/Pause animation |
| Ctrl+S | Save animation |
| ESC | Quit editor |
| Mouse Click | Select tile/frame |
| Mouse Drag | Adjust frame duration |

### Usage
```bash
python tools/map-editor/animation_editor.py
```

### Data Format
Animations export as JSON:
```json
{
  "animation_id": 0,
  "frames": [
    {"tile_id": 10, "duration": 15},
    {"tile_id": 11, "duration": 15}
  ],
  "loop": true
}
```

---

## 2. Interactive Palette Editor
**File:** `tools/map-editor/interactive_palette_editor.py` (507 lines)

### Purpose
Edit SNES BGR555 palettes with draggable RGB sliders and live color preview.

### Features
- **ColorSlider:** 400x30 draggable sliders with gradient backgrounds (R/G/B channels)
- **PaletteSwatch:** 16 color grid (2 rows × 8), hover and selection states
- **Large Preview:** 150x150 color swatch with RGB888/BGR555/Hex display
- Real-time color updates during slider drag
- 24 palette support with Left/Right navigation
- Copy/paste colors between palette slots
- Save to ROM functionality

### Controls
| Key | Action |
|-----|--------|
| Left/Right | Navigate palettes |
| 1 | Copy current color |
| 2 | Paste copied color |
| Ctrl+S | Save palette to ROM |
| ESC | Quit editor |
| Mouse Drag | Adjust RGB values |
| Mouse Click | Select color swatch |

### Color Conversion
- **RGB888:** Standard 24-bit RGB (0-255 per channel)
- **BGR555:** SNES 15-bit BGR (0-31 per channel, stored backwards)
- **Formula:** `BGR555 = (B5 << 10) | (G5 << 5) | R5`

### Usage
```bash
python tools/map-editor/interactive_palette_editor.py
```

---

## 3. Interactive SFX Editor
**File:** `tools/map-editor/interactive_sfx_editor.py` (669 lines)

### Purpose
Edit sound effect parameters with visual feedback and draggable controls.

### Features
- **DraggableSlider:** 600x35 sliders with optional center lines
- **Volume Control:** 0-127 with visual volume bar
- **Pitch Control:** 0-127 (64 = normal pitch) with indicator
- **Pan Control:** 0-127 (64 = center) with L/R offset display
- **Priority Control:** 0-127 for sound mixing
- **SFX Browser:** 400x750 scrollable list of 64 effects
- Visual meters for all parameters
- Save/Reset/Test SFX buttons

### Controls
| Key | Action |
|-----|--------|
| Up/Down | Navigate SFX list |
| Ctrl+S | Save SFX to ROM |
| ESC | Quit editor |
| Mouse Drag | Adjust parameters |
| Mouse Wheel | Scroll SFX list |

### Parameter Ranges
- **Volume:** 0 (silent) to 127 (loudest)
- **Pitch:** 0 (lowest) to 127 (highest), 64 = normal
- **Pan:** 0 (full left) to 127 (full right), 64 = center
- **Priority:** 0 (lowest) to 127 (highest priority)

### Usage
```bash
python tools/map-editor/interactive_sfx_editor.py
```

---

## 4. Sprite Composition Editor
**File:** `tools/map-editor/sprite_editor.py` (636 lines)

### Purpose
Build multi-tile sprites by arranging 8x8 tiles on variable-size canvases.

### Features
- **TileGridCell:** 48x48 tile cells, 12 per row, 256 tiles
- **SpriteCanvas:** Variable grid size based on sprite dimensions
- **6 Sprite Sizes:** 8x8, 16x16, 24x24, 32x32, 16x32, 32x64
- Multi-tile positioning (64px per 8x8 tile)
- Left click to place tile, right click to remove
- Sprite list showing last 10 saved sprites
- to_sprite() conversion to Sprite object

### Controls
| Key | Action |
|-----|--------|
| Left Click | Place selected tile |
| Right Click | Remove tile |
| Mouse Wheel | Scroll tile grid |
| ESC | Quit editor |

### Sprite Sizes
| Size | Tiles | Use Case |
|------|-------|----------|
| 8x8 | 1 | Small objects, icons |
| 16x16 | 4 | Characters, enemies |
| 24x24 | 9 | Medium sprites |
| 32x32 | 16 | Large characters |
| 16x32 | 8 | Tall sprites |
| 32x64 | 32 | Very large sprites |

### Usage
```bash
python tools/map-editor/sprite_editor.py
```

---

## 5. Enhanced Tile Editor
**File:** `tools/map-editor/enhanced_tile_editor.py` (735 lines)

### Purpose
Advanced 8x8 tile editing with copy/paste, undo/redo, and drawing tools.

### Features
- **TileClipboard:** Copy/paste entire tiles or regions
- **50-Level Undo Stack:** Full history with deepcopy
- **5 Drawing Tools:**
  - Pencil: Freehand pixel drawing
  - Fill: Flood fill algorithm (stack-based)
  - Line: Bresenham line drawing
  - Rectangle: Outline or filled rectangles
  - Select: Region selection for copy/paste
- **4 Transformations:**
  - Flip Horizontal/Vertical
  - Rotate Clockwise/Counter-clockwise
- 48px per pixel canvas (384x384 total)
- 32px palette swatches (2 rows × 8)

### Controls
| Key | Action |
|-----|--------|
| Ctrl+C | Copy tile/region |
| Ctrl+V | Paste tile/region |
| Ctrl+Z | Undo |
| Ctrl+Y | Redo |
| Ctrl+S | Save tile |
| C | Clear canvas |
| 1-5 | Select tool (Pencil/Fill/Line/Rect/Select) |
| H/V | Flip horizontal/vertical |
| R/L | Rotate right/left |
| ESC | Quit editor |

### Flood Fill Algorithm
```python
def flood_fill(x, y, target_color, replacement_color):
    stack = [(x, y)]
    while stack:
        px, py = stack.pop()
        if pixels[py][px] == target_color:
            pixels[py][px] = replacement_color
            # Add neighbors to stack
```

### Usage
```bash
python tools/map-editor/enhanced_tile_editor.py
```

---

## 6. Map Event Editor
**File:** `tools/map-editor/map_event_editor.py` (582 lines)

### Purpose
Visual placement and configuration of map events (NPCs, treasures, warps, triggers).

### Features
- **9 Event Types:**
  - NPC: Non-player characters
  - Treasure: Treasure chests
  - Warp: Map transitions
  - Trigger: Story triggers
  - Sign: Read-only signs
  - Door: Doors with locks
  - Chest: Openable containers
  - Switch: Toggle switches
  - Cutscene: Scripted events
- **8 Trigger Conditions:**
  - Always, Once, Flag Set/Clear, Item Have/Not Have, Party Size, Story Progress
- **MapCanvas:** 1100x750 interactive grid (32x32 map, 20px tiles)
- **EventPalette:** Color-coded event selector (250x400)
- **EventPropertyPanel:** Displays event details (440x330)
- Visual event colors: NPC (green), Treasure (gold), Warp (purple), Trigger (red)
- JSON export with full event data

### Controls
| Key | Action |
|-----|--------|
| Left Click | Place event |
| Right Click | Remove event |
| Mouse Wheel | Scroll map |
| Ctrl+S | Save events |
| Ctrl+E | Export JSON |
| ESC | Quit editor |

### Event Data Structure
```python
@dataclass
class MapEvent:
    event_id: int
    type: EventType
    position: Tuple[int, int]
    sprite: int
    dialog: str
    item: int
    warp: Tuple[int, int, int]  # (map_id, x, y)
    trigger: TriggerCondition
```

### Usage
```bash
python tools/map-editor/map_event_editor.py
```

---

## 7. Warp Connection Editor
**File:** `tools/map-editor/warp_editor.py` (696 lines)

### Purpose
Visualize and edit map-to-map warp connections with interactive connection lines.

### Features
- **8 Warp Types:** Door, Stairs Up/Down, Cave Entrance/Exit, Teleport, World Map, Dungeon
- **MapInfo:** Map metadata with grid positioning
- **Warp:** Source/dest maps with tile coordinates
- **MapCell:** 150x150 visual map cells in 8-column grid
- **WarpVisual:** Connection lines with arrowheads
- Click warps to select and view properties
- 16 test FFMQ maps included
- 23 test warp connections
- JSON export with full warp data

### Controls
| Key | Action |
|-----|--------|
| Left Click | Select warp/map |
| Delete | Remove selected warp |
| Ctrl+N | New warp |
| Ctrl+S | Save to ROM |
| Ctrl+E | Export JSON |
| Mouse Wheel | Scroll map grid |
| ESC | Quit editor |

### Warp Data Structure
```python
@dataclass
class Warp:
    warp_id: int
    source_map_id: int
    source_x: int  # Tile coordinates
    source_y: int
    dest_map_id: int
    dest_x: int
    dest_y: int
    warp_type: WarpType
    name: str
    enabled: bool
```

### Visual System
- Source warps: Green circles
- Destination warps: Red circles
- Connection lines: Gray arrows with arrowheads
- Selected warps: Yellow highlight

### Usage
```bash
python tools/map-editor/warp_editor.py
```

---

## 8. Palette Library Tool
**File:** `tools/graphics/palette_library.py` (827 lines)

### Purpose
Advanced palette management with sharing, comparison, and batch operations.

### Features
- **Color Operations:**
  - Distance calculation (Euclidean RGB space)
  - Luminance calculation (0.299R + 0.587G + 0.114B)
  - Hue sorting via HSV conversion
- **Palette Operations:**
  - Copy/paste entire palettes
  - Sort by luminance or hue
  - Find closest color
  - Remap color indices
  - Shift colors
- **Comparison View:** Side-by-side palette comparison with:
  - Color distance analysis
  - Similarity percentage
  - Difference highlighting
- **8 Default Palettes:** Hero, Forest, Fire, Water, Skeleton, Slime, Town, UI
- JSON import/export for sharing
- 2-column scrollable library (700x810)

### Controls
| Key | Action |
|-----|--------|
| Left Click | Select palette |
| Ctrl+C | Copy palette |
| Ctrl+V | Paste palette |
| Ctrl+E | Export JSON |
| Ctrl+I | Import JSON |
| Mouse Wheel | Scroll library |
| ESC | Quit tool |

### Palette Operations
```python
palette.sort_by_luminance()  # Dark to light
palette.sort_by_hue()  # Rainbow order
palette.find_closest_color(Color(r, g, b))  # Index
palette.shift_colors(amount)  # Rotate indices
```

### Comparison Analysis
- **Different Colors:** Count colors that differ
- **Average Distance:** Mean Euclidean distance
- **Similarity:** Percentage of identical colors

### Usage
```bash
python tools/graphics/palette_library.py
```

---

## 9. Batch Tile Operations
**File:** `tools/graphics/batch_tile_ops.py` (746 lines)

### Purpose
Batch processing, transformations, and analysis for large tile sets.

### Features
- **Transformations:**
  - Flip horizontal/vertical
  - Rotate 90° clockwise/counter-clockwise
  - Invert color indices (15 - index)
  - Shift colors (wrap at 16)
- **Color Operations:**
  - Replace color
  - Remap colors via dictionary
  - Grayscale conversion
- **Analysis:**
  - Count unique colors per tile
  - Find similar tiles
  - Color usage statistics
  - Remove duplicate tiles
- **Batch Selection:** Multi-select with Ctrl+Click
- **20-Level Undo:** Full operation history
- **27 Test Tiles:** Procedural patterns (solid, checkerboard, gradients, shapes)
- JSON export with metadata

### Controls
| Key | Action |
|-----|--------|
| Left Click | Select tile |
| Ctrl+Click | Multi-select |
| Ctrl+A | Select all |
| Ctrl+Z | Undo |
| Ctrl+E | Export JSON |
| Mouse Wheel | Scroll tile grid |
| ESC | Quit tool |

### Tile Operations
```python
tile.flip_horizontal()  # Mirror left-right
tile.flip_vertical()  # Mirror top-bottom
tile.rotate_cw()  # 90° clockwise
tile.invert_colors()  # 15 - color_index
tile.shift_colors(n)  # (index + n) % 16
tile.replace_color(old, new)  # Replace all
tile.count_colors()  # Unique colors used
```

### Batch Examples
1. **Flip All Selected:** Select tiles → Click "Flip H" → All tiles flip
2. **Find Duplicates:** Click "Remove Duplicates" → Identical tiles removed
3. **Color Variants:** Select tile → "Generate Variants" → Creates shifted versions
4. **Similar Tiles:** Select reference → "Find Similar" → Highlights matching complexity

### Usage
```bash
python tools/graphics/batch_tile_ops.py
```

---

## 10. Game Metadata Editor
**File:** `tools/data/metadata_editor.py` (823 lines)

### Purpose
Edit game data tables: enemies, items, weapons, armor, spells, and shops.

### Features
- **6 Data Categories:**
  - Enemies: HP, attack, defense, speed, magic, drops
  - Items: Type, effect, value, sellable
  - Weapons: Attack, accuracy, critical, element
  - Armor: Defense, magic defense, type, resistance
  - Spells: MP cost, power, type, target
  - Shops: Location, type, inventory, prices
- **TextField System:** Editable text inputs with:
  - Numeric validation
  - Tab/Enter navigation
  - Cursor blinking
  - Click activation
- **DataList:** Scrollable entry browser
- **EditorPanel:** Dynamic field layout (2 columns)
- Test data for all categories
- JSON export for all data
- New entry creation
- Entry deletion with confirmation

### Controls
| Key | Action |
|-----|--------|
| Left Click | Select entry |
| Tab/Enter | Move between fields |
| Ctrl+S | Apply changes |
| Ctrl+E | Export JSON |
| Mouse Wheel | Scroll entry list |
| ESC | Quit editor |

### Data Structures

#### Enemy
```python
@dataclass
class Enemy:
    enemy_id: int
    name: str
    hp: int
    attack: int
    defense: int
    speed: int
    magic: int
    exp: int
    gold: int
    level: int
    weakness: str
    resistance: str
    drops: List[str]
```

#### Item
```python
@dataclass
class Item:
    item_id: int
    name: str
    description: str
    item_type: str  # Consumable/Key/Quest
    effect: str
    value: int
    sellable: bool
```

#### Weapon/Armor
```python
@dataclass
class Weapon:
    weapon_id: int
    name: str
    attack: int
    accuracy: int
    critical_rate: int
    element: str
    special_effect: str
    cost: int
```

#### Spell
```python
@dataclass
class Spell:
    spell_id: int
    name: str
    mp_cost: int
    power: int
    accuracy: int
    spell_type: str  # Attack/Heal/Buff/Debuff
    element: str
    target: str  # Single/All Enemies/All Allies/Self
    description: str
```

### Workflow
1. Select category (Enemies, Items, etc.)
2. Click entry in list to edit
3. Modify fields as needed
4. Press Ctrl+S to apply changes
5. Create new entries or delete existing
6. Export all data to JSON

### Usage
```bash
python tools/data/metadata_editor.py
```

---

## Common Features Across All Editors

### UI Consistency
- **60 FPS rendering** for smooth interaction
- **Color-coded feedback:** Success (green), Warning (yellow), Error (red)
- **Status messages** with 3-second timers
- **Professional styling** with consistent panel layouts
- **Hover states** for all interactive elements
- **Border highlighting** for selection

### Design Patterns
- **Component-based:** Reusable Button, Slider, Panel classes
- **Dataclass-driven:** Type-safe data structures
- **Event-driven:** pygame event handling with callbacks
- **Export-ready:** JSON serialization for all data

### File Organization
```
tools/
├── graphics/
│   ├── batch_tile_ops.py       # Batch tile operations
│   └── palette_library.py      # Palette management
├── map-editor/
│   ├── animation_editor.py     # Animation system
│   ├── enhanced_tile_editor.py # Advanced tile editing
│   ├── interactive_palette_editor.py  # Palette editing
│   ├── interactive_sfx_editor.py      # SFX parameters
│   ├── map_event_editor.py     # Map events
│   ├── sprite_editor.py        # Sprite composition
│   └── warp_editor.py          # Warp connections
└── data/
    └── metadata_editor.py      # Game data tables
```

---

## Integration Guide

### Embedding in game_editor.py
```python
# Import panels
from animation_editor import AnimationEditor
from palette_editor import PaletteEditorPanel
# ...

# Create instances
self.animation_panel = AnimationEditor(...)
self.palette_panel = PaletteEditorPanel(...)

# Add to tabs
self.tabs = [
    # ... existing tabs ...
    ("Animation", self.animation_panel),
    ("Palette", self.palette_panel),
    # ...
]
```

### Sharing Data Between Editors
```python
# Shared palette reference
palette = load_palette_from_rom()

# Pass to editors
tile_editor.set_palette(palette)
sprite_editor.set_palette(palette)

# Update when changed
def on_palette_change(new_palette):
    tile_editor.set_palette(new_palette)
    sprite_editor.set_palette(new_palette)
```

### ROM Integration
```python
# Read from ROM
def load_tiles_from_rom(rom_path, offset, count):
    with open(rom_path, 'rb') as f:
        f.seek(offset)
        data = f.read(count * 32)  # 32 bytes per 4bpp tile
        return parse_tiles(data)

# Write to ROM
def save_tiles_to_rom(rom_path, offset, tiles):
    data = serialize_tiles(tiles)
    with open(rom_path, 'r+b') as f:
        f.seek(offset)
        f.write(data)
```

---

## Testing Recommendations

### Unit Tests
```python
# Color conversion
def test_bgr555_conversion():
    color = Color(255, 128, 64)
    bgr555 = color.to_bgr555()
    restored = Color.from_bgr555(bgr555)
    assert restored == color

# Tile transformations
def test_tile_flip():
    tile = create_test_tile()
    flipped = tile.flip_horizontal()
    assert flipped.pixels[0] == tile.pixels[0][::-1]
```

### Integration Tests
```python
# Editor state persistence
def test_editor_state_save():
    editor = TileEditor()
    editor.set_tile(test_tile)
    state = editor.get_state()
    
    editor2 = TileEditor()
    editor2.set_state(state)
    assert editor2.get_tile() == test_tile
```

---

## Performance Optimization

### Large Tile Sets (1000+ tiles)
```python
# Virtual scrolling - only render visible tiles
visible_range = range(
    scroll_y // tile_height,
    (scroll_y + screen_height) // tile_height
)
for i in visible_range:
    if i < len(tiles):
        draw_tile(tiles[i])
```

### Color Distance Caching
```python
# Cache color distances for palette matching
distance_cache = {}

def get_cached_distance(c1, c2):
    key = (c1.to_tuple(), c2.to_tuple())
    if key not in distance_cache:
        distance_cache[key] = c1.distance_to(c2)
    return distance_cache[key]
```

---

## Troubleshooting

### Common Issues

**Pygame not found:**
```bash
pip install pygame-ce
```

**Slow performance:**
- Reduce DISPLAY_SCALE
- Enable dirty rect updates
- Use pygame.HWSURFACE

**Wrong colors:**
- Verify BGR555 conversion
- Check palette byte order
- Validate color range (0-31 for BGR555)

**Event handling conflicts:**
- Process text fields first
- Return True when event consumed
- Check event.button for mouse clicks

---

## Future Enhancements

### Short-term
1. **ROM Integration:** Direct read/write to ROM files
2. **Undo for All:** Add undo stack to remaining editors
3. **Project Files:** Save/load editor sessions
4. **Validation:** Enforce ROM constraints

### Long-term
1. **MIDI Import:** Music from external files
2. **Pattern Library:** Reusable tile patterns
3. **Animation Blending:** Smooth transitions
4. **Batch Exports:** Export all data at once

---

## Credits
- **Development:** GitHub Copilot
- **Framework:** pygame-ce 2.5.2
- **Target:** Final Fantasy Mystic Quest (SNES)
- **Date:** November 8, 2025

---

## License
Same as FFMQ-Info project license.

