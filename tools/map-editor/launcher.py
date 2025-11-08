"""
FFMQ Dialog Toolkit Launcher

Provides easy access to all dialog editing tools through a command-line interface.
"""

import argparse
import subprocess
import sys
from pathlib import Path


# Tool definitions
TOOLS = {
	'suite': {
		'script': 'dialog_suite.py',
		'description': 'Launch the complete Dialog Suite GUI application',
		'args': []
	},
	'browser': {
		'script': 'ui/dialog_browser.py',
		'description': 'Launch the Dialog Browser (standalone)',
		'args': []
	},
	'table-editor': {
		'script': 'ui/character_table_editor.py',
		'description': 'Launch the Character Table Editor',
		'args': ['--file', 'complex.tbl']
	},
	'optimizer': {
		'script': 'utils/character_table_optimizer.py',
		'description': 'Run the Character Table Optimizer (command-line)',
		'args': []
	},
	'npc-manager': {
		'script': 'utils/npc_dialog_manager.py',
		'description': 'Launch the NPC Dialog Manager demo',
		'args': []
	},
	'search': {
		'script': 'utils/dialog_search.py',
		'description': 'Launch the Dialog Search Engine demo',
		'args': []
	},
	'translator': {
		'script': 'utils/translation_helper.py',
		'description': 'Launch the Translation Helper demo',
		'args': []
	},
	'batch-editor': {
		'script': 'utils/batch_dialog_editor.py',
		'description': 'Launch the Batch Dialog Editor demo',
		'args': []
	},
	'flow-viz': {
		'script': 'utils/dialog_flow_visualizer.py',
		'description': 'Launch the Dialog Flow Visualizer demo',
		'args': []
	},
	'format': {
		'script': '../tools/format_to_tabs.py',
		'description': 'Run the tab formatter on all Python files',
		'args': []
	},
	'validator': {
		'script': 'utils/dialog_validator.py',
		'description': 'Validate dialog database integrity',
		'args': []
	},
	'exporter': {
		'script': 'utils/dialog_exporter.py',
		'description': 'Export dialogs to various formats (CSV, JSON, XML, etc.)',
		'args': []
	},
	'diff': {
		'script': 'utils/dialog_diff.py',
		'description': 'Compare and merge dialog databases',
		'args': []
	},
}


def print_banner():
	"""Print welcome banner"""
	print("=" * 70)
	print("  FFMQ Dialog Toolkit")
	print("  Professional tools for Final Fantasy Mystic Quest dialog editing")
	print("=" * 70)
	print()


def list_tools():
	"""List all available tools"""
	print_banner()
	print("Available tools:")
	print()

	max_name_len = max(len(name) for name in TOOLS.keys())

	for name, info in sorted(TOOLS.items()):
		print(f"  {name:<{max_name_len}}  -  {info['description']}")

	print()
	print("Usage: python launcher.py <tool-name>")
	print("Example: python launcher.py suite")
	print()


def run_tool(tool_name: str, extra_args: list = None):
	"""Run the specified tool"""
	if tool_name not in TOOLS:
		print(f"Error: Unknown tool '{tool_name}'")
		print()
		list_tools()
		return 1

	tool = TOOLS[tool_name]
	script_path = Path(__file__).parent / tool['script']

	if not script_path.exists():
		print(f"Error: Tool script not found: {script_path}")
		return 1

	# Build command
	cmd = [sys.executable, str(script_path)]
	cmd.extend(tool['args'])
	if extra_args:
		cmd.extend(extra_args)

	print(f"Launching {tool['description']}...")
	print(f"Command: {' '.join(cmd)}")
	print()

	# Run the tool
	try:
		result = subprocess.run(cmd)
		return result.returncode
	except KeyboardInterrupt:
		print("\nInterrupted by user")
		return 0
	except Exception as e:
		print(f"Error running tool: {e}")
		return 1


def main():
	"""Main entry point"""
	parser = argparse.ArgumentParser(
		description="FFMQ Dialog Toolkit Launcher",
		formatter_class=argparse.RawDescriptionHelpFormatter,
		epilog="""
Available tools:
""" + "\n".join(f"  {name:15} - {info['description']}" for name, info in sorted(TOOLS.items()))
	)

	parser.add_argument('tool', nargs='?', help='Tool to launch')
	parser.add_argument('args', nargs='*', help='Additional arguments to pass to the tool')
	parser.add_argument('--list', '-l', action='store_true', help='List all available tools')

	args = parser.parse_args()

	if args.list or not args.tool:
		list_tools()
		return 0

	return run_tool(args.tool, args.args)


if __name__ == '__main__':
	sys.exit(main())
