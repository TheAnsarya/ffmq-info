#!/usr/bin/env python3
"""
Skill Tree Editor

Character skill progression and upgrade paths.
Features:
- Branching skill trees
- Prerequisites
- Stat bonuses
- Active/passive skills
- Unlock costs
"""

from dataclasses import dataclass, field
from enum import Enum
from typing import List, Optional, Set, Dict
import pygame
import json
import math


class SkillCategory(Enum):
    """Skill categories"""
    COMBAT = "combat"
    MAGIC = "magic"
    DEFENSE = "defense"
    SUPPORT = "support"
    PASSIVE = "passive"


@dataclass
class SkillNode:
    """Skill tree node"""
    skill_id: int
    name: str
    category: SkillCategory
    description: str = ""
    max_level: int = 1
    position: tuple = (0, 0)  # Tree position
    prerequisites: List[int] = field(default_factory=list)
    unlock_cost: int = 1  # Skill points
    stat_bonuses: Dict[str, int] = field(default_factory=dict)
    
    def to_dict(self) -> dict:
        return {
            "skill_id": self.skill_id,
            "name": self.name,
            "category": self.category.value,
            "description": self.description,
            "max_level": self.max_level,
            "position": list(self.position),
            "prerequisites": self.prerequisites,
            "unlock_cost": self.unlock_cost,
            "stat_bonuses": self.stat_bonuses,
        }
    
    @staticmethod
    def from_dict(data: dict) -> 'SkillNode':
        return SkillNode(
            skill_id=data["skill_id"],
            name=data["name"],
            category=SkillCategory(data["category"]),
            description=data.get("description", ""),
            max_level=data.get("max_level", 1),
            position=tuple(data.get("position", [0, 0])),
            prerequisites=data.get("prerequisites", []),
            unlock_cost=data.get("unlock_cost", 1),
            stat_bonuses=data.get("stat_bonuses", {}),
        )


@dataclass
class SkillTree:
    """Complete skill tree"""
    tree_id: int
    name: str
    character_id: int
    nodes: List[SkillNode] = field(default_factory=list)
    
    def get_node(self, skill_id: int) -> Optional[SkillNode]:
        """Get node by ID"""
        for node in self.nodes:
            if node.skill_id == skill_id:
                return node
        return None
    
    def to_dict(self) -> dict:
        return {
            "tree_id": self.tree_id,
            "name": self.name,
            "character_id": self.character_id,
            "nodes": [n.to_dict() for n in self.nodes],
        }
    
    @staticmethod
    def from_dict(data: dict) -> 'SkillTree':
        return SkillTree(
            tree_id=data["tree_id"],
            name=data["name"],
            character_id=data["character_id"],
            nodes=[SkillNode.from_dict(n) for n in data.get("nodes", [])],
        )


class SkillTreeEditor:
    """Skill tree editor UI"""
    
    def __init__(self, width: int = 1400, height: int = 900):
        self.width = width
        self.height = height
        self.running = True
        
        pygame.init()
        self.screen = pygame.display.set_mode((width, height))
        pygame.display.set_caption("Skill Tree Editor")
        self.clock = pygame.time.Clock()
        
        self.font = pygame.font.Font(None, 24)
        self.small_font = pygame.font.Font(None, 18)
        
        # Sample tree
        self.trees = self._create_sample_trees()
        self.current_tree: Optional[SkillTree] = self.trees[0] if self.trees else None
        self.selected_node: Optional[SkillNode] = None
        
        # View state
        self.camera_x = 0
        self.camera_y = 0
        self.zoom = 1.0
    
    def _create_sample_trees(self) -> List[SkillTree]:
        """Create sample skill trees"""
        tree = SkillTree(1, "Warrior Skills", 1)
        
        # Root skills
        tree.nodes.append(SkillNode(
            skill_id=1,
            name="Basic Attack",
            category=SkillCategory.COMBAT,
            description="Fundamental combat skill",
            max_level=5,
            position=(200, 100),
            unlock_cost=0,
            stat_bonuses={"strength": 2},
        ))
        
        # Tier 2
        tree.nodes.append(SkillNode(
            skill_id=2,
            name="Power Strike",
            category=SkillCategory.COMBAT,
            description="Powerful single-target attack",
            max_level=3,
            position=(100, 200),
            prerequisites=[1],
            unlock_cost=2,
            stat_bonuses={"strength": 5},
        ))
        
        tree.nodes.append(SkillNode(
            skill_id=3,
            name="Defense Stance",
            category=SkillCategory.DEFENSE,
            description="Increase defense temporarily",
            max_level=3,
            position=(300, 200),
            prerequisites=[1],
            unlock_cost=2,
            stat_bonuses={"defense": 5},
        ))
        
        # Tier 3
        tree.nodes.append(SkillNode(
            skill_id=4,
            name="Cleave",
            category=SkillCategory.COMBAT,
            description="Hit multiple enemies",
            max_level=2,
            position=(50, 300),
            prerequisites=[2],
            unlock_cost=3,
            stat_bonuses={"strength": 8},
        ))
        
        tree.nodes.append(SkillNode(
            skill_id=5,
            name="Berserker Rage",
            category=SkillCategory.COMBAT,
            description="Trade defense for offense",
            max_level=1,
            position=(150, 300),
            prerequisites=[2],
            unlock_cost=5,
            stat_bonuses={"strength": 15, "defense": -5},
        ))
        
        tree.nodes.append(SkillNode(
            skill_id=6,
            name="Iron Wall",
            category=SkillCategory.DEFENSE,
            description="Massively boost defense",
            max_level=1,
            position=(350, 300),
            prerequisites=[3],
            unlock_cost=5,
            stat_bonuses={"defense": 20},
        ))
        
        return [tree]
    
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
                elif event.key == pygame.K_LEFT:
                    self.camera_x -= 20
                elif event.key == pygame.K_RIGHT:
                    self.camera_x += 20
                elif event.key == pygame.K_UP:
                    self.camera_y -= 20
                elif event.key == pygame.K_DOWN:
                    self.camera_y += 20
            
            elif event.type == pygame.MOUSEBUTTONDOWN:
                if event.button == 1:
                    self._handle_click(event.pos)
            
            elif event.type == pygame.MOUSEWHEEL:
                if pygame.key.get_mods() & pygame.KMOD_CTRL:
                    self.zoom *= 1.1 if event.y > 0 else 0.9
                    self.zoom = max(0.5, min(2.0, self.zoom))
    
    def _handle_click(self, pos: tuple):
        """Handle click"""
        if not self.current_tree:
            return
        
        x, y = pos
        
        # Convert to tree coordinates
        tree_x = (x - 400 - self.camera_x) / self.zoom
        tree_y = (y - 50 - self.camera_y) / self.zoom
        
        # Check nodes
        for node in self.current_tree.nodes:
            nx, ny = node.position
            dist = math.sqrt((tree_x - nx) ** 2 + (tree_y - ny) ** 2)
            if dist < 30:
                self.selected_node = node
                return
        
        self.selected_node = None
    
    def _save(self):
        """Save trees"""
        data = {"trees": [t.to_dict() for t in self.trees]}
        with open("skill_trees.json", 'w') as f:
            json.dump(data, f, indent=2)
        print("Saved skill trees")
    
    def _render(self):
        """Render UI"""
        self.screen.fill((25, 25, 35))
        
        # Toolbar
        pygame.draw.rect(self.screen, (45, 45, 55), (0, 0, self.width, 40))
        if self.current_tree:
            title = self.font.render(f"Skill Tree: {self.current_tree.name}", True, (255, 255, 255))
            self.screen.blit(title, (10, 10))
        
        # Tree view
        if self.current_tree:
            self._draw_tree_view()
        
        # Properties panel
        if self.selected_node:
            self._draw_properties()
        
        pygame.display.flip()
    
    def _draw_tree_view(self):
        """Draw skill tree view"""
        view_x = 400
        view_y = 50
        view_width = 700
        view_height = self.height - 100
        
        # Background
        pygame.draw.rect(self.screen, (15, 15, 25), (view_x, view_y, view_width, view_height))
        pygame.draw.rect(self.screen, (80, 80, 100), (view_x, view_y, view_width, view_height), 2)
        
        # Draw connections
        for node in self.current_tree.nodes:
            for prereq_id in node.prerequisites:
                prereq = self.current_tree.get_node(prereq_id)
                if prereq:
                    x1 = view_x + int(prereq.position[0] * self.zoom) + self.camera_x
                    y1 = view_y + int(prereq.position[1] * self.zoom) + self.camera_y
                    x2 = view_x + int(node.position[0] * self.zoom) + self.camera_x
                    y2 = view_y + int(node.position[1] * self.zoom) + self.camera_y
                    
                    pygame.draw.line(self.screen, (100, 100, 150), (x1, y1), (x2, y2), 2)
        
        # Draw nodes
        category_colors = {
            SkillCategory.COMBAT: (255, 100, 100),
            SkillCategory.MAGIC: (100, 100, 255),
            SkillCategory.DEFENSE: (100, 200, 255),
            SkillCategory.SUPPORT: (100, 255, 100),
            SkillCategory.PASSIVE: (255, 255, 100),
        }
        
        for node in self.current_tree.nodes:
            x = view_x + int(node.position[0] * self.zoom) + self.camera_x
            y = view_y + int(node.position[1] * self.zoom) + self.camera_y
            
            radius = int(30 * self.zoom)
            color = category_colors.get(node.category, (150, 150, 150))
            
            # Selection highlight
            if node == self.selected_node:
                pygame.draw.circle(self.screen, (255, 255, 100), (x, y), radius + 4, 3)
            
            # Node circle
            pygame.draw.circle(self.screen, color, (x, y), radius)
            pygame.draw.circle(self.screen, (255, 255, 255), (x, y), radius, 2)
            
            # Name
            if self.zoom >= 0.7:
                name_surf = self.small_font.render(node.name[:10], True, (255, 255, 255))
                name_x = x - name_surf.get_width() // 2
                name_y = y - 8
                self.screen.blit(name_surf, (name_x, name_y))
    
    def _draw_properties(self):
        """Draw properties panel"""
        panel_x = 0
        panel_y = 50
        panel_width = 380
        panel_height = self.height - 50
        
        pygame.draw.rect(self.screen, (35, 35, 45), (panel_x, panel_y, panel_width, panel_height))
        pygame.draw.rect(self.screen, (80, 80, 100), (panel_x, panel_y, panel_width, panel_height), 2)
        
        node = self.selected_node
        y = 80
        
        # Name
        name = self.font.render(node.name, True, (200, 200, 255))
        self.screen.blit(name, (20, y))
        y += 40
        
        # Properties
        props = [
            ("Category", node.category.value),
            ("Max Level", str(node.max_level)),
            ("Unlock Cost", f"{node.unlock_cost} SP"),
            ("Prerequisites", str(len(node.prerequisites))),
        ]
        
        for label, value in props:
            lbl = self.small_font.render(f"{label}:", True, (180, 180, 180))
            self.screen.blit(lbl, (30, y))
            
            val = self.small_font.render(value, True, (255, 255, 255))
            self.screen.blit(val, (200, y))
            
            y += 25
        
        # Description
        y += 20
        desc_title = self.small_font.render("Description:", True, (200, 200, 255))
        self.screen.blit(desc_title, (30, y))
        y += 25
        
        # Word wrap
        words = node.description.split()
        line = ""
        for word in words:
            test = line + word + " "
            if len(test) > 35:
                desc = self.small_font.render(line, True, (180, 180, 180))
                self.screen.blit(desc, (40, y))
                y += 20
                line = word + " "
            else:
                line = test
        
        if line:
            desc = self.small_font.render(line, True, (180, 180, 180))
            self.screen.blit(desc, (40, y))
            y += 20
        
        # Stat bonuses
        if node.stat_bonuses:
            y += 20
            bonus_title = self.small_font.render("Stat Bonuses:", True, (200, 200, 255))
            self.screen.blit(bonus_title, (30, y))
            y += 25
            
            for stat, value in node.stat_bonuses.items():
                sign = "+" if value >= 0 else ""
                color = (150, 255, 150) if value >= 0 else (255, 150, 150)
                bonus = self.small_font.render(f"{stat}: {sign}{value}", True, color)
                self.screen.blit(bonus, (40, y))
                y += 22


def main():
    editor = SkillTreeEditor()
    editor.run()


if __name__ == "__main__":
    main()
