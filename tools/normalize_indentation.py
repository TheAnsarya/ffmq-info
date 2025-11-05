#!/usr/bin/env python3
"""
ASM Indentation Normalization Script

Converts all space-based indentation to tabs.
Ensures consistent tab-based indentation throughout the codebase.

Usage:
    python tools/normalize_indentation.py [--dry-run] [--bank XX] [--tab-width 4]

Options:
    --dry-run       Show what would be changed without modifying files
    --bank XX       Process only a specific bank (e.g., --bank 00)
    --tab-width N   Number of spaces per tab level (default: 4)
"""

import re
import sys
from pathlib import Path
from typing import Tuple


def normalize_indentation(line: str, tab_width: int = 4) -> Tuple[str, bool]:
    """
    Convert leading spaces to tabs.

    Rules:
    - Labels (text starting at column 0 ending with :) = no indentation
    - Instructions = 1 tab
    - Nested instructions (after label on same line) = appropriate tabs
    - Preserve comment alignment where reasonable

    Returns: (normalized_line, was_changed)
    """
    # Don't modify blank lines or pure comment lines
    if not line.strip():
        return line, False
    if line.lstrip().startswith(';') and not line.startswith('\t'):
        # Comment lines should be indented if they're inline with code
        # For now, preserve them as-is
        return line, False

    original = line

    # Check if this is a label line (starts with identifier followed by :)
    if re.match(r'^\w+:', line):
        # Labels should have no indentation
        normalized = line.lstrip()
        return normalized, (original != normalized)

    # For instruction lines, convert leading spaces to tabs
    leading_spaces = len(line) - len(line.lstrip(' '))

    if leading_spaces == 0:
        return line, False

    # Calculate number of tabs needed
    tabs = leading_spaces // tab_width
    remainder_spaces = leading_spaces % tab_width

    # Build normalized line: tabs + remainder spaces + rest of line
    rest_of_line = line.lstrip(' ')
    normalized = '\t' * tabs + ' ' * remainder_spaces + rest_of_line

    return normalized, (original != normalized)


def process_file(filepath: Path, dry_run: bool = False, tab_width: int = 4) -> dict:
    """Process a single ASM file"""
    print(f"Processing {filepath.name}...")

    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    stats = {
        'lines_changed': 0,
        'tabs_added': 0,
        'spaces_removed': 0
    }

    normalized_lines = []

    for line in lines:
        normalized, changed = normalize_indentation(line, tab_width)

        if changed:
            stats['lines_changed'] += 1
            # Count tabs added
            original_tabs = line.count('\t')
            new_tabs = normalized.count('\t')
            stats['tabs_added'] += (new_tabs - original_tabs)
            # Count spaces removed from indentation
            original_leading = len(line) - len(line.lstrip(' '))
            new_leading = len(normalized) - len(normalized.lstrip(' \t'))
            stats['spaces_removed'] += original_leading

        normalized_lines.append(normalized)

    total_changes = stats['lines_changed']

    if total_changes > 0:
        if not dry_run:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.writelines(normalized_lines)
            print(f"  [OK] Modified: {total_changes} lines")
        else:
            print(f"  [DRY RUN] Would modify: {total_changes} lines")

        print(f"     - Lines changed: {stats['lines_changed']}")
        print(f"     - Tabs added: {stats['tabs_added']}")
        print(f"     - Spaces removed: {stats['spaces_removed']}")
    else:
        print(f"  [OK] No changes needed")

    return stats


def main():
    """Main entry point"""
    dry_run = '--dry-run' in sys.argv
    specific_bank = None
    tab_width = 4

    # Check for --bank argument
    for i, arg in enumerate(sys.argv):
        if arg == '--bank' and i + 1 < len(sys.argv):
            specific_bank = sys.argv[i + 1]
        elif arg == '--tab-width' and i + 1 < len(sys.argv):
            tab_width = int(sys.argv[i + 1])

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
    print(f"ASM Indentation Normalization")
    print(f"{'=' * 60}")
    print(f"Mode: {'DRY RUN' if dry_run else 'LIVE'}")
    print(f"Files: {len(files)}")
    print(f"Tab width: {tab_width} spaces")
    print(f"{'=' * 60}\n")

    total_stats = {
        'lines_changed': 0,
        'tabs_added': 0,
        'spaces_removed': 0
    }

    for filepath in files:
        stats = process_file(filepath, dry_run, tab_width)
        for key in total_stats:
            total_stats[key] += stats[key]

    print(f"\n{'=' * 60}")
    print(f"Summary")
    print(f"{'=' * 60}")
    print(f"Lines modified: {total_stats['lines_changed']}")
    print(f"Tabs added: {total_stats['tabs_added']}")
    print(f"Leading spaces removed: {total_stats['spaces_removed']}")

    if dry_run:
        print(f"\n[INFO] Run without --dry-run to apply changes")
    else:
        print(f"\n[OK] All changes applied successfully!")

    return 0


if __name__ == '__main__':
    sys.exit(main())
