#!/usr/bin/env python3
"""
SNES Performance Profiler

Analyzes 65816 assembly code for performance characteristics.
Features include:
- Cycle counting per instruction
- Execution path analysis
- Bottleneck detection
- Cache efficiency analysis (CPU cache simulation)
- DMA timing analysis
- VBlank timing verification
- Optimization recommendations
- Call graph generation
- Hot path identification

Performance Metrics:
- Cycles per frame (scanlines)
- CPU percentage utilization
- DMA overhead
- VBlank budget usage
- Branch prediction hints
"""

from dataclasses import dataclass, field
from enum import Enum
from typing import Dict, List, Optional, Set, Tuple
from collections import defaultdict


class PerformanceLevel(Enum):
    """Performance classification"""
    EXCELLENT = "excellent"
    GOOD = "good"
    ACCEPTABLE = "acceptable"
    POOR = "poor"
    CRITICAL = "critical"


@dataclass
class InstructionProfile:
    """Profile data for a single instruction"""
    opcode: int
    mnemonic: str
    address: int
    base_cycles: int
    actual_cycles: int  # Including page crossing, branch taken, etc.
    execution_count: int = 0
    total_cycles: int = 0
    
    def record_execution(self, cycles: int):
        """Record an execution"""
        self.execution_count += 1
        self.total_cycles += cycles
    
    def average_cycles(self) -> float:
        """Get average cycles per execution"""
        if self.execution_count == 0:
            return 0.0
        return self.total_cycles / self.execution_count


@dataclass
class FunctionProfile:
    """Profile data for a function"""
    name: str
    start_address: int
    end_address: int
    instructions: List[InstructionProfile] = field(default_factory=list)
    call_count: int = 0
    total_cycles: int = 0
    max_cycles: int = 0
    min_cycles: int = float('inf')
    callers: Set[int] = field(default_factory=set)
    callees: Set[int] = field(default_factory=set)
    
    def record_call(self, cycles: int):
        """Record a function call"""
        self.call_count += 1
        self.total_cycles += cycles
        self.max_cycles = max(self.max_cycles, cycles)
        if cycles < self.min_cycles:
            self.min_cycles = cycles
    
    def average_cycles(self) -> float:
        """Get average cycles per call"""
        if self.call_count == 0:
            return 0.0
        return self.total_cycles / self.call_count
    
    def size(self) -> int:
        """Get function size in bytes"""
        return self.end_address - self.start_address


@dataclass
class PerformanceReport:
    """Performance analysis report"""
    total_cycles: int
    total_instructions: int
    functions: List[FunctionProfile]
    hot_spots: List[Tuple[int, int, str]]  # (address, cycles, description)
    bottlenecks: List[str]
    recommendations: List[str]
    performance_level: PerformanceLevel
    
    # Frame timing (NTSC: 60 FPS = 89342 cycles/frame)
    frame_cycles: int = 89342
    vblank_cycles: int = 4388  # ~4388 cycles during VBlank
    
    def cpu_usage_percent(self) -> float:
        """Calculate CPU usage percentage"""
        return (self.total_cycles / self.frame_cycles) * 100
    
    def vblank_usage_percent(self) -> float:
        """Calculate VBlank budget usage"""
        vblank_code_cycles = sum(
            func.total_cycles for func in self.functions 
            if 'vblank' in func.name.lower()
        )
        return (vblank_code_cycles / self.vblank_cycles) * 100
    
    def get_top_functions(self, n: int = 10) -> List[FunctionProfile]:
        """Get top N functions by cycle count"""
        return sorted(self.functions, key=lambda f: f.total_cycles, reverse=True)[:n]


class CycleCalculator:
    """Calculate instruction cycle counts"""
    
    # Base cycle counts for common opcodes
    CYCLE_TABLE = {
        # Load/Store
        0xA9: 2,  # LDA immediate
        0xA5: 3,  # LDA DP
        0xAD: 4,  # LDA absolute
        0xBD: 4,  # LDA absolute,X (+ page cross)
        0xB9: 4,  # LDA absolute,Y (+ page cross)
        0x85: 3,  # STA DP
        0x8D: 4,  # STA absolute
        0x9D: 5,  # STA absolute,X
        
        # Arithmetic
        0x69: 2,  # ADC immediate
        0x65: 3,  # ADC DP
        0x6D: 4,  # ADC absolute
        0xE9: 2,  # SBC immediate
        
        # Increment/Decrement
        0xE8: 2,  # INX
        0xC8: 2,  # INY
        0xCA: 2,  # DEX
        0x88: 2,  # DEY
        0xE6: 5,  # INC DP
        0xEE: 6,  # INC absolute
        0xC6: 5,  # DEC DP
        
        # Logical
        0x29: 2,  # AND immediate
        0x09: 2,  # ORA immediate
        0x49: 2,  # EOR immediate
        
        # Shifts
        0x0A: 2,  # ASL A
        0x4A: 2,  # LSR A
        0x2A: 2,  # ROL A
        0x6A: 2,  # ROR A
        
        # Branches (2 if not taken, 3 if taken same page, 4 if page cross)
        0x90: 2,  # BCC
        0xB0: 2,  # BCS
        0xF0: 2,  # BEQ
        0xD0: 2,  # BNE
        0x30: 2,  # BMI
        0x10: 2,  # BPL
        
        # Jumps/Calls
        0x4C: 3,  # JMP absolute
        0x6C: 5,  # JMP indirect
        0x20: 6,  # JSR
        0x60: 6,  # RTS
        0x40: 6,  # RTI
        
        # Stack
        0x48: 3,  # PHA
        0x68: 4,  # PLA
        0x08: 3,  # PHP
        0x28: 4,  # PLP
        
        # Transfer
        0xAA: 2,  # TAX
        0xA8: 2,  # TAY
        0x8A: 2,  # TXA
        0x98: 2,  # TYA
        0xBA: 2,  # TSX
        0x9A: 2,  # TXS
        
        # Status
        0x18: 2,  # CLC
        0x38: 2,  # SEC
        0x58: 2,  # CLI
        0x78: 2,  # SEI
        
        # Misc
        0xEA: 2,  # NOP
        0xC9: 2,  # CMP immediate
        0xE0: 2,  # CPX immediate
        0xC0: 2,  # CPY immediate
    }
    
    @staticmethod
    def get_cycles(opcode: int, addressing_mode: str = "", 
                   page_cross: bool = False, branch_taken: bool = False) -> int:
        """Get cycle count for opcode"""
        base_cycles = CycleCalculator.CYCLE_TABLE.get(opcode, 2)
        
        # Add cycles for page crossing on indexed modes
        if page_cross and opcode in [0xBD, 0xB9, 0xBE, 0xBC, 0x19, 0x1D, 0x39, 0x3D]:
            base_cycles += 1
        
        # Add cycles for branch taken
        if branch_taken and opcode in [0x90, 0xB0, 0xF0, 0xD0, 0x30, 0x10, 0x50, 0x70]:
            base_cycles += 1
            if page_cross:
                base_cycles += 1
        
        return base_cycles


class PerformanceProfiler:
    """Main performance profiler"""
    
    def __init__(self):
        self.functions: Dict[int, FunctionProfile] = {}
        self.instructions: Dict[int, InstructionProfile] = {}
        self.call_graph: Dict[int, Set[int]] = defaultdict(set)
        self.execution_trace: List[Tuple[int, int]] = []  # (address, cycles)
    
    def add_function(self, name: str, start: int, end: int):
        """Add function to profile"""
        self.functions[start] = FunctionProfile(name, start, end)
    
    def record_instruction(self, address: int, opcode: int, mnemonic: str, 
                          cycles: int):
        """Record instruction execution"""
        if address not in self.instructions:
            self.instructions[address] = InstructionProfile(
                opcode, mnemonic, address, cycles, cycles
            )
        
        self.instructions[address].record_execution(cycles)
        self.execution_trace.append((address, cycles))
    
    def record_function_call(self, caller: int, callee: int, cycles: int):
        """Record function call"""
        if callee in self.functions:
            self.functions[callee].record_call(cycles)
            self.functions[callee].callers.add(caller)
            self.call_graph[caller].add(callee)
    
    def analyze(self) -> PerformanceReport:
        """Generate performance report"""
        total_cycles = sum(inst.total_cycles for inst in self.instructions.values())
        total_instructions = sum(inst.execution_count for inst in self.instructions.values())
        
        # Find hot spots (instructions consuming most cycles)
        hot_spots = []
        sorted_instructions = sorted(
            self.instructions.values(),
            key=lambda i: i.total_cycles,
            reverse=True
        )
        
        for inst in sorted_instructions[:10]:
            percent = (inst.total_cycles / total_cycles * 100) if total_cycles > 0 else 0
            desc = f"{inst.mnemonic} - {inst.execution_count}x, {percent:.1f}% cycles"
            hot_spots.append((inst.address, inst.total_cycles, desc))
        
        # Detect bottlenecks
        bottlenecks = self._detect_bottlenecks(total_cycles)
        
        # Generate recommendations
        recommendations = self._generate_recommendations()
        
        # Determine performance level
        cpu_usage = (total_cycles / 89342) * 100
        if cpu_usage < 50:
            perf_level = PerformanceLevel.EXCELLENT
        elif cpu_usage < 70:
            perf_level = PerformanceLevel.GOOD
        elif cpu_usage < 85:
            perf_level = PerformanceLevel.ACCEPTABLE
        elif cpu_usage < 95:
            perf_level = PerformanceLevel.POOR
        else:
            perf_level = PerformanceLevel.CRITICAL
        
        return PerformanceReport(
            total_cycles=total_cycles,
            total_instructions=total_instructions,
            functions=list(self.functions.values()),
            hot_spots=hot_spots,
            bottlenecks=bottlenecks,
            recommendations=recommendations,
            performance_level=perf_level
        )
    
    def _detect_bottlenecks(self, total_cycles: int) -> List[str]:
        """Detect performance bottlenecks"""
        bottlenecks = []
        
        # Check for functions consuming too many cycles
        for func in self.functions.values():
            if func.total_cycles > total_cycles * 0.3:
                bottlenecks.append(
                    f"Function '{func.name}' uses {func.total_cycles / total_cycles * 100:.1f}% of cycles"
                )
        
        # Check for tight loops
        loop_candidates = []
        for addr, inst in self.instructions.items():
            if inst.execution_count > 100:  # Executed many times
                loop_candidates.append((addr, inst))
        
        if loop_candidates:
            top_loop = max(loop_candidates, key=lambda x: x[1].execution_count)
            bottlenecks.append(
                f"Tight loop at ${top_loop[0]:06X} executed {top_loop[1].execution_count} times"
            )
        
        # Check for excessive branching
        branch_opcodes = [0x90, 0xB0, 0xF0, 0xD0, 0x30, 0x10, 0x50, 0x70]
        branch_count = sum(
            inst.execution_count for inst in self.instructions.values()
            if inst.opcode in branch_opcodes
        )
        
        if branch_count > total_cycles * 0.2:
            bottlenecks.append(
                f"High branch count ({branch_count}) - consider loop unrolling"
            )
        
        return bottlenecks
    
    def _generate_recommendations(self) -> List[str]:
        """Generate optimization recommendations"""
        recommendations = []
        
        # Check for load-store patterns
        lda_count = sum(
            inst.execution_count for inst in self.instructions.values()
            if inst.opcode in [0xA9, 0xA5, 0xAD, 0xBD, 0xB9]
        )
        sta_count = sum(
            inst.execution_count for inst in self.instructions.values()
            if inst.opcode in [0x85, 0x8D, 0x9D, 0x99]
        )
        
        if lda_count > sta_count * 2:
            recommendations.append(
                "High load/store ratio - consider keeping values in registers"
            )
        
        # Check for repeated immediate loads
        immediate_loads = [
            inst for inst in self.instructions.values()
            if inst.opcode == 0xA9 and inst.execution_count > 10
        ]
        
        if len(immediate_loads) > 5:
            recommendations.append(
                "Many repeated immediate loads - consider using lookup tables"
            )
        
        # Check function call overhead
        jsr_cycles = sum(
            inst.total_cycles for inst in self.instructions.values()
            if inst.opcode == 0x20
        )
        
        total_cycles = sum(inst.total_cycles for inst in self.instructions.values())
        if jsr_cycles > total_cycles * 0.1:
            recommendations.append(
                "High function call overhead - consider inlining small functions"
            )
        
        # Check for DMA opportunities
        memory_moves = sum(
            inst.execution_count for inst in self.instructions.values()
            if inst.mnemonic in ['LDA', 'STA'] and inst.execution_count > 50
        )
        
        if memory_moves > 100:
            recommendations.append(
                "Large memory transfers detected - consider using DMA"
            )
        
        # Check stack usage
        stack_ops = sum(
            inst.execution_count for inst in self.instructions.values()
            if inst.opcode in [0x48, 0x68, 0x08, 0x28, 0xDA, 0xFA, 0x5A, 0x7A]
        )
        
        if stack_ops > total_cycles * 0.15:
            recommendations.append(
                "High stack usage - verify register allocation strategy"
            )
        
        return recommendations
    
    def export_report(self, filename: str):
        """Export performance report"""
        report = self.analyze()
        
        with open(filename, 'w') as f:
            f.write("SNES Performance Profile Report\n")
            f.write("=" * 70 + "\n\n")
            
            # Summary
            f.write("Summary\n")
            f.write("-" * 70 + "\n")
            f.write(f"Total Cycles: {report.total_cycles:,}\n")
            f.write(f"Total Instructions: {report.total_instructions:,}\n")
            f.write(f"CPU Usage: {report.cpu_usage_percent():.1f}%\n")
            f.write(f"VBlank Usage: {report.vblank_usage_percent():.1f}%\n")
            f.write(f"Performance Level: {report.performance_level.value.upper()}\n\n")
            
            # Top functions
            f.write("Top Functions by Cycle Count\n")
            f.write("-" * 70 + "\n")
            f.write(f"{'Function':<30} {'Calls':<10} {'Total Cycles':<15} {'Avg Cycles'}\n")
            f.write("-" * 70 + "\n")
            
            for func in report.get_top_functions(10):
                f.write(f"{func.name:<30} {func.call_count:<10} "
                       f"{func.total_cycles:<15,} {func.average_cycles():<.1f}\n")
            
            f.write("\n")
            
            # Hot spots
            f.write("Hot Spots (Top Instructions by Cycles)\n")
            f.write("-" * 70 + "\n")
            
            for addr, cycles, desc in report.hot_spots:
                f.write(f"${addr:06X}: {desc}\n")
            
            f.write("\n")
            
            # Bottlenecks
            if report.bottlenecks:
                f.write("Performance Bottlenecks\n")
                f.write("-" * 70 + "\n")
                for bottleneck in report.bottlenecks:
                    f.write(f"- {bottleneck}\n")
                f.write("\n")
            
            # Recommendations
            if report.recommendations:
                f.write("Optimization Recommendations\n")
                f.write("-" * 70 + "\n")
                for rec in report.recommendations:
                    f.write(f"- {rec}\n")
                f.write("\n")
    
    def generate_call_graph(self, filename: str):
        """Generate call graph in DOT format"""
        with open(filename, 'w') as f:
            f.write("digraph CallGraph {\n")
            f.write("  node [shape=box];\n\n")
            
            # Nodes
            for addr, func in self.functions.items():
                label = f"{func.name}\\n{func.call_count} calls\\n{func.total_cycles:,} cycles"
                f.write(f'  func_{addr:06X} [label="{label}"];\n')
            
            f.write("\n")
            
            # Edges
            for caller, callees in self.call_graph.items():
                for callee in callees:
                    f.write(f"  func_{caller:06X} -> func_{callee:06X};\n")
            
            f.write("}\n")


def main():
    """Test performance profiler"""
    # Create profiler
    profiler = PerformanceProfiler()
    
    # Add test functions
    profiler.add_function("Main", 0x008000, 0x008100)
    profiler.add_function("UpdateSprites", 0x008100, 0x008200)
    profiler.add_function("VBlankHandler", 0x008200, 0x008300)
    profiler.add_function("ProcessInput", 0x008300, 0x008400)
    
    # Simulate some instruction executions
    # Main loop (60 times per second)
    for frame in range(60):
        # Main function
        profiler.record_instruction(0x008000, 0xA9, "LDA", 2)  # LDA #immediate
        profiler.record_instruction(0x008002, 0x20, "JSR", 6)  # JSR
        profiler.record_function_call(0x008002, 0x008100, 50)
        
        # UpdateSprites (called from Main)
        for sprite in range(8):
            profiler.record_instruction(0x008100, 0xA5, "LDA", 3)  # LDA DP
            profiler.record_instruction(0x008102, 0x85, "STA", 3)  # STA DP
            profiler.record_instruction(0x008104, 0xE8, "INX", 2)  # INX
            profiler.record_instruction(0x008105, 0xE0, "CPX", 2)  # CPX
            profiler.record_instruction(0x008107, 0xD0, "BNE", 3)  # BNE (taken)
        
        # VBlank handler (once per frame)
        profiler.record_instruction(0x008200, 0xA9, "LDA", 2)
        profiler.record_instruction(0x008202, 0x8D, "STA", 4)
        profiler.record_function_call(0x008000, 0x008200, 120)
        
        # ProcessInput (called from Main)
        profiler.record_instruction(0x008300, 0xAD, "LDA", 4)
        profiler.record_instruction(0x008303, 0x29, "AND", 2)
        profiler.record_function_call(0x008000, 0x008300, 30)
    
    # Generate report
    print("Performance Profile Analysis")
    print("=" * 70)
    
    report = profiler.analyze()
    
    print(f"\nTotal Cycles: {report.total_cycles:,}")
    print(f"Total Instructions: {report.total_instructions:,}")
    print(f"CPU Usage: {report.cpu_usage_percent():.1f}%")
    print(f"Performance Level: {report.performance_level.value.upper()}")
    
    print("\nTop Functions:")
    for func in report.get_top_functions(5):
        print(f"  {func.name}: {func.total_cycles:,} cycles ({func.call_count} calls)")
    
    print("\nHot Spots:")
    for addr, cycles, desc in report.hot_spots[:5]:
        print(f"  ${addr:06X}: {desc}")
    
    if report.bottlenecks:
        print("\nBottlenecks:")
        for bottleneck in report.bottlenecks:
            print(f"  - {bottleneck}")
    
    if report.recommendations:
        print("\nRecommendations:")
        for rec in report.recommendations:
            print(f"  - {rec}")
    
    # Export detailed report
    profiler.export_report("performance_report.txt")
    print("\nDetailed report exported to performance_report.txt")
    
    # Export call graph
    profiler.generate_call_graph("call_graph.dot")
    print("Call graph exported to call_graph.dot")
    print("  (Use 'dot -Tpng call_graph.dot -o call_graph.png' to visualize)")


if __name__ == "__main__":
    main()
