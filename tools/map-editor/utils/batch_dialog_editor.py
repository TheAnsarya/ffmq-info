"""
Batch Dialog Editor - Tools for editing multiple dialogs at once

Features:
- Find and replace across all dialogs
- Batch control code insertion/removal
- Mass reformatting
- Spell checking
- Text statistics and analysis
"""

import re
from typing import Dict, List, Optional, Set, Tuple, Callable
from dataclasses import dataclass
from collections import Counter


@dataclass
class BatchEditOperation:
	"""Represents a batch edit operation"""
	operation_type: str  # replace, insert, remove, format
	target: str  # What to find/modify
	replacement: Optional[str] = None  # What to replace with
	dialog_ids: Optional[List[int]] = None  # Specific dialogs (None = all)
	case_sensitive: bool = False
	use_regex: bool = False
	
	# Results
	affected_dialogs: List[int] = None
	changes_made: int = 0


class BatchDialogEditor:
	"""Batch editing operations for multiple dialogs"""
	
	def __init__(self):
		self.undo_history: List[Dict[int, str]] = []
		self.max_undo = 50
	
	def find_and_replace(self, 
	                     dialogs: Dict[int, any],
	                     find: str,
	                     replace: str,
	                     dialog_ids: Optional[List[int]] = None,
	                     case_sensitive: bool = False,
	                     use_regex: bool = False,
	                     whole_words: bool = False,
	                     dry_run: bool = False) -> BatchEditOperation:
		"""
		Find and replace text across dialogs
		
		Args:
			dialogs: Dictionary of dialog entries
			find: Text to find
			replace: Text to replace with
			dialog_ids: Specific dialogs to edit (None = all)
			case_sensitive: Case-sensitive matching
			use_regex: Use regular expressions
			whole_words: Match whole words only
			dry_run: Don't actually make changes, just report
		
		Returns:
			BatchEditOperation with results
		"""
		operation = BatchEditOperation(
			operation_type="replace",
			target=find,
			replacement=replace,
			dialog_ids=dialog_ids,
			case_sensitive=case_sensitive,
			use_regex=use_regex
		)
		
		# Save state for undo
		if not dry_run:
			self._save_undo_state(dialogs, dialog_ids)
		
		affected = []
		changes = 0
		
		# Prepare pattern
		if use_regex:
			flags = 0 if case_sensitive else re.IGNORECASE
			try:
				pattern = re.compile(find, flags)
			except re.error as e:
				operation.affected_dialogs = []
				operation.changes_made = 0
				return operation
		else:
			if whole_words:
				pattern = re.compile(r'\b' + re.escape(find) + r'\b', 
				                    flags=0 if case_sensitive else re.IGNORECASE)
			else:
				pattern = find if case_sensitive else find.lower()
		
		# Apply to dialogs
		target_ids = dialog_ids if dialog_ids else list(dialogs.keys())
		
		for dialog_id in target_ids:
			if dialog_id not in dialogs:
				continue
			
			dialog = dialogs[dialog_id]
			original_text = dialog.text
			
			# Perform replacement
			if use_regex or whole_words:
				new_text = pattern.sub(replace, original_text)
			else:
				if case_sensitive:
					new_text = original_text.replace(find, replace)
				else:
					# Case-insensitive replacement
					new_text = re.sub(re.escape(find), replace, original_text, flags=re.IGNORECASE)
			
			if new_text != original_text:
				if not dry_run:
					dialog.text = new_text
					dialog.modified = True
				
				affected.append(dialog_id)
				changes += original_text.count(find) if not use_regex else len(pattern.findall(original_text))
		
		operation.affected_dialogs = affected
		operation.changes_made = changes
		
		return operation
	
	def batch_insert_control_code(self,
	                              dialogs: Dict[int, any],
	                              position: str,  # start, end, before:text, after:text
	                              control_code: str,
	                              dialog_ids: Optional[List[int]] = None,
	                              dry_run: bool = False) -> BatchEditOperation:
		"""
		Insert a control code at specified position in multiple dialogs
		
		Args:
			dialogs: Dictionary of dialog entries
			position: Where to insert (start, end, before:text, after:text)
			control_code: Control code to insert (e.g., [WAIT])
			dialog_ids: Specific dialogs (None = all)
			dry_run: Don't actually make changes
		
		Returns:
			BatchEditOperation with results
		"""
		operation = BatchEditOperation(
			operation_type="insert",
			target=position,
			replacement=control_code,
			dialog_ids=dialog_ids
		)
		
		if not dry_run:
			self._save_undo_state(dialogs, dialog_ids)
		
		affected = []
		changes = 0
		
		target_ids = dialog_ids if dialog_ids else list(dialogs.keys())
		
		for dialog_id in target_ids:
			if dialog_id not in dialogs:
				continue
			
			dialog = dialogs[dialog_id]
			text = dialog.text
			new_text = text
			
			if position == "start":
				new_text = control_code + text
			elif position == "end":
				new_text = text + control_code
			elif position.startswith("before:"):
				marker = position[7:]
				new_text = text.replace(marker, control_code + marker)
			elif position.startswith("after:"):
				marker = position[6:]
				new_text = text.replace(marker, marker + control_code)
			
			if new_text != text:
				if not dry_run:
					dialog.text = new_text
					dialog.modified = True
				
				affected.append(dialog_id)
				changes += 1
		
		operation.affected_dialogs = affected
		operation.changes_made = changes
		
		return operation
	
	def batch_remove_control_code(self,
	                              dialogs: Dict[int, any],
	                              control_code: str,
	                              dialog_ids: Optional[List[int]] = None,
	                              dry_run: bool = False) -> BatchEditOperation:
		"""
		Remove a control code from multiple dialogs
		
		Args:
			dialogs: Dictionary of dialog entries
			control_code: Control code to remove (e.g., [WAIT])
			dialog_ids: Specific dialogs (None = all)
			dry_run: Don't actually make changes
		
		Returns:
			BatchEditOperation with results
		"""
		return self.find_and_replace(
			dialogs=dialogs,
			find=control_code,
			replace="",
			dialog_ids=dialog_ids,
			case_sensitive=False,
			use_regex=False,
			dry_run=dry_run
		)
	
	def batch_reformat(self,
	                  dialogs: Dict[int, any],
	                  operations: List[str],  # normalize_whitespace, remove_trailing_spaces, etc.
	                  dialog_ids: Optional[List[int]] = None,
	                  dry_run: bool = False) -> BatchEditOperation:
		"""
		Apply formatting operations to multiple dialogs
		
		Args:
			dialogs: Dictionary of dialog entries
			operations: List of formatting operations to apply
			dialog_ids: Specific dialogs (None = all)
			dry_run: Don't actually make changes
		
		Returns:
			BatchEditOperation with results
		"""
		operation = BatchEditOperation(
			operation_type="format",
			target=",".join(operations),
			dialog_ids=dialog_ids
		)
		
		if not dry_run:
			self._save_undo_state(dialogs, dialog_ids)
		
		affected = []
		changes = 0
		
		target_ids = dialog_ids if dialog_ids else list(dialogs.keys())
		
		for dialog_id in target_ids:
			if dialog_id not in dialogs:
				continue
			
			dialog = dialogs[dialog_id]
			text = dialog.text
			new_text = text
			
			for op in operations:
				if op == "normalize_whitespace":
					# Replace multiple spaces with single space
					new_text = re.sub(r' +', ' ', new_text)
				
				elif op == "remove_trailing_spaces":
					# Remove spaces at end of lines
					lines = new_text.split('\n')
					lines = [line.rstrip() for line in lines]
					new_text = '\n'.join(lines)
				
				elif op == "remove_leading_spaces":
					# Remove spaces at start of lines
					lines = new_text.split('\n')
					lines = [line.lstrip() for line in lines]
					new_text = '\n'.join(lines)
				
				elif op == "normalize_newlines":
					# Ensure consistent newline usage
					new_text = new_text.replace('\r\n', '\n')
					new_text = new_text.replace('\r', '\n')
				
				elif op == "trim":
					# Remove leading/trailing whitespace
					new_text = new_text.strip()
				
				elif op == "capitalize_sentences":
					# Capitalize first letter of sentences
					sentences = re.split(r'([.!?]+\s*)', new_text)
					for i in range(0, len(sentences), 2):
						if sentences[i]:
							sentences[i] = sentences[i][0].upper() + sentences[i][1:] if len(sentences[i]) > 0 else sentences[i]
					new_text = ''.join(sentences)
			
			if new_text != text:
				if not dry_run:
					dialog.text = new_text
					dialog.modified = True
				
				affected.append(dialog_id)
				changes += 1
		
		operation.affected_dialogs = affected
		operation.changes_made = changes
		
		return operation
	
	def analyze_text_statistics(self, dialogs: Dict[int, any]) -> Dict[str, any]:
		"""
		Analyze text statistics across all dialogs
		
		Returns:
			Dictionary with various statistics
		"""
		total_dialogs = len(dialogs)
		total_chars = 0
		total_words = 0
		total_lines = 0
		
		word_freq = Counter()
		char_freq = Counter()
		control_code_freq = Counter()
		
		lengths = []
		
		for dialog in dialogs.values():
			text = dialog.text
			
			total_chars += len(text)
			lengths.append(len(text))
			
			# Count lines
			lines = text.count('\n') + 1
			total_lines += lines
			
			# Count words
			words = re.findall(r'\b\w+\b', text.lower())
			total_words += len(words)
			word_freq.update(words)
			
			# Count characters
			char_freq.update(text.lower())
			
			# Count control codes
			codes = re.findall(r'\[([A-Z_]+)(?::\w+)?\]', text)
			control_code_freq.update(codes)
		
		avg_length = total_chars / total_dialogs if total_dialogs > 0 else 0
		avg_words = total_words / total_dialogs if total_dialogs > 0 else 0
		
		return {
			'total_dialogs': total_dialogs,
			'total_characters': total_chars,
			'total_words': total_words,
			'total_lines': total_lines,
			'average_length': avg_length,
			'average_words': avg_words,
			'min_length': min(lengths) if lengths else 0,
			'max_length': max(lengths) if lengths else 0,
			'most_common_words': word_freq.most_common(20),
			'most_common_chars': char_freq.most_common(10),
			'control_codes_used': dict(control_code_freq),
			'unique_words': len(word_freq)
		}
	
	def find_potential_errors(self, dialogs: Dict[int, any]) -> Dict[int, List[str]]:
		"""
		Find potential errors in dialogs
		
		Returns:
			Dictionary mapping dialog_id to list of potential issues
		"""
		errors = {}
		
		for dialog_id, dialog in dialogs.items():
			issues = []
			text = dialog.text
			
			# Check for unbalanced brackets
			if text.count('[') != text.count(']'):
				issues.append("Unbalanced control code brackets")
			
			# Check for double spaces
			if '  ' in text:
				issues.append("Contains double spaces")
			
			# Check for trailing spaces
			if text.endswith(' '):
				issues.append("Has trailing space")
			
			# Check for leading spaces
			if text.startswith(' '):
				issues.append("Has leading space")
			
			# Check for missing punctuation at end
			if text and text[-1] not in '.!?':
				# Unless it ends with a control code
				if not text.endswith(']'):
					issues.append("Missing ending punctuation")
			
			# Check for repeated punctuation
			if re.search(r'[.!?]{2,}', text):
				issues.append("Contains repeated punctuation")
			
			# Check for unclosed control codes
			if '[' in text and not re.match(r'.*\[[A-Z_]+(?::\w+)?\].*', text):
				issues.append("Possible malformed control code")
			
			if issues:
				errors[dialog_id] = issues
		
		return errors
	
	def _save_undo_state(self, dialogs: Dict[int, any], dialog_ids: Optional[List[int]]):
		"""Save current state for undo"""
		target_ids = dialog_ids if dialog_ids else list(dialogs.keys())
		
		state = {}
		for dialog_id in target_ids:
			if dialog_id in dialogs:
				state[dialog_id] = dialogs[dialog_id].text
		
		self.undo_history.append(state)
		
		# Limit undo history
		if len(self.undo_history) > self.max_undo:
			self.undo_history.pop(0)
	
	def undo(self, dialogs: Dict[int, any]) -> bool:
		"""
		Undo last batch operation
		
		Returns:
			True if undo was performed
		"""
		if not self.undo_history:
			return False
		
		state = self.undo_history.pop()
		
		for dialog_id, text in state.items():
			if dialog_id in dialogs:
				dialogs[dialog_id].text = text
		
		return True


def demo_batch_editor():
	"""Demo batch editing features"""
	
	# Mock dialog data
	@dataclass
	class MockDialog:
		text: str
		modified: bool = False
	
	dialogs = {
		0x0001: MockDialog("Welcome  to Foresta! "),
		0x0002: MockDialog("the Crystal of Light awaits you."),
		0x0003: MockDialog("You must find the Crystal"),
		0x0004: MockDialog("[WAIT]Talk to the old man[WAIT]"),
		0x0005: MockDialog("this is a test  with errors  "),
	}
	
	editor = BatchDialogEditor()
	
	# Test find and replace
	print("=== Find and Replace ===")
	result = editor.find_and_replace(dialogs, "Crystal", "Gem", dry_run=True)
	print(f"Would affect {len(result.affected_dialogs)} dialogs")
	print(f"Would make {result.changes_made} changes")
	
	# Test batch reformat
	print("\n=== Batch Reformat ===")
	result = editor.batch_reformat(
		dialogs, 
		["normalize_whitespace", "remove_trailing_spaces", "capitalize_sentences"],
		dry_run=True
	)
	print(f"Would affect {len(result.affected_dialogs)} dialogs")
	
	# Test statistics
	print("\n=== Text Statistics ===")
	stats = editor.analyze_text_statistics(dialogs)
	print(f"Total dialogs: {stats['total_dialogs']}")
	print(f"Total characters: {stats['total_characters']}")
	print(f"Average length: {stats['average_length']:.1f}")
	print(f"Most common words: {stats['most_common_words'][:5]}")
	
	# Test error detection
	print("\n=== Potential Errors ===")
	errors = editor.find_potential_errors(dialogs)
	for dialog_id, issues in errors.items():
		print(f"Dialog 0x{dialog_id:04X}:")
		for issue in issues:
			print(f"  - {issue}")


if __name__ == '__main__':
	demo_batch_editor()
