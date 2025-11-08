# PowerShell Scripts Reference

> **Last Updated:** 2025-11-07  
> **Location:** Root directory and tools/ subdirectory  
> **Total Scripts:** 30+ PowerShell scripts

This document provides comprehensive documentation for all PowerShell scripts in the project.

## 📖 Quick Navigation

- [Root Scripts](#root-scripts) - Main project automation scripts
- [Build Scripts](#build-scripts) - ROM building and verification
- [Tracking Scripts](#tracking-scripts) - Progress tracking and logging
- [Tools Scripts](#tools-scripts) - Development and formatting tools

---

## 🏠 Root Scripts

Main automation scripts in the project root directory.

### build.ps1 ⭐
**Purpose:** Main ROM build script  
**Location:** Root directory  
**Usage:**
```powershell
.\build.ps1                    # Standard build
.\build.ps1 -Verbose          # Verbose output
.\build.ps1 -Symbols          # Generate symbol file
.\build.ps1 -Clean            # Clean build
```

**Features:**
- Assembles ROM from src/asm/ sources
- Uses Asar assembler
- Validates output file size
- Generates build reports
- Creates symbol files (optional)

**Output:** `build/ffmq-rebuilt.sfc`

**Related:**
- See [docs/guides/BUILD_GUIDE.md](docs/guides/BUILD_GUIDE.md) for complete build documentation

---

### modern-build.ps1
**Purpose:** Modern build system with enhanced features  
**Location:** Root directory  
**Usage:**
```powershell
.\modern-build.ps1
.\modern-build.ps1 -Watch     # Watch mode for auto-rebuild
```

**Features:**
- Enhanced error reporting
- Incremental build support
- File watching capability
- Improved performance

---

### setup.ps1
**Purpose:** Initial project setup script  
**Location:** Root directory  
**Usage:** `.\setup.ps1`

**Features:**
- Checks for required tools (Asar, Python, etc.)
- Validates ROM file presence
- Creates necessary directories
- Initializes configuration
- Installs Python dependencies

**First-Time Setup:**
```powershell
# Run once after cloning repository
.\setup.ps1
```

---

### start-tracking.ps1 ⭐
**Purpose:** Start automatic change tracking (background service)  
**Location:** Root directory  
**Usage:** `.\start-tracking.ps1`

**Features:**
- Launches auto_tracker.py in background
- Monitors file changes
- Automatically logs modifications
- Runs as Windows background task

**Note:** Run once; tracking continues in background until system restart.

---

### track.ps1
**Purpose:** Manual file change tracking  
**Location:** Root directory  
**Usage:**
```powershell
.\track.ps1                   # Show recent changes
.\track.ps1 -Summary          # Summary view
```

**Features:**
- Lists recent file modifications
- Tracks ASM, Python, and documentation changes
- Generates change summaries

---

### log.ps1
**Purpose:** Session logging helper  
**Location:** Root directory  
**Usage:**
```powershell
.\log.ps1 "Change description"
.\log.ps1 -Question "Question text"
.\log.ps1 -Note "Note text"
```

**Features:**
- Adds entries to session log
- Timestamps all entries
- Organizes by category (changes, questions, notes)

---

### update.ps1 ⭐
**Purpose:** Update chat log with structured entries  
**Location:** Root directory  
**Usage:**
```powershell
.\update.ps1                  # Interactive mode
```

**Features:**
- Prompts for change type (change/question/note)
- Adds to current session log
- Maintains chronological order
- Formats entries consistently

**Related:** Calls `tools/update_chat_log.py`

---

## 🔨 Build Scripts

ROM building and verification scripts.

### build-report.ps1
**Purpose:** Generate detailed build report  
**Location:** Root directory  
**Usage:** `.\build-report.ps1`

**Output:**
- File sizes for all banks
- Free space analysis
- Build statistics
- Comparison with original ROM

**Report Location:** `reports/build-report-[timestamp].md`

---

### quick-verify.ps1
**Purpose:** Quick ROM verification  
**Location:** Root directory  
**Usage:** `.\quick-verify.ps1`

**Features:**
- Fast file size check
- CRC32 validation
- Header verification
- Basic structure validation

**Related:** Calls `tools/quick_verify.py`

---

### test-roundtrip.ps1
**Purpose:** Roundtrip build verification  
**Location:** Root directory  
**Usage:**
```powershell
.\test-roundtrip.ps1
.\test-roundtrip.ps1 -Verbose
```

**Process:**
1. Clean build directory
2. Build ROM from source
3. Compare with original byte-by-byte
4. Report differences

**Expected Result:** "FC: no differences encountered"

**Related:** See [docs/BYTE_PERFECT_REBUILD.md](docs/BYTE_PERFECT_REBUILD.md)

---

## 📊 Tracking Scripts

Progress tracking and logging.

### Scripts in this category are documented above in Root Scripts:
- `start-tracking.ps1` - Automatic tracking
- `track.ps1` - Manual tracking
- `log.ps1` - Session logging
- `update.ps1` - Chat log updates

---

## 🛠️ Tools Scripts

Development tools in the `tools/` subdirectory.

### Build System Tools

#### Build-System.ps1
**Location:** `tools/`  
**Purpose:** Build system orchestrator  
**Usage:** `.\tools\Build-System.ps1`

**Features:**
- Manages build workflow
- Coordinates multiple build types
- Integrates asset building
- Handles dependencies

---

#### Build-Validator.ps1
**Location:** `tools/`  
**Purpose:** Validate build output  
**Usage:** `.\tools\Build-Validator.ps1`

**Checks:**
- ROM file size (must be 1MB)
- Header structure
- Bank organization
- Checksum validation

---

#### Build-Watch.ps1
**Location:** `tools/`  
**Purpose:** Watch files and auto-rebuild  
**Usage:** `.\tools\Build-Watch.ps1`

**Features:**
- Monitors src/ directory for changes
- Automatically triggers rebuild
- Debounces rapid changes
- Logs all build attempts

---

#### dev-watch.ps1
**Location:** `tools/`  
**Purpose:** Development file watcher  
**Usage:** `.\tools\dev-watch.ps1`

**Features:**
- Watches for code changes
- Runs formatters automatically
- Validates on save
- Developer-friendly output

---

### Formatting & Standards

#### format_asm.ps1 ⭐
**Location:** `tools/`  
**Purpose:** Format ASM files to project standards  
**Usage:**
```powershell
.\tools\format_asm.ps1 -Path file.asm              # Format file
.\tools\format_asm.ps1 -Path file.asm -DryRun      # Preview only
```

**Features:**
- Standardizes indentation (tabs)
- Aligns columns (labels, opcodes, operands, comments)
- Fixes line endings (CRLF)
- Ensures UTF-8 with BOM encoding
- Preserves existing formatting where appropriate

**Column Alignment:**
- Labels: Column 0
- Opcodes: Column 23
- Operands: Column 47
- Comments: Column 57

**VS Code Integration:**
- Task: "✨ Format ASM File"
- Task: "🔍 Verify ASM Formatting"

---

#### fix_indentation.ps1
**Location:** `tools/`  
**Purpose:** Fix ASM indentation issues  
**Usage:** `.\tools\fix_indentation.ps1 file.asm`

---

#### test_format_validation.ps1
**Location:** `tools/`  
**Purpose:** Test formatting validation  
**Usage:** `.\tools\test_format_validation.ps1`

---

#### standardize_registers.ps1
**Location:** `tools/`  
**Purpose:** Standardize SNES register naming  
**Usage:** `.\tools\standardize_registers.ps1 file.asm`

**Changes:**
- `$2100` → `INIDISP` (with proper labels)
- `$2121` → `CGADD`
- Etc. (uses snes_registers.inc)

---

#### convert_to_lowercase.ps1
**Location:** `tools/`  
**Purpose:** Convert labels to lowercase  
**Usage:** `.\tools\convert_to_lowercase.ps1 file.asm`

---

#### rename_instruction_labels.ps1
**Location:** `tools/`  
**Purpose:** Rename instruction labels systematically  
**Usage:** `.\tools\rename_instruction_labels.ps1 file.asm`

---

#### format_priority_banks.ps1
**Location:** `tools/`  
**Purpose:** Format priority 1 banks  
**Usage:** `.\tools\format_priority_banks.ps1`

---

#### format_priority2_banks.ps1
**Location:** `tools/`  
**Purpose:** Format priority 2 banks  
**Usage:** `.\tools\format_priority2_banks.ps1`

---

#### format_priority3_sections.ps1
**Location:** `tools/`  
**Purpose:** Format priority 3 sections  
**Usage:** `.\tools\format_priority3_sections.ps1`

---

### Disassembly Tools

#### Aggressive-Disassemble.ps1
**Location:** `tools/`  
**Purpose:** Aggressive disassembly processing  
**Usage:** `.\tools\Aggressive-Disassemble.ps1`

**Features:**
- Processes entire ROM
- Labels all code sections
- Identifies data regions
- Generates comprehensive output

---

#### Import-Reference-Disassembly.ps1
**Location:** `tools/`  
**Purpose:** Import reference disassembly  
**Usage:** `.\tools\Import-Reference-Disassembly.ps1`

**Process:**
1. Reads external disassembly
2. Converts to project format
3. Merges with existing work
4. Preserves custom labels

---

### Data Cataloging

#### scan_addresses.ps1
**Location:** `tools/`  
**Purpose:** Scan for raw memory addresses in ASM  
**Usage:** `.\tools\scan_addresses.ps1`

**Output:**
- Lists all $XXXX raw addresses
- Groups by bank
- Identifies unlabeled addresses
- Suggests label additions

**Report:** `reports/address-scan-[timestamp].txt`

---

#### catalog_rom_data.ps1
**Location:** `tools/`  
**Purpose:** Catalog all DATA8/DATA16/ADDR labels  
**Usage:** `.\tools\catalog_rom_data.ps1`

**Output:**
- Complete list of data labels
- Organized by type (DATA8, DATA16, ADDR, etc.)
- Grouped by bank
- Includes address ranges

**Report:** `reports/data-catalog-[timestamp].csv`

---

### GitHub Integration

#### create_github_issues.ps1
**Location:** `tools/`  
**Purpose:** Create GitHub issues from templates  
**Usage:** `.\tools\create_github_issues.ps1`

**Features:**
- Reads issue templates
- Creates issues via GitHub API
- Sets labels, milestones
- Links related issues

---

#### create_github_sub_issues.ps1
**Location:** `tools/`  
**Purpose:** Create sub-issues for epics  
**Usage:** `.\tools\create_github_sub_issues.ps1`

---

#### create_github_granular_issues.ps1
**Location:** `tools/`  
**Purpose:** Create granular task issues  
**Usage:** `.\tools\create_github_granular_issues.ps1`

---

#### add_children_to_parent_checklists.ps1
**Location:** `tools/`  
**Purpose:** Add child issue checklists to parent issues  
**Usage:** `.\tools\add_children_to_parent_checklists.ps1`

---

#### add_tasks_to_child_issues.ps1
**Location:** `tools/`  
**Purpose:** Add task lists to child issues  
**Usage:** `.\tools\add_tasks_to_child_issues.ps1`

---

#### link_child_issues_to_parents.ps1
**Location:** `tools/`  
**Purpose:** Link child issues to parent epics  
**Usage:** `.\tools\link_child_issues_to_parents.ps1`

---

#### setup_project_board.ps1
**Location:** `tools/`  
**Purpose:** Set up GitHub project board  
**Usage:** `.\tools\setup_project_board.ps1`

---

#### apply_labels.ps1
**Location:** `tools/`  
**Purpose:** Apply labels to GitHub issues  
**Usage:** `.\tools\apply_labels.ps1`

---

## 🔧 Common Workflows

### Initial Setup
```powershell
# 1. Run setup (once)
.\setup.ps1

# 2. Start automatic tracking (once)
.\start-tracking.ps1

# 3. Build ROM
.\build.ps1
```

### Development Workflow
```powershell
# 1. Edit ASM files
# (tracking happens automatically)

# 2. Format code
.\tools\format_asm.ps1 -Path src\asm\bank_XX.asm

# 3. Build
.\build.ps1

# 4. Verify
.\quick-verify.ps1

# 5. Log changes
.\update.ps1
```

### Build Verification
```powershell
# Quick check
.\quick-verify.ps1

# Full roundtrip test
.\test-roundtrip.ps1

# Detailed report
.\build-report.ps1
```

### Formatting Multiple Files
```powershell
# Format all bank files
Get-ChildItem src\asm\bank_*.asm | ForEach-Object {
    .\tools\format_asm.ps1 -Path $_.FullName
}

# Preview changes first
Get-ChildItem src\asm\bank_*.asm | ForEach-Object {
    .\tools\format_asm.ps1 -Path $_.FullName -DryRun
}
```

---

## 📝 Script Parameters

### Common Parameters

Most scripts support these parameters:

**-Verbose**
- Shows detailed output
- Useful for debugging
- Example: `.\build.ps1 -Verbose`

**-WhatIf** (some scripts)
- Preview mode (no changes made)
- Shows what would happen
- Example: `.\format_asm.ps1 -Path file.asm -WhatIf`

**-DryRun** (formatting scripts)
- Same as -WhatIf
- Preview changes only
- Example: `.\tools\format_asm.ps1 -Path file.asm -DryRun`

**-Force**
- Skip confirmations
- Overwrite existing files
- Example: `.\build.ps1 -Force`

**-Clean**
- Remove previous build artifacts
- Start fresh build
- Example: `.\build.ps1 -Clean`

---

## 🎯 Dependencies

### Required Tools
- **PowerShell 5.1+** (Windows) or **PowerShell Core 7+** (cross-platform)
- **Asar** - SNES assembler (for build scripts)
- **Python 3.x** - For Python tool integration

### Optional Tools
- **Git** - For version control integration
- **GitHub CLI (gh)** - For GitHub integration scripts

---

## 🔗 Related Documentation

- **[Build Guide](docs/guides/BUILD_GUIDE.md)** - Comprehensive build documentation
- **[Tools Reference](docs/TOOLS_REFERENCE.md)** - Python tools documentation
- **[Contributing Guide](CONTRIBUTING.md)** - Coding standards and workflows
- **[Logging Reference](docs/guides/LOGGING-QUICK-REF.md)** - Logging system guide

---

## 💡 Tips & Best Practices

### Script Execution Policy

If you can't run scripts, set execution policy:
```powershell
# For current user (recommended)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Or bypass for single script
powershell -ExecutionPolicy Bypass -File .\build.ps1
```

### Error Handling

All scripts include error handling. Check `$LASTEXITCODE` after execution:
```powershell
.\build.ps1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed!" -ForegroundColor Red
}
```

### Logging

Most scripts log to `logs/` directory. Check logs for details:
```powershell
# View latest build log
Get-Content logs\build-latest.log -Tail 20
```

---

## 🐛 Troubleshooting

### "Script not found"
- Ensure you're in project root directory
- Use `.\` prefix: `.\build.ps1`

### "Permission denied"
- Run PowerShell as Administrator
- Or adjust execution policy (see above)

### "Asar not found"
- Install Asar from https://github.com/RPGHacker/asar
- Add to PATH or place `asar.exe` in project root

### "Python not found"
- Install Python 3.x
- Ensure `python` is in PATH
- Or use full path in scripts

---

## 📧 Questions?

If you need help with a specific script:

1. Run with `-Verbose` for detailed output
2. Check related documentation (links above)
3. Review error messages in logs
4. Create a GitHub issue

---

**Happy scripting! 🎮**
