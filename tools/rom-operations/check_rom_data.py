import json

with open('data/extracted/enemies/enemies.json') as f:
    data = json.load(f)

brownie = data['enemies'][0]
print(f"Brownie HP in JSON: {brownie['hp']} (0x{brownie['hp']:04X})")
print(f"Expected bytes: {brownie['hp'] & 0xFF:02X} {(brownie['hp'] >> 8) & 0xFF:02X} (little-endian)")

# LoROM mapping: Bank $02 address $C275
# Bank $02 starts at PC $010000, SNES $02:$8000 = PC $010000
# So $02:$C275 = PC $010000 + ($C275 - $8000) = $010000 + $4275 = $014275
pc_offset = 0x014275

with open('build/ffmq-rebuilt.sfc', 'rb') as f:
    f.seek(pc_offset)
    data = f.read(14)
    print(f"\nFirst 14 bytes at PC offset 0x{pc_offset:06X} (SNES $02:$C275):")
    print(' '.join(f'{b:02X}' for b in data))

    hp_rom = data[0] | (data[1] << 8)
    print(f"\nHP from ROM: {hp_rom}")
