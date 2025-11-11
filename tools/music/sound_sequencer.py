"""
Advanced Sound Sequencer and Waveform Editor for SNES
Create and edit custom sound effects and music with visual waveform display.
"""

import pygame
import numpy as np
import wave
import struct
from dataclasses import dataclass, field
from typing import List, Tuple, Optional, Callable
from enum import Enum
import math
import json


class WaveformType(Enum):
	"""Basic waveform types"""
	SINE = "sine"
	SQUARE = "square"
	SAWTOOTH = "sawtooth"
	TRIANGLE = "triangle"
	NOISE = "noise"
	PULSE = "pulse"
	CUSTOM = "custom"


class EnvelopeShape(Enum):
	"""Envelope curve shapes"""
	LINEAR = "linear"
	EXPONENTIAL = "exponential"
	LOGARITHMIC = "logarithmic"
	SCURVE = "scurve"


@dataclass
class Envelope:
	"""ADSR envelope with customizable shapes"""
	attack_time: float  # Seconds
	decay_time: float
	sustain_level: float  # 0-1
	release_time: float
	attack_shape: EnvelopeShape = EnvelopeShape.LINEAR
	decay_shape: EnvelopeShape = EnvelopeShape.EXPONENTIAL
	release_shape: EnvelopeShape = EnvelopeShape.EXPONENTIAL

	def get_amplitude(self, t: float, note_duration: float, released_at: Optional[float]
					  ) -> float:
		"""Get envelope amplitude at time t"""
		if released_at is not None:
			# Release phase
			release_elapsed = t - released_at
			if release_elapsed >= self.release_time:
				return 0.0

			# Get amplitude at release point
			release_amp = self.get_amplitude(released_at, note_duration, None)
			progress = release_elapsed / self.release_time
			return release_amp * (1 - self._apply_shape(progress, self.release_shape))

		if t < self.attack_time:
			# Attack phase
			progress = t / self.attack_time if self.attack_time > 0 else 1.0
			return self._apply_shape(progress, self.attack_shape)

		elif t < self.attack_time + self.decay_time:
			# Decay phase
			progress = (t - self.attack_time) / self.decay_time if self.decay_time > 0 else 1.0
			return 1.0 - (1.0 - self.sustain_level) * self._apply_shape(
				progress, self.decay_shape)

		else:
			# Sustain phase
			return self.sustain_level

	def _apply_shape(self, progress: float, shape: EnvelopeShape) -> float:
		"""Apply envelope shape curve"""
		progress = max(0.0, min(1.0, progress))

		if shape == EnvelopeShape.LINEAR:
			return progress
		elif shape == EnvelopeShape.EXPONENTIAL:
			return progress ** 2
		elif shape == EnvelopeShape.LOGARITHMIC:
			return math.sqrt(progress)
		elif shape == EnvelopeShape.SCURVE:
			# Smoothstep
			return progress * progress * (3 - 2 * progress)
		return progress

	def to_dict(self):
		return {
			'attack_time': self.attack_time,
			'decay_time': self.decay_time,
			'sustain_level': self.sustain_level,
			'release_time': self.release_time,
			'attack_shape': self.attack_shape.value,
			'decay_shape': self.decay_shape.value,
			'release_shape': self.release_shape.value
		}


@dataclass
class Filter:
	"""Digital filter for sound processing"""
	filter_type: str  # "lowpass", "highpass", "bandpass"
	cutoff_freq: float  # Hz
	resonance: float  # 0-1
	enabled: bool = True

	def apply(self, samples: np.ndarray, sample_rate: int) -> np.ndarray:
		"""Apply filter to samples"""
		if not self.enabled or len(samples) == 0:
			return samples

		# Simple one-pole filter
		alpha = min(0.99, 2 * math.pi * self.cutoff_freq / sample_rate)

		if self.filter_type == "lowpass":
			filtered = np.zeros_like(samples)
			filtered[0] = samples[0]
			for i in range(1, len(samples)):
				filtered[i] = alpha * samples[i] + (1 - alpha) * filtered[i - 1]
			return filtered

		elif self.filter_type == "highpass":
			filtered = np.zeros_like(samples)
			filtered[0] = samples[0]
			for i in range(1, len(samples)):
				filtered[i] = alpha * (filtered[i - 1] + samples[i] - samples[i - 1])
			return filtered

		return samples

	def to_dict(self):
		return {
			'filter_type': self.filter_type,
			'cutoff_freq': self.cutoff_freq,
			'resonance': self.resonance,
			'enabled': self.enabled
		}


@dataclass
class Effect:
	"""Sound effect (reverb, delay, chorus, etc.)"""
	effect_type: str
	params: dict = field(default_factory=dict)
	mix: float = 0.5  # Dry/wet mix 0-1
	enabled: bool = True

	def apply(self, samples: np.ndarray, sample_rate: int) -> np.ndarray:
		"""Apply effect to samples"""
		if not self.enabled:
			return samples

		if self.effect_type == "delay":
			delay_time = self.params.get('delay_time', 0.3)  # Seconds
			feedback = self.params.get('feedback', 0.5)

			delay_samples = int(delay_time * sample_rate)
			delayed = np.zeros(len(samples) + delay_samples)
			delayed[:len(samples)] = samples

			for i in range(len(samples), len(delayed)):
				if i >= delay_samples:
					delayed[i] += delayed[i - delay_samples] * feedback

			# Mix dry/wet
			result = samples * (1 - self.mix)
			result = result + delayed[:len(samples)] * self.mix
			return result

		elif self.effect_type == "reverb":
			# Simple comb filter reverb
			delays = [0.029, 0.037, 0.041, 0.043]  # Seconds
			decays = [0.7, 0.7, 0.7, 0.7]

			output = samples.copy()

			for delay_time, decay in zip(delays, decays):
				delay_samples = int(delay_time * sample_rate)
				if delay_samples < len(samples):
					delayed = np.zeros_like(samples)
					delayed[delay_samples:] = samples[:-delay_samples] * decay
					output += delayed * self.mix

			return output / (1 + len(delays) * self.mix)

		return samples

	def to_dict(self):
		return {
			'effect_type': self.effect_type,
			'params': self.params,
			'mix': self.mix,
			'enabled': self.enabled
		}


@dataclass
class SoundLayer:
	"""Single sound layer with waveform"""
	waveform_type: WaveformType
	frequency: float  # Hz
	amplitude: float  # 0-1
	phase: float = 0.0  # 0-1
	pulse_width: float = 0.5  # For pulse wave
	detune: float = 0.0  # Cents

	# Custom waveform samples (if WaveformType.CUSTOM)
	custom_samples: Optional[np.ndarray] = None

	def generate_samples(self, duration: float, sample_rate: int) -> np.ndarray:
		"""Generate waveform samples"""
		num_samples = int(duration * sample_rate)
		t = np.linspace(0, duration, num_samples, endpoint=False)

		# Apply detune
		freq = self.frequency * (2 ** (self.detune / 1200))

		if self.waveform_type == WaveformType.SINE:
			samples = np.sin(2 * np.pi * freq * t + self.phase * 2 * np.pi)

		elif self.waveform_type == WaveformType.SQUARE:
			samples = np.sign(np.sin(2 * np.pi * freq * t + self.phase * 2 * np.pi))

		elif self.waveform_type == WaveformType.SAWTOOTH:
			samples = 2 * (freq * t + self.phase - np.floor(freq * t + self.phase + 0.5))

		elif self.waveform_type == WaveformType.TRIANGLE:
			sawtooth = 2 * (freq * t + self.phase - np.floor(freq * t + self.phase + 0.5))
			samples = 2 * np.abs(sawtooth) - 1

		elif self.waveform_type == WaveformType.PULSE:
			phase_val = (freq * t + self.phase) % 1.0
			samples = np.where(phase_val < self.pulse_width, 1.0, -1.0)

		elif self.waveform_type == WaveformType.NOISE:
			samples = np.random.uniform(-1, 1, num_samples)

		elif self.waveform_type == WaveformType.CUSTOM and self.custom_samples is not None:
			# Resample custom waveform
			indices = np.linspace(0, len(self.custom_samples) - 1, num_samples)
			samples = np.interp(indices, np.arange(len(self.custom_samples)),
								self.custom_samples)

		else:
			samples = np.zeros(num_samples)

		return samples * self.amplitude

	def to_dict(self):
		return {
			'waveform_type': self.waveform_type.value,
			'frequency': self.frequency,
			'amplitude': self.amplitude,
			'phase': self.phase,
			'pulse_width': self.pulse_width,
			'detune': self.detune
		}


@dataclass
class Sound:
	"""Complete sound definition"""
	sound_id: int
	name: str
	layers: List[SoundLayer] = field(default_factory=list)
	envelope: Optional[Envelope] = None
	filter: Optional[Filter] = None
	effects: List[Effect] = field(default_factory=list)
	duration: float = 1.0  # Seconds
	sample_rate: int = 44100

	def generate(self) -> np.ndarray:
		"""Generate complete sound"""
		# Mix all layers
		mixed = np.zeros(int(self.duration * self.sample_rate))

		for layer in self.layers:
			layer_samples = layer.generate_samples(self.duration, self.sample_rate)
			mixed += layer_samples

		# Normalize
		if np.max(np.abs(mixed)) > 0:
			mixed = mixed / np.max(np.abs(mixed))

		# Apply envelope
		if self.envelope:
			t = np.linspace(0, self.duration, len(mixed))
			envelope_curve = np.array([
				self.envelope.get_amplitude(time, self.duration, None)
				for time in t
			])
			mixed = mixed * envelope_curve

		# Apply filter
		if self.filter:
			mixed = self.filter.apply(mixed, self.sample_rate)

		# Apply effects
		for effect in self.effects:
			mixed = effect.apply(mixed, self.sample_rate)

		# Normalize again
		if np.max(np.abs(mixed)) > 0:
			mixed = mixed / np.max(np.abs(mixed)) * 0.9  # Prevent clipping

		return mixed

	def export_wav(self, filepath: str):
		"""Export to WAV file"""
		samples = self.generate()

		# Convert to 16-bit PCM
		samples_int = np.int16(samples * 32767)

		with wave.open(filepath, 'w') as wav_file:
			wav_file.setnchannels(1)  # Mono
			wav_file.setsampwidth(2)  # 16-bit
			wav_file.setframerate(self.sample_rate)
			wav_file.writeframes(samples_int.tobytes())

	def to_dict(self):
		return {
			'sound_id': self.sound_id,
			'name': self.name,
			'layers': [layer.to_dict() for layer in self.layers],
			'envelope': self.envelope.to_dict() if self.envelope else None,
			'filter': self.filter.to_dict() if self.filter else None,
			'effects': [effect.to_dict() for effect in self.effects],
			'duration': self.duration,
			'sample_rate': self.sample_rate
		}


class WaveformVisualizer:
	"""Visual waveform display"""

	def __init__(self, width: int = 800, height: int = 200):
		self.width = width
		self.height = height
		self.surface = pygame.Surface((width, height))

	def draw_waveform(self, samples: np.ndarray, color: Tuple[int, int, int] = (100, 200, 255)):
		"""Draw waveform"""
		self.surface.fill((20, 20, 20))

		if len(samples) == 0:
			return

		# Draw center line
		mid_y = self.height // 2
		pygame.draw.line(self.surface, (80, 80, 80), (0, mid_y), (self.width, mid_y))

		# Downsample for display
		step = max(1, len(samples) // self.width)
		display_samples = samples[::step]

		if len(display_samples) < 2:
			return

		# Draw waveform
		points = []
		for i, sample in enumerate(display_samples):
			x = int(i * self.width / len(display_samples))
			y = int(mid_y - sample * (self.height // 2 - 10))
			y = max(0, min(self.height - 1, y))
			points.append((x, y))

		if len(points) > 1:
			pygame.draw.lines(self.surface, color, False, points, 2)

		# Draw grid
		for i in range(0, self.height, 40):
			pygame.draw.line(self.surface, (40, 40, 40), (0, i), (self.width, i))


class SoundSequencerUI:
	"""Interactive sound sequencer"""

	def __init__(self):
		pygame.init()
		pygame.mixer.init(frequency=44100, size=-16, channels=1)

		self.screen = pygame.display.set_mode((1400, 900))
		pygame.display.set_caption("SNES Sound Sequencer")
		self.clock = pygame.time.Clock()

		self.font = pygame.font.Font(None, 24)
		self.small_font = pygame.font.Font(None, 18)

		# Create default sound
		self.sound = self._create_default_sound()
		self.waveform_viz = WaveformVisualizer(1000, 200)

		# UI state
		self.selected_layer = 0 if self.sound.layers else None
		self.playing = False
		self.generated_samples = None

		self.update_waveform()

	def _create_default_sound(self) -> Sound:
		"""Create default sound"""
		sound = Sound(
			sound_id=0,
			name="Test Sound",
			duration=1.0
		)

		# Add a simple layer
		sound.layers.append(SoundLayer(
			waveform_type=WaveformType.SINE,
			frequency=440.0,
			amplitude=0.7
		))

		# Add envelope
		sound.envelope = Envelope(
			attack_time=0.05,
			decay_time=0.1,
			sustain_level=0.6,
			release_time=0.3
		)

		# Add filter
		sound.filter = Filter(
			filter_type="lowpass",
			cutoff_freq=2000.0,
			resonance=0.5,
			enabled=False
		)

		return sound

	def update_waveform(self):
		"""Regenerate and display waveform"""
		self.generated_samples = self.sound.generate()
		self.waveform_viz.draw_waveform(self.generated_samples)

	def play_sound(self):
		"""Play current sound"""
		if self.generated_samples is None:
			return

		# Convert to pygame sound
		samples_int = np.int16(self.generated_samples * 32767)
		sound_obj = pygame.sndarray.make_sound(samples_int)
		sound_obj.play()

	def draw_layer_panel(self):
		"""Draw layer editor"""
		panel_rect = pygame.Rect(20, 50, 350, 400)
		pygame.draw.rect(self.screen, (40, 40, 40), panel_rect)
		pygame.draw.rect(self.screen, (200, 200, 200), panel_rect, 2)

		# Title
		text = self.font.render("Layers", True, (255, 255, 255))
		self.screen.blit(text, (30, 55))

		y = 90
		for i, layer in enumerate(self.sound.layers):
			item_rect = pygame.Rect(30, y, 330, 60)

			if i == self.selected_layer:
				pygame.draw.rect(self.screen, (80, 80, 150), item_rect)

			# Layer info
			text = self.small_font.render(
				f"Layer {i}: {layer.waveform_type.value}",
				True, (255, 255, 255)
			)
			self.screen.blit(text, (40, y + 5))

			freq_text = f"Freq: {layer.frequency:.1f} Hz"
			text = self.small_font.render(freq_text, True, (200, 200, 200))
			self.screen.blit(text, (40, y + 25))

			amp_text = f"Amp: {layer.amplitude:.2f}"
			text = self.small_font.render(amp_text, True, (200, 200, 200))
			self.screen.blit(text, (200, y + 25))

			detune_text = f"Detune: {layer.detune:+.0f} cents"
			text = self.small_font.render(detune_text, True, (200, 200, 200))
			self.screen.blit(text, (40, y + 43))

			y += 65

	def draw_envelope_panel(self):
		"""Draw envelope editor"""
		panel_rect = pygame.Rect(20, 470, 350, 250)
		pygame.draw.rect(self.screen, (40, 40, 40), panel_rect)
		pygame.draw.rect(self.screen, (200, 200, 200), panel_rect, 2)

		if not self.sound.envelope:
			text = self.font.render("No Envelope", True, (255, 255, 255))
			self.screen.blit(text, (30, 485))
			return

		# Title
		text = self.font.render("Envelope", True, (255, 255, 255))
		self.screen.blit(text, (30, 475))

		env = self.sound.envelope
		y = 510

		params = [
			("Attack", env.attack_time),
			("Decay", env.decay_time),
			("Sustain", env.sustain_level),
			("Release", env.release_time)
		]

		for label, value in params:
			text = self.small_font.render(f"{label}: {value:.3f}",
										   True, (255, 255, 255))
			self.screen.blit(text, (40, y))
			y += 25

		# Visual envelope
		env_surface = pygame.Surface((300, 80))
		env_surface.fill((20, 20, 20))

		# Draw envelope shape
		points = []
		total_time = env.attack_time + env.decay_time + 0.5  # +sustain time
		for i in range(300):
			t = i * total_time / 300
			amp = env.get_amplitude(t, total_time, None)
			x = i
			y = 70 - int(amp * 60)
			points.append((x, y))

		if len(points) > 1:
			pygame.draw.lines(env_surface, (100, 255, 100), False, points, 2)

		self.screen.blit(env_surface, (40, 620))

	def draw_waveform_display(self):
		"""Draw waveform visualization"""
		viz_rect = pygame.Rect(390, 50, 1000, 200)
		pygame.draw.rect(self.screen, (200, 200, 200), viz_rect, 2)
		self.screen.blit(self.waveform_viz.surface, (390, 50))

		# Title
		text = self.font.render(
			f"Waveform: {self.sound.name}",
			True, (255, 255, 255)
		)
		self.screen.blit(text, (390, 20))

	def draw_controls(self):
		"""Draw control buttons"""
		button_y = 730

		# Play button
		play_rect = pygame.Rect(390, button_y, 100, 40)
		color = (100, 200, 100) if not self.playing else (200, 100, 100)
		pygame.draw.rect(self.screen, color, play_rect)
		pygame.draw.rect(self.screen, (255, 255, 255), play_rect, 2)

		text = self.font.render("Play", True, (255, 255, 255))
		text_rect = text.get_rect(center=play_rect.center)
		self.screen.blit(text, text_rect)

		# Generate button
		gen_rect = pygame.Rect(510, button_y, 120, 40)
		pygame.draw.rect(self.screen, (100, 100, 200), gen_rect)
		pygame.draw.rect(self.screen, (255, 255, 255), gen_rect, 2)

		text = self.font.render("Generate", True, (255, 255, 255))
		text_rect = text.get_rect(center=gen_rect.center)
		self.screen.blit(text, text_rect)

		# Export button
		export_rect = pygame.Rect(650, button_y, 100, 40)
		pygame.draw.rect(self.screen, (200, 150, 100), export_rect)
		pygame.draw.rect(self.screen, (255, 255, 255), export_rect, 2)

		text = self.font.render("Export", True, (255, 255, 255))
		text_rect = text.get_rect(center=export_rect.center)
		self.screen.blit(text, text_rect)

	def handle_click(self, pos: Tuple[int, int]):
		"""Handle clicks"""
		x, y = pos

		# Layer selection
		if 20 <= x <= 370 and 90 <= y <= 450:
			idx = (y - 90) // 65
			if 0 <= idx < len(self.sound.layers):
				self.selected_layer = idx

		# Play button
		elif 390 <= x <= 490 and 730 <= y <= 770:
			self.play_sound()

		# Generate button
		elif 510 <= x <= 630 and 730 <= y <= 770:
			self.update_waveform()

		# Export button
		elif 650 <= x <= 750 and 730 <= y <= 770:
			self.sound.export_wav(f"{self.sound.name}.wav")
			print(f"Exported to {self.sound.name}.wav")

	def run(self):
		"""Main loop"""
		running = True

		while running:
			for event in pygame.event.get():
				if event.type == pygame.QUIT:
					running = False

				elif event.type == pygame.MOUSEBUTTONDOWN:
					if event.button == 1:
						self.handle_click(event.pos)

				elif event.type == pygame.KEYDOWN:
					if event.key == pygame.K_ESCAPE:
						running = False

					elif event.key == pygame.K_SPACE:
						self.play_sound()

					elif event.key == pygame.K_g:
						self.update_waveform()

					elif event.key == pygame.K_s and (
							pygame.key.get_mods() & pygame.KMOD_CTRL):
						# Save sound definition
						with open("sound.json", 'w') as f:
							json.dump(self.sound.to_dict(), f, indent=2)
						print("Sound definition saved!")

			# Draw
			self.screen.fill((30, 30, 30))

			self.draw_layer_panel()
			self.draw_envelope_panel()
			self.draw_waveform_display()
			self.draw_controls()

			# Instructions
			inst = self.small_font.render(
				"Space: Play | G: Generate | Ctrl+S: Save | ESC: Quit",
				True, (150, 150, 150)
			)
			self.screen.blit(inst, (20, 870))

			pygame.display.flip()
			self.clock.tick(60)

		pygame.quit()


def main():
	"""Run sound sequencer"""
	ui = SoundSequencerUI()
	ui.run()


if __name__ == '__main__':
	main()
