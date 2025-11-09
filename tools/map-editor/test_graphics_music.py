"""
Test Graphics and Music Systems

Verifies all graphics and music functionality.
"""

import unittest
import sys
from pathlib import Path

# Add parent to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from utils.graphics_data import (
    Color, Palette, Tile, Sprite, Animation, AnimationFrame,
    Tileset, SpriteSheet, PaletteType, SpriteSize, AnimationType,
    create_gradient_palette, create_blank_tile, create_solid_tile
)
from utils.graphics_database import GraphicsDatabase

from utils.music_data import (
    MusicTrack, SoundEffect, Sample, SPCState,
    MusicType, SoundEffectType,
    create_default_track, create_default_sfx,
    note_to_pitch, pitch_to_note
)
from utils.music_database import MusicDatabase


class TestGraphicsData(unittest.TestCase):
    """Test graphics data structures"""

    def test_color_conversion(self):
        """Test BGR555 <-> RGB888 conversion"""
        # Test black
        color = Color(0, 0, 0)
        r, g, b = color.to_rgb888()
        self.assertEqual((r, g, b), (0, 0, 0))

        # Test white
        color = Color(31, 31, 31)
        r, g, b = color.to_rgb888()
        self.assertEqual((r, g, b), (255, 255, 255))

        # Test round-trip
        original = Color.from_rgb888(128, 200, 64)
        r, g, b = original.to_rgb888()
        converted = Color.from_rgb888(r, g, b)
        self.assertEqual(original.red, converted.red)
        self.assertEqual(original.green, converted.green)
        self.assertEqual(original.blue, converted.blue)

    def test_palette_serialization(self):
        """Test palette to_bytes/from_bytes"""
        # Create palette
        palette = Palette(palette_id=5, palette_type=PaletteType.SPRITE)
        palette.colors[0] = Color(0, 0, 0)
        palette.colors[1] = Color(31, 0, 0)
        palette.colors[2] = Color(0, 31, 0)
        palette.colors[3] = Color(0, 0, 31)

        # Serialize
        data = palette.to_bytes()
        self.assertEqual(len(data), 32)

        # Deserialize
        restored = Palette.from_bytes(data, 5)
        self.assertEqual(restored.palette_id, palette.palette_id)
        self.assertEqual(restored.colors[0].red, palette.colors[0].red)
        self.assertEqual(restored.colors[1].red, palette.colors[1].red)

    def test_tile_operations(self):
        """Test tile pixel operations"""
        tile = Tile(tile_id=10)

        # Set pixels
        tile.set_pixel(0, 0, 1)
        tile.set_pixel(7, 7, 15)

        # Get pixels
        self.assertEqual(tile.get_pixel(0, 0), 1)
        self.assertEqual(tile.get_pixel(7, 7), 15)
        self.assertEqual(tile.get_pixel(4, 4), 0)  # Default

        # Test bounds
        with self.assertRaises(ValueError):
            tile.set_pixel(8, 0, 1)

    def test_tile_flip(self):
        """Test tile flipping"""
        tile = Tile(tile_id=0)
        tile.set_pixel(0, 0, 1)
        tile.set_pixel(7, 0, 2)

        # Flip horizontally
        flipped = tile.flip_horizontal()
        self.assertEqual(flipped.get_pixel(7, 0), 1)
        self.assertEqual(flipped.get_pixel(0, 0), 2)

    def test_tileset_serialization(self):
        """Test tileset to_bytes/from_bytes"""
        # Create small tileset
        tileset = Tileset(tileset_id=1, name="Test")
        for i in range(10):
            tile = Tile(tile_id=i)
            tileset.add_tile(tile)

        # Serialize
        data = tileset.to_bytes()
        self.assertEqual(len(data), 10 * 32)

        # Deserialize
        restored = Tileset.from_bytes(data, 1, 10)
        self.assertEqual(len(restored.tiles), 10)

    def test_gradient_palette(self):
        """Test gradient palette generation"""
        start = Color(0, 0, 0)
        end = Color(31, 31, 31)

        palette = create_gradient_palette(start, end)
        self.assertEqual(len(palette.colors), 16)
        self.assertEqual(palette.colors[0].red, 0)
        self.assertEqual(palette.colors[15].red, 31)

    def test_sprite_size(self):
        """Test sprite size calculations"""
        sprite = Sprite(sprite_id=0, size=SpriteSize.SIZE_16x16)
        width, height = sprite.get_size_pixels()
        self.assertEqual(width, 16)
        self.assertEqual(height, 16)

        sprite = Sprite(sprite_id=1, size=SpriteSize.SIZE_32x64)
        width, height = sprite.get_size_pixels()
        self.assertEqual(width, 32)
        self.assertEqual(height, 64)


class TestMusicData(unittest.TestCase):
    """Test music data structures"""

    def test_music_track_serialization(self):
        """Test track to_bytes/from_bytes"""
        # Create track
        track = MusicTrack(
            track_id=5,
            name="Test Track",
            music_type=MusicType.BATTLE,
            tempo=140,
            volume=100,
            loop_start=100,
            loop_end=500
        )

        # Serialize
        data = track.to_bytes()
        self.assertEqual(len(data), 16)

        # Deserialize
        restored = MusicTrack.from_bytes(data, 5)
        self.assertEqual(restored.music_type, MusicType.BATTLE)
        self.assertEqual(restored.tempo, 140)
        self.assertEqual(restored.volume, 100)
        self.assertEqual(restored.loop_start, 100)
        self.assertEqual(restored.loop_end, 500)

    def test_sfx_serialization(self):
        """Test SFX to_bytes/from_bytes"""
        # Create SFX
        sfx = SoundEffect(
            sfx_id=10,
            name="Test SFX",
            sfx_type=SoundEffectType.ATTACK,
            priority=80,
            volume=120,
            pitch=64,
            pan=100
        )

        # Serialize
        data = sfx.to_bytes()
        self.assertEqual(len(data), 12)

        # Deserialize
        restored = SoundEffect.from_bytes(data, 10)
        self.assertEqual(restored.sfx_type, SoundEffectType.ATTACK)
        self.assertEqual(restored.priority, 80)
        self.assertEqual(restored.volume, 120)
        self.assertEqual(restored.pitch, 64)
        self.assertEqual(restored.pan, 100)

    def test_sample_serialization(self):
        """Test sample to_bytes/from_bytes"""
        sample = Sample(
            sample_id=3,
            name="Test Sample",
            loop_start=100,
            loop_length=200,
            pitch_multiplier=256,
            envelope=0xE0
        )

        # Serialize
        data = sample.to_bytes()
        self.assertEqual(len(data), 16)

        # Deserialize
        restored = Sample.from_bytes(data, 3)
        self.assertEqual(restored.loop_start, 100)
        self.assertEqual(restored.loop_length, 200)
        self.assertEqual(restored.pitch_multiplier, 256)
        self.assertEqual(restored.envelope, 0xE0)

    def test_note_conversion(self):
        """Test note <-> pitch conversion"""
        # Test specific notes
        pitch_c4 = note_to_pitch("C4")
        self.assertGreater(pitch_c4, 0)

        pitch_a4 = note_to_pitch("A4")
        self.assertGreater(pitch_a4, pitch_c4)

        # Test pitch to note
        note = pitch_to_note(0x1000)
        self.assertIn("C", note)
        self.assertIn("4", note)

    def test_track_duration(self):
        """Test track duration calculation"""
        track = MusicTrack(track_id=0)
        track.loop_end = 3600  # 60 seconds at 60 ticks/sec

        duration = track.get_duration_seconds(60)
        self.assertEqual(duration, 60.0)

    def test_spc_state(self):
        """Test SPC state serialization"""
        state = SPCState()
        state.master_volume_l = 100
        state.master_volume_r = 100
        state.channel_volumes = [80] * 8

        # Serialize
        data = state.to_bytes()
        self.assertEqual(len(data), 128)

        # Deserialize
        restored = SPCState.from_bytes(data)
        self.assertEqual(restored.master_volume_l, 100)
        self.assertEqual(restored.master_volume_r, 100)


class TestGraphicsDatabase(unittest.TestCase):
    """Test graphics database operations"""

    def test_database_creation(self):
        """Test creating graphics database"""
        db = GraphicsDatabase()
        self.assertEqual(len(db.tilesets), 0)
        self.assertEqual(len(db.palettes), 0)

    def test_statistics(self):
        """Test statistics gathering"""
        db = GraphicsDatabase()

        # Add test data
        palette = Palette(palette_id=0, palette_type=PaletteType.CHARACTER)
        db.palettes[0] = palette

        tileset = Tileset(tileset_id=0, name="Test")
        for i in range(100):
            tileset.add_tile(Tile(tile_id=i))
        db.tilesets[0] = tileset

        # Get stats
        stats = db.get_statistics()
        self.assertEqual(stats['total_palettes'], 1)
        self.assertEqual(stats['total_tilesets'], 1)
        self.assertEqual(stats['total_tiles'], 100)

    def test_find_similar_colors(self):
        """Test finding similar colors"""
        db = GraphicsDatabase()

        # Create palettes with similar colors
        palette1 = Palette(palette_id=0, palette_type=PaletteType.SPRITE)
        palette1.colors[0] = Color.from_rgb888(255, 0, 0)
        palette1.colors[1] = Color.from_rgb888(250, 5, 5)
        db.palettes[0] = palette1

        # Find similar to red
        red = Color.from_rgb888(255, 0, 0)
        similar = db.find_similar_colors(red, threshold=10)

        self.assertGreater(len(similar), 0)


class TestMusicDatabase(unittest.TestCase):
    """Test music database operations"""

    def test_database_creation(self):
        """Test creating music database"""
        db = MusicDatabase()
        self.assertEqual(len(db.tracks), 0)
        self.assertEqual(len(db.sfx), 0)

    def test_add_track(self):
        """Test adding track"""
        db = MusicDatabase()
        track = create_default_track(0, MusicType.FIELD)

        success = db.add_track(track)
        self.assertTrue(success)
        self.assertEqual(len(db.tracks), 1)

    def test_add_sfx(self):
        """Test adding SFX"""
        db = MusicDatabase()
        sfx = create_default_sfx(0, SoundEffectType.MENU)

        success = db.add_sfx(sfx)
        self.assertTrue(success)
        self.assertEqual(len(db.sfx), 1)

    def test_find_unused_slots(self):
        """Test finding unused slots"""
        db = MusicDatabase()

        # Add some tracks
        db.add_track(create_default_track(0))
        db.add_track(create_default_track(1))
        db.add_track(create_default_track(5))

        unused = db.find_unused_tracks()
        self.assertIn(2, unused)
        self.assertIn(3, unused)
        self.assertNotIn(0, unused)
        self.assertNotIn(1, unused)

    def test_duplicate_track(self):
        """Test track duplication"""
        db = MusicDatabase()
        original = create_default_track(0)
        original.name = "Original"
        db.add_track(original)

        # Duplicate
        duplicate = db.duplicate_track(0, 1)
        self.assertIsNotNone(duplicate)
        self.assertEqual(duplicate.track_id, 1)
        self.assertIn("Copy", duplicate.name)

    def test_swap_tracks(self):
        """Test swapping tracks"""
        db = MusicDatabase()
        track1 = create_default_track(0)
        track1.name = "Track 1"
        track2 = create_default_track(1)
        track2.name = "Track 2"

        db.add_track(track1)
        db.add_track(track2)

        # Swap
        success = db.swap_tracks(0, 1)
        self.assertTrue(success)
        self.assertEqual(db.tracks[0].name, "Track 2")
        self.assertEqual(db.tracks[1].name, "Track 1")

    def test_validate_track(self):
        """Test track validation"""
        db = MusicDatabase()
        track = create_default_track(0)
        db.add_track(track)

        # Should be valid
        issues = db.validate_track(0)
        self.assertEqual(len(issues), 0)

        # Make invalid
        track.tempo = 300  # Too high
        issues = db.validate_track(0)
        self.assertGreater(len(issues), 0)

    def test_statistics(self):
        """Test statistics gathering"""
        db = MusicDatabase()

        # Add test data
        db.add_track(create_default_track(0, MusicType.FIELD))
        db.add_track(create_default_track(1, MusicType.BATTLE))
        db.add_sfx(create_default_sfx(0, SoundEffectType.MENU))

        stats = db.get_statistics()
        self.assertEqual(stats['total_tracks'], 2)
        self.assertEqual(stats['total_sfx'], 1)


def run_tests():
    """Run all tests"""
    # Create test suite
    loader = unittest.TestLoader()
    suite = unittest.TestSuite()

    # Add all test cases
    suite.addTests(loader.loadTestsFromTestCase(TestGraphicsData))
    suite.addTests(loader.loadTestsFromTestCase(TestMusicData))
    suite.addTests(loader.loadTestsFromTestCase(TestGraphicsDatabase))
    suite.addTests(loader.loadTestsFromTestCase(TestMusicDatabase))

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
