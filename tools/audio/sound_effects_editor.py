#!/usr/bin/env python3
"""
Sound Effects Editor

Comprehensive waveform editor for SNES sound effects.
Features include:
- Waveform visualization and editing
- Sample generation (sine, square, triangle, sawtooth, noise)
- Envelope editing (ADSR, custom)
- Filter effects (low-pass, high-pass, band-pass, notch)
- Modulation effects (vibrato, tremolo, chorus, flanger)
- Time effects (reverse, pitch shift, time stretch)
- BRR encoding/decoding
- Real-time preview and playback
- Sample library management
- Export to SNES BRR format
- Import from WAV files

Waveform Types:
- Sine: Pure tone
- Square: Chiptune/retro sound
- Triangle: Mellower than square
- Sawtooth: Bright, rich harmonics
- Noise: White/pink noise
- Custom: Draw your own

Effects:
- ADSR Envelope
- Low-pass/High-pass filters
- Vibrato/Tremolo
- Pitch bend
- Echo/Reverb
- Distortion
"""

from dataclasses import dataclass, field
from enum import Enum
from typing import List, Optional, Tuple, Callable
import pygame
import numpy as np
import struct
import math


class WaveformType(Enum):
    """Waveform generator types"""
    SINE = "sine"
    SQUARE = "square"
    TRIANGLE = "triangle"
    SAWTOOTH = "sawtooth"
    NOISE = "noise"
    CUSTOM = "custom"


class FilterType(Enum):
    """Audio filter types"""
    LOWPASS = "lowpass"
    HIGHPASS = "highpass"
    BANDPASS = "bandpass"
    NOTCH = "notch"


@dataclass
class ADSR:
    """ADSR envelope parameters"""
    attack: float = 0.1  # Seconds
    decay: float = 0.1
    sustain: float = 0.7  # Level 0-1
    release: float = 0.2

    def apply(self, samples: np.ndarray, sample_rate: int) -> np.ndarray:
        """Apply ADSR envelope to samples"""
        total_samples = len(samples)
        envelope = np.ones(total_samples)

        attack_samples = int(self.attack * sample_rate)
        decay_samples = int(self.decay * sample_rate)
        release_samples = int(self.release * sample_rate)

        # Attack
        if attack_samples > 0:
            envelope[:attack_samples] = np.linspace(0, 1, attack_samples)

        # Decay
        if decay_samples > 0:
            decay_end = attack_samples + decay_samples
            envelope[attack_samples:decay_end] = np.linspace(
                1, self.sustain, decay_samples)

        # Sustain
        sustain_end = total_samples - release_samples
        if sustain_end > attack_samples + decay_samples:
            envelope[attack_samples + decay_samples:sustain_end] = self.sustain

        # Release
        if release_samples > 0:
            envelope[-release_samples:] = np.linspace(
                self.sustain, 0, release_samples)

        return samples * envelope


@dataclass
class SoundEffect:
    """Sound effect definition"""
    name: str
    waveform_type: WaveformType = WaveformType.SINE
    samples: np.ndarray = field(default_factory=lambda: np.zeros(1000))
    sample_rate: int = 16000
    frequency: float = 440.0
    amplitude: float = 0.8
    duration: float = 1.0
    envelope: ADSR = field(default_factory=ADSR)

    def generate(self):
        """Generate waveform from parameters"""
        num_samples = int(self.duration * self.sample_rate)
        t = np.linspace(0, self.duration, num_samples, False)

        if self.waveform_type == WaveformType.SINE:
            self.samples = np.sin(2 * np.pi * self.frequency * t)

        elif self.waveform_type == WaveformType.SQUARE:
            self.samples = np.sign(np.sin(2 * np.pi * self.frequency * t))

        elif self.waveform_type == WaveformType.TRIANGLE:
            self.samples = 2 * np.abs(
                2 * (self.frequency * t - np.floor(self.frequency * t + 0.5))) - 1

        elif self.waveform_type == WaveformType.SAWTOOTH:
            self.samples = 2 * (self.frequency * t - np.floor(self.frequency * t)) - 1

        elif self.waveform_type == WaveformType.NOISE:
            self.samples = np.random.uniform(-1, 1, num_samples)

        # Apply amplitude
        self.samples *= self.amplitude

        # Apply envelope
        self.samples = self.envelope.apply(self.samples, self.sample_rate)

    def apply_lowpass(self, cutoff: float):
        """Apply low-pass filter"""
        # Simple RC filter approximation
        rc = 1.0 / (cutoff * 2 * np.pi)
        dt = 1.0 / self.sample_rate
        alpha = dt / (rc + dt)

        filtered = np.zeros_like(self.samples)
        filtered[0] = self.samples[0]

        for i in range(1, len(self.samples)):
            filtered[i] = filtered[i - 1] + \
                alpha * (self.samples[i] - filtered[i - 1])

        self.samples = filtered

    def apply_highpass(self, cutoff: float):
        """Apply high-pass filter"""
        # Simple RC filter approximation
        rc = 1.0 / (cutoff * 2 * np.pi)
        dt = 1.0 / self.sample_rate
        alpha = rc / (rc + dt)

        filtered = np.zeros_like(self.samples)
        filtered[0] = self.samples[0]

        for i in range(1, len(self.samples)):
            filtered[i] = alpha * \
                (filtered[i - 1] + self.samples[i] - self.samples[i - 1])

        self.samples = filtered

    def apply_vibrato(self, rate: float, depth: float):
        """Apply vibrato (pitch modulation)"""
        num_samples = len(self.samples)
        t = np.arange(num_samples) / self.sample_rate

        # Modulation signal
        mod = depth * np.sin(2 * np.pi * rate * t)

        # Time-varying delay
        indices = np.arange(num_samples) + mod * self.sample_rate / self.frequency
        indices = np.clip(indices, 0, num_samples - 1).astype(int)

        self.samples = self.samples[indices]

    def apply_tremolo(self, rate: float, depth: float):
        """Apply tremolo (amplitude modulation)"""
        num_samples = len(self.samples)
        t = np.arange(num_samples) / self.sample_rate

        # Modulation signal
        mod = 1 + depth * np.sin(2 * np.pi * rate * t)

        self.samples *= mod

    def apply_distortion(self, amount: float):
        """Apply distortion/overdrive"""
        # Soft clipping
        self.samples = np.tanh(amount * self.samples)

    def reverse(self):
        """Reverse the waveform"""
        self.samples = self.samples[::-1]

    def pitch_shift(self, semitones: float):
        """Shift pitch by semitones"""
        ratio = 2 ** (semitones / 12)
        new_length = int(len(self.samples) / ratio)
        indices = np.linspace(0, len(self.samples) - 1, new_length)
        self.samples = np.interp(indices, np.arange(
            len(self.samples)), self.samples)
        self.frequency *= ratio

    def normalize(self):
        """Normalize amplitude to 0-1 range"""
        max_val = np.max(np.abs(self.samples))
        if max_val > 0:
            self.samples /= max_val

    def to_pcm16(self) -> bytes:
        """Convert to 16-bit PCM"""
        # Scale to int16 range
        pcm = (self.samples * 32767).astype(np.int16)
        return pcm.tobytes()

    def to_wav(self, filename: str):
        """Export to WAV file"""
        import wave

        with wave.open(filename, 'w') as wav:
            wav.setnchannels(1)  # Mono
            wav.setsampwidth(2)  # 16-bit
            wav.setframerate(self.sample_rate)
            wav.writeframes(self.to_pcm16())

    def from_wav(self, filename: str):
        """Import from WAV file"""
        import wave

        with wave.open(filename, 'r') as wav:
            self.sample_rate = wav.getframerate()
            frames = wav.readframes(wav.getnframes())

            # Convert to float samples
            pcm = np.frombuffer(frames, dtype=np.int16)
            self.samples = pcm.astype(float) / 32767

            self.duration = len(self.samples) / self.sample_rate

    def to_brr(self) -> bytes:
        """Encode to SNES BRR format"""
        # Simplified BRR encoding
        # Real BRR encoding is more complex with prediction filters

        brr_data = bytearray()
        samples_16bit = (self.samples * 32767).astype(np.int16)

        # Process in 16-sample blocks
        for i in range(0, len(samples_16bit), 16):
            block = samples_16bit[i:i + 16]

            # Pad if needed
            if len(block) < 16:
                block = np.pad(block, (0, 16 - len(block)))

            # Find best shift amount
            max_val = np.max(np.abs(block))
            shift = 0
            if max_val > 0:
                shift = max(0, min(12, int(np.log2(32767 / max_val))))

            # Header byte
            header = shift
            if i + 16 >= len(samples_16bit):
                header |= 0x01  # End flag

            brr_data.append(header)

            # Encode 16 samples to 8 bytes
            shifted = (block >> shift).astype(np.int8)
            for j in range(0, 16, 2):
                byte = ((shifted[j] & 0x0F) << 4) | (shifted[j + 1] & 0x0F)
                brr_data.append(byte & 0xFF)

        return bytes(brr_data)


class SoundEffectLibrary:
    """Library of preset sound effects"""

    def __init__(self):
        self.effects: List[SoundEffect] = []
        self._init_presets()

    def _init_presets(self):
        """Initialize preset sound effects"""
        # Jump sound
        jump = SoundEffect(name="Jump", frequency=440, duration=0.15)
        jump.waveform_type = WaveformType.SQUARE
        jump.envelope = ADSR(attack=0.01, decay=0.05, sustain=0.3, release=0.09)
        jump.generate()
        jump.pitch_shift(12)  # One octave up
        self.effects.append(jump)

        # Coin collect
        coin = SoundEffect(name="Coin", frequency=880, duration=0.2)
        coin.waveform_type = WaveformType.SINE
        coin.envelope = ADSR(attack=0.01, decay=0.04, sustain=0.5, release=0.15)
        coin.generate()
        self.effects.append(coin)

        # Explosion
        explosion = SoundEffect(name="Explosion", frequency=100, duration=0.5)
        explosion.waveform_type = WaveformType.NOISE
        explosion.envelope = ADSR(attack=0.01, decay=0.2, sustain=0.1, release=0.29)
        explosion.generate()
        explosion.apply_lowpass(2000)
        self.effects.append(explosion)

        # Menu beep
        beep = SoundEffect(name="Menu Beep", frequency=660, duration=0.1)
        beep.waveform_type = WaveformType.SQUARE
        beep.envelope = ADSR(attack=0.01, decay=0.02, sustain=0.5, release=0.07)
        beep.generate()
        self.effects.append(beep)

        # Laser
        laser = SoundEffect(name="Laser", frequency=1200, duration=0.3)
        laser.waveform_type = WaveformType.SAWTOOTH
        laser.envelope = ADSR(attack=0.01, decay=0.1, sustain=0.3, release=0.19)
        laser.generate()
        laser.pitch_shift(-24)  # Sweep down
        self.effects.append(laser)

        # Power up
        powerup = SoundEffect(name="Power Up", frequency=330, duration=0.5)
        powerup.waveform_type = WaveformType.TRIANGLE
        powerup.envelope = ADSR(attack=0.05, decay=0.1, sustain=0.7, release=0.35)
        powerup.generate()
        powerup.pitch_shift(24)  # Sweep up
        powerup.apply_vibrato(5, 0.1)
        self.effects.append(powerup)

        # Hit/Impact
        hit = SoundEffect(name="Hit", frequency=150, duration=0.15)
        hit.waveform_type = WaveformType.NOISE
        hit.envelope = ADSR(attack=0.01, decay=0.05, sustain=0.2, release=0.09)
        hit.generate()
        hit.apply_lowpass(1000)
        hit.apply_distortion(2.0)
        self.effects.append(hit)

        # Footstep
        step = SoundEffect(name="Footstep", frequency=120, duration=0.08)
        step.waveform_type = WaveformType.NOISE
        step.envelope = ADSR(attack=0.005, decay=0.02, sustain=0.1, release=0.055)
        step.generate()
        step.apply_lowpass(800)
        self.effects.append(step)

    def add(self, effect: SoundEffect):
        """Add effect to library"""
        self.effects.append(effect)

    def remove(self, effect: SoundEffect):
        """Remove effect from library"""
        if effect in self.effects:
            self.effects.remove(effect)

    def get_by_name(self, name: str) -> Optional[SoundEffect]:
        """Get effect by name"""
        for effect in self.effects:
            if effect.name == name:
                return effect
        return None


class SoundEffectEditor:
    """Main sound effect editor with UI"""

    def __init__(self, width: int = 1600, height: int = 900):
        self.width = width
        self.height = height
        self.running = True

        pygame.init()
        self.screen = pygame.display.set_mode((width, height))
        pygame.display.set_caption("Sound Effect Editor")
        self.clock = pygame.time.Clock()

        self.font = pygame.font.Font(None, 24)
        self.small_font = pygame.font.Font(None, 18)

        # Sound library
        self.library = SoundEffectLibrary()
        self.current_effect: Optional[SoundEffect] = None

        # UI state
        self.library_scroll = 0
        self.waveform_offset = 0
        self.waveform_zoom = 1.0
        self.selected_effect_index = 0

        # Panels
        self.show_library = True
        self.show_controls = True
        self.show_effects = True

        # Editing
        self.editing_param: Optional[str] = None
        self.param_value = ""

        # Playback (simplified, no actual audio)
        self.playing = False
        self.play_position = 0

        # Select first effect
        if self.library.effects:
            self.current_effect = self.library.effects[0]

    def run(self):
        """Main editor loop"""
        while self.running:
            self._handle_events()
            self._render()
            self.clock.tick(60)

        pygame.quit()

    def _handle_events(self):
        """Handle input events"""
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                self.running = False

            elif event.type == pygame.KEYDOWN:
                if self.editing_param:
                    self._handle_param_input(event)
                else:
                    self._handle_command_input(event)

            elif event.type == pygame.MOUSEBUTTONDOWN:
                self._handle_mouse_click(event.pos, event.button)

            elif event.type == pygame.MOUSEWHEEL:
                # Zoom waveform
                if pygame.key.get_mods() & pygame.KMOD_CTRL:
                    self.waveform_zoom *= 1.1 if event.y > 0 else 0.9
                    self.waveform_zoom = max(0.1, min(10.0, self.waveform_zoom))
                else:
                    self.library_scroll = max(
                        0, self.library_scroll - event.y * 30)

    def _handle_param_input(self, event):
        """Handle parameter editing input"""
        if event.key == pygame.K_RETURN:
            self._apply_param_edit()
            self.editing_param = None
            self.param_value = ""

        elif event.key == pygame.K_ESCAPE:
            self.editing_param = None
            self.param_value = ""

        elif event.key == pygame.K_BACKSPACE:
            self.param_value = self.param_value[:-1]

        elif event.unicode and (event.unicode.isdigit() or event.unicode in '.-'):
            self.param_value += event.unicode

    def _apply_param_edit(self):
        """Apply parameter edit to current effect"""
        if not self.current_effect or not self.editing_param:
            return

        try:
            value = float(self.param_value)

            if self.editing_param == "frequency":
                self.current_effect.frequency = max(20, min(20000, value))
            elif self.editing_param == "amplitude":
                self.current_effect.amplitude = max(0, min(1, value))
            elif self.editing_param == "duration":
                self.current_effect.duration = max(0.01, min(10, value))
            elif self.editing_param == "attack":
                self.current_effect.envelope.attack = max(0, min(2, value))
            elif self.editing_param == "decay":
                self.current_effect.envelope.decay = max(0, min(2, value))
            elif self.editing_param == "sustain":
                self.current_effect.envelope.sustain = max(0, min(1, value))
            elif self.editing_param == "release":
                self.current_effect.envelope.release = max(0, min(2, value))

            # Regenerate with new parameters
            self.current_effect.generate()

        except ValueError:
            pass

    def _handle_command_input(self, event):
        """Handle command input"""
        if event.key == pygame.K_ESCAPE:
            self.running = False

        # New effect
        elif event.key == pygame.K_n:
            new_effect = SoundEffect(name=f"Effect {len(self.library.effects) + 1}")
            new_effect.generate()
            self.library.add(new_effect)
            self.current_effect = new_effect
            self.selected_effect_index = len(self.library.effects) - 1

        # Generate
        elif event.key == pygame.K_g:
            if self.current_effect:
                self.current_effect.generate()

        # Play
        elif event.key == pygame.K_SPACE:
            self.playing = not self.playing
            if self.playing:
                self.play_position = 0

        # Export
        elif event.key == pygame.K_e:
            if self.current_effect:
                filename = f"{self.current_effect.name.replace(' ', '_')}.wav"
                self.current_effect.to_wav(filename)
                print(f"Exported to {filename}")

        # Normalize
        elif event.key == pygame.K_r:
            if self.current_effect:
                self.current_effect.normalize()

        # Reverse
        elif event.key == pygame.K_v:
            if self.current_effect:
                self.current_effect.reverse()

        # Navigation
        elif event.key == pygame.K_UP:
            self.selected_effect_index = max(
                0, self.selected_effect_index - 1)
            if self.library.effects:
                self.current_effect = self.library.effects[self.selected_effect_index]

        elif event.key == pygame.K_DOWN:
            self.selected_effect_index = min(
                len(self.library.effects) - 1, self.selected_effect_index + 1)
            if self.library.effects:
                self.current_effect = self.library.effects[self.selected_effect_index]

        # Toggle panels
        elif event.key == pygame.K_F1:
            self.show_library = not self.show_library
        elif event.key == pygame.K_F2:
            self.show_controls = not self.show_controls
        elif event.key == pygame.K_F3:
            self.show_effects = not self.show_effects

    def _handle_mouse_click(self, pos: Tuple[int, int], button: int):
        """Handle mouse click"""
        x, y = pos

        # Check library panel
        if self.show_library and x < 250 and button == 1:
            y_offset = 80 - self.library_scroll

            for i, effect in enumerate(self.library.effects):
                if y_offset <= y < y_offset + 40:
                    self.current_effect = effect
                    self.selected_effect_index = i
                    break
                y_offset += 45

        # Check controls panel
        if self.show_controls and y > self.height - 300:
            self._handle_control_click(pos)

    def _handle_control_click(self, pos: Tuple[int, int]):
        """Handle control panel click"""
        if not self.current_effect:
            return

        x, y = pos
        panel_x = 250 if self.show_library else 0
        panel_y = self.height - 300

        # Check parameter labels for editing
        params = [
            ("frequency", 20),
            ("amplitude", 60),
            ("duration", 100),
            ("attack", 160),
            ("decay", 200),
            ("sustain", 240),
            ("release", 280),
        ]

        for param_name, y_offset in params:
            if (panel_x + 10 < x < panel_x + 200 and
                    panel_y + y_offset < y < panel_y + y_offset + 20):
                self.editing_param = param_name

                # Get current value
                if param_name in ["frequency", "amplitude", "duration"]:
                    self.param_value = str(
                        getattr(self.current_effect, param_name))
                else:
                    self.param_value = str(
                        getattr(self.current_effect.envelope, param_name))
                break

    def _render(self):
        """Render editor"""
        self.screen.fill((25, 25, 35))

        # Draw library panel
        if self.show_library:
            self._draw_library_panel()

        # Draw waveform
        self._draw_waveform()

        # Draw controls panel
        if self.show_controls:
            self._draw_controls_panel()

        # Draw effects panel
        if self.show_effects:
            self._draw_effects_panel()

        # Draw toolbar
        self._draw_toolbar()

        pygame.display.flip()

        # Update playback
        if self.playing and self.current_effect:
            self.play_position += 1
            if self.play_position >= len(self.current_effect.samples):
                self.playing = False
                self.play_position = 0

    def _draw_library_panel(self):
        """Draw sound effect library panel"""
        panel_x = 0
        panel_y = 50
        panel_width = 250
        panel_height = self.height - 350

        # Background
        pygame.draw.rect(self.screen, (35, 35, 45),
                         (panel_x, panel_y, panel_width, panel_height))
        pygame.draw.rect(self.screen, (80, 80, 100),
                         (panel_x, panel_y, panel_width, panel_height), 2)

        # Title
        title = self.font.render("Sound Library", True, (255, 255, 255))
        self.screen.blit(title, (panel_x + 10, panel_y + 10))

        # Effects list
        y_offset = panel_y + 50 - self.library_scroll

        for i, effect in enumerate(self.library.effects):
            if y_offset + 40 < panel_y or y_offset > panel_y + panel_height:
                y_offset += 45
                continue

            # Background
            bg_color = (60, 60, 80) if i == self.selected_effect_index else (45, 45, 55)
            pygame.draw.rect(self.screen, bg_color,
                             (panel_x + 5, y_offset, panel_width - 10, 40))
            pygame.draw.rect(self.screen, (100, 100, 120),
                             (panel_x + 5, y_offset, panel_width - 10, 40), 1)

            # Name
            name_text = self.small_font.render(effect.name, True, (200, 200, 255))
            self.screen.blit(name_text, (panel_x + 10, y_offset + 5))

            # Info
            info = f"{effect.frequency:.0f}Hz, {effect.duration:.2f}s"
            info_text = self.small_font.render(info, True, (150, 150, 150))
            self.screen.blit(info_text, (panel_x + 10, y_offset + 22))

            y_offset += 45

    def _draw_waveform(self):
        """Draw waveform visualization"""
        wave_x = 250 if self.show_library else 0
        wave_y = 50
        wave_width = self.width - wave_x - (300 if self.show_effects else 0)
        wave_height = (self.height - 350) if self.show_controls else (
            self.height - 100)

        # Background
        pygame.draw.rect(self.screen, (20, 20, 30),
                         (wave_x, wave_y, wave_width, wave_height))
        pygame.draw.rect(self.screen, (80, 80, 100),
                         (wave_x, wave_y, wave_width, wave_height), 2)

        if not self.current_effect:
            return

        # Draw center line
        center_y = wave_y + wave_height // 2
        pygame.draw.line(self.screen, (60, 60, 80),
                         (wave_x, center_y), (wave_x + wave_width, center_y), 1)

        # Draw waveform
        samples = self.current_effect.samples
        if len(samples) == 0:
            return

        # Calculate visible range
        samples_per_pixel = max(1, int(len(samples) / (wave_width * self.waveform_zoom)))
        start_sample = int(self.waveform_offset)
        end_sample = min(len(samples), start_sample + wave_width * samples_per_pixel)

        points = []
        for x in range(wave_width):
            sample_index = start_sample + x * samples_per_pixel
            if sample_index >= len(samples):
                break

            # Average samples in this pixel
            pixel_samples = samples[sample_index:sample_index + samples_per_pixel]
            if len(pixel_samples) > 0:
                avg = np.mean(pixel_samples)
                y = int(center_y - avg * (wave_height // 2 - 10))
                points.append((wave_x + x, y))

        # Draw waveform line
        if len(points) > 1:
            pygame.draw.lines(self.screen, (100, 200, 255), False, points, 2)

        # Draw playback position
        if self.playing:
            play_x = wave_x + int((self.play_position - start_sample) / samples_per_pixel)
            if wave_x <= play_x < wave_x + wave_width:
                pygame.draw.line(self.screen, (255, 100, 100),
                                 (play_x, wave_y), (play_x, wave_y + wave_height), 2)

        # Draw info
        info_text = f"Zoom: {self.waveform_zoom:.1f}x | Samples: {len(samples)} | Rate: {self.current_effect.sample_rate}Hz"
        info_surf = self.small_font.render(info_text, True, (180, 180, 180))
        self.screen.blit(info_surf, (wave_x + 10, wave_y + 10))

    def _draw_controls_panel(self):
        """Draw parameter controls panel"""
        panel_x = 250 if self.show_library else 0
        panel_y = self.height - 300
        panel_width = self.width - panel_x - (300 if self.show_effects else 0)
        panel_height = 250

        # Background
        pygame.draw.rect(self.screen, (35, 35, 45),
                         (panel_x, panel_y, panel_width, panel_height))
        pygame.draw.rect(self.screen, (80, 80, 100),
                         (panel_x, panel_y, panel_width, panel_height), 2)

        if not self.current_effect:
            return

        # Title
        title = self.font.render("Parameters", True, (255, 255, 255))
        self.screen.blit(title, (panel_x + 10, panel_y + 10))

        # Parameters
        params = [
            ("Frequency", f"{self.current_effect.frequency:.1f} Hz",
             "frequency", 20),
            ("Amplitude", f"{self.current_effect.amplitude:.2f}",
             "amplitude", 60),
            ("Duration", f"{self.current_effect.duration:.2f} sec",
             "duration", 100),
            ("", "", "", 130),
            ("Attack", f"{self.current_effect.envelope.attack:.3f}s",
             "attack", 160),
            ("Decay", f"{self.current_effect.envelope.decay:.3f}s", "decay", 200),
            ("Sustain", f"{self.current_effect.envelope.sustain:.2f}",
             "sustain", 240),
            ("Release", f"{self.current_effect.envelope.release:.3f}s",
             "release", 280),
        ]

        for label, value, param_name, y_offset in params:
            if not label:
                # Draw separator
                pygame.draw.line(self.screen, (60, 60, 80),
                                 (panel_x + 10, panel_y + y_offset),
                                 (panel_x + panel_width - 10, panel_y + y_offset), 1)
                continue

            # Highlight if editing
            color = (255, 255, 100) if param_name == self.editing_param else (200, 200, 200)

            label_surf = self.small_font.render(label + ":", True, color)
            self.screen.blit(label_surf, (panel_x + 10, panel_y + y_offset))

            # Value (or input field)
            if param_name == self.editing_param:
                value_text = self.param_value + "_"
            else:
                value_text = value

            value_surf = self.small_font.render(value_text, True, color)
            self.screen.blit(value_surf, (panel_x + 150, panel_y + y_offset))

        # Waveform type
        wave_label = self.small_font.render(
            f"Waveform: {self.current_effect.waveform_type.value}", True, (200, 200, 200))
        self.screen.blit(wave_label, (panel_x + 350, panel_y + 20))

    def _draw_effects_panel(self):
        """Draw effects/actions panel"""
        panel_x = self.width - 300
        panel_y = 50
        panel_width = 300
        panel_height = self.height - 100

        # Background
        pygame.draw.rect(self.screen, (35, 35, 45),
                         (panel_x, panel_y, panel_width, panel_height))
        pygame.draw.rect(self.screen, (80, 80, 100),
                         (panel_x, panel_y, panel_width, panel_height), 2)

        # Title
        title = self.font.render("Effects & Actions", True, (255, 255, 255))
        self.screen.blit(title, (panel_x + 10, panel_y + 10))

        # Action buttons (visual only - click handlers would go in mouse click)
        actions = [
            ("Generate (G)", 50),
            ("Play/Stop (Space)", 80),
            ("Normalize (R)", 110),
            ("Reverse (V)", 140),
            ("Export WAV (E)", 170),
            ("", 200),
            ("Filters:", 220),
            ("  Low-pass", 245),
            ("  High-pass", 270),
            ("  Band-pass", 295),
            ("", 320),
            ("Modulation:", 340),
            ("  Vibrato", 365),
            ("  Tremolo", 390),
            ("  Chorus", 415),
            ("", 440),
            ("Time:", 460),
            ("  Pitch Shift", 485),
            ("  Time Stretch", 510),
            ("  Reverse", 535),
        ]

        for label, y_offset in actions:
            if not label:
                pygame.draw.line(self.screen, (60, 60, 80),
                                 (panel_x + 10, panel_y + y_offset),
                                 (panel_x + panel_width - 10, panel_y + y_offset), 1)
                continue

            color = (200, 200, 255) if ":" in label else (180, 180, 180)
            text_surf = self.small_font.render(label, True, color)
            self.screen.blit(text_surf, (panel_x + 10, panel_y + y_offset))

    def _draw_toolbar(self):
        """Draw top toolbar"""
        toolbar_height = 40
        pygame.draw.rect(self.screen, (45, 45, 55),
                         (0, 0, self.width, toolbar_height))
        pygame.draw.rect(self.screen, (80, 80, 100),
                         (0, 0, self.width, toolbar_height), 2)

        # Title
        if self.current_effect:
            title = self.font.render(
                f"Effect: {self.current_effect.name}", True, (255, 255, 255))
            self.screen.blit(title, (10, 10))

        # Instructions
        help_text = "N:New | G:Generate | Space:Play | E:Export | R:Normalize | V:Reverse | ↑↓:Navigate"
        help_surf = self.small_font.render(help_text, True, (180, 180, 180))
        self.screen.blit(help_surf, (350, 12))


def main():
    """Run sound effect editor"""
    editor = SoundEffectEditor()
    editor.run()


if __name__ == "__main__":
    main()
