"""
Dialog Translation Helper - Tools for translating FFMQ dialogs

Features:
- Side-by-side comparison of original and translated text
- Translation memory (remembers previously translated phrases)
- Glossary management for consistent terminology
- Character limit warnings
- Translation progress tracking
"""

import json
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass, field
from pathlib import Path
from datetime import datetime


@dataclass
class TranslationEntry:
	"""Represents a translation entry"""
	dialog_id: int
	original_text: str
	translated_text: str
	status: str = "draft"  # draft, review, approved
	translator: str = ""
	reviewer: str = ""
	notes: str = ""
	timestamp: str = field(default_factory=lambda: datetime.now().isoformat())

	# Validation
	fits_limit: bool = True
	encoding_valid: bool = True
	warnings: List[str] = field(default_factory=list)


@dataclass
class GlossaryEntry:
	"""Term in the translation glossary"""
	source_term: str
	target_term: str
	category: str = "general"  # general, character, place, item, spell, etc.
	notes: str = ""
	mandatory: bool = False  # Must use this translation


class TranslationMemory:
	"""Stores and suggests previously translated phrases"""

	def __init__(self):
		self.memory: Dict[str, str] = {}  # source -> target
		self.usage_count: Dict[str, int] = {}  # Track usage frequency

	def add(self, source: str, target: str):
		"""Add a translation to memory"""
		# Normalize
		source_norm = source.lower().strip()

		self.memory[source_norm] = target
		self.usage_count[source_norm] = self.usage_count.get(source_norm, 0) + 1

	def get(self, source: str) -> Optional[str]:
		"""Get translation from memory"""
		source_norm = source.lower().strip()
		return self.memory.get(source_norm)

	def find_similar(self, source: str, max_results: int = 5) -> List[Tuple[str, str, float]]:
		"""
		Find similar phrases in translation memory

		Returns:
			List of (source, target, similarity_score) tuples
		"""
		source_norm = source.lower().strip()
		source_words = set(source_norm.split())

		results = []

		for mem_source, mem_target in self.memory.items():
			mem_words = set(mem_source.split())

			# Calculate Jaccard similarity
			intersection = len(source_words & mem_words)
			union = len(source_words | mem_words)
			similarity = intersection / union if union > 0 else 0.0

			if similarity > 0.3:  # Threshold
				results.append((mem_source, mem_target, similarity))

		# Sort by similarity
		results.sort(key=lambda x: x[2], reverse=True)

		return results[:max_results]

	def get_most_used(self, n: int = 10) -> List[Tuple[str, str, int]]:
		"""Get most frequently used translations"""
		sorted_by_usage = sorted(
			[(src, tgt, self.usage_count.get(src, 0)) for src, tgt in self.memory.items()],
			key=lambda x: x[2],
			reverse=True
		)
		return sorted_by_usage[:n]


class TranslationGlossary:
	"""Manages consistent terminology for translation"""

	def __init__(self):
		self.entries: List[GlossaryEntry] = []
		self.categories = set()

	def add_entry(self, entry: GlossaryEntry):
		"""Add glossary entry"""
		self.entries.append(entry)
		self.categories.add(entry.category)

	def find_term(self, text: str) -> List[GlossaryEntry]:
		"""Find glossary entries that appear in text"""
		text_lower = text.lower()
		matches = []

		for entry in self.entries:
			if entry.source_term.lower() in text_lower:
				matches.append(entry)

		return matches

	def get_by_category(self, category: str) -> List[GlossaryEntry]:
		"""Get all entries in a category"""
		return [e for e in self.entries if e.category == category]

	def validate_translation(self, original: str, translated: str) -> List[str]:
		"""
		Validate that translation uses correct glossary terms

		Returns:
			List of warnings
		"""
		warnings = []

		# Find terms in original
		original_terms = self.find_term(original)

		for term in original_terms:
			if term.mandatory:
				# Check if target term is in translation
				if term.target_term.lower() not in translated.lower():
					warnings.append(
						f"Missing mandatory term: '{term.source_term}' should be translated as '{term.target_term}'"
					)

		return warnings

	def export_to_csv(self, filepath: str):
		"""Export glossary to CSV file"""
		import csv

		with open(filepath, 'w', newline='', encoding='utf-8') as f:
			writer = csv.writer(f)
			writer.writerow(['Source', 'Target', 'Category', 'Mandatory', 'Notes'])

			for entry in sorted(self.entries, key=lambda e: (e.category, e.source_term)):
				writer.writerow([
					entry.source_term,
					entry.target_term,
					entry.category,
					'Yes' if entry.mandatory else 'No',
					entry.notes
				])

	def import_from_csv(self, filepath: str):
		"""Import glossary from CSV file"""
		import csv

		self.entries.clear()
		self.categories.clear()

		with open(filepath, 'r', encoding='utf-8') as f:
			reader = csv.DictReader(f)
			for row in reader:
				entry = GlossaryEntry(
					source_term=row['Source'],
					target_term=row['Target'],
					category=row.get('Category', 'general'),
					mandatory=row.get('Mandatory', 'No').lower() == 'yes',
					notes=row.get('Notes', '')
				)
				self.add_entry(entry)


class TranslationProject:
	"""Manages a complete translation project"""

	def __init__(self, name: str = "FFMQ Translation"):
		self.name = name
		self.translations: Dict[int, TranslationEntry] = {}
		self.memory = TranslationMemory()
		self.glossary = TranslationGlossary()
		self.source_language = "English"
		self.target_language = "Unknown"

	def add_translation(self, entry: TranslationEntry):
		"""Add or update a translation"""
		self.translations[entry.dialog_id] = entry

		# Update translation memory with phrases
		if entry.status in ["review", "approved"]:
			# Extract sentences
			import re
			sentences = re.split(r'[.!?]+', entry.original_text)
			translated_sentences = re.split(r'[.!?]+', entry.translated_text)

			for src, tgt in zip(sentences, translated_sentences):
				src = src.strip()
				tgt = tgt.strip()
				if src and tgt:
					self.memory.add(src, tgt)

	def get_progress(self) -> Dict[str, int]:
		"""Get translation progress statistics"""
		total = len(self.translations)

		status_counts = {
			'draft': 0,
			'review': 0,
			'approved': 0,
			'untranslated': 0
		}

		for entry in self.translations.values():
			if not entry.translated_text:
				status_counts['untranslated'] += 1
			else:
				status_counts[entry.status] += 1

		percent_complete = (status_counts['approved'] / total * 100) if total > 0 else 0

		return {
			'total': total,
			'draft': status_counts['draft'],
			'review': status_counts['review'],
			'approved': status_counts['approved'],
			'untranslated': status_counts['untranslated'],
			'percent_complete': percent_complete
		}

	def get_next_untranslated(self) -> Optional[int]:
		"""Get the next dialog ID that needs translation"""
		for dialog_id, entry in sorted(self.translations.items()):
			if not entry.translated_text:
				return dialog_id
		return None

	def save(self, filepath: str):
		"""Save project to JSON file"""
		data = {
			'name': self.name,
			'source_language': self.source_language,
			'target_language': self.target_language,
			'translations': [
				{
					'dialog_id': e.dialog_id,
					'original_text': e.original_text,
					'translated_text': e.translated_text,
					'status': e.status,
					'translator': e.translator,
					'reviewer': e.reviewer,
					'notes': e.notes,
					'timestamp': e.timestamp,
					'fits_limit': e.fits_limit,
					'encoding_valid': e.encoding_valid,
					'warnings': e.warnings
				}
				for e in self.translations.values()
			],
			'memory': list(self.memory.memory.items()),
			'glossary': [
				{
					'source_term': e.source_term,
					'target_term': e.target_term,
					'category': e.category,
					'notes': e.notes,
					'mandatory': e.mandatory
				}
				for e in self.glossary.entries
			]
		}

		with open(filepath, 'w', encoding='utf-8') as f:
			json.dump(data, f, indent=2, ensure_ascii=False)

	def load(self, filepath: str):
		"""Load project from JSON file"""
		with open(filepath, 'r', encoding='utf-8') as f:
			data = json.load(f)

		self.name = data.get('name', 'Translation Project')
		self.source_language = data.get('source_language', 'English')
		self.target_language = data.get('target_language', 'Unknown')

		# Load translations
		self.translations.clear()
		for t in data.get('translations', []):
			entry = TranslationEntry(
				dialog_id=t['dialog_id'],
				original_text=t['original_text'],
				translated_text=t['translated_text'],
				status=t.get('status', 'draft'),
				translator=t.get('translator', ''),
				reviewer=t.get('reviewer', ''),
				notes=t.get('notes', ''),
				timestamp=t.get('timestamp', ''),
				fits_limit=t.get('fits_limit', True),
				encoding_valid=t.get('encoding_valid', True),
				warnings=t.get('warnings', [])
			)
			self.translations[entry.dialog_id] = entry

		# Load memory
		self.memory.memory.clear()
		for src, tgt in data.get('memory', []):
			self.memory.add(src, tgt)

		# Load glossary
		self.glossary.entries.clear()
		for g in data.get('glossary', []):
			entry = GlossaryEntry(
				source_term=g['source_term'],
				target_term=g['target_term'],
				category=g.get('category', 'general'),
				notes=g.get('notes', ''),
				mandatory=g.get('mandatory', False)
			)
			self.glossary.add_entry(entry)


def demo_translation():
	"""Demo the translation system"""

	# Create project
	project = TranslationProject("FFMQ Spanish Translation")
	project.source_language = "English"
	project.target_language = "Spanish"

	# Add glossary terms
	project.glossary.add_entry(GlossaryEntry(
		"Crystal", "Cristal", "item", mandatory=True
	))
	project.glossary.add_entry(GlossaryEntry(
		"Foresta", "Foresta", "place", mandatory=True,
		notes="Keep original name"
	))

	# Add translations
	entry1 = TranslationEntry(
		dialog_id=0x0001,
		original_text="Welcome to Foresta! The Crystal awaits.",
		translated_text="¡Bienvenido a Foresta! El Cristal te espera.",
		status="approved",
		translator="Alice"
	)
	project.add_translation(entry1)

	entry2 = TranslationEntry(
		dialog_id=0x0002,
		original_text="The Crystal of Light is very powerful.",
		translated_text="El Cristal de Luz es muy poderoso.",
		status="review",
		translator="Bob"
	)
	project.add_translation(entry2)

	# Check progress
	print("Translation Progress:")
	progress = project.get_progress()
	for key, value in progress.items():
		print(f"  {key}: {value}")

	# Test translation memory
	print("\nTranslation Memory Suggestions for 'The Crystal':")
	suggestions = project.memory.find_similar("The Crystal")
	for src, tgt, score in suggestions:
		print(f"  '{src}' → '{tgt}' (similarity: {score:.2f})")

	# Test glossary validation
	print("\nGlossary Validation:")
	bad_translation = "The Gem of Light is powerful."
	warnings = project.glossary.validate_translation(entry2.original_text, bad_translation)
	for warning in warnings:
		print(f"  ⚠ {warning}")

	# Save project
	project.save("demo_translation.json")
	print("\nProject saved to demo_translation.json")


if __name__ == '__main__':
	demo_translation()
