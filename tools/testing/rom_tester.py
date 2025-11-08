#!/usr/bin/env python3
"""
Final Fantasy Mystic Quest - ROM Testing Framework
Basic automated testing for ROM functionality
"""

import os
import sys
import hashlib
import struct
from typing import Dict, List, Tuple

class FFMQROMTester:
	"""Test framework for FFMQ ROM functionality"""
	
	def __init__(self, rom_path: str):
		self.rom_path = rom_path
		self.rom_data = None
		self.errors = []
		self.warnings = []
		
	def load_rom(self) -> bool:
		"""Load ROM file for testing"""
		try:
			with open(self.rom_path, 'rb') as f:
				self.rom_data = f.read()
			print(f"Loaded ROM: {self.rom_path} ({len(self.rom_data)} bytes)")
			return True
		except Exception as e:
			self.errors.append(f"Failed to load ROM: {e}")
			return False
	
	def test_rom_header(self) -> bool:
		"""Test ROM header integrity"""
		print("Testing ROM header...")
		
		if len(self.rom_data) < 0x8000:
			self.errors.append("ROM too small to contain header")
			return False
		
		# Test header locations (LoROM format)
		header_offset = 0x7fc0  # LoROM header location
		
		# Check for valid header signature
		try:
			# Game title (21 bytes)
			title_bytes = self.rom_data[header_offset:header_offset + 21]
			title = title_bytes.decode('ascii', errors='ignore').rstrip('\x00 ')
			print(f"  Game title: {title}")
			
			# ROM makeup byte
			rom_makeup = self.rom_data[header_offset + 21]
			print(f"  ROM makeup: 0x{rom_makeup:02X}")
			
			# Cartridge type
			cart_type = self.rom_data[header_offset + 22]
			print(f"  Cartridge type: 0x{cart_type:02X}")
			
			# ROM size
			rom_size = self.rom_data[header_offset + 23]
			expected_size = 1 << (rom_size + 10)
			print(f"  ROM size: 0x{rom_size:02X} ({expected_size} bytes expected)")
			
			if len(self.rom_data) != expected_size:
				self.warnings.append(f"ROM size mismatch: {len(self.rom_data)} vs {expected_size}")
			
			# RAM size
			ram_size = self.rom_data[header_offset + 24]
			ram_kb = 1 << ram_size if ram_size > 0 else 0
			print(f"  RAM size: 0x{ram_size:02X} ({ram_kb} KB)")
			
			# Country code
			country = self.rom_data[header_offset + 25]
			print(f"  Country code: 0x{country:02X}")
			
			# Version
			version = self.rom_data[header_offset + 27]
			print(f"  Version: 0x{version:02X}")
			
			return True
			
		except Exception as e:
			self.errors.append(f"Header test failed: {e}")
			return False
	
	def test_checksums(self) -> bool:
		"""Test ROM checksums"""
		print("Testing ROM checksums...")
		
		header_offset = 0x7fc0
		
		try:
			# Read checksums from header
			checksum_offset = header_offset + 28
			complement = struct.unpack('<H', self.rom_data[checksum_offset:checksum_offset + 2])[0]
			checksum = struct.unpack('<H', self.rom_data[checksum_offset + 2:checksum_offset + 4])[0]
			
			print(f"  Header complement: 0x{complement:04X}")
			print(f"  Header checksum: 0x{checksum:04X}")
			
			# Calculate actual checksum
			calculated_sum = 0
			for i in range(len(self.rom_data)):
				if not (checksum_offset <= i < checksum_offset + 4):  # Skip checksum area
					calculated_sum += self.rom_data[i]
			
			calculated_sum &= 0xffff
			calculated_complement = calculated_sum ^ 0xffff
			
			print(f"  Calculated sum: 0x{calculated_sum:04X}")
			print(f"  Calculated complement: 0x{calculated_complement:04X}")
			
			# Check if checksums match
			if checksum == calculated_sum and complement == calculated_complement:
				print("  ✓ Checksums valid")
				return True
			else:
				self.warnings.append("Checksum mismatch - ROM may be modified")
				return True  # Not a fatal error for development
				
		except Exception as e:
			self.errors.append(f"Checksum test failed: {e}")
			return False
	
	def test_interrupt_vectors(self) -> bool:
		"""Test interrupt vector table"""
		print("Testing interrupt vectors...")
		
		try:
			vector_offset = 0x7fe4  # Start of vector table in LoROM
			
			vectors = {
				'COP': vector_offset,
				'BRK': vector_offset + 2,
				'ABORT': vector_offset + 4,
				'NMI': vector_offset + 6,
				'RESET': vector_offset + 8,
				'IRQ': vector_offset + 10,
			}
			
			for name, offset in vectors.items():
				if offset + 1 < len(self.rom_data):
					vector = struct.unpack('<H', self.rom_data[offset:offset + 2])[0]
					print(f"  {name}: 0x{vector:04X}")
					
					# Basic sanity check - vectors should be in valid address ranges
					if vector < 0x8000 or vector > 0xffff:
						self.warnings.append(f"Unusual {name} vector: 0x{vector:04X}")
				else:
					self.errors.append(f"ROM too small for {name} vector")
					
			return True
			
		except Exception as e:
			self.errors.append(f"Vector test failed: {e}")
			return False
	
	def test_basic_code_structure(self) -> bool:
		"""Test basic code structure at reset vector"""
		print("Testing basic code structure...")
		
		try:
			# Get reset vector
			reset_vector = struct.unpack('<H', self.rom_data[0x7fec:0x7fee])[0]
			print(f"  Reset vector: 0x{reset_vector:04X}")
			
			# Convert to ROM offset
			if reset_vector >= 0x8000:
				rom_offset = reset_vector - 0x8000
				
				if rom_offset < len(self.rom_data):
					# Check first few bytes for typical initialization code
					code_start = self.rom_data[rom_offset:rom_offset + 16]
					print(f"  Code at reset: {' '.join(f'{b:02X}' for b in code_start)}")
					
					# Look for common SNES initialization patterns
					if code_start[0] == 0x78:  # SEI instruction
						print("  ✓ Found SEI (disable interrupts) at start")
					elif code_start[0] == 0x18:  # CLC instruction
						print("  ✓ Found CLC (clear carry) at start")
					else:
						self.warnings.append(f"Unusual start instruction: 0x{code_start[0]:02X}")
				else:
					self.errors.append("Reset vector points outside ROM")
			else:
				self.errors.append(f"Invalid reset vector: 0x{reset_vector:04X}")
				
			return True
			
		except Exception as e:
			self.errors.append(f"Code structure test failed: {e}")
			return False
	
	def test_data_integrity(self) -> bool:
		"""Test data integrity (look for obvious corruption)"""
		print("Testing data integrity...")
		
		try:
			# Check for large blocks of identical bytes (possible corruption)
			chunk_size = 1024
			for i in range(0, len(self.rom_data) - chunk_size, chunk_size):
				chunk = self.rom_data[i:i + chunk_size]
				
				# Check for all zeros
				if chunk == b'\x00' * chunk_size:
					self.warnings.append(f"Found large zero block at 0x{i:06X}")
				
				# Check for all 0xff
				elif chunk == b'\xFF' * chunk_size:
					self.warnings.append(f"Found large 0xff block at 0x{i:06X}")
				
				# Check for repeating patterns
				elif len(set(chunk)) < 4:
					unique_bytes = set(chunk)
					self.warnings.append(f"Found low-entropy block at 0x{i:06X}: {unique_bytes}")
			
			print("  Data integrity check complete")
			return True
			
		except Exception as e:
			self.errors.append(f"Data integrity test failed: {e}")
			return False
	
	def run_all_tests(self) -> bool:
		"""Run all tests"""
		print(f"Running ROM tests on: {self.rom_path}")
		print("=" * 50)
		
		if not self.load_rom():
			return False
		
		tests = [
			self.test_rom_header,
			self.test_checksums,
			self.test_interrupt_vectors,
			self.test_basic_code_structure,
			self.test_data_integrity
		]
		
		success = True
		for test in tests:
			try:
				if not test():
					success = False
				print()  # Add spacing between tests
			except Exception as e:
				self.errors.append(f"Test {test.__name__} crashed: {e}")
				success = False
		
		# Print summary
		print("Test Summary")
		print("=" * 20)
		if self.errors:
			print("Errors:")
			for error in self.errors:
				print(f"  ❌ {error}")
		
		if self.warnings:
			print("Warnings:")
			for warning in self.warnings:
				print(f"  ⚠️  {warning}")
		
		if not self.errors and not self.warnings:
			print("✅ All tests passed with no issues!")
		elif not self.errors:
			print("✅ All tests passed (with warnings)")
		else:
			print("❌ Tests failed")
		
		return success

def main():
	if len(sys.argv) != 2:
		print("Usage: python rom_tester.py <rom_path>")
		sys.exit(1)
	
	rom_path = sys.argv[1]
	
	if not os.path.exists(rom_path):
		print(f"Error: ROM file not found: {rom_path}")
		sys.exit(1)
	
	tester = FFMQROMTester(rom_path)
	success = tester.run_all_tests()
	
	sys.exit(0 if success else 1)

if __name__ == "__main__":
	main()