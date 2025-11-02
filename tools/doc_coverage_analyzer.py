#!/usr/bin/env python3
"""
Documentation Coverage Analyzer
Analyzes which game systems are documented vs undocumented
"""

import re
from pathlib import Path
from typing import Dict, List, Tuple, Set
from datetime import datetime

class DocumentationCoverageAnalyzer:
	"""Analyze documentation coverage across the project"""
	
	# Known game systems to track
	GAME_SYSTEMS = {
		'Battle System': ['BATTLE', 'COMBAT', 'ENEMY', 'ENCOUNTER'],
		'Graphics System': ['GRAPHICS', 'SPRITE', 'TILE', 'PALETTE', 'PPU', 'OAM'],
		'Map System': ['MAP', 'COLLISION', 'TRIGGER', 'WARP', 'CHEST'],
		'Text System': ['TEXT', 'DIALOG', 'MESSAGE', 'STRING', 'FONT'],
		'Sound System': ['SOUND', 'MUSIC', 'SPC', 'APU', 'AUDIO'],
		'Menu System': ['MENU', 'INVENTORY', 'STATUS', 'EQUIPMENT'],
		'Save System': ['SAVE', 'SRAM', 'BATTERY'],
		'Character System': ['CHARACTER', 'STATS', 'LEVEL', 'GROWTH', 'PARTY'],
		'Item System': ['ITEM', 'WEAPON', 'ARMOR', 'CONSUMABLE'],
		'Spell System': ['SPELL', 'MAGIC', 'ABILITY'],
		'AI System': ['AI', 'BEHAVIOR', 'PATTERN'],
		'Overworld System': ['OVERWORLD', 'WORLD MAP', 'TRAVEL'],
		'Cutscene System': ['CUTSCENE', 'EVENT', 'SCRIPT'],
		'Boot/Init System': ['BOOT', 'INIT', 'STARTUP', 'RESET'],
		'Input System': ['INPUT', 'CONTROLLER', 'JOYPAD'],
		'DMA/Transfer System': ['DMA', 'HDMA', 'TRANSFER', 'VRAM'],
		'RAM Management': ['RAM', 'MEMORY', 'VARIABLE', 'BUFFER'],
	}
	
	def __init__(self, project_root: str = "."):
		self.project_root = Path(project_root)
		self.docs_dir = self.project_root / 'docs'
		
	def scan_documentation(self) -> Dict[str, List[Path]]:
		"""Scan all documentation files"""
		if not self.docs_dir.exists():
			print(f"⚠️  Documentation directory not found: {self.docs_dir}")
			return {}
			
		# Find all markdown files
		md_files = list(self.docs_dir.rglob('*.md'))
		
		# Filter out backup files
		md_files = [f for f in md_files if not f.name.endswith('.bak')]
		
		return {str(f.relative_to(self.docs_dir)): f for f in md_files}
	
	def analyze_system_coverage(self) -> Dict[str, Dict]:
		"""Analyze which systems are documented"""
		docs = self.scan_documentation()
		
		coverage = {}
		
		for system_name, keywords in self.GAME_SYSTEMS.items():
			# Find docs that mention this system
			relevant_docs = []
			
			for doc_name, doc_path in docs.items():
				try:
					content = doc_path.read_text(encoding='utf-8').upper()
					
					# Check if any keywords appear
					for keyword in keywords:
						if keyword in content:
							relevant_docs.append(doc_name)
							break
							
				except Exception as e:
					print(f"⚠️  Error reading {doc_path}: {e}")
					continue
			
			coverage[system_name] = {
				'docs': relevant_docs,
				'count': len(relevant_docs),
				'covered': len(relevant_docs) > 0
			}
		
		return coverage
	
	def analyze_doc_freshness(self) -> Dict[str, Dict]:
		"""Check when docs were last modified"""
		docs = self.scan_documentation()
		
		freshness = {}
		
		for doc_name, doc_path in docs.items():
			try:
				stat = doc_path.stat()
				mtime = datetime.fromtimestamp(stat.st_mtime)
				age_days = (datetime.now() - mtime).days
				
				freshness[doc_name] = {
					'modified': mtime.strftime('%Y-%m-%d'),
					'age_days': age_days,
					'size': stat.st_size,
				}
				
			except Exception as e:
				print(f"⚠️  Error checking {doc_path}: {e}")
				continue
		
		return freshness
	
	def find_undocumented_banks(self) -> List[str]:
		"""Find ROM banks that lack documentation"""
		# Check which banks have documented ASM files
		bank_docs = set()
		
		# Scan docs for bank references
		docs = self.scan_documentation()
		bank_pattern = re.compile(r'\bBANK[_\s]+([0-9A-F]{2})\b', re.IGNORECASE)
		
		for doc_path in docs.values():
			try:
				content = doc_path.read_text(encoding='utf-8')
				matches = bank_pattern.findall(content)
				bank_docs.update(m.upper() for m in matches)
			except:
				continue
		
		# Scan ASM files for bank files
		asm_banks = set()
		asm_dir = self.project_root / 'src' / 'asm'
		
		if asm_dir.exists():
			bank_file_pattern = re.compile(r'bank[_\s]*([0-9A-F]{2})', re.IGNORECASE)
			
			for asm_file in asm_dir.rglob('*.asm'):
				match = bank_file_pattern.search(asm_file.name)
				if match:
					asm_banks.add(match.group(1).upper())
		
		# Find undocumented banks
		undocumented = sorted(asm_banks - bank_docs)
		
		return undocumented
	
	def generate_report(self, save_to_file: bool = False) -> str:
		"""Generate comprehensive documentation coverage report"""
		lines = []
		lines.append("="*80)
		lines.append(" Documentation Coverage Analysis")
		lines.append("="*80)
		lines.append("")
		
		# Overall stats
		docs = self.scan_documentation()
		lines.append("📚 DOCUMENTATION OVERVIEW")
		lines.append("─"*80)
		lines.append(f"  Total Documentation Files: {len(docs)}")
		
		# Calculate total size
		total_size = 0
		for doc_path in docs.values():
			try:
				total_size += doc_path.stat().st_size
			except:
				continue
		
		lines.append(f"  Total Size: {total_size / 1024:.1f} KB")
		lines.append("")
		
		# System coverage
		coverage = self.analyze_system_coverage()
		
		lines.append("🎮 GAME SYSTEM COVERAGE")
		lines.append("─"*80)
		
		covered_systems = sum(1 for s in coverage.values() if s['covered'])
		total_systems = len(coverage)
		coverage_percent = (covered_systems / total_systems * 100) if total_systems > 0 else 0
		
		lines.append(f"  Coverage: {covered_systems}/{total_systems} systems ({coverage_percent:.1f}%)")
		lines.append("")
		
		# Documented systems
		lines.append("✅ DOCUMENTED SYSTEMS:")
		for system_name, data in sorted(coverage.items()):
			if data['covered']:
				lines.append(f"  {system_name}: {data['count']} doc(s)")
				for doc in data['docs'][:3]:  # Show first 3
					lines.append(f"    - {doc}")
				if len(data['docs']) > 3:
					lines.append(f"    ... and {len(data['docs']) - 3} more")
		lines.append("")
		
		# Undocumented systems
		undocumented = [name for name, data in coverage.items() if not data['covered']]
		if undocumented:
			lines.append("❌ UNDOCUMENTED SYSTEMS:")
			for system_name in undocumented:
				lines.append(f"  - {system_name}")
			lines.append("")
		
		# Bank coverage
		undocumented_banks = self.find_undocumented_banks()
		if undocumented_banks:
			lines.append("🏦 UNDOCUMENTED BANKS")
			lines.append("─"*80)
			lines.append(f"  Found {len(undocumented_banks)} bank(s) with no documentation:")
			for bank in undocumented_banks:
				lines.append(f"    Bank ${bank}")
			lines.append("")
		
		# Document freshness
		freshness = self.analyze_doc_freshness()
		
		# Find stale docs (>30 days old)
		stale_docs = [(name, data) for name, data in freshness.items() 
					  if data['age_days'] > 30]
		stale_docs.sort(key=lambda x: x[1]['age_days'], reverse=True)
		
		if stale_docs:
			lines.append("📅 STALE DOCUMENTATION (>30 days old)")
			lines.append("─"*80)
			lines.append(f"  Found {len(stale_docs)} stale document(s):")
			for doc_name, data in stale_docs[:10]:  # Show top 10 oldest
				lines.append(f"  {doc_name}")
				lines.append(f"    Last modified: {data['modified']} ({data['age_days']} days ago)")
			if len(stale_docs) > 10:
				lines.append(f"  ... and {len(stale_docs) - 10} more")
			lines.append("")
		
		# Recent docs (<7 days old)
		recent_docs = [(name, data) for name, data in freshness.items() 
					   if data['age_days'] < 7]
		recent_docs.sort(key=lambda x: x[1]['age_days'])
		
		if recent_docs:
			lines.append("🆕 RECENT DOCUMENTATION (<7 days old)")
			lines.append("─"*80)
			for doc_name, data in recent_docs[:10]:
				lines.append(f"  {doc_name} (modified {data['modified']})")
			if len(recent_docs) > 10:
				lines.append(f"  ... and {len(recent_docs) - 10} more")
			lines.append("")
		
		# Recommendations
		lines.append("💡 RECOMMENDATIONS")
		lines.append("─"*80)
		
		if undocumented:
			lines.append("  Priority: Document the following systems:")
			for system in undocumented[:5]:
				lines.append(f"    - {system}")
		
		if undocumented_banks:
			lines.append(f"  Priority: Document {len(undocumented_banks)} bank(s) with ASM files")
		
		if len(stale_docs) > 5:
			lines.append(f"  Consider: Review and update {len(stale_docs)} stale documents")
		
		lines.append("")
		lines.append("="*80)
		
		report = '\n'.join(lines)
		
		# Save to file if requested
		if save_to_file:
			output_path = self.project_root / 'reports' / 'documentation_coverage.txt'
			output_path.parent.mkdir(parents=True, exist_ok=True)
			output_path.write_text(report, encoding='utf-8')
			print(f"\n💾 Report saved to: {output_path}")
		
		return report

def main():
	"""Main entry point"""
	import sys
	
	save_to_file = '--save' in sys.argv
	
	analyzer = DocumentationCoverageAnalyzer()
	report = analyzer.generate_report(save_to_file=save_to_file)
	print(report)

if __name__ == '__main__':
	main()
