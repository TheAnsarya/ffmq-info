#!/usr/bin/env python3
"""
ASM Case Normalization Script

Converts all hexadecimal values and assembly instructions to lowercase
to maintain consistent code formatting across all bank files.

Usage:
    python tools/normalize_case.py [--dry-run] [--bank XX]

Options:
    --dry-run    Show what would be changed without modifying files
    --bank XX    Process only a specific bank (e.g., --bank 00)
"""

import re
import sys
import glob
from pathlib import Path
from typing import List, Tuple

# 65816 instruction mnemonics (complete set)
INSTRUCTIONS = [
    'adc', 'and', 'asl', 'bcc', 'bcs', 'beq', 'bit', 'bmi', 'bne', 'bpl',
    'bra', 'brk', 'brl', 'bvc', 'bvs', 'clc', 'cld', 'cli', 'clv', 'cmp',
    'cop', 'cpx', 'cpy', 'dec', 'dex', 'dey', 'eor', 'inc', 'inx', 'iny',
    'jml', 'jmp', 'jsl', 'jsr', 'lda', 'ldx', 'ldy', 'lsr', 'mvn', 'mvp',
    'nop', 'ora', 'pea', 'pei', 'per', 'pha', 'phb', 'phd', 'phk', 'php',
    'phx', 'phy', 'pla', 'plb', 'pld', 'plp', 'plx', 'ply', 'rep', 'rol',
    'ror', 'rti', 'rtl', 'rts', 'sbc', 'sec', 'sed', 'sei', 'sep', 'sta',
    'stp', 'stx', 'sty', 'stz', 'tax', 'tay', 'tcd', 'tcs', 'tdc', 'trb',
    'tsb', 'tsc', 'tsx', 'txa', 'txs', 'txy', 'tya', 'tyx', 'wai', 'wdm',
    'xba', 'xce'
]


def normalize_hex(content: str) -> Tuple[str, int]:
    """Convert all hex values to lowercase: $FF -> $ff"""
    count = 0

    def replace_hex(match):
        nonlocal count
        count += 1
        return f'${match.group(1).lower()}'

    # Match $XX or $XXXX hex values
    content = re.sub(r'\$([0-9A-Fa-f]+)', replace_hex, content)
    return content, count


def normalize_instructions(content: str) -> Tuple[str, int]:
    """Convert all instruction mnemonics to lowercase"""
    count = 0

    for inst in INSTRUCTIONS:
        # Match instruction at start of code line (after whitespace)
        # Don't match if it's part of a label or comment
        pattern = rf'(?<=\s){inst.upper()}(?=[\s\.])'

        def replace_inst(match):
            nonlocal count
            count += 1
            return inst

        content = re.sub(pattern, replace_inst, content, flags=re.IGNORECASE)

    return content, count


def normalize_addressing_modes(content: str) -> Tuple[str, int]:
    """Convert addressing mode suffixes to lowercase: .B -> .b, .W -> .w, .L -> .l"""
    count = 0

    def replace_mode(match):
        nonlocal count
        count += 1
        return f'.{match.group(1).lower()}'

    # Match .B, .W, .L after instructions
    content = re.sub(r'\.([BWL])\b', replace_mode, content)
    return content, count


def process_file(filepath: Path, dry_run: bool = False) -> dict:
    """Process a single ASM file"""
    print(f"Processing {filepath.name}...")

    with open(filepath, 'r', encoding='utf-8') as f:
        original_content = f.read()

    content = original_content
    stats = {
        'hex': 0,
        'instructions': 0,
        'addressing_modes': 0
    }

    # Apply transformations
    content, stats['hex'] = normalize_hex(content)
    content, stats['instructions'] = normalize_instructions(content)
    content, stats['addressing_modes'] = normalize_addressing_modes(content)

    total_changes = sum(stats.values())

    if total_changes > 0:
        if not dry_run:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"  [OK] Modified: {total_changes} changes")
        else:
            print(f"  [DRY RUN] Would modify: {total_changes} changes")

        print(f"     - Hex values: {stats['hex']}")
        print(f"     - Instructions: {stats['instructions']}")
        print(f"     - Addressing modes: {stats['addressing_modes']}")
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
            print(f"Γ¥î Error: Bank {specific_bank} not found")
            return 1
    else:
        files = sorted(Path('.').glob('src/asm/bank_*_documented.asm'))

    if not files:
        print("Γ¥î Error: No ASM files found")
        return 1

    print(f"{'=' * 60}")
    print(f"ASM Case Normalization")
    print(f"{'=' * 60}")
    print(f"Mode: {'DRY RUN' if dry_run else 'LIVE'}")
    print(f"Files: {len(files)}")
    print(f"{'=' * 60}\n")

    total_stats = {
        'hex': 0,
        'instructions': 0,
        'addressing_modes': 0
    }

    for filepath in files:
        stats = process_file(filepath, dry_run)
        for key in total_stats:
            total_stats[key] += stats[key]

    print(f"\n{'=' * 60}")
    print(f"Summary")
    print(f"{'=' * 60}")
    print(f"Total hex values normalized: {total_stats['hex']}")
    print(f"Total instructions normalized: {total_stats['instructions']}")
    print(f"Total addressing modes normalized: {total_stats['addressing_modes']}")
    print(f"Total changes: {sum(total_stats.values())}")

    if dry_run:
        print(f"\n≡ƒÆí Run without --dry-run to apply changes")
    else:
        print(f"\nΓ£à All changes applied successfully!")

    return 0


if __name__ == '__main__':
    sys.exit(main())
