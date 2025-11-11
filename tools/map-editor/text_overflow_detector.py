"""
Text Overflow Detector for FFMQ Dialog System

Analyzes dialog text to detect when it exceeds dialog box capacity.

FFMQ Dialog Box Specifications (estimated):
- Characters per line: ~32 (varies by character width)
- Lines per page: 3
- Characters per page: ~96
- Maximum pages per dialog: ~4 (with [PAGE] breaks)

Control Codes:
- [PARA]: New paragraph (newline within same page)
- [PAGE]: New page (next dialog box)
- Other codes don't affect layout significantly

This tool:
1. Analyzes each dialog's text layout
2. Simulates dialog box rendering
3. Detects overflow conditions
4. Suggests [PARA] and [PAGE] placements
5. Reports problematic dialogs
"""

import sys
from pathlib import Path
import re

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent))

from utils.dialog_database import DialogDatabase


class DialogBoxSimulator:
	"""Simulates FFMQ dialog box layout"""

	# Dialog box dimensions (estimated from game)
	CHARS_PER_LINE = 32      # Maximum characters per line
	LINES_PER_PAGE = 3       # Lines per dialog box
	MAX_PAGES = 4            # Maximum pages per dialog

	# Character widths (proportional font approximation)
	# Most chars are 8px, some are narrower (.,!i) or wider (WMm@)
	CHAR_WIDTHS = {
		# Narrow characters (4-6px)
		'.': 0.5, ',': 0.5, '!': 0.5, 'i': 0.5, 'l': 0.5, "'": 0.5,
		' ': 0.5,

		# Wide characters (10-12px)
		'W': 1.5, 'M': 1.5, 'm': 1.25, 'w': 1.25, '@': 1.5,

		# Default width (8px)
	}
	DEFAULT_CHAR_WIDTH = 1.0

	def __init__(self):
		"""Initialize simulator"""
		pass

	def calculate_line_width(self, text: str) -> float:
		"""Calculate line width in character units

		Args:
			text: Line text

		Returns:
			Width in character units (1.0 = average character)
		"""
		width = 0.0
		for char in text:
			width += self.CHAR_WIDTHS.get(char, self.DEFAULT_CHAR_WIDTH)
		return width

	def simulate_layout(self, text: str) -> dict:
		"""Simulate dialog box layout

		Args:
			text: Dialog text with [PARA] and [PAGE] codes

		Returns:
			Dict with layout information:
			- pages: List of pages, each containing list of lines
			- overflow_lines: Lines that exceed max width
			- overflow_pages: Pages that exceed max lines
			- total_pages: Total number of pages
			- warnings: List of warning messages
		"""
		# Remove non-layout control codes
		text = re.sub(r'\[(?!PARA|PAGE)[^\]]+\]', '', text)

		# Split by [PAGE]
		pages_text = text.split('[PAGE]')

		pages = []
		overflow_lines = []
		overflow_pages = []
		warnings = []

		for page_num, page_text in enumerate(pages_text, 1):
			# Split by [PARA] (newlines within page)
			lines_text = page_text.split('[PARA]')

			page_lines = []

			for line_num, line_text in enumerate(lines_text, 1):
				# Clean up the line
				line = line_text.strip()

				if not line:
					continue

				# Calculate line width
				width = self.calculate_line_width(line)

				page_lines.append({
					'text': line,
					'width': width,
					'exceeds_width': width > self.CHARS_PER_LINE
				})

				if width > self.CHARS_PER_LINE:
					overflow_lines.append({
						'page': page_num,
						'line': line_num,
						'text': line,
						'width': width,
						'excess': width - self.CHARS_PER_LINE
					})
					warnings.append(
						f"Page {page_num}, Line {line_num}: Exceeds width "
						f"by {width - self.CHARS_PER_LINE:.1f} chars"
					)

			# Check if page exceeds max lines
			if len(page_lines) > self.LINES_PER_PAGE:
				overflow_pages.append({
					'page': page_num,
					'lines': len(page_lines),
					'excess': len(page_lines) - self.LINES_PER_PAGE
				})
				warnings.append(
					f"Page {page_num}: Has {len(page_lines)} lines "
					f"(max {self.LINES_PER_PAGE})"
				)

			pages.append(page_lines)

		# Check total pages
		if len(pages) > self.MAX_PAGES:
			warnings.append(
				f"Dialog has {len(pages)} pages (max {self.MAX_PAGES})"
			)

		return {
			'pages': pages,
			'overflow_lines': overflow_lines,
			'overflow_pages': overflow_pages,
			'total_pages': len(pages),
			'warnings': warnings,
			'has_overflow': len(overflow_lines) > 0 or len(overflow_pages) > 0
		}

	def suggest_breaks(self, text: str) -> str:
		"""Suggest [PARA] and [PAGE] break placements

		Args:
			text: Dialog text without breaks

		Returns:
			Text with suggested breaks inserted
		"""
		# Remove existing breaks
		text = text.replace('[PARA]', ' ').replace('[PAGE]', ' ')

		# Split into sentences (approximate)
		sentences = re.split(r'([.!?]+\s+)', text)

		result_pages = []
		current_page = []
		current_line = []
		current_line_width = 0.0

		for sentence in sentences:
			sentence = sentence.strip()
			if not sentence:
				continue

			# Split sentence into words
			words = sentence.split()

			for word in words:
				word_width = self.calculate_line_width(word + ' ')

				# Check if word fits on current line
				if current_line_width + word_width > self.CHARS_PER_LINE:
					# Start new line
					current_page.append(' '.join(current_line))
					current_line = [word]
					current_line_width = word_width

					# Check if page is full
					if len(current_page) >= self.LINES_PER_PAGE:
						result_pages.append('[PARA]'.join(current_page))
						current_page = []
				else:
					current_line.append(word)
					current_line_width += word_width

		# Add remaining text
		if current_line:
			current_page.append(' '.join(current_line))
		if current_page:
			result_pages.append('[PARA]'.join(current_page))

		return '[PAGE]'.join(result_pages)


class TextOverflowDetector:
	"""Detect text overflow issues in all dialogs"""

	def __init__(self, rom_path: str):
		"""Initialize detector

		Args:
			rom_path: Path to ROM file
		"""
		self.db = DialogDatabase(Path(rom_path))
		self.db.extract_all_dialogs()

		self.simulator = DialogBoxSimulator()

	def analyze_all_dialogs(self) -> list:
		"""Analyze all dialogs for overflow

		Returns:
			List of dicts with dialog_id and layout info
		"""
		results = []

		for dialog_id, entry in sorted(self.db.dialogs.items()):
			layout = self.simulator.simulate_layout(entry.text)

			if layout['has_overflow'] or len(layout['warnings']) > 0:
				results.append({
					'id': dialog_id,
					'text': entry.text,
					'layout': layout
				})

		return results

	def generate_report(self):
		"""Generate overflow detection report"""
		print("=" * 70)
		print("Dialog Text Overflow Detection")
		print("=" * 70)
		print()

		print("Dialog Box Specifications:")
		print(f"  Characters per line: {self.simulator.CHARS_PER_LINE}")
		print(f"  Lines per page:      {self.simulator.LINES_PER_PAGE}")
		print(f"  Max pages:           {self.simulator.MAX_PAGES}")
		print()

		# Analyze all dialogs
		print("Analyzing all dialogs...")
		issues = self.analyze_all_dialogs()

		if not issues:
			print("✓ No overflow issues detected!")
			print()
			return

		print(f"Found {len(issues)} dialogs with potential issues")
		print()

		# Group by issue type
		line_overflow = [d for d in issues if d['layout']['overflow_lines']]
		page_overflow = [d for d in issues if d['layout']['overflow_pages']]
		too_many_pages = [d for d in issues if d['layout']['total_pages'] > self.simulator.MAX_PAGES]

		print("Issue Summary:")
		print(f"  Line overflow:  {len(line_overflow)} dialogs")
		print(f"  Page overflow:  {len(page_overflow)} dialogs")
		print(f"  Too many pages: {len(too_many_pages)} dialogs")
		print()

		# Show detailed issues
		print("Detailed Issues:")
		print("-" * 70)

		for issue in issues[:20]:  # Show first 20
			dialog_id = issue['id']
			layout = issue['layout']

			print(f"\nDialog 0x{dialog_id:04X}:")
			print(f"  Pages: {layout['total_pages']}")

			if layout['warnings']:
				for warning in layout['warnings']:
					print(f"  ⚠ {warning}")

			# Show first few lines of text
			text_preview = issue['text'][:60]
			if len(issue['text']) > 60:
				text_preview += "..."
			print(f"  Text: {text_preview}")

		if len(issues) > 20:
			print(f"\n... and {len(issues) - 20} more issues")

		print()

		# Recommendations
		print("Recommendations:")
		print("-" * 70)
		print("• Use [PARA] to break long lines into multiple lines")
		print("• Use [PAGE] to split text across multiple dialog boxes")
		print("• Edit text to reduce length where possible")
		print("• Use compression-friendly DTE sequences")
		print()

		# Show example fix for first issue
		if issues:
			first = issues[0]
			print(f"Example Fix for Dialog 0x{first['id']:04X}:")
			print("-" * 70)
			print("Original:")
			print(f"  {first['text'][:100]}")
			print()
			print("Suggested:")
			suggested = self.simulator.suggest_breaks(first['text'])
			print(f"  {suggested[:100]}")
			print()


def main():
	"""Main entry point"""
	if len(sys.argv) < 2:
		print("Usage: python text_overflow_detector.py <rom_file>")
		print()
		print("Example:")
		print('  python text_overflow_detector.py "Final Fantasy - Mystic Quest (U) (V1.1).smc"')
		return 1

	rom_path = sys.argv[1]

	if not Path(rom_path).exists():
		print(f"Error: ROM file not found: {rom_path}")
		return 1

	try:
		detector = TextOverflowDetector(rom_path)
		detector.generate_report()

		return 0

	except Exception as e:
		print(f"Error: {e}")
		import traceback
		traceback.print_exc()
		return 1


if __name__ == '__main__':
	sys.exit(main())
