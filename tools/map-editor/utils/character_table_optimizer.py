"""
Character Table Optimizer - Analyzes dialog text to suggest optimal multi-character sequences
for compression in the FFMQ character table.

This module provides tools to:
- Analyze a corpus of dialog text to find common patterns
- Suggest multi-character sequences that would save the most bytes
- Auto-generate character table entries from analysis
- Evaluate compression efficiency
"""

from typing import Dict, List, Tuple, Set
from collections import Counter
from dataclasses import dataclass
import re


@dataclass
class CompressionCandidate:
	"""Represents a potential multi-character sequence for compression"""
	sequence: str
	frequency: int
	byte_savings: int  # Total bytes saved if this sequence is encoded
	avg_compression: float  # Average compression ratio
	priority_score: float  # Overall priority (higher = better candidate)
	
	def __repr__(self):
		return f"'{self.sequence}' (freq={self.frequency}, saves={self.byte_savings} bytes, score={self.priority_score:.2f})"


class CharacterTableOptimizer:
	"""Analyzes dialog text and suggests optimal character table entries"""
	
	def __init__(self, min_length: int = 2, max_length: int = 20):
		"""
		Args:
			min_length: Minimum characters in a sequence (default 2)
			max_length: Maximum characters in a sequence (default 20)
		"""
		self.min_length = min_length
		self.max_length = max_length
		self.candidates: List[CompressionCandidate] = []
		
	def analyze_corpus(self, texts: List[str], existing_sequences: Set[str] = None) -> List[CompressionCandidate]:
		"""
		Analyze a corpus of text to find optimal multi-character sequences.
		
		Args:
			texts: List of dialog text strings to analyze
			existing_sequences: Set of sequences already in the character table (to avoid)
		
		Returns:
			List of CompressionCandidate objects, sorted by priority score
		"""
		if existing_sequences is None:
			existing_sequences = set()
		
		# Combine all texts into one corpus
		corpus = "\n".join(texts)
		
		# Find all n-grams from min_length to max_length
		ngram_counts: Dict[str, int] = {}
		
		for length in range(self.min_length, self.max_length + 1):
			for i in range(len(corpus) - length + 1):
				ngram = corpus[i:i+length]
				
				# Skip if:
				# - Contains newline (we handle that separately)
				# - Is only whitespace
				# - Already in existing sequences
				# - Contains control characters
				if '\n' in ngram or ngram.isspace() or ngram in existing_sequences:
					continue
				if any(ord(c) < 32 for c in ngram):
					continue
				
				ngram_counts[ngram] = ngram_counts.get(ngram, 0) + 1
		
		# Calculate compression metrics for each candidate
		candidates = []
		for sequence, frequency in ngram_counts.items():
			if frequency < 2:  # Must appear at least twice to be worth it
				continue
			
			# Calculate byte savings
			# Each occurrence saves (len(sequence) - 1) bytes
			# because we encode the whole sequence as 1 byte instead of len(sequence) bytes
			bytes_per_occurrence = len(sequence) - 1
			total_byte_savings = bytes_per_occurrence * frequency
			
			# Calculate compression ratio
			original_bytes = len(sequence) * frequency
			compressed_bytes = frequency  # Each occurrence becomes 1 byte
			avg_compression = original_bytes / compressed_bytes if compressed_bytes > 0 else 1.0
			
			# Calculate priority score
			# Factors:
			# - Total byte savings (most important)
			# - Frequency (higher frequency = better)
			# - Compression ratio
			# - Sequence length (prefer common words/phrases)
			priority_score = (
				total_byte_savings * 10.0 +  # Byte savings is most important
				frequency * 5.0 +			  # Frequency matters
				avg_compression * 2.0 +		# Compression ratio
				(len(sequence) * 0.5)		  # Slight preference for longer sequences
			)
			
			candidate = CompressionCandidate(
				sequence=sequence,
				frequency=frequency,
				byte_savings=total_byte_savings,
				avg_compression=avg_compression,
				priority_score=priority_score
			)
			candidates.append(candidate)
		
		# Sort by priority score (highest first)
		candidates.sort(key=lambda c: c.priority_score, reverse=True)
		
		# Remove overlapping sequences (greedy selection)
		# Keep the highest priority sequence, remove any that overlap with it
		self.candidates = self._remove_overlapping(candidates)
		
		return self.candidates
	
	def _remove_overlapping(self, candidates: List[CompressionCandidate]) -> List[CompressionCandidate]:
		"""
		Remove overlapping candidates, keeping the highest priority ones.
		
		For example, if we have "the " and " the", keep only the higher priority one.
		"""
		selected = []
		used_chars = set()
		
		for candidate in candidates:
			# Check if this sequence overlaps with any selected sequence
			overlaps = False
			for selected_candidate in selected:
				# Check if sequences overlap
				if self._sequences_overlap(candidate.sequence, selected_candidate.sequence):
					overlaps = True
					break
			
			if not overlaps:
				selected.append(candidate)
		
		return selected
	
	def _sequences_overlap(self, seq1: str, seq2: str) -> bool:
		"""Check if two sequences overlap (one contains the other or they share characters)"""
		# Simple overlap check: does one contain the other?
		return seq1 in seq2 or seq2 in seq1
	
	def find_common_words(self, texts: List[str], min_frequency: int = 5) -> List[Tuple[str, int]]:
		"""
		Find common whole words in the corpus.
		
		Args:
			texts: List of dialog text strings
			min_frequency: Minimum number of occurrences
		
		Returns:
			List of (word, frequency) tuples, sorted by frequency
		"""
		corpus = " ".join(texts)
		
		# Extract words (alphanumeric sequences)
		words = re.findall(r'\b[a-zA-Z]+\b', corpus.lower())
		
		# Count frequencies
		word_counts = Counter(words)
		
		# Filter by minimum frequency
		common_words = [(word, count) for word, count in word_counts.items() 
						if count >= min_frequency]
		
		# Sort by frequency
		common_words.sort(key=lambda x: x[1], reverse=True)
		
		return common_words
	
	def find_common_phrases(self, texts: List[str], min_frequency: int = 3) -> List[Tuple[str, int]]:
		"""
		Find common phrases (2-4 words) in the corpus.
		
		Args:
			texts: List of dialog text strings
			min_frequency: Minimum number of occurrences
		
		Returns:
			List of (phrase, frequency) tuples, sorted by frequency
		"""
		corpus = " ".join(texts)
		
		# Extract 2-4 word phrases
		phrases = []
		for word_count in range(2, 5):
			pattern = r'\b(' + r'\s+'.join([r'[a-zA-Z]+'] * word_count) + r')\b'
			phrases.extend(re.findall(pattern, corpus.lower()))
		
		# Count frequencies
		phrase_counts = Counter(phrases)
		
		# Filter by minimum frequency
		common_phrases = [(phrase, count) for phrase, count in phrase_counts.items() 
						  if count >= min_frequency]
		
		# Sort by frequency
		common_phrases.sort(key=lambda x: x[1], reverse=True)
		
		return common_phrases
	
	def generate_table_entries(self, num_entries: int = 50, start_byte: int = 0x40) -> Dict[int, str]:
		"""
		Generate character table entries from the top candidates.
		
		Args:
			num_entries: Number of entries to generate
			start_byte: Starting byte value for new entries
		
		Returns:
			Dictionary mapping byte values to sequences
		"""
		table = {}
		
		for i, candidate in enumerate(self.candidates[:num_entries]):
			byte_value = start_byte + i
			if byte_value > 0xFF:
				break  # Can't exceed byte range
			
			table[byte_value] = candidate.sequence
		
		return table
	
	def evaluate_compression(self, texts: List[str], character_table: Dict[int, str]) -> Dict[str, any]:
		"""
		Evaluate how much compression a character table provides on the given texts.
		
		Args:
			texts: List of dialog text strings
			character_table: Dictionary mapping byte values to sequences
		
		Returns:
			Dictionary with compression statistics
		"""
		# Create reverse lookup (sequence -> byte)
		seq_to_byte = {seq: byte for byte, seq in character_table.items()}
		
		original_bytes = 0
		compressed_bytes = 0
		sequences_used = {}
		
		for text in texts:
			original_bytes += len(text)
			
			# Simulate encoding with longest-match
			i = 0
			while i < len(text):
				# Try to match longest sequence
				matched = False
				for length in range(min(self.max_length, len(text) - i), 0, -1):
					sequence = text[i:i+length]
					if sequence in seq_to_byte:
						compressed_bytes += 1
						sequences_used[sequence] = sequences_used.get(sequence, 0) + 1
						i += length
						matched = True
						break
				
				if not matched:
					# Single character
					compressed_bytes += 1
					i += 1
		
		compression_ratio = original_bytes / compressed_bytes if compressed_bytes > 0 else 1.0
		bytes_saved = original_bytes - compressed_bytes
		percent_saved = (bytes_saved / original_bytes * 100) if original_bytes > 0 else 0.0
		
		return {
			'original_bytes': original_bytes,
			'compressed_bytes': compressed_bytes,
			'bytes_saved': bytes_saved,
			'compression_ratio': compression_ratio,
			'percent_saved': percent_saved,
			'sequences_used': sequences_used,
			'total_sequences': len(sequences_used),
			'most_used': sorted(sequences_used.items(), key=lambda x: x[1], reverse=True)[:10]
		}
	
	def export_candidates_report(self, output_path: str, top_n: int = 100):
		"""
		Export a detailed report of compression candidates to a text file.
		
		Args:
			output_path: Path to output file
			top_n: Number of top candidates to include
		"""
		with open(output_path, 'w', encoding='utf-8') as f:
			f.write("=" * 80 + "\n")
			f.write("CHARACTER TABLE OPTIMIZATION REPORT\n")
			f.write("=" * 80 + "\n\n")
			
			f.write(f"Total candidates analyzed: {len(self.candidates)}\n")
			f.write(f"Showing top {min(top_n, len(self.candidates))} candidates\n\n")
			
			f.write("-" * 80 + "\n")
			f.write(f"{'Rank':<6} {'Sequence':<25} {'Freq':<8} {'Saves':<10} {'Score':<10}\n")
			f.write("-" * 80 + "\n")
			
			for i, candidate in enumerate(self.candidates[:top_n], 1):
				# Escape special characters for display
				display_seq = candidate.sequence.replace('\n', '\\n').replace('\t', '\\t')
				
				f.write(f"{i:<6} {display_seq:<25} {candidate.frequency:<8} "
						f"{candidate.byte_savings:<10} {candidate.priority_score:<10.2f}\n")
			
			f.write("-" * 80 + "\n")


def demo_optimizer():
	"""Demo: Analyze sample FFMQ dialog text"""
	
	# Sample FFMQ dialog texts
	sample_dialogs = [
		"Welcome to Foresta! The Crystal is in danger.",
		"You must find the Crystal and save the world!",
		"The prophecy speaks of a hero who will save us all.",
		"Have you seen the Crystal? It's very important.",
		"The Crystal of Light is the key to everything.",
		"You are the chosen one from the prophecy!",
		"The Dark King threatens our world. You must stop him.",
		"I have been waiting for you. The prophecy said you would come.",
		"The Crystal is protected by powerful magic.",
		"You need the Crystal to unlock the sealed door.",
		"The prophecy tells of four Crystals that must be found.",
		"This is the Forest. The Forest of Foresta.",
		"The old man in the village knows about the Crystal.",
		"You should talk to the old man. He knows everything.",
		"The Crystal of Light shines brightly in the darkness.",
	]
	
	# Existing sequences in complex.tbl (simplified)
	existing = {
		"the ", "you", "ing ", "Crystal", "prophecy"
	}
	
	optimizer = CharacterTableOptimizer(min_length=2, max_length=15)
	
	print("Analyzing corpus...")
	candidates = optimizer.analyze_corpus(sample_dialogs, existing_sequences=existing)
	
	print(f"\nTop 20 compression candidates:")
	print("-" * 80)
	for i, candidate in enumerate(candidates[:20], 1):
		print(f"{i:2}. {candidate}")
	
	print("\n\nCommon words:")
	print("-" * 80)
	words = optimizer.find_common_words(sample_dialogs, min_frequency=3)
	for word, freq in words[:15]:
		print(f"  {word:<20} (frequency: {freq})")
	
	print("\n\nCommon phrases:")
	print("-" * 80)
	phrases = optimizer.find_common_phrases(sample_dialogs, min_frequency=2)
	for phrase, freq in phrases[:15]:
		print(f"  {phrase:<30} (frequency: {freq})")
	
	# Generate table entries
	print("\n\nSuggested character table entries:")
	print("-" * 80)
	table = optimizer.generate_table_entries(num_entries=20, start_byte=0x40)
	for byte_val, sequence in sorted(table.items()):
		display_seq = sequence.replace('\n', '\\n').replace(' ', '·')
		print(f"  0x{byte_val:02X} = \"{display_seq}\"")
	
	# Evaluate compression
	print("\n\nCompression evaluation:")
	print("-" * 80)
	stats = optimizer.evaluate_compression(sample_dialogs, table)
	print(f"  Original size:	 {stats['original_bytes']} bytes")
	print(f"  Compressed size:   {stats['compressed_bytes']} bytes")
	print(f"  Bytes saved:	   {stats['bytes_saved']} bytes")
	print(f"  Compression ratio: {stats['compression_ratio']:.2f}x")
	print(f"  Percent saved:	 {stats['percent_saved']:.1f}%")
	print(f"\n  Most used sequences:")
	for seq, count in stats['most_used'][:10]:
		display_seq = seq.replace(' ', '·')
		print(f"	\"{display_seq}\" used {count} times")


if __name__ == '__main__':
	demo_optimizer()
