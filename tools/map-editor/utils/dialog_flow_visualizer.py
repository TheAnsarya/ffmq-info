"""
Dialog Flow Visualizer - Visualize dialog relationships and conversation flows

Features:
- Visual graph of dialog connections
- NPC conversation trees
- Flag-based dialog branches
- Export to graphviz/mermaid
"""

import re
from typing import Dict, List, Set, Tuple, Optional
from dataclasses import dataclass, field
from collections import defaultdict


@dataclass
class DialogNode:
	"""Represents a node in the dialog flow graph"""
	dialog_id: int
	text_preview: str  # First ~50 chars
	npc_id: Optional[int] = None
	npc_name: str = "Unknown"
	map_id: Optional[int] = None
	
	# Connections
	next_dialogs: List[int] = field(default_factory=list)  # Direct successors
	flag_requirements: Dict[int, List[int]] = field(default_factory=dict)  # flag_id -> dialog_ids
	item_requirements: Dict[int, List[int]] = field(default_factory=dict)  # item_id -> dialog_ids
	
	# Metadata
	is_entry_point: bool = False  # Starting dialog for an NPC
	is_terminal: bool = False  # Has no successors
	visit_count: int = 0  # For analysis


@dataclass
class ConversationPath:
	"""Represents a path through a conversation"""
	dialogs: List[int]
	flags_required: Set[int]
	items_required: Set[int]
	length: int = 0
	
	def __post_init__(self):
		self.length = len(self.dialogs)


class DialogFlowGraph:
	"""Builds and analyzes dialog flow graphs"""
	
	def __init__(self):
		self.nodes: Dict[int, DialogNode] = {}
		self.edges: List[Tuple[int, int, str]] = []  # (from_id, to_id, label)
	
	def add_node(self, node: DialogNode):
		"""Add a dialog node to the graph"""
		self.nodes[node.dialog_id] = node
	
	def add_edge(self, from_id: int, to_id: int, label: str = ""):
		"""Add an edge between dialogs"""
		self.edges.append((from_id, to_id, label))
		
		# Update node connections
		if from_id in self.nodes:
			if to_id not in self.nodes[from_id].next_dialogs:
				self.nodes[from_id].next_dialogs.append(to_id)
	
	def build_from_event_scripts(self, event_scripts: Dict[int, any]):
		"""
		Build graph from event script analysis
		
		Analyzes SHOW_DIALOG commands and conditional branches
		"""
		for script_id, script in event_scripts.items():
			# Parse script for SHOW_DIALOG commands
			dialog_sequence = []
			current_flags = set()
			current_items = set()
			
			for line in script.split('\n'):
				line = line.strip()
				
				# SHOW_DIALOG command
				if line.startswith('SHOW_DIALOG'):
					match = re.search(r'SHOW_DIALOG\s+0x([0-9A-Fa-f]+)', line)
					if match:
						dialog_id = int(match.group(1), 16)
						dialog_sequence.append(dialog_id)
				
				# Flag checks
				elif line.startswith('CHECK_FLAG'):
					match = re.search(r'CHECK_FLAG\s+0x([0-9A-Fa-f]+)', line)
					if match:
						flag_id = int(match.group(1), 16)
						current_flags.add(flag_id)
				
				# Item checks
				elif line.startswith('CHECK_ITEM'):
					match = re.search(r'CHECK_ITEM\s+0x([0-9A-Fa-f]+)', line)
					if match:
						item_id = int(match.group(1), 16)
						current_items.add(item_id)
			
			# Create edges for sequential dialogs
			for i in range(len(dialog_sequence) - 1):
				from_id = dialog_sequence[i]
				to_id = dialog_sequence[i + 1]
				
				label = ""
				if current_flags:
					label = f"Flag {list(current_flags)[0]:04X}"
				elif current_items:
					label = f"Item {list(current_items)[0]:04X}"
				
				self.add_edge(from_id, to_id, label)
	
	def find_all_paths(self, start_id: int, max_depth: int = 10) -> List[ConversationPath]:
		"""
		Find all possible conversation paths from a starting dialog
		
		Args:
			start_id: Starting dialog ID
			max_depth: Maximum path length to explore
		
		Returns:
			List of ConversationPath objects
		"""
		paths = []
		
		def explore(current_id: int, path: List[int], flags: Set[int], items: Set[int], depth: int):
			if depth > max_depth:
				return
			
			if current_id not in self.nodes:
				return
			
			node = self.nodes[current_id]
			
			# Add current dialog to path
			new_path = path + [current_id]
			
			# If terminal node, save path
			if node.is_terminal or not node.next_dialogs:
				paths.append(ConversationPath(
					dialogs=new_path,
					flags_required=flags.copy(),
					items_required=items.copy()
				))
				return
			
			# Explore next dialogs
			for next_id in node.next_dialogs:
				explore(next_id, new_path, flags, items, depth + 1)
			
			# Explore flag-based branches
			for flag_id, next_ids in node.flag_requirements.items():
				new_flags = flags | {flag_id}
				for next_id in next_ids:
					explore(next_id, new_path, new_flags, items, depth + 1)
			
			# Explore item-based branches
			for item_id, next_ids in node.item_requirements.items():
				new_items = items | {item_id}
				for next_id in next_ids:
					explore(next_id, new_path, flags, new_items, depth + 1)
		
		explore(start_id, [], set(), set(), 0)
		return paths
	
	def find_entry_points(self) -> List[int]:
		"""
		Find dialog entry points (dialogs with no predecessors)
		
		Returns:
			List of dialog IDs that are entry points
		"""
		# Get all dialogs that are targets of edges
		targets = {to_id for _, to_id, _ in self.edges}
		
		# Entry points are nodes not in targets
		entry_points = [
			dialog_id for dialog_id in self.nodes.keys()
			if dialog_id not in targets
		]
		
		return entry_points
	
	def find_terminal_nodes(self) -> List[int]:
		"""
		Find terminal dialog nodes (no successors)
		
		Returns:
			List of dialog IDs that are terminal
		"""
		terminal = []
		
		for dialog_id, node in self.nodes.items():
			if not node.next_dialogs and not node.flag_requirements and not node.item_requirements:
				terminal.append(dialog_id)
				node.is_terminal = True
		
		return terminal
	
	def get_npc_conversation_tree(self, npc_id: int) -> Dict[str, any]:
		"""
		Get the complete conversation tree for an NPC
		
		Returns:
			Dictionary with tree structure
		"""
		# Find all dialogs for this NPC
		npc_dialogs = [
			dialog_id for dialog_id, node in self.nodes.items()
			if node.npc_id == npc_id
		]
		
		if not npc_dialogs:
			return {}
		
		# Find entry point (first dialog)
		entry_points = [d for d in npc_dialogs if self.nodes[d].is_entry_point]
		
		if not entry_points:
			# Use first dialog as entry point
			entry_points = [npc_dialogs[0]]
		
		# Build tree from entry point
		tree = {
			'npc_id': npc_id,
			'entry_dialog': entry_points[0],
			'all_dialogs': npc_dialogs,
			'paths': self.find_all_paths(entry_points[0])
		}
		
		return tree
	
	def export_to_graphviz(self, output_file: str = "dialog_flow.dot"):
		"""
		Export graph to Graphviz DOT format
		
		Args:
			output_file: Path to output .dot file
		"""
		lines = ['digraph DialogFlow {']
		lines.append('  rankdir=TB;')
		lines.append('  node [shape=box, style=rounded];')
		lines.append('')
		
		# Add nodes
		for dialog_id, node in self.nodes.items():
			label = f"{dialog_id:04X}: {node.text_preview[:30]}..."
			
			style = ""
			if node.is_entry_point:
				style = ', style=filled, fillcolor=lightgreen'
			elif node.is_terminal:
				style = ', style=filled, fillcolor=lightcoral'
			
			lines.append(f'  n{dialog_id:04X} [label="{label}"{style}];')
		
		lines.append('')
		
		# Add edges
		for from_id, to_id, label in self.edges:
			edge_label = f' [label="{label}"]' if label else ''
			lines.append(f'  n{from_id:04X} -> n{to_id:04X}{edge_label};')
		
		lines.append('}')
		
		with open(output_file, 'w', encoding='utf-8') as f:
			f.write('\n'.join(lines))
	
	def export_to_mermaid(self, output_file: str = "dialog_flow.mmd"):
		"""
		Export graph to Mermaid diagram format
		
		Args:
			output_file: Path to output .mmd file
		"""
		lines = ['graph TD']
		
		# Add nodes
		for dialog_id, node in self.nodes.items():
			label = f"{dialog_id:04X}: {node.text_preview[:20]}..."
			
			shape_start = "["
			shape_end = "]"
			
			if node.is_entry_point:
				shape_start = "(("
				shape_end = "))"
			elif node.is_terminal:
				shape_start = "{"
				shape_end = "}"
			
			lines.append(f'  {dialog_id:04X}{shape_start}"{label}"{shape_end}')
		
		# Add edges
		for from_id, to_id, label in self.edges:
			edge = f'  {from_id:04X} -->|{label}| {to_id:04X}' if label else f'  {from_id:04X} --> {to_id:04X}'
			lines.append(edge)
		
		with open(output_file, 'w', encoding='utf-8') as f:
			f.write('\n'.join(lines))
	
	def analyze_complexity(self) -> Dict[str, any]:
		"""
		Analyze dialog flow complexity
		
		Returns:
			Dictionary with complexity metrics
		"""
		total_nodes = len(self.nodes)
		total_edges = len(self.edges)
		
		# Count branching
		branching_nodes = sum(1 for node in self.nodes.values() if len(node.next_dialogs) > 1)
		
		# Find longest path
		entry_points = self.find_entry_points()
		longest_path = 0
		
		for entry in entry_points:
			paths = self.find_all_paths(entry)
			if paths:
				longest_path = max(longest_path, max(p.length for p in paths))
		
		# Calculate average outdegree
		avg_outdegree = total_edges / total_nodes if total_nodes > 0 else 0
		
		# Count cycles
		has_cycles = self._detect_cycles()
		
		return {
			'total_dialogs': total_nodes,
			'total_connections': total_edges,
			'branching_points': branching_nodes,
			'longest_path': longest_path,
			'average_outdegree': avg_outdegree,
			'has_cycles': has_cycles,
			'entry_points': len(entry_points),
			'terminal_nodes': len(self.find_terminal_nodes())
		}
	
	def _detect_cycles(self) -> bool:
		"""Detect if graph has cycles using DFS"""
		visited = set()
		rec_stack = set()
		
		def dfs(node_id: int) -> bool:
			visited.add(node_id)
			rec_stack.add(node_id)
			
			if node_id in self.nodes:
				for next_id in self.nodes[node_id].next_dialogs:
					if next_id not in visited:
						if dfs(next_id):
							return True
					elif next_id in rec_stack:
						return True
			
			rec_stack.remove(node_id)
			return False
		
		for node_id in self.nodes:
			if node_id not in visited:
				if dfs(node_id):
					return True
		
		return False


def demo_flow_visualizer():
	"""Demo dialog flow visualization"""
	
	# Create graph
	graph = DialogFlowGraph()
	
	# Add nodes
	graph.add_node(DialogNode(
		dialog_id=0x0001,
		text_preview="Welcome to Foresta!",
		npc_id=1,
		npc_name="Old Man",
		is_entry_point=True
	))
	
	graph.add_node(DialogNode(
		dialog_id=0x0002,
		text_preview="The Crystal is in the temple.",
		npc_id=1,
		npc_name="Old Man"
	))
	
	graph.add_node(DialogNode(
		dialog_id=0x0003,
		text_preview="You found the Crystal!",
		npc_id=1,
		npc_name="Old Man",
		is_terminal=True
	))
	
	graph.add_node(DialogNode(
		dialog_id=0x0004,
		text_preview="You don't have the Crystal yet.",
		npc_id=1,
		npc_name="Old Man",
		is_terminal=True
	))
	
	# Add edges
	graph.add_edge(0x0001, 0x0002, "First talk")
	graph.add_edge(0x0002, 0x0003, "Has Crystal")
	graph.add_edge(0x0002, 0x0004, "No Crystal")
	
	# Find paths
	print("=== Conversation Paths ===")
	paths = graph.find_all_paths(0x0001)
	for i, path in enumerate(paths, 1):
		dialog_str = " -> ".join(f"0x{d:04X}" for d in path.dialogs)
		print(f"Path {i}: {dialog_str}")
		if path.flags_required:
			print(f"  Requires flags: {[f'0x{f:04X}' for f in path.flags_required]}")
	
	# Analyze complexity
	print("\n=== Complexity Analysis ===")
	complexity = graph.analyze_complexity()
	for key, value in complexity.items():
		print(f"{key}: {value}")
	
	# Export
	print("\n=== Exports ===")
	graph.export_to_graphviz("demo_dialog_flow.dot")
	print("Exported to demo_dialog_flow.dot")
	
	graph.export_to_mermaid("demo_dialog_flow.mmd")
	print("Exported to demo_dialog_flow.mmd")


if __name__ == '__main__':
	demo_flow_visualizer()
