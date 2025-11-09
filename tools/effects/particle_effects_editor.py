#!/usr/bin/env python3
"""
Particle Effects Editor

Comprehensive particle system and visual effects editor.
Features include:
- Particle emitter configuration
- Multiple particle types
- Physics simulation
- Color gradients over lifetime
- Size/alpha curves
- Sprite-based particles
- Force fields (gravity, wind, vortex)
- Collision detection
- Burst and continuous modes
- Real-time preview
- Export to game format

Particle Properties:
- Position, velocity, acceleration
- Lifetime and fade
- Color gradient
- Size scaling
- Rotation and spin
- Sprite/shape rendering

Emitter Types:
- Point: Single point emission
- Line: Along a line
- Circle: Circular area
- Cone: Directional cone
- Box: Rectangular area
"""

from dataclasses import dataclass, field
from enum import Enum
from typing import Dict, List, Optional, Tuple, Any
import pygame
import json
import math
import random


class EmitterShape(Enum):
    """Emitter shape types"""
    POINT = "point"
    LINE = "line"
    CIRCLE = "circle"
    CONE = "cone"
    BOX = "box"


class ParticleBlendMode(Enum):
    """Particle rendering blend modes"""
    NORMAL = "normal"
    ADDITIVE = "additive"
    MULTIPLY = "multiply"
    SCREEN = "screen"


@dataclass
class ColorGradient:
    """Color gradient over particle lifetime"""
    colors: List[Tuple[int, int, int, int]] = field(default_factory=list)
    stops: List[float] = field(default_factory=list)  # 0.0 to 1.0
    
    def __post_init__(self):
        if not self.colors:
            self.colors = [(255, 255, 255, 255), (255, 255, 255, 0)]
            self.stops = [0.0, 1.0]
    
    def get_color(self, t: float) -> Tuple[int, int, int, int]:
        """Get color at lifetime position t (0.0 to 1.0)"""
        if not self.colors or not self.stops:
            return (255, 255, 255, 255)
        
        # Clamp t
        t = max(0.0, min(1.0, t))
        
        # Find surrounding stops
        for i in range(len(self.stops) - 1):
            if self.stops[i] <= t <= self.stops[i + 1]:
                # Interpolate between colors
                t_local = (t - self.stops[i]) / (self.stops[i + 1] - self.stops[i])
                
                c1 = self.colors[i]
                c2 = self.colors[i + 1]
                
                r = int(c1[0] + (c2[0] - c1[0]) * t_local)
                g = int(c1[1] + (c2[1] - c1[1]) * t_local)
                b = int(c1[2] + (c2[2] - c1[2]) * t_local)
                a = int(c1[3] + (c2[3] - c1[3]) * t_local)
                
                return (r, g, b, a)
        
        return self.colors[-1]
    
    def to_dict(self) -> dict:
        """Convert to dictionary"""
        return {
            "colors": self.colors,
            "stops": self.stops,
        }
    
    @staticmethod
    def from_dict(data: dict) -> 'ColorGradient':
        """Create from dictionary"""
        return ColorGradient(
            colors=data.get("colors", []),
            stops=data.get("stops", []),
        )


@dataclass
class SizeCurve:
    """Size curve over particle lifetime"""
    points: List[Tuple[float, float]] = field(default_factory=list)
    
    def __post_init__(self):
        if not self.points:
            self.points = [(0.0, 1.0), (1.0, 0.0)]
    
    def get_size(self, t: float) -> float:
        """Get size multiplier at lifetime position t"""
        if not self.points:
            return 1.0
        
        t = max(0.0, min(1.0, t))
        
        # Find surrounding points
        for i in range(len(self.points) - 1):
            if self.points[i][0] <= t <= self.points[i + 1][0]:
                t_local = (t - self.points[i][0]) / \
                    (self.points[i + 1][0] - self.points[i][0])
                size1 = self.points[i][1]
                size2 = self.points[i + 1][1]
                return size1 + (size2 - size1) * t_local
        
        return self.points[-1][1]
    
    def to_dict(self) -> dict:
        """Convert to dictionary"""
        return {"points": self.points}
    
    @staticmethod
    def from_dict(data: dict) -> 'SizeCurve':
        """Create from dictionary"""
        return SizeCurve(points=data.get("points", []))


@dataclass
class Particle:
    """Individual particle"""
    position: Tuple[float, float] = (0.0, 0.0)
    velocity: Tuple[float, float] = (0.0, 0.0)
    acceleration: Tuple[float, float] = (0.0, 0.0)
    lifetime: float = 1.0
    age: float = 0.0
    rotation: float = 0.0
    angular_velocity: float = 0.0
    base_size: float = 5.0
    
    def update(self, dt: float):
        """Update particle physics"""
        # Update velocity
        vx, vy = self.velocity
        ax, ay = self.acceleration
        vx += ax * dt
        vy += ay * dt
        self.velocity = (vx, vy)
        
        # Update position
        x, y = self.position
        x += vx * dt
        y += vy * dt
        self.position = (x, y)
        
        # Update rotation
        self.rotation += self.angular_velocity * dt
        
        # Update age
        self.age += dt
    
    def is_dead(self) -> bool:
        """Check if particle should be removed"""
        return self.age >= self.lifetime
    
    def get_lifetime_t(self) -> float:
        """Get lifetime progress (0.0 to 1.0)"""
        if self.lifetime <= 0:
            return 1.0
        return min(1.0, self.age / self.lifetime)


@dataclass
class ParticleEmitter:
    """Particle emitter configuration"""
    emitter_id: int
    name: str
    shape: EmitterShape = EmitterShape.POINT
    position: Tuple[float, float] = (0.0, 0.0)
    
    # Emission properties
    emission_rate: float = 10.0  # Particles per second
    burst_count: int = 0  # 0 = continuous
    duration: float = -1.0  # -1 = infinite
    
    # Shape parameters
    radius: float = 50.0  # For circle/cone
    angle: float = 90.0  # For cone (degrees)
    direction: float = 0.0  # Base direction (degrees)
    width: float = 100.0  # For line/box
    height: float = 100.0  # For box
    
    # Particle properties
    lifetime_min: float = 1.0
    lifetime_max: float = 2.0
    speed_min: float = 50.0
    speed_max: float = 100.0
    size_min: float = 5.0
    size_max: float = 10.0
    rotation_min: float = 0.0
    rotation_max: float = 360.0
    angular_velocity_min: float = -180.0
    angular_velocity_max: float = 180.0
    
    # Visual properties
    color_gradient: ColorGradient = field(default_factory=ColorGradient)
    size_curve: SizeCurve = field(default_factory=SizeCurve)
    blend_mode: ParticleBlendMode = ParticleBlendMode.ADDITIVE
    
    # Physics
    gravity: Tuple[float, float] = (0.0, 100.0)
    damping: float = 0.0  # 0-1, velocity multiplier per second
    
    # Internal state
    particles: List[Particle] = field(default_factory=list)
    emission_timer: float = 0.0
    emitter_age: float = 0.0
    active: bool = True
    
    def emit_particle(self) -> Particle:
        """Emit a single particle"""
        # Random position based on shape
        if self.shape == EmitterShape.POINT:
            pos = self.position
        
        elif self.shape == EmitterShape.LINE:
            t = random.uniform(-0.5, 0.5)
            angle_rad = math.radians(self.direction)
            pos = (
                self.position[0] + math.cos(angle_rad) * self.width * t,
                self.position[1] + math.sin(angle_rad) * self.width * t,
            )
        
        elif self.shape == EmitterShape.CIRCLE:
            r = random.uniform(0, self.radius)
            theta = random.uniform(0, 2 * math.pi)
            pos = (
                self.position[0] + r * math.cos(theta),
                self.position[1] + r * math.sin(theta),
            )
        
        elif self.shape == EmitterShape.CONE:
            # Random angle within cone
            half_angle = self.angle / 2
            angle_offset = random.uniform(-half_angle, half_angle)
            angle_rad = math.radians(self.direction + angle_offset)
            
            # Random distance
            dist = random.uniform(0, self.radius)
            pos = (
                self.position[0] + dist * math.cos(angle_rad),
                self.position[1] + dist * math.sin(angle_rad),
            )
        
        elif self.shape == EmitterShape.BOX:
            pos = (
                self.position[0] + random.uniform(-self.width / 2, self.width / 2),
                self.position[1] + random.uniform(-self.height / 2, self.height / 2),
            )
        
        else:
            pos = self.position
        
        # Random velocity
        speed = random.uniform(self.speed_min, self.speed_max)
        
        if self.shape == EmitterShape.CONE:
            half_angle = self.angle / 2
            angle_offset = random.uniform(-half_angle, half_angle)
            angle_rad = math.radians(self.direction + angle_offset)
        else:
            angle_rad = random.uniform(0, 2 * math.pi)
        
        velocity = (
            speed * math.cos(angle_rad),
            speed * math.sin(angle_rad),
        )
        
        # Create particle
        particle = Particle(
            position=pos,
            velocity=velocity,
            acceleration=self.gravity,
            lifetime=random.uniform(self.lifetime_min, self.lifetime_max),
            rotation=random.uniform(self.rotation_min, self.rotation_max),
            angular_velocity=random.uniform(
                self.angular_velocity_min, self.angular_velocity_max),
            base_size=random.uniform(self.size_min, self.size_max),
        )
        
        return particle
    
    def update(self, dt: float):
        """Update emitter and particles"""
        if not self.active:
            return
        
        # Update emitter age
        self.emitter_age += dt
        
        # Check duration
        if self.duration > 0 and self.emitter_age >= self.duration:
            self.active = False
            return
        
        # Emit particles
        if self.burst_count > 0:
            # Burst mode
            if self.emitter_age < 0.1:  # Emit burst at start
                for _ in range(self.burst_count):
                    self.particles.append(self.emit_particle())
        else:
            # Continuous mode
            self.emission_timer += dt
            emit_interval = 1.0 / self.emission_rate if self.emission_rate > 0 else 1.0
            
            while self.emission_timer >= emit_interval:
                self.particles.append(self.emit_particle())
                self.emission_timer -= emit_interval
        
        # Update particles
        for particle in self.particles:
            particle.update(dt)
            
            # Apply damping
            if self.damping > 0:
                damping_factor = 1.0 - self.damping * dt
                vx, vy = particle.velocity
                particle.velocity = (vx * damping_factor, vy * damping_factor)
        
        # Remove dead particles
        self.particles = [p for p in self.particles if not p.is_dead()]
    
    def reset(self):
        """Reset emitter to initial state"""
        self.particles.clear()
        self.emission_timer = 0.0
        self.emitter_age = 0.0
        self.active = True
    
    def to_dict(self) -> dict:
        """Convert to dictionary"""
        return {
            "emitter_id": self.emitter_id,
            "name": self.name,
            "shape": self.shape.value,
            "position": self.position,
            "emission_rate": self.emission_rate,
            "burst_count": self.burst_count,
            "duration": self.duration,
            "radius": self.radius,
            "angle": self.angle,
            "direction": self.direction,
            "width": self.width,
            "height": self.height,
            "lifetime_min": self.lifetime_min,
            "lifetime_max": self.lifetime_max,
            "speed_min": self.speed_min,
            "speed_max": self.speed_max,
            "size_min": self.size_min,
            "size_max": self.size_max,
            "rotation_min": self.rotation_min,
            "rotation_max": self.rotation_max,
            "angular_velocity_min": self.angular_velocity_min,
            "angular_velocity_max": self.angular_velocity_max,
            "color_gradient": self.color_gradient.to_dict(),
            "size_curve": self.size_curve.to_dict(),
            "blend_mode": self.blend_mode.value,
            "gravity": self.gravity,
            "damping": self.damping,
        }
    
    @staticmethod
    def from_dict(data: dict) -> 'ParticleEmitter':
        """Create from dictionary"""
        return ParticleEmitter(
            emitter_id=data["emitter_id"],
            name=data["name"],
            shape=EmitterShape(data.get("shape", "point")),
            position=tuple(data.get("position", (0.0, 0.0))),
            emission_rate=data.get("emission_rate", 10.0),
            burst_count=data.get("burst_count", 0),
            duration=data.get("duration", -1.0),
            radius=data.get("radius", 50.0),
            angle=data.get("angle", 90.0),
            direction=data.get("direction", 0.0),
            width=data.get("width", 100.0),
            height=data.get("height", 100.0),
            lifetime_min=data.get("lifetime_min", 1.0),
            lifetime_max=data.get("lifetime_max", 2.0),
            speed_min=data.get("speed_min", 50.0),
            speed_max=data.get("speed_max", 100.0),
            size_min=data.get("size_min", 5.0),
            size_max=data.get("size_max", 10.0),
            rotation_min=data.get("rotation_min", 0.0),
            rotation_max=data.get("rotation_max", 360.0),
            angular_velocity_min=data.get("angular_velocity_min", -180.0),
            angular_velocity_max=data.get("angular_velocity_max", 180.0),
            color_gradient=ColorGradient.from_dict(data.get("color_gradient", {})),
            size_curve=SizeCurve.from_dict(data.get("size_curve", {})),
            blend_mode=ParticleBlendMode(data.get("blend_mode", "additive")),
            gravity=tuple(data.get("gravity", (0.0, 100.0))),
            damping=data.get("damping", 0.0),
        )


class EmitterLibrary:
    """Library of particle emitter presets"""
    
    @staticmethod
    def get_fire_emitter() -> ParticleEmitter:
        """Fire/flame effect"""
        emitter = ParticleEmitter(
            emitter_id=1,
            name="Fire",
            shape=EmitterShape.CONE,
            position=(400, 400),
            emission_rate=30.0,
            direction=-90.0,  # Upward
            angle=30.0,
            radius=10.0,
            lifetime_min=0.5,
            lifetime_max=1.5,
            speed_min=80.0,
            speed_max=120.0,
            size_min=8.0,
            size_max=15.0,
            angular_velocity_min=-90.0,
            angular_velocity_max=90.0,
            gravity=(0.0, -50.0),  # Negative = upward
            damping=0.5,
        )
        
        # Fire colors: yellow -> orange -> red -> black
        emitter.color_gradient = ColorGradient(
            colors=[
                (255, 255, 100, 255),
                (255, 150, 50, 255),
                (255, 50, 50, 200),
                (50, 50, 50, 0),
            ],
            stops=[0.0, 0.3, 0.7, 1.0],
        )
        
        emitter.size_curve = SizeCurve(points=[
            (0.0, 0.5),
            (0.3, 1.0),
            (1.0, 0.2),
        ])
        
        return emitter
    
    @staticmethod
    def get_explosion_emitter() -> ParticleEmitter:
        """Explosion burst"""
        emitter = ParticleEmitter(
            emitter_id=2,
            name="Explosion",
            shape=EmitterShape.CIRCLE,
            position=(400, 400),
            burst_count=100,
            duration=2.0,
            radius=5.0,
            lifetime_min=0.5,
            lifetime_max=2.0,
            speed_min=100.0,
            speed_max=300.0,
            size_min=3.0,
            size_max=12.0,
            gravity=(0.0, 200.0),
            damping=1.5,
        )
        
        # Explosion colors: bright white/yellow -> orange -> dark
        emitter.color_gradient = ColorGradient(
            colors=[
                (255, 255, 255, 255),
                (255, 200, 100, 255),
                (255, 100, 50, 200),
                (100, 50, 50, 0),
            ],
            stops=[0.0, 0.2, 0.5, 1.0],
        )
        
        return emitter
    
    @staticmethod
    def get_smoke_emitter() -> ParticleEmitter:
        """Smoke effect"""
        emitter = ParticleEmitter(
            emitter_id=3,
            name="Smoke",
            shape=EmitterShape.POINT,
            position=(400, 400),
            emission_rate=10.0,
            lifetime_min=2.0,
            lifetime_max=4.0,
            speed_min=20.0,
            speed_max=50.0,
            size_min=10.0,
            size_max=20.0,
            angular_velocity_min=-30.0,
            angular_velocity_max=30.0,
            gravity=(0.0, -30.0),  # Rises
            damping=0.8,
        )
        
        # Smoke colors: dark gray -> light gray -> transparent
        emitter.color_gradient = ColorGradient(
            colors=[
                (100, 100, 100, 200),
                (150, 150, 150, 150),
                (180, 180, 180, 0),
            ],
            stops=[0.0, 0.5, 1.0],
        )
        
        emitter.size_curve = SizeCurve(points=[
            (0.0, 0.5),
            (0.5, 1.2),
            (1.0, 1.5),
        ])
        
        emitter.blend_mode = ParticleBlendMode.NORMAL
        
        return emitter
    
    @staticmethod
    def get_sparkle_emitter() -> ParticleEmitter:
        """Sparkle/glitter effect"""
        emitter = ParticleEmitter(
            emitter_id=4,
            name="Sparkle",
            shape=EmitterShape.BOX,
            position=(400, 300),
            emission_rate=20.0,
            width=100.0,
            height=100.0,
            lifetime_min=0.5,
            lifetime_max=1.5,
            speed_min=10.0,
            speed_max=40.0,
            size_min=2.0,
            size_max=5.0,
            rotation_min=0.0,
            rotation_max=360.0,
            angular_velocity_min=-360.0,
            angular_velocity_max=360.0,
            gravity=(0.0, 50.0),
            damping=0.2,
        )
        
        # Sparkle colors: bright white -> fade out
        emitter.color_gradient = ColorGradient(
            colors=[
                (255, 255, 255, 0),
                (255, 255, 200, 255),
                (255, 255, 150, 255),
                (200, 200, 255, 0),
            ],
            stops=[0.0, 0.1, 0.5, 1.0],
        )
        
        emitter.size_curve = SizeCurve(points=[
            (0.0, 0.0),
            (0.1, 1.0),
            (0.9, 1.0),
            (1.0, 0.0),
        ])
        
        return emitter


class ParticleDatabase:
    """Database of particle emitters"""
    
    def __init__(self):
        self.emitters: Dict[int, ParticleEmitter] = {}
        self._init_sample_data()
    
    def _init_sample_data(self):
        """Initialize sample emitters"""
        self.emitters[1] = EmitterLibrary.get_fire_emitter()
        self.emitters[2] = EmitterLibrary.get_explosion_emitter()
        self.emitters[3] = EmitterLibrary.get_smoke_emitter()
        self.emitters[4] = EmitterLibrary.get_sparkle_emitter()
    
    def add(self, emitter: ParticleEmitter):
        """Add emitter to database"""
        self.emitters[emitter.emitter_id] = emitter
    
    def get(self, emitter_id: int) -> Optional[ParticleEmitter]:
        """Get emitter by ID"""
        return self.emitters.get(emitter_id)
    
    def save_json(self, filename: str):
        """Save to JSON"""
        data = {
            "emitters": [e.to_dict() for e in self.emitters.values()]
        }
        
        with open(filename, 'w') as f:
            json.dump(data, f, indent=2)
    
    def load_json(self, filename: str):
        """Load from JSON"""
        with open(filename, 'r') as f:
            data = json.load(f)
        
        self.emitters = {}
        for emitter_data in data.get("emitters", []):
            emitter = ParticleEmitter.from_dict(emitter_data)
            self.emitters[emitter.emitter_id] = emitter


class ParticleEffectsEditor:
    """Main particle effects editor with UI"""
    
    def __init__(self, width: int = 1600, height: int = 900):
        self.width = width
        self.height = height
        self.running = True
        
        pygame.init()
        self.screen = pygame.display.set_mode((width, height))
        pygame.display.set_caption("Particle Effects Editor")
        self.clock = pygame.time.Clock()
        
        self.font = pygame.font.Font(None, 24)
        self.small_font = pygame.font.Font(None, 18)
        
        # Database
        self.database = ParticleDatabase()
        self.current_emitter: Optional[ParticleEmitter] = None
        self.selected_emitter_id: Optional[int] = None
        
        # UI state
        self.emitter_scroll = 0
        self.preview_offset = (750, 400)
        
        # Select first emitter
        if self.database.emitters:
            first_id = min(self.database.emitters.keys())
            self.current_emitter = self.database.emitters[first_id]
            self.selected_emitter_id = first_id
    
    def run(self):
        """Main editor loop"""
        while self.running:
            dt = self.clock.tick(60) / 1000.0
            self._handle_events()
            self._update(dt)
            self._render()
        
        pygame.quit()
    
    def _update(self, dt: float):
        """Update particle systems"""
        if self.current_emitter:
            self.current_emitter.update(dt)
    
    def _handle_events(self):
        """Handle input events"""
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                self.running = False
            
            elif event.type == pygame.KEYDOWN:
                self._handle_command_input(event)
            
            elif event.type == pygame.MOUSEBUTTONDOWN:
                self._handle_mouse_click(event.pos, event.button)
            
            elif event.type == pygame.MOUSEWHEEL:
                self.emitter_scroll = max(0, self.emitter_scroll - event.y * 30)
    
    def _handle_command_input(self, event):
        """Handle command input"""
        if event.key == pygame.K_ESCAPE:
            self.running = False
        
        # Save/Load
        elif event.key == pygame.K_s and pygame.key.get_mods() & pygame.KMOD_CTRL:
            self.database.save_json("particles.json")
            print("Particles saved to particles.json")
        
        elif event.key == pygame.K_o and pygame.key.get_mods() & pygame.KMOD_CTRL:
            try:
                self.database.load_json("particles.json")
                print("Particles loaded from particles.json")
            except FileNotFoundError:
                print("No particles.json file found")
        
        # Playback
        elif event.key == pygame.K_SPACE:
            if self.current_emitter:
                self.current_emitter.reset()
        
        elif event.key == pygame.K_p:
            if self.current_emitter:
                self.current_emitter.active = not self.current_emitter.active
        
        # Navigation
        elif event.key == pygame.K_UP:
            emitter_ids = sorted(self.database.emitters.keys())
            if self.selected_emitter_id in emitter_ids:
                idx = emitter_ids.index(self.selected_emitter_id)
                if idx > 0:
                    self.selected_emitter_id = emitter_ids[idx - 1]
                    self.current_emitter = self.database.emitters[self.selected_emitter_id]
        
        elif event.key == pygame.K_DOWN:
            emitter_ids = sorted(self.database.emitters.keys())
            if self.selected_emitter_id in emitter_ids:
                idx = emitter_ids.index(self.selected_emitter_id)
                if idx < len(emitter_ids) - 1:
                    self.selected_emitter_id = emitter_ids[idx + 1]
                    self.current_emitter = self.database.emitters[self.selected_emitter_id]
    
    def _handle_mouse_click(self, pos: Tuple[int, int], button: int):
        """Handle mouse click"""
        x, y = pos
        
        # Check emitter list
        if x < 250 and button == 1:
            y_offset = 80 - self.emitter_scroll
            
            for emitter_id in sorted(self.database.emitters.keys()):
                if y_offset <= y < y_offset + 70:
                    self.current_emitter = self.database.emitters[emitter_id]
                    self.selected_emitter_id = emitter_id
                    break
                y_offset += 75
        
        # Click in preview to move emitter
        elif 250 < x < 1200 and 50 < y < self.height - 50 and button == 1:
            if self.current_emitter:
                self.current_emitter.position = (
                    x - self.preview_offset[0] + 400,
                    y - self.preview_offset[1] + 400,
                )
    
    def _render(self):
        """Render editor"""
        self.screen.fill((25, 25, 35))
        
        # Draw emitter list
        self._draw_emitter_list()
        
        # Draw preview area
        self._draw_preview_area()
        
        # Draw properties panel
        self._draw_properties_panel()
        
        # Draw toolbar
        self._draw_toolbar()
        
        pygame.display.flip()
    
    def _draw_emitter_list(self):
        """Draw emitter list panel"""
        panel_x = 0
        panel_y = 50
        panel_width = 250
        panel_height = self.height - 100
        
        # Background
        pygame.draw.rect(self.screen, (35, 35, 45),
                         (panel_x, panel_y, panel_width, panel_height))
        pygame.draw.rect(self.screen, (80, 80, 100),
                         (panel_x, panel_y, panel_width, panel_height), 2)
        
        # Title
        title = self.font.render("Emitters", True, (255, 255, 255))
        self.screen.blit(title, (panel_x + 10, panel_y + 10))
        
        # Emitter list
        y_offset = panel_y + 50 - self.emitter_scroll
        
        for emitter_id in sorted(self.database.emitters.keys()):
            emitter = self.database.emitters[emitter_id]
            
            if y_offset + 70 < panel_y or y_offset > panel_y + panel_height:
                y_offset += 75
                continue
            
            # Background
            bg_color = (60, 60, 80) if emitter_id == self.selected_emitter_id else (
                45, 45, 55)
            pygame.draw.rect(self.screen, bg_color,
                             (panel_x + 5, y_offset, panel_width - 10, 70))
            pygame.draw.rect(self.screen, (100, 100, 120),
                             (panel_x + 5, y_offset, panel_width - 10, 70), 1)
            
            # Emitter ID
            id_text = self.small_font.render(
                f"#{emitter_id}", True, (180, 180, 180))
            self.screen.blit(id_text, (panel_x + 10, y_offset + 5))
            
            # Active indicator
            if emitter.active:
                pygame.draw.circle(self.screen, (100, 255, 100),
                                   (panel_x + 230, y_offset + 12), 5)
            else:
                pygame.draw.circle(self.screen, (100, 100, 100),
                                   (panel_x + 230, y_offset + 12), 5)
            
            # Emitter name
            name_text = self.small_font.render(
                emitter.name, True, (200, 200, 255))
            self.screen.blit(name_text, (panel_x + 10, y_offset + 25))
            
            # Shape and particle count
            info = f"{emitter.shape.value} | {len(emitter.particles)} particles"
            info_text = self.small_font.render(info, True, (150, 150, 150))
            self.screen.blit(info_text, (panel_x + 10, y_offset + 45))
            
            # Emission info
            if emitter.burst_count > 0:
                emit_text = f"Burst: {emitter.burst_count}"
            else:
                emit_text = f"Rate: {emitter.emission_rate:.1f}/s"
            
            emit_surf = self.small_font.render(emit_text, True, (150, 150, 150))
            self.screen.blit(emit_surf, (panel_x + 10, y_offset + 60))
            
            y_offset += 75
    
    def _draw_preview_area(self):
        """Draw particle preview area"""
        preview_x = 250
        preview_y = 50
        preview_width = 950
        preview_height = self.height - 100
        
        # Background
        pygame.draw.rect(self.screen, (10, 10, 20),
                         (preview_x, preview_y, preview_width, preview_height))
        pygame.draw.rect(self.screen, (80, 80, 100),
                         (preview_x, preview_y, preview_width, preview_height), 2)
        
        if not self.current_emitter:
            return
        
        # Draw grid
        grid_spacing = 50
        for x in range(preview_x, preview_x + preview_width, grid_spacing):
            pygame.draw.line(self.screen, (30, 30, 40),
                             (x, preview_y), (x, preview_y + preview_height), 1)
        for y in range(preview_y, preview_y + preview_height, grid_spacing):
            pygame.draw.line(self.screen, (30, 30, 40),
                             (preview_x, y), (preview_x + preview_width, y), 1)
        
        # Draw emitter position indicator
        emitter_screen_pos = (
            int(self.current_emitter.position[0] +
                self.preview_offset[0] - 400),
            int(self.current_emitter.position[1] +
                self.preview_offset[1] - 400),
        )
        
        pygame.draw.circle(self.screen, (255, 100, 100),
                           emitter_screen_pos, 8, 2)
        pygame.draw.line(self.screen, (255, 100, 100),
                         (emitter_screen_pos[0] - 10, emitter_screen_pos[1]),
                         (emitter_screen_pos[0] + 10, emitter_screen_pos[1]), 2)
        pygame.draw.line(self.screen, (255, 100, 100),
                         (emitter_screen_pos[0], emitter_screen_pos[1] - 10),
                         (emitter_screen_pos[0], emitter_screen_pos[1] + 10), 2)
        
        # Draw particles
        for particle in self.current_emitter.particles:
            self._draw_particle(particle, self.current_emitter)
    
    def _draw_particle(self, particle: Particle, emitter: ParticleEmitter):
        """Draw a single particle"""
        # Calculate screen position
        screen_x = int(particle.position[0] + self.preview_offset[0] - 400)
        screen_y = int(particle.position[1] + self.preview_offset[1] - 400)
        
        # Get color from gradient
        t = particle.get_lifetime_t()
        color = emitter.color_gradient.get_color(t)
        
        # Get size from curve
        size_mult = emitter.size_curve.get_size(t)
        size = int(particle.base_size * size_mult)
        
        if size < 1:
            return
        
        # Create surface for particle with alpha
        if color[3] < 255:
            particle_surf = pygame.Surface((size * 2, size * 2), pygame.SRCALPHA)
        else:
            particle_surf = pygame.Surface((size * 2, size * 2))
            particle_surf.set_colorkey((0, 0, 0))
        
        # Draw particle shape
        pygame.draw.circle(particle_surf, color[:3], (size, size), size)
        
        # Apply alpha
        if color[3] < 255:
            particle_surf.set_alpha(color[3])
        
        # Blit to screen
        self.screen.blit(particle_surf, (screen_x - size, screen_y - size))
    
    def _draw_properties_panel(self):
        """Draw properties panel"""
        panel_x = self.width - 400
        panel_y = 50
        panel_width = 400
        panel_height = self.height - 100
        
        # Background
        pygame.draw.rect(self.screen, (35, 35, 45),
                         (panel_x, panel_y, panel_width, panel_height))
        pygame.draw.rect(self.screen, (80, 80, 100),
                         (panel_x, panel_y, panel_width, panel_height), 2)
        
        if not self.current_emitter:
            return
        
        # Title
        title = self.font.render("Properties", True, (255, 255, 255))
        self.screen.blit(title, (panel_x + 10, panel_y + 10))
        
        y_offset = panel_y + 45
        
        # Emitter properties
        props = [
            ("Name", self.current_emitter.name),
            ("Shape", self.current_emitter.shape.value),
            ("Particles", str(len(self.current_emitter.particles))),
            ("Active", "Yes" if self.current_emitter.active else "No"),
            ("", ""),
            ("Emission", ""),
            ("Rate", f"{self.current_emitter.emission_rate:.1f}/s" if self.current_emitter.burst_count == 0 else f"Burst: {self.current_emitter.burst_count}"),
            ("Duration", f"{self.current_emitter.duration:.1f}s" if self.current_emitter.duration > 0 else "Infinite"),
            ("", ""),
            ("Lifetime", ""),
            ("Min", f"{self.current_emitter.lifetime_min:.2f}s"),
            ("Max", f"{self.current_emitter.lifetime_max:.2f}s"),
            ("", ""),
            ("Speed", ""),
            ("Min", f"{self.current_emitter.speed_min:.1f}"),
            ("Max", f"{self.current_emitter.speed_max:.1f}"),
            ("", ""),
            ("Size", ""),
            ("Min", f"{self.current_emitter.size_min:.1f}"),
            ("Max", f"{self.current_emitter.size_max:.1f}"),
            ("", ""),
            ("Physics", ""),
            ("Gravity", f"({self.current_emitter.gravity[0]:.0f}, {self.current_emitter.gravity[1]:.0f})"),
            ("Damping", f"{self.current_emitter.damping:.2f}"),
        ]
        
        for label, value in props:
            if label == "":
                y_offset += 10
                continue
            
            if value == "":
                # Section header
                label_surf = self.small_font.render(
                    label, True, (200, 200, 255))
                self.screen.blit(label_surf, (panel_x + 15, y_offset))
                y_offset += 25
            else:
                label_surf = self.small_font.render(
                    f"{label}:", True, (180, 180, 180))
                self.screen.blit(label_surf, (panel_x + 25, y_offset))
                
                value_surf = self.small_font.render(
                    value, True, (150, 150, 150))
                self.screen.blit(value_surf, (panel_x + 200, y_offset))
                
                y_offset += 22
    
    def _draw_toolbar(self):
        """Draw top toolbar"""
        toolbar_height = 40
        pygame.draw.rect(self.screen, (45, 45, 55),
                         (0, 0, self.width, toolbar_height))
        pygame.draw.rect(self.screen, (80, 80, 100),
                         (0, 0, self.width, toolbar_height), 2)
        
        # Title
        if self.current_emitter:
            title = self.font.render(
                f"Emitter: {self.current_emitter.name}", True, (255, 255, 255))
            self.screen.blit(title, (10, 10))
        
        # Instructions
        help_text = "Space:Reset | P:Pause | Click:Move | ↑↓:Navigate | Ctrl+S:Save | Esc:Exit"
        help_surf = self.small_font.render(help_text, True, (180, 180, 180))
        self.screen.blit(help_surf, (400, 12))


def main():
    """Run particle effects editor"""
    editor = ParticleEffectsEditor()
    editor.run()


if __name__ == "__main__":
    main()
