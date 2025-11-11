#!/usr/bin/env python3
"""Fix Windows encoding issues in conversion scripts."""

import re
from pathlib import Path

def fix_script(script_path):
	"""Remove emojis and fix encoding issues in a Python script."""
	with open(script_path, 'r', encoding='utf-8') as f:
		content = f.read()

	# Add encoding declaration if not present
	if '# -*- coding: utf-8 -*-' not in content:
		content = content.replace(
			'#!/usr/bin/env python3\n',
			'#!/usr/bin/env python3\n# -*- coding: utf-8 -*-\n'
		)

	# Add Windows console fix if not present
	if 'if sys.platform ==' not in content:
		content = content.replace(
			'import sys\n',
			'''import sys
import io

# Fix Windows console encoding issues
if sys.platform == 'win32':
	sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
	sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')
'''
		)

	# Replace emojis with text
	replacements = {
		'📂': '[INFO]',
		'🔨': '[INFO]',
		'✓': '[OK]',
		'❌': '[ERROR]',
		'✨': '[SUCCESS]',
		'•': '-',
		'📁': '[INFO]',
		'📄': '[INFO]',
	}

	for emoji, text in replacements.items():
		content = content.replace(emoji, text)

	with open(script_path, 'w', encoding='utf-8') as f:
		f.write(content)

	print(f"Fixed: {script_path}")

# Fix all conversion scripts
scripts = [
	Path('tools/conversion/convert_attacks.py'),
	Path('tools/conversion/convert_enemy_attack_links.py'),
]

for script in scripts:
	if script.exists():
		fix_script(script)

print("Done!")
