#!/usr/bin/env python3
"""
FFMQ Weather & Particle System Designer - Environmental effects and particles

Weather Features:
- Rain
- Snow
- Fog
- Wind
- Lightning
- Sandstorm
- Custom effects

Particle Systems:
- Emitters
- Particle behavior
- Physics simulation
- Collision
- Color/alpha fading
- Lifetime management

Particle Types:
- Rain drops
- Snow flakes
- Leaves
- Sparkles
- Fire
- Smoke
- Dust
- Magic effects

Effect Properties:
- Intensity
- Direction
- Speed
- Spawn rate
- Lifetime
- Gravity
- Wind

Usage:
	python ffmq_weather_particle.py rom.sfc --weather rain --intensity 80
	python ffmq_weather_particle.py rom.sfc --particle snow --count 100
	python ffmq_weather_particle.py rom.sfc --create rain_heavy.json
	python ffmq_weather_particle.py rom.sfc --test sparkle
	python ffmq_weather_particle.py rom.sfc --export weather_config.json
"""

import argparse
import json
import math
import random
from pathlib import Path
from typing import List, Tuple, Optional
from dataclasses import dataclass, asdict, field
from enum import Enum


class WeatherType(Enum):
	"""Weather effect type"""
	NONE = "none"
	RAIN = "rain"
	SNOW = "snow"
	FOG = "fog"
	WIND = "wind"
	LIGHTNING = "lightning"
	SANDSTORM = "sandstorm"


class ParticleType(Enum):
	"""Particle type"""
	RAINDROP = "raindrop"
	SNOWFLAKE = "snowflake"
	LEAF = "leaf"
	SPARKLE = "sparkle"
	FIRE = "fire"
	SMOKE = "smoke"
	DUST = "dust"
	MAGIC = "magic"


@dataclass
class Particle:
	"""Single particle instance"""
	x: float
	y: float
	velocity_x: float
	velocity_y: float
	lifetime: int  # Frames
	max_lifetime: int
	color: int  # Palette index
	alpha: float = 1.0
	
	def update(self, gravity: float = 0.0, wind: float = 0.0) -> bool:
		"""Update particle position and lifetime. Returns True if alive."""
		self.x += self.velocity_x + wind
		self.y += self.velocity_y
		self.velocity_y += gravity
		
		self.lifetime -= 1
		
		# Fade out over lifetime
		if self.max_lifetime > 0:
			self.alpha = self.lifetime / self.max_lifetime
		
		return self.lifetime > 0
	
	def to_dict(self) -> dict:
		return asdict(self)


@dataclass
class ParticleEmitter:
	"""Particle emitter configuration"""
	particle_type: ParticleType
	x: float  # Emitter position
	y: float
	width: float  # Spawn area
	height: float
	spawn_rate: float  # Particles per frame
	particle_lifetime: int  # Frames
	velocity_min: Tuple[float, float]
	velocity_max: Tuple[float, float]
	gravity: float = 0.1
	wind: float = 0.0
	max_particles: int = 500
	
	def to_dict(self) -> dict:
		d = asdict(self)
		d['particle_type'] = self.particle_type.value
		return d


@dataclass
class WeatherEffect:
	"""Weather effect configuration"""
	weather_type: WeatherType
	intensity: float  # 0-100
	emitters: List[ParticleEmitter] = field(default_factory=list)
	
	def to_dict(self) -> dict:
		d = asdict(self)
		d['weather_type'] = self.weather_type.value
		return d


class FFMQWeatherParticleSystem:
	"""Weather and particle system designer"""
	
	# Screen dimensions
	SCREEN_WIDTH = 256
	SCREEN_HEIGHT = 224
	
	def __init__(self, rom_path: Optional[Path] = None, verbose: bool = False):
		self.rom_path = rom_path
		self.verbose = verbose
		self.particles: List[Particle] = []
		self.emitters: List[ParticleEmitter] = []
	
	def create_weather_effect(self, weather_type: WeatherType, 
							  intensity: float = 50.0) -> WeatherEffect:
		"""Create weather effect with default emitters"""
		effect = WeatherEffect(weather_type=weather_type, intensity=intensity)
		
		if weather_type == WeatherType.RAIN:
			effect.emitters = self._create_rain_emitters(intensity)
		elif weather_type == WeatherType.SNOW:
			effect.emitters = self._create_snow_emitters(intensity)
		elif weather_type == WeatherType.SANDSTORM:
			effect.emitters = self._create_sandstorm_emitters(intensity)
		elif weather_type == WeatherType.WIND:
			effect.emitters = self._create_wind_emitters(intensity)
		
		return effect
	
	def _create_rain_emitters(self, intensity: float) -> List[ParticleEmitter]:
		"""Create rain particle emitters"""
		spawn_rate = intensity / 10.0  # 5-10 particles per frame at 50-100 intensity
		
		emitter = ParticleEmitter(
			particle_type=ParticleType.RAINDROP,
			x=0,
			y=-10,
			width=self.SCREEN_WIDTH,
			height=10,
			spawn_rate=spawn_rate,
			particle_lifetime=60,  # 1 second
			velocity_min=(0, 4.0),
			velocity_max=(0, 8.0),
			gravity=0.2,
			wind=0.0
		)
		
		return [emitter]
	
	def _create_snow_emitters(self, intensity: float) -> List[ParticleEmitter]:
		"""Create snow particle emitters"""
		spawn_rate = intensity / 15.0
		
		emitter = ParticleEmitter(
			particle_type=ParticleType.SNOWFLAKE,
			x=0,
			y=-10,
			width=self.SCREEN_WIDTH,
			height=10,
			spawn_rate=spawn_rate,
			particle_lifetime=120,  # 2 seconds
			velocity_min=(-0.5, 1.0),
			velocity_max=(0.5, 2.0),
			gravity=0.05,
			wind=0.2  # Gentle drift
		)
		
		return [emitter]
	
	def _create_sandstorm_emitters(self, intensity: float) -> List[ParticleEmitter]:
		"""Create sandstorm particle emitters"""
		spawn_rate = intensity / 8.0
		
		# Horizontal sandstorm from left
		emitter = ParticleEmitter(
			particle_type=ParticleType.DUST,
			x=-10,
			y=0,
			width=10,
			height=self.SCREEN_HEIGHT,
			spawn_rate=spawn_rate,
			particle_lifetime=90,
			velocity_min=(3.0, -1.0),
			velocity_max=(6.0, 1.0),
			gravity=0.0,
			wind=intensity / 50.0  # Stronger wind with higher intensity
		)
		
		return [emitter]
	
	def _create_wind_emitters(self, intensity: float) -> List[ParticleEmitter]:
		"""Create wind leaf emitters"""
		spawn_rate = intensity / 20.0
		
		emitter = ParticleEmitter(
			particle_type=ParticleType.LEAF,
			x=-10,
			y=0,
			width=10,
			height=self.SCREEN_HEIGHT,
			spawn_rate=spawn_rate,
			particle_lifetime=150,
			velocity_min=(2.0, -0.5),
			velocity_max=(4.0, 0.5),
			gravity=0.03,
			wind=intensity / 30.0
		)
		
		return [emitter]
	
	def add_emitter(self, emitter: ParticleEmitter) -> None:
		"""Add particle emitter"""
		self.emitters.append(emitter)
		
		if self.verbose:
			print(f"✓ Added {emitter.particle_type.value} emitter at ({emitter.x}, {emitter.y})")
	
	def spawn_particle(self, emitter: ParticleEmitter) -> Particle:
		"""Spawn particle from emitter"""
		# Random position within spawn area
		x = emitter.x + random.uniform(0, emitter.width)
		y = emitter.y + random.uniform(0, emitter.height)
		
		# Random velocity
		vx = random.uniform(emitter.velocity_min[0], emitter.velocity_max[0])
		vy = random.uniform(emitter.velocity_min[1], emitter.velocity_max[1])
		
		# Color based on particle type
		color_map = {
			ParticleType.RAINDROP: 0,  # Blue
			ParticleType.SNOWFLAKE: 1,  # White
			ParticleType.LEAF: 2,  # Green
			ParticleType.SPARKLE: 3,  # Yellow
			ParticleType.FIRE: 4,  # Red
			ParticleType.SMOKE: 5,  # Gray
			ParticleType.DUST: 6,  # Brown
			ParticleType.MAGIC: 7   # Purple
		}
		
		color = color_map.get(emitter.particle_type, 0)
		
		particle = Particle(
			x=x,
			y=y,
			velocity_x=vx,
			velocity_y=vy,
			lifetime=emitter.particle_lifetime,
			max_lifetime=emitter.particle_lifetime,
			color=color,
			alpha=1.0
		)
		
		return particle
	
	def update(self) -> None:
		"""Update all particles (call every frame)"""
		# Spawn new particles from emitters
		for emitter in self.emitters:
			# Spawn based on spawn rate
			num_spawn = int(emitter.spawn_rate)
			if random.random() < (emitter.spawn_rate - num_spawn):
				num_spawn += 1
			
			for _ in range(num_spawn):
				if len(self.particles) < emitter.max_particles:
					particle = self.spawn_particle(emitter)
					self.particles.append(particle)
		
		# Update all particles
		alive_particles = []
		
		for particle in self.particles:
			# Get emitter for physics params (use first emitter for simplicity)
			emitter = self.emitters[0] if self.emitters else None
			gravity = emitter.gravity if emitter else 0.0
			wind = emitter.wind if emitter else 0.0
			
			# Update particle
			if particle.update(gravity, wind):
				# Check if still on screen
				if (-20 <= particle.x <= self.SCREEN_WIDTH + 20 and
					-20 <= particle.y <= self.SCREEN_HEIGHT + 20):
					alive_particles.append(particle)
		
		self.particles = alive_particles
	
	def simulate(self, num_frames: int = 60) -> None:
		"""Simulate particle system for N frames"""
		print(f"\n=== Simulating {num_frames} frames ===\n")
		
		for frame in range(num_frames):
			self.update()
			
			if frame % 10 == 0:
				print(f"Frame {frame}: {len(self.particles)} active particles")
		
		print(f"\nFinal: {len(self.particles)} particles\n")
	
	def export_config(self, output_path: Path) -> None:
		"""Export particle system configuration"""
		data = {
			'emitters': [e.to_dict() for e in self.emitters]
		}
		
		with open(output_path, 'w', encoding='utf-8') as f:
			json.dump(data, f, indent='\t')
		
		if self.verbose:
			print(f"✓ Exported config to {output_path}")
	
	def import_config(self, input_path: Path) -> None:
		"""Import particle system configuration"""
		with open(input_path, 'r', encoding='utf-8') as f:
			data = json.load(f)
		
		self.emitters = []
		
		for emitter_data in data['emitters']:
			emitter_data['particle_type'] = ParticleType(emitter_data['particle_type'])
			emitter = ParticleEmitter(**emitter_data)
			self.emitters.append(emitter)
		
		if self.verbose:
			print(f"✓ Imported {len(self.emitters)} emitter(s) from {input_path}")
	
	def print_emitter_info(self, emitter: ParticleEmitter) -> None:
		"""Print emitter configuration"""
		print(f"\n=== {emitter.particle_type.value.title()} Emitter ===\n")
		print(f"Position: ({emitter.x}, {emitter.y})")
		print(f"Spawn Area: {emitter.width}x{emitter.height}")
		print(f"Spawn Rate: {emitter.spawn_rate:.2f} particles/frame")
		print(f"Lifetime: {emitter.particle_lifetime} frames ({emitter.particle_lifetime/60:.1f}s)")
		print(f"Velocity: ({emitter.velocity_min[0]:.2f}, {emitter.velocity_min[1]:.2f}) to "
			  f"({emitter.velocity_max[0]:.2f}, {emitter.velocity_max[1]:.2f})")
		print(f"Gravity: {emitter.gravity:.3f}")
		print(f"Wind: {emitter.wind:.3f}")
		print(f"Max Particles: {emitter.max_particles}\n")
	
	def visualize_ascii(self, width: int = 64, height: int = 48) -> None:
		"""Visualize particles in ASCII art"""
		grid = [[' ' for _ in range(width)] for _ in range(height)]
		
		# Map particles to grid
		for particle in self.particles:
			# Scale to ASCII grid
			x = int((particle.x / self.SCREEN_WIDTH) * width)
			y = int((particle.y / self.SCREEN_HEIGHT) * height)
			
			if 0 <= x < width and 0 <= y < height:
				# Character based on particle type
				char_map = {
					0: '·',  # Raindrop
					1: '*',  # Snowflake
					2: '~',  # Leaf
					3: '✦',  # Sparkle
					4: '░',  # Fire
					5: '▒',  # Smoke
					6: '.',  # Dust
					7: '○'   # Magic
				}
				
				char = char_map.get(particle.color, '•')
				grid[y][x] = char
		
		# Print grid
		print('┌' + '─' * width + '┐')
		for row in grid:
			print('│' + ''.join(row) + '│')
		print('└' + '─' * width + '┘')
		print(f'{len(self.particles)} particles')


def main():
	parser = argparse.ArgumentParser(description='FFMQ Weather & Particle System Designer')
	parser.add_argument('rom', type=str, nargs='?', help='FFMQ ROM file (optional)')
	parser.add_argument('--weather', type=str, choices=[w.value for w in WeatherType],
					   help='Create weather effect')
	parser.add_argument('--particle', type=str, choices=[p.value for p in ParticleType],
					   help='Create particle emitter')
	parser.add_argument('--intensity', type=float, default=50.0, help='Weather intensity (0-100)')
	parser.add_argument('--count', type=int, default=100, help='Particle count')
	parser.add_argument('--test', action='store_true', help='Run simulation test')
	parser.add_argument('--frames', type=int, default=60, help='Simulation frames')
	parser.add_argument('--visualize', action='store_true', help='ASCII visualization')
	parser.add_argument('--export', type=str, help='Export config to JSON')
	parser.add_argument('--import', type=str, dest='import_file', help='Import config from JSON')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	rom_path = Path(args.rom) if args.rom else None
	system = FFMQWeatherParticleSystem(rom_path=rom_path, verbose=args.verbose)
	
	# Import config
	if args.import_file:
		system.import_config(Path(args.import_file))
		
		for emitter in system.emitters:
			system.print_emitter_info(emitter)
		
		return 0
	
	# Create weather effect
	if args.weather:
		weather_type = WeatherType(args.weather)
		effect = system.create_weather_effect(weather_type, args.intensity)
		
		print(f"\nCreated {weather_type.value} effect (intensity: {args.intensity})\n")
		
		for emitter in effect.emitters:
			system.add_emitter(emitter)
			system.print_emitter_info(emitter)
	
	# Create particle emitter
	elif args.particle:
		particle_type = ParticleType(args.particle)
		
		emitter = ParticleEmitter(
			particle_type=particle_type,
			x=system.SCREEN_WIDTH / 2,
			y=system.SCREEN_HEIGHT / 2,
			width=20,
			height=20,
			spawn_rate=args.count / 60.0,  # Spawn count particles over 60 frames
			particle_lifetime=60,
			velocity_min=(-2.0, -2.0),
			velocity_max=(2.0, 2.0),
			gravity=0.1,
			wind=0.0
		)
		
		system.add_emitter(emitter)
		system.print_emitter_info(emitter)
	
	# Test simulation
	if args.test or args.visualize:
		if not system.emitters:
			# Create default rain
			effect = system.create_weather_effect(WeatherType.RAIN, 50.0)
			system.emitters = effect.emitters
		
		system.simulate(args.frames)
		
		if args.visualize:
			# Run a few more frames and visualize
			for _ in range(10):
				system.update()
			
			print()
			system.visualize_ascii()
	
	# Export config
	if args.export:
		system.export_config(Path(args.export))
		return 0
	
	# Default: show usage
	if not (args.weather or args.particle or args.test or args.import_file):
		print("\nWeather & Particle System Designer")
		print("=" * 50)
		print("\nExamples:")
		print("  --weather rain --intensity 80 --test --visualize")
		print("  --weather snow --intensity 60 --export snow.json")
		print("  --particle sparkle --count 200 --test")
		print()
	
	return 0


if __name__ == '__main__':
	exit(main())
