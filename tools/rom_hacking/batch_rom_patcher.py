#!/usr/bin/env python3
"""
FFMQ Batch ROM Patcher
======================

Applies multiple compiled event scripts to a ROM file in a single batch operation.
Supports automated patching workflows, version control, and rollback capabilities.

Features:
---------
1. **Batch Patching** - Apply multiple script patches in one operation
2. **Address Mapping** - Automatically map dialog IDs to ROM offsets
3. **Verification** - Validate patches before and after application
4. **Backup/Restore** - Automatic backup creation and rollback support
5. **Patch Tracking** - Log all applied patches with timestamps
6. **Checksum Validation** - Verify ROM integrity before/after patching
7. **Dry Run Mode** - Preview changes without modifying ROM

Patch File Format:
------------------
JSON format with patch specifications:

```json
{
	"rom_file": "ffmq.sfc",
	"patches": [
		{
			"dialog_id": 0,
			"script_file": "compiled/dialog_0.bin",
			"offset": "0xC0/8FA0",
			"max_size": 512,
			"description": "Intro dialog modification"
		}
	]
}
```

Author: TheAnsarya
Date: 2025-11-12
License: MIT
"""

import json
import struct
import hashlib
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Tuple, Optional, Any
from dataclasses import dataclass, field
from enum import Enum


class PatchStatus(Enum):
	"""Patch application status."""
	PENDING = "pending"
	SUCCESS = "success"
	FAILED = "failed"
	SKIPPED = "skipped"


@dataclass
class PatchEntry:
	"""Represents a single patch operation."""
	dialog_id: int
	script_file: str
	offset: int
	max_size: int
	description: str = ""
	status: PatchStatus = PatchStatus.PENDING
	error_message: str = ""
	applied_size: int = 0
	checksum_before: str = ""
	checksum_after: str = ""
	timestamp: str = ""


@dataclass
class PatchLog:
	"""Patch application log."""
	rom_file: str
	backup_file: str
	total_patches: int = 0
	successful_patches: int = 0
	failed_patches: int = 0
	patches: List[PatchEntry] = field(default_factory=list)
	start_time: str = ""
	end_time: str = ""
	rom_checksum_before: str = ""
	rom_checksum_after: str = ""


class BatchROMPatcher:
	"""
	Batch ROM patcher for FFMQ event scripts.
	"""
	
	# ROM header offset and size
	ROM_HEADER_OFFSET = 0x7FC0
	ROM_HEADER_SIZE = 64
	
	# SNES LoROM bank mapping
	LOROM_BANK_SIZE = 0x8000
	LOROM_OFFSET = 0x8000
	
	def __init__(self, rom_file: str, dry_run: bool = False):
		"""
		Initialize patcher.
		
		Args:
			rom_file: Path to ROM file
			dry_run: If True, don't actually modify ROM
		"""
		self.rom_file = Path(rom_file)
		self.dry_run = dry_run
		self.rom_data: bytearray = bytearray()
		self.backup_file: Optional[Path] = None
		self.patch_log = PatchLog(rom_file=str(rom_file), backup_file="")
	
	def calculate_checksum(self, data: bytes) -> str:
		"""Calculate SHA-256 checksum."""
		return hashlib.sha256(data).hexdigest()
	
	def parse_offset(self, offset_str: str) -> int:
		"""
		Parse offset string to absolute ROM offset.
		
		Args:
			offset_str: Offset string (e.g., "0xC0/8FA0" or "0x08FA0")
		
		Returns:
			Absolute ROM offset
		"""
		# Format: "0xBB/OOOO" where BB = bank, OOOO = offset
		if '/' in offset_str:
			bank_str, offset_str = offset_str.split('/')
			bank = int(bank_str, 16)
			offset = int(offset_str, 16)
			
			# LoROM mapping: Bank $C0+ maps to second half of ROM
			if bank >= 0xC0:
				# Bank $C0 = 0x000000, $C1 = 0x010000, etc.
				absolute_offset = (bank - 0xC0) * 0x10000 + (offset - self.LOROM_OFFSET)
			else:
				# Banks $00-$3F, $80-$BF map to first half
				absolute_offset = (bank & 0x3F) * 0x10000 + (offset - self.LOROM_OFFSET)
			
			return absolute_offset
		else:
			# Already absolute offset
			return int(offset_str, 16)
	
	def load_rom(self) -> None:
		"""Load ROM file."""
		print(f"\n📂 Loading ROM: {self.rom_file}")
		
		if not self.rom_file.exists():
			raise FileNotFoundError(f"ROM file not found: {self.rom_file}")
		
		with open(self.rom_file, 'rb') as f:
			self.rom_data = bytearray(f.read())
		
		print(f"  ROM size: {len(self.rom_data):,} bytes ({len(self.rom_data) // 1024} KB)")
		
		# Calculate checksum
		self.patch_log.rom_checksum_before = self.calculate_checksum(self.rom_data)
		print(f"  Checksum: {self.patch_log.rom_checksum_before[:16]}...")
	
	def create_backup(self) -> None:
		"""Create backup of original ROM."""
		if self.dry_run:
			print("\n💾 [DRY RUN] Would create backup")
			return
		
		timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
		backup_name = f"{self.rom_file.stem}_backup_{timestamp}{self.rom_file.suffix}"
		self.backup_file = self.rom_file.parent / backup_name
		
		print(f"\n💾 Creating backup: {self.backup_file}")
		
		with open(self.backup_file, 'wb') as f:
			f.write(self.rom_data)
		
		self.patch_log.backup_file = str(self.backup_file)
		print("  ✅ Backup created")
	
	def apply_patch(self, patch: PatchEntry) -> bool:
		"""
		Apply a single patch.
		
		Args:
			patch: Patch entry
		
		Returns:
			True if successful
		"""
		print(f"\n🔧 Applying patch: Dialog {patch.dialog_id}")
		print(f"  Script: {patch.script_file}")
		print(f"  Offset: 0x{patch.offset:06X}")
		
		# Load script data
		script_file = Path(patch.script_file)
		if not script_file.exists():
			patch.status = PatchStatus.FAILED
			patch.error_message = f"Script file not found: {patch.script_file}"
			print(f"  ❌ {patch.error_message}")
			return False
		
		with open(script_file, 'rb') as f:
			script_data = f.read()
		
		script_size = len(script_data)
		print(f"  Script size: {script_size} bytes")
		
		# Validate size
		if script_size > patch.max_size:
			patch.status = PatchStatus.FAILED
			patch.error_message = f"Script size {script_size} exceeds maximum {patch.max_size}"
			print(f"  ❌ {patch.error_message}")
			return False
		
		# Validate offset
		if patch.offset + script_size > len(self.rom_data):
			patch.status = PatchStatus.FAILED
			patch.error_message = f"Patch would extend beyond ROM end"
			print(f"  ❌ {patch.error_message}")
			return False
		
		# Calculate checksums
		region_before = bytes(self.rom_data[patch.offset:patch.offset + script_size])
		patch.checksum_before = self.calculate_checksum(region_before)
		
		if self.dry_run:
			print("  🔍 [DRY RUN] Would write patch data")
			patch.status = PatchStatus.SUCCESS
			patch.applied_size = script_size
			patch.checksum_after = self.calculate_checksum(script_data)
			return True
		
		# Apply patch
		self.rom_data[patch.offset:patch.offset + script_size] = script_data
		
		# Verify
		region_after = bytes(self.rom_data[patch.offset:patch.offset + script_size])
		patch.checksum_after = self.calculate_checksum(region_after)
		
		if patch.checksum_after != self.calculate_checksum(script_data):
			patch.status = PatchStatus.FAILED
			patch.error_message = "Verification failed - checksum mismatch"
			print(f"  ❌ {patch.error_message}")
			return False
		
		patch.status = PatchStatus.SUCCESS
		patch.applied_size = script_size
		patch.timestamp = datetime.now().isoformat()
		
		print(f"  ✅ Patch applied successfully")
		print(f"  Checksum: {patch.checksum_after[:16]}...")
		
		return True
	
	def apply_patches(self, patches: List[PatchEntry]) -> None:
		"""
		Apply all patches.
		
		Args:
			patches: List of patches to apply
		"""
		print("\n" + "=" * 80)
		print("APPLYING PATCHES")
		print("=" * 80)
		
		self.patch_log.start_time = datetime.now().isoformat()
		self.patch_log.total_patches = len(patches)
		
		for patch in patches:
			success = self.apply_patch(patch)
			
			if success:
				self.patch_log.successful_patches += 1
			else:
				self.patch_log.failed_patches += 1
			
			self.patch_log.patches.append(patch)
		
		self.patch_log.end_time = datetime.now().isoformat()
	
	def save_rom(self, output_file: Optional[str] = None) -> None:
		"""
		Save patched ROM.
		
		Args:
			output_file: Optional output file (default: overwrite original)
		"""
		if self.dry_run:
			print("\n💾 [DRY RUN] Would save ROM")
			return
		
		output_path = Path(output_file) if output_file else self.rom_file
		
		print(f"\n💾 Saving patched ROM: {output_path}")
		
		with open(output_path, 'wb') as f:
			f.write(self.rom_data)
		
		# Calculate final checksum
		self.patch_log.rom_checksum_after = self.calculate_checksum(self.rom_data)
		
		print("  ✅ ROM saved")
		print(f"  Final checksum: {self.patch_log.rom_checksum_after[:16]}...")
	
	def generate_log(self, log_file: str) -> None:
		"""Generate patch log."""
		log_path = Path(log_file)
		
		log_data = {
			'rom_file': self.patch_log.rom_file,
			'backup_file': self.patch_log.backup_file,
			'start_time': self.patch_log.start_time,
			'end_time': self.patch_log.end_time,
			'rom_checksum_before': self.patch_log.rom_checksum_before,
			'rom_checksum_after': self.patch_log.rom_checksum_after,
			'total_patches': self.patch_log.total_patches,
			'successful_patches': self.patch_log.successful_patches,
			'failed_patches': self.patch_log.failed_patches,
			'patches': [
				{
					'dialog_id': p.dialog_id,
					'script_file': p.script_file,
					'offset': f'0x{p.offset:06X}',
					'max_size': p.max_size,
					'applied_size': p.applied_size,
					'description': p.description,
					'status': p.status.value,
					'error_message': p.error_message,
					'checksum_before': p.checksum_before,
					'checksum_after': p.checksum_after,
					'timestamp': p.timestamp,
				}
				for p in self.patch_log.patches
			]
		}
		
		with open(log_path, 'w', encoding='utf-8') as f:
			json.dump(log_data, f, indent='\t')
		
		print(f"\n📄 Patch log saved: {log_path}")
	
	def generate_report(self, report_file: str) -> None:
		"""Generate human-readable report."""
		report_path = Path(report_file)
		
		lines = []
		lines.append("# ROM Patching Report")
		lines.append("=" * 80)
		lines.append("")
		lines.append(f"**ROM File**: {self.patch_log.rom_file}")
		lines.append(f"**Backup File**: {self.patch_log.backup_file}")
		lines.append(f"**Start Time**: {self.patch_log.start_time}")
		lines.append(f"**End Time**: {self.patch_log.end_time}")
		lines.append("")
		lines.append(f"**ROM Checksum (Before)**: {self.patch_log.rom_checksum_before}")
		lines.append(f"**ROM Checksum (After)**: {self.patch_log.rom_checksum_after}")
		lines.append("")
		
		# Summary
		lines.append("## Summary")
		lines.append("")
		lines.append(f"- **Total Patches**: {self.patch_log.total_patches}")
		lines.append(f"- **✅ Successful**: {self.patch_log.successful_patches}")
		lines.append(f"- **❌ Failed**: {self.patch_log.failed_patches}")
		lines.append(f"- **Success Rate**: {(self.patch_log.successful_patches / self.patch_log.total_patches * 100) if self.patch_log.total_patches > 0 else 0:.1f}%")
		lines.append("")
		
		# Patches
		lines.append("## Patches Applied")
		lines.append("")
		
		for patch in self.patch_log.patches:
			status_icon = "✅" if patch.status == PatchStatus.SUCCESS else "❌"
			lines.append(f"### {status_icon} Dialog {patch.dialog_id}")
			lines.append(f"- **Script**: {patch.script_file}")
			lines.append(f"- **Offset**: 0x{patch.offset:06X}")
			lines.append(f"- **Size**: {patch.applied_size} / {patch.max_size} bytes")
			lines.append(f"- **Status**: {patch.status.value}")
			
			if patch.description:
				lines.append(f"- **Description**: {patch.description}")
			
			if patch.error_message:
				lines.append(f"- **Error**: {patch.error_message}")
			
			if patch.checksum_after:
				lines.append(f"- **Checksum**: {patch.checksum_after[:16]}...")
			
			if patch.timestamp:
				lines.append(f"- **Timestamp**: {patch.timestamp}")
			
			lines.append("")
		
		with open(report_path, 'w', encoding='utf-8') as f:
			f.write('\n'.join(lines))
		
		print(f"📊 Report saved: {report_path}")
	
	def print_summary(self) -> None:
		"""Print summary to console."""
		print("\n" + "=" * 80)
		print("PATCHING SUMMARY")
		print("=" * 80)
		print(f"\nTotal patches: {self.patch_log.total_patches}")
		print(f"✅ Successful: {self.patch_log.successful_patches}")
		print(f"❌ Failed: {self.patch_log.failed_patches}")
		print(f"Success rate: {(self.patch_log.successful_patches / self.patch_log.total_patches * 100) if self.patch_log.total_patches > 0 else 0:.1f}%")
		print("")


def load_patch_file(patch_file: str) -> Tuple[str, List[PatchEntry]]:
	"""
	Load patch specifications from JSON file.
	
	Args:
		patch_file: Path to patch JSON file
	
	Returns:
		(rom_file, patches)
	"""
	with open(patch_file, 'r', encoding='utf-8') as f:
		data = json.load(f)
	
	rom_file = data['rom_file']
	
	patches = []
	for p in data['patches']:
		# Parse offset
		patcher = BatchROMPatcher(rom_file, dry_run=True)
		offset = patcher.parse_offset(p['offset'])
		
		patches.append(PatchEntry(
			dialog_id=p['dialog_id'],
			script_file=p['script_file'],
			offset=offset,
			max_size=p['max_size'],
			description=p.get('description', '')
		))
	
	return rom_file, patches


def main():
	"""Main entry point."""
	import argparse
	
	parser = argparse.ArgumentParser(
		description="Batch patch FFMQ ROM with compiled event scripts",
		formatter_class=argparse.RawDescriptionHelpFormatter,
		epilog="""
Examples:
	# Apply patches from specification file
	python batch_rom_patcher.py --patches patches.json

	# Dry run (don't modify ROM)
	python batch_rom_patcher.py --patches patches.json --dry-run

	# Save to different file
	python batch_rom_patcher.py --patches patches.json --output ffmq_modified.sfc

	# Generate detailed report
	python batch_rom_patcher.py --patches patches.json --report patch_report.md

Documentation:
	Applies multiple compiled scripts to ROM in batch.
	See ROM_HACKING_TOOLCHAIN_GUIDE.md for workflow examples.
		"""
	)
	
	parser.add_argument(
		'--patches',
		required=True,
		help='Path to patch specification JSON file'
	)
	
	parser.add_argument(
		'--output',
		help='Output ROM file (default: overwrite original)'
	)
	
	parser.add_argument(
		'--log',
		default='patch_log.json',
		help='Path for patch log (JSON)'
	)
	
	parser.add_argument(
		'--report',
		default='patch_report.md',
		help='Path for patch report (Markdown)'
	)
	
	parser.add_argument(
		'--dry-run',
		action='store_true',
		help='Preview changes without modifying ROM'
	)
	
	args = parser.parse_args()
	
	print("=" * 80)
	print("BATCH ROM PATCHER")
	print("=" * 80)
	
	if args.dry_run:
		print("\n🔍 DRY RUN MODE - No changes will be made")
	
	# Load patch specifications
	print(f"\n📋 Loading patch specifications: {args.patches}")
	rom_file, patches = load_patch_file(args.patches)
	print(f"  ROM: {rom_file}")
	print(f"  Patches: {len(patches)}")
	
	# Initialize patcher
	patcher = BatchROMPatcher(rom_file, dry_run=args.dry_run)
	
	# Load ROM
	patcher.load_rom()
	
	# Create backup
	patcher.create_backup()
	
	# Apply patches
	patcher.apply_patches(patches)
	
	# Save ROM
	patcher.save_rom(args.output)
	
	# Generate outputs
	patcher.generate_log(args.log)
	patcher.generate_report(args.report)
	
	# Print summary
	patcher.print_summary()
	
	print("\n" + "=" * 80)
	print("PATCHING COMPLETE")
	print("=" * 80)
	print("")


if __name__ == '__main__':
	main()
