#!/usr/bin/env python3
"""
Diztinguish to asar Assembly Converter
======================================
Converts Diztinguish disassembly format to proper asar syntax
Removes PC addresses, cleans up formatting
Preserves labels and data

Input format (Diztinguish):
	CODE_008000:
					   CLC                                  ;008000|18      |      ;
					   XCE                                  ;008001|FB      |      ;

Output format (asar):
CODE_008000:
	CLC
	XCE

Usage:
	python convert_diztinguish.py bank_00.asm > bank_00_clean.asm
"""

import sys
import re
from pathlib import Path

def convert_line(line: str) -> str:
	"""Convert a single line from Diztinguish format to asar format"""
	
	# Match label lines (no indentation)
	label_match = re.match(r'^(\s*)([A-Z_][A-Z0-9_]+):\s*$', line)
	if label_match:
		return label_match.group(2) + ':\n'
	
	# Match DATA lines
	data_match = re.match(r'^(\s*)DATA8_([0-9A-F]+):', line)
	if data_match:
		addr = data_match.group(2)
		return f'DATA_{addr}:\n'
	
	# Match CODE lines  
	code_match = re.match(r'^(\s*)CODE_([0-9A-F]+):', line)
	if code_match:
		addr = code_match.group(2)
		return f'CODE_{addr}:\n'
	
	# Match ORG directive
	org_match = re.match(r'^(\s*)ORG \$([0-9A-F]+)', line)
	if org_match:
		addr = org_match.group(2)
		return f'org ${addr}\n'
	
	# Match instruction lines (indented)
	# Format: "                       INSTRUCTION                      ;ADDRESS|BYTES|      ;"
	inst_match = re.match(r'^\s+([A-Z]+(?:\.[BWL])?)\s+(.+?)\s*;[0-9A-F]+\|', line)
	if inst_match:
		instruction = inst_match.group(1)
		operand = inst_match.group(2).strip()
		
		# Clean up operand (remove excessive spaces)
		operand = re.sub(r'\s+', ' ', operand)
		
		# Convert some common patterns
		# $XXXXXX → long address
		# #$XX → immediate
		# $XX → direct page or absolute
		# [$XX] → indirect
		
		return f'    {instruction} {operand}\n'
	
	# Match simple instructions with no operands
	inst_simple = re.match(r'^\s+([A-Z]+)\s*;[0-9A-F]+\|', line)
	if inst_simple:
		instruction = inst_simple.group(1)
		return f'    {instruction}\n'
	
	# Match db/dw directives
	db_match = re.match(r'^\s+db\s+(.+?)\s*;[0-9A-F]+\|', line)
	if db_match:
		data = db_match.group(1).strip()
		return f'    db {data}\n'
	
	dw_match = re.match(r'^\s+dw\s+(.+?)\s*;[0-9A-F]+\|', line)
	if dw_match:
		data = dw_match.group(1).strip()
		return f'    dw {data}\n'
	
	# Match comment lines
	comment_match = re.match(r'^\s*;(.+)$', line)
	if comment_match:
		comment = comment_match.group(1)
		return f'    ;{comment}\n'
	
	# Match blank lines
	if line.strip() == '':
		return '\n'
	
	# Unknown format - return as comment
	return f'    ; UNKNOWN FORMAT: {line.strip()}\n'

def convert_file(input_file: Path):
	"""Convert entire file"""
	
	print('; ==============================================================================')
	print(f'; Converted from Diztinguish: {input_file.name}')
	print('; ==============================================================================')
	print()
	
	with open(input_file, 'r', encoding='utf-8') as f:
		for line_num, line in enumerate(f, 1):
			try:
				converted = convert_line(line)
				print(converted, end='')
			except Exception as e:
				print(f'    ; ERROR LINE {line_num}: {e}', file=sys.stderr)
				print(f'    ; {line.strip()}', end='\n')

def main():
	if len(sys.argv) < 2:
		print('Usage: python convert_diztinguish.py <bank_file.asm>', file=sys.stderr)
		print('Example: python convert_diztinguish.py src/asm/banks/bank_00.asm > bank_00_clean.asm', file=sys.stderr)
		sys.exit(1)
	
	input_file = Path(sys.argv[1])
	if not input_file.exists():
		print(f'Error: File not found: {input_file}', file=sys.stderr)
		sys.exit(1)
	
	convert_file(input_file)

if __name__ == '__main__':
	main()
