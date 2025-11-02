# Map Editing Guide for FFMQ

Complete guide to editing maps in Final Fantasy Mystic Quest using Tiled Map Editor.

## Table of Contents
- [Quick Start](#quick-start)
- [Prerequisites](#prerequisites)
- [Map Structure](#map-structure)
- [Workflow](#workflow)
- [Tiled Editor Basics](#tiled-editor-basics)
- [Layers](#layers)
- [Events and Objects](#events-and-objects)
- [Map Properties](#map-properties)
- [Examples](#examples)
- [Troubleshooting](#troubleshooting)

## Quick Start

### Install Tiled
Download and install [Tiled Map Editor](https://www.mapeditor.org/)
- Free and open source
- Cross-platform (Windows, Mac, Linux)
- Industry-standard map editor

### Extract Maps
```bash
# Using Makefile (recommended)
make maps-extract

# Or directly
python tools/extract_maps_enhanced.py roms/FFMQ.sfc data/extracted/maps tmx,json
```

### Edit in Tiled
1. Open Tiled Map Editor
2. File → Open → Navigate to `data/extracted/maps/maps/`
3. Open any `.tmx` file (e.g., `00_Hill_of_Destiny.tmx`)
4. Edit terrain, collision, events
5. File → Save

### Import Maps
```bash
# Using Makefile (recommended)
make maps-rebuild

# Or directly
python tools/import/import_maps.py roms/FFMQ.sfc data/extracted/maps/maps roms/FFMQ_modified.sfc
```

### Test
```bash
# Test in emulator
start roms/FFMQ_modified.sfc
```

## Prerequisites

### Required Software
- **Tiled Map Editor** (v1.10+): https://www.mapeditor.org/
- **Python 3.x**: For extraction/import tools
- **SNES Emulator**: For testing (MesenS, Snes9x, etc.)

### Optional Software
- **Image Editor**: For editing tilesets (Aseprite, GIMP, etc.)
- **Hex Editor**: For advanced debugging

## Map Structure

### FFMQ Map Organization

The game has ~20 maps covering:
- **Overworld**: Hill of Destiny, connecting paths
- **Towns**: Foresta, Aquaria, Fireburg, Windia
- **Dungeons**: Bone Dungeon, Mine, Spencer Cave, etc.
- **Temples**: Libra Temple, Sand Temple, Life Temple, Sealed Temple
- **Focus Tower**: 4 floors (B1-B4)

### Map Dimensions

Maps are typically:
- **32×32 tiles**: Standard dungeon/town size
- **16×16 tiles**: Small houses, rooms
- **Tile Size**: 16×16 pixels each

### File Structure

```
data/extracted/maps/
├── maps/                      # TMX files (edit these in Tiled)
│   ├── 00_Hill_of_Destiny.tmx
│   ├── 01_Foresta.tmx
│   ├── 04_Libra_Temple.tmx
│   └── ...
├── tilesets/                  # Tileset images (auto-referenced)
│   ├── tileset_00.png
│   ├── tileset_01.png
│   └── ...
└── extraction_summary.txt     # Extraction log
```

## Workflow

### Complete Round-Trip Workflow

```
┌─────────────────┐
│  Extract Maps   │  make maps-extract
│   ROM → TMX     │  Exports to Tiled format
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Edit in Tiled │  Tiled Map Editor
│  Terrain, Events│  Visual map editing
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Import Maps   │  make maps-rebuild
│   TMX → ROM     │  Validates + Writes to ROM
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Test in Emu    │  Play and verify changes
│  Verify Changes │  Walk around, test events
└─────────────────┘
```

### Incremental Workflow

```bash
# Extract once
make maps-extract

# Edit → Rebuild → Test cycle (repeat as needed)
# Open map in Tiled, edit...
# Save in Tiled
make maps-rebuild
# Test in emulator...

# Edit more maps...
make maps-rebuild
# Test again...
```

## Tiled Editor Basics

### Opening a Map

1. **Launch Tiled**: Double-click Tiled icon
2. **Open Map**: File → Open → Browse to `data/extracted/maps/maps/`
3. **Select Map**: Choose any `.tmx` file
4. **View**: Map appears with terrain, collision, events

### Tiled Interface

```
┌─────────────────────────────────────┐
│ File  Edit  View  Map  Layer  Help  │  Menu Bar
├──────┬──────────────────────┬───────┤
│Tools │                      │Layers │
│      │                      │       │
│ ┌─┐  │   Map View Area      │ ▢ Terrain
│ │◆│  │                      │ ▢ Collision
│ ├─┤  │   (Visual editor)    │ ▢ Events
│ │⬚│  │                      │       │
│ └─┘  │                      │Properties
├──────┴──────────────────────┴───────┤
│ Status Bar                          │
└─────────────────────────────────────┘
```

### Essential Tools

| Tool | Icon | Usage | Shortcut |
|------|------|-------|----------|
| **Stamp Brush** | 🖊️ | Paint tiles | B |
| **Fill Tool** | 🪣 | Fill area with tile | F |
| **Eraser** | 🧽 | Erase tiles | E |
| **Select** | ⬚ | Select region | S |
| **Object Tool** | ◆ | Place/edit events | O |

### Basic Editing

**Paint Single Tile**:
1. Select Stamp Brush (B)
2. Click tile in tileset panel
3. Click on map to place

**Paint Multiple Tiles**:
1. Select Stamp Brush (B)
2. Click and drag in tileset to select multiple
3. Click on map to place pattern

**Fill Area**:
1. Select Fill Tool (F)
2. Click tile in tileset
3. Click on map area to fill

**Erase Tiles**:
1. Select Eraser (E)
2. Click tiles to erase (sets to tile 0)

## Layers

FFMQ maps have 3 layers:

### 1. Terrain Layer

**Purpose**: Visual map tiles (ground, walls, objects)

**Tile IDs**: 1-256 from tileset
- **0**: Empty/transparent
- **1-255**: Tileset tiles
- **256+**: Extended tiles (if used)

**Editing**:
1. Select "Terrain" layer in Layers panel
2. Use Stamp Brush to paint tiles
3. Build map layout (floors, walls, decorations)

**Tips**:
- Copy/paste tile patterns for consistency
- Use rectangular select for large areas
- Check neighboring maps for tile usage

### 2. Collision Layer

**Purpose**: Walkability/passability (where player can walk)

**Tile IDs**:
- **0**: Passable (player can walk)
- **1**: Solid (wall, obstacle)
- **2**: Water (special movement)
- **3**: Damage (lava, spikes - damages player)

**Editing**:
1. Select "Collision" layer in Layers panel
2. Layer is semi-transparent (see terrain underneath)
3. Paint collision tiles:
   - Tile 0 = walkable areas
   - Tile 1 = walls, obstacles
   - Tile 2 = water tiles
   - Tile 3 = damage tiles

**Tips**:
- Start with all solid (tile 1), carve out paths (tile 0)
- Match collision to visual terrain
- Test in-game to verify walkability
- Doors should be passable (tile 0)

### 3. Events Layer (Object Layer)

**Purpose**: Event triggers (NPCs, chests, doors, exits)

**Object Types**:
- **npc**: NPC character
- **chest**: Treasure chest
- **door**: Interior door (same map)
- **exit**: Map transition (different map)
- **trigger**: Script trigger
- **enemy**: Enemy encounter
- **switch**: Interactive switch

**Editing**: See [Events and Objects](#events-and-objects) section

### Layer Visibility

Toggle layers in the Layers panel:
- ☑️ **Visible**: Layer is shown
- ☐ **Hidden**: Layer is hidden

**Workflow Tips**:
1. Hide collision layer when editing terrain
2. Hide terrain when editing collision (easier to see)
3. Show all layers when placing events

### Layer Opacity

Adjust opacity in Layers panel:
- **100%**: Fully opaque
- **50%**: Semi-transparent (good for collision)
- **0%**: Invisible (same as hidden)

## Events and Objects

### Event Object Structure

Each event is a **16×16 pixel object** placed on the Events layer.

### Placing Events

1. **Select Object Tool** (O)
2. **Insert Object**: Click on Events layer
3. **Place on Map**: Click location to place
4. **Set Type**: In Properties panel, set "type" field
5. **Set Properties**: Add event-specific properties

### Event Types and Properties

#### NPC Event

**Type**: `npc`

**Properties**:
- `npc_id`: NPC sprite ID (which NPC graphic)
- `dialogue_id`: Dialogue text ID (what NPC says)
- `event_id`: Event script ID (optional)

**Example**:
```
Object: NPC
Type: npc
X: 128 (tile 8)
Y: 96 (tile 6)
Properties:
  npc_id: 5 (old man sprite)
  dialogue_id: 42 (specific dialogue)
```

#### Chest Event

**Type**: `chest`

**Properties**:
- `item_id`: Item contained in chest
- `opened`: 0 = closed, 1 = opened (flag)
- `event_id`: Chest event ID

**Example**:
```
Object: Treasure
Type: chest
X: 64 (tile 4)
Y: 80 (tile 5)
Properties:
  item_id: 10 (Cure item)
  opened: 0 (starts closed)
```

#### Door Event

**Type**: `door`

**Properties**:
- `destination_map`: Target map ID
- `destination_x`: Target X coordinate (tiles)
- `destination_y`: Target Y coordinate (tiles)
- `event_id`: Door event ID

**Example**:
```
Object: Exit
Type: door
X: 240 (tile 15)
Y: 128 (tile 8)
Properties:
  destination_map: 2 (Foresta House 1)
  destination_x: 8
  destination_y: 14
```

#### Exit Event (Map Transition)

**Type**: `exit`

**Properties**:
- `exit_map`: Destination map ID
- `exit_x`: Destination X coordinate
- `exit_y`: Destination Y coordinate
- `event_id`: Exit event ID

**Example**:
```
Object: Map Exit
Type: exit
X: 0 (tile 0, left edge)
Y: 160 (tile 10)
Properties:
  exit_map: 0 (Hill of Destiny)
  exit_x: 31
  exit_y: 10
```

#### Trigger Event

**Type**: `trigger`

**Properties**:
- `event_id`: Script event ID
- `param1`, `param2`, `param3`: Event parameters

**Example**:
```
Object: Story Trigger
Type: trigger
X: 144 (tile 9)
Y: 144 (tile 9)
Properties:
  event_id: 100 (boss cutscene)
  param1: 1 (trigger once flag)
```

### Adding Event Properties

1. **Select Object**: Click object with Object Tool
2. **Open Properties**: View → Properties Window (if not visible)
3. **Add Property**: Click "+" button in Properties panel
4. **Set Name**: Type property name (e.g., `npc_id`)
5. **Set Type**: Choose type (usually "int" for numbers)
6. **Set Value**: Enter value

### Editing Events

**Move Event**:
- Select Object Tool (O)
- Click and drag object

**Resize Event**:
- Select object
- Drag corner handles (keep at 16×16!)

**Delete Event**:
- Select object
- Press Delete key

**Copy/Paste Event**:
- Select object
- Ctrl+C to copy
- Ctrl+V to paste
- Move to new location

## Map Properties

### Viewing Map Properties

1. **Map Menu** → **Map Properties**
2. **Properties Panel** → Click on map background (not on layer)

### Essential Map Properties

FFMQ maps have these custom properties:

| Property | Type | Description | Example |
|----------|------|-------------|---------|
| `map_id` | int | Map ID number | 0-19 |
| `music_id` | int | Background music | 0-15 |
| `encounter_group` | int | Enemy encounter group | 0-31 |
| `palette_id` | int | Color palette | 0-7 |

### Editing Map Properties

1. **Open Map Properties**: Map → Map Properties
2. **Find Property**: Scroll to property in list
3. **Edit Value**: Click value, type new value
4. **Save**: Click OK

### Property Details

**map_id**:
- Unique identifier for this map
- Don't change (links to ROM data)
- Read-only in practice

**music_id**:
- Background music track
- 0-15 (varies by region)
- Test different values to change music

**encounter_group**:
- Which enemies appear in random battles
- 0-31
- 0 = no encounters
- Higher values = tougher enemies

**palette_id**:
- Color scheme for tiles
- 0-7
- Different palettes = different tile colors

## Examples

### Example 1: Simple Terrain Edit

**Goal**: Change floor tiles in a room

1. Open `02_Foresta_House_1.tmx` in Tiled
2. Select "Terrain" layer
3. Select Stamp Brush (B)
4. Click floor tile in tileset (e.g., tile 10)
5. Paint over existing floor tiles
6. File → Save
7. Run `make maps-rebuild`
8. Test in emulator

### Example 2: Add a Treasure Chest

**Goal**: Place a chest with an item

1. Open map in Tiled
2. Select "Events" layer
3. Select Object Tool (O)
4. Click "Insert Rectangle" button
5. Click on map where chest should appear
6. In Properties panel:
   - Set `type` = `chest`
   - Add property `item_id` = 10 (Cure)
   - Add property `opened` = 0 (closed)
7. File → Save
8. Run `make maps-rebuild`
9. Test - walk to chest location, open it

### Example 3: Create a New Door

**Goal**: Add door connecting two rooms

1. Open map in Tiled
2. Edit terrain layer:
   - Place door tile in wall (tile 25 or similar)
3. Edit collision layer:
   - Make door passable (tile 0)
4. Select "Events" layer
5. Place door event object on door tile
6. Set properties:
   - `type` = `door`
   - `destination_map` = 3 (target map ID)
   - `destination_x` = 8 (spawn X in target)
   - `destination_y` = 14 (spawn Y in target)
7. File → Save
8. Run `make maps-rebuild`
9. Test - walk through door

### Example 4: Change Map Music

**Goal**: Change background music

1. Open map in Tiled
2. Map → Map Properties
3. Find `music_id` property
4. Change value (try 1, 2, 3, etc.)
5. File → Save
6. Run `make maps-rebuild`
7. Test - listen to new music

### Example 5: Add an NPC

**Goal**: Place NPC that talks to player

1. Open map in Tiled
2. Select "Events" layer
3. Place NPC object
4. Set properties:
   - `type` = `npc`
   - `npc_id` = 5 (old man sprite)
   - `dialogue_id` = 42 (text entry ID)
5. File → Save
6. Edit text (see [TEXT_EDITING.md](TEXT_EDITING.md)):
   - Extract text: `make text-extract`
   - Edit dialogue ID 42 in `text_complete.json`
   - Import text: `make text-rebuild`
7. Run `make maps-rebuild`
8. Test - talk to NPC

## Troubleshooting

### Issue: Map doesn't load in Tiled

**Cause**: TMX file corrupted or wrong version

**Fix**:
- Re-extract: `make maps-extract`
- Check Tiled version (need 1.10+)
- Verify file isn't corrupted

### Issue: Tileset images missing

**Cause**: Tileset PNG files not extracted

**Fix**:
- Run overworld extraction: `make overworld-extract`
- Check `data/extracted/tilesets/` exists
- Verify PNG files present

### Issue: Changes don't appear in game

**Possible Causes**:
1. Forgot to rebuild: Run `make maps-rebuild`
2. Wrong ROM loaded in emulator
3. Changes not saved in Tiled
4. Event properties incorrect

**Debug Steps**:
1. Save in Tiled (Ctrl+S)
2. Run `make maps-rebuild`
3. Close emulator completely
4. Re-open modified ROM
5. Navigate to edited map

### Issue: "Validation failed" error

**Cause**: Map data doesn't match expected format

**Fix**:
- Check map dimensions (must be 16×16, 32×32, or 64×64)
- Verify terrain layer exists
- Check tile IDs (must be 0-1023)
- Ensure events are within map bounds

### Issue: Player can walk through walls

**Cause**: Collision layer not set correctly

**Fix**:
1. Open map in Tiled
2. Select "Collision" layer
3. Paint tile 1 (solid) on walls
4. Paint tile 0 (passable) on floors
5. Save and rebuild

### Issue: Events not triggering

**Possible Causes**:
1. Event type incorrect
2. Event properties missing
3. Event outside map bounds
4. Event IDs don't match ROM data

**Debug Steps**:
1. Check event type is correct (`npc`, `chest`, etc.)
2. Verify all required properties are set
3. Check event coordinates (X, Y)
4. Test with simple event first

### Issue: Door goes to wrong location

**Cause**: Destination properties incorrect

**Fix**:
1. Check `destination_map` ID (correct map?)
2. Verify `destination_x` and `destination_y` coordinates
3. Remember: coordinates are in tiles, not pixels
4. Test destination map exists

## Advanced Topics

### Creating New Maps

1. **Tiled**: File → New → New Map
2. **Settings**:
   - Orientation: Orthogonal
   - Tile layer format: CSV
   - Tile size: 16×16 pixels
   - Map size: 32×32 tiles (or 16×16)
3. **Add Tileset**: Map → Add External Tileset
4. **Create Layers**:
   - Layer → New → Tile Layer → "Terrain"
   - Layer → New → Tile Layer → "Collision"
   - Layer → New → Object Layer → "Events"
5. **Set Properties**: Map → Map Properties (add map_id, music_id, etc.)
6. **Design Map**: Paint terrain, collision, add events
7. **Save**: File → Save As → `data/extracted/maps/maps/20_New_Map.tmx`

**Note**: New maps require ROM hacking knowledge to integrate fully.

### Batch Map Editing

Edit multiple maps programmatically using Python:

```python
import xml.etree.ElementTree as ET
from pathlib import Path

# Change music in all town maps
for tmx_file in Path('data/extracted/maps/maps').glob('*Town*.tmx'):
    tree = ET.parse(tmx_file)
    root = tree.getroot()
    
    # Find music_id property
    props = root.find('.//properties')
    for prop in props.findall('property'):
        if prop.get('name') == 'music_id':
            prop.set('value', '5')  # New music ID
    
    # Save modified TMX
    tree.write(tmx_file)
```

### Exporting to Other Formats

Tiled supports many export formats:
- **JSON**: File → Export As → JSON
- **Lua**: File → Export As → Lua
- **CSV**: Layer → Export As → CSV (per-layer)

Useful for custom tools or analysis.

## Quick Reference

### Common Commands

```bash
# Extract maps
make maps-extract

# Rebuild maps
make maps-rebuild

# Full pipeline
make maps-pipeline

# Direct import
python tools/import/import_maps.py roms/FFMQ.sfc data/extracted/maps/maps roms/FFMQ_modified.sfc
```

### Keyboard Shortcuts (Tiled)

```
B - Stamp Brush
F - Fill Tool
E - Eraser
S - Select
O - Object Tool
Ctrl+S - Save
Ctrl+Z - Undo
Ctrl+Y - Redo
Ctrl+C - Copy
Ctrl+V - Paste
Delete - Delete selected
```

### Collision Tile IDs

```
0 - Passable (walk here)
1 - Solid (wall, obstacle)
2 - Water (special movement)
3 - Damage (lava, spikes)
```

### Event Types

```
npc     - NPC character
chest   - Treasure chest
door    - Interior door
exit    - Map exit/entrance
trigger - Script trigger
enemy   - Enemy encounter
switch  - Interactive switch
```

### File Locations

```
data/extracted/maps/
├── maps/                       # TMX files (edit in Tiled)
│   ├── 00_Hill_of_Destiny.tmx
│   ├── 01_Foresta.tmx
│   └── ...
└── tilesets/                   # Tileset PNGs (auto-referenced)
    ├── tileset_00.png
    └── ...
```

## Support

For issues or questions:
- Check this guide's [Troubleshooting](#troubleshooting) section
- Review [Tiled Manual](https://doc.mapeditor.org/en/stable/)
- See `docs/PHASE_3_COMPLETE.md` for system overview
- Check `tools/extract_maps_enhanced.py` source code

---

**Next Steps**: Once you're comfortable with map editing, try:
- [Text Editing Guide](TEXT_EDITING.md) - Edit dialogue and text
- [Graphics Editing Guide](BUILD_INTEGRATION.md) - Edit sprites
- [Complete ROM Building](PHASE_3_COMPLETE.md) - Build with all mods
