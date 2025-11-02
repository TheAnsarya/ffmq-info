# Graphics Modding System - Quick Start

Complete guide to modding FFMQ graphics using the automated pipeline.

## ⚡ Quick Start (3 Commands)

```bash
# 1. Extract graphics (first time only)
make graphics-extract

# 2. Edit sprites in your image editor
# Open: data/extracted/sprites/enemies/enemy_18_skeleton.png
# Edit and save!

# 3. Build ROM with your changes
make rom-with-graphics
```

**Done!** Your modified ROM is at `build/ffmq-modified.sfc`

## 📁 What You Can Edit

### Enemy Sprites (83 enemies)
Location: `data/extracted/sprites/enemies/`

Examples:
- `enemy_00_brownie.png` - Gray brownie enemy
- `enemy_18_skeleton.png` - Skeleton enemy  
- `enemy_52_ice_golem.png` - Ice golem
- `enemy_82_dark_king_spider.png` - Final boss spider form

**Format:** 4BPP (16 colors max)  
**Dimensions:** Various (see metadata JSON)

### Character Battle Sprites (4 characters)
Location: `data/extracted/sprites/characters/`

- `benjamin_battle_frame0.png` through `frame3.png` (4 animation frames)
- `kaeli_battle_frame0.png` through `frame3.png`
- `phoebe_battle_frame0.png` through `frame3.png`
- `reuben_battle_frame0.png` through `frame3.png`

**Format:** 4BPP (16 colors max)  
**Dimensions:** Various per character

### UI Elements (2 elements)
Location: `data/extracted/sprites/ui/`

- `font_main.png` - Main game font
- `menu_borders.png` - Menu borders

## 🎨 Editing Guidelines

### Required
1. **Keep dimensions** - Don't change PNG size
2. **Respect palette** - Max 16 colors for 4BPP
3. **Preserve transparency** - Color index 0 is transparent
4. **Save as PNG** - Keep same filename

### Recommended Image Editors
- **Aseprite** - Best for pixel art (has palette tools)
- **GIMP** - Free, powerful (use indexed color mode)
- **Photoshop** - Works (use indexed color mode)
- **Paint.NET** - Simple and free

### Tips
- Use indexed color mode to see palette
- Zoom to 800% or more for pixel editing
- Save frequently
- Test in emulator after each change

## 🔄 Complete Workflow

### First Time Setup

```bash
# Extract all graphics from ROM
make graphics-extract
```

This creates:
- `data/extracted/sprites/enemies/*.png` (83 files)
- `data/extracted/sprites/characters/*.png` (16 files)
- `data/extracted/sprites/ui/*.png` (2 files)
- `data/extracted/palettes/enemy_palettes.json`

### Editing Workflow

1. **Choose a sprite to edit:**
   ```bash
   # Example: Edit skeleton enemy
   open data/extracted/sprites/enemies/enemy_18_skeleton.png
   ```

2. **Edit in your image editor:**
   - Open the PNG
   - Make changes (colors, design)
   - Keep same dimensions!
   - Save

3. **Rebuild and test:**
   ```bash
   # This rebuilds changed graphics AND builds ROM
   make rom-with-graphics
   
   # Open in emulator
   open build/ffmq-modified.sfc
   ```

### Advanced Workflow

```bash
# Rebuild only (no ROM build)
make graphics-rebuild

# Validate before building
make graphics-validate

# Generate ASM only
make graphics-asm

# Full rebuild (extract + rebuild)
make graphics-full
```

## 📊 What Happens Behind the Scenes

When you run `make rom-with-graphics`:

1. **Change Detection**
   - System calculates SHA256 hash of each PNG
   - Compares with build manifest
   - Identifies modified files

2. **PNG → Binary Conversion**
   - Modified PNGs converted to 4BPP tiles
   - Palettes extracted and converted to RGB555
   - Binary files saved to `data/rebuilt/`

3. **ASM Generation**
   - System reads import summaries
   - Generates `src/asm/graphics/enemies_auto.asm`
   - Creates proper `org` and `incbin` statements
   - Builds master include file

4. **ROM Build**
   - Asar assembler includes graphics
   - Binary data written to ROM addresses
   - Output: `build/ffmq-modified.sfc`

## 🗂️ File Structure

```
data/
├── extracted/              # Edit these!
│   └── sprites/
│       ├── enemies/
│       │   ├── enemy_18_skeleton.png        # Edit this
│       │   └── enemy_18_skeleton_meta.json  # Don't edit
│       ├── characters/
│       └── ui/
│
├── rebuilt/                # Auto-generated
│   └── sprites/
│       └── enemies/
│           ├── enemy_18_skeleton.bin         # Binary tiles
│           ├── enemy_18_skeleton_palette.bin # Binary palette
│           └── import_summary.json          # Build info
│
src/asm/graphics/           # Auto-generated
├── enemies_auto.asm        # Include this in your ROM
├── characters_auto.asm
└── graphics_auto.asm       # Master include

build/
├── graphics_manifest.json  # Build tracking
└── ffmq-modified.sfc      # Your modified ROM!
```

## 📝 Metadata Files

Each PNG has a matching `*_meta.json` file:

```json
{
  "name": "enemy_18_skeleton",
  "rom_offset": "0x098600",
  "palette_offset": "0x048120",
  "tile_width": 6,
  "tile_height": 6,
  "size_bytes": 1152,
  "format": "4bpp"
}
```

**Don't edit these!** They're used by the build system.

## 🎯 Example: Editing the Skeleton

Let's make the skeleton enemy have red bones instead of white:

1. **Open the file:**
   ```bash
   # In Aseprite, GIMP, etc.
   open data/extracted/sprites/enemies/enemy_18_skeleton.png
   ```

2. **Edit colors:**
   - Current: White (#FFFFFF) and yellow (#FFD652)
   - Change to: Red (#FF0000) and dark red (#8B0000)
   - Keep transparency!

3. **Save:**
   - Save as PNG (same filename)
   - Close editor

4. **Rebuild:**
   ```bash
   make rom-with-graphics
   ```
   
   Output:
   ```
   🔨 Rebuilding modified graphics...
     Found 1 modified files:
       • data/extracted/sprites/enemies/enemy_18_skeleton.png
   
     📦 Importing sprites...
       ✓ Imported 1 files
   
     🔨 Generating ASM includes...
       ✓ Generated 83 sprite includes
   
   ✅ Graphics rebuild complete!
   
   Building ROM...
   ✅ ROM built successfully!
   ```

5. **Test:**
   ```bash
   # Open in your favorite emulator
   open build/ffmq-modified.sfc
   
   # Find a skeleton enemy in game
   # See your red-boned skeleton!
   ```

## 🚀 Performance

- **First extraction:** ~3 seconds (one time)
- **Single sprite rebuild:** ~0.1 seconds
- **Full rebuild (all 83 enemies):** ~5 seconds
- **ROM build:** ~2 seconds
- **Total (single change):** ~2.5 seconds from edit to ROM!

## ❓ Troubleshooting

### "No modified graphics found"
**Problem:** System doesn't detect your changes.

**Solution:** 
- Make sure you saved the PNG
- Check the file timestamp updated
- Try: `make graphics-full` to force rebuild

### "Image has too many colors"
**Problem:** PNG has more than 16 colors (4BPP limit).

**Solution:**
- Use indexed color mode in your editor
- Reduce to max 16 colors
- Check transparency counts as color 0

### "Image dimensions must be multiples of 8"
**Problem:** You changed the PNG dimensions.

**Solution:**
- Restore original dimensions
- Tiles must be 8×8 pixels
- Check metadata JSON for correct size

### "ASM generation failed"
**Problem:** Missing metadata or corrupt files.

**Solution:**
```bash
# Validate all graphics
make graphics-validate

# Re-extract if needed
make graphics-extract
```

## 🔧 Advanced Usage

### Testing the Pipeline

```bash
# Run automated test
python tools/test_graphics_pipeline.py

# Full test with extraction
python tools/test_graphics_pipeline.py --full
```

### Manual Steps

```bash
# 1. Extract
python tools/build_integration.py --extract

# 2. Edit PNGs
# ...

# 3. Rebuild
python tools/build_integration.py --rebuild

# 4. Generate ASM
python tools/generate_graphics_asm.py

# 5. Validate
python tools/generate_graphics_asm.py --validate

# 6. Build ROM
make rom
```

### Category-Specific

```bash
# Generate ASM for enemies only
python tools/generate_graphics_asm.py --category enemies

# Import specific directory
python tools/import/import_sprites.py \
  data/extracted/sprites/enemies/ \
  data/rebuilt/sprites/enemies/
```

## 📚 Documentation

Detailed guides available:

- **BUILD_INTEGRATION.md** - Complete technical reference
- **ASAR_INTEGRATION.md** - Asar assembler integration
- **PHASE_2_COMPLETE.md** - Achievement summary

## 💡 Tips & Tricks

1. **Work on one sprite at a time** - Easier to test
2. **Keep backups** - Save originals before editing
3. **Test frequently** - Rebuild after each change
4. **Use version control** - Commit working changes
5. **Check in emulator** - Some colors look different in game
6. **Study existing sprites** - Learn from original art style

## 🎮 Testing Your Changes

### In Emulator
1. Open `build/ffmq-modified.sfc` in MesenS/Snes9x
2. Start new game or load save
3. Find the enemy you edited
4. Enter battle
5. See your custom sprite!

### Quick Enemy Locations
- **Brownie** - Hill of Destiny (first area)
- **Skeleton** - Bone Dungeon
- **Ice Golem** - Ice Pyramid
- **Dark King** - Doom Castle (final boss)

## 🏆 Example Projects

### Simple Color Swap
Change enemy colors (easiest):
- Open sprite PNG
- Select color
- Replace with new color
- Rebuild

### Design Modification
Change sprite appearance (medium):
- Sketch design on paper
- Edit pixels in sprite
- Keep same size/shape
- Test in game

### Complete Sprite Replacement
New sprite from scratch (advanced):
- Create 8×8 tiles
- Assemble into sprite
- Match dimensions exactly
- Use max 16 colors
- Test thoroughly

## ✅ Checklist

Before rebuilding, check:

- [ ] PNG saved with correct filename
- [ ] Dimensions unchanged
- [ ] Max 16 colors (4BPP)
- [ ] Transparency preserved
- [ ] Looks good at actual size (not just zoomed)

After rebuilding, verify:

- [ ] No error messages
- [ ] Binary files created in `data/rebuilt/`
- [ ] ASM files updated in `src/asm/graphics/`
- [ ] ROM built successfully
- [ ] Sprite looks correct in emulator

---

## Summary

**Three simple commands:**
```bash
make graphics-extract    # Once
# Edit PNGs
make rom-with-graphics   # Build!
```

**That's the entire workflow!** 🎉

You're now ready to create amazing FFMQ graphics mods!

---

**Need help?** Check the detailed docs in the `docs/` folder.  
**Found a bug?** Report it on GitHub.  
**Made something cool?** Share it with the community!

Happy modding! 🎨✨
