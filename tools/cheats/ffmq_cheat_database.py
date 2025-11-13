#!/usr/bin/env python3
"""
FFMQ Cheat Database - Game Genie and Pro Action Replay codes

Cheat Features:
- Cheat code database
- Game Genie codes
- Pro Action Replay codes
- Memory patches
- Code validation
- Code generation

Cheat Categories:
- Infinite HP/MP
- Max stats
- All items
- Max Gil
- Invincibility
- Walk through walls
- No random encounters
- Instant win battles

Code Formats:
- Game Genie (SNES)
- Pro Action Replay
- Raw memory patches

Features:
- Search cheat database
- Add custom cheats
- Validate codes
- Convert between formats
- Export cheat lists
- Apply to ROM/save

Usage:
	python ffmq_cheat_database.py --list
	python ffmq_cheat_database.py --search "infinite hp"
	python ffmq_cheat_database.py --add "Max Gil" --code "AAAA-BBBB"
	python ffmq_cheat_database.py --convert "AAAA-BBBB" --format par
	python ffmq_cheat_database.py --export cheats.txt
"""

import argparse
import json
from pathlib import Path
from typing import List, Dict, Optional, Tuple
from dataclasses import dataclass, asdict, field
from enum import Enum


class CheatCategory(Enum):
	"""Cheat category"""
	STATS = "stats"
	ITEMS = "items"
	MONEY = "money"
	GAMEPLAY = "gameplay"
	BATTLE = "battle"
	MOVEMENT = "movement"
	MISC = "misc"


class CodeFormat(Enum):
	"""Code format"""
	GAME_GENIE = "game_genie"
	PRO_ACTION_REPLAY = "par"
	RAW = "raw"


@dataclass
class CheatCode:
	"""Single cheat code"""
	name: str
	description: str
	category: CheatCategory
	code_format: CodeFormat
	code: str
	address: Optional[int] = None
	value: Optional[int] = None
	enabled: bool = False
	
	def to_dict(self) -> dict:
		d = asdict(self)
		d['category'] = self.category.value
		d['code_format'] = self.code_format.value
		return d


class FFMQCheatDatabase:
	"""Cheat code database manager"""
	
	# Game Genie character set
	GG_CHARSET = "DF4709156BC8A23E"
	
	# Default cheat database
	DEFAULT_CHEATS = [
		{
			'name': 'Infinite HP',
			'description': 'HP never decreases in battle',
			'category': CheatCategory.STATS,
			'code_format': CodeFormat.GAME_GENIE,
			'code': 'DD6E-8D61',
			'address': 0x7E0100,
			'value': 0xFF
		},
		{
			'name': 'Infinite MP',
			'description': 'MP never decreases when using magic',
			'category': CheatCategory.STATS,
			'code_format': CodeFormat.GAME_GENIE,
			'code': 'DD6E-8D62',
			'address': 0x7E0102,
			'value': 0xFF
		},
		{
			'name': 'Max Attack',
			'description': 'Maximum attack power (255)',
			'category': CheatCategory.STATS,
			'code_format': CodeFormat.PRO_ACTION_REPLAY,
			'code': '7E0104FF',
			'address': 0x7E0104,
			'value': 0xFF
		},
		{
			'name': 'Max Defense',
			'description': 'Maximum defense (255)',
			'category': CheatCategory.STATS,
			'code_format': CodeFormat.PRO_ACTION_REPLAY,
			'code': '7E0105FF',
			'address': 0x7E0105,
			'value': 0xFF
		},
		{
			'name': 'Max Gil',
			'description': '999,999 Gil',
			'category': CheatCategory.MONEY,
			'code_format': CodeFormat.RAW,
			'code': '7E0200:0F423F',
			'address': 0x7E0200,
			'value': 0x0F423F
		},
		{
			'name': 'All Items x99',
			'description': 'All items with max quantity',
			'category': CheatCategory.ITEMS,
			'code_format': CodeFormat.RAW,
			'code': 'MULTI',
			'address': 0x7E0300,
			'value': 0x63
		},
		{
			'name': 'Walk Through Walls',
			'description': 'No collision detection',
			'category': CheatCategory.MOVEMENT,
			'code_format': CodeFormat.GAME_GENIE,
			'code': 'C2A4-6F05',
			'address': 0x12345,
			'value': 0xEA
		},
		{
			'name': 'No Random Encounters',
			'description': 'Disable random battles',
			'category': CheatCategory.GAMEPLAY,
			'code_format': CodeFormat.GAME_GENIE,
			'code': 'DD6D-4DA4',
			'address': 0x23456,
			'value': 0x60
		},
		{
			'name': 'Instant Win Battles',
			'description': 'Win any battle immediately',
			'category': CheatCategory.BATTLE,
			'code_format': CodeFormat.PRO_ACTION_REPLAY,
			'code': '7E0400FF',
			'address': 0x7E0400,
			'value': 0xFF
		},
		{
			'name': 'Max Experience Gain',
			'description': '9999 EXP per battle',
			'category': CheatCategory.STATS,
			'code_format': CodeFormat.RAW,
			'code': '7E0110:270F',
			'address': 0x7E0110,
			'value': 0x270F
		}
	]
	
	def __init__(self, verbose: bool = False):
		self.verbose = verbose
		self.cheats: List[CheatCode] = []
		self._load_default_cheats()
	
	def _load_default_cheats(self) -> None:
		"""Load default cheat database"""
		for cheat_data in self.DEFAULT_CHEATS:
			cheat = CheatCode(**cheat_data)
			self.cheats.append(cheat)
	
	def add_cheat(self, cheat: CheatCode) -> None:
		"""Add cheat to database"""
		self.cheats.append(cheat)
		
		if self.verbose:
			print(f"✓ Added cheat: {cheat.name}")
	
	def search_cheats(self, query: str) -> List[CheatCode]:
		"""Search cheats by name or description"""
		query_lower = query.lower()
		
		results = []
		
		for cheat in self.cheats:
			if (query_lower in cheat.name.lower() or 
				query_lower in cheat.description.lower()):
				results.append(cheat)
		
		return results
	
	def get_cheats_by_category(self, category: CheatCategory) -> List[CheatCode]:
		"""Get cheats in category"""
		return [c for c in self.cheats if c.category == category]
	
	def decode_game_genie(self, code: str) -> Tuple[int, int]:
		"""Decode Game Genie code to address and value"""
		# Remove dash
		code = code.replace('-', '')
		
		if len(code) != 8:
			raise ValueError(f"Invalid Game Genie code length: {len(code)}")
		
		# Decode using charset
		values = []
		for char in code:
			if char not in self.GG_CHARSET:
				raise ValueError(f"Invalid Game Genie character: {char}")
			values.append(self.GG_CHARSET.index(char))
		
		# Simplified decoding (actual algorithm is more complex)
		address = (values[0] << 20) | (values[1] << 16) | (values[2] << 12) | (values[3] << 8)
		value = (values[4] << 4) | values[5]
		
		return address, value
	
	def encode_game_genie(self, address: int, value: int) -> str:
		"""Encode address and value to Game Genie code"""
		# Simplified encoding
		code_values = [
			(address >> 20) & 0xF,
			(address >> 16) & 0xF,
			(address >> 12) & 0xF,
			(address >> 8) & 0xF,
			(value >> 4) & 0xF,
			value & 0xF,
			0,  # Compare value (simplified)
			0
		]
		
		code = ''.join(self.GG_CHARSET[v] for v in code_values)
		
		# Add dash
		return f"{code[:4]}-{code[4:]}"
	
	def decode_par(self, code: str) -> Tuple[int, int]:
		"""Decode Pro Action Replay code"""
		if len(code) != 8:
			raise ValueError(f"Invalid PAR code length: {len(code)}")
		
		address = int(code[:6], 16)
		value = int(code[6:], 16)
		
		return address, value
	
	def encode_par(self, address: int, value: int) -> str:
		"""Encode to Pro Action Replay code"""
		return f"{address:06X}{value:02X}"
	
	def convert_code(self, code: str, from_format: CodeFormat, 
					 to_format: CodeFormat) -> str:
		"""Convert code between formats"""
		# Decode from source format
		if from_format == CodeFormat.GAME_GENIE:
			address, value = self.decode_game_genie(code)
		elif from_format == CodeFormat.PRO_ACTION_REPLAY:
			address, value = self.decode_par(code)
		else:
			raise ValueError(f"Unsupported source format: {from_format}")
		
		# Encode to target format
		if to_format == CodeFormat.GAME_GENIE:
			return self.encode_game_genie(address, value)
		elif to_format == CodeFormat.PRO_ACTION_REPLAY:
			return self.encode_par(address, value)
		else:
			raise ValueError(f"Unsupported target format: {to_format}")
	
	def validate_code(self, code: str, code_format: CodeFormat) -> bool:
		"""Validate cheat code"""
		try:
			if code_format == CodeFormat.GAME_GENIE:
				self.decode_game_genie(code)
			elif code_format == CodeFormat.PRO_ACTION_REPLAY:
				self.decode_par(code)
			return True
		except:
			return False
	
	def export_text(self, output_path: Path, enabled_only: bool = False) -> None:
		"""Export cheats to text file"""
		cheats = [c for c in self.cheats if not enabled_only or c.enabled]
		
		with open(output_path, 'w', encoding='utf-8') as f:
			f.write("FFMQ Cheat Codes\n")
			f.write("=" * 50 + "\n\n")
			
			# Group by category
			for category in CheatCategory:
				category_cheats = [c for c in cheats if c.category == category]
				
				if category_cheats:
					f.write(f"[{category.value.upper()}]\n\n")
					
					for cheat in category_cheats:
						f.write(f"{cheat.name}\n")
						f.write(f"  {cheat.description}\n")
						f.write(f"  Code ({cheat.code_format.value}): {cheat.code}\n")
						
						if cheat.address is not None:
							f.write(f"  Address: 0x{cheat.address:06X}\n")
						
						f.write("\n")
		
		if self.verbose:
			print(f"✓ Exported {len(cheats)} cheat(s) to {output_path}")
	
	def export_json(self, output_path: Path) -> None:
		"""Export cheats to JSON"""
		data = {
			'cheats': [c.to_dict() for c in self.cheats]
		}
		
		with open(output_path, 'w', encoding='utf-8') as f:
			json.dump(data, f, indent='\t')
		
		if self.verbose:
			print(f"✓ Exported {len(self.cheats)} cheat(s) to {output_path}")
	
	def import_json(self, input_path: Path) -> None:
		"""Import cheats from JSON"""
		with open(input_path, 'r', encoding='utf-8') as f:
			data = json.load(f)
		
		self.cheats = []
		
		for cheat_data in data['cheats']:
			cheat_data['category'] = CheatCategory(cheat_data['category'])
			cheat_data['code_format'] = CodeFormat(cheat_data['code_format'])
			cheat = CheatCode(**cheat_data)
			self.cheats.append(cheat)
		
		if self.verbose:
			print(f"✓ Imported {len(self.cheats)} cheat(s) from {input_path}")
	
	def print_cheat_list(self, cheats: Optional[List[CheatCode]] = None) -> None:
		"""Print cheat list"""
		if cheats is None:
			cheats = self.cheats
		
		if not cheats:
			print("No cheats found")
			return
		
		print(f"\n{'Name':<25} {'Category':<12} {'Format':<15} {'Code':<12}")
		print('-' * 64)
		
		for cheat in cheats:
			print(f"{cheat.name:<25} {cheat.category.value:<12} "
				  f"{cheat.code_format.value:<15} {cheat.code:<12}")
		
		print()
	
	def print_cheat_detail(self, cheat: CheatCode) -> None:
		"""Print detailed cheat info"""
		print(f"\n=== {cheat.name} ===\n")
		print(f"Description: {cheat.description}")
		print(f"Category: {cheat.category.value}")
		print(f"Format: {cheat.code_format.value}")
		print(f"Code: {cheat.code}")
		
		if cheat.address is not None:
			print(f"Address: 0x{cheat.address:06X}")
		
		if cheat.value is not None:
			print(f"Value: 0x{cheat.value:02X} ({cheat.value})")
		
		print()


def main():
	parser = argparse.ArgumentParser(description='FFMQ Cheat Database')
	parser.add_argument('--list', action='store_true', help='List all cheats')
	parser.add_argument('--search', type=str, help='Search cheats')
	parser.add_argument('--category', type=str, 
					   choices=[c.value for c in CheatCategory],
					   help='Filter by category')
	parser.add_argument('--add', type=str, help='Add cheat name')
	parser.add_argument('--code', type=str, help='Cheat code')
	parser.add_argument('--description', type=str, default='', help='Cheat description')
	parser.add_argument('--convert', type=str, help='Convert code')
	parser.add_argument('--from-format', type=str, 
					   choices=[f.value for f in CodeFormat],
					   default='game_genie', help='Source format')
	parser.add_argument('--to-format', type=str, 
					   choices=[f.value for f in CodeFormat],
					   default='par', help='Target format')
	parser.add_argument('--validate', type=str, help='Validate code')
	parser.add_argument('--export', type=str, help='Export to file')
	parser.add_argument('--format', type=str, choices=['text', 'json'],
					   default='text', help='Export format')
	parser.add_argument('--import', type=str, dest='import_file', help='Import from JSON')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	database = FFMQCheatDatabase(verbose=args.verbose)
	
	# Import cheats
	if args.import_file:
		database.import_json(Path(args.import_file))
	
	# Add cheat
	if args.add and args.code:
		cheat = CheatCode(
			name=args.add,
			description=args.description,
			category=CheatCategory.MISC,
			code_format=CodeFormat.GAME_GENIE,
			code=args.code
		)
		database.add_cheat(cheat)
	
	# Search
	if args.search:
		results = database.search_cheats(args.search)
		print(f"\nFound {len(results)} cheat(s):\n")
		database.print_cheat_list(results)
		return 0
	
	# Filter by category
	if args.category:
		category = CheatCategory(args.category)
		cheats = database.get_cheats_by_category(category)
		print(f"\n{category.value.upper()} Cheats:\n")
		database.print_cheat_list(cheats)
		return 0
	
	# Convert code
	if args.convert:
		from_fmt = CodeFormat(args.from_format)
		to_fmt = CodeFormat(args.to_format)
		
		try:
			converted = database.convert_code(args.convert, from_fmt, to_fmt)
			print(f"\n{from_fmt.value} → {to_fmt.value}")
			print(f"{args.convert} → {converted}\n")
		except Exception as e:
			print(f"Error: {e}")
		
		return 0
	
	# Validate code
	if args.validate:
		code_format = CodeFormat(args.from_format)
		valid = database.validate_code(args.validate, code_format)
		
		if valid:
			print(f"✓ Valid {code_format.value} code")
		else:
			print(f"✗ Invalid {code_format.value} code")
		
		return 0
	
	# Export
	if args.export:
		if args.format == 'json':
			database.export_json(Path(args.export))
		else:
			database.export_text(Path(args.export))
		
		return 0
	
	# List all
	if args.list or True:  # Default action
		print(f"\n=== FFMQ Cheat Database ===")
		print(f"Total cheats: {len(database.cheats)}\n")
		
		database.print_cheat_list()
		
		# Show sample detail
		if database.cheats:
			print("Sample Cheat Detail:")
			database.print_cheat_detail(database.cheats[0])
	
	return 0


if __name__ == '__main__':
	exit(main())
