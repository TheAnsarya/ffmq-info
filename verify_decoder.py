#!/usr/bin/env python3
"""
Verify FFMQ DTE decoder is working correctly
"""

import sys
from pathlib import Path

# Add parent directories to path
sys.path.insert(0, str(Path(__file__).parent))
sys.path.insert(0, str(Path(__file__).parent / 'tools' / 'map-editor'))

from utils.dialog_database import DialogDatabase

def main():
    """Test various dialogs"""

    rom_path = Path("roms/Final Fantasy - Mystic Quest (U) (V1.1).sfc")

    if not rom_path.exists():
        print(f"ERROR: ROM not found at {rom_path}")
        return False

    print("=== FFMQ DTE Decoder Verification ===\n")

    # Load database and extract dialogs
    db = DialogDatabase(rom_path)
    db.extract_all_dialogs()

    print(f"Total dialogs extracted: {len(db.dialogs)}\n")

    # Test specific dialogs
    test_dialogs = [
        (0x16, "beautiful"),  # "s beautiful as ever!"
        (0x59, "Prophecy"),   # Contains "Prophecy"
        (0x21, "the"),        # Contains "the" (DTE)
    ]

    print("Testing known dialogs:\n")

    for dialog_id, expected_word in test_dialogs:
        if dialog_id not in db.dialogs:
            print(f"✗ Dialog 0x{dialog_id:02X} not found")
            continue

        dialog = db.dialogs[dialog_id]

        # Clean the text for checking
        text_clean = dialog.text.replace('[END]', '').replace('\n', ' ')
        text_clean = ''.join([c for c in text_clean if c not in '<>[]'])

        if expected_word.lower() in text_clean.lower():
            print(f"✓ Dialog 0x{dialog_id:02X}: Contains '{expected_word}'")
            print(f"  Text: {text_clean[:60]}...")
        else:
            print(f"✗ Dialog 0x{dialog_id:02X}: Missing '{expected_word}'")
            print(f"  Text: {text_clean[:60]}...")
        print()

    # Show some example dialogs with good readable text
    print("\nExample decoded dialogs:\n")

    for dialog_id in [0x21, 0x59, 0x3E]:
        if dialog_id in db.dialogs:
            dialog = db.dialogs[dialog_id]
            text_clean = dialog.text.replace('[END]', '').replace('\n', ' ')
            # Remove control codes for display
            import re
            text_clean = re.sub(r'<[0-9A-F]{2}>', '', text_clean)
            text_clean = re.sub(r'\[[A-Z:]+\]', '', text_clean)

            print(f"Dialog 0x{dialog_id:02X}:")
            print(f"  {text_clean[:100]}")
            print()

    return True

if __name__ == '__main__':
    success = main()
    sys.exit(0 if success else 1)
