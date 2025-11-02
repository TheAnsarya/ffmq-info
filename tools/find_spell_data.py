#!/usr/bin/env python3
"""
ROM Scanner to Find Spell Data Table
Searches for patterns that match expected spell data structure
"""

import sys
from pathlib import Path

def scan_rom_for_spell_data(rom_path):
	"""Scan ROM for potential spell data tables"""

	with open(rom_path, 'rb') as f:
		rom = f.read()

	print("="*80)
	print("Scanning ROM for Spell Data Tables")
	print("="*80)
	print()

	# Known: Items are at $066000-$0663FF
	# Expected spell data structure (from docs):
	# +$00: Base power (1 byte) - reasonable range: 10-100
	# +$01: MP cost (1 byte) - reasonable range: 1-20
	# +$02: Element (1 byte) - valid: 0-4
	# +$03: Target flags (1 byte)
	# +$04: Animation ID (1 byte)
	# Entry size: 5-8 bytes

	# FFMQ has ~12 spells (Cure, Heal, Life, Fire, Blizzard, Thunder, etc.)

	candidates = []

	# Scan ROM in data banks near item data
	# Items at $066000, so check surrounding areas
	search_ranges = [
		(0x030000, 0x038000, "Bank $06"),
		(0x038000, 0x040000, "Bank $07"),
		(0x040000, 0x048000, "Bank $08"),
		(0x060000, 0x068000, "Bank $0C (item area)"),
		(0x068000, 0x070000, "Bank $0D"),
	]

	for start, end, bank_name in search_ranges:
		print(f"\nScanning {bank_name} (${start:06X}-${end:06X})...")

		# Look for sequences that match spell data patterns
		# Try different entry sizes: 5, 6, 8 bytes
		for entry_size in [5, 6, 8]:
			for addr in range(start, end - 256, entry_size):
				# Read potential spell entry
				if addr + 16 * entry_size > len(rom):  # Need space for ~16 spells
					continue

				# Check if this could be start of spell table
				valid_entries = 0
				non_zero_entries = 0

				for i in range(16):  # Check up to 16 entries
					offset = addr + (i * entry_size)
					if offset + entry_size > len(rom):
						break

					power = rom[offset]
					mp_cost = rom[offset + 1]

					# Validate entry - more strict criteria
					is_valid = (
						((power == 0 and mp_cost == 0) or  # Empty slot
						 (15 <= power <= 100 and 1 <= mp_cost <= 20))  # Valid spell
					)

					if is_valid:
						valid_entries += 1
						if power > 0 or mp_cost > 0:
							non_zero_entries += 1

				# If we found a good cluster, it's a candidate
				# Require at least 8 valid entries with at least 4 non-zero
				if valid_entries >= 8 and non_zero_entries >= 4:
					# Additional check: element bytes should be reasonable
					has_good_elements = True
					for i in range(min(8, non_zero_entries)):
						offset = addr + (i * entry_size)
						if offset + 3 <= len(rom):
							elem = rom[offset + 2]
							if elem > 5:  # Element should be 0-4, or 5 for special
								has_good_elements = False
								break

					if has_good_elements:
						candidates.append((addr, valid_entries, non_zero_entries, entry_size, bank_name))

	print()
	print("="*80)
	print(f"Found {len(candidates)} potential spell data tables")
	print("="*80)
	print()

	if candidates:
		# Sort by non-zero entries (most likely first), then by valid entries
		candidates.sort(key=lambda x: (x[2], x[1]), reverse=True)

		print(f"{'ROM Offset':<12} {'Size':<6} {'Valid':<7} {'NonZero':<9} {'Bank':<20} {'Confidence'}")
		print("-"*80)

		for addr, valid, nonzero, size, bank in candidates[:15]:  # Show top 15
			confidence = "HIGH" if nonzero >= 8 else "MEDIUM" if nonzero >= 5 else "LOW"
			print(f"${addr:06X}      {size:<6} {valid:<7} {nonzero:<9} {bank:<20} {confidence}")

		print()
		print("="*80)
		print("Detailed Analysis of Top Candidates")
		print("="*80)

		# Analyze top 3 candidates in detail
		for cand_idx in range(min(3, len(candidates))):
			print()
			top_addr, top_valid, top_nonzero, top_size, top_bank = candidates[cand_idx]
			print(f"\nCandidate #{cand_idx + 1}: ${top_addr:06X} ({top_bank}, {top_size}-byte entries)")
			print(f"Valid: {top_valid}, Non-Zero: {top_nonzero}")
			print()
			print(f"{'ID':<4} {'Power':<7} {'MP':<5} {'Elem':<6} {'Byte3':<7} {'Byte4':<7} {'Hex Data'}")
			print("-"*80)

			for i in range(16):
				offset = top_addr + (i * top_size)
				if offset + top_size > len(rom):
					break

				data = rom[offset:offset+top_size]
				power, mp = data[0], data[1]
				elem = data[2] if len(data) > 2 else 0
				b3 = data[3] if len(data) > 3 else 0
				b4 = data[4] if len(data) > 4 else 0

				elem_names = {0: 'None', 1: 'Fire', 2: 'Water', 3: 'Wind', 4: 'Earth'}
				elem_str = elem_names.get(elem, f'${elem:02X}')

				hex_str = ' '.join(f'{b:02X}' for b in data)

				# Highlight non-zero entries
				marker = " *" if (power > 0 or mp > 0) else ""
				print(f"{i:<4} {power:<7} {mp:<5} {elem_str:<6} ${b3:02X}     ${b4:02X}     {hex_str}{marker}")

	else:
		print("No potential spell data tables found.")
		print("The data structure or location assumptions may be incorrect.")
		print("\nTrying alternative search strategy...")

		# Alternative: Look for consecutive reasonable MP costs
		print("\nSearching for MP cost patterns (1-20 range)...")
		for start, end, bank_name in search_ranges:
			for addr in range(start, end - 64):
				# Look for 8+ consecutive bytes in range 1-20
				mp_sequence = rom[addr:addr+16]
				valid_mp = sum(1 for b in mp_sequence if 1 <= b <= 20)
				if valid_mp >= 8:
					print(f"  Possible MP costs at ${addr:06X}: {' '.join(f'{b:02d}' for b in mp_sequence[:12])}")

	return candidates

def main():
	if len(sys.argv) < 2:
		print("Usage: find_spell_data.py <rom_file>")
		sys.exit(1)

	rom_path = sys.argv[1]

	if not Path(rom_path).exists():
		print(f"Error: ROM file not found: {rom_path}")
		sys.exit(1)

	candidates = scan_rom_for_spell_data(rom_path)

	if candidates:
		top_addr, _, _, top_size, _ = candidates[0]
		print()
		print("="*80)
		print("RECOMMENDATION")
		print("="*80)
		print(f"Update SPELL_DATA_ADDRESS in extract_spells.py to: 0x{top_addr:06X}")
		print(f"Update SPELL_ENTRY_SIZE to: {top_size}")
		print()
	else:
		print()
		print("="*80)
		print("NO CLEAR CANDIDATES FOUND")
		print("="*80)
		print("Next steps:")
		print("1. Check battle code for spell data loading")
		print("2. Examine save states during spell casting")
		print("3. Review disassembly for data table pointers")
		print("="*80)

if __name__ == '__main__':
	main()
