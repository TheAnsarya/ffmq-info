#!/usr/bin/env python3
"""
Item Crafting System Editor

Crafting recipe and material management.
Features:
- Recipe creation
- Material requirements
- Success rates
- Result items
- Crafting stations
- Skill requirements
"""

from dataclasses import dataclass, field
from enum import Enum
from typing import List, Optional
import pygame
import json


class CraftingStation(Enum):
    """Crafting station types"""
    WORKBENCH = "workbench"
    FORGE = "forge"
    ALCHEMY_LAB = "alchemy_lab"
    COOKING_POT = "cooking_pot"
    ENCHANTING_TABLE = "enchanting_table"


@dataclass
class MaterialRequirement:
    """Material needed for crafting"""
    item_id: int
    quantity: int
    consumed: bool = True
    
    def to_dict(self) -> dict:
        return {
            "item_id": self.item_id,
            "quantity": self.quantity,
            "consumed": self.consumed,
        }
    
    @staticmethod
    def from_dict(data: dict) -> 'MaterialRequirement':
        return MaterialRequirement(
            item_id=data["item_id"],
            quantity=data["quantity"],
            consumed=data.get("consumed", True),
        )


@dataclass
class CraftingRecipe:
    """Crafting recipe"""
    recipe_id: int
    name: str
    station: CraftingStation
    materials: List[MaterialRequirement] = field(default_factory=list)
    result_item_id: int = 0
    result_quantity: int = 1
    success_rate: float = 1.0  # 0.0 to 1.0
    crafting_time: int = 1  # Seconds
    required_level: int = 1
    skill_exp_gain: int = 10
    gold_cost: int = 0
    
    def to_dict(self) -> dict:
        return {
            "recipe_id": self.recipe_id,
            "name": self.name,
            "station": self.station.value,
            "materials": [m.to_dict() for m in self.materials],
            "result_item_id": self.result_item_id,
            "result_quantity": self.result_quantity,
            "success_rate": self.success_rate,
            "crafting_time": self.crafting_time,
            "required_level": self.required_level,
            "skill_exp_gain": self.skill_exp_gain,
            "gold_cost": self.gold_cost,
        }
    
    @staticmethod
    def from_dict(data: dict) -> 'CraftingRecipe':
        return CraftingRecipe(
            recipe_id=data["recipe_id"],
            name=data["name"],
            station=CraftingStation(data["station"]),
            materials=[MaterialRequirement.from_dict(m) for m in data.get("materials", [])],
            result_item_id=data.get("result_item_id", 0),
            result_quantity=data.get("result_quantity", 1),
            success_rate=data.get("success_rate", 1.0),
            crafting_time=data.get("crafting_time", 1),
            required_level=data.get("required_level", 1),
            skill_exp_gain=data.get("skill_exp_gain", 10),
            gold_cost=data.get("gold_cost", 0),
        )


class CraftingSystemEditor:
    """Crafting system editor UI"""
    
    def __init__(self, width: int = 1200, height: int = 800):
        self.width = width
        self.height = height
        self.running = True
        
        pygame.init()
        self.screen = pygame.display.set_mode((width, height))
        pygame.display.set_caption("Crafting System Editor")
        self.clock = pygame.time.Clock()
        
        self.font = pygame.font.Font(None, 24)
        self.small_font = pygame.font.Font(None, 18)
        
        # Sample recipes
        self.recipes = self._create_samples()
        self.current_recipe: Optional[CraftingRecipe] = self.recipes[0] if self.recipes else None
        self.scroll = 0
    
    def _create_samples(self) -> List[CraftingRecipe]:
        """Create sample recipes"""
        return [
            CraftingRecipe(
                recipe_id=1,
                name="Iron Sword",
                station=CraftingStation.FORGE,
                materials=[
                    MaterialRequirement(101, 5),  # 5x Iron Ore
                    MaterialRequirement(102, 2),  # 2x Wood
                ],
                result_item_id=201,
                result_quantity=1,
                success_rate=0.95,
                crafting_time=5,
                required_level=5,
                gold_cost=100,
            ),
            CraftingRecipe(
                recipe_id=2,
                name="Health Potion",
                station=CraftingStation.ALCHEMY_LAB,
                materials=[
                    MaterialRequirement(50, 3),   # 3x Herb
                    MaterialRequirement(51, 1),   # 1x Empty Bottle
                ],
                result_item_id=1,
                result_quantity=3,
                success_rate=1.0,
                crafting_time=2,
                required_level=1,
                gold_cost=10,
            ),
            CraftingRecipe(
                recipe_id=3,
                name="Bread",
                station=CraftingStation.COOKING_POT,
                materials=[
                    MaterialRequirement(70, 2),   # 2x Wheat
                    MaterialRequirement(71, 1),   # 1x Water
                ],
                result_item_id=10,
                result_quantity=5,
                success_rate=0.98,
                crafting_time=1,
                required_level=1,
                gold_cost=5,
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
        
        if x < 350:
            y_offset = 80 - self.scroll
            for recipe in self.recipes:
                if y_offset < y < y_offset + 70:
                    self.current_recipe = recipe
                    break
                y_offset += 75
    
    def _save(self):
        """Save recipes"""
        data = {"recipes": [r.to_dict() for r in self.recipes]}
        with open("crafting_recipes.json", 'w') as f:
            json.dump(data, f, indent=2)
        print("Saved")
    
    def _render(self):
        """Render UI"""
        self.screen.fill((25, 25, 35))
        
        # Toolbar
        pygame.draw.rect(self.screen, (45, 45, 55), (0, 0, self.width, 40))
        title = self.font.render("Crafting System Editor", True, (255, 255, 255))
        self.screen.blit(title, (10, 10))
        
        # Recipe list
        pygame.draw.rect(self.screen, (35, 35, 45), (0, 50, 350, self.height - 50))
        
        y = 80 - self.scroll
        for recipe in self.recipes:
            bg = (60, 60, 80) if recipe == self.current_recipe else (45, 45, 55)
            pygame.draw.rect(self.screen, bg, (10, y, 330, 70))
            
            # Station color
            station_colors = {
                CraftingStation.WORKBENCH: (150, 120, 80),
                CraftingStation.FORGE: (255, 100, 50),
                CraftingStation.ALCHEMY_LAB: (150, 100, 255),
                CraftingStation.COOKING_POT: (255, 200, 100),
                CraftingStation.ENCHANTING_TABLE: (100, 200, 255),
            }
            color = station_colors.get(recipe.station, (150, 150, 150))
            pygame.draw.circle(self.screen, color, (30, y + 35), 12)
            
            name = self.small_font.render(recipe.name, True, (200, 200, 255))
            self.screen.blit(name, (50, y + 10))
            
            station = self.small_font.render(recipe.station.value, True, (150, 150, 150))
            self.screen.blit(station, (50, y + 30))
            
            mats = self.small_font.render(f"{len(recipe.materials)} materials", True, (120, 120, 140))
            self.screen.blit(mats, (50, y + 50))
            
            y += 75
        
        # Properties
        if self.current_recipe:
            self._draw_properties()
        
        pygame.display.flip()
    
    def _draw_properties(self):
        """Draw properties"""
        panel_x = 370
        pygame.draw.rect(self.screen, (35, 35, 45), (panel_x, 50, 810, self.height - 50))
        
        recipe = self.current_recipe
        y = 80
        
        # Basic info
        title = self.font.render(recipe.name, True, (200, 200, 255))
        self.screen.blit(title, (panel_x + 20, y))
        y += 40
        
        props = [
            ("Station", recipe.station.value),
            ("Required Level", str(recipe.required_level)),
            ("Success Rate", f"{recipe.success_rate * 100:.0f}%"),
            ("Crafting Time", f"{recipe.crafting_time}s"),
            ("Gold Cost", f"{recipe.gold_cost}g"),
            ("Skill EXP", str(recipe.skill_exp_gain)),
        ]
        
        for label, value in props:
            lbl = self.small_font.render(f"{label}:", True, (180, 180, 180))
            self.screen.blit(lbl, (panel_x + 30, y))
            
            val = self.small_font.render(value, True, (255, 255, 255))
            self.screen.blit(val, (panel_x + 250, y))
            
            y += 25
        
        # Materials
        y += 20
        mats_title = self.font.render("Materials Required", True, (200, 200, 255))
        self.screen.blit(mats_title, (panel_x + 20, y))
        y += 35
        
        for mat in recipe.materials:
            mat_text = self.small_font.render(
                f"Item #{mat.item_id} x{mat.quantity}",
                True, (255, 200, 150))
            self.screen.blit(mat_text, (panel_x + 40, y))
            
            if not mat.consumed:
                tool_text = self.small_font.render("(Tool)", True, (150, 150, 150))
                self.screen.blit(tool_text, (panel_x + 300, y))
            
            y += 25
        
        # Result
        y += 20
        result_title = self.font.render("Result", True, (200, 200, 255))
        self.screen.blit(result_title, (panel_x + 20, y))
        y += 35
        
        result_text = self.small_font.render(
            f"Item #{recipe.result_item_id} x{recipe.result_quantity}",
            True, (150, 255, 150))
        self.screen.blit(result_text, (panel_x + 40, y))


def main():
    editor = CraftingSystemEditor()
    editor.run()


if __name__ == "__main__":
    main()
