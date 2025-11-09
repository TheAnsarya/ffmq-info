#!/usr/bin/env python3
"""
Quest System Editor

Comprehensive quest and mission management tool.
Features include:
- Quest chains and dependencies
- Objective tracking (kill, collect, talk, explore)
- Branching quest paths
- Reward configuration
- Quest state management
- Conditional unlocking
- Visual quest tree
- Progress tracking
- Export to game format

Quest Components:
- Objectives: Goals to complete
- Rewards: Items, gold, exp, skills
- Requirements: Level, items, flags
- Branches: Multiple paths
- Chains: Sequential quests

Quest Types:
- Main Story: Core narrative
- Side Quest: Optional content
- Repeatable: Daily/weekly quests
- Hidden: Secret quests
- Event: Time-limited
"""

from dataclasses import dataclass, field
from enum import Enum
from typing import Dict, List, Optional, Tuple, Any, Set
import pygame
import json
import math


class QuestType(Enum):
    """Quest type categories"""
    MAIN_STORY = "main_story"
    SIDE_QUEST = "side_quest"
    REPEATABLE = "repeatable"
    HIDDEN = "hidden"
    EVENT = "event"
    TUTORIAL = "tutorial"


class QuestStatus(Enum):
    """Quest completion status"""
    NOT_STARTED = "not_started"
    AVAILABLE = "available"
    ACTIVE = "active"
    COMPLETED = "completed"
    FAILED = "failed"
    LOCKED = "locked"


class ObjectiveType(Enum):
    """Objective types"""
    KILL_ENEMY = "kill_enemy"
    COLLECT_ITEM = "collect_item"
    TALK_TO_NPC = "talk_to_npc"
    EXPLORE_AREA = "explore_area"
    DELIVER_ITEM = "deliver_item"
    ESCORT_NPC = "escort_npc"
    DEFEAT_BOSS = "defeat_boss"
    REACH_LEVEL = "reach_level"
    LEARN_SKILL = "learn_skill"
    EQUIP_ITEM = "equip_item"
    SPEND_GOLD = "spend_gold"
    CUSTOM = "custom"


class RewardType(Enum):
    """Reward types"""
    GOLD = "gold"
    EXP = "exp"
    ITEM = "item"
    SKILL = "skill"
    FLAG = "flag"
    REPUTATION = "reputation"
    UNLOCK_QUEST = "unlock_quest"
    UNLOCK_AREA = "unlock_area"


@dataclass
class Objective:
    """Quest objective"""
    objective_id: int
    objective_type: ObjectiveType
    description: str
    target: str = ""  # Enemy ID, item ID, NPC ID, area ID
    required_count: int = 1
    current_count: int = 0
    optional: bool = False
    hidden: bool = False

    def is_complete(self) -> bool:
        """Check if objective is complete"""
        return self.current_count >= self.required_count

    def get_progress(self) -> float:
        """Get completion progress (0.0 to 1.0)"""
        if self.required_count == 0:
            return 1.0
        return min(1.0, self.current_count / self.required_count)

    def to_dict(self) -> dict:
        """Convert to dictionary"""
        return {
            "objective_id": self.objective_id,
            "objective_type": self.objective_type.value,
            "description": self.description,
            "target": self.target,
            "required_count": self.required_count,
            "current_count": self.current_count,
            "optional": self.optional,
            "hidden": self.hidden,
        }

    @staticmethod
    def from_dict(data: dict) -> 'Objective':
        """Create from dictionary"""
        return Objective(
            objective_id=data["objective_id"],
            objective_type=ObjectiveType(data["objective_type"]),
            description=data["description"],
            target=data.get("target", ""),
            required_count=data.get("required_count", 1),
            current_count=data.get("current_count", 0),
            optional=data.get("optional", False),
            hidden=data.get("hidden", False),
        )


@dataclass
class Reward:
    """Quest reward"""
    reward_type: RewardType
    value: Any  # Gold amount, item ID, skill ID, flag name, etc.
    amount: int = 1

    def get_description(self) -> str:
        """Get human-readable description"""
        if self.reward_type == RewardType.GOLD:
            return f"{self.value} Gold"
        elif self.reward_type == RewardType.EXP:
            return f"{self.value} EXP"
        elif self.reward_type == RewardType.ITEM:
            return f"{self.value} x{self.amount}"
        elif self.reward_type == RewardType.SKILL:
            return f"Skill: {self.value}"
        elif self.reward_type == RewardType.FLAG:
            return f"Flag: {self.value}"
        elif self.reward_type == RewardType.REPUTATION:
            return f"Reputation +{self.value}"
        elif self.reward_type == RewardType.UNLOCK_QUEST:
            return f"Unlock Quest: {self.value}"
        elif self.reward_type == RewardType.UNLOCK_AREA:
            return f"Unlock Area: {self.value}"
        return str(self.value)

    def to_dict(self) -> dict:
        """Convert to dictionary"""
        return {
            "reward_type": self.reward_type.value,
            "value": self.value,
            "amount": self.amount,
        }

    @staticmethod
    def from_dict(data: dict) -> 'Reward':
        """Create from dictionary"""
        return Reward(
            reward_type=RewardType(data["reward_type"]),
            value=data["value"],
            amount=data.get("amount", 1),
        )


@dataclass
class QuestRequirement:
    """Quest unlock requirement"""
    required_level: int = 1
    required_quests: List[int] = field(default_factory=list)
    required_flags: List[str] = field(default_factory=list)
    required_items: List[str] = field(default_factory=list)
    forbidden_flags: List[str] = field(default_factory=list)

    def is_met(self, context: Dict[str, Any]) -> bool:
        """Check if requirements are met"""
        # Check level
        player_level = context.get("level", 1)
        if player_level < self.required_level:
            return False

        # Check completed quests
        completed_quests = context.get("completed_quests", set())
        for quest_id in self.required_quests:
            if quest_id not in completed_quests:
                return False

        # Check flags
        flags = context.get("flags", set())
        for flag in self.required_flags:
            if flag not in flags:
                return False

        for flag in self.forbidden_flags:
            if flag in flags:
                return False

        # Check items
        inventory = context.get("inventory", set())
        for item in self.required_items:
            if item not in inventory:
                return False

        return True

    def to_dict(self) -> dict:
        """Convert to dictionary"""
        return {
            "required_level": self.required_level,
            "required_quests": self.required_quests,
            "required_flags": self.required_flags,
            "required_items": self.required_items,
            "forbidden_flags": self.forbidden_flags,
        }

    @staticmethod
    def from_dict(data: dict) -> 'QuestRequirement':
        """Create from dictionary"""
        return QuestRequirement(
            required_level=data.get("required_level", 1),
            required_quests=data.get("required_quests", []),
            required_flags=data.get("required_flags", []),
            required_items=data.get("required_items", []),
            forbidden_flags=data.get("forbidden_flags", []),
        )


@dataclass
class Quest:
    """Complete quest definition"""
    quest_id: int
    name: str
    description: str
    quest_type: QuestType = QuestType.SIDE_QUEST
    objectives: List[Objective] = field(default_factory=list)
    rewards: List[Reward] = field(default_factory=list)
    requirements: QuestRequirement = field(default_factory=QuestRequirement)
    giver_npc: str = ""
    turn_in_npc: str = ""
    time_limit: int = 0  # Seconds, 0 = no limit
    repeatable: bool = False
    repeat_delay: int = 0  # Seconds between repeats
    next_quests: List[int] = field(default_factory=list)
    branches: Dict[str, int] = field(default_factory=dict)  # Choice -> quest_id
    status: QuestStatus = QuestStatus.NOT_STARTED

    def is_complete(self) -> bool:
        """Check if all required objectives are complete"""
        for obj in self.objectives:
            if not obj.optional and not obj.is_complete():
                return False
        return True

    def get_progress(self) -> float:
        """Get overall quest progress"""
        if not self.objectives:
            return 1.0

        required_objs = [obj for obj in self.objectives if not obj.optional]
        if not required_objs:
            return 1.0

        total_progress = sum(obj.get_progress() for obj in required_objs)
        return total_progress / len(required_objs)

    def get_incomplete_objectives(self) -> List[Objective]:
        """Get list of incomplete objectives"""
        return [obj for obj in self.objectives if not obj.is_complete()]

    def to_dict(self) -> dict:
        """Convert to dictionary"""
        return {
            "quest_id": self.quest_id,
            "name": self.name,
            "description": self.description,
            "quest_type": self.quest_type.value,
            "giver_npc": self.giver_npc,
            "turn_in_npc": self.turn_in_npc,
            "time_limit": self.time_limit,
            "repeatable": self.repeatable,
            "repeat_delay": self.repeat_delay,
            "next_quests": self.next_quests,
            "branches": self.branches,
            "status": self.status.value,
            "objectives": [obj.to_dict() for obj in self.objectives],
            "rewards": [rew.to_dict() for rew in self.rewards],
            "requirements": self.requirements.to_dict(),
        }

    @staticmethod
    def from_dict(data: dict) -> 'Quest':
        """Create from dictionary"""
        return Quest(
            quest_id=data["quest_id"],
            name=data["name"],
            description=data["description"],
            quest_type=QuestType(data.get("quest_type", "side_quest")),
            giver_npc=data.get("giver_npc", ""),
            turn_in_npc=data.get("turn_in_npc", ""),
            time_limit=data.get("time_limit", 0),
            repeatable=data.get("repeatable", False),
            repeat_delay=data.get("repeat_delay", 0),
            next_quests=data.get("next_quests", []),
            branches=data.get("branches", {}),
            status=QuestStatus(data.get("status", "not_started")),
            objectives=[Objective.from_dict(obj) for obj in data.get("objectives", [])],
            rewards=[Reward.from_dict(rew) for rew in data.get("rewards", [])],
            requirements=QuestRequirement.from_dict(data.get("requirements", {})),
        )


class QuestDatabase:
    """Database of quests"""

    def __init__(self):
        self.quests: Dict[int, Quest] = {}
        self._init_sample_data()

    def _init_sample_data(self):
        """Initialize sample quests"""
        # Tutorial quest
        tutorial = Quest(
            quest_id=1,
            name="Welcome to Adventure",
            description="Learn the basics of adventuring.",
            quest_type=QuestType.TUTORIAL,
            giver_npc="Village Elder",
            turn_in_npc="Village Elder",
        )

        tutorial.objectives.append(Objective(
            objective_id=1,
            objective_type=ObjectiveType.TALK_TO_NPC,
            description="Talk to the Blacksmith",
            target="blacksmith_npc",
        ))

        tutorial.objectives.append(Objective(
            objective_id=2,
            objective_type=ObjectiveType.COLLECT_ITEM,
            description="Collect 5 herbs",
            target="herb_item",
            required_count=5,
        ))

        tutorial.rewards.append(Reward(RewardType.GOLD, 100))
        tutorial.rewards.append(Reward(RewardType.EXP, 50))
        tutorial.rewards.append(Reward(RewardType.ITEM, "potion", 3))

        self.quests[1] = tutorial

        # Main story quest
        main_quest = Quest(
            quest_id=2,
            name="The Dark Forest",
            description="Investigate strange occurrences in the forest.",
            quest_type=QuestType.MAIN_STORY,
            giver_npc="Guard Captain",
            turn_in_npc="Guard Captain",
            requirements=QuestRequirement(
                required_level=5,
                required_quests=[1],
            ),
        )

        main_quest.objectives.append(Objective(
            objective_id=1,
            objective_type=ObjectiveType.EXPLORE_AREA,
            description="Explore the Dark Forest",
            target="dark_forest",
        ))

        main_quest.objectives.append(Objective(
            objective_id=2,
            objective_type=ObjectiveType.KILL_ENEMY,
            description="Defeat shadow creatures",
            target="shadow_creature",
            required_count=10,
        ))

        main_quest.objectives.append(Objective(
            objective_id=3,
            objective_type=ObjectiveType.DEFEAT_BOSS,
            description="Defeat the Forest Guardian",
            target="forest_guardian",
        ))

        main_quest.rewards.append(Reward(RewardType.GOLD, 500))
        main_quest.rewards.append(Reward(RewardType.EXP, 300))
        main_quest.rewards.append(Reward(RewardType.ITEM, "forest_blade", 1))
        main_quest.rewards.append(Reward(RewardType.UNLOCK_AREA, "mountain_pass"))

        main_quest.next_quests = [3, 4]  # Unlocks two follow-up quests

        self.quests[2] = main_quest

        # Side quest with branching
        side_quest = Quest(
            quest_id=3,
            name="The Lost Artifact",
            description="Help the archaeologist find a lost artifact.",
            quest_type=QuestType.SIDE_QUEST,
            giver_npc="Archaeologist",
            turn_in_npc="Archaeologist",
            requirements=QuestRequirement(required_level=7),
        )

        side_quest.objectives.append(Objective(
            objective_id=1,
            objective_type=ObjectiveType.COLLECT_ITEM,
            description="Find the ancient map",
            target="ancient_map",
        ))

        side_quest.objectives.append(Objective(
            objective_id=2,
            objective_type=ObjectiveType.COLLECT_ITEM,
            description="Collect 3 artifact fragments",
            target="artifact_fragment",
            required_count=3,
        ))

        side_quest.rewards.append(Reward(RewardType.GOLD, 300))
        side_quest.rewards.append(Reward(RewardType.EXP, 200))

        # Branching choices
        side_quest.branches = {
            "keep_artifact": 5,  # Player keeps it
            "donate_artifact": 6,  # Player donates to museum
        }

        self.quests[3] = side_quest

        # Repeatable daily quest
        daily_quest = Quest(
            quest_id=4,
            name="Daily Hunt",
            description="Hunt monsters for the guild.",
            quest_type=QuestType.REPEATABLE,
            giver_npc="Guild Master",
            turn_in_npc="Guild Master",
            repeatable=True,
            repeat_delay=86400,  # 24 hours
            requirements=QuestRequirement(required_level=10),
        )

        daily_quest.objectives.append(Objective(
            objective_id=1,
            objective_type=ObjectiveType.KILL_ENEMY,
            description="Defeat any enemies",
            target="any",
            required_count=20,
        ))

        daily_quest.rewards.append(Reward(RewardType.GOLD, 200))
        daily_quest.rewards.append(Reward(RewardType.EXP, 150))
        daily_quest.rewards.append(Reward(RewardType.REPUTATION, 10))

        self.quests[4] = daily_quest

    def add(self, quest: Quest):
        """Add quest to database"""
        self.quests[quest.quest_id] = quest

    def get(self, quest_id: int) -> Optional[Quest]:
        """Get quest by ID"""
        return self.quests.get(quest_id)

    def get_available_quests(self, context: Dict[str, Any]) -> List[Quest]:
        """Get quests available to player"""
        available = []
        for quest in self.quests.values():
            if quest.status == QuestStatus.NOT_STARTED:
                if quest.requirements.is_met(context):
                    available.append(quest)
        return available

    def save_json(self, filename: str):
        """Save to JSON"""
        data = {
            "quests": [q.to_dict() for q in self.quests.values()]
        }

        with open(filename, 'w') as f:
            json.dump(data, f, indent=2)

    def load_json(self, filename: str):
        """Load from JSON"""
        with open(filename, 'r') as f:
            data = json.load(f)

        self.quests = {}
        for quest_data in data.get("quests", []):
            quest = Quest.from_dict(quest_data)
            self.quests[quest.quest_id] = quest


class QuestSystemEditor:
    """Main quest system editor with UI"""

    def __init__(self, width: int = 1600, height: int = 900):
        self.width = width
        self.height = height
        self.running = True

        pygame.init()
        self.screen = pygame.display.set_mode((width, height))
        pygame.display.set_caption("Quest System Editor")
        self.clock = pygame.time.Clock()

        self.font = pygame.font.Font(None, 24)
        self.small_font = pygame.font.Font(None, 18)

        # Database
        self.database = QuestDatabase()
        self.current_quest: Optional[Quest] = None
        self.selected_quest_id: Optional[int] = None

        # UI state
        self.quest_scroll = 0
        self.current_tab = 0  # 0=Objectives, 1=Rewards, 2=Requirements

        # Quest tree layout
        self.quest_positions: Dict[int, Tuple[int, int]] = {}

        # Select first quest
        if self.database.quests:
            first_id = min(self.database.quests.keys())
            self.current_quest = self.database.quests[first_id]
            self.selected_quest_id = first_id

        self._layout_quest_tree()

    def _layout_quest_tree(self):
        """Calculate positions for quest tree"""
        if not self.database.quests:
            return

        # Group quests by level
        levels: Dict[int, List[Quest]] = {}

        for quest in self.database.quests.values():
            level = quest.requirements.required_level
            if level not in levels:
                levels[level] = []
            levels[level].append(quest)

        # Layout quests
        x_start = 350
        y_start = 150
        x_spacing = 200
        y_spacing = 120

        for level, quests in sorted(levels.items()):
            for i, quest in enumerate(quests):
                x = x_start + i * x_spacing
                y = y_start + level * y_spacing
                self.quest_positions[quest.quest_id] = (x, y)

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
                self._handle_command_input(event)

            elif event.type == pygame.MOUSEBUTTONDOWN:
                self._handle_mouse_click(event.pos, event.button)

            elif event.type == pygame.MOUSEWHEEL:
                if pygame.key.get_mods() & pygame.KMOD_SHIFT:
                    self.quest_scroll = max(0, self.quest_scroll - event.y * 30)

    def _handle_command_input(self, event):
        """Handle command input"""
        if event.key == pygame.K_ESCAPE:
            self.running = False

        # Save/Load
        elif event.key == pygame.K_s and pygame.key.get_mods() & pygame.KMOD_CTRL:
            self.database.save_json("quests.json")
            print("Quests saved to quests.json")

        elif event.key == pygame.K_o and pygame.key.get_mods() & pygame.KMOD_CTRL:
            try:
                self.database.load_json("quests.json")
                print("Quests loaded from quests.json")
            except FileNotFoundError:
                print("No quests.json file found")

        # Tabs
        elif event.key == pygame.K_1:
            self.current_tab = 0
        elif event.key == pygame.K_2:
            self.current_tab = 1
        elif event.key == pygame.K_3:
            self.current_tab = 2

        # Navigation
        elif event.key == pygame.K_UP:
            quest_ids = sorted(self.database.quests.keys())
            if self.selected_quest_id in quest_ids:
                idx = quest_ids.index(self.selected_quest_id)
                if idx > 0:
                    self.selected_quest_id = quest_ids[idx - 1]
                    self.current_quest = self.database.quests[self.selected_quest_id]

        elif event.key == pygame.K_DOWN:
            quest_ids = sorted(self.database.quests.keys())
            if self.selected_quest_id in quest_ids:
                idx = quest_ids.index(self.selected_quest_id)
                if idx < len(quest_ids) - 1:
                    self.selected_quest_id = quest_ids[idx + 1]
                    self.current_quest = self.database.quests[self.selected_quest_id]

    def _handle_mouse_click(self, pos: Tuple[int, int], button: int):
        """Handle mouse click"""
        x, y = pos

        # Check quest list
        if x < 250 and button == 1:
            y_offset = 80 - self.quest_scroll

            for quest_id in sorted(self.database.quests.keys()):
                if y_offset <= y < y_offset + 70:
                    self.current_quest = self.database.quests[quest_id]
                    self.selected_quest_id = quest_id
                    break
                y_offset += 75

        # Check tab bar
        elif 250 < x < 1200 and 50 < y < 85:
            tab_width = 150
            if 260 < x < 260 + tab_width:
                self.current_tab = 0
            elif 410 < x < 410 + tab_width:
                self.current_tab = 1
            elif 560 < x < 560 + tab_width:
                self.current_tab = 2

    def _render(self):
        """Render editor"""
        self.screen.fill((25, 25, 35))

        # Draw quest list
        self._draw_quest_list()

        # Draw main panel with tabs
        self._draw_main_panel()

        # Draw properties panel
        self._draw_properties_panel()

        # Draw toolbar
        self._draw_toolbar()

        pygame.display.flip()

    def _draw_quest_list(self):
        """Draw quest list panel"""
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
        title = self.font.render("Quests", True, (255, 255, 255))
        self.screen.blit(title, (panel_x + 10, panel_y + 10))

        # Quest list
        y_offset = panel_y + 50 - self.quest_scroll

        for quest_id in sorted(self.database.quests.keys()):
            quest = self.database.quests[quest_id]

            if y_offset + 70 < panel_y or y_offset > panel_y + panel_height:
                y_offset += 75
                continue

            # Background
            bg_color = (60, 60, 80) if quest_id == self.selected_quest_id else (
                45, 45, 55)
            pygame.draw.rect(self.screen, bg_color,
                             (panel_x + 5, y_offset, panel_width - 10, 70))
            pygame.draw.rect(self.screen, (100, 100, 120),
                             (panel_x + 5, y_offset, panel_width - 10, 70), 1)

            # Quest ID and type
            id_text = self.small_font.render(
                f"#{quest_id}", True, (180, 180, 180))
            self.screen.blit(id_text, (panel_x + 10, y_offset + 5))

            # Type indicator
            type_colors = {
                QuestType.MAIN_STORY: (255, 200, 100),
                QuestType.SIDE_QUEST: (100, 200, 255),
                QuestType.REPEATABLE: (100, 255, 100),
                QuestType.HIDDEN: (200, 100, 255),
                QuestType.EVENT: (255, 100, 100),
                QuestType.TUTORIAL: (150, 150, 255),
            }
            type_color = type_colors.get(quest.quest_type, (150, 150, 150))
            pygame.draw.circle(self.screen, type_color,
                               (panel_x + 230, y_offset + 12), 6)

            # Quest name
            name_text = self.small_font.render(
                quest.name[:25], True, (200, 200, 255))
            self.screen.blit(name_text, (panel_x + 10, y_offset + 25))

            # Objectives and rewards
            info = f"{len(quest.objectives)} obj | {len(quest.rewards)} rew"
            info_text = self.small_font.render(info, True, (150, 150, 150))
            self.screen.blit(info_text, (panel_x + 10, y_offset + 45))

            # Required level
            level_text = self.small_font.render(
                f"Lv {quest.requirements.required_level}", True, (180, 180, 180))
            self.screen.blit(level_text, (panel_x + 10, y_offset + 60))

            y_offset += 75

    def _draw_main_panel(self):
        """Draw main panel with tabs"""
        panel_x = 250
        panel_y = 50
        panel_width = 950
        panel_height = self.height - 100

        # Background
        pygame.draw.rect(self.screen, (20, 20, 30),
                         (panel_x, panel_y, panel_width, panel_height))
        pygame.draw.rect(self.screen, (80, 80, 100),
                         (panel_x, panel_y, panel_width, panel_height), 2)

        # Tab bar
        self._draw_tab_bar(panel_x, panel_y, panel_width)

        if not self.current_quest:
            return

        # Tab content
        content_y = panel_y + 45
        content_height = panel_height - 45

        if self.current_tab == 0:
            self._draw_objectives_tab(panel_x, content_y, panel_width, content_height)
        elif self.current_tab == 1:
            self._draw_rewards_tab(panel_x, content_y, panel_width, content_height)
        elif self.current_tab == 2:
            self._draw_requirements_tab(panel_x, content_y, panel_width, content_height)

    def _draw_tab_bar(self, x: int, y: int, width: int):
        """Draw tab bar"""
        tabs = ["Objectives", "Rewards", "Requirements"]
        tab_width = 150

        for i, tab_name in enumerate(tabs):
            tab_x = x + 10 + i * tab_width
            tab_y = y + 5

            # Tab background
            if i == self.current_tab:
                bg_color = (60, 60, 80)
                text_color = (255, 255, 255)
            else:
                bg_color = (40, 40, 50)
                text_color = (180, 180, 180)

            pygame.draw.rect(self.screen, bg_color,
                             (tab_x, tab_y, tab_width - 10, 30))
            pygame.draw.rect(self.screen, (100, 100, 120),
                             (tab_x, tab_y, tab_width - 10, 30), 1)

            # Tab text
            text_surf = self.small_font.render(tab_name, True, text_color)
            text_rect = text_surf.get_rect(
                center=(tab_x + (tab_width - 10) // 2, tab_y + 15))
            self.screen.blit(text_surf, text_rect)

    def _draw_objectives_tab(self, x: int, y: int, width: int, height: int):
        """Draw objectives tab"""
        y_offset = y + 20

        if not self.current_quest.objectives:
            no_obj_text = self.font.render(
                "No objectives defined", True, (150, 150, 150))
            self.screen.blit(no_obj_text, (x + 20, y_offset))
            return

        for obj in self.current_quest.objectives:
            # Objective box
            box_height = 80
            pygame.draw.rect(self.screen, (35, 35, 50),
                             (x + 20, y_offset, width - 40, box_height))
            pygame.draw.rect(self.screen, (100, 100, 120),
                             (x + 20, y_offset, width - 40, box_height), 1)

            # Objective ID and type
            id_text = self.small_font.render(
                f"#{obj.objective_id}", True, (180, 180, 180))
            self.screen.blit(id_text, (x + 30, y_offset + 10))

            type_text = self.small_font.render(
                obj.objective_type.value, True, (100, 200, 255))
            self.screen.blit(type_text, (x + 80, y_offset + 10))

            # Optional/Hidden markers
            if obj.optional:
                opt_text = self.small_font.render(
                    "[OPTIONAL]", True, (200, 200, 100))
                self.screen.blit(opt_text, (x + 250, y_offset + 10))

            if obj.hidden:
                hid_text = self.small_font.render(
                    "[HIDDEN]", True, (200, 100, 200))
                self.screen.blit(hid_text, (x + 350, y_offset + 10))

            # Description
            desc_text = self.small_font.render(
                obj.description[:60], True, (200, 200, 200))
            self.screen.blit(desc_text, (x + 30, y_offset + 35))

            # Target and count
            if obj.target:
                target_text = self.small_font.render(
                    f"Target: {obj.target}", True, (150, 150, 150))
                self.screen.blit(target_text, (x + 30, y_offset + 55))

            if obj.required_count > 1:
                count_text = self.small_font.render(
                    f"Count: {obj.current_count}/{obj.required_count}",
                    True, (150, 150, 150))
                self.screen.blit(count_text, (x + 300, y_offset + 55))

                # Progress bar
                bar_width = 200
                bar_x = x + 500
                bar_y = y_offset + 55
                progress = obj.get_progress()

                pygame.draw.rect(self.screen, (50, 50, 60),
                                 (bar_x, bar_y, bar_width, 16))
                pygame.draw.rect(self.screen, (100, 200, 100),
                                 (bar_x, bar_y, int(bar_width * progress), 16))
                pygame.draw.rect(self.screen, (100, 100, 120),
                                 (bar_x, bar_y, bar_width, 16), 1)

            y_offset += box_height + 10

    def _draw_rewards_tab(self, x: int, y: int, width: int, height: int):
        """Draw rewards tab"""
        y_offset = y + 20

        if not self.current_quest.rewards:
            no_rew_text = self.font.render(
                "No rewards defined", True, (150, 150, 150))
            self.screen.blit(no_rew_text, (x + 20, y_offset))
            return

        for reward in self.current_quest.rewards:
            # Reward box
            box_height = 50
            pygame.draw.rect(self.screen, (35, 35, 50),
                             (x + 20, y_offset, width - 40, box_height))
            pygame.draw.rect(self.screen, (100, 100, 120),
                             (x + 20, y_offset, width - 40, box_height), 1)

            # Reward type
            type_colors = {
                RewardType.GOLD: (255, 215, 0),
                RewardType.EXP: (100, 200, 255),
                RewardType.ITEM: (100, 255, 100),
                RewardType.SKILL: (255, 100, 255),
                RewardType.FLAG: (200, 200, 100),
                RewardType.REPUTATION: (255, 150, 100),
                RewardType.UNLOCK_QUEST: (150, 200, 255),
                RewardType.UNLOCK_AREA: (200, 150, 255),
            }
            type_color = type_colors.get(reward.reward_type, (150, 150, 150))

            type_text = self.small_font.render(
                reward.reward_type.value, True, type_color)
            self.screen.blit(type_text, (x + 30, y_offset + 17))

            # Description
            desc_text = self.small_font.render(
                reward.get_description(), True, (200, 200, 200))
            self.screen.blit(desc_text, (x + 200, y_offset + 17))

            y_offset += box_height + 10

    def _draw_requirements_tab(self, x: int, y: int, width: int, height: int):
        """Draw requirements tab"""
        y_offset = y + 20

        req = self.current_quest.requirements

        # Required level
        level_text = self.font.render(
            f"Required Level: {req.required_level}", True, (200, 200, 200))
        self.screen.blit(level_text, (x + 20, y_offset))
        y_offset += 40

        # Required quests
        if req.required_quests:
            quest_label = self.small_font.render(
                "Required Quests:", True, (180, 180, 180))
            self.screen.blit(quest_label, (x + 20, y_offset))
            y_offset += 25

            for quest_id in req.required_quests:
                quest_text = self.small_font.render(
                    f"  • Quest #{quest_id}", True, (150, 150, 150))
                self.screen.blit(quest_text, (x + 30, y_offset))
                y_offset += 20

            y_offset += 10

        # Required flags
        if req.required_flags:
            flag_label = self.small_font.render(
                "Required Flags:", True, (180, 180, 180))
            self.screen.blit(flag_label, (x + 20, y_offset))
            y_offset += 25

            for flag in req.required_flags:
                flag_text = self.small_font.render(
                    f"  • {flag}", True, (150, 150, 150))
                self.screen.blit(flag_text, (x + 30, y_offset))
                y_offset += 20

            y_offset += 10

        # Required items
        if req.required_items:
            item_label = self.small_font.render(
                "Required Items:", True, (180, 180, 180))
            self.screen.blit(item_label, (x + 20, y_offset))
            y_offset += 25

            for item in req.required_items:
                item_text = self.small_font.render(
                    f"  • {item}", True, (150, 150, 150))
                self.screen.blit(item_text, (x + 30, y_offset))
                y_offset += 20

            y_offset += 10

        # Forbidden flags
        if req.forbidden_flags:
            forbid_label = self.small_font.render(
                "Forbidden Flags:", True, (180, 180, 180))
            self.screen.blit(forbid_label, (x + 20, y_offset))
            y_offset += 25

            for flag in req.forbidden_flags:
                flag_text = self.small_font.render(
                    f"  • {flag}", True, (150, 150, 150))
                self.screen.blit(flag_text, (x + 30, y_offset))
                y_offset += 20

    def _draw_properties_panel(self):
        """Draw properties panel"""
        panel_x = self.width - 400
        panel_y = 50
        panel_width = 400
        panel_height = self.height - 100

        # Background
        pygame.draw.rect(self.screen, (35, 35, 45),
                         (panel_x, panel_y, panel_width, panel_height))
        pygame.draw.rect(self.screen, (80, 80, 100),
                         (panel_x, panel_y, panel_width, panel_height), 2)

        if not self.current_quest:
            return

        # Title
        title = self.font.render("Quest Info", True, (255, 255, 255))
        self.screen.blit(title, (panel_x + 10, panel_y + 10))

        y_offset = panel_y + 45

        # Quest details
        info_items = [
            ("ID", f"#{self.current_quest.quest_id}"),
            ("Type", self.current_quest.quest_type.value),
            ("Status", self.current_quest.status.value),
            ("Giver", self.current_quest.giver_npc or "None"),
            ("Turn In", self.current_quest.turn_in_npc or "None"),
            ("Progress", f"{self.current_quest.get_progress()*100:.0f}%"),
            ("Repeatable", "Yes" if self.current_quest.repeatable else "No"),
        ]

        for label, value in info_items:
            label_surf = self.small_font.render(
                f"{label}:", True, (200, 200, 200))
            self.screen.blit(label_surf, (panel_x + 20, y_offset))

            value_surf = self.small_font.render(
                value, True, (150, 150, 150))
            self.screen.blit(value_surf, (panel_x + 150, y_offset))

            y_offset += 25

        # Description
        y_offset += 10
        desc_label = self.small_font.render(
            "Description:", True, (200, 200, 200))
        self.screen.blit(desc_label, (panel_x + 20, y_offset))
        y_offset += 25

        # Word wrap description
        words = self.current_quest.description.split()
        line = ""
        for word in words:
            test_line = line + word + " "
            if len(test_line) > 40:
                desc_surf = self.small_font.render(
                    line, True, (150, 150, 150))
                self.screen.blit(desc_surf, (panel_x + 20, y_offset))
                y_offset += 20
                line = word + " "
            else:
                line = test_line

        if line:
            desc_surf = self.small_font.render(line, True, (150, 150, 150))
            self.screen.blit(desc_surf, (panel_x + 20, y_offset))
            y_offset += 20

        # Next quests
        if self.current_quest.next_quests:
            y_offset += 10
            next_label = self.small_font.render(
                "Unlocks Quests:", True, (200, 200, 200))
            self.screen.blit(next_label, (panel_x + 20, y_offset))
            y_offset += 25

            for next_id in self.current_quest.next_quests:
                next_text = self.small_font.render(
                    f"  • Quest #{next_id}", True, (150, 150, 150))
                self.screen.blit(next_text, (panel_x + 20, y_offset))
                y_offset += 20

    def _draw_toolbar(self):
        """Draw top toolbar"""
        toolbar_height = 40
        pygame.draw.rect(self.screen, (45, 45, 55),
                         (0, 0, self.width, toolbar_height))
        pygame.draw.rect(self.screen, (80, 80, 100),
                         (0, 0, self.width, toolbar_height), 2)

        # Title
        if self.current_quest:
            title = self.font.render(
                f"Quest: {self.current_quest.name}", True, (255, 255, 255))
            self.screen.blit(title, (10, 10))

        # Instructions
        help_text = "1-3:Tabs | ↑↓:Navigate | Ctrl+S:Save | Ctrl+O:Load | Esc:Exit"
        help_surf = self.small_font.render(help_text, True, (180, 180, 180))
        self.screen.blit(help_surf, (500, 12))


def main():
    """Run quest system editor"""
    editor = QuestSystemEditor()
    editor.run()


if __name__ == "__main__":
    main()
