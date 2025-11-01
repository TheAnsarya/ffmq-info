# ASM File Backups

This directory contains backups of ASM source files before formatting changes.

## Current Backup

**Date**: November 1, 2025  
**Purpose**: Pre-formatting backup before applying ASM code formatting standardization  
**Issue**: #13 - ASM Formatting: Prerequisites and Setup  
**Directory**: `asm_pre_formatting_2025-11-01_003601/`

### Backed Up Files

All `.asm` files from `src/asm/` including:
- Main documented banks (bank_00 through bank_0F)
- Section files (bank_00_section2-5)
- Master assembly files (ffmq_*.asm)
- Engine files (graphics_engine.asm, text_engine.asm)
- Historical versions
- Generated files

## How to Restore

If formatting changes cause issues, you can restore files from this backup:

```powershell
# Restore all files
Copy-Item -Path backups/asm_pre_formatting_2025-11-01_003601/* -Destination src/asm/ -Recurse -Force

# Restore specific file
Copy-Item -Path backups/asm_pre_formatting_2025-11-01_003601/bank_00_documented.asm -Destination src/asm/
```

## Backup Process

Backups are created automatically by the formatting scripts before any changes are applied.

### Manual Backup Command

```powershell
$backupDir = "backups/asm_pre_formatting_$(Get-Date -Format 'yyyy-MM-dd_HHmmss')"
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
Copy-Item -Path src/asm/* -Destination $backupDir -Recurse
```

## Important Notes

- ⚠️ **Do not modify backup files** - they are reference copies only
- ✅ **Verify backups** before applying changes
- 📦 **Keep backups** until formatting is verified and ROM builds successfully
- 🔄 **Create new backups** for each major formatting change

## Verification

After restoring from backup, always:
1. Build the ROM
2. Compare with original ROM hash
3. Run any tests to ensure functionality
4. Check that all files assembled correctly

---

**Last Updated**: November 1, 2025  
**Related Issue**: #13  
**Status**: Initial backup created ✅
