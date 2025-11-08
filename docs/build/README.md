# Build System Documentation

This directory contains comprehensive documentation for building Final Fantasy Mystic Quest from source code, including modern toolchain setup, byte-perfect reproduction, and advanced build configurations.

## 📋 Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Documentation Index](#documentation-index)
  - [Getting Started](#getting-started)
  - [Core Build System](#core-build-system)
  - [Advanced Topics](#advanced-topics)
  - [Toolchain Setup](#toolchain-setup)
  - [Testing & Verification](#testing--verification)
- [Build Workflows](#build-workflows)
  - [Basic Build](#basic-build)
  - [Clean Build](#clean-build)
  - [Verified Build](#verified-build)
  - [Development Build](#development-build)
- [Common Tasks](#common-tasks)
- [Troubleshooting](#troubleshooting)
- [Related Documentation](#related-documentation)

---

## Overview

The FFMQ build system provides multiple approaches to assembling the game ROM from disassembled source code:

**Build Approaches:**
- **Modern Toolchain** - Using Asar for clean, maintainable builds
- **Byte-Perfect Reproduction** - Exact binary match with original ROM
- **Development Builds** - Fast iteration with debug symbols
- **Verified Builds** - Automated testing and validation

**Key Features:**
- ✅ Byte-perfect reproduction capability
- ✅ Modern assembler (Asar) integration
- ✅ Automated verification testing
- ✅ Multiple build configurations
- ✅ Cross-platform support (Windows, Linux, macOS)
- ✅ CI/CD ready workflows
- ✅ Incremental build support

---

## Quick Start

### Prerequisites

1. **Install Asar assembler:**
   ```bash
   # See INSTALL_ASAR.md for detailed instructions
   python tools/build/install_asar.py
   ```

2. **Verify original ROM:**
   ```bash
   # Place your FFMQ ROM in roms/ directory
   python tools/build/verify_rom.py roms/ffmq.sfc
   ```

### Basic Build

```bash
# PowerShell (Windows)
.\build.ps1

# Python (cross-platform)
python tools/build/build_rom.py

# Makefile (Linux/macOS)
make
```

### Verify Build

```bash
# Verify byte-perfect reproduction
python tools/build/compare_roms.py build/ffmq.sfc roms/ffmq_original.sfc

# Run automated tests
python tools/testing/run_all_tests.py --build
```

---

## Documentation Index

### Getting Started

#### [`BUILD_GUIDE.md`](BUILD_GUIDE.md) 📖 **START HERE**
*Comprehensive guide for building FFMQ from source*

**Contents:**
- Prerequisites and system requirements
- Step-by-step build instructions
- Common build configurations
- Troubleshooting guide
- Best practices

**Use when:**
- First time building the project
- Setting up development environment
- Need comprehensive build reference

**Example workflows:**
```bash
# First-time setup
1. Read BUILD_GUIDE.md prerequisites
2. Install Asar (see INSTALL_ASAR.md)
3. Configure build environment
4. Run first build
5. Verify output

# Regular development
1. Make code changes
2. Run incremental build
3. Test changes
4. Verify byte-perfect match (if required)
```

---

#### [`build-instructions.md`](build-instructions.md) ⚡ Quick Reference
*Quick build commands and common tasks*

**Contents:**
- Common build commands
- Build options reference
- Quick troubleshooting
- Platform-specific notes

**Use when:**
- Need quick command reference
- Looking for specific build option
- Platform-specific build issues

**Quick commands:**
```bash
# Standard build
python tools/build/build_rom.py

# Clean build
python tools/build/build_rom.py --clean

# Verbose output
python tools/build/build_rom.py --verbose

# Build specific bank
python tools/build/build_rom.py --bank 02
```

---

### Core Build System

#### [`BUILD_SYSTEM.md`](BUILD_SYSTEM.md) 🏗️ Architecture Overview
*Complete build system architecture and design*

**Contents:**
- Build system architecture
- Tool interactions and data flow
- Build pipeline stages
- Configuration management
- Extension points

**Use when:**
- Understanding build system internals
- Modifying build process
- Debugging build issues
- Adding new build features

**Architecture overview:**
```
Source Code (src/)
    ↓
[Pre-processing]
    ↓
Assembler (Asar)
    ↓
[Post-processing]
    ↓
Verification
    ↓
Output ROM (build/)
```

**Build stages:**
1. **Source validation** - Syntax checking, dependency verification
2. **Pre-processing** - Macro expansion, constant substitution
3. **Assembly** - Asar assembles source to binary
4. **Post-processing** - Header updates, checksums
5. **Verification** - ROM validation, comparison tests

---

#### [`BUILD_SYSTEM_V2_SUMMARY.md`](BUILD_SYSTEM_V2_SUMMARY.md) 📊 Version 2 Features
*Summary of Build System V2 improvements*

**Contents:**
- V2 feature overview
- Migration from V1
- Performance improvements
- New capabilities

**Major V2 features:**
- ✅ Incremental builds (10x faster)
- ✅ Parallel assembly
- ✅ Dependency tracking
- ✅ Smart caching
- ✅ Better error messages
- ✅ Integration testing

**Use when:**
- Upgrading from V1
- Understanding V2 improvements
- Optimizing build performance

---

#### [`BUILD_INTEGRATION.md`](BUILD_INTEGRATION.md) 🔗 Tool Integration
*How build system integrates with other tools*

**Contents:**
- IDE integration (VS Code, Vim, Emacs)
- CI/CD integration
- Testing integration
- Git hooks
- Automation scripts

**Use when:**
- Setting up IDE build tasks
- Configuring CI/CD pipelines
- Automating build workflows

**VS Code integration:**
```json
// .vscode/tasks.json
{
  "label": "Build FFMQ",
  "type": "shell",
  "command": "python",
  "args": ["tools/build/build_rom.py"],
  "group": {
    "kind": "build",
    "isDefault": true
  }
}
```

**CI/CD example (GitHub Actions):**
```yaml
name: Build and Test
on: [push, pull_request]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Install Asar
        run: python tools/build/install_asar.py
      - name: Build ROM
        run: python tools/build/build_rom.py
      - name: Verify Build
        run: python tools/testing/run_all_tests.py --build
```

---

#### [`BUILD_INTEGRATION_SUMMARY.md`](BUILD_INTEGRATION_SUMMARY.md) 📝 Integration Summary
*Quick reference for build integrations*

**Contents:**
- Integration checklist
- Common integration patterns
- Quick setup guides

---

### Advanced Topics

#### [`BUILD_SYSTEM_ADVANCED.md`](BUILD_SYSTEM_ADVANCED.md) 🚀 Advanced Features
*Advanced build configurations and optimizations*

**Contents:**
- Custom build configurations
- Optimization techniques
- Advanced debugging
- Build scripting
- Performance tuning

**Use when:**
- Optimizing build performance
- Creating custom configurations
- Advanced debugging needs
- Build automation

**Advanced configurations:**

**1. Debug Build Configuration:**
```ini
# config/debug.cfg
[build]
optimize = false
debug_symbols = true
verbose_output = true
assertions = enabled

[assembly]
warnings_as_errors = true
strict_mode = true
```

**2. Release Build Configuration:**
```ini
# config/release.cfg
[build]
optimize = true
debug_symbols = false
strip_comments = true
compress = true

[verification]
require_byte_perfect = true
run_tests = true
```

**3. Development Build (Fast Iteration):**
```bash
# Skip verification for speed
python tools/build/build_rom.py --quick --no-verify

# Build only changed banks
python tools/build/build_rom.py --incremental

# Parallel assembly
python tools/build/build_rom.py --parallel --jobs 8
```

**Performance optimization techniques:**

**Cache Management:**
```bash
# View cache status
python tools/build/build_rom.py --cache-status

# Clear cache
python tools/build/build_rom.py --clear-cache

# Prebuild cache
python tools/build/build_rom.py --prebuild-cache
```

**Parallel Assembly:**
```python
# config/parallel.py
PARALLEL_CONFIG = {
    'enabled': True,
    'max_workers': 8,
    'bank_groups': [
        [0x00, 0x01, 0x02],  # Core engine
        [0x03, 0x07, 0x08],  # Graphics
        [0x09, 0x0A, 0x0B],  # Battle
        # ... more groups
    ]
}
```

---

#### [`BYTE_PERFECT_REBUILD.md`](BYTE_PERFECT_REBUILD.md) 🎯 Byte-Perfect Reproduction
*Guide to achieving byte-perfect ROM reproduction*

**Contents:**
- What is byte-perfect reproduction
- Why it matters
- How to achieve it
- Verification process
- Troubleshooting differences

**Use when:**
- Verifying disassembly accuracy
- Preparing for release
- Ensuring compatibility
- Debugging assembly issues

**What is byte-perfect reproduction?**

A byte-perfect build produces a ROM that is **identical at the binary level** to the original game ROM. Every single byte matches exactly.

**Why it matters:**
- ✅ Proves disassembly completeness and accuracy
- ✅ Ensures compatibility with original hardware
- ✅ Maintains save file compatibility
- ✅ Validates emulator behavior
- ✅ Enables safe modding (know exact changes)

**Verification process:**

**1. Build ROM:**
```bash
python tools/build/build_rom.py --verify
```

**2. Compare with original:**
```bash
python tools/build/compare_roms.py \
    build/ffmq.sfc \
    roms/ffmq_original.sfc \
    --verbose
```

**3. Review differences (if any):**
```bash
# Generate difference report
python tools/build/compare_roms.py \
    build/ffmq.sfc \
    roms/ffmq_original.sfc \
    --report differences.txt \
    --hex-dump

# View specific differences
python tools/rom-operations/hex_diff.py \
    build/ffmq.sfc \
    roms/ffmq_original.sfc \
    --address 0x1234
```

**Common causes of differences:**

**1. Assembly Directive Differences:**
```asm
; Problematic (assembler-specific)
db $00, $01, $02

; Better (explicit)
.byte $00, $01, $02
```

**2. Padding Issues:**
```asm
; May produce different padding
org $808000

; Explicit padding
org $808000
padbyte $FF
pad $810000
```

**3. Header Checksums:**
```bash
# Fix header checksums
python tools/rom-operations/fix_header.py build/ffmq.sfc
```

**4. Build Environment:**
```bash
# Ensure consistent environment
python --version  # Python 3.8+
asar --version    # Asar 1.81+
```

**Troubleshooting byte-perfect issues:**

**Issue: Small number of byte differences**
```bash
# Analyze differences
python tools/build/analyze_differences.py \
    build/ffmq.sfc \
    roms/ffmq_original.sfc

# Common fixes:
# - Check assembly directive syntax
# - Verify padding configuration
# - Update header checksums
# - Check endianness
```

**Issue: Large sections differ**
```bash
# Likely causes:
# - Wrong assembler version
# - Missing source files
# - Configuration mismatch

# Verify assembler
asar --version  # Should be 1.81+

# Verify all source files present
python tools/analysis/check_completeness.py
```

**Issue: Consistent offset**
```bash
# Likely causes:
# - Wrong base address
# - Bank configuration mismatch

# Check memory map
python tools/disassembly/check_memory_map.py
```

---

#### [`MODERN_SNES_TOOLCHAIN.md`](MODERN_SNES_TOOLCHAIN.md) 🔧 Modern Tools
*Modern SNES development toolchain overview*

**Contents:**
- Modern tool ecosystem
- Tool comparisons
- Setup guides
- Integration examples

**Use when:**
- Setting up modern development environment
- Choosing tools for project
- Understanding tool options

**Modern SNES toolchain components:**

**1. Assemblers:**

**Asar (Recommended):**
```bash
# Install
python tools/build/install_asar.py

# Features
- Fast assembly
- Excellent error messages
- Active development
- Good documentation
- Cross-platform
```

**bass:**
```bash
# Alternative assembler
# Pros: Very flexible, powerful macro system
# Cons: Steeper learning curve
```

**2. Debuggers:**

**Mesen-S (Recommended):**
```
Features:
- Cycle-accurate SNES emulation
- Powerful debugger
- Memory viewer
- Event viewer
- Trace logger
- Label import support
```

**bsnes-plus:**
```
Features:
- Debugging support
- Save state manipulation
- Memory editor
- Good compatibility
```

**3. Graphics Tools:**

**YY-CHR:**
```
Features:
- Tile editor
- Palette editor
- Export to multiple formats
- Good for SNES graphics
```

**Custom Python tools (this project):**
```bash
# Our graphics toolkit
python tools/graphics/snes_graphics.py --help
python tools/graphics/palette_editor.py --help
python tools/graphics/extract_graphics_v2.py --help
```

**4. Music Tools:**

**SPC700 IDE:**
```
Features:
- SPC editing
- Sample management
- Export tools
```

**AddMusicK:**
```
Features:
- Music insertion
- Custom samples
- Multiple formats
```

---

#### [`ROM_CONFIG_VERIFICATION.md`](ROM_CONFIG_VERIFICATION.md) ✅ Configuration Verification
*ROM configuration verification and validation*

**Contents:**
- Configuration requirements
- Verification procedures
- Common configuration errors
- Automated verification

**Use when:**
- Verifying ROM configuration
- Troubleshooting configuration issues
- Automating verification

**Configuration verification workflow:**

**1. Header Verification:**
```bash
# Verify ROM header
python tools/rom-operations/verify_header.py build/ffmq.sfc

# Expected output:
# ✅ Title: MYSTIC QUEST
# ✅ ROM Size: 1MB
# ✅ Region: USA
# ✅ Checksum: Valid
```

**2. Memory Map Verification:**
```bash
# Verify memory map configuration
python tools/disassembly/verify_memory_map.py

# Checks:
# - Bank configurations
# - Address ranges
# - No overlaps
# - Proper alignment
```

**3. Build Configuration Verification:**
```bash
# Verify build config
python tools/build/verify_config.py

# Checks:
# - Assembler version
# - Required tools installed
# - Path configurations
# - Output directories exist
```

**Common configuration errors:**

**Error: Invalid ROM header**
```bash
# Problem: Header checksum invalid
# Fix:
python tools/rom-operations/fix_header.py build/ffmq.sfc

# Verify:
python tools/rom-operations/verify_header.py build/ffmq.sfc
```

**Error: Bank configuration mismatch**
```bash
# Problem: Banks not properly configured
# Check configuration:
cat config/memory_map.cfg

# Should contain:
# [bank_00]
# address = 0x808000
# size = 0x8000
# type = code
```

**Error: Assembly errors**
```bash
# Problem: Source assembly fails
# Debug:
python tools/build/build_rom.py --verbose --debug

# Common causes:
# - Syntax errors
# - Missing includes
# - Label conflicts
# - Macro issues
```

**Automated verification:**

**Pre-build checks:**
```bash
# Run before building
python tools/build/pre_build_checks.py

# Verifies:
# ✅ All required tools installed
# ✅ Source files present
# ✅ Configuration valid
# ✅ Output directory writable
```

**Post-build verification:**
```bash
# Run after building
python tools/build/post_build_verify.py build/ffmq.sfc

# Verifies:
# ✅ ROM size correct
# ✅ Header valid
# ✅ Checksum matches
# ✅ No gaps in binary
# ✅ All banks present
```

**Continuous verification:**
```bash
# Run during development
python tools/build/watch_and_verify.py

# Features:
# - Watch source files
# - Auto-rebuild on changes
# - Immediate verification
# - Error reporting
```

---

### Toolchain Setup

#### [`INSTALL_ASAR.md`](INSTALL_ASAR.md) 📥 Asar Installation
*Step-by-step Asar assembler installation guide*

**Contents:**
- Installation instructions (all platforms)
- Version requirements
- Troubleshooting installation
- Verification steps

**Use when:**
- First-time setup
- Installing on new platform
- Troubleshooting Asar issues

**Installation guide:**

**Windows:**
```powershell
# Method 1: Automated installer (recommended)
python tools/build/install_asar.py

# Method 2: Manual installation
# 1. Download from: https://github.com/RPGHacker/asar/releases
# 2. Extract asar.exe
# 3. Add to PATH or place in project root

# Verify installation
asar --version
# Expected: asar 1.81 or higher
```

**Linux:**
```bash
# Method 1: Automated installer
python tools/build/install_asar.py

# Method 2: Build from source
git clone https://github.com/RPGHacker/asar.git
cd asar
make
sudo make install

# Verify installation
asar --version
```

**macOS:**
```bash
# Method 1: Automated installer
python tools/build/install_asar.py

# Method 2: Homebrew (if available)
brew install asar

# Method 3: Build from source
git clone https://github.com/RPGHacker/asar.git
cd asar
make
sudo make install

# Verify installation
asar --version
```

**Verification:**
```bash
# Test Asar works
echo "org \$808000" > test.asm
echo "db \$FF" >> test.asm
asar test.asm test.sfc
rm test.asm test.sfc

# If successful, Asar is properly installed
```

**Troubleshooting:**

**Problem: asar not found**
```bash
# Windows: Add to PATH
# 1. Copy asar.exe to project root, or
# 2. Add Asar directory to PATH environment variable

# Linux/macOS: Check installation path
which asar
# If not found, ensure install directory in PATH
export PATH=$PATH:/usr/local/bin
```

**Problem: Wrong version**
```bash
# Update Asar
python tools/build/install_asar.py --upgrade

# Or manually download latest from:
# https://github.com/RPGHacker/asar/releases
```

---

#### [`ASAR_INTEGRATION.md`](ASAR_INTEGRATION.md) 🔌 Asar Integration
*Integrating Asar into build workflow*

**Contents:**
- Asar command-line usage
- Integration with build scripts
- Configuration options
- Advanced features

**Use when:**
- Customizing build process
- Adding Asar features
- Optimizing assembly
- Debugging assembly issues

**Basic Asar usage:**

**Command-line:**
```bash
# Basic assembly
asar source.asm output.sfc

# With symbols (for debugging)
asar --symbols=symbols.sym source.asm output.sfc

# Verbose output
asar --verbose source.asm output.sfc

# Fix checksum
asar --fix-checksum=on source.asm output.sfc
```

**Python integration:**
```python
# tools/build/asar_wrapper.py
import subprocess
import os

def assemble(source_file, output_file, **options):
    """Assemble source file using Asar."""
    cmd = ['asar']
    
    # Add options
    if options.get('symbols'):
        cmd.append(f'--symbols={options["symbols"]}')
    if options.get('verbose'):
        cmd.append('--verbose')
    if options.get('fix_checksum', True):
        cmd.append('--fix-checksum=on')
    
    cmd.extend([source_file, output_file])
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    
    if result.returncode != 0:
        raise AssemblyError(result.stderr)
    
    return result.stdout

# Usage
assemble(
    'src/main.asm',
    'build/ffmq.sfc',
    symbols='build/symbols.sym',
    verbose=True
)
```

**Advanced Asar features:**

**1. Define Symbols:**
```bash
# Pass defines to assembly
asar -DDEBUG=1 -DVERSION=2 source.asm output.sfc
```

**2. Include Paths:**
```bash
# Add include directories
asar --include=src/include --include=src/macros source.asm output.sfc
```

**3. Symbol Export:**
```bash
# Export symbols for debugging
asar --symbols=symbols.sym --symbols-format=wla source.asm output.sfc

# Symbol formats:
# - wla (default)
# - vice
# - nocash
```

**4. Warning Control:**
```bash
# Warnings as errors
asar --werror source.asm output.sfc

# Disable specific warnings
asar --no-warn=label-not-found source.asm output.sfc
```

**Integration examples:**

**PowerShell build script:**
```powershell
# build.ps1
param(
    [switch]$Debug,
    [switch]$Verbose
)

$asarCmd = 'asar'
$asarArgs = @()

if ($Debug) {
    $asarArgs += '--symbols=build/symbols.sym'
    $asarArgs += '-DDEBUG=1'
}

if ($Verbose) {
    $asarArgs += '--verbose'
}

$asarArgs += '--fix-checksum=on'
$asarArgs += 'src/main.asm'
$asarArgs += 'build/ffmq.sfc'

& $asarCmd $asarArgs
```

**Makefile:**
```makefile
# Makefile
ASAR = asar
ASAR_FLAGS = --fix-checksum=on
SOURCE = src/main.asm
OUTPUT = build/ffmq.sfc

.PHONY: all clean debug

all:
\t$(ASAR) $(ASAR_FLAGS) $(SOURCE) $(OUTPUT)

debug:
\t$(ASAR) $(ASAR_FLAGS) --symbols=build/symbols.sym -DDEBUG=1 $(SOURCE) $(OUTPUT)

clean:
\trm -f $(OUTPUT) build/symbols.sym
```

---

### Testing & Verification

#### [`ASM_FORMAT_TESTING.md`](ASM_FORMAT_TESTING.md) 🧪 Assembly Testing
*Testing assembly output and formatting*

**Contents:**
- Assembly test procedures
- Format verification
- Automated testing
- Regression testing

**Use when:**
- Verifying assembly output
- Testing code changes
- Setting up CI/CD
- Debugging assembly issues

**Test categories:**

**1. Syntax Testing:**
```bash
# Test source files assemble without errors
python tools/testing/test_assembly.py --syntax

# Tests:
# ✅ No syntax errors
# ✅ All includes resolved
# ✅ No label conflicts
# ✅ Macros expand correctly
```

**2. Output Testing:**
```bash
# Test assembled output matches expectations
python tools/testing/test_assembly.py --output

# Tests:
# ✅ Correct ROM size
# ✅ Valid header
# ✅ Expected byte patterns
# ✅ No gaps in banks
```

**3. Regression Testing:**
```bash
# Test changes don't break existing code
python tools/testing/test_assembly.py --regression

# Tests:
# ✅ Byte-perfect match (if no changes)
# ✅ Only expected bytes changed
# ✅ No unintended side effects
# ✅ Save compatibility maintained
```

**Automated test suite:**

**Test configuration:**
```python
# config/tests.py
ASSEMBLY_TESTS = {
    'syntax': {
        'enabled': True,
        'strict': True,
        'warnings_as_errors': False
    },
    'output': {
        'enabled': True,
        'verify_size': True,
        'verify_header': True,
        'verify_checksum': True
    },
    'regression': {
        'enabled': True,
        'baseline': 'roms/ffmq_baseline.sfc',
        'allow_intentional_changes': True
    }
}
```

**Running tests:**
```bash
# Run all assembly tests
python tools/testing/run_all_tests.py --assembly

# Run specific test category
python tools/testing/run_all_tests.py --assembly --category syntax

# Run with verbose output
python tools/testing/run_all_tests.py --assembly --verbose

# Generate test report
python tools/testing/run_all_tests.py --assembly --report tests/report.html
```

**Test example (syntax):**
```python
# tools/testing/test_assembly_syntax.py
import unittest
from tools.build import asar_wrapper

class AssemblySyntaxTests(unittest.TestCase):
    def test_main_assembles(self):
        """Test main.asm assembles without errors."""
        try:
            asar_wrapper.assemble('src/main.asm', 'build/test.sfc')
        except Exception as e:
            self.fail(f"Assembly failed: {e}")
    
    def test_all_banks_assemble(self):
        """Test all bank files assemble individually."""
        banks = ['bank_00.asm', 'bank_01.asm', 'bank_02.asm']
        for bank in banks:
            with self.subTest(bank=bank):
                try:
                    asar_wrapper.assemble(f'src/{bank}', 'build/test.sfc')
                except Exception as e:
                    self.fail(f"Bank {bank} failed: {e}")
```

**Test example (output):**
```python
# tools/testing/test_assembly_output.py
import unittest
from tools.rom_operations import rom_utils

class AssemblyOutputTests(unittest.TestCase):
    def setUp(self):
        """Build ROM before tests."""
        asar_wrapper.assemble('src/main.asm', 'build/test.sfc')
        self.rom = rom_utils.load_rom('build/test.sfc')
    
    def test_rom_size(self):
        """Test ROM is correct size."""
        self.assertEqual(len(self.rom), 1024 * 1024)  # 1MB
    
    def test_header_valid(self):
        """Test ROM header is valid."""
        header = rom_utils.parse_header(self.rom)
        self.assertEqual(header['title'], 'MYSTIC QUEST')
        self.assertEqual(header['region'], 'USA')
    
    def test_bank_00_present(self):
        """Test Bank $00 is present and valid."""
        bank_00 = self.rom[0x8000:0x10000]
        self.assertNotEqual(bank_00, b'\x00' * len(bank_00))
```

**Continuous integration:**
```yaml
# .github/workflows/test-assembly.yml
name: Assembly Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Install Asar
        run: python tools/build/install_asar.py
      
      - name: Run syntax tests
        run: python tools/testing/run_all_tests.py --assembly --category syntax
      
      - name: Build ROM
        run: python tools/build/build_rom.py
      
      - name: Run output tests
        run: python tools/testing/run_all_tests.py --assembly --category output
      
      - name: Run regression tests
        run: python tools/testing/run_all_tests.py --assembly --category regression
      
      - name: Upload test report
        uses: actions/upload-artifact@v2
        with:
          name: test-report
          path: tests/report.html
```

---

#### [`MODERN_BUILD_STATUS.md`](MODERN_BUILD_STATUS.md) 📈 Build Status
*Current status of modern build system*

**Contents:**
- Feature implementation status
- Known issues
- Planned improvements
- Version history

**Use when:**
- Checking feature availability
- Understanding current limitations
- Planning feature use

**Implementation status:**

**✅ Fully Implemented:**
- Basic ROM assembly
- Asar integration
- Byte-perfect reproduction
- Header verification
- Build automation scripts
- Cross-platform support
- Error reporting
- Symbol export

**🚧 Partial Implementation:**
- Incremental builds (basic support)
- Parallel assembly (experimental)
- Debug symbol integration
- IDE integration (VS Code only)

**📋 Planned Features:**
- Full incremental build system
- Stable parallel assembly
- Advanced optimization
- Plugin system
- Web-based build monitor
- Distributed builds

**Known issues:**

**Issue: Parallel builds occasionally fail**
- **Severity:** Medium
- **Workaround:** Use sequential builds (`--no-parallel`)
- **Status:** Under investigation
- **Tracking:** Issue #42

**Issue: Incremental builds miss some dependencies**
- **Severity:** Low
- **Workaround:** Clean build when in doubt
- **Status:** Planned fix in v2.1
- **Tracking:** Issue #56

**Version history:**

**v2.0 (Current):**
- Added Asar integration
- Byte-perfect reproduction
- Automated testing
- Cross-platform support

**v1.5:**
- Improved error messages
- Symbol export
- Basic verification

**v1.0:**
- Initial release
- Basic assembly
- Manual verification

---

## Build Workflows

### Basic Build

**Standard build workflow for daily development:**

```bash
# 1. Pull latest changes
git pull origin master

# 2. Build ROM
python tools/build/build_rom.py

# 3. Test in emulator
# (Launch build/ffmq.sfc in your emulator)

# 4. Verify (optional)
python tools/build/compare_roms.py build/ffmq.sfc roms/ffmq_original.sfc
```

**PowerShell workflow:**
```powershell
# Quick build and test
.\build.ps1
if ($LASTEXITCODE -eq 0) {
    Write-Host "Build successful!" -ForegroundColor Green
    & "path\to\emulator.exe" "build\ffmq.sfc"
}
```

---

### Clean Build

**Complete rebuild from scratch:**

```bash
# 1. Clean build directory
python tools/build/build_rom.py --clean

# 2. Clear cache
python tools/build/build_rom.py --clear-cache

# 3. Full rebuild
python tools/build/build_rom.py --verbose

# 4. Verify output
python tools/build/verify_rom.py build/ffmq.sfc
```

**When to use clean builds:**
- After pulling major changes
- Before release/submission
- Troubleshooting build issues
- Verifying byte-perfect reproduction
- After changing build configuration

---

### Verified Build

**Build with full verification:**

```bash
# 1. Run pre-build checks
python tools/build/pre_build_checks.py

# 2. Build with verification
python tools/build/build_rom.py --verify --verbose

# 3. Run test suite
python tools/testing/run_all_tests.py --build

# 4. Generate verification report
python tools/build/generate_build_report.py build/ffmq.sfc > build/report.txt
```

**Verification checklist:**
- ✅ All source files present
- ✅ Asar version correct
- ✅ No assembly errors
- ✅ ROM size correct (1MB)
- ✅ Header valid
- ✅ Checksum valid
- ✅ Byte-perfect match (if required)
- ✅ All tests pass

---

### Development Build

**Fast iteration for active development:**

```bash
# 1. Quick build (skip verification)
python tools/build/build_rom.py --quick --no-verify

# 2. Build only changed banks
python tools/build/build_rom.py --incremental

# 3. Build with debug symbols
python tools/build/build_rom.py --debug --symbols build/symbols.sym

# 4. Watch mode (auto-rebuild on changes)
python tools/build/watch_and_build.py --auto-test
```

**Development tips:**
- Use `--quick` for fast iteration
- Use `--incremental` when changing single banks
- Use `--debug` for debugging sessions
- Use watch mode for rapid testing
- Skip verification during active development
- Run full verification before committing

---

## Common Tasks

### Building Specific Banks

```bash
# Build only Bank $02
python tools/build/build_rom.py --bank 02

# Build multiple banks
python tools/build/build_rom.py --banks 00,01,02,03

# Build all banks except specific ones
python tools/build/build_rom.py --exclude-banks 0D,0E,0F
```

### Generating Symbol Files

```bash
# Generate symbols for debugging
python tools/build/build_rom.py --symbols build/symbols.sym

# Export to specific format
python tools/build/build_rom.py \
    --symbols build/symbols.sym \
    --symbol-format wla

# Generate symbol map
python tools/build/generate_symbol_map.py build/symbols.sym > build/symbol_map.txt
```

### Comparing ROMs

```bash
# Basic comparison
python tools/build/compare_roms.py build/ffmq.sfc roms/ffmq_original.sfc

# Verbose comparison with hex dump
python tools/build/compare_roms.py \
    build/ffmq.sfc \
    roms/ffmq_original.sfc \
    --verbose \
    --hex-dump

# Generate difference report
python tools/build/compare_roms.py \
    build/ffmq.sfc \
    roms/ffmq_original.sfc \
    --report build/differences.txt
```

### Fixing ROM Headers

```bash
# Fix header checksum
python tools/rom-operations/fix_header.py build/ffmq.sfc

# Update header fields
python tools/rom-operations/fix_header.py \
    build/ffmq.sfc \
    --title "MYSTIC QUEST" \
    --region USA
```

### Build Performance Analysis

```bash
# Analyze build performance
python tools/build/build_rom.py --profile > build/profile.txt

# View timing breakdown
python tools/build/analyze_build_performance.py build/profile.txt

# Example output:
# Source validation:    0.5s  (10%)
# Pre-processing:       0.2s  (4%)
# Assembly (Asar):      3.5s  (70%)
# Post-processing:      0.3s  (6%)
# Verification:         0.5s  (10%)
# Total:                5.0s
```

---

## Troubleshooting

### Build Fails with Assembly Errors

**Problem:** Asar reports syntax errors

**Solutions:**

1. **Check error message:**
   ```bash
   python tools/build/build_rom.py --verbose
   # Read error carefully - shows file and line number
   ```

2. **Common syntax issues:**
   ```asm
   ; Problem: Missing semicolon
   LDA $1234
   STA $5678  Missing comment delimiter
   
   ; Fix: Add semicolon
   LDA $1234
   STA $5678  ; Store to target address
   
   ; Problem: Label conflict
   .loop:
       ; ... code ...
       BNE .loop
   .loop:  ; ERROR: Duplicate label
   
   ; Fix: Use unique labels
   .loop:
       ; ... code ...
       BNE .loop
   .done:
   ```

3. **Verify source files:**
   ```bash
   python tools/analysis/check_source_files.py
   ```

### ROM Size Incorrect

**Problem:** Generated ROM is wrong size

**Solutions:**

1. **Check bank configurations:**
   ```bash
   python tools/disassembly/check_memory_map.py
   ```

2. **Verify padding:**
   ```asm
   ; Ensure proper padding at end of banks
   org $808000
   ; ... code ...
   padbyte $FF
   pad $810000  ; Pad to next bank
   ```

3. **Check for gaps:**
   ```bash
   python tools/rom-operations/find_gaps.py build/ffmq.sfc
   ```

### Byte-Perfect Build Fails

**Problem:** ROM doesn't match original exactly

**Solutions:**

1. **Identify differences:**
   ```bash
   python tools/build/compare_roms.py \
       build/ffmq.sfc \
       roms/ffmq_original.sfc \
       --verbose \
       --report build/diff.txt
   ```

2. **Common causes:**
   - Header checksum: `python tools/rom-operations/fix_header.py build/ffmq.sfc`
   - Padding bytes: Check padbyte directives in source
   - Assembly directives: Verify directive syntax
   - Asar version: Ensure correct version (`asar --version`)

3. **Analyze specific differences:**
   ```bash
   python tools/rom-operations/hex_diff.py \
       build/ffmq.sfc \
       roms/ffmq_original.sfc \
       --address 0x1234 \
       --context 16
   ```

### Build is Slow

**Problem:** Build takes too long

**Solutions:**

1. **Use incremental builds:**
   ```bash
   python tools/build/build_rom.py --incremental
   ```

2. **Enable parallel assembly:**
   ```bash
   python tools/build/build_rom.py --parallel --jobs 8
   ```

3. **Skip verification during development:**
   ```bash
   python tools/build/build_rom.py --quick --no-verify
   ```

4. **Profile build performance:**
   ```bash
   python tools/build/build_rom.py --profile
   ```

### Asar Not Found

**Problem:** Build can't find Asar

**Solutions:**

1. **Install Asar:**
   ```bash
   python tools/build/install_asar.py
   ```

2. **Verify installation:**
   ```bash
   asar --version
   # Should show: asar 1.81 or higher
   ```

3. **Check PATH (Windows):**
   ```powershell
   $env:PATH -split ';' | Select-String asar
   # Should show directory containing asar.exe
   ```

4. **Check PATH (Linux/macOS):**
   ```bash
   which asar
   # Should show: /usr/local/bin/asar or similar
   ```

### Build Configuration Issues

**Problem:** Build uses wrong configuration

**Solutions:**

1. **Verify configuration:**
   ```bash
   python tools/build/verify_config.py
   ```

2. **Check configuration file:**
   ```bash
   cat config/build.cfg
   # Verify all paths and settings
   ```

3. **Reset to defaults:**
   ```bash
   python tools/build/reset_config.py
   ```

4. **Use explicit configuration:**
   ```bash
   python tools/build/build_rom.py --config config/custom.cfg
   ```

---

## Related Documentation

### Within This Directory

- **[BUILD_GUIDE.md](BUILD_GUIDE.md)** - Comprehensive build guide
- **[BUILD_SYSTEM.md](BUILD_SYSTEM.md)** - Build system architecture
- **[BYTE_PERFECT_REBUILD.md](BYTE_PERFECT_REBUILD.md)** - Byte-perfect reproduction guide
- **[INSTALL_ASAR.md](INSTALL_ASAR.md)** - Asar installation
- **[ASAR_INTEGRATION.md](ASAR_INTEGRATION.md)** - Asar integration guide

### Other Documentation

- **[../architecture/](../architecture/)** - System architecture documentation
- **[../graphics/](../graphics/)** - Graphics system documentation
- **[../reference/DATA_STRUCTURES.md](../reference/DATA_STRUCTURES.md)** - Data structure reference
- **[../../tools/build/README.md](../../tools/build/README.md)** - Build tools documentation
- **[../../tools/testing/README.md](../../tools/testing/README.md)** - Testing framework

### External Resources

- **[Asar Documentation](https://github.com/RPGHacker/asar)** - Asar assembler docs
- **[SNES Dev Manual](https://snes.nesdev.org/)** - SNES hardware reference
- **[65816 Reference](http://6502.org/tutorials/65c816opcodes.html)** - CPU instruction reference

---

## Contributing

When adding build documentation:

1. **Follow existing structure** - Match formatting and organization
2. **Include examples** - Show concrete command examples
3. **Test procedures** - Verify all commands work
4. **Cross-reference** - Link to related documentation
5. **Update this README** - Add new docs to index

---

## Questions?

- **Build issues?** Check [Troubleshooting](#troubleshooting) section
- **Need help?** See [BUILD_GUIDE.md](BUILD_GUIDE.md)
- **Tool problems?** See [../../tools/build/README.md](../../tools/build/README.md)
- **Found a bug?** Report in project issues

---

**Last Updated:** 2025-11-07  
**Build System Version:** 2.0  
**Asar Version Required:** 1.81+
