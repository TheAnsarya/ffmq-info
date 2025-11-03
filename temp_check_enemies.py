import json

with open('data/extracted/enemies/enemies.json') as f:
    data = json.load(f)

print('Enemies with resistances/weaknesses:\n')
for e in data['enemies']:
    if e['resistances'] != 0 or e['weaknesses'] != 0:
        resist_str = ', '.join(e['resistances_decoded']) if e['resistances_decoded'] else 'None'
        weak_str = ', '.join(e['weaknesses_decoded']) if e['weaknesses_decoded'] else 'None'
        print(f"{e['name']:25s} R: 0x{e['resistances']:04X} ({resist_str})")
        print(f"{'':25s} W: 0x{e['weaknesses']:04X} ({weak_str})")
        print()
