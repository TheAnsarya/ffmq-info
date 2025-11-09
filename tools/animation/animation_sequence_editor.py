#!/usr/bin/env python3
"""
Animation Sequence Editor

Comprehensive animation and cutscene sequencing tool.
Features include:
- Frame-by-frame sprite animation
- Cutscene timeline editing
- Camera movement and effects
- Sprite movement paths
- Text and dialog timing
- Sound effect triggers
- Screen effects (fade, shake, flash)
- Parallel track support
- Keyframe interpolation
- Export to multiple formats

Animation Types:
- Sprite Animation: Character/enemy animations
- Cutscene: Scripted sequences
- Camera: Panning, zooming, following
- Effects: Visual effects timing
- Dialog: Text synchronized with events

Timeline Tracks:
- Sprite: Sprite position, frame, flip
- Camera: Position, zoom, shake
- Effect: Screen effects, fades
- Sound: Music, SFX triggers
- Dialog: Text display timing
- Event: Game event triggers
"""

from dataclasses import dataclass, field
from enum import Enum
from typing import Dict, List, Optional, Tuple, Any
import pygame
import json
import math


class TrackType(Enum):
    """Timeline track types"""
    SPRITE = "sprite"
    CAMERA = "camera"
    EFFECT = "effect"
    SOUND = "sound"
    DIALOG = "dialog"
    EVENT = "event"


class InterpolationType(Enum):
    """Keyframe interpolation methods"""
    LINEAR = "linear"
    EASE_IN = "ease_in"
    EASE_OUT = "ease_out"
    EASE_IN_OUT = "ease_in_out"
    STEP = "step"


class EffectType(Enum):
    """Screen effect types"""
    FADE_IN = "fade_in"
    FADE_OUT = "fade_out"
    FLASH = "flash"
    SHAKE = "shake"
    ZOOM = "zoom"
    TINT = "tint"


@dataclass
class Keyframe:
    """Animation keyframe"""
    frame: int
    properties: Dict[str, Any] = field(default_factory=dict)
    interpolation: InterpolationType = InterpolationType.LINEAR

    def get_interpolated_value(
        self,
        next_keyframe: 'Keyframe',
        current_frame: int,
        property_name: str
    ) -> Any:
        """Interpolate value between this and next keyframe"""
        if property_name not in self.properties or property_name not in next_keyframe.properties:
            return self.properties.get(property_name)

        start_value = self.properties[property_name]
        end_value = next_keyframe.properties[property_name]

        # Calculate progress (0.0 to 1.0)
        total_frames = next_keyframe.frame - self.frame
        if total_frames == 0:
            return start_value

        progress = (current_frame - self.frame) / total_frames

        # Apply interpolation curve
        if self.interpolation == InterpolationType.STEP:
            return start_value

        elif self.interpolation == InterpolationType.LINEAR:
            t = progress

        elif self.interpolation == InterpolationType.EASE_IN:
            t = progress ** 2

        elif self.interpolation == InterpolationType.EASE_OUT:
            t = 1 - (1 - progress) ** 2

        elif self.interpolation == InterpolationType.EASE_IN_OUT:
            if progress < 0.5:
                t = 2 * progress ** 2
            else:
                t = 1 - 2 * (1 - progress) ** 2

        else:
            t = progress

        # Interpolate based on value type
        if isinstance(start_value, (int, float)):
            return start_value + (end_value - start_value) * t

        elif isinstance(start_value, tuple) and len(start_value) == 2:
            # 2D position
            x = start_value[0] + (end_value[0] - start_value[0]) * t
            y = start_value[1] + (end_value[1] - start_value[1]) * t
            return (x, y)

        return start_value


@dataclass
class Track:
    """Animation track"""
    track_id: int
    name: str
    track_type: TrackType
    keyframes: List[Keyframe] = field(default_factory=list)
    enabled: bool = True
    locked: bool = False

    def add_keyframe(self, keyframe: Keyframe):
        """Add keyframe to track"""
        self.keyframes.append(keyframe)
        self.keyframes.sort(key=lambda k: k.frame)

    def remove_keyframe(self, keyframe: Keyframe):
        """Remove keyframe from track"""
        if keyframe in self.keyframes:
            self.keyframes.remove(keyframe)

    def get_value_at_frame(self, frame: int, property_name: str) -> Any:
        """Get interpolated value at frame"""
        if not self.keyframes:
            return None

        # Find surrounding keyframes
        prev_kf = None
        next_kf = None

        for i, kf in enumerate(self.keyframes):
            if kf.frame <= frame:
                prev_kf = kf
            if kf.frame > frame and next_kf is None:
                next_kf = kf
                break

        if prev_kf is None:
            return self.keyframes[0].properties.get(property_name)

        if next_kf is None:
            return prev_kf.properties.get(property_name)

        # Interpolate between keyframes
        return prev_kf.get_interpolated_value(next_kf, frame, property_name)

    def get_keyframe_at_frame(self, frame: int) -> Optional[Keyframe]:
        """Get keyframe at exact frame"""
        for kf in self.keyframes:
            if kf.frame == frame:
                return kf
        return None


@dataclass
class AnimationSequence:
    """Complete animation sequence"""
    sequence_id: int
    name: str
    duration: int = 300  # Frames (60 FPS = 5 seconds)
    tracks: List[Track] = field(default_factory=list)
    loop: bool = False

    def add_track(self, track: Track):
        """Add track to sequence"""
        self.tracks.append(track)

    def remove_track(self, track: Track):
        """Remove track from sequence"""
        if track in self.tracks:
            self.tracks.remove(track)

    def get_track_by_id(self, track_id: int) -> Optional[Track]:
        """Get track by ID"""
        for track in self.tracks:
            if track.track_id == track_id:
                return track
        return None

    def to_dict(self) -> dict:
        """Convert to dictionary"""
        return {
            "sequence_id": self.sequence_id,
            "name": self.name,
            "duration": self.duration,
            "loop": self.loop,
            "tracks": [
                {
                    "track_id": t.track_id,
                    "name": t.name,
                    "track_type": t.track_type.value,
                    "enabled": t.enabled,
                    "locked": t.locked,
                    "keyframes": [
                        {
                            "frame": kf.frame,
                            "properties": kf.properties,
                            "interpolation": kf.interpolation.value,
                        }
                        for kf in t.keyframes
                    ],
                }
                for t in self.tracks
            ],
        }

    @staticmethod
    def from_dict(data: dict) -> 'AnimationSequence':
        """Create from dictionary"""
        seq = AnimationSequence(
            sequence_id=data["sequence_id"],
            name=data["name"],
            duration=data.get("duration", 300),
            loop=data.get("loop", False),
        )

        for track_data in data.get("tracks", []):
            track = Track(
                track_id=track_data["track_id"],
                name=track_data["name"],
                track_type=TrackType(track_data["track_type"]),
                enabled=track_data.get("enabled", True),
                locked=track_data.get("locked", False),
            )

            for kf_data in track_data.get("keyframes", []):
                keyframe = Keyframe(
                    frame=kf_data["frame"],
                    properties=kf_data["properties"],
                    interpolation=InterpolationType(
                        kf_data.get("interpolation", "linear")),
                )
                track.add_keyframe(keyframe)

            seq.add_track(track)

        return seq


class AnimationDatabase:
    """Database of animation sequences"""

    def __init__(self):
        self.sequences: Dict[int, AnimationSequence] = {}
        self._init_sample_data()

    def _init_sample_data(self):
        """Initialize sample animations"""
        # Simple character walk cycle
        walk_seq = AnimationSequence(
            sequence_id=1,
            name="Character Walk",
            duration=60,
            loop=True
        )

        # Sprite track
        sprite_track = Track(
            track_id=1,
            name="Hero Sprite",
            track_type=TrackType.SPRITE
        )

        # Walk animation keyframes
        sprite_track.add_keyframe(Keyframe(
            frame=0,
            properties={"position": (100, 200), "frame": 0, "flip_h": False}
        ))
        sprite_track.add_keyframe(Keyframe(
            frame=15,
            properties={"position": (150, 200), "frame": 1, "flip_h": False},
            interpolation=InterpolationType.LINEAR
        ))
        sprite_track.add_keyframe(Keyframe(
            frame=30,
            properties={"position": (200, 200), "frame": 2, "flip_h": False}
        ))
        sprite_track.add_keyframe(Keyframe(
            frame=45,
            properties={"position": (250, 200), "frame": 3, "flip_h": False}
        ))
        sprite_track.add_keyframe(Keyframe(
            frame=60,
            properties={"position": (300, 200), "frame": 0, "flip_h": False}
        ))

        walk_seq.add_track(sprite_track)
        self.sequences[1] = walk_seq

        # Cutscene example
        cutscene = AnimationSequence(
            sequence_id=2,
            name="Intro Cutscene",
            duration=300
        )

        # Camera track
        camera_track = Track(
            track_id=2,
            name="Camera",
            track_type=TrackType.CAMERA
        )

        camera_track.add_keyframe(Keyframe(
            frame=0,
            properties={"position": (0, 0), "zoom": 1.0}
        ))
        camera_track.add_keyframe(Keyframe(
            frame=120,
            properties={"position": (200, 100), "zoom": 1.5},
            interpolation=InterpolationType.EASE_IN_OUT
        ))
        camera_track.add_keyframe(Keyframe(
            frame=240,
            properties={"position": (400, 200), "zoom": 1.0}
        ))

        cutscene.add_track(camera_track)

        # Effect track
        effect_track = Track(
            track_id=3,
            name="Screen Effects",
            track_type=TrackType.EFFECT
        )

        effect_track.add_keyframe(Keyframe(
            frame=0,
            properties={"effect": "fade_in", "duration": 30}
        ))
        effect_track.add_keyframe(Keyframe(
            frame=270,
            properties={"effect": "fade_out", "duration": 30}
        ))

        cutscene.add_track(effect_track)

        # Dialog track
        dialog_track = Track(
            track_id=4,
            name="Dialog",
            track_type=TrackType.DIALOG
        )

        dialog_track.add_keyframe(Keyframe(
            frame=60,
            properties={"text": "Welcome, hero...", "speaker": "Elder"}
        ))
        dialog_track.add_keyframe(Keyframe(
            frame=150,
            properties={"text": "Your journey begins here.", "speaker": "Elder"}
        ))

        cutscene.add_track(dialog_track)

        self.sequences[2] = cutscene

    def add(self, sequence: AnimationSequence):
        """Add sequence to database"""
        self.sequences[sequence.sequence_id] = sequence

    def get(self, sequence_id: int) -> Optional[AnimationSequence]:
        """Get sequence by ID"""
        return self.sequences.get(sequence_id)

    def save_json(self, filename: str):
        """Save to JSON"""
        data = {
            "sequences": [seq.to_dict() for seq in self.sequences.values()]
        }

        with open(filename, 'w') as f:
            json.dump(data, f, indent=2)

    def load_json(self, filename: str):
        """Load from JSON"""
        with open(filename, 'r') as f:
            data = json.load(f)

        self.sequences = {}
        for seq_data in data.get("sequences", []):
            seq = AnimationSequence.from_dict(seq_data)
            self.sequences[seq.sequence_id] = seq


class AnimationSequenceEditor:
    """Main animation sequence editor with UI"""

    def __init__(self, width: int = 1600, height: int = 900):
        self.width = width
        self.height = height
        self.running = True

        pygame.init()
        self.screen = pygame.display.set_mode((width, height))
        pygame.display.set_caption("Animation Sequence Editor")
        self.clock = pygame.time.Clock()

        self.font = pygame.font.Font(None, 24)
        self.small_font = pygame.font.Font(None, 18)

        # Database
        self.database = AnimationDatabase()
        self.current_sequence: Optional[AnimationSequence] = None
        self.selected_sequence_id: Optional[int] = None
        self.selected_track: Optional[Track] = None
        self.selected_keyframe: Optional[Keyframe] = None

        # Timeline state
        self.current_frame = 0
        self.playing = False
        self.timeline_zoom = 2.0  # Pixels per frame
        self.timeline_scroll = 0

        # UI state
        self.sequence_scroll = 0

        # Select first sequence
        if self.database.sequences:
            first_id = min(self.database.sequences.keys())
            self.current_sequence = self.database.sequences[first_id]
            self.selected_sequence_id = first_id

    def run(self):
        """Main editor loop"""
        while self.running:
            self._handle_events()
            self._update()
            self._render()
            self.clock.tick(60)

        pygame.quit()

    def _update(self):
        """Update animation state"""
        if self.playing and self.current_sequence:
            self.current_frame += 1

            if self.current_frame >= self.current_sequence.duration:
                if self.current_sequence.loop:
                    self.current_frame = 0
                else:
                    self.playing = False
                    self.current_frame = self.current_sequence.duration

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
                # Zoom timeline
                if pygame.key.get_mods() & pygame.KMOD_CTRL:
                    self.timeline_zoom *= 1.1 if event.y > 0 else 0.9
                    self.timeline_zoom = max(0.5, min(10.0, self.timeline_zoom))
                else:
                    self.sequence_scroll = max(
                        0, self.sequence_scroll - event.y * 30)

    def _handle_command_input(self, event):
        """Handle command input"""
        if event.key == pygame.K_ESCAPE:
            self.running = False

        # Playback
        elif event.key == pygame.K_SPACE:
            self.playing = not self.playing

        elif event.key == pygame.K_HOME:
            self.current_frame = 0
            self.playing = False

        elif event.key == pygame.K_END:
            if self.current_sequence:
                self.current_frame = self.current_sequence.duration
            self.playing = False

        elif event.key == pygame.K_LEFT:
            self.current_frame = max(0, self.current_frame - 1)
            self.playing = False

        elif event.key == pygame.K_RIGHT:
            if self.current_sequence:
                self.current_frame = min(
                    self.current_sequence.duration, self.current_frame + 1)
            self.playing = False

        # Save/Load
        elif event.key == pygame.K_s and pygame.key.get_mods() & pygame.KMOD_CTRL:
            self.database.save_json("animations.json")
            print("Animations saved to animations.json")

        elif event.key == pygame.K_o and pygame.key.get_mods() & pygame.KMOD_CTRL:
            try:
                self.database.load_json("animations.json")
                print("Animations loaded from animations.json")
            except FileNotFoundError:
                print("No animations.json file found")

        # Navigation
        elif event.key == pygame.K_UP:
            seq_ids = sorted(self.database.sequences.keys())
            if self.selected_sequence_id in seq_ids:
                idx = seq_ids.index(self.selected_sequence_id)
                if idx > 0:
                    self.selected_sequence_id = seq_ids[idx - 1]
                    self.current_sequence = self.database.sequences[self.selected_sequence_id]
                    self.current_frame = 0
                    self.playing = False

        elif event.key == pygame.K_DOWN:
            seq_ids = sorted(self.database.sequences.keys())
            if self.selected_sequence_id in seq_ids:
                idx = seq_ids.index(self.selected_sequence_id)
                if idx < len(seq_ids) - 1:
                    self.selected_sequence_id = seq_ids[idx + 1]
                    self.current_sequence = self.database.sequences[self.selected_sequence_id]
                    self.current_frame = 0
                    self.playing = False

    def _handle_mouse_click(self, pos: Tuple[int, int], button: int):
        """Handle mouse click"""
        x, y = pos

        # Check sequence list
        if x < 250 and button == 1:
            y_offset = 80 - self.sequence_scroll

            for seq_id in sorted(self.database.sequences.keys()):
                if y_offset <= y < y_offset + 50:
                    self.current_sequence = self.database.sequences[seq_id]
                    self.selected_sequence_id = seq_id
                    self.current_frame = 0
                    self.playing = False
                    break
                y_offset += 55

        # Check timeline for frame selection
        if 250 < x < self.width - 400 and self.height - 250 < y < self.height - 50:
            timeline_x = x - 300
            frame = int((timeline_x + self.timeline_scroll) / self.timeline_zoom)
            if self.current_sequence and 0 <= frame <= self.current_sequence.duration:
                self.current_frame = frame
                self.playing = False

    def _render(self):
        """Render editor"""
        self.screen.fill((25, 25, 35))

        # Draw sequence list
        self._draw_sequence_list()

        # Draw preview area
        self._draw_preview_area()

        # Draw timeline
        self._draw_timeline()

        # Draw properties panel
        self._draw_properties_panel()

        # Draw toolbar
        self._draw_toolbar()

        pygame.display.flip()

    def _draw_sequence_list(self):
        """Draw sequence list panel"""
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
        title = self.font.render("Sequences", True, (255, 255, 255))
        self.screen.blit(title, (panel_x + 10, panel_y + 10))

        # Sequence list
        y_offset = panel_y + 50 - self.sequence_scroll

        for seq_id in sorted(self.database.sequences.keys()):
            seq = self.database.sequences[seq_id]

            if y_offset + 50 < panel_y or y_offset > panel_y + panel_height:
                y_offset += 55
                continue

            # Background
            bg_color = (60, 60, 80) if seq_id == self.selected_sequence_id else (
                45, 45, 55)
            pygame.draw.rect(self.screen, bg_color,
                             (panel_x + 5, y_offset, panel_width - 10, 50))
            pygame.draw.rect(self.screen, (100, 100, 120),
                             (panel_x + 5, y_offset, panel_width - 10, 50), 1)

            # Sequence ID
            id_text = self.small_font.render(
                f"#{seq_id}", True, (180, 180, 180))
            self.screen.blit(id_text, (panel_x + 10, y_offset + 5))

            # Sequence name
            name_text = self.small_font.render(
                seq.name, True, (200, 200, 255))
            self.screen.blit(name_text, (panel_x + 10, y_offset + 25))

            # Duration and tracks
            info = f"{seq.duration}f | {len(seq.tracks)} tracks"
            info_text = self.small_font.render(info, True, (150, 150, 150))
            self.screen.blit(info_text, (panel_x + 10, y_offset + 42))

            y_offset += 55

    def _draw_preview_area(self):
        """Draw animation preview area"""
        preview_x = 250
        preview_y = 50
        preview_width = self.width - 650
        preview_height = self.height - 300

        # Background
        pygame.draw.rect(self.screen, (20, 20, 30),
                         (preview_x, preview_y, preview_width, preview_height))
        pygame.draw.rect(self.screen, (80, 80, 100),
                         (preview_x, preview_y, preview_width, preview_height), 2)

        if not self.current_sequence:
            return

        # Draw grid
        grid_spacing = 50
        for x in range(preview_x, preview_x + preview_width, grid_spacing):
            pygame.draw.line(self.screen, (40, 40, 50),
                             (x, preview_y), (x, preview_y + preview_height), 1)
        for y in range(preview_y, preview_y + preview_height, grid_spacing):
            pygame.draw.line(self.screen, (40, 40, 50),
                             (preview_x, y), (preview_x + preview_width, y), 1)

        # Render current frame state
        for track in self.current_sequence.tracks:
            if not track.enabled:
                continue

            if track.track_type == TrackType.SPRITE:
                self._render_sprite_preview(track, preview_x, preview_y)
            elif track.track_type == TrackType.CAMERA:
                self._render_camera_preview(track, preview_x, preview_y)
            elif track.track_type == TrackType.EFFECT:
                self._render_effect_preview(track, preview_x, preview_y)
            elif track.track_type == TrackType.DIALOG:
                self._render_dialog_preview(track, preview_x, preview_y, preview_width)

    def _render_sprite_preview(self, track: Track, offset_x: int, offset_y: int):
        """Render sprite at current frame"""
        position = track.get_value_at_frame(self.current_frame, "position")
        if not position:
            return

        x, y = position
        x += offset_x
        y += offset_y

        # Draw simple sprite placeholder
        pygame.draw.rect(self.screen, (100, 200, 255),
                         (int(x) - 16, int(y) - 16, 32, 32))
        pygame.draw.rect(self.screen, (255, 255, 255),
                         (int(x) - 16, int(y) - 16, 32, 32), 2)

        # Draw sprite name
        name_surf = self.small_font.render(
            track.name, True, (255, 255, 255))
        self.screen.blit(name_surf, (int(x) - 20, int(y) - 30))

    def _render_camera_preview(self, track: Track, offset_x: int, offset_y: int):
        """Render camera visualization"""
        position = track.get_value_at_frame(self.current_frame, "position")
        zoom = track.get_value_at_frame(self.current_frame, "zoom")

        if position:
            x, y = position
            x += offset_x + 50
            y += offset_y + 50

            # Draw camera indicator
            size = 40 if zoom else 40
            if zoom:
                size = int(40 * zoom)

            pygame.draw.circle(self.screen, (255, 200, 100),
                               (int(x), int(y)), size, 2)
            pygame.draw.line(self.screen, (255, 200, 100),
                             (int(x) - size, int(y)),
                             (int(x) + size, int(y)), 2)
            pygame.draw.line(self.screen, (255, 200, 100),
                             (int(x), int(y) - size),
                             (int(x), int(y) + size), 2)

    def _render_effect_preview(self, track: Track, offset_x: int, offset_y: int):
        """Render effect overlay"""
        effect = track.get_value_at_frame(self.current_frame, "effect")
        if effect:
            effect_text = self.font.render(
                f"Effect: {effect}", True, (255, 100, 100))
            self.screen.blit(effect_text, (offset_x + 20, offset_y + 20))

    def _render_dialog_preview(
        self,
        track: Track,
        offset_x: int,
        offset_y: int,
        width: int
    ):
        """Render dialog text"""
        text = track.get_value_at_frame(self.current_frame, "text")
        speaker = track.get_value_at_frame(self.current_frame, "speaker")

        if text:
            # Dialog box
            box_y = offset_y + 400
            pygame.draw.rect(self.screen, (40, 40, 60),
                             (offset_x + 20, box_y, width - 40, 100))
            pygame.draw.rect(self.screen, (100, 100, 150),
                             (offset_x + 20, box_y, width - 40, 100), 2)

            # Speaker
            if speaker:
                speaker_surf = self.small_font.render(
                    speaker, True, (200, 200, 255))
                self.screen.blit(speaker_surf, (offset_x + 30, box_y + 10))

            # Text
            text_surf = self.small_font.render(text, True, (255, 255, 255))
            self.screen.blit(text_surf, (offset_x + 30, box_y + 35))

    def _draw_timeline(self):
        """Draw timeline panel"""
        timeline_x = 250
        timeline_y = self.height - 250
        timeline_width = self.width - 650
        timeline_height = 200

        # Background
        pygame.draw.rect(self.screen, (30, 30, 40),
                         (timeline_x, timeline_y, timeline_width, timeline_height))
        pygame.draw.rect(self.screen, (80, 80, 100),
                         (timeline_x, timeline_y, timeline_width, timeline_height), 2)

        if not self.current_sequence:
            return

        # Draw frame ruler
        ruler_y = timeline_y + 20
        frame_interval = max(1, int(20 / self.timeline_zoom))

        for frame in range(0, self.current_sequence.duration + 1, frame_interval):
            x = timeline_x + 50 + int(frame * self.timeline_zoom) - self.timeline_scroll

            if timeline_x < x < timeline_x + timeline_width:
                pygame.draw.line(self.screen, (100, 100, 120),
                                 (x, ruler_y), (x, ruler_y + 10), 1)

                if frame % (frame_interval * 5) == 0:
                    frame_text = self.small_font.render(
                        str(frame), True, (150, 150, 150))
                    self.screen.blit(frame_text, (x - 10, ruler_y - 15))

        # Draw tracks
        track_y = timeline_y + 40
        track_height = 30

        for track in self.current_sequence.tracks:
            # Track background
            track_color = (45, 45, 60) if track == self.selected_track else (
                35, 35, 50)
            pygame.draw.rect(self.screen, track_color,
                             (timeline_x, track_y, timeline_width, track_height))
            pygame.draw.rect(self.screen, (80, 80, 100),
                             (timeline_x, track_y, timeline_width, track_height), 1)

            # Track name
            name_surf = self.small_font.render(
                track.name, True, (200, 200, 200))
            self.screen.blit(name_surf, (timeline_x + 5, track_y + 7))

            # Draw keyframes
            for keyframe in track.keyframes:
                kf_x = timeline_x + 50 + \
                    int(keyframe.frame * self.timeline_zoom) - self.timeline_scroll

                if timeline_x < kf_x < timeline_x + timeline_width:
                    kf_color = (255, 255, 100) if keyframe == self.selected_keyframe else (
                        100, 200, 255)
                    pygame.draw.circle(self.screen, kf_color,
                                       (kf_x, track_y + track_height // 2), 5)

            track_y += track_height + 5

        # Draw playhead
        playhead_x = timeline_x + 50 + \
            int(self.current_frame * self.timeline_zoom) - self.timeline_scroll
        pygame.draw.line(self.screen, (255, 100, 100),
                         (playhead_x, timeline_y),
                         (playhead_x, timeline_y + timeline_height), 2)

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

        if not self.current_sequence:
            return

        # Title
        title = self.font.render("Properties", True, (255, 255, 255))
        self.screen.blit(title, (panel_x + 10, panel_y + 10))

        # Sequence info
        y_offset = panel_y + 45

        info_items = [
            ("Name", self.current_sequence.name),
            ("Duration", f"{self.current_sequence.duration} frames"),
            ("Current Frame", str(self.current_frame)),
            ("Tracks", str(len(self.current_sequence.tracks))),
            ("Loop", "Yes" if self.current_sequence.loop else "No"),
            ("Playing", "Yes" if self.playing else "No"),
        ]

        for label, value in info_items:
            label_surf = self.small_font.render(
                f"{label}:", True, (200, 200, 200))
            self.screen.blit(label_surf, (panel_x + 20, y_offset))

            value_surf = self.small_font.render(
                value, True, (150, 150, 150))
            self.screen.blit(value_surf, (panel_x + 150, y_offset))

            y_offset += 25

        # Selected keyframe properties
        if self.selected_keyframe:
            y_offset += 20
            kf_title = self.font.render(
                "Keyframe", True, (200, 200, 255))
            self.screen.blit(kf_title, (panel_x + 10, y_offset))
            y_offset += 30

            frame_text = self.small_font.render(
                f"Frame: {self.selected_keyframe.frame}", True, (180, 180, 180))
            self.screen.blit(frame_text, (panel_x + 20, y_offset))
            y_offset += 25

            interp_text = self.small_font.render(
                f"Interpolation: {self.selected_keyframe.interpolation.value}",
                True, (180, 180, 180))
            self.screen.blit(interp_text, (panel_x + 20, y_offset))
            y_offset += 30

            # Properties
            props_label = self.small_font.render(
                "Properties:", True, (200, 200, 200))
            self.screen.blit(props_label, (panel_x + 20, y_offset))
            y_offset += 25

            for key, value in self.selected_keyframe.properties.items():
                prop_text = self.small_font.render(
                    f"  {key}: {value}", True, (150, 150, 150))
                self.screen.blit(prop_text, (panel_x + 20, y_offset))
                y_offset += 20

    def _draw_toolbar(self):
        """Draw top toolbar"""
        toolbar_height = 40
        pygame.draw.rect(self.screen, (45, 45, 55),
                         (0, 0, self.width, toolbar_height))
        pygame.draw.rect(self.screen, (80, 80, 100),
                         (0, 0, self.width, toolbar_height), 2)

        # Title
        if self.current_sequence:
            title = self.font.render(
                f"Sequence: {self.current_sequence.name}", True, (255, 255, 255))
            self.screen.blit(title, (10, 10))

        # Instructions
        help_text = "Space:Play/Pause | Home:Start | End:End | ←→:Frame | Ctrl+S:Save | Ctrl+O:Load"
        help_surf = self.small_font.render(help_text, True, (180, 180, 180))
        self.screen.blit(help_surf, (350, 12))


def main():
    """Run animation sequence editor"""
    editor = AnimationSequenceEditor()
    editor.run()


if __name__ == "__main__":
    main()
