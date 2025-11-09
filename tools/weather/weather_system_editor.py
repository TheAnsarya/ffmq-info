#!/usr/bin/env python3
"""Weather System Editor - Dynamic weather and environmental effects"""

from dataclasses import dataclass, field
from enum import Enum
from typing import List, Optional
import pygame
import json


class WeatherType(Enum):
    CLEAR = "clear"
    RAIN = "rain"
    SNOW = "snow"
    FOG = "fog"
    STORM = "storm"
    SANDSTORM = "sandstorm"


@dataclass
class WeatherEffect:
    weather_id: int
    name: str
    weather_type: WeatherType
    particle_count: int = 100
    wind_speed: float = 0.0
    visibility_modifier: float = 1.0  # 0.0-1.0
    encounter_rate_modifier: float = 1.0
    movement_speed_modifier: float = 1.0
    color_tint: tuple = (255, 255, 255, 0)
    
    def to_dict(self) -> dict:
        return {
            "weather_id": self.weather_id,
            "name": self.name,
            "weather_type": self.weather_type.value,
            "particle_count": self.particle_count,
            "wind_speed": self.wind_speed,
            "visibility_modifier": self.visibility_modifier,
            "encounter_rate_modifier": self.encounter_rate_modifier,
            "movement_speed_modifier": self.movement_speed_modifier,
            "color_tint": list(self.color_tint),
        }


class WeatherSystemEditor:
    def __init__(self):
        pygame.init()
        self.screen = pygame.display.set_mode((1100, 700))
        pygame.display.set_caption("Weather System Editor")
        self.font = pygame.font.Font(None, 20)
        self.running = True
        
        self.weather_effects = [
            WeatherEffect(1, "Light Rain", WeatherType.RAIN, 50, 2.0, 0.9, 1.1),
            WeatherEffect(2, "Heavy Snow", WeatherType.SNOW, 150, 5.0, 0.7, 0.8, 0.9, (200, 220, 255, 40)),
            WeatherEffect(3, "Thick Fog", WeatherType.FOG, 200, 0.0, 0.5, 1.3, color_tint=(180, 180, 200, 80)),
        ]
        self.selected: Optional[WeatherEffect] = None
    
    def run(self):
        while self.running:
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    self.running = False
                elif event.type == pygame.KEYDOWN:
                    if event.key == pygame.K_s and pygame.key.get_mods() & pygame.KMOD_CTRL:
                        data = {"weather": [w.to_dict() for w in self.weather_effects]}
                        with open("weather.json", 'w') as f:
                            json.dump(data, f, indent=2)
                elif event.type == pygame.MOUSEBUTTONDOWN:
                    y_off = 70
                    for effect in self.weather_effects:
                        if y_off < event.pos[1] < y_off + 50:
                            self.selected = effect
                            break
                        y_off += 55
            
            self.screen.fill((25, 25, 35))
            
            # Weather list
            pygame.draw.rect(self.screen, (35, 35, 45), (10, 50, 400, 630))
            
            y = 70
            for effect in self.weather_effects:
                bg = (60, 60, 80) if effect == self.selected else (45, 45, 55)
                pygame.draw.rect(self.screen, bg, (20, y, 380, 50))
                
                name = self.font.render(effect.name, True, (200, 200, 255))
                self.screen.blit(name, (30, y + 8))
                
                info = self.font.render(
                    f"{effect.weather_type.value} | {effect.particle_count} particles",
                    True, (150, 150, 150))
                self.screen.blit(info, (30, y + 28))
                
                y += 55
            
            # Properties
            if self.selected:
                pygame.draw.rect(self.screen, (35, 35, 45), (430, 50, 650, 630))
                
                y = 80
                props = [
                    ("Name", self.selected.name),
                    ("Type", self.selected.weather_type.value),
                    ("Particles", str(self.selected.particle_count)),
                    ("Wind Speed", f"{self.selected.wind_speed:.1f}"),
                    ("Visibility", f"{self.selected.visibility_modifier * 100:.0f}%"),
                    ("Encounter Rate", f"{self.selected.encounter_rate_modifier * 100:.0f}%"),
                    ("Movement Speed", f"{self.selected.movement_speed_modifier * 100:.0f}%"),
                ]
                
                for label, value in props:
                    lbl = self.font.render(f"{label}:", True, (180, 180, 180))
                    self.screen.blit(lbl, (450, y))
                    
                    val = self.font.render(value, True, (255, 255, 255))
                    self.screen.blit(val, (680, y))
                    
                    y += 30
            
            pygame.display.flip()
        pygame.quit()


def main():
    editor = WeatherSystemEditor()
    editor.run()


if __name__ == "__main__":
    main()
