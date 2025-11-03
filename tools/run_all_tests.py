#!/usr/bin/env python3
"""
Master Test Suite Runner
=========================

Runs all verification and validation tests for the FFMQ battle data pipeline.

Test Categories:
1. Pipeline Tests - End-to-end workflow validation
2. GameFAQs Verification - Community data accuracy
3. Build Integration - ROM modification verification
4. Round-Trip Verification - Data integrity checks

Usage:
    python tools/run_all_tests.py
    python tools/run_all_tests.py --category pipeline
    python tools/run_all_tests.py --verbose
"""

import subprocess
import sys
from pathlib import Path
import argparse
from datetime import datetime

# Test configurations
TESTS = {
    'pipeline': {
        'name': 'Pipeline End-to-End Tests',
        'script': 'tools/test_pipeline.py',
        'required': True,
        'description': 'Validates extraction, modification, and conversion workflow'
    },
    'gamefaqs': {
        'name': 'GameFAQs Data Verification',
        'script': 'tools/verify_gamefaqs_data.py',
        'required': False,
        'description': 'Compares extracted data against community-verified values'
    },
    'build': {
        'name': 'Build Integration Verification',
        'script': 'tools/verify_build_integration.py',
        'required': True,
        'description': 'Verifies battle data is correctly integrated into ROM'
    }
}

class Colors:
    """ANSI color codes for terminal output."""
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

def print_header(text):
    """Print a formatted header."""
    print()
    print("=" * 80)
    print(f"{Colors.BOLD}{Colors.HEADER}{text}{Colors.ENDC}")
    print("=" * 80)

def print_success(text):
    """Print success message."""
    print(f"{Colors.OKGREEN}✓ {text}{Colors.ENDC}")

def print_error(text):
    """Print error message."""
    print(f"{Colors.FAIL}✗ {text}{Colors.ENDC}")

def print_info(text):
    """Print info message."""
    print(f"{Colors.OKCYAN}ℹ {text}{Colors.ENDC}")

def run_test(test_key, verbose=False):
    """
    Run a single test.
    
    Args:
        test_key: Key of test in TESTS dict
        verbose: Show full output
        
    Returns:
        (passed, output) tuple
    """
    test = TESTS[test_key]
    script_path = Path(test['script'])
    
    if not script_path.exists():
        print_error(f"Test script not found: {script_path}")
        return False, ""
    
    print_info(f"Running: {test['name']}")
    print(f"  Description: {test['description']}")
    
    try:
        result = subprocess.run(
            [sys.executable, str(script_path)],
            capture_output=True,
            text=True,
            timeout=60
        )
        
        passed = result.returncode == 0
        
        if verbose or not passed:
            print()
            print(result.stdout)
            if result.stderr:
                print(result.stderr)
        
        if passed:
            print_success(f"{test['name']} PASSED")
        else:
            print_error(f"{test['name']} FAILED (exit code {result.returncode})")
        
        return passed, result.stdout + result.stderr
        
    except subprocess.TimeoutExpired:
        print_error(f"{test['name']} TIMEOUT (>60s)")
        return False, "Test timed out"
    except Exception as e:
        print_error(f"{test['name']} ERROR: {e}")
        return False, str(e)

def run_all_tests(category=None, verbose=False):
    """
    Run all tests or tests in a specific category.
    
    Args:
        category: Test category to run (None = all)
        verbose: Show full output for all tests
        
    Returns:
        (total, passed, failed) tuple
    """
    print_header("FFMQ Battle Data Pipeline - Master Test Suite")
    print(f"Started: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()
    
    # Determine which tests to run
    if category:
        if category not in TESTS:
            print_error(f"Unknown test category: {category}")
            print(f"Available categories: {', '.join(TESTS.keys())}")
            return 0, 0, 0
        
        tests_to_run = {category: TESTS[category]}
    else:
        tests_to_run = TESTS
    
    print_info(f"Running {len(tests_to_run)} test suite(s)")
    print()
    
    results = {}
    
    # Run each test
    for test_key in tests_to_run:
        print_header(f"Test Suite: {TESTS[test_key]['name']}")
        passed, output = run_test(test_key, verbose)
        results[test_key] = {
            'passed': passed,
            'output': output,
            'required': TESTS[test_key]['required']
        }
        print()
    
    # Summary
    print_header("Test Results Summary")
    
    total = len(results)
    passed_count = sum(1 for r in results.values() if r['passed'])
    failed_count = total - passed_count
    required_failed = sum(1 for r in results.values() if not r['passed'] and r['required'])
    
    for test_key, result in results.items():
        test = TESTS[test_key]
        status = "✓ PASS" if result['passed'] else "✗ FAIL"
        required = "(REQUIRED)" if test['required'] else "(OPTIONAL)"
        
        if result['passed']:
            print_success(f"{status:8} {test['name']:40} {required}")
        else:
            print_error(f"{status:8} {test['name']:40} {required}")
    
    print()
    print(f"Total Tests:    {total}")
    print(f"Passed:         {passed_count}")
    print(f"Failed:         {failed_count}")
    print(f"Required Failed: {required_failed}")
    print()
    
    if passed_count == total:
        print_success("ALL TESTS PASSED! 🎉")
        print()
        print("Your FFMQ battle data pipeline is fully functional!")
        print()
        print("You can now:")
        print("  • Edit enemies with the GUI (enemy_editor.bat)")
        print("  • Build modified ROMs (pwsh -File build.ps1)")
        print("  • Test in your emulator (mesen build/ffmq-rebuilt.sfc)")
        return total, passed_count, failed_count
    elif required_failed == 0:
        print_info("All required tests passed (some optional tests failed)")
        return total, passed_count, failed_count
    else:
        print_error(f"CRITICAL: {required_failed} required test(s) failed!")
        print()
        print("Please fix the failing tests before using the pipeline.")
        return total, passed_count, failed_count

def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description='Run FFMQ battle data pipeline test suite',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Test Categories:
  pipeline  - End-to-end pipeline tests (extraction, conversion, modification)
  gamefaqs  - GameFAQs data verification (community validation)
  build     - Build integration tests (ROM verification)

Examples:
  python tools/run_all_tests.py                    # Run all tests
  python tools/run_all_tests.py --category pipeline # Run pipeline tests only
  python tools/run_all_tests.py --verbose          # Show full output
        """
    )
    
    parser.add_argument(
        '--category',
        choices=list(TESTS.keys()),
        help='Run only tests in specified category'
    )
    
    parser.add_argument(
        '--verbose', '-v',
        action='store_true',
        help='Show full output for all tests'
    )
    
    args = parser.parse_args()
    
    total, passed, failed = run_all_tests(
        category=args.category,
        verbose=args.verbose
    )
    
    # Exit code: 0 if all tests passed, 1 otherwise
    sys.exit(0 if failed == 0 else 1)

if __name__ == '__main__':
    main()
