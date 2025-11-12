#!/usr/bin/env python3
"""
Comprehensive CODE_* label renaming tool.
Analyzes ALL CODE_* labels across entire codebase and renames them with meaningful names.
"""

import re
from pathlib import Path
from collections import defaultdict
from typing import Dict, List, Tuple

def read_file(filepath: Path) -> List[str]:
	"""Read file into lines."""
	with open(filepath, 'r', encoding='utf-8') as f:
		return f.readlines()

def write_file(filepath: Path, lines: List[str]):
	"""Write lines to file."""
	with open(filepath, 'w', encoding='utf-8') as f:
		f.writelines(lines)

def extract_comment_name(comment: str) -> str:
	"""Extract meaningful name from comment."""
	# Remove label reference itself
	comment = re.sub(r'CODE_[0-9A-Fa-f]+:?\s*-?\s*', '', comment)
	comment = comment.strip().strip(':').strip('-').strip()
	
	if not comment or len(comment) < 3:
		return None
	
	# Convert to PascalCase
	words = re.findall(r'[a-zA-Z0-9]+', comment)
	if not words:
		return None
	
	return ''.join(word.capitalize() for word in words[:6])  # Limit to 6 words

def analyze_instructions(instructions: List[str]) -> Tuple[str, str]:
	"""Analyze instructions to suggest a name and reason."""
	if not instructions:
		return 'EmptyRoutine', 'No instructions'
	
	instr_text = ' '.join(instructions).upper()
	first = instructions[0].upper().strip()
	
	# Immediate returns
	if first.startswith('RTS') or first.startswith('RTL'):
		return 'Return', 'Immediate return'
	
	# Pattern matching for common routines
	patterns = [
		# Graphics/PPU/DMA
		(r'\$2100|\$2101', 'SetupScreen', 'Screen register setup'),
		(r'\$2115|\$2116|\$2117', 'SetupVRAM', 'VRAM address setup'),
		(r'\$2118|\$2119', 'WriteVRAM', 'VRAM write'),
		(r'\$211[ABC]', 'SetupMode7', 'Mode 7 setup'),
		(r'\$212[0-5]', 'SetupLayers', 'Layer configuration'),
		(r'\$2126|\$2127|\$2128', 'SetupWindow', 'Window setup'),
		(r'\$212[AB]', 'SetupMainSub', 'Main/sub screen setup'),
		(r'\$212[CDE]', 'SetupColorMath', 'Color math setup'),
		(r'\$213', 'ReadPPU', 'PPU read'),
		(r'\$2180', 'AccessWRAM', 'WRAM access'),
		(r'\$21[0-9A-F][0-9A-F].*\$21[0-9A-F][0-9A-F]', 'ConfigurePPU', 'Multiple PPU registers'),
		(r'\$43[0-7][0-9A-F]', 'SetupDMA', 'DMA configuration'),
		(r'\$420B', 'TriggerDMA', 'DMA trigger'),
		(r'\$420C', 'TriggerHDMA', 'HDMA trigger'),
		
		# Input
		(r'\$4016|\$4017|\$4218|\$4219', 'ReadInput', 'Controller input'),
		(r'\$421[89A-F]', 'ReadJoypad', 'Joypad read'),
		
		# Memory operations
		(r'LDA.*STA.*LDA.*STA', 'CopyMultiple', 'Multiple copy operations'),
		(r'LDA.*STA', 'CopyData', 'Copy operation'),
		(r'STZ.*STZ.*STZ', 'ClearMultiple', 'Clear multiple bytes'),
		(r'STZ', 'ClearMemory', 'Clear memory'),
		(r'MVN|MVP', 'BlockTransfer', 'Block move'),
		
		# Arithmetic
		(r'CLC.*ADC|ADC', 'Add', 'Addition'),
		(r'SEC.*SBC|SBC', 'Subtract', 'Subtraction'),
		(r'INC.*INC', 'IncrementMultiple', 'Multiple increments'),
		(r'DEC.*DEC', 'DecrementMultiple', 'Multiple decrements'),
		(r'ASL.*ASL|ASL.*ROL', 'ShiftLeft', 'Left shift'),
		(r'LSR.*LSR|LSR.*ROR', 'ShiftRight', 'Right shift'),
		(r'MUL', 'Multiply', 'Multiplication'),
		
		# Bit operations
		(r'AND.*#\$[0-9A-F]+', 'MaskBits', 'Bit masking'),
		(r'ORA.*#\$[0-9A-F]+', 'SetBits', 'Set bits'),
		(r'EOR.*#\$[0-9A-F]+', 'ToggleBits', 'Toggle bits'),
		(r'BIT', 'TestBits', 'Bit test'),
		
		# Comparisons/branching
		(r'CMP.*BEQ', 'CheckEqual', 'Compare equal'),
		(r'CMP.*BNE', 'CheckNotEqual', 'Compare not equal'),
		(r'CMP.*BCS', 'CheckGreaterOrEqual', 'Compare >='),
		(r'CMP.*BCC', 'CheckLessThan', 'Compare <'),
		
		# Loops
		(r'DEX.*BNE.*BRA', 'LoopX', 'Loop with X'),
		(r'DEY.*BNE.*BRA', 'LoopY', 'Loop with Y'),
		(r'DEC.*BNE', 'CountdownLoop', 'Countdown loop'),
		(r'INC.*CMP.*BNE', 'CountUpLoop', 'Count-up loop'),
		
		# Stack
		(r'PHA.*PHA.*PHA', 'PushRegisters', 'Push multiple registers'),
		(r'PLA.*PLA.*PLA', 'PopRegisters', 'Pop multiple registers'),
		(r'PHP.*PLP', 'PreserveFlags', 'Save/restore flags'),
		
		# Function calls
		(r'JSR.*JSR.*JSR', 'CallMultiple', 'Multiple subroutine calls'),
		(r'JSL.*JSL', 'CallLongMultiple', 'Multiple long calls'),
		
		# Wait/delays
		(r'WAI', 'WaitInterrupt', 'Wait for interrupt'),
		(r'NOP.*NOP.*NOP', 'Delay', 'Delay with NOPs'),
		(r'WDM', 'DebugBreak', 'Debug break'),
	]
	
	for pattern, name, reason in patterns:
		if re.search(pattern, instr_text):
			return name, reason
	
	# Fallback based on length
	if len(instructions) == 1:
		return 'SimpleOp', 'Single instruction'
	elif len(instructions) <= 3:
		return 'ShortRoutine', 'Short routine'
	else:
		return 'Subroutine', 'Subroutine'

def find_label_definition(lines: List[str], label: str) -> int:
	"""Find line number where label is defined."""
	pattern = re.compile(rf'^{re.escape(label)}:', re.IGNORECASE)
	for i, line in enumerate(lines):
		if pattern.match(line):
			return i
	return -1

def suggest_name_for_label(lines: List[str], label: str, def_line: int) -> Tuple[str, str]:
	"""Suggest a meaningful name for a label based on context."""
	# Look for comment on same line
	if def_line >= 0:
		same_line = lines[def_line]
		if ';' in same_line:
			comment = same_line.split(';', 1)[1].strip()
			name = extract_comment_name(comment)
			if name:
				return name, f'From same-line comment: {comment}'
	
	# Look for comment above
	if def_line > 0:
		for i in range(max(0, def_line - 5), def_line):
			line = lines[i].strip()
			if line.startswith(';') and not line.startswith(';---') and not line.startswith(';==='):
				comment = line.lstrip(';').strip()
				name = extract_comment_name(comment)
				if name:
					return name, f'From preceding comment: {comment}'
	
	# Analyze instructions following the label
	instructions = []
	if def_line >= 0:
		for i in range(def_line + 1, min(len(lines), def_line + 15)):
			line = lines[i].strip()
			if not line or line.startswith(';'):
				continue
			if ':' in line and not line.startswith('.'):
				break  # Hit next label
			instructions.append(line.split(';')[0].strip())
			if len(instructions) >= 10:
				break
	
	if instructions:
		name, reason = analyze_instructions(instructions)
		return name, reason
	
	return 'UnknownRoutine', 'No context available'

def main():
	src_dir = Path(__file__).parent.parent.parent / 'src' / 'asm'
	
	print("="*80)
	print("COMPREHENSIVE CODE_* LABEL RENAMING")
	print("="*80)
	
	# Step 1: Find all CODE_* labels across all files
	print("\n[1/5] Finding all CODE_* labels...")
	
	label_definitions = {}  # label -> (file, line_num)
	label_references = defaultdict(list)  # label -> [(file, line_num), ...]
	
	asm_files = sorted(src_dir.rglob('*.asm'))
	
	for asm_file in asm_files:
		try:
			lines = read_file(asm_file)
			for i, line in enumerate(lines):
				# Check for label definition
				def_match = re.match(r'^(CODE_[0-9A-Fa-f]+):', line, re.IGNORECASE)
				if def_match:
					label = def_match.group(1).upper()
					if label not in label_definitions:
						label_definitions[label] = (asm_file, i)
				
				# Check for label reference (in any context)
				for ref_match in re.finditer(r'\b(CODE_[0-9A-Fa-f]+)\b', line, re.IGNORECASE):
					ref_label = ref_match.group(1).upper()
					label_references[ref_label].append((asm_file, i))
		except Exception as e:
			print(f"  Error reading {asm_file.name}: {e}")
	
	print(f"  Found {len(label_definitions)} label definitions")
	print(f"  Found {len(label_references)} labels referenced")
	print(f"  Total references: {sum(len(refs) for refs in label_references.values())}")
	
	# Step 2: Analyze each label and suggest name
	print("\n[2/5] Analyzing labels and suggesting names...")
	
	rename_map = {}  # old_label -> (new_label, reason, confidence)
	
	for label in sorted(label_definitions.keys()):
		filepath, line_num = label_definitions[label]
		lines = read_file(filepath)
		
		new_name, reason = suggest_name_for_label(lines, label, line_num)
		
		# Make unique if name collision
		base_name = new_name
		counter = 2
		while new_name in rename_map.values():
			new_name = f"{base_name}{counter}"
			counter += 1
		
		# Determine confidence
		if 'comment' in reason.lower():
			confidence = 'high'
		elif any(word in reason for word in ['PPU', 'DMA', 'VRAM', 'Screen', 'Input']):
			confidence = 'medium'
		else:
			confidence = 'low'
		
		rename_map[label] = (new_name, reason, confidence)
	
	# Step 3: Display suggested renames
	print("\n[3/5] Suggested renames:")
	
	high = {k: v for k, v in rename_map.items() if v[2] == 'high'}
	medium = {k: v for k, v in rename_map.items() if v[2] == 'medium'}
	low = {k: v for k, v in rename_map.items() if v[2] == 'low'}
	
	print(f"\n  HIGH confidence: {len(high)}")
	for label, (new_name, reason, _) in sorted(high.items())[:10]:
		print(f"    {label} -> {new_name}")
		print(f"      {reason}")
	if len(high) > 10:
		print(f"    ... and {len(high) - 10} more")
	
	print(f"\n  MEDIUM confidence: {len(medium)}")
	for label, (new_name, reason, _) in sorted(medium.items())[:10]:
		print(f"    {label} -> {new_name}")
		print(f"      {reason}")
	if len(medium) > 10:
		print(f"    ... and {len(medium) - 10} more")
	
	print(f"\n  LOW confidence: {len(low)}")
	for label, (new_name, reason, _) in sorted(low.items())[:10]:
		print(f"    {label} -> {new_name}")
		print(f"      {reason}")
	if len(low) > 10:
		print(f"    ... and {len(low) - 10} more")
	
	# Step 4: Apply renames
	print("\n[4/5] Applying renames...")
	
	files_modified = 0
	total_replacements = 0
	
	for asm_file in asm_files:
		try:
			lines = read_file(asm_file)
			modified = False
			
			for i, line in enumerate(lines):
				original_line = line
				
				# Replace each CODE_* label with its new name
				for old_label, (new_name, _, _) in rename_map.items():
					# Replace as whole word only
					pattern = re.compile(r'\b' + re.escape(old_label) + r'\b', re.IGNORECASE)
					line = pattern.sub(new_name, line)
				
				if line != original_line:
					lines[i] = line
					modified = True
					total_replacements += 1
			
			if modified:
				write_file(asm_file, lines)
				files_modified += 1
				print(f"  Modified: {asm_file.relative_to(src_dir)}")
		except Exception as e:
			print(f"  Error processing {asm_file.name}: {e}")
	
	print(f"\n  Modified {files_modified} files")
	print(f"  Total replacements: {total_replacements}")
	
	# Step 5: Save report
	print("\n[5/5] Saving report...")
	
	report_file = Path(__file__).parent.parent.parent / 'reports' / 'code_label_renames.txt'
	report_file.parent.mkdir(parents=True, exist_ok=True)
	
	with open(report_file, 'w', encoding='utf-8') as f:
		f.write("CODE_* LABEL COMPREHENSIVE RENAME REPORT\n")
		f.write("="*80 + "\n\n")
		f.write(f"Total labels renamed: {len(rename_map)}\n")
		f.write(f"Files modified: {files_modified}\n")
		f.write(f"Total replacements: {total_replacements}\n")
		f.write(f"High confidence: {len(high)}\n")
		f.write(f"Medium confidence: {len(medium)}\n")
		f.write(f"Low confidence: {len(low)}\n\n")
		
		for confidence_name, items in [('HIGH', high), ('MEDIUM', medium), ('LOW', low)]:
			f.write(f"\n{'='*80}\n")
			f.write(f"{confidence_name} CONFIDENCE RENAMES\n")
			f.write(f"{'='*80}\n\n")
			
			for label, (new_name, reason, _) in sorted(items.items()):
				filepath, line_num = label_definitions.get(label, (None, -1))
				refs = len(label_references.get(label, []))
				
				f.write(f"{label} -> {new_name}\n")
				f.write(f"  Reason: {reason}\n")
				f.write(f"  References: {refs}\n")
				if filepath:
					f.write(f"  Defined in: {filepath.relative_to(src_dir)} (line {line_num + 1})\n")
				f.write("\n")
	
	print(f"  Report saved to: {report_file}")
	
	print("\n" + "="*80)
	print("RENAMING COMPLETE!")
	print("="*80)
	print(f"\n✓ Renamed {len(rename_map)} labels")
	print(f"✓ Modified {files_modified} files")
	print(f"✓ Made {total_replacements} replacements")
	print(f"\nNext: Review {report_file} and commit changes")

if __name__ == '__main__':
	main()
