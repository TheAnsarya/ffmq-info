#!/usr/bin/env python3
"""Check hex bytes of dialog 0x59"""
import sys
from pathlib import Path
sys.path.insert(0, str(Path('tools/map-editor')))

from utils.dialog_database import DialogDatabase

rom_path = Path('roms/Final Fantasy - Mystic Quest (U) (V1.1).sfc')
db = DialogDatabase(rom_path)
db.extract_all_dialogs()

dialog = db.dialogs[0x59]
print(f'Dialog 0x59 first 80 bytes (hex):')
for i in range(0, min(80, len(dialog.raw_bytes)), 16):
	hex_bytes = dialog.raw_bytes[i:i+16]
	hex_str = ' '.join(f'{b:02X}' for b in hex_bytes)
	ascii_str = ''.join(chr(b) if 32 <= b < 127 else '.' for b in hex_bytes)
	print(f'{i:04X}: {hex_str:<48} {ascii_str}')

print(f'\nExpected: "For years Mac\'s been studying a Prophecy..."')
print(f'\nLet me decode first 20 bytes manually:')

# Character mappings
chars = {
	0x9F: 'F', 0xB5: 'b', 0xB8: 'e', 0xC2: 'o', 0xC5: 'r',
	0xC9: 'v', 0xB4: 'a', 0xC6: 's', 0xA6: 'M', 0xC7: 't',
	0xFF: ' ', 0xD1: "'",
}

for i, byte in enumerate(dialog.raw_bytes[:20]):
	if byte in chars:
		print(f'  [{i:02d}] 0x{byte:02X} = \'{chars[byte]}\'')
	elif 0x3D <= byte <= 0x7E:
		print(f'  [{i:02d}] 0x{byte:02X} = <DTE>')
	elif byte < 0x20:
		print(f'  [{i:02d}] 0x{byte:02X} = <CTRL>')
	else:
		print(f'  [{i:02d}] 0x{byte:02X} = ?')
