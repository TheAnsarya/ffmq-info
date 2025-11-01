# Contributing to FFMQ Disassembly Project

Thank you for your interest in contributing to the Final Fantasy Mystic Quest disassembly project! This document provides guidelines and standards for contributing.

## Table of Contents

- [Getting Started](#getting-started)
- [Development Environment](#development-environment)
- [Code Standards](#code-standards)
- [ASM Formatting Standards](#asm-formatting-standards)
- [Commit Guidelines](#commit-guidelines)
- [Pull Request Process](#pull-request-process)
- [Testing](#testing)

## Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/YOUR-USERNAME/ffmq-info.git
   cd ffmq-info
   ```
3. **Set up the development environment** (see below)
4. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

## Development Environment

### Required Tools

- **PowerShell 7.0+** for build scripts
- **Python 3.8+** for tooling
- **asar** assembler ([download here](https://github.com/RPGHacker/asar/releases))
- **Git** for version control

### Optional Tools

- **VS Code** with recommended extensions
- **Mesen-S** emulator for testing
- **Diztinguish** for disassembly analysis

### Setup

Run the setup script to configure your environment:

```powershell
.\setup.ps1
```

This will:
- Check for required tools
- Set up Python virtual environment
- Install dependencies
- Verify build system

## Code Standards

### Assembly Code

All assembly code must follow these standards:

1. **Use meaningful labels** that describe functionality
2. **Add comments** for complex operations
3. **Document subroutines** with purpose, inputs, outputs
4. **Use standard SNES register names** (from `snes_registers.inc`)
5. **Follow formatting standards** (see below)

### Example

```asm
; ==============================================================================
; LoadPlayerStats - Load player character statistics
; ==============================================================================
; Inputs:
;   A = Character ID (0-3)
; Outputs:
;   X = Character stats pointer
;   Carry = Set if invalid character ID
; ==============================================================================
LoadPlayerStats:
	cmp	#$04		; Check if character ID is valid
	bcs	.invalid	; Branch if >= 4
	
	asl	a		; Multiply by 2 (word size)
	tax			; Transfer to X
	lda	CharacterStatsTable,x	; Load stats pointer
	rts
	
.invalid:
	sec			; Set carry to indicate error
	rts
```

## ASM Formatting Standards

**All assembly files must follow standardized formatting for consistency and readability.**

### Formatting Rules

1. **Line Endings**: CRLF (Windows standard)
2. **Encoding**: UTF-8 with BOM
3. **Indentation**: Tabs (1 tab = 4 spaces equivalent)
4. **Column Alignment**:
   - Labels: Column 0
   - Opcodes: Column 23
   - Operands: Column 47
   - Comments: Column 57

### Example Formatting

```asm
; Labels start at column 0
MainLoop:
	lda	$2137		; Opcodes at col 23, operands at 47, comments at 57
	and	#$80		; Consistent spacing
	beq	MainLoop	; Easy to read
	rts
```

### Using the Formatter

#### Format a Single File

```powershell
# Preview changes (dry-run)
.\tools\format_asm.ps1 -Path src\asm\bank_00_documented.asm -DryRun

# Apply formatting
.\tools\format_asm.ps1 -Path src\asm\bank_00_documented.asm
```

#### VS Code Tasks

You can use VS Code tasks to format files:

1. Open an ASM file
2. Press `Ctrl+Shift+P`
3. Select:
   - **"✨ Format ASM File"** to apply formatting
   - **"🔍 Verify ASM Formatting (Dry-Run)"** to preview changes

#### Format Multiple Files

```powershell
# Format all bank files
Get-ChildItem src\asm\bank_*.asm | ForEach-Object {
    .\tools\format_asm.ps1 -Path $_.FullName
}
```

### Pre-Commit Formatting

Before committing assembly code:

1. Run the formatter on modified files
2. Verify changes with dry-run
3. Ensure line count remains the same (formatting shouldn't add/remove lines)

## Commit Guidelines

### Commit Messages

Follow this format:

```
<type>: <short summary> (max 72 chars)

<optional detailed description>

<optional footer>
```

#### Types

- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation changes
- **style**: Formatting, whitespace (no code changes)
- **refactor**: Code restructuring (no behavior change)
- **test**: Adding or updating tests
- **chore**: Maintenance tasks

#### Examples

```
feat: Add character stats documentation to bank_0B

Added detailed comments documenting the character statistics
data structure including HP, MP, attack, defense, and experience
values for all four characters.

Closes #42
```

```
style: Format bank_03_documented.asm - ASM code formatting

Applied standardized formatting:
- CRLF line endings
- UTF-8 with BOM encoding
- Tab indentation
- Column alignment (labels: 0, opcodes: 23, operands: 47, comments: 57)

Part of Issue #17
```

### Commit Frequency

- **Small, focused commits** are preferred
- **One logical change per commit**
- **Formatting changes** should be in separate commits from code changes

## Pull Request Process

### Before Submitting

1. **Format your code** using the formatter
2. **Test your changes** (build the ROM and verify)
3. **Update documentation** if needed
4. **Run tests** if applicable
5. **Rebase on main** to ensure clean history

### PR Title

Use the same format as commit messages:

```
feat: Add complete battle system documentation
```

### PR Description

Include:

1. **What** - What does this PR do?
2. **Why** - Why is this change needed?
3. **How** - How was it implemented?
4. **Testing** - How was it tested?
5. **Related Issues** - Link to issues (e.g., "Closes #42")

### Example PR Description

```markdown
## What
Adds complete documentation for the battle system in bank_03.

## Why
The battle system code was previously undocumented, making it difficult
for contributors to understand combat mechanics.

## How
- Added detailed comments for each subroutine
- Documented data structures for enemies, attacks, and damage calculation
- Created flowcharts for combat flow

## Testing
- Built ROM successfully
- Verified ROM matches original (byte-perfect)
- Tested battle sequences in Mesen-S emulator

Closes #23
```

## Testing

### Build Testing

Always test your changes by building the ROM:

```powershell
# Standard build
.\build.ps1

# Verbose output
.\build.ps1 -Verbose

# Clean build
.\build.ps1 -Clean
```

### ROM Verification

After building, verify the ROM:

```powershell
# Compare with original ROM
.\tools\verify-build.ps1
```

### Emulator Testing

Test your changes in an emulator:

1. Load the built ROM in Mesen-S
2. Test affected game areas
3. Verify no regressions
4. Document any behavior changes

## Questions?

If you have questions:

1. Check existing documentation in `docs/`
2. Search existing issues on GitHub
3. Ask in a new issue with the `question` label

## Code of Conduct

- **Be respectful** and constructive
- **Help others** learn and improve
- **Focus on the code**, not the person
- **Assume good intentions**
- **Celebrate contributions** of all sizes

Thank you for contributing to the FFMQ disassembly project! 🎮✨
