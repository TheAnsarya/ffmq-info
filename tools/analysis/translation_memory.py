#!/usr/bin/env python3
"""
Translation Memory Tool - Build translation database from script comparisons
Extracts parallel text segments and exports to industry-standard formats

Features:
- Extract source/target text pairs from parallel scripts
- Build translation memory database
- Export to TMX (Translation Memory eXchange) format
- Export to XLIFF format for CAT tools
- Calculate translation coverage and consistency
- Detect fuzzy matches for reuse
- Support for context preservation
- Terminology extraction
- Translation quality metrics

Supported Export Formats:
- TMX 1.4b (compatible with SDL Trados, memoQ, OmegaT)
- XLIFF 1.2 (compatible with most CAT tools)
- JSON (for custom processing)
- CSV (for spreadsheet review)

Usage:
	python translation_memory.py --source original.txt --target translated.txt
	python translation_memory.py --source en.txt --target ja.txt --export-tmx translation.tmx
	python translation_memory.py --source en.txt --target ja.txt --export-xliff translation.xlf
	python translation_memory.py --source en.txt --target ja.txt --fuzzy-threshold 0.7
	python translation_memory.py --source en.txt --target ja.txt --extract-terms terms.json
"""

import argparse
import re
import json
import csv
import hashlib
from pathlib import Path
from typing import Dict, List, Tuple, Optional, Set
from dataclasses import dataclass, field, asdict
from datetime import datetime
from difflib import SequenceMatcher
from collections import Counter
from xml.etree import ElementTree as ET
from xml.dom import minidom


@dataclass
class TranslationUnit:
	"""A single translation memory unit (source + target pair)"""
	tu_id: str
	source_text: str
	target_text: str
	source_dialog: str
	target_dialog: str
	source_line: int
	target_line: int
	context: str = ""
	creation_date: str = ""
	change_date: str = ""
	translator: str = ""
	quality_score: float = 1.0
	fuzzy_match: bool = False
	notes: str = ""
	
	def __post_init__(self):
		if not self.creation_date:
			self.creation_date = datetime.now().isoformat()
		if not self.tu_id:
			combined = f"{self.source_text}|{self.target_text}"
			self.tu_id = hashlib.md5(combined.encode('utf-8')).hexdigest()[:16]


@dataclass
class TermEntry:
	"""A terminology entry extracted from translations"""
	term_source: str
	term_target: str
	frequency: int
	contexts: List[str] = field(default_factory=list)
	part_of_speech: str = ""
	notes: str = ""


@dataclass
class TranslationMetrics:
	"""Translation quality and coverage metrics"""
	total_segments: int
	translated_segments: int
	fuzzy_matches: int
	exact_matches: int
	coverage_percent: float
	avg_quality_score: float
	consistency_score: float
	terminology_count: int
	
	def __post_init__(self):
		if self.total_segments > 0:
			self.coverage_percent = (self.translated_segments / self.total_segments) * 100
		else:
			self.coverage_percent = 0.0


@dataclass
class TranslationMemory:
	"""Complete translation memory database"""
	source_language: str
	target_language: str
	creation_date: str
	creator: str
	units: List[TranslationUnit]
	terminology: List[TermEntry]
	metrics: TranslationMetrics
	
	def __post_init__(self):
		if not self.creation_date:
			self.creation_date = datetime.now().isoformat()


class TranslationMemoryBuilder:
	"""Build translation memory from parallel scripts"""
	
	# Text normalization patterns
	NORMALIZATION_PATTERNS = [
		(r'\s+', ' '),  # Normalize whitespace
		(r'^\s+|\s+$', ''),  # Trim
	]
	
	# Common words to ignore for terminology extraction
	COMMON_WORDS = {
		'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for',
		'of', 'with', 'by', 'from', 'is', 'are', 'was', 'were', 'be', 'been',
		'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'could',
		'should', 'may', 'might', 'can', 'this', 'that', 'these', 'those'
	}
	
	def __init__(self, source_lang: str = "en", target_lang: str = "ja",
	             fuzzy_threshold: float = 0.8, verbose: bool = False):
		self.source_lang = source_lang
		self.target_lang = target_lang
		self.fuzzy_threshold = fuzzy_threshold
		self.verbose = verbose
		
		self.source_dialogs: Dict[str, List[str]] = {}
		self.target_dialogs: Dict[str, List[str]] = {}
		self.translation_units: List[TranslationUnit] = []
		self.terminology: List[TermEntry] = []
	
	def parse_script_file(self, script_path: Path) -> Dict[str, List[str]]:
		"""Parse script file into dialog dictionary"""
		if self.verbose:
			print(f"Parsing {script_path}...")
		
		dialogs = {}
		
		with open(script_path, 'r', encoding='utf-8') as f:
			content = f.read()
		
		# Split by dialog markers
		dialog_pattern = r'^DIALOG\s+(\S+):(.*?)(?=^DIALOG\s+|\Z)'
		matches = re.finditer(dialog_pattern, content, re.MULTILINE | re.DOTALL)
		
		for match in matches:
			dialog_id = match.group(1)
			dialog_content = match.group(2).strip()
			
			# Extract text lines only (quoted strings)
			text_lines = []
			for line in dialog_content.split('\n'):
				line = line.strip()
				if line.startswith('"') and line.endswith('"'):
					text = line[1:-1]  # Remove quotes
					text_lines.append(text)
			
			dialogs[dialog_id] = text_lines
		
		return dialogs
	
	def normalize_text(self, text: str) -> str:
		"""Normalize text for comparison"""
		for pattern, replacement in self.NORMALIZATION_PATTERNS:
			text = re.sub(pattern, replacement, text)
		return text
	
	def calculate_similarity(self, text1: str, text2: str) -> float:
		"""Calculate similarity ratio between two texts"""
		norm1 = self.normalize_text(text1.lower())
		norm2 = self.normalize_text(text2.lower())
		return SequenceMatcher(None, norm1, norm2).ratio()
	
	def align_dialogs(self) -> None:
		"""Align source and target dialog texts"""
		if self.verbose:
			print(f"\nAligning {len(self.source_dialogs)} source dialogs with {len(self.target_dialogs)} target dialogs...")
		
		aligned_count = 0
		fuzzy_count = 0
		
		for dialog_id in self.source_dialogs:
			if dialog_id not in self.target_dialogs:
				if self.verbose:
					print(f"  Warning: No target for dialog {dialog_id}")
				continue
			
			source_lines = self.source_dialogs[dialog_id]
			target_lines = self.target_dialogs[dialog_id]
			
			# Simple 1:1 alignment (assumes same number of lines)
			if len(source_lines) == len(target_lines):
				for i, (source_text, target_text) in enumerate(zip(source_lines, target_lines)):
					if not source_text.strip() or not target_text.strip():
						continue
					
					# Calculate quality score based on length ratio
					len_ratio = len(target_text) / max(len(source_text), 1)
					quality_score = 1.0 if 0.5 <= len_ratio <= 2.0 else 0.7
					
					tu = TranslationUnit(
						tu_id="",  # Will be auto-generated
						source_text=source_text,
						target_text=target_text,
						source_dialog=dialog_id,
						target_dialog=dialog_id,
						source_line=i,
						target_line=i,
						context=f"Dialog {dialog_id}",
						quality_score=quality_score
					)
					self.translation_units.append(tu)
					aligned_count += 1
			
			# Fuzzy alignment for mismatched line counts
			else:
				if self.verbose:
					print(f"  Fuzzy aligning {dialog_id}: {len(source_lines)} source, {len(target_lines)} target")
				
				# Try to find best matches
				for i, source_text in enumerate(source_lines):
					if not source_text.strip():
						continue
					
					best_match = None
					best_similarity = 0.0
					best_idx = -1
					
					for j, target_text in enumerate(target_lines):
						if not target_text.strip():
							continue
						
						# Use length as a simple heuristic
						len_similarity = 1.0 - abs(len(source_text) - len(target_text)) / max(len(source_text), len(target_text))
						
						if len_similarity > best_similarity:
							best_similarity = len_similarity
							best_match = target_text
							best_idx = j
					
					if best_match and best_similarity >= self.fuzzy_threshold:
						tu = TranslationUnit(
							tu_id="",
							source_text=source_text,
							target_text=best_match,
							source_dialog=dialog_id,
							target_dialog=dialog_id,
							source_line=i,
							target_line=best_idx,
							context=f"Dialog {dialog_id}",
							quality_score=best_similarity,
							fuzzy_match=True,
							notes=f"Fuzzy aligned (similarity: {best_similarity:.2f})"
						)
						self.translation_units.append(tu)
						fuzzy_count += 1
		
		if self.verbose:
			print(f"  Aligned {aligned_count} exact matches, {fuzzy_count} fuzzy matches")
	
	def extract_terminology(self, min_frequency: int = 2) -> None:
		"""Extract terminology from translation pairs"""
		if self.verbose:
			print("\nExtracting terminology...")
		
		# Build word pair frequency
		word_pairs: Dict[Tuple[str, str], List[str]] = {}
		
		for tu in self.translation_units:
			source_words = self._extract_words(tu.source_text)
			target_words = self._extract_words(tu.target_text)
			
			# Simple heuristic: look for capitalized words and unique terms
			for src_word in source_words:
				if len(src_word) < 3:
					continue
				if src_word.lower() in self.COMMON_WORDS:
					continue
				
				# For now, just track source terms
				# More sophisticated alignment would be needed for actual source-target pairs
				for tgt_word in target_words:
					if len(tgt_word) < 2:
						continue
					
					pair = (src_word, tgt_word)
					if pair not in word_pairs:
						word_pairs[pair] = []
					word_pairs[pair].append(tu.context)
		
		# Filter by frequency
		for (src_term, tgt_term), contexts in word_pairs.items():
			if len(contexts) >= min_frequency:
				entry = TermEntry(
					term_source=src_term,
					term_target=tgt_term,
					frequency=len(contexts),
					contexts=list(set(contexts))[:5],  # Keep up to 5 unique contexts
					notes=f"Appears {len(contexts)} times"
				)
				self.terminology.append(entry)
		
		# Sort by frequency
		self.terminology.sort(key=lambda t: t.frequency, reverse=True)
		
		if self.verbose:
			print(f"  Extracted {len(self.terminology)} terminology entries")
	
	def _extract_words(self, text: str) -> List[str]:
		"""Extract words from text"""
		# Simple word extraction
		words = re.findall(r'\b[A-Za-z]+\b', text)
		return [w for w in words if len(w) >= 3]
	
	def calculate_metrics(self) -> TranslationMetrics:
		"""Calculate translation quality metrics"""
		total_source_segments = sum(len(lines) for lines in self.source_dialogs.values())
		translated_segments = len(self.translation_units)
		fuzzy_matches = sum(1 for tu in self.translation_units if tu.fuzzy_match)
		exact_matches = translated_segments - fuzzy_matches
		
		avg_quality = sum(tu.quality_score for tu in self.translation_units) / max(len(self.translation_units), 1)
		
		# Consistency: check for duplicate sources with different targets
		source_to_targets: Dict[str, Set[str]] = {}
		for tu in self.translation_units:
			norm_source = self.normalize_text(tu.source_text)
			if norm_source not in source_to_targets:
				source_to_targets[norm_source] = set()
			source_to_targets[norm_source].add(tu.target_text)
		
		consistent_count = sum(1 for targets in source_to_targets.values() if len(targets) == 1)
		consistency = consistent_count / max(len(source_to_targets), 1)
		
		return TranslationMetrics(
			total_segments=total_source_segments,
			translated_segments=translated_segments,
			fuzzy_matches=fuzzy_matches,
			exact_matches=exact_matches,
			coverage_percent=0.0,  # Will be calculated in __post_init__
			avg_quality_score=avg_quality,
			consistency_score=consistency,
			terminology_count=len(self.terminology)
		)
	
	def build_memory(self, source_path: Path, target_path: Path, creator: str = "TranslationMemoryBuilder") -> TranslationMemory:
		"""Build complete translation memory"""
		# Parse scripts
		self.source_dialogs = self.parse_script_file(source_path)
		self.target_dialogs = self.parse_script_file(target_path)
		
		# Align dialogs
		self.align_dialogs()
		
		# Extract terminology
		self.extract_terminology()
		
		# Calculate metrics
		metrics = self.calculate_metrics()
		
		# Create translation memory
		tm = TranslationMemory(
			source_language=self.source_lang,
			target_language=self.target_lang,
			creation_date=datetime.now().isoformat(),
			creator=creator,
			units=self.translation_units,
			terminology=self.terminology,
			metrics=metrics
		)
		
		return tm
	
	def export_tmx(self, tm: TranslationMemory, output_path: Path) -> None:
		"""Export to TMX 1.4b format"""
		if self.verbose:
			print(f"\nExporting to TMX format: {output_path}")
		
		# Create TMX structure
		tmx = ET.Element('tmx', version="1.4")
		header = ET.SubElement(tmx, 'header', {
			'creationtool': 'TranslationMemoryBuilder',
			'creationtoolversion': '1.0',
			'datatype': 'plaintext',
			'segtype': 'sentence',
			'adminlang': tm.source_language,
			'srclang': tm.source_language,
			'o-tmf': 'unknown',
			'creationdate': tm.creation_date
		})
		
		body = ET.SubElement(tmx, 'body')
		
		for tu_obj in tm.units:
			tu = ET.SubElement(body, 'tu', {
				'tuid': tu_obj.tu_id,
				'creationdate': tu_obj.creation_date,
				'creationid': tm.creator
			})
			
			if tu_obj.context:
				prop = ET.SubElement(tu, 'prop', type='context')
				prop.text = tu_obj.context
			
			# Source segment
			tuv_src = ET.SubElement(tu, 'tuv', {
				'xml:lang': tm.source_language
			})
			seg_src = ET.SubElement(tuv_src, 'seg')
			seg_src.text = tu_obj.source_text
			
			# Target segment
			tuv_tgt = ET.SubElement(tu, 'tuv', {
				'xml:lang': tm.target_language
			})
			seg_tgt = ET.SubElement(tuv_tgt, 'seg')
			seg_tgt.text = tu_obj.target_text
		
		# Pretty print
		xml_str = ET.tostring(tmx, encoding='utf-8')
		dom = minidom.parseString(xml_str)
		pretty_xml = dom.toprettyxml(indent='  ', encoding='utf-8')
		
		with open(output_path, 'wb') as f:
			f.write(pretty_xml)
		
		if self.verbose:
			print(f"  Exported {len(tm.units)} translation units to TMX")
	
	def export_xliff(self, tm: TranslationMemory, output_path: Path) -> None:
		"""Export to XLIFF 1.2 format"""
		if self.verbose:
			print(f"\nExporting to XLIFF format: {output_path}")
		
		xliff = ET.Element('xliff', {
			'version': '1.2',
			'xmlns': 'urn:oasis:names:tc:xliff:document:1.2'
		})
		
		file_elem = ET.SubElement(xliff, 'file', {
			'source-language': tm.source_language,
			'target-language': tm.target_language,
			'datatype': 'plaintext',
			'original': 'translation_memory'
		})
		
		header = ET.SubElement(file_elem, 'header')
		body = ET.SubElement(file_elem, 'body')
		
		for tu_obj in tm.units:
			trans_unit = ET.SubElement(body, 'trans-unit', {
				'id': tu_obj.tu_id
			})
			
			source = ET.SubElement(trans_unit, 'source')
			source.text = tu_obj.source_text
			
			target = ET.SubElement(trans_unit, 'target')
			target.text = tu_obj.target_text
			
			if tu_obj.context:
				context_group = ET.SubElement(trans_unit, 'context-group', {
					'purpose': 'location'
				})
				context = ET.SubElement(context_group, 'context', {
					'context-type': 'sourcefile'
				})
				context.text = tu_obj.context
		
		# Pretty print
		xml_str = ET.tostring(xliff, encoding='utf-8')
		dom = minidom.parseString(xml_str)
		pretty_xml = dom.toprettyxml(indent='  ', encoding='utf-8')
		
		with open(output_path, 'wb') as f:
			f.write(pretty_xml)
		
		if self.verbose:
			print(f"  Exported {len(tm.units)} translation units to XLIFF")
	
	def export_json(self, tm: TranslationMemory, output_path: Path) -> None:
		"""Export to JSON format"""
		data = {
			'source_language': tm.source_language,
			'target_language': tm.target_language,
			'creation_date': tm.creation_date,
			'creator': tm.creator,
			'metrics': asdict(tm.metrics),
			'units': [asdict(tu) for tu in tm.units],
			'terminology': [asdict(term) for term in tm.terminology]
		}
		
		with open(output_path, 'w', encoding='utf-8') as f:
			json.dump(data, f, indent=2, ensure_ascii=False)
		
		if self.verbose:
			print(f"\nExported to JSON: {output_path}")
	
	def export_csv(self, tm: TranslationMemory, output_path: Path) -> None:
		"""Export to CSV format"""
		with open(output_path, 'w', newline='', encoding='utf-8') as f:
			writer = csv.writer(f)
			writer.writerow([
				'ID', 'Source', 'Target', 'Context', 'Quality', 'Fuzzy', 'Notes'
			])
			
			for tu in tm.units:
				writer.writerow([
					tu.tu_id,
					tu.source_text,
					tu.target_text,
					tu.context,
					f"{tu.quality_score:.2f}",
					'Yes' if tu.fuzzy_match else 'No',
					tu.notes
				])
		
		if self.verbose:
			print(f"\nExported to CSV: {output_path}")
	
	def export_terminology_csv(self, tm: TranslationMemory, output_path: Path) -> None:
		"""Export terminology to CSV"""
		with open(output_path, 'w', newline='', encoding='utf-8') as f:
			writer = csv.writer(f)
			writer.writerow(['Source Term', 'Target Term', 'Frequency', 'Contexts'])
			
			for term in tm.terminology:
				contexts_str = '; '.join(term.contexts[:3])
				writer.writerow([
					term.term_source,
					term.term_target,
					term.frequency,
					contexts_str
				])
		
		if self.verbose:
			print(f"\nExported terminology to CSV: {output_path}")
	
	def generate_report(self, tm: TranslationMemory) -> str:
		"""Generate translation memory report"""
		lines = [
			"# Translation Memory Report",
			"",
			"## Overview",
			f"- **Source Language**: {tm.source_language}",
			f"- **Target Language**: {tm.target_language}",
			f"- **Creation Date**: {tm.creation_date}",
			f"- **Creator**: {tm.creator}",
			"",
			"## Statistics",
			f"- **Total Source Segments**: {tm.metrics.total_segments:,}",
			f"- **Translated Segments**: {tm.metrics.translated_segments:,}",
			f"- **Coverage**: {tm.metrics.coverage_percent:.1f}%",
			f"- **Exact Matches**: {tm.metrics.exact_matches:,}",
			f"- **Fuzzy Matches**: {tm.metrics.fuzzy_matches:,}",
			f"- **Average Quality Score**: {tm.metrics.avg_quality_score:.2f}",
			f"- **Consistency Score**: {tm.metrics.consistency_score:.2%}",
			f"- **Terminology Entries**: {tm.metrics.terminology_count:,}",
			"",
			"## Quality Assessment",
			""
		]
		
		# Quality distribution
		quality_ranges = {
			'Excellent (1.0)': sum(1 for tu in tm.units if tu.quality_score == 1.0),
			'Good (0.8-0.99)': sum(1 for tu in tm.units if 0.8 <= tu.quality_score < 1.0),
			'Fair (0.6-0.79)': sum(1 for tu in tm.units if 0.6 <= tu.quality_score < 0.8),
			'Poor (<0.6)': sum(1 for tu in tm.units if tu.quality_score < 0.6)
		}
		
		for quality_range, count in quality_ranges.items():
			percent = (count / max(len(tm.units), 1)) * 100
			lines.append(f"- **{quality_range}**: {count} ({percent:.1f}%)")
		
		lines.extend([
			"",
			"## Top Terminology (by frequency)",
			""
		])
		
		for i, term in enumerate(tm.terminology[:20], 1):
			lines.append(f"{i}. **{term.term_source}** → **{term.term_target}** ({term.frequency} occurrences)")
		
		lines.extend([
			"",
			"## Sample Translations",
			""
		])
		
		# Show high-quality samples
		high_quality = [tu for tu in tm.units if tu.quality_score >= 0.9][:10]
		for i, tu in enumerate(high_quality, 1):
			lines.extend([
				f"### Example {i}",
				f"- **Source**: {tu.source_text}",
				f"- **Target**: {tu.target_text}",
				f"- **Context**: {tu.context}",
				f"- **Quality**: {tu.quality_score:.2f}",
				""
			])
		
		return '\n'.join(lines)


def main():
	parser = argparse.ArgumentParser(description='Build translation memory from parallel scripts')
	parser.add_argument('--source', type=Path, required=True, help='Source language script file')
	parser.add_argument('--target', type=Path, required=True, help='Target language script file')
	parser.add_argument('--source-lang', default='en', help='Source language code (default: en)')
	parser.add_argument('--target-lang', default='ja', help='Target language code (default: ja)')
	parser.add_argument('--export-tmx', type=Path, help='Export to TMX file')
	parser.add_argument('--export-xliff', type=Path, help='Export to XLIFF file')
	parser.add_argument('--export-json', type=Path, help='Export to JSON file')
	parser.add_argument('--export-csv', type=Path, help='Export to CSV file')
	parser.add_argument('--extract-terms', type=Path, help='Extract terminology to CSV file')
	parser.add_argument('--report', type=Path, help='Generate analysis report')
	parser.add_argument('--fuzzy-threshold', type=float, default=0.8, help='Fuzzy match threshold (0.0-1.0)')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	builder = TranslationMemoryBuilder(
		source_lang=args.source_lang,
		target_lang=args.target_lang,
		fuzzy_threshold=args.fuzzy_threshold,
		verbose=args.verbose
	)
	
	# Build translation memory
	tm = builder.build_memory(args.source, args.target)
	
	# Export to requested formats
	if args.export_tmx:
		builder.export_tmx(tm, args.export_tmx)
	
	if args.export_xliff:
		builder.export_xliff(tm, args.export_xliff)
	
	if args.export_json:
		builder.export_json(tm, args.export_json)
	
	if args.export_csv:
		builder.export_csv(tm, args.export_csv)
	
	if args.extract_terms:
		builder.export_terminology_csv(tm, args.extract_terms)
	
	if args.report:
		report = builder.generate_report(tm)
		with open(args.report, 'w', encoding='utf-8') as f:
			f.write(report)
		if args.verbose:
			print(f"\nReport saved to {args.report}")
	
	# Print summary
	print(f"\n✓ Translation memory built successfully")
	print(f"  Source: {args.source} ({args.source_lang})")
	print(f"  Target: {args.target} ({args.target_lang})")
	print(f"  Translation units: {len(tm.units):,}")
	print(f"  Coverage: {tm.metrics.coverage_percent:.1f}%")
	print(f"  Quality: {tm.metrics.avg_quality_score:.2f}")
	print(f"  Consistency: {tm.metrics.consistency_score:.2%}")
	print(f"  Terminology: {len(tm.terminology):,} entries")
	
	return 0


if __name__ == '__main__':
	exit(main())
