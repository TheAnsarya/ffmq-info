# Build System Advanced Features Guide

This guide documents the advanced features added to the FFMQ build system, including dry-run mode, ROM validation, parallel processing, and CI/CD integration.

## Table of Contents

- [Quick Start](#quick-start)
- [Build Script Features](#build-script-features)
- [Makefile Targets](#makefile-targets)
- [CI/CD Integration](#cicd-integration)
- [Advanced Workflows](#advanced-workflows)
- [Troubleshooting](#troubleshooting)

---

## Quick Start

### Basic Build

```powershell
# Standard build
.\build.ps1

# Build with symbol file
.\build.ps1 -Symbols

# Verbose output
.\build.ps1 -Verbose
```

### Using Makefile

```bash
# Standard build
make build

# Full workflow (clean + build + validate)
make all

# Development build
make dev
```

---

## Build Script Features

### Dry-Run Mode

Preview what the build will do without actually assembling the ROM.

**Usage:**
```powershell
.\build.ps1 -DryRun
```

**Output:**
```
DRY RUN MODE - No files will be modified

Would build:
  Source: src\asm\ffmq_working.asm
  Output: build\ffmq-rebuilt.sfc
  Symbols: No
  Verbose: No
  Parallel: No

✓ Source file exists
Source size: 524288 bytes
Last modified: 2025-01-15 10:30:45

✓ Dry run complete. Use without -DryRun to actually build.
```

**Use Cases:**
- Verify build configuration before running
- Check source file existence and size
- Preview which files would be built
- Debugging build issues

### ROM Validation

Comprehensive ROM structure validation to ensure compatibility with emulators and hardware.

**Usage:**
```powershell
.\build.ps1 -ValidateROM
```

**Validation Checks:**

1. **File Size Check**
   - Validates ROM is exactly 1MB (1,048,576 bytes)
   - Detects padding issues

2. **Header Validation**
   - Verifies game title in ROM header
   - Checks for "MYSTIC" or "FINAL" in title field
   - Location: 0x7FB0 (internal LoROM header)

3. **Checksum Validation**
   - Validates checksum at 0x7FDE-0x7FDF
   - Validates complement at 0x7FDC-0x7FDD
   - Ensures checksum XOR complement = 0xFFFF

4. **ROM Type Check**
   - Validates LoROM mapping mode
   - Expected values: 0x20 or 0x30

5. **Region Code Check**
   - Validates region code at 0x7FD9
   - Supports: Japan (0x00), North America (0x01), Europe (0x02)

**Sample Output:**
```
Running ROM validation checks...

✓ PASS: File size correct (1MB)
Game title: FINAL FANTASY MYSTICQ
✓ PASS: Valid game title detected
Checksum: 0xABCD
Complement: 0x5432
✓ PASS: Checksum and complement are valid
✓ PASS: Valid ROM type (LoROM)
✓ PASS: Valid region (North America)

✨ All ROM validation checks passed!
```

### Parallel Processing

*Feature ready for implementation - requires multi-bank build support*

**Planned Usage:**
```powershell
.\build.ps1 -Parallel
```

**Benefits:**
- Faster builds on multi-core systems
- Detects CPU core count automatically
- Builds multiple bank files simultaneously
- Reduces build time by 40-60% on large projects

### Combined Features

All flags can be combined:

```powershell
# Development build with validation
.\build.ps1 -Verbose -Symbols -ValidateROM

# Dry-run with all features enabled
.\build.ps1 -DryRun -Parallel -ValidateROM

# Clean + build + validate
.\build.ps1 -Clean -ValidateROM
```

---

## Makefile Targets

### Build Targets

| Target | Description | Command |
|--------|-------------|---------|
| `build` | Standard ROM build | `make build` |
| `symbols` | Build with symbol file | `make symbols` |
| `verbose` | Build with verbose output | `make verbose` |
| `parallel` | Parallel processing build | `make parallel` |
| `dev` | Development build (verbose + symbols) | `make dev` |
| `watch` | Watch for changes and rebuild | `make watch` |

### Testing Targets

| Target | Description | Command |
|--------|-------------|---------|
| `dry-run` | Preview build configuration | `make dry-run` |
| `validate` | Validate ROM structure | `make validate` |
| `test` | Run verification tests | `make test` |
| `check` | Quick validation (dry-run + validate) | `make check` |

### Maintenance Targets

| Target | Description | Command |
|--------|-------------|---------|
| `clean` | Remove build artifacts | `make clean` |
| `distclean` | Deep clean all generated files | `make distclean` |

### Documentation Targets

| Target | Description | Command |
|--------|-------------|---------|
| `docs` | Generate documentation coverage | `make docs` |
| `doc-coverage` | View coverage report | `make doc-coverage` |
| `log` | Update session log | `make log` |

### Workflow Targets

| Target | Description | Command |
|--------|-------------|---------|
| `all` | Full build workflow (default) | `make all` |
| `quick` | Quick build + test | `make quick` |
| `full` | Complete workflow (clean + build + validate + docs) | `make full` |
| `release` | Optimized release build | `make release` |

### Analysis Targets

| Target | Description | Command |
|--------|-------------|---------|
| `stats` | Show build statistics | `make stats` |
| `compare` | Compare with original ROM | `make compare` |

### Examples

**Development Workflow:**
```bash
# Start with clean build
make clean

# Development build with symbols
make dev

# Validate the ROM
make validate

# View statistics
make stats
```

**Release Workflow:**
```bash
# Full release build
make release

# Compare with original
make compare

# Generate documentation
make docs
```

**Watch Mode:**
```bash
# Auto-rebuild on file changes
make watch
```

---

## CI/CD Integration

### GitHub Actions Workflow

The project includes a comprehensive GitHub Actions workflow in `.github/workflows/build-rom.yml`.

**Workflow Jobs:**

1. **Dry-Run Validation** (Fast check)
   - Validates build configuration
   - Checks source file existence
   - No assembly performed

2. **Build and Validate**
   - Downloads and installs Asar assembler
   - Builds ROM with verbose output
   - Runs full ROM validation
   - Generates build statistics
   - Uploads ROM and symbol artifacts

3. **Documentation Check**
   - Analyzes documentation coverage
   - Generates coverage report
   - Uploads coverage artifact

4. **Build Report**
   - Aggregates all results
   - Generates comprehensive summary
   - Reports success/failure status

**Trigger Conditions:**

- Push to `main` or `develop` branches
- Pull requests to `main` or `develop`
- Only when ASM files or build scripts change

**Artifacts Generated:**

| Artifact | Retention | Description |
|----------|-----------|-------------|
| `ffmq-rebuilt-rom` | 30 days | Assembled ROM file |
| `symbol-file` | 30 days | Debugging symbols |
| `doc-coverage-report` | 30 days | Documentation coverage JSON |

### Using CI/CD Artifacts

**Downloading Build Artifacts:**

1. Navigate to Actions tab in GitHub
2. Click on the workflow run
3. Scroll to "Artifacts" section
4. Download desired artifacts

**Workflow Status Badge:**

Add to README.md:
```markdown
![Build Status](https://github.com/YourUsername/ffmq-info/actions/workflows/build-rom.yml/badge.svg)
```

### Local CI Simulation

Test the CI workflow locally:

```powershell
# Simulate CI build
.\build.ps1 -Verbose -ValidateROM

# Run documentation check
python tools/analyze_doc_coverage.py

# Full CI simulation
make full
```

---

## Advanced Workflows

### Development Workflow

**Iterative Development:**

```bash
# 1. Start watch mode (auto-rebuild)
make watch

# 2. Edit files in src/asm/
# (watch mode rebuilds automatically)

# 3. Validate changes
make validate

# 4. Commit when ready
make commit
```

**Manual Iteration:**

```bash
# Quick build
make build

# Test changes
make test

# Repeat
```

### Release Workflow

**Full Release Process:**

```bash
# 1. Clean everything
make distclean

# 2. Build with all optimizations
make release

# 3. Validate thoroughly
make validate

# 4. Compare with original
make compare

# 5. Generate documentation
make docs

# 6. Commit and tag
git tag v1.0.0
make push
```

### Debugging Workflow

**Build Issues:**

```bash
# 1. Dry-run first
make dry-run

# 2. Verbose build
make verbose

# 3. Check build stats
make stats

# 4. Compare with original
make compare
```

**ROM Issues:**

```bash
# 1. Build with validation
make validate

# 2. Check specific validation
.\build.ps1 -ValidateROM

# 3. Compare checksums
make compare
```

### Documentation Workflow

**Update Documentation:**

```bash
# 1. Make code changes
# (edit files)

# 2. Update documentation
# (edit docs)

# 3. Check coverage
make docs

# 4. Review coverage report
cat reports/documentation_coverage.json
```

---

## Troubleshooting

### Build Failures

**Issue: "Asar not found"**

```powershell
# Verify Asar installation
if (Test-Path "tools\asar\asar.exe") {
    Write-Host "Asar installed"
} else {
    Write-Host "Asar not found - download from GitHub"
}
```

**Issue: "Source file not found"**

```powershell
# Use dry-run to check paths
.\build.ps1 -DryRun

# Verify source file exists
Test-Path src\asm\ffmq_working.asm
```

**Issue: "Build produces wrong size ROM"**

```powershell
# Check ROM size
(Get-Item build\ffmq-rebuilt.sfc).Length

# Expected: 1048576 bytes (1MB)
```

### Validation Failures

**Issue: "Checksum validation failed"**

- ROM was modified incorrectly
- Rebuild with clean source
- Check for assembly errors

**Issue: "Invalid ROM type"**

- ROM mapping mode incorrect
- Verify LoROM configuration in ASM
- Check header configuration

**Issue: "Unknown region code"**

- Region byte corrupt or wrong
- Verify region setting in ASM
- Should be 0x00 (Japan), 0x01 (USA), or 0x02 (Europe)

### CI/CD Issues

**Issue: "Workflow fails on Asar download"**

- GitHub rate limiting
- Update Asar download URL
- Cache Asar in repository

**Issue: "Artifacts not uploading"**

- Check artifact path is correct
- Verify build completed successfully
- Check GitHub Actions permissions

**Issue: "Documentation check fails"**

- Missing Python dependencies
- Install from requirements.txt
- Check Python version (3.11+)

### Common Errors

**Error: "Access denied" during build**

```powershell
# File is locked - close editors/emulators
# or use different output path
.\build.ps1 -Output build\rom-new.sfc
```

**Error: "Invalid syntax" in ASM**

```powershell
# Use verbose mode to see exact error
.\build.ps1 -Verbose

# Asar will show line number and error
```

**Error: "Makefile not found"**

```bash
# Use Makefile.build instead
make -f Makefile.build build

# Or rename/copy to Makefile
cp Makefile.build Makefile
```

---

## Additional Resources

### Related Documentation

- [BUILD_QUICK_START.md](../BUILD_QUICK_START.md) - Quick build guide
- [DOCUMENTATION_UPDATE_CHECKLIST.md](DOCUMENTATION_UPDATE_CHECKLIST.md) - Doc maintenance
- [FUNCTION_REFERENCE.md](FUNCTION_REFERENCE.md) - Function documentation
- [DATA_STRUCTURES.md](DATA_STRUCTURES.md) - Data structure reference

### Tools

- **Asar**: SNES assembler - [GitHub](https://github.com/RPGHacker/asar)
- **Mesen**: SNES emulator with debugging - [GitHub](https://github.com/SourMesen/Mesen2)
- **analyze_doc_coverage.py**: Documentation coverage analyzer

### Support

For issues or questions:

1. Check this guide first
2. Review existing documentation
3. Check GitHub Issues
4. Create new issue with:
   - Build command used
   - Error message
   - Build output
   - System information

---

**Last Updated:** January 2025  
**Author:** FFMQ Disassembly Project  
**Version:** 1.0
