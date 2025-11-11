"""
Documentation Coverage Analyzer
Analyzes documentation coverage across the FFMQ project.

Generates reports on:
- Which code files have documentation
- Which systems are documented
- Documentation completeness metrics
- Outdated documentation detection
"""

import os
import re
from pathlib import Path
from datetime import datetime, timedelta
from collections import defaultdict
import json


class DocCoverageAnalyzer:
	"""Analyze documentation coverage across the project."""
	
	def __init__(self, project_root="."):
		self.project_root = Path(project_root)
		self.docs_dir = self.project_root / "docs"
		self.src_dir = self.project_root / "src" / "asm"
		self.tools_dir = self.project_root / "tools"
		
		self.stats = {
			"total_md_files": 0,
			"total_asm_files": 0,
			"total_py_files": 0,
			"documented_functions": 0,
			"undocumented_functions": 0,
			"outdated_docs": [],
			"missing_docs": [],
			"doc_file_sizes": {},
		}
	
	def analyze(self):
		"""Run full documentation coverage analysis."""
		print("=" * 70)
		print("FFMQ DOCUMENTATION COVERAGE ANALYSIS")
		print("=" * 70)
		print()
		
		self.analyze_markdown_files()
		self.analyze_asm_documentation()
		self.analyze_python_documentation()
		self.check_outdated_documentation()
		self.check_missing_documentation()
		
		self.print_report()
		self.save_report()
	
	def analyze_markdown_files(self):
		"""Analyze all markdown documentation files."""
		print("📄 Analyzing Markdown Documentation...")
		
		md_files = list(self.project_root.rglob("*.md"))
		self.stats["total_md_files"] = len(md_files)
		
		for md_file in md_files:
			# Get file size (as proxy for documentation depth)
			size = md_file.stat().st_size
			rel_path = md_file.relative_to(self.project_root)
			self.stats["doc_file_sizes"][str(rel_path)] = size
		
		# Find largest docs
		sorted_docs = sorted(
			self.stats["doc_file_sizes"].items(),
			key=lambda x: x[1],
			reverse=True
		)
		
		print(f"  ✓ Found {len(md_files)} markdown files")
		print(f"  ✓ Top 5 largest docs:")
		for path, size in sorted_docs[:5]:
			print(f"    - {path}: {size:,} bytes")
		print()
	
	def analyze_asm_documentation(self):
		"""Analyze ASM file documentation coverage."""
		print("🔧 Analyzing ASM Documentation...")
		
		if not self.src_dir.exists():
			print("  ⚠ ASM source directory not found")
			return
		
		asm_files = list(self.src_dir.rglob("*.asm"))
		self.stats["total_asm_files"] = len(asm_files)
		
		for asm_file in asm_files:
			content = asm_file.read_text(encoding='utf-8', errors='ignore')
			
			# Count function headers (==== markers)
			documented = len(re.findall(r'; ={50,}', content))
			self.stats["documented_functions"] += documented
			
			# Count potential undocumented functions (labels followed by code)
			# This is a heuristic - not perfect
			labels = len(re.findall(r'^[A-Za-z_][A-Za-z0-9_]*:', content, re.MULTILINE))
			undocumented = max(0, labels - documented)
			self.stats["undocumented_functions"] += undocumented
		
		print(f"  ✓ Analyzed {len(asm_files)} ASM files")
		print(f"  ✓ Documented functions: {self.stats['documented_functions']}")
		print(f"  ✓ Potentially undocumented: {self.stats['undocumented_functions']}")
		print()
	
	def analyze_python_documentation(self):
		"""Analyze Python tool documentation."""
		print("🐍 Analyzing Python Tool Documentation...")
		
		if not self.tools_dir.exists():
			print("  ⚠ Tools directory not found")
			return
		
		py_files = list(self.tools_dir.rglob("*.py"))
		self.stats["total_py_files"] = len(py_files)
		
		documented_tools = 0
		for py_file in py_files:
			try:
				content = py_file.read_text(encoding='utf-8')
				# Check for module docstring
				if re.search(r'^"""[\s\S]+?"""', content, re.MULTILINE):
					documented_tools += 1
			except:
				pass
		
		print(f"  ✓ Found {len(py_files)} Python files")
		print(f"  ✓ Files with docstrings: {documented_tools}/{len(py_files)}")
		print()
	
	def check_outdated_documentation(self):
		"""Find documentation that might be outdated."""
		print("🕒 Checking for Outdated Documentation...")
		
		outdated_threshold = datetime.now() - timedelta(days=90)  # 3 months
		
		for md_file in self.project_root.rglob("*.md"):
			try:
				content = md_file.read_text(encoding='utf-8', errors='ignore')
				
				# Look for "Last Updated:" marker
				match = re.search(r'\*\*Last Updated:\*\*\s*(\d{4}-\d{2}-\d{2})', content)
				if match:
					date_str = match.group(1)
					try:
						doc_date = datetime.strptime(date_str, '%Y-%m-%d')
						if doc_date < outdated_threshold:
							rel_path = md_file.relative_to(self.project_root)
							self.stats["outdated_docs"].append({
								"file": str(rel_path),
								"last_updated": date_str,
								"days_old": (datetime.now() - doc_date).days
							})
					except ValueError:
						pass
			except:
				pass
		
		if self.stats["outdated_docs"]:
			print(f"  ⚠ Found {len(self.stats['outdated_docs'])} potentially outdated docs (>90 days old)")
			for doc in self.stats["outdated_docs"][:5]:
				print(f"    - {doc['file']}: {doc['days_old']} days old")
		else:
			print(f"  ✓ No obviously outdated documentation found")
		print()
	
	def check_missing_documentation(self):
		"""Find systems that might need documentation."""
		print("🔍 Checking for Missing Documentation...")
		
		# Expected documentation files
		expected_docs = [
			"docs/ARCHITECTURE.md",
			"docs/BATTLE_SYSTEM.md",
			"docs/BATTLE_MECHANICS.md",
			"docs/GRAPHICS_SYSTEM.md",
			"docs/TEXT_SYSTEM.md",
			"docs/SOUND_SYSTEM.md",
			"docs/MAP_SYSTEM.md",
			"docs/DATA_STRUCTURES.md",
			"docs/FUNCTION_REFERENCE.md",
			"docs/BUILD_GUIDE.md",
			"docs/MODDING_GUIDE.md",
			"docs/RAM_MAP.md",
			"docs/ROM_DATA_MAP.md",
		]
		
		for expected in expected_docs:
			path = self.project_root / expected
			if not path.exists():
				self.stats["missing_docs"].append(expected)
		
		if self.stats["missing_docs"]:
			print(f"  ⚠ Missing {len(self.stats['missing_docs'])} expected documentation files:")
			for missing in self.stats["missing_docs"]:
				print(f"    - {missing}")
		else:
			print(f"  ✓ All expected documentation files exist")
		print()
	
	def print_report(self):
		"""Print summary report."""
		print("=" * 70)
		print("DOCUMENTATION COVERAGE SUMMARY")
		print("=" * 70)
		print()
		
		print(f"📊 Overall Statistics:")
		print(f"  - Markdown files: {self.stats['total_md_files']}")
		print(f"  - ASM source files: {self.stats['total_asm_files']}")
		print(f"  - Python tool files: {self.stats['total_py_files']}")
		print()
		
		print(f"✍️  Function Documentation:")
		total_funcs = self.stats['documented_functions'] + self.stats['undocumented_functions']
		if total_funcs > 0:
			coverage = (self.stats['documented_functions'] / total_funcs) * 100
			print(f"  - Documented: {self.stats['documented_functions']}/{total_funcs} ({coverage:.1f}%)")
		print()
		
		print(f"⚠️  Issues Found:")
		print(f"  - Outdated docs (>90 days): {len(self.stats['outdated_docs'])}")
		print(f"  - Missing expected docs: {len(self.stats['missing_docs'])}")
		print()
		
		if self.stats["outdated_docs"] or self.stats["missing_docs"]:
			print(f"💡 Recommendations:")
			if self.stats["outdated_docs"]:
				print(f"  - Review and update outdated documentation")
			if self.stats["missing_docs"]:
				print(f"  - Create missing documentation files (see list above)")
			print()
	
	def save_report(self):
		"""Save report to JSON file."""
		report_path = self.project_root / "reports" / "documentation_coverage.json"
		report_path.parent.mkdir(exist_ok=True)
		
		report = {
			"generated": datetime.now().isoformat(),
			"stats": self.stats
		}
		
		with open(report_path, 'w', encoding='utf-8') as f:
			json.dump(report, f, indent=2)
		
		print(f"📄 Full report saved to: {report_path}")
		print()


def main():
	"""Run documentation coverage analysis."""
	analyzer = DocCoverageAnalyzer()
	analyzer.analyze()
	
	return 0


if __name__ == '__main__':
	import sys
	sys.exit(main())
