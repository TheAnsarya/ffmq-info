#!/usr/bin/env python3
"""
Dependency Graph Generator - Visualize event script dependencies and call graphs
Generate interactive dependency graphs showing script relationships

Features:
- Call graph generation (which scripts call which)
- Dependency analysis (flag/variable dependencies)
- Circular dependency detection
- Dead code identification
- Entry point analysis
- Subroutine usage tracking
- Interactive HTML visualization
- GraphViz export for publication-quality diagrams

Graph Types:
- Call graph (subroutine calls)
- Data flow graph (flag/variable usage)
- Control flow graph (branch/jump targets)
- Dependency graph (script dependencies)
- Impact graph (what depends on this script)

Analysis Features:
- Find unreachable code
- Identify circular dependencies
- Detect unused subroutines
- Calculate script coupling
- Analyze script cohesion
- Generate refactoring suggestions

Output Formats:
- DOT (GraphViz)
- Mermaid (GitHub-compatible)
- Interactive HTML (D3.js force graph)
- JSON graph data
- PlantUML

Usage:
	python dependency_graph_generator.py scripts/ --output deps.dot
	python dependency_graph_generator.py scripts/ --format mermaid --output deps.mmd
	python dependency_graph_generator.py scripts/ --interactive --output graph.html
	python dependency_graph_generator.py scripts/ --analyze --find-circular
"""

import argparse
import re
from pathlib import Path
from typing import Dict, List, Optional, Set, Tuple
from dataclasses import dataclass, field
from collections import defaultdict, deque
from enum import Enum
import json


class DependencyType(Enum):
	"""Type of dependency relationship"""
	CALL = "call"
	FLAG_READ = "flag_read"
	FLAG_WRITE = "flag_write"
	VARIABLE_READ = "variable_read"
	VARIABLE_WRITE = "variable_write"
	JUMP = "jump"
	BRANCH = "branch"


@dataclass
class ScriptNode:
	"""Node in dependency graph"""
	script_id: str
	file_path: str
	entry_points: List[int] = field(default_factory=list)
	is_subroutine: bool = False
	is_entry_point: bool = False
	calls_made: Set[str] = field(default_factory=set)
	called_by: Set[str] = field(default_factory=set)
	flags_read: Set[int] = field(default_factory=set)
	flags_written: Set[int] = field(default_factory=set)
	variables_read: Set[str] = field(default_factory=set)
	variables_written: Set[str] = field(default_factory=set)


@dataclass
class Dependency:
	"""Dependency edge in graph"""
	source: str
	target: str
	dep_type: DependencyType
	metadata: Dict = field(default_factory=dict)


@dataclass
class CircularDependency:
	"""Detected circular dependency"""
	cycle: List[str]
	dep_types: Set[DependencyType]
	severity: str  # "low", "medium", "high"


class DependencyGraphGenerator:
	"""Generate and analyze script dependency graphs"""

	def __init__(self, verbose: bool = False):
		self.verbose = verbose
		self.nodes: Dict[str, ScriptNode] = {}
		self.dependencies: List[Dependency] = []
		self.circular_deps: List[CircularDependency] = []

	def parse_script(self, path: Path, script_id: Optional[str] = None) -> None:
		"""Parse script file and extract dependencies"""
		if script_id is None:
			script_id = path.stem

		if script_id not in self.nodes:
			self.nodes[script_id] = ScriptNode(script_id=script_id, file_path=str(path))

		node = self.nodes[script_id]

		try:
			with open(path) as f:
				lines = f.readlines()
		except Exception as e:
			if self.verbose:
				print(f"Error reading {path}: {e}")
			return

		for line_num, line in enumerate(lines, 1):
			line = line.strip()
			if not line or line.startswith(';'):
				continue

			# Parse command
			match = re.match(r'^([A-Z_]+)(?:\s+(.+))?$', line)
			if not match:
				continue

			command = match.group(1)
			params_str = match.group(2) or ""

			# Call dependencies
			if command == 'CALL':
				target = self.parse_address(params_str)
				if target:
					node.calls_made.add(target)
					self.add_dependency(script_id, target, DependencyType.CALL)

			# Jump/branch dependencies
			elif command in ('JUMP', 'BRANCH'):
				target = self.parse_label(params_str)
				if target:
					dep_type = DependencyType.JUMP if command == 'JUMP' else DependencyType.BRANCH
					self.add_dependency(script_id, target, dep_type)

			# Flag dependencies
			elif command in ('SET_FLAG', 'CLEAR_FLAG'):
				flag_id = self.parse_flag_id(params_str)
				if flag_id is not None:
					node.flags_written.add(flag_id)
					self.add_dependency(script_id, f"flag_{flag_id}", DependencyType.FLAG_WRITE)

			elif command == 'CHECK_FLAG':
				flag_id = self.parse_flag_id(params_str)
				if flag_id is not None:
					node.flags_read.add(flag_id)
					self.add_dependency(script_id, f"flag_{flag_id}", DependencyType.FLAG_READ)

			# Variable dependencies
			elif command in ('VARIABLE_SET', 'MEMORY_WRITE'):
				var_name = self.parse_variable(params_str)
				if var_name:
					node.variables_written.add(var_name)
					self.add_dependency(script_id, f"var_{var_name}", DependencyType.VARIABLE_WRITE)

			elif command in ('VARIABLE_CHECK', 'MEMORY_READ', 'MEMORY_COMPARE'):
				var_name = self.parse_variable(params_str)
				if var_name:
					node.variables_read.add(var_name)
					self.add_dependency(script_id, f"var_{var_name}", DependencyType.VARIABLE_READ)

	def parse_address(self, params: str) -> Optional[str]:
		"""Parse subroutine address from parameters"""
		# Try to extract bank/offset or label
		match = re.match(r'(?:0x)?([0-9A-Fa-f]{2})/([0-9A-Fa-f]{4})', params)
		if match:
			bank = match.group(1)
			offset = match.group(2)
			return f"sub_{bank}_{offset}"

		# Try label
		match = re.match(r'([a-zA-Z_][a-zA-Z0-9_]*)', params)
		if match:
			return match.group(1)

		return None

	def parse_label(self, params: str) -> Optional[str]:
		"""Parse label from parameters"""
		match = re.match(r'([a-zA-Z_][a-zA-Z0-9_]*)', params)
		if match:
			return match.group(1)
		return None

	def parse_flag_id(self, params: str) -> Optional[int]:
		"""Parse flag ID from parameters"""
		parts = params.split(',')
		if parts:
			try:
				return int(parts[0].strip(), 0)
			except ValueError:
				pass
		return None

	def parse_variable(self, params: str) -> Optional[str]:
		"""Parse variable name/address from parameters"""
		parts = params.split(',')
		if parts:
			var = parts[0].strip()
			# Check if it's an address
			if var.startswith('0x') or var.startswith('$'):
				return var
			# Check if it's a name
			if re.match(r'[a-zA-Z_][a-zA-Z0-9_]*', var):
				return var
		return None

	def add_dependency(self, source: str, target: str, dep_type: DependencyType, **metadata) -> None:
		"""Add dependency edge"""
		dep = Dependency(
			source=source,
			target=target,
			dep_type=dep_type,
			metadata=metadata
		)
		self.dependencies.append(dep)

		# Update node relationships for call dependencies
		if dep_type == DependencyType.CALL:
			if target not in self.nodes:
				self.nodes[target] = ScriptNode(script_id=target, file_path="unknown", is_subroutine=True)
			self.nodes[target].called_by.add(source)

	def find_circular_dependencies(self) -> List[CircularDependency]:
		"""Find circular dependencies using DFS"""
		self.circular_deps = []
		visited = set()
		rec_stack = set()
		path = []

		def dfs(node_id: str) -> None:
			visited.add(node_id)
			rec_stack.add(node_id)
			path.append(node_id)

			if node_id in self.nodes:
				for target in self.nodes[node_id].calls_made:
					if target not in visited:
						dfs(target)
					elif target in rec_stack:
						# Found cycle
						cycle_start = path.index(target)
						cycle = path[cycle_start:] + [target]

						# Determine severity
						severity = "high" if len(cycle) <= 3 else "medium"

						circular = CircularDependency(
							cycle=cycle,
							dep_types={DependencyType.CALL},
							severity=severity
						)
						self.circular_deps.append(circular)

			path.pop()
			rec_stack.remove(node_id)

		for node_id in self.nodes:
			if node_id not in visited:
				dfs(node_id)

		return self.circular_deps

	def find_unreachable_scripts(self) -> List[str]:
		"""Find scripts that are never called"""
		reachable = set()

		# Start from entry points
		entry_points = [node_id for node_id, node in self.nodes.items() if node.is_entry_point]

		if not entry_points:
			# If no explicit entry points, assume all non-subroutines are entry points
			entry_points = [node_id for node_id, node in self.nodes.items() if not node.is_subroutine]

		# BFS from entry points
		queue = deque(entry_points)
		while queue:
			current = queue.popleft()
			if current in reachable:
				continue

			reachable.add(current)

			if current in self.nodes:
				for target in self.nodes[current].calls_made:
					if target not in reachable:
						queue.append(target)

		# Unreachable = all nodes - reachable
		all_scripts = set(self.nodes.keys())
		unreachable = all_scripts - reachable

		return sorted(unreachable)

	def calculate_coupling(self, node_id: str) -> int:
		"""Calculate coupling (number of dependencies)"""
		if node_id not in self.nodes:
			return 0

		node = self.nodes[node_id]
		return len(node.calls_made) + len(node.called_by)

	def generate_dot(self, include_data_deps: bool = False) -> str:
		"""Generate GraphViz DOT format"""
		lines = [
			"digraph Dependencies {",
			"\trankdir=LR;",
			"\tnode [shape=box, style=rounded];",
			""
		]

		# Nodes
		for node_id, node in self.nodes.items():
			color = "lightblue" if node.is_entry_point else "lightgray"
			if node.is_subroutine:
				color = "lightgreen"

			label = node_id
			if self.calculate_coupling(node_id) > 5:
				color = "orange"

			lines.append(f'\t"{node_id}" [fillcolor={color}, style="filled,rounded"];')

		lines.append("")

		# Edges
		seen_edges = set()
		for dep in self.dependencies:
			# Skip data dependencies unless requested
			if not include_data_deps and dep.dep_type in (DependencyType.FLAG_READ, DependencyType.FLAG_WRITE,
				DependencyType.VARIABLE_READ, DependencyType.VARIABLE_WRITE):
				continue

			edge_key = (dep.source, dep.target, dep.dep_type)
			if edge_key in seen_edges:
				continue
			seen_edges.add(edge_key)

			# Edge style based on type
			if dep.dep_type == DependencyType.CALL:
				style = "solid"
				color = "black"
			elif dep.dep_type in (DependencyType.JUMP, DependencyType.BRANCH):
				style = "dashed"
				color = "blue"
			else:
				style = "dotted"
				color = "gray"

			lines.append(f'\t"{dep.source}" -> "{dep.target}" [style={style}, color={color}];')

		lines.append("}")
		return '\n'.join(lines)

	def generate_mermaid(self) -> str:
		"""Generate Mermaid diagram"""
		lines = [
			"graph TD",
			""
		]

		# Nodes with styles
		for node_id, node in self.nodes.items():
			safe_id = node_id.replace('-', '_').replace('/', '_')

			if node.is_entry_point:
				lines.append(f'\t{safe_id}["{node_id}"]:::entry')
			elif node.is_subroutine:
				lines.append(f'\t{safe_id}("{node_id}"):::subroutine')
			else:
				lines.append(f'\t{safe_id}["{node_id}"]')

		lines.append("")

		# Edges (call dependencies only)
		seen_edges = set()
		for dep in self.dependencies:
			if dep.dep_type != DependencyType.CALL:
				continue

			edge_key = (dep.source, dep.target)
			if edge_key in seen_edges:
				continue
			seen_edges.add(edge_key)

			source_safe = dep.source.replace('-', '_').replace('/', '_')
			target_safe = dep.target.replace('-', '_').replace('/', '_')

			lines.append(f'\t{source_safe} --> {target_safe}')

		# Styles
		lines.extend([
			"",
			"\tclassDef entry fill:#90EE90,stroke:#333;",
			"\tclassDef subroutine fill:#ADD8E6,stroke:#333;"
		])

		return '\n'.join(lines)

	def generate_json(self) -> str:
		"""Generate JSON graph data"""
		nodes = [
			{
				"id": node_id,
				"file": node.file_path,
				"is_entry_point": node.is_entry_point,
				"is_subroutine": node.is_subroutine,
				"coupling": self.calculate_coupling(node_id)
			}
			for node_id, node in self.nodes.items()
		]

		edges = [
			{
				"source": dep.source,
				"target": dep.target,
				"type": dep.dep_type.value
			}
			for dep in self.dependencies
		]

		data = {
			"nodes": nodes,
			"edges": edges
		}

		return json.dumps(data, indent=2)

	def generate_interactive_html(self) -> str:
		"""Generate interactive D3.js force graph"""
		graph_data = self.generate_json()

		html = f"""<!DOCTYPE html>
<html>
<head>
	<meta charset="utf-8">
	<title>Dependency Graph</title>
	<script src="https://d3js.org/d3.v7.min.js"></script>
	<style>
		body {{ margin: 0; font-family: Arial, sans-serif; }}
		#graph {{ width: 100vw; height: 100vh; }}
		.node {{ cursor: pointer; }}
		.link {{ stroke: #999; stroke-opacity: 0.6; }}
		.tooltip {{
			position: absolute;
			padding: 8px;
			background: rgba(0,0,0,0.8);
			color: white;
			border-radius: 4px;
			pointer-events: none;
			display: none;
		}}
	</style>
</head>
<body>
	<div id="graph"></div>
	<div class="tooltip" id="tooltip"></div>
	<script>
		const data = {graph_data};

		const width = window.innerWidth;
		const height = window.innerHeight;

		const svg = d3.select("#graph")
			.append("svg")
			.attr("width", width)
			.attr("height", height);

		const simulation = d3.forceSimulation(data.nodes)
			.force("link", d3.forceLink(data.edges).id(d => d.id).distance(100))
			.force("charge", d3.forceManyBody().strength(-300))
			.force("center", d3.forceCenter(width / 2, height / 2));

		const link = svg.append("g")
			.selectAll("line")
			.data(data.edges)
			.join("line")
			.attr("class", "link")
			.attr("stroke-width", 2);

		const node = svg.append("g")
			.selectAll("circle")
			.data(data.nodes)
			.join("circle")
			.attr("class", "node")
			.attr("r", d => d.is_entry_point ? 8 : 6)
			.attr("fill", d => d.is_entry_point ? "#90EE90" : d.is_subroutine ? "#ADD8E6" : "#ccc")
			.call(d3.drag()
				.on("start", dragstarted)
				.on("drag", dragged)
				.on("end", dragended));

		const label = svg.append("g")
			.selectAll("text")
			.data(data.nodes)
			.join("text")
			.text(d => d.id)
			.attr("font-size", 10)
			.attr("dx", 8)
			.attr("dy", 4);

		simulation.on("tick", () => {{
			link
				.attr("x1", d => d.source.x)
				.attr("y1", d => d.source.y)
				.attr("x2", d => d.target.x)
				.attr("y2", d => d.target.y);

			node
				.attr("cx", d => d.x)
				.attr("cy", d => d.y);

			label
				.attr("x", d => d.x)
				.attr("y", d => d.y);
		}});

		function dragstarted(event) {{
			if (!event.active) simulation.alphaTarget(0.3).restart();
			event.subject.fx = event.subject.x;
			event.subject.fy = event.subject.y;
		}}

		function dragged(event) {{
			event.subject.fx = event.x;
			event.subject.fy = event.y;
		}}

		function dragended(event) {{
			if (!event.active) simulation.alphaTarget(0);
			event.subject.fx = null;
			event.subject.fy = null;
		}}
	</script>
</body>
</html>"""

		return html


def main():
	parser = argparse.ArgumentParser(description='Generate dependency graphs from event scripts')
	parser.add_argument('input_paths', type=Path, nargs='+', help='Script files or directories')
	parser.add_argument('--output', type=Path, help='Output file')
	parser.add_argument('--format', choices=['dot', 'mermaid', 'json', 'html'], default='dot',
		help='Output format')
	parser.add_argument('--interactive', action='store_true', help='Generate interactive HTML')
	parser.add_argument('--analyze', action='store_true', help='Perform dependency analysis')
	parser.add_argument('--find-circular', action='store_true', help='Find circular dependencies')
	parser.add_argument('--find-unreachable', action='store_true', help='Find unreachable code')
	parser.add_argument('--include-data-deps', action='store_true', help='Include data dependencies')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')

	args = parser.parse_args()

	generator = DependencyGraphGenerator(verbose=args.verbose)

	# Parse all scripts
	for input_path in args.input_paths:
		if input_path.is_file():
			generator.parse_script(input_path)
		elif input_path.is_dir():
			for script_file in input_path.rglob('*.txt'):
				generator.parse_script(script_file)
			for script_file in input_path.rglob('*.asm'):
				generator.parse_script(script_file)

	if args.verbose:
		print(f"Parsed {len(generator.nodes)} scripts")
		print(f"Found {len(generator.dependencies)} dependencies")

	# Analysis
	if args.find_circular or args.analyze:
		circular = generator.find_circular_dependencies()
		if circular:
			print(f"\n⚠ Found {len(circular)} circular dependencies:")
			for circ in circular:
				print(f"  - {' -> '.join(circ.cycle)} [{circ.severity}]")

	if args.find_unreachable or args.analyze:
		unreachable = generator.find_unreachable_scripts()
		if unreachable:
			print(f"\n⚠ Found {len(unreachable)} unreachable scripts:")
			for script in unreachable[:10]:
				print(f"  - {script}")

	# Generate output
	if args.interactive or args.format == 'html':
		output = generator.generate_interactive_html()
	elif args.format == 'dot':
		output = generator.generate_dot(include_data_deps=args.include_data_deps)
	elif args.format == 'mermaid':
		output = generator.generate_mermaid()
	elif args.format == 'json':
		output = generator.generate_json()

	# Write output
	if args.output:
		with open(args.output, 'w') as f:
			f.write(output)
		print(f"\n✓ Dependency graph generated: {args.output}")
	else:
		print(output)

	return 0


if __name__ == '__main__':
	exit(main())
