import json

rom = open('roms/Final Fantasy - Mystic Quest (U) (V1.1).sfc', 'rb').read()
data = json.load(open('data/map_tilemaps.json'))

errors = 0
for mt in data['metatiles']['metatiles'][:20]:
	offset = 0x068000 + (mt['id'] * 4)
	rom_bytes = rom[offset:offset+4]
	json_bytes = [
		mt['tiles']['top_left'],
		mt['tiles']['top_right'],
		mt['tiles']['bottom_left'],
		mt['tiles']['bottom_right']
	]
	match = list(rom_bytes) == json_bytes
	
	if not match:
		print(f"Tile ${mt['id']:02X}: ROM={rom_bytes.hex().upper()} JSON={' '.join(f'{x:02X}' for x in json_bytes)} FAIL")
		errors += 1

if errors == 0:
	print("✓ All 20 tiles verified - extraction is correct!")
else:
	print(f"✗ {errors}/20 tiles failed verification")
