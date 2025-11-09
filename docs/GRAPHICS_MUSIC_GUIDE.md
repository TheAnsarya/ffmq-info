# FFMQ Graphics & Music Editor Guide

## November 2025 Enhancement Release

### Overview

This guide covers the newly added Graphics and Music editing capabilities for Final Fantasy: Mystic Quest (FFMQ).

---

## Graphics Editor

### Features

The Graphics Editor provides comprehensive tools for editing SNES graphics data:

- **Palette Editor**: Edit 16-color palettes with RGB888 ↔ BGR555 conversion
- **Tile Editor**: Pixel-level editing of 8×8 tiles in 4bpp planar format
- **Tileset Viewer**: Browse and select tiles from tilesets
- **PNG Import/Export**: Convert between ROM graphics and standard image formats

### Getting Started

#### Running the Graphics Editor

```powershell
python tools/map-editor/graphics_editor.py path/to/ffmq.smc
```

#### Keyboard Shortcuts

- `Ctrl+S`: Save changes to ROM
- `ESC`: Quit editor
- `Mouse Wheel`: Scroll tileset viewer

### Working with Palettes

#### Palette Structure

Each palette contains 16 colors in SNES BGR555 format:
- 15-bit color (5 bits per channel)
- Stored as 2 bytes per color (32 bytes total)
- Automatic conversion to/from RGB888 for editing

#### Editing Colors

1. Click on a color swatch in the Palette Editor panel
2. The selected color displays as RGB888 and BGR555 values
3. Color adjustment sliders show current R, G, B values
4. Future versions will allow direct slider editing

#### Exporting Palettes

```python
from utils.graphics_database import GraphicsDatabase

db = GraphicsDatabase()
db.load_from_rom("ffmq.smc")
db.export_palette_to_image(palette_id=0, output_path="palette_0.png")
```

Palettes export as 16×16 PNG images (each color is a 1×16 vertical stripe).

#### Importing Palettes

```python
db.import_palette_from_image(palette_id=0, image_path="custom_palette.png")
db.save_to_rom("ffmq_modified.smc")
```

### Working with Tiles

#### Tile Structure

SNES tiles are 8×8 pixels in 4bpp planar format:
- 4 bits per pixel (16 colors from palette)
- Stored as 4 bit planes (32 bytes total)
- Support horizontal/vertical flipping

#### Editing Tiles

1. Select a tile from the Tileset Viewer (click on tile)
2. The Tile Editor shows the tile at large scale (32×32 pixels per tile pixel)
3. Click and drag to paint pixels with the selected palette color
4. Preview shows actual size (8×8 pixels)

#### Drawing Tools

- **Left Mouse Button**: Paint pixels with selected color
- **Drag**: Paint multiple pixels
- Selected color shown in "Selected Color" field

### Working with Tilesets

#### Tileset Structure

Tilesets are collections of tiles:
- Character Tileset: 256 tiles (8KB)
- Enemy Tilesets: 512 tiles each (16KB each)
- Total: 4 enemy tilesets + 1 character tileset

#### ROM Addresses

```python
TILESET_BASE = 0x080000      # Character tileset
PALETTE_BASE = 0x0C0000      # Palettes
SPRITE_BASE = 0x0A0000       # Sprite data
```

#### Exporting Tilesets

```python
db.export_tileset_to_image(
    tileset_id=0,
    palette_id=0,
    output_path="tileset_0.png",
    tiles_per_row=16
)
```

Tilesets export as PNG with configurable layout (default 16 tiles per row).

### Advanced Features

#### Color Optimization

Remove duplicate colors from palettes:

```python
removed = db.optimize_palette(palette_id=0)
print(f"Removed {removed} duplicate colors")
```

#### Finding Similar Colors

Find similar colors across all palettes:

```python
from utils.graphics_data import Color

color = Color.from_rgb888(255, 128, 64)
similar = db.find_similar_colors(color, threshold=5)

for palette_id, color_idx, pal_color in similar:
    print(f"Palette {palette_id}, Color {color_idx}: {pal_color}")
```

#### Creating Gradient Palettes

```python
from utils.graphics_data import create_gradient_palette

start = Color.from_rgb888(0, 0, 128)
end = Color.from_rgb888(255, 255, 255)
gradient_palette = create_gradient_palette(start, end)
```

---

## Music Editor

### Features

The Music Editor provides tools for editing SNES audio:

- **Track List**: Browse all music tracks
- **Track Editor**: Edit track properties (tempo, volume, looping)
- **SFX List**: Browse sound effects
- **SFX Editor**: Edit sound effect parameters
- **SPC Export**: Export tracks as SPC files for playback

### Getting Started

#### Running the Music Editor

```powershell
python tools/map-editor/music_editor.py path/to/ffmq.smc
```

#### Keyboard Shortcuts

- `Ctrl+S`: Save changes to ROM
- `ESC`: Quit editor
- `Mouse Wheel`: Scroll track/SFX lists

### Working with Music Tracks

#### Track Structure

FFMQ music tracks contain:
- **Track ID**: 0x00-0x1F (32 tracks)
- **Tempo**: 40-240 BPM
- **Volume**: 0-127
- **Loop Points**: Start and end positions for looping
- **Channel Mask**: Which of the 8 SPC700 channels are used

#### Default Track List

```python
0x00: "Title Theme"
0x01: "Overworld"
0x02: "Town Theme"
0x03: "Dungeon Theme"
0x04: "Battle Theme"
0x05: "Boss Battle"
0x06: "Final Battle"
0x07: "Victory Fanfare"
0x08: "Game Over"
0x09: "Inn/Rest"
0x0A: "Shop Theme"
0x0B: "Mystic Forest"
0x0C: "Ice Pyramid"
0x0D: "Volcano"
0x0E: "Mine Cart"
0x0F: "Ship Theme"
0x10: "Credits"
0x11: "Chocobo"
```

#### Editing Tracks

1. Select a track from the Track List
2. Track Editor shows all properties
3. Channel visualization shows which channels are active (green = active, gray = inactive)
4. Modify properties as needed
5. Save with `Ctrl+S`

#### Track Properties

- **Type**: Field, Battle, Town, Dungeon, Boss, Event, Fanfare
- **Tempo**: Beats per minute (affects playback speed)
- **Volume**: Overall track volume (0-127)
- **Channels**: Bitmask of 8 SPC700 channels
- **Loop Start/End**: Loop points in ticks
- **Data Offset/Size**: ROM location and size

### Working with Sound Effects

#### SFX Structure

Sound effects are simpler than music tracks:
- **SFX ID**: 0x00-0x3F (64 sound effects)
- **Priority**: 0-127 (higher priority interrupts lower)
- **Volume**: 0-127
- **Pitch**: 0-127 (64 = normal pitch)
- **Pan**: 0-127 (0 = left, 64 = center, 127 = right)

#### Default SFX List

```python
0x00: "Cursor Move"
0x01: "Menu Select"
0x02: "Menu Cancel"
0x03: "Menu Invalid"
0x04: "Level Up"
0x05: "Door Open"
0x08: "Attack Hit"
0x09: "Attack Miss"
0x0A: "Spell Cast"
0x0B: "Heal"
0x0C: "Item Get"
0x10: "Enemy Death"
0x11: "Explosion"
```

#### Editing SFX

1. Select a sound effect from the SFX List
2. SFX Editor shows all parameters
3. Visual sliders display volume, pitch, and pan settings
4. Modify as needed and save

### SPC Export/Import

#### Exporting Tracks

Export tracks as SPC files for playback in SPC players:

```python
from utils.music_database import MusicDatabase

db = MusicDatabase()
db.load_from_rom("ffmq.smc")
db.export_spc(track_id=0x01, output_path="overworld.spc")
```

SPC files contain:
- 256-byte header with track metadata
- 64KB SPC700 RAM dump
- 128-byte DSP register state
- Compatible with standard SPC players

#### Importing SPC Files

```python
track = db.import_spc("custom_track.spc")
if track:
    db.add_track(track)
    db.save_to_rom("ffmq_modified.smc")
```

### Advanced Features

#### Track Validation

Validate track data for issues:

```python
issues = db.validate_track(track_id=0x01)
for issue in issues:
    print(f"Warning: {issue}")
```

Common issues detected:
- Unusual tempo (< 40 or > 240 BPM)
- Invalid volume (> 127)
- Invalid loop points
- Missing track data
- Oversized track data

#### Duplicating Tracks

```python
new_track = db.duplicate_track(track_id=0x01, new_id=0x10)
if new_track:
    new_track.name = "Custom Overworld"
    db.save_to_rom()
```

#### Swapping Tracks

```python
# Swap overworld and town themes
db.swap_tracks(0x01, 0x02)
db.save_to_rom()
```

#### Finding Unused Slots

```python
unused_tracks = db.find_unused_tracks()
unused_sfx = db.find_unused_sfx()

print(f"Unused track IDs: {unused_tracks}")
print(f"Unused SFX IDs: {unused_sfx}")
```

### Note Conversion

Convert between note names and pitch values:

```python
from utils.music_data import note_to_pitch, pitch_to_note

pitch = note_to_pitch("A4")  # Returns pitch value for A4 (440Hz)
note = pitch_to_note(0x1000)  # Returns "C4"
```

Supported note format: `[C-B][#]?[0-9]` (e.g., "C#4", "A5")

---

## Integration with Game Editor

The graphics and music editors are integrated into the main Game Editor.

### Accessing Graphics/Music

1. Run the main game editor:
   ```powershell
   python tools/map-editor/game_editor.py path/to/ffmq.smc
   ```

2. Click the "Graphics" or "Music" tab

3. View statistics:
   - Graphics: Tilesets, palettes, total tiles
   - Music: Tracks, sound effects, samples, data sizes

4. Export data:
   - Graphics: Export tileset to PNG
   - Music: Export track to SPC

### Statistics Display

Press `F1` to toggle statistics display.

#### Graphics Statistics

```
Tilesets: 5
Palettes: 24
Total Tiles: 2816
Character Palettes: 8
Enemy Palettes: 16
```

#### Music Statistics

```
Music Tracks: 22
Sound Effects: 45
Samples: 28
Music Data: 32768 bytes
SFX Data: 8192 bytes
```

---

## File Structure

### Graphics Files

```
tools/map-editor/
├── utils/
│   ├── graphics_data.py       # Data structures
│   └── graphics_database.py   # ROM I/O
└── graphics_editor.py          # Visual editor
```

### Music Files

```
tools/map-editor/
├── utils/
│   ├── music_data.py          # Data structures
│   └── music_database.py      # ROM I/O
└── music_editor.py             # Visual editor
```

---

## Technical Details

### SNES Graphics Format

#### Color Format (BGR555)

```
15-bit color: 0BBBBBGGGGGRRRRR
B: Blue (5 bits, 0-31)
G: Green (5 bits, 0-31)
R: Red (5 bits, 0-31)
```

Conversion to RGB888:
```python
r8 = (r5 << 3) | (r5 >> 2)  # 5-bit to 8-bit
g8 = (g5 << 3) | (g5 >> 2)
b8 = (b5 << 3) | (b5 >> 2)
```

#### 4bpp Planar Tile Format

```
Bytes 0-1:   Plane 0 (bits 0)
Bytes 2-3:   Plane 1 (bits 1)
Bytes 4-5:   Plane 2 (bits 2)
Bytes 6-7:   Plane 3 (bits 3)
...pattern repeats for all 8 rows
```

Each pixel value = (plane3 << 3) | (plane2 << 2) | (plane1 << 1) | plane0

### SPC700 Audio Format

#### SPC File Structure

```
Offset   Size    Description
0x00     33      Magic: "SNES-SPC700 Sound File Data v0.30"
0x21     2       Version tag
0x23     1       Has ID666 tag
0x25     6       SPC registers
0x2E     32      Song title
0x4E     32      Game title
0xB5     32      Artist
0x100    65536   SPC700 RAM
0x10100  128     DSP registers
```

#### DSP Register Layout

```
Register  Purpose
0x0C      Master Volume Left
0x1C      Master Volume Right
0x2C      Echo Volume Left
0x3C      Echo Volume Right
0x0D      Echo Feedback
0x7D      Echo Delay
```

---

## Examples

### Example 1: Recolor an Enemy

```python
from utils.graphics_database import GraphicsDatabase
from utils.graphics_data import Color

# Load ROM
db = GraphicsDatabase()
db.load_from_rom("ffmq.smc")

# Get enemy palette (palette 8 = first enemy palette)
palette = db.get_palette(8)

# Change primary color to red
palette.colors[1] = Color.from_rgb888(255, 0, 0)

# Change secondary color to dark red
palette.colors[2] = Color.from_rgb888(128, 0, 0)

# Save
db.save_to_rom("ffmq_red_enemy.smc")
```

### Example 2: Speed Up Battle Music

```python
from utils.music_database import MusicDatabase

# Load ROM
db = MusicDatabase()
db.load_from_rom("ffmq.smc")

# Get battle theme (track 0x04)
track = db.get_track(0x04)

# Increase tempo by 20%
track.tempo = int(track.tempo * 1.2)

# Increase volume slightly
track.volume = min(127, track.volume + 10)

# Save
db.save_to_rom("ffmq_fast_battle.smc")
```

### Example 3: Create Custom Palette

```python
from utils.graphics_data import Palette, Color, PaletteType

# Create new palette
palette = Palette(palette_id=20, palette_type=PaletteType.SPRITE)
palette.name = "Custom Fire Palette"

# Set colors (fire theme)
palette.colors[0] = Color.from_rgb888(0, 0, 0)        # Transparent
palette.colors[1] = Color.from_rgb888(255, 255, 128)  # Bright yellow
palette.colors[2] = Color.from_rgb888(255, 200, 0)    # Yellow
palette.colors[3] = Color.from_rgb888(255, 128, 0)    # Orange
palette.colors[4] = Color.from_rgb888(255, 64, 0)     # Red-orange
palette.colors[5] = Color.from_rgb888(200, 0, 0)      # Red
palette.colors[6] = Color.from_rgb888(128, 0, 0)      # Dark red
palette.colors[7] = Color.from_rgb888(64, 0, 0)       # Very dark red

# Add to database
db = GraphicsDatabase()
db.load_from_rom("ffmq.smc")
db.palettes[20] = palette
db.save_to_rom("ffmq_custom_palette.smc")
```

### Example 4: Export All Music

```python
from utils.music_database import MusicDatabase
from pathlib import Path

# Load ROM
db = MusicDatabase()
db.load_from_rom("ffmq.smc")

# Create output directory
Path("music_export").mkdir(exist_ok=True)

# Export all tracks
for track_id, track in db.tracks.items():
    filename = f"music_export/{track_id:02X}_{track.name.replace('/', '_')}.spc"
    try:
        db.export_spc(track_id, filename)
        print(f"Exported: {filename}")
    except Exception as e:
        print(f"Error exporting {track_id:02X}: {e}")
```

---

## Troubleshooting

### Graphics Editor Issues

**Problem**: Colors look wrong after editing
- **Cause**: BGR555 ↔ RGB888 conversion precision loss
- **Solution**: Use multiples of 8 for RGB values when possible (8, 16, 24, etc.)

**Problem**: Tiles appear garbled
- **Cause**: Incorrect planar format interpretation
- **Solution**: Verify tile data is at correct ROM offset

**Problem**: Palette export produces solid colors
- **Cause**: Palette contains duplicate colors
- **Solution**: Use `optimize_palette()` to remove duplicates

### Music Editor Issues

**Problem**: Exported SPC doesn't play correctly
- **Cause**: Missing or incomplete track data
- **Solution**: Verify track has valid data_offset and data_size

**Problem**: Track validation reports unusual tempo
- **Cause**: Tempo outside normal range (40-240 BPM)
- **Solution**: Adjust tempo to recommended range

**Problem**: Sound effect too quiet/loud
- **Cause**: Volume or priority conflicts
- **Solution**: Adjust volume (0-127) and priority to balance

---

## Future Enhancements

### Planned Features

- [ ] Interactive color sliders in palette editor
- [ ] Copy/paste tiles between tilesets
- [ ] Animation preview for sprites
- [ ] Music playback in editor (SPC playback)
- [ ] Sound effect preview
- [ ] Visual waveform display
- [ ] Batch palette operations
- [ ] Undo/redo support
- [ ] Tileset search and filter
- [ ] Automated palette generation

### Integration Improvements

- [ ] Direct PNG import to tiles
- [ ] Automatic sprite assembly from tiles
- [ ] MIDI import/export for music
- [ ] Tracker-style music editor
- [ ] Visual music timeline
- [ ] Sample waveform editor

---

## Credits

**Graphics System**: Complete SNES 4bpp graphics support with palette editing

**Music System**: SPC700 audio editing with track and SFX management

**Integration**: Unified into comprehensive game editor

---

## License

This editor is provided as-is for educational and modding purposes.

FFMQ is © Square (now Square Enix).
