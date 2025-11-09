#!/usr/bin/env python3
"""
World Map Editor

Comprehensive world/region map editing tool.
Features include:
- Multi-region world map
- Zone connections and transitions
- Encounter areas
- Treasure placement
- NPC placement
- Warp points
- Region properties
- Visual map editor
- Export to game format

Map Components:
- Regions: Large map areas
- Zones: Sub-areas within regions
- Connections: Paths between areas
- Encounters: Battle zones
- Points of Interest: Towns, dungeons, etc.

Region Types:
- Overworld: Main world map
- Town: Settlement areas
- Dungeon: Underground areas
- Cave: Natural caverns
- Tower: Vertical structures
- Special: Unique locations
"""

from dataclasses import dataclass, field
from enum import Enum
from typing import Dict, List, Optional, Tuple, Any, Set
import pygame
import json
import math


class RegionType(Enum):
    """Region type categories"""
    OVERWORLD = "overworld"
    TOWN = "town"
    DUNGEON = "dungeon"
    CAVE = "cave"
    TOWER = "tower"
    FOREST = "forest"
    MOUNTAIN = "mountain"
    DESERT = "desert"
    OCEAN = "ocean"
    SPECIAL = "special"


class ConnectionType(Enum):
    """Connection types between regions"""
    WALK = "walk"
    DOOR = "door"
    STAIRS = "stairs"
    LADDER = "ladder"
    TELEPORT = "teleport"
    BOAT = "boat"
    AIRSHIP = "airship"


class POIType(Enum):
    """Point of interest types"""
    TOWN = "town"
    DUNGEON = "dungeon"
    BOSS = "boss"
    TREASURE = "treasure"
    NPC = "npc"
    SHOP = "shop"
    INN = "inn"
    SAVE_POINT = "save_point"
    QUEST = "quest"
    LANDMARK = "landmark"


@dataclass
class EncounterZone:
    """Random encounter zone"""
    zone_id: int
    name: str
    position: Tuple[int, int]  # Top-left corner
    size: Tuple[int, int]  # Width, height
    enemy_groups: List[int] = field(default_factory=list)
    encounter_rate: float = 0.1  # Encounters per step
    min_level: int = 1
    max_level: int = 99
    
    def contains_point(self, x: int, y: int) -> bool:
        """Check if point is within zone"""
        px, py = self.position
        w, h = self.size
        return px <= x <= px + w and py <= y <= py + h
    
    def to_dict(self) -> dict:
        """Convert to dictionary"""
        return {
            "zone_id": self.zone_id,
            "name": self.name,
            "position": self.position,
            "size": self.size,
            "enemy_groups": self.enemy_groups,
            "encounter_rate": self.encounter_rate,
            "min_level": self.min_level,
            "max_level": self.max_level,
        }
    
    @staticmethod
    def from_dict(data: dict) -> 'EncounterZone':
        """Create from dictionary"""
        return EncounterZone(
            zone_id=data["zone_id"],
            name=data["name"],
            position=tuple(data["position"]),
            size=tuple(data["size"]),
            enemy_groups=data.get("enemy_groups", []),
            encounter_rate=data.get("encounter_rate", 0.1),
            min_level=data.get("min_level", 1),
            max_level=data.get("max_level", 99),
        )


@dataclass
class PointOfInterest:
    """Point of interest on map"""
    poi_id: int
    name: str
    poi_type: POIType
    position: Tuple[int, int]
    description: str = ""
    icon_id: int = 0
    unlocked: bool = True
    quest_id: Optional[int] = None
    
    def to_dict(self) -> dict:
        """Convert to dictionary"""
        return {
            "poi_id": self.poi_id,
            "name": self.name,
            "poi_type": self.poi_type.value,
            "position": self.position,
            "description": self.description,
            "icon_id": self.icon_id,
            "unlocked": self.unlocked,
            "quest_id": self.quest_id,
        }
    
    @staticmethod
    def from_dict(data: dict) -> 'PointOfInterest':
        """Create from dictionary"""
        return PointOfInterest(
            poi_id=data["poi_id"],
            name=data["name"],
            poi_type=POIType(data["poi_type"]),
            position=tuple(data["position"]),
            description=data.get("description", ""),
            icon_id=data.get("icon_id", 0),
            unlocked=data.get("unlocked", True),
            quest_id=data.get("quest_id"),
        )


@dataclass
class RegionConnection:
    """Connection between regions"""
    connection_id: int
    from_region: int
    to_region: int
    from_position: Tuple[int, int]
    to_position: Tuple[int, int]
    connection_type: ConnectionType = ConnectionType.WALK
    requires_item: Optional[str] = None
    requires_flag: Optional[str] = None
    bidirectional: bool = True
    
    def to_dict(self) -> dict:
        """Convert to dictionary"""
        return {
            "connection_id": self.connection_id,
            "from_region": self.from_region,
            "to_region": self.to_region,
            "from_position": self.from_position,
            "to_position": self.to_position,
            "connection_type": self.connection_type.value,
            "requires_item": self.requires_item,
            "requires_flag": self.requires_flag,
            "bidirectional": self.bidirectional,
        }
    
    @staticmethod
    def from_dict(data: dict) -> 'RegionConnection':
        """Create from dictionary"""
        return RegionConnection(
            connection_id=data["connection_id"],
            from_region=data["from_region"],
            to_region=data["to_region"],
            from_position=tuple(data["from_position"]),
            to_position=tuple(data["to_position"]),
            connection_type=ConnectionType(data.get("connection_type", "walk")),
            requires_item=data.get("requires_item"),
            requires_flag=data.get("requires_flag"),
            bidirectional=data.get("bidirectional", True),
        )


@dataclass
class MapRegion:
    """Map region definition"""
    region_id: int
    name: str
    region_type: RegionType
    width: int = 100
    height: int = 100
    background_color: Tuple[int, int, int] = (50, 100, 50)
    music_id: int = 0
    encounter_zones: List[EncounterZone] = field(default_factory=list)
    points_of_interest: List[PointOfInterest] = field(default_factory=list)
    connections: List[RegionConnection] = field(default_factory=list)
    requires_item: Optional[str] = None
    requires_flag: Optional[str] = None
    
    def get_poi_at(self, x: int, y: int, radius: int = 10) -> Optional[PointOfInterest]:
        """Get POI near position"""
        for poi in self.points_of_interest:
            px, py = poi.position
            distance = math.sqrt((x - px) ** 2 + (y - py) ** 2)
            if distance <= radius:
                return poi
        return None
    
    def get_encounter_zone_at(self, x: int, y: int) -> Optional[EncounterZone]:
        """Get encounter zone containing position"""
        for zone in self.encounter_zones:
            if zone.contains_point(x, y):
                return zone
        return None
    
    def to_dict(self) -> dict:
        """Convert to dictionary"""
        return {
            "region_id": self.region_id,
            "name": self.name,
            "region_type": self.region_type.value,
            "width": self.width,
            "height": self.height,
            "background_color": self.background_color,
            "music_id": self.music_id,
            "requires_item": self.requires_item,
            "requires_flag": self.requires_flag,
            "encounter_zones": [z.to_dict() for z in self.encounter_zones],
            "points_of_interest": [p.to_dict() for p in self.points_of_interest],
            "connections": [c.to_dict() for c in self.connections],
        }
    
    @staticmethod
    def from_dict(data: dict) -> 'MapRegion':
        """Create from dictionary"""
        return MapRegion(
            region_id=data["region_id"],
            name=data["name"],
            region_type=RegionType(data.get("region_type", "overworld")),
            width=data.get("width", 100),
            height=data.get("height", 100),
            background_color=tuple(data.get("background_color", (50, 100, 50))),
            music_id=data.get("music_id", 0),
            requires_item=data.get("requires_item"),
            requires_flag=data.get("requires_flag"),
            encounter_zones=[EncounterZone.from_dict(z)
                             for z in data.get("encounter_zones", [])],
            points_of_interest=[PointOfInterest.from_dict(p)
                                for p in data.get("points_of_interest", [])],
            connections=[RegionConnection.from_dict(c)
                         for c in data.get("connections", [])],
        )


class WorldMapDatabase:
    """Database of world map regions"""
    
    def __init__(self):
        self.regions: Dict[int, MapRegion] = {}
        self._init_sample_data()
    
    def _init_sample_data(self):
        """Initialize sample world map"""
        # Overworld region
        overworld = MapRegion(
            region_id=1,
            name="Main Continent",
            region_type=RegionType.OVERWORLD,
            width=500,
            height=400,
            background_color=(50, 150, 50),
            music_id=1,
        )
        
        # Encounter zones
        overworld.encounter_zones.append(EncounterZone(
            zone_id=1,
            name="Grasslands",
            position=(50, 50),
            size=(200, 150),
            enemy_groups=[1, 2, 3],
            encounter_rate=0.08,
            min_level=1,
            max_level=5,
        ))
        
        overworld.encounter_zones.append(EncounterZone(
            zone_id=2,
            name="Dark Forest",
            position=(300, 100),
            size=(150, 200),
            enemy_groups=[4, 5, 6],
            encounter_rate=0.12,
            min_level=8,
            max_level=15,
        ))
        
        # Points of interest
        overworld.points_of_interest.append(PointOfInterest(
            poi_id=1,
            name="Starting Village",
            poi_type=POIType.TOWN,
            position=(100, 100),
            description="A peaceful village where your journey begins.",
            icon_id=1,
        ))
        
        overworld.points_of_interest.append(PointOfInterest(
            poi_id=2,
            name="Ancient Ruins",
            poi_type=POIType.DUNGEON,
            position=(350, 200),
            description="Mysterious ruins from a lost civilization.",
            icon_id=2,
        ))
        
        overworld.points_of_interest.append(PointOfInterest(
            poi_id=3,
            name="Mountain Pass",
            poi_type=POIType.LANDMARK,
            position=(450, 150),
            description="A treacherous mountain passage.",
            icon_id=3,
        ))
        
        self.regions[1] = overworld
        
        # Town region
        town = MapRegion(
            region_id=2,
            name="Starting Village",
            region_type=RegionType.TOWN,
            width=80,
            height=60,
            background_color=(100, 120, 80),
            music_id=2,
        )
        
        town.points_of_interest.append(PointOfInterest(
            poi_id=4,
            name="Inn",
            poi_type=POIType.INN,
            position=(20, 20),
            description="Rest and recover here.",
        ))
        
        town.points_of_interest.append(PointOfInterest(
            poi_id=5,
            name="Item Shop",
            poi_type=POIType.SHOP,
            position=(50, 20),
            description="Buy supplies for your journey.",
        ))
        
        town.points_of_interest.append(PointOfInterest(
            poi_id=6,
            name="Village Elder",
            poi_type=POIType.QUEST,
            position=(40, 40),
            description="The village elder has a request.",
            quest_id=1,
        ))
        
        # Connection from town to overworld
        town.connections.append(RegionConnection(
            connection_id=1,
            from_region=2,
            to_region=1,
            from_position=(40, 5),
            to_position=(100, 100),
            connection_type=ConnectionType.DOOR,
        ))
        
        self.regions[2] = town
        
        # Dungeon region
        dungeon = MapRegion(
            region_id=3,
            name="Ancient Ruins",
            region_type=RegionType.DUNGEON,
            width=120,
            height=100,
            background_color=(40, 40, 50),
            music_id=3,
        )
        
        dungeon.encounter_zones.append(EncounterZone(
            zone_id=3,
            name="Ruins Interior",
            position=(0, 0),
            size=(120, 100),
            enemy_groups=[7, 8, 9],
            encounter_rate=0.15,
            min_level=10,
            max_level=18,
        ))
        
        dungeon.points_of_interest.append(PointOfInterest(
            poi_id=7,
            name="Treasure Room",
            poi_type=POIType.TREASURE,
            position=(100, 80),
            description="A sealed treasure chest.",
        ))
        
        dungeon.points_of_interest.append(PointOfInterest(
            poi_id=8,
            name="Boss Chamber",
            poi_type=POIType.BOSS,
            position=(60, 20),
            description="An ominous chamber lies ahead.",
        ))
        
        dungeon.connections.append(RegionConnection(
            connection_id=2,
            from_region=3,
            to_region=1,
            from_position=(10, 90),
            to_position=(350, 200),
            connection_type=ConnectionType.STAIRS,
        ))
        
        self.regions[3] = dungeon
    
    def add(self, region: MapRegion):
        """Add region to database"""
        self.regions[region.region_id] = region
    
    def get(self, region_id: int) -> Optional[MapRegion]:
        """Get region by ID"""
        return self.regions.get(region_id)
    
    def save_json(self, filename: str):
        """Save to JSON"""
        data = {
            "regions": [r.to_dict() for r in self.regions.values()]
        }
        
        with open(filename, 'w') as f:
            json.dump(data, f, indent=2)
    
    def load_json(self, filename: str):
        """Load from JSON"""
        with open(filename, 'r') as f:
            data = json.load(f)
        
        self.regions = {}
        for region_data in data.get("regions", []):
            region = MapRegion.from_dict(region_data)
            self.regions[region.region_id] = region


class WorldMapEditor:
    """Main world map editor with UI"""
    
    def __init__(self, width: int = 1600, height: int = 900):
        self.width = width
        self.height = height
        self.running = True
        
        pygame.init()
        self.screen = pygame.display.set_mode((width, height))
        pygame.display.set_caption("World Map Editor")
        self.clock = pygame.time.Clock()
        
        self.font = pygame.font.Font(None, 24)
        self.small_font = pygame.font.Font(None, 18)
        
        # Database
        self.database = WorldMapDatabase()
        self.current_region: Optional[MapRegion] = None
        self.selected_region_id: Optional[int] = None
        
        # View state
        self.camera_x = 0
        self.camera_y = 0
        self.zoom = 1.0
        
        # UI state
        self.region_scroll = 0
        self.show_encounter_zones = True
        self.show_poi = True
        self.show_connections = True
        self.selected_poi: Optional[PointOfInterest] = None
        self.selected_zone: Optional[EncounterZone] = None
        
        # Select first region
        if self.database.regions:
            first_id = min(self.database.regions.keys())
            self.current_region = self.database.regions[first_id]
            self.selected_region_id = first_id
    
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
                self._handle_command_input(event)
            
            elif event.type == pygame.MOUSEBUTTONDOWN:
                self._handle_mouse_click(event.pos, event.button)
            
            elif event.type == pygame.MOUSEWHEEL:
                # Zoom
                if pygame.key.get_mods() & pygame.KMOD_CTRL:
                    self.zoom *= 1.1 if event.y > 0 else 0.9
                    self.zoom = max(0.5, min(3.0, self.zoom))
                else:
                    self.region_scroll = max(0, self.region_scroll - event.y * 30)
    
    def _handle_command_input(self, event):
        """Handle command input"""
        if event.key == pygame.K_ESCAPE:
            self.running = False
        
        # Save/Load
        elif event.key == pygame.K_s and pygame.key.get_mods() & pygame.KMOD_CTRL:
            self.database.save_json("world_map.json")
            print("World map saved to world_map.json")
        
        elif event.key == pygame.K_o and pygame.key.get_mods() & pygame.KMOD_CTRL:
            try:
                self.database.load_json("world_map.json")
                print("World map loaded from world_map.json")
            except FileNotFoundError:
                print("No world_map.json file found")
        
        # Toggle layers
        elif event.key == pygame.K_e:
            self.show_encounter_zones = not self.show_encounter_zones
        
        elif event.key == pygame.K_p:
            self.show_poi = not self.show_poi
        
        elif event.key == pygame.K_c:
            self.show_connections = not self.show_connections
        
        # Camera movement
        elif event.key == pygame.K_LEFT:
            self.camera_x -= 20 / self.zoom
        elif event.key == pygame.K_RIGHT:
            self.camera_x += 20 / self.zoom
        elif event.key == pygame.K_UP:
            self.camera_y -= 20 / self.zoom
        elif event.key == pygame.K_DOWN:
            self.camera_y += 20 / self.zoom
        
        # Region navigation
        elif event.key == pygame.K_PAGEUP:
            region_ids = sorted(self.database.regions.keys())
            if self.selected_region_id in region_ids:
                idx = region_ids.index(self.selected_region_id)
                if idx > 0:
                    self.selected_region_id = region_ids[idx - 1]
                    self.current_region = self.database.regions[self.selected_region_id]
                    self.camera_x = 0
                    self.camera_y = 0
        
        elif event.key == pygame.K_PAGEDOWN:
            region_ids = sorted(self.database.regions.keys())
            if self.selected_region_id in region_ids:
                idx = region_ids.index(self.selected_region_id)
                if idx < len(region_ids) - 1:
                    self.selected_region_id = region_ids[idx + 1]
                    self.current_region = self.database.regions[self.selected_region_id]
                    self.camera_x = 0
                    self.camera_y = 0
    
    def _handle_mouse_click(self, pos: Tuple[int, int], button: int):
        """Handle mouse click"""
        x, y = pos
        
        # Check region list
        if x < 250 and button == 1:
            y_offset = 80 - self.region_scroll
            
            for region_id in sorted(self.database.regions.keys()):
                if y_offset <= y < y_offset + 60:
                    self.current_region = self.database.regions[region_id]
                    self.selected_region_id = region_id
                    self.camera_x = 0
                    self.camera_y = 0
                    break
                y_offset += 65
        
        # Check map area
        elif 250 < x < 1200 and 50 < y < self.height - 50:
            # Convert to world coordinates
            world_x = (x - 250 - 475) / self.zoom + self.camera_x
            world_y = (y - 50 - 400) / self.zoom + self.camera_y
            
            if self.current_region and self.show_poi:
                poi = self.current_region.get_poi_at(int(world_x), int(world_y), 15)
                if poi:
                    self.selected_poi = poi
                    self.selected_zone = None
                elif self.show_encounter_zones:
                    zone = self.current_region.get_encounter_zone_at(
                        int(world_x), int(world_y))
                    if zone:
                        self.selected_zone = zone
                        self.selected_poi = None
    
    def _render(self):
        """Render editor"""
        self.screen.fill((25, 25, 35))
        
        # Draw region list
        self._draw_region_list()
        
        # Draw map view
        self._draw_map_view()
        
        # Draw properties panel
        self._draw_properties_panel()
        
        # Draw toolbar
        self._draw_toolbar()
        
        pygame.display.flip()
    
    def _draw_region_list(self):
        """Draw region list panel"""
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
        title = self.font.render("Regions", True, (255, 255, 255))
        self.screen.blit(title, (panel_x + 10, panel_y + 10))
        
        # Region list
        y_offset = panel_y + 50 - self.region_scroll
        
        for region_id in sorted(self.database.regions.keys()):
            region = self.database.regions[region_id]
            
            if y_offset + 60 < panel_y or y_offset > panel_y + panel_height:
                y_offset += 65
                continue
            
            # Background
            bg_color = (60, 60, 80) if region_id == self.selected_region_id else (
                45, 45, 55)
            pygame.draw.rect(self.screen, bg_color,
                             (panel_x + 5, y_offset, panel_width - 10, 60))
            pygame.draw.rect(self.screen, (100, 100, 120),
                             (panel_x + 5, y_offset, panel_width - 10, 60), 1)
            
            # Region ID
            id_text = self.small_font.render(
                f"#{region_id}", True, (180, 180, 180))
            self.screen.blit(id_text, (panel_x + 10, y_offset + 5))
            
            # Type indicator color
            type_colors = {
                RegionType.OVERWORLD: (100, 200, 100),
                RegionType.TOWN: (200, 200, 100),
                RegionType.DUNGEON: (200, 100, 100),
                RegionType.CAVE: (150, 100, 50),
                RegionType.TOWER: (150, 150, 200),
                RegionType.FOREST: (50, 150, 50),
                RegionType.MOUNTAIN: (150, 150, 150),
                RegionType.DESERT: (200, 180, 100),
                RegionType.OCEAN: (100, 100, 200),
                RegionType.SPECIAL: (200, 100, 200),
            }
            type_color = type_colors.get(region.region_type, (150, 150, 150))
            pygame.draw.circle(self.screen, type_color,
                               (panel_x + 230, y_offset + 12), 6)
            
            # Region name
            name_text = self.small_font.render(
                region.name[:20], True, (200, 200, 255))
            self.screen.blit(name_text, (panel_x + 10, y_offset + 25))
            
            # Size and POI count
            info = f"{region.width}x{region.height} | {len(region.points_of_interest)} POI"
            info_text = self.small_font.render(info, True, (150, 150, 150))
            self.screen.blit(info_text, (panel_x + 10, y_offset + 45))
            
            y_offset += 65
    
    def _draw_map_view(self):
        """Draw map view area"""
        view_x = 250
        view_y = 50
        view_width = 950
        view_height = self.height - 100
        
        # Background
        pygame.draw.rect(self.screen, (10, 10, 20),
                         (view_x, view_y, view_width, view_height))
        pygame.draw.rect(self.screen, (80, 80, 100),
                         (view_x, view_y, view_width, view_height), 2)
        
        if not self.current_region:
            return
        
        # Draw region background
        center_x = view_x + view_width // 2
        center_y = view_y + view_height // 2
        
        region_screen_w = int(self.current_region.width * self.zoom)
        region_screen_h = int(self.current_region.height * self.zoom)
        
        region_x = center_x - int(self.camera_x * self.zoom)
        region_y = center_y - int(self.camera_y * self.zoom)
        
        pygame.draw.rect(self.screen, self.current_region.background_color,
                         (region_x, region_y, region_screen_w, region_screen_h))
        pygame.draw.rect(self.screen, (100, 100, 120),
                         (region_x, region_y, region_screen_w, region_screen_h), 2)
        
        # Draw encounter zones
        if self.show_encounter_zones:
            for zone in self.current_region.encounter_zones:
                zx, zy = zone.position
                zw, zh = zone.size
                
                screen_x = region_x + int(zx * self.zoom)
                screen_y = region_y + int(zy * self.zoom)
                screen_w = int(zw * self.zoom)
                screen_h = int(zh * self.zoom)
                
                # Zone color based on level
                level_avg = (zone.min_level + zone.max_level) / 2
                if level_avg < 10:
                    zone_color = (100, 255, 100, 50)
                elif level_avg < 30:
                    zone_color = (255, 255, 100, 50)
                else:
                    zone_color = (255, 100, 100, 50)
                
                # Draw zone
                zone_surf = pygame.Surface((screen_w, screen_h), pygame.SRCALPHA)
                zone_surf.fill(zone_color)
                self.screen.blit(zone_surf, (screen_x, screen_y))
                
                # Border
                border_color = (255, 255, 100) if zone == self.selected_zone else (
                    150, 150, 150)
                pygame.draw.rect(self.screen, border_color,
                                 (screen_x, screen_y, screen_w, screen_h), 2)
        
        # Draw POIs
        if self.show_poi:
            for poi in self.current_region.points_of_interest:
                px, py = poi.position
                
                screen_x = region_x + int(px * self.zoom)
                screen_y = region_y + int(py * self.zoom)
                
                # POI color by type
                poi_colors = {
                    POIType.TOWN: (255, 255, 100),
                    POIType.DUNGEON: (255, 100, 100),
                    POIType.BOSS: (255, 50, 50),
                    POIType.TREASURE: (255, 215, 0),
                    POIType.NPC: (100, 200, 255),
                    POIType.SHOP: (100, 255, 100),
                    POIType.INN: (200, 150, 255),
                    POIType.SAVE_POINT: (100, 255, 255),
                    POIType.QUEST: (255, 150, 100),
                    POIType.LANDMARK: (200, 200, 200),
                }
                poi_color = poi_colors.get(poi.poi_type, (150, 150, 150))
                
                # Draw POI
                size = 12 if poi == self.selected_poi else 8
                pygame.draw.circle(self.screen, poi_color, (screen_x, screen_y), size)
                pygame.draw.circle(self.screen, (255, 255, 255),
                                   (screen_x, screen_y), size, 2)
                
                # Draw name
                name_surf = self.small_font.render(
                    poi.name, True, (255, 255, 255))
                self.screen.blit(name_surf, (screen_x + 10, screen_y - 10))
        
        # Draw connections
        if self.show_connections:
            for conn in self.current_region.connections:
                cx, cy = conn.from_position
                
                screen_x = region_x + int(cx * self.zoom)
                screen_y = region_y + int(cy * self.zoom)
                
                # Connection indicator
                pygame.draw.circle(self.screen, (100, 200, 255),
                                   (screen_x, screen_y), 6)
                pygame.draw.circle(self.screen, (255, 255, 255),
                                   (screen_x, screen_y), 6, 2)
                
                # Draw arrow pointing out
                pygame.draw.line(self.screen, (100, 200, 255),
                                 (screen_x, screen_y),
                                 (screen_x, screen_y - 15), 2)
                pygame.draw.polygon(self.screen, (100, 200, 255), [
                    (screen_x, screen_y - 15),
                    (screen_x - 5, screen_y - 10),
                    (screen_x + 5, screen_y - 10),
                ])
    
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
        
        if not self.current_region:
            return
        
        # Title
        title = self.font.render("Properties", True, (255, 255, 255))
        self.screen.blit(title, (panel_x + 10, panel_y + 10))
        
        y_offset = panel_y + 45
        
        # Region info
        info_items = [
            ("Region", ""),
            ("ID", f"#{self.current_region.region_id}"),
            ("Type", self.current_region.region_type.value),
            ("Size", f"{self.current_region.width}x{self.current_region.height}"),
            ("Music", f"#{self.current_region.music_id}"),
            ("", ""),
            ("Content", ""),
            ("POIs", str(len(self.current_region.points_of_interest))),
            ("Zones", str(len(self.current_region.encounter_zones))),
            ("Connections", str(len(self.current_region.connections))),
        ]
        
        for label, value in info_items:
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
                self.screen.blit(value_surf, (panel_x + 150, y_offset))
                
                y_offset += 22
        
        # Selected POI
        if self.selected_poi:
            y_offset += 15
            poi_title = self.font.render("Selected POI", True, (200, 200, 255))
            self.screen.blit(poi_title, (panel_x + 10, y_offset))
            y_offset += 30
            
            poi_info = [
                ("Name", self.selected_poi.name),
                ("Type", self.selected_poi.poi_type.value),
                ("Position", f"{self.selected_poi.position}"),
                ("Unlocked", "Yes" if self.selected_poi.unlocked else "No"),
            ]
            
            for label, value in poi_info:
                label_surf = self.small_font.render(
                    f"{label}:", True, (180, 180, 180))
                self.screen.blit(label_surf, (panel_x + 20, y_offset))
                
                value_surf = self.small_font.render(
                    value, True, (150, 150, 150))
                self.screen.blit(value_surf, (panel_x + 150, y_offset))
                
                y_offset += 22
            
            if self.selected_poi.description:
                y_offset += 10
                desc_label = self.small_font.render(
                    "Description:", True, (180, 180, 180))
                self.screen.blit(desc_label, (panel_x + 20, y_offset))
                y_offset += 22
                
                # Word wrap
                words = self.selected_poi.description.split()
                line = ""
                for word in words:
                    test_line = line + word + " "
                    if len(test_line) > 35:
                        desc_surf = self.small_font.render(
                            line, True, (150, 150, 150))
                        self.screen.blit(desc_surf, (panel_x + 20, y_offset))
                        y_offset += 18
                        line = word + " "
                    else:
                        line = test_line
                
                if line:
                    desc_surf = self.small_font.render(
                        line, True, (150, 150, 150))
                    self.screen.blit(desc_surf, (panel_x + 20, y_offset))
        
        # Selected zone
        elif self.selected_zone:
            y_offset += 15
            zone_title = self.font.render(
                "Selected Zone", True, (200, 200, 255))
            self.screen.blit(zone_title, (panel_x + 10, y_offset))
            y_offset += 30
            
            zone_info = [
                ("Name", self.selected_zone.name),
                ("Position", f"{self.selected_zone.position}"),
                ("Size", f"{self.selected_zone.size}"),
                ("Rate", f"{self.selected_zone.encounter_rate:.2f}"),
                ("Level Range", f"{self.selected_zone.min_level}-{self.selected_zone.max_level}"),
                ("Groups", f"{len(self.selected_zone.enemy_groups)}"),
            ]
            
            for label, value in zone_info:
                label_surf = self.small_font.render(
                    f"{label}:", True, (180, 180, 180))
                self.screen.blit(label_surf, (panel_x + 20, y_offset))
                
                value_surf = self.small_font.render(
                    value, True, (150, 150, 150))
                self.screen.blit(value_surf, (panel_x + 150, y_offset))
                
                y_offset += 22
    
    def _draw_toolbar(self):
        """Draw top toolbar"""
        toolbar_height = 40
        pygame.draw.rect(self.screen, (45, 45, 55),
                         (0, 0, self.width, toolbar_height))
        pygame.draw.rect(self.screen, (80, 80, 100),
                         (0, 0, self.width, toolbar_height), 2)
        
        # Title
        if self.current_region:
            title = self.font.render(
                f"Region: {self.current_region.name}", True, (255, 255, 255))
            self.screen.blit(title, (10, 10))
        
        # Instructions
        help_text = "PgUp/Dn:Regions | Arrows:Pan | Ctrl+Wheel:Zoom | E:Zones P:POIs C:Connections | Ctrl+S:Save"
        help_surf = self.small_font.render(help_text, True, (180, 180, 180))
        self.screen.blit(help_surf, (400, 12))


def main():
    """Run world map editor"""
    editor = WorldMapEditor()
    editor.run()


if __name__ == "__main__":
    main()
