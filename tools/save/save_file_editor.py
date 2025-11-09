#!/usr/bin/env python3
"""
Save File Editor

Comprehensive save data editing and management.
Features:
- Character stats editing
- Inventory management
- Progress flags
- Quest completion
- Map unlocks
- Play time tracking
- Gold/currency
- Equipment editing
"""

from dataclasses import dataclass, field
from enum import Enum
from typing import Dict, List, Optional, Set
import pygame
import json
from datetime import datetime, timedelta


class EquipSlot(Enum):
    """Equipment slots"""
    WEAPON = "weapon"
    ARMOR = "armor"
    ACCESSORY_1 = "accessory_1"
    ACCESSORY_2 = "accessory_2"


@dataclass
class CharacterStats:
    """Character statistics"""
    character_id: int
    name: str
    level: int = 1
    exp: int = 0
    hp: int = 100
    max_hp: int = 100
    mp: int = 50
    max_mp: int = 50
    strength: int = 10
    defense: int = 10
    magic: int = 10
    speed: int = 10
    equipment: Dict[str, int] = field(default_factory=dict)
    learned_skills: List[int] = field(default_factory=list)
    
    def to_dict(self) -> dict:
        return {
            "character_id": self.character_id,
            "name": self.name,
            "level": self.level,
            "exp": self.exp,
            "hp": self.hp,
            "max_hp": self.max_hp,
            "mp": self.mp,
            "max_mp": self.max_mp,
            "strength": self.strength,
            "defense": self.defense,
            "magic": self.magic,
            "speed": self.speed,
            "equipment": self.equipment,
            "learned_skills": self.learned_skills,
        }
    
    @staticmethod
    def from_dict(data: dict) -> 'CharacterStats':
        return CharacterStats(
            character_id=data["character_id"],
            name=data["name"],
            level=data.get("level", 1),
            exp=data.get("exp", 0),
            hp=data.get("hp", 100),
            max_hp=data.get("max_hp", 100),
            mp=data.get("mp", 50),
            max_mp=data.get("max_mp", 50),
            strength=data.get("strength", 10),
            defense=data.get("defense", 10),
            magic=data.get("magic", 10),
            speed=data.get("speed", 10),
            equipment=data.get("equipment", {}),
            learned_skills=data.get("learned_skills", []),
        )


@dataclass
class InventoryItem:
    """Inventory item"""
    item_id: int
    quantity: int
    
    def to_dict(self) -> dict:
        return {"item_id": self.item_id, "quantity": self.quantity}
    
    @staticmethod
    def from_dict(data: dict) -> 'InventoryItem':
        return InventoryItem(data["item_id"], data["quantity"])


@dataclass
class SaveData:
    """Complete save data"""
    save_id: int
    save_name: str
    created_time: datetime = field(default_factory=datetime.now)
    last_played: datetime = field(default_factory=datetime.now)
    play_time: float = 0.0  # In seconds
    gold: int = 0
    map_id: int = 1
    position: tuple = (10, 10)
    party: List[int] = field(default_factory=list)
    characters: Dict[int, CharacterStats] = field(default_factory=dict)
    inventory: List[InventoryItem] = field(default_factory=list)
    flags: Set[str] = field(default_factory=set)
    completed_quests: Set[int] = field(default_factory=set)
    unlocked_maps: Set[int] = field(default_factory=set)
    
    def get_play_time_str(self) -> str:
        """Get formatted play time"""
        td = timedelta(seconds=int(self.play_time))
        hours = td.seconds // 3600
        minutes = (td.seconds % 3600) // 60
        return f"{hours:02d}:{minutes:02d}"
    
    def to_dict(self) -> dict:
        return {
            "save_id": self.save_id,
            "save_name": self.save_name,
            "created_time": self.created_time.isoformat(),
            "last_played": self.last_played.isoformat(),
            "play_time": self.play_time,
            "gold": self.gold,
            "map_id": self.map_id,
            "position": list(self.position),
            "party": self.party,
            "characters": {k: v.to_dict() for k, v in self.characters.items()},
            "inventory": [item.to_dict() for item in self.inventory],
            "flags": list(self.flags),
            "completed_quests": list(self.completed_quests),
            "unlocked_maps": list(self.unlocked_maps),
        }
    
    @staticmethod
    def from_dict(data: dict) -> 'SaveData':
        save = SaveData(
            save_id=data["save_id"],
            save_name=data["save_name"],
            created_time=datetime.fromisoformat(data.get("created_time", datetime.now().isoformat())),
            last_played=datetime.fromisoformat(data.get("last_played", datetime.now().isoformat())),
            play_time=data.get("play_time", 0.0),
            gold=data.get("gold", 0),
            map_id=data.get("map_id", 1),
            position=tuple(data.get("position", [10, 10])),
            party=data.get("party", []),
        )
        
        save.characters = {
            int(k): CharacterStats.from_dict(v)
            for k, v in data.get("characters", {}).items()
        }
        save.inventory = [
            InventoryItem.from_dict(item)
            for item in data.get("inventory", [])
        ]
        save.flags = set(data.get("flags", []))
        save.completed_quests = set(data.get("completed_quests", []))
        save.unlocked_maps = set(data.get("unlocked_maps", []))
        
        return save


class SaveFileEditor:
    """Save file editor UI"""
    
    def __init__(self, width: int = 1400, height: int = 900):
        self.width = width
        self.height = height
        self.running = True
        
        pygame.init()
        self.screen = pygame.display.set_mode((width, height))
        pygame.display.set_caption("Save File Editor")
        self.clock = pygame.time.Clock()
        
        self.font = pygame.font.Font(None, 24)
        self.small_font = pygame.font.Font(None, 18)
        
        # Sample save data
        self.save_data = self._create_sample_save()
        self.selected_character: Optional[CharacterStats] = None
        self.current_tab = 0  # 0=Stats, 1=Inventory, 2=Progress
        self.scroll = 0
    
    def _create_sample_save(self) -> SaveData:
        """Create sample save"""
        save = SaveData(
            save_id=1,
            save_name="Adventure Save",
            play_time=7200.0,  # 2 hours
            gold=5000,
            map_id=1,
            position=(50, 30),
            party=[1, 2],
        )
        
        # Add characters
        save.characters[1] = CharacterStats(
            character_id=1,
            name="Hero",
            level=15,
            exp=8500,
            hp=250,
            max_hp=250,
            mp=120,
            max_mp=120,
            strength=35,
            defense=28,
            magic=25,
            speed=30,
            equipment={"weapon": 5, "armor": 3, "accessory_1": 10},
            learned_skills=[1, 2, 3, 5, 8],
        )
        
        save.characters[2] = CharacterStats(
            character_id=2,
            name="Mage",
            level=14,
            exp=7800,
            hp=180,
            max_hp=180,
            mp=200,
            max_mp=200,
            strength=18,
            defense=20,
            magic=45,
            speed=25,
            equipment={"weapon": 12, "armor": 8},
            learned_skills=[10, 11, 12, 13, 14, 15],
        )
        
        # Add inventory
        save.inventory = [
            InventoryItem(1, 10),  # 10x Potion
            InventoryItem(2, 5),   # 5x Ether
            InventoryItem(10, 3),  # 3x Phoenix Down
            InventoryItem(20, 1),  # 1x Rare Item
        ]
        
        # Add progress
        save.flags = {"tutorial_complete", "met_elder", "defeated_boss_1"}
        save.completed_quests = {1, 2, 3, 5}
        save.unlocked_maps = {1, 2, 3, 10}
        
        return save
    
    def run(self):
        """Main loop"""
        while self.running:
            self._handle_events()
            self._render()
            self.clock.tick(60)
        
        pygame.quit()
    
    def _handle_events(self):
        """Handle events"""
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                self.running = False
            
            elif event.type == pygame.KEYDOWN:
                if event.key == pygame.K_ESCAPE:
                    self.running = False
                elif event.key == pygame.K_s and pygame.key.get_mods() & pygame.KMOD_CTRL:
                    self._save_file()
                elif event.key == pygame.K_1:
                    self.current_tab = 0
                elif event.key == pygame.K_2:
                    self.current_tab = 1
                elif event.key == pygame.K_3:
                    self.current_tab = 2
            
            elif event.type == pygame.MOUSEBUTTONDOWN:
                self._handle_click(event.pos, event.button)
            
            elif event.type == pygame.MOUSEWHEEL:
                self.scroll = max(0, self.scroll - event.y * 20)
    
    def _handle_click(self, pos: tuple, button: int):
        """Handle mouse click"""
        x, y = pos
        
        # Tab bar
        if 50 < y < 80:
            if 50 < x < 200:
                self.current_tab = 0
            elif 200 < x < 350:
                self.current_tab = 1
            elif 350 < x < 500:
                self.current_tab = 2
        
        # Character selection
        if self.current_tab == 0 and 50 < x < 300:
            y_offset = 120 - self.scroll
            for char in self.save_data.characters.values():
                if y_offset < y < y_offset + 60:
                    self.selected_character = char
                    break
                y_offset += 65
    
    def _save_file(self):
        """Save to file"""
        filename = f"save_{self.save_data.save_id}.json"
        with open(filename, 'w') as f:
            json.dump(self.save_data.to_dict(), f, indent=2)
        print(f"Saved to {filename}")
    
    def _render(self):
        """Render UI"""
        self.screen.fill((25, 25, 35))
        
        # Toolbar
        pygame.draw.rect(self.screen, (45, 45, 55), (0, 0, self.width, 40))
        title = self.font.render(f"Save: {self.save_data.save_name}", True, (255, 255, 255))
        self.screen.blit(title, (10, 10))
        
        info = self.small_font.render(
            f"Time: {self.save_data.get_play_time_str()} | Gold: {self.save_data.gold}g | Map: #{self.save_data.map_id}",
            True, (180, 180, 180))
        self.screen.blit(info, (400, 12))
        
        # Tab bar
        self._draw_tabs()
        
        # Content
        if self.current_tab == 0:
            self._draw_stats_tab()
        elif self.current_tab == 1:
            self._draw_inventory_tab()
        elif self.current_tab == 2:
            self._draw_progress_tab()
        
        pygame.display.flip()
    
    def _draw_tabs(self):
        """Draw tab bar"""
        tabs = ["Stats", "Inventory", "Progress"]
        tab_y = 50
        
        for i, name in enumerate(tabs):
            x = 50 + i * 150
            color = (80, 80, 120) if i == self.current_tab else (50, 50, 70)
            pygame.draw.rect(self.screen, color, (x, tab_y, 145, 30))
            pygame.draw.rect(self.screen, (100, 100, 140), (x, tab_y, 145, 30), 1)
            
            text = self.small_font.render(name, True, (255, 255, 255))
            self.screen.blit(text, (x + 10, tab_y + 8))
    
    def _draw_stats_tab(self):
        """Draw stats tab"""
        # Character list
        pygame.draw.rect(self.screen, (35, 35, 45), (50, 100, 250, self.height - 150))
        
        y = 120 - self.scroll
        for char in self.save_data.characters.values():
            bg = (60, 60, 80) if char == self.selected_character else (45, 45, 55)
            pygame.draw.rect(self.screen, bg, (55, y, 240, 60))
            
            name = self.small_font.render(f"{char.name} Lv.{char.level}", True, (200, 200, 255))
            self.screen.blit(name, (65, y + 10))
            
            hp = self.small_font.render(f"HP: {char.hp}/{char.max_hp}", True, (150, 255, 150))
            self.screen.blit(hp, (65, y + 30))
            
            y += 65
        
        # Stats panel
        if self.selected_character:
            pygame.draw.rect(self.screen, (35, 35, 45), (320, 100, 500, self.height - 150))
            
            char = self.selected_character
            y = 120
            
            stats = [
                ("Name", char.name),
                ("Level", str(char.level)),
                ("EXP", str(char.exp)),
                ("HP", f"{char.hp}/{char.max_hp}"),
                ("MP", f"{char.mp}/{char.max_mp}"),
                ("STR", str(char.strength)),
                ("DEF", str(char.defense)),
                ("MAG", str(char.magic)),
                ("SPD", str(char.speed)),
            ]
            
            for label, value in stats:
                lbl = self.small_font.render(f"{label}:", True, (180, 180, 180))
                self.screen.blit(lbl, (340, y))
                
                val = self.small_font.render(value, True, (255, 255, 255))
                self.screen.blit(val, (500, y))
                
                y += 30
    
    def _draw_inventory_tab(self):
        """Draw inventory tab"""
        pygame.draw.rect(self.screen, (35, 35, 45), (50, 100, 600, self.height - 150))
        
        y = 120 - self.scroll
        for item in self.save_data.inventory:
            pygame.draw.rect(self.screen, (45, 45, 55), (60, y, 580, 40))
            
            item_text = self.small_font.render(f"Item #{item.item_id}", True, (200, 200, 255))
            self.screen.blit(item_text, (70, y + 12))
            
            qty = self.small_font.render(f"x{item.quantity}", True, (150, 255, 150))
            self.screen.blit(qty, (500, y + 12))
            
            y += 45
    
    def _draw_progress_tab(self):
        """Draw progress tab"""
        pygame.draw.rect(self.screen, (35, 35, 45), (50, 100, 700, self.height - 150))
        
        y = 120
        
        # Flags
        title = self.font.render("Flags", True, (200, 200, 255))
        self.screen.blit(title, (70, y))
        y += 35
        
        for flag in sorted(self.save_data.flags):
            text = self.small_font.render(f"• {flag}", True, (180, 180, 180))
            self.screen.blit(text, (80, y))
            y += 22
        
        y += 20
        
        # Quests
        title = self.font.render("Completed Quests", True, (200, 200, 255))
        self.screen.blit(title, (70, y))
        y += 35
        
        for qid in sorted(self.save_data.completed_quests):
            text = self.small_font.render(f"Quest #{qid}", True, (180, 180, 180))
            self.screen.blit(text, (80, y))
            y += 22


def main():
    editor = SaveFileEditor()
    editor.run()


if __name__ == "__main__":
    main()
