# Build Tools

This directory contains tools for building, verifying, and managing ROM compilation from assembly source code.

## Core Build System

### Primary Build Tools
- **build_rom.py** ⭐ - Main ROM build script
  - Assembles source code into ROM
  - Validates output against reference ROM
  - Generates build reports
  - Supports incremental builds
  - Usage: `python tools/build/build_rom.py [--clean] [--verbose]`

- **build_and_compare.py** - Build and auto-compare with reference
  - Builds ROM from source
  - Automatically compares with original ROM
  - Highlights differences
  - Generates diff reports
  - Usage: `python tools/build/build_and_compare.py`

### Build Verification
- **verify_build_integration.py** ⭐ - Comprehensive build verification
  - Checks byte-perfect output
  - Validates all data sections
  - Verifies labels and symbols
  - Tests ROM functionality
  - Usage: `python tools/build/verify_build_integration.py`

- **quick_verify.py** - Fast build verification
  - Quick checksum validation
  - Basic structure checks
  - Rapid iteration testing
  - Usage: `python tools/build/quick_verify.py`

- **verify_roundtrip.py** - Round-trip verification
  - Disassemble → Reassemble → Compare
  - Ensures data preservation
  - Validates conversion accuracy
  - Usage: `python tools/build/verify_roundtrip.py`

### ROM Comparison
- **compare_roms.py** - Detailed ROM comparison
  - Byte-by-byte comparison
  - Visual diff output
  - Address mapping
  - Change highlighting
  - Usage: `python tools/build/compare_roms.py <rom1.smc> <rom2.smc> [--output report.txt]`

## Advanced Build Tools

### ASM Generation
- **build_asm_from_json.py** - Generate assembly from JSON data
  - Converts JSON data structures to assembly
  - Maintains formatting standards
  - Validates data integrity
  - Creates documented output
  - Usage: `python tools/build/build_asm_from_json.py --input <data.json> --output <file.asm>`

### Integration Tools
- **build_integration.py** - Build system integration
  - Coordinates multiple build steps
  - Manages dependencies
  - Handles build artifacts
  - Runs validation suite
  - Usage: `python tools/build/build_integration.py`

- **build_integration_helper.py** - Build integration utilities
  - Helper functions for integration
  - Path management
  - File operations
  - Logging utilities
  - Usage: Import as module

## PowerShell Build Scripts

### Build System Management
- **Build-System.ps1** - Main PowerShell build orchestrator
  - Orchestrates full build process
  - Manages build configuration
  - Handles error recovery
  - Generates build logs
  - Usage: `.\tools\build\Build-System.ps1 [-Clean] [-Verbose]`

- **Build-Validator.ps1** - PowerShell validation script
  - Validates build output
  - Runs test suite
  - Checks ROM integrity
  - Generates validation reports
  - Usage: `.\tools\build\Build-Validator.ps1 <rom_file.smc>`

### Development Automation
- **Build-Watch.ps1** - Watch mode for continuous builds
  - Monitors source files for changes
  - Automatically rebuilds on save
  - Runs validation after build
  - Displays real-time status
  - Usage: `.\tools\build\Build-Watch.ps1`

- **dev-watch.ps1** - Development watch mode
  - Similar to Build-Watch but with more features
  - Integrates with emulator
  - Live reload support
  - Enhanced logging
  - Usage: `.\tools\build\dev-watch.ps1`

## Common Workflows

### Standard Build Process
```bash
# Clean build from scratch
python tools/build/build_rom.py --clean

# Verify build is byte-perfect
python tools/build/verify_build_integration.py

# If verification fails, compare with original
python tools/build/compare_roms.py roms/original.smc build/output.smc
```

### Quick Iteration Workflow
```bash
# Make changes to source code...

# Quick build (no clean)
python tools/build/build_rom.py

# Quick verification
python tools/build/quick_verify.py

# Test in emulator
```

### Continuous Development
```powershell
# Start watch mode (PowerShell)
.\tools\build\dev-watch.ps1

# Make changes to source - auto-builds and validates
# ROM automatically reloaded in emulator
```

### Data Integration Workflow
```bash
# 1. Export modified data to JSON
python tools/battle/view_enemy.py --export enemies.json

# 2. Edit enemies.json

# 3. Generate assembly from JSON
python tools/build/build_asm_from_json.py --input enemies.json --output src/data/enemies.asm

# 4. Build ROM with new data
python tools/build/build_rom.py

# 5. Verify integration
python tools/build/verify_build_integration.py
```

### Debugging Build Issues
```bash
# 1. Enable verbose output
python tools/build/build_rom.py --verbose

# 2. Compare with reference ROM
python tools/build/compare_roms.py roms/original.smc build/output.smc --output diff.txt

# 3. Check specific sections
python tools/build/verify_build_integration.py --section battle_data

# 4. Validate round-trip
python tools/build/verify_roundtrip.py
```

## Build Configuration

### build_config.json
```json
{
    "assembler": "asar",
    "source_file": "src/main.asm",
    "output_rom": "build/ffmq.smc",
    "reference_rom": "roms/original.smc",
    "build_type": "debug",
    "optimization_level": 0,
    "verify_build": true,
    "incremental": true
}
```

### Environment Variables
- `FFMQ_SOURCE_DIR` - Source code directory (default: `src/`)
- `FFMQ_BUILD_DIR` - Build output directory (default: `build/`)
- `FFMQ_ROM_DIR` - Reference ROM directory (default: `roms/`)
- `FFMQ_ASSEMBLER` - Assembler to use (default: `asar`)

## Build Process Details

### Stage 1: Pre-processing
1. Validate source files exist
2. Check assembler availability
3. Create build directory
4. Generate build ID and timestamp

### Stage 2: Assembly
1. Run assembler on main.asm
2. Process includes and imports
3. Apply patches and data
4. Generate symbol table

### Stage 3: Post-processing
1. Validate ROM header
2. Calculate checksums
3. Apply ROM fixes if needed
4. Generate build artifacts

### Stage 4: Verification
1. Compare with reference ROM
2. Validate data sections
3. Check symbol references
4. Run integrity tests

## Build Artifacts

### Generated Files
- `build/ffmq.smc` - Output ROM
- `build/ffmq.sym` - Symbol table
- `build/build.log` - Build log
- `build/build_report.txt` - Build report
- `build/diff.txt` - Diff from reference (if different)

### Symbol Table Format
```
# Symbol table generated by asar
00:8000 = MainGameLoop
00:8100 = InitializeSystem
01:C000 = BattleData_Enemies
...
```

## Assembler Integration

### ASAR (Recommended)
FFMQ project uses ASAR (All-Purpose SNES Assembler).

**Installation:**
```bash
# Download from https://github.com/RPGHacker/asar
# Extract asar.exe to project root or add to PATH
```

**Basic Usage:**
```bash
asar src/main.asm build/ffmq.smc
```

**With Symbols:**
```bash
asar --symbols=wla src/main.asm build/ffmq.smc
```

### Alternative Assemblers
The build system can be configured for other assemblers:
- WLA-DX
- bass
- ca65

Modify `build_config.json` to specify assembler.

## Error Handling

### Common Build Errors

**Error: "Assembler not found"**
- Solution: Install ASAR and add to PATH or set `FFMQ_ASSEMBLER` environment variable

**Error: "ROM size mismatch"**
- Solution: Check source includes all data sections, verify no missing files

**Error: "Checksum verification failed"**
- Solution: Expected for modified ROMs, use `--no-verify` flag

**Error: "Symbol undefined"**
- Solution: Check label definitions, ensure all includes are present

**Error: "Build output differs from reference"**
- Solution: Normal if code was modified, use compare_roms.py to see differences

## Optimization

### Build Speed Optimization
- Use incremental builds (only reassemble changed files)
- Enable build caching
- Use SSD for build directory
- Disable verbose output unless debugging

### ROM Size Optimization
- Remove unused code/data
- Use compression for graphics/music
- Optimize data tables
- Remove debug symbols in release builds

## Testing Integration

### Automated Testing
```bash
# Build and run full test suite
python tools/build/build_rom.py && python tools/testing/run_all_tests.py

# Build, verify, and test
python tools/build/build_and_compare.py && python tools/build/verify_build_integration.py
```

### Continuous Integration
See `.github/workflows/build.yml` for CI configuration.

## Dependencies

- Python 3.7+
- ASAR assembler
- PowerShell 5.1+ (for .ps1 scripts)
- Standard library modules only (no pip packages required)

## See Also

- **tools/rom-operations/** - For ROM manipulation and analysis
- **tools/testing/** - For ROM testing and validation
- **tools/data-extraction/** - For extracting data from ROMs
- **docs/technical/BUILD_SYSTEM.md** - Detailed build system documentation
- **docs/guides/BUILD_GUIDE.md** - Step-by-step build instructions

## Tips and Best Practices

### Daily Development
1. Use watch mode for rapid iteration
2. Commit before major changes
3. Verify build after each feature
4. Test in emulator regularly
5. Keep reference ROM for comparison

### Clean Builds
- Always clean build before releases
- Clean build after major refactoring
- Clean build when switching branches
- Clean build if incremental build fails

### Version Control
- Don't commit build artifacts (build/)
- Do commit source code (src/)
- Do commit build configuration
- Tag stable build points

### Performance
- Use `quick_verify.py` during development
- Use `verify_build_integration.py` before commits
- Use full verification before releases
- Profile slow builds to identify bottlenecks

## Troubleshooting

**Build is slow**
- Try incremental builds
- Check antivirus exclusions
- Use SSD for build directory
- Reduce verification frequency

**Build output inconsistent**
- Always clean build
- Check for timestamp/random data
- Verify assembler version
- Check environment variables

**Verification always fails**
- Check reference ROM is original
- Verify expected modifications
- Use compare tool to see differences
- Check symbol table matches

## Advanced Topics

### Custom Build Steps
Extend `build_integration.py` to add custom build steps:
```python
def custom_build_step():
    # Your custom logic
    pass
```

### Build Hooks
Register hooks for build events:
- pre_build
- post_build
- pre_verify
- post_verify

### Parallel Builds
Enable parallel assembly of independent sections for faster builds.

## Contributing

When modifying build tools:
1. Maintain backward compatibility
2. Update build documentation
3. Add error handling
4. Test on clean checkout
5. Verify incremental builds work
6. Update this README

## Future Development

Planned improvements:
- [ ] Distributed build support
- [ ] Cloud build integration
- [ ] Enhanced incremental builds
- [ ] Build artifact caching
- [ ] Multi-platform support
- [ ] GUI build manager
- [ ] Real-time build metrics
