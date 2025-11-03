# Images Reference

This directory contains reference images from the GameInfo repository documenting FFMQ text tables as they appear in emulator RAM viewers.

## Source

All images sourced from: https://github.com/TheAnsarya/GameInfo/tree/main/Final%20Fantasy%20Mystic%20Quest%20(SNES)/Wiki/Images

## File Types

- **PNG** - Screenshot images showing text tables in RAM
- **JSON** - Metadata for PNG files (emulator state, addresses, etc.)
- **XCF** - GIMP project files (editable source for PNG images)

## Available Images

### English Versions

| ROM Version | Files | VRAM Address |
|-------------|-------|--------------|
| US v1.0 | Text Table in RAM.png, .json, .xcf | $6300-$6fff |
| US v1.1 | Text Table in RAM.png, .json, .xcf | $6300-$6fff |
| European | Text Table in RAM.png, .json, .xcf | $6300-$6fff |
| Generic FFMQ | Text Table in RAM.png, .json, .xcf | $6300-$6fff |

### French Version

| ROM Version | Files | VRAM Address |
|-------------|-------|--------------|
| Mystic Quest Legend (F) | Text Table in RAM.png, .json, .xcf | $6200-$6fff |

### German Versions

| ROM Version | Files | VRAM Address |
|-------------|-------|--------------|
| Mystic Quest Legend (G) | Text Table in RAM.png | $6200-$6fff |
| Mystic Quest Legend (G) [!] | Text Table in RAM.png, .json, .xcf | $6200-$6fff |

### Japanese Versions

| ROM Version | Files | VRAM Address |
|-------------|-------|--------------|
| Final Fantasy USA - Mystic Quest (J) | Text Table in RAM.png | $6200-$6fff |
| Final Fantasy USA - Mystic Quest (J) [!] | Text Table in RAM.png, .json, .xcf | $6200-$6fff |

## Total Files

- **24 files** across 8 ROM variants
- **8 PNG** screenshots
- **7 JSON** metadata files
- **9 XCF** GIMP project files

## Usage

These images are referenced in the text table documentation:
- [[Final Fantasy: Mystic Quest/TBL/English|English TBL]]
- [[Final Fantasy: Mystic Quest/TBL/French|French TBL]]
- [[Final Fantasy: Mystic Quest/TBL/German|German TBL]]
- [[Final Fantasy: Mystic Quest/TBL/Japanese|Japanese TBL]]

## Screenshots Show

The RAM viewer screenshots capture:
- **Simple character table** - Direct 1:1 character mappings ($80/$90-$dd)
- **Complex/DTE table** - Compressed phrases ($3d-$7e)
- **Control codes** - Special function codes
- **Tile graphics** - How characters appear as 8×8 tiles in VRAM

## Tools

Images captured using **Mesen2** emulator's RAM viewer feature, showing VRAM at runtime during gameplay.

## Reference URLs

Direct links to images (for documentation):

```
https://raw.githubusercontent.com/TheAnsarya/GameInfo/main/Final%20Fantasy%20Mystic%20Quest%20(SNES)/Wiki/Images/Final%20Fantasy%20-%20Mystic%20Quest%20(U)%20(V1.0)%20[!]%20(SNES)%20-%20Text%20Table%20in%20RAM.png
https://raw.githubusercontent.com/TheAnsarya/GameInfo/main/Final%20Fantasy%20Mystic%20Quest%20(SNES)/Wiki/Images/Final%20Fantasy%20-%20Mystic%20Quest%20(U)%20(V1.1)%20(SNES)%20-%20Text%20Table%20in%20RAM.png
https://raw.githubusercontent.com/TheAnsarya/GameInfo/main/Final%20Fantasy%20Mystic%20Quest%20(SNES)/Wiki/Images/Mystic%20Quest%20Legend%20(E)%20[!]%20(SNES)%20-%20Text%20Table%20in%20RAM.png
https://raw.githubusercontent.com/TheAnsarya/GameInfo/main/Final%20Fantasy%20Mystic%20Quest%20(SNES)/Wiki/Images/Mystic%20Quest%20Legend%20(F)%20(SNES)%20-%20Text%20Table%20in%20RAM.png
https://raw.githubusercontent.com/TheAnsarya/GameInfo/main/Final%20Fantasy%20Mystic%20Quest%20(SNES)/Wiki/Images/Mystic%20Quest%20Legend%20(G)%20[!]%20(SNES)%20-%20Text%20Table%20in%20RAM.png
https://raw.githubusercontent.com/TheAnsarya/GameInfo/main/Final%20Fantasy%20Mystic%20Quest%20(SNES)/Wiki/Images/Final%20Fantasy%20USA%20-%20Mystic%20Quest%20(J)%20[!]%20(SNES)%20-%20Text%20Table%20in%20RAM.png
```

## Notes

- Images are hosted on GitHub, not downloaded locally
- JSON metadata contains emulator state snapshots
- XCF files allow editing/enhancement in GIMP
- All screenshots show runtime VRAM state, not ROM data
