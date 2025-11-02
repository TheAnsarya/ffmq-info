#!/usr/bin/env python3
"""Validate and display attack data samples."""

import json
from pathlib import Path

JSON_FILE = Path("data/extracted/attacks/attacks.json")

def main():
    with open(JSON_FILE) as f:
        data = json.load(f)
    
    attacks = data['attacks']
    
    print("Sample attacks at different indices:")
    print(f"{'ID':>3} | {'Unk1':>4} | {'Unk2':>4} | {'Power':>5} | {'Type':>4} | {'Sound':>5} | {'Unk3':>4} | {'Anim':>4}")
    print("-" * 75)
    
    # Sample different attacks
    indices = [0, 10, 20, 50, 100, 150, 168]
    for i in indices:
        a = attacks[i]
        print(f"{a['id']:>3} | {a['unknown1']:>4} | {a['unknown2']:>4} | {a['power']:>5} | "
              f"{a['attack_type']:>4} | {a['attack_sound']:>5} | {a['unknown3']:>4} | "
              f"{a['attack_target_animation']:>4}")
    
    print(f"\nTotal attacks: {len(attacks)}")

if __name__ == "__main__":
    main()
