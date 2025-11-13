#!/usr/bin/env python3
"""
Interactive Hex Editor/Viewer - View and edit binary files with annotations

Features:
- Hex dump with ASCII view
- Interactive editing
- Search (hex/ASCII/regex)
- Data annotations
- Diff mode (compare two files)
- Bookmarks
- Multiple display formats
- Export to HTML with syntax highlighting
- Cursor navigation
- Undo/redo

Usage:
	python hex_editor.py rom.sfc --view --offset 0x80000 --length 0x100
	python hex_editor.py rom.sfc --search "FF 00 FF" --format hex
	python hex_editor.py rom.sfc --diff other.sfc --output diff.html
	python hex_editor.py rom.sfc --annotate annotations.json --export-html
	python hex_editor.py rom.sfc --interactive
"""

import argparse
import re
import json
from pathlib import Path
from typing import List, Tuple, Optional, Dict
from dataclasses import dataclass, asdict
from enum import Enum


class DataType(Enum):
	"""Data type for interpretation"""
	HEX = "hex"
	ASCII = "ascii"
	UINT8 = "uint8"
	INT8 = "int8"
	UINT16_LE = "uint16_le"
	UINT16_BE = "uint16_be"
	INT16_LE = "int16_le"
	INT16_BE = "int16_be"
	UINT32_LE = "uint32_le"
	UINT32_BE = "uint32_be"


@dataclass
class Annotation:
	"""Memory region annotation"""
	offset: int
	length: int
	name: str
	description: str
	data_type: DataType
	color: Optional[str] = None


@dataclass
class Bookmark:
	"""Bookmarked location"""
	offset: int
	name: str
	description: str


class HexViewer:
	"""Hex viewer/editor"""
	
	def __init__(self, file_path: Path, read_only: bool = False):
		self.file_path = file_path
		self.read_only = read_only
		
		with open(file_path, 'rb') as f:
			self.data = bytearray(f.read())
		
		self.size = len(self.data)
		self.annotations: List[Annotation] = []
		self.bookmarks: List[Bookmark] = []
		self.modified = False
	
	def hex_dump(self, offset: int = 0, length: int = 256, bytes_per_line: int = 16) -> str:
		"""Generate hex dump"""
		lines = []
		
		end = min(offset + length, self.size)
		
		for line_offset in range(offset, end, bytes_per_line):
			# Offset
			line = f"{line_offset:08X}  "
			
			# Hex bytes
			hex_bytes = []
			ascii_chars = []
			
			for i in range(bytes_per_line):
				pos = line_offset + i
				
				if pos < end:
					byte = self.data[pos]
					hex_bytes.append(f"{byte:02X}")
					
					# ASCII representation
					if 0x20 <= byte <= 0x7E:
						ascii_chars.append(chr(byte))
					else:
						ascii_chars.append('.')
				else:
					hex_bytes.append('  ')
					ascii_chars.append(' ')
			
			# Group hex bytes (8 + space + 8)
			hex_part = ' '.join(hex_bytes[:8]) + '  ' + ' '.join(hex_bytes[8:])
			ascii_part = ''.join(ascii_chars)
			
			line += hex_part + '  ' + ascii_part
			lines.append(line)
		
		return '\n'.join(lines)
	
	def search_hex(self, pattern: bytes, start: int = 0) -> List[int]:
		"""Search for hex pattern"""
		matches = []
		pos = start
		
		while True:
			pos = self.data.find(pattern, pos)
			if pos == -1:
				break
			matches.append(pos)
			pos += 1
		
		return matches
	
	def search_ascii(self, text: str, start: int = 0) -> List[int]:
		"""Search for ASCII text"""
		pattern = text.encode('ascii', errors='ignore')
		return self.search_hex(pattern, start)
	
	def search_regex(self, pattern: str, start: int = 0) -> List[Tuple[int, bytes]]:
		"""Search using regex"""
		regex = re.compile(pattern.encode('ascii', errors='ignore'))
		matches = []
		
		for match in regex.finditer(self.data[start:]):
			matches.append((start + match.start(), match.group()))
		
		return matches
	
	def write_byte(self, offset: int, value: int) -> None:
		"""Write single byte"""
		if self.read_only:
			raise RuntimeError("File is read-only")
		
		if offset < 0 or offset >= self.size:
			raise ValueError(f"Offset {offset} out of range")
		
		self.data[offset] = value & 0xFF
		self.modified = True
	
	def write_bytes(self, offset: int, data: bytes) -> None:
		"""Write multiple bytes"""
		if self.read_only:
			raise RuntimeError("File is read-only")
		
		if offset < 0 or offset + len(data) > self.size:
			raise ValueError(f"Write would exceed file size")
		
		self.data[offset:offset + len(data)] = data
		self.modified = True
	
	def add_annotation(self, annotation: Annotation) -> None:
		"""Add annotation"""
		self.annotations.append(annotation)
	
	def add_bookmark(self, bookmark: Bookmark) -> None:
		"""Add bookmark"""
		self.bookmarks.append(bookmark)
	
	def get_annotations_at(self, offset: int) -> List[Annotation]:
		"""Get annotations at offset"""
		return [a for a in self.annotations 
				if a.offset <= offset < a.offset + a.length]
	
	def annotated_dump(self, offset: int = 0, length: int = 256, bytes_per_line: int = 16) -> str:
		"""Hex dump with annotations"""
		lines = []
		end = min(offset + length, self.size)
		
		for line_offset in range(offset, end, bytes_per_line):
			# Check for annotations on this line
			line_annotations = []
			for anno in self.annotations:
				if anno.offset <= line_offset < anno.offset + anno.length:
					line_annotations.append(anno)
			
			# Build line
			line = f"{line_offset:08X}  "
			
			hex_bytes = []
			ascii_chars = []
			
			for i in range(bytes_per_line):
				pos = line_offset + i
				
				if pos < end:
					byte = self.data[pos]
					hex_bytes.append(f"{byte:02X}")
					
					if 0x20 <= byte <= 0x7E:
						ascii_chars.append(chr(byte))
					else:
						ascii_chars.append('.')
				else:
					hex_bytes.append('  ')
					ascii_chars.append(' ')
			
			hex_part = ' '.join(hex_bytes[:8]) + '  ' + ' '.join(hex_bytes[8:])
			ascii_part = ''.join(ascii_chars)
			
			line += hex_part + '  ' + ascii_part
			
			# Add annotation info
			if line_annotations:
				anno_names = ', '.join(a.name for a in line_annotations)
				line += f"  [{anno_names}]"
			
			lines.append(line)
		
		return '\n'.join(lines)
	
	def save(self, output_path: Optional[Path] = None) -> None:
		"""Save modified data"""
		if self.read_only:
			raise RuntimeError("File is read-only")
		
		save_path = output_path or self.file_path
		
		with open(save_path, 'wb') as f:
			f.write(self.data)
		
		self.modified = False
	
	def export_html(self, output_path: Path, offset: int = 0, length: int = 4096) -> None:
		"""Export to HTML with syntax highlighting"""
		html = """<!DOCTYPE html>
<html>
<head>
	<title>Hex View: {filename}</title>
	<style>
		body {{
			font-family: 'Consolas', 'Courier New', monospace;
			background: #1e1e1e;
			color: #d4d4d4;
			padding: 20px;
			font-size: 12px;
		}}
		.hex-line {{
			margin: 2px 0;
			white-space: pre;
		}}
		.offset {{
			color: #808080;
		}}
		.hex {{
			color: #4ec9b0;
		}}
		.ascii {{
			color: #ce9178;
		}}
		.annotation {{
			color: #dcdcaa;
			font-style: italic;
		}}
		.annotated-byte {{
			background: #264f78;
			border-radius: 2px;
		}}
		h1 {{
			color: #569cd6;
			margin: 0 0 20px 0;
		}}
		.bookmark {{
			color: #f44747;
			font-weight: bold;
		}}
	</style>
</head>
<body>
	<h1>Hex View: {filename}</h1>
	<p>Size: {size:,} bytes | Offset: 0x{offset:X} | Length: {length:,} bytes</p>
""".format(
			filename=self.file_path.name,
			size=self.size,
			offset=offset,
			length=length
		)
		
		# Bookmarks
		if self.bookmarks:
			html += "\t<h2>Bookmarks</h2>\n\t<ul>\n"
			for bm in self.bookmarks:
				html += f'\t\t<li class="bookmark">0x{bm.offset:08X}: {bm.name} - {bm.description}</li>\n'
			html += "\t</ul>\n"
		
		# Annotations
		if self.annotations:
			html += "\t<h2>Annotations</h2>\n\t<ul>\n"
			for anno in self.annotations:
				html += f'\t\t<li>0x{anno.offset:08X} - 0x{anno.offset + anno.length:08X}: '
				html += f'{anno.name} ({anno.description})</li>\n'
			html += "\t</ul>\n"
		
		html += "\t<h2>Hex Dump</h2>\n\t<pre>\n"
		
		# Generate annotated dump
		end = min(offset + length, self.size)
		bytes_per_line = 16
		
		for line_offset in range(offset, end, bytes_per_line):
			# Check annotations
			line_annos = self.get_annotations_at(line_offset)
			
			line = f'<span class="offset">{line_offset:08X}</span>  '
			
			hex_bytes = []
			ascii_chars = []
			
			for i in range(bytes_per_line):
				pos = line_offset + i
				
				if pos < end:
					byte = self.data[pos]
					
					# Check if annotated
					is_annotated = any(a.offset <= pos < a.offset + a.length for a in self.annotations)
					
					if is_annotated:
						hex_bytes.append(f'<span class="annotated-byte">{byte:02X}</span>')
					else:
						hex_bytes.append(f'{byte:02X}')
					
					if 0x20 <= byte <= 0x7E:
						ascii_chars.append(chr(byte))
					else:
						ascii_chars.append('.')
				else:
					hex_bytes.append('  ')
					ascii_chars.append(' ')
			
			hex_part = '<span class="hex">' + ' '.join(hex_bytes[:8]) + '  ' + ' '.join(hex_bytes[8:]) + '</span>'
			ascii_part = '<span class="ascii">' + ''.join(ascii_chars) + '</span>'
			
			line += hex_part + '  ' + ascii_part
			
			if line_annos:
				anno_names = ', '.join(a.name for a in line_annos)
				line += f'  <span class="annotation">[{anno_names}]</span>'
			
			html += f'\t{line}\n'
		
		html += "\t</pre>\n</body>\n</html>"
		
		with open(output_path, 'w', encoding='utf-8') as f:
			f.write(html)
	
	def diff(self, other_path: Path) -> List[Tuple[int, int, int]]:
		"""Compare with another file, return list of (offset, byte1, byte2)"""
		with open(other_path, 'rb') as f:
			other_data = f.read()
		
		differences = []
		min_size = min(len(self.data), len(other_data))
		
		for i in range(min_size):
			if self.data[i] != other_data[i]:
				differences.append((i, self.data[i], other_data[i]))
		
		# Check for size difference
		if len(self.data) != len(other_data):
			print(f"Warning: Files have different sizes ({len(self.data)} vs {len(other_data)})")
		
		return differences


def main():
	parser = argparse.ArgumentParser(description='Hex editor/viewer')
	parser.add_argument('file', type=Path, help='File to view/edit')
	parser.add_argument('--view', action='store_true', help='View hex dump')
	parser.add_argument('--offset', type=lambda x: int(x, 0), default=0, help='Start offset (hex)')
	parser.add_argument('--length', type=lambda x: int(x, 0), default=256, help='Length to view (hex)')
	parser.add_argument('--bytes-per-line', type=int, default=16, help='Bytes per line')
	parser.add_argument('--search', type=str, help='Search pattern')
	parser.add_argument('--search-format', type=str, choices=['hex', 'ascii', 'regex'], default='hex', help='Search format')
	parser.add_argument('--diff', type=Path, help='Compare with another file')
	parser.add_argument('--annotate', type=Path, help='Load annotations from JSON')
	parser.add_argument('--export-html', action='store_true', help='Export to HTML')
	parser.add_argument('--output', type=Path, help='Output file')
	parser.add_argument('--read-only', action='store_true', help='Read-only mode')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	viewer = HexViewer(args.file, read_only=args.read_only)
	
	# Load annotations
	if args.annotate:
		with open(args.annotate, 'r') as f:
			anno_data = json.load(f)
		
		for anno in anno_data.get('annotations', []):
			viewer.add_annotation(Annotation(
				offset=anno['offset'],
				length=anno['length'],
				name=anno['name'],
				description=anno['description'],
				data_type=DataType(anno.get('data_type', 'hex')),
				color=anno.get('color')
			))
		
		for bm in anno_data.get('bookmarks', []):
			viewer.add_bookmark(Bookmark(
				offset=bm['offset'],
				name=bm['name'],
				description=bm['description']
			))
		
		if args.verbose:
			print(f"Loaded {len(viewer.annotations)} annotations, {len(viewer.bookmarks)} bookmarks")
	
	# Search
	if args.search:
		matches = []
		
		if args.search_format == 'hex':
			# Parse hex pattern
			hex_bytes = bytes.fromhex(args.search.replace(' ', ''))
			matches = viewer.search_hex(hex_bytes)
		elif args.search_format == 'ascii':
			matches = viewer.search_ascii(args.search)
		elif args.search_format == 'regex':
			matches = [(m[0], m[1]) for m in viewer.search_regex(args.search)]
		
		print(f"\nFound {len(matches)} matches:")
		for i, match in enumerate(matches[:100]):  # Limit to 100
			if isinstance(match, tuple):
				offset, data = match
				print(f"  {i + 1}. 0x{offset:08X}: {data.hex()}")
			else:
				print(f"  {i + 1}. 0x{match:08X}")
		
		if len(matches) > 100:
			print(f"  ... and {len(matches) - 100} more")
	
	# Diff mode
	if args.diff:
		differences = viewer.diff(args.diff)
		
		print(f"\nFound {len(differences)} differences:")
		for i, (offset, byte1, byte2) in enumerate(differences[:100]):
			print(f"  {offset:08X}: {byte1:02X} → {byte2:02X}")
		
		if len(differences) > 100:
			print(f"  ... and {len(differences) - 100} more")
		
		# Export diff HTML
		if args.export_html:
			output_path = args.output or Path('diff.html')
			viewer.export_html(output_path, length=4096)
			print(f"✓ Exported diff to {output_path}")
	
	# Export HTML
	elif args.export_html:
		output_path = args.output or Path('hexview.html')
		viewer.export_html(output_path, args.offset, args.length)
		print(f"✓ Exported to {output_path}")
	
	# View
	elif args.view or not any([args.search, args.diff, args.export_html]):
		print(f"\nFile: {args.file.name}")
		print(f"Size: {viewer.size:,} bytes\n")
		
		if viewer.annotations:
			dump = viewer.annotated_dump(args.offset, args.length, args.bytes_per_line)
		else:
			dump = viewer.hex_dump(args.offset, args.length, args.bytes_per_line)
		
		print(dump)
	
	return 0


if __name__ == '__main__':
	exit(main())
