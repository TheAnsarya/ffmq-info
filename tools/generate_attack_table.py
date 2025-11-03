"""
Generate wikitext attack table from attacks.json for DataCrystal documentation
"""
import json

# Read attacks.json
with open('data/extracted/attacks/attacks.json', 'r') as f:
    data = json.load(f)

attacks = data['attacks']

print("=== Generated Attack Table ===\n")
print("Based on extracted data from ROM $013C78 (Bank $02)\n")
print("{| class=\"wikitable sortable\"")
print("! ID !! Power !! Type !! Sound !! Animation !! Unknown1 !! Unknown2 !! Unknown3 !! ROM Offset")
print("|-")

# ROM base address
base_addr = 0x013C78

for idx, attack in enumerate(attacks):
    attack_id = f"${idx:02x}"
    power = attack['power']
    attack_type = f"${attack['attack_type']:02x}"
    attack_sound = f"${attack['attack_sound']:02x}"
    animation = f"${attack['attack_target_animation']:02x}"
    unknown1 = f"${attack['unknown1']:02x}"
    unknown2 = f"${attack['unknown2']:02x}"
    unknown3 = f"${attack['unknown3']:02x}"

    # Calculate ROM offset (7 bytes per entry)
    offset = base_addr + (idx * 7)
    rom_offset = f"${offset:06x}"

    print(f"| {attack_id} || {power} || {attack_type} || {attack_sound} || {animation} || {unknown1} || {unknown2} || {unknown3} || {rom_offset}")
    print("|-")

print("|}")
print(f"\nTotal: {len(attacks)} attack entries")
print("Each entry is 7 bytes")
