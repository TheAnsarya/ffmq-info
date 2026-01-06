# ROM Verification Guide

How to verify that built ROMs match the original.

## Quick Verification

```powershell
# Run verification script
.\verify-build.ps1
```

## Manual Verification

### 1. Calculate Checksums

```powershell
# Original ROM
Get-FileHash "roms/Final Fantasy - Mystic Quest (USA).sfc" -Algorithm SHA256

# Built ROM  
Get-FileHash "build/ffmq.sfc" -Algorithm SHA256
```

### 2. Compare Files

```powershell
# Binary comparison
fc.exe /b "roms/Final Fantasy - Mystic Quest (USA).sfc" "build/ffmq.sfc"
```

### 3. Verify in Emulator

1. Load built ROM in Mesen-S
2. Play through intro sequence
3. Verify title screen graphics
4. Check dialog text
5. Test battle system

## Expected Results

| Check | Expected |
|-------|----------|
| File size | 1,048,576 bytes (1 MB) |
| SHA256 | (matches original) |
| Binary diff | No differences |

## Troubleshooting

### Size Mismatch
- Check for header issues
- Verify build script completed

### Content Mismatch
- Check assembly includes
- Verify data files not modified

## Related Documentation

- [Build Guide](../BUILD.md)
- [Dialog Testing](dialog-testing.md)
