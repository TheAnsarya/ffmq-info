# FFMQ Graphics Extraction Report

**Generated:** 2025-11-01 18:08:22
**Total Assets:** 22
**Total Size:** 0.64 MB

## Overview

This report catalogs all extracted graphics assets from Final Fantasy: Mystic Quest.

## Statistics

### Asset Breakdown by Category

| Category | Count | Size (MB) |
|----------|-------|-----------|
| Palettes | 15 | 0.09 |
| Sprites | 2 | 0.13 |
| Tiles | 4 | 0.42 |
| Uncategorized | 1 | 0.00 |

### File Type Distribution

| Type | Count |
|------|-------|
| BIN | 8 |
| JSON | 4 |
| MD | 2 |
| PNG | 7 |
| TXT | 1 |


### Image Assets

- **Total Image Files:** 7
- **Total Binary Files:** 8
- **Total Pixels:** 742,400

## Asset Categories


### Palettes (15 assets)


#### BIN Files

| Filename | Size | Dimensions | Description |
|----------|------|------------|-------------|
| `battle_bg_palettes.bin` | 0.1 KB | N/A | Color palette data |
| `bg_palettes.bin` | 0.2 KB | N/A | Color palette data |
| `character_palettes.bin` | 0.2 KB | N/A | Color palette data |
| `enemy_palettes.bin` | 0.5 KB | N/A | Color palette data |
| `main_palettes_palette.bin` | 0.5 KB | N/A | Main tileset |

#### JSON Files

| Filename | Size | Dimensions | Description |
|----------|------|------------|-------------|
| `battle_bg_palettes.json` | 8.6 KB | N/A | Color palette data |
| `bg_palettes.json` | 17.2 KB | N/A | Color palette data |
| `character_palettes.json` | 17.2 KB | N/A | Color palette data |
| `enemy_palettes.json` | 34.3 KB | N/A | Color palette data |

#### MD Files

| Filename | Size | Dimensions | Description |
|----------|------|------------|-------------|
| `SPRITE_GUIDE.md` | 1.0 KB | N/A | Sprite graphics |

#### PNG Files

| Filename | Size | Dimensions | Description |
|----------|------|------------|-------------|
| `battle_bg_palettes_preview.png` | 0.5 KB | 256x64 | Color palette data |
| `bg_palettes_preview.png` | 0.9 KB | 256x128 | Color palette data |
| `character_palettes_preview.png` | 1.0 KB | 256x128 | Color palette data |
| `enemy_palettes_preview.png` | 1.8 KB | 256x256 | Color palette data |

#### TXT Files

| Filename | Size | Dimensions | Description |
|----------|------|------------|-------------|
| `main_palettes_palette.txt` | 9.1 KB | N/A | Main tileset |

### Sprites (2 assets)


#### BIN Files

| Filename | Size | Dimensions | Description |
|----------|------|------------|-------------|
| `sprite_tiles_raw.bin` | 67.0 KB | N/A | Sprite graphics |

#### PNG Files

| Filename | Size | Dimensions | Description |
|----------|------|------------|-------------|
| `sprite_tiles.png` | 65.0 KB | 128x1072 | Sprite graphics |

### Tiles (4 assets)


#### BIN Files

| Filename | Size | Dimensions | Description |
|----------|------|------------|-------------|
| `extra_tiles_raw.bin` | 6.0 KB | N/A | Additional tiles |
| `main_tiles_raw.bin` | 217.5 KB | N/A | Main tileset |

#### PNG Files

| Filename | Size | Dimensions | Description |
|----------|------|------------|-------------|
| `extra_tiles.png` | 5.6 KB | 128x96 | Additional tiles |
| `main_tiles.png` | 199.0 KB | 128x3480 | Main tileset |

### Uncategorized (1 assets)


#### MD Files

| Filename | Size | Dimensions | Description |
|----------|------|------------|-------------|
| `README.md` | 1.9 KB | N/A |  |


## Directory Structure

```
assets/graphics/
├── palettes/          # Extracted color palettes
├── tiles/             # Tile graphics (backgrounds, tilesets)
├── sprites/           # Character and enemy sprites
├── ui/                # User interface graphics
├── backgrounds/       # Background images
└── fonts/             # Font/text graphics
```

## Extraction Tools

- `tools/extract_graphics.py` - Main graphics extractor
- `tools/extract_palettes.py` - Palette extraction
- `tools/palette_manager.py` - Palette management CLI
- `tools/graphics_converter.py` - Format conversion utilities

## Related Documentation

- [ROM_DATA_MAP.md](ROM_DATA_MAP.md) - ROM data structure documentation
- [palette_book.html](../reports/palette_book.html) - Visual palette reference

## Uncatalogued Regions

Areas of the ROM that may contain graphics data but haven't been extracted yet:

- **Bank $0A:** Additional compressed graphics
- **Bank $0E:** Compressed tileset data
- **Bank $0F:** Unknown graphics regions

## Next Steps

- [ ] Extract remaining compressed graphics from Banks $0A, $0E, $0F
- [ ] Catalog all sprite animation frames
- [ ] Extract and document all UI elements
- [ ] Create sprite sheet assemblies
- [ ] Generate tile usage maps

---

**End of Graphics Extraction Report**
