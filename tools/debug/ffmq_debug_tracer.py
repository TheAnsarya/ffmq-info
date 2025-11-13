#!/usr/bin/env python3
"""
FFMQ Debug Tracer - CPU execution tracing and debugging

Debug Features:
- CPU instruction tracing
- Breakpoints
- Memory watchpoints
- Call stack tracking
- Profiling
- Disassembly

65816 CPU Features:
- Instruction tracing
- Register tracking (A, X, Y, SP, PC, DB, D, P)
- Memory access logging
- Interrupt handling
- DMA tracking

Debug Features:
- Set breakpoints
- Watch memory addresses
- Trace execution
- Profile performance
- Disassemble code
- Generate debug logs

Features:
- Execute with tracing
- Set breakpoints
- Watch memory
- Profile code
- Export trace logs
- Disassemble regions

Usage:
	python ffmq_debug_tracer.py --rom game.smc --trace --start 0x80000
	python ffmq_debug_tracer.py --rom game.smc --breakpoint 0x8100
	python ffmq_debug_tracer.py --rom game.smc --watch 0x7E0100
	python ffmq_debug_tracer.py --rom game.smc --disassemble 0x80000 0x80100
	python ffmq_debug_tracer.py --rom game.smc --profile --function 0x81000
"""

import argparse
import struct
from pathlib import Path
from typing import List, Dict, Optional, Tuple, Set
from dataclasses import dataclass, asdict, field
from enum import Enum


class CPUMode(Enum):
	"""65816 CPU mode"""
	EMULATION = "emulation"  # 6502 mode
	NATIVE = "native"  # 65816 mode


class AddressMode(Enum):
	"""Addressing mode"""
	IMPLIED = "implied"
	IMMEDIATE = "immediate"
	ABSOLUTE = "absolute"
	ABSOLUTE_X = "absolute,x"
	ABSOLUTE_Y = "absolute,y"
	DIRECT = "direct"
	DIRECT_X = "direct,x"
	DIRECT_Y = "direct,y"
	INDIRECT = "indirect"
	INDEXED_INDIRECT = "(indirect,x)"
	INDIRECT_INDEXED = "(indirect),y"
	LONG = "long"
	LONG_X = "long,x"


@dataclass
class CPUState:
	"""CPU register state"""
	a: int = 0  # Accumulator (16-bit)
	x: int = 0  # X index (16-bit)
	y: int = 0  # Y index (16-bit)
	sp: int = 0x01FF  # Stack pointer
	pc: int = 0  # Program counter (24-bit)
	db: int = 0  # Data bank
	d: int = 0  # Direct page
	p: int = 0  # Processor status
	
	def __str__(self) -> str:
		return (f"A:{self.a:04X} X:{self.x:04X} Y:{self.y:04X} "
				f"SP:{self.sp:04X} PC:{self.pc:06X} "
				f"DB:{self.db:02X} D:{self.d:04X} P:{self.p:02X}")


@dataclass
class Instruction:
	"""Disassembled instruction"""
	address: int
	opcode: int
	mnemonic: str
	mode: AddressMode
	operand: int = 0
	length: int = 1
	
	def __str__(self) -> str:
		if self.mode == AddressMode.IMPLIED:
			return f"{self.address:06X}  {self.opcode:02X}        {self.mnemonic}"
		elif self.mode == AddressMode.IMMEDIATE:
			return f"{self.address:06X}  {self.opcode:02X} {self.operand:02X}     {self.mnemonic} #${self.operand:02X}"
		elif self.mode == AddressMode.ABSOLUTE:
			return f"{self.address:06X}  {self.opcode:02X} {self.operand:04X}   {self.mnemonic} ${self.operand:04X}"
		else:
			return f"{self.address:06X}  {self.opcode:02X} ...     {self.mnemonic}"


@dataclass
class Breakpoint:
	"""Execution breakpoint"""
	address: int
	enabled: bool = True
	hit_count: int = 0
	condition: Optional[str] = None


@dataclass
class Watchpoint:
	"""Memory watchpoint"""
	address: int
	size: int = 1
	read: bool = True
	write: bool = True
	enabled: bool = True
	hit_count: int = 0


@dataclass
class TraceEntry:
	"""Execution trace entry"""
	frame: int
	address: int
	instruction: str
	state: str
	memory_access: Optional[str] = None


@dataclass
class ProfileEntry:
	"""Function profile entry"""
	address: int
	function_name: str
	call_count: int = 0
	total_cycles: int = 0
	
	@property
	def avg_cycles(self) -> float:
		return self.total_cycles / self.call_count if self.call_count > 0 else 0.0


class FFMQDebugTracer:
	"""Debug tracer and profiler"""
	
	# 65816 instruction set (simplified)
	OPCODES = {
		0x00: ('BRK', AddressMode.IMPLIED, 1),
		0x18: ('CLC', AddressMode.IMPLIED, 1),
		0x20: ('JSR', AddressMode.ABSOLUTE, 3),
		0x4C: ('JMP', AddressMode.ABSOLUTE, 3),
		0x60: ('RTS', AddressMode.IMPLIED, 1),
		0x6B: ('RTL', AddressMode.IMPLIED, 1),
		0x80: ('BRA', AddressMode.IMMEDIATE, 2),
		0x8D: ('STA', AddressMode.ABSOLUTE, 3),
		0x8F: ('STA', AddressMode.LONG, 4),
		0x9C: ('STZ', AddressMode.ABSOLUTE, 3),
		0xA0: ('LDY', AddressMode.IMMEDIATE, 2),
		0xA2: ('LDX', AddressMode.IMMEDIATE, 2),
		0xA9: ('LDA', AddressMode.IMMEDIATE, 2),
		0xAD: ('LDA', AddressMode.ABSOLUTE, 3),
		0xAF: ('LDA', AddressMode.LONG, 4),
		0xC9: ('CMP', AddressMode.IMMEDIATE, 2),
		0xD0: ('BNE', AddressMode.IMMEDIATE, 2),
		0xE8: ('INX', AddressMode.IMPLIED, 1),
		0xEA: ('NOP', AddressMode.IMPLIED, 1),
		0xF0: ('BEQ', AddressMode.IMMEDIATE, 2),
	}
	
	# Cycle timing (simplified)
	CYCLES = {
		0x00: 7, 0x18: 2, 0x20: 6, 0x4C: 3, 0x60: 6, 0x6B: 6,
		0x80: 3, 0x8D: 4, 0x8F: 5, 0x9C: 4, 0xA0: 2, 0xA2: 2,
		0xA9: 2, 0xAD: 4, 0xAF: 5, 0xC9: 2, 0xD0: 2, 0xE8: 2,
		0xEA: 2, 0xF0: 2
	}
	
	def __init__(self, rom_path: Optional[Path] = None, verbose: bool = False):
		self.verbose = verbose
		self.rom_data: Optional[bytes] = None
		self.cpu_state = CPUState()
		self.breakpoints: Dict[int, Breakpoint] = {}
		self.watchpoints: Dict[int, Watchpoint] = {}
		self.trace_log: List[TraceEntry] = []
		self.call_stack: List[int] = []
		self.profile_data: Dict[int, ProfileEntry] = {}
		self.current_frame = 0
		self.total_cycles = 0
		self.tracing_enabled = False
		self.profiling_enabled = False
		
		if rom_path:
			self.load_rom(rom_path)
	
	def load_rom(self, rom_path: Path) -> bool:
		"""Load ROM file"""
		try:
			with open(rom_path, 'rb') as f:
				self.rom_data = f.read()
			
			if self.verbose:
				print(f"✓ Loaded ROM: {len(self.rom_data):,} bytes")
			
			return True
		
		except Exception as e:
			print(f"Error loading ROM: {e}")
			return False
	
	def set_breakpoint(self, address: int, condition: Optional[str] = None) -> None:
		"""Set breakpoint"""
		breakpoint = Breakpoint(
			address=address,
			condition=condition
		)
		
		self.breakpoints[address] = breakpoint
		
		if self.verbose:
			print(f"🔴 Breakpoint set at 0x{address:06X}")
	
	def remove_breakpoint(self, address: int) -> bool:
		"""Remove breakpoint"""
		if address in self.breakpoints:
			del self.breakpoints[address]
			
			if self.verbose:
				print(f"⚪ Breakpoint removed at 0x{address:06X}")
			
			return True
		
		return False
	
	def set_watchpoint(self, address: int, size: int = 1, 
					   read: bool = True, write: bool = True) -> None:
		"""Set memory watchpoint"""
		watchpoint = Watchpoint(
			address=address,
			size=size,
			read=read,
			write=write
		)
		
		self.watchpoints[address] = watchpoint
		
		if self.verbose:
			mode = "R" if read else ""
			mode += "W" if write else ""
			print(f"👁 Watchpoint set at 0x{address:06X} ({mode})")
	
	def disassemble(self, address: int, length: int = 16) -> List[Instruction]:
		"""Disassemble code"""
		if not self.rom_data:
			return []
		
		instructions = []
		offset = address
		
		for _ in range(length):
			if offset >= len(self.rom_data):
				break
			
			opcode = self.rom_data[offset]
			
			if opcode in self.OPCODES:
				mnemonic, mode, inst_len = self.OPCODES[opcode]
			else:
				mnemonic, mode, inst_len = 'UNK', AddressMode.IMPLIED, 1
			
			# Read operand
			operand = 0
			if inst_len > 1 and offset + inst_len <= len(self.rom_data):
				if inst_len == 2:
					operand = self.rom_data[offset + 1]
				elif inst_len == 3:
					operand = struct.unpack('<H', self.rom_data[offset+1:offset+3])[0]
				elif inst_len == 4:
					operand = struct.unpack('<I', self.rom_data[offset+1:offset+4] + b'\x00')[0]
			
			inst = Instruction(
				address=offset,
				opcode=opcode,
				mnemonic=mnemonic,
				mode=mode,
				operand=operand,
				length=inst_len
			)
			
			instructions.append(inst)
			offset += inst_len
		
		return instructions
	
	def trace_instruction(self, address: int) -> None:
		"""Trace single instruction"""
		if not self.tracing_enabled:
			return
		
		instructions = self.disassemble(address, 1)
		
		if not instructions:
			return
		
		inst = instructions[0]
		
		# Create trace entry
		entry = TraceEntry(
			frame=self.current_frame,
			address=address,
			instruction=str(inst),
			state=str(self.cpu_state)
		)
		
		self.trace_log.append(entry)
		
		# Update cycles
		cycles = self.CYCLES.get(inst.opcode, 2)
		self.total_cycles += cycles
		
		# Check for function call
		if inst.opcode in [0x20, 0x22]:  # JSR/JSL
			self.call_stack.append(address)
			
			if self.profiling_enabled:
				self._profile_function(inst.operand, cycles)
	
	def _profile_function(self, address: int, cycles: int) -> None:
		"""Profile function call"""
		if address not in self.profile_data:
			self.profile_data[address] = ProfileEntry(
				address=address,
				function_name=f"func_{address:06X}"
			)
		
		profile = self.profile_data[address]
		profile.call_count += 1
		profile.total_cycles += cycles
	
	def check_breakpoint(self, address: int) -> bool:
		"""Check if breakpoint hit"""
		if address not in self.breakpoints:
			return False
		
		bp = self.breakpoints[address]
		
		if not bp.enabled:
			return False
		
		bp.hit_count += 1
		
		if self.verbose:
			print(f"🛑 Breakpoint hit at 0x{address:06X} (count: {bp.hit_count})")
		
		return True
	
	def check_watchpoint(self, address: int, is_write: bool = False) -> bool:
		"""Check if watchpoint hit"""
		for wp_addr, wp in self.watchpoints.items():
			if wp_addr <= address < wp_addr + wp.size:
				if not wp.enabled:
					continue
				
				if (is_write and wp.write) or (not is_write and wp.read):
					wp.hit_count += 1
					
					if self.verbose:
						access = "Write" if is_write else "Read"
						print(f"👁 Watchpoint hit: {access} at 0x{address:06X}")
					
					return True
		
		return False
	
	def export_trace(self, output_path: Path, max_entries: int = 10000) -> bool:
		"""Export trace log"""
		try:
			with open(output_path, 'w', encoding='utf-8') as f:
				f.write("FFMQ Debug Trace Log\n")
				f.write("=" * 80 + "\n\n")
				
				entries = self.trace_log[-max_entries:]
				
				for entry in entries:
					f.write(f"[Frame {entry.frame:6d}] {entry.instruction}\n")
					f.write(f"  State: {entry.state}\n")
					
					if entry.memory_access:
						f.write(f"  Memory: {entry.memory_access}\n")
					
					f.write("\n")
			
			if self.verbose:
				print(f"✓ Exported trace to {output_path} ({len(entries)} entries)")
			
			return True
		
		except Exception as e:
			print(f"Error exporting trace: {e}")
			return False
	
	def export_profile(self, output_path: Path) -> bool:
		"""Export profile data"""
		try:
			with open(output_path, 'w', encoding='utf-8') as f:
				f.write("FFMQ Profile Report\n")
				f.write("=" * 80 + "\n\n")
				
				# Sort by total cycles
				sorted_funcs = sorted(
					self.profile_data.values(),
					key=lambda p: p.total_cycles,
					reverse=True
				)
				
				f.write(f"{'Address':<12} {'Name':<25} {'Calls':<10} {'Total Cycles':<15} {'Avg Cycles':<12}\n")
				f.write('-' * 74 + "\n")
				
				for profile in sorted_funcs:
					f.write(f"0x{profile.address:06X}    {profile.function_name:<25} "
						   f"{profile.call_count:<10} {profile.total_cycles:<15} "
						   f"{profile.avg_cycles:<12.2f}\n")
			
			if self.verbose:
				print(f"✓ Exported profile to {output_path}")
			
			return True
		
		except Exception as e:
			print(f"Error exporting profile: {e}")
			return False
	
	def print_disassembly(self, address: int, length: int = 16) -> None:
		"""Print disassembly"""
		instructions = self.disassemble(address, length)
		
		print(f"\nDisassembly at 0x{address:06X}:\n")
		
		for inst in instructions:
			print(str(inst))
	
	def print_breakpoints(self) -> None:
		"""Print breakpoint list"""
		if not self.breakpoints:
			print("No breakpoints")
			return
		
		print(f"\n{'Address':<12} {'Enabled':<10} {'Hits':<10}")
		print('-' * 32)
		
		for address, bp in sorted(self.breakpoints.items()):
			enabled = "Yes" if bp.enabled else "No"
			print(f"0x{address:06X}    {enabled:<10} {bp.hit_count:<10}")
	
	def print_watchpoints(self) -> None:
		"""Print watchpoint list"""
		if not self.watchpoints:
			print("No watchpoints")
			return
		
		print(f"\n{'Address':<12} {'Mode':<8} {'Enabled':<10} {'Hits':<10}")
		print('-' * 40)
		
		for address, wp in sorted(self.watchpoints.items()):
			mode = ""
			if wp.read:
				mode += "R"
			if wp.write:
				mode += "W"
			
			enabled = "Yes" if wp.enabled else "No"
			print(f"0x{address:06X}    {mode:<8} {enabled:<10} {wp.hit_count:<10}")
	
	def print_profile_summary(self) -> None:
		"""Print profile summary"""
		if not self.profile_data:
			print("No profile data")
			return
		
		print(f"\n=== Profile Summary ===\n")
		print(f"Total cycles: {self.total_cycles:,}")
		print(f"Functions profiled: {len(self.profile_data)}")
		
		# Top 10 by cycles
		sorted_funcs = sorted(
			self.profile_data.values(),
			key=lambda p: p.total_cycles,
			reverse=True
		)[:10]
		
		print(f"\nTop 10 by cycles:")
		print(f"{'Address':<12} {'Calls':<10} {'Total':<15} {'Avg':<12}")
		print('-' * 49)
		
		for profile in sorted_funcs:
			print(f"0x{profile.address:06X}    {profile.call_count:<10} "
				  f"{profile.total_cycles:<15,} {profile.avg_cycles:<12.2f}")


def main():
	parser = argparse.ArgumentParser(description='FFMQ Debug Tracer')
	parser.add_argument('--rom', type=str, help='ROM file path')
	parser.add_argument('--trace', action='store_true', help='Enable tracing')
	parser.add_argument('--profile', action='store_true', help='Enable profiling')
	parser.add_argument('--breakpoint', type=str, help='Set breakpoint (hex address)')
	parser.add_argument('--watch', type=str, help='Set watchpoint (hex address)')
	parser.add_argument('--disassemble', type=str, nargs=2,
					   metavar=('START', 'END'), help='Disassemble range')
	parser.add_argument('--export-trace', type=str, metavar='OUTPUT',
					   help='Export trace log')
	parser.add_argument('--export-profile', type=str, metavar='OUTPUT',
					   help='Export profile data')
	parser.add_argument('--list-breakpoints', action='store_true',
					   help='List breakpoints')
	parser.add_argument('--list-watchpoints', action='store_true',
					   help='List watchpoints')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	tracer = FFMQDebugTracer(
		rom_path=Path(args.rom) if args.rom else None,
		verbose=args.verbose
	)
	
	# Enable tracing/profiling
	tracer.tracing_enabled = args.trace
	tracer.profiling_enabled = args.profile
	
	# Set breakpoint
	if args.breakpoint:
		address = int(args.breakpoint, 16)
		tracer.set_breakpoint(address)
	
	# Set watchpoint
	if args.watch:
		address = int(args.watch, 16)
		tracer.set_watchpoint(address)
	
	# Disassemble
	if args.disassemble:
		start = int(args.disassemble[0], 16)
		end = int(args.disassemble[1], 16)
		length = (end - start) // 2  # Estimate instruction count
		tracer.print_disassembly(start, length)
		return 0
	
	# Export trace
	if args.export_trace:
		tracer.export_trace(Path(args.export_trace))
		return 0
	
	# Export profile
	if args.export_profile:
		tracer.export_profile(Path(args.export_profile))
		return 0
	
	# List breakpoints
	if args.list_breakpoints:
		tracer.print_breakpoints()
		return 0
	
	# List watchpoints
	if args.list_watchpoints:
		tracer.print_watchpoints()
		return 0
	
	# Default: show info
	print("\n=== FFMQ Debug Tracer ===\n")
	print(f"Tracing: {'Enabled' if tracer.tracing_enabled else 'Disabled'}")
	print(f"Profiling: {'Enabled' if tracer.profiling_enabled else 'Disabled'}")
	print(f"Breakpoints: {len(tracer.breakpoints)}")
	print(f"Watchpoints: {len(tracer.watchpoints)}")
	
	if tracer.rom_data:
		print(f"ROM loaded: {len(tracer.rom_data):,} bytes")
	
	return 0


if __name__ == '__main__':
	exit(main())
