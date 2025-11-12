#!/usr/bin/env python3
"""
FFMQ Event System Analyzer
===========================

Advanced analysis tool that treats FFMQ's dialog system as an event system with
embedded text functionality. Analyzes parameter-based control codes, event flow,
state modifications, and inter-dialog relationships.

Based on user insight: "dialog is also the event system and should be treated
more as an event system with a dialog system than a dialog system with events"

Key Features:
------------
1. **Event Command Analysis**
   - Identifies all control codes as event commands
   - Extracts command parameters
   - Traces parameter byte sequences
   - Maps parameter types (addresses, values, indices)

2. **Control Flow Analysis**
   - Builds event flow graphs
   - Traces subroutine calls (0x08)
   - Identifies branching logic
   - Maps event dependencies

3. **State Modification Tracking**
   - Memory write operations (0x0E)
   - Variable assignments (0x24-0x28)
   - Game state changes
   - Quest flag manipulation

4. **Parameter Pattern Recognition**
   - Identifies parameter usage patterns
   - Clusters similar command sequences
   - Suggests parameter meanings
   - Validates hypotheses

5. **Event System Documentation**
   - Generates event command reference
   - Documents parameter formats
   - Creates call graphs
   - Produces usage statistics

Author: TheAnsarya
Date: 2025-11-12
License: MIT
"""

import struct
import json
import sys
from pathlib import Path
from typing import Dict, List, Tuple, Set, Optional, Any
from dataclasses import dataclass, field, asdict
from collections import Counter, defaultdict
from enum import Enum


class CommandCategory(Enum):
    """Event command categories."""
    TEXT_DISPLAY = "text_display"
    CONTROL_FLOW = "control_flow"
    STATE_MODIFICATION = "state_modification"
    DYNAMIC_INSERTION = "dynamic_insertion"
    FORMATTING = "formatting"
    MEMORY_OPERATION = "memory_operation"
    UNKNOWN = "unknown"


@dataclass
class EventCommand:
    """Represents a single event command (control code) with parameters."""

    opcode: int
    name: str
    address: int  # ROM address where command appears
    dialog_id: int  # Which dialog this command is in
    position: int  # Position within dialog
    parameters: List[int] = field(default_factory=list)
    parameter_count: int = 0
    category: CommandCategory = CommandCategory.UNKNOWN
    description: str = ""

    # Analysis metadata
    follows: Optional[int] = None  # Previous command opcode
    precedes: Optional[int] = None  # Next command opcode
    context: List[int] = field(default_factory=list)  # Surrounding bytes

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for JSON serialization."""
        d = asdict(self)
        d['category'] = self.category.value
        return d


@dataclass
class EventDialog:
    """Represents a dialog as an event script."""

    dialog_id: int
    address: int  # ROM address
    raw_bytes: bytes
    length: int

    commands: List[EventCommand] = field(default_factory=list)
    text_segments: List[Tuple[int, str]] = field(default_factory=list)  # (position, text)

    # Event system analysis
    calls_subroutines: List[int] = field(default_factory=list)  # 0x08 targets
    modifies_memory: List[Tuple[int, int]] = field(default_factory=list)  # 0x0E (addr, value)
    sets_variables: Dict[str, int] = field(default_factory=dict)  # Variable assignments

    # Control flow
    has_branching: bool = False
    has_loops: bool = False
    references_dialogs: List[int] = field(default_factory=list)

    # Statistics
    command_count: int = 0
    text_bytes: int = 0
    event_bytes: int = 0

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for JSON serialization."""
        return {
            'dialog_id': self.dialog_id,
            'address': f"0x{self.address:06X}",
            'length': self.length,
            'commands': [cmd.to_dict() for cmd in self.commands],
            'text_segments': [(pos, text) for pos, text in self.text_segments],
            'calls_subroutines': [f"0x{addr:04X}" for addr in self.calls_subroutines],
            'modifies_memory': [(f"0x{addr:04X}", f"0x{val:04X}") for addr, val in self.modifies_memory],
            'sets_variables': self.sets_variables,
            'has_branching': self.has_branching,
            'has_loops': self.has_loops,
            'references_dialogs': self.references_dialogs,
            'command_count': self.command_count,
            'text_bytes': self.text_bytes,
            'event_bytes': self.event_bytes
        }


class EventSystemAnalyzer:
    """Analyzes FFMQ dialog system as an event scripting system."""

    # Known event commands (control codes) with parameter counts
    COMMANDS = {
        # Basic operations (0x00-0x06)
        0x00: ("END", 0, CommandCategory.CONTROL_FLOW, "Dialog/event terminator"),
        0x01: ("NEWLINE", 0, CommandCategory.TEXT_DISPLAY, "Text line break"),
        0x02: ("WAIT", 0, CommandCategory.TEXT_DISPLAY, "Wait for user input"),
        0x03: ("ASTERISK", 0, CommandCategory.TEXT_DISPLAY, "Portrait/asterisk marker"),
        0x04: ("NAME", 0, CommandCategory.DYNAMIC_INSERTION, "Character name insertion"),
        0x05: ("ITEM", 1, CommandCategory.DYNAMIC_INSERTION, "Item name insertion"),
        0x06: ("SPACE", 0, CommandCategory.TEXT_DISPLAY, "Space character"),

        # Unknown/complex operations (0x07-0x0F)
        0x07: ("UNK_07", 3, CommandCategory.UNKNOWN, "Unknown 3-parameter operation"),
        0x08: ("CALL_SUBROUTINE", 2, CommandCategory.CONTROL_FLOW, "Execute dialog subroutine"),
        0x09: ("UNK_09", 3, CommandCategory.UNKNOWN, "Unknown 3-parameter operation"),
        0x0A: ("UNK_0A", 0, CommandCategory.UNKNOWN, "Unknown no-parameter operation"),
        0x0B: ("UNK_0B", None, CommandCategory.UNKNOWN, "Unknown conditional operation"),
        0x0C: ("UNK_0C", 3, CommandCategory.UNKNOWN, "Unknown 3-parameter R/W operation"),
        0x0D: ("UNK_0D", 4, CommandCategory.UNKNOWN, "Unknown 4-parameter operation"),
        0x0E: ("MEMORY_WRITE", 4, CommandCategory.MEMORY_OPERATION, "Write 16-bit value to address"),
        0x0F: ("UNK_0F", 2, CommandCategory.UNKNOWN, "Unknown 2-parameter state control"),

        # Dynamic insertion (0x10-0x19)
        0x10: ("INSERT_ITEM", 1, CommandCategory.DYNAMIC_INSERTION, "Dynamic item name"),
        0x11: ("INSERT_SPELL", 1, CommandCategory.DYNAMIC_INSERTION, "Dynamic spell name"),
        0x12: ("INSERT_MONSTER", 1, CommandCategory.DYNAMIC_INSERTION, "Dynamic monster name"),
        0x13: ("INSERT_CHARACTER", 1, CommandCategory.DYNAMIC_INSERTION, "Dynamic character name"),
        0x14: ("INSERT_LOCATION", 1, CommandCategory.DYNAMIC_INSERTION, "Dynamic location name"),
        0x15: ("INSERT_NUMBER", 2, CommandCategory.DYNAMIC_INSERTION, "Insert number (unused)"),
        0x16: ("INSERT_OBJECT", 2, CommandCategory.DYNAMIC_INSERTION, "Dynamic object name"),
        0x17: ("INSERT_WEAPON", 1, CommandCategory.DYNAMIC_INSERTION, "Dynamic weapon name"),
        0x18: ("INSERT_ARMOR", 0, CommandCategory.DYNAMIC_INSERTION, "Dynamic armor name (uses register)"),
        0x19: ("INSERT_ACCESSORY", 0, CommandCategory.DYNAMIC_INSERTION, "Insert accessory (unused)"),

        # Formatting/display control (0x1A-0x1F)
        0x1A: ("TEXTBOX_BELOW", 1, CommandCategory.FORMATTING, "Position textbox below"),
        0x1B: ("TEXTBOX_ABOVE", 1, CommandCategory.FORMATTING, "Position textbox above"),
        0x1C: ("UNK_1C", 0, CommandCategory.UNKNOWN, "Unknown formatting operation"),
        0x1D: ("FORMAT_ITEM_E1", 1, CommandCategory.FORMATTING, "Format dictionary 0x50"),
        0x1E: ("FORMAT_ITEM_E2", 1, CommandCategory.FORMATTING, "Format dictionary 0x51"),
        0x1F: ("CRYSTAL", 1, CommandCategory.DYNAMIC_INSERTION, "Crystal reference"),

        # State control (0x20-0x2F)
        0x20: ("UNK_20", 1, CommandCategory.STATE_MODIFICATION, "State + subroutine"),
        0x21: ("UNK_21", 0, CommandCategory.UNKNOWN, "Unknown state operation"),
        0x22: ("UNK_22", 0, CommandCategory.UNKNOWN, "Unknown state operation"),
        0x23: ("EXTERNAL_CALL_1", 1, CommandCategory.CONTROL_FLOW, "Call external routine"),
        0x24: ("SET_STATE_VAR", 4, CommandCategory.STATE_MODIFICATION, "Set 2 state variables"),
        0x25: ("SET_STATE_BYTE", 1, CommandCategory.STATE_MODIFICATION, "Set 8-bit state variable"),
        0x26: ("SET_STATE_WORD", 4, CommandCategory.STATE_MODIFICATION, "Set 16-bit state variable"),
        0x27: ("SET_STATE_BYTE_2", 1, CommandCategory.STATE_MODIFICATION, "Set 8-bit state variable"),
        0x28: ("SET_STATE_BYTE_3", 1, CommandCategory.STATE_MODIFICATION, "Set 8-bit state variable"),
        0x29: ("EXTERNAL_CALL_2", 1, CommandCategory.CONTROL_FLOW, "Call external routine"),
        0x2A: ("UNK_2A", None, CommandCategory.UNKNOWN, "Unknown operation"),
        0x2B: ("EXTERNAL_CALL_3", 1, CommandCategory.CONTROL_FLOW, "Call external routine"),
        0x2C: ("UNK_2C", 2, CommandCategory.UNKNOWN, "Unknown 2-parameter operation"),
        0x2D: ("SET_STATE_WORD_2", 2, CommandCategory.STATE_MODIFICATION, "Set 16-bit state variable"),
        0x2E: ("UNK_2E", 1, CommandCategory.UNKNOWN, "Bitfield test operation"),
        0x2F: ("UNK_2F", 0, CommandCategory.UNKNOWN, "Loads constant"),
    }

    # Text characters (simplified - will load from .tbl file)
    TEXT_CHARS = set(range(0x90, 0xCE))  # Approximate range

    def __init__(self, rom_path: str, table_path: Optional[str] = None):
        """
        Initialize analyzer.

        Args:
            rom_path: Path to ROM file
            table_path: Optional path to character table (.tbl)
        """
        self.rom_path = Path(rom_path)
        self.table_path = Path(table_path) if table_path else None

        self.rom_data: bytes = b""
        self.char_table: Dict[int, str] = {}
        self.reverse_table: Dict[str, int] = {}

        self.dialogs: List[EventDialog] = []
        self.all_commands: List[EventCommand] = []

        # Analysis results
        self.command_usage: Counter = Counter()
        self.parameter_patterns: Dict[int, List[List[int]]] = defaultdict(list)
        self.command_sequences: Counter = Counter()
        self.subroutine_calls: Dict[int, List[int]] = defaultdict(list)  # addr -> calling dialogs
        self.memory_writes: List[Tuple[int, int, int]] = []  # (dialog_id, address, value)

    def load_rom(self) -> None:
        """Load ROM file."""
        print(f"Loading ROM: {self.rom_path}")
        with open(self.rom_path, 'rb') as f:
            self.rom_data = f.read()
        print(f"  Loaded {len(self.rom_data):,} bytes")

    def load_character_table(self) -> None:
        """Load character encoding table."""
        if not self.table_path:
            print("No character table provided, using defaults")
            return

        print(f"Loading character table: {self.table_path}")
        with open(self.table_path, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith('#'):
                    continue

                if '=' in line:
                    byte_str, char = line.split('=', 1)
                    byte_val = int(byte_str, 16)
                    self.char_table[byte_val] = char
                    self.reverse_table[char] = byte_val

        print(f"  Loaded {len(self.char_table)} character mappings")

        # Update TEXT_CHARS set with actual character bytes
        self.TEXT_CHARS = set(self.char_table.keys())

    def read_pointer_table(self, table_address: int, count: int) -> List[int]:
        """
        Read dialog pointer table.

        Args:
            table_address: ROM address of pointer table
            count: Number of pointers to read

        Returns:
            List of ROM addresses
        """
        print(f"Reading pointer table at 0x{table_address:06X} ({count} entries)")

        pointers = []
        for i in range(count):
            offset = table_address + (i * 2)
            if offset + 2 > len(self.rom_data):
                break

            ptr_val = struct.unpack('<H', self.rom_data[offset:offset+2])[0]

            # Convert bank $03 pointer to ROM address
            # Assume pointers are in bank $03 (ROM $018000-$01FFFF)
            if ptr_val < 0x8000:
                continue  # Invalid pointer

            rom_addr = 0x018000 + (ptr_val - 0x8000)
            pointers.append(rom_addr)

        print(f"  Read {len(pointers)} valid pointers")
        return pointers

    def extract_dialog_bytes(self, start_address: int, max_length: int = 1024) -> bytes:
        """
        Extract dialog bytes from ROM.

        Args:
            start_address: ROM address of dialog start
            max_length: Maximum bytes to read

        Returns:
            Dialog bytes (up to END marker)
        """
        bytes_list = []
        offset = start_address

        for i in range(max_length):
            if offset >= len(self.rom_data):
                break

            byte = self.rom_data[offset]
            bytes_list.append(byte)
            offset += 1

            # Stop at END marker
            if byte == 0x00:
                break

        return bytes(bytes_list)

    def is_text_byte(self, byte: int) -> bool:
        """Check if byte is a text character."""
        return byte in self.TEXT_CHARS

    def parse_event_command(self, data: bytes, position: int, dialog_id: int, rom_address: int) -> Tuple[EventCommand, int]:
        """
        Parse a single event command from dialog data.

        Args:
            data: Dialog byte data
            position: Current position in data
            dialog_id: Dialog ID
            rom_address: ROM address of this command

        Returns:
            (EventCommand, bytes_consumed)
        """
        if position >= len(data):
            raise ValueError("Position out of bounds")

        opcode = data[position]

        # Get command info
        if opcode in self.COMMANDS:
            name, param_count, category, description = self.COMMANDS[opcode]
        else:
            name = f"UNK_{opcode:02X}"
            param_count = 0
            category = CommandCategory.UNKNOWN
            description = "Unknown command"

        # Read parameters
        parameters = []
        bytes_consumed = 1

        if param_count is not None and param_count > 0:
            for i in range(param_count):
                if position + bytes_consumed >= len(data):
                    break
                param_byte = data[position + bytes_consumed]
                parameters.append(param_byte)
                bytes_consumed += 1

        # Get context (5 bytes before and after)
        context_start = max(0, position - 5)
        context_end = min(len(data), position + bytes_consumed + 5)
        context = list(data[context_start:context_end])

        # Determine previous and next commands
        follows = data[position - 1] if position > 0 else None
        precedes = data[position + bytes_consumed] if position + bytes_consumed < len(data) else None

        command = EventCommand(
            opcode=opcode,
            name=name,
            address=rom_address + position,
            dialog_id=dialog_id,
            position=position,
            parameters=parameters,
            parameter_count=len(parameters),
            category=category,
            description=description,
            follows=follows,
            precedes=precedes,
            context=context
        )

        return command, bytes_consumed

    def analyze_dialog_as_event_script(self, dialog_id: int, address: int, data: bytes) -> EventDialog:
        """
        Analyze a dialog as an event script.

        Args:
            dialog_id: Dialog ID
            address: ROM address
            data: Dialog byte data

        Returns:
            EventDialog with full analysis
        """
        event_dialog = EventDialog(
            dialog_id=dialog_id,
            address=address,
            raw_bytes=data,
            length=len(data)
        )

        position = 0
        text_buffer = []
        text_start = -1

        while position < len(data):
            byte = data[position]

            # Check if this is a command
            if byte in self.COMMANDS or byte < 0x30:
                # Save any accumulated text
                if text_buffer:
                    text = ''.join(text_buffer)
                    event_dialog.text_segments.append((text_start, text))
                    event_dialog.text_bytes += len(text_buffer)
                    text_buffer = []
                    text_start = -1

                # Parse event command
                try:
                    command, consumed = self.parse_event_command(data, position, dialog_id, address)
                    event_dialog.commands.append(command)
                    event_dialog.command_count += 1
                    event_dialog.event_bytes += consumed

                    # Track command usage
                    self.command_usage[command.opcode] += 1
                    self.all_commands.append(command)

                    # Track parameter patterns
                    if command.parameters:
                        self.parameter_patterns[command.opcode].append(command.parameters)

                    # Special analysis for specific commands
                    if command.opcode == 0x08:  # CALL_SUBROUTINE
                        if len(command.parameters) >= 2:
                            target_addr = struct.unpack('<H', bytes(command.parameters[:2]))[0]
                            event_dialog.calls_subroutines.append(target_addr)
                            self.subroutine_calls[target_addr].append(dialog_id)

                    elif command.opcode == 0x0E:  # MEMORY_WRITE
                        if len(command.parameters) >= 4:
                            mem_addr = struct.unpack('<H', bytes(command.parameters[:2]))[0]
                            mem_value = struct.unpack('<H', bytes(command.parameters[2:4]))[0]
                            event_dialog.modifies_memory.append((mem_addr, mem_value))
                            self.memory_writes.append((dialog_id, mem_addr, mem_value))

                    position += consumed

                except Exception as e:
                    print(f"Warning: Error parsing command at position {position} in dialog {dialog_id}: {e}")
                    position += 1

            # Text character
            elif self.is_text_byte(byte):
                if text_start == -1:
                    text_start = position

                char = self.char_table.get(byte, f"[{byte:02X}]")
                text_buffer.append(char)
                position += 1

            # Unknown byte - treat as command
            else:
                # Save any accumulated text
                if text_buffer:
                    text = ''.join(text_buffer)
                    event_dialog.text_segments.append((text_start, text))
                    event_dialog.text_bytes += len(text_buffer)
                    text_buffer = []
                    text_start = -1

                # Try to parse as command
                try:
                    command, consumed = self.parse_event_command(data, position, dialog_id, address)
                    event_dialog.commands.append(command)
                    event_dialog.event_bytes += consumed
                    position += consumed
                except:
                    position += 1

        # Save any remaining text
        if text_buffer:
            text = ''.join(text_buffer)
            event_dialog.text_segments.append((text_start, text))
            event_dialog.text_bytes += len(text_buffer)

        return event_dialog

    def analyze_all_dialogs(self, pointer_table_address: int, dialog_count: int) -> None:
        """
        Analyze all dialogs in ROM.

        Args:
            pointer_table_address: ROM address of dialog pointer table
            dialog_count: Number of dialogs to analyze
        """
        print(f"\nAnalyzing {dialog_count} dialogs...")

        pointers = self.read_pointer_table(pointer_table_address, dialog_count)

        for i, address in enumerate(pointers):
            if i % 10 == 0:
                print(f"  Progress: {i}/{len(pointers)} dialogs analyzed...")

            # Extract dialog bytes
            data = self.extract_dialog_bytes(address)

            # Analyze as event script
            event_dialog = self.analyze_dialog_as_event_script(i, address, data)
            self.dialogs.append(event_dialog)

        print(f"  Completed: {len(self.dialogs)} dialogs analyzed")

    def generate_statistics(self) -> Dict[str, Any]:
        """Generate comprehensive analysis statistics."""
        stats = {
            'total_dialogs': len(self.dialogs),
            'total_commands': len(self.all_commands),
            'total_bytes_analyzed': sum(d.length for d in self.dialogs),
            'text_bytes': sum(d.text_bytes for d in self.dialogs),
            'event_bytes': sum(d.event_bytes for d in self.dialogs),

            'command_usage': {
                f"0x{opcode:02X} ({self.COMMANDS.get(opcode, ('UNKNOWN',))[0]})": count
                for opcode, count in self.command_usage.most_common()
            },

            'category_usage': {},
            'parameter_statistics': {},
            'subroutine_call_graph': {},
            'memory_modification_map': {},

            'dialogs_with_events': sum(1 for d in self.dialogs if d.command_count > 0),
            'dialogs_text_only': sum(1 for d in self.dialogs if d.command_count == 0),
            'dialogs_calling_subroutines': sum(1 for d in self.dialogs if d.calls_subroutines),
            'dialogs_modifying_memory': sum(1 for d in self.dialogs if d.modifies_memory),
        }

        # Category usage
        category_counts = defaultdict(int)
        for cmd in self.all_commands:
            category_counts[cmd.category.value] += 1
        stats['category_usage'] = dict(category_counts)

        # Parameter statistics
        for opcode, patterns in self.parameter_patterns.items():
            if opcode in self.COMMANDS:
                name = self.COMMANDS[opcode][0]
                stats['parameter_statistics'][f"0x{opcode:02X} ({name})"] = {
                    'count': len(patterns),
                    'unique_patterns': len(set(tuple(p) for p in patterns)),
                    'average_param_count': sum(len(p) for p in patterns) / len(patterns) if patterns else 0,
                    'sample_patterns': [list(p) for p in patterns[:5]]  # First 5 examples
                }

        # Subroutine call graph
        for target_addr, calling_dialogs in self.subroutine_calls.items():
            stats['subroutine_call_graph'][f"0x{target_addr:04X}"] = {
                'called_by_count': len(calling_dialogs),
                'calling_dialogs': calling_dialogs[:10]  # First 10
            }

        # Memory modification map
        memory_map = defaultdict(list)
        for dialog_id, mem_addr, mem_value in self.memory_writes:
            memory_map[mem_addr].append((dialog_id, mem_value))

        for mem_addr, modifications in memory_map.items():
            stats['memory_modification_map'][f"0x{mem_addr:04X}"] = {
                'modification_count': len(modifications),
                'modifying_dialogs': [dialog_id for dialog_id, _ in modifications[:10]],
                'values_written': [f"0x{val:04X}" for _, val in modifications[:10]]
            }

        return stats

    def generate_event_command_reference(self) -> str:
        """Generate comprehensive event command reference documentation."""
        lines = []
        lines.append("# FFMQ Event System Command Reference")
        lines.append("=" * 80)
        lines.append("")
        lines.append("**Generated from ROM analysis**")
        lines.append(f"**Analyzed {len(self.dialogs)} dialog/event scripts**")
        lines.append(f"**Total event commands: {len(self.all_commands):,}**")
        lines.append("")
        lines.append("## Command Categories")
        lines.append("")

        # Group commands by category
        by_category = defaultdict(list)
        for opcode, (name, param_count, category, desc) in self.COMMANDS.items():
            by_category[category].append((opcode, name, param_count, desc))

        for category in CommandCategory:
            if category not in by_category:
                continue

            lines.append(f"### {category.value.replace('_', ' ').title()}")
            lines.append("")

            commands = sorted(by_category[category], key=lambda x: x[0])

            for opcode, name, param_count, desc in commands:
                usage_count = self.command_usage.get(opcode, 0)

                lines.append(f"**0x{opcode:02X}: {name}**")
                lines.append(f"- Description: {desc}")
                lines.append(f"- Parameters: {param_count if param_count is not None else 'Variable'}")
                lines.append(f"- Usage: {usage_count:,} occurrences ({usage_count / len(self.all_commands) * 100:.1f}%)")

                # Parameter patterns
                if opcode in self.parameter_patterns:
                    patterns = self.parameter_patterns[opcode]
                    unique_patterns = set(tuple(p) for p in patterns)
                    lines.append(f"- Unique parameter patterns: {len(unique_patterns)}")

                    if patterns:
                        lines.append(f"- Example parameters:")
                        for pattern in list(unique_patterns)[:3]:
                            hex_params = ' '.join(f"{p:02X}" for p in pattern)
                            lines.append(f"  - [{hex_params}]")

                # Special analysis for key commands
                if opcode == 0x08:  # CALL_SUBROUTINE
                    lines.append(f"- Subroutine call targets: {len(self.subroutine_calls)} unique addresses")
                    lines.append(f"- Most called subroutines:")
                    for addr, dialogs in sorted(self.subroutine_calls.items(), key=lambda x: len(x[1]), reverse=True)[:5]:
                        lines.append(f"  - 0x{addr:04X}: called by {len(dialogs)} dialogs")

                elif opcode == 0x0E:  # MEMORY_WRITE
                    memory_map = defaultdict(list)
                    for dialog_id, mem_addr, mem_value in self.memory_writes:
                        memory_map[mem_addr].append((dialog_id, mem_value))

                    lines.append(f"- Memory addresses modified: {len(memory_map)} unique addresses")
                    lines.append(f"- Most frequently modified:")
                    for addr, mods in sorted(memory_map.items(), key=lambda x: len(x[1]), reverse=True)[:5]:
                        lines.append(f"  - 0x{addr:04X}: modified {len(mods)} times")

                lines.append("")

        return '\n'.join(lines)

    def export_results(self, output_dir: str) -> None:
        """
        Export analysis results to files.

        Args:
            output_dir: Output directory path
        """
        output_path = Path(output_dir)
        output_path.mkdir(parents=True, exist_ok=True)

        print(f"\nExporting results to {output_path}/")

        # 1. Statistics JSON
        stats = self.generate_statistics()
        with open(output_path / 'event_system_statistics.json', 'w') as f:
            json.dump(stats, f, indent=2)
        print("  ✅ event_system_statistics.json")

        # 2. All dialogs as event scripts JSON
        dialogs_data = [d.to_dict() for d in self.dialogs]
        with open(output_path / 'event_scripts.json', 'w') as f:
            json.dump(dialogs_data, f, indent=2)
        print("  ✅ event_scripts.json")

        # 3. Command reference markdown
        reference = self.generate_event_command_reference()
        with open(output_path / 'EVENT_COMMAND_REFERENCE.md', 'w') as f:
            f.write(reference)
        print("  ✅ EVENT_COMMAND_REFERENCE.md")

        # 4. Subroutine call graph (CSV)
        with open(output_path / 'subroutine_call_graph.csv', 'w') as f:
            f.write("Target Address,Call Count,Calling Dialogs\n")
            for addr, dialogs in sorted(self.subroutine_calls.items(), key=lambda x: len(x[1]), reverse=True):
                dialog_list = ';'.join(str(d) for d in dialogs)
                f.write(f"0x{addr:04X},{len(dialogs)},{dialog_list}\n")
        print("  ✅ subroutine_call_graph.csv")

        # 5. Memory modification map (CSV)
        with open(output_path / 'memory_modification_map.csv', 'w') as f:
            f.write("Dialog ID,Memory Address,Value Written\n")
            for dialog_id, mem_addr, mem_value in self.memory_writes:
                f.write(f"{dialog_id},0x{mem_addr:04X},0x{mem_value:04X}\n")
        print("  ✅ memory_modification_map.csv")

        # 6. Parameter patterns (CSV)
        with open(output_path / 'parameter_patterns.csv', 'w') as f:
            f.write("Opcode,Command Name,Pattern Count,Unique Patterns,Sample Pattern\n")
            for opcode, patterns in sorted(self.parameter_patterns.items()):
                name = self.COMMANDS.get(opcode, ('UNKNOWN',))[0]
                unique = set(tuple(p) for p in patterns)
                sample = ' '.join(f"{b:02X}" for b in patterns[0]) if patterns else ""
                f.write(f"0x{opcode:02X},{name},{len(patterns)},{len(unique)},{sample}\n")
        print("  ✅ parameter_patterns.csv")

        print("\n✅ Export complete!")


def main():
    """Main entry point."""
    import argparse

    parser = argparse.ArgumentParser(
        description="Analyze FFMQ dialog system as event scripting system",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Analyze all dialogs
  python event_system_analyzer.py --rom ffmq.sfc --table simple.tbl

  # Analyze with custom dialog count
  python event_system_analyzer.py --rom ffmq.sfc --table simple.tbl --count 200

  # Export to specific directory
  python event_system_analyzer.py --rom ffmq.sfc --table simple.tbl --output analysis/

Documentation:
  This tool treats FFMQ's dialog system as an event scripting system,
  analyzing parameter-based control codes, control flow, and state modifications.

  Key features:
  - Event command identification and parameter extraction
  - Subroutine call graph generation
  - Memory modification tracking
  - Parameter pattern recognition
  - Control flow analysis
        """
    )

    parser.add_argument(
        '--rom',
        required=True,
        help='Path to FFMQ ROM file'
    )

    parser.add_argument(
        '--table',
        help='Path to character table file (.tbl)'
    )

    parser.add_argument(
        '--pointer-table',
        type=lambda x: int(x, 16),
        default=0x00D636,
        help='ROM address of dialog pointer table (hex, default: 0x00D636)'
    )

    parser.add_argument(
        '--count',
        type=int,
        default=256,
        help='Number of dialogs to analyze (default: 256)'
    )

    parser.add_argument(
        '--output',
        default='docs/event_system_analysis',
        help='Output directory for analysis results'
    )

    args = parser.parse_args()

    # Initialize analyzer
    analyzer = EventSystemAnalyzer(args.rom, args.table)

    # Load data
    analyzer.load_rom()
    if args.table:
        analyzer.load_character_table()

    # Analyze dialogs
    analyzer.analyze_all_dialogs(args.pointer_table, args.count)

    # Generate and export results
    analyzer.export_results(args.output)

    print("\n" + "=" * 80)
    print("EVENT SYSTEM ANALYSIS COMPLETE")
    print("=" * 80)
    print(f"\nSummary:")
    print(f"  Dialogs analyzed: {len(analyzer.dialogs)}")
    print(f"  Event commands found: {len(analyzer.all_commands):,}")
    print(f"  Unique commands used: {len(analyzer.command_usage)}")
    print(f"  Subroutine calls: {sum(len(d.calls_subroutines) for d in analyzer.dialogs)}")
    print(f"  Memory modifications: {len(analyzer.memory_writes)}")
    print(f"\nResults exported to: {args.output}/")
    print(f"\nGenerated files:")
    print(f"  ✓ {args.output}/event_system_statistics.json")
    print(f"  ✓ {args.output}/event_scripts.json")
    print(f"  ✓ {args.output}/EVENT_COMMAND_REFERENCE.md")
    print(f"  ✓ {args.output}/subroutine_call_graph.csv")
    print(f"  ✓ {args.output}/memory_modification_map.csv")
    print(f"  ✓ {args.output}/parameter_patterns.csv")
    print(f"\nNext steps:")
    print(f"  1. Review event_system_statistics.json for overview")
    print(f"  2. Check EVENT_COMMAND_REFERENCE.md for command details")
    print(f"  3. Analyze parameter patterns for unknown commands")
    print(f"  4. See docs/EVENT_SYSTEM_QUICK_START.md for analysis workflows")
    print("")


if __name__ == '__main__':
    main()
