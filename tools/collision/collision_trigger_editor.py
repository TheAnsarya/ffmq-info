#!/usr/bin/env python3
"""
Collision and Trigger Editor

Comprehensive collision map and trigger zone editing tool.
Features include:
- Collision layer editing
- Trigger zone placement
- Event triggers
- Area properties
- Tile properties
- Walkability editing
- Visual layer editing
- Export to game format

Collision Types:
- Solid: Blocks movement
- Passable: Can walk through
- One-way: Directional blocking
- Water: Requires swimming
- Ladder: Climbing
- Ice: Slippery surface
- Damage: Hurts player
- Warp: Teleport trigger

Trigger Types:
- Step: Activated by stepping
- Touch: Activated by touching
- Action: Requires button press
- Proximity: Activated when near
- Timed: Auto-activates
"""

from dataclasses import dataclass, field
from enum import Enum
from typing import Dict, List, Optional, Tuple, Any, Set
import pygame
import json


class CollisionType(Enum):
    """Collision tile types"""
    PASSABLE = "passable"
    SOLID = "solid"
    ONE_WAY_UP = "one_way_up"
    ONE_WAY_DOWN = "one_way_down"
    ONE_WAY_LEFT = "one_way_left"
    ONE_WAY_RIGHT = "one_way_right"
    WATER = "water"
    LADDER = "ladder"
    ICE = "ice"
    DAMAGE = "damage"
    WARP = "warp"


class TriggerType(Enum):
    """Trigger activation types"""
    STEP = "step"
    TOUCH = "touch"
    ACTION = "action"
    PROXIMITY = "proximity"
    TIMED = "timed"


@dataclass
class TriggerZone:
    """Trigger zone definition"""
    trigger_id: int
    name: str
    trigger_type: TriggerType
    position: Tuple[int, int]  # Top-left corner (tile coordinates)
    size: Tuple[int, int]  # Width, height in tiles
    event_id: int = 0
    script_id: int = 0
    enabled: bool = True
    one_time: bool = False
    requires_flag: Optional[str] = None
    proximity_range: int = 2  # For proximity triggers
    timer_interval: float = 1.0  # For timed triggers (seconds)
    
    def contains_tile(self, tx: int, ty: int) -> bool:
        """Check if tile is within trigger zone"""
        x, y = self.position
        w, h = self.size
        return x <= tx < x + w and y <= ty < y + h
    
    def to_dict(self) -> dict:
        """Convert to dictionary"""
        return {
            "trigger_id": self.trigger_id,
            "name": self.name,
            "trigger_type": self.trigger_type.value,
            "position": self.position,
            "size": self.size,
            "event_id": self.event_id,
            "script_id": self.script_id,
            "enabled": self.enabled,
            "one_time": self.one_time,
            "requires_flag": self.requires_flag,
            "proximity_range": self.proximity_range,
            "timer_interval": self.timer_interval,
        }
    
    @staticmethod
    def from_dict(data: dict) -> 'TriggerZone':
        """Create from dictionary"""
        return TriggerZone(
            trigger_id=data["trigger_id"],
            name=data["name"],
            trigger_type=TriggerType(data["trigger_type"]),
            position=tuple(data["position"]),
            size=tuple(data["size"]),
            event_id=data.get("event_id", 0),
            script_id=data.get("script_id", 0),
            enabled=data.get("enabled", True),
            one_time=data.get("one_time", False),
            requires_flag=data.get("requires_flag"),
            proximity_range=data.get("proximity_range", 2),
            timer_interval=data.get("timer_interval", 1.0),
        )


@dataclass
class CollisionMap:
    """Collision and trigger map"""
    map_id: int
    name: str
    width: int = 50
    height: int = 50
    tile_size: int = 16
    collision_data: List[List[CollisionType]] = field(default_factory=list)
    trigger_zones: List[TriggerZone] = field(default_factory=list)
    
    def __post_init__(self):
        """Initialize collision data"""
        if not self.collision_data:
            self.collision_data = [
                [CollisionType.PASSABLE for _ in range(self.width)]
                for _ in range(self.height)
            ]
    
    def set_collision(self, x: int, y: int, collision_type: CollisionType):
        """Set collision type at tile"""
        if 0 <= y < self.height and 0 <= x < self.width:
            self.collision_data[y][x] = collision_type
    
    def get_collision(self, x: int, y: int) -> CollisionType:
        """Get collision type at tile"""
        if 0 <= y < self.height and 0 <= x < self.width:
            return self.collision_data[y][x]
        return CollisionType.SOLID
    
    def fill_rect(self, x: int, y: int, w: int, h: int, collision_type: CollisionType):
        """Fill rectangle with collision type"""
        for ty in range(y, min(y + h, self.height)):
            for tx in range(x, min(x + w, self.width)):
                self.set_collision(tx, ty, collision_type)
    
    def get_trigger_at(self, x: int, y: int) -> Optional[TriggerZone]:
        """Get trigger zone containing tile"""
        for trigger in self.trigger_zones:
            if trigger.contains_tile(x, y):
                return trigger
        return None
    
    def to_dict(self) -> dict:
        """Convert to dictionary"""
        return {
            "map_id": self.map_id,
            "name": self.name,
            "width": self.width,
            "height": self.height,
            "tile_size": self.tile_size,
            "collision_data": [
                [tile.value for tile in row]
                for row in self.collision_data
            ],
            "trigger_zones": [t.to_dict() for t in self.trigger_zones],
        }
    
    @staticmethod
    def from_dict(data: dict) -> 'CollisionMap':
        """Create from dictionary"""
        cmap = CollisionMap(
            map_id=data["map_id"],
            name=data["name"],
            width=data.get("width", 50),
            height=data.get("height", 50),
            tile_size=data.get("tile_size", 16),
        )
        
        # Load collision data
        if "collision_data" in data:
            cmap.collision_data = [
                [CollisionType(tile) for tile in row]
                for row in data["collision_data"]
            ]
        
        # Load triggers
        cmap.trigger_zones = [
            TriggerZone.from_dict(t)
            for t in data.get("trigger_zones", [])
        ]
        
        return cmap


class CollisionMapDatabase:
    """Database of collision maps"""
    
    def __init__(self):
        self.maps: Dict[int, CollisionMap] = {}
        self._init_sample_data()
    
    def _init_sample_data(self):
        """Initialize sample collision map"""
        # Simple test map
        test_map = CollisionMap(
            map_id=1,
            name="Test Map",
            width=30,
            height=20,
            tile_size=16,
        )
        
        # Create walls around border
        for x in range(test_map.width):
            test_map.set_collision(x, 0, CollisionType.SOLID)
            test_map.set_collision(x, test_map.height - 1, CollisionType.SOLID)
        
        for y in range(test_map.height):
            test_map.set_collision(0, y, CollisionType.SOLID)
            test_map.set_collision(test_map.width - 1, y, CollisionType.SOLID)
        
        # Add some obstacles
        test_map.fill_rect(10, 5, 5, 3, CollisionType.SOLID)
        test_map.fill_rect(15, 10, 3, 5, CollisionType.SOLID)
        
        # Water area
        test_map.fill_rect(5, 12, 4, 4, CollisionType.WATER)
        
        # Ladder
        test_map.fill_rect(25, 5, 1, 5, CollisionType.LADDER)
        
        # Damage tiles
        test_map.fill_rect(20, 15, 3, 2, CollisionType.DAMAGE)
        
        # Warp tile
        test_map.set_collision(15, 15, CollisionType.WARP)
        
        # Add trigger zones
        test_map.trigger_zones.append(TriggerZone(
            trigger_id=1,
            name="Door Trigger",
            trigger_type=TriggerType.STEP,
            position=(10, 10),
            size=(2, 1),
            event_id=1,
        ))
        
        test_map.trigger_zones.append(TriggerZone(
            trigger_id=2,
            name="Treasure Chest",
            trigger_type=TriggerType.ACTION,
            position=(20, 5),
            size=(1, 1),
            event_id=2,
            one_time=True,
        ))
        
        test_map.trigger_zones.append(TriggerZone(
            trigger_id=3,
            name="Boss Arena",
            trigger_type=TriggerType.PROXIMITY,
            position=(25, 15),
            size=(3, 3),
            event_id=3,
            proximity_range=3,
        ))
        
        self.maps[1] = test_map
    
    def add(self, cmap: CollisionMap):
        """Add map to database"""
        self.maps[cmap.map_id] = cmap
    
    def get(self, map_id: int) -> Optional[CollisionMap]:
        """Get map by ID"""
        return self.maps.get(map_id)
    
    def save_json(self, filename: str):
        """Save to JSON"""
        data = {
            "maps": [m.to_dict() for m in self.maps.values()]
        }
        
        with open(filename, 'w') as f:
            json.dump(data, f, indent=2)
    
    def load_json(self, filename: str):
        """Load from JSON"""
        with open(filename, 'r') as f:
            data = json.load(f)
        
        self.maps = {}
        for map_data in data.get("maps", []):
            cmap = CollisionMap.from_dict(map_data)
            self.maps[cmap.map_id] = cmap


class CollisionTriggerEditor:
    """Main collision and trigger editor with UI"""
    
    def __init__(self, width: int = 1600, height: int = 900):
        self.width = width
        self.height = height
        self.running = True
        
        pygame.init()
        self.screen = pygame.display.set_mode((width, height))
        pygame.display.set_caption("Collision & Trigger Editor")
        self.clock = pygame.time.Clock()
        
        self.font = pygame.font.Font(None, 24)
        self.small_font = pygame.font.Font(None, 18)
        
        # Database
        self.database = CollisionMapDatabase()
        self.current_map: Optional[CollisionMap] = None
        self.selected_map_id: Optional[int] = None
        
        # View state
        self.camera_x = 0
        self.camera_y = 0
        self.zoom = 2.0
        
        # Edit state
        self.current_collision_type = CollisionType.SOLID
        self.painting = False
        self.show_triggers = True
        self.show_grid = True
        self.selected_trigger: Optional[TriggerZone] = None
        
        # UI state
        self.map_scroll = 0
        
        # Select first map
        if self.database.maps:
            first_id = min(self.database.maps.keys())
            self.current_map = self.database.maps[first_id]
            self.selected_map_id = first_id
    
    def run(self):
        """Main editor loop"""
        while self.running:
            self._handle_events()
            self._render()
            self.clock.tick(60)
        
        pygame.quit()
    
    def _handle_events(self):
        """Handle input events"""
        mouse_buttons = pygame.mouse.get_pressed()
        
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                self.running = False
            
            elif event.type == pygame.KEYDOWN:
                self._handle_command_input(event)
            
            elif event.type == pygame.MOUSEBUTTONDOWN:
                self._handle_mouse_click(event.pos, event.button)
            
            elif event.type == pygame.MOUSEBUTTONUP:
                if event.button == 1:
                    self.painting = False
            
            elif event.type == pygame.MOUSEWHEEL:
                if pygame.key.get_mods() & pygame.KMOD_CTRL:
                    self.zoom *= 1.1 if event.y > 0 else 0.9
                    self.zoom = max(0.5, min(4.0, self.zoom))
                else:
                    self.map_scroll = max(0, self.map_scroll - event.y * 30)
        
        # Handle mouse dragging
        if mouse_buttons[0] and self.painting:
            self._handle_mouse_paint(pygame.mouse.get_pos())
    
    def _handle_command_input(self, event):
        """Handle command input"""
        if event.key == pygame.K_ESCAPE:
            self.running = False
        
        # Save/Load
        elif event.key == pygame.K_s and pygame.key.get_mods() & pygame.KMOD_CTRL:
            self.database.save_json("collision_maps.json")
            print("Collision maps saved to collision_maps.json")
        
        elif event.key == pygame.K_o and pygame.key.get_mods() & pygame.KMOD_CTRL:
            try:
                self.database.load_json("collision_maps.json")
                print("Collision maps loaded from collision_maps.json")
            except FileNotFoundError:
                print("No collision_maps.json file found")
        
        # Toggle displays
        elif event.key == pygame.K_t:
            self.show_triggers = not self.show_triggers
        
        elif event.key == pygame.K_g:
            self.show_grid = not self.show_grid
        
        # Select collision types (1-9)
        elif event.key == pygame.K_1:
            self.current_collision_type = CollisionType.PASSABLE
        elif event.key == pygame.K_2:
            self.current_collision_type = CollisionType.SOLID
        elif event.key == pygame.K_3:
            self.current_collision_type = CollisionType.WATER
        elif event.key == pygame.K_4:
            self.current_collision_type = CollisionType.LADDER
        elif event.key == pygame.K_5:
            self.current_collision_type = CollisionType.ICE
        elif event.key == pygame.K_6:
            self.current_collision_type = CollisionType.DAMAGE
        elif event.key == pygame.K_7:
            self.current_collision_type = CollisionType.WARP
        elif event.key == pygame.K_8:
            self.current_collision_type = CollisionType.ONE_WAY_UP
        elif event.key == pygame.K_9:
            self.current_collision_type = CollisionType.ONE_WAY_DOWN
        
        # Camera
        elif event.key == pygame.K_LEFT:
            self.camera_x -= 10
        elif event.key == pygame.K_RIGHT:
            self.camera_x += 10
        elif event.key == pygame.K_UP:
            self.camera_y -= 10
        elif event.key == pygame.K_DOWN:
            self.camera_y += 10
        
        # Map navigation
        elif event.key == pygame.K_PAGEUP:
            map_ids = sorted(self.database.maps.keys())
            if self.selected_map_id in map_ids:
                idx = map_ids.index(self.selected_map_id)
                if idx > 0:
                    self.selected_map_id = map_ids[idx - 1]
                    self.current_map = self.database.maps[self.selected_map_id]
                    self.camera_x = 0
                    self.camera_y = 0
        
        elif event.key == pygame.K_PAGEDOWN:
            map_ids = sorted(self.database.maps.keys())
            if self.selected_map_id in map_ids:
                idx = map_ids.index(self.selected_map_id)
                if idx < len(map_ids) - 1:
                    self.selected_map_id = map_ids[idx + 1]
                    self.current_map = self.database.maps[self.selected_map_id]
                    self.camera_x = 0
                    self.camera_y = 0
    
    def _handle_mouse_click(self, pos: Tuple[int, int], button: int):
        """Handle mouse click"""
        x, y = pos
        
        # Check map list
        if x < 250 and button == 1:
            y_offset = 80 - self.map_scroll
            
            for map_id in sorted(self.database.maps.keys()):
                if y_offset <= y < y_offset + 60:
                    self.current_map = self.database.maps[map_id]
                    self.selected_map_id = map_id
                    self.camera_x = 0
                    self.camera_y = 0
                    break
                y_offset += 65
        
        # Check map area
        elif 250 < x < 1200 and 50 < y < self.height - 50:
            if button == 1:  # Left click - paint
                self.painting = True
                self._handle_mouse_paint(pos)
            elif button == 3:  # Right click - select trigger
                self._handle_trigger_select(pos)
    
    def _handle_mouse_paint(self, pos: Tuple[int, int]):
        """Handle painting collision tiles"""
        if not self.current_map:
            return
        
        x, y = pos
        
        # Convert to tile coordinates
        view_x = 250
        view_y = 50
        
        tile_screen_size = int(self.current_map.tile_size * self.zoom)
        
        tile_x = int((x - view_x - self.camera_x) / tile_screen_size)
        tile_y = int((y - view_y - self.camera_y) / tile_screen_size)
        
        # Set collision
        if 0 <= tile_x < self.current_map.width and 0 <= tile_y < self.current_map.height:
            self.current_map.set_collision(
                tile_x, tile_y, self.current_collision_type)
    
    def _handle_trigger_select(self, pos: Tuple[int, int]):
        """Handle trigger selection"""
        if not self.current_map:
            return
        
        x, y = pos
        
        # Convert to tile coordinates
        view_x = 250
        view_y = 50
        
        tile_screen_size = int(self.current_map.tile_size * self.zoom)
        
        tile_x = int((x - view_x - self.camera_x) / tile_screen_size)
        tile_y = int((y - view_y - self.camera_y) / tile_screen_size)
        
        # Find trigger
        trigger = self.current_map.get_trigger_at(tile_x, tile_y)
        self.selected_trigger = trigger
    
    def _render(self):
        """Render editor"""
        self.screen.fill((25, 25, 35))
        
        # Draw map list
        self._draw_map_list()
        
        # Draw collision map
        self._draw_collision_map()
        
        # Draw properties panel
        self._draw_properties_panel()
        
        # Draw toolbar
        self._draw_toolbar()
        
        pygame.display.flip()
    
    def _draw_map_list(self):
        """Draw map list panel"""
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
        title = self.font.render("Maps", True, (255, 255, 255))
        self.screen.blit(title, (panel_x + 10, panel_y + 10))
        
        # Map list
        y_offset = panel_y + 50 - self.map_scroll
        
        for map_id in sorted(self.database.maps.keys()):
            cmap = self.database.maps[map_id]
            
            if y_offset + 60 < panel_y or y_offset > panel_y + panel_height:
                y_offset += 65
                continue
            
            # Background
            bg_color = (60, 60, 80) if map_id == self.selected_map_id else (45, 45, 55)
            pygame.draw.rect(self.screen, bg_color,
                             (panel_x + 5, y_offset, panel_width - 10, 60))
            pygame.draw.rect(self.screen, (100, 100, 120),
                             (panel_x + 5, y_offset, panel_width - 10, 60), 1)
            
            # Map ID
            id_text = self.small_font.render(f"#{map_id}", True, (180, 180, 180))
            self.screen.blit(id_text, (panel_x + 10, y_offset + 5))
            
            # Map name
            name_text = self.small_font.render(cmap.name, True, (200, 200, 255))
            self.screen.blit(name_text, (panel_x + 10, y_offset + 25))
            
            # Size and triggers
            info = f"{cmap.width}x{cmap.height} | {len(cmap.trigger_zones)} triggers"
            info_text = self.small_font.render(info, True, (150, 150, 150))
            self.screen.blit(info_text, (panel_x + 10, y_offset + 45))
            
            y_offset += 65
    
    def _draw_collision_map(self):
        """Draw collision map view"""
        view_x = 250
        view_y = 50
        view_width = 950
        view_height = self.height - 100
        
        # Background
        pygame.draw.rect(self.screen, (10, 10, 20),
                         (view_x, view_y, view_width, view_height))
        pygame.draw.rect(self.screen, (80, 80, 100),
                         (view_x, view_y, view_width, view_height), 2)
        
        if not self.current_map:
            return
        
        tile_screen_size = int(self.current_map.tile_size * self.zoom)
        
        # Collision type colors
        collision_colors = {
            CollisionType.PASSABLE: (50, 50, 50),
            CollisionType.SOLID: (150, 50, 50),
            CollisionType.ONE_WAY_UP: (100, 100, 200),
            CollisionType.ONE_WAY_DOWN: (100, 150, 200),
            CollisionType.ONE_WAY_LEFT: (150, 100, 200),
            CollisionType.ONE_WAY_RIGHT: (150, 150, 200),
            CollisionType.WATER: (50, 100, 255),
            CollisionType.LADDER: (200, 150, 100),
            CollisionType.ICE: (150, 200, 255),
            CollisionType.DAMAGE: (255, 100, 100),
            CollisionType.WARP: (255, 100, 255),
        }
        
        # Draw tiles
        for y in range(self.current_map.height):
            for x in range(self.current_map.width):
                screen_x = view_x + x * tile_screen_size + self.camera_x
                screen_y = view_y + y * tile_screen_size + self.camera_y
                
                # Skip if off screen
                if (screen_x + tile_screen_size < view_x or screen_x > view_x + view_width or
                        screen_y + tile_screen_size < view_y or screen_y > view_y + view_height):
                    continue
                
                collision_type = self.current_map.get_collision(x, y)
                color = collision_colors.get(collision_type, (100, 100, 100))
                
                pygame.draw.rect(self.screen, color,
                                 (screen_x, screen_y, tile_screen_size, tile_screen_size))
                
                # Grid
                if self.show_grid:
                    pygame.draw.rect(self.screen, (80, 80, 100),
                                     (screen_x, screen_y, tile_screen_size, tile_screen_size), 1)
        
        # Draw triggers
        if self.show_triggers:
            for trigger in self.current_map.trigger_zones:
                tx, ty = trigger.position
                tw, th = trigger.size
                
                screen_x = view_x + tx * tile_screen_size + self.camera_x
                screen_y = view_y + ty * tile_screen_size + self.camera_y
                screen_w = tw * tile_screen_size
                screen_h = th * tile_screen_size
                
                # Trigger colors by type
                trigger_colors = {
                    TriggerType.STEP: (255, 255, 100, 80),
                    TriggerType.TOUCH: (255, 150, 100, 80),
                    TriggerType.ACTION: (100, 255, 100, 80),
                    TriggerType.PROXIMITY: (100, 150, 255, 80),
                    TriggerType.TIMED: (255, 100, 255, 80),
                }
                trigger_color = trigger_colors.get(
                    trigger.trigger_type, (150, 150, 150, 80))
                
                # Draw trigger overlay
                trigger_surf = pygame.Surface((screen_w, screen_h), pygame.SRCALPHA)
                trigger_surf.fill(trigger_color)
                self.screen.blit(trigger_surf, (screen_x, screen_y))
                
                # Border
                border_color = (255, 255, 100) if trigger == self.selected_trigger else (
                    200, 200, 200)
                pygame.draw.rect(self.screen, border_color,
                                 (screen_x, screen_y, screen_w, screen_h), 2)
                
                # Name
                name_surf = self.small_font.render(
                    trigger.name, True, (255, 255, 255))
                self.screen.blit(name_surf, (screen_x + 5, screen_y + 5))
    
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
        
        # Title
        title = self.font.render("Properties", True, (255, 255, 255))
        self.screen.blit(title, (panel_x + 10, panel_y + 10))
        
        y_offset = panel_y + 45
        
        # Current tool
        tool_label = self.small_font.render(
            "Current Tool:", True, (200, 200, 255))
        self.screen.blit(tool_label, (panel_x + 15, y_offset))
        y_offset += 25
        
        tool_text = self.small_font.render(
            self.current_collision_type.value, True, (150, 150, 150))
        self.screen.blit(tool_text, (panel_x + 25, y_offset))
        y_offset += 35
        
        # Collision types legend
        legend_label = self.small_font.render(
            "Collision Types:", True, (200, 200, 255))
        self.screen.blit(legend_label, (panel_x + 15, y_offset))
        y_offset += 25
        
        collision_types = [
            ("1: Passable", (50, 50, 50)),
            ("2: Solid", (150, 50, 50)),
            ("3: Water", (50, 100, 255)),
            ("4: Ladder", (200, 150, 100)),
            ("5: Ice", (150, 200, 255)),
            ("6: Damage", (255, 100, 100)),
            ("7: Warp", (255, 100, 255)),
            ("8: One-Way Up", (100, 100, 200)),
            ("9: One-Way Down", (100, 150, 200)),
        ]
        
        for label, color in collision_types:
            # Color swatch
            pygame.draw.rect(self.screen, color,
                             (panel_x + 25, y_offset, 20, 16))
            pygame.draw.rect(self.screen, (100, 100, 120),
                             (panel_x + 25, y_offset, 20, 16), 1)
            
            # Label
            type_text = self.small_font.render(label, True, (180, 180, 180))
            self.screen.blit(type_text, (panel_x + 50, y_offset))
            
            y_offset += 20
        
        # Selected trigger info
        if self.selected_trigger:
            y_offset += 20
            trigger_title = self.font.render(
                "Selected Trigger", True, (200, 200, 255))
            self.screen.blit(trigger_title, (panel_x + 10, y_offset))
            y_offset += 30
            
            trigger_info = [
                ("Name", self.selected_trigger.name),
                ("Type", self.selected_trigger.trigger_type.value),
                ("Position", f"{self.selected_trigger.position}"),
                ("Size", f"{self.selected_trigger.size}"),
                ("Event ID", f"#{self.selected_trigger.event_id}"),
                ("Enabled", "Yes" if self.selected_trigger.enabled else "No"),
                ("One-Time", "Yes" if self.selected_trigger.one_time else "No"),
            ]
            
            for label, value in trigger_info:
                label_surf = self.small_font.render(
                    f"{label}:", True, (180, 180, 180))
                self.screen.blit(label_surf, (panel_x + 20, y_offset))
                
                value_surf = self.small_font.render(
                    value, True, (150, 150, 150))
                self.screen.blit(value_surf, (panel_x + 180, y_offset))
                
                y_offset += 22
    
    def _draw_toolbar(self):
        """Draw top toolbar"""
        toolbar_height = 40
        pygame.draw.rect(self.screen, (45, 45, 55),
                         (0, 0, self.width, toolbar_height))
        pygame.draw.rect(self.screen, (80, 80, 100),
                         (0, 0, self.width, toolbar_height), 2)
        
        # Title
        if self.current_map:
            title = self.font.render(
                f"Map: {self.current_map.name}", True, (255, 255, 255))
            self.screen.blit(title, (10, 10))
        
        # Instructions
        help_text = "1-9:Tools | Click:Paint | RClick:Select | T:Triggers G:Grid | Arrows:Pan | Ctrl+Wheel:Zoom"
        help_surf = self.small_font.render(help_text, True, (180, 180, 180))
        self.screen.blit(help_surf, (350, 12))


def main():
    """Run collision and trigger editor"""
    editor = CollisionTriggerEditor()
    editor.run()


if __name__ == "__main__":
    main()
