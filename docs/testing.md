# FFMQ Testing Environment

This document describes the testing environment for the Final Fantasy Mystic Quest SNES disassembly project.

## Overview

The testing environment provides:
- Automated ROM validation tests
- MesenS emulator integration
- Debug symbol generation
- Automated test scripts

## Quick Start

1. **Setup testing environment:**
   ```bash
   make test-setup
   ```

2. **Run full tests:**
   ```bash
   make test
   ```

3. **Test ROM only (no emulator):**
   ```bash
   make test-rom
   ```

4. **Launch in MesenS:**
   ```bash
   make test-launch
   ```

5. **Debug in MesenS:**
   ```bash
   make test-debug
   ```

## Testing Tools

### ROM Tester (`tools/rom_tester.py`)

Automated validation tool that checks:
- ROM header integrity
- Checksum validation
- Interrupt vector table
- Basic code structure
- Data integrity

Usage:
```bash
python tools/rom_tester.py build/ffmq-modified.sfc
```

### MesenS Integration (`tools/mesen_integration.py`)

Provides integration with MesenS emulator:
- Automatic MesenS detection
- Debug symbol generation
- Test script creation
- Launch automation

Commands:
```bash
python tools/mesen_integration.py setup          # Setup environment
python tools/mesen_integration.py launch <rom>   # Launch ROM
python tools/mesen_integration.py debug <rom>    # Launch with debugging
```

## Generated Files

The testing setup creates several files in the `build/` directory:

### Debug Files
- `ffmq_debug.mlb` - MesenS symbol file with RAM labels, ROM labels, and hardware registers
- `debug_config.json` - Debug configuration with breakpoints and watches
- `test_script.lua` - Automated test script for MesenS

### Launch Scripts
- `test_rom.bat` - Windows batch file for easy ROM testing
- `test_rom.ps1` - PowerShell script for ROM testing

## MesenS Emulator

### Installation

Download MesenS from: https://github.com/SourMesen/Mesen-S

The testing tools will automatically detect MesenS in common installation locations:
- `C:\Program Files\Mesen-S\Mesen-S.exe`
- `C:\Program Files (x86)\Mesen-S\Mesen-S.exe`
- System PATH as `mesen-s` or `mesen-s.exe`

### Debug Features

When launching with debugging (`make test-debug`), the following features are available:

1. **Memory Watches:**
   - Player Level (`$7E1010`)
   - Player HP (`$7E1014`)
   - Current Map (`$7E0E88`)

2. **Breakpoints:**
   - Game start (`$008000`)
   - Basic initialization (`$008247`)

3. **Symbol Labels:**
   - RAM variables (player stats, position, etc.)
   - ROM code labels
   - Hardware registers

### Automated Testing

The included Lua script (`build/test_script.lua`) provides automated testing:
- Runs for 30 seconds (1800 frames)
- Auto-advances through intro screens
- Monitors game state
- Logs test progress

Load the script in MesenS: **Debug → Script Window → Load Script**

## ROM Validation

The ROM tester performs comprehensive validation:

### Header Tests
- Game title verification
- ROM makeup and cartridge type
- Size validation
- RAM size check
- Country code and version

### Checksum Tests
- Header checksum verification
- Complement calculation
- Data integrity validation

### Code Structure Tests
- Interrupt vector validation
- Reset vector verification
- Initial instruction analysis

### Data Integrity Tests
- Corruption detection
- Pattern analysis
- Entropy checking

## Troubleshooting

### Common Issues

1. **MesenS not found**
   - Install MesenS from official repository
   - Add to system PATH
   - Check installation paths in `mesen_integration.py`

2. **ROM validation fails**
   - Verify base ROM integrity
   - Check build process
   - Review assembly source files

3. **Python import errors**
   - Ensure Python 3.x is installed
   - Check required modules are available

### Debug Output

Enable verbose output by running tools directly:
```bash
python tools/rom_tester.py build/ffmq-modified.sfc
python tools/mesen_integration.py setup
```

## Development Workflow

1. **Make changes** to assembly source files
2. **Build ROM** with `make rom`
3. **Test ROM** with `make test-rom`
4. **Launch in emulator** with `make test-launch`
5. **Debug if needed** with `make test-debug`

## Configuration

### MesenS Paths

Edit `tools/mesen_integration.py` to add custom MesenS installation paths:
```python
self.mesen_paths = [
    "path/to/your/mesen-s.exe",
    # ... existing paths
]
```

### Debug Symbols

Edit symbol definitions in `MesenSIntegration.create_debug_symbols()` to add custom labels.

### Test Configuration

Modify `debug_config.json` to customize breakpoints and memory watches.

## Contributing

When adding new testing features:
1. Update this documentation
2. Add tests to `rom_tester.py`
3. Update MesenS integration as needed
4. Test on multiple platforms if possible