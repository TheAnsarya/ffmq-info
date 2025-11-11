"""
Advanced ROM Patching System for SNES
Create, apply, and manage IPS/UPS/BPS patches with validation.
"""

import struct
import hashlib
from typing import List, Tuple, Optional, Dict
from enum import Enum
from dataclasses import dataclass
import json


class PatchFormat(Enum):
	"""Patch file formats"""
	IPS = "ips"    # International Patching System
	UPS = "ups"    # Universal Patching System
	BPS = "bps"    # Beat Patching System
	CUSTOM = "custom"


@dataclass
class PatchRecord:
	"""Single patch record"""
	offset: int
	old_data: bytes
	new_data: bytes
	description: str = ""

	def to_dict(self):
		return {
			'offset': hex(self.offset),
			'old_data': self.old_data.hex(),
			'new_data': self.new_data.hex(),
			'size': len(self.new_data),
			'description': self.description
		}


@dataclass
class PatchMetadata:
	"""Patch metadata"""
	name: str
	author: str
	version: str
	description: str
	source_checksum: str
	target_checksum: str
	created_date: str

	def to_dict(self):
		return {
			'name': self.name,
			'author': self.author,
			'version': self.version,
			'description': self.description,
			'source_checksum': self.source_checksum,
			'target_checksum': self.target_checksum,
			'created_date': self.created_date
		}


class IPSPatcher:
	"""IPS (International Patching System) format handler"""

	HEADER = b'PATCH'
	EOF_MARKER = b'EOF'

	@staticmethod
	def create_patch(source_data: bytes, target_data: bytes) -> bytes:
		"""Create IPS patch from source and target"""
		patch = bytearray(IPSPatcher.HEADER)

		# Find differences
		i = 0
		while i < len(target_data):
			# Skip matching bytes
			if i < len(source_data) and source_data[i] == target_data[i]:
				i += 1
				continue

			# Found difference, start record
			offset = i
			changed_bytes = bytearray()

			# Collect consecutive changed bytes (max 65535)
			while i < len(target_data) and len(changed_bytes) < 65535:
				if i < len(source_data) and source_data[i] == target_data[i]:
					# If we have a good run of matches, end this record
					if i + 10 < len(target_data):
						match_count = 0
						for j in range(10):
							if i + j < len(source_data) and i + j < len(target_data):
								if source_data[i + j] == target_data[i + j]:
									match_count += 1
						if match_count >= 8:
							break

				changed_bytes.append(target_data[i] if i < len(target_data) else 0)
				i += 1

			if changed_bytes:
				# Write record: offset (3 bytes) + size (2 bytes) + data
				patch.extend(struct.pack('>I', offset)[1:])  # 24-bit offset
				patch.extend(struct.pack('>H', len(changed_bytes)))
				patch.extend(changed_bytes)

		# EOF marker
		patch.extend(IPSPatcher.EOF_MARKER)

		return bytes(patch)

	@staticmethod
	def apply_patch(source_data: bytes, patch_data: bytes) -> bytes:
		"""Apply IPS patch to source data"""
		if not patch_data.startswith(IPSPatcher.HEADER):
			raise ValueError("Invalid IPS patch: missing header")

		result = bytearray(source_data)
		i = len(IPSPatcher.HEADER)

		while i < len(patch_data):
			# Check for EOF
			if patch_data[i:i + 3] == IPSPatcher.EOF_MARKER:
				break

			# Read record
			if i + 5 > len(patch_data):
				break

			# Offset (24-bit big-endian)
			offset = struct.unpack('>I', b'\x00' + patch_data[i:i + 3])[0]
			i += 3

			# Size (16-bit big-endian)
			size = struct.unpack('>H', patch_data[i:i + 2])[0]
			i += 2

			if size == 0:
				# RLE record: next 2 bytes are size, next byte is value
				if i + 3 > len(patch_data):
					break
				rle_size = struct.unpack('>H', patch_data[i:i + 2])[0]
				i += 2
				rle_value = patch_data[i]
				i += 1

				# Expand result if needed
				if offset + rle_size > len(result):
					result.extend([0] * (offset + rle_size - len(result)))

				# Apply RLE
				result[offset:offset + rle_size] = [rle_value] * rle_size
			else:
				# Normal record
				if i + size > len(patch_data):
					break

				patch_bytes = patch_data[i:i + size]
				i += size

				# Expand result if needed
				if offset + size > len(result):
					result.extend([0] * (offset + size - len(result)))

				# Apply patch
				result[offset:offset + size] = patch_bytes

		return bytes(result)

	@staticmethod
	def validate_patch(patch_data: bytes) -> bool:
		"""Validate IPS patch format"""
		if not patch_data.startswith(IPSPatcher.HEADER):
			return False

		if not IPSPatcher.EOF_MARKER in patch_data:
			return False

		return True


class UPSPatcher:
	"""UPS (Universal Patching System) format handler"""

	HEADER = b'UPS1'

	@staticmethod
	def create_patch(source_data: bytes, target_data: bytes,
					 metadata: Optional[PatchMetadata] = None) -> bytes:
		"""Create UPS patch"""
		patch = bytearray(UPSPatcher.HEADER)

		# Source size (VLV encoded)
		patch.extend(UPSPatcher._encode_vlv(len(source_data)))

		# Target size (VLV encoded)
		patch.extend(UPSPatcher._encode_vlv(len(target_data)))

		# Find differences
		i = 0
		max_len = max(len(source_data), len(target_data))

		while i < max_len:
			# Skip matching bytes
			offset = 0
			while i < max_len:
				src_byte = source_data[i] if i < len(source_data) else 0
				tgt_byte = target_data[i] if i < len(target_data) else 0

				if src_byte != tgt_byte:
					break

				offset += 1
				i += 1

			if i >= max_len:
				break

			# Encode offset
			patch.extend(UPSPatcher._encode_vlv(offset))

			# Collect XOR bytes
			xor_bytes = bytearray()
			while i < max_len:
				src_byte = source_data[i] if i < len(source_data) else 0
				tgt_byte = target_data[i] if i < len(target_data) else 0

				if src_byte == tgt_byte:
					break

				xor_bytes.append(src_byte ^ tgt_byte)
				i += 1

			# Write XOR data
			patch.extend(xor_bytes)
			patch.append(0x00)  # Terminator

		# Checksums
		source_crc = UPSPatcher._crc32(source_data)
		target_crc = UPSPatcher._crc32(target_data)
		patch_crc = UPSPatcher._crc32(bytes(patch))

		patch.extend(struct.pack('<I', source_crc))
		patch.extend(struct.pack('<I', target_crc))
		patch.extend(struct.pack('<I', patch_crc))

		return bytes(patch)

	@staticmethod
	def apply_patch(source_data: bytes, patch_data: bytes) -> bytes:
		"""Apply UPS patch"""
		if not patch_data.startswith(UPSPatcher.HEADER):
			raise ValueError("Invalid UPS patch: missing header")

		i = len(UPSPatcher.HEADER)

		# Read source size
		source_size, i = UPSPatcher._decode_vlv(patch_data, i)

		# Read target size
		target_size, i = UPSPatcher._decode_vlv(patch_data, i)

		# Verify source size
		if len(source_data) != source_size:
			raise ValueError(f"Source size mismatch: expected {source_size}, "
							 f"got {len(source_data)}")

		# Apply patches
		result = bytearray(source_data)
		result.extend([0] * (target_size - len(result)))

		position = 0

		while i < len(patch_data) - 12:  # Leave room for checksums
			# Read offset
			offset, i = UPSPatcher._decode_vlv(patch_data, i)
			position += offset

			# Read XOR bytes until terminator
			while i < len(patch_data) and patch_data[i] != 0:
				if position < len(result):
					result[position] ^= patch_data[i]
				position += 1
				i += 1

			i += 1  # Skip terminator
			position += 1

		return bytes(result[:target_size])

	@staticmethod
	def _encode_vlv(value: int) -> bytes:
		"""Encode variable-length value"""
		result = bytearray()

		while True:
			byte = value & 0x7F
			value >>= 7

			if value == 0:
				result.append(byte | 0x80)
				break
			else:
				result.append(byte)

		return bytes(result)

	@staticmethod
	def _decode_vlv(data: bytes, offset: int) -> Tuple[int, int]:
		"""Decode variable-length value"""
		value = 0
		shift = 0

		while offset < len(data):
			byte = data[offset]
			offset += 1

			value |= (byte & 0x7F) << shift

			if byte & 0x80:
				break

			shift += 7

		return value, offset

	@staticmethod
	def _crc32(data: bytes) -> int:
		"""Calculate CRC32 checksum"""
		# Simple CRC32 implementation
		crc = 0xFFFFFFFF

		for byte in data:
			crc ^= byte
			for _ in range(8):
				if crc & 1:
					crc = (crc >> 1) ^ 0xEDB88320
				else:
					crc >>= 1

		return crc ^ 0xFFFFFFFF


class PatchManager:
	"""Manage ROM patches"""

	def __init__(self):
		self.records = []
		self.metadata = None

	def add_record(self, offset: int, old_data: bytes, new_data: bytes,
				   description: str = ""):
		"""Add patch record"""
		record = PatchRecord(offset, old_data, new_data, description)
		self.records.append(record)

	def set_metadata(self, metadata: PatchMetadata):
		"""Set patch metadata"""
		self.metadata = metadata

	def create_patch(self, source_data: bytes, format: PatchFormat = PatchFormat.IPS
					 ) -> bytes:
		"""Create patch file"""
		# Apply all records to source to create target
		target_data = bytearray(source_data)

		for record in self.records:
			end_offset = record.offset + len(record.new_data)
			if end_offset > len(target_data):
				target_data.extend([0] * (end_offset - len(target_data)))

			target_data[record.offset:end_offset] = record.new_data

		# Create patch
		if format == PatchFormat.IPS:
			return IPSPatcher.create_patch(source_data, bytes(target_data))
		elif format == PatchFormat.UPS:
			return UPSPatcher.create_patch(source_data, bytes(target_data), self.metadata)
		else:
			raise ValueError(f"Unsupported patch format: {format}")

	def apply_patch(self, source_data: bytes, patch_data: bytes,
					format: PatchFormat = PatchFormat.IPS) -> bytes:
		"""Apply patch to source"""
		if format == PatchFormat.IPS:
			return IPSPatcher.apply_patch(source_data, patch_data)
		elif format == PatchFormat.UPS:
			return UPSPatcher.apply_patch(source_data, patch_data)
		else:
			raise ValueError(f"Unsupported patch format: {format}")

	def export_records(self, filepath: str):
		"""Export patch records to JSON"""
		data = {
			'metadata': self.metadata.to_dict() if self.metadata else None,
			'records': [record.to_dict() for record in self.records]
		}

		with open(filepath, 'w') as f:
			json.dump(data, f, indent=2)

	def calculate_checksum(self, data: bytes, algorithm: str = "crc32") -> str:
		"""Calculate data checksum"""
		if algorithm == "crc32":
			crc = UPSPatcher._crc32(data)
			return f"{crc:08x}"
		elif algorithm == "md5":
			return hashlib.md5(data).hexdigest()
		elif algorithm == "sha1":
			return hashlib.sha1(data).hexdigest()
		else:
			return ""


class PatchValidator:
	"""Validate patches and ROM compatibility"""

	@staticmethod
	def validate_ips(patch_data: bytes) -> Dict[str, any]:
		"""Validate IPS patch"""
		result = {
			'valid': False,
			'format': 'IPS',
			'errors': [],
			'warnings': [],
			'records': 0
		}

		# Check header
		if not patch_data.startswith(b'PATCH'):
			result['errors'].append("Missing PATCH header")
			return result

		# Check EOF
		if b'EOF' not in patch_data:
			result['errors'].append("Missing EOF marker")
			return result

		# Count records
		i = 5  # After header
		record_count = 0

		try:
			while i < len(patch_data):
				if patch_data[i:i + 3] == b'EOF':
					break

				if i + 5 > len(patch_data):
					result['errors'].append("Truncated record")
					break

				# Read size
				size = struct.unpack('>H', patch_data[i + 3:i + 5])[0]
				i += 5

				if size == 0:  # RLE
					i += 3
				else:
					i += size

				record_count += 1

			result['records'] = record_count
			result['valid'] = len(result['errors']) == 0

		except Exception as e:
			result['errors'].append(f"Parse error: {str(e)}")

		return result

	@staticmethod
	def compare_roms(rom1_data: bytes, rom2_data: bytes) -> Dict[str, any]:
		"""Compare two ROMs"""
		differences = []

		max_len = max(len(rom1_data), len(rom2_data))

		i = 0
		while i < max_len:
			byte1 = rom1_data[i] if i < len(rom1_data) else 0
			byte2 = rom2_data[i] if i < len(rom2_data) else 0

			if byte1 != byte2:
				# Find run of differences
				start = i
				while i < max_len:
					b1 = rom1_data[i] if i < len(rom1_data) else 0
					b2 = rom2_data[i] if i < len(rom2_data) else 0
					if b1 == b2:
						break
					i += 1

				differences.append({
					'offset': hex(start),
					'size': i - start,
					'old_data': rom1_data[start:i].hex() if start < len(rom1_data) else "",
					'new_data': rom2_data[start:i].hex() if start < len(rom2_data) else ""
				})
			else:
				i += 1

		return {
			'rom1_size': len(rom1_data),
			'rom2_size': len(rom2_data),
			'differences': len(differences),
			'changed_bytes': sum(d['size'] for d in differences),
			'details': differences[:100]  # Limit to first 100
		}


def main():
	"""Test patching system"""

	# Create test ROM data
	source_rom = bytearray(1024)
	for i in range(len(source_rom)):
		source_rom[i] = i % 256

	# Create modified version
	target_rom = bytearray(source_rom)

	# Make some changes
	target_rom[0x100:0x110] = b'MODIFIED DATA!!!'
	target_rom[0x500] = 0xFF
	target_rom[0x800:0x900] = bytes([0xAA] * 256)

	# Create patch
	manager = PatchManager()

	# Add metadata
	metadata = PatchMetadata(
		name="Test Patch",
		author="AI Assistant",
		version="1.0",
		description="Test patch for demonstration",
		source_checksum=manager.calculate_checksum(bytes(source_rom)),
		target_checksum=manager.calculate_checksum(bytes(target_rom)),
		created_date="2025-11-08"
	)
	manager.set_metadata(metadata)

	# Create IPS patch
	ips_patch = IPSPatcher.create_patch(bytes(source_rom), bytes(target_rom))
	print(f"IPS patch created: {len(ips_patch)} bytes")

	# Validate IPS
	validation = PatchValidator.validate_ips(ips_patch)
	print(f"IPS validation: {validation}")

	# Apply IPS patch
	patched_rom = IPSPatcher.apply_patch(bytes(source_rom), ips_patch)

	if patched_rom == bytes(target_rom):
		print("✓ IPS patch applied successfully!")
	else:
		print("✗ IPS patch failed!")

	# Create UPS patch
	ups_patch = UPSPatcher.create_patch(bytes(source_rom), bytes(target_rom), metadata)
	print(f"\nUPS patch created: {len(ups_patch)} bytes")

	# Apply UPS patch
	patched_ups = UPSPatcher.apply_patch(bytes(source_rom), ups_patch)

	if patched_ups == bytes(target_rom):
		print("✓ UPS patch applied successfully!")
	else:
		print("✗ UPS patch failed!")

	# Compare ROMs
	comparison = PatchValidator.compare_roms(bytes(source_rom), bytes(target_rom))
	print(f"\nROM Comparison:")
	print(f"  Differences: {comparison['differences']}")
	print(f"  Changed bytes: {comparison['changed_bytes']}")

	# Save patches
	with open("test.ips", 'wb') as f:
		f.write(ips_patch)

	with open("test.ups", 'wb') as f:
		f.write(ups_patch)

	print("\nPatches saved: test.ips, test.ups")


if __name__ == '__main__':
	main()
