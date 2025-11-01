# Contributing to FFMQ Disassembly Project

Thank you for your interest in contributing to the Final Fantasy Mystic Quest disassembly project! This document provides guidelines and standards for contributing.

## Table of Contents

- [Getting Started](#getting-started)
- [Development Environment](#development-environment)
- [Code Standards](#code-standards)
  - [ASM Code Style](#asm-code-style)
  - [Python Code Style](#python-code-style)
  - [PowerShell Code Style](#powershell-code-style)
- [Documentation Standards](#documentation-standards)
- [Label Naming Conventions](#label-naming-conventions)
- [Commit Guidelines](#commit-guidelines)
- [Pull Request Process](#pull-request-process)
- [Testing Requirements](#testing-requirements)
- [Code of Conduct](#code-of-conduct)

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

### ASM Code Style

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

### Python Code Style

All Python code should follow PEP 8 guidelines:

1. **Use 4 spaces** for indentation (no tabs)
2. **Maximum line length**: 88 characters (Black formatter standard)
3. **Use type hints** for function signatures
4. **Add docstrings** for all functions and classes
5. **Follow PEP 8 naming**:
   - `snake_case` for functions and variables
   - `PascalCase` for classes
   - `UPPER_SNAKE_CASE` for constants

#### Example

```python
from pathlib import Path
from typing import Optional, List

def extract_graphics(rom_path: Path, output_dir: Path) -> List[Path]:
    """Extract graphics from SNES ROM.
    
    Args:
        rom_path: Path to the input ROM file
        output_dir: Directory to write extracted graphics
        
    Returns:
        List of paths to extracted PNG files
        
    Raises:
        FileNotFoundError: If ROM file doesn't exist
        ValueError: If ROM format is invalid
    """
    if not rom_path.exists():
        raise FileNotFoundError(f"ROM not found: {rom_path}")
    
    # Implementation...
    return extracted_files
```

#### Formatting Tools

Use these tools for Python code:

```powershell
# Format code with Black
python -m black tools/

# Check with flake8
python -m flake8 tools/

# Type check with mypy
python -m mypy tools/
```

### PowerShell Code Style

PowerShell scripts should follow these conventions:

1. **Use PascalCase** for function names
2. **Use proper parameters** with types and help text
3. **Add comment-based help** for all functions
4. **Use approved verbs** (Get, Set, New, Remove, etc.)
5. **Handle errors gracefully** with try/catch
6. **Use Write-Verbose** for debugging output

#### Example

```powershell
<#
.SYNOPSIS
    Formats an assembly source file with standardized spacing and alignment.

.DESCRIPTION
    Applies consistent formatting to SNES assembly files including line endings,
    encoding, indentation, and column alignment for improved readability.

.PARAMETER Path
    Path to the assembly file to format.

.PARAMETER DryRun
    Preview changes without modifying the file.

.EXAMPLE
    .\format_asm.ps1 -Path "src\asm\bank_00.asm"
    Format the specified assembly file.

.EXAMPLE
    .\format_asm.ps1 -Path "src\asm\bank_00.asm" -DryRun
    Preview formatting changes without saving.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateScript({Test-Path $_})]
    [string]$Path,
    
    [switch]$DryRun
)

try {
    Write-Verbose "Processing file: $Path"
    # Implementation...
}
catch {
    Write-Error "Failed to format file: $_"
    exit 1
}
```

## Documentation Standards

All documentation should follow these guidelines:

### Markdown Style

1. **Use ATX-style headers** (`#` not underlines)
2. **One sentence per line** for easier diffs
3. **Wrap code in backticks** (`` ` ``) or code blocks (` ``` `)
4. **Use relative links** for internal documentation
5. **Include table of contents** for docs > 200 lines

### Documentation Structure

Every documentation file should have:

```markdown
# Document Title

Brief one-paragraph description of what this document covers.

## Table of Contents

- [Section 1](#section-1)
- [Section 2](#section-2)

## Section 1

Content here...

## Section 2

More content...

## See Also

- [Related Doc 1](related-doc.md)
- [Related Doc 2](other-doc.md)
```

### Code Examples

- **Always test code examples** before adding them
- **Include expected output** when relevant
- **Provide context** - explain what the code does
- **Use syntax highlighting** with language tags

### Technical Accuracy

- **Verify all technical details** before documenting
- **Include version numbers** for tool requirements
- **Update docs** when code changes
- **Mark deprecated features** clearly

## Label Naming Conventions

GitHub issues and PRs use these label categories:

### Type Labels

- `type: bug` - Something isn't working correctly
- `type: feature` - New functionality or enhancement
- `type: documentation` - Documentation improvements
- `type: formatting` - Code style and formatting
- `type: build-system` - Build scripts and configuration
- `type: tools` - Development tools and utilities
- `type: data` - Game data extraction and organization
- `type: graphics` - Graphics-related work
- `type: extraction` - Data/asset extraction tasks

### Priority Labels

- `priority: critical` - Blocking issue, must fix immediately
- `priority: high` - Important, should address soon
- `priority: medium` - Normal priority
- `priority: low` - Nice to have, not urgent

### Status Labels

- `status: blocked` - Cannot proceed due to dependency
- `status: in-progress` - Actively being worked on
- `status: needs-review` - Awaiting code review
- `status: needs-testing` - Awaiting testing/verification

### Effort Labels

- `effort: small` - < 2 hours of work
- `effort: medium` - 2-8 hours of work
- `effort: large` - > 8 hours of work

### Special Labels

- `good-first-issue` - Suitable for newcomers
- `help-wanted` - Community help requested
- `question` - Needs clarification or discussion
- `requires: testing` - Needs test coverage
- `duplicate` - Duplicate of another issue
- `wontfix` - Will not be addressed

### Using Labels

When creating issues or PRs:

1. **Always add a type label** (e.g., `type: bug`)
2. **Add priority** if known (e.g., `priority: high`)
3. **Add effort estimate** for issues (e.g., `effort: medium`)
4. **Add status labels** as work progresses
5. **Tag special cases** (`good-first-issue`, `help-wanted`)

## Testing Requirements

**All contributions must be tested before submission.**

### Required Testing

1. **Build Test**: ROM must build successfully
2. **Verification Test**: ROM must match original (for documentation/formatting changes)
3. **Functional Test**: Changes must be tested in emulator

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

### Unit Testing (for Tools)

Python tools should include unit tests:

```powershell
# Run all tests
python -m pytest tests/

# Run with coverage
python -m pytest --cov=tools tests/

# Run specific test file
python -m pytest tests/test_extract_graphics.py
```

### Integration Testing

For complex changes:

1. **Test the full workflow** from source to ROM
2. **Verify all affected systems** work together
3. **Check for side effects** in unrelated areas
4. **Test edge cases** and error conditions

### Test Documentation

Document your testing in PR descriptions:

```markdown
## Testing Performed

- ✅ Built ROM successfully with `.\build.ps1`
- ✅ Verified byte-perfect match with original ROM
- ✅ Tested in Mesen-S: Loaded save file, entered battle, used new spell
- ✅ Checked for regressions: Tested inventory, equipment, status menus
- ✅ Ran unit tests: All 42 tests passed
```

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
