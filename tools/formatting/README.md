# Formatting Tools

This directory contains tools for formatting, standardizing, and cleaning up assembly code and project files.

## Python Formatting Tools

### Case Normalization
- **normalize_case.py** - Normalize instruction and register case
  - Standardizes instruction casing (LDA, STA, etc.)
  - Normalizes register names (A, X, Y, etc.)
  - Preserves label casing
  - Configurable case style
  - Usage: `python tools/formatting/normalize_case.py <file.asm> [--style upper|lower]`

- **normalize_case_original.py** - Original case normalizer
  - Legacy case normalization implementation
  - Fallback option for compatibility
  - Usage: `python tools/formatting/normalize_case_original.py <file.asm>`

### Spacing and Indentation
- **normalize_indentation.py** - Standardize indentation
  - Converts tabs to spaces
  - Aligns instructions and operands
  - Formats labels consistently
  - Configurable indent width
  - Usage: `python tools/formatting/normalize_indentation.py <file.asm> [--width 4]`

- **normalize_spacing.py** - Normalize whitespace
  - Removes trailing whitespace
  - Standardizes line endings
  - Normalizes spacing around operators
  - Removes excessive blank lines
  - Usage: `python tools/formatting/normalize_spacing.py <file.asm>`

### Label Management
- **fix_duplicate_labels.py** - Fix duplicate label definitions
  - Detects duplicate labels
  - Renames duplicates with unique suffixes
  - Updates all references
  - Logs all changes
  - Usage: `python tools/formatting/fix_duplicate_labels.py <file.asm> [--suffix _dup]`

### Encoding Fixes
- **fix_windows_encoding.py** - Fix Windows encoding issues
  - Converts CRLF to LF
  - Fixes UTF-8 BOM
  - Handles mixed encodings
  - Preserves file timestamps
  - Usage: `python tools/formatting/fix_windows_encoding.py <file.asm>`

## PowerShell Formatting Scripts

### Primary Formatters
- **format_asm.ps1** ⭐ - Main assembly formatter
  - Comprehensive formatting of assembly files
  - Applies all formatting rules
  - Batch processing support
  - Creates backups before formatting
  - Usage: `.\tools\formatting\format_asm.ps1 -Path <file.asm> [-NoBackup]`

### Priority Bank Formatting
- **format_priority_banks.ps1** - Format priority 1 banks
  - Formats high-priority banks first
  - Focuses on core engine code
  - Usage: `.\tools\formatting\format_priority_banks.ps1`

- **format_priority2_banks.ps1** - Format priority 2 banks
  - Formats medium-priority banks
  - Battle and graphics systems
  - Usage: `.\tools\formatting\format_priority2_banks.ps1`

- **format_priority3_sections.ps1** - Format priority 3 sections
  - Formats lower-priority sections
  - Data tables and constants
  - Usage: `.\tools\formatting\format_priority3_sections.ps1`

### Advanced Formatting
- **fix_indentation.ps1** - Advanced indentation fixer
  - Context-aware indentation
  - Handles nested structures
  - Preserves manual formatting flags
  - Usage: `.\tools\formatting\fix_indentation.ps1 -Path <file.asm>`

- **convert_to_lowercase.ps1** - Convert to lowercase
  - Converts instructions to lowercase
  - Maintains label casing
  - Configurable exclusions
  - Usage: `.\tools\formatting\convert_to_lowercase.ps1 -Path <file.asm>`

### Label and Symbol Tools
- **rename_instruction_labels.ps1** - Rename instruction labels
  - Renames labels to follow conventions
  - Updates all references
  - Generates rename report
  - Usage: `.\tools\formatting\rename_instruction_labels.ps1 -Old <name> -New <name>`

- **standardize_registers.ps1** - Standardize register names
  - Normalizes A, X, Y register references
  - Fixes [A], [X], [Y] syntax
  - Handles addressing modes
  - Usage: `.\tools\formatting\standardize_registers.ps1 -Path <file.asm>`

### Validation
- **test_format_validation.ps1** - Validate formatting
  - Checks formatting compliance
  - Reports violations
  - Suggests fixes
  - Usage: `.\tools\formatting\test_format_validation.ps1 -Path <file.asm>`

## Common Workflows

### Format Single File
```bash
# Python approach
python tools/formatting/normalize_case.py src/bank00.asm
python tools/formatting/normalize_indentation.py src/bank00.asm
python tools/formatting/normalize_spacing.py src/bank00.asm

# Or PowerShell all-in-one
.\tools\formatting\format_asm.ps1 -Path src\bank00.asm
```

### Format Entire Project
```powershell
# Format all priority 1 banks (core engine)
.\tools\formatting\format_priority_banks.ps1

# Format all priority 2 banks (battle/graphics)
.\tools\formatting\format_priority2_banks.ps1

# Format remaining sections
.\tools\formatting\format_priority3_sections.ps1

# Validate all formatting
.\tools\formatting\test_format_validation.ps1 -Path src\
```

### Fix Specific Issues
```bash
# Fix duplicate labels
python tools/formatting/fix_duplicate_labels.py src/bank02.asm

# Fix encoding issues
python tools/formatting/fix_windows_encoding.py src/bank03.asm

# Standardize registers
.\tools\formatting\standardize_registers.ps1 -Path src\bank01.asm
```

### Batch Processing
```powershell
# Format all .asm files in directory
Get-ChildItem src\*.asm | ForEach-Object {
    .\tools\formatting\format_asm.ps1 -Path $_.FullName
}

# Format with Python (Unix)
find src -name "*.asm" -exec python tools/formatting/normalize_case.py {} \;
```

### Pre-Commit Formatting
```bash
# Format changed files before commit
git diff --name-only | grep "\.asm$" | while read file; do
    python tools/formatting/normalize_case.py "$file"
    python tools/formatting/normalize_indentation.py "$file"
    python tools/formatting/normalize_spacing.py "$file"
done
```

## Formatting Standards

### Instruction Case
```asm
; Standard: UPPERCASE
LDA #$00
STA $7E0000
JSR Func_Initialize

; Not recommended: lowercase
lda #$00
sta $7e0000
jsr func_initialize
```

### Indentation
```asm
; Standard: 4 spaces for instructions, labels at column 0
MainLoop:
    LDA $00
    BEQ .skip
    JSR ProcessData
.skip:
    RTS

; Data: aligned by type
DataTable:
    .db $00, $01, $02, $03
    .dw $1000, $2000, $3000
```

### Spacing
```asm
; Standard: one space after comma, around operators
LDA #$00                    ; Load zero
STA $7E0000, X              ; Store with X offset
LDA Table + 5, Y            ; Calculate offset

; Alignment: operands at column 24
LDA #$00                    ; Comment at column 40
STA $7E0000, X
```

### Label Naming
```asm
; Global labels: PascalCase
MainGameLoop:
BattleEngine_Initialize:

; Local labels: dot prefix, lowercase
.loop:
.skip:
.done:

; Data labels: descriptive names
EnemyDataTable:
AttackPowerLookup:
```

### Comments
```asm
; File-level comment block
;===============================================================================
; Bank $00 - Core Engine
;===============================================================================

; Function header
;-------------------------------------------------------------------------------
; Function: InitializeSystem
; Description: Initialize all system components
; Parameters: None
; Returns: None
;-------------------------------------------------------------------------------
InitializeSystem:
    ; Inline comments aligned at column 40
    LDA #$00                    ; Clear accumulator
    RTS
```

## Formatting Configuration

### format_config.json
```json
{
    "instruction_case": "upper",
    "register_case": "upper",
    "label_style": "PascalCase",
    "local_label_prefix": ".",
    "indent_width": 4,
    "use_tabs": false,
    "operand_column": 24,
    "comment_column": 40,
    "max_line_length": 100,
    "preserve_blank_lines": 1,
    "line_ending": "LF"
}
```

## Formatting Rules

### Rule 1: Consistent Case
- Instructions: UPPERCASE
- Registers: UPPERCASE (A, X, Y, S, P)
- Directives: lowercase (.db, .dw, .include)
- Labels: PascalCase (global), .lowercase (local)

### Rule 2: Indentation
- Labels: Column 0
- Instructions: 4 spaces from left
- Local labels: 0 spaces (same as instructions for alignment)
- Continued lines: +4 spaces additional

### Rule 3: Spacing
- One space after commas
- One space around operators (+, -, *, /)
- No space before commas or colons
- Align operands at column 24 (optional but recommended)

### Rule 4: Line Length
- Maximum 100 characters
- Break long lines at logical points
- Indent continuation lines

### Rule 5: Comments
- File headers: multi-line comment blocks
- Function headers: standardized format
- Inline comments: aligned at column 40 minimum
- Comment spacing: one space after semicolon

## Dependencies

- Python 3.7+
- PowerShell 5.1+ (for .ps1 scripts)
- Standard library modules only (no pip packages)

## See Also

- **tools/disassembly/** - For disassembly-specific formatting
- **docs/guides/CODING_STANDARDS.md** - Coding standards documentation
- **docs/technical/ASM_STYLE_GUIDE.md** - Assembly style guide
- **.editorconfig** - Editor configuration for auto-formatting

## Tips and Best Practices

### Before Formatting
- Commit current state to git
- Run tests to ensure code works
- Backup files if not using version control
- Review formatting configuration

### During Formatting
- Format one bank at a time
- Verify build still works after formatting
- Check diff to ensure no logic changes
- Test formatted code

### After Formatting
- Run validation script
- Build ROM and compare
- Run test suite
- Commit formatting changes separately

### Maintaining Formatting
- Set up git pre-commit hooks
- Use editor auto-formatting
- Review formatting in code reviews
- Update formatting rules as needed

## Troubleshooting

**Issue: Formatter changes code logic**
- Solution: This should never happen. Review diff carefully, report bug

**Issue: Build fails after formatting**
- Solution: Check for label renames, verify all references updated

**Issue: Merge conflicts after formatting**
- Solution: Format in separate commit, rebase other branches

**Issue: Inconsistent formatting across files**
- Solution: Run format_asm.ps1 on all files, check config consistency

## Validation

### Pre-Commit Validation
```powershell
# Validate formatting before commit
.\tools\formatting\test_format_validation.ps1 -Path src\ -Strict

# Auto-fix validation failures
.\tools\formatting\format_asm.ps1 -Path src\ -Fix
```

### Continuous Integration
```yaml
# GitHub Actions validation
- name: Validate Formatting
  run: |
    python tools/formatting/validate_all.py --strict
```

## Advanced Features

### Custom Formatting Rules
Add custom rules to `format_config.json`:
```json
{
    "custom_rules": [
        {
            "name": "no_trailing_labels",
            "pattern": "^\\w+:\\s+\\w+",
            "error": "Label and instruction on same line"
        }
    ]
}
```

### Formatting Exclusions
Exclude files or patterns from formatting:
```json
{
    "exclude": [
        "src/external/*.asm",
        "src/generated/*.asm",
        "**/old_*.asm"
    ]
}
```

### Batch Formatting
```powershell
# Format with progress bar
$files = Get-ChildItem src\*.asm
$i = 0
foreach ($file in $files) {
    $i++
    Write-Progress -Activity "Formatting" -Status $file.Name -PercentComplete ($i/$files.Count*100)
    .\tools\formatting\format_asm.ps1 -Path $file.FullName -NoBackup
}
```

## Contributing

When modifying formatting tools:
1. Preserve existing code logic
2. Make formatting deterministic (same input = same output)
3. Add tests for edge cases
4. Update formatting rules documentation
5. Version config file format
6. Maintain backwards compatibility
7. Update this README

## Future Development

Planned additions:
- [ ] Auto-formatting on save (editor plugin)
- [ ] Semantic-aware formatting
- [ ] Context-sensitive indentation
- [ ] Custom formatter plugins
- [ ] Real-time formatting validation
- [ ] AI-assisted formatting suggestions
- [ ] Format diff tool (show formatting changes only)
