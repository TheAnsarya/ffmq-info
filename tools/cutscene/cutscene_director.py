#!/usr/bin/env python3
"""Cutscene Director - Timeline-based cutscene editor"""

from dataclasses import dataclass
from enum import Enum
from typing import List
import pygame
import json


class EventType(Enum):
    DIALOG = "dialog"
    CAMERA = "camera"
    ANIMATION = "animation"
    SOUND = "sound"


@dataclass
class CutsceneEvent:
    time: float
    event_type: EventType
    data: dict

    def to_dict(self) -> dict:
        return {"time": self.time, "type": self.event_type.value, "data": self.data}


@dataclass
class Cutscene:
    cutscene_id: int
    name: str
    events: List[CutsceneEvent]

    def to_dict(self) -> dict:
        return {
            "cutscene_id": self.cutscene_id,
            "name": self.name,
            "events": [e.to_dict() for e in self.events]
        }


class CutsceneDirector:
    def __init__(self):
        pygame.init()
        self.screen = pygame.display.set_mode((1200, 600))
        pygame.display.set_caption("Cutscene Director")
        self.font = pygame.font.Font(None, 18)
        self.running = True

        self.cutscenes = [
            Cutscene(1, "Opening", [
                CutsceneEvent(0.0, EventType.DIALOG, {"text": "Long ago..."}),
                CutsceneEvent(3.0, EventType.CAMERA, {"zoom": 2.0}),
            ])
        ]

    def run(self):
        while self.running:
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    self.running = False

            self.screen.fill((25, 25, 35))

            # Timeline
            pygame.draw.rect(self.screen, (50, 50, 60), (50, 100, 1100, 400))

            if self.cutscenes:
                cs = self.cutscenes[0]
                for evt in cs.events:
                    x = 50 + int(evt.time * 100)
                    pygame.draw.circle(self.screen, (255, 200, 100), (x, 300), 8)

            pygame.display.flip()
        pygame.quit()


def main():
    director = CutsceneDirector()
    director.run()


if __name__ == "__main__":
    main()
