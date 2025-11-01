# Installing asar - SNES Assembler

## Critical Blocker

**You cannot build the ROM without asar installed.** This is the main blocker for establishing the baseline comparison.

## What is asar?

asar is a SNES assembler by RPGHacker that can assemble 65816 assembly code and patch it into SNES ROMs. It's essential for the byte-perfect rebuild process.

## Installation Steps

### Option 1: Download Pre-compiled Binary (Recommended)

1. **Download asar:**
   - Go to: https://github.com/RPGHacker/asar/releases
   - Download the latest Windows release (e.g., `asar-1.91-Windows.zip`)

2. **Extract:**
   ```powershell
   # Example:
   Expand-Archive -Path "Downloads\asar-1.91-Windows.zip" -DestinationPath "C:\tools\asar"
   ```

3. **Add to PATH:**
   
   **Option A: System-wide (Recommended)**
   ```powershell
   # Run as Administrator:
   [Environment]::SetEnvironmentVariable("Path", "$env:Path;C:\tools\asar", "Machine")
   # Restart PowerShell for changes to take effect
   ```
   
   **Option B: Local to this project**
   ```powershell
   # Create tools directory
   New-Item -ItemType Directory -Path "tools/bin" -Force
   
   # Copy asar.exe
   Copy-Item "C:\tools\asar\asar.exe" "tools/bin/asar.exe"
   
   # Add to PATH temporarily (only for current session)
   $env:Path += ";$(Get-Location)\tools\bin"
   ```

4. **Verify installation:**
   ```powershell
   where.exe asar
   asar --version
   ```
   
   Should show:
   ```
   asar 1.91 (or later)
   ```

### Option 2: Build from Source

If you want to build asar yourself:

1. **Clone repository:**
   ```powershell
   git clone https://github.com/RPGHacker/asar.git
   cd asar
   ```

2. **Build (requires Visual Studio or MinGW):**
   - See asar's README for build instructions
   - Not recommended unless you need specific modifications

## Post-Installation: Verify Setup

Once asar is installed, run:

```powershell
# Check asar is available
where.exe asar

# Check ROM exists
Test-Path "~roms\Final Fantasy - Mystic Quest (U) (V1.1).sfc"

# Check build directory
New-Item -ItemType Directory -Path "build" -Force
```

## Next Steps After Installation

Once asar is installed, you can:

1. **Build the ROM:**
   ```powershell
   # Copy original ROM as base
   Copy-Item "~roms\Final Fantasy - Mystic Quest (U) (V1.1).sfc" "build\ffmq-modified.sfc"
   
   # Assemble code (assuming main.asm exists)
   asar ffmq.asm build\ffmq-modified.sfc
   ```

2. **Establish Baseline:**
   ```powershell
   python tools/rom_compare.py "~roms/Final Fantasy - Mystic Quest (U) (V1.1).sfc" "build/ffmq-modified.sfc" --report-dir reports/initial
   ```

3. **Check results:**
   ```powershell
   # View HTML report
   Start-Process "reports\initial\comparison.html"
   
   # Or text report
   Get-Content "reports\initial\comparison.txt"
   ```

## Troubleshooting

### "asar not found" after installation

- Make sure you restarted PowerShell after adding to PATH
- Verify the asar.exe file exists in the directory you added to PATH
- Try using full path: `C:\tools\asar\asar.exe --version`

### "Cannot execute binary file"

- You might have downloaded the Linux version instead of Windows
- Re-download the correct Windows release

### Permission denied

- Run PowerShell as Administrator when modifying system PATH
- Or use the local project installation method instead

## Current Status

**BLOCKER:** asar is NOT installed
- `where.exe asar` returned "Could not find files"
- Cannot proceed with build until this is resolved

**What's waiting on this:**
- Building ROM from assembly
- Establishing baseline comparison
- Iterating toward 100% match
- Complete byte-perfect rebuild workflow

## Related Documentation

- [BYTE_PERFECT_REBUILD.md](BYTE_PERFECT_REBUILD.md) - Full rebuild process
- [BUILD_SYSTEM.md](BUILD_SYSTEM.md) - Build system overview
- [BUILD_QUICK_START.md](BUILD_QUICK_START.md) - Quick start guide

## External Resources

- asar GitHub: https://github.com/RPGHacker/asar
- asar Documentation: https://github.com/RPGHacker/asar/blob/master/README.md
- SNES Assembly Guide: https://ersanio.gitbook.io/assembly-for-the-snes/
