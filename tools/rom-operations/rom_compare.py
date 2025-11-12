#!/usr/bin/env python3
"""
Final Fantasy Mystic Quest - ROM Comparison Tool
Compares original ROM with built ROM to identify differences and track progress toward byte-perfect rebuild

This tool generates detailed reports showing:
- Overall match percentage
- Differences by region (code, graphics, text, data, audio)
- Specific byte ranges that differ
- What needs to be worked on next
"""

import sys
import os
from pathlib import Path
from typing import Dict, List, Tuple, Optional
import json
from dataclasses import dataclass, asdict

@dataclass
class ROMRegion:
	"""Represents a region of the ROM with a specific purpose"""
	name: str
	start: int
	end: int
	category: str  # 'code', 'graphics', 'text', 'data', 'audio', 'unknown'
	description: str
	
@dataclass
class DiffBlock:
	"""Represents a contiguous block of differing bytes"""
	start: int
	end: int
	size: int
	region_name: str
	category: str
	original_bytes: bytes
	built_bytes: bytes
	
	def to_dict(self):
		return {
			'start': f'${self.start:06X}',
			'end': f'${self.end:06X}',
			'size': self.size,
			'region': self.region_name,
			'category': self.category,
			'original_sample': self.original_bytes[:16].hex(),
			'built_sample': self.built_bytes[:16].hex()
		}

class ROMComparator:
	"""Compare original ROM with built ROM and generate detailed reports"""
	
	# Known ROM regions for FFMQ (LoROM addresses = file offsets)
	# These will be refined as we understand more of the ROM
	REGIONS = [
		# Bank $00 - Core engine
		ROMRegion("Boot/Reset", 0x000000, 0x000200, "code", "Boot vectors and initialization"),
		ROMRegion("Main Engine", 0x000200, 0x004000, "code", "Main game loop, input, graphics DMA"),
		ROMRegion("Engine Data", 0x004000, 0x008000, "data", "Engine data tables"),
		
		# Bank $01-$02 - Game logic
		ROMRegion("Field System", 0x008000, 0x010000, "code", "Field/map system, events"),
		ROMRegion("Battle System", 0x010000, 0x018000, "code", "Battle engine, enemy AI"),
		
		# Bank $03 - Menu/UI
		ROMRegion("Menu System", 0x018000, 0x020000, "code", "Menu rendering, equipment"),
		
		# Bank $04 - Text
		ROMRegion("Text Engine", 0x020000, 0x024000, "code", "Text rendering engine"),
		ROMRegion("Dialog Data", 0x024000, 0x028000, "text", "Dialog strings and tables"),
		
		# Bank $05 - Magic/Items
		ROMRegion("Magic System", 0x028000, 0x02c000, "code", "Spell effects, magic engine"),
		ROMRegion("Item System", 0x02c000, 0x030000, "code", "Item handling, inventory"),
		
		# Bank $06 - Enemy/Battle Data
		ROMRegion("Enemy Stats", 0x030000, 0x032000, "data", "Enemy stats, resistances, rewards"),
		ROMRegion("Battle Data", 0x032000, 0x038000, "data", "Battle backgrounds, formations"),
		
		# Bank $07-$09 - Graphics
		ROMRegion("Character Graphics", 0x038000, 0x040000, "graphics", "Hero and NPC sprites"),
		ROMRegion("Enemy Graphics", 0x040000, 0x048000, "graphics", "Enemy and boss sprites"),
		ROMRegion("Tile Graphics", 0x048000, 0x050000, "graphics", "Map tiles, backgrounds"),
		
		# Bank $0a-$0b - Audio
		ROMRegion("Sound Engine", 0x050000, 0x054000, "code", "SPC700 sound driver"),
		ROMRegion("Music Data", 0x054000, 0x058000, "audio", "Music sequences (SPC)"),
		ROMRegion("Sound Effects", 0x058000, 0x060000, "audio", "Sound effect samples"),
		
		# Bank $0c - VBlank/IRQ
		ROMRegion("VBlank Handler", 0x060000, 0x064000, "code", "NMI/IRQ handlers, screen updates"),
		
		# Bank $0d - Save/Load
		ROMRegion("Save System", 0x064000, 0x068000, "code", "Save/load, SRAM handling"),
		
		# Bank $0e-$0f - Additional code/data
		ROMRegion("Additional Code", 0x068000, 0x070000, "code", "Misc game logic"),
		ROMRegion("Additional Data", 0x070000, 0x080000, "data", "Misc data tables"),
		
		# Header
		ROMRegion("ROM Header", 0x007fb0, 0x008000, "data", "SNES ROM header and vectors"),
	]
	
	def __init__(self, original_path: str, built_path: str):
		self.original_path = Path(original_path)
		self.built_path = Path(built_path)
		self.original_data = bytearray()
		self.built_data = bytearray()
		self.diff_blocks = []
		self.stats = {
			'total_bytes': 0,
			'matching_bytes': 0,
			'differing_bytes': 0,
			'match_percentage': 0.0,
			'by_category': {}
		}
		
	def load_roms(self) -> bool:
		"""Load both ROM files"""
		if not self.original_path.exists():
			print(f"ERROR: Original ROM not found: {self.original_path}")
			return False
			
		if not self.built_path.exists():
			print(f"ERROR: Built ROM not found: {self.built_path}")
			return False
			
		with open(self.original_path, 'rb') as f:
			self.original_data = bytearray(f.read())
			
		with open(self.built_path, 'rb') as f:
			self.built_data = bytearray(f.read())
			
		print(f"Loaded original ROM: {len(self.original_data)} bytes")
		print(f"Loaded built ROM:	{len(self.built_data)} bytes")
		
		# Check size mismatch
		if len(self.original_data) != len(self.built_data):
			print(f"\nWARNING: ROM sizes differ!")
			print(f"  Original: {len(self.original_data)} bytes")
			print(f"  Built:	{len(self.built_data)} bytes")
			print(f"  Difference: {abs(len(self.original_data) - len(self.built_data))} bytes")
			
		return True
		
	def compare(self) -> Dict:
		"""Perform byte-by-byte comparison"""
		print("\nComparing ROMs byte-by-byte...")
		
		size = min(len(self.original_data), len(self.built_data))
		self.stats['total_bytes'] = len(self.original_data)
		
		# Find all differing bytes
		diff_start = None
		for i in range(size):
			if self.original_data[i] != self.built_data[i]:
				if diff_start is None:
					diff_start = i
				self.stats['differing_bytes'] += 1
			else:
				if diff_start is not None:
					# End of diff block
					self._add_diff_block(diff_start, i)
					diff_start = None
				self.stats['matching_bytes'] += 1
				
		# Handle diff block at end
		if diff_start is not None:
			self._add_diff_block(diff_start, size)
			
		# Handle size difference
		if len(self.original_data) > len(self.built_data):
			self.stats['differing_bytes'] += len(self.original_data) - len(self.built_data)
		elif len(self.built_data) > len(self.original_data):
			self.stats['differing_bytes'] += len(self.built_data) - len(self.original_data)
			
		# Calculate percentage
		if self.stats['total_bytes'] > 0:
			self.stats['match_percentage'] = (self.stats['matching_bytes'] / self.stats['total_bytes']) * 100
			
		# Calculate by category
		self._calculate_category_stats()
		
		return self.stats
		
	def _add_diff_block(self, start: int, end: int):
		"""Add a difference block"""
		size = end - start
		region = self._find_region(start)
		
		orig_bytes = self.original_data[start:end] if start < len(self.original_data) else b''
		built_bytes = self.built_data[start:end] if start < len(self.built_data) else b''
		
		block = DiffBlock(
			start=start,
			end=end,
			size=size,
			region_name=region.name,
			category=region.category,
			original_bytes=orig_bytes,
			built_bytes=built_bytes
		)
		self.diff_blocks.append(block)
		
	def _find_region(self, address: int) -> ROMRegion:
		"""Find which region an address belongs to"""
		for region in self.REGIONS:
			if region.start <= address < region.end:
				return region
		return ROMRegion("Unknown", address, address + 1, "unknown", "Unidentified region")
		
	def _calculate_category_stats(self):
		"""Calculate statistics by category"""
		categories = {}
		
		for region in self.REGIONS:
			cat = region.category
			if cat not in categories:
				categories[cat] = {
					'total_bytes': 0,
					'matching_bytes': 0,
					'differing_bytes': 0,
					'match_percentage': 0.0
				}
			
			region_size = region.end - region.start
			categories[cat]['total_bytes'] += region_size
			
		# Add bytes from diff blocks
		for block in self.diff_blocks:
			cat = block.category
			if cat in categories:
				categories[cat]['differing_bytes'] += block.size
				
		# Calculate matching bytes and percentages
		for cat, stats in categories.items():
			stats['matching_bytes'] = stats['total_bytes'] - stats['differing_bytes']
			if stats['total_bytes'] > 0:
				stats['match_percentage'] = (stats['matching_bytes'] / stats['total_bytes']) * 100
				
		self.stats['by_category'] = categories
		
	def generate_text_report(self, output_path: str):
		"""Generate human-readable text report"""
		output = Path(output_path)
		output.parent.mkdir(parents=True, exist_ok=True)
		
		with open(output, 'w', encoding='utf-8') as f:
			f.write("=" * 80 + "\n")
			f.write("FFMQ ROM Comparison Report\n")
			f.write("=" * 80 + "\n\n")
			
			f.write(f"Original ROM: {self.original_path}\n")
			f.write(f"Built ROM:	{self.built_path}\n\n")
			
			# Overall stats
			f.write("Overall Statistics:\n")
			f.write("-" * 80 + "\n")
			f.write(f"Total Bytes:	  {self.stats['total_bytes']:>10,}\n")
			f.write(f"Matching Bytes:   {self.stats['matching_bytes']:>10,}\n")
			f.write(f"Differing Bytes:  {self.stats['differing_bytes']:>10,}\n")
			f.write(f"Match Percentage: {self.stats['match_percentage']:>10.2f}%\n\n")
			
			# Category breakdown
			f.write("Statistics by Category:\n")
			f.write("-" * 80 + "\n")
			f.write(f"{'Category':<15} {'Total':<12} {'Matching':<12} {'Differing':<12} {'Match %':<10}\n")
			f.write("-" * 80 + "\n")
			
			for cat, stats in sorted(self.stats['by_category'].items()):
				f.write(f"{cat:<15} "
					   f"{stats['total_bytes']:>11,} "
					   f"{stats['matching_bytes']:>11,} "
					   f"{stats['differing_bytes']:>11,} "
					   f"{stats['match_percentage']:>9.2f}%\n")
					   
			# Difference blocks
			f.write("\n\nDifference Blocks (First 50):\n")
			f.write("-" * 80 + "\n")
			f.write(f"{'Start':<10} {'End':<10} {'Size':<8} {'Region':<25} {'Category':<12}\n")
			f.write("-" * 80 + "\n")
			
			for block in self.diff_blocks[:50]:
				f.write(f"${block.start:06X}   "
					   f"${block.end:06X}   "
					   f"{block.size:>6}   "
					   f"{block.region_name:<25} "
					   f"{block.category:<12}\n")
					   
			if len(self.diff_blocks) > 50:
				f.write(f"\n... and {len(self.diff_blocks) - 50} more difference blocks\n")
				
			# Recommendations
			f.write("\n\nRecommendations:\n")
			f.write("-" * 80 + "\n")
			self._write_recommendations(f)
			
		print(f"\nText report saved: {output}")
		
	def _write_recommendations(self, f):
		"""Write recommendations for what to work on next"""
		# Find category with most differences
		worst_category = None
		worst_diff = 0
		
		for cat, stats in self.stats['by_category'].items():
			if stats['differing_bytes'] > worst_diff:
				worst_diff = stats['differing_bytes']
				worst_category = cat
				
		if worst_category:
			f.write(f"1. Focus on '{worst_category}' category ({worst_diff:,} differing bytes)\n")
			
		# Find largest diff blocks
		if self.diff_blocks:
			largest_blocks = sorted(self.diff_blocks, key=lambda b: b.size, reverse=True)[:5]
			f.write("\n2. Largest difference blocks to investigate:\n")
			for i, block in enumerate(largest_blocks, 1):
				f.write(f"   {i}. ${block.start:06X}-${block.end:06X} ({block.size:,} bytes) - {block.region_name}\n")
				
		# Check if byte-perfect
		if self.stats['match_percentage'] == 100.0:
			f.write("\n✅ BYTE-PERFECT MATCH ACHIEVED!\n")
		elif self.stats['match_percentage'] > 99.0:
			f.write(f"\n⚠️  Almost there! Only {self.stats['differing_bytes']} bytes differ.\n")
		elif self.stats['match_percentage'] > 90.0:
			f.write("\n📊 Good progress. Focus on extracting remaining data structures.\n")
		else:
			f.write("\n🔧 Significant work needed. Ensure all assets are extracted properly.\n")
			
	def generate_json_report(self, output_path: str):
		"""Generate machine-readable JSON report"""
		output = Path(output_path)
		output.parent.mkdir(parents=True, exist_ok=True)
		
		report = {
			'original_rom': str(self.original_path),
			'built_rom': str(self.built_path),
			'statistics': self.stats,
			'difference_blocks': [block.to_dict() for block in self.diff_blocks],
			'regions': [asdict(region) for region in self.REGIONS]
		}
		
		with open(output, 'w', encoding='utf-8') as f:
			json.dump(report, f, indent=2)
			
		print(f"JSON report saved: {output}")
		
	def generate_html_report(self, output_path: str):
		"""Generate visual HTML report"""
		output = Path(output_path)
		output.parent.mkdir(parents=True, exist_ok=True)
		
		html = f"""<!DOCTYPE html>
<html>
<head>
	<title>FFMQ ROM Comparison Report</title>
	<style>
		body {{ font-family: 'Segoe UI', Arial, sans-serif; margin: 20px; background: #f5f5f5; }}
		.container {{ max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }}
		h1 {{ color: #2c3e50; border-bottom: 3px solid #3498db; padding-bottom: 10px; }}
		h2 {{ color: #34495e; margin-top: 30px; }}
		.stats {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 20px; margin: 20px 0; }}
		.stat-box {{ background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; border-radius: 8px; }}
		.stat-box h3 {{ margin: 0 0 10px 0; font-size: 14px; opacity: 0.9; }}
		.stat-box .value {{ font-size: 32px; font-weight: bold; }}
		.progress-bar {{ background: #ecf0f1; height: 30px; border-radius: 15px; overflow: hidden; margin: 20px 0; }}
		.progress-fill {{ background: linear-gradient(90deg, #2ecc71 0%, #27ae60 100%); height: 100%; transition: width 0.3s; display: flex; align-items: center; justify-content: center; color: white; font-weight: bold; }}
		table {{ width: 100%; border-collapse: collapse; margin: 20px 0; }}
		th {{ background: #34495e; color: white; padding: 12px; text-align: left; }}
		td {{ padding: 10px; border-bottom: 1px solid #ecf0f1; }}
		tr:hover {{ background: #f8f9fa; }}
		.category-code {{ color: #3498db; }}
		.category-graphics {{ color: #e74c3c; }}
		.category-text {{ color: #2ecc71; }}
		.category-data {{ color: #f39c12; }}
		.category-audio {{ color: #9b59b6; }}
		.diff-block {{ background: #fff3cd; padding: 5px; margin: 2px 0; border-left: 3px solid #ffc107; }}
	</style>
</head>
<body>
	<div class="container">
		<h1>🎮 Final Fantasy Mystic Quest - ROM Comparison Report</h1>
		
		<p><strong>Original ROM:</strong> {self.original_path.name}</p>
		<p><strong>Built ROM:</strong> {self.built_path.name}</p>
		
		<h2>📊 Overall Progress</h2>
		<div class="progress-bar">
			<div class="progress-fill" style="width: {self.stats['match_percentage']:.2f}%">
				{self.stats['match_percentage']:.2f}% Match
			</div>
		</div>
		
		<div class="stats">
			<div class="stat-box">
				<h3>Total Bytes</h3>
				<div class="value">{self.stats['total_bytes']:,}</div>
			</div>
			<div class="stat-box">
				<h3>Matching Bytes</h3>
				<div class="value">{self.stats['matching_bytes']:,}</div>
			</div>
			<div class="stat-box">
				<h3>Differing Bytes</h3>
				<div class="value">{self.stats['differing_bytes']:,}</div>
			</div>
		</div>
		
		<h2>📂 Statistics by Category</h2>
		<table>
			<tr>
				<th>Category</th>
				<th>Total Bytes</th>
				<th>Matching</th>
				<th>Differing</th>
				<th>Match %</th>
				<th>Progress</th>
			</tr>
"""
		
		for cat, stats in sorted(self.stats['by_category'].items()):
			html += f"""
			<tr>
				<td class="category-{cat}">{cat.upper()}</td>
				<td>{stats['total_bytes']:,}</td>
				<td>{stats['matching_bytes']:,}</td>
				<td>{stats['differing_bytes']:,}</td>
				<td>{stats['match_percentage']:.2f}%</td>
				<td>
					<div style="background: #ecf0f1; height: 20px; border-radius: 10px; overflow: hidden;">
						<div style="background: #2ecc71; width: {stats['match_percentage']:.2f}%; height: 100%;"></div>
					</div>
				</td>
			</tr>
"""
		
		html += """
		</table>
		
		<h2>🔍 Difference Blocks (First 100)</h2>
		<table>
			<tr>
				<th>Address Range</th>
				<th>Size</th>
				<th>Region</th>
				<th>Category</th>
			</tr>
"""
		
		for block in self.diff_blocks[:100]:
			html += f"""
			<tr>
				<td><code>${block.start:06X} - ${block.end:06X}</code></td>
				<td>{block.size:,} bytes</td>
				<td>{block.region_name}</td>
				<td class="category-{block.category}">{block.category}</td>
			</tr>
"""
		
		if len(self.diff_blocks) > 100:
			html += f"""
			<tr>
				<td colspan="4" style="text-align: center; font-style: italic;">
					... and {len(self.diff_blocks) - 100} more difference blocks
				</td>
			</tr>
"""
		
		html += """
		</table>
	</div>
</body>
</html>
"""
		
		with open(output, 'w', encoding='utf-8') as f:
			f.write(html)
			
		print(f"HTML report saved: {output}")


def main():
	if len(sys.argv) < 3:
		print("Usage: rom_compare.py <original_rom> <built_rom> [--report-dir reports/]")
		print("\nCompares original ROM with built ROM and generates detailed reports")
		print("\nReports generated:")
		print("  - comparison.txt  - Human-readable text report")
		print("  - comparison.json - Machine-readable JSON data")
		print("  - comparison.html - Visual HTML report")
		sys.exit(1)
		
	original_rom = sys.argv[1]
	built_rom = sys.argv[2]
	
	report_dir = "reports"
	for i, arg in enumerate(sys.argv):
		if arg == '--report-dir' and i + 1 < len(sys.argv):
			report_dir = sys.argv[i + 1]
			
	print("=" * 80)
	print("Final Fantasy Mystic Quest - ROM Comparator")
	print("=" * 80)
	print()
	
	comparator = ROMComparator(original_rom, built_rom)
	
	if not comparator.load_roms():
		sys.exit(1)
		
	stats = comparator.compare()
	
	print(f"\n{'=' * 80}")
	print("Comparison Results:")
	print(f"{'=' * 80}")
	print(f"Match Percentage: {stats['match_percentage']:.2f}%")
	print(f"Matching Bytes:   {stats['matching_bytes']:,} / {stats['total_bytes']:,}")
	print(f"Differing Bytes:  {stats['differing_bytes']:,}")
	print(f"Diff Blocks:	  {len(comparator.diff_blocks)}")
	
	print(f"\n{'=' * 80}")
	print("Generating reports...")
	print(f"{'=' * 80}")
	
	comparator.generate_text_report(f"{report_dir}/comparison.txt")
	comparator.generate_json_report(f"{report_dir}/comparison.json")
	comparator.generate_html_report(f"{report_dir}/comparison.html")
	
	print(f"\n{'=' * 80}")
	if stats['match_percentage'] == 100.0:
		print("✅ SUCCESS! Byte-perfect match achieved!")
	elif stats['match_percentage'] > 99.0:
		print(f"⚠️  Almost there! Only {stats['differing_bytes']} bytes to go.")
	else:
		print(f"📊 Progress: {stats['match_percentage']:.2f}% complete")
	print(f"{'=' * 80}")


if __name__ == '__main__':
	main()
