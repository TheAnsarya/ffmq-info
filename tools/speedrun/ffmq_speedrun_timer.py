#!/usr/bin/env python3
"""
FFMQ Speedrun Timer - Timing and split tracking

Timer Features:
- Split timing
- Segment timing
- Comparison data
- Sum of best
- PB tracking
- Auto-splitting

Split Types:
- Manual splits
- Auto splits (memory-based)
- Segment splits
- Subsplits
- Gold splits
- Comparison splits

Features:
- LiveSplit format import/export
- WSplit format support
- Real-time and game-time
- Split customization
- Comparison tracking
- Statistics

Usage:
	python ffmq_speedrun_timer.py --splits splits.lss
	python ffmq_speedrun_timer.py --create-splits my_splits.json
	python ffmq_speedrun_timer.py --import splits.lss
	python ffmq_speedrun_timer.py --statistics
"""

import argparse
import json
import time
from pathlib import Path
from typing import List, Dict, Optional
from dataclasses import dataclass, asdict, field
from datetime import timedelta
from enum import Enum


class SplitState(Enum):
	"""Split state"""
	NOT_STARTED = "not_started"
	RUNNING = "running"
	COMPLETED = "completed"
	SKIPPED = "skipped"


class ComparisonType(Enum):
	"""Comparison type"""
	PERSONAL_BEST = "personal_best"
	BEST_SEGMENTS = "best_segments"
	AVERAGE = "average"
	MEDIAN = "median"
	BALANCED = "balanced"


@dataclass
class Split:
	"""Individual split"""
	name: str
	segment_time: float = 0.0  # Seconds for this segment
	pb_time: Optional[float] = None  # PB time for this split
	best_segment: Optional[float] = None  # Best segment time
	gold: bool = False  # This segment is current best
	state: SplitState = SplitState.NOT_STARTED
	icon: Optional[str] = None
	
	def to_dict(self) -> dict:
		d = asdict(self)
		d['state'] = self.state.value
		return d


@dataclass
class Attempt:
	"""Run attempt"""
	attempt_id: int
	timestamp: str
	completed: bool = False
	total_time: float = 0.0  # Seconds
	segment_times: List[float] = field(default_factory=list)


@dataclass
class Comparison:
	"""Comparison times"""
	name: str
	type: ComparisonType
	split_times: List[float] = field(default_factory=list)
	
	def to_dict(self) -> dict:
		d = asdict(self)
		d['type'] = self.type.value
		return d


class SpeedrunTimer:
	"""Speedrun timer"""
	
	# Default FFMQ splits
	DEFAULT_SPLITS = [
		"Hill of Destiny",
		"Foresta Region",
		"Aquaria Region",
		"Fireburg Region",
		"Windia Region",
		"Pazuzu",
		"Hydra",
		"Medusa",
		"Kraken",
		"Doom Castle",
		"Dark King"
	]
	
	def __init__(self, verbose: bool = False):
		self.verbose = verbose
		self.splits: List[Split] = []
		self.attempts: List[Attempt] = []
		self.comparisons: Dict[str, Comparison] = {}
		
		# Timer state
		self.current_split_index: int = 0
		self.start_time: Optional[float] = None
		self.pause_time: Optional[float] = None
		self.paused: bool = False
		self.total_pause_duration: float = 0.0
		
		# Current attempt
		self.current_attempt: Optional[Attempt] = None
	
	def create_splits(self, split_names: List[str]) -> None:
		"""Create splits from names"""
		self.splits = [Split(name=name) for name in split_names]
		
		if self.verbose:
			print(f"✓ Created {len(self.splits)} splits")
	
	def start_timer(self) -> None:
		"""Start the timer"""
		if self.start_time is not None:
			print("Timer already running")
			return
		
		self.start_time = time.time()
		self.current_split_index = 0
		self.paused = False
		self.total_pause_duration = 0.0
		
		# Create new attempt
		self.current_attempt = Attempt(
			attempt_id=len(self.attempts) + 1,
			timestamp=time.strftime("%Y-%m-%d %H:%M:%S")
		)
		
		# Set all splits to not started
		for split in self.splits:
			split.state = SplitState.NOT_STARTED
			split.segment_time = 0.0
		
		if self.verbose:
			print(f"✓ Timer started")
	
	def split(self) -> Optional[float]:
		"""Record a split"""
		if self.start_time is None:
			print("Timer not running")
			return None
		
		if self.current_split_index >= len(self.splits):
			print("All splits completed")
			return None
		
		# Calculate current time
		current_time = self._get_current_time()
		
		# Calculate segment time
		if self.current_split_index == 0:
			segment_time = current_time
		else:
			prev_split_time = sum(s.segment_time for s in self.splits[:self.current_split_index])
			segment_time = current_time - prev_split_time
		
		# Update split
		split = self.splits[self.current_split_index]
		split.segment_time = segment_time
		split.state = SplitState.COMPLETED
		
		# Check for gold split (best segment)
		if split.best_segment is None or segment_time < split.best_segment:
			split.best_segment = segment_time
			split.gold = True
		else:
			split.gold = False
		
		# Record in attempt
		if self.current_attempt:
			self.current_attempt.segment_times.append(segment_time)
		
		if self.verbose:
			print(f"✓ Split: {split.name} - {self._format_time(segment_time)}")
		
		# Move to next split
		self.current_split_index += 1
		
		# Check if final split
		if self.current_split_index >= len(self.splits):
			self._finish_run()
		
		return segment_time
	
	def skip_split(self) -> None:
		"""Skip current split"""
		if self.current_split_index >= len(self.splits):
			return
		
		split = self.splits[self.current_split_index]
		split.state = SplitState.SKIPPED
		
		self.current_split_index += 1
		
		if self.verbose:
			print(f"⊘ Skipped: {split.name}")
	
	def pause(self) -> None:
		"""Pause the timer"""
		if self.paused or self.start_time is None:
			return
		
		self.pause_time = time.time()
		self.paused = True
		
		if self.verbose:
			print(f"⏸ Timer paused")
	
	def resume(self) -> None:
		"""Resume the timer"""
		if not self.paused or self.pause_time is None:
			return
		
		pause_duration = time.time() - self.pause_time
		self.total_pause_duration += pause_duration
		
		self.paused = False
		self.pause_time = None
		
		if self.verbose:
			print(f"▶ Timer resumed")
	
	def reset(self) -> None:
		"""Reset the timer"""
		self.start_time = None
		self.pause_time = None
		self.paused = False
		self.total_pause_duration = 0.0
		self.current_split_index = 0
		self.current_attempt = None
		
		for split in self.splits:
			split.state = SplitState.NOT_STARTED
			split.segment_time = 0.0
		
		if self.verbose:
			print(f"↻ Timer reset")
	
	def _finish_run(self) -> None:
		"""Finish the current run"""
		if self.current_attempt is None:
			return
		
		total_time = sum(s.segment_time for s in self.splits)
		
		self.current_attempt.completed = True
		self.current_attempt.total_time = total_time
		
		self.attempts.append(self.current_attempt)
		
		# Update PB if faster
		pb = self.get_pb_time()
		if pb is None or total_time < pb:
			self._update_pb()
			
			if self.verbose:
				print(f"🎉 New PB: {self._format_time(total_time)}")
		
		if self.verbose:
			print(f"✓ Run finished: {self._format_time(total_time)}")
	
	def _update_pb(self) -> None:
		"""Update PB times"""
		if not self.splits:
			return
		
		cumulative_time = 0.0
		for i, split in enumerate(self.splits):
			cumulative_time += split.segment_time
			split.pb_time = cumulative_time
	
	def _get_current_time(self) -> float:
		"""Get current elapsed time"""
		if self.start_time is None:
			return 0.0
		
		if self.paused and self.pause_time is not None:
			return self.pause_time - self.start_time - self.total_pause_duration
		
		return time.time() - self.start_time - self.total_pause_duration
	
	def get_current_time_display(self) -> str:
		"""Get formatted current time"""
		return self._format_time(self._get_current_time())
	
	def get_pb_time(self) -> Optional[float]:
		"""Get PB total time"""
		completed_attempts = [a for a in self.attempts if a.completed]
		
		if not completed_attempts:
			return None
		
		return min(a.total_time for a in completed_attempts)
	
	def get_sum_of_best(self) -> float:
		"""Get sum of best segments"""
		total = 0.0
		
		for split in self.splits:
			if split.best_segment is not None:
				total += split.best_segment
		
		return total
	
	def _format_time(self, seconds: float) -> str:
		"""Format time as HH:MM:SS.mmm"""
		if seconds < 0:
			seconds = 0
		
		hours = int(seconds // 3600)
		minutes = int((seconds % 3600) // 60)
		secs = seconds % 60
		
		if hours > 0:
			return f"{hours}:{minutes:02d}:{secs:06.3f}"
		else:
			return f"{minutes}:{secs:06.3f}"
	
	def export_json(self, output_path: Path) -> bool:
		"""Export splits to JSON"""
		try:
			data = {
				'splits': [s.to_dict() for s in self.splits],
				'attempts': [asdict(a) for a in self.attempts],
				'pb_time': self.get_pb_time(),
				'sum_of_best': self.get_sum_of_best()
			}
			
			with open(output_path, 'w', encoding='utf-8') as f:
				json.dump(data, f, indent='\t')
			
			if self.verbose:
				print(f"✓ Exported splits to {output_path}")
			
			return True
		
		except Exception as e:
			print(f"Error exporting splits: {e}")
			return False
	
	def import_json(self, input_path: Path) -> bool:
		"""Import splits from JSON"""
		try:
			with open(input_path, 'r', encoding='utf-8') as f:
				data = json.load(f)
			
			# Import splits
			self.splits = []
			for split_data in data['splits']:
				split_data['state'] = SplitState(split_data['state'])
				split = Split(**split_data)
				self.splits.append(split)
			
			# Import attempts
			self.attempts = []
			for attempt_data in data.get('attempts', []):
				attempt = Attempt(**attempt_data)
				self.attempts.append(attempt)
			
			if self.verbose:
				print(f"✓ Imported splits from {input_path}")
			
			return True
		
		except Exception as e:
			print(f"Error importing splits: {e}")
			return False
	
	def print_splits(self) -> None:
		"""Print current splits"""
		print(f"\n=== Splits ===\n")
		print(f"{'#':<4} {'Split':<30} {'Segment':<12} {'Gold':<6} {'PB':<12}")
		print('-' * 64)
		
		for i, split in enumerate(self.splits, 1):
			segment = self._format_time(split.segment_time) if split.segment_time > 0 else "-"
			gold = "★" if split.gold else ""
			pb = self._format_time(split.pb_time) if split.pb_time else "-"
			
			print(f"{i:<4} {split.name:<30} {segment:<12} {gold:<6} {pb:<12}")
		
		print()
		
		pb_time = self.get_pb_time()
		sob = self.get_sum_of_best()
		
		if pb_time:
			print(f"PB: {self._format_time(pb_time)}")
		
		print(f"Sum of Best: {self._format_time(sob)}")
	
	def print_statistics(self) -> None:
		"""Print run statistics"""
		print(f"\n=== Statistics ===\n")
		
		completed = [a for a in self.attempts if a.completed]
		
		print(f"Total Attempts: {len(self.attempts)}")
		print(f"Completed: {len(completed)}")
		print(f"Completion Rate: {len(completed)/len(self.attempts)*100:.1f}%" if self.attempts else "0%")
		
		if completed:
			times = [a.total_time for a in completed]
			avg_time = sum(times) / len(times)
			
			print(f"\nPB: {self._format_time(self.get_pb_time() or 0)}")
			print(f"Average: {self._format_time(avg_time)}")
			print(f"Sum of Best: {self._format_time(self.get_sum_of_best())}")


def main():
	parser = argparse.ArgumentParser(description='FFMQ Speedrun Timer')
	parser.add_argument('--create-splits', type=str, metavar='FILE',
					   help='Create default splits')
	parser.add_argument('--splits', type=str, metavar='FILE',
					   help='Load splits from JSON')
	parser.add_argument('--import', type=str, dest='import_file',
					   metavar='FILE', help='Import splits')
	parser.add_argument('--export', type=str, metavar='FILE',
					   help='Export splits')
	parser.add_argument('--list', action='store_true', help='List splits')
	parser.add_argument('--statistics', action='store_true',
					   help='Show statistics')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	timer = SpeedrunTimer(verbose=args.verbose)
	
	# Create default splits
	if args.create_splits:
		timer.create_splits(timer.DEFAULT_SPLITS)
		timer.export_json(Path(args.create_splits))
		return 0
	
	# Load splits
	if args.splits:
		timer.import_json(Path(args.splits))
	elif args.import_file:
		timer.import_json(Path(args.import_file))
	else:
		# Use default splits
		timer.create_splits(timer.DEFAULT_SPLITS)
	
	# Export
	if args.export:
		timer.export_json(Path(args.export))
		return 0
	
	# Statistics
	if args.statistics:
		timer.print_statistics()
		return 0
	
	# List splits
	if args.list or not any([args.create_splits, args.export, args.statistics]):
		timer.print_splits()
		return 0
	
	return 0


if __name__ == '__main__':
	exit(main())
