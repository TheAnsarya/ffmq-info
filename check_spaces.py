#!/usr/bin/env python3
"""Check if trailing spaces are in complex.tbl"""

with open('complex.tbl', 'rb') as f:
	content = f.read().decode('utf-8')

lines = content.split('\n')

print("Checking lines with expected trailing spaces:")
check_lines = ['40', '41', '42', '45', '46', '48', '5F', '67']

for hex_code in check_lines:
	matching = [l for l in lines if l.startswith(f'{hex_code}=')]
	if matching:
		line = matching[0]
		parts = line.split('=', 1)
		if len(parts) == 2:
			value = parts[1]
			has_space = value.endswith(' ')
			print(f"  {hex_code}={value!r} - Has trailing space: {has_space}")
