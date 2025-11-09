"""
Advanced Battle System Editor for FFMQ
Edit enemy formations, AI patterns, battle events.
"""

import pygame
import json
from dataclasses import dataclass, field
from typing import List, Tuple, Optional, Dict
from enum import Enum
import random


class EnemyAIPattern(Enum):
    """AI behavior patterns"""
    AGGRESSIVE = "aggressive"
    DEFENSIVE = "defensive"
    BALANCED = "balanced"
    SUPPORT = "support"
    RANDOM = "random"
    SCRIPTED = "scripted"


class AttackType(Enum):
    """Attack types"""
    PHYSICAL = "physical"
    MAGICAL = "magical"
    SPECIAL = "special"
    STATUS = "status"
    HEAL = "heal"
    BUFF = "buff"
    DEBUFF = "debuff"


class TargetPattern(Enum):
    """Target selection patterns"""
    SINGLE_RANDOM = "single_random"
    SINGLE_LOWEST_HP = "single_lowest_hp"
    SINGLE_HIGHEST_HP = "single_highest_hp"
    ALL_ENEMIES = "all_enemies"
    ALL_ALLIES = "all_allies"
    SELF = "self"
    FRONT_ROW = "front_row"
    BACK_ROW = "back_row"


class ElementType(Enum):
    """Elemental types"""
    NONE = "none"
    FIRE = "fire"
    ICE = "ice"
    THUNDER = "thunder"
    EARTH = "earth"
    WIND = "wind"
    WATER = "water"
    HOLY = "holy"
    DARK = "dark"


@dataclass
class StatusEffect:
    """Status effect definition"""
    effect_id: int
    name: str
    duration: int  # Turns
    chance: int  # 0-100%
    stackable: bool = False
    
    def to_dict(self):
        return {
            'effect_id': self.effect_id,
            'name': self.name,
            'duration': self.duration,
            'chance': self.chance,
            'stackable': self.stackable
        }


@dataclass
class Attack:
    """Enemy attack definition"""
    attack_id: int
    name: str
    attack_type: AttackType
    element: ElementType
    power: int  # Base damage/effect
    accuracy: int  # 0-100%
    mp_cost: int = 0
    target_pattern: TargetPattern = TargetPattern.SINGLE_RANDOM
    status_effects: List[StatusEffect] = field(default_factory=list)
    animation_id: int = 0
    
    def to_dict(self):
        return {
            'attack_id': self.attack_id,
            'name': self.name,
            'attack_type': self.attack_type.value,
            'element': self.element.value,
            'power': self.power,
            'accuracy': self.accuracy,
            'mp_cost': self.mp_cost,
            'target_pattern': self.target_pattern.value,
            'status_effects': [se.to_dict() for se in self.status_effects],
            'animation_id': self.animation_id
        }


@dataclass
class AICondition:
    """AI decision condition"""
    condition_type: str  # "hp_below", "ally_dead", "turn_count", etc.
    threshold: any
    action: Attack
    priority: int = 5  # 0-10, higher = more important
    
    def to_dict(self):
        return {
            'condition_type': self.condition_type,
            'threshold': self.threshold,
            'action': self.action.to_dict(),
            'priority': self.priority
        }


@dataclass
class EnemyData:
    """Complete enemy definition"""
    enemy_id: int
    name: str
    level: int
    hp: int
    mp: int
    attack: int
    defense: int
    magic: int
    speed: int
    
    # Resistances (0-100%, can be negative for weakness)
    physical_resist: int = 0
    magical_resist: int = 0
    elemental_resist: Dict[ElementType, int] = field(default_factory=dict)
    
    # AI
    ai_pattern: EnemyAIPattern = EnemyAIPattern.BALANCED
    attacks: List[Attack] = field(default_factory=list)
    ai_conditions: List[AICondition] = field(default_factory=list)
    
    # Visuals
    sprite_id: int = 0
    palette_id: int = 0
    
    # Rewards
    exp: int = 0
    gold: int = 0
    item_drops: List[Tuple[str, int]] = field(default_factory=list)  # (item, chance%)
    
    def to_dict(self):
        return {
            'enemy_id': self.enemy_id,
            'name': self.name,
            'level': self.level,
            'hp': self.hp,
            'mp': self.mp,
            'attack': self.attack,
            'defense': self.defense,
            'magic': self.magic,
            'speed': self.speed,
            'physical_resist': self.physical_resist,
            'magical_resist': self.magical_resist,
            'elemental_resist': {k.value: v for k, v in
                                 self.elemental_resist.items()},
            'ai_pattern': self.ai_pattern.value,
            'attacks': [a.to_dict() for a in self.attacks],
            'ai_conditions': [c.to_dict() for c in self.ai_conditions],
            'sprite_id': self.sprite_id,
            'palette_id': self.palette_id,
            'exp': self.exp,
            'gold': self.gold,
            'item_drops': self.item_drops
        }


@dataclass
class FormationSlot:
    """Enemy position in formation"""
    enemy: EnemyData
    x: int  # Position on battlefield (0-255)
    y: int  # Position on battlefield (0-191)
    visible_at_start: bool = True
    reinforcement: bool = False  # Appears mid-battle
    reinforcement_turn: int = 0
    
    def to_dict(self):
        return {
            'enemy_id': self.enemy.enemy_id,
            'x': self.x,
            'y': self.y,
            'visible_at_start': self.visible_at_start,
            'reinforcement': self.reinforcement,
            'reinforcement_turn': self.reinforcement_turn
        }


@dataclass
class BattleFormation:
    """Complete battle formation"""
    formation_id: int
    name: str
    slots: List[FormationSlot] = field(default_factory=list)
    background_id: int = 0
    music_id: int = 0
    
    # Battle events
    intro_script: Optional[int] = None
    victory_script: Optional[int] = None
    escape_allowed: bool = True
    
    def to_dict(self):
        return {
            'formation_id': self.formation_id,
            'name': self.name,
            'slots': [s.to_dict() for s in self.slots],
            'background_id': self.background_id,
            'music_id': self.music_id,
            'intro_script': self.intro_script,
            'victory_script': self.victory_script,
            'escape_allowed': self.escape_allowed
        }


class BattlePreview:
    """Visual preview of battle formation"""
    
    def __init__(self, width: int = 600, height: int = 400):
        self.width = width
        self.height = height
        self.surface = pygame.Surface((width, height))
        
    def draw_formation(self, formation: BattleFormation):
        """Draw formation preview"""
        # Background
        self.surface.fill((20, 40, 60))
        
        # Grid
        for x in range(0, self.width, 50):
            pygame.draw.line(self.surface, (40, 60, 80), (x, 0), (x, self.height))
        for y in range(0, self.height, 50):
            pygame.draw.line(self.surface, (40, 60, 80), (0, y), (self.width, y))
        
        font = pygame.font.Font(None, 20)
        
        # Draw enemies
        for i, slot in enumerate(formation.slots):
            # Scale position to preview
            x = int(slot.x * self.width / 256)
            y = int(slot.y * self.height / 192)
            
            # Enemy box
            color = (255, 100, 100) if slot.visible_at_start else (100, 100, 100)
            if slot.reinforcement:
                color = (255, 200, 100)
            
            pygame.draw.rect(self.surface, color, (x - 30, y - 30, 60, 60))
            pygame.draw.rect(self.surface, (255, 255, 255),
                             (x - 30, y - 30, 60, 60), 2)
            
            # Enemy name
            name = slot.enemy.name[:8]
            text = font.render(name, True, (255, 255, 255))
            text_rect = text.get_rect(center=(x, y - 15))
            self.surface.blit(text, text_rect)
            
            # Level
            level_text = f"Lv{slot.enemy.level}"
            text = font.render(level_text, True, (255, 255, 100))
            text_rect = text.get_rect(center=(x, y + 5))
            self.surface.blit(text, text_rect)
            
            # HP
            hp_text = f"{slot.enemy.hp}HP"
            text = font.render(hp_text, True, (100, 255, 100))
            text_rect = text.get_rect(center=(x, y + 20))
            self.surface.blit(text, text_rect)


class BattleEditor:
    """Interactive battle editor"""
    
    def __init__(self):
        pygame.init()
        self.screen = pygame.display.set_mode((1400, 850))
        pygame.display.set_caption("FFMQ Battle System Editor")
        self.clock = pygame.time.Clock()
        
        self.font = pygame.font.Font(None, 24)
        self.small_font = pygame.font.Font(None, 20)
        
        # Sample data
        self.enemies = self._create_sample_enemies()
        self.formations = self._create_sample_formations()
        
        self.current_formation = self.formations[0]
        self.selected_enemy = None
        self.selected_slot = None
        
        self.preview = BattlePreview(600, 400)
        
        self.mode = "formation"  # "formation", "enemy", "ai"
        
    def _create_sample_enemies(self) -> List[EnemyData]:
        """Create sample enemies"""
        # Basic attacks
        slash = Attack(
            0, "Slash", AttackType.PHYSICAL, ElementType.NONE,
            power=20, accuracy=90
        )
        
        fireball = Attack(
            1, "Fireball", AttackType.MAGICAL, ElementType.FIRE,
            power=35, accuracy=95, mp_cost=5,
            target_pattern=TargetPattern.SINGLE_RANDOM
        )
        
        heal = Attack(
            2, "Heal", AttackType.HEAL, ElementType.HOLY,
            power=30, accuracy=100, mp_cost=8,
            target_pattern=TargetPattern.SINGLE_LOWEST_HP
        )
        
        return [
            EnemyData(
                0, "Goblin", 3, 45, 0, 12, 8, 5, 10,
                attacks=[slash],
                ai_pattern=EnemyAIPattern.AGGRESSIVE,
                exp=15, gold=20,
                item_drops=[("Potion", 30)]
            ),
            EnemyData(
                1, "Skeleton", 5, 70, 10, 15, 10, 8, 8,
                attacks=[slash],
                ai_pattern=EnemyAIPattern.BALANCED,
                exp=30, gold=35,
                item_drops=[("Bone", 50), ("Potion", 25)]
            ),
            EnemyData(
                2, "Fire Mage", 7, 55, 40, 8, 6, 18, 12,
                attacks=[fireball],
                ai_pattern=EnemyAIPattern.BALANCED,
                elemental_resist={ElementType.FIRE: 50, ElementType.ICE: -50},
                exp=50, gold=60,
                item_drops=[("Fire Scroll", 20)]
            ),
            EnemyData(
                3, "Priest", 6, 60, 50, 10, 8, 15, 9,
                attacks=[slash, heal],
                ai_pattern=EnemyAIPattern.SUPPORT,
                exp=45, gold=50,
                item_drops=[("Heal Herb", 40)]
            ),
        ]
    
    def _create_sample_formations(self) -> List[BattleFormation]:
        """Create sample formations"""
        formations = []
        
        # Formation 1: Three goblins
        form1 = BattleFormation(0, "Goblin Trio", background_id=1)
        form1.slots = [
            FormationSlot(self.enemies[0], 100, 80),
            FormationSlot(self.enemies[0], 150, 120),
            FormationSlot(self.enemies[0], 200, 100)
        ]
        formations.append(form1)
        
        # Formation 2: Mixed group
        form2 = BattleFormation(1, "Mixed Group", background_id=2)
        form2.slots = [
            FormationSlot(self.enemies[1], 120, 100),
            FormationSlot(self.enemies[2], 180, 90),
            FormationSlot(self.enemies[0], 150, 140)
        ]
        formations.append(form2)
        
        # Formation 3: Boss with reinforcements
        form3 = BattleFormation(2, "Boss Battle", background_id=3,
                                escape_allowed=False)
        form3.slots = [
            FormationSlot(self.enemies[3], 150, 100),  # Boss (Priest)
            FormationSlot(self.enemies[0], 100, 140, reinforcement=True,
                          reinforcement_turn=3),
            FormationSlot(self.enemies[0], 200, 140, reinforcement=True,
                          reinforcement_turn=3)
        ]
        formations.append(form3)
        
        return formations
    
    def draw_formation_list(self):
        """Draw formation selector"""
        list_rect = pygame.Rect(20, 50, 250, 300)
        pygame.draw.rect(self.screen, (40, 40, 40), list_rect)
        pygame.draw.rect(self.screen, (200, 200, 200), list_rect, 2)
        
        y = 60
        for form in self.formations:
            item_rect = pygame.Rect(30, y, 230, 30)
            
            if form == self.current_formation:
                pygame.draw.rect(self.screen, (80, 80, 150), item_rect)
            
            text = self.small_font.render(
                f"{form.formation_id}: {form.name}",
                True, (255, 255, 255)
            )
            self.screen.blit(text, (40, y + 5))
            
            y += 35
    
    def draw_enemy_list(self):
        """Draw enemy database"""
        list_rect = pygame.Rect(20, 370, 250, 430)
        pygame.draw.rect(self.screen, (40, 40, 40), list_rect)
        pygame.draw.rect(self.screen, (200, 200, 200), list_rect, 2)
        
        # Title
        title = self.small_font.render("Enemy Database", True, (200, 200, 200))
        self.screen.blit(title, (30, 375))
        
        y = 400
        for enemy in self.enemies:
            item_rect = pygame.Rect(30, y, 230, 60)
            
            if enemy == self.selected_enemy:
                pygame.draw.rect(self.screen, (80, 150, 80), item_rect)
            
            # Enemy name and level
            text = self.small_font.render(
                f"{enemy.name} (Lv{enemy.level})",
                True, (255, 255, 255)
            )
            self.screen.blit(text, (40, y + 5))
            
            # Stats
            stats = f"HP:{enemy.hp} ATK:{enemy.attack} DEF:{enemy.defense}"
            text = self.small_font.render(stats, True, (200, 200, 200))
            self.screen.blit(text, (40, y + 25))
            
            # AI pattern
            ai_text = f"AI: {enemy.ai_pattern.value}"
            text = self.small_font.render(ai_text, True, (150, 150, 255))
            self.screen.blit(text, (40, y + 42))
            
            y += 65
    
    def draw_formation_preview(self):
        """Draw battle preview"""
        # Update preview
        self.preview.draw_formation(self.current_formation)
        
        # Draw to screen
        preview_rect = pygame.Rect(290, 50, 600, 400)
        pygame.draw.rect(self.screen, (200, 200, 200), preview_rect, 2)
        self.screen.blit(self.preview.surface, (290, 50))
        
        # Formation info
        info_y = 470
        
        # Name
        text = self.font.render(
            f"Formation: {self.current_formation.name}",
            True, (255, 255, 255)
        )
        self.screen.blit(text, (290, info_y))
        info_y += 30
        
        # Enemy count
        visible = sum(1 for s in self.current_formation.slots if s.visible_at_start)
        total = len(self.current_formation.slots)
        text = self.small_font.render(
            f"Enemies: {visible} visible, {total - visible} reinforcements",
            True, (200, 200, 200)
        )
        self.screen.blit(text, (290, info_y))
        info_y += 25
        
        # Escape
        escape_text = "Escape: " + ("Allowed" if
                                    self.current_formation.escape_allowed else "Disabled")
        text = self.small_font.render(escape_text, True, (200, 200, 200))
        self.screen.blit(text, (290, info_y))
    
    def draw_slot_details(self):
        """Draw selected slot details"""
        panel_rect = pygame.Rect(910, 50, 460, 750)
        pygame.draw.rect(self.screen, (50, 50, 50), panel_rect)
        pygame.draw.rect(self.screen, (200, 200, 200), panel_rect, 2)
        
        if self.selected_slot is None:
            text = self.font.render("Select an enemy slot", True, (255, 255, 255))
            self.screen.blit(text, (930, 100))
            return
        
        y = 70
        enemy = self.selected_slot.enemy
        
        # Enemy name
        text = self.font.render(enemy.name, True, (255, 255, 100))
        self.screen.blit(text, (930, y))
        y += 35
        
        # Stats
        stats = [
            f"Level: {enemy.level}",
            f"HP: {enemy.hp}",
            f"MP: {enemy.mp}",
            f"Attack: {enemy.attack}",
            f"Defense: {enemy.defense}",
            f"Magic: {enemy.magic}",
            f"Speed: {enemy.speed}"
        ]
        
        for stat in stats:
            text = self.small_font.render(stat, True, (255, 255, 255))
            self.screen.blit(text, (930, y))
            y += 22
        
        y += 10
        
        # Resistances
        text = self.small_font.render("Resistances:", True, (200, 200, 200))
        self.screen.blit(text, (930, y))
        y += 22
        
        resist_text = f"Physical: {enemy.physical_resist}%"
        text = self.small_font.render(resist_text, True, (255, 255, 255))
        self.screen.blit(text, (950, y))
        y += 20
        
        resist_text = f"Magical: {enemy.magical_resist}%"
        text = self.small_font.render(resist_text, True, (255, 255, 255))
        self.screen.blit(text, (950, y))
        y += 25
        
        # Attacks
        text = self.small_font.render("Attacks:", True, (200, 200, 200))
        self.screen.blit(text, (930, y))
        y += 22
        
        for attack in enemy.attacks:
            attack_text = f"{attack.name} ({attack.attack_type.value})"
            text = self.small_font.render(attack_text, True, (255, 200, 100))
            self.screen.blit(text, (950, y))
            y += 20
            
            power_text = f"  Power: {attack.power}, Acc: {attack.accuracy}%"
            text = self.small_font.render(power_text, True, (200, 200, 200))
            self.screen.blit(text, (970, y))
            y += 20
        
        y += 10
        
        # Position
        text = self.small_font.render("Position:", True, (200, 200, 200))
        self.screen.blit(text, (930, y))
        y += 22
        
        pos_text = f"X: {self.selected_slot.x}, Y: {self.selected_slot.y}"
        text = self.small_font.render(pos_text, True, (255, 255, 255))
        self.screen.blit(text, (950, y))
        y += 22
        
        # Reinforcement
        if self.selected_slot.reinforcement:
            text = self.small_font.render(
                f"Reinforcement (Turn {self.selected_slot.reinforcement_turn})",
                True, (255, 200, 100)
            )
            self.screen.blit(text, (950, y))
    
    def handle_click(self, pos: Tuple[int, int]):
        """Handle mouse clicks"""
        x, y = pos
        
        # Formation list
        if 20 <= x <= 270 and 50 <= y <= 350:
            idx = (y - 60) // 35
            if 0 <= idx < len(self.formations):
                self.current_formation = self.formations[idx]
                self.selected_slot = None
        
        # Enemy list
        elif 20 <= x <= 270 and 370 <= y <= 800:
            idx = (y - 400) // 65
            if 0 <= idx < len(self.enemies):
                self.selected_enemy = self.enemies[idx]
        
        # Preview area
        elif 290 <= x <= 890 and 50 <= y <= 450:
            # Find clicked enemy slot
            preview_x = x - 290
            preview_y = y - 50
            
            for slot in self.current_formation.slots:
                slot_x = int(slot.x * 600 / 256)
                slot_y = int(slot.y * 400 / 192)
                
                if abs(preview_x - slot_x) <= 30 and abs(preview_y - slot_y) <= 30:
                    self.selected_slot = slot
                    break
    
    def run(self):
        """Main editor loop"""
        running = True
        
        while running:
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    running = False
                
                elif event.type == pygame.MOUSEBUTTONDOWN:
                    if event.button == 1:
                        self.handle_click(event.pos)
                
                elif event.type == pygame.KEYDOWN:
                    if event.key == pygame.K_ESCAPE:
                        running = False
                    
                    elif event.key == pygame.K_s and (
                            pygame.key.get_mods() & pygame.KMOD_CTRL):
                        # Save formation
                        self.save_formation("test_formation.json")
                        print("Formation saved!")
                    
                    elif event.key == pygame.K_e and (
                            pygame.key.get_mods() & pygame.KMOD_CTRL):
                        # Export all
                        self.export_all("battle_data.json")
                        print("All battle data exported!")
            
            # Draw
            self.screen.fill((30, 30, 30))
            
            # Title
            title = self.font.render("Battle System Editor", True, (255, 255, 255))
            self.screen.blit(title, (20, 10))
            
            # Draw panels
            self.draw_formation_list()
            self.draw_enemy_list()
            self.draw_formation_preview()
            self.draw_slot_details()
            
            # Instructions
            inst = self.small_font.render(
                "Ctrl+S: Save Formation | Ctrl+E: Export All | ESC: Quit",
                True, (150, 150, 150)
            )
            self.screen.blit(inst, (20, 820))
            
            pygame.display.flip()
            self.clock.tick(60)
        
        pygame.quit()
    
    def save_formation(self, filepath: str):
        """Save current formation"""
        with open(filepath, 'w') as f:
            json.dump(self.current_formation.to_dict(), f, indent=2)
    
    def export_all(self, filepath: str):
        """Export all battle data"""
        data = {
            'enemies': [e.to_dict() for e in self.enemies],
            'formations': [f.to_dict() for f in self.formations]
        }
        with open(filepath, 'w') as f:
            json.dump(data, f, indent=2)


def main():
    """Run battle editor"""
    editor = BattleEditor()
    editor.run()


if __name__ == '__main__':
    main()
