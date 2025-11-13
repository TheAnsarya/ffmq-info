#!/usr/bin/env python3
"""
Test ROM Builder - Automate test ROM creation for command verification
Build test ROMs with specific event scripts for validation and regression testing

Features:
- Generate test ROM from event scripts
- Inject compiled scripts at specified offsets
- Create minimal working SNES ROM
- Automated header generation
- Checksum calculation and insertion
- Test harness script generation
- Regression test suite support
- Batch test ROM creation

Test Scenarios:
- Individual command testing
- Parameter range validation
- Control flow verification
- Memory operation testing
- Subroutine call verification
- Edge case testing
- Integration testing

Usage:
	python test_rom_builder.py --base original.sfc --script test_dialog.txt --output test.sfc
	python test_rom_builder.py --create-blank --output blank.sfc
	python test_rom_builder.py --test-suite tests.json --output-dir test_roms/
	python test_rom_builder.py --inject test.bin --offset 0xC0/8000 --rom base.sfc
"""

import argparse
import struct
import hashlib
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass, field
from enum import Enum
import json


class ROMType(Enum):
	"""ROM mapping types"""
	LOROM = "lorom"
	HIROM = "hirom"


@dataclass
class ROMHeader:
	"""SNES ROM header structure"""
	title: str  # 21 bytes
	rom_type: ROMType
	rom_size: int  # In bytes
	sram_size: int  # In bytes
	country_code: int
	developer_id: int
	version: int
	checksum_complement: int = 0
	checksum: int = 0

	def to_bytes(self) -> bytes:
		"""Convert header to bytes"""
		data = bytearray(64)  # Header is at offset $FFB0-$FFDF (48 bytes used)

		# Title (21 bytes, padded with spaces)
		title_bytes = self.title[:21].encode('ascii', errors='replace').ljust(21, b' ')
		data[0:21] = title_bytes

		# ROM makeup byte
		if self.rom_type == ROMType.LOROM:
			data[21] = 0x20  # LoROM
		else:
			data[21] = 0x21  # HiROM

		# Chipset byte
		data[22] = 0x00  # ROM only

		# ROM size (log2(size/1024))
		import math
		rom_size_value = int(math.log2(self.rom_size / 1024))
		data[23] = rom_size_value

		# SRAM size
		if self.sram_size > 0:
			sram_size_value = int(math.log2(self.sram_size / 1024))
			data[24] = sram_size_value
		else:
			data[24] = 0

		# Country code
		data[25] = self.country_code

		# Developer ID
		data[26] = self.developer_id

		# Version
		data[27] = self.version

		# Checksum complement
		struct.pack_into('<H', data, 28, self.checksum_complement)

		# Checksum
		struct.pack_into('<H', data, 30, self.checksum)

		return bytes(data[:32])


@dataclass
class TestScript:
	"""A test script to inject into ROM"""
	script_name: str
	script_data: bytes
	target_offset: int
	description: str = ""
	expected_behavior: str = ""


@dataclass
class TestROMConfig:
	"""Configuration for test ROM creation"""
	base_rom_path: Optional[Path]
	output_path: Path
	rom_title: str
	test_scripts: List[TestScript]
	rom_size: int = 1048576  # 1MB default
	rom_type: ROMType = ROMType.LOROM


class TestROMBuilder:
	"""Build test ROMs for event script validation"""

	# SNES ROM header offset (LoROM)
	LOROM_HEADER_OFFSET = 0x007FB0
	HIROM_HEADER_OFFSET = 0x00FFB0

	# Interrupt vectors (LoROM)
	LOROM_VECTOR_OFFSET = 0x007FC0

	# Test harness entry point
	TEST_HARNESS_OFFSET = 0x008000

	def __init__(self, verbose: bool = False):
		self.verbose = verbose

	def create_blank_rom(self, size: int = 1048576) -> bytearray:
		"""Create blank ROM filled with 0xFF"""
		if self.verbose:
			print(f"Creating blank ROM ({size} bytes)...")

		return bytearray([0xFF] * size)

	def calculate_checksum(self, rom_data: bytes) -> Tuple[int, int]:
		"""
		Calculate ROM checksum and complement

		Returns:
			Tuple of (checksum, checksum_complement)
		"""
		# Sum all bytes
		checksum = sum(rom_data) & 0xFFFF

		# Complement
		checksum_complement = checksum ^ 0xFFFF

		return checksum, checksum_complement

	def insert_header(self, rom_data: bytearray, header: ROMHeader) -> None:
		"""Insert ROM header at appropriate offset"""
		if header.rom_type == ROMType.LOROM:
			offset = self.LOROM_HEADER_OFFSET
		else:
			offset = self.HIROM_HEADER_OFFSET

		header_bytes = header.to_bytes()
		rom_data[offset:offset + len(header_bytes)] = header_bytes

		if self.verbose:
			print(f"Inserted header at 0x{offset:06X}")

	def insert_vectors(self, rom_data: bytearray, entry_point: int = 0x8000) -> None:
		"""Insert interrupt vectors"""
		offset = self.LOROM_VECTOR_OFFSET

		# Native mode vectors
		rom_data[offset + 0x04:offset + 0x06] = struct.pack('<H', 0xFFFF)  # COP
		rom_data[offset + 0x06:offset + 0x08] = struct.pack('<H', 0xFFFF)  # BRK
		rom_data[offset + 0x08:offset + 0x0A] = struct.pack('<H', 0xFFFF)  # ABORT
		rom_data[offset + 0x0A:offset + 0x0C] = struct.pack('<H', 0xFFFF)  # NMI
		rom_data[offset + 0x0C:offset + 0x0E] = struct.pack('<H', entry_point)  # RESET
		rom_data[offset + 0x0E:offset + 0x10] = struct.pack('<H', 0xFFFF)  # IRQ

		# Emulation mode vectors
		rom_data[offset + 0x14:offset + 0x16] = struct.pack('<H', 0xFFFF)  # COP
		rom_data[offset + 0x18:offset + 0x1A] = struct.pack('<H', 0xFFFF)  # ABORT
		rom_data[offset + 0x1A:offset + 0x1C] = struct.pack('<H', 0xFFFF)  # NMI
		rom_data[offset + 0x1C:offset + 0x1E] = struct.pack('<H', entry_point)  # RESET
		rom_data[offset + 0x1E:offset + 0x20] = struct.pack('<H', 0xFFFF)  # IRQ/BRK

		if self.verbose:
			print(f"Inserted vectors at 0x{offset:06X}, entry: 0x{entry_point:04X}")

	def insert_test_harness(self, rom_data: bytearray) -> None:
		"""
		Insert minimal test harness code
		Sets up SNES and jumps to test script
		"""
		# Simple test harness in 65816 assembly
		# This is minimal - just initialize and loop
		harness_code = bytes([
			0x18,        # CLC
			0xFB,        # XCE (switch to native mode)
			0xC2, 0x30,  # REP #$30 (16-bit A, X, Y)
			0xA9, 0x00, 0x00,  # LDA #$0000
			0x5C, 0x00, 0x80, 0xC0,  # JML $C08000 (jump to test script)
			0x80, 0xFE   # BRA -2 (infinite loop)
		])

		offset = self.TEST_HARNESS_OFFSET
		rom_data[offset:offset + len(harness_code)] = harness_code

		if self.verbose:
			print(f"Inserted test harness at 0x{offset:06X}")

	def lorom_to_offset(self, bank: int, bank_offset: int) -> int:
		"""Convert LoROM bank/offset to absolute ROM offset"""
		if bank >= 0xC0:
			return 0x200000 + ((bank - 0xC0) * 0x8000) + (bank_offset - 0x8000)
		else:
			return (bank % 0x40) * 0x8000 + (bank_offset - 0x8000)

	def inject_script(self, rom_data: bytearray, script: TestScript) -> None:
		"""Inject compiled script at specified offset"""
		offset = script.target_offset

		if offset + len(script.script_data) > len(rom_data):
			raise ValueError(f"Script {script.script_name} too large for ROM")

		rom_data[offset:offset + len(script.script_data)] = script.script_data

		if self.verbose:
			print(f"Injected {script.script_name} ({len(script.script_data)} bytes) at 0x{offset:06X}")

	def build_test_rom(self, config: TestROMConfig) -> bytearray:
		"""Build complete test ROM"""
		# Start with base ROM or blank
		if config.base_rom_path and config.base_rom_path.exists():
			if self.verbose:
				print(f"Loading base ROM: {config.base_rom_path}")
			with open(config.base_rom_path, 'rb') as f:
				rom_data = bytearray(f.read())
		else:
			rom_data = self.create_blank_rom(config.rom_size)

		# Ensure ROM is correct size
		if len(rom_data) < config.rom_size:
			rom_data.extend([0xFF] * (config.rom_size - len(rom_data)))
		elif len(rom_data) > config.rom_size:
			rom_data = rom_data[:config.rom_size]

		# Insert test harness
		self.insert_test_harness(rom_data)

		# Inject all test scripts
		for script in config.test_scripts:
			self.inject_script(rom_data, script)

		# Create and insert header
		checksum, checksum_complement = self.calculate_checksum(rom_data)

		header = ROMHeader(
			title=config.rom_title,
			rom_type=config.rom_type,
			rom_size=len(rom_data),
			sram_size=0,
			country_code=0x01,  # USA
			developer_id=0x00,
			version=0x00,
			checksum=checksum,
			checksum_complement=checksum_complement
		)

		self.insert_header(rom_data, header)
		self.insert_vectors(rom_data, entry_point=self.TEST_HARNESS_OFFSET)

		# Recalculate checksum after header insertion
		checksum, checksum_complement = self.calculate_checksum(rom_data)
		header.checksum = checksum
		header.checksum_complement = checksum_complement
		self.insert_header(rom_data, header)

		return rom_data

	def compile_simple_script(self, script_text: str) -> bytes:
		"""
		Compile simple script text to bytecode
		Simplified compiler for test purposes
		"""
		commands = {
			'END': b'\x00',
			'WAIT': b'\x01',
			'NEWLINE': b'\x02',
			'SET_FLAG': b'\x03',
			'CLEAR_FLAG': b'\x04',
			'CHECK_FLAG': b'\x05',
			'CALL_SUBROUTINE': b'\x10',
			'MEMORY_WRITE': b'\x20',
			'RETURN': b'\xFF'
		}

		bytecode = bytearray()

		for line in script_text.strip().split('\n'):
			line = line.strip()
			if not line or line.startswith(';'):
				continue

			parts = line.split()
			if not parts:
				continue

			cmd = parts[0]
			params = parts[1:]

			# Text line
			if line.startswith('"'):
				text = line.strip('"')
				bytecode.extend(text.encode('ascii', errors='replace'))
				bytecode.append(0x00)  # NULL terminator

			# Command
			elif cmd in commands:
				bytecode.extend(commands[cmd])

				# Add parameters
				for param in params:
					try:
						value = int(param, 0)
						bytecode.append(value & 0xFF)
					except ValueError:
						pass

		return bytes(bytecode)

	def generate_test_suite(self, suite_config_path: Path) -> List[TestROMConfig]:
		"""Generate multiple test ROM configs from suite definition"""
		with open(suite_config_path) as f:
			suite_data = json.load(f)

		configs = []

		for test in suite_data.get('tests', []):
			# Compile script
			script_data = self.compile_simple_script(test['script'])

			# Parse offset
			offset_str = test.get('offset', '0xC0/8000')
			if '/' in offset_str:
				bank_str, offset_str = offset_str.split('/')
				bank = int(bank_str, 0)
				bank_offset = int(offset_str, 0)
				offset = self.lorom_to_offset(bank, bank_offset)
			else:
				offset = int(offset_str, 0)

			test_script = TestScript(
				script_name=test['name'],
				script_data=script_data,
				target_offset=offset,
				description=test.get('description', ''),
				expected_behavior=test.get('expected', '')
			)

			config = TestROMConfig(
				base_rom_path=Path(suite_data.get('base_rom')) if 'base_rom' in suite_data else None,
				output_path=Path(f"test_{test['name']}.sfc"),
				rom_title=f"TEST_{test['name'][:15].upper()}",
				test_scripts=[test_script],
				rom_size=suite_data.get('rom_size', 1048576)
			)

			configs.append(config)

		return configs

	def generate_test_report(self, configs: List[TestROMConfig], output_dir: Path) -> str:
		"""Generate test ROM build report"""
		lines = [
			"# Test ROM Build Report",
			"",
			f"## Summary",
			f"- Test ROMs Built: {len(configs)}",
			f"- Output Directory: {output_dir}",
			"",
			"## Test ROMs",
			""
		]

		for config in configs:
			lines.append(f"### {config.rom_title}")
			lines.append(f"- Output: `{config.output_path}`")
			lines.append(f"- ROM Size: {config.rom_size:,} bytes")
			lines.append(f"- Test Scripts: {len(config.test_scripts)}")

			for script in config.test_scripts:
				lines.append(f"  - **{script.script_name}**")
				lines.append(f"    - Offset: 0x{script.target_offset:06X}")
				lines.append(f"    - Size: {len(script.script_data)} bytes")
				if script.description:
					lines.append(f"    - Description: {script.description}")
				if script.expected_behavior:
					lines.append(f"    - Expected: {script.expected_behavior}")

			lines.append("")

		return '\n'.join(lines)


def main():
	parser = argparse.ArgumentParser(description='Build test ROMs for event script validation')
	parser.add_argument('--base', type=Path, help='Base ROM file')
	parser.add_argument('--script', type=Path, help='Script file to inject')
	parser.add_argument('--inject', type=Path, help='Binary data to inject')
	parser.add_argument('--offset', type=str, help='Injection offset (0xBB/OOOO or 0xOOOOOO)')
	parser.add_argument('--output', type=Path, help='Output ROM file')
	parser.add_argument('--create-blank', action='store_true', help='Create blank ROM')
	parser.add_argument('--rom-size', type=int, default=1048576, help='ROM size in bytes')
	parser.add_argument('--title', default='TEST ROM', help='ROM title')
	parser.add_argument('--test-suite', type=Path, help='Test suite JSON file')
	parser.add_argument('--output-dir', type=Path, help='Output directory for test suite')
	parser.add_argument('--report', type=Path, help='Generate test report')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')

	args = parser.parse_args()

	builder = TestROMBuilder(verbose=args.verbose)

	# Test suite mode
	if args.test_suite:
		configs = builder.generate_test_suite(args.test_suite)

		output_dir = args.output_dir or Path('test_roms')
		output_dir.mkdir(parents=True, exist_ok=True)

		for config in configs:
			config.output_path = output_dir / config.output_path
			rom_data = builder.build_test_rom(config)

			with open(config.output_path, 'wb') as f:
				f.write(rom_data)

			if args.verbose:
				print(f"✓ Built {config.output_path}")

		# Generate report
		if args.report:
			report = builder.generate_test_report(configs, output_dir)
			with open(args.report, 'w') as f:
				f.write(report)
			print(f"\nReport saved to {args.report}")

		print(f"\n✓ Built {len(configs)} test ROMs in {output_dir}")
		return 0

	# Single ROM mode
	if not args.output:
		print("Error: --output required")
		return 1

	# Parse offset
	if args.offset:
		if '/' in args.offset:
			bank_str, offset_str = args.offset.split('/')
			bank = int(bank_str, 0)
			bank_offset = int(offset_str, 0)
			offset = builder.lorom_to_offset(bank, bank_offset)
		else:
			offset = int(args.offset, 0)
	else:
		offset = 0xC08000  # Default

	# Prepare test script
	test_scripts = []

	if args.script:
		with open(args.script) as f:
			script_text = f.read()
		script_data = builder.compile_simple_script(script_text)
		test_scripts.append(TestScript(
			script_name=args.script.stem,
			script_data=script_data,
			target_offset=offset
		))
	elif args.inject:
		with open(args.inject, 'rb') as f:
			script_data = f.read()
		test_scripts.append(TestScript(
			script_name=args.inject.stem,
			script_data=script_data,
			target_offset=offset
		))

	# Build ROM
	config = TestROMConfig(
		base_rom_path=args.base,
		output_path=args.output,
		rom_title=args.title[:21],
		test_scripts=test_scripts,
		rom_size=args.rom_size
	)

	rom_data = builder.build_test_rom(config)

	with open(args.output, 'wb') as f:
		f.write(rom_data)

	print(f"\n✓ Test ROM built: {args.output}")
	print(f"  Size: {len(rom_data):,} bytes")
	print(f"  Title: {config.rom_title}")
	if test_scripts:
		print(f"  Injected {len(test_scripts)} script(s)")

	return 0


if __name__ == '__main__':
	exit(main())
