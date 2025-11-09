#!/usr/bin/env python3
"""
AI Behavior Pattern Editor

Comprehensive AI behavior and pattern editing tool.
Features include:
- State machine based AI
- Decision tree logic
- Behavior patterns (patrol, aggro, flee, follow)
- Condition evaluation
- Action execution
- Visual state diagram
- Transition editing
- Pattern templates
- Testing and simulation
- Export to game format

AI Components:
- States: Idle, Patrol, Chase, Attack, Flee, Dead
- Transitions: Condition-based state changes
- Actions: Move, attack, use skill, wait
- Conditions: Distance, HP, flags, random
- Patterns: Reusable behavior templates

State Machine:
- Multiple states per AI
- Transition conditions
- Entry/exit actions
- Update actions per frame
- Priority-based evaluation
"""

from dataclasses import dataclass, field
from enum import Enum
from typing import Dict, List, Optional, Tuple, Any, Callable
import pygame
import json
import math
import random


class AIState(Enum):
    """AI state types"""
    IDLE = "idle"
    PATROL = "patrol"
    CHASE = "chase"
    ATTACK = "attack"
    FLEE = "flee"
    SEARCH = "search"
    GUARD = "guard"
    DEAD = "dead"
    CUSTOM = "custom"


class ConditionType(Enum):
    """Condition types for transitions"""
    DISTANCE_LESS = "distance_less"
    DISTANCE_GREATER = "distance_greater"
    HP_LESS = "hp_less"
    HP_GREATER = "hp_greater"
    FLAG_SET = "flag_set"
    FLAG_CLEAR = "flag_clear"
    RANDOM_CHANCE = "random_chance"
    TIMER_EXPIRED = "timer_expired"
    CAN_SEE_TARGET = "can_see_target"
    LOST_SIGHT = "lost_sight"
    TAKING_DAMAGE = "taking_damage"
    ALLY_NEARBY = "ally_nearby"
    ALWAYS = "always"


class ActionType(Enum):
    """Action types"""
    MOVE_TO_TARGET = "move_to_target"
    MOVE_AWAY = "move_away"
    MOVE_RANDOM = "move_random"
    MOVE_PATROL = "move_patrol"
    ATTACK_TARGET = "attack_target"
    USE_SKILL = "use_skill"
    PLAY_ANIMATION = "play_animation"
    PLAY_SOUND = "play_sound"
    SET_FLAG = "set_flag"
    WAIT = "wait"
    FACE_TARGET = "face_target"
    CALL_ALLIES = "call_allies"


@dataclass
class Condition:
    """Transition condition"""
    condition_type: ConditionType
    parameters: Dict[str, Any] = field(default_factory=dict)

    def evaluate(self, context: Dict[str, Any]) -> bool:
        """Evaluate condition with given context"""
        if self.condition_type == ConditionType.ALWAYS:
            return True

        elif self.condition_type == ConditionType.DISTANCE_LESS:
            distance = context.get("distance_to_target", float('inf'))
            threshold = self.parameters.get("distance", 100)
            return distance < threshold

        elif self.condition_type == ConditionType.DISTANCE_GREATER:
            distance = context.get("distance_to_target", 0)
            threshold = self.parameters.get("distance", 100)
            return distance > threshold

        elif self.condition_type == ConditionType.HP_LESS:
            hp_percent = context.get("hp_percent", 100)
            threshold = self.parameters.get("percent", 30)
            return hp_percent < threshold

        elif self.condition_type == ConditionType.HP_GREATER:
            hp_percent = context.get("hp_percent", 100)
            threshold = self.parameters.get("percent", 30)
            return hp_percent > threshold

        elif self.condition_type == ConditionType.FLAG_SET:
            flag_name = self.parameters.get("flag", "")
            flags = context.get("flags", set())
            return flag_name in flags

        elif self.condition_type == ConditionType.FLAG_CLEAR:
            flag_name = self.parameters.get("flag", "")
            flags = context.get("flags", set())
            return flag_name not in flags

        elif self.condition_type == ConditionType.RANDOM_CHANCE:
            chance = self.parameters.get("chance", 0.5)
            return random.random() < chance

        elif self.condition_type == ConditionType.TIMER_EXPIRED:
            timer = context.get("state_timer", 0)
            duration = self.parameters.get("duration", 60)
            return timer >= duration

        elif self.condition_type == ConditionType.CAN_SEE_TARGET:
            return context.get("can_see_target", False)

        elif self.condition_type == ConditionType.LOST_SIGHT:
            return not context.get("can_see_target", False)

        elif self.condition_type == ConditionType.TAKING_DAMAGE:
            return context.get("taking_damage", False)

        elif self.condition_type == ConditionType.ALLY_NEARBY:
            ally_count = context.get("nearby_allies", 0)
            min_allies = self.parameters.get("count", 1)
            return ally_count >= min_allies

        return False

    def to_dict(self) -> dict:
        """Convert to dictionary"""
        return {
            "condition_type": self.condition_type.value,
            "parameters": self.parameters,
        }

    @staticmethod
    def from_dict(data: dict) -> 'Condition':
        """Create from dictionary"""
        return Condition(
            condition_type=ConditionType(data["condition_type"]),
            parameters=data.get("parameters", {}),
        )


@dataclass
class Action:
    """AI action"""
    action_type: ActionType
    parameters: Dict[str, Any] = field(default_factory=dict)

    def execute(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """Execute action and return results"""
        result = {"success": True, "data": {}}

        if self.action_type == ActionType.MOVE_TO_TARGET:
            speed = self.parameters.get("speed", 2.0)
            result["data"]["movement"] = "toward_target"
            result["data"]["speed"] = speed

        elif self.action_type == ActionType.MOVE_AWAY:
            speed = self.parameters.get("speed", 3.0)
            result["data"]["movement"] = "away_from_target"
            result["data"]["speed"] = speed

        elif self.action_type == ActionType.MOVE_RANDOM:
            speed = self.parameters.get("speed", 1.0)
            result["data"]["movement"] = "random"
            result["data"]["speed"] = speed

        elif self.action_type == ActionType.MOVE_PATROL:
            speed = self.parameters.get("speed", 1.5)
            path = self.parameters.get("path", [])
            result["data"]["movement"] = "patrol"
            result["data"]["speed"] = speed
            result["data"]["path"] = path

        elif self.action_type == ActionType.ATTACK_TARGET:
            attack_type = self.parameters.get("attack_type", "basic")
            result["data"]["action"] = "attack"
            result["data"]["attack_type"] = attack_type

        elif self.action_type == ActionType.USE_SKILL:
            skill_id = self.parameters.get("skill_id", 0)
            result["data"]["action"] = "use_skill"
            result["data"]["skill_id"] = skill_id

        elif self.action_type == ActionType.PLAY_ANIMATION:
            anim_id = self.parameters.get("animation_id", 0)
            result["data"]["animation"] = anim_id

        elif self.action_type == ActionType.PLAY_SOUND:
            sound_id = self.parameters.get("sound_id", 0)
            result["data"]["sound"] = sound_id

        elif self.action_type == ActionType.SET_FLAG:
            flag_name = self.parameters.get("flag", "")
            value = self.parameters.get("value", True)
            result["data"]["set_flag"] = flag_name
            result["data"]["flag_value"] = value

        elif self.action_type == ActionType.WAIT:
            duration = self.parameters.get("duration", 30)
            result["data"]["wait"] = duration

        elif self.action_type == ActionType.FACE_TARGET:
            result["data"]["face_target"] = True

        elif self.action_type == ActionType.CALL_ALLIES:
            radius = self.parameters.get("radius", 200)
            result["data"]["call_allies"] = radius

        return result

    def to_dict(self) -> dict:
        """Convert to dictionary"""
        return {
            "action_type": self.action_type.value,
            "parameters": self.parameters,
        }

    @staticmethod
    def from_dict(data: dict) -> 'Action':
        """Create from dictionary"""
        return Action(
            action_type=ActionType(data["action_type"]),
            parameters=data.get("parameters", {}),
        )


@dataclass
class StateTransition:
    """Transition between states"""
    from_state: AIState
    to_state: AIState
    conditions: List[Condition] = field(default_factory=list)
    priority: int = 0
    require_all: bool = True  # AND vs OR for conditions

    def can_transition(self, context: Dict[str, Any]) -> bool:
        """Check if transition should occur"""
        if not self.conditions:
            return True

        if self.require_all:
            # AND - all conditions must be true
            return all(cond.evaluate(context) for cond in self.conditions)
        else:
            # OR - any condition can be true
            return any(cond.evaluate(context) for cond in self.conditions)

    def to_dict(self) -> dict:
        """Convert to dictionary"""
        return {
            "from_state": self.from_state.value,
            "to_state": self.to_state.value,
            "priority": self.priority,
            "require_all": self.require_all,
            "conditions": [c.to_dict() for c in self.conditions],
        }

    @staticmethod
    def from_dict(data: dict) -> 'StateTransition':
        """Create from dictionary"""
        return StateTransition(
            from_state=AIState(data["from_state"]),
            to_state=AIState(data["to_state"]),
            priority=data.get("priority", 0),
            require_all=data.get("require_all", True),
            conditions=[Condition.from_dict(c) for c in data.get("conditions", [])],
        )


@dataclass
class BehaviorState:
    """AI behavior state"""
    state_type: AIState
    entry_actions: List[Action] = field(default_factory=list)
    update_actions: List[Action] = field(default_factory=list)
    exit_actions: List[Action] = field(default_factory=list)

    def on_enter(self, context: Dict[str, Any]) -> List[Dict[str, Any]]:
        """Execute entry actions"""
        return [action.execute(context) for action in self.entry_actions]

    def on_update(self, context: Dict[str, Any]) -> List[Dict[str, Any]]:
        """Execute update actions"""
        return [action.execute(context) for action in self.update_actions]

    def on_exit(self, context: Dict[str, Any]) -> List[Dict[str, Any]]:
        """Execute exit actions"""
        return [action.execute(context) for action in self.exit_actions]

    def to_dict(self) -> dict:
        """Convert to dictionary"""
        return {
            "state_type": self.state_type.value,
            "entry_actions": [a.to_dict() for a in self.entry_actions],
            "update_actions": [a.to_dict() for a in self.update_actions],
            "exit_actions": [a.to_dict() for a in self.exit_actions],
        }

    @staticmethod
    def from_dict(data: dict) -> 'BehaviorState':
        """Create from dictionary"""
        return BehaviorState(
            state_type=AIState(data["state_type"]),
            entry_actions=[Action.from_dict(a) for a in data.get("entry_actions", [])],
            update_actions=[Action.from_dict(a) for a in data.get("update_actions", [])],
            exit_actions=[Action.from_dict(a) for a in data.get("exit_actions", [])],
        )


@dataclass
class BehaviorPattern:
    """Complete AI behavior pattern"""
    pattern_id: int
    name: str
    description: str = ""
    states: List[BehaviorState] = field(default_factory=list)
    transitions: List[StateTransition] = field(default_factory=list)
    initial_state: AIState = AIState.IDLE
    aggro_range: float = 150.0
    sight_range: float = 200.0

    def get_state(self, state_type: AIState) -> Optional[BehaviorState]:
        """Get state by type"""
        for state in self.states:
            if state.state_type == state_type:
                return state
        return None

    def get_valid_transitions(
        self,
        current_state: AIState,
        context: Dict[str, Any]
    ) -> List[StateTransition]:
        """Get valid transitions from current state"""
        valid = []
        for transition in self.transitions:
            if transition.from_state == current_state:
                if transition.can_transition(context):
                    valid.append(transition)

        # Sort by priority (higher first)
        valid.sort(key=lambda t: t.priority, reverse=True)
        return valid

    def to_dict(self) -> dict:
        """Convert to dictionary"""
        return {
            "pattern_id": self.pattern_id,
            "name": self.name,
            "description": self.description,
            "initial_state": self.initial_state.value,
            "aggro_range": self.aggro_range,
            "sight_range": self.sight_range,
            "states": [s.to_dict() for s in self.states],
            "transitions": [t.to_dict() for t in self.transitions],
        }

    @staticmethod
    def from_dict(data: dict) -> 'BehaviorPattern':
        """Create from dictionary"""
        return BehaviorPattern(
            pattern_id=data["pattern_id"],
            name=data["name"],
            description=data.get("description", ""),
            initial_state=AIState(data.get("initial_state", "idle")),
            aggro_range=data.get("aggro_range", 150.0),
            sight_range=data.get("sight_range", 200.0),
            states=[BehaviorState.from_dict(s) for s in data.get("states", [])],
            transitions=[StateTransition.from_dict(t) for t in data.get("transitions", [])],
        )


class PatternLibrary:
    """Library of behavior pattern templates"""

    @staticmethod
    def get_aggressive_pattern() -> BehaviorPattern:
        """Aggressive enemy pattern"""
        pattern = BehaviorPattern(
            pattern_id=1,
            name="Aggressive Enemy",
            description="Chases and attacks player on sight",
            initial_state=AIState.IDLE,
            aggro_range=150.0,
            sight_range=200.0,
        )

        # Idle state
        idle_state = BehaviorState(state_type=AIState.IDLE)
        idle_state.update_actions.append(Action(ActionType.WAIT, {"duration": 10}))
        pattern.states.append(idle_state)

        # Chase state
        chase_state = BehaviorState(state_type=AIState.CHASE)
        chase_state.entry_actions.append(Action(ActionType.PLAY_SOUND, {"sound_id": 1}))
        chase_state.update_actions.append(
            Action(ActionType.MOVE_TO_TARGET, {"speed": 2.5}))
        pattern.states.append(chase_state)

        # Attack state
        attack_state = BehaviorState(state_type=AIState.ATTACK)
        attack_state.update_actions.append(
            Action(ActionType.ATTACK_TARGET, {"attack_type": "melee"}))
        pattern.states.append(attack_state)

        # Transitions
        # Idle -> Chase when target in range
        pattern.transitions.append(StateTransition(
            from_state=AIState.IDLE,
            to_state=AIState.CHASE,
            priority=10,
            conditions=[
                Condition(ConditionType.DISTANCE_LESS, {"distance": 150}),
                Condition(ConditionType.CAN_SEE_TARGET, {}),
            ]
        ))

        # Chase -> Attack when close
        pattern.transitions.append(StateTransition(
            from_state=AIState.CHASE,
            to_state=AIState.ATTACK,
            priority=10,
            conditions=[
                Condition(ConditionType.DISTANCE_LESS, {"distance": 40}),
            ]
        ))

        # Attack -> Chase when too far
        pattern.transitions.append(StateTransition(
            from_state=AIState.ATTACK,
            to_state=AIState.CHASE,
            priority=10,
            conditions=[
                Condition(ConditionType.DISTANCE_GREATER, {"distance": 50}),
            ]
        ))

        # Chase -> Idle when lost sight
        pattern.transitions.append(StateTransition(
            from_state=AIState.CHASE,
            to_state=AIState.IDLE,
            priority=5,
            conditions=[
                Condition(ConditionType.LOST_SIGHT, {}),
            ]
        ))

        return pattern

    @staticmethod
    def get_cowardly_pattern() -> BehaviorPattern:
        """Cowardly enemy pattern"""
        pattern = BehaviorPattern(
            pattern_id=2,
            name="Cowardly Enemy",
            description="Flees when player gets close or HP is low",
            initial_state=AIState.IDLE,
            aggro_range=100.0,
            sight_range=150.0,
        )

        # States
        idle_state = BehaviorState(state_type=AIState.IDLE)
        idle_state.update_actions.append(
            Action(ActionType.MOVE_RANDOM, {"speed": 1.0}))
        pattern.states.append(idle_state)

        flee_state = BehaviorState(state_type=AIState.FLEE)
        flee_state.entry_actions.append(Action(ActionType.PLAY_SOUND, {"sound_id": 2}))
        flee_state.update_actions.append(
            Action(ActionType.MOVE_AWAY, {"speed": 3.0}))
        pattern.states.append(flee_state)

        # Transitions
        # Idle -> Flee when player close
        pattern.transitions.append(StateTransition(
            from_state=AIState.IDLE,
            to_state=AIState.FLEE,
            priority=10,
            conditions=[
                Condition(ConditionType.DISTANCE_LESS, {"distance": 100}),
            ]
        ))

        # Idle -> Flee when HP low
        pattern.transitions.append(StateTransition(
            from_state=AIState.IDLE,
            to_state=AIState.FLEE,
            priority=15,
            conditions=[
                Condition(ConditionType.HP_LESS, {"percent": 30}),
            ]
        ))

        # Flee -> Idle when safe
        pattern.transitions.append(StateTransition(
            from_state=AIState.FLEE,
            to_state=AIState.IDLE,
            priority=5,
            conditions=[
                Condition(ConditionType.DISTANCE_GREATER, {"distance": 200}),
            ]
        ))

        return pattern

    @staticmethod
    def get_patrol_pattern() -> BehaviorPattern:
        """Patrol guard pattern"""
        pattern = BehaviorPattern(
            pattern_id=3,
            name="Patrol Guard",
            description="Patrols set path, chases intruders",
            initial_state=AIState.PATROL,
            aggro_range=120.0,
            sight_range=180.0,
        )

        # States
        patrol_state = BehaviorState(state_type=AIState.PATROL)
        patrol_state.update_actions.append(Action(
            ActionType.MOVE_PATROL,
            {"speed": 1.5, "path": [(100, 100), (300, 100), (300, 300), (100, 300)]}
        ))
        pattern.states.append(patrol_state)

        chase_state = BehaviorState(state_type=AIState.CHASE)
        chase_state.update_actions.append(
            Action(ActionType.MOVE_TO_TARGET, {"speed": 2.0}))
        pattern.states.append(chase_state)

        attack_state = BehaviorState(state_type=AIState.ATTACK)
        attack_state.update_actions.append(
            Action(ActionType.ATTACK_TARGET, {"attack_type": "melee"}))
        pattern.states.append(attack_state)

        search_state = BehaviorState(state_type=AIState.SEARCH)
        search_state.update_actions.append(
            Action(ActionType.MOVE_RANDOM, {"speed": 1.0}))
        pattern.states.append(search_state)

        # Transitions
        # Patrol -> Chase
        pattern.transitions.append(StateTransition(
            from_state=AIState.PATROL,
            to_state=AIState.CHASE,
            priority=10,
            conditions=[
                Condition(ConditionType.DISTANCE_LESS, {"distance": 120}),
                Condition(ConditionType.CAN_SEE_TARGET, {}),
            ]
        ))

        # Chase -> Attack
        pattern.transitions.append(StateTransition(
            from_state=AIState.CHASE,
            to_state=AIState.ATTACK,
            priority=10,
            conditions=[
                Condition(ConditionType.DISTANCE_LESS, {"distance": 40}),
            ]
        ))

        # Attack -> Chase
        pattern.transitions.append(StateTransition(
            from_state=AIState.ATTACK,
            to_state=AIState.CHASE,
            priority=10,
            conditions=[
                Condition(ConditionType.DISTANCE_GREATER, {"distance": 50}),
            ]
        ))

        # Chase -> Search when lost sight
        pattern.transitions.append(StateTransition(
            from_state=AIState.CHASE,
            to_state=AIState.SEARCH,
            priority=5,
            conditions=[
                Condition(ConditionType.LOST_SIGHT, {}),
            ]
        ))

        # Search -> Patrol after timeout
        pattern.transitions.append(StateTransition(
            from_state=AIState.SEARCH,
            to_state=AIState.PATROL,
            priority=5,
            conditions=[
                Condition(ConditionType.TIMER_EXPIRED, {"duration": 180}),
            ]
        ))

        return pattern


class BehaviorDatabase:
    """Database of behavior patterns"""

    def __init__(self):
        self.patterns: Dict[int, BehaviorPattern] = {}
        self._init_sample_data()

    def _init_sample_data(self):
        """Initialize sample patterns"""
        self.patterns[1] = PatternLibrary.get_aggressive_pattern()
        self.patterns[2] = PatternLibrary.get_cowardly_pattern()
        self.patterns[3] = PatternLibrary.get_patrol_pattern()

    def add(self, pattern: BehaviorPattern):
        """Add pattern to database"""
        self.patterns[pattern.pattern_id] = pattern

    def get(self, pattern_id: int) -> Optional[BehaviorPattern]:
        """Get pattern by ID"""
        return self.patterns.get(pattern_id)

    def save_json(self, filename: str):
        """Save to JSON"""
        data = {
            "patterns": [p.to_dict() for p in self.patterns.values()]
        }

        with open(filename, 'w') as f:
            json.dump(data, f, indent=2)

    def load_json(self, filename: str):
        """Load from JSON"""
        with open(filename, 'r') as f:
            data = json.load(f)

        self.patterns = {}
        for pattern_data in data.get("patterns", []):
            pattern = BehaviorPattern.from_dict(pattern_data)
            self.patterns[pattern.pattern_id] = pattern


class BehaviorPatternEditor:
    """Main behavior pattern editor with UI"""

    def __init__(self, width: int = 1600, height: int = 900):
        self.width = width
        self.height = height
        self.running = True

        pygame.init()
        self.screen = pygame.display.set_mode((width, height))
        pygame.display.set_caption("AI Behavior Pattern Editor")
        self.clock = pygame.time.Clock()

        self.font = pygame.font.Font(None, 24)
        self.small_font = pygame.font.Font(None, 18)

        # Database
        self.database = BehaviorDatabase()
        self.current_pattern: Optional[BehaviorPattern] = None
        self.selected_pattern_id: Optional[int] = None
        self.selected_state: Optional[BehaviorState] = None
        self.selected_transition: Optional[StateTransition] = None

        # UI state
        self.pattern_scroll = 0
        self.state_positions: Dict[AIState, Tuple[int, int]] = {}

        # Select first pattern
        if self.database.patterns:
            first_id = min(self.database.patterns.keys())
            self.current_pattern = self.database.patterns[first_id]
            self.selected_pattern_id = first_id
            self._layout_state_diagram()

    def _layout_state_diagram(self):
        """Calculate positions for state diagram"""
        if not self.current_pattern:
            return

        # Simple circular layout
        center_x = 650
        center_y = 400
        radius = 200

        states = self.current_pattern.states
        if not states:
            return

        angle_step = 2 * math.pi / len(states)

        for i, state in enumerate(states):
            angle = i * angle_step - math.pi / 2
            x = center_x + int(radius * math.cos(angle))
            y = center_y + int(radius * math.sin(angle))
            self.state_positions[state.state_type] = (x, y)

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
                self.pattern_scroll = max(0, self.pattern_scroll - event.y * 30)

    def _handle_command_input(self, event):
        """Handle command input"""
        if event.key == pygame.K_ESCAPE:
            self.running = False

        # Save/Load
        elif event.key == pygame.K_s and pygame.key.get_mods() & pygame.KMOD_CTRL:
            self.database.save_json("ai_behaviors.json")
            print("Behaviors saved to ai_behaviors.json")

        elif event.key == pygame.K_o and pygame.key.get_mods() & pygame.KMOD_CTRL:
            try:
                self.database.load_json("ai_behaviors.json")
                print("Behaviors loaded from ai_behaviors.json")
            except FileNotFoundError:
                print("No ai_behaviors.json file found")

        # Navigation
        elif event.key == pygame.K_UP:
            pattern_ids = sorted(self.database.patterns.keys())
            if self.selected_pattern_id in pattern_ids:
                idx = pattern_ids.index(self.selected_pattern_id)
                if idx > 0:
                    self.selected_pattern_id = pattern_ids[idx - 1]
                    self.current_pattern = self.database.patterns[self.selected_pattern_id]
                    self._layout_state_diagram()

        elif event.key == pygame.K_DOWN:
            pattern_ids = sorted(self.database.patterns.keys())
            if self.selected_pattern_id in pattern_ids:
                idx = pattern_ids.index(self.selected_pattern_id)
                if idx < len(pattern_ids) - 1:
                    self.selected_pattern_id = pattern_ids[idx + 1]
                    self.current_pattern = self.database.patterns[self.selected_pattern_id]
                    self._layout_state_diagram()

    def _handle_mouse_click(self, pos: Tuple[int, int], button: int):
        """Handle mouse click"""
        x, y = pos

        # Check pattern list
        if x < 250 and button == 1:
            y_offset = 80 - self.pattern_scroll

            for pattern_id in sorted(self.database.patterns.keys()):
                if y_offset <= y < y_offset + 60:
                    self.current_pattern = self.database.patterns[pattern_id]
                    self.selected_pattern_id = pattern_id
                    self._layout_state_diagram()
                    break
                y_offset += 65

        # Check state nodes
        elif 250 < x < 1200 and button == 1:
            for state_type, (sx, sy) in self.state_positions.items():
                distance = math.sqrt((x - sx) ** 2 + (y - sy) ** 2)
                if distance < 50:
                    self.selected_state = self.current_pattern.get_state(state_type)
                    break

    def _render(self):
        """Render editor"""
        self.screen.fill((25, 25, 35))

        # Draw pattern list
        self._draw_pattern_list()

        # Draw state diagram
        self._draw_state_diagram()

        # Draw properties panel
        self._draw_properties_panel()

        # Draw toolbar
        self._draw_toolbar()

        pygame.display.flip()

    def _draw_pattern_list(self):
        """Draw pattern list panel"""
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
        title = self.font.render("Patterns", True, (255, 255, 255))
        self.screen.blit(title, (panel_x + 10, panel_y + 10))

        # Pattern list
        y_offset = panel_y + 50 - self.pattern_scroll

        for pattern_id in sorted(self.database.patterns.keys()):
            pattern = self.database.patterns[pattern_id]

            if y_offset + 60 < panel_y or y_offset > panel_y + panel_height:
                y_offset += 65
                continue

            # Background
            bg_color = (60, 60, 80) if pattern_id == self.selected_pattern_id else (
                45, 45, 55)
            pygame.draw.rect(self.screen, bg_color,
                             (panel_x + 5, y_offset, panel_width - 10, 60))
            pygame.draw.rect(self.screen, (100, 100, 120),
                             (panel_x + 5, y_offset, panel_width - 10, 60), 1)

            # Pattern ID
            id_text = self.small_font.render(
                f"#{pattern_id}", True, (180, 180, 180))
            self.screen.blit(id_text, (panel_x + 10, y_offset + 5))

            # Pattern name
            name_text = self.small_font.render(
                pattern.name, True, (200, 200, 255))
            self.screen.blit(name_text, (panel_x + 10, y_offset + 25))

            # States and transitions
            info = f"{len(pattern.states)} states | {len(pattern.transitions)} trans"
            info_text = self.small_font.render(info, True, (150, 150, 150))
            self.screen.blit(info_text, (panel_x + 10, y_offset + 45))

            y_offset += 65

    def _draw_state_diagram(self):
        """Draw state machine diagram"""
        diagram_x = 250
        diagram_y = 50
        diagram_width = 950
        diagram_height = self.height - 100

        # Background
        pygame.draw.rect(self.screen, (20, 20, 30),
                         (diagram_x, diagram_y, diagram_width, diagram_height))
        pygame.draw.rect(self.screen, (80, 80, 100),
                         (diagram_x, diagram_y, diagram_width, diagram_height), 2)

        if not self.current_pattern:
            return

        # Draw transitions first (so they appear behind states)
        for transition in self.current_pattern.transitions:
            from_pos = self.state_positions.get(transition.from_state)
            to_pos = self.state_positions.get(transition.to_state)

            if from_pos and to_pos:
                # Draw arrow
                color = (100, 150, 255)
                pygame.draw.line(self.screen, color, from_pos, to_pos, 2)

                # Draw arrowhead
                dx = to_pos[0] - from_pos[0]
                dy = to_pos[1] - from_pos[1]
                length = math.sqrt(dx * dx + dy * dy)
                if length > 0:
                    dx /= length
                    dy /= length

                    # Arrow point
                    arrow_x = to_pos[0] - dx * 50
                    arrow_y = to_pos[1] - dy * 50

                    # Arrow wings
                    wing_len = 15
                    wing1_x = arrow_x - dy * wing_len - dx * wing_len
                    wing1_y = arrow_y + dx * wing_len - dy * wing_len
                    wing2_x = arrow_x + dy * wing_len - dx * wing_len
                    wing2_y = arrow_y - dx * wing_len - dy * wing_len

                    pygame.draw.polygon(self.screen, color, [
                        (arrow_x, arrow_y),
                        (wing1_x, wing1_y),
                        (wing2_x, wing2_y),
                    ])

                # Draw condition count
                mid_x = (from_pos[0] + to_pos[0]) // 2
                mid_y = (from_pos[1] + to_pos[1]) // 2
                cond_count = len(transition.conditions)
                if cond_count > 0:
                    count_text = self.small_font.render(
                        f"{cond_count}", True, (200, 200, 255))
                    self.screen.blit(count_text, (mid_x - 5, mid_y - 10))

        # Draw states
        for state in self.current_pattern.states:
            pos = self.state_positions.get(state.state_type)
            if not pos:
                continue

            x, y = pos

            # State circle
            is_selected = state == self.selected_state
            is_initial = state.state_type == self.current_pattern.initial_state

            circle_color = (255, 200, 100) if is_initial else (100, 200, 255)
            if is_selected:
                circle_color = (255, 255, 100)

            pygame.draw.circle(self.screen, circle_color, (x, y), 50)
            pygame.draw.circle(self.screen, (255, 255, 255), (x, y), 50, 2)

            # State name
            name = state.state_type.value.upper()
            name_surf = self.small_font.render(name, True, (0, 0, 0))
            text_rect = name_surf.get_rect(center=(x, y - 5))
            self.screen.blit(name_surf, text_rect)

            # Action counts
            action_count = len(state.update_actions)
            count_surf = self.small_font.render(
                f"{action_count} actions", True, (0, 0, 0))
            count_rect = count_surf.get_rect(center=(x, y + 15))
            self.screen.blit(count_surf, count_rect)

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

        if not self.current_pattern:
            return

        # Title
        title = self.font.render("Properties", True, (255, 255, 255))
        self.screen.blit(title, (panel_x + 10, panel_y + 10))

        y_offset = panel_y + 45

        # Pattern info
        info_items = [
            ("Name", self.current_pattern.name),
            ("Initial State", self.current_pattern.initial_state.value),
            ("Aggro Range", f"{self.current_pattern.aggro_range:.0f}"),
            ("Sight Range", f"{self.current_pattern.sight_range:.0f}"),
            ("States", str(len(self.current_pattern.states))),
            ("Transitions", str(len(self.current_pattern.transitions))),
        ]

        for label, value in info_items:
            label_surf = self.small_font.render(
                f"{label}:", True, (200, 200, 200))
            self.screen.blit(label_surf, (panel_x + 20, y_offset))

            value_surf = self.small_font.render(
                value, True, (150, 150, 150))
            self.screen.blit(value_surf, (panel_x + 180, y_offset))

            y_offset += 25

        # Selected state details
        if self.selected_state:
            y_offset += 20
            state_title = self.font.render(
                f"State: {self.selected_state.state_type.value}", True, (200, 200, 255))
            self.screen.blit(state_title, (panel_x + 10, y_offset))
            y_offset += 35

            # Entry actions
            if self.selected_state.entry_actions:
                entry_label = self.small_font.render(
                    "Entry Actions:", True, (180, 180, 180))
                self.screen.blit(entry_label, (panel_x + 20, y_offset))
                y_offset += 22

                for action in self.selected_state.entry_actions:
                    action_text = self.small_font.render(
                        f"  • {action.action_type.value}", True, (150, 150, 150))
                    self.screen.blit(action_text, (panel_x + 20, y_offset))
                    y_offset += 18

            # Update actions
            if self.selected_state.update_actions:
                y_offset += 10
                update_label = self.small_font.render(
                    "Update Actions:", True, (180, 180, 180))
                self.screen.blit(update_label, (panel_x + 20, y_offset))
                y_offset += 22

                for action in self.selected_state.update_actions:
                    action_text = self.small_font.render(
                        f"  • {action.action_type.value}", True, (150, 150, 150))
                    self.screen.blit(action_text, (panel_x + 20, y_offset))
                    y_offset += 18

            # Exit actions
            if self.selected_state.exit_actions:
                y_offset += 10
                exit_label = self.small_font.render(
                    "Exit Actions:", True, (180, 180, 180))
                self.screen.blit(exit_label, (panel_x + 20, y_offset))
                y_offset += 22

                for action in self.selected_state.exit_actions:
                    action_text = self.small_font.render(
                        f"  • {action.action_type.value}", True, (150, 150, 150))
                    self.screen.blit(action_text, (panel_x + 20, y_offset))
                    y_offset += 18

    def _draw_toolbar(self):
        """Draw top toolbar"""
        toolbar_height = 40
        pygame.draw.rect(self.screen, (45, 45, 55),
                         (0, 0, self.width, toolbar_height))
        pygame.draw.rect(self.screen, (80, 80, 100),
                         (0, 0, self.width, toolbar_height), 2)

        # Title
        if self.current_pattern:
            title = self.font.render(
                f"Pattern: {self.current_pattern.name}", True, (255, 255, 255))
            self.screen.blit(title, (10, 10))

        # Instructions
        help_text = "↑↓:Navigate | Click:Select State | Ctrl+S:Save | Ctrl+O:Load | Esc:Exit"
        help_surf = self.small_font.render(help_text, True, (180, 180, 180))
        self.screen.blit(help_surf, (400, 12))


def main():
    """Run behavior pattern editor"""
    editor = BehaviorPatternEditor()
    editor.run()


if __name__ == "__main__":
    main()
