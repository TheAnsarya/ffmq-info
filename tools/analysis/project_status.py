#!/usr/bin/env python3
"""
FFMQ Project Status Dashboard
Generates a comprehensive project status report
"""

import json
import sys
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Any

class ProjectStatusDashboard:
	"""Generate comprehensive project status report"""

	def __init__(self, project_root: Path = None):
		self.project_root = project_root or Path('.')
		self.status = {}

	def scan_data_extraction(self) -> Dict[str, Any]:
		"""Scan data extraction progress"""
		data_dir = self.project_root / 'data'
		assets_dir = self.project_root / 'assets' / 'data'

		status = {
			'characters': False,
			'enemies': False,
			'items': False,
			'maps': False,
			'text': False,
		}

		stats = {
			'json_files': 0,
			'csv_files': 0,
			'schemas': 0,
		}

		# Check for character data
		if (data_dir / 'characters.json').exists():
			status['characters'] = True
			stats['json_files'] += 1
		if (data_dir / 'characters.csv').exists():
			stats['csv_files'] += 1

		# Check for enemy data
		if (assets_dir / 'enemies.json').exists():
			status['enemies'] = True
			stats['json_files'] += 1
		if (assets_dir / 'enemies.csv').exists():
			stats['csv_files'] += 1

		# Check for item data
		if (assets_dir / 'items.json').exists():
			status['items'] = True
			stats['json_files'] += 1

		# Check for map data
		if (data_dir / 'map_tilemaps.json').exists():
			status['maps'] = True
			stats['json_files'] += 1

		# Check for text data
		if (data_dir / 'text_data.json').exists():
			status['text'] = True
			stats['json_files'] += 1

		# Count schemas
		schema_dir = data_dir / 'schemas'
		if schema_dir.exists():
			stats['schemas'] = len(list(schema_dir.glob('*.json')))

		return {
			'status': status,
			'stats': stats,
			'completion': sum(1 for v in status.values() if v) / len(status) * 100
		}

	def scan_graphics_extraction(self) -> Dict[str, Any]:
		"""Scan graphics extraction progress"""
		assets_dir = self.project_root / 'assets'

		stats = {
			'palettes': 0,
			'sprites': 0,
			'tilesets': 0,
			'png_files': 0,
		}

		# Check palettes
		palette_dir = assets_dir / 'graphics' / 'palettes'
		if palette_dir.exists():
			stats['palettes'] = len(list(palette_dir.glob('*.json')))

		# Check for PNG files
		graphics_dir = assets_dir / 'graphics'
		if graphics_dir.exists():
			stats['png_files'] = len(list(graphics_dir.rglob('*.png')))

		return stats

	def scan_documentation(self) -> Dict[str, Any]:
		"""Scan documentation status"""
		docs_dir = self.project_root / 'docs'

		stats = {
			'total_docs': 0,
			'md_files': 0,
			'size_kb': 0,
		}

		if docs_dir.exists():
			md_files = list(docs_dir.glob('*.md'))
			stats['total_docs'] = len(md_files)
			stats['md_files'] = len(md_files)
			stats['size_kb'] = sum(f.stat().st_size for f in md_files if f.exists()) / 1024

		return stats

	def scan_tools(self) -> Dict[str, Any]:
		"""Scan available tools"""
		tools_dir = self.project_root / 'tools'

		stats = {
			'python_tools': 0,
			'powershell_tools': 0,
			'extraction_tools': 0,
		}

		if tools_dir.exists():
			stats['python_tools'] = len(list(tools_dir.glob('*.py')))
			stats['powershell_tools'] = len(list(tools_dir.glob('*.ps1')))

		extraction_dir = tools_dir / 'extraction'
		if extraction_dir.exists():
			stats['extraction_tools'] = len(list(extraction_dir.glob('*.py')))

		return stats

	def check_build_status(self) -> Dict[str, Any]:
		"""Check build system status"""
		build_dir = self.project_root / 'build'

		status = {
			'can_build': False,
			'rom_exists': False,
			'rom_size': 0,
			'build_scripts': [],
		}

		# Check for build scripts
		if (self.project_root / 'build.ps1').exists():
			status['build_scripts'].append('build.ps1')
			status['can_build'] = True
		if (self.project_root / 'Makefile').exists():
			status['build_scripts'].append('Makefile')

		# Check for built ROM
		if build_dir.exists():
			rom_files = list(build_dir.glob('*.sfc'))
			if rom_files:
				# Find the largest ROM file (likely the main build)
				main_rom = max(rom_files, key=lambda f: f.stat().st_size if f.exists() else 0)
				if main_rom.exists() and main_rom.stat().st_size > 0:
					status['rom_exists'] = True
					status['rom_size'] = main_rom.stat().st_size

		return status

	def scan_assembly_files(self) -> Dict[str, Any]:
		"""Scan assembly source files"""
		src_dir = self.project_root / 'src' / 'asm'

		stats = {
			'total_asm_files': 0,
			'total_lines': 0,
			'banks_documented': 0,
		}

		if src_dir.exists():
			asm_files = list(src_dir.glob('*.asm'))
			stats['total_asm_files'] = len(asm_files)

			# Count documented banks
			stats['banks_documented'] = len(list(src_dir.glob('bank_*_documented.asm')))

			# Count total lines
			for asm_file in asm_files:
				try:
					with open(asm_file, 'r', encoding='utf-8', errors='ignore') as f:
						stats['total_lines'] += len(f.readlines())
				except:
					pass

		return stats

	def generate_report(self) -> str:
		"""Generate formatted status report"""
		report = []

		report.append("=" * 80)
		report.append(" FFMQ Disassembly Project - Status Dashboard")
		report.append("=" * 80)
		report.append(f" Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
		report.append("=" * 80)
		report.append("")

		# Data Extraction Status
		report.append("📦 DATA EXTRACTION")
		report.append("-" * 80)
		data_status = self.scan_data_extraction()
		report.append(f" Overall Completion: {data_status['completion']:.1f}%")
		report.append("")
		report.append(" Component Status:")
		for component, complete in data_status['status'].items():
			status_icon = "✅" if complete else "⏳"
			report.append(f"   {status_icon} {component.capitalize()}")
		report.append("")
		report.append(" Statistics:")
		report.append(f"   JSON files:   {data_status['stats']['json_files']}")
		report.append(f"   CSV files:	{data_status['stats']['csv_files']}")
		report.append(f"   Schemas:	  {data_status['stats']['schemas']}")
		report.append("")

		# Graphics Extraction Status
		report.append("🎨 GRAPHICS EXTRACTION")
		report.append("-" * 80)
		graphics_status = self.scan_graphics_extraction()
		report.append(f" Palettes:	 {graphics_status['palettes']} JSON files")
		report.append(f" PNG graphics: {graphics_status['png_files']} files")
		report.append("")

		# Documentation Status
		report.append("📚 DOCUMENTATION")
		report.append("-" * 80)
		doc_status = self.scan_documentation()
		report.append(f" Markdown docs: {doc_status['md_files']}")
		report.append(f" Total size:	{doc_status['size_kb']:.1f} KB")
		report.append("")

		# Tools Status
		report.append("🔧 TOOLS")
		report.append("-" * 80)
		tools_status = self.scan_tools()
		report.append(f" Python tools:	 {tools_status['python_tools']}")
		report.append(f" PowerShell tools: {tools_status['powershell_tools']}")
		report.append(f" Extraction tools: {tools_status['extraction_tools']}")
		report.append("")

		# Assembly Status
		report.append("💻 ASSEMBLY SOURCE")
		report.append("-" * 80)
		asm_status = self.scan_assembly_files()
		report.append(f" ASM files:		{asm_status['total_asm_files']}")
		report.append(f" Total lines:	  {asm_status['total_lines']:,}")
		report.append(f" Banks documented: {asm_status['banks_documented']}")
		report.append("")

		# Build Status
		report.append("🏗️  BUILD SYSTEM")
		report.append("-" * 80)
		build_status = self.check_build_status()
		can_build_icon = "✅" if build_status['can_build'] else "❌"
		rom_exists_icon = "✅" if build_status['rom_exists'] else "❌"
		report.append(f" {can_build_icon} Build system: {', '.join(build_status['build_scripts']) if build_status['build_scripts'] else 'Not available'}")
		report.append(f" {rom_exists_icon} Built ROM:	{'Available' if build_status['rom_exists'] else 'Not found'}")
		if build_status['rom_exists']:
			report.append(f"	ROM size:	 {build_status['rom_size']:,} bytes ({build_status['rom_size'] / 1024:.1f} KB)")
		report.append("")

		report.append("=" * 80)
		report.append("")

		return "\n".join(report)

def main():
	"""Main entry point"""
	dashboard = ProjectStatusDashboard()
	report = dashboard.generate_report()
	print(report)

	# Optionally save to file
	if len(sys.argv) > 1 and sys.argv[1] == '--save':
		output_file = Path('PROJECT_STATUS.md')
		with open(output_file, 'w', encoding='utf-8') as f:
			f.write(report)
		print(f"Report saved to: {output_file}")

if __name__ == '__main__':
	main()
