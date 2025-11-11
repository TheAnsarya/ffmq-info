#!/usr/bin/env python3
"""Generate Window Colors wikitext page with complete BGR555 color palette."""

output = """=Values - Window Colors=

{{Back|Final Fantasy: Mystic Quest/Values}}

This page documents the complete BGR555 color palette used for window customization in Final Fantasy: Mystic Quest.

==Overview==

The game uses the SNES BGR555 15-bit color format for window colors. Each color is represented by:
* '''5 bits''' for Red (0-31, mapped to 0-8 in table)
* '''5 bits''' for Green (0-31, mapped to 0-8 in table)
* '''5 bits''' for Blue (0-31, mapped to 0-8 in table)

The color value is split across two bytes:
* '''Byte $9c''': Lower 8 bits of the 15-bit color value
* '''Byte $9d''': Upper 7 bits of the 15-bit color value

==Color Format==

{| class="wikitable"
! Bit Pattern !! Description
|-
| 0bbbbbgg gggrrrrr || 15-bit BGR555 format
|-
| $9c: gggrrrrr || Lower byte (Green low 3 bits + Red 5 bits)
|-
| $9d: 0bbbbbgg || Upper byte (Blue 5 bits + Green high 2 bits)
|}

==Complete Color Palette==

This table contains all 729 possible colors in the BGR555 color space (9×9×9 grid).

{| class="wikitable"
! R !! G !! B !! Value !! $9c bits !! $9d bits !! Color
"""

# Generate 729 color entries (9x9x9)
for b in range(9):
	for g in range(9):
		for r in range(9):
			# Calculate 15-bit value
			r5 = r * 4  # Map 0-8 to 0-32 (use multiples of 4)
			g5 = g * 4
			b5 = b * 4

			# BGR555 format: 0bbbbbgggggrrrrr
			value = (b5 << 10) | (g5 << 5) | r5

			# Split into two bytes
			byte_9c = value & 0xFF
			byte_9d = (value >> 8) & 0x7F

			# Convert to RGB hex for CSS
			r8 = (r5 * 255) // 31
			g8 = (g5 * 255) // 31
			b8 = (b5 * 255) // 31
			hex_color = f'#{r8:02x}{g8:02x}{b8:02x}'

			# Determine text color (black or white) based on brightness
			brightness = (r8 + g8 + b8) // 3
			text_color = '#ffffff' if brightness < 128 else '#000000'

			# Format bits
			bits_9c = f'{byte_9c:08b}'
			bits_9d = f'{byte_9d:08b}'

			# Add row
			output += f"""
|-
| {r} || {g} || {b} || ${value:04x} || {bits_9c[:4]} {bits_9c[4:]} || {bits_9d[:4]} {bits_9d[4:]} || style="color: {text_color}; background-color: {hex_color};" | {hex_color}"""

output += """
|}

==Usage==

To set a window color:
# Find the desired RGB values in the table (R, G, B columns 0-8)
# Set byte $9c to the value in the "$9c bits" column
# Set byte $9d to the value in the "$9d bits" column

==Examples==

{| class="wikitable"
! Color !! R !! G !! B !! $9c !! $9d !! Hex
|-
| style="background-color: #000000; color: #ffffff;" | Black || 0 || 0 || 0 || $00 || $00 || #000000
|-
| style="background-color: #ffffff; color: #000000;" | White || 8 || 8 || 8 || $ff || $7f || #ffffff
|-
| style="background-color: #ff0000; color: #ffffff;" | Red || 8 || 0 || 0 || $20 || $00 || #ff0000
|-
| style="background-color: #00ff00; color: #000000;" | Green || 0 || 8 || 0 || $e0 || $03 || #00ff00
|-
| style="background-color: #0000ff; color: #ffffff;" | Blue || 0 || 0 || 8 || $00 || $7c || #0000ff
|-
| style="background-color: #ffff00; color: #000000;" | Yellow || 8 || 8 || 0 || $ff || $03 || #ffff00
|-
| style="background-color: #ff00ff; color: #ffffff;" | Magenta || 8 || 0 || 8 || $20 || $7c || #ff00ff
|-
| style="background-color: #00ffff; color: #000000;" | Cyan || 0 || 8 || 8 || $e0 || $7f || #00ffff
|}

==See Also==

* [[Final Fantasy: Mystic Quest/Values|Values]]
* [[Final Fantasy: Mystic Quest/ROM_map/Menus|Menus]] - Window system documentation
* [[Final Fantasy: Mystic Quest/ROM_map/Graphics|Graphics]] - Graphics formats

[[Category:Final Fantasy: Mystic Quest]]
"""

# Write output
with open(r'datacrystal\Values\Window_Colors.wikitext', 'w', encoding='utf-8') as f:
	f.write(output)

print(f'Created Window_Colors.wikitext with 729 color entries')
print(f'File size: {len(output)} bytes')
