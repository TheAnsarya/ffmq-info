"""
Advanced Palette Library for Final Fantasy Mystic Quest
Palette sharing, batch operations, and color analysis tools.
"""

import pygame
import json
from dataclasses import dataclass, asdict
from typing import List, Tuple, Optional, Set
from pathlib import Path

# Initialize Pygame
pygame.init()

# Constants
WINDOW_WIDTH = 1600
WINDOW_HEIGHT = 900
FPS = 60

# Colors
COLOR_BG = (30, 30, 40)
COLOR_PANEL_BG = (45, 45, 55)
COLOR_BORDER = (80, 80, 90)
COLOR_TEXT = (220, 220, 230)
COLOR_HIGHLIGHT = (100, 150, 255)
COLOR_SUCCESS = (100, 255, 100)
COLOR_WARNING = (255, 200, 100)
COLOR_ERROR = (255, 100, 100)
COLOR_SELECTED = (255, 200, 50)

# UI Constants
PALETTE_SWATCH_SIZE = 40
PALETTE_PADDING = 10
COLOR_PREVIEW_SIZE = 30


@dataclass
class Color:
    """RGB color with conversion utilities"""
    r: int  # 0-255
    g: int  # 0-255
    b: int  # 0-255

    def to_bgr555(self) -> int:
        """Convert to SNES BGR555 format"""
        b5 = (self.b >> 3) & 0x1F
        g5 = (self.g >> 3) & 0x1F
        r5 = (self.r >> 3) & 0x1F
        return (b5 << 10) | (g5 << 5) | r5

    @staticmethod
    def from_bgr555(bgr555: int) -> 'Color':
        """Convert from SNES BGR555 format"""
        r5 = (bgr555 & 0x1F)
        g5 = (bgr555 >> 5) & 0x1F
        b5 = (bgr555 >> 10) & 0x1F

        # Scale to 8-bit
        r = (r5 << 3) | (r5 >> 2)
        g = (g5 << 3) | (g5 >> 2)
        b = (b5 << 3) | (b5 >> 2)

        return Color(r, g, b)

    def to_tuple(self) -> Tuple[int, int, int]:
        """Get as RGB tuple for pygame"""
        return (self.r, self.g, self.b)

    def to_hex(self) -> str:
        """Get as hex string"""
        return f"#{self.r:02X}{self.g:02X}{self.b:02X}"

    def distance_to(self, other: 'Color') -> float:
        """Calculate color distance (Euclidean)"""
        dr = self.r - other.r
        dg = self.g - other.g
        db = self.b - other.b
        return (dr*dr + dg*dg + db*db) ** 0.5

    def luminance(self) -> float:
        """Calculate perceived luminance (0-255)"""
        return 0.299 * self.r + 0.587 * self.g + 0.114 * self.b


@dataclass
class Palette:
    """16-color SNES palette"""
    palette_id: int
    name: str
    colors: List[Color]
    category: str = "General"
    tags: List[str] = None

    def __post_init__(self):
        if self.tags is None:
            self.tags = []
        # Ensure exactly 16 colors
        while len(self.colors) < 16:
            self.colors.append(Color(0, 0, 0))
        self.colors = self.colors[:16]

    def copy(self) -> 'Palette':
        """Create a deep copy"""
        return Palette(
            palette_id=self.palette_id,
            name=self.name,
            colors=[Color(c.r, c.g, c.b) for c in self.colors],
            category=self.category,
            tags=self.tags.copy()
        )

    def find_closest_color(self, target: Color) -> int:
        """Find index of closest color to target"""
        min_dist = float('inf')
        closest_idx = 0

        for i, color in enumerate(self.colors):
            dist = color.distance_to(target)
            if dist < min_dist:
                min_dist = dist
                closest_idx = i

        return closest_idx

    def sort_by_luminance(self):
        """Sort colors by luminance (dark to light)"""
        self.colors.sort(key=lambda c: c.luminance())

    def sort_by_hue(self):
        """Sort colors by hue"""
        import colorsys

        def get_hue(color: Color):
            h, s, v = colorsys.rgb_to_hsv(color.r/255, color.g/255, color.b/255)
            return h

        self.colors.sort(key=get_hue)

    def to_dict(self):
        """Export to dictionary"""
        return {
            'palette_id': self.palette_id,
            'name': self.name,
            'category': self.category,
            'tags': self.tags,
            'colors': [c.to_hex() for c in self.colors]
        }


class PaletteSwatch:
    """Visual palette swatch with 16 colors"""
    def __init__(self, x, y, palette: Palette):
        self.rect = pygame.Rect(x, y, PALETTE_SWATCH_SIZE * 8 + PALETTE_PADDING * 2, PALETTE_SWATCH_SIZE * 2 + PALETTE_PADDING * 2 + 25)
        self.palette = palette
        self.selected = False
        self.hovered = False

    def draw(self, screen, font, small_font):
        # Background
        bg_color = COLOR_SELECTED if self.selected else (COLOR_HIGHLIGHT if self.hovered else COLOR_PANEL_BG)
        pygame.draw.rect(screen, bg_color, self.rect)
        pygame.draw.rect(screen, COLOR_BORDER, self.rect, 2 if not self.selected else 3)

        # Palette name
        name_text = small_font.render(self.palette.name[:20], True, COLOR_TEXT)
        screen.blit(name_text, (self.rect.x + 5, self.rect.y + 5))

        # Colors (2 rows of 8)
        for i, color in enumerate(self.palette.colors):
            row = i // 8
            col = i % 8
            x = self.rect.x + PALETTE_PADDING + col * PALETTE_SWATCH_SIZE
            y = self.rect.y + 25 + PALETTE_PADDING + row * PALETTE_SWATCH_SIZE

            color_rect = pygame.Rect(x, y, PALETTE_SWATCH_SIZE - 2, PALETTE_SWATCH_SIZE - 2)
            pygame.draw.rect(screen, color.to_tuple(), color_rect)
            pygame.draw.rect(screen, COLOR_BORDER, color_rect, 1)

    def contains_point(self, pos):
        return self.rect.collidepoint(pos)


class Button:
    """Interactive button"""
    def __init__(self, x, y, width, height, text, callback, enabled=True):
        self.rect = pygame.Rect(x, y, width, height)
        self.text = text
        self.callback = callback
        self.enabled = enabled
        self.hovered = False

    def draw(self, screen, font):
        if not self.enabled:
            color = (60, 60, 70)
            text_color = (100, 100, 110)
        else:
            color = COLOR_HIGHLIGHT if self.hovered else COLOR_BORDER
            text_color = COLOR_TEXT

        pygame.draw.rect(screen, COLOR_PANEL_BG, self.rect)
        pygame.draw.rect(screen, color, self.rect, 2)

        text_surf = font.render(self.text, True, text_color)
        text_rect = text_surf.get_rect(center=self.rect.center)
        screen.blit(text_surf, text_rect)

    def handle_event(self, event):
        if not self.enabled:
            return False

        if event.type == pygame.MOUSEMOTION:
            self.hovered = self.rect.collidepoint(event.pos)
        elif event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
            if self.rect.collidepoint(event.pos):
                self.callback()
                return True
        return False


class ColorOperationsPanel:
    """Panel for color operations on selected palette"""
    def __init__(self, x, y, width, height):
        self.rect = pygame.Rect(x, y, width, height)
        self.target_palette: Optional[Palette] = None

    def set_palette(self, palette: Optional[Palette]):
        self.target_palette = palette

    def draw(self, screen, font, small_font):
        # Background
        pygame.draw.rect(screen, COLOR_PANEL_BG, self.rect)
        pygame.draw.rect(screen, COLOR_BORDER, self.rect, 2)

        # Title
        title = font.render("Palette Operations", True, COLOR_TEXT)
        screen.blit(title, (self.rect.x + 10, self.rect.y + 10))

        if not self.target_palette:
            no_sel = small_font.render("No palette selected", True, (150, 150, 150))
            screen.blit(no_sel, (self.rect.x + 10, self.rect.y + 50))
            return

        # Palette info
        y = self.rect.y + 50
        info_lines = [
            f"ID: {self.target_palette.palette_id}",
            f"Name: {self.target_palette.name}",
            f"Category: {self.target_palette.category}",
            f"Colors: {len(self.target_palette.colors)}",
        ]

        for line in info_lines:
            text = small_font.render(line, True, COLOR_TEXT)
            screen.blit(text, (self.rect.x + 10, y))
            y += 22


class PaletteLibraryPanel:
    """Panel showing palette library with filtering"""
    def __init__(self, x, y, width, height):
        self.rect = pygame.Rect(x, y, width, height)
        self.scroll_y = 0
        self.swatches: List[PaletteSwatch] = []
        self.selected_swatch: Optional[PaletteSwatch] = None

    def set_palettes(self, palettes: List[Palette]):
        """Update palette swatches"""
        self.swatches = []

        # Calculate layout (2 columns)
        col_width = (self.rect.width - 30) // 2
        swatch_width = PALETTE_SWATCH_SIZE * 8 + PALETTE_PADDING * 2

        x_offset = self.rect.x + 10
        y_offset = self.rect.y + 50

        for i, palette in enumerate(palettes):
            col = i % 2
            row = i // 2

            x = x_offset + col * (col_width + 10)
            y = y_offset + row * 100

            swatch = PaletteSwatch(x, y, palette)
            self.swatches.append(swatch)

    def draw(self, screen, font, small_font):
        # Background
        pygame.draw.rect(screen, COLOR_PANEL_BG, self.rect)
        pygame.draw.rect(screen, COLOR_BORDER, self.rect, 2)

        # Title
        title = font.render("Palette Library", True, COLOR_TEXT)
        screen.blit(title, (self.rect.x + 10, self.rect.y + 10))

        # Count
        count_text = small_font.render(f"{len(self.swatches)} palettes", True, (180, 180, 200))
        screen.blit(count_text, (self.rect.x + 10, self.rect.y + 32))

        # Clip to panel area
        clip_rect = pygame.Rect(self.rect.x, self.rect.y + 50, self.rect.width, self.rect.height - 50)
        screen.set_clip(clip_rect)

        # Draw swatches
        for swatch in self.swatches:
            # Apply scroll
            original_y = swatch.rect.y
            swatch.rect.y += self.scroll_y

            if swatch.rect.bottom > self.rect.y + 50 and swatch.rect.top < self.rect.bottom:
                swatch.draw(screen, font, small_font)

            swatch.rect.y = original_y

        screen.set_clip(None)

    def handle_click(self, pos):
        """Handle click in library"""
        adjusted_pos = (pos[0], pos[1] - self.scroll_y)

        for swatch in self.swatches:
            if swatch.contains_point(adjusted_pos):
                if self.selected_swatch:
                    self.selected_swatch.selected = False
                swatch.selected = True
                self.selected_swatch = swatch
                return swatch.palette

        return None

    def handle_hover(self, pos):
        """Handle mouse hover"""
        adjusted_pos = (pos[0], pos[1] - self.scroll_y)

        for swatch in self.swatches:
            swatch.hovered = swatch.contains_point(adjusted_pos)

    def scroll(self, amount):
        """Scroll the library"""
        self.scroll_y += amount
        # Clamp scroll
        max_scroll = max(0, len(self.swatches) * 100 - self.rect.height + 100)
        self.scroll_y = max(-max_scroll, min(0, self.scroll_y))


class ComparisonView:
    """Side-by-side palette comparison"""
    def __init__(self, x, y, width, height):
        self.rect = pygame.Rect(x, y, width, height)
        self.palette_a: Optional[Palette] = None
        self.palette_b: Optional[Palette] = None

    def set_palettes(self, palette_a: Optional[Palette], palette_b: Optional[Palette]):
        self.palette_a = palette_a
        self.palette_b = palette_b

    def draw(self, screen, font, small_font):
        # Background
        pygame.draw.rect(screen, COLOR_PANEL_BG, self.rect)
        pygame.draw.rect(screen, COLOR_BORDER, self.rect, 2)

        # Title
        title = font.render("Palette Comparison", True, COLOR_TEXT)
        screen.blit(title, (self.rect.x + 10, self.rect.y + 10))

        if not self.palette_a and not self.palette_b:
            msg = small_font.render("Select palettes to compare", True, (150, 150, 150))
            screen.blit(msg, (self.rect.x + 10, self.rect.y + 50))
            return

        # Draw palette A
        if self.palette_a:
            self._draw_palette_half(screen, small_font, self.palette_a,
                                   self.rect.x + 10, self.rect.y + 50, "Palette A")

        # Draw palette B
        if self.palette_b:
            self._draw_palette_half(screen, small_font, self.palette_b,
                                   self.rect.x + self.rect.width // 2 + 10, self.rect.y + 50, "Palette B")

        # Draw difference analysis if both palettes present
        if self.palette_a and self.palette_b:
            self._draw_difference_analysis(screen, small_font)

    def _draw_palette_half(self, screen, font, palette: Palette, x, y, label):
        """Draw one palette in comparison view"""
        # Label
        label_text = font.render(label, True, COLOR_TEXT)
        screen.blit(label_text, (x, y))

        # Name
        name_text = font.render(palette.name[:18], True, (180, 180, 200))
        screen.blit(name_text, (x, y + 22))

        # Colors
        color_y = y + 50
        for i, color in enumerate(palette.colors):
            row = i // 4
            col = i % 4

            color_x = x + col * (COLOR_PREVIEW_SIZE + 2)
            color_rect_y = color_y + row * (COLOR_PREVIEW_SIZE + 2)

            color_rect = pygame.Rect(color_x, color_rect_y, COLOR_PREVIEW_SIZE, COLOR_PREVIEW_SIZE)
            pygame.draw.rect(screen, color.to_tuple(), color_rect)
            pygame.draw.rect(screen, COLOR_BORDER, color_rect, 1)

    def _draw_difference_analysis(self, screen, font):
        """Draw analysis of differences between palettes"""
        if not self.palette_a or not self.palette_b:
            return

        # Count different colors
        different_count = 0
        total_distance = 0.0

        for color_a, color_b in zip(self.palette_a.colors, self.palette_b.colors):
            dist = color_a.distance_to(color_b)
            if dist > 5:  # Threshold for "different"
                different_count += 1
            total_distance += dist

        avg_distance = total_distance / 16

        # Draw analysis
        analysis_y = self.rect.bottom - 80

        lines = [
            f"Different colors: {different_count}/16",
            f"Avg distance: {avg_distance:.1f}",
            f"Similarity: {100 - (different_count / 16 * 100):.1f}%"
        ]

        for i, line in enumerate(lines):
            text = font.render(line, True, COLOR_TEXT)
            screen.blit(text, (self.rect.x + 10, analysis_y + i * 22))


class PaletteLibraryTool:
    """Advanced palette library and sharing tool"""
    def __init__(self):
        self.screen = pygame.display.set_mode((WINDOW_WIDTH, WINDOW_HEIGHT))
        pygame.display.set_caption("FFMQ Palette Library")
        self.clock = pygame.time.Clock()
        self.running = True

        # Fonts
        self.font = pygame.font.Font(None, 28)
        self.small_font = pygame.font.Font(None, 20)
        self.title_font = pygame.font.Font(None, 36)

        # Palettes
        self.palettes: List[Palette] = self._load_default_palettes()
        self.clipboard_palette: Optional[Palette] = None
        self.comparison_a: Optional[Palette] = None
        self.comparison_b: Optional[Palette] = None

        # UI Panels
        self.library_panel = PaletteLibraryPanel(10, 80, 700, 810)
        self.library_panel.set_palettes(self.palettes)

        self.operations_panel = ColorOperationsPanel(730, 80, 420, 300)

        self.comparison_view = ComparisonView(730, 400, 420, 300)

        # Buttons
        button_y = 720
        button_x = 730
        self.buttons = [
            Button(button_x, button_y, 200, 35, "Copy Palette", self.copy_palette),
            Button(button_x + 210, button_y, 200, 35, "Paste Palette", self.paste_palette),
            Button(button_x, button_y + 45, 200, 35, "Sort by Luminance", self.sort_luminance),
            Button(button_x + 210, button_y + 45, 200, 35, "Sort by Hue", self.sort_hue),
            Button(button_x, button_y + 90, 200, 35, "Compare A", self.set_compare_a),
            Button(button_x + 210, button_y + 90, 200, 35, "Compare B", self.set_compare_b),
            Button(button_x, button_y + 135, 200, 35, "Export JSON", self.export_json),
            Button(button_x + 210, button_y + 135, 200, 35, "Import JSON", self.import_json),
        ]

        # Status message
        self.status_message = ""
        self.status_color = COLOR_TEXT
        self.status_timer = 0

    def _load_default_palettes(self) -> List[Palette]:
        """Load some default/example palettes"""
        palettes = []

        # Hero palette
        hero_colors = [
            Color(0, 0, 0),        # Transparent
            Color(248, 208, 176),  # Skin highlight
            Color(216, 160, 120),  # Skin base
            Color(168, 120, 88),   # Skin shadow
            Color(200, 80, 40),    # Hair highlight
            Color(160, 48, 16),    # Hair base
            Color(120, 32, 8),     # Hair shadow
            Color(248, 248, 248),  # Armor highlight
            Color(200, 200, 200),  # Armor base
            Color(144, 144, 152),  # Armor shadow
            Color(80, 80, 88),     # Armor dark
            Color(248, 200, 80),   # Gold highlight
            Color(216, 152, 32),   # Gold base
            Color(168, 104, 16),   # Gold shadow
            Color(40, 40, 48),     # Outline
            Color(0, 0, 0),        # Black
        ]
        palettes.append(Palette(0, "Hero", hero_colors, "Character", ["main", "player"]))

        # Forest palette
        forest_colors = [
            Color(0, 0, 0),
            Color(144, 224, 120),  # Light green
            Color(96, 184, 80),    # Green
            Color(56, 136, 48),    # Dark green
            Color(32, 88, 32),     # Very dark green
            Color(168, 136, 80),   # Tree trunk light
            Color(120, 88, 56),    # Tree trunk
            Color(80, 56, 32),     # Tree trunk dark
            Color(248, 248, 168),  # Light yellow
            Color(216, 200, 104),  # Yellow
            Color(184, 152, 64),   # Dark yellow
            Color(136, 184, 248),  # Sky blue
            Color(88, 136, 200),   # Blue
            Color(56, 88, 144),    # Dark blue
            Color(48, 48, 56),     # Outline
            Color(0, 0, 0),
        ]
        palettes.append(Palette(1, "Forest", forest_colors, "Environment", ["nature", "overworld"]))

        # Fire palette
        fire_colors = [
            Color(0, 0, 0),
            Color(255, 255, 200),  # White hot
            Color(255, 248, 120),  # Yellow
            Color(255, 200, 64),   # Orange
            Color(255, 128, 32),   # Red-orange
            Color(224, 64, 16),    # Red
            Color(168, 32, 8),     # Dark red
            Color(96, 16, 8),      # Very dark red
            Color(248, 208, 144),  # Light gray
            Color(184, 152, 120),  # Gray
            Color(120, 96, 80),    # Dark gray
            Color(64, 48, 40),     # Very dark gray
            Color(255, 160, 96),   # Pink
            Color(200, 96, 56),    # Brown-red
            Color(40, 32, 32),     # Outline
            Color(0, 0, 0),
        ]
        palettes.append(Palette(2, "Fire Temple", fire_colors, "Environment", ["fire", "dungeon"]))

        # Water palette
        water_colors = [
            Color(0, 0, 0),
            Color(200, 232, 255),  # Very light blue
            Color(152, 200, 248),  # Light blue
            Color(104, 168, 232),  # Blue
            Color(64, 136, 208),   # Medium blue
            Color(32, 104, 176),   # Dark blue
            Color(16, 72, 136),    # Very dark blue
            Color(8, 40, 88),      # Deepest blue
            Color(176, 216, 192),  # Light cyan
            Color(120, 184, 160),  # Cyan
            Color(80, 144, 128),   # Dark cyan
            Color(248, 248, 248),  # White foam
            Color(216, 224, 232),  # Light gray
            Color(152, 176, 192),  # Gray
            Color(48, 56, 72),     # Outline
            Color(0, 0, 0),
        ]
        palettes.append(Palette(3, "Water Temple", water_colors, "Environment", ["water", "dungeon"]))

        # Enemy - Skeleton
        skeleton_colors = [
            Color(0, 0, 0),
            Color(248, 248, 240),  # Bone highlight
            Color(224, 224, 208),  # Bone light
            Color(192, 192, 176),  # Bone base
            Color(152, 152, 144),  # Bone shadow
            Color(104, 104, 96),   # Bone dark
            Color(72, 72, 64),     # Bone very dark
            Color(224, 64, 64),    # Red eyes
            Color(176, 32, 32),    # Dark red eyes
            Color(144, 96, 64),    # Rust highlight
            Color(104, 64, 40),    # Rust
            Color(64, 40, 24),     # Rust shadow
            Color(120, 88, 120),   # Purple
            Color(80, 56, 80),     # Dark purple
            Color(40, 40, 48),     # Outline
            Color(0, 0, 0),
        ]
        palettes.append(Palette(4, "Skeleton Enemy", skeleton_colors, "Enemy", ["undead", "monster"]))

        # Enemy - Slime
        slime_colors = [
            Color(0, 0, 0),
            Color(200, 248, 120),  # Slime highlight
            Color(152, 216, 80),   # Slime light
            Color(104, 184, 48),   # Slime base
            Color(64, 144, 32),    # Slime shadow
            Color(40, 104, 24),    # Slime dark
            Color(24, 64, 16),     # Slime very dark
            Color(248, 248, 200),  # Shine highlight
            Color(216, 216, 160),  # Shine
            Color(255, 200, 200),  # Pink highlight
            Color(224, 152, 152),  # Pink
            Color(96, 216, 248),   # Cyan eye
            Color(48, 168, 200),   # Eye shadow
            Color(32, 88, 32),     # Dark green
            Color(32, 48, 32),     # Outline
            Color(0, 0, 0),
        ]
        palettes.append(Palette(5, "Slime Enemy", slime_colors, "Enemy", ["slime", "monster"]))

        # Town palette
        town_colors = [
            Color(0, 0, 0),
            Color(248, 224, 192),  # Building light
            Color(216, 184, 144),  # Building base
            Color(176, 144, 104),  # Building shadow
            Color(128, 96, 64),    # Building dark
            Color(224, 88, 72),    # Roof light
            Color(184, 56, 48),    # Roof
            Color(136, 32, 32),    # Roof dark
            Color(168, 200, 248),  # Window light
            Color(104, 152, 216),  # Window
            Color(64, 104, 168),   # Window dark
            Color(144, 192, 104),  # Grass
            Color(96, 144, 72),    # Grass dark
            Color(184, 168, 120),  # Path
            Color(48, 48, 56),     # Outline
            Color(0, 0, 0),
        ]
        palettes.append(Palette(6, "Town Buildings", town_colors, "Environment", ["town", "building"]))

        # UI palette
        ui_colors = [
            Color(0, 0, 0),
            Color(248, 248, 248),  # White
            Color(216, 216, 216),  # Light gray
            Color(176, 176, 176),  # Gray
            Color(136, 136, 136),  # Dark gray
            Color(96, 96, 96),     # Very dark gray
            Color(56, 56, 56),     # Almost black
            Color(248, 216, 120),  # Gold highlight
            Color(216, 168, 64),   # Gold
            Color(168, 120, 32),   # Gold shadow
            Color(104, 168, 248),  # Blue highlight
            Color(64, 128, 216),   # Blue
            Color(32, 88, 168),    # Blue shadow
            Color(120, 200, 104),  # Green
            Color(40, 40, 48),     # Outline
            Color(0, 0, 0),
        ]
        palettes.append(Palette(7, "UI/Menu", ui_colors, "UI", ["interface", "menu"]))

        return palettes

    def copy_palette(self):
        """Copy selected palette to clipboard"""
        if self.library_panel.selected_swatch:
            self.clipboard_palette = self.library_panel.selected_swatch.palette.copy()
            self.show_status("Palette copied to clipboard", COLOR_SUCCESS)
        else:
            self.show_status("No palette selected", COLOR_WARNING)

    def paste_palette(self):
        """Paste clipboard palette over selected palette"""
        if not self.clipboard_palette:
            self.show_status("Clipboard is empty", COLOR_WARNING)
            return

        if not self.library_panel.selected_swatch:
            self.show_status("No target palette selected", COLOR_WARNING)
            return

        # Copy colors from clipboard to selected
        target = self.library_panel.selected_swatch.palette
        target.colors = [Color(c.r, c.g, c.b) for c in self.clipboard_palette.colors]
        self.show_status(f"Pasted colors to {target.name}", COLOR_SUCCESS)

    def sort_luminance(self):
        """Sort selected palette by luminance"""
        if self.library_panel.selected_swatch:
            self.library_panel.selected_swatch.palette.sort_by_luminance()
            self.show_status("Sorted by luminance", COLOR_SUCCESS)
        else:
            self.show_status("No palette selected", COLOR_WARNING)

    def sort_hue(self):
        """Sort selected palette by hue"""
        if self.library_panel.selected_swatch:
            self.library_panel.selected_swatch.palette.sort_by_hue()
            self.show_status("Sorted by hue", COLOR_SUCCESS)
        else:
            self.show_status("No palette selected", COLOR_WARNING)

    def set_compare_a(self):
        """Set comparison palette A"""
        if self.library_panel.selected_swatch:
            self.comparison_a = self.library_panel.selected_swatch.palette
            self.comparison_view.set_palettes(self.comparison_a, self.comparison_b)
            self.show_status("Set comparison A", COLOR_SUCCESS)
        else:
            self.show_status("No palette selected", COLOR_WARNING)

    def set_compare_b(self):
        """Set comparison palette B"""
        if self.library_panel.selected_swatch:
            self.comparison_b = self.library_panel.selected_swatch.palette
            self.comparison_view.set_palettes(self.comparison_a, self.comparison_b)
            self.show_status("Set comparison B", COLOR_SUCCESS)
        else:
            self.show_status("No palette selected", COLOR_WARNING)

    def export_json(self):
        """Export all palettes to JSON"""
        data = {
            'palettes': [p.to_dict() for p in self.palettes]
        }

        filename = 'palettes_export.json'
        with open(filename, 'w') as f:
            json.dump(data, f, indent=2)

        self.show_status(f"Exported to {filename}", COLOR_SUCCESS)

    def import_json(self):
        """Import palettes from JSON"""
        filename = 'palettes_import.json'
        try:
            with open(filename, 'r') as f:
                data = json.load(f)

            # Parse palettes
            imported = 0
            for pal_data in data.get('palettes', []):
                colors = []
                for hex_color in pal_data.get('colors', []):
                    # Parse hex color
                    hex_color = hex_color.lstrip('#')
                    r = int(hex_color[0:2], 16)
                    g = int(hex_color[2:4], 16)
                    b = int(hex_color[4:6], 16)
                    colors.append(Color(r, g, b))

                palette = Palette(
                    palette_id=pal_data.get('palette_id', len(self.palettes)),
                    name=pal_data.get('name', f"Imported {len(self.palettes)}"),
                    colors=colors,
                    category=pal_data.get('category', 'Imported'),
                    tags=pal_data.get('tags', [])
                )
                self.palettes.append(palette)
                imported += 1

            self.library_panel.set_palettes(self.palettes)
            self.show_status(f"Imported {imported} palettes", COLOR_SUCCESS)

        except FileNotFoundError:
            self.show_status(f"File not found: {filename}", COLOR_ERROR)
        except Exception as e:
            self.show_status(f"Import error: {str(e)}", COLOR_ERROR)

    def show_status(self, message: str, color):
        """Show status message"""
        self.status_message = message
        self.status_color = color
        self.status_timer = FPS * 3  # 3 seconds

    def handle_events(self):
        """Handle input events"""
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                self.running = False

            # Handle buttons
            for button in self.buttons:
                if button.handle_event(event):
                    continue

            # Mouse events
            if event.type == pygame.MOUSEBUTTONDOWN:
                if event.button == 1:  # Left click
                    if self.library_panel.rect.collidepoint(event.pos):
                        selected = self.library_panel.handle_click(event.pos)
                        if selected:
                            self.operations_panel.set_palette(selected)

                elif event.button == 4:  # Scroll up
                    if self.library_panel.rect.collidepoint(event.pos):
                        self.library_panel.scroll(30)
                elif event.button == 5:  # Scroll down
                    if self.library_panel.rect.collidepoint(event.pos):
                        self.library_panel.scroll(-30)

            elif event.type == pygame.MOUSEMOTION:
                if self.library_panel.rect.collidepoint(event.pos):
                    self.library_panel.handle_hover(event.pos)

            # Keyboard shortcuts
            elif event.type == pygame.KEYDOWN:
                if event.key == pygame.K_ESCAPE:
                    self.running = False
                elif event.key == pygame.K_c and (event.mod & pygame.KMOD_CTRL):
                    self.copy_palette()
                elif event.key == pygame.K_v and (event.mod & pygame.KMOD_CTRL):
                    self.paste_palette()
                elif event.key == pygame.K_e and (event.mod & pygame.KMOD_CTRL):
                    self.export_json()
                elif event.key == pygame.K_i and (event.mod & pygame.KMOD_CTRL):
                    self.import_json()

    def draw(self):
        """Draw the manager"""
        self.screen.fill(COLOR_BG)

        # Title bar
        title_bg = pygame.Rect(0, 0, WINDOW_WIDTH, 70)
        pygame.draw.rect(self.screen, COLOR_PANEL_BG, title_bg)
        pygame.draw.line(self.screen, COLOR_BORDER, (0, 70), (WINDOW_WIDTH, 70), 2)

        title = self.title_font.render("Palette Library", True, COLOR_TEXT)
        self.screen.blit(title, (20, 20))

        # Status message
        if self.status_timer > 0:
            status_text = self.small_font.render(self.status_message, True, self.status_color)
            self.screen.blit(status_text, (WINDOW_WIDTH - status_text.get_width() - 20, 25))
            self.status_timer -= 1

        # Draw panels
        self.library_panel.draw(self.screen, self.font, self.small_font)
        self.operations_panel.draw(self.screen, self.font, self.small_font)
        self.comparison_view.draw(self.screen, self.font, self.small_font)

        # Draw buttons
        for button in self.buttons:
            button.draw(self.screen, self.small_font)

        pygame.display.flip()

    def run(self):
        """Main loop"""
        while self.running:
            self.handle_events()
            self.draw()
            self.clock.tick(FPS)

        pygame.quit()


def main():
    """Entry point"""
    tool = PaletteLibraryTool()
    tool.run()


if __name__ == '__main__':
    main()
