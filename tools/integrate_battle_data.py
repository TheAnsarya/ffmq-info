#!/usr/bin/env python3
"""
Build System Integration Tool
==============================

This script integrates converted battle data into the ROM build system.

It replaces raw hex data in bank_02.asm with include directives to the
converted ASM files.

Backup is created automatically before modification.
"""

import shutil
from pathlib import Path
from datetime import datetime

# Data sections to replace (line numbers are 1-indexed)
SECTIONS = {
    'attack_data': {
        'start_line': 6367,
        'end_line': 6457,
        'include': 'incsrc "../../data/converted/attacks/attacks_data.asm"',
        'comment': '; Attack Data (169 attacks × 7 bytes = 1183 bytes)'
    },
    'enemy_levels': {
        'start_line': 6469,
        'end_line': 6505,  # One before enemy stats start
        'include': 'incsrc "../../data/converted/enemies/enemies_level.asm"',
        'comment': '; Enemy Level Data (83 enemies × 3 bytes = 249 bytes)'
    },
    'enemy_stats': {
        'start_line': 6506,
        'end_line': 6590,
        'include': 'incsrc "../../data/converted/enemies/enemies_stats.asm"',
        'comment': '; Enemy Stats Data (83 enemies × 14 bytes = 1162 bytes)'
    }
}

def backup_file(file_path):
    """Create a timestamped backup of a file."""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_path = file_path.parent / f"{file_path.stem}.backup_{timestamp}{file_path.suffix}"
    shutil.copy2(file_path, backup_path)
    print(f"[INFO] Created backup: {backup_path.name}")
    return backup_path

def integrate_battle_data(dry_run=False):
    """
    Integrate battle data into bank_02.asm.

    Args:
        dry_run: If True, show what would be changed without modifying files
    """
    bank02_path = Path("src/asm/banks/bank_02.asm")

    if not bank02_path.exists():
        print(f"[ERROR] {bank02_path} not found")
        return False

    # Read the file
    with open(bank02_path, 'r') as f:
        lines = f.readlines()

    print("="*80)
    print("Build System Integration - Battle Data")
    print("="*80)
    print()

    if dry_run:
        print("[INFO] DRY RUN MODE - No files will be modified")
        print()

    # Create backup if not dry run
    if not dry_run:
        backup_file(bank02_path)

    # Process each section in reverse order (so line numbers stay valid)
    for section_name in reversed(['attack_data', 'enemy_levels', 'enemy_stats']):
        section = SECTIONS[section_name]
        start = section['start_line'] - 1  # Convert to 0-indexed
        end = section['end_line']  # Exclusive end

        print(f"Section: {section_name}")
        print(f"  Lines: {section['start_line']} to {section['end_line']}")
        print(f"  Replacing {end - start} lines with:")
        print(f"    {section['comment']}")
        print(f"    {section['include']}")
        print()

        if not dry_run:
            # Replace the section with the include directive
            new_section = [
                section['comment'] + '\n',
                section['include'] + '\n'
            ]
            lines[start:end] = new_section

    if not dry_run:
        # Write the modified file
        with open(bank02_path, 'w') as f:
            f.writelines(lines)

        print("[SUCCESS] Integration complete!")
        print(f"[INFO] Modified: {bank02_path}")
        print()
        print("Next steps:")
        print("  1. Verify converted data files exist:")
        print("     - data/converted/enemies/enemies_stats.asm")
        print("     - data/converted/enemies/enemies_level.asm")
        print("     - data/converted/attacks/attacks_data.asm")
        print("  2. Test the build:")
        print("     pwsh -File build.ps1")
        print("  3. Verify ROM builds correctly")
    else:
        print("[INFO] Dry run complete - no changes made")
        print()
        print("To apply these changes, run:")
        print("  python tools/integrate_battle_data.py --apply")

    return True

def main():
    """Main entry point."""
    import sys

    dry_run = '--apply' not in sys.argv

    if dry_run:
        print("[INFO] Running in DRY RUN mode")
        print("[INFO] Use --apply to actually modify files")
        print()

    integrate_battle_data(dry_run=dry_run)

if __name__ == '__main__':
    main()
