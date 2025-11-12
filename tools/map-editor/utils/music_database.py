"""
FFMQ Music Database Manager

Manages loading, saving, and editing music/audio data from ROM.
"""

from typing import Dict, Optional, List, Tuple
from pathlib import Path
import struct

from .music_data import (
	MusicTrack, SoundEffect, Sample, SPCState,
	MusicType, SoundEffectType,
	MUSIC_TABLE_BASE, SFX_TABLE_BASE, SAMPLE_TABLE_BASE, SPC_DATA_BASE,
	DEFAULT_MUSIC_NAMES, DEFAULT_SFX_NAMES,
	create_default_track, create_default_sfx
)


class MusicDatabase:
	"""Manages all music and audio data"""

	def __init__(self):
		self.tracks: Dict[int, MusicTrack] = {}
		self.sfx: Dict[int, SoundEffect] = {}
		self.samples: Dict[int, Sample] = {}
		self.spc_state: Optional[SPCState] = None
		self.rom_path: Optional[str] = None

	def load_from_rom(self, rom_path: str):
		"""Load music data from ROM"""
		self.rom_path = rom_path

		with open(rom_path, 'rb') as f:
			rom_data = f.read()

		# Load music tracks
		self._load_music_tracks(rom_data)

		# Load sound effects
		self._load_sound_effects(rom_data)

		# Load samples
		self._load_samples(rom_data)

		print(f"Loaded {len(self.tracks)} music tracks, {len(self.sfx)} SFX, {len(self.samples)} samples")

	def _load_music_tracks(self, rom_data: bytes):
		"""Load music tracks from ROM"""
		# FFMQ typically has around 32 music tracks
		for i in range(32):
			offset = MUSIC_TABLE_BASE + (i * 16)

			if offset + 16 > len(rom_data):
				break

			track_data = rom_data[offset:offset + 16]

			# Check if track is valid (non-zero data)
			if any(b != 0 for b in track_data):
				track = MusicTrack.from_bytes(track_data, i)
				track.name = DEFAULT_MUSIC_NAMES.get(i, f"Track {i:02X}")
				self.tracks[i] = track

	def _load_sound_effects(self, rom_data: bytes):
		"""Load sound effects from ROM"""
		# FFMQ typically has around 64 sound effects
		for i in range(64):
			offset = SFX_TABLE_BASE + (i * 12)

			if offset + 12 > len(rom_data):
				break

			sfx_data = rom_data[offset:offset + 12]

			# Check if SFX is valid
			if any(b != 0 for b in sfx_data):
				sfx = SoundEffect.from_bytes(sfx_data, i)
				sfx.name = DEFAULT_SFX_NAMES.get(i, f"SFX {i:02X}")
				self.sfx[i] = sfx

	def _load_samples(self, rom_data: bytes):
		"""Load sample data from ROM"""
		# FFMQ typically has around 32 samples/instruments
		for i in range(32):
			offset = SAMPLE_TABLE_BASE + (i * 16)

			if offset + 16 > len(rom_data):
				break

			sample_data = rom_data[offset:offset + 16]

			# Check if sample is valid
			if any(b != 0 for b in sample_data):
				sample = Sample.from_bytes(sample_data, i)
				sample.name = f"Sample {i:02X}"
				self.samples[i] = sample

	def save_to_rom(self, rom_path: Optional[str] = None):
		"""Save music data to ROM"""
		if rom_path is None:
			rom_path = self.rom_path

		if rom_path is None:
			raise ValueError("No ROM path specified")

		with open(rom_path, 'rb') as f:
			rom_data = bytearray(f.read())

		# Save music tracks
		for track_id, track in self.tracks.items():
			offset = MUSIC_TABLE_BASE + (track_id * 16)
			if offset + 16 <= len(rom_data):
				track_bytes = track.to_bytes()
				rom_data[offset:offset + 16] = track_bytes

		# Save sound effects
		for sfx_id, sfx in self.sfx.items():
			offset = SFX_TABLE_BASE + (sfx_id * 12)
			if offset + 12 <= len(rom_data):
				sfx_bytes = sfx.to_bytes()
				rom_data[offset:offset + 12] = sfx_bytes

		# Save samples
		for sample_id, sample in self.samples.items():
			offset = SAMPLE_TABLE_BASE + (sample_id * 16)
			if offset + 16 <= len(rom_data):
				sample_bytes = sample.to_bytes()
				rom_data[offset:offset + 16] = sample_bytes

		# Write back to ROM
		with open(rom_path, 'wb') as f:
			f.write(rom_data)

		print(f"Saved music data to {rom_path}")

	def get_track(self, track_id: int) -> Optional[MusicTrack]:
		"""Get music track by ID"""
		return self.tracks.get(track_id)

	def get_sfx(self, sfx_id: int) -> Optional[SoundEffect]:
		"""Get sound effect by ID"""
		return self.sfx.get(sfx_id)

	def get_sample(self, sample_id: int) -> Optional[Sample]:
		"""Get sample by ID"""
		return self.samples.get(sample_id)

	def add_track(self, track: MusicTrack) -> bool:
		"""Add or update a music track"""
		if 0 <= track.track_id < 32:
			self.tracks[track.track_id] = track
			return True
		return False

	def add_sfx(self, sfx: SoundEffect) -> bool:
		"""Add or update a sound effect"""
		if 0 <= sfx.sfx_id < 64:
			self.sfx[sfx.sfx_id] = sfx
			return True
		return False

	def add_sample(self, sample: Sample) -> bool:
		"""Add or update a sample"""
		if 0 <= sample.sample_id < 32:
			self.samples[sample.sample_id] = sample
			return True
		return False

	def get_tracks_by_type(self, music_type: MusicType) -> List[MusicTrack]:
		"""Get all tracks of a specific type"""
		return [track for track in self.tracks.values() if track.music_type == music_type]

	def get_sfx_by_type(self, sfx_type: SoundEffectType) -> List[SoundEffect]:
		"""Get all sound effects of a specific type"""
		return [sfx for sfx in self.sfx.values() if sfx.sfx_type == sfx_type]

	def export_spc(self, track_id: int, output_path: str):
		"""Export track as SPC file (SNES audio format)"""
		track = self.get_track(track_id)
		if track is None:
			raise ValueError(f"Track {track_id} not found")

		# SPC file format header
		spc_header = bytearray(256)

		# Magic header
		spc_header[0:33] = b'SNES-SPC700 Sound File Data v0.30'
		spc_header[33:35] = b'\x1A\x1A'

		# Version
		spc_header[35] = 0x1E  # Has ID666 tag
		spc_header[36] = 30	# Version minor

		# SPC700 registers (initial state)
		spc_header[37:43] = b'\x00' * 6  # PC, A, X, Y, PSW, SP

		# Reserved
		spc_header[43:45] = b'\x00\x00'

		# ID666 tag (song info)
		song_title = track.name[:32].encode('ascii', errors='ignore')
		spc_header[46:46+len(song_title)] = song_title

		game_title = b'Final Fantasy Mystic Quest'
		spc_header[78:78+len(game_title)] = game_title

		# Time and fade (optional)
		spc_header[171:174] = b'\x00\x00\x00'  # Intro length
		spc_header[174:177] = b'\x00\x00\x00'  # Loop length
		spc_header[177:181] = b'\x00\x00\x00\x00'  # Fade length

		# Artist
		artist = b'Square'
		spc_header[181:181+len(artist)] = artist

		# Read track data from ROM
		if self.rom_path:
			with open(self.rom_path, 'rb') as f:
				f.seek(track.data_offset)
				track_data = f.read(min(track.data_size, 65536))
		else:
			track_data = b'\x00' * 65536

		# Create SPC file
		with open(output_path, 'wb') as f:
			# Write header
			f.write(spc_header)

			# Write 64KB RAM dump
			ram_data = bytearray(65536)
			ram_data[:len(track_data)] = track_data
			f.write(ram_data)

			# Write 128-byte DSP registers
			if self.spc_state:
				f.write(self.spc_state.to_bytes())
			else:
				f.write(b'\x00' * 128)

			# Write 64 bytes unused
			f.write(b'\x00' * 64)

			# Write 64-byte IPL ROM
			f.write(b'\x00' * 64)

		print(f"Exported track {track_id} to {output_path}")

	def import_spc(self, spc_path: str) -> Optional[MusicTrack]:
		"""Import SPC file as a music track"""
		with open(spc_path, 'rb') as f:
			spc_data = f.read()

		if len(spc_data) < 256:
			print("Invalid SPC file (too small)")
			return None

		# Verify magic header
		magic = spc_data[0:33]
		if not magic.startswith(b'SNES-SPC700'):
			print("Invalid SPC file (bad header)")
			return None

		# Read song title
		song_title = spc_data[46:78].decode('ascii', errors='ignore').strip('\x00')

		# Create track
		track_id = len(self.tracks)
		track = create_default_track(track_id)
		track.name = song_title if song_title else f"Imported Track {track_id}"

		# Read RAM data (track data is in here)
		if len(spc_data) >= 256 + 65536:
			ram_data = spc_data[256:256+65536]
			# Find actual track data size (scan for end marker or zeros)
			data_size = 0
			for i in range(len(ram_data)):
				if ram_data[i] != 0:
					data_size = i + 1

			track.data_size = min(data_size, 8192)  # Reasonable limit

		# Read DSP state
		if len(spc_data) >= 256 + 65536 + 128:
			dsp_data = spc_data[256+65536:256+65536+128]
			self.spc_state = SPCState.from_bytes(dsp_data)

		print(f"Imported SPC file: {song_title}")
		return track

	def get_statistics(self) -> Dict[str, any]:
		"""Get music statistics"""
		stats = {
			'total_tracks': len(self.tracks),
			'total_sfx': len(self.sfx),
			'total_samples': len(self.samples),
			'tracks_by_type': {mt.name: len(self.get_tracks_by_type(mt)) for mt in MusicType},
			'sfx_by_type': {st.name: len(self.get_sfx_by_type(st)) for st in SoundEffectType},
			'total_music_size': sum(t.data_size for t in self.tracks.values()),
			'total_sfx_size': sum(s.data_size for s in self.sfx.values()),
		}
		return stats

	def find_unused_tracks(self) -> List[int]:
		"""Find unused track IDs"""
		used_ids = set(self.tracks.keys())
		all_ids = set(range(32))
		return sorted(list(all_ids - used_ids))

	def find_unused_sfx(self) -> List[int]:
		"""Find unused SFX IDs"""
		used_ids = set(self.sfx.keys())
		all_ids = set(range(64))
		return sorted(list(all_ids - used_ids))

	def duplicate_track(self, track_id: int, new_id: Optional[int] = None) -> Optional[MusicTrack]:
		"""Duplicate a music track"""
		track = self.get_track(track_id)
		if track is None:
			return None

		if new_id is None:
			# Find first unused ID
			unused = self.find_unused_tracks()
			if not unused:
				return None
			new_id = unused[0]

		# Create copy
		new_track = MusicTrack(
			track_id=new_id,
			name=f"{track.name} (Copy)",
			music_type=track.music_type,
			tempo=track.tempo,
			volume=track.volume,
			loop_start=track.loop_start,
			loop_end=track.loop_end,
			data_offset=track.data_offset,
			data_size=track.data_size,
			channels_used=track.channels_used
		)

		self.tracks[new_id] = new_track
		return new_track

	def swap_tracks(self, track_id1: int, track_id2: int) -> bool:
		"""Swap two music tracks"""
		track1 = self.get_track(track_id1)
		track2 = self.get_track(track_id2)

		if track1 is None or track2 is None:
			return False

		# Swap IDs
		track1.track_id, track2.track_id = track2.track_id, track1.track_id
		self.tracks[track_id1] = track2
		self.tracks[track_id2] = track1

		return True

	def validate_track(self, track_id: int) -> List[str]:
		"""Validate track data and return any issues"""
		track = self.get_track(track_id)
		if track is None:
			return ["Track not found"]

		issues = []

		if track.tempo < 40 or track.tempo > 240:
			issues.append(f"Unusual tempo: {track.tempo} BPM")

		if track.volume > 127:
			issues.append(f"Invalid volume: {track.volume}")

		if track.loop_end > 0 and track.loop_start >= track.loop_end:
			issues.append("Loop start >= loop end")

		if track.data_size == 0:
			issues.append("No track data")
		elif track.data_size > 16384:
			issues.append(f"Large track data: {track.data_size} bytes")

		return issues
