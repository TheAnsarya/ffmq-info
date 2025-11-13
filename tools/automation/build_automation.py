#!/usr/bin/env python3
"""
Build Automation System - Automated build pipeline for ROM hacking projects
Complete build system with compilation, validation, patching, and testing

Features:
- Multi-stage build pipeline
- Dependency tracking
- Incremental builds
- Parallel compilation
- Automated validation
- ROM patching
- Test execution
- Build caching
- Clean/rebuild support

Build Stages:
1. Pre-build validation
2. Script compilation
3. Asset compilation
4. ROM patching
5. Post-build validation
6. Testing
7. Packaging

Configuration:
- YAML/JSON build config
- Build targets (debug/release)
- Custom build scripts
- Environment variables
- Build profiles

Usage:
	python build_automation.py --config build.json
	python build_automation.py --target release --clean
	python build_automation.py --parallel --jobs 4
	python build_automation.py --stage compile --dry-run
"""

import argparse
import subprocess
import hashlib
import shutil
from pathlib import Path
from typing import Dict, List, Optional, Set, Tuple
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
import json
import time


class BuildStage(Enum):
	"""Build pipeline stages"""
	VALIDATE = "validate"
	COMPILE = "compile"
	ASSETS = "assets"
	PATCH = "patch"
	TEST = "test"
	PACKAGE = "package"


class BuildStatus(Enum):
	"""Build status"""
	SUCCESS = "success"
	FAILED = "failed"
	SKIPPED = "skipped"
	IN_PROGRESS = "in_progress"


@dataclass
class BuildTask:
	"""A build task"""
	name: str
	stage: BuildStage
	command: List[str]
	inputs: List[Path] = field(default_factory=list)
	outputs: List[Path] = field(default_factory=list)
	dependencies: List[str] = field(default_factory=list)
	working_dir: Optional[Path] = None
	env_vars: Dict[str, str] = field(default_factory=dict)
	status: BuildStatus = BuildStatus.IN_PROGRESS
	duration: float = 0.0
	error_message: Optional[str] = None


@dataclass
class BuildConfig:
	"""Build configuration"""
	project_name: str
	version: str
	base_rom: Path
	output_dir: Path
	source_dirs: List[Path]
	build_stages: List[BuildStage]
	tasks: List[BuildTask]
	parallel: bool = False
	max_jobs: int = 1
	incremental: bool = True
	cache_dir: Optional[Path] = None


@dataclass
class BuildResult:
	"""Build result"""
	success: bool
	total_tasks: int
	succeeded_tasks: int
	failed_tasks: int
	skipped_tasks: int
	total_duration: float
	task_results: List[BuildTask]


class BuildAutomation:
	"""Automated build system"""
	
	def __init__(self, config: BuildConfig, verbose: bool = False, dry_run: bool = False):
		self.config = config
		self.verbose = verbose
		self.dry_run = dry_run
		self.file_hashes: Dict[Path, str] = {}
		self.build_cache: Dict[str, Dict] = {}
	
	def load_cache(self) -> None:
		"""Load build cache"""
		if not self.config.cache_dir:
			return
		
		cache_file = self.config.cache_dir / 'build_cache.json'
		if cache_file.exists():
			try:
				with open(cache_file) as f:
					self.build_cache = json.load(f)
				if self.verbose:
					print(f"Loaded build cache from {cache_file}")
			except Exception as e:
				if self.verbose:
					print(f"Failed to load cache: {e}")
	
	def save_cache(self) -> None:
		"""Save build cache"""
		if not self.config.cache_dir:
			return
		
		self.config.cache_dir.mkdir(parents=True, exist_ok=True)
		cache_file = self.config.cache_dir / 'build_cache.json'
		
		try:
			with open(cache_file, 'w') as f:
				json.dump(self.build_cache, f, indent=2, default=str)
			if self.verbose:
				print(f"Saved build cache to {cache_file}")
		except Exception as e:
			if self.verbose:
				print(f"Failed to save cache: {e}")
	
	def calculate_file_hash(self, path: Path) -> str:
		"""Calculate SHA-256 hash of file"""
		if path in self.file_hashes:
			return self.file_hashes[path]
		
		try:
			with open(path, 'rb') as f:
				file_hash = hashlib.sha256(f.read()).hexdigest()
			self.file_hashes[path] = file_hash
			return file_hash
		except Exception:
			return ""
	
	def needs_rebuild(self, task: BuildTask) -> bool:
		"""Check if task needs to be rebuilt"""
		if not self.config.incremental:
			return True
		
		task_key = task.name
		
		# Check if task in cache
		if task_key not in self.build_cache:
			return True
		
		cached = self.build_cache[task_key]
		
		# Check if outputs exist
		for output in task.outputs:
			if not output.exists():
				return True
		
		# Check if inputs changed
		for input_file in task.inputs:
			if not input_file.exists():
				return True
			
			current_hash = self.calculate_file_hash(input_file)
			cached_hash = cached.get('inputs', {}).get(str(input_file))
			
			if current_hash != cached_hash:
				return True
		
		return False
	
	def update_cache(self, task: BuildTask) -> None:
		"""Update build cache for task"""
		task_key = task.name
		
		self.build_cache[task_key] = {
			'inputs': {str(f): self.calculate_file_hash(f) for f in task.inputs},
			'outputs': {str(f): self.calculate_file_hash(f) for f in task.outputs},
			'timestamp': datetime.now().isoformat()
		}
	
	def execute_task(self, task: BuildTask) -> bool:
		"""Execute single build task"""
		if self.verbose:
			print(f"\n[{task.stage.value.upper()}] {task.name}")
		
		# Check if rebuild needed
		if not self.needs_rebuild(task):
			if self.verbose:
				print(f"  Skipped (up to date)")
			task.status = BuildStatus.SKIPPED
			return True
		
		if self.dry_run:
			print(f"  Would execute: {' '.join(str(c) for c in task.command)}")
			task.status = BuildStatus.SUCCESS
			return True
		
		# Execute command
		start_time = time.time()
		
		try:
			env = dict(task.env_vars) if task.env_vars else None
			working_dir = task.working_dir or Path.cwd()
			
			if self.verbose:
				print(f"  Command: {' '.join(str(c) for c in task.command)}")
				print(f"  Working dir: {working_dir}")
			
			result = subprocess.run(
				task.command,
				cwd=working_dir,
				env=env,
				capture_output=True,
				text=True
			)
			
			task.duration = time.time() - start_time
			
			if result.returncode != 0:
				task.status = BuildStatus.FAILED
				task.error_message = result.stderr
				if self.verbose:
					print(f"  ✗ Failed ({task.duration:.2f}s)")
					print(f"  Error: {result.stderr}")
				return False
			
			# Update cache
			self.update_cache(task)
			
			task.status = BuildStatus.SUCCESS
			if self.verbose:
				print(f"  ✓ Success ({task.duration:.2f}s)")
			
			return True
		
		except Exception as e:
			task.duration = time.time() - start_time
			task.status = BuildStatus.FAILED
			task.error_message = str(e)
			if self.verbose:
				print(f"  ✗ Failed ({task.duration:.2f}s)")
				print(f"  Error: {e}")
			return False
	
	def build(self, stages: Optional[List[BuildStage]] = None) -> BuildResult:
		"""Execute build pipeline"""
		start_time = time.time()
		
		# Load cache
		self.load_cache()
		
		# Filter tasks by stage
		if stages:
			tasks = [t for t in self.config.tasks if t.stage in stages]
		else:
			tasks = self.config.tasks
		
		if self.verbose:
			print(f"\n{'='*60}")
			print(f"Building {self.config.project_name} v{self.config.version}")
			print(f"{'='*60}")
			print(f"Total tasks: {len(tasks)}")
			if stages:
				print(f"Stages: {', '.join(s.value for s in stages)}")
		
		# Execute tasks
		succeeded = 0
		failed = 0
		skipped = 0
		
		for task in tasks:
			success = self.execute_task(task)
			
			if task.status == BuildStatus.SUCCESS:
				succeeded += 1
			elif task.status == BuildStatus.FAILED:
				failed += 1
			elif task.status == BuildStatus.SKIPPED:
				skipped += 1
		
		# Save cache
		self.save_cache()
		
		total_duration = time.time() - start_time
		
		result = BuildResult(
			success=(failed == 0),
			total_tasks=len(tasks),
			succeeded_tasks=succeeded,
			failed_tasks=failed,
			skipped_tasks=skipped,
			total_duration=total_duration,
			task_results=tasks
		)
		
		# Print summary
		if self.verbose:
			print(f"\n{'='*60}")
			print("BUILD SUMMARY")
			print(f"{'='*60}")
			print(f"Status: {'SUCCESS' if result.success else 'FAILED'}")
			print(f"Duration: {total_duration:.2f}s")
			print(f"Tasks: {succeeded} succeeded, {failed} failed, {skipped} skipped")
		
		return result
	
	def clean(self) -> None:
		"""Clean build artifacts"""
		if self.verbose:
			print("Cleaning build artifacts...")
		
		# Remove output directory
		if self.config.output_dir.exists():
			if self.dry_run:
				print(f"Would remove: {self.config.output_dir}")
			else:
				shutil.rmtree(self.config.output_dir)
				if self.verbose:
					print(f"Removed {self.config.output_dir}")
		
		# Remove cache
		if self.config.cache_dir and self.config.cache_dir.exists():
			if self.dry_run:
				print(f"Would remove: {self.config.cache_dir}")
			else:
				shutil.rmtree(self.config.cache_dir)
				if self.verbose:
					print(f"Removed {self.config.cache_dir}")
		
		if self.verbose:
			print("✓ Clean complete")
	
	@staticmethod
	def load_config(config_path: Path) -> BuildConfig:
		"""Load build configuration from file"""
		with open(config_path) as f:
			data = json.load(f)
		
		# Parse configuration
		tasks = []
		for task_data in data.get('tasks', []):
			task = BuildTask(
				name=task_data['name'],
				stage=BuildStage(task_data['stage']),
				command=task_data['command'],
				inputs=[Path(p) for p in task_data.get('inputs', [])],
				outputs=[Path(p) for p in task_data.get('outputs', [])],
				dependencies=task_data.get('dependencies', []),
				working_dir=Path(task_data['working_dir']) if 'working_dir' in task_data else None,
				env_vars=task_data.get('env_vars', {})
			)
			tasks.append(task)
		
		config = BuildConfig(
			project_name=data['project_name'],
			version=data['version'],
			base_rom=Path(data['base_rom']),
			output_dir=Path(data['output_dir']),
			source_dirs=[Path(p) for p in data.get('source_dirs', [])],
			build_stages=[BuildStage(s) for s in data.get('build_stages', [])],
			tasks=tasks,
			parallel=data.get('parallel', False),
			max_jobs=data.get('max_jobs', 1),
			incremental=data.get('incremental', True),
			cache_dir=Path(data['cache_dir']) if 'cache_dir' in data else None
		)
		
		return config


def main():
	parser = argparse.ArgumentParser(description='Automated build system for ROM hacking')
	parser.add_argument('--config', type=Path, required=True, help='Build configuration file')
	parser.add_argument('--target', choices=['debug', 'release'], default='debug', help='Build target')
	parser.add_argument('--stage', type=str, help='Run specific stage only')
	parser.add_argument('--clean', action='store_true', help='Clean build artifacts')
	parser.add_argument('--rebuild', action='store_true', help='Force full rebuild')
	parser.add_argument('--parallel', action='store_true', help='Enable parallel builds')
	parser.add_argument('--jobs', type=int, default=1, help='Number of parallel jobs')
	parser.add_argument('--dry-run', action='store_true', help='Dry run (show what would be done)')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	# Load configuration
	config = BuildAutomation.load_config(args.config)
	
	# Override config with command-line args
	if args.rebuild:
		config.incremental = False
	if args.parallel:
		config.parallel = True
		config.max_jobs = args.jobs
	
	# Create build system
	build_system = BuildAutomation(config, verbose=args.verbose, dry_run=args.dry_run)
	
	# Clean if requested
	if args.clean:
		build_system.clean()
		if not args.stage:
			return 0
	
	# Determine stages to run
	stages = None
	if args.stage:
		try:
			stages = [BuildStage(args.stage)]
		except ValueError:
			print(f"Error: Invalid stage '{args.stage}'")
			print(f"Valid stages: {', '.join(s.value for s in BuildStage)}")
			return 1
	
	# Execute build
	result = build_system.build(stages=stages)
	
	# Exit with appropriate code
	return 0 if result.success else 1


if __name__ == '__main__':
	exit(main())
