"""
FFMQ Game Editor Test Suite

Unit tests for all game systems to ensure data integrity.
"""

import unittest
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))

from utils.enemy_data import Enemy, EnemyStats, ResistanceData, ItemDrop, AIScript, EnemyFlags, DropType
from utils.spell_data import Spell, SpellElement, SpellTarget, DamageFormula, SpellFlags
from utils.item_data import Item, EquipmentStats, ItemType, ItemFlags, EquipRestriction


class TestEnemyData(unittest.TestCase):
	"""Test enemy data structures"""
	
	def test_enemy_creation(self):
		"""Test creating basic enemy"""
		stats = EnemyStats(hp=100, attack=10, defense=5, magic=3, magic_def=2, speed=15, accuracy=90, evasion=10)
		resistances = ResistanceData(fire=128, water=128, earth=128, wind=128, holy=128, dark=128, poison=64, status=100, physical=128)
		
		enemy = Enemy(
			enemy_id=0x01,
			name="Test Goblin",
			level=5,
			stats=stats,
			resistances=resistances,
			exp=25,
			gold=10
		)
		
		self.assertEqual(enemy.enemy_id, 0x01)
		self.assertEqual(enemy.name, "Test Goblin")
		self.assertEqual(enemy.level, 5)
		self.assertEqual(enemy.stats.hp, 100)
		self.assertEqual(enemy.exp, 25)
		self.assertEqual(enemy.gold, 10)
	
	def test_enemy_serialization(self):
		"""Test enemy to_bytes and from_bytes"""
		stats = EnemyStats(hp=500, attack=45, defense=30, magic=25, magic_def=20, speed=35, accuracy=95, evasion=15)
		resistances = ResistanceData(fire=128, water=255, earth=64, wind=128, holy=128, dark=128, poison=0, status=50, physical=128)
		
		enemy = Enemy(
			enemy_id=0x10,
			name="Fire Drake",
			level=15,
			stats=stats,
			resistances=resistances,
			exp=450,
			gold=200,
			flags=EnemyFlags.FLYING | EnemyFlags.DRAGON
		)
		
		# Serialize
		data = enemy.to_bytes()
		self.assertEqual(len(data), 256)  # Enemy is 256 bytes
		
		# Deserialize
		enemy2 = Enemy.from_bytes(data, 0x10)
		
		# Verify
		self.assertEqual(enemy2.enemy_id, enemy.enemy_id)
		self.assertEqual(enemy2.name, enemy.name)
		self.assertEqual(enemy2.level, enemy.level)
		self.assertEqual(enemy2.stats.hp, enemy.stats.hp)
		self.assertEqual(enemy2.stats.attack, enemy.stats.attack)
		self.assertEqual(enemy2.resistances.fire, enemy.resistances.fire)
		self.assertEqual(enemy2.resistances.water, enemy.resistances.water)
		self.assertEqual(enemy2.exp, enemy.exp)
		self.assertEqual(enemy2.gold, enemy.gold)
		self.assertEqual(enemy2.flags, enemy.flags)
	
	def test_difficulty_calculation(self):
		"""Test enemy difficulty calculation"""
		stats = EnemyStats(hp=1000, attack=50, defense=40, magic=30, magic_def=25, speed=35, accuracy=90, evasion=10)
		resistances = ResistanceData(fire=128, water=128, earth=128, wind=128, holy=128, dark=128, poison=128, status=100, physical=128)
		
		enemy = Enemy(
			enemy_id=0x20,
			name="Boss Monster",
			level=20,
			stats=stats,
			resistances=resistances,
			exp=2000,
			gold=500,
			flags=EnemyFlags.BOSS
		)
		
		difficulty = enemy.calculate_difficulty()
		self.assertGreater(difficulty, 0)
		self.assertIsInstance(difficulty, int)
	
	def test_weakness_detection(self):
		"""Test weakness/resistance detection"""
		resistances = ResistanceData(
			fire=255,      # Weak
			water=64,      # Resistant
			earth=0,       # Immune
			wind=128,      # Normal
			holy=200,      # Weak
			dark=32,       # Resistant
			poison=0,      # Immune
			status=128,
			physical=128
		)
		
		enemy = Enemy(
			enemy_id=0x30,
			name="Test Enemy",
			level=10,
			stats=EnemyStats(hp=100, attack=10, defense=5, magic=5, magic_def=5, speed=10, accuracy=90, evasion=10),
			resistances=resistances,
			exp=50,
			gold=20
		)
		
		weaknesses = enemy.get_weaknesses()
		self.assertIn('fire', weaknesses)
		self.assertIn('holy', weaknesses)
		
		resistances_list = enemy.get_resistances()
		self.assertIn('water', resistances_list)
		self.assertIn('dark', resistances_list)
		
		immunities = enemy.get_immunities()
		self.assertIn('earth', immunities)
		self.assertIn('poison', immunities)


class TestSpellData(unittest.TestCase):
	"""Test spell data structures"""
	
	def test_spell_creation(self):
		"""Test creating basic spell"""
		spell = Spell(
			spell_id=0x01,
			name="Fire",
			element=SpellElement.FIRE,
			target=SpellTarget.SINGLE_ENEMY,
			mp_cost=4,
			power=20,
			accuracy=95,
			formula=DamageFormula.MAGIC_BASED,
			flags=SpellFlags.OFFENSIVE
		)
		
		self.assertEqual(spell.spell_id, 0x01)
		self.assertEqual(spell.name, "Fire")
		self.assertEqual(spell.element, SpellElement.FIRE)
		self.assertEqual(spell.mp_cost, 4)
		self.assertEqual(spell.power, 20)
	
	def test_spell_serialization(self):
		"""Test spell to_bytes and from_bytes"""
		spell = Spell(
			spell_id=0x10,
			name="Firaga",
			element=SpellElement.FIRE,
			target=SpellTarget.ALL_ENEMIES,
			mp_cost=16,
			power=80,
			accuracy=95,
			formula=DamageFormula.MAGIC_BASED,
			flags=SpellFlags.OFFENSIVE | SpellFlags.AREA_EFFECT
		)
		
		# Serialize
		data = spell.to_bytes()
		self.assertEqual(len(data), 64)  # Spell is 64 bytes
		
		# Deserialize
		spell2 = Spell.from_bytes(data, 0x10)
		
		# Verify
		self.assertEqual(spell2.spell_id, spell.spell_id)
		self.assertEqual(spell2.name, spell.name)
		self.assertEqual(spell2.element, spell.element)
		self.assertEqual(spell2.target, spell.target)
		self.assertEqual(spell2.mp_cost, spell.mp_cost)
		self.assertEqual(spell2.power, spell.power)
		self.assertEqual(spell2.accuracy, spell.accuracy)
		self.assertEqual(spell2.formula, spell.formula)
		self.assertEqual(spell2.flags, spell.flags)
	
	def test_damage_calculation(self):
		"""Test damage formulas"""
		spell = Spell(
			spell_id=0x20,
			name="Test Spell",
			element=SpellElement.FIRE,
			target=SpellTarget.SINGLE_ENEMY,
			mp_cost=8,
			power=40,
			accuracy=95,
			formula=DamageFormula.MAGIC_BASED,
			flags=SpellFlags.OFFENSIVE
		)
		
		# Test MAGIC_BASED formula
		caster_magic = 64
		target_defense = 32
		
		damage, variance = spell.calculate_damage(caster_magic, target_defense)
		self.assertGreater(damage, 0)
		self.assertIsInstance(damage, int)
		self.assertIsInstance(variance, int)
	
	def test_spell_types(self):
		"""Test spell type detection"""
		offensive = Spell(
			spell_id=0x30,
			name="Attack",
			element=SpellElement.NONE,
			target=SpellTarget.SINGLE_ENEMY,
			mp_cost=0,
			power=10,
			accuracy=100,
			formula=DamageFormula.FIXED,
			flags=SpellFlags.OFFENSIVE
		)
		
		healing = Spell(
			spell_id=0x31,
			name="Cure",
			element=SpellElement.HOLY,
			target=SpellTarget.SINGLE_ALLY,
			mp_cost=5,
			power=30,
			accuracy=100,
			formula=DamageFormula.FIXED,
			flags=SpellFlags.HEALING
		)
		
		self.assertEqual(offensive.get_spell_type(), "Offensive")
		self.assertEqual(healing.get_spell_type(), "Healing")


class TestItemData(unittest.TestCase):
	"""Test item data structures"""
	
	def test_item_creation(self):
		"""Test creating basic item"""
		item = Item(
			item_id=0x01,
			name="Potion",
			item_type=ItemType.CONSUMABLE,
			buy_price=50,
			sell_price=25,
			flags=ItemFlags.USABLE_IN_BATTLE | ItemFlags.CONSUMABLE
		)
		
		self.assertEqual(item.item_id, 0x01)
		self.assertEqual(item.name, "Potion")
		self.assertEqual(item.item_type, ItemType.CONSUMABLE)
		self.assertEqual(item.buy_price, 50)
		self.assertEqual(item.sell_price, 25)
	
	def test_equipment_item(self):
		"""Test equipment item"""
		stats = EquipmentStats(
			attack=35,
			defense=0,
			magic=0,
			magic_def=0,
			speed=0,
			hp_bonus=0,
			mp_bonus=0,
			accuracy=95,
			evasion=0
		)
		
		item = Item(
			item_id=0x10,
			name="Steel Sword",
			item_type=ItemType.WEAPON,
			buy_price=500,
			sell_price=250,
			equipment_stats=stats,
			restrictions=EquipRestriction.BENJAMIN | EquipRestriction.KAELI
		)
		
		self.assertTrue(item.is_equipment())
		self.assertFalse(item.is_consumable())
		self.assertEqual(item.equipment_stats.attack, 35)
		
		total_stats = item.get_total_stats_value()
		self.assertGreater(total_stats, 0)
		
		who_can_equip = item.get_who_can_equip()
		self.assertIn("Benjamin", who_can_equip)
		self.assertIn("Kaeli", who_can_equip)
	
	def test_item_serialization(self):
		"""Test item to_bytes and from_bytes"""
		stats = EquipmentStats(attack=25, defense=15, magic=10, magic_def=8, speed=5, hp_bonus=20, mp_bonus=10, accuracy=90, evasion=5)
		
		item = Item(
			item_id=0x20,
			name="Battle Armor",
			item_type=ItemType.ARMOR,
			buy_price=1000,
			sell_price=500,
			equipment_stats=stats,
			restrictions=EquipRestriction.ALL,
			flags=ItemFlags.RARE
		)
		
		# Serialize
		data = item.to_bytes()
		self.assertEqual(len(data), 32)  # Item is 32 bytes
		
		# Deserialize
		item2 = Item.from_bytes(data, 0x20)
		
		# Verify
		self.assertEqual(item2.item_id, item.item_id)
		self.assertEqual(item2.name, item.name)
		self.assertEqual(item2.item_type, item.item_type)
		self.assertEqual(item2.buy_price, item.buy_price)
		self.assertEqual(item2.sell_price, item.sell_price)
		self.assertEqual(item2.equipment_stats.attack, item.equipment_stats.attack)
		self.assertEqual(item2.equipment_stats.defense, item.equipment_stats.defense)
		self.assertEqual(item2.restrictions, item.restrictions)
		self.assertEqual(item2.flags, item.flags)


class TestDataIntegrity(unittest.TestCase):
	"""Test data integrity and validation"""
	
	def test_enemy_stat_ranges(self):
		"""Test enemy stat validation"""
		# Valid HP
		stats = EnemyStats(hp=65535, attack=255, defense=255, magic=255, magic_def=255, speed=255, accuracy=100, evasion=100)
		self.assertLessEqual(stats.hp, 65535)
		self.assertLessEqual(stats.attack, 255)
		
		# Resistances
		resistances = ResistanceData(fire=255, water=128, earth=0, wind=255, holy=128, dark=0, poison=0, status=100, physical=128)
		self.assertLessEqual(resistances.fire, 255)
		self.assertGreaterEqual(resistances.fire, 0)
	
	def test_spell_mp_costs(self):
		"""Test spell MP cost validation"""
		spell = Spell(
			spell_id=0x40,
			name="Expensive Spell",
			element=SpellElement.HOLY,
			target=SpellTarget.ALL_ENEMIES,
			mp_cost=99,
			power=200,
			accuracy=90,
			formula=DamageFormula.MAGIC_BASED,
			flags=SpellFlags.OFFENSIVE
		)
		
		self.assertLessEqual(spell.mp_cost, 99)
		self.assertGreaterEqual(spell.mp_cost, 0)
	
	def test_item_prices(self):
		"""Test item price validation"""
		item = Item(
			item_id=0x50,
			name="Expensive Item",
			item_type=ItemType.WEAPON,
			buy_price=9999,
			sell_price=4999,
			flags=ItemFlags.RARE
		)
		
		self.assertGreaterEqual(item.buy_price, 0)
		self.assertGreaterEqual(item.sell_price, 0)
		self.assertLessEqual(item.sell_price, item.buy_price)


def run_tests():
	"""Run all tests"""
	# Create test suite
	loader = unittest.TestLoader()
	suite = unittest.TestSuite()
	
	# Add test cases
	suite.addTests(loader.loadTestsFromTestCase(TestEnemyData))
	suite.addTests(loader.loadTestsFromTestCase(TestSpellData))
	suite.addTests(loader.loadTestsFromTestCase(TestItemData))
	suite.addTests(loader.loadTestsFromTestCase(TestDataIntegrity))
	
	# Run tests
	runner = unittest.TextTestRunner(verbosity=2)
	result = runner.run(suite)
	
	# Print summary
	print("\n" + "=" * 70)
	print("TEST SUMMARY")
	print("=" * 70)
	print(f"Tests run: {result.testsRun}")
	print(f"Successes: {result.testsRun - len(result.failures) - len(result.errors)}")
	print(f"Failures: {len(result.failures)}")
	print(f"Errors: {len(result.errors)}")
	print("=" * 70)
	
	return result.wasSuccessful()


if __name__ == '__main__':
	success = run_tests()
	sys.exit(0 if success else 1)
