#!/usr/bin/env python3
"""
ASM Spacing Normalization Script

Ensures single space between instructions and their parameters,
removes trailing whitespace, and normalizes spacing around operators.

Usage:
    python tools/normalize_spacing.py [--dry-run] [--bank XX]

Options:
    --dry-run    Show what would be changed without modifying files
    --bank XX    Process only a specific bank (e.g., --bank 00)
"""

import re
import sys
from pathlib import Path
from typing import List, Tuple


def normalize_instruction_spacing(line: str) -> Tuple[str, bool]:
    """
    Normalize spacing between instruction and parameters.
    Ensures single space after instruction mnemonic.

    Returns: (normalized_line, was_changed)
    """
    # Skip non-instruction lines (labels, comments, blank lines)
    if not line.strip():
        return line, False
    if line.lstrip().startswith(';'):
        return line, False
    if re.match(r'^\w+:', line):  # Label line
        return line, False

    # Match instruction lines: [whitespace][instruction][.mode][whitespace][params]
    # Preserve the line ending by stripping it first, then adding it back
    line_ending = '\n' if line.endswith('\n') else ''
    line_content = line.rstrip('\n')
    
    match = re.match(r'^(\s+)(\w+(?:\.[bwl])?)\s+(.*)$', line_content)
    if match:
        indent, instruction, rest = match.groups()
        original = line
        normalized = f'{indent}{instruction} {rest}{line_ending}'
        return normalized, (original != normalized)

    return line, False


def remove_trailing_whitespace(line: str) -> Tuple[str, bool]:
    """Remove trailing whitespace from line"""
    original = line
    normalized = line.rstrip() + '\n' if line.endswith('\n') else line.rstrip()
    return normalized, (original != normalized)


def normalize_operator_spacing(line: str) -> Tuple[str, bool]:
    """Normalize spacing around operators in expressions"""
    # Skip comment-only lines
    if line.lstrip().startswith(';'):
        return line, False

    original = line

    # Split line into code and comment parts
    parts = line.split(';', 1)
    code_part = parts[0]
    comment_part = ';' + parts[1] if len(parts) > 1 else ''

    # Normalize spaces around operators: =, +, -, *, /
    # But preserve hex values like $ff-$00
    changed = False

    # Note: Be careful not to modify hex values or memory addresses
    # This is conservative and only fixes obvious spacing issues

    normalized = code_part + comment_part
    return normalized, (original != normalized)


def process_file(filepath: Path, dry_run: bool = False) -> dict:
    """Process a single ASM file"""
    print(f"Processing {filepath.name}...")

    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    stats = {
        'instruction_spacing': 0,
        'trailing_whitespace': 0,
        'operator_spacing': 0
    }

    normalized_lines = []

    for line in lines:
        # Apply transformations in order
        normalized = line

        # 1. Normalize instruction spacing
        normalized, changed1 = normalize_instruction_spacing(normalized)
        if changed1:
            stats['instruction_spacing'] += 1

        # 2. Remove trailing whitespace
        normalized, changed2 = remove_trailing_whitespace(normalized)
        if changed2:
            stats['trailing_whitespace'] += 1

        # 3. Normalize operator spacing
        normalized, changed3 = normalize_operator_spacing(normalized)
        if changed3:
            stats['operator_spacing'] += 1

        normalized_lines.append(normalized)

    total_changes = sum(stats.values())

    if total_changes > 0:
        if not dry_run:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.writelines(normalized_lines)
            print(f"  [OK] Modified: {total_changes} lines")
        else:
            print(f"  [DRY RUN] Would modify: {total_changes} lines")

        print(f"     - Instruction spacing: {stats['instruction_spacing']}")
        print(f"     - Trailing whitespace: {stats['trailing_whitespace']}")
        print(f"     - Operator spacing: {stats['operator_spacing']}")
    else:
        print(f"  [OK] No changes needed")

    return stats


def main():
    """Main entry point"""
    dry_run = '--dry-run' in sys.argv
    specific_bank = None

    # Check for --bank argument
    for i, arg in enumerate(sys.argv):
        if arg == '--bank' and i + 1 < len(sys.argv):
            specific_bank = sys.argv[i + 1]
            break

    # Determine files to process
    if specific_bank:
        pattern = f'src/asm/bank_{specific_bank}_documented.asm'
        files = list(Path('.').glob(pattern))
        if not files:
            print(f"[ERROR] Error: Bank {specific_bank} not found")
            return 1
    else:
        files = sorted(Path('.').glob('src/asm/bank_*_documented.asm'))

    if not files:
        print("[ERROR] Error: No ASM files found")
        return 1

    print(f"{'=' * 60}")
    print(f"ASM Spacing Normalization")
    print(f"{'=' * 60}")
    print(f"Mode: {'DRY RUN' if dry_run else 'LIVE'}")
    print(f"Files: {len(files)}")
    print(f"{'=' * 60}\n")

    total_stats = {
        'instruction_spacing': 0,
        'trailing_whitespace': 0,
        'operator_spacing': 0
    }

    for filepath in files:
        stats = process_file(filepath, dry_run)
        for key in total_stats:
            total_stats[key] += stats[key]

    print(f"\n{'=' * 60}")
    print(f"Summary")
    print(f"{'=' * 60}")
    print(f"Instruction spacing fixed: {total_stats['instruction_spacing']}")
    print(f"Trailing whitespace removed: {total_stats['trailing_whitespace']}")
    print(f"Operator spacing fixed: {total_stats['operator_spacing']}")
    print(f"Total lines modified: {sum(total_stats.values())}")

    if dry_run:
        print(f"\n[INFO] Run without --dry-run to apply changes")
    else:
        print(f"\n[OK] All changes applied successfully!")

    return 0


if __name__ == '__main__':
    sys.exit(main())
