#!/usr/bin/env python3
"""
Test suite for FFMQ Map Editor
Comprehensive tests for all major components
"""

import unittest
import numpy as np
import sys
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from engine.map_engine import MapEngine, MapData, MapType, LayerType
from utils.compression import FFMQCompression
from utils.tileset_manager import TilesetManager, decode_snes_palette
from utils.file_formats import FFMAPFormat, JSONFormat, BinaryFormat
from utils.example_maps import ExampleMapGenerator


class TestMapEngine(unittest.TestCase):
	"""Test map engine functionality"""

	def setUp(self):
		"""Set up test fixtures"""
		self.engine = MapEngine()

	def test_new_map_creation(self):
		"""Test creating a new map"""
		self.engine.new_map(32, 32, MapType.TOWN)

		self.assertIsNotNone(self.engine.current_map)
		self.assertEqual(self.engine.current_map.width, 32)
		self.assertEqual(self.engine.current_map.height, 32)
		self.assertEqual(self.engine.current_map.bg1_tiles.shape, (32, 32))

	def test_tile_operations(self):
		"""Test get/set tile operations"""
		self.engine.new_map(16, 16, MapType.TOWN)

		# Set tile
		result = self.engine.set_tile(5, 5, 42, LayerType.BG1_GROUND)
		self.assertTrue(result)

		# Get tile
		tile_id = self.engine.get_tile(5, 5, LayerType.BG1_GROUND)
		self.assertEqual(tile_id, 42)

	def test_boundary_checking(self):
		"""Test tile operations respect boundaries"""
		self.engine.new_map(16, 16, MapType.TOWN)

		# Out of bounds set should fail
		result = self.engine.set_tile(20, 20, 1, LayerType.BG1_GROUND)
		self.assertFalse(result)

		# Out of bounds get should return 0
		tile_id = self.engine.get_tile(20, 20, LayerType.BG1_GROUND)
		self.assertEqual(tile_id, 0)

	def test_flood_fill(self):
		"""Test flood fill operation"""
		self.engine.new_map(10, 10, MapType.TOWN)

		# Fill area with tile 5
		self.engine.flood_fill(5, 5, 5, LayerType.BG1_GROUND)

		# Check that tiles were filled
		for y in range(10):
			for x in range(10):
				tile = self.engine.get_tile(x, y, LayerType.BG1_GROUND)
				self.assertEqual(tile, 5)

	def test_paint_rectangle(self):
		"""Test rectangle painting"""
		self.engine.new_map(20, 20, MapType.TOWN)

		# Paint rectangle
		self.engine.paint_rectangle(5, 5, 10, 10, 7, LayerType.BG1_GROUND)

		# Check rectangle was painted
		for y in range(5, 11):
			for x in range(5, 11):
				tile = self.engine.get_tile(x, y, LayerType.BG1_GROUND)
				self.assertEqual(tile, 7)

		# Check outside rectangle wasn't painted
		tile = self.engine.get_tile(4, 4, LayerType.BG1_GROUND)
		self.assertEqual(tile, 0)

	def test_undo_redo(self):
		"""Test undo/redo functionality"""
		self.engine.new_map(10, 10, MapType.TOWN)

		# Perform action
		self.engine.set_tile(5, 5, 42, LayerType.BG1_GROUND)
		self.assertEqual(self.engine.get_tile(5, 5, LayerType.BG1_GROUND), 42)

		# Undo
		self.engine.undo()
		self.assertEqual(self.engine.get_tile(5, 5, LayerType.BG1_GROUND), 0)

		# Redo
		self.engine.redo()
		self.assertEqual(self.engine.get_tile(5, 5, LayerType.BG1_GROUND), 42)

	def test_undo_stack_limit(self):
		"""Test undo stack respects maximum size"""
		self.engine.new_map(10, 10, MapType.TOWN)

		# Perform more than max undo actions
		for i in range(150):
			self.engine.set_tile(0, 0, i % 256, LayerType.BG1_GROUND)

		# Undo stack should be limited
		self.assertLessEqual(len(self.engine.undo_stack), 100)


class TestCompression(unittest.TestCase):
	"""Test compression/decompression algorithms"""

	def test_rle_compression(self):
		"""Test RLE compression"""
		# Create data with runs
		data = bytes([42] * 10)

		compressed = FFMQCompression.compress_map(data)
		decompressed = FFMQCompression.decompress_map(compressed)

		self.assertEqual(data, decompressed)
		self.assertLess(len(compressed), len(data))

	def test_literal_compression(self):
		"""Test literal data compression"""
		# Create random data
		data = bytes([i % 256 for i in range(100)])

		compressed = FFMQCompression.compress_map(data)
		decompressed = FFMQCompression.decompress_map(compressed)

		self.assertEqual(data, decompressed)

	def test_word_pattern_compression(self):
		"""Test word pattern compression"""
		# Create repeating 2-byte pattern
		data = bytes([0x12, 0x34] * 20)

		compressed = FFMQCompression.compress_map(data)
		decompressed = FFMQCompression.decompress_map(compressed)

		self.assertEqual(data, decompressed)
		self.assertLess(len(compressed), len(data))

	def test_empty_data(self):
		"""Test compression of empty data"""
		data = bytes()

		compressed = FFMQCompression.compress_map(data)
		decompressed = FFMQCompression.decompress_map(compressed)

		self.assertEqual(data, decompressed)

	def test_compression_validation(self):
		"""Test compression validation"""
		# Test various data patterns
		test_cases = [
			bytes([1] * 100),  # Single byte RLE
			bytes([i % 256 for i in range(200)]),  # Sequential
			bytes([0xFF, 0x00] * 50),  # Alternating pattern
			bytes([42]),  # Single byte
		]

		for data in test_cases:
			with self.subTest(data_len=len(data)):
				self.assertTrue(FFMQCompression.validate_compression(data))


class TestTilesetManager(unittest.TestCase):
	"""Test tileset management"""

	def setUp(self):
		"""Set up test fixtures"""
		self.manager = TilesetManager()

	def test_placeholder_tileset(self):
		"""Test placeholder tileset generation"""
		result = self.manager.load_tileset(0)

		self.assertTrue(result)
		self.assertIsNotNone(self.manager.current_tileset)
		self.assertEqual(self.manager.current_tileset_id, 0)

	def test_get_tile_surface(self):
		"""Test getting individual tile surfaces"""
		self.manager.load_tileset(0)

		tile_surface = self.manager.get_tile_surface(0)
		self.assertIsNotNone(tile_surface)
		self.assertEqual(tile_surface.get_width(), 8)
		self.assertEqual(tile_surface.get_height(), 8)

	def test_tile_scaling(self):
		"""Test tile surface scaling"""
		self.manager.load_tileset(0)

		tile_surface = self.manager.get_tile_surface(0, size=(32, 32))
		self.assertIsNotNone(tile_surface)
		self.assertEqual(tile_surface.get_width(), 32)
		self.assertEqual(tile_surface.get_height(), 32)

	def test_invalid_tile_id(self):
		"""Test handling of invalid tile IDs"""
		self.manager.load_tileset(0)

		# Negative ID
		tile_surface = self.manager.get_tile_surface(-1)
		self.assertIsNone(tile_surface)

		# Too large ID
		tile_surface = self.manager.get_tile_surface(256)
		self.assertIsNone(tile_surface)


class TestPaletteDecoding(unittest.TestCase):
	"""Test SNES palette decoding"""

	def test_decode_black(self):
		"""Test decoding black color"""
		# Black in SNES format: 0x0000
		palette_data = bytes([0x00, 0x00])
		palette = decode_snes_palette(palette_data, 1)

		self.assertEqual(len(palette), 1)
		self.assertEqual(palette[0], (0, 0, 0))

	def test_decode_white(self):
		"""Test decoding white color"""
		# White in SNES format: 0x7FFF
		palette_data = bytes([0xFF, 0x7F])
		palette = decode_snes_palette(palette_data, 1)

		self.assertEqual(len(palette), 1)
		self.assertEqual(palette[0], (255, 255, 255))

	def test_decode_red(self):
		"""Test decoding red color"""
		# Pure red in SNES format: 0x001F (5 bits)
		palette_data = bytes([0x1F, 0x00])
		palette = decode_snes_palette(palette_data, 1)

		self.assertEqual(len(palette), 1)
		self.assertEqual(palette[0], (255, 0, 0))

	def test_decode_multiple_colors(self):
		"""Test decoding multiple colors"""
		# 4 colors: black, red, green, blue
		palette_data = bytes([
			0x00, 0x00,  # Black
			0x1F, 0x00,  # Red
			0xE0, 0x03,  # Green
			0x00, 0x7C,  # Blue
		])
		palette = decode_snes_palette(palette_data, 4)

		self.assertEqual(len(palette), 4)
		self.assertEqual(palette[0], (0, 0, 0))
		self.assertEqual(palette[1], (255, 0, 0))
		self.assertEqual(palette[2], (0, 255, 0))
		self.assertEqual(palette[3], (0, 0, 255))


class TestFileFormats(unittest.TestCase):
	"""Test file format handlers"""

	def setUp(self):
		"""Set up test fixtures"""
		self.test_map = ExampleMapGenerator.create_simple_town(16, 16)
		self.test_dir = Path('test_output')
		self.test_dir.mkdir(exist_ok=True)

	def tearDown(self):
		"""Clean up test files"""
		import shutil
		if self.test_dir.exists():
			shutil.rmtree(self.test_dir)

	def test_ffmap_save_load(self):
		"""Test FFMAP format save/load"""
		filepath = self.test_dir / 'test.ffmap'

		# Save
		result = FFMAPFormat.save(str(filepath), self.test_map)
		self.assertTrue(result)
		self.assertTrue(filepath.exists())

		# Load
		loaded_map = FFMAPFormat.load(str(filepath))
		self.assertIsNotNone(loaded_map)
		self.assertEqual(loaded_map['width'], self.test_map['width'])
		self.assertEqual(loaded_map['height'], self.test_map['height'])

		# Verify tile data
		np.testing.assert_array_equal(
			loaded_map['bg1_tiles'],
			self.test_map['bg1_tiles']
		)

	def test_json_save_load(self):
		"""Test JSON format save/load"""
		filepath = self.test_dir / 'test.json'

		# Save
		result = JSONFormat.save(str(filepath), self.test_map)
		self.assertTrue(result)
		self.assertTrue(filepath.exists())

		# Load
		loaded_map = JSONFormat.load(str(filepath))
		self.assertIsNotNone(loaded_map)
		self.assertEqual(loaded_map['width'], self.test_map['width'])

		# Verify tile data
		np.testing.assert_array_equal(
			loaded_map['bg1_tiles'],
			self.test_map['bg1_tiles']
		)

	def test_binary_save_load(self):
		"""Test binary format save/load"""
		filepath = self.test_dir / 'test.bin'

		# Save
		result = BinaryFormat.save(str(filepath), self.test_map)
		self.assertTrue(result)
		self.assertTrue(filepath.exists())

		# Load
		loaded_map = BinaryFormat.load(str(filepath))
		self.assertIsNotNone(loaded_map)
		self.assertEqual(loaded_map['width'], self.test_map['width'])

		# Verify tile data
		np.testing.assert_array_equal(
			loaded_map['bg1_tiles'],
			self.test_map['bg1_tiles']
		)


class TestExampleMaps(unittest.TestCase):
	"""Test example map generation"""

	def test_simple_town_generation(self):
		"""Test simple town generation"""
		town = ExampleMapGenerator.create_simple_town(32, 32)

		self.assertEqual(town['width'], 32)
		self.assertEqual(town['height'], 32)
		self.assertEqual(town['map_type'], 'Town')
		self.assertIn('bg1_tiles', town)
		self.assertIn('bg2_tiles', town)
		self.assertIn('collision', town)

	def test_dungeon_generation(self):
		"""Test dungeon generation"""
		dungeon = ExampleMapGenerator.create_dungeon_room(32, 32)

		self.assertEqual(dungeon['map_type'], 'Dungeon')
		self.assertGreater(dungeon['encounter_rate'], 0)

	def test_overworld_generation(self):
		"""Test overworld generation"""
		overworld = ExampleMapGenerator.create_overworld_section(64, 64)

		self.assertEqual(overworld['width'], 64)
		self.assertEqual(overworld['height'], 64)
		self.assertEqual(overworld['map_type'], 'Overworld')

	def test_pattern_test_generation(self):
		"""Test pattern test map generation"""
		pattern = ExampleMapGenerator.create_pattern_test_map(32, 32)

		self.assertEqual(pattern['map_type'], 'Special')

		# Verify various patterns were created
		unique_tiles = len(np.unique(pattern['bg1_tiles']))
		self.assertGreater(unique_tiles, 10)


class TestMapData(unittest.TestCase):
	"""Test MapData class"""

	def test_map_data_creation(self):
		"""Test creating MapData"""
		map_data = MapData(32, 32)

		self.assertEqual(map_data.width, 32)
		self.assertEqual(map_data.height, 32)
		self.assertEqual(map_data.bg1_tiles.shape, (32, 32))
		self.assertEqual(map_data.bg2_tiles.shape, (32, 32))
		self.assertEqual(map_data.bg3_tiles.shape, (32, 32))

	def test_get_layer(self):
		"""Test getting layer data"""
		map_data = MapData(10, 10)

		bg1 = map_data.get_layer(LayerType.BG1_GROUND)
		self.assertIsNotNone(bg1)
		self.assertEqual(bg1.shape, (10, 10))

		bg2 = map_data.get_layer(LayerType.BG2_UPPER)
		self.assertIsNotNone(bg2)

		bg3 = map_data.get_layer(LayerType.BG3_EVENTS)
		self.assertIsNotNone(bg3)


def run_tests():
	"""Run all tests"""
	# Create test suite
	loader = unittest.TestLoader()
	suite = unittest.TestSuite()

	# Add all test classes
	suite.addTests(loader.loadTestsFromTestCase(TestMapEngine))
	suite.addTests(loader.loadTestsFromTestCase(TestCompression))
	suite.addTests(loader.loadTestsFromTestCase(TestTilesetManager))
	suite.addTests(loader.loadTestsFromTestCase(TestPaletteDecoding))
	suite.addTests(loader.loadTestsFromTestCase(TestFileFormats))
	suite.addTests(loader.loadTestsFromTestCase(TestExampleMaps))
	suite.addTests(loader.loadTestsFromTestCase(TestMapData))

	# Run tests
	runner = unittest.TextTestRunner(verbosity=2)
	result = runner.run(suite)

	# Print summary
	print("\n" + "=" * 70)
	print(f"Tests run: {result.testsRun}")
	print(f"Successes: {result.testsRun - len(result.failures) - len(result.errors)}")
	print(f"Failures: {len(result.failures)}")
	print(f"Errors: {len(result.errors)}")
	print("=" * 70)

	return result.wasSuccessful()


if __name__ == '__main__':
	success = run_tests()
	sys.exit(0 if success else 1)
