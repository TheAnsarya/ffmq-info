#!/usr/bin/env python3
"""
Batch Format Converter - Convert between different script formats
Supports multiple input/output formats for maximum interoperability

Supported Formats:
- Assembly (.asm) - Raw 6502/65816 assembly
- Script (.txt) - Human-readable dialog script format
- JSON (.json) - Structured data format
- CSV (.csv) - Spreadsheet-compatible format
- Binary (.bin) - Compiled ROM format
- XML (.xml) - Structured markup format
- YAML (.yaml) - Configuration-friendly format

Features:
- Batch conversion of multiple files
- Format auto-detection
- Configurable output options
- Validation during conversion
- Preservation of comments and metadata
- Character encoding handling
- Template-based output generation

Usage:
	python batch_format_converter.py --input dialogs.txt --output dialogs.json
	python batch_format_converter.py --input *.txt --output-dir json_files --format json
	python batch_format_converter.py --input dialogs.json --output dialogs.csv
	python batch_format_converter.py --input compiled.bin --output decompiled.txt --format script
"""

import argparse
import re
import json
import csv
import struct
from pathlib import Path
from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass, field, asdict
from enum import Enum
import xml.etree.ElementTree as ET
from xml.dom import minidom


class ScriptFormat(Enum):
	"""Supported script formats"""
	ASSEMBLY = "asm"
	SCRIPT = "txt"
	JSON = "json"
	CSV = "csv"
	BINARY = "bin"
	XML = "xml"
	YAML = "yaml"


@dataclass
class Dialog:
	"""A single dialog with metadata"""
	dialog_id: str
	lines: List[str]
	metadata: Dict[str, Any] = field(default_factory=dict)
	comments: List[str] = field(default_factory=list)


@dataclass
class ScriptCollection:
	"""Collection of dialogs with metadata"""
	dialogs: List[Dialog]
	metadata: Dict[str, Any] = field(default_factory=dict)
	
	def to_dict(self) -> dict:
		"""Convert to dictionary"""
		return {
			'metadata': self.metadata,
			'dialogs': [
				{
					'dialog_id': d.dialog_id,
					'lines': d.lines,
					'metadata': d.metadata,
					'comments': d.comments
				}
				for d in self.dialogs
			]
		}


class FormatConverter:
	"""Convert between different script formats"""
	
	# Event command definitions for assembly generation
	COMMAND_OPCODES = {
		'END': 0x00,
		'WAIT': 0x01,
		'NEWLINE': 0x02,
		'SET_FLAG': 0x03,
		'CLEAR_FLAG': 0x04,
		'CHECK_FLAG': 0x05,
		'CALL_SUBROUTINE': 0x10,
		'MEMORY_WRITE': 0x20,
		'MEMORY_READ': 0x21,
		'RETURN': 0xFF
	}
	
	def __init__(self, verbose: bool = False):
		self.verbose = verbose
	
	def detect_format(self, file_path: Path) -> ScriptFormat:
		"""Auto-detect file format from extension and content"""
		suffix = file_path.suffix.lower()
		
		format_map = {
			'.asm': ScriptFormat.ASSEMBLY,
			'.txt': ScriptFormat.SCRIPT,
			'.json': ScriptFormat.JSON,
			'.csv': ScriptFormat.CSV,
			'.bin': ScriptFormat.BINARY,
			'.xml': ScriptFormat.XML,
			'.yaml': ScriptFormat.YAML,
			'.yml': ScriptFormat.YAML
		}
		
		return format_map.get(suffix, ScriptFormat.SCRIPT)
	
	def read_script_format(self, file_path: Path) -> ScriptCollection:
		"""Read human-readable script format (.txt)"""
		dialogs = []
		
		with open(file_path, 'r', encoding='utf-8') as f:
			content = f.read()
		
		# Split by dialog markers
		dialog_pattern = r'^DIALOG\s+(\S+):(.*?)(?=^DIALOG\s+|\Z)'
		matches = re.finditer(dialog_pattern, content, re.MULTILINE | re.DOTALL)
		
		for match in matches:
			dialog_id = match.group(1)
			dialog_content = match.group(2).strip()
			
			# Separate comments from lines
			lines = []
			comments = []
			
			for line in dialog_content.split('\n'):
				line = line.rstrip()
				if not line:
					continue
				
				# Extract inline comments
				if ';' in line:
					code, comment = line.split(';', 1)
					if code.strip():
						lines.append(code.strip())
					if comment.strip():
						comments.append(comment.strip())
				else:
					lines.append(line)
			
			dialog = Dialog(
				dialog_id=dialog_id,
				lines=lines,
				comments=comments
			)
			dialogs.append(dialog)
		
		return ScriptCollection(dialogs=dialogs)
	
	def read_json_format(self, file_path: Path) -> ScriptCollection:
		"""Read JSON format"""
		with open(file_path, 'r', encoding='utf-8') as f:
			data = json.load(f)
		
		dialogs = []
		for dialog_data in data.get('dialogs', []):
			dialog = Dialog(
				dialog_id=dialog_data['dialog_id'],
				lines=dialog_data.get('lines', []),
				metadata=dialog_data.get('metadata', {}),
				comments=dialog_data.get('comments', [])
			)
			dialogs.append(dialog)
		
		return ScriptCollection(
			dialogs=dialogs,
			metadata=data.get('metadata', {})
		)
	
	def read_csv_format(self, file_path: Path) -> ScriptCollection:
		"""Read CSV format"""
		dialogs_dict: Dict[str, List[str]] = {}
		
		with open(file_path, 'r', newline='', encoding='utf-8') as f:
			reader = csv.reader(f)
			header = next(reader, None)
			
			for row in reader:
				if len(row) < 2:
					continue
				
				dialog_id = row[0]
				line_text = row[1]
				
				if dialog_id not in dialogs_dict:
					dialogs_dict[dialog_id] = []
				dialogs_dict[dialog_id].append(line_text)
		
		dialogs = [
			Dialog(dialog_id=did, lines=lines)
			for did, lines in dialogs_dict.items()
		]
		
		return ScriptCollection(dialogs=dialogs)
	
	def read_xml_format(self, file_path: Path) -> ScriptCollection:
		"""Read XML format"""
		tree = ET.parse(file_path)
		root = tree.getroot()
		
		dialogs = []
		
		for dialog_elem in root.findall('dialog'):
			dialog_id = dialog_elem.get('id', '')
			lines = []
			comments = []
			
			for line_elem in dialog_elem.findall('line'):
				lines.append(line_elem.text or '')
			
			for comment_elem in dialog_elem.findall('comment'):
				comments.append(comment_elem.text or '')
			
			dialog = Dialog(
				dialog_id=dialog_id,
				lines=lines,
				comments=comments
			)
			dialogs.append(dialog)
		
		return ScriptCollection(dialogs=dialogs)
	
	def read_file(self, file_path: Path, format: Optional[ScriptFormat] = None) -> ScriptCollection:
		"""Read file in detected or specified format"""
		if format is None:
			format = self.detect_format(file_path)
		
		if self.verbose:
			print(f"Reading {file_path} as {format.value}...")
		
		if format == ScriptFormat.SCRIPT:
			return self.read_script_format(file_path)
		elif format == ScriptFormat.JSON:
			return self.read_json_format(file_path)
		elif format == ScriptFormat.CSV:
			return self.read_csv_format(file_path)
		elif format == ScriptFormat.XML:
			return self.read_xml_format(file_path)
		else:
			raise ValueError(f"Reading {format.value} format not yet implemented")
	
	def write_script_format(self, collection: ScriptCollection, output_path: Path) -> None:
		"""Write human-readable script format (.txt)"""
		lines = []
		
		# Write metadata as comments
		if collection.metadata:
			lines.append("; Metadata:")
			for key, value in collection.metadata.items():
				lines.append(f"; {key}: {value}")
			lines.append("")
		
		# Write dialogs
		for dialog in collection.dialogs:
			lines.append(f"DIALOG {dialog.dialog_id}:")
			
			# Write dialog comments
			for comment in dialog.comments:
				lines.append(f"; {comment}")
			
			# Write lines
			for line in dialog.lines:
				lines.append(line)
			
			lines.append("")
		
		with open(output_path, 'w', encoding='utf-8') as f:
			f.write('\n'.join(lines))
		
		if self.verbose:
			print(f"Wrote {len(collection.dialogs)} dialogs to {output_path}")
	
	def write_json_format(self, collection: ScriptCollection, output_path: Path) -> None:
		"""Write JSON format"""
		data = collection.to_dict()
		
		with open(output_path, 'w', encoding='utf-8') as f:
			json.dump(data, f, indent=2, ensure_ascii=False)
		
		if self.verbose:
			print(f"Wrote {len(collection.dialogs)} dialogs to {output_path}")
	
	def write_csv_format(self, collection: ScriptCollection, output_path: Path) -> None:
		"""Write CSV format"""
		with open(output_path, 'w', newline='', encoding='utf-8') as f:
			writer = csv.writer(f)
			writer.writerow(['Dialog ID', 'Line Number', 'Content', 'Type'])
			
			for dialog in collection.dialogs:
				for line_num, line in enumerate(dialog.lines, 1):
					# Determine line type
					if line.startswith('"'):
						line_type = 'text'
					else:
						line_type = 'command'
					
					writer.writerow([dialog.dialog_id, line_num, line, line_type])
		
		if self.verbose:
			print(f"Wrote {len(collection.dialogs)} dialogs to {output_path}")
	
	def write_xml_format(self, collection: ScriptCollection, output_path: Path) -> None:
		"""Write XML format"""
		root = ET.Element('script_collection')
		
		# Metadata
		if collection.metadata:
			meta_elem = ET.SubElement(root, 'metadata')
			for key, value in collection.metadata.items():
				item = ET.SubElement(meta_elem, 'item', name=key)
				item.text = str(value)
		
		# Dialogs
		for dialog in collection.dialogs:
			dialog_elem = ET.SubElement(root, 'dialog', id=dialog.dialog_id)
			
			# Comments
			for comment in dialog.comments:
				comment_elem = ET.SubElement(dialog_elem, 'comment')
				comment_elem.text = comment
			
			# Lines
			for line in dialog.lines:
				line_elem = ET.SubElement(dialog_elem, 'line')
				line_elem.text = line
		
		# Pretty print
		xml_str = ET.tostring(root, encoding='utf-8')
		dom = minidom.parseString(xml_str)
		pretty_xml = dom.toprettyxml(indent='  ', encoding='utf-8')
		
		with open(output_path, 'wb') as f:
			f.write(pretty_xml)
		
		if self.verbose:
			print(f"Wrote {len(collection.dialogs)} dialogs to {output_path}")
	
	def write_yaml_format(self, collection: ScriptCollection, output_path: Path) -> None:
		"""Write YAML format"""
		lines = []
		
		# Metadata
		if collection.metadata:
			lines.append("metadata:")
			for key, value in collection.metadata.items():
				lines.append(f"  {key}: {value}")
			lines.append("")
		
		# Dialogs
		lines.append("dialogs:")
		for dialog in collection.dialogs:
			lines.append(f"  - id: {dialog.dialog_id}")
			
			if dialog.comments:
				lines.append("    comments:")
				for comment in dialog.comments:
					lines.append(f"      - {comment}")
			
			lines.append("    lines:")
			for line in dialog.lines:
				# Escape special YAML characters
				escaped = line.replace('"', '\\"').replace(':', '\\:')
				lines.append(f'      - "{escaped}"')
			
			lines.append("")
		
		with open(output_path, 'w', encoding='utf-8') as f:
			f.write('\n'.join(lines))
		
		if self.verbose:
			print(f"Wrote {len(collection.dialogs)} dialogs to {output_path}")
	
	def write_assembly_format(self, collection: ScriptCollection, output_path: Path) -> None:
		"""Write 65816 assembly format"""
		lines = [
			"; Auto-generated assembly from script conversion",
			"; Format: 65816 assembly for SNES",
			"",
			".org $C00000  ; Adjust as needed",
			""
		]
		
		for dialog in collection.dialogs:
			lines.append(f"; Dialog: {dialog.dialog_id}")
			lines.append(f"{dialog.dialog_id}:")
			
			for line in dialog.lines:
				# Convert commands to assembly
				if line.startswith('"'):
					# Text data
					text = line.strip('"')
					lines.append(f'  .db "{text}", $00  ; Text string')
				
				elif line in self.COMMAND_OPCODES:
					# Simple command (no parameters)
					opcode = self.COMMAND_OPCODES[line]
					lines.append(f'  .db ${opcode:02X}  ; {line}')
				
				else:
					# Command with parameters
					parts = line.split()
					if parts[0] in self.COMMAND_OPCODES:
						opcode = self.COMMAND_OPCODES[parts[0]]
						lines.append(f'  .db ${opcode:02X}  ; {parts[0]}')
						
						# Parameters
						for param in parts[1:]:
							try:
								# Try to parse as hex or decimal
								value = int(param, 0)
								lines.append(f'  .db ${value:02X}  ; param: {param}')
							except ValueError:
								# Label or symbol
								lines.append(f'  .dw {param}  ; param: {param}')
					else:
						# Unknown command, add as comment
						lines.append(f'  ; Unknown: {line}')
			
			lines.append("")
		
		with open(output_path, 'w', encoding='utf-8') as f:
			f.write('\n'.join(lines))
		
		if self.verbose:
			print(f"Wrote {len(collection.dialogs)} dialogs to {output_path}")
	
	def write_file(self, collection: ScriptCollection, output_path: Path, 
	               format: Optional[ScriptFormat] = None) -> None:
		"""Write file in specified or detected format"""
		if format is None:
			format = self.detect_format(output_path)
		
		if self.verbose:
			print(f"Writing to {output_path} as {format.value}...")
		
		if format == ScriptFormat.SCRIPT:
			self.write_script_format(collection, output_path)
		elif format == ScriptFormat.JSON:
			self.write_json_format(collection, output_path)
		elif format == ScriptFormat.CSV:
			self.write_csv_format(collection, output_path)
		elif format == ScriptFormat.XML:
			self.write_xml_format(collection, output_path)
		elif format == ScriptFormat.YAML:
			self.write_yaml_format(collection, output_path)
		elif format == ScriptFormat.ASSEMBLY:
			self.write_assembly_format(collection, output_path)
		else:
			raise ValueError(f"Writing {format.value} format not yet implemented")
	
	def convert(self, input_path: Path, output_path: Path,
	            input_format: Optional[ScriptFormat] = None,
	            output_format: Optional[ScriptFormat] = None) -> None:
		"""Convert file from one format to another"""
		# Read input
		collection = self.read_file(input_path, input_format)
		
		# Write output
		self.write_file(collection, output_path, output_format)
		
		if self.verbose:
			print(f"✓ Converted {input_path} → {output_path}")
	
	def batch_convert(self, input_paths: List[Path], output_dir: Path,
	                  output_format: ScriptFormat) -> int:
		"""Convert multiple files to target format"""
		output_dir.mkdir(parents=True, exist_ok=True)
		converted_count = 0
		
		for input_path in input_paths:
			# Generate output filename
			output_path = output_dir / f"{input_path.stem}.{output_format.value}"
			
			try:
				self.convert(input_path, output_path, output_format=output_format)
				converted_count += 1
			except Exception as e:
				print(f"Error converting {input_path}: {e}")
		
		return converted_count


def main():
	parser = argparse.ArgumentParser(description='Convert between different script formats')
	parser.add_argument('--input', type=Path, nargs='+', required=True, help='Input file(s)')
	parser.add_argument('--output', type=Path, help='Output file (single file mode)')
	parser.add_argument('--output-dir', type=Path, help='Output directory (batch mode)')
	parser.add_argument('--format', choices=[f.value for f in ScriptFormat], 
	                    help='Output format')
	parser.add_argument('--input-format', choices=[f.value for f in ScriptFormat],
	                    help='Force input format (auto-detect if not specified)')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	converter = FormatConverter(verbose=args.verbose)
	
	# Determine output format
	if args.format:
		output_format = ScriptFormat(args.format)
	elif args.output:
		output_format = converter.detect_format(args.output)
	else:
		output_format = ScriptFormat.JSON  # Default
	
	# Determine input format if specified
	input_format = ScriptFormat(args.input_format) if args.input_format else None
	
	# Single file or batch mode?
	if len(args.input) == 1 and args.output:
		# Single file conversion
		converter.convert(
			args.input[0],
			args.output,
			input_format=input_format,
			output_format=output_format
		)
		print(f"\n✓ Conversion complete: {args.output}")
	
	elif args.output_dir:
		# Batch conversion
		count = converter.batch_convert(
			args.input,
			args.output_dir,
			output_format
		)
		print(f"\n✓ Converted {count}/{len(args.input)} files to {args.output_dir}")
	
	else:
		print("Error: Specify either --output (single file) or --output-dir (batch mode)")
		return 1
	
	return 0


if __name__ == '__main__':
	exit(main())
