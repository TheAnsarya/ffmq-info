#!/usr/bin/env python3
"""
FFMQ ROM Data Extractor
Extracts binary data from Final Fantasy Mystic Quest ROM banks
Generates metadata JSON manifests for extraction provenance
"""

import os
import sys
import json
import hashlib
from pathlib import Path
from typing import Dict, List, Tuple

class FFMQRomExtractor:
	"""Extract data from FFMQ ROM with metadata tracking"""

	def __init__(self, rom_path: str, output_base: str = "data"):
		self.rom_path = Path(rom_path)
		self.output_base = Path(output_base)
		self.rom_data = None
		self.extractions = []

		# SNES LoROM memory map (banks $00-$7F mapped to ROM)
		self.bank_size = 0x8000  # 32KB per bank in LoROM

	def load_rom(self) -> bool:
		"""Load ROM file into memory"""
		if not self.rom_path.exists():
			print(f"ERROR: ROM file not found: {self.rom_path}")
			return False

		with open(self.rom_path, 'rb') as f:
			self.rom_data = bytearray(f.read())

		# Detect and skip SMC header if present (512 bytes)
		if len(self.rom_data) % 1024 == 512:
			print("INFO: SMC header detected, skipping 512 bytes")
			self.rom_data = self.rom_data[512:]

		print(f"INFO: Loaded ROM: {len(self.rom_data)} bytes ({len(self.rom_data)//1024}KB)")
		return True

	def calculate_checksum(self, data: bytes) -> str:
		"""Calculate SHA256 checksum for data integrity"""
		return hashlib.sha256(data).hexdigest()

	def extract_range(self, name: str, rom_offset: int, size: int,
					  category: str, description: str = "") -> Dict:
		"""Extract binary range from ROM with metadata"""

		# Extract data
		data = bytes(self.rom_data[rom_offset:rom_offset + size])

		# Calculate bank info
		bank_num = rom_offset // self.bank_size
		bank_offset = rom_offset % self.bank_size

		# Create output directory
		output_dir = self.output_base / category / "1_original_bin"
		output_dir.mkdir(parents=True, exist_ok=True)

		# Write binary file
		output_file = output_dir / f"{name}.bin"
		with open(output_file, 'wb') as f:
			f.write(data)

		# Create metadata
		metadata = {
			"name": name,
			"category": category,
			"description": description,
			"rom_offset": f"0x{rom_offset:06X}",
			"rom_offset_dec": rom_offset,
			"size": size,
			"size_hex": f"0x{size:04X}",
			"bank": f"${bank_num:02X}",
			"bank_offset": f"${bank_offset:04X}",
			"snes_address": f"${bank_num:02X}:{bank_offset + 0x8000:04X}",
			"checksum_sha256": self.calculate_checksum(data),
			"output_file": str(output_file.relative_to(self.output_base.parent))
		}

		self.extractions.append(metadata)

		print(f"EXTRACTED: {name} ({size} bytes) from {metadata['snes_address']} -> {output_file.name}")

		return metadata

	def extract_bank_07_graphics(self):
		"""Extract Bank $07 graphics and animation data"""

		# DATA8_07B013 - Multi-sprite configuration blocks (from Cycle 4 analysis)
		# ROM offset: Bank $07 starts at $038000 (LoROM), $B013 offset = $03B013
		self.extract_range(
			name="bank07_sprite_configs",
			rom_offset=0x03B013,
			size=0x1000,  # Estimate 4KB, adjust based on actual size
			category="sprites",
			description="Multi-sprite configuration blocks (DATA8_07B013) - scene objects, battle formations, NPC configs"
		)

		# DATA8_07AF3B - Scene object lookup table (78 entries × 2 bytes = 156 bytes)
		self.extract_range(
			name="bank07_scene_lookup",
			rom_offset=0x03AF3B,
			size=156,
			category="tables",
			description="Scene object lookup table (DATA8_07AF3B) - 78 entries, 16-bit pointers to sprite configs"
		)

	def extract_title_screen_graphics(self):
		"""Extract existing title screen graphics (already extracted)"""

		# These files already exist in data/graphics/, document them in manifest
		existing_files = [
			("title-screen-crystals-01.bin", "Title screen crystal animation frame 1"),
			("title-screen-crystals-02.bin", "Title screen crystal animation frame 2"),
			("title-screen-crystals-03.bin", "Title screen crystal animation frame 3"),
			("title-screen-words.bin", "Title screen text/logo graphics"),
			("tiles.bin", "General tile graphics data"),
			("048000-tiles.bin", "Graphics tiles from ROM offset $048000"),
			("data07b013.bin", "Bank $07 sprite data (matches DATA8_07B013)")
		]

		for filename, desc in existing_files:
			src_path = self.output_base / "graphics" / filename
			if src_path.exists():
				data = src_path.read_bytes()
				metadata = {
					"name": filename.replace(".bin", ""),
					"category": "graphics",
					"description": desc,
					"size": len(data),
					"checksum_sha256": self.calculate_checksum(data),
					"output_file": str(src_path.relative_to(self.output_base.parent)),
					"note": "Pre-existing extraction, ROM offset unknown"
				}
				self.extractions.append(metadata)
				print(f"DOCUMENTED: {filename} ({len(data)} bytes) - pre-existing")

	def save_manifest(self):
		"""Save extraction manifest JSON"""

		manifest_file = self.output_base / "extraction_manifest.json"

		manifest = {
			"rom_file": str(self.rom_path),
			"rom_size": len(self.rom_data),
			"rom_checksum": self.calculate_checksum(bytes(self.rom_data)),
			"extraction_count": len(self.extractions),
			"extractions": self.extractions
		}

		with open(manifest_file, 'w') as f:
			json.dump(manifest, f, indent=2)

		print(f"\nMANIFEST: Saved {len(self.extractions)} extractions to {manifest_file}")

	def run(self):
		"""Execute extraction pipeline"""

		print("=" * 70)
		print("FFMQ ROM DATA EXTRACTOR")
		print("=" * 70)

		if not self.load_rom():
			return False

		print("\nEXTRACTING DATA...")

		# Extract Bank $07 data (from recent analysis)
		self.extract_bank_07_graphics()

		# Document existing extractions
		self.extract_title_screen_graphics()

		# Save manifest
		self.save_manifest()

		print("\n" + "=" * 70)
		print(f"EXTRACTION COMPLETE: {len(self.extractions)} files")
		print("=" * 70)

		return True

def main():
	"""Main entry point"""

	# Default ROM path (adjust as needed)
	rom_path = "ffmq.sfc"

	if len(sys.argv) > 1:
		rom_path = sys.argv[1]

	extractor = FFMQRomExtractor(rom_path)
	success = extractor.run()

	sys.exit(0 if success else 1)

if __name__ == "__main__":
	main()
