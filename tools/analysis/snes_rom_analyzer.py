#!/usr/bin/env python3
"""
SNES ROM Analyzer - Comprehensive SNES ROM analysis and documentation

Analyzes SNES ROM structure, headers, mapping modes, and content.

Features:
- ROM header parsing (internal/external)
- Mapping mode detection (LoROM/HiROM/ExHiROM/etc.)
- Checksum validation
- Region detection (NTSC/PAL)
- ROM size analysis
- Entropy analysis for compression detection
- Data vs code heuristics
- Bank analysis
- Vector table extraction
- Title/maker code extraction
- Coprocessor detection (DSP/SuperFX/SA-1/etc.)

Usage:
	python snes_rom_analyzer.py rom.sfc --full-analysis
	python snes_rom_analyzer.py rom.sfc --validate
	python snes_rom_analyzer.py rom.sfc --entropy --output entropy.png
	python snes_rom_analyzer.py rom.sfc --bank-analysis
	python snes_rom_analyzer.py rom.sfc --export-report --output report.md
"""

import argparse
import json
import struct
import math
from pathlib import Path
from typing import List, Tuple, Optional, Dict
from dataclasses import dataclass, asdict
from enum import Enum
from collections import Counter

try:
	from PIL import Image, ImageDraw
	PIL_AVAILABLE = True
except ImportError:
	PIL_AVAILABLE = False


class MappingMode(Enum):
	"""SNES ROM mapping modes"""
	LOROM = "LoROM"
	HIROM = "HiROM"
	EXHIROM = "ExHiROM"
	EXLOROM = "ExLoROM"
	SDD1ROM = "SDD-1 ROM"
	SA1ROM = "SA-1 ROM"
	SUPERFXROM = "SuperFX ROM"
	UNKNOWN = "Unknown"


class Region(Enum):
	"""SNES regions"""
	JAPAN = "Japan"
	NORTH_AMERICA = "North America"
	EUROPE = "Europe"
	SWEDEN = "Sweden"
	FINLAND = "Finland"
	DENMARK = "Denmark"
	FRANCE = "France"
	HOLLAND = "Holland"
	SPAIN = "Spain"
	GERMANY = "Germany"
	ITALY = "Italy"
	CHINA = "China"
	KOREA = "Korea"
	COMMON = "Common (Worldwide)"
	CANADA = "Canada"
	BRAZIL = "Brazil"
	AUSTRALIA = "Australia"
	OTHER = "Other"


class VideoMode(Enum):
	"""Video modes"""
	NTSC = "NTSC (60Hz)"
	PAL = "PAL (50Hz)"


@dataclass
class ROMHeader:
	"""SNES ROM header"""
	title: str
	mapping_mode: MappingMode
	rom_type: int
	rom_size: int
	sram_size: int
	region: Region
	video_mode: VideoMode
	maker_code: int
	version: int
	checksum_complement: int
	checksum: int
	has_coprocessor: bool
	coprocessor_type: Optional[str]
	
	def to_dict(self) -> dict:
		d = asdict(self)
		d['mapping_mode'] = self.mapping_mode.value
		d['region'] = self.region.value
		d['video_mode'] = self.video_mode.value
		return d


class SNESROMAnalyzer:
	"""Analyze SNES ROM structure"""
	
	# Region code mapping
	REGION_MAP = {
		0x00: Region.JAPAN,
		0x01: Region.NORTH_AMERICA,
		0x02: Region.EUROPE,
		0x03: Region.SWEDEN,
		0x04: Region.FINLAND,
		0x05: Region.DENMARK,
		0x06: Region.FRANCE,
		0x07: Region.HOLLAND,
		0x08: Region.SPAIN,
		0x09: Region.GERMANY,
		0x0A: Region.ITALY,
		0x0B: Region.CHINA,
		0x0C: Region.KOREA,
		0x0D: Region.COMMON,
		0x0E: Region.CANADA,
		0x0F: Region.BRAZIL,
		0x10: Region.AUSTRALIA,
	}
	
	# Coprocessor types (based on ROM type byte)
	COPROCESSOR_MAP = {
		0x03: "DSP-1",
		0x05: "DSP-2",
		0x13: "SuperFX",
		0x14: "OBC-1",
		0x15: "SA-1",
		0x1A: "SPC7110",
		0x25: "S-DD1",
		0x35: "S-RTC",
		0x43: "Cx4",
		0x53: "SPC7110 + RTC",
		0xE3: "SA-1 + Battery",
		0xF3: "SuperFX + Battery",
		0xF5: "DSP + Battery",
		0xF9: "SPC7110 + Battery",
	}
	
	def __init__(self, rom_path: Path, verbose: bool = False):
		self.rom_path = rom_path
		self.verbose = verbose
		
		with open(rom_path, 'rb') as f:
			self.rom_data = f.read()
		
		self.rom_size = len(self.rom_data)
		self.has_header = self._detect_header()
		self.header_offset = 512 if self.has_header else 0
		
		if self.verbose:
			print(f"Loaded ROM: {rom_path}")
			print(f"Size: {self.rom_size:,} bytes ({self.rom_size // 1024} KB)")
			print(f"SMC header: {'Yes' if self.has_header else 'No'}")
	
	def _detect_header(self) -> bool:
		"""Detect 512-byte SMC header"""
		# ROM size should be power of 2, or power of 2 + 512
		size_without_header = self.rom_size
		size_with_header = self.rom_size - 512
		
		def is_power_of_2_or_close(n: int) -> bool:
			# Check if n is power of 2 or very close
			if n <= 0:
				return False
			return (n & (n - 1)) == 0 or ((n + 512) & (n + 511)) == 0
		
		# If size minus 512 is more "standard", there's a header
		if self.rom_size % 1024 == 512:
			return True
		
		return False
	
	def _find_header_location(self) -> Tuple[int, MappingMode]:
		"""Find header location and mapping mode"""
		# LoROM: header at $7FB0 (file offset $7FB0 or $FFC0)
		# HiROM: header at $FFB0 (file offset $FFB0 or $1FFC0)
		
		lorom_offsets = [0x7FB0, 0xFFC0]
		hirom_offsets = [0xFFB0, 0x1FFC0, 0x40FFB0]
		
		def score_header(offset: int) -> int:
			"""Score potential header location"""
			if offset + 48 > len(self.rom_data):
				return 0
			
			score = 0
			
			# Check title (should be ASCII or spaces)
			title_offset = offset - 0x15
			if title_offset >= 0:
				title_bytes = self.rom_data[title_offset:title_offset + 21]
				ascii_count = sum(1 for b in title_bytes if 0x20 <= b <= 0x7E)
				score += ascii_count * 5
			
			# Check checksum complement
			checksum_comp = struct.unpack_from('<H', self.rom_data, offset + 0x1C)[0]
			checksum = struct.unpack_from('<H', self.rom_data, offset + 0x1E)[0]
			
			if (checksum_comp ^ checksum) == 0xFFFF:
				score += 100
			
			# Check mapping mode byte
			mapping = self.rom_data[offset + 0x15] if offset + 0x15 < len(self.rom_data) else 0
			if mapping in [0x20, 0x21, 0x23, 0x25, 0x30, 0x31, 0x32, 0x35]:
				score += 50
			
			return score
		
		best_offset = 0
		best_score = 0
		best_mode = MappingMode.UNKNOWN
		
		# Try LoROM locations
		for offset in lorom_offsets:
			actual_offset = self.header_offset + offset
			score = score_header(actual_offset)
			if score > best_score:
				best_score = score
				best_offset = actual_offset
				best_mode = MappingMode.LOROM
		
		# Try HiROM locations
		for offset in hirom_offsets:
			actual_offset = self.header_offset + offset
			score = score_header(actual_offset)
			if score > best_score:
				best_score = score
				best_offset = actual_offset
				best_mode = MappingMode.HIROM
		
		return (best_offset, best_mode)
	
	def parse_header(self) -> ROMHeader:
		"""Parse ROM header"""
		header_offset, mapping_mode = self._find_header_location()
		
		if header_offset == 0:
			# Create default header
			return ROMHeader(
				title="Unknown",
				mapping_mode=MappingMode.UNKNOWN,
				rom_type=0,
				rom_size=0,
				sram_size=0,
				region=Region.OTHER,
				video_mode=VideoMode.NTSC,
				maker_code=0,
				version=0,
				checksum_complement=0,
				checksum=0,
				has_coprocessor=False,
				coprocessor_type=None
			)
		
		# Parse header data
		title_offset = header_offset - 0x15
		title_bytes = self.rom_data[title_offset:title_offset + 21]
		title = title_bytes.decode('ascii', errors='ignore').strip()
		
		mapping_byte = self.rom_data[header_offset + 0x15]
		rom_type = self.rom_data[header_offset + 0x16]
		rom_size = self.rom_data[header_offset + 0x17]
		sram_size = self.rom_data[header_offset + 0x18]
		region_code = self.rom_data[header_offset + 0x19]
		maker_code = self.rom_data[header_offset + 0x1A]
		version = self.rom_data[header_offset + 0x1B]
		
		checksum_comp = struct.unpack_from('<H', self.rom_data, header_offset + 0x1C)[0]
		checksum = struct.unpack_from('<H', self.rom_data, header_offset + 0x1E)[0]
		
		# Determine region and video mode
		region = self.REGION_MAP.get(region_code, Region.OTHER)
		
		# Video mode based on region
		pal_regions = [Region.EUROPE, Region.SWEDEN, Region.FINLAND, Region.DENMARK,
					   Region.FRANCE, Region.HOLLAND, Region.SPAIN, Region.GERMANY,
					   Region.ITALY, Region.AUSTRALIA]
		video_mode = VideoMode.PAL if region in pal_regions else VideoMode.NTSC
		
		# Detect coprocessor
		has_coprocessor = rom_type in self.COPROCESSOR_MAP
		coprocessor_type = self.COPROCESSOR_MAP.get(rom_type)
		
		# Refine mapping mode based on mapping byte
		if mapping_byte & 0x0F == 0x00:
			mapping_mode = MappingMode.LOROM
		elif mapping_byte & 0x0F == 0x01:
			mapping_mode = MappingMode.HIROM
		elif mapping_byte & 0x0F == 0x02:
			mapping_mode = MappingMode.LOROM  # LoROM + S-DD1
		elif mapping_byte & 0x0F == 0x03:
			mapping_mode = MappingMode.LOROM  # LoROM + SA-1
		elif mapping_byte & 0x0F == 0x05:
			mapping_mode = MappingMode.EXHIROM
		elif mapping_byte & 0x0F == 0x0A:
			mapping_mode = MappingMode.HIROM  # HiROM + SPC7110
		
		return ROMHeader(
			title=title,
			mapping_mode=mapping_mode,
			rom_type=rom_type,
			rom_size=rom_size,
			sram_size=sram_size,
			region=region,
			video_mode=video_mode,
			maker_code=maker_code,
			version=version,
			checksum_complement=checksum_comp,
			checksum=checksum,
			has_coprocessor=has_coprocessor,
			coprocessor_type=coprocessor_type
		)
	
	def validate_checksum(self, header: ROMHeader) -> Tuple[bool, int]:
		"""Validate ROM checksum"""
		# Calculate checksum (sum of all bytes)
		calculated = 0
		
		for byte in self.rom_data[self.header_offset:]:
			calculated = (calculated + byte) & 0xFFFF
		
		# For small ROMs, mirror the data to fill 2MB
		rom_size_kb = (len(self.rom_data) - self.header_offset) // 1024
		if rom_size_kb < 2048:
			# Calculate how many times to mirror
			mirrors = 2048 // rom_size_kb
			calculated = (calculated * mirrors) & 0xFFFF
		
		checksum_valid = (calculated & 0xFFFF) == header.checksum
		
		return (checksum_valid, calculated)
	
	def analyze_entropy(self, block_size: int = 256) -> List[float]:
		"""Calculate entropy for each block (measures compression/randomness)"""
		entropies = []
		
		for i in range(0, len(self.rom_data), block_size):
			block = self.rom_data[i:i + block_size]
			
			if len(block) == 0:
				entropies.append(0.0)
				continue
			
			# Calculate entropy
			counter = Counter(block)
			entropy = 0.0
			
			for count in counter.values():
				probability = count / len(block)
				entropy -= probability * math.log2(probability)
			
			entropies.append(entropy)
		
		return entropies
	
	def generate_entropy_map(self, output_path: Path, width: int = 256) -> None:
		"""Generate visual entropy map"""
		if not PIL_AVAILABLE:
			print("Error: PIL/Pillow required for entropy map")
			return
		
		entropies = self.analyze_entropy()
		
		height = (len(entropies) + width - 1) // width
		
		img = Image.new('RGB', (width, height), (0, 0, 0))
		pixels = img.load()
		
		max_entropy = 8.0  # Max entropy for byte = 8 bits
		
		for i, entropy in enumerate(entropies):
			x = i % width
			y = i // width
			
			# Color based on entropy (blue = low, red = high)
			normalized = entropy / max_entropy
			
			if normalized < 0.5:
				# Low entropy (blue to cyan)
				r = 0
				g = int(normalized * 2 * 255)
				b = 255
			else:
				# High entropy (cyan to red)
				r = int((normalized - 0.5) * 2 * 255)
				g = int((1.0 - normalized) * 2 * 255)
				b = int((1.0 - normalized) * 2 * 255)
			
			if x < width and y < height:
				pixels[x, y] = (r, g, b)
		
		img.save(output_path)
		
		if self.verbose:
			print(f"✓ Entropy map saved to {output_path}")
	
	def analyze_banks(self) -> List[Dict]:
		"""Analyze ROM banks"""
		banks = []
		bank_size = 0x8000  # 32KB per bank
		
		for bank_num in range(self.rom_size // bank_size):
			offset = bank_num * bank_size
			bank_data = self.rom_data[offset:offset + bank_size]
			
			if len(bank_data) == 0:
				continue
			
			# Calculate statistics
			zero_bytes = sum(1 for b in bank_data if b == 0x00)
			ff_bytes = sum(1 for b in bank_data if b == 0xFF)
			
			# Estimate if code vs data
			# Code typically has more varied bytes, data more repeated
			unique_bytes = len(set(bank_data))
			
			# Calculate entropy
			counter = Counter(bank_data)
			entropy = 0.0
			for count in counter.values():
				prob = count / len(bank_data)
				entropy -= prob * math.log2(prob)
			
			bank_type = "unknown"
			if zero_bytes > len(bank_data) * 0.9:
				bank_type = "empty/zero"
			elif ff_bytes > len(bank_data) * 0.9:
				bank_type = "empty/FF"
			elif entropy > 6.5:
				bank_type = "compressed/data"
			elif entropy > 4.5:
				bank_type = "code"
			else:
				bank_type = "data/graphics"
			
			banks.append({
				'bank': bank_num,
				'offset': f"0x{offset:06X}",
				'size': len(bank_data),
				'zero_bytes': zero_bytes,
				'ff_bytes': ff_bytes,
				'unique_bytes': unique_bytes,
				'entropy': round(entropy, 2),
				'estimated_type': bank_type
			})
		
		return banks
	
	def extract_vectors(self) -> Dict[str, int]:
		"""Extract interrupt vectors"""
		header_offset, mapping_mode = self._find_header_location()
		
		# Vectors are at the end of the header bank
		if mapping_mode == MappingMode.HIROM:
			vector_offset = header_offset + 0x10 - 0x20  # Vectors before header
		else:
			vector_offset = header_offset + 0x10 - 0x20
		
		vectors = {}
		
		vector_names = [
			('native_cop', -0x14),
			('native_brk', -0x16),
			('native_abort', -0x18),
			('native_nmi', -0x1A),
			('native_reset', -0x1C),  # Not used
			('native_irq', -0x1E),
			('emulation_cop', -0x04),
			('emulation_abort', -0x08),
			('emulation_nmi', -0x0A),
			('emulation_reset', -0x0C),
			('emulation_irq_brk', -0x0E),
		]
		
		for name, offset in vector_names:
			addr_offset = header_offset + 0x20 + offset
			if addr_offset >= 0 and addr_offset + 1 < len(self.rom_data):
				vector = struct.unpack_from('<H', self.rom_data, addr_offset)[0]
				vectors[name] = f"0x{vector:04X}"
		
		return vectors
	
	def generate_report(self, output_path: Path) -> None:
		"""Generate comprehensive analysis report"""
		header = self.parse_header()
		checksum_valid, calculated_checksum = self.validate_checksum(header)
		vectors = self.extract_vectors()
		banks = self.analyze_banks()
		
		report = f"""# SNES ROM Analysis Report

## ROM Information
- **File**: {self.rom_path.name}
- **Size**: {self.rom_size:,} bytes ({self.rom_size // 1024} KB)
- **SMC Header**: {'Yes (512 bytes)' if self.has_header else 'No'}

## ROM Header
- **Title**: {header.title}
- **Mapping Mode**: {header.mapping_mode.value}
- **ROM Type**: 0x{header.rom_type:02X}
- **ROM Size**: {1 << header.rom_size} KB
- **SRAM Size**: {1 << header.sram_size if header.sram_size > 0 else 0} KB
- **Region**: {header.region.value}
- **Video Mode**: {header.video_mode.value}
- **Maker Code**: 0x{header.maker_code:02X}
- **Version**: {header.version}

## Coprocessor
- **Has Coprocessor**: {header.has_coprocessor}
- **Type**: {header.coprocessor_type or 'None'}

## Checksum
- **Stored**: 0x{header.checksum:04X}
- **Complement**: 0x{header.checksum_complement:04X}
- **Calculated**: 0x{calculated_checksum:04X}
- **Valid**: {'✓ Yes' if checksum_valid else '✗ No'}
- **Complement Match**: {'✓ Yes' if (header.checksum ^ header.checksum_complement) == 0xFFFF else '✗ No'}

## Interrupt Vectors
"""
		
		for name, addr in vectors.items():
			report += f"- **{name.replace('_', ' ').title()}**: {addr}\n"
		
		report += f"\n## Bank Analysis\n\n"
		report += "| Bank | Offset | Type | Entropy | Unique Bytes | Zero % | FF % |\n"
		report += "|------|--------|------|---------|--------------|--------|------|\n"
		
		for bank in banks[:64]:  # Limit to first 64 banks
			zero_pct = (bank['zero_bytes'] / bank['size']) * 100
			ff_pct = (bank['ff_bytes'] / bank['size']) * 100
			report += f"| {bank['bank']:02X} | {bank['offset']} | {bank['estimated_type']} | {bank['entropy']} | {bank['unique_bytes']} | {zero_pct:.1f}% | {ff_pct:.1f}% |\n"
		
		with open(output_path, 'w', encoding='utf-8') as f:
			f.write(report)
		
		if self.verbose:
			print(f"✓ Report saved to {output_path}")


def main():
	parser = argparse.ArgumentParser(description='Analyze SNES ROM')
	parser.add_argument('rom', type=Path, help='ROM file')
	parser.add_argument('--full-analysis', action='store_true', help='Full analysis')
	parser.add_argument('--validate', action='store_true', help='Validate checksum')
	parser.add_argument('--entropy', action='store_true', help='Generate entropy map')
	parser.add_argument('--bank-analysis', action='store_true', help='Analyze banks')
	parser.add_argument('--vectors', action='store_true', help='Extract interrupt vectors')
	parser.add_argument('--export-report', action='store_true', help='Export report as Markdown')
	parser.add_argument('--export-json', action='store_true', help='Export data as JSON')
	parser.add_argument('--output', type=Path, help='Output file')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	analyzer = SNESROMAnalyzer(args.rom, verbose=args.verbose)
	
	# Parse header
	header = analyzer.parse_header()
	
	# Full analysis
	if args.full_analysis or not any([args.validate, args.entropy, args.bank_analysis, args.vectors, args.export_report, args.export_json]):
		print(f"\n=== SNES ROM Analysis ===\n")
		print(f"Title: {header.title}")
		print(f"Mapping: {header.mapping_mode.value}")
		print(f"Region: {header.region.value} ({header.video_mode.value})")
		print(f"Size: {1 << header.rom_size} KB")
		
		if header.has_coprocessor:
			print(f"Coprocessor: {header.coprocessor_type}")
		
		checksum_valid, calc = analyzer.validate_checksum(header)
		print(f"\nChecksum: {'✓ Valid' if checksum_valid else '✗ Invalid'}")
		print(f"  Stored: 0x{header.checksum:04X}")
		print(f"  Calculated: 0x{calc:04X}")
	
	# Validate only
	if args.validate:
		checksum_valid, calc = analyzer.validate_checksum(header)
		print(f"Checksum: {'✓ Valid' if checksum_valid else '✗ Invalid'}")
		print(f"Stored: 0x{header.checksum:04X}")
		print(f"Calculated: 0x{calc:04X}")
		print(f"Complement: 0x{header.checksum_complement:04X}")
		print(f"Complement check: {'✓ Pass' if (header.checksum ^ header.checksum_complement) == 0xFFFF else '✗ Fail'}")
	
	# Entropy map
	if args.entropy:
		output_path = args.output or Path('entropy.png')
		
		if not PIL_AVAILABLE:
			print("Error: PIL/Pillow required for entropy map")
			return 1
		
		analyzer.generate_entropy_map(output_path)
	
	# Bank analysis
	if args.bank_analysis:
		banks = analyzer.analyze_banks()
		
		print(f"\nBank Analysis ({len(banks)} banks):\n")
		print(f"{'Bank':<6} {'Offset':<10} {'Type':<20} {'Entropy':<8} {'Unique':<8}")
		print("-" * 60)
		
		for bank in banks[:32]:
			print(f"{bank['bank']:02X}     {bank['offset']:<10} {bank['estimated_type']:<20} {bank['entropy']:<8.2f} {bank['unique_bytes']:<8}")
	
	# Vectors
	if args.vectors:
		vectors = analyzer.extract_vectors()
		
		print(f"\nInterrupt Vectors:\n")
		for name, addr in vectors.items():
			print(f"  {name.replace('_', ' ').title():<25} {addr}")
	
	# Export report
	if args.export_report:
		output_path = args.output or Path('rom_analysis.md')
		analyzer.generate_report(output_path)
	
	# Export JSON
	if args.export_json:
		output_path = args.output or Path('rom_analysis.json')
		
		data = {
			'file': str(analyzer.rom_path),
			'size': analyzer.rom_size,
			'has_smc_header': analyzer.has_header,
			'header': header.to_dict(),
			'checksum_valid': analyzer.validate_checksum(header)[0],
			'vectors': analyzer.extract_vectors(),
			'banks': analyzer.analyze_banks()
		}
		
		with open(output_path, 'w') as f:
			json.dump(data, f, indent='\t')
		
		print(f"✓ Exported to {output_path}")
	
	return 0


if __name__ == '__main__':
	exit(main())
