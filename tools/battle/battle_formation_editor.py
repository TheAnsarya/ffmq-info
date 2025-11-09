#!/usr/bin/env python3
"""
Battle Formation Editor

Battle encounter and enemy formation designer.
Features:
- Enemy positioning
- Wave patterns
- Reinforcement timing
- Victory/defeat conditions
- Formation templates
- Enemy group management
"""

from dataclasses import dataclass, field
from enum import Enum
from typing import List, Optional, Tuple
import pygame
import json
import math


class FormationType(Enum):
    """Formation types"""
    STANDARD = "standard"
    AMBUSH = "ambush"
    PINCER = "pincer"
    BACK_ATTACK = "back_attack"
    BOSS = "boss"


class ReinforcementTrigger(Enum):
    """Reinforcement triggers"""
    TURN = "turn"
    HP_THRESHOLD = "hp_threshold"
    ENEMY_DEFEATED = "enemy_defeated"
    TIME_ELAPSED = "time_elapsed"


@dataclass
class EnemyPosition:
    """Enemy in formation"""
    enemy_id: int
    position: Tuple[int, int]
    wave: int = 0
    is_reinforcement: bool = False
    
    def to_dict(self) -> dict:
        return {
            "enemy_id": self.enemy_id,
            "position": list(self.position),
            "wave": self.wave,
            "is_reinforcement": self.is_reinforcement,
        }
    
    @staticmethod
    def from_dict(data: dict) -> 'EnemyPosition':
        return EnemyPosition(
            enemy_id=data["enemy_id"],
            position=tuple(data["position"]),
            wave=data.get("wave", 0),
            is_reinforcement=data.get("is_reinforcement", False),
        )


@dataclass
class Reinforcement:
    """Reinforcement wave"""
    wave_id: int
    trigger: ReinforcementTrigger
    trigger_value: int
    enemies: List[EnemyPosition] = field(default_factory=list)
    
    def to_dict(self) -> dict:
        return {
            "wave_id": self.wave_id,
            "trigger": self.trigger.value,
            "trigger_value": self.trigger_value,
            "enemies": [e.to_dict() for e in self.enemies],
        }
    
    @staticmethod
    def from_dict(data: dict) -> 'Reinforcement':
        return Reinforcement(
            wave_id=data["wave_id"],
            trigger=ReinforcementTrigger(data["trigger"]),
            trigger_value=data["trigger_value"],
            enemies=[EnemyPosition.from_dict(e) for e in data.get("enemies", [])],
        )


@dataclass
class BattleFormation:
    """Battle formation"""
    formation_id: int
    name: str
    formation_type: FormationType
    enemies: List[EnemyPosition] = field(default_factory=list)
    reinforcements: List[Reinforcement] = field(default_factory=list)
    music_id: int = 1
    background_id: int = 1
    can_escape: bool = True
    
    def to_dict(self) -> dict:
        return {
            "formation_id": self.formation_id,
            "name": self.name,
            "formation_type": self.formation_type.value,
            "enemies": [e.to_dict() for e in self.enemies],
            "reinforcements": [r.to_dict() for r in self.reinforcements],
            "music_id": self.music_id,
            "background_id": self.background_id,
            "can_escape": self.can_escape,
        }
    
    @staticmethod
    def from_dict(data: dict) -> 'BattleFormation':
        return BattleFormation(
            formation_id=data["formation_id"],
            name=data["name"],
            formation_type=FormationType(data.get("formation_type", "standard")),
            enemies=[EnemyPosition.from_dict(e) for e in data.get("enemies", [])],
            reinforcements=[Reinforcement.from_dict(r) for r in data.get("reinforcements", [])],
            music_id=data.get("music_id", 1),
            background_id=data.get("background_id", 1),
            can_escape=data.get("can_escape", True),
        )


class BattleFormationEditor:
    """Battle formation editor UI"""
    
    def __init__(self, width: int = 1400, height: int = 900):
        self.width = width
        self.height = height
        self.running = True
        
        pygame.init()
        self.screen = pygame.display.set_mode((width, height))
        pygame.display.set_caption("Battle Formation Editor")
        self.clock = pygame.time.Clock()
        
        self.font = pygame.font.Font(None, 24)
        self.small_font = pygame.font.Font(None, 18)
        
        # Sample formations
        self.formations = self._create_samples()
        self.current_formation: Optional[BattleFormation] = self.formations[0] if self.formations else None
        self.selected_enemy: Optional[EnemyPosition] = None
        self.dragging = False
        
        # Battle field dimensions
        self.field_x = 400
        self.field_y = 150
        self.field_width = 600
        self.field_height = 400
    
    def _create_samples(self) -> List[BattleFormation]:
        """Create sample formations"""
        formations = []
        
        # Standard encounter
        formation1 = BattleFormation(
            formation_id=1,
            name="Goblin Pack",
            formation_type=FormationType.STANDARD,
            enemies=[
                EnemyPosition(1, (150, 100)),
                EnemyPosition(1, (250, 120)),
                EnemyPosition(2, (350, 110)),
            ],
            can_escape=True,
        )
        formations.append(formation1)
        
        # Boss battle
        formation2 = BattleFormation(
            formation_id=2,
            name="Dragon Boss",
            formation_type=FormationType.BOSS,
            enemies=[
                EnemyPosition(10, (300, 150)),
            ],
            reinforcements=[
                Reinforcement(
                    wave_id=1,
                    trigger=ReinforcementTrigger.HP_THRESHOLD,
                    trigger_value=50,
                    enemies=[
                        EnemyPosition(5, (100, 100), wave=1, is_reinforcement=True),
                        EnemyPosition(5, (500, 100), wave=1, is_reinforcement=True),
                    ],
                ),
            ],
            can_escape=False,
        )
        formations.append(formation2)
        
        return formations
    
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
                    self._save()
                elif event.key == pygame.K_DELETE and self.selected_enemy:
                    if self.current_formation:
                        self.current_formation.enemies.remove(self.selected_enemy)
                        self.selected_enemy = None
            
            elif event.type == pygame.MOUSEBUTTONDOWN:
                self._handle_click(event.pos, event.button)
            
            elif event.type == pygame.MOUSEBUTTONUP:
                self.dragging = False
            
            elif event.type == pygame.MOUSEMOTION and self.dragging:
                self._handle_drag(event.pos)
    
    def _handle_click(self, pos: tuple, button: int):
        """Handle click"""
        x, y = pos
        
        # Formation list
        if x < 250:
            y_offset = 80
            for formation in self.formations:
                if y_offset < y < y_offset + 50:
                    self.current_formation = formation
                    self.selected_enemy = None
                    break
                y_offset += 55
        
        # Battle field
        elif self.field_x < x < self.field_x + self.field_width:
            if self.field_y < y < self.field_y + self.field_height:
                if button == 1:  # Left click
                    self._select_enemy_at(x - self.field_x, y - self.field_y)
                    if self.selected_enemy:
                        self.dragging = True
    
    def _select_enemy_at(self, fx: int, fy: int):
        """Select enemy at field position"""
        if not self.current_formation:
            return
        
        for enemy in self.current_formation.enemies:
            ex, ey = enemy.position
            dist = math.sqrt((fx - ex)**2 + (fy - ey)**2)
            if dist < 25:
                self.selected_enemy = enemy
                return
        
        self.selected_enemy = None
    
    def _handle_drag(self, pos: tuple):
        """Handle dragging"""
        if not self.selected_enemy:
            return
        
        x, y = pos
        fx = x - self.field_x
        fy = y - self.field_y
        
        # Clamp to field
        fx = max(0, min(self.field_width, fx))
        fy = max(0, min(self.field_height, fy))
        
        self.selected_enemy.position = (fx, fy)
    
    def _save(self):
        """Save formations"""
        data = {"formations": [f.to_dict() for f in self.formations]}
        with open("battle_formations.json", 'w') as f:
            json.dump(data, f, indent=2)
        print("Saved to battle_formations.json")
    
    def _render(self):
        """Render UI"""
        self.screen.fill((25, 25, 35))
        
        # Toolbar
        pygame.draw.rect(self.screen, (45, 45, 55), (0, 0, self.width, 40))
        title = self.font.render("Battle Formation Editor", True, (255, 255, 255))
        self.screen.blit(title, (10, 10))
        
        # Formation list
        self._draw_formation_list()
        
        # Battle field
        self._draw_battle_field()
        
        # Properties
        self._draw_properties()
        
        pygame.display.flip()
    
    def _draw_formation_list(self):
        """Draw formation list"""
        pygame.draw.rect(self.screen, (35, 35, 45), (0, 50, 250, self.height - 50))
        
        y = 80
        for formation in self.formations:
            bg = (60, 60, 80) if formation == self.current_formation else (45, 45, 55)
            pygame.draw.rect(self.screen, bg, (10, y, 230, 50))
            
            name = self.small_font.render(formation.name, True, (200, 200, 255))
            self.screen.blit(name, (20, y + 8))
            
            info = self.small_font.render(
                f"{len(formation.enemies)} enemies | {formation.formation_type.value}",
                True, (150, 150, 150))
            self.screen.blit(info, (20, y + 28))
            
            y += 55
    
    def _draw_battle_field(self):
        """Draw battle field"""
        # Background
        pygame.draw.rect(self.screen, (20, 30, 40),
                         (self.field_x, self.field_y, self.field_width, self.field_height))
        pygame.draw.rect(self.screen, (80, 80, 100),
                         (self.field_x, self.field_y, self.field_width, self.field_height), 2)
        
        if not self.current_formation:
            return
        
        # Draw grid
        for i in range(0, self.field_width, 50):
            pygame.draw.line(self.screen, (40, 50, 60),
                             (self.field_x + i, self.field_y),
                             (self.field_x + i, self.field_y + self.field_height))
        
        for i in range(0, self.field_height, 50):
            pygame.draw.line(self.screen, (40, 50, 60),
                             (self.field_x, self.field_y + i),
                             (self.field_x + self.field_width, self.field_y + i))
        
        # Draw enemies
        for enemy in self.current_formation.enemies:
            ex, ey = enemy.position
            x = self.field_x + ex
            y = self.field_y + ey
            
            # Color by wave
            if enemy.is_reinforcement:
                color = (255, 150, 100)
            else:
                color = (150, 100, 255)
            
            # Circle
            radius = 25
            if enemy == self.selected_enemy:
                pygame.draw.circle(self.screen, (255, 255, 100), (x, y), radius + 3, 2)
            
            pygame.draw.circle(self.screen, color, (x, y), radius)
            pygame.draw.circle(self.screen, (255, 255, 255), (x, y), radius, 2)
            
            # Enemy ID
            id_text = self.small_font.render(f"#{enemy.enemy_id}", True, (255, 255, 255))
            self.screen.blit(id_text, (x - 12, y - 8))
    
    def _draw_properties(self):
        """Draw properties panel"""
        panel_x = self.width - 350
        pygame.draw.rect(self.screen, (35, 35, 45),
                         (panel_x, 50, 350, self.height - 50))
        
        if not self.current_formation:
            return
        
        y = 80
        
        # Formation info
        title = self.font.render("Formation", True, (200, 200, 255))
        self.screen.blit(title, (panel_x + 15, y))
        y += 35
        
        props = [
            ("Name", self.current_formation.name),
            ("Type", self.current_formation.formation_type.value),
            ("Enemies", str(len(self.current_formation.enemies))),
            ("Can Escape", "Yes" if self.current_formation.can_escape else "No"),
            ("Music ID", f"#{self.current_formation.music_id}"),
            ("BG ID", f"#{self.current_formation.background_id}"),
        ]
        
        for label, value in props:
            lbl = self.small_font.render(f"{label}:", True, (180, 180, 180))
            self.screen.blit(lbl, (panel_x + 25, y))
            
            val = self.small_font.render(value, True, (255, 255, 255))
            self.screen.blit(val, (panel_x + 200, y))
            
            y += 25
        
        # Reinforcements
        if self.current_formation.reinforcements:
            y += 20
            title = self.font.render("Reinforcements", True, (200, 200, 255))
            self.screen.blit(title, (panel_x + 15, y))
            y += 35
            
            for reinf in self.current_formation.reinforcements:
                wave_text = self.small_font.render(
                    f"Wave {reinf.wave_id}: {reinf.trigger.value} @ {reinf.trigger_value}",
                    True, (255, 150, 100))
                self.screen.blit(wave_text, (panel_x + 25, y))
                y += 22


def main():
    editor = BattleFormationEditor()
    editor.run()


if __name__ == "__main__":
    main()
