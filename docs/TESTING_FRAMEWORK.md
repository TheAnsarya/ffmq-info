# FFMQ Testing Documentation

Automated testing suite for FFMQ reverse engineering project.

## Overview

The testing framework provides comprehensive validation of:
- **Data Extraction**: Unit tests for ROM data extraction tools
- **Data Integrity**: Validation of extracted data structures
- **Build System**: Integration tests for ROM building
- **Validation Tools**: Verification that validation tools work correctly

## Test Structure

```
tests/
├── run_unit_tests.py          # Unit test runner
├── test_extract_enemies.py    # Enemy extraction tests
├── test_extract_attacks.py    # Attack extraction tests
├── test_extract_spells.py     # Spell extraction tests
└── __init__.py                # Test package init

tools/
└── run_tests.py               # Full integration test framework
```

## Running Tests

### Quick Test (Unit Tests Only)

```powershell
# Run all unit tests
python tests/run_unit_tests.py

# Run specific test file
python -m unittest tests.test_extract_enemies

# Run specific test case
python -m unittest tests.test_extract_enemies.TestEnemyExtraction.test_enemy_count
```

### Full Test Suite (Unit + Integration)

```powershell
# Run comprehensive test suite
python tools/run_tests.py
```

This runs:
- ✅ Data file existence checks
- ✅ Data structure validation
- ✅ ROM integrity verification
- ✅ Validation tool execution
- ✅ Visualization tool execution
- ✅ Build system checks

## Test Categories

### 1. Data Extraction Tests

**test_extract_enemies.py** - Enemy data validation
- Enemy count (83 total)
- Data structure correctness
- HP/stats within valid ranges (0-255 or 0-65535)
- Element bitfield parsing (16-bit)
- Unique sequential IDs
- No resistance/weakness overlap
- Known enemy verification (Behemoth stats)

**test_extract_attacks.py** - Attack data validation
- Attack count (169 total)
- Data structure correctness
- Power values (0-255)
- Type/target byte validity
- Unique sequential IDs
- Power distribution analysis
- Name uniqueness

**test_extract_spells.py** - Spell data validation
- Spell effect count (16 total)
- Learnable spell mapping (12 spells)
- MP cost validity (0-99)
- Power values (0-255)
- Known spell existence (Fire, Blizzard, etc.)
- Randomizer mapping correctness

### 2. Integration Tests

**run_tests.py** - Full system validation
- Data file existence
- JSON structure validation
- ROM file integrity
- Validation tool execution
- Visualization tool execution
- Build system components

## Test Results

### Output Files

Test results are saved to:
```
reports/
├── unit_test_results.json     # Unit test detailed results
└── test_results.json          # Integration test results
```

### Report Format

```json
{
	"timestamp": "2025-01-15T10:30:00",
	"summary": {
		"total_tests": 45,
		"passed": 45,
		"failed": 0,
		"errors": 0,
		"skipped": 0,
		"pass_rate": 100.0
	},
	"status": "success",
	"failures": [],
	"errors": []
}
```

## Writing New Tests

### Unit Test Template

```python
import unittest
from pathlib import Path

project_dir = Path(__file__).parent.parent

class TestNewFeature(unittest.TestCase):
	"""Test description"""
	
	@classmethod
	def setUpClass(cls):
		"""Load data once for all tests"""
		# Load test data
		pass
	
	def test_something(self):
		"""Test specific behavior"""
		self.assertEqual(actual, expected, "Failure message")
```

### Test Naming Convention

- Test files: `test_<module_name>.py`
- Test classes: `Test<FeatureName>`
- Test methods: `test_<specific_behavior>`

### Assertions

Common assertions:
```python
self.assertEqual(a, b)           # a == b
self.assertNotEqual(a, b)        # a != b
self.assertTrue(x)               # bool(x) is True
self.assertFalse(x)              # bool(x) is False
self.assertIs(a, b)              # a is b
self.assertIsNone(x)             # x is None
self.assertIn(a, b)              # a in b
self.assertIsInstance(a, b)      # isinstance(a, b)
self.assertGreater(a, b)         # a > b
self.assertLess(a, b)            # a < b
self.assertGreaterEqual(a, b)    # a >= b
self.assertLessEqual(a, b)       # a <= b
```

## Test Coverage

### Current Coverage

| Component | Tests | Coverage |
|-----------|-------|----------|
| Enemy Extraction | 11 | 100% |
| Attack Extraction | 8 | 100% |
| Spell Extraction | 8 | 100% |
| Data Integrity | 6 | 100% |
| ROM Integrity | 3 | 100% |
| Validation Tools | 2 | 100% |
| Visualization Tools | 3 | 100% |
| Build System | 3 | 100% |

### Planned Coverage

- [ ] Text extraction tests
- [ ] Graphics extraction tests
- [ ] Music extraction tests
- [ ] Palette extraction tests
- [ ] Map data extraction tests
- [ ] Build system integration tests

## Continuous Integration

### GitHub Actions (Future)

```yaml
name: Run Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-python@v2
      - run: pip install -r requirements.txt
      - run: python tests/run_unit_tests.py
      - run: python tools/run_tests.py
```

## Troubleshooting

### Common Issues

**Issue**: `FileNotFoundError: Enemy data not found`
```powershell
# Solution: Extract data first
python tools/extract_enemies.py
```

**Issue**: `AssertionError: Expected 83 enemies, found 0`
```powershell
# Solution: Verify extraction completed successfully
python tools/extract_all_assets.py
```

**Issue**: Tests hang on validation tools
```powershell
# Solution: Check ROM file exists
ls roms/
```

## Best Practices

1. **Run tests before committing** - Verify changes don't break extraction
2. **Add tests for new features** - Maintain test coverage
3. **Use descriptive test names** - Make failures easy to understand
4. **Test edge cases** - Min/max values, empty data, invalid inputs
5. **Keep tests fast** - Unit tests should complete in seconds

## Performance

Expected test durations:
- Unit tests: ~5 seconds
- Integration tests: ~30 seconds
- Full validation suite: ~2 minutes

## Exit Codes

- `0` - All tests passed
- `1` - Some tests failed
- `2` - Test execution error

## Related Documentation

- [BUILD_QUICK_START.md](../BUILD_QUICK_START.md) - Build system setup
- [DATA_EXTRACTION_PLAN.md](../DATA_EXTRACTION_PLAN.md) - Extraction overview
- [PROGRESS_REPORT.md](../PROGRESS_REPORT.md) - Project status

## Support

For issues with the testing framework, check:
1. Test output in `reports/unit_test_results.json`
2. Integration test output in `reports/test_results.json`
3. Individual test file documentation
