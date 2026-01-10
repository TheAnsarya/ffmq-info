# GameInfo Universal Project Format Specification

**Version:** 1.0-draft
**Created:** 2025-01 Analysis Session
**Purpose:** Define a universal project format for ROM hacking projects

---
## ⚠️ EXISTING IMPLEMENTATION

**The .giproj format is already implemented in GameInfo!**

See the authoritative implementation at:
- [Project.cs](../../../../GameInfo/src/GameInfoTools.Core/Project/Project.cs) - Main project class (412 lines)
- [ProjectService.cs](../../../../GameInfo/src/GameInfoTools.Core/Project/ProjectService.cs) - Project management (515 lines)
- [IProjectService.cs](../../../../GameInfo/src/GameInfoTools.Core/Project/IProjectService.cs) - Interface definition (203 lines)

**Key Classes:**
- `Project` - Main project container with assets and metadata
- `ProjectMetadata` - Schema version, name, authors, game reference, ROM reference
- `AssetManifest` - List of all extracted assets with ROM offsets
- `BuildConfiguration` - Assembler settings, profiles, output config
- `GameReference` - Game ID, name, platform, region
- `RomReference` - Filename, size, CRC32, MD5, SHA1, SHA256, header info

This document describes the FFMQ-specific requirements for the universal format.

---
## Overview

The `.giproj` (GameInfo Project) format is a self-contained project file that captures all modifications to a ROM without including the original copyrighted data. This allows sharing mods legally while maintaining full reproducibility.

---

## Design Goals

1. **Legal:** Never include original ROM data
2. **Portable:** Single file or directory contains everything needed
3. **Versionable:** Git-friendly format (JSON/text-based)
4. **Extensible:** Support any game/platform
5. **Bidirectional:** Can apply to ROM and extract from ROM

---

## File Structure

### Option A: Single File (.giproj)

```json
{
  "$schema": "https://gameinfo.darkrepos.io/schemas/giproj-1.0.json",
  "version": "1.0",
  "projectName": "My FFMQ Mod",
  "author": "Modder Name",
  "description": "Custom difficulty adjustments",
  "created": "2025-01-10T12:00:00Z",
  "modified": "2025-01-10T15:30:00Z",
  
  "game": {
    "id": "ffmq-snes",
    "title": "Final Fantasy Mystic Quest",
    "platform": "snes",
    "region": "usa",
    "version": "1.0"
  },
  
  "baseRom": {
    "sha256": "abc123...",
    "sha1": "def456...",
    "md5": "789ghi...",
    "size": 1048576,
    "header": false
  },
  
  "modifications": {
    "enemies": [...],
    "items": [...],
    "spells": [...],
    "dialogs": [...],
    "graphics": [...],
    "audio": [...],
    "code": [...]
  },
  
  "assets": {
    "embedded": true,
    "graphics": {
      "title-screen.png": "base64...",
      "custom-sprite.png": "base64..."
    }
  },
  
  "patches": [
    {
      "type": "ips",
      "name": "Custom Patch",
      "data": "base64..."
    }
  ],
  
  "metadata": {
    "tags": ["difficulty", "balance", "quality-of-life"],
    "compatibility": ["v1.0-usa"],
    "requires": []
  }
}
```

### Option B: Directory Structure (.giproj.d/)

```
my-ffmq-mod.giproj.d/
├── project.json          # Main project metadata
├── modifications/
│   ├── enemies.json      # Enemy modifications
│   ├── items.json        # Item modifications
│   ├── spells.json       # Spell modifications
│   ├── dialogs.json      # Dialog modifications
│   └── code.asm          # Assembly patches
├── assets/
│   ├── graphics/
│   │   ├── title-screen.png
│   │   └── custom-sprite.png
│   └── audio/
│       └── custom-track.spc
├── patches/
│   └── custom.ips        # IPS patch (optional)
└── README.md             # Project documentation
```

---

## Modification Format

### Enemies

```json
{
  "enemies": [
    {
      "id": 0,
      "name": "Brownie",
      "changes": {
        "hp": { "original": 100, "modified": 150 },
        "attack": { "original": 20, "modified": 25 },
        "weaknesses": { "original": ["fire"], "modified": ["fire", "ice"] }
      }
    }
  ]
}
```

### Items

```json
{
  "items": [
    {
      "id": 5,
      "type": "weapon",
      "name": "Steel Sword",
      "changes": {
        "attackPower": { "original": 30, "modified": 45 }
      }
    }
  ]
}
```

### Dialogs

```json
{
  "dialogs": [
    {
      "id": 0,
      "originalText": "For years Mac...",
      "modifiedText": "Long ago Mac...",
      "controlCodes": "preserved"
    }
  ]
}
```

### Graphics

```json
{
  "graphics": [
    {
      "type": "tileset",
      "id": "character-sprites",
      "address": "0x028c80",
      "asset": "assets/graphics/custom-sprites.png",
      "format": "4bpp-planar"
    }
  ]
}
```

### Code Patches

```json
{
  "code": [
    {
      "address": "0x008000",
      "original": "18fb",
      "modified": "ea18fb",
      "description": "Add NOP before boot"
    }
  ]
}
```

---

## Implementation Phases

### Phase 1: Specification (This Document)
- [x] Define JSON schema
- [x] Define modification formats
- [x] Define asset embedding

### Phase 2: C# Reader/Writer (FFMQLib)
- [ ] `GiprojFile.cs` - Parse/serialize .giproj
- [ ] `GiprojModifications.cs` - Apply modifications to ROM
- [ ] `GiprojExporter.cs` - Extract modifications from ROM
- [ ] Unit tests

### Phase 3: Python Support (ffmq-info)
- [ ] `giproj.py` - Parse/serialize .giproj
- [ ] Integration with game_editor.py
- [ ] Import/export workflows

### Phase 4: Validation & Tools
- [ ] JSON schema validation
- [ ] Project integrity checker
- [ ] Diff tool (compare two projects)
- [ ] Merge tool (combine projects)

---

## C# Implementation Skeleton

```csharp
namespace FFMQLib;

/// <summary>
/// GameInfo Universal Project Format
/// </summary>
public class GiprojFile {
    public string Version { get; set; } = "1.0";
    public string ProjectName { get; set; } = "";
    public string Author { get; set; } = "";
    public GiprojGame Game { get; set; } = new();
    public GiprojBaseRom BaseRom { get; set; } = new();
    public GiprojModifications Modifications { get; set; } = new();
    
    public static GiprojFile Load(string path) { ... }
    public void Save(string path) { ... }
    public byte[] ApplyToRom(byte[] originalRom) { ... }
    public void ExtractFromRom(byte[] modifiedRom, byte[] originalRom) { ... }
}

public class GiprojGame {
    public string Id { get; set; } = "";
    public string Title { get; set; } = "";
    public string Platform { get; set; } = "";
    public string Region { get; set; } = "";
}

public class GiprojBaseRom {
    public string Sha256 { get; set; } = "";
    public int Size { get; set; }
    public bool Header { get; set; }
}

public class GiprojModifications {
    public List<EnemyModification> Enemies { get; set; } = [];
    public List<ItemModification> Items { get; set; } = [];
    public List<SpellModification> Spells { get; set; } = [];
    public List<DialogModification> Dialogs { get; set; } = [];
    public List<GraphicsModification> Graphics { get; set; } = [];
    public List<CodePatch> Code { get; set; } = [];
}
```

---

## Python Implementation Skeleton

```python
from dataclasses import dataclass
from typing import Optional
import json

@dataclass
class GiprojFile:
    version: str = "1.0"
    project_name: str = ""
    author: str = ""
    game: dict = None
    base_rom: dict = None
    modifications: dict = None
    
    @classmethod
    def load(cls, path: str) -> "GiprojFile":
        with open(path, "r") as f:
            data = json.load(f)
        return cls(**data)
    
    def save(self, path: str):
        with open(path, "w") as f:
            json.dump(self.__dict__, f, indent=2)
    
    def apply_to_rom(self, rom: bytes) -> bytes:
        """Apply all modifications to ROM"""
        ...
    
    def extract_from_rom(self, modified: bytes, original: bytes):
        """Extract modifications by comparing ROMs"""
        ...
```

---

## Related Documentation

- [FFMQ Completion Plan](FFMQ_COMPLETION_PLAN_2025-01.md)
- [Python Tool Documentation](../../docs/GAME_EDITOR_GUIDE.md)
- [FFMQLib C# Library](../../../logsmall/FFMQLib/)

---

## Next Steps

1. Review and finalize JSON schema
2. Create C# implementation in FFMQLib
3. Create Python implementation in ffmq-info
4. Write integration tests
5. Document workflow guides

---

*Draft specification - subject to revision*
