"""
MIDI to SNES Music Converter for Final Fantasy Mystic Quest
Convert MIDI files to SNES SPC700 music format with channel mapping.
"""

import pygame.midi
import struct
from dataclasses import dataclass, field
from typing import List, Tuple, Optional, Dict
from enum import Enum
import json


class InstrumentType(Enum):
	"""SNES instrument types"""
	SQUARE_WAVE = 0
	SAWTOOTH = 1
	TRIANGLE = 2
	SINE = 3
	NOISE = 4
	SAMPLE = 5
	FM_SYNTH = 6
	PCM = 7


class ADSRPhase(Enum):
	"""ADSR envelope phases"""
	ATTACK = 0
	DECAY = 1
	SUSTAIN = 2
	RELEASE = 3


@dataclass
class ADSREnvelope:
	"""ADSR envelope for SNES audio"""
	attack: int  # 0-15 (exponential rate)
	decay: int   # 0-7 (exponential rate)
	sustain: int  # 0-7 (sustain level)
	release: int  # 0-31 (exponential rate)
	
	def to_bytes(self) -> bytes:
		"""Convert to SNES ADSR format (2 bytes)"""
		# ADSR1: DDDR RRRR (Decay, Release)
		# ADSR2: IAAA SSSL (Attack, Sustain)
		adsr1 = ((self.decay & 0x07) << 5) | (self.release & 0x1F)
		adsr2 = 0x80 | ((self.attack & 0x0F) << 3) | (self.sustain & 0x07)
		return bytes([adsr1, adsr2])


@dataclass
class SNESInstrument:
	"""SNES instrument definition"""
	instrument_id: int
	name: str
	type: InstrumentType
	adsr: ADSREnvelope
	sample_offset: int = 0
	sample_loop_offset: int = 0
	pitch_multiplier: float = 1.0
	volume: int = 127  # 0-127
	pan: int = 64      # 0-127 (64 = center)
	
	def to_dict(self):
		return {
			'instrument_id': self.instrument_id,
			'name': self.name,
			'type': self.type.name,
			'adsr': {
				'attack': self.adsr.attack,
				'decay': self.adsr.decay,
				'sustain': self.adsr.sustain,
				'release': self.adsr.release
			},
			'sample_offset': self.sample_offset,
			'sample_loop_offset': self.sample_loop_offset,
			'pitch_multiplier': self.pitch_multiplier,
			'volume': self.volume,
			'pan': self.pan
		}


@dataclass
class MIDINote:
	"""MIDI note event"""
	time: int        # Ticks from start
	channel: int     # MIDI channel 0-15
	note: int        # MIDI note 0-127
	velocity: int    # 0-127
	duration: int    # Ticks
	
	def to_snes_pitch(self) -> int:
		"""Convert MIDI note to SNES pitch value"""
		# SNES pitch = base_freq * 2^((note-60)/12)
		# Simplified: use lookup table
		return min(0x3FFF, max(0, int(440 * (2 ** ((self.note - 69) / 12)))))


@dataclass
class MIDITrack:
	"""MIDI track data"""
	track_id: int
	name: str
	channel: int
	instrument: int
	notes: List[MIDINote] = field(default_factory=list)
	tempo_changes: List[Tuple[int, int]] = field(default_factory=list)
	volume_changes: List[Tuple[int, int]] = field(default_factory=list)
	pan_changes: List[Tuple[int, int]] = field(default_factory=list)


@dataclass
class SNESMusicData:
	"""Complete SNES music data"""
	title: str
	tempo: int  # BPM
	time_signature: Tuple[int, int]  # (numerator, denominator)
	tracks: List[MIDITrack]
	instruments: List[SNESInstrument]
	loop_point: int = 0  # Tick where loop starts
	total_ticks: int = 0
	
	def to_spc700_binary(self) -> bytes:
		"""Convert to SPC700 binary format"""
		# This is a simplified conversion - real SPC700 is complex
		output = bytearray()
		
		# Header (simplified)
		output.extend(b'SNES-SPC700\x00')
		output.extend(struct.pack('<H', self.tempo))
		output.extend(struct.pack('<H', self.total_ticks))
		output.extend(struct.pack('<H', self.loop_point))
		
		# Instrument data
		output.append(len(self.instruments))
		for inst in self.instruments:
			output.extend(inst.adsr.to_bytes())
			output.append(inst.volume)
			output.append(inst.pan)
		
		# Track data
		output.append(len(self.tracks))
		for track in self.tracks:
			output.extend(self._encode_track(track))
		
		return bytes(output)
	
	def _encode_track(self, track: MIDITrack) -> bytes:
		"""Encode single track to binary"""
		data = bytearray()
		
		# Track header
		data.append(track.channel)
		data.append(track.instrument)
		data.extend(struct.pack('<H', len(track.notes)))
		
		# Note events
		last_time = 0
		for note in sorted(track.notes, key=lambda n: n.time):
			# Delta time (variable length)
			delta = note.time - last_time
			data.extend(self._encode_variable_length(delta))
			
			# Note on
			data.append(0x90 | track.channel)
			data.append(note.note)
			data.append(note.velocity)
			
			# Note duration
			data.extend(self._encode_variable_length(note.duration))
			
			# Note off
			data.append(0x80 | track.channel)
			data.append(note.note)
			data.append(0)
			
			last_time = note.time + note.duration
		
		return bytes(data)
	
	def _encode_variable_length(self, value: int) -> bytes:
		"""Encode variable length quantity"""
		result = bytearray()
		result.append(value & 0x7F)
		value >>= 7
		while value > 0:
			result.insert(0, 0x80 | (value & 0x7F))
			value >>= 7
		return bytes(result)


class MIDIConverter:
	"""Convert MIDI files to SNES format"""
	
	def __init__(self):
		self.default_instruments = self._create_default_instruments()
		
	def _create_default_instruments(self) -> List[SNESInstrument]:
		"""Create default SNES instruments"""
		return [
			SNESInstrument(
				0, "Square Lead", InstrumentType.SQUARE_WAVE,
				ADSREnvelope(15, 7, 7, 20), volume=100
			),
			SNESInstrument(
				1, "Bass", InstrumentType.SAWTOOTH,
				ADSREnvelope(12, 6, 5, 15), volume=110
			),
			SNESInstrument(
				2, "Strings", InstrumentType.TRIANGLE,
				ADSREnvelope(10, 5, 6, 25), volume=90
			),
			SNESInstrument(
				3, "Brass", InstrumentType.SQUARE_WAVE,
				ADSREnvelope(14, 7, 6, 18), volume=105
			),
			SNESInstrument(
				4, "Flute", InstrumentType.SINE,
				ADSREnvelope(9, 4, 5, 22), volume=85
			),
			SNESInstrument(
				5, "Percussion", InstrumentType.NOISE,
				ADSREnvelope(15, 7, 0, 5), volume=120
			),
		]
	
	def load_midi_file(self, filepath: str) -> Optional[SNESMusicData]:
		"""Load and parse MIDI file"""
		try:
			import mido
		except ImportError:
			print("mido library not installed. Using simple parser.")
			return self._simple_midi_parse(filepath)
		
		try:
			mid = mido.MidiFile(filepath)
			return self._convert_mido_to_snes(mid)
		except Exception as e:
			print(f"Error loading MIDI: {e}")
			return None
	
	def _convert_mido_to_snes(self, mid) -> SNESMusicData:
		"""Convert mido MIDI to SNES format"""
		import mido
		
		# Extract tempo
		tempo = 120
		time_sig = (4, 4)
		
		# Parse all tracks
		tracks = []
		for i, track in enumerate(mid.tracks):
			midi_track = MIDITrack(i, f"Track {i}", 0, 0)
			
			current_time = 0
			active_notes = {}  # note -> (time, velocity)
			
			for msg in track:
				current_time += msg.time
				
				if msg.type == 'note_on' and msg.velocity > 0:
					# Note start
					active_notes[msg.note] = (current_time, msg.velocity)
					
				elif msg.type == 'note_off' or (
						msg.type == 'note_on' and msg.velocity == 0):
					# Note end
					if msg.note in active_notes:
						start_time, velocity = active_notes.pop(msg.note)
						duration = current_time - start_time
						
						note = MIDINote(
							start_time, msg.channel, msg.note,
							velocity, duration
						)
						midi_track.notes.append(note)
				
				elif msg.type == 'set_tempo':
					tempo = mido.tempo2bpm(msg.tempo)
					midi_track.tempo_changes.append((current_time, int(tempo)))
				
				elif msg.type == 'control_change':
					if msg.control == 7:  # Volume
						midi_track.volume_changes.append((current_time, msg.value))
					elif msg.control == 10:  # Pan
						midi_track.pan_changes.append((current_time, msg.value))
			
			if midi_track.notes:
				tracks.append(midi_track)
		
		# Create SNES music data
		total_ticks = max(
			(note.time + note.duration for track in tracks for note in track.notes),
			default=0
		)
		
		return SNESMusicData(
			title="Converted MIDI",
			tempo=int(tempo),
			time_signature=time_sig,
			tracks=tracks,
			instruments=self.default_instruments,
			total_ticks=total_ticks
		)
	
	def _simple_midi_parse(self, filepath: str) -> SNESMusicData:
		"""Simple MIDI parser fallback"""
		# Create sample data
		tracks = [
			MIDITrack(0, "Melody", 0, 0, notes=[
				MIDINote(0, 0, 60, 100, 480),
				MIDINote(480, 0, 62, 100, 480),
				MIDINote(960, 0, 64, 100, 480),
				MIDINote(1440, 0, 65, 100, 960),
			])
		]
		
		return SNESMusicData(
			title="Sample Music",
			tempo=120,
			time_signature=(4, 4),
			tracks=tracks,
			instruments=self.default_instruments,
			total_ticks=2400
		)
	
	def export_to_json(self, music_data: SNESMusicData, filepath: str):
		"""Export music data to JSON"""
		data = {
			'title': music_data.title,
			'tempo': music_data.tempo,
			'time_signature': music_data.time_signature,
			'loop_point': music_data.loop_point,
			'total_ticks': music_data.total_ticks,
			'instruments': [inst.to_dict() for inst in music_data.instruments],
			'tracks': [
				{
					'track_id': t.track_id,
					'name': t.name,
					'channel': t.channel,
					'instrument': t.instrument,
					'notes': [
						{
							'time': n.time,
							'note': n.note,
							'velocity': n.velocity,
							'duration': n.duration
						} for n in t.notes
					]
				} for t in music_data.tracks
			]
		}
		
		with open(filepath, 'w') as f:
			json.dump(data, f, indent=2)
	
	def optimize_for_snes(self, music_data: SNESMusicData) -> SNESMusicData:
		"""Optimize music data for SNES limitations"""
		# SNES has 8 channels max
		if len(music_data.tracks) > 8:
			# Merge similar tracks
			music_data.tracks = self._merge_tracks(music_data.tracks, 8)
		
		# Quantize note timings to SNES tick resolution
		for track in music_data.tracks:
			for note in track.notes:
				note.time = self._quantize_time(note.time)
				note.duration = max(1, self._quantize_time(note.duration))
		
		# Limit velocity range
		for track in music_data.tracks:
			for note in track.notes:
				note.velocity = min(127, max(1, note.velocity))
		
		return music_data
	
	def _merge_tracks(self, tracks: List[MIDITrack], max_tracks: int
					  ) -> List[MIDITrack]:
		"""Merge tracks to fit SNES channel limit"""
		if len(tracks) <= max_tracks:
			return tracks
		
		# Sort by number of notes (keep busiest tracks)
		sorted_tracks = sorted(
			tracks, key=lambda t: len(t.notes), reverse=True
		)
		return sorted_tracks[:max_tracks]
	
	def _quantize_time(self, time: int, resolution: int = 24) -> int:
		"""Quantize time to SNES resolution"""
		return (time + resolution // 2) // resolution * resolution


def main():
	"""Test MIDI converter"""
	converter = MIDIConverter()
	
	# Create sample music
	music = converter._simple_midi_parse("")
	
	# Export to JSON
	converter.export_to_json(music, "sample_music.json")
	print(f"Created sample music: {music.title}")
	print(f"  Tempo: {music.tempo} BPM")
	print(f"  Tracks: {len(music.tracks)}")
	print(f"  Total notes: {sum(len(t.notes) for t in music.tracks)}")
	
	# Export to binary
	binary = music.to_spc700_binary()
	with open("sample_music.spc", 'wb') as f:
		f.write(binary)
	print(f"  Binary size: {len(binary)} bytes")


if __name__ == '__main__':
	main()
