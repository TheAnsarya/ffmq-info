#!/usr/bin/env python3
"""Achievement/Trophy System Editor"""

from dataclasses import dataclass, field
from enum import Enum
from typing import List, Optional
import pygame
import json


class AchievementType(Enum):
    STORY = "story"
    COMBAT = "combat"
    COLLECTION = "collection"
    SECRET = "secret"


@dataclass
class Achievement:
    achievement_id: int
    name: str
    achievement_type: AchievementType
    description: str = ""
    points: int = 10
    hidden: bool = False
    progress_max: int = 1

    def to_dict(self) -> dict:
        return {
            "achievement_id": self.achievement_id,
            "name": self.name,
            "type": self.achievement_type.value,
            "description": self.description,
            "points": self.points,
            "hidden": self.hidden,
            "progress_max": self.progress_max,
        }


class AchievementEditor:
    def __init__(self):
        pygame.init()
        self.screen = pygame.display.set_mode((1000, 700))
        pygame.display.set_caption("Achievement Editor")
        self.font = pygame.font.Font(None, 20)
        self.running = True

        self.achievements = [
            Achievement(1, "First Victory", AchievementType.COMBAT, "Win first battle", 10),
            Achievement(2, "Collector", AchievementType.COLLECTION, "Collect 100 items", 25, False, 100),
        ]
        self.current: Optional[Achievement] = None

    def run(self):
        while self.running:
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    self.running = False

            self.screen.fill((30, 30, 40))
            y = 60
            for ach in self.achievements:
                text = self.font.render(f"{ach.name} ({ach.achievement_type.value})", True, (200, 200, 255))
                self.screen.blit(text, (20, y))
                y += 30

            pygame.display.flip()
        pygame.quit()


def main():
    editor = AchievementEditor()
    editor.run()


if __name__ == "__main__":
    main()
