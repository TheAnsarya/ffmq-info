#!/usr/bin/env python3
"""
AI-Assisted 65816 Code Generator

Intelligent code generation tool for SNES 65816 assembly.
Features include:
- Pseudocode to assembly translation
- Code snippet library with intelligent search
- Pattern-based code generation
- Optimization suggestions
- Register allocation assistance
- Common routine templates
- Macro expansion system
- Code analysis and recommendations

Pseudocode Examples:
- "set HP to 100" → LDA #100 / STA $HP_Address
- "if player level > 10" → LDA $Level / CMP #10 / BCC skip
- "loop 8 times" → LDX #8 / loop: ... / DEX / BNE loop
"""

from dataclasses import dataclass
from enum import Enum
from typing import Dict, List, Optional, Tuple
import re


class CodePattern(Enum):
	"""Common code patterns"""
	VARIABLE_SET = "var_set"
	VARIABLE_INC = "var_inc"
	VARIABLE_DEC = "var_dec"
	CONDITION_IF = "condition_if"
	CONDITION_ELSE = "condition_else"
	LOOP_COUNTED = "loop_counted"
	LOOP_WHILE = "loop_while"
	LOOP_FOREACH = "loop_foreach"
	CALL_FUNCTION = "call_function"
	RETURN = "return"
	MATH_ADD = "math_add"
	MATH_SUB = "math_sub"
	MATH_MUL = "math_mul"
	MATH_DIV = "math_div"
	BIT_SET = "bit_set"
	BIT_CLEAR = "bit_clear"
	BIT_TEST = "bit_test"
	MEMORY_COPY = "memory_copy"
	MEMORY_FILL = "memory_fill"


@dataclass
class CodeTemplate:
	"""Template for code generation"""
	name: str
	pattern: CodePattern
	description: str
	parameters: List[str]
	code_template: str
	example: str

	def generate(self, **kwargs) -> str:
		"""Generate code from template"""
		code = self.code_template

		# Substitute parameters
		for param, value in kwargs.items():
			placeholder = f"{{{param}}}"
			code = code.replace(placeholder, str(value))

		return code


@dataclass
class CodeSnippet:
	"""Reusable code snippet"""
	name: str
	description: str
	code: str
	tags: List[str]
	complexity: str  # "simple", "moderate", "complex"


@dataclass
class OptimizationSuggestion:
	"""Code optimization suggestion"""
	line_number: int
	original_code: str
	suggested_code: str
	reason: str
	cycles_saved: int


class CodeLibrary:
	"""Library of code snippets and patterns"""

	def __init__(self):
		self.snippets: List[CodeSnippet] = []
		self.templates: Dict[CodePattern, List[CodeTemplate]] = {}
		self._init_library()

	def _init_library(self):
		"""Initialize code library"""
		# Math snippets
		self.add_snippet(CodeSnippet(
			name="Multiply by 2",
			description="Multiply accumulator by 2 (fast)",
			code="ASL A  ; A = A * 2",
			tags=["math", "multiplication", "optimization"],
			complexity="simple"
		))

		self.add_snippet(CodeSnippet(
			name="Divide by 2",
			description="Divide accumulator by 2 (fast)",
			code="LSR A  ; A = A / 2",
			tags=["math", "division", "optimization"],
			complexity="simple"
		))

		self.add_snippet(CodeSnippet(
			name="Multiply 8-bit",
			description="Multiply A by value in X (result in A)",
			code="""
; Multiply A * X → A (8-bit)
	STA $00		; Store multiplicand
	STX $01		; Store multiplier
	LDA #0		 ; Clear accumulator
	LDX $01		; Load counter
	BEQ .done	  ; Skip if X=0
.loop:
	CLC
	ADC $00		; Add multiplicand
	DEX
	BNE .loop	  ; Loop until done
.done:
			""".strip(),
			tags=["math", "multiplication", "8bit"],
			complexity="moderate"
		))

		# Loop snippets
		self.add_snippet(CodeSnippet(
			name="Counted Loop",
			description="Loop N times using X register",
			code="""
	LDX #COUNT	 ; Load loop counter
.loop:
	; Loop body here
	DEX
	BNE .loop	  ; Loop while X != 0
			""".strip(),
			tags=["loop", "control"],
			complexity="simple"
		))

		self.add_snippet(CodeSnippet(
			name="Memory Copy",
			description="Copy N bytes from source to destination",
			code="""
	LDX #0		 ; Initialize index
.loop:
	LDA SOURCE,X   ; Read byte
	STA DEST,X	 ; Write byte
	INX
	CPX #COUNT	 ; Check if done
	BNE .loop
			""".strip(),
			tags=["memory", "copy", "loop"],
			complexity="moderate"
		))

		# Condition snippets
		self.add_snippet(CodeSnippet(
			name="Compare and Branch",
			description="If A >= value, branch to label",
			code="""
	CMP #VALUE	 ; Compare with value
	BCS .greater   ; Branch if >= (carry set)
	; Less than code here
	BRA .done
.greater:
	; Greater/equal code here
.done:
			""".strip(),
			tags=["condition", "branch", "compare"],
			complexity="simple"
		))

		# DMA snippet
		self.add_snippet(CodeSnippet(
			name="DMA Transfer",
			description="Setup and execute DMA transfer",
			code="""
	LDA #%00000001 ; DMA mode (1 register, 2 addresses)
	STA $4300	  ; DMA control
	LDA #$18	   ; Destination: VRAM data ($2118)
	STA $4301	  ; DMA destination
	LDA #<SOURCE   ; Source address low
	STA $4302
	LDA #>SOURCE   ; Source address high
	STA $4303
	LDA #^SOURCE   ; Source bank
	STA $4304
	LDA #<SIZE	 ; Transfer size low
	STA $4305
	LDA #>SIZE	 ; Transfer size high
	STA $4306
	LDA #$01	   ; Enable DMA channel 0
	STA $420B	  ; Start transfer
			""".strip(),
			tags=["dma", "transfer", "graphics", "advanced"],
			complexity="complex"
		))

		# Initialize templates
		self._init_templates()

	def _init_templates(self):
		"""Initialize code templates"""
		# Variable set template
		self.add_template(CodeTemplate(
			name="Set Variable (8-bit)",
			pattern=CodePattern.VARIABLE_SET,
			description="Set a variable to a value",
			parameters=["variable", "value"],
			code_template="""LDA #{value}
STA {variable}  ; Set {variable} = {value}""",
			example="set HP to 100"
		))

		self.add_template(CodeTemplate(
			name="Set Variable (16-bit)",
			pattern=CodePattern.VARIABLE_SET,
			description="Set a 16-bit variable",
			parameters=["variable", "value"],
			code_template="""REP #$20	   ; 16-bit A
LDA #{value}
STA {variable}
SEP #$20	   ; 8-bit A""",
			example="set MaxHP to 9999"
		))

		# Increment template
		self.add_template(CodeTemplate(
			name="Increment Variable",
			pattern=CodePattern.VARIABLE_INC,
			description="Increment a variable by 1",
			parameters=["variable"],
			code_template="""INC {variable}  ; {variable}++""",
			example="increment counter"
		))

		# Condition template
		self.add_template(CodeTemplate(
			name="If Greater Than",
			pattern=CodePattern.CONDITION_IF,
			description="Conditional branch if variable > value",
			parameters=["variable", "value", "label"],
			code_template="""LDA {variable}
CMP #{value}
BEQ .skip_{label}  ; Skip if equal
BCC .skip_{label}  ; Skip if less
; Code if {variable} > {value}
.skip_{label}:""",
			example="if level > 10"
		))

		# Loop template
		self.add_template(CodeTemplate(
			name="Counted Loop",
			pattern=CodePattern.LOOP_COUNTED,
			description="Loop a specific number of times",
			parameters=["count", "label"],
			code_template="""LDX #{count}
.loop_{label}:
	; Loop body here
	DEX
	BNE .loop_{label}""",
			example="loop 8 times"
		))

		# Math add template
		self.add_template(CodeTemplate(
			name="Add to Variable",
			pattern=CodePattern.MATH_ADD,
			description="Add value to variable",
			parameters=["variable", "value"],
			code_template="""LDA {variable}
CLC
ADC #{value}
STA {variable}  ; {variable} += {value}""",
			example="add 10 to score"
		))

		# Bit set template
		self.add_template(CodeTemplate(
			name="Set Bit",
			pattern=CodePattern.BIT_SET,
			description="Set a specific bit in a variable",
			parameters=["variable", "bit"],
			code_template="""LDA {variable}
ORA #(1<<{bit})
STA {variable}  ; Set bit {bit}""",
			example="set bit 3"
		))

		# Memory copy template
		self.add_template(CodeTemplate(
			name="Copy Memory Block",
			pattern=CodePattern.MEMORY_COPY,
			description="Copy block of memory",
			parameters=["source", "dest", "size"],
			code_template="""LDX #0
.copy_loop:
	LDA {source},X
	STA {dest},X
	INX
	CPX #{size}
	BNE .copy_loop""",
			example="copy 16 bytes from source to dest"
		))

	def add_snippet(self, snippet: CodeSnippet):
		"""Add code snippet to library"""
		self.snippets.append(snippet)

	def add_template(self, template: CodeTemplate):
		"""Add code template"""
		if template.pattern not in self.templates:
			self.templates[template.pattern] = []
		self.templates[template.pattern].append(template)

	def search_snippets(self, query: str) -> List[CodeSnippet]:
		"""Search snippets by name, description, or tags"""
		query_lower = query.lower()
		results = []

		for snippet in self.snippets:
			if query_lower in snippet.name.lower():
				results.append(snippet)
			elif query_lower in snippet.description.lower():
				results.append(snippet)
			elif any(query_lower in tag for tag in snippet.tags):
				results.append(snippet)

		return results

	def get_template(self, pattern: CodePattern) -> Optional[CodeTemplate]:
		"""Get first template for pattern"""
		templates = self.templates.get(pattern, [])
		return templates[0] if templates else None


class PseudocodeParser:
	"""Parse pseudocode and generate assembly"""

	def __init__(self, library: CodeLibrary):
		self.library = library
		self.label_counter = 0

	def generate_label(self, prefix: str = "label") -> str:
		"""Generate unique label"""
		self.label_counter += 1
		return f"{prefix}_{self.label_counter}"

	def parse(self, pseudocode: str) -> str:
		"""Parse pseudocode and generate assembly"""
		lines = pseudocode.strip().split('\n')
		assembly_lines = []

		for line in lines:
			line = line.strip()
			if not line:
				continue

			asm = self._parse_line(line)
			if asm:
				assembly_lines.append(asm)

		return '\n'.join(assembly_lines)

	def _parse_line(self, line: str) -> Optional[str]:
		"""Parse single pseudocode line"""
		line_lower = line.lower()

		# Set variable: "set X to Y"
		match = re.match(r'set\s+(\w+)\s+to\s+(.+)', line_lower)
		if match:
			var = match.group(1)
			value = match.group(2)

			# Try to parse value as number
			try:
				if value.startswith('0x'):
					num_value = int(value, 16)
				else:
					num_value = int(value)
				value_str = f"${num_value:02X}"
			except:
				value_str = value

			template = self.library.get_template(CodePattern.VARIABLE_SET)
			if template:
				return template.generate(variable=var, value=value_str)

		# Increment: "increment X"
		match = re.match(r'increment\s+(\w+)', line_lower)
		if match:
			var = match.group(1)
			template = self.library.get_template(CodePattern.VARIABLE_INC)
			if template:
				return template.generate(variable=var)

		# Add: "add X to Y"
		match = re.match(r'add\s+(.+)\s+to\s+(\w+)', line_lower)
		if match:
			value = match.group(1)
			var = match.group(2)

			try:
				num_value = int(value)
				value_str = f"${num_value:02X}"
			except:
				value_str = value

			template = self.library.get_template(CodePattern.MATH_ADD)
			if template:
				return template.generate(variable=var, value=value_str)

		# Loop: "loop X times"
		match = re.match(r'loop\s+(\d+)\s+times', line_lower)
		if match:
			count = match.group(1)
			label = self.generate_label("loop")
			template = self.library.get_template(CodePattern.LOOP_COUNTED)
			if template:
				return template.generate(count=count, label=label)

		# If condition: "if X > Y"
		match = re.match(r'if\s+(\w+)\s*>\s*(.+)', line_lower)
		if match:
			var = match.group(1)
			value = match.group(2).strip()

			try:
				num_value = int(value)
				value_str = f"${num_value:02X}"
			except:
				value_str = value

			label = self.generate_label("cond")
			template = self.library.get_template(CodePattern.CONDITION_IF)
			if template:
				return template.generate(variable=var, value=value_str, label=label)

		# Call function: "call X"
		match = re.match(r'call\s+(\w+)', line_lower)
		if match:
			func = match.group(1)
			return f"JSR {func}"

		# Return: "return"
		if line_lower == "return":
			return "RTS"

		# Comment
		if line.startswith(';'):
			return line

		# Unknown - return as comment
		return f"; TODO: {line}"

	def parse_interactive(self):
		"""Interactive pseudocode to assembly"""
		print("Pseudocode to Assembly Converter")
		print("=" * 60)
		print("Enter pseudocode (blank line to generate, 'quit' to exit)")
		print("\nExamples:")
		print("  set HP to 100")
		print("  increment counter")
		print("  add 10 to score")
		print("  loop 8 times")
		print("  if level > 10")
		print("  call UpdateSprite")
		print()

		while True:
			print("\nEnter pseudocode:")
			lines = []
			while True:
				line = input("> ")
				if line.lower() == 'quit':
					return
				if not line:
					break
				lines.append(line)

			if lines:
				pseudocode = '\n'.join(lines)
				print("\nGenerated Assembly:")
				print("-" * 60)
				print(self.parse(pseudocode))
				print("-" * 60)


class CodeOptimizer:
	"""Analyze and optimize assembly code"""

	def __init__(self):
		self.optimizations: List[Tuple[str, str, str, int]] = []
		self._init_optimizations()

	def _init_optimizations(self):
		"""Initialize optimization patterns"""
		# Pattern: (original, replacement, reason, cycles_saved)
		self.optimizations = [
			# Clear accumulator
			(r'LDA #\$00', 'LDA #0\n; Or better: TDC (if DP=0)',
			 'Use TDC to clear A (faster if DP is 0)', 1),

			# Increment by loading
			(r'LDA (.+)\nCLC\nADC #\$01\nSTA \1', 'INC \\1',
			 'Use INC instead of load-add-store', 2),

			# Set/clear carry unnecessarily
			(r'CLC\nADC #\$00', '; Remove CLC+ADC #0 (no effect)',
			 'Redundant operation', 3),

			# Redundant transfers
			(r'TAX\nTXA', '; Remove TAX+TXA (no effect)',
			 'Redundant transfer', 4),

			# Branch optimization
			(r'BEQ (.+)\nJMP (.+)\n\1:', 'BNE \\2\n\\1:',
			 'Invert branch condition to avoid JMP', 3),
		]

	def analyze(self, code: str) -> List[OptimizationSuggestion]:
		"""Analyze code and suggest optimizations"""
		suggestions = []
		lines = code.split('\n')

		for i, line in enumerate(lines):
			line = line.strip()

			# Check for common inefficiencies
			if 'LDA' in line and 'STA' in lines[i + 1] if i + 1 < len(lines) else False:
				# Check if loading and immediately storing to same place
				if 'LDA $' in line and 'STA $' in lines[i + 1]:
					var_load = line.split('$')[1].split()[0]
					var_store = lines[i + 1].split('$')[1].split()[0]
					if var_load == var_store:
						suggestions.append(OptimizationSuggestion(
							line_number=i + 1,
							original_code=f"{line}\n{lines[i + 1]}",
							suggested_code="; Remove redundant load/store",
							reason="Loading and storing same value",
							cycles_saved=4
						))

			# Check for multiple pushes/pulls
			if line.startswith('PHA') and i + 1 < len(lines) and lines[i + 1].strip().startswith('PLA'):
				suggestions.append(OptimizationSuggestion(
					line_number=i + 1,
					original_code=f"{line}\n{lines[i + 1]}",
					suggested_code="; Remove redundant push/pull",
					reason="Pushing and immediately pulling",
					cycles_saved=7
				))

		return suggestions


def main():
	"""Test code generator"""
	# Create library
	library = CodeLibrary()

	# Test snippet search
	print("Code Snippet Library")
	print("=" * 60)
	print("\nSearching for 'multiply':")
	results = library.search_snippets("multiply")
	for snippet in results:
		print(f"\n{snippet.name} ({snippet.complexity})")
		print(f"  {snippet.description}")
		print(f"  Tags: {', '.join(snippet.tags)}")

	# Test pseudocode parsing
	print("\n\nPseudocode to Assembly")
	print("=" * 60)

	parser = PseudocodeParser(library)

	pseudocode = """
set HP to 100
set MP to 50
increment level
add 10 to experience
loop 8 times
if level > 10
call LevelUpRoutine
return
	""".strip()

	print("\nPseudocode:")
	print(pseudocode)
	print("\nGenerated Assembly:")
	print("-" * 60)
	print(parser.parse(pseudocode))

	# Test optimizer
	print("\n\nCode Optimization")
	print("=" * 60)

	optimizer = CodeOptimizer()

	test_code = """
	LDA $1000
	STA $1000
	PHA
	PLA
	LDA #$00
	""".strip()

	print("\nOriginal Code:")
	print(test_code)
	print("\nOptimization Suggestions:")
	suggestions = optimizer.analyze(test_code)
	for suggestion in suggestions:
		print(f"\nLine {suggestion.line_number}:")
		print(f"  Issue: {suggestion.reason}")
		print(f"  Cycles saved: {suggestion.cycles_saved}")

	# Interactive mode
	print("\n\n")
	response = input("Start interactive mode? (y/n): ")
	if response.lower() == 'y':
		parser.parse_interactive()


if __name__ == "__main__":
	main()
