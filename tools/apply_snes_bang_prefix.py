#!/usr/bin/env python3
"""
Apply ! prefix to all SNES_ register labels.
Converts old-style "SNES_REGISTER" to new-style "!SNES_REGISTER".
"""

import re
from pathlib import Path

# Base directory
BASE_DIR = Path(__file__).parent.parent
ASM_DIR = BASE_DIR / 'src' / 'asm'

def convert_snes_labels(file_path):
    """Convert SNES_ labels to !SNES_ format."""
    content = file_path.read_text(encoding='utf-8')
    original = content
    
    # Pattern: match .w/.W/.b/.B followed by space and SNES_REGISTER
    # Handles both absolute (.W) and direct page (.B) addressing
    # Don't match if already has ! prefix
    pattern = r'(\.\w)\s+SNES_([A-Z0-9_]+)'
    replacement = r'\1 !SNES_\2'
    
    content = re.sub(pattern, replacement, content)
    
    if content != original:
        # Count replacements
        count = len(re.findall(pattern, original))
        return content, count
    
    return None, 0

def main():
    print("Converting old-style SNES_ labels to !SNES_ format...\n")
    
    total_replacements = 0
    modified_files = []
    
    # Process all .asm files
    for asm_file in ASM_DIR.rglob('*.asm'):
        new_content, count = convert_snes_labels(asm_file)
        
        if new_content:
            asm_file.write_text(new_content, encoding='utf-8')
            print(f"{asm_file.name}: {count} replacements")
            total_replacements += count
            modified_files.append(asm_file.name)
    
    print(f"\n✓ TOTAL: {total_replacements} old SNES_ labels converted to !SNES_ across {len(modified_files)} files")
    
    if modified_files:
        print(f"\nModified files: {', '.join(modified_files[:10])}")
        if len(modified_files) > 10:
            print(f"... and {len(modified_files) - 10} more")

if __name__ == '__main__':
    main()
