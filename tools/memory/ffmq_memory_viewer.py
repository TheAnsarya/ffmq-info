#!/usr/bin/env python3
"""
FFMQ Memory Viewer - ROM and RAM inspection

Memory Features:
- View ROM data
- View RAM data
- Search memory
- Compare memory
- Memory dumps
- Watch addresses

Memory Types:
- ROM (read-only)
- WRAM (work RAM)
- SRAM (save RAM)
- VRAM (video RAM)
- OAM (sprite data)
- CGRAM (palette data)

Address Ranges:
- ROM: 0x000000 - 0x3FFFFF (4 MB max)
- WRAM: 0x7E0000 - 0x7FFFFF (128 KB)
- SRAM: 0x700000 - 0x71FFFF (128 KB)
- VRAM: 0x0000 - 0xFFFF (64 KB)

Features:
- Hex dump with ASCII
- Memory search (bytes/text)
- Address bookmarks
- Memory comparison
- Export dumps
- Watch list

Usage:
	python ffmq_memory_viewer.py --rom game.smc --view 0x80000
	python ffmq_memory_viewer.py --rom game.smc --search "Benjamin"
	python ffmq_memory_viewer.py --rom game.smc --dump 0x80000 0x81000
	python ffmq_memory_viewer.py --rom game.smc --compare save1.srm save2.srm
	python ffmq_memory_viewer.py --rom game.smc --watch 0x7E0100
"""

import argparse
import struct
from pathlib import Path
from typing import List, Dict, Optional, Tuple
from dataclasses import dataclass, asdict, field
from enum import Enum


class MemoryType(Enum):
	"""Memory type"""
	ROM = "rom"
	WRAM = "wram"
	SRAM = "sram"
	VRAM = "vram"
	OAM = "oam"
	CGRAM = "cgram"


class SearchType(Enum):
	"""Search type"""
	BYTES = "bytes"
	TEXT = "text"
	VALUE = "value"


@dataclass
class Bookmark:
	"""Memory bookmark"""
	address: int
	name: str
	description: str = ""
	memory_type: MemoryType = MemoryType.ROM


@dataclass
class WatchPoint:
	"""Memory watch point"""
	address: int
	name: str
	data_type: str = "byte"  # byte, word, dword
	last_value: Optional[int] = None


@dataclass
class SearchResult:
	"""Memory search result"""
	address: int
	data: bytes
	context: str = ""


class FFMQMemoryViewer:
	"""Memory viewer and analyzer"""
	
	# SNES memory map
	MEMORY_REGIONS = {
		'rom_lo': (0x008000, 0x00FFFF, 'LoROM Bank 0'),
		'rom_hi': (0x800000, 0xFFFFFF, 'HiROM'),
		'wram': (0x7E0000, 0x7FFFFF, 'Work RAM'),
		'sram': (0x700000, 0x71FFFF, 'Save RAM'),
	}
	
	# Known addresses
	KNOWN_ADDRESSES = {
		0x7E0100: 'Character 1 HP',
		0x7E0102: 'Character 1 MP',
		0x7E0104: 'Character 1 Attack',
		0x7E0105: 'Character 1 Defense',
		0x7E0106: 'Character 1 Speed',
		0x7E0107: 'Character 1 Magic',
		0x7E0200: 'Gil Amount',
		0x7E0204: 'Play Time',
		0x7E0300: 'Inventory Start',
		0x7E0400: 'Map ID',
		0x7E0402: 'X Position',
		0x7E0404: 'Y Position',
	}
	
	def __init__(self, rom_path: Optional[Path] = None, verbose: bool = False):
		self.verbose = verbose
		self.rom_data: Optional[bytes] = None
		self.bookmarks: List[Bookmark] = []
		self.watch_points: List[WatchPoint] = []
		
		if rom_path:
			self.load_rom(rom_path)
		
		self._create_default_bookmarks()
	
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
	
	def _create_default_bookmarks(self) -> None:
		"""Create default bookmarks"""
		for address, name in self.KNOWN_ADDRESSES.items():
			self.add_bookmark(address, name, memory_type=MemoryType.WRAM)
	
	def add_bookmark(self, address: int, name: str, description: str = "",
					 memory_type: MemoryType = MemoryType.ROM) -> None:
		"""Add memory bookmark"""
		bookmark = Bookmark(
			address=address,
			name=name,
			description=description,
			memory_type=memory_type
		)
		
		self.bookmarks.append(bookmark)
		
		if self.verbose:
			print(f"✓ Added bookmark: {name} @ 0x{address:06X}")
	
	def add_watch(self, address: int, name: str, data_type: str = "byte") -> None:
		"""Add watch point"""
		watch = WatchPoint(
			address=address,
			name=name,
			data_type=data_type
		)
		
		self.watch_points.append(watch)
		
		if self.verbose:
			print(f"✓ Added watch: {name} @ 0x{address:06X}")
	
	def read_byte(self, address: int, data: Optional[bytes] = None) -> Optional[int]:
		"""Read byte from memory"""
		if data is None:
			data = self.rom_data
		
		if not data or address >= len(data):
			return None
		
		return data[address]
	
	def read_word(self, address: int, data: Optional[bytes] = None) -> Optional[int]:
		"""Read word (16-bit) from memory"""
		if data is None:
			data = self.rom_data
		
		if not data or address + 1 >= len(data):
			return None
		
		return struct.unpack('<H', data[address:address+2])[0]
	
	def read_dword(self, address: int, data: Optional[bytes] = None) -> Optional[int]:
		"""Read dword (32-bit) from memory"""
		if data is None:
			data = self.rom_data
		
		if not data or address + 3 >= len(data):
			return None
		
		return struct.unpack('<I', data[address:address+4])[0]
	
	def read_bytes(self, address: int, length: int, 
				   data: Optional[bytes] = None) -> Optional[bytes]:
		"""Read multiple bytes"""
		if data is None:
			data = self.rom_data
		
		if not data or address + length > len(data):
			return None
		
		return data[address:address+length]
	
	def hex_dump(self, address: int, length: int = 256,
				 data: Optional[bytes] = None) -> str:
		"""Generate hex dump"""
		if data is None:
			data = self.rom_data
		
		if not data:
			return "No data loaded"
		
		lines = []
		
		for offset in range(0, length, 16):
			addr = address + offset
			
			if addr >= len(data):
				break
			
			# Read 16 bytes
			chunk_size = min(16, len(data) - addr)
			chunk = data[addr:addr+chunk_size]
			
			# Format address
			line = f"{addr:06X}  "
			
			# Format hex bytes
			hex_part = ' '.join(f"{b:02X}" for b in chunk)
			hex_part = hex_part.ljust(48)  # 16 * 3 = 48
			line += hex_part + "  "
			
			# Format ASCII
			ascii_part = ''.join(chr(b) if 32 <= b < 127 else '.' for b in chunk)
			line += ascii_part
			
			lines.append(line)
		
		return '\n'.join(lines)
	
	def search_bytes(self, pattern: bytes, data: Optional[bytes] = None,
					 start: int = 0) -> List[SearchResult]:
		"""Search for byte pattern"""
		if data is None:
			data = self.rom_data
		
		if not data:
			return []
		
		results = []
		pattern_len = len(pattern)
		
		for i in range(start, len(data) - pattern_len + 1):
			if data[i:i+pattern_len] == pattern:
				result = SearchResult(
					address=i,
					data=pattern,
					context=self._get_context(i, data)
				)
				results.append(result)
		
		return results
	
	def search_text(self, text: str, data: Optional[bytes] = None,
					encoding: str = 'ascii') -> List[SearchResult]:
		"""Search for text string"""
		try:
			pattern = text.encode(encoding)
			return self.search_bytes(pattern, data)
		except:
			return []
	
	def search_value(self, value: int, size: int = 1,
					 data: Optional[bytes] = None) -> List[SearchResult]:
		"""Search for numeric value"""
		if size == 1:
			pattern = struct.pack('B', value)
		elif size == 2:
			pattern = struct.pack('<H', value)
		elif size == 4:
			pattern = struct.pack('<I', value)
		else:
			return []
		
		return self.search_bytes(pattern, data)
	
	def _get_context(self, address: int, data: bytes, size: int = 32) -> str:
		"""Get context around address"""
		start = max(0, address - size)
		end = min(len(data), address + size)
		
		context = data[start:end]
		
		# Convert to hex string
		return ' '.join(f"{b:02X}" for b in context)
	
	def compare_memory(self, data1: bytes, data2: bytes) -> List[Tuple[int, int, int]]:
		"""Compare two memory regions"""
		differences = []
		
		max_len = min(len(data1), len(data2))
		
		for i in range(max_len):
			if data1[i] != data2[i]:
				differences.append((i, data1[i], data2[i]))
		
		return differences
	
	def update_watches(self, data: bytes) -> Dict[str, any]:
		"""Update watch points and return changes"""
		changes = {}
		
		for watch in self.watch_points:
			# Read current value
			if watch.data_type == 'byte':
				current = self.read_byte(watch.address, data)
			elif watch.data_type == 'word':
				current = self.read_word(watch.address, data)
			elif watch.data_type == 'dword':
				current = self.read_dword(watch.address, data)
			else:
				continue
			
			# Check for change
			if watch.last_value is not None and current != watch.last_value:
				changes[watch.name] = {
					'address': watch.address,
					'old': watch.last_value,
					'new': current
				}
			
			watch.last_value = current
		
		return changes
	
	def export_dump(self, output_path: Path, address: int, length: int,
					data: Optional[bytes] = None) -> bool:
		"""Export memory dump to file"""
		dump_data = self.read_bytes(address, length, data)
		
		if not dump_data:
			return False
		
		try:
			with open(output_path, 'wb') as f:
				f.write(dump_data)
			
			if self.verbose:
				print(f"✓ Exported {length} bytes from 0x{address:06X} to {output_path}")
			
			return True
		
		except Exception as e:
			print(f"Error exporting dump: {e}")
			return False
	
	def print_bookmarks(self) -> None:
		"""Print bookmark list"""
		if not self.bookmarks:
			print("No bookmarks")
			return
		
		print(f"\n{'Address':<12} {'Name':<25} {'Type':<10}")
		print('-' * 47)
		
		for bookmark in self.bookmarks:
			print(f"0x{bookmark.address:06X}    {bookmark.name:<25} "
				  f"{bookmark.memory_type.value:<10}")
	
	def print_watches(self) -> None:
		"""Print watch points"""
		if not self.watch_points:
			print("No watch points")
			return
		
		print(f"\n{'Address':<12} {'Name':<25} {'Type':<10} {'Value':<10}")
		print('-' * 57)
		
		for watch in self.watch_points:
			value_str = f"0x{watch.last_value:X}" if watch.last_value is not None else "---"
			print(f"0x{watch.address:06X}    {watch.name:<25} "
				  f"{watch.data_type:<10} {value_str:<10}")
	
	def print_search_results(self, results: List[SearchResult]) -> None:
		"""Print search results"""
		if not results:
			print("No results found")
			return
		
		print(f"\nFound {len(results)} result(s):\n")
		
		for i, result in enumerate(results[:50]):  # Limit to first 50
			print(f"{i+1}. 0x{result.address:06X}: "
				  f"{' '.join(f'{b:02X}' for b in result.data)}")
			
			if result.context:
				print(f"   Context: {result.context[:60]}...")
		
		if len(results) > 50:
			print(f"\n... and {len(results) - 50} more results")


def main():
	parser = argparse.ArgumentParser(description='FFMQ Memory Viewer')
	parser.add_argument('--rom', type=str, help='ROM file path')
	parser.add_argument('--view', type=str, help='View address (hex)')
	parser.add_argument('--length', type=int, default=256, help='View length')
	parser.add_argument('--search', type=str, help='Search text')
	parser.add_argument('--search-bytes', type=str, help='Search hex bytes')
	parser.add_argument('--search-value', type=int, help='Search numeric value')
	parser.add_argument('--value-size', type=int, default=1, choices=[1, 2, 4],
					   help='Value size (1/2/4 bytes)')
	parser.add_argument('--dump', type=str, nargs=2, metavar=('START', 'END'),
					   help='Dump memory range')
	parser.add_argument('--output', type=str, help='Output file')
	parser.add_argument('--compare', type=str, nargs=2, metavar=('FILE1', 'FILE2'),
					   help='Compare two files')
	parser.add_argument('--watch', type=str, help='Add watch address (hex)')
	parser.add_argument('--bookmarks', action='store_true', help='Show bookmarks')
	parser.add_argument('--watches', action='store_true', help='Show watch points')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	viewer = FFMQMemoryViewer(
		rom_path=Path(args.rom) if args.rom else None,
		verbose=args.verbose
	)
	
	# Add watch
	if args.watch:
		address = int(args.watch, 16)
		viewer.add_watch(address, f"Watch_{address:06X}")
	
	# View memory
	if args.view:
		address = int(args.view, 16)
		print(f"\nMemory @ 0x{address:06X}:\n")
		print(viewer.hex_dump(address, args.length))
		print()
		return 0
	
	# Search text
	if args.search:
		results = viewer.search_text(args.search)
		viewer.print_search_results(results)
		return 0
	
	# Search bytes
	if args.search_bytes:
		pattern = bytes.fromhex(args.search_bytes.replace(' ', ''))
		results = viewer.search_bytes(pattern)
		viewer.print_search_results(results)
		return 0
	
	# Search value
	if args.search_value is not None:
		results = viewer.search_value(args.search_value, args.value_size)
		viewer.print_search_results(results)
		return 0
	
	# Dump memory
	if args.dump and args.output:
		start = int(args.dump[0], 16)
		end = int(args.dump[1], 16)
		length = end - start
		viewer.export_dump(Path(args.output), start, length)
		return 0
	
	# Compare files
	if args.compare:
		with open(args.compare[0], 'rb') as f:
			data1 = f.read()
		with open(args.compare[1], 'rb') as f:
			data2 = f.read()
		
		differences = viewer.compare_memory(data1, data2)
		
		print(f"\nFound {len(differences)} difference(s):\n")
		
		for i, (addr, val1, val2) in enumerate(differences[:100]):
			print(f"0x{addr:06X}: {val1:02X} → {val2:02X}")
		
		if len(differences) > 100:
			print(f"\n... and {len(differences) - 100} more differences")
		
		return 0
	
	# Show bookmarks
	if args.bookmarks:
		viewer.print_bookmarks()
		return 0
	
	# Show watches
	if args.watches:
		viewer.print_watches()
		return 0
	
	# Default: show info
	if viewer.rom_data:
		print(f"\n=== FFMQ Memory Viewer ===\n")
		print(f"ROM size: {len(viewer.rom_data):,} bytes")
		print(f"Bookmarks: {len(viewer.bookmarks)}")
		print(f"Watch points: {len(viewer.watch_points)}")
		print("\nUse --view <address> to view memory")
		print("Use --search <text> to search")
	else:
		print("No ROM loaded. Use --rom <file> to load a ROM.")
	
	return 0


if __name__ == '__main__':
	exit(main())
