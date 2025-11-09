#!/usr/bin/env python3
"""
Status Effect Editor

Custom status effect designer.
Features:
- Effect parameters (duration, stacking)
- Stat modifications
- Visual effects
- Cure items
- Immunity flags
"""

from dataclasses import dataclass, field
from enum import Enum
from typing import List, Optional, Dict
import pygame
import json


class EffectType(Enum):
    """Effect types"""
    BUFF = "buff"
    DEBUFF = "debuff"
    DOT = "dot"  # Damage over time
    HOT = "hot"  # Heal over time
    SPECIAL = "special"


class StatModType(Enum):
    """Stat modification type"""
    FLAT = "flat"
    PERCENT = "percent"


@dataclass
class StatModifier:
    """Stat modification"""
    stat_name: str
    mod_type: StatModType
    value: int

    def to_dict(self) -> dict:
        return {
            "stat_name": self.stat_name,
            "mod_type": self.mod_type.value,
            "value": self.value,
        }

    @staticmethod
    def from_dict(data: dict) -> 'StatModifier':
        return StatModifier(
            stat_name=data["stat_name"],
            mod_type=StatModType(data["mod_type"]),
            value=data["value"],
        )


@dataclass
class StatusEffect:
    """Status effect definition"""
    effect_id: int
    name: str
    effect_type: EffectType
    description: str = ""
    duration: int = 3  # Turns
    can_stack: bool = False
    max_stacks: int = 1
    stat_mods: List[StatModifier] = field(default_factory=list)
    dot_value: int = 0  # Damage/heal per turn
    icon_id: int = 0
    color: tuple = (255, 255, 255)
    cure_items: List[int] = field(default_factory=list)
    prevented_by: List[int] = field(default_factory=list)  # Other effects that prevent this

    def to_dict(self) -> dict:
        return {
            "effect_id": self.effect_id,
            "name": self.name,
            "effect_type": self.effect_type.value,
            "description": self.description,
            "duration": self.duration,
            "can_stack": self.can_stack,
            "max_stacks": self.max_stacks,
            "stat_mods": [m.to_dict() for m in self.stat_mods],
            "dot_value": self.dot_value,
            "icon_id": self.icon_id,
            "color": list(self.color),
            "cure_items": self.cure_items,
            "prevented_by": self.prevented_by,
        }

    @staticmethod
    def from_dict(data: dict) -> 'StatusEffect':
        return StatusEffect(
            effect_id=data["effect_id"],
            name=data["name"],
            effect_type=EffectType(data["effect_type"]),
            description=data.get("description", ""),
            duration=data.get("duration", 3),
            can_stack=data.get("can_stack", False),
            max_stacks=data.get("max_stacks", 1),
            stat_mods=[StatModifier.from_dict(m) for m in data.get("stat_mods", [])],
            dot_value=data.get("dot_value", 0),
            icon_id=data.get("icon_id", 0),
            color=tuple(data.get("color", [255, 255, 255])),
            cure_items=data.get("cure_items", []),
            prevented_by=data.get("prevented_by", []),
        )


class StatusEffectEditor:
    """Status effect editor UI"""

    def __init__(self, width: int = 1200, height: int = 800):
        self.width = width
        self.height = height
        self.running = True

        pygame.init()
        self.screen = pygame.display.set_mode((width, height))
        pygame.display.set_caption("Status Effect Editor")
        self.clock = pygame.time.Clock()

        self.font = pygame.font.Font(None, 24)
        self.small_font = pygame.font.Font(None, 18)

        # Sample effects
        self.effects = self._create_samples()
        self.current_effect: Optional[StatusEffect] = self.effects[0] if self.effects else None
        self.scroll = 0

    def _create_samples(self) -> List[StatusEffect]:
        """Create sample effects"""
        return [
            StatusEffect(
                effect_id=1,
                name="Power Up",
                effect_type=EffectType.BUFF,
                description="Increases attack power",
                duration=5,
                stat_mods=[StatModifier("strength", StatModType.PERCENT, 50)],
                color=(255, 150, 100),
                cure_items=[],
            ),
            StatusEffect(
                effect_id=2,
                name="Poison",
                effect_type=EffectType.DOT,
                description="Takes damage each turn",
                duration=999,
                dot_value=10,
                color=(150, 100, 255),
                cure_items=[5, 6],
            ),
            StatusEffect(
                effect_id=3,
                name="Regen",
                effect_type=EffectType.HOT,
                description="Restores HP each turn",
                duration=10,
                dot_value=20,
                color=(100, 255, 150),
            ),
        ]

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

            elif event.type == pygame.MOUSEBUTTONDOWN:
                self._handle_click(event.pos)

            elif event.type == pygame.MOUSEWHEEL:
                self.scroll = max(0, self.scroll - event.y * 20)

    def _handle_click(self, pos: tuple):
        """Handle click"""
        x, y = pos

        if x < 300:
            y_offset = 80 - self.scroll
            for effect in self.effects:
                if y_offset < y < y_offset + 60:
                    self.current_effect = effect
                    break
                y_offset += 65

    def _save(self):
        """Save effects"""
        data = {"effects": [e.to_dict() for e in self.effects]}
        with open("status_effects.json", 'w') as f:
            json.dump(data, f, indent=2)
        print("Saved")

    def _render(self):
        """Render UI"""
        self.screen.fill((25, 25, 35))

        # Toolbar
        pygame.draw.rect(self.screen, (45, 45, 55), (0, 0, self.width, 40))
        title = self.font.render("Status Effect Editor", True, (255, 255, 255))
        self.screen.blit(title, (10, 10))

        # Effect list
        pygame.draw.rect(self.screen, (35, 35, 45), (0, 50, 300, self.height - 50))

        y = 80 - self.scroll
        for effect in self.effects:
            bg = (60, 60, 80) if effect == self.current_effect else (45, 45, 55)
            pygame.draw.rect(self.screen, bg, (10, y, 280, 60))

            # Type indicator
            pygame.draw.circle(self.screen, effect.color, (30, y + 30), 10)

            name = self.small_font.render(effect.name, True, (200, 200, 255))
            self.screen.blit(name, (50, y + 10))

            type_text = self.small_font.render(effect.effect_type.value, True, (150, 150, 150))
            self.screen.blit(type_text, (50, y + 30))

            y += 65

        # Properties
        if self.current_effect:
            self._draw_properties()

        pygame.display.flip()

    def _draw_properties(self):
        """Draw properties"""
        panel_x = 320
        pygame.draw.rect(self.screen, (35, 35, 45), (panel_x, 50, 860, self.height - 50))

        effect = self.current_effect
        y = 80

        props = [
            ("Name", effect.name),
            ("Type", effect.effect_type.value),
            ("Duration", f"{effect.duration} turns"),
            ("Can Stack", "Yes" if effect.can_stack else "No"),
            ("Max Stacks", str(effect.max_stacks)),
            ("DOT/HOT", str(effect.dot_value)),
        ]

        for label, value in props:
            lbl = self.small_font.render(f"{label}:", True, (180, 180, 180))
            self.screen.blit(lbl, (panel_x + 20, y))

            val = self.small_font.render(value, True, (255, 255, 255))
            self.screen.blit(val, (panel_x + 200, y))

            y += 30

        # Description
        y += 20
        desc_title = self.font.render("Description", True, (200, 200, 255))
        self.screen.blit(desc_title, (panel_x + 20, y))
        y += 30

        desc = self.small_font.render(effect.description, True, (180, 180, 180))
        self.screen.blit(desc, (panel_x + 30, y))
        y += 40

        # Stat mods
        if effect.stat_mods:
            mods_title = self.font.render("Stat Modifiers", True, (200, 200, 255))
            self.screen.blit(mods_title, (panel_x + 20, y))
            y += 30

            for mod in effect.stat_mods:
                sign = "+" if mod.value >= 0 else ""
                mod_text = self.small_font.render(
                    f"{mod.stat_name}: {sign}{mod.value}{'%' if mod.mod_type == StatModType.PERCENT else ''}",
                    True, (150, 255, 150))
                self.screen.blit(mod_text, (panel_x + 30, y))
                y += 25


def main():
    editor = StatusEffectEditor()
    editor.run()


if __name__ == "__main__":
    main()
