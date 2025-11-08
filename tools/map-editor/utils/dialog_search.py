"""
Dialog Search and Navigation - Advanced search capabilities for FFMQ dialogs

Features:
- Full-text search across all dialogs
- Search by NPC, location, flags, items
- Regex search support
- Search history
- Quick jump to dialog in editor
"""

import re
from typing import List, Dict, Optional, Tuple, Set
from dataclasses import dataclass
from enum import Enum


class SearchMode(Enum):
	"""Search mode options"""
	TEXT = "text"  # Plain text search
	REGEX = "regex"  # Regular expression search
	FUZZY = "fuzzy"  # Fuzzy text matching
	CONTROL_CODE = "control"  # Search by control codes


@dataclass
class SearchResult:
	"""Represents a search result"""
	dialog_id: int
	address: int
	text: str
	matches: List[Tuple[int, int]]  # List of (start, end) positions of matches
	score: float  # Relevance score (0.0 to 1.0)
	context: str  # Text snippet showing match in context
	
	def __repr__(self):
		return f"Dialog 0x{self.dialog_id:04X}: {self.context}"


class DialogSearchEngine:
	"""Advanced search engine for FFMQ dialogs"""
	
	def __init__(self):
		"""Initialize search engine"""
		self.search_history: List[str] = []
		self.max_history = 50
		
		# Search settings
		self.case_sensitive = False
		self.whole_words = False
		self.max_results = 100
	
	def search(self, 
	          dialogs: Dict[int, any],  # dialog_id -> DialogEntry
	          query: str,
	          mode: SearchMode = SearchMode.TEXT,
	          npc_filter: Optional[List[int]] = None,
	          map_filter: Optional[List[int]] = None) -> List[SearchResult]:
		"""
		Search dialogs with various filters
		
		Args:
			dialogs: Dictionary of dialog entries
			query: Search query string
			mode: Search mode (text, regex, fuzzy, control)
			npc_filter: Optional list of NPC IDs to filter by
			map_filter: Optional list of map IDs to filter by
		
		Returns:
			List of SearchResult objects, sorted by relevance
		"""
		if not query:
			return []
		
		# Add to history
		if query not in self.search_history:
			self.search_history.insert(0, query)
			self.search_history = self.search_history[:self.max_history]
		
		results = []
		
		for dialog_id, dialog in dialogs.items():
			# Apply filters
			if npc_filter and dialog.npc_id not in npc_filter:
				continue
			if map_filter and dialog.map_id not in map_filter:
				continue
			
			# Perform search based on mode
			if mode == SearchMode.TEXT:
				matches, score = self._search_text(dialog.text, query)
			elif mode == SearchMode.REGEX:
				matches, score = self._search_regex(dialog.text, query)
			elif mode == SearchMode.FUZZY:
				matches, score = self._search_fuzzy(dialog.text, query)
			elif mode == SearchMode.CONTROL_CODE:
				matches, score = self._search_control_code(dialog.text, query)
			else:
				continue
			
			# If found matches, create result
			if matches:
				context = self._create_context(dialog.text, matches[0])
				result = SearchResult(
					dialog_id=dialog_id,
					address=dialog.address,
					text=dialog.text,
					matches=matches,
					score=score,
					context=context
				)
				results.append(result)
		
		# Sort by score (highest first)
		results.sort(key=lambda r: r.score, reverse=True)
		
		# Limit results
		return results[:self.max_results]
	
	def _search_text(self, text: str, query: str) -> Tuple[List[Tuple[int, int]], float]:
		"""
		Plain text search
		
		Returns:
			(matches, score) where matches is list of (start, end) positions
		"""
		search_text = text if self.case_sensitive else text.lower()
		search_query = query if self.case_sensitive else query.lower()
		
		matches = []
		score = 0.0
		
		if self.whole_words:
			# Word boundary search
			pattern = r'\b' + re.escape(search_query) + r'\b'
			for match in re.finditer(pattern, search_text, flags=0 if self.case_sensitive else re.IGNORECASE):
				matches.append((match.start(), match.end()))
		else:
			# Substring search
			start = 0
			while True:
				pos = search_text.find(search_query, start)
				if pos == -1:
					break
				matches.append((pos, pos + len(search_query)))
				start = pos + 1
		
		if matches:
			# Calculate score based on:
			# - Number of matches
			# - Position of first match (earlier = better)
			# - Match length relative to text length
			num_matches = len(matches)
			first_pos = matches[0][0]
			match_coverage = sum(end - start for start, end in matches) / len(text)
			
			score = (
				min(num_matches / 5, 1.0) * 0.4 +  # Max 5 matches for full score
				(1.0 - first_pos / max(len(text), 1)) * 0.3 +  # Earlier = better
				match_coverage * 0.3  # More coverage = better
			)
		
		return matches, score
	
	def _search_regex(self, text: str, pattern: str) -> Tuple[List[Tuple[int, int]], float]:
		"""
		Regular expression search
		
		Returns:
			(matches, score)
		"""
		try:
			flags = 0 if self.case_sensitive else re.IGNORECASE
			regex = re.compile(pattern, flags)
			
			matches = []
			for match in regex.finditer(text):
				matches.append((match.start(), match.end()))
			
			# Score based on number of matches
			score = min(len(matches) / 5, 1.0) if matches else 0.0
			
			return matches, score
		except re.error:
			# Invalid regex
			return [], 0.0
	
	def _search_fuzzy(self, text: str, query: str) -> Tuple[List[Tuple[int, int]], float]:
		"""
		Fuzzy text matching (allows some character differences)
		
		Returns:
			(matches, score)
		"""
		search_text = text if self.case_sensitive else text.lower()
		search_query = query if self.case_sensitive else query.lower()
		
		matches = []
		
		# Simple fuzzy matching: allow 1 character difference per 4 characters
		max_errors = max(1, len(search_query) // 4)
		
		# Sliding window approach
		for i in range(len(search_text) - len(search_query) + 1):
			window = search_text[i:i+len(search_query)]
			errors = sum(c1 != c2 for c1, c2 in zip(window, search_query))
			
			if errors <= max_errors:
				matches.append((i, i + len(search_query)))
		
		# Score based on match quality
		if matches:
			avg_errors = sum(
				sum(c1 != c2 for c1, c2 in zip(text[s:e], search_query)) / len(search_query)
				for s, e in matches
			) / len(matches)
			score = 1.0 - avg_errors
		else:
			score = 0.0
		
		return matches, score
	
	def _search_control_code(self, text: str, code: str) -> Tuple[List[Tuple[int, int]], float]:
		"""
		Search for control codes like [WAIT], [NEWLINE], etc.
		
		Returns:
			(matches, score)
		"""
		# Find all control codes in text
		pattern = r'\[' + re.escape(code.strip('[]').upper()) + r'\]'
		matches = []
		
		for match in re.finditer(pattern, text, re.IGNORECASE):
			matches.append((match.start(), match.end()))
		
		score = min(len(matches) / 5, 1.0) if matches else 0.0
		
		return matches, score
	
	def _create_context(self, text: str, match: Tuple[int, int], context_size: int = 40) -> str:
		"""
		Create a context snippet showing the match
		
		Args:
			text: Full text
			match: (start, end) position of match
			context_size: Characters to show before/after match
		
		Returns:
			Context string with "..." markers if truncated
		"""
		start, end = match
		
		# Get context before match
		context_start = max(0, start - context_size)
		before = text[context_start:start]
		if context_start > 0:
			before = "..." + before
		
		# Get matched text
		matched = text[start:end]
		
		# Get context after match
		context_end = min(len(text), end + context_size)
		after = text[end:context_end]
		if context_end < len(text):
			after = after + "..."
		
		return before + "[" + matched + "]" + after
	
	def search_by_length(self, dialogs: Dict[int, any], 
	                     min_length: Optional[int] = None,
	                     max_length: Optional[int] = None) -> List[int]:
		"""
		Search dialogs by length
		
		Args:
			dialogs: Dictionary of dialog entries
			min_length: Minimum length in bytes
			max_length: Maximum length in bytes
		
		Returns:
			List of dialog IDs matching length criteria
		"""
		results = []
		
		for dialog_id, dialog in dialogs.items():
			length = len(dialog.raw_bytes) if hasattr(dialog, 'raw_bytes') else len(dialog.text)
			
			if min_length is not None and length < min_length:
				continue
			if max_length is not None and length > max_length:
				continue
			
			results.append(dialog_id)
		
		return results
	
	def search_by_control_codes(self, dialogs: Dict[int, any], 
	                            has_codes: Optional[List[str]] = None,
	                            missing_codes: Optional[List[str]] = None) -> List[int]:
		"""
		Search dialogs by presence or absence of control codes
		
		Args:
			dialogs: Dictionary of dialog entries
			has_codes: List of control codes that must be present
			missing_codes: List of control codes that must NOT be present
		
		Returns:
			List of dialog IDs matching criteria
		"""
		results = []
		
		for dialog_id, dialog in dialogs.items():
			text = dialog.text
			
			# Check required codes
			if has_codes:
				if not all(f"[{code.strip('[]').upper()}]" in text.upper() for code in has_codes):
					continue
			
			# Check forbidden codes
			if missing_codes:
				if any(f"[{code.strip('[]').upper()}]" in text.upper() for code in missing_codes):
					continue
			
			results.append(dialog_id)
		
		return results
	
	def find_duplicates(self, dialogs: Dict[int, any]) -> Dict[str, List[int]]:
		"""
		Find duplicate or similar dialog texts
		
		Args:
			dialogs: Dictionary of dialog entries
		
		Returns:
			Dictionary mapping normalized text to list of dialog IDs
		"""
		text_to_ids = {}
		
		for dialog_id, dialog in dialogs.items():
			# Normalize text (lowercase, remove extra whitespace)
			normalized = ' '.join(dialog.text.lower().split())
			
			if normalized not in text_to_ids:
				text_to_ids[normalized] = []
			text_to_ids[normalized].append(dialog_id)
		
		# Filter to only duplicates
		duplicates = {text: ids for text, ids in text_to_ids.items() if len(ids) > 1}
		
		return duplicates
	
	def get_search_suggestions(self, query: str, dialogs: Dict[int, any]) -> List[str]:
		"""
		Get search suggestions based on partial query
		
		Args:
			query: Partial search query
			dialogs: Dictionary of dialog entries
		
		Returns:
			List of suggested search terms
		"""
		if len(query) < 2:
			return []
		
		suggestions = set()
		query_lower = query.lower()
		
		# Extract words from all dialogs
		for dialog in dialogs.values():
			words = re.findall(r'\b\w+\b', dialog.text.lower())
			for word in words:
				if word.startswith(query_lower) and len(word) > len(query):
					suggestions.add(word)
		
		# Return top suggestions
		return sorted(list(suggestions))[:10]


# Example usage
def demo_search():
	"""Demo the search engine"""
	
	# Mock dialog data
	@dataclass
	class MockDialog:
		text: str
		address: int = 0
		npc_id: int = 0
		map_id: int = 0
		raw_bytes: bytes = b''
	
	dialogs = {
		0x0001: MockDialog("Welcome to Foresta! The Crystal awaits."),
		0x0002: MockDialog("The Crystal of Light is very powerful."),
		0x0003: MockDialog("You must find the four Crystals!"),
		0x0004: MockDialog("Have you seen the Crystal?[WAIT]"),
		0x0005: MockDialog("The prophecy speaks of a hero.[NEWLINE]You are that hero!"),
	}
	
	engine = DialogSearchEngine()
	
	# Test text search
	print("Searching for 'Crystal':")
	results = engine.search(dialogs, "Crystal", SearchMode.TEXT)
	for i, result in enumerate(results, 1):
		print(f"  {i}. {result}")
	
	print("\nSearching for 'WAIT' control code:")
	results = engine.search(dialogs, "WAIT", SearchMode.CONTROL_CODE)
	for i, result in enumerate(results, 1):
		print(f"  {i}. {result}")
	
	print("\nSearching with regex '[A-Z][a-z]+ of [A-Z]':")
	results = engine.search(dialogs, r'[A-Z][a-z]+ of [A-Z]', SearchMode.REGEX)
	for i, result in enumerate(results, 1):
		print(f"  {i}. {result}")
	
	print("\nSearch suggestions for 'Cry':")
	suggestions = engine.get_search_suggestions("Cry", dialogs)
	print(f"  {suggestions}")


if __name__ == '__main__':
	demo_search()
