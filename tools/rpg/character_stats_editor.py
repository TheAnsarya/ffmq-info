#!/usr/bin/env python3
"""
Character Stats Editor

Comprehensive character/enemy stats editor for RPG games.
Features include:
- Character stat management (HP, MP, Attack, Defense, etc.)
- Equipment and inventory editing
- Skill/Ability assignment
- Level progression curves
- Stat growth formulas
- Equipment bonuses and modifiers
- Status effect resistance
- AI pattern configuration
- Character sprites and animations
- Export to multiple formats

Stats Categories:
- Base Stats: HP, MP, STR, DEF, INT, SPD, LUK
- Derived Stats: ATK, DEF, M.ATK, M.DEF, EVA, ACC
- Growth Rates: Level-up stat increases
- Resistances: Element, Status effects
- Equipment: Weapon, Armor, Accessory slots
- Skills: Learned abilities by level
"""

from dataclasses import dataclass, field
from enum import Enum
from typing import Dict, List, Optional, Tuple
import pygame
import json
import math


class StatType(Enum):
    """Character stat types"""
    HP = "hp"
    MP = "mp"
    STRENGTH = "strength"
    DEFENSE = "defense"
    INTELLIGENCE = "intelligence"
    SPEED = "speed"
    LUCK = "luck"
    ATTACK = "attack"
    MAGIC_ATTACK = "magic_attack"
    EVASION = "evasion"
    ACCURACY = "accuracy"


class ElementType(Enum):
    """Elemental types"""
    FIRE = "fire"
    ICE = "ice"
    THUNDER = "thunder"
    WATER = "water"
    EARTH = "earth"
    WIND = "wind"
    LIGHT = "light"
    DARK = "dark"
    POISON = "poison"


class StatusEffect(Enum):
    """Status effect types"""
    POISON = "poison"
    SLEEP = "sleep"
    PARALYZE = "paralyze"
    CONFUSE = "confuse"
    BLIND = "blind"
    SILENCE = "silence"
    BERSERK = "berserk"
    SLOW = "slow"
    HASTE = "haste"
    REGEN = "regen"


class EquipSlot(Enum):
    """Equipment slot types"""
    WEAPON = "weapon"
    HEAD = "head"
    BODY = "body"
    ACCESSORY = "accessory"


@dataclass
class StatGrowth:
    """Stat growth formula parameters"""
    base: float
    per_level: float
    curve_type: str = "linear"  # linear, logarithmic, exponential, quadratic

    def calculate(self, level: int) -> int:
        """Calculate stat value at level"""
        if self.curve_type == "linear":
            return int(self.base + self.per_level * level)

        elif self.curve_type == "logarithmic":
            return int(self.base + self.per_level * math.log(level + 1) * 10)

        elif self.curve_type == "exponential":
            return int(self.base * (1 + self.per_level) ** level)

        elif self.curve_type == "quadratic":
            return int(self.base + self.per_level * level ** 2)

        return int(self.base)


@dataclass
class Skill:
    """Character skill/ability"""
    skill_id: int
    name: str
    mp_cost: int = 0
    power: int = 0
    element: Optional[ElementType] = None
    target: str = "single"  # single, all, self
    effect: Optional[str] = None
    learn_level: int = 1


@dataclass
class Equipment:
    """Equipment item"""
    item_id: int
    name: str
    slot: EquipSlot
    attack_bonus: int = 0
    defense_bonus: int = 0
    magic_attack_bonus: int = 0
    magic_defense_bonus: int = 0
    speed_bonus: int = 0
    hp_bonus: int = 0
    mp_bonus: int = 0
    special_effect: Optional[str] = None


@dataclass
class Character:
    """Character/Enemy data"""
    char_id: int
    name: str
    is_enemy: bool = False

    # Base stats at level 1
    base_hp: int = 100
    base_mp: int = 50
    base_strength: int = 10
    base_defense: int = 10
    base_intelligence: int = 10
    base_speed: int = 10
    base_luck: int = 10

    # Growth formulas
    hp_growth: StatGrowth = field(default_factory=lambda: StatGrowth(100, 10))
    mp_growth: StatGrowth = field(default_factory=lambda: StatGrowth(50, 5))
    str_growth: StatGrowth = field(default_factory=lambda: StatGrowth(10, 2))
    def_growth: StatGrowth = field(default_factory=lambda: StatGrowth(10, 2))
    int_growth: StatGrowth = field(default_factory=lambda: StatGrowth(10, 2))
    spd_growth: StatGrowth = field(default_factory=lambda: StatGrowth(10, 1))
    luk_growth: StatGrowth = field(default_factory=lambda: StatGrowth(10, 1))

    # Resistances (0-100%)
    element_resist: Dict[ElementType, int] = field(default_factory=dict)
    status_resist: Dict[StatusEffect, int] = field(default_factory=dict)

    # Skills
    skills: List[Skill] = field(default_factory=list)

    # Equipment
    equipped: Dict[EquipSlot, Optional[Equipment]] = field(default_factory=dict)

    # Experience
    exp_to_next: int = 100
    exp_curve: str = "exponential"  # linear, exponential

    # Graphics
    sprite_id: int = 0
    portrait_id: int = 0
    palette_id: int = 0

    # AI (for enemies)
    ai_pattern: str = "aggressive"
    ai_script: Optional[str] = None

    def get_stat(self, stat_type: StatType, level: int) -> int:
        """Get stat value at level"""
        growth_map = {
            StatType.HP: self.hp_growth,
            StatType.MP: self.mp_growth,
            StatType.STRENGTH: self.str_growth,
            StatType.DEFENSE: self.def_growth,
            StatType.INTELLIGENCE: self.int_growth,
            StatType.SPEED: self.spd_growth,
            StatType.LUCK: self.luk_growth,
        }

        if stat_type in growth_map:
            return growth_map[stat_type].calculate(level)

        # Derived stats
        if stat_type == StatType.ATTACK:
            return self.get_stat(StatType.STRENGTH, level) * 2
        elif stat_type == StatType.MAGIC_ATTACK:
            return self.get_stat(StatType.INTELLIGENCE, level) * 2
        elif stat_type == StatType.EVASION:
            return self.get_stat(StatType.SPEED, level) // 2
        elif stat_type == StatType.ACCURACY:
            return 95 + self.get_stat(StatType.LUCK, level) // 10

        return 0

    def get_skills_at_level(self, level: int) -> List[Skill]:
        """Get all skills learned up to level"""
        return [s for s in self.skills if s.learn_level <= level]

    def get_exp_for_level(self, level: int) -> int:
        """Get total EXP required for level"""
        if self.exp_curve == "linear":
            return self.exp_to_next * level
        elif self.exp_curve == "exponential":
            return int(self.exp_to_next * (1.2 ** (level - 1)))
        return self.exp_to_next * level

    def to_dict(self) -> dict:
        """Convert to dictionary"""
        return {
            "char_id": self.char_id,
            "name": self.name,
            "is_enemy": self.is_enemy,
            "base_hp": self.base_hp,
            "base_mp": self.base_mp,
            "base_strength": self.base_strength,
            "base_defense": self.base_defense,
            "base_intelligence": self.base_intelligence,
            "base_speed": self.base_speed,
            "base_luck": self.base_luck,
            "hp_growth": {
                "base": self.hp_growth.base,
                "per_level": self.hp_growth.per_level,
                "curve_type": self.hp_growth.curve_type,
            },
            "mp_growth": {
                "base": self.mp_growth.base,
                "per_level": self.mp_growth.per_level,
                "curve_type": self.mp_growth.curve_type,
            },
            "str_growth": {
                "base": self.str_growth.base,
                "per_level": self.str_growth.per_level,
                "curve_type": self.str_growth.curve_type,
            },
            "def_growth": {
                "base": self.def_growth.base,
                "per_level": self.def_growth.per_level,
                "curve_type": self.def_growth.curve_type,
            },
            "int_growth": {
                "base": self.int_growth.base,
                "per_level": self.int_growth.per_level,
                "curve_type": self.int_growth.curve_type,
            },
            "spd_growth": {
                "base": self.spd_growth.base,
                "per_level": self.spd_growth.per_level,
                "curve_type": self.spd_growth.curve_type,
            },
            "luk_growth": {
                "base": self.luk_growth.base,
                "per_level": self.luk_growth.per_level,
                "curve_type": self.luk_growth.curve_type,
            },
            "element_resist": {k.value: v for k, v in self.element_resist.items()},
            "status_resist": {k.value: v for k, v in self.status_resist.items()},
            "skills": [
                {
                    "skill_id": s.skill_id,
                    "name": s.name,
                    "mp_cost": s.mp_cost,
                    "power": s.power,
                    "element": s.element.value if s.element else None,
                    "target": s.target,
                    "effect": s.effect,
                    "learn_level": s.learn_level,
                }
                for s in self.skills
            ],
            "exp_to_next": self.exp_to_next,
            "exp_curve": self.exp_curve,
            "sprite_id": self.sprite_id,
            "portrait_id": self.portrait_id,
            "palette_id": self.palette_id,
            "ai_pattern": self.ai_pattern,
            "ai_script": self.ai_script,
        }

    @staticmethod
    def from_dict(data: dict) -> 'Character':
        """Create from dictionary"""
        char = Character(
            char_id=data["char_id"],
            name=data["name"],
            is_enemy=data.get("is_enemy", False),
            base_hp=data.get("base_hp", 100),
            base_mp=data.get("base_mp", 50),
            base_strength=data.get("base_strength", 10),
            base_defense=data.get("base_defense", 10),
            base_intelligence=data.get("base_intelligence", 10),
            base_speed=data.get("base_speed", 10),
            base_luck=data.get("base_luck", 10),
        )

        # Growth formulas
        if "hp_growth" in data:
            g = data["hp_growth"]
            char.hp_growth = StatGrowth(
                g["base"], g["per_level"], g.get("curve_type", "linear"))

        if "mp_growth" in data:
            g = data["mp_growth"]
            char.mp_growth = StatGrowth(
                g["base"], g["per_level"], g.get("curve_type", "linear"))

        if "str_growth" in data:
            g = data["str_growth"]
            char.str_growth = StatGrowth(
                g["base"], g["per_level"], g.get("curve_type", "linear"))

        if "def_growth" in data:
            g = data["def_growth"]
            char.def_growth = StatGrowth(
                g["base"], g["per_level"], g.get("curve_type", "linear"))

        if "int_growth" in data:
            g = data["int_growth"]
            char.int_growth = StatGrowth(
                g["base"], g["per_level"], g.get("curve_type", "linear"))

        if "spd_growth" in data:
            g = data["spd_growth"]
            char.spd_growth = StatGrowth(
                g["base"], g["per_level"], g.get("curve_type", "linear"))

        if "luk_growth" in data:
            g = data["luk_growth"]
            char.luk_growth = StatGrowth(
                g["base"], g["per_level"], g.get("curve_type", "linear"))

        # Resistances
        if "element_resist" in data:
            char.element_resist = {ElementType(k): v for k,
                                   v in data["element_resist"].items()}

        if "status_resist" in data:
            char.status_resist = {StatusEffect(k): v for k,
                                  v in data["status_resist"].items()}

        # Skills
        if "skills" in data:
            char.skills = [
                Skill(
                    skill_id=s["skill_id"],
                    name=s["name"],
                    mp_cost=s.get("mp_cost", 0),
                    power=s.get("power", 0),
                    element=ElementType(
                        s["element"]) if s.get("element") else None,
                    target=s.get("target", "single"),
                    effect=s.get("effect"),
                    learn_level=s.get("learn_level", 1),
                )
                for s in data["skills"]
            ]

        char.exp_to_next = data.get("exp_to_next", 100)
        char.exp_curve = data.get("exp_curve", "exponential")
        char.sprite_id = data.get("sprite_id", 0)
        char.portrait_id = data.get("portrait_id", 0)
        char.palette_id = data.get("palette_id", 0)
        char.ai_pattern = data.get("ai_pattern", "aggressive")
        char.ai_script = data.get("ai_script")

        return char


class CharacterDatabase:
    """Database of characters and enemies"""

    def __init__(self):
        self.characters: Dict[int, Character] = {}
        self._init_sample_data()

    def _init_sample_data(self):
        """Initialize sample characters"""
        # Hero
        hero = Character(
            char_id=1,
            name="Hero",
            base_hp=150,
            base_mp=50,
            base_strength=15,
            base_defense=12,
            base_intelligence=10,
            base_speed=12,
            base_luck=8,
        )

        hero.hp_growth = StatGrowth(150, 12, "linear")
        hero.mp_growth = StatGrowth(50, 5, "linear")
        hero.str_growth = StatGrowth(15, 2.5, "linear")
        hero.def_growth = StatGrowth(12, 2, "linear")

        # Add skills
        hero.skills = [
            Skill(1, "Attack", 0, 50, None, "single", None, 1),
            Skill(2, "Heal", 8, 30, None, "single", "heal", 3),
            Skill(3, "Fire Slash", 12, 80,
                  ElementType.FIRE, "single", None, 7),
            Skill(4, "Power Strike", 15, 120, None, "single", None, 12),
        ]

        # Resistances
        hero.element_resist = {
            ElementType.FIRE: 20,
            ElementType.ICE: 0,
            ElementType.THUNDER: 10,
        }

        self.characters[1] = hero

        # Wizard
        wizard = Character(
            char_id=2,
            name="Wizard",
            base_hp=80,
            base_mp=120,
            base_strength=6,
            base_defense=8,
            base_intelligence=20,
            base_speed=10,
            base_luck=12,
        )

        wizard.hp_growth = StatGrowth(80, 8, "linear")
        wizard.mp_growth = StatGrowth(120, 12, "linear")
        wizard.int_growth = StatGrowth(20, 3, "linear")

        wizard.skills = [
            Skill(10, "Fire", 10, 60, ElementType.FIRE, "single", None, 1),
            Skill(11, "Ice", 10, 60, ElementType.ICE, "single", None, 1),
            Skill(12, "Thunder", 10, 60,
                  ElementType.THUNDER, "single", None, 1),
            Skill(13, "Firaga", 30, 150,
                  ElementType.FIRE, "all", None, 15),
        ]

        self.characters[2] = wizard

        # Goblin (Enemy)
        goblin = Character(
            char_id=100,
            name="Goblin",
            is_enemy=True,
            base_hp=50,
            base_mp=0,
            base_strength=8,
            base_defense=5,
            base_intelligence=3,
            base_speed=7,
            base_luck=5,
        )

        goblin.hp_growth = StatGrowth(50, 8, "linear")
        goblin.str_growth = StatGrowth(8, 1.5, "linear")
        goblin.ai_pattern = "aggressive"

        self.characters[100] = goblin

    def add(self, character: Character):
        """Add character to database"""
        self.characters[character.char_id] = character

    def get(self, char_id: int) -> Optional[Character]:
        """Get character by ID"""
        return self.characters.get(char_id)

    def get_all_heroes(self) -> List[Character]:
        """Get all player characters"""
        return [c for c in self.characters.values() if not c.is_enemy]

    def get_all_enemies(self) -> List[Character]:
        """Get all enemies"""
        return [c for c in self.characters.values() if c.is_enemy]

    def save_json(self, filename: str):
        """Save database to JSON"""
        data = {
            "characters": [c.to_dict() for c in self.characters.values()]
        }

        with open(filename, 'w') as f:
            json.dump(data, f, indent=2)

    def load_json(self, filename: str):
        """Load database from JSON"""
        with open(filename, 'r') as f:
            data = json.load(f)

        self.characters = {}
        for char_data in data.get("characters", []):
            char = Character.from_dict(char_data)
            self.characters[char.char_id] = char


class CharacterStatsEditor:
    """Main character stats editor with UI"""

    def __init__(self, width: int = 1400, height: int = 900):
        self.width = width
        self.height = height
        self.running = True

        pygame.init()
        self.screen = pygame.display.set_mode((width, height))
        pygame.display.set_caption("Character Stats Editor")
        self.clock = pygame.time.Clock()

        self.font = pygame.font.Font(None, 24)
        self.small_font = pygame.font.Font(None, 18)

        # Database
        self.database = CharacterDatabase()
        self.current_char: Optional[Character] = None
        self.selected_char_id: Optional[int] = None

        # UI state
        self.char_scroll = 0
        self.current_tab = "stats"  # stats, growth, skills, resist
        self.preview_level = 1

        # Editing
        self.editing_field: Optional[str] = None
        self.edit_value = ""

        # Select first character
        if self.database.characters:
            first_id = min(self.database.characters.keys())
            self.current_char = self.database.characters[first_id]
            self.selected_char_id = first_id

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
                if self.editing_field:
                    self._handle_edit_input(event)
                else:
                    self._handle_command_input(event)

            elif event.type == pygame.MOUSEBUTTONDOWN:
                self._handle_mouse_click(event.pos, event.button)

            elif event.type == pygame.MOUSEWHEEL:
                self.char_scroll = max(0, self.char_scroll - event.y * 30)

    def _handle_edit_input(self, event):
        """Handle field editing input"""
        if event.key == pygame.K_RETURN:
            self._apply_edit()
            self.editing_field = None
            self.edit_value = ""

        elif event.key == pygame.K_ESCAPE:
            self.editing_field = None
            self.edit_value = ""

        elif event.key == pygame.K_BACKSPACE:
            self.edit_value = self.edit_value[:-1]

        elif event.unicode and (event.unicode.isdigit() or event.unicode in '.-'):
            self.edit_value += event.unicode

    def _apply_edit(self):
        """Apply field edit to current character"""
        if not self.current_char or not self.editing_field:
            return

        try:
            value = float(self.edit_value)

            # Base stats
            base_stats = ["base_hp", "base_mp", "base_strength",
                          "base_defense", "base_intelligence", "base_speed", "base_luck"]
            if self.editing_field in base_stats:
                setattr(self.current_char, self.editing_field, int(value))

            # Growth parameters
            growth_fields = {
                "hp_growth_base": (self.current_char.hp_growth, "base"),
                "hp_growth_rate": (self.current_char.hp_growth, "per_level"),
                "mp_growth_base": (self.current_char.mp_growth, "base"),
                "mp_growth_rate": (self.current_char.mp_growth, "per_level"),
                "str_growth_base": (self.current_char.str_growth, "base"),
                "str_growth_rate": (self.current_char.str_growth, "per_level"),
                "def_growth_base": (self.current_char.def_growth, "base"),
                "def_growth_rate": (self.current_char.def_growth, "per_level"),
                "int_growth_base": (self.current_char.int_growth, "base"),
                "int_growth_rate": (self.current_char.int_growth, "per_level"),
                "spd_growth_base": (self.current_char.spd_growth, "base"),
                "spd_growth_rate": (self.current_char.spd_growth, "per_level"),
            }

            if self.editing_field in growth_fields:
                growth_obj, attr = growth_fields[self.editing_field]
                setattr(growth_obj, attr, value)

        except ValueError:
            pass

    def _handle_command_input(self, event):
        """Handle command input"""
        if event.key == pygame.K_ESCAPE:
            self.running = False

        # Tabs
        elif event.key == pygame.K_1:
            self.current_tab = "stats"
        elif event.key == pygame.K_2:
            self.current_tab = "growth"
        elif event.key == pygame.K_3:
            self.current_tab = "skills"
        elif event.key == pygame.K_4:
            self.current_tab = "resist"

        # Preview level
        elif event.key == pygame.K_EQUALS or event.key == pygame.K_PLUS:
            self.preview_level = min(99, self.preview_level + 1)
        elif event.key == pygame.K_MINUS:
            self.preview_level = max(1, self.preview_level - 1)

        # Save/Load
        elif event.key == pygame.K_s and pygame.key.get_mods() & pygame.KMOD_CTRL:
            self.database.save_json("characters.json")
            print("Database saved to characters.json")

        elif event.key == pygame.K_o and pygame.key.get_mods() & pygame.KMOD_CTRL:
            try:
                self.database.load_json("characters.json")
                print("Database loaded from characters.json")
            except FileNotFoundError:
                print("No characters.json file found")

        # Navigation
        elif event.key == pygame.K_UP:
            char_ids = sorted(self.database.characters.keys())
            if self.selected_char_id in char_ids:
                idx = char_ids.index(self.selected_char_id)
                if idx > 0:
                    self.selected_char_id = char_ids[idx - 1]
                    self.current_char = self.database.characters[self.selected_char_id]

        elif event.key == pygame.K_DOWN:
            char_ids = sorted(self.database.characters.keys())
            if self.selected_char_id in char_ids:
                idx = char_ids.index(self.selected_char_id)
                if idx < len(char_ids) - 1:
                    self.selected_char_id = char_ids[idx + 1]
                    self.current_char = self.database.characters[self.selected_char_id]

    def _handle_mouse_click(self, pos: Tuple[int, int], button: int):
        """Handle mouse click"""
        x, y = pos

        # Check character list
        if x < 250 and button == 1:
            y_offset = 80 - self.char_scroll

            for char_id in sorted(self.database.characters.keys()):
                if y_offset <= y < y_offset + 50:
                    self.current_char = self.database.characters[char_id]
                    self.selected_char_id = char_id
                    break
                y_offset += 55

        # Check tabs
        if 250 < x < self.width - 400 and 50 < y < 90:
            tab_width = (self.width - 650) // 4
            tab_index = (x - 250) // tab_width
            tabs = ["stats", "growth", "skills", "resist"]
            if 0 <= tab_index < len(tabs):
                self.current_tab = tabs[tab_index]

    def _render(self):
        """Render editor"""
        self.screen.fill((25, 25, 35))

        # Draw character list
        self._draw_character_list()

        # Draw tabs
        self._draw_tabs()

        # Draw current tab content
        if self.current_tab == "stats":
            self._draw_stats_tab()
        elif self.current_tab == "growth":
            self._draw_growth_tab()
        elif self.current_tab == "skills":
            self._draw_skills_tab()
        elif self.current_tab == "resist":
            self._draw_resist_tab()

        # Draw preview panel
        self._draw_preview_panel()

        # Draw toolbar
        self._draw_toolbar()

        pygame.display.flip()

    def _draw_character_list(self):
        """Draw character list panel"""
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
        title = self.font.render("Characters", True, (255, 255, 255))
        self.screen.blit(title, (panel_x + 10, panel_y + 10))

        # Character list
        y_offset = panel_y + 50 - self.char_scroll

        for char_id in sorted(self.database.characters.keys()):
            char = self.database.characters[char_id]

            if y_offset + 50 < panel_y or y_offset > panel_y + panel_height:
                y_offset += 55
                continue

            # Background
            bg_color = (60, 60, 80) if char_id == self.selected_char_id else (45, 45, 55)
            pygame.draw.rect(self.screen, bg_color,
                             (panel_x + 5, y_offset, panel_width - 10, 50))
            pygame.draw.rect(self.screen, (100, 100, 120),
                             (panel_x + 5, y_offset, panel_width - 10, 50), 1)

            # ID
            id_text = self.small_font.render(f"#{char_id}", True, (180, 180, 180))
            self.screen.blit(id_text, (panel_x + 10, y_offset + 5))

            # Name
            name_color = (255, 100, 100) if char.is_enemy else (100, 200, 255)
            name_text = self.small_font.render(char.name, True, name_color)
            self.screen.blit(name_text, (panel_x + 10, y_offset + 25))

            y_offset += 55

    def _draw_tabs(self):
        """Draw tab bar"""
        tab_y = 50
        tab_x = 250
        tab_width = (self.width - 650) // 4
        tab_height = 35

        tabs = [
            ("Stats", "stats"),
            ("Growth", "growth"),
            ("Skills", "skills"),
            ("Resist", "resist"),
        ]

        for i, (label, tab_id) in enumerate(tabs):
            x = tab_x + i * tab_width

            # Background
            bg_color = (60, 60, 80) if tab_id == self.current_tab else (45, 45, 55)
            pygame.draw.rect(self.screen, bg_color,
                             (x, tab_y, tab_width, tab_height))
            pygame.draw.rect(self.screen, (100, 100, 120),
                             (x, tab_y, tab_width, tab_height), 2)

            # Label
            text = self.small_font.render(label, True, (255, 255, 255))
            text_rect = text.get_rect(
                center=(x + tab_width // 2, tab_y + tab_height // 2))
            self.screen.blit(text, text_rect)

    def _draw_stats_tab(self):
        """Draw base stats tab"""
        if not self.current_char:
            return

        panel_x = 250
        panel_y = 90
        panel_width = self.width - 650
        panel_height = self.height - 140

        # Background
        pygame.draw.rect(self.screen, (35, 35, 45),
                         (panel_x, panel_y, panel_width, panel_height))
        pygame.draw.rect(self.screen, (80, 80, 100),
                         (panel_x, panel_y, panel_width, panel_height), 2)

        # Stats
        stats = [
            ("HP", self.current_char.base_hp, "base_hp"),
            ("MP", self.current_char.base_mp, "base_mp"),
            ("Strength", self.current_char.base_strength, "base_strength"),
            ("Defense", self.current_char.base_defense, "base_defense"),
            ("Intelligence", self.current_char.base_intelligence,
             "base_intelligence"),
            ("Speed", self.current_char.base_speed, "base_speed"),
            ("Luck", self.current_char.base_luck, "base_luck"),
        ]

        y_offset = panel_y + 20
        for label, value, field in stats:
            color = (255, 255, 100) if field == self.editing_field else (200, 200, 200)

            label_surf = self.font.render(f"{label}:", True, color)
            self.screen.blit(label_surf, (panel_x + 20, y_offset))

            value_text = self.edit_value + \
                "_" if field == self.editing_field else str(value)
            value_surf = self.font.render(value_text, True, color)
            self.screen.blit(value_surf, (panel_x + 200, y_offset))

            y_offset += 35

    def _draw_growth_tab(self):
        """Draw growth curves tab"""
        if not self.current_char:
            return

        panel_x = 250
        panel_y = 90
        panel_width = self.width - 650
        panel_height = self.height - 140

        # Background
        pygame.draw.rect(self.screen, (35, 35, 45),
                         (panel_x, panel_y, panel_width, panel_height))
        pygame.draw.rect(self.screen, (80, 80, 100),
                         (panel_x, panel_y, panel_width, panel_height), 2)

        # Growth parameters
        growth_params = [
            ("HP", self.current_char.hp_growth, "hp_growth"),
            ("MP", self.current_char.mp_growth, "mp_growth"),
            ("STR", self.current_char.str_growth, "str_growth"),
            ("DEF", self.current_char.def_growth, "def_growth"),
            ("INT", self.current_char.int_growth, "int_growth"),
            ("SPD", self.current_char.spd_growth, "spd_growth"),
        ]

        y_offset = panel_y + 20
        for label, growth, prefix in growth_params:
            label_surf = self.small_font.render(
                f"{label}:", True, (200, 200, 255))
            self.screen.blit(label_surf, (panel_x + 20, y_offset))

            # Base
            base_field = f"{prefix}_base"
            base_color = (255, 255, 100) if base_field == self.editing_field else (
                200, 200, 200)
            base_text = f"Base: {growth.base:.1f}"
            base_surf = self.small_font.render(base_text, True, base_color)
            self.screen.blit(base_surf, (panel_x + 80, y_offset))

            # Rate
            rate_field = f"{prefix}_rate"
            rate_color = (255, 255, 100) if rate_field == self.editing_field else (
                200, 200, 200)
            rate_text = f"Per Lv: {growth.per_level:.1f}"
            rate_surf = self.small_font.render(rate_text, True, rate_color)
            self.screen.blit(rate_surf, (panel_x + 220, y_offset))

            # Curve
            curve_surf = self.small_font.render(
                f"Curve: {growth.curve_type}", True, (150, 150, 150))
            self.screen.blit(curve_surf, (panel_x + 370, y_offset))

            y_offset += 30

    def _draw_skills_tab(self):
        """Draw skills tab"""
        if not self.current_char:
            return

        panel_x = 250
        panel_y = 90
        panel_width = self.width - 650
        panel_height = self.height - 140

        # Background
        pygame.draw.rect(self.screen, (35, 35, 45),
                         (panel_x, panel_y, panel_width, panel_height))
        pygame.draw.rect(self.screen, (80, 80, 100),
                         (panel_x, panel_y, panel_width, panel_height), 2)

        # Skills list
        y_offset = panel_y + 20

        for skill in sorted(self.current_char.skills, key=lambda s: s.learn_level):
            # Skill header
            skill_text = f"Lv{skill.learn_level}: {skill.name}"
            skill_surf = self.small_font.render(
                skill_text, True, (200, 200, 255))
            self.screen.blit(skill_surf, (panel_x + 20, y_offset))

            # Details
            details = f"MP:{skill.mp_cost} | Power:{skill.power} | Target:{skill.target}"
            if skill.element:
                details += f" | {skill.element.value}"

            detail_surf = self.small_font.render(
                details, True, (150, 150, 150))
            self.screen.blit(detail_surf, (panel_x + 40, y_offset + 20))

            y_offset += 50

    def _draw_resist_tab(self):
        """Draw resistances tab"""
        if not self.current_char:
            return

        panel_x = 250
        panel_y = 90
        panel_width = self.width - 650
        panel_height = self.height - 140

        # Background
        pygame.draw.rect(self.screen, (35, 35, 45),
                         (panel_x, panel_y, panel_width, panel_height))
        pygame.draw.rect(self.screen, (80, 80, 100),
                         (panel_x, panel_y, panel_width, panel_height), 2)

        # Element resistances
        y_offset = panel_y + 20

        elem_label = self.font.render(
            "Element Resistances", True, (200, 200, 255))
        self.screen.blit(elem_label, (panel_x + 20, y_offset))
        y_offset += 35

        for elem in ElementType:
            resist = self.current_char.element_resist.get(elem, 0)
            text = f"{elem.value.capitalize()}: {resist}%"
            text_surf = self.small_font.render(text, True, (180, 180, 180))
            self.screen.blit(text_surf, (panel_x + 40, y_offset))
            y_offset += 25

        # Status resistances
        y_offset += 20
        status_label = self.font.render(
            "Status Resistances", True, (200, 200, 255))
        self.screen.blit(status_label, (panel_x + 20, y_offset))
        y_offset += 35

        for status in list(StatusEffect)[:6]:  # Show first 6
            resist = self.current_char.status_resist.get(status, 0)
            text = f"{status.value.capitalize()}: {resist}%"
            text_surf = self.small_font.render(text, True, (180, 180, 180))
            self.screen.blit(text_surf, (panel_x + 40, y_offset))
            y_offset += 25

    def _draw_preview_panel(self):
        """Draw stat preview at level"""
        panel_x = self.width - 400
        panel_y = 50
        panel_width = 400
        panel_height = self.height - 100

        # Background
        pygame.draw.rect(self.screen, (35, 35, 45),
                         (panel_x, panel_y, panel_width, panel_height))
        pygame.draw.rect(self.screen, (80, 80, 100),
                         (panel_x, panel_y, panel_width, panel_height), 2)

        if not self.current_char:
            return

        # Title
        title = self.font.render(
            f"Preview (Level {self.preview_level})", True, (255, 255, 255))
        self.screen.blit(title, (panel_x + 10, panel_y + 10))

        # Stats at level
        stats = [
            ("HP", StatType.HP),
            ("MP", StatType.MP),
            ("STR", StatType.STRENGTH),
            ("DEF", StatType.DEFENSE),
            ("INT", StatType.INTELLIGENCE),
            ("SPD", StatType.SPEED),
            ("LUK", StatType.LUCK),
            ("", None),
            ("ATK", StatType.ATTACK),
            ("M.ATK", StatType.MAGIC_ATTACK),
            ("EVA", StatType.EVASION),
            ("ACC", StatType.ACCURACY),
        ]

        y_offset = panel_y + 50
        for label, stat_type in stats:
            if not label:
                pygame.draw.line(self.screen, (60, 60, 80),
                                 (panel_x + 10, y_offset),
                                 (panel_x + panel_width - 10, y_offset), 1)
                y_offset += 10
                continue

            value = self.current_char.get_stat(stat_type, self.preview_level)
            text = f"{label}: {value}"
            text_surf = self.small_font.render(text, True, (200, 200, 200))
            self.screen.blit(text_surf, (panel_x + 20, y_offset))

            y_offset += 25

        # Skills at level
        y_offset += 20
        skills_label = self.font.render(
            "Available Skills", True, (200, 200, 255))
        self.screen.blit(skills_label, (panel_x + 10, y_offset))
        y_offset += 30

        skills = self.current_char.get_skills_at_level(self.preview_level)
        for skill in skills[:10]:  # Show first 10
            skill_text = self.small_font.render(
                skill.name, True, (180, 180, 180))
            self.screen.blit(skill_text, (panel_x + 20, y_offset))
            y_offset += 20

    def _draw_toolbar(self):
        """Draw top toolbar"""
        toolbar_height = 40
        pygame.draw.rect(self.screen, (45, 45, 55),
                         (0, 0, self.width, toolbar_height))
        pygame.draw.rect(self.screen, (80, 80, 100),
                         (0, 0, self.width, toolbar_height), 2)

        # Title
        if self.current_char:
            title = self.font.render(
                f"Character: {self.current_char.name}", True, (255, 255, 255))
            self.screen.blit(title, (10, 10))

        # Instructions
        help_text = "1-4:Tabs | ↑↓:Navigate | +/-:Preview Level | Ctrl+S:Save | Ctrl+O:Load"
        help_surf = self.small_font.render(help_text, True, (180, 180, 180))
        self.screen.blit(help_surf, (350, 12))


def main():
    """Run character stats editor"""
    editor = CharacterStatsEditor()
    editor.run()


if __name__ == "__main__":
    main()
