"""
World Map Editor with Region Management for FFMQ
Edit overworld maps, regions, connections, encounters.
"""

import pygame
import json
from dataclasses import dataclass, field
from typing import List, Tuple, Optional, Dict, Set
from enum import Enum
import math


class TerrainType(Enum):
    """Terrain types"""
    GRASS = 0
    FOREST = 1
    MOUNTAIN = 2
    WATER = 3
    DESERT = 4
    SNOW = 5
    SWAMP = 6
    LAVA = 7
    CAVE = 8
    TOWN = 9
    DUNGEON = 10
    BRIDGE = 11


class RegionType(Enum):
    """Region classifications"""
    OVERWORLD = "overworld"
    DUNGEON = "dungeon"
    TOWN = "town"
    INTERIOR = "interior"
    SPECIAL = "special"


@dataclass
class EncounterData:
    """Random encounter definition"""
    formation_id: int
    chance: int  # 0-100%
    min_level: int = 0
    max_level: int = 99
    
    def to_dict(self):
        return {
            'formation_id': self.formation_id,
            'chance': self.chance,
            'min_level': self.min_level,
            'max_level': self.max_level
        }


@dataclass
class MapTile:
    """Single map tile"""
    tile_id: int
    terrain: TerrainType
    walkable: bool = True
    encounter_rate: int = 0  # 0-100%
    
    def to_dict(self):
        return {
            'tile_id': self.tile_id,
            'terrain': self.terrain.value,
            'walkable': self.walkable,
            'encounter_rate': self.encounter_rate
        }


@dataclass
class MapConnection:
    """Connection between maps"""
    source_map: int
    source_x: int
    source_y: int
    target_map: int
    target_x: int
    target_y: int
    connection_type: str = "normal"  # "normal", "stairs", "door", "warp"
    
    def to_dict(self):
        return {
            'source_map': self.source_map,
            'source_x': self.source_x,
            'source_y': self.source_y,
            'target_map': self.target_map,
            'target_x': self.target_x,
            'target_y': self.target_y,
            'connection_type': self.connection_type
        }


@dataclass
class MapRegion:
    """Defined region on map"""
    region_id: int
    name: str
    region_type: RegionType
    bounds: Tuple[int, int, int, int]  # (x, y, width, height)
    encounters: List[EncounterData] = field(default_factory=list)
    music_id: int = 0
    ambient_sound: Optional[int] = None
    weather: Optional[str] = None
    
    def contains_point(self, x: int, y: int) -> bool:
        """Check if point is in region"""
        rx, ry, rw, rh = self.bounds
        return rx <= x < rx + rw and ry <= y < ry + rh
    
    def to_dict(self):
        return {
            'region_id': self.region_id,
            'name': self.name,
            'region_type': self.region_type.value,
            'bounds': self.bounds,
            'encounters': [e.to_dict() for e in self.encounters],
            'music_id': self.music_id,
            'ambient_sound': self.ambient_sound,
            'weather': self.weather
        }


@dataclass
class WorldMap:
    """Complete world map"""
    map_id: int
    name: str
    width: int  # Tiles
    height: int  # Tiles
    tiles: List[List[MapTile]] = field(default_factory=list)
    regions: List[MapRegion] = field(default_factory=list)
    connections: List[MapConnection] = field(default_factory=list)
    
    def __post_init__(self):
        """Initialize tile grid if empty"""
        if not self.tiles:
            self.tiles = [
                [MapTile(0, TerrainType.GRASS) for _ in range(self.width)]
                for _ in range(self.height)
            ]
    
    def get_tile(self, x: int, y: int) -> Optional[MapTile]:
        """Get tile at position"""
        if 0 <= x < self.width and 0 <= y < self.height:
            return self.tiles[y][x]
        return None
    
    def set_tile(self, x: int, y: int, tile: MapTile):
        """Set tile at position"""
        if 0 <= x < self.width and 0 <= y < self.height:
            self.tiles[y][x] = tile
    
    def get_region_at(self, x: int, y: int) -> Optional[MapRegion]:
        """Get region containing point"""
        for region in self.regions:
            if region.contains_point(x, y):
                return region
        return None
    
    def to_dict(self):
        return {
            'map_id': self.map_id,
            'name': self.name,
            'width': self.width,
            'height': self.height,
            'tiles': [[t.to_dict() for t in row] for row in self.tiles],
            'regions': [r.to_dict() for r in self.regions],
            'connections': [c.to_dict() for c in self.connections]
        }


class MapRenderer:
    """Render world map to surface"""
    
    TERRAIN_COLORS = {
        TerrainType.GRASS: (100, 200, 100),
        TerrainType.FOREST: (50, 150, 50),
        TerrainType.MOUNTAIN: (150, 150, 150),
        TerrainType.WATER: (100, 150, 255),
        TerrainType.DESERT: (255, 220, 150),
        TerrainType.SNOW: (240, 240, 255),
        TerrainType.SWAMP: (120, 150, 100),
        TerrainType.LAVA: (255, 100, 50),
        TerrainType.CAVE: (80, 80, 80),
        TerrainType.TOWN: (200, 200, 100),
        TerrainType.DUNGEON: (120, 80, 120),
        TerrainType.BRIDGE: (180, 140, 100)
    }
    
    def __init__(self, tile_size: int = 16):
        self.tile_size = tile_size
        
    def render_map(self, world_map: WorldMap, surface: pygame.Surface,
                   offset_x: int = 0, offset_y: int = 0,
                   show_regions: bool = False, show_connections: bool = False):
        """Render map to surface"""
        # Draw tiles
        for y in range(world_map.height):
            for x in range(world_map.width):
                tile = world_map.tiles[y][x]
                color = self.TERRAIN_COLORS.get(tile.terrain, (128, 128, 128))
                
                rect = pygame.Rect(
                    offset_x + x * self.tile_size,
                    offset_y + y * self.tile_size,
                    self.tile_size,
                    self.tile_size
                )
                pygame.draw.rect(surface, color, rect)
                
                # Unwalkable overlay
                if not tile.walkable:
                    pygame.draw.rect(surface, (255, 0, 0, 128), rect, 1)
        
        # Draw grid
        grid_color = (80, 80, 80)
        for x in range(0, world_map.width * self.tile_size + 1, self.tile_size):
            pygame.draw.line(
                surface, grid_color,
                (offset_x + x, offset_y),
                (offset_x + x, offset_y + world_map.height * self.tile_size)
            )
        for y in range(0, world_map.height * self.tile_size + 1, self.tile_size):
            pygame.draw.line(
                surface, grid_color,
                (offset_x, offset_y + y),
                (offset_x + world_map.width * self.tile_size, offset_y + y)
            )
        
        # Draw regions
        if show_regions:
            for region in world_map.regions:
                rx, ry, rw, rh = region.bounds
                rect = pygame.Rect(
                    offset_x + rx * self.tile_size,
                    offset_y + ry * self.tile_size,
                    rw * self.tile_size,
                    rh * self.tile_size
                )
                pygame.draw.rect(surface, (255, 255, 0), rect, 2)
                
                # Region name
                font = pygame.font.Font(None, 16)
                text = font.render(region.name, True, (255, 255, 0))
                surface.blit(text, (rect.x + 5, rect.y + 5))
        
        # Draw connections
        if show_connections:
            for conn in world_map.connections:
                if conn.source_map == world_map.map_id:
                    x = offset_x + conn.source_x * self.tile_size + self.tile_size // 2
                    y = offset_y + conn.source_y * self.tile_size + self.tile_size // 2
                    pygame.draw.circle(surface, (255, 100, 255), (x, y), 8)
    
    def world_to_screen(self, wx: int, wy: int, offset_x: int, offset_y: int
                        ) -> Tuple[int, int]:
        """Convert world coords to screen coords"""
        return (offset_x + wx * self.tile_size, offset_y + wy * self.tile_size)
    
    def screen_to_world(self, sx: int, sy: int, offset_x: int, offset_y: int
                        ) -> Tuple[int, int]:
        """Convert screen coords to world coords"""
        return ((sx - offset_x) // self.tile_size, (sy - offset_y) // self.tile_size)


class WorldMapEditor:
    """Interactive world map editor"""
    
    def __init__(self):
        pygame.init()
        self.screen = pygame.display.set_mode((1600, 900))
        pygame.display.set_caption("FFMQ World Map Editor")
        self.clock = pygame.time.Clock()
        
        self.font = pygame.font.Font(None, 24)
        self.small_font = pygame.font.Font(None, 18)
        
        # Create sample map
        self.world_map = self._create_sample_map()
        self.renderer = MapRenderer(tile_size=20)
        
        # UI state
        self.camera_x = 0
        self.camera_y = 0
        self.selected_terrain = TerrainType.GRASS
        self.brush_size = 1
        self.show_regions = True
        self.show_connections = True
        self.selected_region = None
        
        # Drawing state
        self.is_drawing = False
        self.is_panning = False
        self.pan_start = (0, 0)
        
        # Tools
        self.tool = "paint"  # "paint", "region", "connection"
        
    def _create_sample_map(self) -> WorldMap:
        """Create sample world map"""
        world_map = WorldMap(0, "Overworld", 64, 48)
        
        # Generate terrain
        for y in range(world_map.height):
            for x in range(world_map.width):
                # Simple terrain generation
                if x < 10 or x >= 54 or y < 5 or y >= 43:
                    # Water border
                    terrain = TerrainType.WATER
                    walkable = False
                elif 20 <= x < 30 and 15 <= y < 25:
                    # Mountain range
                    terrain = TerrainType.MOUNTAIN
                    walkable = False
                elif 35 <= x < 45 and 20 <= y < 30:
                    # Forest
                    terrain = TerrainType.FOREST
                    walkable = True
                else:
                    # Grass
                    terrain = TerrainType.GRASS
                    walkable = True
                
                world_map.tiles[y][x] = MapTile(
                    0, terrain, walkable,
                    encounter_rate=30 if walkable else 0
                )
        
        # Add town
        for y in range(10, 15):
            for x in range(15, 20):
                world_map.tiles[y][x] = MapTile(0, TerrainType.TOWN, True, 0)
        
        # Add regions
        world_map.regions = [
            MapRegion(
                0, "Starting Area", RegionType.OVERWORLD,
                (10, 5, 20, 15),
                encounters=[
                    EncounterData(0, 50),  # Goblin formation
                    EncounterData(1, 30)   # Mixed formation
                ],
                music_id=1
            ),
            MapRegion(
                1, "Forest Zone", RegionType.OVERWORLD,
                (35, 20, 10, 10),
                encounters=[
                    EncounterData(1, 60)
                ],
                music_id=2
            ),
            MapRegion(
                2, "Hometown", RegionType.TOWN,
                (15, 10, 5, 5),
                music_id=10
            )
        ]
        
        # Add connections
        world_map.connections = [
            MapConnection(0, 17, 14, 1, 5, 5, "door")  # Town entrance
        ]
        
        return world_map
    
    def draw_toolbar(self):
        """Draw top toolbar"""
        toolbar_rect = pygame.Rect(0, 0, 1600, 40)
        pygame.draw.rect(self.screen, (50, 50, 50), toolbar_rect)
        pygame.draw.rect(self.screen, (200, 200, 200), toolbar_rect, 2)
        
        x = 10
        
        # Tool buttons
        tools = [
            ("Paint", "paint"),
            ("Region", "region"),
            ("Connection", "connection")
        ]
        
        for label, tool in tools:
            color = (100, 150, 100) if self.tool == tool else (80, 80, 80)
            btn_rect = pygame.Rect(x, 5, 100, 30)
            pygame.draw.rect(self.screen, color, btn_rect)
            pygame.draw.rect(self.screen, (200, 200, 200), btn_rect, 2)
            
            text = self.small_font.render(label, True, (255, 255, 255))
            text_rect = text.get_rect(center=btn_rect.center)
            self.screen.blit(text, text_rect)
            
            x += 110
        
        # Brush size
        x += 20
        text = self.small_font.render(f"Brush: {self.brush_size}",
                                       True, (255, 255, 255))
        self.screen.blit(text, (x, 10))
        
        # Map name
        text = self.font.render(f"Map: {self.world_map.name}",
                                True, (255, 255, 255))
        self.screen.blit(text, (1200, 8))
    
    def draw_terrain_palette(self):
        """Draw terrain selector"""
        palette_rect = pygame.Rect(10, 50, 200, 800)
        pygame.draw.rect(self.screen, (40, 40, 40), palette_rect)
        pygame.draw.rect(self.screen, (200, 200, 200), palette_rect, 2)
        
        # Title
        text = self.small_font.render("Terrain Types", True, (200, 200, 200))
        self.screen.blit(text, (20, 55))
        
        y = 80
        for terrain in TerrainType:
            item_rect = pygame.Rect(20, y, 180, 35)
            
            # Highlight selected
            if terrain == self.selected_terrain:
                pygame.draw.rect(self.screen, (100, 100, 150), item_rect)
            
            # Color swatch
            color = self.renderer.TERRAIN_COLORS.get(terrain, (128, 128, 128))
            swatch_rect = pygame.Rect(25, y + 5, 25, 25)
            pygame.draw.rect(self.screen, color, swatch_rect)
            pygame.draw.rect(self.screen, (255, 255, 255), swatch_rect, 1)
            
            # Label
            text = self.small_font.render(terrain.name, True, (255, 255, 255))
            self.screen.blit(text, (55, y + 8))
            
            y += 40
    
    def draw_region_list(self):
        """Draw region list"""
        list_rect = pygame.Rect(1390, 50, 200, 400)
        pygame.draw.rect(self.screen, (40, 40, 40), list_rect)
        pygame.draw.rect(self.screen, (200, 200, 200), list_rect, 2)
        
        # Title
        text = self.small_font.render("Regions", True, (200, 200, 200))
        self.screen.blit(text, (1400, 55))
        
        y = 80
        for region in self.world_map.regions:
            item_rect = pygame.Rect(1400, y, 180, 50)
            
            if region == self.selected_region:
                pygame.draw.rect(self.screen, (100, 150, 100), item_rect)
            
            # Region name
            text = self.small_font.render(region.name, True, (255, 255, 255))
            self.screen.blit(text, (1405, y + 5))
            
            # Type
            type_text = region.region_type.value
            text = self.small_font.render(type_text, True, (200, 200, 200))
            self.screen.blit(text, (1405, y + 25))
            
            y += 55
    
    def draw_map_view(self):
        """Draw main map view"""
        view_rect = pygame.Rect(220, 50, 1160, 800)
        pygame.draw.rect(self.screen, (20, 20, 20), view_rect)
        
        # Render map
        map_surface = pygame.Surface((
            self.world_map.width * self.renderer.tile_size,
            self.world_map.height * self.renderer.tile_size
        ))
        
        self.renderer.render_map(
            self.world_map, map_surface, 0, 0,
            self.show_regions, self.show_connections
        )
        
        # Blit visible portion
        self.screen.blit(map_surface, (220, 50), (
            self.camera_x, self.camera_y,
            view_rect.width, view_rect.height
        ))
        
        # View border
        pygame.draw.rect(self.screen, (200, 200, 200), view_rect, 2)
    
    def handle_map_click(self, screen_x: int, screen_y: int, button: int):
        """Handle click on map view"""
        # Convert to world coords
        wx, wy = self.renderer.screen_to_world(
            screen_x - 220 + self.camera_x,
            screen_y - 50 + self.camera_y,
            0, 0
        )
        
        if not (0 <= wx < self.world_map.width and 0 <= wy < self.world_map.height):
            return
        
        if self.tool == "paint":
            # Paint terrain
            for dy in range(-self.brush_size + 1, self.brush_size):
                for dx in range(-self.brush_size + 1, self.brush_size):
                    tx, ty = wx + dx, wy + dy
                    if 0 <= tx < self.world_map.width and 0 <= ty < self.world_map.height:
                        walkable = self.selected_terrain not in (
                            TerrainType.WATER, TerrainType.MOUNTAIN
                        )
                        tile = MapTile(0, self.selected_terrain, walkable, 30)
                        self.world_map.set_tile(tx, ty, tile)
        
        elif self.tool == "region":
            # Select region
            region = self.world_map.get_region_at(wx, wy)
            self.selected_region = region
    
    def handle_toolbar_click(self, pos: Tuple[int, int]):
        """Handle toolbar clicks"""
        x, y = pos
        
        if y > 40:
            return
        
        # Tool buttons
        if 10 <= x < 110:
            self.tool = "paint"
        elif 120 <= x < 220:
            self.tool = "region"
        elif 230 <= x < 330:
            self.tool = "connection"
    
    def handle_palette_click(self, pos: Tuple[int, int]):
        """Handle terrain palette clicks"""
        x, y = pos
        
        if not (10 <= x <= 210 and 80 <= y <= 830):
            return
        
        idx = (y - 80) // 40
        terrains = list(TerrainType)
        if 0 <= idx < len(terrains):
            self.selected_terrain = terrains[idx]
    
    def run(self):
        """Main editor loop"""
        running = True
        
        while running:
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    running = False
                
                elif event.type == pygame.MOUSEBUTTONDOWN:
                    if event.button == 1:  # Left click
                        if 220 <= event.pos[0] <= 1380 and 50 <= event.pos[1] <= 850:
                            self.is_drawing = True
                            self.handle_map_click(event.pos[0], event.pos[1], 1)
                        elif event.pos[1] <= 40:
                            self.handle_toolbar_click(event.pos)
                        elif 10 <= event.pos[0] <= 210:
                            self.handle_palette_click(event.pos)
                    
                    elif event.button == 2:  # Middle click - pan
                        self.is_panning = True
                        self.pan_start = event.pos
                    
                    elif event.button == 4:  # Scroll up
                        self.brush_size = min(5, self.brush_size + 1)
                    
                    elif event.button == 5:  # Scroll down
                        self.brush_size = max(1, self.brush_size - 1)
                
                elif event.type == pygame.MOUSEBUTTONUP:
                    if event.button == 1:
                        self.is_drawing = False
                    elif event.button == 2:
                        self.is_panning = False
                
                elif event.type == pygame.MOUSEMOTION:
                    if self.is_drawing:
                        if 220 <= event.pos[0] <= 1380 and 50 <= event.pos[1] <= 850:
                            self.handle_map_click(event.pos[0], event.pos[1], 1)
                    
                    if self.is_panning:
                        dx = event.pos[0] - self.pan_start[0]
                        dy = event.pos[1] - self.pan_start[1]
                        self.camera_x = max(0, self.camera_x - dx)
                        self.camera_y = max(0, self.camera_y - dy)
                        self.pan_start = event.pos
                
                elif event.type == pygame.KEYDOWN:
                    if event.key == pygame.K_ESCAPE:
                        running = False
                    
                    elif event.key == pygame.K_s and (
                            pygame.key.get_mods() & pygame.KMOD_CTRL):
                        self.save_map("world_map.json")
                        print("Map saved!")
                    
                    elif event.key == pygame.K_r:
                        self.show_regions = not self.show_regions
                    
                    elif event.key == pygame.K_c:
                        self.show_connections = not self.show_connections
            
            # Draw
            self.screen.fill((30, 30, 30))
            
            self.draw_toolbar()
            self.draw_terrain_palette()
            self.draw_map_view()
            self.draw_region_list()
            
            # Instructions
            inst = self.small_font.render(
                "R: Toggle Regions | C: Toggle Connections | Ctrl+S: Save | ESC: Quit",
                True, (150, 150, 150)
            )
            self.screen.blit(inst, (220, 860))
            
            pygame.display.flip()
            self.clock.tick(60)
        
        pygame.quit()
    
    def save_map(self, filepath: str):
        """Save world map"""
        with open(filepath, 'w') as f:
            json.dump(self.world_map.to_dict(), f, indent=2)


def main():
    """Run world map editor"""
    editor = WorldMapEditor()
    editor.run()


if __name__ == '__main__':
    main()
