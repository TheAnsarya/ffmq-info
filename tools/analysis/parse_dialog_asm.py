#!/usr/bin/env python3
"""
Parse `assets/text/dialog.asm` and extract control-code usage and contexts
This helps analyze dialog/event commands from the assembly source we generated.

Produces: reports/dialog_asm_analysis.md
"""
from pathlib import Path
import re
from collections import Counter, defaultdict

ASM_PATH = Path(__file__).parent.parent / 'assets' / 'text' / 'dialog.asm'
OUT_PATH = Path(__file__).parent.parent.parent / 'reports' / 'dialog_asm_analysis.md'

CONTROL_RANGES = list(range(0x00, 0x3D)) + list(range(0x80, 0x90))
DTE_RANGE = range(0x3D, 0x7F)

hex_byte_re = re.compile(r'\$([0-9A-Fa-f]{2})')
label_re = re.compile(r'^\s*;\s*(\d{4}):')


def parse_dialog_asm(asm_path: Path):
	if not asm_path.exists():
		raise FileNotFoundError(asm_path)

	with open(asm_path, 'r', encoding='utf-8') as f:
		lines = f.readlines()

	dialogs = {}
	current_label = None
	current_bytes = []
	for line in lines:
		m = label_re.match(line)
		if m:
			# New label comment (dialog id in comment)
			if current_label is not None:
				dialogs[current_label] = bytes(current_bytes)
				current_bytes = []
			current_label = int(m.group(1))
			continue

		if line.strip().startswith('db'):
			# extract hex bytes
			for hb in hex_byte_re.findall(line):
				current_bytes.append(int(hb, 16))

	# flush last
	if current_label is not None and current_label not in dialogs:
		dialogs[current_label] = bytes(current_bytes)

	return dialogs


def analyze_dialogs(dialogs):
	usage = Counter()
	contexts = defaultdict(list)

	for did, bts in sorted(dialogs.items()):
		for i, b in enumerate(bts):
			if b in CONTROL_RANGES:
				usage[b] += 1
				before = bts[max(0, i-4):i]
				after = bts[i+1:i+5]
				contexts[b].append({
					'dialog': did,
					'pos': i,
					'before': before.hex(),
					'after': after.hex()
				})

	return usage, contexts


def write_report(usage, contexts, out_path: Path):
	out_path.parent.mkdir(parents=True, exist_ok=True)
	with open(out_path, 'w', encoding='utf-8') as f:
		f.write('# Dialog ASM Analysis Report\n\n')
		f.write('This report analyzes control code usage found in `assets/text/dialog.asm`.\n\n')

		total = sum(usage.values())
		f.write(f'Total control-code instances found: {total}\n\n')

		f.write('## Top control codes by frequency\n\n')
		f.write('| Hex | Count | Example contexts |\n')
		f.write('|-----|------:|------------------|\n')
		for b, count in usage.most_common(30):
			ctxs = contexts[b][:3]
			examples = []
			for c in ctxs:
				examples.append(f"dlg {c['dialog']} pos {c['pos']} (..{c['before']} [{b:02X}] {c['after']}..)")
			f.write(f'| 0x{b:02X} | {count} | {'; '.join(examples)} |\n')

		f.write('\n## Suggested mappings (based on patterns)\n\n')
		f.write('- 0x00 = [END] (terminator)\n')
		f.write('- 0x01 = {newline} (line break)\n')
		f.write('- 0x02 = [WAIT] (wait for button)\n')
		f.write('- 0x03 = [ASTERISK] or special marker\n')
		f.write('- 0x23 = [CLEAR] (clear box)\n')
		f.write('- 0x30 = [PARA] (paragraph/line break)\n')

		f.write('\n## Next steps\n\n')
		f.write('- Cross-check these results with `tools/map-editor/dialog_database.py` and `tools/map-editor/utils/dialog_text.py`.\n')
		f.write('- Use the data to prioritize reverse-engineering of top-used parameterized codes (0x10-0x3B).\n')

	print(f'Report written to {out_path}')


if __name__ == '__main__':
	dialogs = parse_dialog_asm(ASM_PATH)
	usage, contexts = analyze_dialogs(dialogs)
	write_report(usage, contexts, OUT_PATH)
	print('Done')
