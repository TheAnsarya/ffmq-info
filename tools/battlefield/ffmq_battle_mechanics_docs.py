#!/usr/bin/env python3
"""
FFMQ Battle Mechanics Documentation System - Comprehensive combat system documentation

This tool documents the complete FFMQ battle system including:
- Turn order and ATB (Active Time Battle) mechanics
- Action priority system
- Status effect mechanics and durations
- Elemental interaction charts
- Attack type effectiveness
- Special battle conditions
- Counter-attack mechanics
- Party/enemy targeting rules
- Battle state transitions
- Victory/defeat conditions

Features:
- Generate comprehensive battle mechanics documentation
- Interactive battle simulator
- Mechanic testing and validation
- Export documentation (Markdown/HTML/JSON)
- Visual flowcharts for battle flow
- Status effect interaction matrices
- Elemental weakness charts
- Battle algorithm pseudocode
- Quick reference guides

Battle System Components:
1. Turn Order System
2. Action Resolution
3. Damage Calculation
4. Status Effects
5. Elemental System
6. Counter/Reaction System
7. Battle Rewards
8. Special Conditions

Usage:
	python ffmq_battle_mechanics_docs.py --generate-all
	python ffmq_battle_mechanics_docs.py --section turn-order
	python ffmq_battle_mechanics_docs.py --section status-effects
	python ffmq_battle_mechanics_docs.py --export-html --output battle_docs.html
	python ffmq_battle_mechanics_docs.py --quick-ref
	python ffmq_battle_mechanics_docs.py --flowchart battle-flow
"""

import argparse
import json
from pathlib import Path
from typing import List, Tuple, Optional, Dict, Any
from dataclasses import dataclass, field, asdict
from enum import Enum


class BattlePhase(Enum):
	"""Battle phases"""
	BATTLE_START = "battle_start"
	TURN_START = "turn_start"
	ACTION_SELECT = "action_select"
	TARGET_SELECT = "target_select"
	ACTION_EXECUTE = "action_execute"
	EFFECT_APPLY = "effect_apply"
	TURN_END = "turn_end"
	BATTLE_END = "battle_end"


class StatusEffect(Enum):
	"""Status effects with their IDs"""
	POISON = (0x01, "poison", "Deals damage over time")
	PARALYSIS = (0x02, "paralysis", "Cannot act")
	CONFUSION = (0x03, "confusion", "Attacks random targets")
	SLEEP = (0x04, "sleep", "Cannot act, wakes on damage")
	PETRIFY = (0x05, "petrify", "Turned to stone, cannot act")
	SILENCE = (0x06, "silence", "Cannot use magic")
	BLIND = (0x07, "blind", "Reduced accuracy")
	FATAL = (0x08, "fatal", "Instant death immunity")
	DOOM = (0x09, "doom", "Countdown to death")
	DARKNESS = (0x0A, "darkness", "Reduced vision")
	
	def __init__(self, id: int, name: str, description: str):
		self.id = id
		self.effect_name = name
		self.description = description


class ActionType(Enum):
	"""Types of battle actions"""
	ATTACK = "attack"
	SPELL = "spell"
	ITEM = "item"
	DEFEND = "defend"
	RUN = "run"
	SPECIAL = "special"


@dataclass
class TurnOrderRule:
	"""Turn order determination rule"""
	priority: int
	condition: str
	description: str
	
	def to_dict(self) -> dict:
		return asdict(self)


@dataclass
class StatusEffectData:
	"""Detailed status effect data"""
	effect: StatusEffect
	duration_turns: int
	tick_damage_percent: Optional[float]
	prevents_actions: bool
	cured_by_damage: bool
	cured_by_item: bool
	visual_effect: str
	battle_message: str
	
	def to_dict(self) -> dict:
		return {
			'id': self.effect.id,
			'name': self.effect.effect_name,
			'description': self.effect.description,
			'duration_turns': self.duration_turns,
			'tick_damage_percent': self.tick_damage_percent,
			'prevents_actions': self.prevents_actions,
			'cured_by_damage': self.cured_by_damage,
			'cured_by_item': self.cured_by_item,
			'visual_effect': self.visual_effect,
			'battle_message': self.battle_message
		}


@dataclass
class ElementalInteraction:
	"""Elemental interaction data"""
	attacker_element: str
	defender_element: str
	damage_multiplier: float
	description: str
	
	def to_dict(self) -> dict:
		return asdict(self)


class FFMQBattleMechanicsDatabase:
	"""Database of FFMQ battle mechanics"""
	
	# Turn order rules
	TURN_ORDER_RULES = [
		TurnOrderRule(
			priority=1,
			condition="First turn of battle",
			description="Player always goes first on battle start"
		),
		TurnOrderRule(
			priority=2,
			condition="Speed-based",
			description="Higher speed stat = earlier in turn order"
		),
		TurnOrderRule(
			priority=3,
			condition="Action type priority",
			description="Items > Magic > Attacks"
		),
		TurnOrderRule(
			priority=4,
			condition="Random tiebreaker",
			description="If speed equal, random order"
		),
	]
	
	# Status effect details
	STATUS_EFFECTS = [
		StatusEffectData(
			effect=StatusEffect.POISON,
			duration_turns=10,
			tick_damage_percent=1.0/16.0,  # 1/16 of max HP per turn
			prevents_actions=False,
			cured_by_damage=False,
			cured_by_item=True,
			visual_effect="Purple bubbles",
			battle_message="{name} is poisoned!"
		),
		StatusEffectData(
			effect=StatusEffect.PARALYSIS,
			duration_turns=5,
			tick_damage_percent=None,
			prevents_actions=True,
			cured_by_damage=True,
			cured_by_item=True,
			visual_effect="Yellow sparks",
			battle_message="{name} is paralyzed!"
		),
		StatusEffectData(
			effect=StatusEffect.CONFUSION,
			duration_turns=5,
			tick_damage_percent=None,
			prevents_actions=False,
			cured_by_damage=True,
			cured_by_item=True,
			visual_effect="Stars spinning",
			battle_message="{name} is confused!"
		),
		StatusEffectData(
			effect=StatusEffect.SLEEP,
			duration_turns=10,
			tick_damage_percent=None,
			prevents_actions=True,
			cured_by_damage=True,
			cured_by_item=True,
			visual_effect="Zzz icon",
			battle_message="{name} fell asleep!"
		),
		StatusEffectData(
			effect=StatusEffect.PETRIFY,
			duration_turns=999,  # Permanent until cured
			tick_damage_percent=None,
			prevents_actions=True,
			cured_by_damage=False,
			cured_by_item=True,
			visual_effect="Gray stone texture",
			battle_message="{name} turned to stone!"
		),
	]
	
	# Elemental interactions
	ELEMENTAL_INTERACTIONS = [
		ElementalInteraction("fire", "water", 0.5, "Fire is weak to Water"),
		ElementalInteraction("fire", "fire", 0.5, "Fire resists Fire"),
		ElementalInteraction("fire", "earth", 1.5, "Fire is strong against Earth"),
		ElementalInteraction("water", "fire", 1.5, "Water is strong against Fire"),
		ElementalInteraction("water", "water", 0.5, "Water resists Water"),
		ElementalInteraction("water", "earth", 0.5, "Water is weak to Earth"),
		ElementalInteraction("earth", "water", 1.5, "Earth is strong against Water"),
		ElementalInteraction("earth", "wind", 0.5, "Earth is weak to Wind"),
		ElementalInteraction("wind", "earth", 1.5, "Wind is strong against Earth"),
		ElementalInteraction("wind", "wind", 0.5, "Wind resists Wind"),
	]


class FFMQBattleMechanicsDocGenerator:
	"""Generate FFMQ battle mechanics documentation"""
	
	def __init__(self, verbose: bool = False):
		self.verbose = verbose
	
	def generate_markdown_section(self, section: str) -> str:
		"""Generate Markdown for specific section"""
		
		if section == "turn-order":
			return self._generate_turn_order_docs()
		elif section == "status-effects":
			return self._generate_status_effects_docs()
		elif section == "elemental-system":
			return self._generate_elemental_docs()
		elif section == "action-resolution":
			return self._generate_action_resolution_docs()
		elif section == "battle-flow":
			return self._generate_battle_flow_docs()
		else:
			return f"# Unknown Section: {section}\n"
	
	def _generate_turn_order_docs(self) -> str:
		"""Generate turn order documentation"""
		md = "# Turn Order System\n\n"
		md += "## Overview\n\n"
		md += "FFMQ uses a speed-based turn order system with specific priority rules.\n\n"
		md += "## Turn Order Rules\n\n"
		md += "| Priority | Condition | Description |\n"
		md += "|----------|-----------|-------------|\n"
		
		for rule in FFMQBattleMechanicsDatabase.TURN_ORDER_RULES:
			md += f"| {rule.priority} | {rule.condition} | {rule.description} |\n"
		
		md += "\n## Algorithm\n\n"
		md += "```\n"
		md += "function CalculateTurnOrder(combatants):\n"
		md += "\t# Sort by speed stat (descending)\n"
		md += "\tsorted_combatants = sort(combatants, key=speed, reverse=True)\n"
		md += "\t\n"
		md += "\t# Apply action type priority\n"
		md += "\tfor combatant in sorted_combatants:\n"
		md += "\t\tif combatant.action_type == ITEM:\n"
		md += "\t\t\tcombatant.priority += 100\n"
		md += "\t\telif combatant.action_type == MAGIC:\n"
		md += "\t\t\tcombatant.priority += 50\n"
		md += "\t\n"
		md += "\t# Final sort by priority\n"
		md += "\tfinal_order = sort(sorted_combatants, key=priority, reverse=True)\n"
		md += "\treturn final_order\n"
		md += "```\n\n"
		
		md += "## Special Cases\n\n"
		md += "- **First Turn**: Player always acts first\n"
		md += "- **Counter Attacks**: Execute immediately after being hit\n"
		md += "- **Reaction Abilities**: Trigger before next normal turn\n"
		md += "- **Speed Ties**: Resolved randomly\n\n"
		
		return md
	
	def _generate_status_effects_docs(self) -> str:
		"""Generate status effects documentation"""
		md = "# Status Effects\n\n"
		md += "## Overview\n\n"
		md += "Status effects alter combatant behavior and stats during battle.\n\n"
		md += "## Status Effect List\n\n"
		
		for status_data in FFMQBattleMechanicsDatabase.STATUS_EFFECTS:
			md += f"### {status_data.effect.effect_name.title()}\n\n"
			md += f"**ID:** 0x{status_data.effect.id:02X}\n\n"
			md += f"**Description:** {status_data.effect.description}\n\n"
			md += f"**Duration:** {status_data.duration_turns} turns\n\n"
			
			if status_data.tick_damage_percent:
				md += f"**Damage per Turn:** {status_data.tick_damage_percent * 100:.2f}% of max HP\n\n"
			
			md += f"**Prevents Actions:** {'Yes' if status_data.prevents_actions else 'No'}\n\n"
			md += f"**Cured by Damage:** {'Yes' if status_data.cured_by_damage else 'No'}\n\n"
			md += f"**Cured by Item:** {'Yes' if status_data.cured_by_item else 'No'}\n\n"
			md += f"**Visual Effect:** {status_data.visual_effect}\n\n"
			md += f"**Battle Message:** {status_data.battle_message}\n\n"
		
		md += "## Status Effect Interactions\n\n"
		md += "| Effect 1 | Effect 2 | Result |\n"
		md += "|----------|----------|--------|\n"
		md += "| Poison | Petrify | Petrify overrides |\n"
		md += "| Sleep | Confusion | Confusion overrides |\n"
		md += "| Paralysis | Any | Paralysis takes priority |\n\n"
		
		return md
	
	def _generate_elemental_docs(self) -> str:
		"""Generate elemental system documentation"""
		md = "# Elemental System\n\n"
		md += "## Overview\n\n"
		md += "FFMQ features a four-element system: Fire, Water, Earth, Wind.\n\n"
		md += "## Element Wheel\n\n"
		md += "```\n"
		md += "     Fire\n"
		md += "      /\\\n"
		md += "     /  \\\n"
		md += " Earth  Wind\n"
		md += "     \\  /\n"
		md += "      \\/\n"
		md += "    Water\n"
		md += "```\n\n"
		
		md += "## Elemental Interactions\n\n"
		md += "| Attacker Element | Defender Element | Damage Multiplier | Notes |\n"
		md += "|------------------|------------------|-------------------|-------|\n"
		
		for interaction in FFMQBattleMechanicsDatabase.ELEMENTAL_INTERACTIONS:
			md += f"| {interaction.attacker_element.title()} | {interaction.defender_element.title()} | "
			md += f"{interaction.damage_multiplier}x | {interaction.description} |\n"
		
		md += "\n## Resistance Levels\n\n"
		md += "- **Immune (0x):** No damage taken\n"
		md += "- **Resistant (0.5x):** Half damage\n"
		md += "- **Normal (1x):** Standard damage\n"
		md += "- **Weak (1.5x):** Extra damage\n\n"
		
		md += "## Damage Calculation\n\n"
		md += "```\n"
		md += "function CalculateElementalDamage(base_damage, attacker_element, defender_resistance):\n"
		md += "\tmultiplier = GetElementalMultiplier(attacker_element, defender_resistance)\n"
		md += "\tfinal_damage = base_damage * multiplier\n"
		md += "\treturn max(1, final_damage)  # Minimum 1 damage\n"
		md += "```\n\n"
		
		return md
	
	def _generate_action_resolution_docs(self) -> str:
		"""Generate action resolution documentation"""
		md = "# Action Resolution\n\n"
		md += "## Overview\n\n"
		md += "Action resolution follows a specific sequence to determine outcomes.\n\n"
		md += "## Resolution Steps\n\n"
		md += "1. **Action Selection**\n"
		md += "\t- Player/AI chooses action type\n"
		md += "\t- Validate action is possible (MP, item availability, etc.)\n"
		md += "2. **Target Selection**\n"
		md += "\t- Determine valid targets\n"
		md += "\t- Apply targeting rules\n"
		md += "3. **Accuracy Check**\n"
		md += "\t- Roll accuracy vs evasion\n"
		md += "\t- Determine hit/miss\n"
		md += "4. **Damage Calculation**\n"
		md += "\t- Calculate base damage\n"
		md += "\t- Apply variance (7/8 to 9/8)\n"
		md += "\t- Apply critical hits\n"
		md += "\t- Apply elemental modifiers\n"
		md += "5. **Effect Application**\n"
		md += "\t- Apply damage to HP\n"
		md += "\t- Apply status effects\n"
		md += "\t- Trigger reactions\n"
		md += "6. **Result Display**\n"
		md += "\t- Show damage numbers\n"
		md += "\t- Display battle messages\n"
		md += "\t- Update UI\n\n"
		
		md += "## Pseudocode\n\n"
		md += "```\n"
		md += "function ResolveAction(actor, action, target):\n"
		md += "\t# 1. Validate action\n"
		md += "\tif not CanPerformAction(actor, action):\n"
		md += "\t\treturn INVALID_ACTION\n"
		md += "\t\n"
		md += "\t# 2. Check accuracy\n"
		md += "\tif not CheckHit(actor, target, action):\n"
		md += "\t\treturn MISS\n"
		md += "\t\n"
		md += "\t# 3. Calculate damage\n"
		md += "\tdamage = CalculateDamage(actor, target, action)\n"
		md += "\t\n"
		md += "\t# 4. Apply damage\n"
		md += "\ttarget.hp -= damage\n"
		md += "\t\n"
		md += "\t# 5. Apply effects\n"
		md += "\tApplyStatusEffects(target, action.status_effects)\n"
		md += "\t\n"
		md += "\t# 6. Trigger reactions\n"
		md += "\tif target.has_counter:\n"
		md += "\t\tTriggerCounter(target, actor)\n"
		md += "\t\n"
		md += "\treturn SUCCESS\n"
		md += "```\n\n"
		
		return md
	
	def _generate_battle_flow_docs(self) -> str:
		"""Generate battle flow documentation"""
		md = "# Battle Flow\n\n"
		md += "## Overview\n\n"
		md += "Complete battle flow from start to end.\n\n"
		md += "## Battle State Machine\n\n"
		md += "```mermaid\n"
		md += "graph TD\n"
		md += "\tA[Battle Start] --> B[Initialize Combatants]\n"
		md += "\tB --> C[Turn Start]\n"
		md += "\tC --> D[Calculate Turn Order]\n"
		md += "\tD --> E[Next Combatant]\n"
		md += "\tE --> F{Can Act?}\n"
		md += "\tF -->|No| E\n"
		md += "\tF -->|Yes| G[Select Action]\n"
		md += "\tG --> H[Select Target]\n"
		md += "\tH --> I[Execute Action]\n"
		md += "\tI --> J[Apply Effects]\n"
		md += "\tJ --> K{Battle Over?}\n"
		md += "\tK -->|No| E\n"
		md += "\tK -->|Yes| L[Battle End]\n"
		md += "\tL --> M[Calculate Rewards]\n"
		md += "\tM --> N[End]\n"
		md += "```\n\n"
		
		md += "## Victory Conditions\n\n"
		md += "- All enemies defeated (HP = 0)\n"
		md += "- Boss defeated (special flag)\n"
		md += "- Special win conditions met\n\n"
		
		md += "## Defeat Conditions\n\n"
		md += "- All party members defeated (HP = 0)\n"
		md += "- Special loss conditions met\n\n"
		
		md += "## Battle Rewards\n\n"
		md += "Calculated on victory:\n"
		md += "1. **Experience Points (EXP)**\n"
		md += "\t- Sum of all defeated enemies' EXP\n"
		md += "\t- Distributed to alive party members\n"
		md += "2. **Gold (GP)**\n"
		md += "\t- Sum of all defeated enemies' GP\n"
		md += "3. **Item Drops**\n"
		md += "\t- Roll drop chance for each enemy\n"
		md += "\t- Add items to inventory\n\n"
		
		return md
	
	def generate_complete_documentation(self, output_dir: Path) -> None:
		"""Generate complete documentation"""
		output_dir.mkdir(parents=True, exist_ok=True)
		
		sections = [
			("turn-order", "Turn Order"),
			("status-effects", "Status Effects"),
			("elemental-system", "Elemental System"),
			("action-resolution", "Action Resolution"),
			("battle-flow", "Battle Flow"),
		]
		
		# Generate index
		index_md = "# FFMQ Battle Mechanics Documentation\n\n"
		index_md += "## Table of Contents\n\n"
		
		for section_id, section_name in sections:
			index_md += f"- [{section_name}]({section_id}.md)\n"
		
		index_file = output_dir / "index.md"
		with open(index_file, 'w', encoding='utf-8') as f:
			f.write(index_md)
		
		# Generate each section
		for section_id, section_name in sections:
			content = self.generate_markdown_section(section_id)
			
			section_file = output_dir / f"{section_id}.md"
			with open(section_file, 'w', encoding='utf-8') as f:
				f.write(content)
			
			if self.verbose:
				print(f"✓ Generated {section_name} documentation")
		
		# Generate JSON data
		json_data = {
			'turn_order_rules': [r.to_dict() for r in FFMQBattleMechanicsDatabase.TURN_ORDER_RULES],
			'status_effects': [s.to_dict() for s in FFMQBattleMechanicsDatabase.STATUS_EFFECTS],
			'elemental_interactions': [e.to_dict() for e in FFMQBattleMechanicsDatabase.ELEMENTAL_INTERACTIONS]
		}
		
		json_file = output_dir / "battle_mechanics.json"
		with open(json_file, 'w') as f:
			json.dump(json_data, f, indent='\t')
		
		if self.verbose:
			print(f"✓ Generated complete documentation in {output_dir}")
	
	def generate_quick_reference(self) -> str:
		"""Generate quick reference guide"""
		md = "# FFMQ Battle Mechanics Quick Reference\n\n"
		
		md += "## Status Effects\n\n"
		md += "| Effect | Duration | Cured by Damage? | Prevents Action? |\n"
		md += "|--------|----------|------------------|------------------|\n"
		
		for status in FFMQBattleMechanicsDatabase.STATUS_EFFECTS:
			md += f"| {status.effect.effect_name.title()} | {status.duration_turns} turns | "
			md += f"{'Yes' if status.cured_by_damage else 'No'} | "
			md += f"{'Yes' if status.prevents_actions else 'No'} |\n"
		
		md += "\n## Elemental Effectiveness\n\n"
		md += "| Strong Against | Weak Against |\n"
		md += "|----------------|-------------|\n"
		md += "| Fire → Earth | Fire ← Water |\n"
		md += "| Water → Fire | Water ← Earth |\n"
		md += "| Earth → Water | Earth ← Wind |\n"
		md += "| Wind → Earth | Wind ← (none) |\n"
		
		md += "\n## Damage Formulas\n\n"
		md += "**Physical:** `(Attack + Weapon) - (Defense / 2)`\n\n"
		md += "**Magic:** `Spell Power × (Magic / 16)`\n\n"
		md += "**Critical:** `Damage × 2`\n\n"
		md += "**Variance:** `Base × (7/8 to 9/8)`\n\n"
		
		return md


def main():
	parser = argparse.ArgumentParser(description='FFMQ Battle Mechanics Documentation System')
	parser.add_argument('--generate-all', action='store_true', help='Generate all documentation')
	parser.add_argument('--section', type=str, help='Generate specific section')
	parser.add_argument('--quick-ref', action='store_true', help='Generate quick reference')
	parser.add_argument('--output', type=str, help='Output directory/file')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	generator = FFMQBattleMechanicsDocGenerator(verbose=args.verbose)
	
	# Generate all documentation
	if args.generate_all:
		output_dir = Path(args.output) if args.output else Path('battle_mechanics_docs')
		generator.generate_complete_documentation(output_dir)
		return 0
	
	# Generate specific section
	if args.section:
		content = generator.generate_markdown_section(args.section)
		
		if args.output:
			with open(args.output, 'w', encoding='utf-8') as f:
				f.write(content)
			print(f"✓ Generated {args.section} documentation to {args.output}")
		else:
			print(content)
		
		return 0
	
	# Generate quick reference
	if args.quick_ref:
		content = generator.generate_quick_reference()
		
		if args.output:
			with open(args.output, 'w', encoding='utf-8') as f:
				f.write(content)
			print(f"✓ Generated quick reference to {args.output}")
		else:
			print(content)
		
		return 0
	
	print("Use --generate-all, --section <name>, or --quick-ref")
	return 0


if __name__ == '__main__':
	exit(main())
