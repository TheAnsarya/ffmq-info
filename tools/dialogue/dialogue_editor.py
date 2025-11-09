#!/usr/bin/env python3
"""
Dialogue System Editor

Branching dialogue and conversation trees.
Features:
- Character portraits
- Dialogue choices
- Branching paths
- Condition checking
- Script triggers
"""

from dataclasses import dataclass, field
from enum import Enum
from typing import List, Optional, Dict
import pygame
import json


class DialogueNodeType(Enum):
    """Node types"""
    TEXT = "text"
    CHOICE = "choice"
    BRANCH = "branch"
    END = "end"


@dataclass
class DialogueChoice:
    """Player choice option"""
    choice_id: int
    text: str
    next_node_id: int
    requires_flag: Optional[str] = None
    
    def to_dict(self) -> dict:
        return {
            "choice_id": self.choice_id,
            "text": self.text,
            "next_node_id": self.next_node_id,
            "requires_flag": self.requires_flag,
        }
    
    @staticmethod
    def from_dict(data: dict) -> 'DialogueChoice':
        return DialogueChoice(
            choice_id=data["choice_id"],
            text=data["text"],
            next_node_id=data["next_node_id"],
            requires_flag=data.get("requires_flag"),
        )


@dataclass
class DialogueNode:
    """Dialogue tree node"""
    node_id: int
    node_type: DialogueNodeType
    speaker: str = ""
    text: str = ""
    portrait_id: int = 0
    next_node_id: Optional[int] = None
    choices: List[DialogueChoice] = field(default_factory=list)
    set_flags: List[str] = field(default_factory=list)
    
    def to_dict(self) -> dict:
        return {
            "node_id": self.node_id,
            "node_type": self.node_type.value,
            "speaker": self.speaker,
            "text": self.text,
            "portrait_id": self.portrait_id,
            "next_node_id": self.next_node_id,
            "choices": [c.to_dict() for c in self.choices],
            "set_flags": self.set_flags,
        }
    
    @staticmethod
    def from_dict(data: dict) -> 'DialogueNode':
        return DialogueNode(
            node_id=data["node_id"],
            node_type=DialogueNodeType(data["node_type"]),
            speaker=data.get("speaker", ""),
            text=data.get("text", ""),
            portrait_id=data.get("portrait_id", 0),
            next_node_id=data.get("next_node_id"),
            choices=[DialogueChoice.from_dict(c) for c in data.get("choices", [])],
            set_flags=data.get("set_flags", []),
        )


@dataclass
class Dialogue:
    """Complete dialogue tree"""
    dialogue_id: int
    name: str
    start_node_id: int
    nodes: List[DialogueNode] = field(default_factory=list)
    
    def get_node(self, node_id: int) -> Optional[DialogueNode]:
        """Get node by ID"""
        for node in self.nodes:
            if node.node_id == node_id:
                return node
        return None
    
    def to_dict(self) -> dict:
        return {
            "dialogue_id": self.dialogue_id,
            "name": self.name,
            "start_node_id": self.start_node_id,
            "nodes": [n.to_dict() for n in self.nodes],
        }
    
    @staticmethod
    def from_dict(data: dict) -> 'Dialogue':
        return Dialogue(
            dialogue_id=data["dialogue_id"],
            name=data["name"],
            start_node_id=data["start_node_id"],
            nodes=[DialogueNode.from_dict(n) for n in data.get("nodes", [])],
        )


class DialogueEditor:
    """Dialogue editor UI"""
    
    def __init__(self, width: int = 1400, height: int = 900):
        self.width = width
        self.height = height
        self.running = True
        
        pygame.init()
        self.screen = pygame.display.set_mode((width, height))
        pygame.display.set_caption("Dialogue Editor")
        self.clock = pygame.time.Clock()
        
        self.font = pygame.font.Font(None, 24)
        self.small_font = pygame.font.Font(None, 18)
        
        # Sample dialogue
        self.dialogues = self._create_sample()
        self.current_dialogue: Optional[Dialogue] = self.dialogues[0] if self.dialogues else None
        self.selected_node: Optional[DialogueNode] = None
        self.scroll = 0
    
    def _create_sample(self) -> List[Dialogue]:
        """Create sample dialogue"""
        dialogue = Dialogue(1, "Merchant Greeting", 1)
        
        # Node 1: Greeting
        dialogue.nodes.append(DialogueNode(
            node_id=1,
            node_type=DialogueNodeType.TEXT,
            speaker="Merchant",
            text="Welcome to my shop! What can I do for you?",
            next_node_id=2,
        ))
        
        # Node 2: Choice
        dialogue.nodes.append(DialogueNode(
            node_id=2,
            node_type=DialogueNodeType.CHOICE,
            speaker="Merchant",
            text="So, what'll it be?",
            choices=[
                DialogueChoice(1, "Show me your wares", 3),
                DialogueChoice(2, "Tell me about this town", 4),
                DialogueChoice(3, "Nothing, thanks", 5),
            ],
        ))
        
        # Node 3: Shop
        dialogue.nodes.append(DialogueNode(
            node_id=3,
            node_type=DialogueNodeType.TEXT,
            speaker="Merchant",
            text="Here's what I have in stock today!",
            next_node_id=5,
            set_flags=["opened_shop"],
        ))
        
        # Node 4: Info
        dialogue.nodes.append(DialogueNode(
            node_id=4,
            node_type=DialogueNodeType.TEXT,
            speaker="Merchant",
            text="This is a peaceful trading town. We get travelers from all over!",
            next_node_id=2,
        ))
        
        # Node 5: End
        dialogue.nodes.append(DialogueNode(
            node_id=5,
            node_type=DialogueNodeType.END,
            speaker="Merchant",
            text="Come back anytime!",
        ))
        
        return [dialogue]
    
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
            if self.current_dialogue:
                for node in self.current_dialogue.nodes:
                    if y_offset < y < y_offset + 80:
                        self.selected_node = node
                        break
                    y_offset += 85
    
    def _save(self):
        """Save dialogues"""
        data = {"dialogues": [d.to_dict() for d in self.dialogues]}
        with open("dialogues.json", 'w') as f:
            json.dump(data, f, indent=2)
        print("Saved dialogues")
    
    def _render(self):
        """Render UI"""
        self.screen.fill((25, 25, 35))
        
        # Toolbar
        pygame.draw.rect(self.screen, (45, 45, 55), (0, 0, self.width, 40))
        if self.current_dialogue:
            title = self.font.render(f"Dialogue: {self.current_dialogue.name}", True, (255, 255, 255))
            self.screen.blit(title, (10, 10))
        
        # Node list
        if self.current_dialogue:
            self._draw_node_list()
        
        # Properties
        if self.selected_node:
            self._draw_properties()
        
        pygame.display.flip()
    
    def _draw_node_list(self):
        """Draw node list"""
        pygame.draw.rect(self.screen, (35, 35, 45), (0, 50, 350, self.height - 50))
        
        y = 80 - self.scroll
        for node in self.current_dialogue.nodes:
            bg = (60, 60, 80) if node == self.selected_node else (45, 45, 55)
            pygame.draw.rect(self.screen, bg, (10, y, 330, 80))
            
            # Type indicator
            type_colors = {
                DialogueNodeType.TEXT: (100, 200, 255),
                DialogueNodeType.CHOICE: (255, 200, 100),
                DialogueNodeType.BRANCH: (200, 100, 255),
                DialogueNodeType.END: (255, 100, 100),
            }
            color = type_colors.get(node.node_type, (150, 150, 150))
            pygame.draw.circle(self.screen, color, (30, y + 40), 12)
            
            # Node ID
            id_text = self.small_font.render(f"#{node.node_id}", True, (150, 150, 150))
            self.screen.blit(id_text, (50, y + 10))
            
            # Speaker
            if node.speaker:
                speaker = self.small_font.render(node.speaker, True, (200, 200, 255))
                self.screen.blit(speaker, (50, y + 30))
            
            # Preview
            preview = node.text[:40] + "..." if len(node.text) > 40 else node.text
            text = self.small_font.render(preview, True, (180, 180, 180))
            self.screen.blit(text, (50, y + 50))
            
            y += 85
    
    def _draw_properties(self):
        """Draw properties panel"""
        panel_x = 370
        pygame.draw.rect(self.screen, (35, 35, 45), (panel_x, 50, 1010, self.height - 50))
        
        node = self.selected_node
        y = 80
        
        # Node info
        props = [
            ("Node ID", f"#{node.node_id}"),
            ("Type", node.node_type.value),
            ("Speaker", node.speaker or "None"),
        ]
        
        for label, value in props:
            lbl = self.small_font.render(f"{label}:", True, (180, 180, 180))
            self.screen.blit(lbl, (panel_x + 20, y))
            
            val = self.small_font.render(value, True, (255, 255, 255))
            self.screen.blit(val, (panel_x + 150, y))
            
            y += 25
        
        # Text
        y += 20
        text_title = self.font.render("Text:", True, (200, 200, 255))
        self.screen.blit(text_title, (panel_x + 20, y))
        y += 30
        
        # Word wrap
        words = node.text.split()
        line = ""
        for word in words:
            test = line + word + " "
            if len(test) > 70:
                text_surf = self.small_font.render(line, True, (180, 180, 180))
                self.screen.blit(text_surf, (panel_x + 30, y))
                y += 20
                line = word + " "
            else:
                line = test
        
        if line:
            text_surf = self.small_font.render(line, True, (180, 180, 180))
            self.screen.blit(text_surf, (panel_x + 30, y))
            y += 20
        
        # Choices
        if node.choices:
            y += 20
            choices_title = self.font.render("Choices:", True, (200, 200, 255))
            self.screen.blit(choices_title, (panel_x + 20, y))
            y += 30
            
            for choice in node.choices:
                choice_text = self.small_font.render(
                    f"→ {choice.text} (leads to #{choice.next_node_id})",
                    True, (255, 200, 100))
                self.screen.blit(choice_text, (panel_x + 30, y))
                y += 25
        
        # Next node
        if node.next_node_id:
            y += 20
            next_text = self.small_font.render(
                f"Next: Node #{node.next_node_id}",
                True, (150, 200, 255))
            self.screen.blit(next_text, (panel_x + 20, y))


def main():
    editor = DialogueEditor()
    editor.run()


if __name__ == "__main__":
    main()
