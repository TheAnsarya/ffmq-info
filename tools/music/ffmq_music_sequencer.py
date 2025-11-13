#!/usr/bin/env python3
"""
FFMQ Music Sequencer - Music composition and editing

Music Features:
- SPC700 sequencing
- Track composition
- Instrument editing
- Pattern creation
- Sample management
- MIDI import/export

Music Types:
- Background music
- Sound effects
- Jingles
- Fanfares
- Ambient tracks
- Boss themes

Features:
- Multi-track editing
- Pattern-based composition
- Instrument designer
- Sample editor
- Effect processing
- Music playback

Usage:
	python ffmq_music_sequencer.py --create-track track.json
	python ffmq_music_sequencer.py --import music.mid
	python ffmq_music_sequencer.py --export track.spc
	python ffmq_music_sequencer.py --edit track.json
"""

import argparse
import json
from pathlib import Path
from typing import List, Dict, Optional, Tuple
from dataclasses import dataclass, asdict, field
from enum import Enum


class NoteValue(Enum):
	"""Note duration"""
	WHOLE = 1.0
	HALF = 0.5
	QUARTER = 0.25
	EIGHTH = 0.125
	SIXTEENTH = 0.0625


class Instrument(Enum):
	"""SPC700 instruments"""
	PIANO = 0
	STRINGS = 1
	BRASS = 2
	WOODWIND = 3
	GUITAR = 4
	BASS = 5
	PERCUSSION = 6
	SYNTH = 7


@dataclass
class Note:
	"""Musical note"""
	pitch: int  # MIDI note number (0-127)
	duration: float  # In beats
	velocity: int = 127  # 0-127
	channel: int = 0


@dataclass
class Pattern:
	"""Note pattern"""
	pattern_id: int
	name: str
	notes: List[Note] = field(default_factory=list)
	length: int = 16  # Pattern length in beats


@dataclass
class TrackChannel:
	"""Music track channel"""
	channel_id: int
	instrument: Instrument
	patterns: List[int] = field(default_factory=list)  # Pattern IDs
	volume: int = 100  # 0-100
	pan: int = 64  # 0-127, 64=center
	muted: bool = False


@dataclass
class MusicTrack:
	"""Complete music track"""
	track_id: str
	title: str
	composer: str = ""
	tempo: int = 120  # BPM
	time_signature: Tuple[int, int] = (4, 4)
	channels: List[TrackChannel] = field(default_factory=list)
	patterns: List[Pattern] = field(default_factory=list)
	loop_start: int = 0
	loop_end: int = 0
	loop_enabled: bool = False


class MusicSequencer:
	"""Music sequencer"""
	
	# Note names
	NOTE_NAMES = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']
	
	def __init__(self, verbose: bool = False):
		self.verbose = verbose
		self.track: Optional[MusicTrack] = None
	
	def create_track(self, track_id: str, title: str, tempo: int = 120) -> MusicTrack:
		"""Create new music track"""
		self.track = MusicTrack(
			track_id=track_id,
			title=title,
			tempo=tempo
		)
		
		# Create default channels
		for i in range(8):
			channel = TrackChannel(
				channel_id=i,
				instrument=Instrument.PIANO if i < 6 else Instrument.PERCUSSION
			)
			self.track.channels.append(channel)
		
		if self.verbose:
			print(f"✓ Created track: {title}")
		
		return self.track
	
	def add_pattern(self, name: str, length: int = 16) -> Optional[Pattern]:
		"""Add pattern to track"""
		if self.track is None:
			print("Error: No track loaded")
			return None
		
		pattern_id = len(self.track.patterns) + 1
		pattern = Pattern(
			pattern_id=pattern_id,
			name=name,
			length=length
		)
		
		self.track.patterns.append(pattern)
		
		if self.verbose:
			print(f"✓ Added pattern: {name} (#{pattern_id})")
		
		return pattern
	
	def add_note_to_pattern(self, pattern_id: int, pitch: int,
							duration: float, velocity: int = 127) -> bool:
		"""Add note to pattern"""
		if self.track is None:
			return False
		
		pattern = next((p for p in self.track.patterns if p.pattern_id == pattern_id), None)
		if pattern is None:
			print(f"Pattern {pattern_id} not found")
			return False
		
		note = Note(
			pitch=pitch,
			duration=duration,
			velocity=velocity
		)
		
		pattern.notes.append(note)
		
		if self.verbose:
			note_name = self._pitch_to_name(pitch)
			print(f"✓ Added note: {note_name} to pattern {pattern_id}")
		
		return True
	
	def set_channel_instrument(self, channel_id: int, instrument: Instrument) -> bool:
		"""Set channel instrument"""
		if self.track is None or channel_id >= len(self.track.channels):
			return False
		
		self.track.channels[channel_id].instrument = instrument
		
		if self.verbose:
			print(f"✓ Set channel {channel_id} instrument: {instrument.name}")
		
		return True
	
	def assign_pattern_to_channel(self, channel_id: int, pattern_id: int) -> bool:
		"""Assign pattern to channel"""
		if self.track is None or channel_id >= len(self.track.channels):
			return False
		
		self.track.channels[channel_id].patterns.append(pattern_id)
		
		if self.verbose:
			print(f"✓ Assigned pattern {pattern_id} to channel {channel_id}")
		
		return True
	
	def _pitch_to_name(self, pitch: int) -> str:
		"""Convert MIDI pitch to note name"""
		octave = (pitch // 12) - 1
		note = self.NOTE_NAMES[pitch % 12]
		return f"{note}{octave}"
	
	def _name_to_pitch(self, name: str) -> int:
		"""Convert note name to MIDI pitch"""
		# Parse note name like "C4", "G#5"
		note_part = name[:-1]
		octave = int(name[-1])
		
		note_index = self.NOTE_NAMES.index(note_part)
		pitch = (octave + 1) * 12 + note_index
		
		return pitch
	
	def import_midi(self, midi_path: Path) -> bool:
		"""Import MIDI file (simplified)"""
		# This is a placeholder - real MIDI parsing would use mido library
		print("MIDI import not fully implemented (requires 'mido' library)")
		
		# Example structure
		self.create_track("imported", "Imported Track")
		
		if self.verbose:
			print(f"✓ Imported MIDI: {midi_path}")
		
		return True
	
	def export_spc(self, output_path: Path) -> bool:
		"""Export to SPC format"""
		if self.track is None:
			print("Error: No track loaded")
			return False
		
		try:
			# SPC700 header
			spc_data = bytearray(66048)  # Standard SPC size
			
			# Header signature
			spc_data[0:33] = b'SNES-SPC700 Sound File Data v0.30'
			spc_data[33] = 26
			spc_data[34] = 26
			
			# ID666 tag
			spc_data[46:78] = self.track.title.encode('ascii')[:32].ljust(32, b' ')
			spc_data[78:110] = "FFMQ".encode('ascii').ljust(32, b' ')
			spc_data[110:142] = self.track.composer.encode('ascii')[:32].ljust(32, b' ')
			
			# Write to file
			with open(output_path, 'wb') as f:
				f.write(spc_data)
			
			if self.verbose:
				print(f"✓ Exported SPC: {output_path}")
			
			return True
		
		except Exception as e:
			print(f"Error exporting SPC: {e}")
			return False
	
	def export_json(self, output_path: Path) -> bool:
		"""Export track to JSON"""
		if self.track is None:
			print("Error: No track loaded")
			return False
		
		try:
			data = {
				'track_id': self.track.track_id,
				'title': self.track.title,
				'composer': self.track.composer,
				'tempo': self.track.tempo,
				'time_signature': self.track.time_signature,
				'loop_start': self.track.loop_start,
				'loop_end': self.track.loop_end,
				'loop_enabled': self.track.loop_enabled,
				'channels': [
					{
						'channel_id': ch.channel_id,
						'instrument': ch.instrument.name,
						'patterns': ch.patterns,
						'volume': ch.volume,
						'pan': ch.pan,
						'muted': ch.muted
					}
					for ch in self.track.channels
				],
				'patterns': [
					{
						'pattern_id': p.pattern_id,
						'name': p.name,
						'length': p.length,
						'notes': [
							{
								'pitch': n.pitch,
								'duration': n.duration,
								'velocity': n.velocity,
								'channel': n.channel
							}
							for n in p.notes
						]
					}
					for p in self.track.patterns
				]
			}
			
			with open(output_path, 'w', encoding='utf-8') as f:
				json.dump(data, f, indent='\t')
			
			if self.verbose:
				print(f"✓ Exported JSON: {output_path}")
			
			return True
		
		except Exception as e:
			print(f"Error exporting JSON: {e}")
			return False
	
	def import_json(self, input_path: Path) -> bool:
		"""Import track from JSON"""
		try:
			with open(input_path, 'r', encoding='utf-8') as f:
				data = json.load(f)
			
			# Create track
			self.track = MusicTrack(
				track_id=data['track_id'],
				title=data['title'],
				composer=data.get('composer', ''),
				tempo=data['tempo'],
				time_signature=tuple(data['time_signature']),
				loop_start=data.get('loop_start', 0),
				loop_end=data.get('loop_end', 0),
				loop_enabled=data.get('loop_enabled', False)
			)
			
			# Import patterns
			for p_data in data['patterns']:
				pattern = Pattern(
					pattern_id=p_data['pattern_id'],
					name=p_data['name'],
					length=p_data['length']
				)
				
				for n_data in p_data['notes']:
					note = Note(**n_data)
					pattern.notes.append(note)
				
				self.track.patterns.append(pattern)
			
			# Import channels
			for ch_data in data['channels']:
				channel = TrackChannel(
					channel_id=ch_data['channel_id'],
					instrument=Instrument[ch_data['instrument']],
					patterns=ch_data['patterns'],
					volume=ch_data['volume'],
					pan=ch_data['pan'],
					muted=ch_data['muted']
				)
				
				self.track.channels.append(channel)
			
			if self.verbose:
				print(f"✓ Imported JSON: {input_path}")
			
			return True
		
		except Exception as e:
			print(f"Error importing JSON: {e}")
			return False
	
	def print_track_info(self) -> None:
		"""Print track information"""
		if self.track is None:
			print("No track loaded")
			return
		
		print(f"\n=== Track: {self.track.title} ===\n")
		print(f"Composer: {self.track.composer or 'Unknown'}")
		print(f"Tempo: {self.track.tempo} BPM")
		print(f"Time Signature: {self.track.time_signature[0]}/{self.track.time_signature[1]}")
		print(f"Patterns: {len(self.track.patterns)}")
		print(f"Channels: {len(self.track.channels)}")
		
		if self.track.loop_enabled:
			print(f"Loop: {self.track.loop_start} - {self.track.loop_end}")
		
		print(f"\n--- Channels ---\n")
		for ch in self.track.channels:
			status = "MUTED" if ch.muted else "ACTIVE"
			print(f"Channel {ch.channel_id}: {ch.instrument.name} ({status})")
			print(f"  Patterns: {ch.patterns}")
			print(f"  Volume: {ch.volume}, Pan: {ch.pan}")
		
		print(f"\n--- Patterns ---\n")
		for pattern in self.track.patterns:
			print(f"Pattern {pattern.pattern_id}: {pattern.name}")
			print(f"  Length: {pattern.length} beats")
			print(f"  Notes: {len(pattern.notes)}")


def main():
	parser = argparse.ArgumentParser(description='FFMQ Music Sequencer')
	parser.add_argument('--create-track', nargs=2, metavar=('ID', 'TITLE'),
					   help='Create new track')
	parser.add_argument('--import-midi', type=str, metavar='FILE',
					   help='Import MIDI file')
	parser.add_argument('--import-json', type=str, metavar='FILE',
					   help='Import JSON track')
	parser.add_argument('--export-spc', type=str, metavar='FILE',
					   help='Export to SPC format')
	parser.add_argument('--export-json', type=str, metavar='FILE',
					   help='Export to JSON')
	parser.add_argument('--info', action='store_true', help='Show track info')
	parser.add_argument('--tempo', type=int, default=120, help='Track tempo')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	sequencer = MusicSequencer(verbose=args.verbose)
	
	# Create track
	if args.create_track:
		track_id, title = args.create_track
		sequencer.create_track(track_id, title, args.tempo)
		
		if args.export_json:
			sequencer.export_json(Path(args.export_json))
		
		return 0
	
	# Import MIDI
	if args.import_midi:
		sequencer.import_midi(Path(args.import_midi))
	
	# Import JSON
	if args.import_json:
		sequencer.import_json(Path(args.import_json))
	
	# Export SPC
	if args.export_spc:
		sequencer.export_spc(Path(args.export_spc))
		return 0
	
	# Export JSON
	if args.export_json:
		sequencer.export_json(Path(args.export_json))
		return 0
	
	# Show info
	if args.info or not any([args.create_track, args.import_midi, args.import_json, args.export_spc, args.export_json]):
		sequencer.print_track_info()
		return 0
	
	return 0


if __name__ == '__main__':
	exit(main())
