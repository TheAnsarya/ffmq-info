#!/usr/bin/env python3
"""Mini-Game Designer - Custom mini-game logic editor"""

from dataclasses import dataclass, field
from enum import Enum
from typing import List, Dict, Optional
import pygame
import json


class MiniGameType(Enum):
    PUZZLE = "puzzle"
    TIMING = "timing"
    MEMORY = "memory"
    SHOOTER = "shooter"
    RACING = "racing"


@dataclass
class MiniGame:
    game_id: int
    name: str
    game_type: MiniGameType
    difficulty: int = 1  # 1-10
    time_limit: int = 60  # seconds
    score_multiplier: float = 1.0
    rewards: Dict[str, int] = field(default_factory=dict)
    high_score_requirement: int = 1000
    
    def to_dict(self) -> dict:
        return {
            "game_id": self.game_id,
            "name": self.name,
            "game_type": self.game_type.value,
            "difficulty": self.difficulty,
            "time_limit": self.time_limit,
            "score_multiplier": self.score_multiplier,
            "rewards": self.rewards,
            "high_score_requirement": self.high_score_requirement,
        }


class MiniGameDesigner:
    def __init__(self):
        pygame.init()
        self.screen = pygame.display.set_mode((1100, 700))
        pygame.display.set_caption("Mini-Game Designer")
        self.font = pygame.font.Font(None, 20)
        self.running = True
        
        self.games = [
            MiniGame(1, "Card Matching", MiniGameType.MEMORY, 3, 90, 1.5, {"gold": 100}),
            MiniGame(2, "Target Practice", MiniGameType.SHOOTER, 5, 60, 2.0, {"exp": 50}),
        ]
    
    def run(self):
        while self.running:
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    self.running = False
                elif event.type == pygame.KEYDOWN:
                    if event.key == pygame.K_s and pygame.key.get_mods() & pygame.KMOD_CTRL:
                        data = {"games": [g.to_dict() for g in self.games]}
                        with open("minigames.json", 'w') as f:
                            json.dump(data, f, indent=2)
            
            self.screen.fill((25, 25, 35))
            
            y = 70
            for game in self.games:
                text = self.font.render(
                    f"{game.name} ({game.game_type.value}) - Difficulty: {game.difficulty}/10",
                    True, (200, 200, 255))
                self.screen.blit(text, (30, y))
                y += 40
            
            pygame.display.flip()
        pygame.quit()


def main():
    designer = MiniGameDesigner()
    designer.run()


if __name__ == "__main__":
    main()
