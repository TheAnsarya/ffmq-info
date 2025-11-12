#!/usr/bin/env python3
"""
FFMQ Development - Automatic Activity Tracker
Monitors all file changes and automatically logs development activity.

This runs in the background and automatically logs:
- File modifications as they happen
- Code changes with file tracking
- Git operations (commits, checkouts, etc.)
- All development activity

Usage:
	python tools/auto_tracker.py start   # Start background tracking
	python tools/auto_tracker.py stop	# Stop background tracking
	python tools/auto_tracker.py status  # Check if running
"""

import os
import sys
import time
import json
import hashlib
import subprocess
from pathlib import Path
from datetime import datetime
from typing import Dict, Set, List


class AutoTracker:
	"""Automatic activity tracker for FFMQ development"""
	
	def __init__(self):
		"""Initialize the automatic tracker"""
		self.project_root = Path(__file__).parent.parent
		self.state_file = self.project_root / ".auto_tracker_state.json"
		self.pid_file = self.project_root / ".auto_tracker.pid"
		
		# Directories to watch
		self.watch_dirs = [
			self.project_root / "src",
			self.project_root / "tools",
			self.project_root / "docs",
			self.project_root / ".vscode",
		]
		
		# File extensions to track
		self.track_extensions = {
			'.py', '.s', '.asm', '.inc', '.md', '.txt',
			'.json', '.ps1', '.bat', '.sh', '.c', '.cpp', '.h'
		}
		
		# Load or initialize state
		self.state = self.load_state()
		
		# Chat log updater
		sys.path.insert(0, str(self.project_root / "tools"))
		from update_chat_log import ChatLogUpdater
		self.logger = ChatLogUpdater()
	
	def load_state(self) -> dict:
		"""
		Load tracker state from file.
		
		State tracks file hashes to detect actual changes vs. just timestamps.
		"""
		if self.state_file.exists():
			try:
				with open(self.state_file, 'r') as f:
					return json.load(f)
			except Exception:
				pass
		
		return {
			'file_hashes': {},
			'last_activity': None,
			'session_start': datetime.now().isoformat()
		}
	
	def save_state(self):
		"""Save tracker state to file"""
		try:
			with open(self.state_file, 'w') as f:
				json.dump(self.state, f, indent=2)
		except Exception as e:
			print(f"Warning: Could not save state: {e}")
	
	def get_file_hash(self, filepath: Path) -> str:
		"""
		Get hash of file contents for change detection.
		
		Args:
			filepath: Path to file to hash
		
		Returns:
			MD5 hash of file contents
		"""
		try:
			with open(filepath, 'rb') as f:
				return hashlib.md5(f.read()).hexdigest()
		except Exception:
			return ""
	
	def scan_for_changes(self) -> Dict[str, List[str]]:
		"""
		Scan watched directories for file changes.
		
		Returns:
			Dictionary with 'modified', 'added', 'deleted' file lists
		"""
		changes = {
			'modified': [],
			'added': [],
			'deleted': []
		}
		
		current_hashes = {}
		
		# Scan all watched directories
		for watch_dir in self.watch_dirs:
			if not watch_dir.exists():
				continue
			
			# Recursively find all trackable files
			for filepath in watch_dir.rglob('*'):
				if not filepath.is_file():
					continue
				
				if filepath.suffix not in self.track_extensions:
					continue
				
				# Get relative path for storage
				rel_path = str(filepath.relative_to(self.project_root))
				
				# Calculate hash
				file_hash = self.get_file_hash(filepath)
				current_hashes[rel_path] = file_hash
				
				# Check if file is new or modified
				if rel_path not in self.state['file_hashes']:
					changes['added'].append(rel_path)
				elif self.state['file_hashes'][rel_path] != file_hash:
					changes['modified'].append(rel_path)
		
		# Check for deleted files
		for old_path in self.state['file_hashes']:
			if old_path not in current_hashes:
				changes['deleted'].append(old_path)
		
		# Update state with current hashes
		self.state['file_hashes'] = current_hashes
		
		return changes
	
	def get_git_status(self) -> dict:
		"""
		Get current git status.
		
		Returns:
			Dictionary with branch, commit info
		"""
		try:
			branch = subprocess.check_output(
				['git', 'rev-parse', '--abbrev-ref', 'HEAD'],
				cwd=self.project_root,
				text=True
			).strip()
			
			last_commit = subprocess.check_output(
				['git', 'log', '-1', '--format=%h|%s'],
				cwd=self.project_root,
				text=True
			).strip()
			
			if last_commit:
				commit_hash, commit_msg = last_commit.split('|', 1)
			else:
				commit_hash = ""
				commit_msg = ""
			
			return {
				'branch': branch,
				'commit_hash': commit_hash,
				'commit_msg': commit_msg
			}
		except Exception:
			return {
				'branch': 'unknown',
				'commit_hash': '',
				'commit_msg': ''
			}
	
	def auto_log_changes(self, changes: Dict[str, List[str]]):
		"""
		Automatically log file changes to chat log.
		
		Args:
			changes: Dictionary with modified/added/deleted file lists
		"""
		total_changes = len(changes['modified']) + len(changes['added']) + len(changes['deleted'])
		
		if total_changes == 0:
			return
		
		# Build description
		parts = []
		
		if changes['modified']:
			parts.append(f"Modified {len(changes['modified'])} file(s)")
		if changes['added']:
			parts.append(f"Added {len(changes['added'])} file(s)")
		if changes['deleted']:
			parts.append(f"Deleted {len(changes['deleted'])} file(s)")
		
		description = f"Auto-tracked: {', '.join(parts)}"
		
		# Get all affected files
		all_files = changes['modified'] + changes['added'] + changes['deleted']
		
		# Log to chat
		try:
			self.logger.add_change_entry(description, all_files[:10])  # Limit to first 10 files
			print(f"✓ Auto-logged {total_changes} changes")
		except Exception as e:
			print(f"Warning: Could not auto-log changes: {e}")
		
		# Update last activity
		self.state['last_activity'] = datetime.now().isoformat()
	
	def track_session(self, interval: int = 60):
		"""
		Track development session automatically.
		
		Args:
			interval: Seconds between checks (default 60)
		
		Continuously monitors files and auto-logs changes.
		"""
		print("╔═══════════════════════════════════════════════════╗")
		print("║  FFMQ Automatic Activity Tracker - RUNNING	   ║")
		print("╚═══════════════════════════════════════════════════╝")
		print()
		print(f"Monitoring directories: {len(self.watch_dirs)}")
		print(f"Check interval: {interval} seconds")
		print(f"Tracking extensions: {', '.join(sorted(self.track_extensions))}")
		print()
		print("All file changes will be automatically logged!")
		print("Press Ctrl+C to stop tracking")
		print()
		
		# Save PID for stop command
		try:
			with open(self.pid_file, 'w') as f:
				f.write(str(os.getpid()))
		except Exception:
			pass
		
		try:
			while True:
				# Scan for changes
				changes = self.scan_for_changes()
				
				# Auto-log if changes found
				if any(changes.values()):
					self.auto_log_changes(changes)
				
				# Save state
				self.save_state()
				
				# Wait for next check
				time.sleep(interval)
				
		except KeyboardInterrupt:
			print()
			print("Stopping automatic tracker...")
			self.cleanup()
		except Exception as e:
			print(f"Error in tracking loop: {e}")
			self.cleanup()
	
	def cleanup(self):
		"""Clean up tracker resources"""
		if self.pid_file.exists():
			try:
				self.pid_file.unlink()
			except Exception:
				pass
		
		self.save_state()
		print("✓ Tracker stopped")
	
	def is_running(self) -> bool:
		"""
		Check if tracker is currently running.
		
		Returns:
			True if running, False otherwise
		"""
		if not self.pid_file.exists():
			return False
		
		try:
			with open(self.pid_file, 'r') as f:
				pid = int(f.read().strip())
			
			# Check if process exists (Windows and Unix compatible)
			try:
				os.kill(pid, 0)
				return True
			except OSError:
				return False
		except Exception:
			return False
	
	def stop(self):
		"""Stop the running tracker"""
		if not self.is_running():
			print("Tracker is not running")
			return False
		
		try:
			with open(self.pid_file, 'r') as f:
				pid = int(f.read().strip())
			
			print(f"Stopping tracker (PID: {pid})...")
			
			# Send termination signal
			try:
				if sys.platform == 'win32':
					subprocess.run(['taskkill', '/F', '/PID', str(pid)], check=True)
				else:
					os.kill(pid, 15)  # SIGTERM
				
				time.sleep(1)
				print("✓ Tracker stopped")
				return True
			except Exception as e:
				print(f"Error stopping tracker: {e}")
				return False
		except Exception as e:
			print(f"Error reading PID file: {e}")
			return False


def main():
	"""Main entry point for automatic tracker"""
	if len(sys.argv) < 2:
		print("Usage: python auto_tracker.py {start|stop|status}")
		sys.exit(1)
	
	command = sys.argv[1].lower()
	tracker = AutoTracker()
	
	if command == 'start':
		if tracker.is_running():
			print("Tracker is already running!")
			print("Use 'python tools/auto_tracker.py stop' to stop it first")
			sys.exit(1)
		
		# Get interval from command line or use default
		interval = int(sys.argv[2]) if len(sys.argv) > 2 else 60
		
		tracker.track_session(interval)
		
	elif command == 'stop':
		if not tracker.stop():
			sys.exit(1)
		
	elif command == 'status':
		if tracker.is_running():
			print("✓ Tracker is running")
			
			# Show last activity
			if tracker.state.get('last_activity'):
				print(f"Last activity: {tracker.state['last_activity']}")
			
			# Show tracked file count
			print(f"Tracking {len(tracker.state['file_hashes'])} files")
		else:
			print("✗ Tracker is not running")
			print("Start it with: python tools/auto_tracker.py start")
		
	else:
		print(f"Unknown command: {command}")
		print("Usage: python auto_tracker.py {start|stop|status}")
		sys.exit(1)


if __name__ == "__main__":
	main()
