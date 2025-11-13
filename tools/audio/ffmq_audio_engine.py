#!/usr/bin/env python3
"""
FFMQ Audio Engine - Music and sound effects

Audio Features:
- SPC700 sound driver
- Music playback control
- Sound effect triggers
- Audio channel management
- Volume control
- Pitch/tempo control

SPC700 Architecture:
- 8 audio channels
- 64 KB audio RAM
- Sample-based playback
- DSP effects (echo, reverb)

Music Features:
- Track playback
- Loop points
- Tempo control
- Volume fade
- Channel muting

Sound Features:
- SFX playback
- Priority system
- Panning control
- Envelope (ADSR)

Features:
- Play music tracks
- Trigger sound effects
- Control volume/tempo
- Mute channels
- Export audio data
- SPC file generation

Usage:
	python ffmq_audio_engine.py --play-music 1
	python ffmq_audio_engine.py --play-sfx 10
	python ffmq_audio_engine.py --set-volume 80
	python ffmq_audio_engine.py --set-tempo 120
	python ffmq_audio_engine.py --mute-channel 3
	python ffmq_audio_engine.py --export-spc track01.spc
"""

import argparse
import struct
from pathlib import Path
from typing import List, Dict, Optional, Tuple
from dataclasses import dataclass, asdict, field
from enum import Enum


class ChannelType(Enum):
	"""Audio channel type"""
	MELODY = "melody"
	HARMONY = "harmony"
	BASS = "bass"
	PERCUSSION = "percussion"
	SFX = "sfx"


class PlaybackState(Enum):
	"""Playback state"""
	STOPPED = "stopped"
	PLAYING = "playing"
	PAUSED = "paused"
	FADING = "fading"


@dataclass
class AudioSample:
	"""Audio sample data"""
	sample_id: int
	name: str
	data: bytes
	loop_start: int = 0
	loop_end: Optional[int] = None
	pitch: int = 440  # Base frequency in Hz
	volume: int = 100  # 0-100


@dataclass
class SoundEffect:
	"""Sound effect definition"""
	sfx_id: int
	name: str
	sample_id: int
	pitch: int = 440
	volume: int = 100
	priority: int = 50  # 0-100 (higher = higher priority)
	pan: int = 64  # 0-127 (0=left, 64=center, 127=right)


@dataclass
class MusicTrack:
	"""Music track"""
	track_id: int
	name: str
	composer: str = ""
	tempo: int = 120  # BPM
	loop_start: int = 0
	loop_enabled: bool = True
	channels_used: int = 0xFF  # Bitmask of channels 0-7


@dataclass
class AudioChannel:
	"""Audio channel state"""
	channel_id: int
	channel_type: ChannelType
	sample_id: Optional[int] = None
	pitch: int = 440
	volume: int = 100
	pan: int = 64
	muted: bool = False
	playing: bool = False


class FFMQAudioEngine:
	"""Audio engine and music system"""
	
	# SPC700 constants
	NUM_CHANNELS = 8
	AUDIO_RAM_SIZE = 65536
	MAX_SAMPLES = 64
	
	# Known music tracks
	MUSIC_TRACKS = {
		1: "Hill of Destiny",
		2: "Foresta Village",
		3: "Battle Theme",
		4: "Boss Battle",
		5: "Aquaria",
		6: "Fireburg",
		7: "Dungeon",
		8: "Final Battle",
		9: "Ending Theme",
		10: "Game Over"
	}
	
	# Sound effects
	SOUND_EFFECTS = {
		1: "Menu Cursor",
		2: "Menu Select",
		3: "Menu Cancel",
		4: "Footstep",
		5: "Door Open",
		6: "Chest Open",
		7: "Item Get",
		8: "Battle Start",
		9: "Attack Hit",
		10: "Magic Cast",
		11: "Heal",
		12: "Level Up",
		13: "Enemy Defeat",
		14: "Victory Fanfare",
		15: "Damage Taken"
	}
	
	# Channel assignments
	DEFAULT_CHANNELS = {
		0: ChannelType.MELODY,
		1: ChannelType.HARMONY,
		2: ChannelType.HARMONY,
		3: ChannelType.BASS,
		4: ChannelType.PERCUSSION,
		5: ChannelType.PERCUSSION,
		6: ChannelType.SFX,
		7: ChannelType.SFX
	}
	
	def __init__(self, verbose: bool = False):
		self.verbose = verbose
		self.channels: List[AudioChannel] = []
		self.samples: Dict[int, AudioSample] = {}
		self.music_tracks: Dict[int, MusicTrack] = {}
		self.sound_effects: Dict[int, SoundEffect] = {}
		
		self.current_track: Optional[int] = None
		self.playback_state = PlaybackState.STOPPED
		self.master_volume: int = 100
		self.tempo_multiplier: float = 1.0
		
		self._initialize_channels()
		self._load_default_tracks()
		self._load_default_sfx()
	
	def _initialize_channels(self) -> None:
		"""Initialize audio channels"""
		for i in range(self.NUM_CHANNELS):
			channel = AudioChannel(
				channel_id=i,
				channel_type=self.DEFAULT_CHANNELS[i]
			)
			self.channels.append(channel)
	
	def _load_default_tracks(self) -> None:
		"""Load default music track metadata"""
		for track_id, name in self.MUSIC_TRACKS.items():
			track = MusicTrack(
				track_id=track_id,
				name=name,
				tempo=120,
				loop_enabled=True,
				channels_used=0x3F  # Channels 0-5
			)
			self.music_tracks[track_id] = track
	
	def _load_default_sfx(self) -> None:
		"""Load default sound effects"""
		for sfx_id, name in self.SOUND_EFFECTS.items():
			sfx = SoundEffect(
				sfx_id=sfx_id,
				name=name,
				sample_id=sfx_id + 100,  # Offset for SFX samples
				priority=50,
				volume=100
			)
			self.sound_effects[sfx_id] = sfx
	
	def play_music(self, track_id: int) -> bool:
		"""Play music track"""
		if track_id not in self.music_tracks:
			print(f"Error: Track {track_id} not found")
			return False
		
		track = self.music_tracks[track_id]
		
		# Stop current track
		if self.current_track is not None:
			self.stop_music()
		
		# Start new track
		self.current_track = track_id
		self.playback_state = PlaybackState.PLAYING
		
		# Enable channels used by track
		for i in range(self.NUM_CHANNELS):
			if track.channels_used & (1 << i):
				self.channels[i].playing = True
		
		if self.verbose:
			print(f"♪ Playing: {track.name}")
		
		return True
	
	def stop_music(self) -> None:
		"""Stop music playback"""
		if self.current_track is None:
			return
		
		# Stop all music channels
		for channel in self.channels:
			if channel.channel_type != ChannelType.SFX:
				channel.playing = False
		
		self.current_track = None
		self.playback_state = PlaybackState.STOPPED
		
		if self.verbose:
			print("■ Music stopped")
	
	def pause_music(self) -> None:
		"""Pause music playback"""
		if self.playback_state == PlaybackState.PLAYING:
			self.playback_state = PlaybackState.PAUSED
			
			if self.verbose:
				print("⏸ Music paused")
	
	def resume_music(self) -> None:
		"""Resume music playback"""
		if self.playback_state == PlaybackState.PAUSED:
			self.playback_state = PlaybackState.PLAYING
			
			if self.verbose:
				print("▶ Music resumed")
	
	def play_sfx(self, sfx_id: int, channel_override: Optional[int] = None) -> bool:
		"""Play sound effect"""
		if sfx_id not in self.sound_effects:
			print(f"Error: SFX {sfx_id} not found")
			return False
		
		sfx = self.sound_effects[sfx_id]
		
		# Find available SFX channel
		if channel_override is not None:
			channel = self.channels[channel_override]
		else:
			channel = self._find_sfx_channel(sfx.priority)
		
		if not channel:
			if self.verbose:
				print(f"No available channel for SFX {sfx_id}")
			return False
		
		# Play on channel
		channel.sample_id = sfx.sample_id
		channel.pitch = sfx.pitch
		channel.volume = sfx.volume
		channel.pan = sfx.pan
		channel.playing = True
		
		if self.verbose:
			print(f"🔊 Playing SFX: {sfx.name} on channel {channel.channel_id}")
		
		return True
	
	def _find_sfx_channel(self, priority: int) -> Optional[AudioChannel]:
		"""Find available SFX channel"""
		# Try to find free SFX channel
		for channel in self.channels:
			if channel.channel_type == ChannelType.SFX and not channel.playing:
				return channel
		
		# If priority is high enough, take any SFX channel
		if priority > 75:
			for channel in self.channels:
				if channel.channel_type == ChannelType.SFX:
					return channel
		
		return None
	
	def set_master_volume(self, volume: int) -> None:
		"""Set master volume (0-100)"""
		self.master_volume = max(0, min(100, volume))
		
		if self.verbose:
			print(f"🔊 Master volume: {self.master_volume}%")
	
	def set_channel_volume(self, channel_id: int, volume: int) -> bool:
		"""Set channel volume"""
		if not (0 <= channel_id < self.NUM_CHANNELS):
			return False
		
		self.channels[channel_id].volume = max(0, min(100, volume))
		
		if self.verbose:
			print(f"🔊 Channel {channel_id} volume: {volume}%")
		
		return True
	
	def mute_channel(self, channel_id: int, mute: bool = True) -> bool:
		"""Mute/unmute channel"""
		if not (0 <= channel_id < self.NUM_CHANNELS):
			return False
		
		self.channels[channel_id].muted = mute
		
		if self.verbose:
			status = "muted" if mute else "unmuted"
			print(f"🔇 Channel {channel_id} {status}")
		
		return True
	
	def set_tempo(self, tempo: int) -> None:
		"""Set playback tempo (BPM)"""
		if self.current_track is not None:
			track = self.music_tracks[self.current_track]
			self.tempo_multiplier = tempo / track.tempo
			
			if self.verbose:
				print(f"♪ Tempo: {tempo} BPM ({self.tempo_multiplier:.2f}×)")
	
	def fade_out(self, duration_frames: int = 60) -> None:
		"""Fade out music"""
		self.playback_state = PlaybackState.FADING
		
		if self.verbose:
			print(f"🔊 Fading out over {duration_frames} frames")
	
	def export_spc(self, output_path: Path) -> bool:
		"""Export to SPC file format"""
		try:
			with open(output_path, 'wb') as f:
				# SPC file header
				f.write(b'SNES-SPC700 Sound File Data v0.30')
				f.write(b'\x1A\x1A')  # EOF markers
				
				# Header data (simplified)
				f.write(struct.pack('B', 26))  # Version minor
				f.write(struct.pack('B', 26))  # SPC700 version
				
				# PC register
				f.write(struct.pack('<H', 0x0000))
				
				# Registers (A, X, Y, PSW, SP)
				f.write(struct.pack('B', 0))  # A
				f.write(struct.pack('B', 0))  # X
				f.write(struct.pack('B', 0))  # Y
				f.write(struct.pack('B', 0))  # PSW
				f.write(struct.pack('B', 0xFF))  # SP
				
				# Reserved
				f.write(b'\x00' * 2)
				
				# ID666 tag (song info)
				song_name = "FFMQ Track"
				if self.current_track and self.current_track in self.music_tracks:
					track = self.music_tracks[self.current_track]
					song_name = track.name
				
				# Song name (32 bytes)
				f.write(song_name.encode('ascii')[:32].ljust(32, b'\x00'))
				
				# Game name (32 bytes)
				f.write(b'Final Fantasy Mystic Quest'.ljust(32, b'\x00'))
				
				# Dumper name (16 bytes)
				f.write(b'FFMQ Tools'.ljust(16, b'\x00'))
				
				# Comments (32 bytes)
				f.write(b'\x00' * 32)
				
				# Date (11 bytes)
				f.write(b'2024/01/01\x00')
				
				# Length in seconds (3 bytes as ASCII)
				f.write(b'180')
				
				# Fade length in ms (5 bytes as ASCII)
				f.write(b'10000')
				
				# Artist (32 bytes)
				f.write(b'Ryuji Sasai'.ljust(32, b'\x00'))
				
				# Default channel disables (1 byte)
				f.write(b'\x00')
				
				# Emulator used (1 byte)
				f.write(b'\x01')  # Unknown
				
				# Reserved
				f.write(b'\x00' * 45)
				
				# 64KB RAM dump (simplified - zeros for now)
				f.write(b'\x00' * 65536)
				
				# DSP registers (128 bytes)
				f.write(b'\x00' * 128)
				
				# Extra RAM (64 bytes)
				f.write(b'\x00' * 64)
			
			if self.verbose:
				print(f"✓ Exported SPC to {output_path}")
			
			return True
		
		except Exception as e:
			print(f"Error exporting SPC: {e}")
			return False
	
	def print_status(self) -> None:
		"""Print audio engine status"""
		print(f"\n=== Audio Engine Status ===\n")
		
		# Playback state
		print(f"State: {self.playback_state.value}")
		
		if self.current_track is not None:
			track = self.music_tracks[self.current_track]
			print(f"Track: {track.name}")
			print(f"Tempo: {track.tempo} BPM × {self.tempo_multiplier:.2f}")
		
		print(f"Master Volume: {self.master_volume}%")
		
		# Channels
		print(f"\nChannels:")
		print(f"{'ID':<4} {'Type':<12} {'Volume':<8} {'Pan':<6} {'Muted':<7} {'Playing':<8}")
		print('-' * 55)
		
		for channel in self.channels:
			muted = "Yes" if channel.muted else "No"
			playing = "Yes" if channel.playing else "No"
			print(f"{channel.channel_id:<4} {channel.channel_type.value:<12} "
				  f"{channel.volume:<8} {channel.pan:<6} {muted:<7} {playing:<8}")
	
	def print_track_list(self) -> None:
		"""Print available music tracks"""
		print(f"\n=== Music Tracks ===\n")
		print(f"{'ID':<4} {'Name':<30} {'Tempo':<8} {'Loop':<6}")
		print('-' * 48)
		
		for track_id, track in sorted(self.music_tracks.items()):
			loop = "Yes" if track.loop_enabled else "No"
			print(f"{track.track_id:<4} {track.name:<30} {track.tempo:<8} {loop:<6}")
	
	def print_sfx_list(self) -> None:
		"""Print available sound effects"""
		print(f"\n=== Sound Effects ===\n")
		print(f"{'ID':<4} {'Name':<25} {'Priority':<10} {'Volume':<8}")
		print('-' * 47)
		
		for sfx_id, sfx in sorted(self.sound_effects.items()):
			print(f"{sfx.sfx_id:<4} {sfx.name:<25} {sfx.priority:<10} {sfx.volume:<8}")


def main():
	parser = argparse.ArgumentParser(description='FFMQ Audio Engine')
	parser.add_argument('--play-music', type=int, metavar='TRACK_ID',
					   help='Play music track')
	parser.add_argument('--stop-music', action='store_true', help='Stop music')
	parser.add_argument('--pause', action='store_true', help='Pause music')
	parser.add_argument('--resume', action='store_true', help='Resume music')
	parser.add_argument('--play-sfx', type=int, metavar='SFX_ID',
					   help='Play sound effect')
	parser.add_argument('--set-volume', type=int, metavar='VOLUME',
					   help='Set master volume (0-100)')
	parser.add_argument('--set-tempo', type=int, metavar='BPM',
					   help='Set playback tempo')
	parser.add_argument('--mute-channel', type=int, metavar='CHANNEL',
					   help='Mute channel')
	parser.add_argument('--unmute-channel', type=int, metavar='CHANNEL',
					   help='Unmute channel')
	parser.add_argument('--fade-out', action='store_true', help='Fade out music')
	parser.add_argument('--export-spc', type=str, metavar='OUTPUT',
					   help='Export to SPC file')
	parser.add_argument('--list-tracks', action='store_true', help='List music tracks')
	parser.add_argument('--list-sfx', action='store_true', help='List sound effects')
	parser.add_argument('--status', action='store_true', help='Show audio status')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	engine = FFMQAudioEngine(verbose=args.verbose)
	
	# Play music
	if args.play_music:
		engine.play_music(args.play_music)
	
	# Stop music
	if args.stop_music:
		engine.stop_music()
	
	# Pause
	if args.pause:
		engine.pause_music()
	
	# Resume
	if args.resume:
		engine.resume_music()
	
	# Play SFX
	if args.play_sfx:
		engine.play_sfx(args.play_sfx)
	
	# Set volume
	if args.set_volume is not None:
		engine.set_master_volume(args.set_volume)
	
	# Set tempo
	if args.set_tempo:
		engine.set_tempo(args.set_tempo)
	
	# Mute channel
	if args.mute_channel is not None:
		engine.mute_channel(args.mute_channel, True)
	
	# Unmute channel
	if args.unmute_channel is not None:
		engine.mute_channel(args.unmute_channel, False)
	
	# Fade out
	if args.fade_out:
		engine.fade_out()
	
	# Export SPC
	if args.export_spc:
		engine.export_spc(Path(args.export_spc))
		return 0
	
	# List tracks
	if args.list_tracks:
		engine.print_track_list()
		return 0
	
	# List SFX
	if args.list_sfx:
		engine.print_sfx_list()
		return 0
	
	# Status
	if args.status or not any([
		args.play_music, args.stop_music, args.pause, args.resume,
		args.play_sfx, args.set_volume, args.set_tempo,
		args.mute_channel, args.unmute_channel, args.fade_out
	]):
		engine.print_status()
	
	return 0


if __name__ == '__main__':
	exit(main())
