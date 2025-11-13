#!/usr/bin/env python3
"""
FFMQ Item Crafting System - Design custom item crafting mechanics

Crafting Features:
- Recipe system
- Material requirements
- Crafting stations
- Success rates
- Experience gain
- Skill levels
- Crafting time
- Item quality

Recipe Types:
- Weapons
- Armor
- Accessories
- Consumables
- Materials
- Special items

Crafting Mechanics:
- Combine items
- Upgrade equipment
- Break down items
- Transmutation
- Enchanting
- Socketing

Material System:
- Common materials
- Rare materials
- Unique materials
- Stackable quantities
- Material properties
- Drop sources

Features:
- Create recipes
- Set requirements
- Configure crafting
- Export recipes
- Import recipes
- Generate crafting trees

Usage:
	python ffmq_item_crafting.py create --name "Steel Sword" --result 100
	python ffmq_item_crafting.py add-material --recipe steel_sword --item iron 5
	python ffmq_item_crafting.py list --category weapons
	python ffmq_item_crafting.py tree --item steel_sword
	python ffmq_item_crafting.py export --output recipes.json
"""

import argparse
import json
from pathlib import Path
from typing import List, Dict, Tuple, Optional, Any
from dataclasses import dataclass, asdict, field
from enum import Enum


class RecipeCategory(Enum):
	"""Recipe categories"""
	WEAPON = "weapon"
	ARMOR = "armor"
	ACCESSORY = "accessory"
	CONSUMABLE = "consumable"
	MATERIAL = "material"
	SPECIAL = "special"


class CraftingStation(Enum):
	"""Crafting location types"""
	FORGE = "forge"
	ALCHEMY_LAB = "alchemy_lab"
	ENCHANTING_TABLE = "enchanting_table"
	WORKBENCH = "workbench"
	ANYWHERE = "anywhere"


@dataclass
class Material:
	"""Crafting material requirement"""
	item_id: int
	item_name: str
	quantity: int
	
	def to_dict(self) -> dict:
		return asdict(self)


@dataclass
class Recipe:
	"""Crafting recipe"""
	recipe_id: int
	name: str
	category: RecipeCategory
	result_item_id: int
	result_quantity: int
	materials: List[Material]
	station: CraftingStation
	skill_required: int  # 1-99
	success_rate: int  # 0-100%
	crafting_time: int  # Seconds
	experience_gained: int
	
	def to_dict(self) -> dict:
		d = asdict(self)
		d['category'] = self.category.value
		d['station'] = self.station.value
		d['materials'] = [m.to_dict() for m in self.materials]
		return d


@dataclass
class CraftingTree:
	"""Dependency tree for crafting"""
	root_item: str
	dependencies: Dict[str, List[str]]  # item -> required items


class FFMQItemCrafting:
	"""Item crafting system"""
	
	# Known items (sample)
	ITEMS = {
		# Weapons
		100: "Steel Sword",
		101: "Iron Axe",
		102: "Mythril Dagger",
		
		# Armor
		200: "Leather Armor",
		201: "Iron Helm",
		202: "Steel Shield",
		
		# Materials
		300: "Iron Ore",
		301: "Mythril Ore",
		302: "Leather",
		303: "Steel Ingot",
		304: "Crystal Shard"
	}
	
	# Recipe templates
	RECIPE_TEMPLATES = {
		'steel_sword': {
			'name': 'Steel Sword',
			'category': RecipeCategory.WEAPON,
			'result': 100,
			'quantity': 1,
			'materials': [
				{'item_id': 303, 'name': 'Steel Ingot', 'quantity': 3},
				{'item_id': 302, 'name': 'Leather', 'quantity': 1}
			],
			'station': CraftingStation.FORGE,
			'skill': 25,
			'success': 85,
			'time': 120,
			'exp': 50
		},
		'iron_axe': {
			'name': 'Iron Axe',
			'category': RecipeCategory.WEAPON,
			'result': 101,
			'quantity': 1,
			'materials': [
				{'item_id': 300, 'name': 'Iron Ore', 'quantity': 5},
				{'item_id': 302, 'name': 'Leather', 'quantity': 1}
			],
			'station': CraftingStation.FORGE,
			'skill': 15,
			'success': 90,
			'time': 90,
			'exp': 30
		},
		'steel_ingot': {
			'name': 'Steel Ingot',
			'category': RecipeCategory.MATERIAL,
			'result': 303,
			'quantity': 1,
			'materials': [
				{'item_id': 300, 'name': 'Iron Ore', 'quantity': 2}
			],
			'station': CraftingStation.FORGE,
			'skill': 10,
			'success': 95,
			'time': 60,
			'exp': 15
		}
	}
	
	def __init__(self, verbose: bool = False):
		self.verbose = verbose
		self.recipes: List[Recipe] = []
		self.next_id = 1
	
	def create_recipe(self, name: str, category: RecipeCategory,
					 result_item_id: int, result_quantity: int,
					 materials: List[Material],
					 station: CraftingStation = CraftingStation.WORKBENCH,
					 skill_required: int = 1,
					 success_rate: int = 100,
					 crafting_time: int = 60,
					 experience_gained: int = 10) -> Recipe:
		"""Create new recipe"""
		recipe = Recipe(
			recipe_id=self.next_id,
			name=name,
			category=category,
			result_item_id=result_item_id,
			result_quantity=result_quantity,
			materials=materials,
			station=station,
			skill_required=skill_required,
			success_rate=success_rate,
			crafting_time=crafting_time,
			experience_gained=experience_gained
		)
		
		self.recipes.append(recipe)
		self.next_id += 1
		
		if self.verbose:
			print(f"✓ Created recipe: {name}")
		
		return recipe
	
	def create_from_template(self, template_name: str) -> Optional[Recipe]:
		"""Create recipe from template"""
		if template_name not in self.RECIPE_TEMPLATES:
			if self.verbose:
				print(f"Unknown template: {template_name}")
			return None
		
		template = self.RECIPE_TEMPLATES[template_name]
		
		# Build materials
		materials = []
		for mat_data in template['materials']:
			material = Material(
				item_id=mat_data['item_id'],
				item_name=mat_data['name'],
				quantity=mat_data['quantity']
			)
			materials.append(material)
		
		recipe = self.create_recipe(
			name=template['name'],
			category=template['category'],
			result_item_id=template['result'],
			result_quantity=template['quantity'],
			materials=materials,
			station=template['station'],
			skill_required=template['skill'],
			success_rate=template['success'],
			crafting_time=template['time'],
			experience_gained=template['exp']
		)
		
		return recipe
	
	def calculate_material_cost(self, recipe: Recipe) -> Dict[int, int]:
		"""Calculate total materials needed (including dependencies)"""
		total_materials = {}
		
		for material in recipe.materials:
			# Add direct material
			if material.item_id in total_materials:
				total_materials[material.item_id] += material.quantity
			else:
				total_materials[material.item_id] = material.quantity
			
			# Check if material has recipe (recursive crafting)
			sub_recipe = self.find_recipe_by_result(material.item_id)
			if sub_recipe:
				sub_materials = self.calculate_material_cost(sub_recipe)
				for item_id, quantity in sub_materials.items():
					if item_id in total_materials:
						total_materials[item_id] += quantity * material.quantity
					else:
						total_materials[item_id] = quantity * material.quantity
		
		return total_materials
	
	def find_recipe_by_result(self, item_id: int) -> Optional[Recipe]:
		"""Find recipe that produces item"""
		for recipe in self.recipes:
			if recipe.result_item_id == item_id:
				return recipe
		return None
	
	def build_crafting_tree(self, recipe: Recipe) -> CraftingTree:
		"""Build dependency tree"""
		dependencies = {}
		
		def add_dependencies(rec: Recipe, depth: int = 0):
			if depth > 10:  # Prevent infinite recursion
				return
			
			item_name = rec.name
			dependencies[item_name] = []
			
			for material in rec.materials:
				mat_name = material.item_name
				dependencies[item_name].append(mat_name)
				
				# Recurse for sub-recipes
				sub_recipe = self.find_recipe_by_result(material.item_id)
				if sub_recipe and sub_recipe.name not in dependencies:
					add_dependencies(sub_recipe, depth + 1)
		
		add_dependencies(recipe)
		
		tree = CraftingTree(
			root_item=recipe.name,
			dependencies=dependencies
		)
		
		return tree
	
	def print_crafting_tree(self, tree: CraftingTree, indent: int = 0) -> None:
		"""Print tree structure"""
		def print_node(item: str, level: int):
			prefix = "  " * level + ("└─ " if level > 0 else "")
			print(f"{prefix}{item}")
			
			if item in tree.dependencies:
				for dep in tree.dependencies[item]:
					print_node(dep, level + 1)
		
		print_node(tree.root_item, 0)
	
	def generate_all_recipes(self) -> None:
		"""Generate all template recipes"""
		for template_name in self.RECIPE_TEMPLATES:
			self.create_from_template(template_name)
	
	def export_recipes(self, output_path: Path) -> None:
		"""Export recipes to JSON"""
		data = {
			'recipes': [r.to_dict() for r in self.recipes],
			'total_count': len(self.recipes)
		}
		
		with open(output_path, 'w') as f:
			json.dump(data, f, indent='\t')
		
		if self.verbose:
			print(f"✓ Exported {len(self.recipes)} recipes to {output_path}")
	
	def import_recipes(self, input_path: Path) -> None:
		"""Import recipes from JSON"""
		with open(input_path, 'r') as f:
			data = json.load(f)
		
		self.recipes = []
		for recipe_dict in data['recipes']:
			recipe_dict['category'] = RecipeCategory(recipe_dict['category'])
			recipe_dict['station'] = CraftingStation(recipe_dict['station'])
			
			# Rebuild materials
			materials = []
			for mat_dict in recipe_dict['materials']:
				materials.append(Material(**mat_dict))
			recipe_dict['materials'] = materials
			
			recipe = Recipe(**recipe_dict)
			self.recipes.append(recipe)
		
		if self.verbose:
			print(f"✓ Imported {len(self.recipes)} recipes from {input_path}")


def main():
	parser = argparse.ArgumentParser(description='FFMQ Item Crafting System')
	parser.add_argument('command', choices=['create', 'list', 'tree', 'export', 'import'],
					   help='Command to execute')
	parser.add_argument('--name', type=str, help='Recipe name')
	parser.add_argument('--category', type=str, choices=[c.value for c in RecipeCategory],
					   help='Recipe category')
	parser.add_argument('--template', type=str, help='Recipe template')
	parser.add_argument('--item', type=str, help='Item name for tree')
	parser.add_argument('--output', type=str, help='Output file')
	parser.add_argument('--input', type=str, help='Input file')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	crafting = FFMQItemCrafting(verbose=args.verbose)
	
	# List recipes
	if args.command == 'list':
		crafting.generate_all_recipes()
		
		print(f"\n=== Crafting Recipes ({len(crafting.recipes)} total) ===\n")
		
		# Filter by category if specified
		recipes = crafting.recipes
		if args.category:
			recipes = [r for r in recipes if r.category.value == args.category]
		
		for recipe in recipes:
			print(f"⚒️  {recipe.name}")
			print(f"   Category: {recipe.category.value}")
			print(f"   Result: {recipe.result_quantity}× {crafting.ITEMS.get(recipe.result_item_id, 'Unknown')}")
			print(f"   Materials:")
			for mat in recipe.materials:
				print(f"     - {mat.quantity}× {mat.item_name}")
			print(f"   Station: {recipe.station.value}")
			print(f"   Skill: {recipe.skill_required}")
			print(f"   Success Rate: {recipe.success_rate}%")
			print(f"   Time: {recipe.crafting_time}s")
			print(f"   EXP: {recipe.experience_gained}")
			print()
		
		return 0
	
	# Show crafting tree
	elif args.command == 'tree':
		if not args.item:
			print("Error: --item required")
			print(f"Available: {', '.join(crafting.RECIPE_TEMPLATES.keys())}")
			return 1
		
		crafting.generate_all_recipes()
		
		# Find recipe
		recipe = None
		for r in crafting.recipes:
			if r.name.lower() == args.item.lower() or args.item in crafting.RECIPE_TEMPLATES:
				recipe = r
				break
		
		if not recipe and args.item in crafting.RECIPE_TEMPLATES:
			recipe = crafting.create_from_template(args.item)
		
		if recipe:
			print(f"\n=== Crafting Tree: {recipe.name} ===\n")
			tree = crafting.build_crafting_tree(recipe)
			crafting.print_crafting_tree(tree)
			print()
			
			# Material summary
			total_materials = crafting.calculate_material_cost(recipe)
			print("Total Materials Required:")
			for item_id, quantity in total_materials.items():
				item_name = crafting.ITEMS.get(item_id, f"Item {item_id}")
				print(f"  {quantity}× {item_name}")
			print()
			
			return 0
		else:
			print(f"Recipe not found: {args.item}")
			return 1
	
	# Export
	elif args.command == 'export':
		if not args.output:
			print("Error: --output required")
			return 1
		
		if not crafting.recipes:
			crafting.generate_all_recipes()
		
		crafting.export_recipes(Path(args.output))
		return 0
	
	# Import
	elif args.command == 'import':
		if not args.input:
			print("Error: --input required")
			return 1
		
		crafting.import_recipes(Path(args.input))
		return 0
	
	return 0


if __name__ == '__main__':
	exit(main())
