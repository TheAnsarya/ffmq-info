#!/usr/bin/env python3
"""
FFMQ Development - Chat Log and Documentation Updater
Automatically updates chat logs and documentation when commits are made or significant changes occur.

Usage:
	python tools/update_chat_log.py --commit "commit message"
	python tools/update_chat_log.py --change "description of change"
	python tools/update_chat_log.py --question "question asked"
"""

import os
import sys
import argparse
from datetime import datetime
from pathlib import Path


class ChatLogUpdater:
	"""Manages automatic updates to chat logs and documentation"""
	
	def __init__(self):
		"""Initialize the chat log updater with project paths"""
		# Get project root directory
		self.project_root = Path(__file__).parent.parent
		
		# Chat log directory
		self.chat_log_dir = self.project_root / "~docs" / "copilot-chats"
		
		# Current session log file (based on today's date)
		self.current_date = datetime.now().strftime("%Y-%m-%d")
		self.current_log = self.chat_log_dir / f"{self.current_date}-session.md"
		
		# Ensure chat log directory exists
		self.chat_log_dir.mkdir(parents=True, exist_ok=True)
	
	def get_git_status(self) -> dict:
		"""
		Get current git status including branch, last commit, and changed files.
		
		Returns:
			Dictionary with git status information
		
		Reference: https://git-scm.com/docs/git-status
		"""
		import subprocess
		
		try:
			# Get current branch
			branch = subprocess.check_output(
				["git", "rev-parse", "--abbrev-ref", "HEAD"],
				cwd=self.project_root,
				text=True
			).strip()
			
			# Get last commit hash and message
			last_commit = subprocess.check_output(
				["git", "log", "-1", "--format=%H|%s"],
				cwd=self.project_root,
				text=True
			).strip()
			
			if last_commit:
				commit_hash, commit_msg = last_commit.split("|", 1)
			else:
				commit_hash, commit_msg = "none", "No commits yet"
			
			# Get changed files
			changed_files = subprocess.check_output(
				["git", "status", "--short"],
				cwd=self.project_root,
				text=True
			).strip()
			
			return {
				"branch": branch,
				"last_commit_hash": commit_hash[:7],
				"last_commit_msg": commit_msg,
				"changed_files": changed_files.split("\n") if changed_files else []
			}
			
		except subprocess.CalledProcessError as e:
			print(f"Warning: Could not get git status: {e}")
			return {
				"branch": "unknown",
				"last_commit_hash": "unknown",
				"last_commit_msg": "unknown",
				"changed_files": []
			}
	
	def initialize_session_log(self):
		"""
		Create a new session log file if it doesn't exist.
		
		Each day gets a new session log file to track all work done that day.
		"""
		if not self.current_log.exists():
			git_status = self.get_git_status()
			
			content = f"""# Copilot Chat Log - {self.current_date}
**Date:** {datetime.now().strftime("%B %d, %Y")}  
**Branch:** {git_status['branch']}  
**Session Start:** {datetime.now().strftime("%H:%M:%S")}

## Session Overview
This log tracks all development work, questions, and decisions made during this session.

## Git Status at Session Start
- **Branch:** {git_status['branch']}
- **Last Commit:** {git_status['last_commit_hash']} - {git_status['last_commit_msg']}

## Activity Log

"""
			
			with open(self.current_log, 'w', encoding='utf-8') as f:
				f.write(content)
			
			print(f"✓ Created new session log: {self.current_log.name}")
	
	def add_commit_entry(self, commit_hash: str, commit_message: str, files_changed: list):
		"""
		Add a git commit entry to the chat log.
		
		Args:
			commit_hash: Short git commit hash
			commit_message: Commit message text
			files_changed: List of files modified in the commit
		
		Reference: https://git-scm.com/book/en/v2/Git-Basics-Recording-Changes-to-the-Repository
		"""
		self.initialize_session_log()
		
		timestamp = datetime.now().strftime("%H:%M:%S")
		
		entry = f"""
### [{timestamp}] Git Commit: {commit_hash}

**Message:** {commit_message}

**Files Changed:**
"""
		
		# Add files changed
		for file in files_changed:
			entry += f"- `{file}`\n"
		
		entry += "\n"
		
		# Append to log file
		with open(self.current_log, 'a', encoding='utf-8') as f:
			f.write(entry)
		
		print(f"✓ Added commit entry to {self.current_log.name}")
	
	def add_change_entry(self, description: str, files_affected: list = None):
		"""
		Add a significant change entry to the chat log.
		
		Args:
			description: Description of the change made
			files_affected: Optional list of files affected by the change
		"""
		self.initialize_session_log()
		
		timestamp = datetime.now().strftime("%H:%M:%S")
		
		entry = f"""
### [{timestamp}] Change Made

**Description:** {description}

"""
		
		if files_affected:
			entry += "**Files Affected:**\n"
			for file in files_affected:
				entry += f"- `{file}`\n"
			entry += "\n"
		
		# Append to log file
		with open(self.current_log, 'a', encoding='utf-8') as f:
			f.write(entry)
		
		print(f"✓ Added change entry to {self.current_log.name}")
	
	def add_question_entry(self, question: str, answer: str = None):
		"""
		Add a question (and optional answer) to the chat log.
		
		Args:
			question: Question that was asked
			answer: Optional answer to the question
		"""
		self.initialize_session_log()
		
		timestamp = datetime.now().strftime("%H:%M:%S")
		
		entry = f"""
### [{timestamp}] Question

**Q:** {question}

"""
		
		if answer:
			entry += f"**A:** {answer}\n\n"
		else:
			entry += "**A:** _(To be answered)_\n\n"
		
		# Append to log file
		with open(self.current_log, 'a', encoding='utf-8') as f:
			f.write(entry)
		
		print(f"✓ Added question entry to {self.current_log.name}")
	
	def add_note_entry(self, note: str):
		"""
		Add a note or decision to the chat log.
		
		Notes are for tracking thoughts, decisions, or observations
		that don't fit cleanly into commit/change/question categories.
		
		Args:
			note: Note text to record
		"""
		self.initialize_session_log()
		
		timestamp = datetime.now().strftime("%H:%M:%S")
		
		entry = f"""
### [{timestamp}] Note

**Note:** {note}

"""
		
		# Append to log file
		with open(self.current_log, 'a', encoding='utf-8') as f:
			f.write(entry)
		
		print(f"✓ Added note to {self.current_log.name}")
	
	def update_main_log(self):
		"""
		Update the main project reorganization log with today's session.
		
		Links the daily session log to the main project log for complete history.
		"""
		main_log = self.chat_log_dir / "2025-01-24-project-reorganization.md"
		
		if not main_log.exists():
			print("Warning: Main project log not found")
			return
		
		# Check if today's session is already linked
		with open(main_log, 'r', encoding='utf-8') as f:
			content = f.read()
		
		session_link = f"- **{self.current_log.name}**"
		
		if session_link not in content:
			# Add session link to main log
			session_entry = f"\n### Session {self.current_date}\nSee detailed log: [{self.current_log.name}]({self.current_log.name})\n"
			
			# Append to main log
			with open(main_log, 'a', encoding='utf-8') as f:
				f.write(session_entry)
			
			print(f"✓ Linked session to main project log")
	
	def generate_summary(self):
		"""
		Generate a summary of today's session.
		
		Returns:
			Summary text of all activities in current session
		"""
		if not self.current_log.exists():
			return "No session activity recorded today."
		
		with open(self.current_log, 'r', encoding='utf-8') as f:
			content = f.read()
		
		# Count different types of entries
		commits = content.count("### [")
		changes = content.count("Change Made")
		questions = content.count("Question")
		
		summary = f"""
Session Summary for {self.current_date}
========================================
Total Commits Logged: {commits}
Changes Documented: {changes}
Questions Recorded: {questions}

Full log: {self.current_log}
"""
		
		return summary


def main():
	"""Main entry point for the chat log updater"""
	parser = argparse.ArgumentParser(
		description="Update chat logs and documentation for FFMQ development"
	)
	
	# Add mutually exclusive group for different types of updates
	group = parser.add_mutually_exclusive_group(required=True)
	group.add_argument(
		"--commit",
		type=str,
		help="Log a git commit with the specified message"
	)
	group.add_argument(
		"--change",
		type=str,
		help="Log a significant change with description"
	)
	group.add_argument(
		"--question",
		type=str,
		help="Log a question that was asked"
	)
	group.add_argument(
		"--note",
		type=str,
		help="Log a note, thought, or decision"
	)
	group.add_argument(
		"--summary",
		action="store_true",
		help="Display summary of today's session"
	)
	
	# Optional arguments
	parser.add_argument(
		"--files",
		nargs="+",
		help="List of files affected by the change"
	)
	parser.add_argument(
		"--answer",
		type=str,
		help="Answer to the question (used with --question)"
	)
	
	args = parser.parse_args()
	
	# Create updater instance
	updater = ChatLogUpdater()
	
	# Process based on argument type
	if args.commit:
		# Get git status for commit details
		git_status = updater.get_git_status()
		files = args.files if args.files else git_status.get("changed_files", [])
		
		updater.add_commit_entry(
			git_status["last_commit_hash"],
			args.commit,
			files
		)
		updater.update_main_log()
		
	elif args.change:
		updater.add_change_entry(args.change, args.files)
		updater.update_main_log()
		
	elif args.question:
		updater.add_question_entry(args.question, args.answer)
		updater.update_main_log()
		
	elif args.note:
		updater.add_note_entry(args.note)
		updater.update_main_log()
		
	elif args.summary:
		print(updater.generate_summary())


if __name__ == "__main__":
	main()
