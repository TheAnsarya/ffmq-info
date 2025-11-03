#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Enemy Stats Viewer
==================

Quick command-line viewer for enemy stats.
Useful for checking enemy data without opening the GUI.

Usage:
    python tools/view_enemy.py Brownie
    python tools/view_enemy.py 0           # By ID
    python tools/view_enemy.py --list      # List all enemies
    python tools/view_enemy.py --search boss
"""

import sys
import io
import json
from pathlib import Path

# Fix Windows console encoding
if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

# Element names for bitfield decoding
ELEMENTS = [
    'Silence', 'Blind', 'Poison', 'Confusion',
    'Sleep', 'Paralysis', 'Stone', 'Doom',
    'Projectile', 'Bomb', 'Axe', 'Zombie',
    'Air', 'Fire', 'Water', 'Earth'
]

def decode_elements(bitfield):
    """Decode element bitfield to list of element names."""
    elements = []
    for i, name in enumerate(ELEMENTS):
        if bitfield & (1 << i):
            elements.append(name)
    return elements if elements else ['None']

def load_enemies():
    """Load enemy data from JSON."""
    json_path = Path("data/extracted/enemies/enemies.json")
    
    if not json_path.exists():
        print(f"[ERROR] Enemy data not found: {json_path}")
        print("        Run extraction first:")
        print("        python tools/extraction/extract_enemies.py roms/your-rom.sfc")
        return None
    
    with open(json_path, 'r') as f:
        data = json.load(f)
    
    return data['enemies']

def display_enemy(enemy, show_detailed=True):
    """Display enemy stats in a nice format."""
    print()
    print("=" * 80)
    print(f"Enemy #{enemy['id']:03d}: {enemy['name']}")
    print("=" * 80)
    print()
    
    # Basic Stats
    print("BASIC STATS:")
    print(f"  HP:              {enemy['hp']:5d}")
    print(f"  Attack:          {enemy['attack']:5d}")
    print(f"  Defense:         {enemy['defense']:5d}")
    print(f"  Speed:           {enemy['speed']:5d}")
    print(f"  Magic:           {enemy['magic']:5d}")
    print()
    
    # Advanced Stats
    if show_detailed:
        print("ADVANCED STATS:")
        print(f"  Magic Defense:   {enemy['magic_defense']:5d}")
        print(f"  Magic Evade:     {enemy['magic_evade']:5d}")
        print(f"  Accuracy:        {enemy['accuracy']:5d}")
        print(f"  Evade:           {enemy['evade']:5d}")
        print()
    
    # Level & Rewards
    print("LEVEL & REWARDS:")
    print(f"  Level:           {enemy['level']:5d}")
    print(f"  XP Multiplier:   {enemy['xp_mult']:5d}")
    print(f"  GP Multiplier:   {enemy['gp_mult']:5d}")
    print()
    
    # Resistances
    resistances = decode_elements(enemy['resistances'])
    print("RESISTANCES:")
    if len(resistances) <= 4:
        print(f"  {', '.join(resistances)}")
    else:
        # Multi-line for many resistances
        for i in range(0, len(resistances), 4):
            chunk = resistances[i:i+4]
            print(f"  {', '.join(chunk)}")
    print()
    
    # Weaknesses
    weaknesses = decode_elements(enemy['weaknesses'])
    print("WEAKNESSES:")
    if len(weaknesses) <= 4:
        print(f"  {', '.join(weaknesses)}")
    else:
        # Multi-line for many weaknesses
        for i in range(0, len(weaknesses), 4):
            chunk = weaknesses[i:i+4]
            print(f"  {', '.join(chunk)}")
    print()
    
    # Raw data (if detailed)
    if show_detailed:
        print("RAW DATA:")
        print(f"  Resistances:     0x{enemy['resistances']:04X}")
        print(f"  Weaknesses:      0x{enemy['weaknesses']:04X}")
        print()

def list_enemies(enemies, search=None):
    """List all enemies or search results."""
    if search:
        search = search.lower()
        filtered = [e for e in enemies if search in e['name'].lower()]
        
        if not filtered:
            print(f"[INFO] No enemies found matching '{search}'")
            return
        
        print(f"\nFound {len(filtered)} enemies matching '{search}':\n")
        enemies = filtered
    else:
        print(f"\nAll {len(enemies)} Enemies:\n")
    
    # Print in columns
    for i, enemy in enumerate(enemies):
        print(f"  {enemy['id']:3d}. {enemy['name']:25s}  HP: {enemy['hp']:5d}  Lv: {enemy['level']:3d}")
        
        if (i + 1) % 20 == 0 and i + 1 < len(enemies):
            input("\nPress Enter to continue...")
            print()

def main():
    """Main entry point."""
    import argparse
    
    parser = argparse.ArgumentParser(
        description='View enemy stats from the command line',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # View specific enemy by name
  python tools/view_enemy.py Brownie
  
  # View by ID
  python tools/view_enemy.py 0
  
  # List all enemies
  python tools/view_enemy.py --list
  
  # Search for enemies
  python tools/view_enemy.py --search dragon
  
  # Brief view (less detailed)
  python tools/view_enemy.py Brownie --brief
        """
    )
    
    parser.add_argument('enemy', nargs='?', help='Enemy name or ID')
    parser.add_argument('--list', '-l', action='store_true',
                       help='List all enemies')
    parser.add_argument('--search', '-s', type=str,
                       help='Search for enemies by name')
    parser.add_argument('--brief', '-b', action='store_true',
                       help='Show brief stats only')
    
    args = parser.parse_args()
    
    # Load enemy data
    enemies = load_enemies()
    if enemies is None:
        return 1
    
    # Handle commands
    if args.list:
        list_enemies(enemies)
        return 0
    
    if args.search:
        list_enemies(enemies, args.search)
        return 0
    
    if not args.enemy:
        parser.print_help()
        return 0
    
    # Find enemy
    enemy = None
    
    # Try by ID first
    try:
        enemy_id = int(args.enemy)
        if 0 <= enemy_id < len(enemies):
            enemy = enemies[enemy_id]
    except ValueError:
        # Search by name
        search = args.enemy.lower()
        for e in enemies:
            if e['name'].lower() == search:
                enemy = e
                break
        
        # Try partial match if exact match not found
        if not enemy:
            matches = [e for e in enemies if search in e['name'].lower()]
            if len(matches) == 1:
                enemy = matches[0]
            elif len(matches) > 1:
                print(f"\n[INFO] Multiple enemies match '{args.enemy}':")
                for e in matches:
                    print(f"  {e['id']:3d}. {e['name']}")
                print("\nPlease be more specific or use the enemy ID.")
                return 1
    
    if not enemy:
        print(f"[ERROR] Enemy not found: {args.enemy}")
        print("\nUse --list to see all enemies")
        print("Use --search to search by name")
        return 1
    
    # Display enemy
    display_enemy(enemy, show_detailed=not args.brief)
    
    return 0

if __name__ == '__main__':
    sys.exit(main())
