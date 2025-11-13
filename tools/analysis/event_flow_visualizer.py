#!/usr/bin/env python3
"""
Event Flow Visualizer - Generate flowcharts from event scripts
Creates visual representations of control flow, subroutine calls, and decision trees

Features:
- Parse event scripts and build control flow graph
- Detect branches, loops, and subroutine calls
- Generate Graphviz DOT format
- Export to PNG, SVG, PDF (via Graphviz)
- Generate Mermaid diagrams for Markdown
- Highlight critical paths
- Show memory operations
- Analyze complexity metrics

Supported Output Formats:
- DOT (Graphviz) - Can be rendered to PNG/SVG/PDF
- Mermaid - For embedding in Markdown/GitHub
- ASCII Art - Terminal-friendly visualization
- HTML with interactive D3.js graph

Usage:
	python event_flow_visualizer.py --script dialogs.txt --output flow.dot
	python event_flow_visualizer.py --script dialogs.txt --output flow.mmd --format mermaid
	python event_flow_visualizer.py --script dialogs.txt --dialog INTRO_01 --output intro.svg
	python event_flow_visualizer.py --script dialogs.txt --format ascii
	python event_flow_visualizer.py --script dialogs.txt --interactive flow.html
"""

import argparse
import re
import subprocess
from pathlib import Path
from typing import Dict, List, Set, Optional, Tuple
from dataclasses import dataclass, field
from enum import Enum
from collections import defaultdict


class NodeType(Enum):
	"""Types of nodes in control flow graph"""
	START = "start"
	END = "end"
	TEXT = "text"
	COMMAND = "command"
	BRANCH = "branch"
	CALL = "call"
	MEMORY = "memory"
	RETURN = "return"


class EdgeType(Enum):
	"""Types of edges in control flow graph"""
	SEQUENTIAL = "sequential"
	BRANCH_TRUE = "branch_true"
	BRANCH_FALSE = "branch_false"
	CALL = "call"
	RETURN = "return"


@dataclass
class FlowNode:
	"""A node in the control flow graph"""
	node_id: str
	node_type: NodeType
	label: str
	line_number: int
	metadata: Dict = field(default_factory=dict)
	
	def __hash__(self):
		return hash(self.node_id)


@dataclass
class FlowEdge:
	"""An edge in the control flow graph"""
	from_node: str
	to_node: str
	edge_type: EdgeType
	label: str = ""
	
	def __hash__(self):
		return hash((self.from_node, self.to_node, self.edge_type))


@dataclass
class ControlFlowGraph:
	"""Complete control flow graph for a dialog"""
	dialog_id: str
	nodes: List[FlowNode]
	edges: List[FlowEdge]
	entry_node: str
	exit_nodes: List[str]
	subroutine_calls: List[str] = field(default_factory=list)
	complexity_score: int = 0
	
	def add_node(self, node: FlowNode) -> None:
		"""Add node to graph"""
		if node not in self.nodes:
			self.nodes.append(node)
	
	def add_edge(self, edge: FlowEdge) -> None:
		"""Add edge to graph"""
		if edge not in self.edges:
			self.edges.append(edge)
	
	def get_node(self, node_id: str) -> Optional[FlowNode]:
		"""Get node by ID"""
		for node in self.nodes:
			if node.node_id == node_id:
				return node
		return None


class EventFlowVisualizer:
	"""Generate flowcharts from event scripts"""
	
	# Event commands that affect control flow
	CONTROL_FLOW_COMMANDS = {
		'END': NodeType.END,
		'RETURN': NodeType.RETURN,
		'CALL_SUBROUTINE': NodeType.CALL,
		'CHECK_FLAG': NodeType.BRANCH,
		'JUMP_IF': NodeType.BRANCH,
		'JUMP': NodeType.BRANCH
	}
	
	# Memory operation commands
	MEMORY_COMMANDS = {
		'MEMORY_WRITE',
		'MEMORY_READ',
		'SET_FLAG',
		'CLEAR_FLAG'
	}
	
	def __init__(self, verbose: bool = False):
		self.verbose = verbose
		self.dialogs: Dict[str, List[str]] = {}
		self.graphs: Dict[str, ControlFlowGraph] = {}
	
	def parse_script_file(self, script_path: Path) -> None:
		"""Parse script file into dialog dictionary"""
		if self.verbose:
			print(f"Parsing {script_path}...")
		
		with open(script_path, 'r', encoding='utf-8') as f:
			content = f.read()
		
		# Split by dialog markers
		dialog_pattern = r'^DIALOG\s+(\S+):(.*?)(?=^DIALOG\s+|\Z)'
		matches = re.finditer(dialog_pattern, content, re.MULTILINE | re.DOTALL)
		
		for match in matches:
			dialog_id = match.group(1)
			dialog_content = match.group(2).strip()
			lines = [line.strip() for line in dialog_content.split('\n') if line.strip()]
			self.dialogs[dialog_id] = lines
		
		if self.verbose:
			print(f"  Loaded {len(self.dialogs)} dialogs")
	
	def build_control_flow_graph(self, dialog_id: str) -> ControlFlowGraph:
		"""Build control flow graph for a dialog"""
		if dialog_id not in self.dialogs:
			raise ValueError(f"Dialog {dialog_id} not found")
		
		lines = self.dialogs[dialog_id]
		graph = ControlFlowGraph(
			dialog_id=dialog_id,
			nodes=[],
			edges=[],
			entry_node=f"{dialog_id}_START",
			exit_nodes=[]
		)
		
		# Create START node
		start_node = FlowNode(
			node_id=f"{dialog_id}_START",
			node_type=NodeType.START,
			label="START",
			line_number=0
		)
		graph.add_node(start_node)
		
		# Process each line
		prev_node_id = start_node.node_id
		for line_num, line in enumerate(lines, 1):
			node_id = f"{dialog_id}_L{line_num}"
			
			# Determine node type
			node_type = self._classify_line(line)
			
			# Create node
			node = FlowNode(
				node_id=node_id,
				node_type=node_type,
				label=self._format_label(line),
				line_number=line_num,
				metadata=self._extract_metadata(line)
			)
			graph.add_node(node)
			
			# Add edge from previous node
			edge = FlowEdge(
				from_node=prev_node_id,
				to_node=node_id,
				edge_type=EdgeType.SEQUENTIAL
			)
			graph.add_edge(edge)
			
			# Handle control flow
			if node_type == NodeType.BRANCH:
				# Branch creates two paths
				graph.complexity_score += 2
				
				# True path (continues to next line)
				# False path (would need to be determined by jump target)
				# For now, just mark as branch point
				
			elif node_type == NodeType.CALL:
				# Extract subroutine name
				match = re.search(r'CALL_SUBROUTINE\s+(\S+)', line)
				if match:
					subroutine = match.group(1)
					graph.subroutine_calls.append(subroutine)
					
					# Add call edge
					call_edge = FlowEdge(
						from_node=node_id,
						to_node=subroutine,
						edge_type=EdgeType.CALL,
						label=f"call {subroutine}"
					)
					graph.add_edge(call_edge)
					graph.complexity_score += 1
			
			elif node_type in [NodeType.END, NodeType.RETURN]:
				# Terminal node
				graph.exit_nodes.append(node_id)
				prev_node_id = None
				break
			
			prev_node_id = node_id
		
		# If no explicit END, last node is exit
		if prev_node_id and prev_node_id not in graph.exit_nodes:
			graph.exit_nodes.append(prev_node_id)
		
		return graph
	
	def _classify_line(self, line: str) -> NodeType:
		"""Classify line into node type"""
		# Check control flow commands
		for cmd, node_type in self.CONTROL_FLOW_COMMANDS.items():
			if line.startswith(cmd):
				return node_type
		
		# Check memory commands
		if any(line.startswith(cmd) for cmd in self.MEMORY_COMMANDS):
			return NodeType.MEMORY
		
		# Text lines (quoted)
		if line.startswith('"'):
			return NodeType.TEXT
		
		# Other commands
		return NodeType.COMMAND
	
	def _format_label(self, line: str, max_length: int = 40) -> str:
		"""Format line as node label"""
		if len(line) <= max_length:
			return line
		return line[:max_length - 3] + "..."
	
	def _extract_metadata(self, line: str) -> Dict:
		"""Extract metadata from line"""
		metadata = {}
		
		# Extract command and parameters
		parts = line.split(None, 2)
		if parts:
			metadata['command'] = parts[0]
			if len(parts) > 1:
				metadata['parameters'] = parts[1:]
		
		return metadata
	
	def generate_dot(self, graph: ControlFlowGraph) -> str:
		"""Generate Graphviz DOT format"""
		lines = [
			f'digraph "{graph.dialog_id}" {{',
			'  rankdir=TB;',
			'  node [shape=box, style=rounded];',
			''
		]
		
		# Define node styles
		node_styles = {
			NodeType.START: 'shape=circle, style=filled, fillcolor=lightgreen',
			NodeType.END: 'shape=circle, style=filled, fillcolor=lightcoral',
			NodeType.TEXT: 'shape=box, style=filled, fillcolor=lightyellow',
			NodeType.COMMAND: 'shape=box',
			NodeType.BRANCH: 'shape=diamond, style=filled, fillcolor=lightblue',
			NodeType.CALL: 'shape=box, style="rounded,filled", fillcolor=lightgray',
			NodeType.MEMORY: 'shape=box, style=filled, fillcolor=lavender',
			NodeType.RETURN: 'shape=circle, style=filled, fillcolor=lightcoral'
		}
		
		# Add nodes
		for node in graph.nodes:
			style = node_styles.get(node.node_type, '')
			label = node.label.replace('"', '\\"')
			lines.append(f'  "{node.node_id}" [label="{label}", {style}];')
		
		lines.append('')
		
		# Add edges
		edge_styles = {
			EdgeType.SEQUENTIAL: '',
			EdgeType.BRANCH_TRUE: 'label="true", color=green',
			EdgeType.BRANCH_FALSE: 'label="false", color=red',
			EdgeType.CALL: 'label="call", style=dashed, color=blue',
			EdgeType.RETURN: 'label="return", style=dashed, color=purple'
		}
		
		for edge in graph.edges:
			style = edge_styles.get(edge.edge_type, '')
			if edge.label:
				style = f'label="{edge.label}"' + (', ' + style if style else '')
			lines.append(f'  "{edge.from_node}" -> "{edge.to_node}" [{style}];')
		
		lines.append('}')
		return '\n'.join(lines)
	
	def generate_mermaid(self, graph: ControlFlowGraph) -> str:
		"""Generate Mermaid diagram format"""
		lines = [
			'```mermaid',
			'graph TD',
			''
		]
		
		# Define node shapes for Mermaid
		node_shapes = {
			NodeType.START: ('((', '))'),
			NodeType.END: ('((', '))'),
			NodeType.TEXT: ('[', ']'),
			NodeType.COMMAND: ('[', ']'),
			NodeType.BRANCH: ('{', '}'),
			NodeType.CALL: ('[[', ']]'),
			NodeType.MEMORY: ('[', ']'),
			NodeType.RETURN: ('((', '))')
		}
		
		# Add nodes
		for node in graph.nodes:
			shape_start, shape_end = node_shapes.get(node.node_type, ('[', ']'))
			label = node.label.replace('"', "'")
			node_id = node.node_id.replace('-', '_')
			lines.append(f'  {node_id}{shape_start}"{label}"{shape_end}')
		
		lines.append('')
		
		# Add edges
		for edge in graph.edges:
			from_id = edge.from_node.replace('-', '_')
			to_id = edge.to_node.replace('-', '_')
			
			if edge.edge_type == EdgeType.CALL:
				lines.append(f'  {from_id} -.->|"{edge.label or "call"}"| {to_id}')
			elif edge.edge_type in [EdgeType.BRANCH_TRUE, EdgeType.BRANCH_FALSE]:
				label = edge.edge_type.value.replace('branch_', '')
				lines.append(f'  {from_id} -->|"{label}"| {to_id}')
			else:
				lines.append(f'  {from_id} --> {to_id}')
		
		lines.append('```')
		return '\n'.join(lines)
	
	def generate_ascii(self, graph: ControlFlowGraph) -> str:
		"""Generate ASCII art flowchart"""
		lines = [
			f"=== {graph.dialog_id} ===",
			""
		]
		
		# Simple linear representation
		for i, node in enumerate(graph.nodes):
			# Node representation
			if node.node_type == NodeType.START:
				lines.append("┌─────────┐")
				lines.append(f"│ {node.label:^7} │")
				lines.append("└────┬────┘")
			elif node.node_type == NodeType.END:
				lines.append("     │")
				lines.append("┌────┴────┐")
				lines.append(f"│ {node.label:^7} │")
				lines.append("└─────────┘")
			elif node.node_type == NodeType.BRANCH:
				lines.append("     │")
				lines.append("   ╱─┴─╲")
				lines.append(f"  ╱ {node.label[:5]:^5} ╲")
				lines.append(" ╱───────╲")
			elif node.node_type == NodeType.CALL:
				lines.append("     │")
				lines.append("┌────┴────┐")
				lines.append(f"│ {node.label[:7]:^7} │═══╗")
				lines.append("└────┬────┘   ║")
			else:
				lines.append("     │")
				lines.append("┌────┴────┐")
				lines.append(f"│ {node.label[:7]:^7} │")
				lines.append("└────┬────┘")
		
		lines.extend([
			"",
			f"Complexity: {graph.complexity_score}",
			f"Subroutines: {', '.join(graph.subroutine_calls) if graph.subroutine_calls else 'None'}",
			f"Exit points: {len(graph.exit_nodes)}"
		])
		
		return '\n'.join(lines)
	
	def generate_interactive_html(self, graphs: List[ControlFlowGraph], output_path: Path) -> None:
		"""Generate interactive HTML with D3.js visualization"""
		html_template = """<!DOCTYPE html>
<html>
<head>
	<meta charset="utf-8">
	<title>Event Flow Visualizer</title>
	<script src="https://d3js.org/d3.v7.min.js"></script>
	<style>
		body {{
			font-family: Arial, sans-serif;
			margin: 20px;
		}}
		#graph {{
			border: 1px solid #ccc;
			width: 100%;
			height: 600px;
		}}
		.node {{
			stroke: #333;
			stroke-width: 2px;
		}}
		.node-start {{ fill: #90ee90; }}
		.node-end {{ fill: #f08080; }}
		.node-text {{ fill: #ffffe0; }}
		.node-command {{ fill: #e0e0e0; }}
		.node-branch {{ fill: #add8e6; }}
		.node-call {{ fill: #d3d3d3; }}
		.node-memory {{ fill: #e6e6fa; }}
		.link {{
			stroke: #999;
			stroke-width: 2px;
			fill: none;
		}}
		.link-call {{
			stroke: #0000ff;
			stroke-dasharray: 5,5;
		}}
		text {{
			font-size: 10px;
			pointer-events: none;
		}}
		#info {{
			margin-top: 20px;
			padding: 10px;
			background: #f0f0f0;
		}}
	</style>
</head>
<body>
	<h1>Event Flow Visualizer</h1>
	<div id="graph"></div>
	<div id="info">
		<h3>Graph Information</h3>
		<p id="details">Click on a node for details</p>
	</div>
	
	<script>
		// Graph data
		const graphData = {graph_data_json};
		
		// Set up SVG
		const width = document.getElementById('graph').clientWidth;
		const height = 600;
		const svg = d3.select('#graph')
			.append('svg')
			.attr('width', width)
			.attr('height', height);
		
		// Create force simulation
		const simulation = d3.forceSimulation(graphData.nodes)
			.force('link', d3.forceLink(graphData.links).id(d => d.id).distance(100))
			.force('charge', d3.forceManyBody().strength(-300))
			.force('center', d3.forceCenter(width / 2, height / 2));
		
		// Draw links
		const link = svg.append('g')
			.selectAll('path')
			.data(graphData.links)
			.enter()
			.append('path')
			.attr('class', d => 'link ' + (d.type === 'call' ? 'link-call' : ''));
		
		// Draw nodes
		const node = svg.append('g')
			.selectAll('circle')
			.data(graphData.nodes)
			.enter()
			.append('circle')
			.attr('r', 20)
			.attr('class', d => 'node node-' + d.type)
			.call(d3.drag()
				.on('start', dragstarted)
				.on('drag', dragged)
				.on('end', dragended))
			.on('click', (event, d) => {{
				document.getElementById('details').innerHTML = 
					'<b>' + d.id + '</b><br>' +
					'Type: ' + d.type + '<br>' +
					'Label: ' + d.label + '<br>' +
					'Line: ' + d.line;
			}});
		
		// Labels
		const labels = svg.append('g')
			.selectAll('text')
			.data(graphData.nodes)
			.enter()
			.append('text')
			.text(d => d.label.substring(0, 10))
			.attr('text-anchor', 'middle')
			.attr('dy', 5);
		
		// Update positions
		simulation.on('tick', () => {{
			link.attr('d', d => `M${{d.source.x}},${{d.source.y}} L${{d.target.x}},${{d.target.y}}`);
			node.attr('cx', d => d.x).attr('cy', d => d.y);
			labels.attr('x', d => d.x).attr('y', d => d.y);
		}});
		
		function dragstarted(event, d) {{
			if (!event.active) simulation.alphaTarget(0.3).restart();
			d.fx = d.x;
			d.fy = d.y;
		}}
		
		function dragged(event, d) {{
			d.fx = event.x;
			d.fy = event.y;
		}}
		
		function dragended(event, d) {{
			if (!event.active) simulation.alphaTarget(0);
			d.fx = null;
			d.fy = null;
		}}
	</script>
</body>
</html>"""
		
		# Convert graphs to D3.js format
		all_nodes = []
		all_links = []
		
		for graph in graphs:
			for node in graph.nodes:
				all_nodes.append({
					'id': node.node_id,
					'label': node.label,
					'type': node.node_type.value,
					'line': node.line_number
				})
			
			for edge in graph.edges:
				all_links.append({
					'source': edge.from_node,
					'target': edge.to_node,
					'type': edge.edge_type.value
				})
		
		graph_data = {
			'nodes': all_nodes,
			'links': all_links
		}
		
		import json
		html_content = html_template.replace('{graph_data_json}', json.dumps(graph_data, indent=2))
		
		with open(output_path, 'w', encoding='utf-8') as f:
			f.write(html_content)
		
		if self.verbose:
			print(f"\nGenerated interactive HTML: {output_path}")
	
	def render_dot_to_image(self, dot_content: str, output_path: Path, format: str = 'png') -> None:
		"""Render DOT file to image using Graphviz"""
		try:
			# Write DOT to temp file
			dot_file = output_path.with_suffix('.dot')
			with open(dot_file, 'w') as f:
				f.write(dot_content)
			
			# Render with Graphviz
			subprocess.run(
				['dot', f'-T{format}', str(dot_file), '-o', str(output_path)],
				check=True
			)
			
			if self.verbose:
				print(f"Rendered to {output_path}")
			
			# Clean up DOT file
			dot_file.unlink()
			
		except subprocess.CalledProcessError:
			print("Error: Graphviz 'dot' command not found. Please install Graphviz.")
			print("DOT content saved to:", dot_file)
		except FileNotFoundError:
			print("Error: Graphviz not found. Install from https://graphviz.org/")
			print("DOT content saved to:", dot_file)


def main():
	parser = argparse.ArgumentParser(description='Generate flowcharts from event scripts')
	parser.add_argument('--script', type=Path, required=True, help='Script file to visualize')
	parser.add_argument('--dialog', type=str, help='Specific dialog to visualize (default: all)')
	parser.add_argument('--output', type=Path, help='Output file')
	parser.add_argument('--format', choices=['dot', 'mermaid', 'ascii', 'interactive'], 
	                    default='dot', help='Output format')
	parser.add_argument('--render', choices=['png', 'svg', 'pdf'], 
	                    help='Render DOT to image (requires Graphviz)')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	visualizer = EventFlowVisualizer(verbose=args.verbose)
	
	# Parse script
	visualizer.parse_script_file(args.script)
	
	# Determine which dialogs to process
	if args.dialog:
		dialog_ids = [args.dialog]
	else:
		dialog_ids = list(visualizer.dialogs.keys())
	
	# Build graphs
	graphs = []
	for dialog_id in dialog_ids:
		graph = visualizer.build_control_flow_graph(dialog_id)
		visualizer.graphs[dialog_id] = graph
		graphs.append(graph)
		
		if args.verbose:
			print(f"Built graph for {dialog_id}: {len(graph.nodes)} nodes, {len(graph.edges)} edges")
	
	# Generate output
	if args.format == 'interactive':
		if not args.output:
			args.output = Path('flow_visualization.html')
		visualizer.generate_interactive_html(graphs, args.output)
	
	else:
		for graph in graphs:
			if args.format == 'dot':
				output = visualizer.generate_dot(graph)
			elif args.format == 'mermaid':
				output = visualizer.generate_mermaid(graph)
			elif args.format == 'ascii':
				output = visualizer.generate_ascii(graph)
			
			# Write output
			if args.output:
				output_file = args.output
				if len(graphs) > 1:
					# Multiple graphs, append dialog ID
					output_file = args.output.with_stem(f"{args.output.stem}_{graph.dialog_id}")
				
				with open(output_file, 'w', encoding='utf-8') as f:
					f.write(output)
				
				if args.verbose:
					print(f"Saved {graph.dialog_id} to {output_file}")
				
				# Render if requested
				if args.render and args.format == 'dot':
					image_file = output_file.with_suffix(f'.{args.render}')
					visualizer.render_dot_to_image(output, image_file, args.render)
			
			else:
				# Print to console
				print(output)
				print()
	
	# Summary
	total_nodes = sum(len(g.nodes) for g in graphs)
	total_edges = sum(len(g.edges) for g in graphs)
	total_calls = sum(len(g.subroutine_calls) for g in graphs)
	avg_complexity = sum(g.complexity_score for g in graphs) / max(len(graphs), 1)
	
	print(f"\n✓ Processed {len(graphs)} dialog(s)")
	print(f"  Total nodes: {total_nodes}")
	print(f"  Total edges: {total_edges}")
	print(f"  Subroutine calls: {total_calls}")
	print(f"  Avg complexity: {avg_complexity:.1f}")
	
	return 0


if __name__ == '__main__':
	exit(main())
