#!/usr/bin/env python3
"""
Systematically Extract DTE Sequences from ROM
Builds complete DTE table by analyzing all dialog bytes
"""

import struct
from pathlib import Path
from collections import defaultdict, Counter
from typing import Dict, List, Set, Tuple, Optional


# Known character mappings (confirmed from analysis)
KNOWN_CHARS = {
	# Lowercase letters (0xB4-0xCD)
	0xB4: 'a', 0xB5: 'b', 0xB6: 'c', 0xB7: 'd', 0xB8: 'e', 0xB9: 'f',
	0xBA: 'g', 0xBB: 'h', 0xBC: 'i', 0xBD: 'j', 0xBE: 'k', 0xBF: 'l',
	0xC0: 'm', 0xC1: 'n', 0xC2: 'o', 0xC3: 'p', 0xC4: 'q', 0xC5: 'r',
	0xC6: 's', 0xC7: 't', 0xC8: 'u', 0xC9: 'v', 0xCA: 'w', 0xCB: 'x',
	0xCC: 'y', 0xCD: 'z',
	
	# Uppercase letters (0x9A-0xB3)
	0x9A: 'A', 0x9B: 'B', 0x9C: 'C', 0x9D: 'D', 0x9E: 'E', 0x9F: 'F',
	0xA0: 'G', 0xA1: 'H', 0xA2: 'I', 0xA3: 'J', 0xA4: 'K', 0xA5: 'L',
	0xA6: 'M', 0xA7: 'N', 0xA8: 'O', 0xA9: 'P', 0xAA: 'Q', 0xAB: 'R',
	0xAC: 'S', 0xAD: 'T', 0xAE: 'U', 0xAF: 'V', 0xB0: 'W', 0xB1: 'X',
	0xB2: 'Y', 0xB3: 'Z',
	
	# Punctuation
	0xCE: '!', 0xCF: '?', 0xD0: ',', 0xD1: "'", 0xD2: '.', 0xD3: '"',
	0xD4: '"', 0xD5: '."', 0xD6: ';', 0xD7: ':', 0xD8: '…', 0xD9: '/',
	0xDA: '-', 0xDB: '&', 0xDC: '▶', 0xDD: '%',
	
	# Control codes
	0x00: '[END]', 0x01: '\n', 0x06: ' ',
}

# Known DTE sequences (verified from ROM analysis)
VERIFIED_DTE = {
	0x45: 's ',
	0x49: 'l ',
	0x4B: 'er',
	0x5E: 'ea',
}


class DTEExtractor:
	"""Extract DTE sequences by analyzing ROM patterns"""
	
	def __init__(self, rom_path: str):
		"""Initialize with ROM path"""
		self.rom_path = Path(rom_path)
		with open(self.rom_path, 'rb') as f:
			self.rom_data = f.read()
		
		# Dialog data
		self.pointer_table_pc = 0x0D636
		self.dialog_count = 116
		
		# DTE range
		self.dte_range = range(0x3D, 0x7F)  # 116 sequences
		
		# Track findings
		self.dte_usage = Counter()
		self.dte_contexts = defaultdict(list)
		self.dte_sequences = {}  # Byte -> string mapping
	
	def extract_dialog_bytes(self, dialog_id: int) -> bytes:
		"""Extract raw bytes for a dialog"""
		ptr_offset = self.pointer_table_pc + (dialog_id * 2)
		snes_pointer = struct.unpack('<H', self.rom_data[ptr_offset:ptr_offset+2])[0]
		
		# LoROM conversion
		if snes_pointer >= 0x8000:
			pc_address = 0x018000 + (snes_pointer - 0x8000)
		else:
			pc_address = 0x018000 + snes_pointer
		
		# Read until 0x00
		dialog_bytes = bytearray()
		offset = pc_address
		while offset < len(self.rom_data):
			byte = self.rom_data[offset]
			dialog_bytes.append(byte)
			if byte == 0x00:
				break
			offset += 1
		
		return bytes(dialog_bytes)
	
	def decode_with_known(self, dialog_bytes: bytes) -> str:
		"""Decode dialog using known characters"""
		result = []
		i = 0
		while i < len(dialog_bytes):
			byte = dialog_bytes[i]
			if byte in KNOWN_CHARS:
				result.append(KNOWN_CHARS[byte])
			elif byte in VERIFIED_DTE:
				result.append(f'{{{VERIFIED_DTE[byte]}}}')
			elif byte in self.dte_range:
				result.append(f'[{byte:02X}]')
			else:
				result.append(f'<{byte:02X}>')
			i += 1
		return ''.join(result)
	
	def find_dte_patterns(self):
		"""Find DTE sequence patterns from all dialogs"""
		print(f"Analyzing {self.dialog_count} dialogs for DTE patterns...\n")
		
		all_decoded = []
		
		for dialog_id in range(self.dialog_count):
			dialog_bytes = self.extract_dialog_bytes(dialog_id)
			decoded = self.decode_with_known(dialog_bytes)
			all_decoded.append({
				'id': dialog_id,
				'bytes': dialog_bytes.hex(),
				'decoded': decoded,
				'length': len(dialog_bytes)
			})
			
			# Track DTE usage
			for byte in dialog_bytes:
				if byte in self.dte_range:
					self.dte_usage[byte] += 1
					# Get context (3 bytes before and after)
					idx = dialog_bytes.index(byte)
					context_before = dialog_bytes[max(0, idx-3):idx].hex()
					context_after = dialog_bytes[idx+1:min(len(dialog_bytes), idx+4)].hex()
					self.dte_contexts[byte].append({
						'dialog': dialog_id,
						'position': idx,
						'before': context_before,
						'after': context_after
					})
			
			if dialog_id % 20 == 0:
				print(f"  Processed {dialog_id}/{self.dialog_count}...")
		
		return all_decoded
	
	def analyze_dte_byte(self, dte_byte: int) -> Optional[str]:
		"""Try to deduce DTE sequence from context"""
		if dte_byte not in self.dte_contexts:
			return None
		
		contexts = self.dte_contexts[dte_byte]
		
		# Look for patterns in what follows
		following_chars = Counter()
		preceding_chars = Counter()
		
		for ctx in contexts:
			# Decode what follows
			after_bytes = bytes.fromhex(ctx['after'])
			before_bytes = bytes.fromhex(ctx['before'])
			
			if after_bytes and after_bytes[0] in KNOWN_CHARS:
				following_chars[KNOWN_CHARS[after_bytes[0]]] += 1
			
			if before_bytes and before_bytes[-1] in KNOWN_CHARS:
				preceding_chars[KNOWN_CHARS[before_bytes[-1]]] += 1
		
		# If there's a consistent pattern, note it
		most_common_after = following_chars.most_common(1)
		most_common_before = preceding_chars.most_common(1)
		
		hints = {
			'byte': dte_byte,
			'uses': len(contexts),
			'common_before': most_common_before[0] if most_common_before else None,
			'common_after': most_common_after[0] if most_common_after else None,
			'sample_contexts': contexts[:3]
		}
		
		return hints
	
	def generate_report(self, output_path: str):
		"""Generate DTE extraction report"""
		all_decoded = self.find_dte_patterns()
		
		with open(output_path, 'w', encoding='utf-8') as f:
			f.write("# DTE Sequence Extraction Report\n\n")
			f.write(f"Analyzed {self.dialog_count} dialogs\n\n")
			
			# Summary
			f.write("## DTE Usage Summary\n\n")
			f.write(f"Total unique DTE bytes: {len(self.dte_usage)}\n")
			f.write(f"Expected DTE bytes (0x3D-0x7E): 66\n\n")
			
			# Most common DTE sequences
			f.write("### Most Common DTE Sequences\n\n")
			f.write("| Byte | Hex | Uses | Sample Contexts |\n")
			f.write("|------|-----|------|----------------|\n")
			
			for byte_val, count in self.dte_usage.most_common(30):
				contexts = self.dte_contexts[byte_val][:2]
				context_str = ", ".join([f"D{c['dialog']}:{c['before']}[{byte_val:02X}]{c['after']}" for c in contexts])
				f.write(f"| {byte_val:3d} | 0x{byte_val:02X} | {count:4d} | {context_str} |\n")
			
			# Detailed analysis per DTE byte
			f.write("\n## Detailed DTE Analysis\n\n")
			
			for byte_val in sorted(self.dte_usage.keys()):
				hints = self.analyze_dte_byte(byte_val)
				if hints:
					f.write(f"\n### 0x{byte_val:02X} ({byte_val})\n\n")
					f.write(f"**Uses:** {hints['uses']}\n\n")
					
					if hints['common_before']:
						f.write(f"**Often preceded by:** '{hints['common_before'][0]}' ({hints['common_before'][1]} times)\n\n")
					
					if hints['common_after']:
						f.write(f"**Often followed by:** '{hints['common_after'][0]}' ({hints['common_after'][1]} times)\n\n")
					
					f.write("**Sample contexts:**\n```\n")
					for ctx in hints['sample_contexts']:
						before = bytes.fromhex(ctx['before'])
						after = bytes.fromhex(ctx['after'])
						before_str = ''.join([KNOWN_CHARS.get(b, f'<{b:02X}>') for b in before])
						after_str = ''.join([KNOWN_CHARS.get(b, f'<{b:02X}>') for b in after])
						f.write(f"Dialog {ctx['dialog']:3d}: {before_str}[{byte_val:02X}]{after_str}\n")
					f.write("```\n")
			
			# Sample dialogs with DTE
			f.write("\n## Sample Dialog Decoding\n\n")
			f.write("First 10 dialogs with DTE sequences decoded using known characters:\n\n")
			
			for dialog in all_decoded[:10]:
				f.write(f"\n### Dialog {dialog['id']}\n\n")
				f.write(f"**Bytes ({dialog['length']}):** `{dialog['bytes']}`\n\n")
				f.write(f"**Decoded:** {dialog['decoded']}\n\n")
		
		print(f"\nReport written to {output_path}")
		
		# Print summary
		print(f"\nDTE Usage Summary:")
		print(f"  Unique DTE bytes found: {len(self.dte_usage)}")
		print(f"  Expected (0x3D-0x7E): 66")
		print(f"\nTop 10 most used DTE bytes:")
		for byte_val, count in self.dte_usage.most_common(10):
			verified = " (VERIFIED)" if byte_val in VERIFIED_DTE else ""
			print(f"  0x{byte_val:02X}: {count:4d} uses{verified}")


def main():
	"""Main entry point"""
	rom_path = Path(__file__).parent.parent.parent / 'roms' / 'Final Fantasy - Mystic Quest (U) (V1.1).sfc'
	
	if not rom_path.exists():
		print(f"ERROR: ROM not found at {rom_path}")
		return
	
	extractor = DTEExtractor(str(rom_path))
	
	output_path = Path(__file__).parent.parent.parent / 'reports' / 'dte_extraction.md'
	output_path.parent.mkdir(parents=True, exist_ok=True)
	
	extractor.generate_report(str(output_path))
	
	print("\nExtraction complete!")
	print("\nNext steps:")
	print("1. Review reports/dte_extraction.md")
	print("2. Look for patterns in contexts")
	print("3. Cross-reference with known English words")
	print("4. Update complex.tbl with verified sequences")


if __name__ == '__main__':
	main()
