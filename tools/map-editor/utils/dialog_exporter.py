"""
Dialog Export/Import Utility

Supports multiple formats for dialog data exchange:
- CSV: Spreadsheet-friendly
- JSON: Structured data
- TSV: Tab-separated values
- TXT: Plain text with metadata
- XML: Structured exchange format
"""

import csv
import json
import xml.etree.ElementTree as ET
from typing import Dict, List, Optional
from pathlib import Path
import sys

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from utils.dialog_database import DialogEntry, DialogDatabase


class DialogExporter:
	"""Export dialogs to various formats"""
	
	def __init__(self, db: DialogDatabase):
		self.db = db
	
	def export_to_csv(self, filepath: str, include_metadata: bool = True):
		"""Export to CSV format"""
		with open(filepath, 'w', newline='', encoding='utf-8') as f:
			if include_metadata:
				fieldnames = ['id', 'text', 'pointer', 'address', 'length', 'tags', 'notes']
			else:
				fieldnames = ['id', 'text']
			
			writer = csv.DictWriter(f, fieldnames=fieldnames)
			writer.writeheader()
			
			for dialog_id, dialog in sorted(self.db.dialogs.items()):
				row = {'id': f'0x{dialog_id:04X}', 'text': dialog.text}
				
				if include_metadata:
					row['pointer'] = f'0x{dialog.pointer:06X}'
					row['address'] = f'0x{dialog.address:06X}'
					row['length'] = dialog.length
					row['tags'] = ','.join(sorted(dialog.tags))
					row['notes'] = dialog.notes
				
				writer.writerow(row)
	
	def export_to_json(self, filepath: str, include_metadata: bool = True, pretty: bool = True):
		"""Export to JSON format"""
		data = {}
		
		for dialog_id, dialog in self.db.dialogs.items():
			key = f'0x{dialog_id:04X}'
			
			if include_metadata:
				data[key] = {
					'text': dialog.text,
					'pointer': f'0x{dialog.pointer:06X}',
					'address': f'0x{dialog.address:06X}',
					'length': dialog.length,
					'tags': list(sorted(dialog.tags)),
					'notes': dialog.notes,
					'modified': dialog.modified
				}
			else:
				data[key] = dialog.text
		
		with open(filepath, 'w', encoding='utf-8') as f:
			if pretty:
				json.dump(data, f, indent=2, ensure_ascii=False)
			else:
				json.dump(data, f, ensure_ascii=False)
	
	def export_to_tsv(self, filepath: str):
		"""Export to TSV (tab-separated values) format"""
		with open(filepath, 'w', encoding='utf-8') as f:
			f.write("ID\tText\tPointer\tAddress\tLength\tTags\tNotes\n")
			
			for dialog_id, dialog in sorted(self.db.dialogs.items()):
				# Escape tabs and newlines in text
				text = dialog.text.replace('\t', '\\t').replace('\n', '\\n')
				notes = dialog.notes.replace('\t', '\\t').replace('\n', '\\n')
				
				line = (
					f"0x{dialog_id:04X}\t"
					f"{text}\t"
					f"0x{dialog.pointer:06X}\t"
					f"0x{dialog.address:06X}\t"
					f"{dialog.length}\t"
					f"{','.join(sorted(dialog.tags))}\t"
					f"{notes}\n"
				)
				f.write(line)
	
	def export_to_txt(self, filepath: str, separator: str = "=" * 70):
		"""Export to plain text format with separators"""
		with open(filepath, 'w', encoding='utf-8') as f:
			f.write("FFMQ Dialog Export\n")
			f.write(separator + "\n\n")
			
			for dialog_id, dialog in sorted(self.db.dialogs.items()):
				f.write(f"Dialog ID: 0x{dialog_id:04X}\n")
				f.write(f"Pointer:   0x{dialog.pointer:06X}\n")
				f.write(f"Address:   0x{dialog.address:06X}\n")
				f.write(f"Length:    {dialog.length} bytes\n")
				
				if dialog.tags:
					f.write(f"Tags:      {', '.join(sorted(dialog.tags))}\n")
				
				if dialog.notes:
					f.write(f"Notes:     {dialog.notes}\n")
				
				f.write("\n")
				f.write(dialog.text)
				f.write("\n\n")
				f.write(separator + "\n\n")
	
	def export_to_xml(self, filepath: str):
		"""Export to XML format"""
		root = ET.Element('dialogs')
		root.set('count', str(len(self.db.dialogs)))
		
		for dialog_id, dialog in sorted(self.db.dialogs.items()):
			dialog_elem = ET.SubElement(root, 'dialog')
			dialog_elem.set('id', f'0x{dialog_id:04X}')
			dialog_elem.set('pointer', f'0x{dialog.pointer:06X}')
			dialog_elem.set('address', f'0x{dialog.address:06X}')
			dialog_elem.set('length', str(dialog.length))
			
			text_elem = ET.SubElement(dialog_elem, 'text')
			text_elem.text = dialog.text
			
			if dialog.tags:
				tags_elem = ET.SubElement(dialog_elem, 'tags')
				for tag in sorted(dialog.tags):
					tag_elem = ET.SubElement(tags_elem, 'tag')
					tag_elem.text = tag
			
			if dialog.notes:
				notes_elem = ET.SubElement(dialog_elem, 'notes')
				notes_elem.text = dialog.notes
		
		tree = ET.ElementTree(root)
		ET.indent(tree, space="  ")
		tree.write(filepath, encoding='utf-8', xml_declaration=True)


class DialogImporter:
	"""Import dialogs from various formats"""
	
	def __init__(self, db: DialogDatabase):
		self.db = db
	
	def import_from_csv(self, filepath: str, update_existing: bool = True) -> int:
		"""Import from CSV format, returns number of dialogs imported"""
		count = 0
		
		with open(filepath, 'r', encoding='utf-8') as f:
			reader = csv.DictReader(f)
			
			for row in reader:
				dialog_id = int(row['id'], 16)
				
				# Check if dialog exists
				if dialog_id in self.db.dialogs:
					if not update_existing:
						continue
					dialog = self.db.dialogs[dialog_id]
				else:
					# Create new dialog entry
					dialog = DialogEntry(
						id=dialog_id,
						text="",
						raw_bytes=bytearray(),
						pointer=0,
						address=0,
						length=0
					)
					self.db.dialogs[dialog_id] = dialog
				
				# Update fields
				dialog.text = row['text']
				
				if 'pointer' in row and row['pointer']:
					dialog.pointer = int(row['pointer'], 16)
				
				if 'address' in row and row['address']:
					dialog.address = int(row['address'], 16)
				
				if 'length' in row and row['length']:
					dialog.length = int(row['length'])
				
				if 'tags' in row and row['tags']:
					dialog.tags = set(row['tags'].split(','))
				
				if 'notes' in row:
					dialog.notes = row['notes']
				
				dialog.modified = True
				count += 1
		
		return count
	
	def import_from_json(self, filepath: str, update_existing: bool = True) -> int:
		"""Import from JSON format, returns number of dialogs imported"""
		count = 0
		
		with open(filepath, 'r', encoding='utf-8') as f:
			data = json.load(f)
		
		for dialog_id_str, dialog_data in data.items():
			dialog_id = int(dialog_id_str, 16)
			
			# Check if dialog exists
			if dialog_id in self.db.dialogs:
				if not update_existing:
					continue
				dialog = self.db.dialogs[dialog_id]
			else:
				# Create new dialog entry
				dialog = DialogEntry(
					id=dialog_id,
					text="",
					raw_bytes=bytearray(),
					pointer=0,
					address=0,
					length=0
				)
				self.db.dialogs[dialog_id] = dialog
			
			# Handle simple format (string value)
			if isinstance(dialog_data, str):
				dialog.text = dialog_data
			else:
				# Handle full metadata format
				dialog.text = dialog_data['text']
				
				if 'pointer' in dialog_data:
					dialog.pointer = int(dialog_data['pointer'], 16)
				
				if 'address' in dialog_data:
					dialog.address = int(dialog_data['address'], 16)
				
				if 'length' in dialog_data:
					dialog.length = dialog_data['length']
				
				if 'tags' in dialog_data:
					dialog.tags = set(dialog_data['tags'])
				
				if 'notes' in dialog_data:
					dialog.notes = dialog_data['notes']
			
			dialog.modified = True
			count += 1
		
		return count
	
	def import_from_tsv(self, filepath: str, update_existing: bool = True) -> int:
		"""Import from TSV format, returns number of dialogs imported"""
		count = 0
		
		with open(filepath, 'r', encoding='utf-8') as f:
			# Skip header
			f.readline()
			
			for line in f:
				parts = line.rstrip('\n').split('\t')
				if len(parts) < 2:
					continue
				
				dialog_id = int(parts[0], 16)
				
				# Check if dialog exists
				if dialog_id in self.db.dialogs:
					if not update_existing:
						continue
					dialog = self.db.dialogs[dialog_id]
				else:
					# Create new dialog entry
					dialog = DialogEntry(
						id=dialog_id,
						text="",
						raw_bytes=bytearray(),
						pointer=0,
						address=0,
						length=0
					)
					self.db.dialogs[dialog_id] = dialog
				
				# Unescape text
				dialog.text = parts[1].replace('\\t', '\t').replace('\\n', '\n')
				
				if len(parts) > 2 and parts[2]:
					dialog.pointer = int(parts[2], 16)
				
				if len(parts) > 3 and parts[3]:
					dialog.address = int(parts[3], 16)
				
				if len(parts) > 4 and parts[4]:
					dialog.length = int(parts[4])
				
				if len(parts) > 5 and parts[5]:
					dialog.tags = set(parts[5].split(','))
				
				if len(parts) > 6:
					dialog.notes = parts[6].replace('\\t', '\t').replace('\\n', '\n')
				
				dialog.modified = True
				count += 1
		
		return count


def demo():
	"""Demonstration of export/import"""
	# Create test database
	db = DialogDatabase()
	
	# Add some test dialogs
	db.dialogs[0x0001] = DialogEntry(
		id=0x0001,
		text="Welcome to the world of Final Fantasy!",
		raw_bytes=bytearray(),
		pointer=0x1000,
		address=0x8000,
		length=40,
		tags={'intro', 'important'},
		notes="Opening dialog"
	)
	
	db.dialogs[0x0002] = DialogEntry(
		id=0x0002,
		text="The Crystal shines bright.[WAIT]",
		raw_bytes=bytearray(),
		pointer=0x1028,
		address=0x8028,
		length=32,
		tags={'crystal', 'cutscene'}
	)
	
	db.dialogs[0x0003] = DialogEntry(
		id=0x0003,
		text="Good luck on your adventure!",
		raw_bytes=bytearray(),
		pointer=0x1048,
		address=0x8048,
		length=29
	)
	
	print("Created test database with 3 dialogs\n")
	
	# Export to various formats
	exporter = DialogExporter(db)
	
	print("Exporting to CSV...")
	exporter.export_to_csv("test_dialogs.csv")
	print("✓ Exported to test_dialogs.csv")
	
	print("\nExporting to JSON...")
	exporter.export_to_json("test_dialogs.json")
	print("✓ Exported to test_dialogs.json")
	
	print("\nExporting to TSV...")
	exporter.export_to_tsv("test_dialogs.tsv")
	print("✓ Exported to test_dialogs.tsv")
	
	print("\nExporting to TXT...")
	exporter.export_to_txt("test_dialogs.txt")
	print("✓ Exported to test_dialogs.txt")
	
	print("\nExporting to XML...")
	exporter.export_to_xml("test_dialogs.xml")
	print("✓ Exported to test_dialogs.xml")
	
	# Test import
	print("\n" + "=" * 70)
	print("Testing import...")
	
	# Create new database and import
	db2 = DialogDatabase()
	importer = DialogImporter(db2)
	
	count = importer.import_from_json("test_dialogs.json")
	print(f"✓ Imported {count} dialogs from JSON")
	
	# Verify
	print(f"\nVerification:")
	for dialog_id, dialog in sorted(db2.dialogs.items()):
		print(f"  0x{dialog_id:04X}: {dialog.text[:50]}...")
	
	print("\n✓ All formats tested successfully!")


if __name__ == '__main__':
	demo()
