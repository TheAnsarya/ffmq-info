"""Check ROM header difference"""
with open('roms/Final Fantasy - Mystic Quest (U) (V1.1).sfc', 'rb') as f:
	f.seek(0x7FC0)
	original = f.read(64)

with open('build/ffmq-rebuilt.sfc', 'rb') as f:
	f.seek(0x7FC0)
	rebuilt = f.read(64)

print('Original ROM Header at $007FC0:')
for i in range(0, len(original), 16):
	chunk = original[i:i+16]
	hex_str = ' '.join(f'{b:02X}' for b in chunk)
	ascii_str = ''.join(chr(b) if 32 <= b < 127 else '.' for b in chunk)
	print(f'  {0x7FC0+i:06X}  {hex_str:<48} {ascii_str}')

print('\nRebuilt ROM Header at $007FC0:')
for i in range(0, len(rebuilt), 16):
	chunk = rebuilt[i:i+16]
	hex_str = ' '.join(f'{b:02X}' for b in chunk)
	ascii_str = ''.join(chr(b) if 32 <= b < 127 else '.' for b in chunk)
	print(f'  {0x7FC0+i:06X}  {hex_str:<48} {ascii_str}')

print('\nDifferences:')
for i in range(len(original)):
	if original[i] != rebuilt[i]:
		print(f'  ${0x7FC0+i:06X}: {original[i]:02X} -> {rebuilt[i]:02X}  ({chr(original[i]) if 32 <= original[i] < 127 else "."} -> {chr(rebuilt[i]) if 32 <= rebuilt[i] < 127 else "."})')
