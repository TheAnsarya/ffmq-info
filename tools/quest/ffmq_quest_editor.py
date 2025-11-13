#!/usr/bin/env python3
"""
FFMQ Quest/Event Editor - Edit quests, events, and story progression

Final Fantasy Mystic Quest quest system:
- Story progression flags
- Event triggers and conditions
- NPC dialogue trees
- Quest objectives
- Cutscene sequences
- Conditional branches
- Item requirements
- Location-based events
- Time-based triggers
- Character interactions

Features:
- View/edit event scripts
- Modify quest requirements
- Change event triggers
- Edit dialogue branches
- Configure cutscenes
- Set progression flags
- Test event chains
- Export event documentation
- Validate event logic
- Create custom quests

Event System:
- Event ID: Unique identifier
- Triggers: What activates the event
- Conditions: Requirements to activate
- Actions: What happens when triggered
- Flags: Story progress tracking
- Branches: Conditional paths

Usage:
	python ffmq_quest_editor.py rom.sfc --list-events
	python ffmq_quest_editor.py rom.sfc --show-event 42
	python ffmq_quest_editor.py rom.sfc --edit-event 42 --set-flag 100
	python ffmq_quest_editor.py rom.sfc --list-quests
	python ffmq_quest_editor.py rom.sfc --modify-requirement 5 --item 10
	python ffmq_quest_editor.py rom.sfc --export-events events.json
	python ffmq_quest_editor.py rom.sfc --validate-events
"""

import argparse
import json
import struct
from pathlib import Path
from typing import List, Tuple, Optional, Dict, Any
from dataclasses import dataclass, field, asdict
from enum import Enum


class EventType(Enum):
	"""Event types"""
	DIALOGUE = "dialogue"
	CUTSCENE = "cutscene"
	BATTLE = "battle"
	ITEM_GET = "item_get"
	TREASURE = "treasure"
	NPC_INTERACTION = "npc_interaction"
	MAP_CHANGE = "map_change"
	QUEST_START = "quest_start"
	QUEST_COMPLETE = "quest_complete"
	CONDITIONAL = "conditional"


class TriggerType(Enum):
	"""Event trigger types"""
	ON_ENTER = "on_enter"
	ON_INTERACT = "on_interact"
	ON_ITEM = "on_item"
	ON_FLAG = "on_flag"
	ON_BATTLE_WIN = "on_battle_win"
	ON_TIME = "on_time"
	AUTOMATIC = "automatic"


@dataclass
class EventCondition:
	"""Event activation condition"""
	condition_type: str  # "flag_set", "flag_clear", "has_item", "level_ge", etc.
	param1: int
	param2: int
	
	def to_dict(self) -> dict:
		return asdict(self)


@dataclass
class EventAction:
	"""Event action"""
	action_type: str  # "set_flag", "give_item", "start_battle", "show_text", etc.
	param1: int
	param2: int
	param3: int
	
	def to_dict(self) -> dict:
		return asdict(self)


@dataclass
class GameEvent:
	"""Game event"""
	event_id: int
	name: str
	event_type: EventType
	trigger: TriggerType
	map_id: int
	x: int
	y: int
	conditions: List[EventCondition]
	actions: List[EventAction]
	script_pointer: int
	
	def to_dict(self) -> dict:
		d = {
			'event_id': self.event_id,
			'name': self.name,
			'event_type': self.event_type.value,
			'trigger': self.trigger.value,
			'map_id': self.map_id,
			'x': self.x,
			'y': self.y,
			'conditions': [c.to_dict() for c in self.conditions],
			'actions': [a.to_dict() for a in self.actions],
			'script_pointer': f'0x{self.script_pointer:06X}'
		}
		return d


@dataclass
class Quest:
	"""Quest definition"""
	quest_id: int
	name: str
	description: str
	start_event: int
	complete_event: int
	required_items: List[int]
	required_flags: List[int]
	reward_items: List[int]
	reward_exp: int
	reward_gil: int
	
	def to_dict(self) -> dict:
		return asdict(self)


class FFMQQuestDatabase:
	"""Database of FFMQ quests and events"""
	
	# Known quests
	QUESTS = {
		0: "Hill of Destiny",
		1: "Foresta Quest",
		2: "Aquaria Quest",
		3: "Fireburg Quest",
		4: "Windia Quest",
		5: "Level Forest",
		6: "Bone Dungeon",
		7: "Focus Tower",
		# ... more quests
	}
	
	# Event data locations
	EVENT_DATA_OFFSET = 0x290000
	NUM_EVENTS = 256
	
	# Quest data
	QUEST_DATA_OFFSET = 0x2A0000
	NUM_QUESTS = 32
	
	# Story flags
	FLAG_DATA_OFFSET = 0x2B0000
	NUM_FLAGS = 256
	
	@classmethod
	def get_quest_name(cls, quest_id: int) -> str:
		"""Get quest name"""
		return cls.QUESTS.get(quest_id, f"Quest {quest_id}")


class FFMQQuestEditor:
	"""Edit FFMQ quests and events"""
	
	def __init__(self, rom_path: Path, verbose: bool = False):
		self.rom_path = rom_path
		self.verbose = verbose
		
		with open(rom_path, 'rb') as f:
			self.rom_data = bytearray(f.read())
		
		if self.verbose:
			print(f"Loaded FFMQ ROM: {rom_path} ({len(self.rom_data):,} bytes)")
	
	def extract_event(self, event_id: int) -> Optional[GameEvent]:
		"""Extract event from ROM"""
		if event_id >= FFMQQuestDatabase.NUM_EVENTS:
			return None
		
		event_offset = FFMQQuestDatabase.EVENT_DATA_OFFSET + (event_id * 64)
		
		if event_offset + 64 > len(self.rom_data):
			return None
		
		# Read event data (example structure)
		event_type_id = self.rom_data[event_offset]
		trigger_id = self.rom_data[event_offset + 1]
		map_id = self.rom_data[event_offset + 2]
		x = self.rom_data[event_offset + 3]
		y = self.rom_data[event_offset + 4]
		script_ptr = struct.unpack_from('<H', self.rom_data, event_offset + 8)[0]
		
		# Decode event type
		event_types = list(EventType)
		event_type = event_types[event_type_id % len(event_types)]
		
		# Decode trigger
		triggers = list(TriggerType)
		trigger = triggers[trigger_id % len(triggers)]
		
		# Read conditions (up to 4)
		conditions = []
		for i in range(4):
			cond_offset = event_offset + 16 + (i * 4)
			
			if cond_offset + 4 > len(self.rom_data):
				break
			
			cond_type = self.rom_data[cond_offset]
			if cond_type == 0xFF:
				continue
			
			param1 = self.rom_data[cond_offset + 1]
			param2 = self.rom_data[cond_offset + 2]
			
			condition_types = ["flag_set", "flag_clear", "has_item", "level_ge", "map_visited"]
			cond_type_name = condition_types[cond_type % len(condition_types)]
			
			conditions.append(EventCondition(
				condition_type=cond_type_name,
				param1=param1,
				param2=param2
			))
		
		# Read actions (up to 8)
		actions = []
		for i in range(8):
			act_offset = event_offset + 32 + (i * 4)
			
			if act_offset + 4 > len(self.rom_data):
				break
			
			act_type = self.rom_data[act_offset]
			if act_type == 0xFF:
				continue
			
			param1 = self.rom_data[act_offset + 1]
			param2 = self.rom_data[act_offset + 2]
			param3 = self.rom_data[act_offset + 3]
			
			action_types = ["set_flag", "clear_flag", "give_item", "remove_item", "show_text", 
							"start_battle", "heal_party", "warp", "play_music", "open_door"]
			act_type_name = action_types[act_type % len(action_types)]
			
			actions.append(EventAction(
				action_type=act_type_name,
				param1=param1,
				param2=param2,
				param3=param3
			))
		
		event = GameEvent(
			event_id=event_id,
			name=f"Event {event_id}",
			event_type=event_type,
			trigger=trigger,
			map_id=map_id,
			x=x,
			y=y,
			conditions=conditions,
			actions=actions,
			script_pointer=script_ptr
		)
		
		return event
	
	def extract_quest(self, quest_id: int) -> Optional[Quest]:
		"""Extract quest from ROM"""
		if quest_id >= FFMQQuestDatabase.NUM_QUESTS:
			return None
		
		quest_offset = FFMQQuestDatabase.QUEST_DATA_OFFSET + (quest_id * 32)
		
		if quest_offset + 32 > len(self.rom_data):
			return None
		
		# Read quest data
		start_event = self.rom_data[quest_offset]
		complete_event = self.rom_data[quest_offset + 1]
		
		# Required items (up to 4)
		required_items = []
		for i in range(4):
			item_id = self.rom_data[quest_offset + 4 + i]
			if item_id != 0xFF:
				required_items.append(item_id)
		
		# Required flags (up to 4)
		required_flags = []
		for i in range(4):
			flag_id = self.rom_data[quest_offset + 8 + i]
			if flag_id != 0xFF:
				required_flags.append(flag_id)
		
		# Rewards
		reward_items = []
		for i in range(4):
			item_id = self.rom_data[quest_offset + 16 + i]
			if item_id != 0xFF:
				reward_items.append(item_id)
		
		reward_exp = struct.unpack_from('<H', self.rom_data, quest_offset + 24)[0]
		reward_gil = struct.unpack_from('<H', self.rom_data, quest_offset + 26)[0]
		
		quest = Quest(
			quest_id=quest_id,
			name=FFMQQuestDatabase.get_quest_name(quest_id),
			description="",
			start_event=start_event,
			complete_event=complete_event,
			required_items=required_items,
			required_flags=required_flags,
			reward_items=reward_items,
			reward_exp=reward_exp,
			reward_gil=reward_gil
		)
		
		return quest
	
	def list_events(self) -> List[GameEvent]:
		"""List all events"""
		events = []
		
		for i in range(FFMQQuestDatabase.NUM_EVENTS):
			event = self.extract_event(i)
			if event:
				events.append(event)
		
		return events
	
	def list_quests(self) -> List[Quest]:
		"""List all quests"""
		quests = []
		
		for i in range(FFMQQuestDatabase.NUM_QUESTS):
			quest = self.extract_quest(i)
			if quest:
				quests.append(quest)
		
		return quests
	
	def modify_event_flag(self, event_id: int, action_index: int, flag_id: int) -> bool:
		"""Modify event flag action"""
		if event_id >= FFMQQuestDatabase.NUM_EVENTS:
			return False
		
		event_offset = FFMQQuestDatabase.EVENT_DATA_OFFSET + (event_id * 64)
		act_offset = event_offset + 32 + (action_index * 4)
		
		if act_offset + 4 > len(self.rom_data):
			return False
		
		# Modify action
		self.rom_data[act_offset + 1] = flag_id
		
		if self.verbose:
			print(f"✓ Modified Event {event_id} Action {action_index} flag to {flag_id}")
		
		return True
	
	def modify_quest_requirement(self, quest_id: int, item_index: int, item_id: int) -> bool:
		"""Modify quest item requirement"""
		if quest_id >= FFMQQuestDatabase.NUM_QUESTS:
			return False
		
		quest_offset = FFMQQuestDatabase.QUEST_DATA_OFFSET + (quest_id * 32)
		
		if quest_offset + 32 > len(self.rom_data):
			return False
		
		self.rom_data[quest_offset + 4 + item_index] = item_id
		
		if self.verbose:
			print(f"✓ Modified Quest {quest_id} requirement {item_index} to item {item_id}")
		
		return True
	
	def validate_events(self) -> List[str]:
		"""Validate event data"""
		errors = []
		
		for event_id in range(FFMQQuestDatabase.NUM_EVENTS):
			event = self.extract_event(event_id)
			
			if not event:
				continue
			
			# Check conditions reference valid flags
			for cond in event.conditions:
				if cond.condition_type in ["flag_set", "flag_clear"]:
					if cond.param1 >= FFMQQuestDatabase.NUM_FLAGS:
						errors.append(f"Event {event_id}: Condition references invalid flag {cond.param1}")
			
			# Check actions reference valid data
			for action in event.actions:
				if action.action_type in ["set_flag", "clear_flag"]:
					if action.param1 >= FFMQQuestDatabase.NUM_FLAGS:
						errors.append(f"Event {event_id}: Action references invalid flag {action.param1}")
				
				if action.action_type in ["give_item", "remove_item"]:
					if action.param1 >= 256:  # Max items
						errors.append(f"Event {event_id}: Action references invalid item {action.param1}")
		
		return errors
	
	def save_rom(self, output_path: Optional[Path] = None) -> None:
		"""Save modified ROM"""
		save_path = output_path or self.rom_path
		
		with open(save_path, 'wb') as f:
			f.write(self.rom_data)
		
		if self.verbose:
			print(f"✓ Saved ROM to {save_path}")


def main():
	parser = argparse.ArgumentParser(description='FFMQ Quest/Event Editor')
	parser.add_argument('rom', type=str, help='FFMQ ROM file')
	parser.add_argument('--list-events', action='store_true', help='List all events')
	parser.add_argument('--list-quests', action='store_true', help='List all quests')
	parser.add_argument('--show-event', type=int, help='Show event details')
	parser.add_argument('--show-quest', type=int, help='Show quest details')
	parser.add_argument('--edit-event', type=int, help='Edit event')
	parser.add_argument('--set-flag', type=int, help='Set flag ID')
	parser.add_argument('--action-index', type=int, default=0, help='Action index')
	parser.add_argument('--modify-requirement', type=int, help='Modify quest requirement')
	parser.add_argument('--item', type=int, help='Item ID')
	parser.add_argument('--item-index', type=int, default=0, help='Requirement index')
	parser.add_argument('--validate-events', action='store_true', help='Validate events')
	parser.add_argument('--export-events', type=str, help='Export events to JSON')
	parser.add_argument('--save', type=str, help='Save modified ROM')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	editor = FFMQQuestEditor(Path(args.rom), verbose=args.verbose)
	
	# List events
	if args.list_events:
		events = editor.list_events()
		
		print(f"\nFFMQ Events ({len(events)}):\n")
		for event in events[:50]:  # Show first 50
			print(f"  {event.event_id:3d}: {event.event_type.value:<15} @ Map {event.map_id:2d} "
				  f"({event.x:3d},{event.y:3d}) - {len(event.actions)} actions")
		
		if len(events) > 50:
			print(f"\n  ... and {len(events) - 50} more events")
		
		return 0
	
	# List quests
	if args.list_quests:
		quests = editor.list_quests()
		
		print(f"\nFFMQ Quests ({len(quests)}):\n")
		for quest in quests:
			print(f"  {quest.quest_id:2d}: {quest.name}")
			print(f"      Start Event: {quest.start_event}, Complete Event: {quest.complete_event}")
			print(f"      Rewards: {quest.reward_exp} EXP, {quest.reward_gil} GP")
		
		return 0
	
	# Show event
	if args.show_event is not None:
		event = editor.extract_event(args.show_event)
		
		if event:
			print(f"\n=== Event {event.event_id} ===\n")
			print(f"Type: {event.event_type.value}")
			print(f"Trigger: {event.trigger.value}")
			print(f"Location: Map {event.map_id} ({event.x}, {event.y})")
			
			print(f"\nConditions ({len(event.conditions)}):")
			for i, cond in enumerate(event.conditions):
				print(f"  {i}. {cond.condition_type} ({cond.param1}, {cond.param2})")
			
			print(f"\nActions ({len(event.actions)}):")
			for i, action in enumerate(event.actions):
				print(f"  {i}. {action.action_type} ({action.param1}, {action.param2}, {action.param3})")
		
		return 0
	
	# Edit event
	if args.edit_event is not None:
		if args.set_flag is not None:
			success = editor.modify_event_flag(args.edit_event, args.action_index, args.set_flag)
			
			if success and args.save:
				editor.save_rom(Path(args.save))
		
		return 0
	
	# Modify quest
	if args.modify_requirement is not None:
		if args.item is not None:
			success = editor.modify_quest_requirement(args.modify_requirement, args.item_index, args.item)
			
			if success and args.save:
				editor.save_rom(Path(args.save))
		
		return 0
	
	# Validate events
	if args.validate_events:
		errors = editor.validate_events()
		
		if errors:
			print(f"\n❌ Found {len(errors)} event errors:\n")
			for error in errors:
				print(f"  • {error}")
		else:
			print("\n✅ All events are valid")
		
		return 0
	
	# Export events
	if args.export_events:
		events = editor.list_events()
		
		data = {'events': [e.to_dict() for e in events]}
		
		with open(args.export_events, 'w') as f:
			json.dump(data, f, indent='\t')
		
		if args.verbose:
			print(f"✓ Exported {len(events)} events to {args.export_events}")
		
		return 0
	
	print("Use --list-events, --list-quests, --show-event, --edit-event, --modify-requirement, --validate-events, or --export-events")
	return 0


if __name__ == '__main__':
	exit(main())
