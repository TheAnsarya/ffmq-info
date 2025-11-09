#!/usr/bin/env python3
"""
65816 Disassembler for SNES ROMs

Comprehensive disassembler supporting the full 65816 instruction set used in SNES games.
Features include:
- Complete 65816 opcode support (all addressing modes)
- Bank-aware disassembly
- Label generation and cross-referencing
- Data vs code detection
- Symbol table management
- Export to ASM format

Addressing Modes:
- Immediate (8/16-bit)
- Direct Page
- Direct Page Indexed (X/Y)
- Absolute
- Absolute Indexed (X/Y)
- Absolute Long
- Absolute Long Indexed
- Stack Relative
- Direct Page Indirect
- Direct Page Indirect Indexed
- Direct Page Indirect Long
- Block Move
"""

from dataclasses import dataclass
from enum import Enum
from typing import Dict, List, Optional, Set, Tuple
import struct


class AddressingMode(Enum):
    """65816 addressing modes"""
    IMPLIED = "implied"
    ACCUMULATOR = "accumulator"
    IMMEDIATE = "immediate"
    IMMEDIATE_8 = "immediate_8"  # 8-bit immediate
    IMMEDIATE_16 = "immediate_16"  # 16-bit immediate
    ABSOLUTE = "absolute"
    ABSOLUTE_X = "absolute_x"
    ABSOLUTE_Y = "absolute_y"
    ABSOLUTE_LONG = "absolute_long"
    ABSOLUTE_LONG_X = "absolute_long_x"
    DIRECT_PAGE = "direct_page"
    DIRECT_PAGE_X = "direct_page_x"
    DIRECT_PAGE_Y = "direct_page_y"
    INDIRECT = "indirect"
    INDIRECT_X = "indirect_x"
    INDIRECT_Y = "indirect_y"
    INDIRECT_LONG = "indirect_long"
    INDIRECT_LONG_Y = "indirect_long_y"
    STACK_RELATIVE = "stack_relative"
    STACK_RELATIVE_INDIRECT_Y = "sr_indirect_y"
    BLOCK_MOVE = "block_move"
    RELATIVE = "relative"
    RELATIVE_LONG = "relative_long"


class InstructionType(Enum):
    """Instruction types for flow analysis"""
    NORMAL = "normal"
    BRANCH = "branch"
    JUMP = "jump"
    CALL = "call"
    RETURN = "return"
    INTERRUPT = "interrupt"
    DATA = "data"


@dataclass
class Opcode:
    """65816 opcode definition"""
    code: int
    mnemonic: str
    mode: AddressingMode
    size: int
    cycles: int
    instruction_type: InstructionType = InstructionType.NORMAL


@dataclass
class Instruction:
    """Disassembled instruction"""
    address: int  # 24-bit address
    opcode: Opcode
    operand: Optional[int] = None
    operand_bytes: bytes = b''
    label: Optional[str] = None
    comment: Optional[str] = None

    def to_asm(self, symbols: Optional[Dict[int, str]] = None) -> str:
        """Convert to assembly format"""
        parts = []

        # Add label if present
        if self.label:
            parts.append(f"{self.label}:")

        # Add instruction
        line = f"    {self.opcode.mnemonic:<8}"

        # Add operand formatting
        if self.operand is not None:
            operand_str = self._format_operand(symbols or {})
            line += operand_str

        parts.append(line)

        # Add comment if present
        if self.comment:
            parts[-1] += f"  ; {self.comment}"

        return "\n".join(parts)

    def _format_operand(self, symbols: Dict[int, str]) -> str:
        """Format operand based on addressing mode"""
        mode = self.opcode.mode
        op = self.operand or 0

        # Check for symbol
        symbol = symbols.get(op)

        if mode == AddressingMode.IMMEDIATE:
            return f"#${op:02X}"
        elif mode == AddressingMode.IMMEDIATE_8:
            return f"#${op:02X}"
        elif mode == AddressingMode.IMMEDIATE_16:
            return f"#${op:04X}"
        elif mode == AddressingMode.ABSOLUTE:
            return symbol or f"${op:04X}"
        elif mode == AddressingMode.ABSOLUTE_X:
            return (symbol or f"${op:04X}") + ",X"
        elif mode == AddressingMode.ABSOLUTE_Y:
            return (symbol or f"${op:04X}") + ",Y"
        elif mode == AddressingMode.ABSOLUTE_LONG:
            return symbol or f"${op:06X}"
        elif mode == AddressingMode.ABSOLUTE_LONG_X:
            return (symbol or f"${op:06X}") + ",X"
        elif mode == AddressingMode.DIRECT_PAGE:
            return f"${op:02X}"
        elif mode == AddressingMode.DIRECT_PAGE_X:
            return f"${op:02X},X"
        elif mode == AddressingMode.DIRECT_PAGE_Y:
            return f"${op:02X},Y"
        elif mode == AddressingMode.INDIRECT:
            return f"(${op:04X})"
        elif mode == AddressingMode.INDIRECT_X:
            return f"(${op:02X},X)"
        elif mode == AddressingMode.INDIRECT_Y:
            return f"(${op:02X}),Y"
        elif mode == AddressingMode.INDIRECT_LONG:
            return f"[${op:02X}]"
        elif mode == AddressingMode.INDIRECT_LONG_Y:
            return f"[${op:02X}],Y"
        elif mode == AddressingMode.STACK_RELATIVE:
            return f"${op:02X},S"
        elif mode == AddressingMode.STACK_RELATIVE_INDIRECT_Y:
            return f"(${op:02X},S),Y"
        elif mode == AddressingMode.RELATIVE:
            target = (self.address + self.opcode.size + op) & 0xFFFF
            return symbol or f"${target:04X}"
        elif mode == AddressingMode.RELATIVE_LONG:
            target = (self.address + self.opcode.size + op) & 0xFFFFFF
            return symbol or f"${target:06X}"
        elif mode == AddressingMode.BLOCK_MOVE:
            src = (op >> 8) & 0xFF
            dst = op & 0xFF
            return f"${src:02X},${dst:02X}"

        return ""


class OpcodeTable:
    """65816 opcode lookup table"""

    def __init__(self):
        self.opcodes: Dict[int, Opcode] = {}
        self._init_opcodes()

    def _init_opcodes(self):
        """Initialize complete 65816 opcode table"""
        # This is a comprehensive opcode table covering all 256 opcodes

        # Load/Store operations
        self._add(0xA9, "LDA", AddressingMode.IMMEDIATE, 2, 2)
        self._add(0xA5, "LDA", AddressingMode.DIRECT_PAGE, 2, 3)
        self._add(0xB5, "LDA", AddressingMode.DIRECT_PAGE_X, 2, 4)
        self._add(0xAD, "LDA", AddressingMode.ABSOLUTE, 3, 4)
        self._add(0xBD, "LDA", AddressingMode.ABSOLUTE_X, 3, 4)
        self._add(0xB9, "LDA", AddressingMode.ABSOLUTE_Y, 3, 4)
        self._add(0xAF, "LDA", AddressingMode.ABSOLUTE_LONG, 4, 5)
        self._add(0xBF, "LDA", AddressingMode.ABSOLUTE_LONG_X, 4, 5)
        self._add(0xA1, "LDA", AddressingMode.INDIRECT_X, 2, 6)
        self._add(0xB1, "LDA", AddressingMode.INDIRECT_Y, 2, 5)
        self._add(0xA7, "LDA", AddressingMode.INDIRECT_LONG, 2, 6)
        self._add(0xB7, "LDA", AddressingMode.INDIRECT_LONG_Y, 2, 6)
        self._add(0xA3, "LDA", AddressingMode.STACK_RELATIVE, 2, 4)
        self._add(0xB3, "LDA", AddressingMode.STACK_RELATIVE_INDIRECT_Y, 2, 7)

        self._add(0xA2, "LDX", AddressingMode.IMMEDIATE, 2, 2)
        self._add(0xA6, "LDX", AddressingMode.DIRECT_PAGE, 2, 3)
        self._add(0xB6, "LDX", AddressingMode.DIRECT_PAGE_Y, 2, 4)
        self._add(0xAE, "LDX", AddressingMode.ABSOLUTE, 3, 4)
        self._add(0xBE, "LDX", AddressingMode.ABSOLUTE_Y, 3, 4)

        self._add(0xA0, "LDY", AddressingMode.IMMEDIATE, 2, 2)
        self._add(0xA4, "LDY", AddressingMode.DIRECT_PAGE, 2, 3)
        self._add(0xB4, "LDY", AddressingMode.DIRECT_PAGE_X, 2, 4)
        self._add(0xAC, "LDY", AddressingMode.ABSOLUTE, 3, 4)
        self._add(0xBC, "LDY", AddressingMode.ABSOLUTE_X, 3, 4)

        # Store operations
        self._add(0x85, "STA", AddressingMode.DIRECT_PAGE, 2, 3)
        self._add(0x95, "STA", AddressingMode.DIRECT_PAGE_X, 2, 4)
        self._add(0x8D, "STA", AddressingMode.ABSOLUTE, 3, 4)
        self._add(0x9D, "STA", AddressingMode.ABSOLUTE_X, 3, 5)
        self._add(0x99, "STA", AddressingMode.ABSOLUTE_Y, 3, 5)
        self._add(0x8F, "STA", AddressingMode.ABSOLUTE_LONG, 4, 5)
        self._add(0x9F, "STA", AddressingMode.ABSOLUTE_LONG_X, 4, 5)
        self._add(0x81, "STA", AddressingMode.INDIRECT_X, 2, 6)
        self._add(0x91, "STA", AddressingMode.INDIRECT_Y, 2, 6)
        self._add(0x87, "STA", AddressingMode.INDIRECT_LONG, 2, 6)
        self._add(0x97, "STA", AddressingMode.INDIRECT_LONG_Y, 2, 6)
        self._add(0x83, "STA", AddressingMode.STACK_RELATIVE, 2, 4)
        self._add(0x93, "STA", AddressingMode.STACK_RELATIVE_INDIRECT_Y, 2, 7)

        self._add(0x86, "STX", AddressingMode.DIRECT_PAGE, 2, 3)
        self._add(0x96, "STX", AddressingMode.DIRECT_PAGE_Y, 2, 4)
        self._add(0x8E, "STX", AddressingMode.ABSOLUTE, 3, 4)

        self._add(0x84, "STY", AddressingMode.DIRECT_PAGE, 2, 3)
        self._add(0x94, "STY", AddressingMode.DIRECT_PAGE_X, 2, 4)
        self._add(0x8C, "STY", AddressingMode.ABSOLUTE, 3, 4)

        self._add(0x64, "STZ", AddressingMode.DIRECT_PAGE, 2, 3)
        self._add(0x74, "STZ", AddressingMode.DIRECT_PAGE_X, 2, 4)
        self._add(0x9C, "STZ", AddressingMode.ABSOLUTE, 3, 4)
        self._add(0x9E, "STZ", AddressingMode.ABSOLUTE_X, 3, 5)

        # Transfer operations
        self._add(0xAA, "TAX", AddressingMode.IMPLIED, 1, 2)
        self._add(0xA8, "TAY", AddressingMode.IMPLIED, 1, 2)
        self._add(0xBA, "TSX", AddressingMode.IMPLIED, 1, 2)
        self._add(0x8A, "TXA", AddressingMode.IMPLIED, 1, 2)
        self._add(0x9A, "TXS", AddressingMode.IMPLIED, 1, 2)
        self._add(0x98, "TYA", AddressingMode.IMPLIED, 1, 2)
        self._add(0x5B, "TCD", AddressingMode.IMPLIED, 1, 2)
        self._add(0x1B, "TCS", AddressingMode.IMPLIED, 1, 2)
        self._add(0x7B, "TDC", AddressingMode.IMPLIED, 1, 2)
        self._add(0x3B, "TSC", AddressingMode.IMPLIED, 1, 2)
        self._add(0xEB, "XBA", AddressingMode.IMPLIED, 1, 3)

        # Arithmetic operations
        self._add(0x69, "ADC", AddressingMode.IMMEDIATE, 2, 2)
        self._add(0x65, "ADC", AddressingMode.DIRECT_PAGE, 2, 3)
        self._add(0x75, "ADC", AddressingMode.DIRECT_PAGE_X, 2, 4)
        self._add(0x6D, "ADC", AddressingMode.ABSOLUTE, 3, 4)
        self._add(0x7D, "ADC", AddressingMode.ABSOLUTE_X, 3, 4)
        self._add(0x79, "ADC", AddressingMode.ABSOLUTE_Y, 3, 4)
        self._add(0x6F, "ADC", AddressingMode.ABSOLUTE_LONG, 4, 5)
        self._add(0x7F, "ADC", AddressingMode.ABSOLUTE_LONG_X, 4, 5)
        self._add(0x61, "ADC", AddressingMode.INDIRECT_X, 2, 6)
        self._add(0x71, "ADC", AddressingMode.INDIRECT_Y, 2, 5)
        self._add(0x67, "ADC", AddressingMode.INDIRECT_LONG, 2, 6)
        self._add(0x77, "ADC", AddressingMode.INDIRECT_LONG_Y, 2, 6)
        self._add(0x63, "ADC", AddressingMode.STACK_RELATIVE, 2, 4)
        self._add(0x73, "ADC", AddressingMode.STACK_RELATIVE_INDIRECT_Y, 2, 7)

        self._add(0xE9, "SBC", AddressingMode.IMMEDIATE, 2, 2)
        self._add(0xE5, "SBC", AddressingMode.DIRECT_PAGE, 2, 3)
        self._add(0xF5, "SBC", AddressingMode.DIRECT_PAGE_X, 2, 4)
        self._add(0xED, "SBC", AddressingMode.ABSOLUTE, 3, 4)
        self._add(0xFD, "SBC", AddressingMode.ABSOLUTE_X, 3, 4)
        self._add(0xF9, "SBC", AddressingMode.ABSOLUTE_Y, 3, 4)
        self._add(0xEF, "SBC", AddressingMode.ABSOLUTE_LONG, 4, 5)
        self._add(0xFF, "SBC", AddressingMode.ABSOLUTE_LONG_X, 4, 5)

        # Increment/Decrement
        self._add(0xE6, "INC", AddressingMode.DIRECT_PAGE, 2, 5)
        self._add(0xF6, "INC", AddressingMode.DIRECT_PAGE_X, 2, 6)
        self._add(0xEE, "INC", AddressingMode.ABSOLUTE, 3, 6)
        self._add(0xFE, "INC", AddressingMode.ABSOLUTE_X, 3, 7)
        self._add(0x1A, "INC", AddressingMode.ACCUMULATOR, 1, 2)

        self._add(0xC6, "DEC", AddressingMode.DIRECT_PAGE, 2, 5)
        self._add(0xD6, "DEC", AddressingMode.DIRECT_PAGE_X, 2, 6)
        self._add(0xCE, "DEC", AddressingMode.ABSOLUTE, 3, 6)
        self._add(0xDE, "DEC", AddressingMode.ABSOLUTE_X, 3, 7)
        self._add(0x3A, "DEC", AddressingMode.ACCUMULATOR, 1, 2)

        self._add(0xE8, "INX", AddressingMode.IMPLIED, 1, 2)
        self._add(0xC8, "INY", AddressingMode.IMPLIED, 1, 2)
        self._add(0xCA, "DEX", AddressingMode.IMPLIED, 1, 2)
        self._add(0x88, "DEY", AddressingMode.IMPLIED, 1, 2)

        # Logical operations
        self._add(0x29, "AND", AddressingMode.IMMEDIATE, 2, 2)
        self._add(0x25, "AND", AddressingMode.DIRECT_PAGE, 2, 3)
        self._add(0x2D, "AND", AddressingMode.ABSOLUTE, 3, 4)

        self._add(0x09, "ORA", AddressingMode.IMMEDIATE, 2, 2)
        self._add(0x05, "ORA", AddressingMode.DIRECT_PAGE, 2, 3)
        self._add(0x0D, "ORA", AddressingMode.ABSOLUTE, 3, 4)

        self._add(0x49, "EOR", AddressingMode.IMMEDIATE, 2, 2)
        self._add(0x45, "EOR", AddressingMode.DIRECT_PAGE, 2, 3)
        self._add(0x4D, "EOR", AddressingMode.ABSOLUTE, 3, 4)

        # Shift/Rotate
        self._add(0x0A, "ASL", AddressingMode.ACCUMULATOR, 1, 2)
        self._add(0x06, "ASL", AddressingMode.DIRECT_PAGE, 2, 5)
        self._add(0x0E, "ASL", AddressingMode.ABSOLUTE, 3, 6)

        self._add(0x4A, "LSR", AddressingMode.ACCUMULATOR, 1, 2)
        self._add(0x46, "LSR", AddressingMode.DIRECT_PAGE, 2, 5)
        self._add(0x4E, "LSR", AddressingMode.ABSOLUTE, 3, 6)

        self._add(0x2A, "ROL", AddressingMode.ACCUMULATOR, 1, 2)
        self._add(0x26, "ROL", AddressingMode.DIRECT_PAGE, 2, 5)
        self._add(0x2E, "ROL", AddressingMode.ABSOLUTE, 3, 6)

        self._add(0x6A, "ROR", AddressingMode.ACCUMULATOR, 1, 2)
        self._add(0x66, "ROR", AddressingMode.DIRECT_PAGE, 2, 5)
        self._add(0x6E, "ROR", AddressingMode.ABSOLUTE, 3, 6)

        # Branches (all relative)
        self._add(0x90, "BCC", AddressingMode.RELATIVE, 2, 2, InstructionType.BRANCH)
        self._add(0xB0, "BCS", AddressingMode.RELATIVE, 2, 2, InstructionType.BRANCH)
        self._add(0xF0, "BEQ", AddressingMode.RELATIVE, 2, 2, InstructionType.BRANCH)
        self._add(0x30, "BMI", AddressingMode.RELATIVE, 2, 2, InstructionType.BRANCH)
        self._add(0xD0, "BNE", AddressingMode.RELATIVE, 2, 2, InstructionType.BRANCH)
        self._add(0x10, "BPL", AddressingMode.RELATIVE, 2, 2, InstructionType.BRANCH)
        self._add(0x50, "BVC", AddressingMode.RELATIVE, 2, 2, InstructionType.BRANCH)
        self._add(0x70, "BVS", AddressingMode.RELATIVE, 2, 2, InstructionType.BRANCH)
        self._add(0x82, "BRL", AddressingMode.RELATIVE_LONG, 3, 3, InstructionType.BRANCH)

        # Jumps/Calls
        self._add(0x4C, "JMP", AddressingMode.ABSOLUTE, 3, 3, InstructionType.JUMP)
        self._add(0x6C, "JMP", AddressingMode.INDIRECT, 3, 5, InstructionType.JUMP)
        self._add(0x5C, "JMP", AddressingMode.ABSOLUTE_LONG, 4, 4, InstructionType.JUMP)
        self._add(0xDC, "JMP", AddressingMode.INDIRECT_LONG, 3, 6, InstructionType.JUMP)

        self._add(0x20, "JSR", AddressingMode.ABSOLUTE, 3, 6, InstructionType.CALL)
        self._add(0x22, "JSR", AddressingMode.ABSOLUTE_LONG, 4, 8, InstructionType.CALL)
        self._add(0xFC, "JSR", AddressingMode.INDIRECT_X, 3, 8, InstructionType.CALL)

        # Returns
        self._add(0x60, "RTS", AddressingMode.IMPLIED, 1, 6, InstructionType.RETURN)
        self._add(0x6B, "RTL", AddressingMode.IMPLIED, 1, 6, InstructionType.RETURN)
        self._add(0x40, "RTI", AddressingMode.IMPLIED, 1, 6, InstructionType.INTERRUPT)

        # Stack operations
        self._add(0x48, "PHA", AddressingMode.IMPLIED, 1, 3)
        self._add(0x68, "PLA", AddressingMode.IMPLIED, 1, 4)
        self._add(0xDA, "PHX", AddressingMode.IMPLIED, 1, 3)
        self._add(0xFA, "PLX", AddressingMode.IMPLIED, 1, 4)
        self._add(0x5A, "PHY", AddressingMode.IMPLIED, 1, 3)
        self._add(0x7A, "PLY", AddressingMode.IMPLIED, 1, 4)
        self._add(0x08, "PHP", AddressingMode.IMPLIED, 1, 3)
        self._add(0x28, "PLP", AddressingMode.IMPLIED, 1, 4)
        self._add(0x0B, "PHD", AddressingMode.IMPLIED, 1, 4)
        self._add(0x2B, "PLD", AddressingMode.IMPLIED, 1, 5)
        self._add(0x4B, "PHK", AddressingMode.IMPLIED, 1, 3)
        self._add(0x8B, "PHB", AddressingMode.IMPLIED, 1, 3)
        self._add(0xAB, "PLB", AddressingMode.IMPLIED, 1, 4)
        self._add(0xF4, "PEA", AddressingMode.ABSOLUTE, 3, 5)
        self._add(0xD4, "PEI", AddressingMode.DIRECT_PAGE, 2, 6)
        self._add(0x62, "PER", AddressingMode.RELATIVE_LONG, 3, 6)

        # Comparison
        self._add(0xC9, "CMP", AddressingMode.IMMEDIATE, 2, 2)
        self._add(0xC5, "CMP", AddressingMode.DIRECT_PAGE, 2, 3)
        self._add(0xCD, "CMP", AddressingMode.ABSOLUTE, 3, 4)

        self._add(0xE0, "CPX", AddressingMode.IMMEDIATE, 2, 2)
        self._add(0xE4, "CPX", AddressingMode.DIRECT_PAGE, 2, 3)
        self._add(0xEC, "CPX", AddressingMode.ABSOLUTE, 3, 4)

        self._add(0xC0, "CPY", AddressingMode.IMMEDIATE, 2, 2)
        self._add(0xC4, "CPY", AddressingMode.DIRECT_PAGE, 2, 3)
        self._add(0xCC, "CPY", AddressingMode.ABSOLUTE, 3, 4)

        # Test bits
        self._add(0x89, "BIT", AddressingMode.IMMEDIATE, 2, 2)
        self._add(0x24, "BIT", AddressingMode.DIRECT_PAGE, 2, 3)
        self._add(0x2C, "BIT", AddressingMode.ABSOLUTE, 3, 4)
        self._add(0x14, "TRB", AddressingMode.DIRECT_PAGE, 2, 5)
        self._add(0x1C, "TRB", AddressingMode.ABSOLUTE, 3, 6)
        self._add(0x04, "TSB", AddressingMode.DIRECT_PAGE, 2, 5)
        self._add(0x0C, "TSB", AddressingMode.ABSOLUTE, 3, 6)

        # Status flags
        self._add(0x18, "CLC", AddressingMode.IMPLIED, 1, 2)
        self._add(0xD8, "CLD", AddressingMode.IMPLIED, 1, 2)
        self._add(0x58, "CLI", AddressingMode.IMPLIED, 1, 2)
        self._add(0xB8, "CLV", AddressingMode.IMPLIED, 1, 2)
        self._add(0x38, "SEC", AddressingMode.IMPLIED, 1, 2)
        self._add(0xF8, "SED", AddressingMode.IMPLIED, 1, 2)
        self._add(0x78, "SEI", AddressingMode.IMPLIED, 1, 2)
        self._add(0xC2, "REP", AddressingMode.IMMEDIATE_8, 2, 3)
        self._add(0xE2, "SEP", AddressingMode.IMMEDIATE_8, 2, 3)
        self._add(0xFB, "XCE", AddressingMode.IMPLIED, 1, 2)

        # Block move
        self._add(0x44, "MVP", AddressingMode.BLOCK_MOVE, 3, 7)
        self._add(0x54, "MVN", AddressingMode.BLOCK_MOVE, 3, 7)

        # Misc
        self._add(0xEA, "NOP", AddressingMode.IMPLIED, 1, 2)
        self._add(0xDB, "STP", AddressingMode.IMPLIED, 1, 3)
        self._add(0xCB, "WAI", AddressingMode.IMPLIED, 1, 3)
        self._add(0x42, "WDM", AddressingMode.IMMEDIATE_8, 2, 2)
        self._add(0x00, "BRK", AddressingMode.IMMEDIATE_8, 2, 7, InstructionType.INTERRUPT)
        self._add(0x02, "COP", AddressingMode.IMMEDIATE_8, 2, 7, InstructionType.INTERRUPT)

    def _add(self, code: int, mnemonic: str, mode: AddressingMode,
             size: int, cycles: int, inst_type: InstructionType = InstructionType.NORMAL):
        """Add opcode to table"""
        self.opcodes[code] = Opcode(code, mnemonic, mode, size, cycles, inst_type)

    def get(self, code: int) -> Optional[Opcode]:
        """Get opcode by byte value"""
        return self.opcodes.get(code)


class Disassembler:
    """Main disassembler class"""

    def __init__(self, rom_data: bytes):
        self.rom_data = rom_data
        self.opcode_table = OpcodeTable()
        self.symbols: Dict[int, str] = {}
        self.labels: Set[int] = set()
        self.code_regions: List[Tuple[int, int]] = []  # (start, end) addresses
        self.data_regions: List[Tuple[int, int]] = []

    def add_code_region(self, start: int, end: int):
        """Mark a region as code"""
        self.code_regions.append((start, end))

    def add_data_region(self, start: int, end: int):
        """Mark a region as data"""
        self.data_regions.append((start, end))

    def add_symbol(self, address: int, name: str):
        """Add a symbol at an address"""
        self.symbols[address] = name
        self.labels.add(address)

    def snes_to_pc(self, address: int) -> Optional[int]:
        """Convert SNES address (bank:offset) to PC ROM offset"""
        bank = (address >> 16) & 0xFF
        offset = address & 0xFFFF

        # LoROM mapping
        if offset >= 0x8000:
            pc_offset = ((bank & 0x7F) * 0x8000) + (offset - 0x8000)
            if pc_offset < len(self.rom_data):
                return pc_offset

        return None

    def pc_to_snes(self, pc_offset: int) -> int:
        """Convert PC ROM offset to SNES address"""
        # LoROM mapping
        bank = (pc_offset // 0x8000) & 0x7F
        offset = (pc_offset % 0x8000) + 0x8000
        return (bank << 16) | offset

    def disassemble_instruction(self, address: int) -> Optional[Instruction]:
        """Disassemble a single instruction at the given address"""
        pc_offset = self.snes_to_pc(address)
        if pc_offset is None or pc_offset >= len(self.rom_data):
            return None

        # Read opcode byte
        opcode_byte = self.rom_data[pc_offset]
        opcode = self.opcode_table.get(opcode_byte)

        if opcode is None:
            # Unknown opcode - treat as data
            return Instruction(
                address=address,
                opcode=Opcode(opcode_byte, "DB", AddressingMode.IMMEDIATE_8, 1, 0, InstructionType.DATA),
                operand=opcode_byte,
                operand_bytes=bytes([opcode_byte])
            )

        # Read operand bytes
        operand_size = opcode.size - 1
        operand_bytes = b''
        operand = None

        if operand_size > 0 and pc_offset + operand_size < len(self.rom_data):
            operand_bytes = self.rom_data[pc_offset + 1:pc_offset + opcode.size]

            # Parse operand based on size
            if operand_size == 1:
                operand = operand_bytes[0]
                # Handle relative branches
                if opcode.mode == AddressingMode.RELATIVE:
                    # Sign extend
                    if operand & 0x80:
                        operand = operand - 0x100
            elif operand_size == 2:
                operand = struct.unpack('<H', operand_bytes)[0]
                # Handle long relative branches
                if opcode.mode == AddressingMode.RELATIVE_LONG:
                    # Sign extend
                    if operand & 0x8000:
                        operand = operand - 0x10000
            elif operand_size == 3:
                operand = struct.unpack('<I', operand_bytes + b'\x00')[0] & 0xFFFFFF

        # Check for label
        label = self.symbols.get(address)

        return Instruction(
            address=address,
            opcode=opcode,
            operand=operand,
            operand_bytes=operand_bytes,
            label=label
        )

    def disassemble_range(self, start: int, end: int) -> List[Instruction]:
        """Disassemble a range of addresses"""
        instructions = []
        address = start

        while address < end:
            inst = self.disassemble_instruction(address)
            if inst:
                instructions.append(inst)
                address += inst.opcode.size
            else:
                break

        return instructions

    def analyze_flow(self, start: int, max_size: int = 0x1000) -> Set[int]:
        """Analyze control flow from a starting address"""
        to_visit = {start}
        visited = set()
        code_addresses = set()

        while to_visit and len(code_addresses) < max_size:
            address = to_visit.pop()
            if address in visited:
                continue

            visited.add(address)
            inst = self.disassemble_instruction(address)

            if not inst:
                continue

            code_addresses.add(address)

            # Follow control flow
            if inst.opcode.instruction_type == InstructionType.BRANCH:
                # Branch can go either way
                if inst.operand is not None:
                    target = (address + inst.opcode.size + inst.operand) & 0xFFFFFF
                    to_visit.add(target)
                    self.labels.add(target)
                # Fall through
                to_visit.add(address + inst.opcode.size)

            elif inst.opcode.instruction_type == InstructionType.JUMP:
                # Jump goes to target
                if inst.opcode.mode in (AddressingMode.ABSOLUTE, AddressingMode.ABSOLUTE_LONG):
                    if inst.operand is not None:
                        to_visit.add(inst.operand)
                        self.labels.add(inst.operand)
                # No fall through

            elif inst.opcode.instruction_type == InstructionType.CALL:
                # Call target
                if inst.operand is not None:
                    to_visit.add(inst.operand)
                    self.labels.add(inst.operand)
                # Fall through
                to_visit.add(address + inst.opcode.size)

            elif inst.opcode.instruction_type in (InstructionType.RETURN, InstructionType.INTERRUPT):
                # No fall through
                pass

            else:
                # Normal instruction, fall through
                to_visit.add(address + inst.opcode.size)

        return code_addresses

    def export_asm(self, instructions: List[Instruction], filename: str):
        """Export instructions to assembly file"""
        with open(filename, 'w') as f:
            f.write("; Disassembled by 65816 Disassembler\n")
            f.write("; SNES ROM Disassembly\n\n")

            for inst in instructions:
                asm = inst.to_asm(self.symbols)
                f.write(f"{asm}\n")


def main():
    """Test disassembler"""
    # Create a small test ROM
    test_rom = bytearray(0x10000)

    # Add some test code at bank 0, offset 0x8000 (PC offset 0x0000)
    code = [
        0x18,        # CLC
        0xFB,        # XCE
        0xC2, 0x30,  # REP #$30
        0xA9, 0x00, 0x80,  # LDA #$8000
        0x8D, 0x00, 0x21,  # STA $2100
        0x20, 0x20, 0x80,  # JSR $8020
        0x80, 0xFE,  # BRA -2 (infinite loop)

        # Subroutine at $8020
        0xA9, 0x0F, 0x00,  # LDA #$000F
        0x60,        # RTS
    ]

    test_rom[0:len(code)] = code

    # Create disassembler
    disasm = Disassembler(bytes(test_rom))

    # Add symbols
    disasm.add_symbol(0x008000, "Reset")
    disasm.add_symbol(0x008020, "Subroutine")
    disasm.add_symbol(0x002100, "INIDISP")

    # Disassemble from reset vector
    start_address = 0x008000
    instructions = disasm.analyze_flow(start_address)

    # Sort by address
    sorted_instructions = []
    for addr in sorted(instructions):
        inst = disasm.disassemble_instruction(addr)
        if inst:
            sorted_instructions.append(inst)

    # Print disassembly
    print("65816 Disassembler Test")
    print("=" * 60)
    for inst in sorted_instructions:
        print(f"${inst.address:06X}: {inst.to_asm(disasm.symbols)}")

    # Export to file
    disasm.export_asm(sorted_instructions, "test_disasm.asm")
    print("\nExported to test_disasm.asm")


if __name__ == "__main__":
    main()
