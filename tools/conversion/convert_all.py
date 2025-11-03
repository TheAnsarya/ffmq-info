#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Master Data Conversion Script
==============================

Runs all JSON-to-ASM converters in the correct order.

Usage:
    python tools/conversion/convert_all.py

This script:
  1. Converts enemy stats (enemies_stats.asm, enemies_level.asm)
  2. Converts attack data (attacks_data.asm)
  3. Converts enemy-attack links (enemy_attack_links.asm)

Output:
    data/converted/enemies/*.asm
    data/converted/attacks/*.asm

Author: FFMQ Disassembly Project
Date: 2025-11-02
"""

import sys
import io
import subprocess
from pathlib import Path

# Fix Windows console encoding issues
if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')


def run_converter(script_name: str) -> int:
    """
    Run a conversion script.

    Args:
        script_name: Name of the Python script to run

    Returns:
        Exit code (0 = success)
    """
    script_path = Path(__file__).parent / script_name

    print(f"\n{'='*80}")
    print(f"Running: {script_name}")
    print('='*80)

    result = subprocess.run([sys.executable, str(script_path)])

    if result.returncode != 0:
        print(f"\n[ERROR] {script_name} failed with exit code {result.returncode}")
        return result.returncode

    return 0


def main():
    """Run all conversion scripts."""
    print("="*80)
    print("Master Data Conversion Script")
    print("="*80)
    print()
    print("This script will convert all extracted JSON data to ASM format:")
    print("  • Enemy stats and levels")
    print("  • Attack data")
    print("  • Enemy-attack links")
    print()

    # List of converters to run
    converters = [
        "convert_enemies.py",
        "convert_attacks.py",
        "convert_enemy_attack_links.py",
    ]

    # Run each converter
    for converter in converters:
        result = run_converter(converter)
        if result != 0:
            print()
            print("="*80)
            print("[FAILED] Conversion Failed")
            print("="*80)
            return result

    # Success!
    print()
    print("="*80)
    print("[SUCCESS] All Conversions Complete!")
    print("="*80)
    print()
    print("Generated ASM files:")
    print("  - data/converted/enemies/enemies_stats.asm")
    print("  - data/converted/enemies/enemies_level.asm")
    print("  - data/converted/attacks/attacks_data.asm")
    print("  - data/converted/attacks/enemy_attack_links.asm")
    print()
    print("Next steps:")
    print("  1. Build ROM with: make build-from-data")
    print("  2. Verify round-trip: python tools/verify_data_roundtrip.py")
    print()

    return 0


if __name__ == '__main__':
    sys.exit(main())
