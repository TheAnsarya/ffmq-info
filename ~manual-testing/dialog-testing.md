# Dialog Testing Guide

Testing dialog extraction, modification, and reinsertion.

## Test Cases

### TC-1: Extract All Dialog

```powershell
python tools/dialog_extractor.py --rom roms/ffmq.sfc --output dialogs.txt
```

**Expected:** All dialog blocks extracted to text file.

### TC-2: Roundtrip Test

```powershell
# Extract
python tools/dialog_extractor.py --rom roms/ffmq.sfc --output test_dialogs.txt

# Reinsert (dry run)
python tools/dialog_inserter.py --input test_dialogs.txt --rom roms/ffmq.sfc --verify
```

**Expected:** No differences reported.

### TC-3: Modified Dialog

1. Extract dialog
2. Modify a short string (same length)
3. Reinsert
4. Verify in emulator

**Expected:** Modified text appears in-game.

### TC-4: Control Codes

Test dialog with control codes:
- `[PAUSE]` - Pause for input
- `[CLEAR]` - Clear text box
- `[NAME]` - Insert character name

**Expected:** Control codes function correctly.

## Emulator Verification

### Locations to Check

| Location | Dialog Type |
|----------|-------------|
| Intro sequence | Story text |
| Foresta village | NPC dialog |
| Battle victory | System messages |
| Item use | Item descriptions |

## Related Documentation

- [Control Codes Reference](../CONTROL_CODES_QUICK_REF.md)
- [Dialog System Features](../DIALOG_SYSTEM_FEATURES.md)
