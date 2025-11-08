"""
Dialog Diff and Merge Utility

Compares dialog databases and merges changes.
Useful for collaboration and version control.
"""

from dataclasses import dataclass
from typing import Dict, List, Set, Tuple, Optional
from enum import Enum
import sys
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from utils.dialog_database import DialogEntry, DialogDatabase


class ChangeType(Enum):
	"""Type of change in diff"""
	ADDED = "added"
	REMOVED = "removed"
	MODIFIED = "modified"
	UNCHANGED = "unchanged"


@dataclass
class DialogDiff:
	"""Represents a difference between two dialog entries"""
	dialog_id: int
	change_type: ChangeType
	old_dialog: Optional[DialogEntry]
	new_dialog: Optional[DialogEntry]
	text_changed: bool = False
	metadata_changed: bool = False
	changes: List[str] = None  # Detailed list of changes
	
	def __post_init__(self):
		if self.changes is None:
			self.changes = []


class DialogDiffer:
	"""Compares two dialog databases"""
	
	def __init__(self, old_db: DialogDatabase, new_db: DialogDatabase):
		self.old_db = old_db
		self.new_db = new_db
		self.diffs: List[DialogDiff] = []
	
	def compare(self) -> List[DialogDiff]:
		"""Compare the two databases and return diffs"""
		self.diffs = []
		
		# Get all dialog IDs from both databases
		all_ids = set(self.old_db.dialogs.keys()) | set(self.new_db.dialogs.keys())
		
		for dialog_id in sorted(all_ids):
			old_dialog = self.old_db.dialogs.get(dialog_id)
			new_dialog = self.new_db.dialogs.get(dialog_id)
			
			if old_dialog is None:
				# Added
				self.diffs.append(DialogDiff(
					dialog_id=dialog_id,
					change_type=ChangeType.ADDED,
					old_dialog=None,
					new_dialog=new_dialog,
					changes=["Dialog added"]
				))
			
			elif new_dialog is None:
				# Removed
				self.diffs.append(DialogDiff(
					dialog_id=dialog_id,
					change_type=ChangeType.REMOVED,
					old_dialog=old_dialog,
					new_dialog=None,
					changes=["Dialog removed"]
				))
			
			else:
				# Check for modifications
				changes = []
				text_changed = False
				metadata_changed = False
				
				if old_dialog.text != new_dialog.text:
					text_changed = True
					changes.append(f"Text changed: '{old_dialog.text[:30]}...' → '{new_dialog.text[:30]}...'")
				
				if old_dialog.pointer != new_dialog.pointer:
					metadata_changed = True
					changes.append(f"Pointer: 0x{old_dialog.pointer:06X} → 0x{new_dialog.pointer:06X}")
				
				if old_dialog.address != new_dialog.address:
					metadata_changed = True
					changes.append(f"Address: 0x{old_dialog.address:06X} → 0x{new_dialog.address:06X}")
				
				if old_dialog.tags != new_dialog.tags:
					metadata_changed = True
					added_tags = new_dialog.tags - old_dialog.tags
					removed_tags = old_dialog.tags - new_dialog.tags
					if added_tags:
						changes.append(f"Tags added: {', '.join(added_tags)}")
					if removed_tags:
						changes.append(f"Tags removed: {', '.join(removed_tags)}")
				
				if old_dialog.notes != new_dialog.notes:
					metadata_changed = True
					changes.append("Notes changed")
				
				if changes:
					self.diffs.append(DialogDiff(
						dialog_id=dialog_id,
						change_type=ChangeType.MODIFIED,
						old_dialog=old_dialog,
						new_dialog=new_dialog,
						text_changed=text_changed,
						metadata_changed=metadata_changed,
						changes=changes
					))
				else:
					self.diffs.append(DialogDiff(
						dialog_id=dialog_id,
						change_type=ChangeType.UNCHANGED,
						old_dialog=old_dialog,
						new_dialog=new_dialog
					))
		
		return self.diffs
	
	def get_statistics(self) -> Dict[str, int]:
		"""Get statistics about the diff"""
		stats = {
			'total': len(self.diffs),
			'added': 0,
			'removed': 0,
			'modified': 0,
			'unchanged': 0,
			'text_changed': 0,
			'metadata_changed': 0
		}
		
		for diff in self.diffs:
			stats[diff.change_type.value] += 1
			if diff.text_changed:
				stats['text_changed'] += 1
			if diff.metadata_changed:
				stats['metadata_changed'] += 1
		
		return stats
	
	def generate_report(self, include_unchanged: bool = False) -> str:
		"""Generate a human-readable diff report"""
		lines = []
		lines.append("=" * 70)
		lines.append("Dialog Database Diff Report")
		lines.append("=" * 70)
		lines.append("")
		
		# Statistics
		stats = self.get_statistics()
		lines.append(f"Total Dialogs: {stats['total']}")
		lines.append(f"  Added:    {stats['added']}")
		lines.append(f"  Removed:  {stats['removed']}")
		lines.append(f"  Modified: {stats['modified']}")
		lines.append(f"  Unchanged: {stats['unchanged']}")
		lines.append("")
		lines.append(f"Text Changes:     {stats['text_changed']}")
		lines.append(f"Metadata Changes: {stats['metadata_changed']}")
		lines.append("")
		
		# Group diffs by type
		by_type = {
			ChangeType.ADDED: [],
			ChangeType.REMOVED: [],
			ChangeType.MODIFIED: [],
			ChangeType.UNCHANGED: []
		}
		
		for diff in self.diffs:
			by_type[diff.change_type].append(diff)
		
		# Added dialogs
		if by_type[ChangeType.ADDED]:
			lines.append("-" * 70)
			lines.append(f"ADDED DIALOGS ({len(by_type[ChangeType.ADDED])})")
			lines.append("-" * 70)
			
			for diff in by_type[ChangeType.ADDED]:
				lines.append(f"\n[+] Dialog 0x{diff.dialog_id:04X}")
				lines.append(f"    Text: {diff.new_dialog.text}")
		
		# Removed dialogs
		if by_type[ChangeType.REMOVED]:
			lines.append("")
			lines.append("-" * 70)
			lines.append(f"REMOVED DIALOGS ({len(by_type[ChangeType.REMOVED])})")
			lines.append("-" * 70)
			
			for diff in by_type[ChangeType.REMOVED]:
				lines.append(f"\n[-] Dialog 0x{diff.dialog_id:04X}")
				lines.append(f"    Text: {diff.old_dialog.text}")
		
		# Modified dialogs
		if by_type[ChangeType.MODIFIED]:
			lines.append("")
			lines.append("-" * 70)
			lines.append(f"MODIFIED DIALOGS ({len(by_type[ChangeType.MODIFIED])})")
			lines.append("-" * 70)
			
			for diff in by_type[ChangeType.MODIFIED]:
				lines.append(f"\n[M] Dialog 0x{diff.dialog_id:04X}")
				for change in diff.changes:
					lines.append(f"    • {change}")
		
		# Unchanged (optional)
		if include_unchanged and by_type[ChangeType.UNCHANGED]:
			lines.append("")
			lines.append("-" * 70)
			lines.append(f"UNCHANGED DIALOGS ({len(by_type[ChangeType.UNCHANGED])})")
			lines.append("-" * 70)
			
			for diff in by_type[ChangeType.UNCHANGED]:
				lines.append(f"[ ] Dialog 0x{diff.dialog_id:04X}")
		
		lines.append("")
		lines.append("=" * 70)
		
		return "\n".join(lines)


class DialogMerger:
	"""Merges changes from multiple dialog databases"""
	
	def __init__(self, base_db: DialogDatabase):
		self.base_db = base_db
	
	def merge_changes(self, other_db: DialogDatabase, conflict_resolution: str = 'theirs') -> Tuple[DialogDatabase, List[str]]:
		"""
		Merge changes from other_db into base_db.
		
		Args:
			other_db: Database to merge from
			conflict_resolution: How to resolve conflicts ('ours', 'theirs', or 'ask')
		
		Returns:
			Tuple of (merged_db, list of conflicts)
		"""
		merged_db = DialogDatabase()
		conflicts = []
		
		# Get all dialog IDs
		all_ids = set(self.base_db.dialogs.keys()) | set(other_db.dialogs.keys())
		
		for dialog_id in sorted(all_ids):
			base_dialog = self.base_db.dialogs.get(dialog_id)
			other_dialog = other_db.dialogs.get(dialog_id)
			
			if base_dialog is None:
				# New dialog in other - add it
				merged_db.dialogs[dialog_id] = other_dialog
			
			elif other_dialog is None:
				# Dialog removed in other - keep base
				merged_db.dialogs[dialog_id] = base_dialog
			
			else:
				# Both have the dialog - check for conflicts
				if base_dialog.text != other_dialog.text:
					conflict_msg = f"Dialog 0x{dialog_id:04X}: Text conflict"
					conflicts.append(conflict_msg)
					
					if conflict_resolution == 'ours':
						merged_db.dialogs[dialog_id] = base_dialog
					elif conflict_resolution == 'theirs':
						merged_db.dialogs[dialog_id] = other_dialog
					else:
						# For 'ask' mode, would prompt user
						# For now, default to 'theirs'
						merged_db.dialogs[dialog_id] = other_dialog
				else:
					# No text conflict - merge metadata
					merged = DialogEntry(
						id=dialog_id,
						text=base_dialog.text,
						raw_bytes=other_dialog.raw_bytes if other_dialog.modified else base_dialog.raw_bytes,
						pointer=other_dialog.pointer,
						address=other_dialog.address,
						length=other_dialog.length,
						references=list(set(base_dialog.references) | set(other_dialog.references)),
						tags=base_dialog.tags | other_dialog.tags,
						notes=other_dialog.notes if other_dialog.notes else base_dialog.notes,
						modified=base_dialog.modified or other_dialog.modified
					)
					merged_db.dialogs[dialog_id] = merged
		
		return merged_db, conflicts
	
	def three_way_merge(
		self,
		ancestor_db: DialogDatabase,
		ours_db: DialogDatabase,
		theirs_db: DialogDatabase
	) -> Tuple[DialogDatabase, List[str]]:
		"""
		Perform a three-way merge using common ancestor.
		
		Args:
			ancestor_db: Common ancestor database
			ours_db: Our version
			theirs_db: Their version
		
		Returns:
			Tuple of (merged_db, list of conflicts)
		"""
		merged_db = DialogDatabase()
		conflicts = []
		
		# Get all dialog IDs
		all_ids = (
			set(ancestor_db.dialogs.keys()) |
			set(ours_db.dialogs.keys()) |
			set(theirs_db.dialogs.keys())
		)
		
		for dialog_id in sorted(all_ids):
			ancestor = ancestor_db.dialogs.get(dialog_id)
			ours = ours_db.dialogs.get(dialog_id)
			theirs = theirs_db.dialogs.get(dialog_id)
			
			# Analyze changes
			we_changed = ancestor is not None and ours is not None and ancestor.text != ours.text
			they_changed = ancestor is not None and theirs is not None and ancestor.text != theirs.text
			we_added = ancestor is None and ours is not None
			they_added = ancestor is None and theirs is not None
			we_removed = ancestor is not None and ours is None
			they_removed = ancestor is not None and theirs is None
			
			# Decision logic
			if we_added and they_added:
				# Both added same dialog ID
				if ours.text == theirs.text:
					merged_db.dialogs[dialog_id] = ours
				else:
					conflicts.append(f"Dialog 0x{dialog_id:04X}: Both added with different text")
					merged_db.dialogs[dialog_id] = theirs  # Default to theirs
			
			elif we_removed and they_removed:
				# Both removed - that's fine
				pass
			
			elif we_removed and they_changed:
				conflicts.append(f"Dialog 0x{dialog_id:04X}: We removed, they modified")
				merged_db.dialogs[dialog_id] = theirs  # Keep their version
			
			elif they_removed and we_changed:
				conflicts.append(f"Dialog 0x{dialog_id:04X}: They removed, we modified")
				merged_db.dialogs[dialog_id] = ours  # Keep our version
			
			elif we_changed and they_changed:
				# Both modified
				if ours.text == theirs.text:
					# Same changes
					merged_db.dialogs[dialog_id] = ours
				else:
					# Conflict
					conflicts.append(f"Dialog 0x{dialog_id:04X}: Both modified differently")
					merged_db.dialogs[dialog_id] = theirs  # Default to theirs
			
			elif we_changed:
				# Only we changed
				merged_db.dialogs[dialog_id] = ours
			
			elif they_changed:
				# Only they changed
				merged_db.dialogs[dialog_id] = theirs
			
			else:
				# No changes or only one version exists
				dialog = ours or theirs or ancestor
				if dialog:
					merged_db.dialogs[dialog_id] = dialog
		
		return merged_db, conflicts


def demo():
	"""Demonstration of diff and merge"""
	print("=" * 70)
	print("Dialog Diff and Merge Demo")
	print("=" * 70)
	print()
	
	# Create base database
	base_db = DialogDatabase()
	base_db.dialogs[0x0001] = DialogEntry(0x0001, "Hello, world!", bytearray(), 0x1000, 0x1000, 13)
	base_db.dialogs[0x0002] = DialogEntry(0x0002, "The Crystal shines.", bytearray(), 0x1020, 0x1020, 19)
	base_db.dialogs[0x0003] = DialogEntry(0x0003, "Good luck!", bytearray(), 0x1040, 0x1040, 10)
	
	# Create modified database
	modified_db = DialogDatabase()
	modified_db.dialogs[0x0001] = DialogEntry(0x0001, "Hello, brave warrior!", bytearray(), 0x1000, 0x1000, 21)  # Modified
	modified_db.dialogs[0x0002] = DialogEntry(0x0002, "The Crystal shines.", bytearray(), 0x1020, 0x1020, 19)  # Unchanged
	modified_db.dialogs[0x0004] = DialogEntry(0x0004, "New dialog added!", bytearray(), 0x1060, 0x1060, 17)  # Added
	# Note: 0x0003 removed
	
	# Perform diff
	print("Comparing base database with modified version...")
	print()
	
	differ = DialogDiffer(base_db, modified_db)
	diffs = differ.compare()
	
	# Print report
	print(differ.generate_report())
	
	# Test merge
	print("\n" + "=" * 70)
	print("Testing merge...")
	print("=" * 70)
	print()
	
	merger = DialogMerger(base_db)
	merged_db, conflicts = merger.merge_changes(modified_db, conflict_resolution='theirs')
	
	print(f"Merged database has {len(merged_db.dialogs)} dialogs")
	print(f"Conflicts encountered: {len(conflicts)}")
	
	if conflicts:
		print("\nConflicts:")
		for conflict in conflicts:
			print(f"  • {conflict}")
	
	print("\nMerged dialogs:")
	for dialog_id, dialog in sorted(merged_db.dialogs.items()):
		print(f"  0x{dialog_id:04X}: {dialog.text}")
	
	print("\n✓ Diff and merge demo complete!")


if __name__ == '__main__':
	demo()
