# Testing Tools

This directory contains tools for testing ROM builds, validating data integrity, and ensuring code quality.

## Core Testing Tools

### Test Execution
- **run_all_tests.py** ⭐ - Run complete test suite
  - Executes all project tests
  - Generates test reports
  - Tracks pass/fail statistics
  - Supports parallel test execution
  - Usage: `python tools/testing/run_all_tests.py [--verbose] [--parallel]`

- **run_tests.py** - Run specific tests
  - Execute individual test files
  - Filter tests by pattern
  - Skip known failures
  - Usage: `python tools/testing/run_tests.py <test_file.py> [--filter <pattern>]`

### ROM Testing
- **rom_tester.py** - ROM functionality testing
  - Test ROM in automated emulator
  - Validate game states
  - Test battle mechanics
  - Check save/load functionality
  - Usage: `python tools/testing/rom_tester.py --rom <file.smc> [--tests <suite>]`

### Pipeline Testing
- **test_pipeline.py** - Test build/extraction pipeline
  - Validate complete workflow
  - Test data round-trips (extract → modify → import → build)
  - Verify data integrity throughout pipeline
  - Usage: `python tools/testing/test_pipeline.py [--full]`

### Data Validation
- **verify_gamefaqs_data.py** - Verify data against GameFAQs
  - Compare extracted data with GameFAQs guides
  - Validate enemy stats
  - Check item properties
  - Verify spell data
  - Usage: `python tools/testing/verify_gamefaqs_data.py --data <extracted_data.json>`

## Test Categories

### Unit Tests
Located in `tests/unit/`:
- `test_snes_graphics.py` - Graphics library tests
- `test_rom_operations.py` - ROM manipulation tests
- `test_build_system.py` - Build system tests
- `test_data_extraction.py` - Extraction tests

### Integration Tests
Located in `tests/integration/`:
- `test_build_integration.py` - Full build workflow
- `test_data_pipeline.py` - Data pipeline tests
- `test_import_export.py` - Import/export round-trips

### Validation Tests
Located in `tests/validation/`:
- `test_rom_integrity.py` - ROM integrity checks
- `test_data_consistency.py` - Data consistency tests
- `test_cross_references.py` - Reference validation

### Regression Tests
Located in `tests/regression/`:
- `test_known_issues.py` - Tests for previously fixed bugs
- `test_compatibility.py` - Version compatibility tests

## Common Workflows

### Run Full Test Suite
```bash
# Run all tests
python tools/testing/run_all_tests.py

# Run with verbose output
python tools/testing/run_all_tests.py --verbose

# Run in parallel for speed
python tools/testing/run_all_tests.py --parallel --jobs 4

# Generate HTML report
python tools/testing/run_all_tests.py --output-html reports/test_report.html
```

### Run Specific Test Category
```bash
# Unit tests only
python tools/testing/run_tests.py tests/unit/

# Integration tests
python tools/testing/run_tests.py tests/integration/

# Single test file
python tools/testing/run_tests.py tests/unit/test_snes_graphics.py

# Specific test function
python tools/testing/run_tests.py tests/unit/test_snes_graphics.py::test_decode_2bpp
```

### Test ROM Functionality
```bash
# Test basic ROM functionality
python tools/testing/rom_tester.py --rom build/ffmq.smc --quick

# Full ROM test suite
python tools/testing/rom_tester.py --rom build/ffmq.smc --full

# Test specific game features
python tools/testing/rom_tester.py --rom build/ffmq.smc --tests battle,save,items

# Compare with reference ROM
python tools/testing/rom_tester.py --rom build/ffmq.smc --reference roms/original.smc
```

### Validate Pipeline
```bash
# Quick pipeline test
python tools/testing/test_pipeline.py

# Full pipeline with all data
python tools/testing/test_pipeline.py --full

# Test specific data type
python tools/testing/test_pipeline.py --type enemies

# Verbose output for debugging
python tools/testing/test_pipeline.py --verbose
```

### Verify Against Reference Data
```bash
# Verify enemy data
python tools/testing/verify_gamefaqs_data.py --data assets/enemies.json --type enemies

# Verify all data types
python tools/testing/verify_gamefaqs_data.py --data assets/ --all

# Generate discrepancy report
python tools/testing/verify_gamefaqs_data.py --data assets/ --output discrepancies.txt
```

### Pre-Commit Testing
```bash
# Quick pre-commit test suite
python tools/testing/run_all_tests.py --fast

# Build and test
python tools/build/build_rom.py && python tools/testing/run_all_tests.py --smoke

# Full pre-push validation
python tools/testing/run_all_tests.py --full && python tools/testing/test_pipeline.py --full
```

## Test Configuration

### pytest.ini
```ini
[pytest]
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*
addopts = 
    --verbose
    --color=yes
    --strict-markers
    --tb=short
markers =
    slow: marks tests as slow
    integration: marks integration tests
    rom: marks tests requiring ROM file
```

### Test Environment Variables
- `FFMQ_TEST_ROM` - Path to test ROM
- `FFMQ_REFERENCE_ROM` - Path to reference ROM
- `FFMQ_TEST_DATA` - Path to test data directory
- `FFMQ_EMULATOR` - Path to emulator for ROM tests

## Writing Tests

### Unit Test Example
```python
# tests/unit/test_snes_graphics.py
import pytest
from tools.graphics.snes_graphics import decode_2bpp, encode_2bpp

def test_decode_2bpp():
    """Test 2bpp tile decoding"""
    # 8x8 tile with simple pattern
    tile_data = bytes([0xFF, 0x00] * 8)
    pixels = decode_2bpp(tile_data)
    
    assert len(pixels) == 64  # 8x8
    assert pixels[0] == 1  # First pixel color 1
    assert pixels[1] == 0  # Second pixel color 0

def test_roundtrip_2bpp():
    """Test encoding/decoding round-trip"""
    original = bytes([0xAB, 0xCD] * 8)
    pixels = decode_2bpp(original)
    encoded = encode_2bpp(pixels)
    
    assert encoded == original
```

### Integration Test Example
```python
# tests/integration/test_data_pipeline.py
import pytest
from tools.data_extraction.extract_enemies import extract_enemy
from tools.battle.integrate_battle_data import integrate_enemy

@pytest.mark.integration
def test_enemy_roundtrip():
    """Test enemy extract → modify → integrate → extract"""
    # Extract original
    original = extract_enemy(42)
    
    # Modify
    modified = original.copy()
    modified['hp'] = 9999
    
    # Integrate
    integrate_enemy(42, modified)
    
    # Re-extract
    result = extract_enemy(42)
    
    # Verify
    assert result['hp'] == 9999
    assert result['name'] == original['name']
```

### ROM Test Example
```python
# tests/validation/test_rom_integrity.py
import pytest
from tools.testing.rom_tester import ROMTester

@pytest.mark.rom
def test_rom_boots():
    """Test ROM boots successfully"""
    tester = ROMTester('build/ffmq.smc')
    assert tester.boot()
    assert tester.title_screen_appears()

@pytest.mark.rom
def test_start_new_game():
    """Test can start new game"""
    tester = ROMTester('build/ffmq.smc')
    tester.boot()
    tester.press_start()
    tester.select_new_game()
    
    assert tester.in_game()
    assert tester.get_location() == "Hill of Destiny"
```

## Test Reports

### Console Output
```
============================= test session starts ==============================
platform win32 -- Python 3.11.0, pytest-7.4.0
collected 142 items

tests/unit/test_snes_graphics.py ..................                     [ 12%]
tests/unit/test_rom_operations.py .........................            [ 30%]
tests/integration/test_build_integration.py ........                   [ 36%]
tests/integration/test_data_pipeline.py ...........                    [ 44%]
tests/validation/test_rom_integrity.py .....                           [ 48%]
tests/validation/test_data_consistency.py .................            [ 60%]

============================== 142 passed in 45.2s ==============================
```

### HTML Report
Generates visual HTML report with:
- Pass/fail summary
- Test duration breakdown
- Failed test details
- Code coverage
- Historical trends

### JSON Report
```json
{
    "summary": {
        "total": 142,
        "passed": 140,
        "failed": 2,
        "skipped": 0,
        "duration": 45.2
    },
    "failures": [
        {
            "test": "tests/unit/test_new_feature.py::test_edge_case",
            "error": "AssertionError: expected 100, got 99",
            "traceback": "..."
        }
    ]
}
```

## Continuous Integration

### GitHub Actions
```yaml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Set up Python
        uses: actions/setup-python@v2
        with:
          python-version: 3.11
      - name: Install dependencies
        run: pip install -r requirements.txt
      - name: Run tests
        run: python tools/testing/run_all_tests.py --ci
```

## Dependencies

- Python 3.7+
- **pytest** - `pip install pytest` (test framework)
- **pytest-cov** - `pip install pytest-cov` (coverage)
- **pytest-html** - `pip install pytest-html` (HTML reports)
- **pytest-xdist** - `pip install pytest-xdist` (parallel execution)
- Emulator (for ROM tests) - Mesen-S or SNES9x

## See Also

- **tools/build/** - For build system tests
- **tools/validation/** - For data validation
- **tools/analysis/** - For test coverage analysis
- **docs/guides/TESTING_GUIDE.md** - Testing best practices

## Tips and Best Practices

### Test Organization
- Group related tests in classes
- Use descriptive test names
- One assertion per test (when possible)
- Use fixtures for setup/teardown
- Mark slow tests with `@pytest.mark.slow`

### Test Data
- Store test data in `tests/data/`
- Use small, focused test ROMs
- Version control test data
- Document test data sources

### Performance
- Use `--parallel` for faster execution
- Cache expensive operations
- Mock external dependencies
- Skip slow tests during development

### Debugging Failed Tests
```bash
# Run with verbose output
python tools/testing/run_tests.py <test> -vv

# Drop into debugger on failure
python tools/testing/run_tests.py <test> --pdb

# Run only failed tests
python tools/testing/run_tests.py --lf

# Show print statements
python tools/testing/run_tests.py <test> -s
```

## Troubleshooting

**Issue: Tests fail with "ROM not found"**
- Solution: Set `FFMQ_TEST_ROM` environment variable

**Issue: Parallel tests fail**
- Solution: Ensure tests are independent, no shared state

**Issue: ROM tests timeout**
- Solution: Increase timeout, check emulator installation

**Issue: Flaky tests**
- Solution: Identify race conditions, add proper waits

## Code Coverage

### Generate Coverage Report
```bash
# Run tests with coverage
python tools/testing/run_all_tests.py --coverage

# Generate HTML coverage report
python tools/testing/run_all_tests.py --coverage --coverage-html reports/coverage/

# Coverage for specific module
python tools/testing/run_tests.py tests/ --coverage --coverage-module tools.graphics
```

### Coverage Thresholds
- Excellent: 90%+
- Good: 70-90%
- Acceptable: 50-70%
- Poor: <50%

Current coverage: ~65%

## Contributing

When adding tests:
1. Follow pytest naming conventions
2. Add docstrings to test functions
3. Use fixtures for common setup
4. Mark tests appropriately (slow, integration, etc.)
5. Update test documentation
6. Ensure tests are deterministic
7. Add to appropriate test suite

## Future Development

Planned additions:
- [ ] Automated emulator testing
- [ ] Performance benchmarking
- [ ] Mutation testing
- [ ] Property-based testing
- [ ] Fuzz testing
- [ ] Visual regression testing
- [ ] Test generation from specs
