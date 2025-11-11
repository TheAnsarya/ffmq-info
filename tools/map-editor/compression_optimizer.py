"""
DTE Compression Optimizer for FFMQ

Analyzes all dialog text to find optimal multi-character sequences
for the DTE (Dual Tile Encoding) compression table.

Current compression: 57.9% (9,876 chars → 4,162 bytes)
Goal: Find better sequences to improve to 60%+ compression

Algorithm:
1. Extract all dialog text
2. Find all 2-20 character substrings
3. Count frequency of each substring
4. Calculate compression benefit (frequency × (length - 1))
5. Recommend top candidates for DTE table
"""

import sys
from pathlib import Path
from collections import Counter, defaultdict
import re

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent))

from utils.dialog_database import DialogDatabase
from utils.dialog_text import DialogText, CharacterTable


class CompressionOptimizer:
    """Optimize DTE compression table"""

    def __init__(self, rom_path: str, table_path: str = "complex.tbl"):
        """Initialize optimizer

        Args:
            rom_path: Path to ROM file
            table_path: Path to character table
        """
        self.db = DialogDatabase(Path(rom_path))
        self.db.extract_all_dialogs()

        self.char_table = CharacterTable(Path(table_path))

        # Get all dialog text
        self.all_text = self._extract_all_text()

    def _extract_all_text(self) -> str:
        """Extract all dialog text concatenated"""
        texts = []
        for entry in self.db.dialogs.values():
            # Remove control codes for analysis
            text = entry.text
            text = re.sub(r'\[[^\]]+\]', '', text)  # Remove [TAGS]
            texts.append(text)

        return '\n'.join(texts)

    def find_substring_frequencies(self, min_length: int = 2, max_length: int = 20) -> dict:
        """Find frequency of all substrings

        Args:
            min_length: Minimum substring length
            max_length: Maximum substring length

        Returns:
            Dict mapping substring -> frequency
        """
        frequencies = Counter()

        # Count substrings of each length
        for length in range(min_length, max_length + 1):
            for i in range(len(self.all_text) - length + 1):
                substring = self.all_text[i:i+length]

                # Skip substrings with newlines or only whitespace
                if '\n' in substring or substring.strip() == '':
                    continue

                frequencies[substring] += 1

        return dict(frequencies)

    def calculate_compression_benefit(self, frequencies: dict) -> list:
        """Calculate compression benefit for each substring

        Benefit = frequency × (length - 1) bytes saved

        Args:
            frequencies: Dict of substring -> frequency

        Returns:
            List of (substring, frequency, benefit, length) tuples sorted by benefit
        """
        candidates = []

        for substring, frequency in frequencies.items():
            length = len(substring)

            # Skip if frequency too low (not worth encoding)
            if frequency < 3:
                continue

            # Skip if already in DTE table
            if self._is_in_dte_table(substring):
                continue

            # Calculate bytes saved: frequency × (length - 1)
            # Each occurrence saves (length - 1) bytes
            benefit = frequency * (length - 1)

            candidates.append((substring, frequency, benefit, length))

        # Sort by benefit descending
        candidates.sort(key=lambda x: x[2], reverse=True)

        return candidates

    def _is_in_dte_table(self, substring: str) -> bool:
        """Check if substring is already in DTE table"""
        # Check if it's a DTE sequence
        for byte_val in range(0x3D, 0x7F):
            if byte_val in self.char_table.byte_to_char:
                chars = self.char_table.byte_to_char[byte_val]
                if chars == substring:
                    return True
        return False

    def analyze_current_table(self) -> dict:
        """Analyze current DTE table efficiency

        Returns:
            Dict with statistics about current DTE usage
        """
        stats = {
            'total_dte_sequences': 0,
            'used_sequences': 0,
            'unused_sequences': [],
            'frequencies': {},
            'total_benefit': 0
        }

        # Count DTE sequences in table
        for byte_val in range(0x3D, 0x7F):
            if byte_val in self.char_table.byte_to_char:
                stats['total_dte_sequences'] += 1
                chars = self.char_table.byte_to_char[byte_val]

                # Count occurrences in text
                freq = self.all_text.count(chars)

                if freq > 0:
                    stats['used_sequences'] += 1
                    stats['frequencies'][chars] = freq
                    stats['total_benefit'] += freq * (len(chars) - 1)
                else:
                    stats['unused_sequences'].append((byte_val, chars))

        return stats

    def generate_report(self, top_n: int = 50):
        """Generate optimization report

        Args:
            top_n: Number of top candidates to show
        """
        print("=" * 70)
        print("DTE Compression Optimization Analysis")
        print("=" * 70)
        print()

        # Current table analysis
        print("Current DTE Table Statistics")
        print("-" * 70)
        stats = self.analyze_current_table()

        print(f"Total DTE sequences in table: {stats['total_dte_sequences']}")
        print(f"Used sequences:               {stats['used_sequences']}")
        print(f"Unused sequences:             {len(stats['unused_sequences'])}")
        print(f"Total bytes saved:            {stats['total_benefit']}")
        print()

        if stats['unused_sequences']:
            print("Unused DTE Sequences (could be replaced):")
            for byte_val, chars in stats['unused_sequences'][:10]:
                print(f"  0x{byte_val:02X} = '{chars}'")
            if len(stats['unused_sequences']) > 10:
                print(f"  ... and {len(stats['unused_sequences']) - 10} more")
            print()

        # Top used sequences
        print("Top 10 Most Used DTE Sequences:")
        top_used = sorted(stats['frequencies'].items(), key=lambda x: x[1], reverse=True)[:10]
        for chars, freq in top_used:
            benefit = freq * (len(chars) - 1)
            print(f"  '{chars}' (len={len(chars)}): {freq} times, saves {benefit} bytes")
        print()

        # Find candidates
        print(f"Analyzing substrings (2-20 characters)...")
        frequencies = self.find_substring_frequencies()
        candidates = self.calculate_compression_benefit(frequencies)

        print(f"Found {len(candidates)} candidate sequences")
        print()

        # Show top candidates
        print(f"Top {top_n} Compression Candidates:")
        print("-" * 70)
        print(f"{'Rank':<6} {'Substring':<25} {'Freq':<6} {'Len':<5} {'Benefit':<8}")
        print("-" * 70)

        for i, (substring, frequency, benefit, length) in enumerate(candidates[:top_n], 1):
            # Escape newlines and tabs for display
            display = substring.replace('\n', '\\n').replace('\t', '\\t')
            if len(display) > 22:
                display = display[:22] + '...'

            print(f"{i:<6} {display:<25} {frequency:<6} {length:<5} {benefit:<8}")

        print()

        # Recommendations
        print("Recommendations:")
        print("-" * 70)

        # Calculate potential improvement
        if candidates:
            # If we replace unused sequences with top candidates
            replaceable = len(stats['unused_sequences'])
            if replaceable > 0:
                potential_savings = sum(c[2] for c in candidates[:replaceable])
                current_size = sum(len(entry.raw_bytes) for entry in self.db.dialogs.values())

                print(f"• Replace {replaceable} unused DTE sequences with top candidates")
                print(f"• Potential additional bytes saved: ~{potential_savings}")
                print(f"• Current compressed size: {current_size} bytes")
                print(f"• Potential compressed size: ~{current_size - potential_savings} bytes")

                current_ratio = (current_size / len(self.all_text)) * 100
                new_ratio = ((current_size - potential_savings) / len(self.all_text)) * 100

                print(f"• Current compression ratio: {current_ratio:.1f}%")
                print(f"• Potential compression ratio: {new_ratio:.1f}%")
                print(f"• Improvement: {current_ratio - new_ratio:.1f} percentage points")
            else:
                print("• All DTE sequences are in use")
                print("• Consider reorganizing table to prioritize high-benefit sequences")

        print()

        # Specific recommendations
        print("Suggested DTE Table Changes:")
        print("-" * 70)

        if stats['unused_sequences'] and candidates:
            print("\nReplace these unused sequences:")
            for i, (byte_val, old_chars) in enumerate(stats['unused_sequences'][:10]):
                if i < len(candidates):
                    new_chars, freq, benefit, length = candidates[i]
                    print(f"  0x{byte_val:02X}: '{old_chars}' → '{new_chars}' (saves {benefit} bytes)")

        print()


def main():
    """Main entry point"""
    if len(sys.argv) < 2:
        print("Usage: python compression_optimizer.py <rom_file>")
        print()
        print("Example:")
        print('  python compression_optimizer.py "Final Fantasy - Mystic Quest (U) (V1.1).smc"')
        return 1

    rom_path = sys.argv[1]

    if not Path(rom_path).exists():
        print(f"Error: ROM file not found: {rom_path}")
        return 1

    try:
        optimizer = CompressionOptimizer(rom_path)
        optimizer.generate_report(top_n=50)

        return 0

    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
        return 1


if __name__ == '__main__':
    sys.exit(main())
