"""
FFMQ Music and Audio Data Structures

Handles music tracks, sound effects, and SPC audio data.
"""

from dataclasses import dataclass, field
from typing import List, Optional, Dict
from enum import Enum
import struct


# ROM addresses for music data
MUSIC_TABLE_BASE = 0x0D8000  # Music track pointers
SFX_TABLE_BASE = 0x0DA000	# Sound effect pointers
SAMPLE_TABLE_BASE = 0x0DC000  # Sample/instrument data
SPC_DATA_BASE = 0x0E0000	 # SPC700 driver code


class MusicType(Enum):
	"""Types of music tracks"""
	FIELD = 0	  # Overworld/field music
	BATTLE = 1	 # Battle music
	TOWN = 2	   # Town music
	DUNGEON = 3	# Dungeon music
	BOSS = 4	   # Boss battle music
	EVENT = 5	  # Event/cutscene music
	FANFARE = 6	# Victory/fanfare


class SoundEffectType(Enum):
	"""Types of sound effects"""
	MENU = 0	   # Menu sounds
	ATTACK = 1	 # Attack sounds
	SPELL = 2	  # Spell/magic sounds
	ITEM = 3	   # Item use sounds
	FOOTSTEP = 4   # Movement sounds
	AMBIENT = 5	# Background/ambient sounds


@dataclass
class MusicTrack:
	"""Represents a music track"""
	track_id: int
	name: str = ""
	music_type: MusicType = MusicType.FIELD
	tempo: int = 120  # BPM
	volume: int = 127  # 0-127
	loop_start: int = 0  # Loop point in ticks
	loop_end: int = 0	# Loop end point
	data_offset: int = 0  # ROM offset to track data
	data_size: int = 0	# Size of track data in bytes
	
	# Channel settings
	channels_used: int = 0xFF  # Bitmask of active channels (8 channels)
	
	def to_bytes(self) -> bytes:
		"""Convert to bytes for ROM"""
		data = bytearray(16)
		
		# Header
		data[0] = self.music_type.value
		data[1] = self.tempo & 0xFF
		data[2] = self.volume & 0x7F
		data[3] = self.channels_used & 0xFF
		
		# Loop points (2 bytes each)
		struct.pack_into('<H', data, 4, self.loop_start & 0xFFFF)
		struct.pack_into('<H', data, 6, self.loop_end & 0xFFFF)
		
		# Data offset and size (3 bytes each for 24-bit addresses)
		struct.pack_into('<I', data, 8, self.data_offset & 0xFFFFFF)
		data[11] = 0  # Padding
		struct.pack_into('<I', data, 12, self.data_size & 0xFFFFFF)
		data[15] = 0  # Padding
		
		return bytes(data)
	
	@classmethod
	def from_bytes(cls, data: bytes, track_id: int) -> 'MusicTrack':
		"""Create from ROM bytes"""
		track = cls(track_id=track_id)
		
		track.music_type = MusicType(data[0] & 0x07)
		track.tempo = data[1]
		track.volume = data[2] & 0x7F
		track.channels_used = data[3]
		
		track.loop_start = struct.unpack_from('<H', data, 4)[0]
		track.loop_end = struct.unpack_from('<H', data, 6)[0]
		
		track.data_offset = struct.unpack_from('<I', data, 8)[0] & 0xFFFFFF
		track.data_size = struct.unpack_from('<I', data, 12)[0] & 0xFFFFFF
		
		return track
	
	def get_duration_seconds(self, ticks_per_second: int = 60) -> float:
		"""Calculate track duration in seconds"""
		if self.loop_end > 0:
			ticks = self.loop_end
		else:
			# Estimate based on data size
			ticks = self.data_size * 4
		
		return ticks / ticks_per_second


@dataclass
class SoundEffect:
	"""Represents a sound effect"""
	sfx_id: int
	name: str = ""
	sfx_type: SoundEffectType = SoundEffectType.MENU
	priority: int = 64  # 0-127, higher = more important
	volume: int = 127   # 0-127
	pitch: int = 64	 # 0-127, 64 = normal
	pan: int = 64	   # 0-127, 64 = center
	data_offset: int = 0
	data_size: int = 0
	
	def to_bytes(self) -> bytes:
		"""Convert to bytes for ROM"""
		data = bytearray(12)
		
		data[0] = self.sfx_type.value
		data[1] = self.priority & 0x7F
		data[2] = self.volume & 0x7F
		data[3] = self.pitch & 0x7F
		data[4] = self.pan & 0x7F
		data[5] = 0  # Reserved
		
		# Data offset and size
		struct.pack_into('<I', data, 6, self.data_offset & 0xFFFFFF)
		data[9] = 0  # Padding
		struct.pack_into('<H', data, 10, self.data_size & 0xFFFF)
		
		return bytes(data)
	
	@classmethod
	def from_bytes(cls, data: bytes, sfx_id: int) -> 'SoundEffect':
		"""Create from ROM bytes"""
		sfx = cls(sfx_id=sfx_id)
		
		sfx.sfx_type = SoundEffectType(data[0] & 0x07)
		sfx.priority = data[1] & 0x7F
		sfx.volume = data[2] & 0x7F
		sfx.pitch = data[3] & 0x7F
		sfx.pan = data[4] & 0x7F
		
		sfx.data_offset = struct.unpack_from('<I', data, 6)[0] & 0xFFFFFF
		sfx.data_size = struct.unpack_from('<H', data, 10)[0]
		
		return sfx


@dataclass
class Sample:
	"""Represents an audio sample/instrument"""
	sample_id: int
	name: str = ""
	loop_start: int = 0  # Sample loop point
	loop_length: int = 0  # Loop length
	pitch_multiplier: int = 256  # Pitch adjustment (256 = normal)
	envelope: int = 0xE0  # ADSR envelope
	data_offset: int = 0
	data_size: int = 0
	
	def to_bytes(self) -> bytes:
		"""Convert to bytes for ROM"""
		data = bytearray(16)
		
		struct.pack_into('<H', data, 0, self.loop_start & 0xFFFF)
		struct.pack_into('<H', data, 2, self.loop_length & 0xFFFF)
		struct.pack_into('<H', data, 4, self.pitch_multiplier & 0xFFFF)
		data[6] = self.envelope & 0xFF
		data[7] = 0  # Reserved
		
		struct.pack_into('<I', data, 8, self.data_offset & 0xFFFFFF)
		data[11] = 0
		struct.pack_into('<I', data, 12, self.data_size & 0xFFFFFF)
		data[15] = 0
		
		return bytes(data)
	
	@classmethod
	def from_bytes(cls, data: bytes, sample_id: int) -> 'Sample':
		"""Create from ROM bytes"""
		sample = cls(sample_id=sample_id)
		
		sample.loop_start = struct.unpack_from('<H', data, 0)[0]
		sample.loop_length = struct.unpack_from('<H', data, 2)[0]
		sample.pitch_multiplier = struct.unpack_from('<H', data, 4)[0]
		sample.envelope = data[6]
		
		sample.data_offset = struct.unpack_from('<I', data, 8)[0] & 0xFFFFFF
		sample.data_size = struct.unpack_from('<I', data, 12)[0] & 0xFFFFFF
		
		return sample


@dataclass
class SPCState:
	"""SPC700 audio processor state"""
	# DSP registers
	master_volume_l: int = 127
	master_volume_r: int = 127
	echo_volume_l: int = 0
	echo_volume_r: int = 0
	echo_feedback: int = 0
	echo_delay: int = 0
	
	# Channel states (8 channels)
	channel_volumes: List[int] = field(default_factory=lambda: [127] * 8)
	channel_pans: List[int] = field(default_factory=lambda: [64] * 8)
	channel_pitches: List[int] = field(default_factory=lambda: [0] * 8)
	channel_samples: List[int] = field(default_factory=lambda: [0] * 8)
	
	def to_bytes(self) -> bytes:
		"""Convert to SPC register dump"""
		data = bytearray(128)
		
		# Master volume
		data[0x0C] = self.master_volume_l & 0x7F
		data[0x1C] = self.master_volume_r & 0x7F
		
		# Echo
		data[0x2C] = self.echo_volume_l & 0x7F
		data[0x3C] = self.echo_volume_r & 0x7F
		data[0x0D] = self.echo_feedback & 0x7F
		data[0x7D] = self.echo_delay & 0x0F
		
		# Channels
		for i in range(8):
			base = i * 0x10
			data[base + 0x00] = self.channel_volumes[i] & 0x7F  # Volume L
			data[base + 0x01] = self.channel_volumes[i] & 0x7F  # Volume R
			data[base + 0x02] = self.channel_pitches[i] & 0xFF  # Pitch low
			data[base + 0x03] = (self.channel_pitches[i] >> 8) & 0x3F  # Pitch high
			data[base + 0x04] = self.channel_samples[i] & 0xFF  # Sample
		
		return bytes(data)
	
	@classmethod
	def from_bytes(cls, data: bytes) -> 'SPCState':
		"""Create from SPC register dump"""
		state = cls()
		
		state.master_volume_l = data[0x0C] & 0x7F
		state.master_volume_r = data[0x1C] & 0x7F
		
		state.echo_volume_l = data[0x2C] & 0x7F
		state.echo_volume_r = data[0x3C] & 0x7F
		state.echo_feedback = data[0x0D] & 0x7F
		state.echo_delay = data[0x7D] & 0x0F
		
		for i in range(8):
			base = i * 0x10
			state.channel_volumes[i] = data[base + 0x00] & 0x7F
			state.channel_pans[i] = 64  # Default center
			state.channel_pitches[i] = data[base + 0x02] | ((data[base + 0x03] & 0x3F) << 8)
			state.channel_samples[i] = data[base + 0x04]
		
		return state


# Default music track names for FFMQ
DEFAULT_MUSIC_NAMES = {
	0x00: "Title Theme",
	0x01: "Overworld",
	0x02: "Town Theme",
	0x03: "Dungeon Theme",
	0x04: "Battle Theme",
	0x05: "Boss Battle",
	0x06: "Final Battle",
	0x07: "Victory Fanfare",
	0x08: "Game Over",
	0x09: "Inn/Rest",
	0x0A: "Shop Theme",
	0x0B: "Mystic Forest",
	0x0C: "Ice Pyramid",
	0x0D: "Volcano",
	0x0E: "Mine Cart",
	0x0F: "Ship Theme",
	0x10: "Credits",
	0x11: "Chocobo",
	0x12: "Peaceful Theme",
	0x13: "Tension",
	0x14: "Sad Theme",
	0x15: "Mysterious",
}

# Default sound effect names
DEFAULT_SFX_NAMES = {
	0x00: "Cursor Move",
	0x01: "Menu Select",
	0x02: "Menu Cancel",
	0x03: "Menu Invalid",
	0x04: "Level Up",
	0x05: "Door Open",
	0x06: "Door Close",
	0x07: "Treasure Chest",
	0x08: "Attack Hit",
	0x09: "Attack Miss",
	0x0A: "Spell Cast",
	0x0B: "Heal",
	0x0C: "Item Get",
	0x0D: "Footstep",
	0x0E: "Jump",
	0x0F: "Damage",
	0x10: "Enemy Death",
	0x11: "Explosion",
	0x12: "Water Splash",
	0x13: "Fire",
	0x14: "Thunder",
	0x15: "Wind",
	0x16: "Earth",
	0x17: "Ice",
	0x18: "Critical Hit",
	0x19: "Status Effect",
	0x1A: "Warp",
}


def create_default_track(track_id: int, music_type: MusicType = MusicType.FIELD) -> MusicTrack:
	"""Create a default music track"""
	track = MusicTrack(
		track_id=track_id,
		name=DEFAULT_MUSIC_NAMES.get(track_id, f"Track {track_id}"),
		music_type=music_type,
		tempo=120,
		volume=127,
		channels_used=0xFF
	)
	return track


def create_default_sfx(sfx_id: int, sfx_type: SoundEffectType = SoundEffectType.MENU) -> SoundEffect:
	"""Create a default sound effect"""
	sfx = SoundEffect(
		sfx_id=sfx_id,
		name=DEFAULT_SFX_NAMES.get(sfx_id, f"SFX {sfx_id}"),
		sfx_type=sfx_type,
		priority=64,
		volume=127
	)
	return sfx


def note_to_pitch(note: str) -> int:
	"""Convert note name to pitch value (e.g., "C4" -> pitch)"""
	note_values = {
		'C': 0, 'C#': 1, 'D': 2, 'D#': 3, 'E': 4, 'F': 5,
		'F#': 6, 'G': 7, 'G#': 8, 'A': 9, 'A#': 10, 'B': 11
	}
	
	# Parse note
	if len(note) < 2:
		return 0
	
	note_name = note[:-1]
	octave = int(note[-1])
	
	if note_name not in note_values:
		return 0
	
	# Calculate pitch (A4 = 440Hz is reference)
	semitones_from_c4 = note_values[note_name] + (octave - 4) * 12
	
	# SNES pitch calculation (base pitch 1000h = C4)
	base_pitch = 0x1000
	pitch = int(base_pitch * (2 ** (semitones_from_c4 / 12)))
	
	return pitch & 0x3FFF


def pitch_to_note(pitch: int) -> str:
	"""Convert pitch value to note name"""
	if pitch == 0:
		return "---"
	
	note_names = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']
	
	# Calculate semitones from base
	import math
	base_pitch = 0x1000
	semitones = 12 * math.log2(pitch / base_pitch)
	
	note_idx = int(round(semitones)) % 12
	octave = 4 + int(semitones // 12)
	
	return f"{note_names[note_idx]}{octave}"
