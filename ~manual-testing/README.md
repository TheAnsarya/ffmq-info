# FFMQ Manual Testing Documentation

Manual testing procedures, debugging guides, and verification workflows for Final Fantasy Mystic Quest.

## 📁 Contents

| Document | Description |
|----------|-------------|
| [ROM Verification](rom-verification.md) | Verify ROM builds match original |
| [Dialog Testing](dialog-testing.md) | Test dialog extraction and insertion |
| [Editor Testing](editor-testing.md) | Test data editors in emulator |

## 🎯 Purpose

These guides document **manual procedures** for:

- **ROM Verification** - Ensuring built ROMs match original byte-for-byte
- **Dialog Testing** - Verifying text extraction/insertion roundtrips
- **Editor Testing** - Testing monster/item/spell editor changes in-game
- **Build Validation** - Manual verification of build pipeline

## 🔧 Prerequisites

### Required Software

| Tool | Purpose |
|------|---------|
| **Mesen-S** | SNES emulator with debugger |
| **bsnes-plus** | Alternative debugger |
| **HxD** | Hex editor for ROM comparison |

### ROM Files

Place original ROM in `roms/` folder:
- `Final Fantasy - Mystic Quest (USA).sfc`

## 📚 Related Documentation

- [GameInfo Manual Testing](https://github.com/TheAnsarya/GameInfo/tree/main/~manual-testing)
- [FFMQ Testing Docs](https://github.com/TheAnsarya/GameInfo/tree/main/~manual-testing/game-specific/ffmq-snes)
- [Main README](../README.md)

## 📝 Quick Verification

```powershell
# Build and verify ROM
.\build.ps1
.\verify-build.ps1

# Run test suite
python -m pytest tests/
```
