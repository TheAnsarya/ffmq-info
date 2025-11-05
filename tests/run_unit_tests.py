#!/usr/bin/env python3
"""
Test Runner for FFMQ Project

Runs all unit tests and generates comprehensive test reports.
Supports individual test files or full test suite execution.
"""

import sys
import unittest
import json
from pathlib import Path
from datetime import datetime
from typing import List, Dict


class FFMQTestRunner:
	"""Custom test runner with enhanced reporting"""
	
	def __init__(self, project_dir: Path):
		self.project_dir = project_dir
		self.tests_dir = project_dir / "tests"
		self.reports_dir = project_dir / "reports"
	
	def discover_tests(self) -> unittest.TestSuite:
		"""Discover all test cases in tests/ directory"""
		loader = unittest.TestLoader()
		suite = loader.discover(
			start_dir=str(self.tests_dir),
			pattern='test_*.py',
			top_level_dir=str(self.project_dir)
		)
		return suite
	
	def run_tests(self, suite: unittest.TestSuite, verbosity: int = 2) -> unittest.TestResult:
		"""Run test suite with specified verbosity"""
		runner = unittest.TextTestRunner(verbosity=verbosity)
		result = runner.run(suite)
		return result
	
	def generate_report(self, result: unittest.TestResult) -> Dict:
		"""Generate detailed test report"""
		total_tests = result.testsRun
		failures = len(result.failures)
		errors = len(result.errors)
		skipped = len(result.skipped)
		passed = total_tests - failures - errors - skipped
		
		pass_rate = (passed / total_tests * 100) if total_tests > 0 else 0
		
		report = {
			"timestamp": datetime.now().isoformat(),
			"summary": {
				"total_tests": total_tests,
				"passed": passed,
				"failed": failures,
				"errors": errors,
				"skipped": skipped,
				"pass_rate": round(pass_rate, 2)
			},
			"status": "success" if failures == 0 and errors == 0 else "failure",
			"failures": [
				{
					"test": str(test),
					"traceback": traceback
				}
				for test, traceback in result.failures
			],
			"errors": [
				{
					"test": str(test),
					"traceback": traceback
				}
				for test, traceback in result.errors
			]
		}
		
		return report
	
	def save_report(self, report: Dict, filename: str = "unit_test_results.json"):
		"""Save report to JSON file"""
		self.reports_dir.mkdir(parents=True, exist_ok=True)
		report_file = self.reports_dir / filename
		
		with open(report_file, 'w', encoding='utf-8') as f:
			json.dump(report, f, indent=2)
		
		print(f"\n📄 Test report saved to: {report_file}")
		return report_file
	
	def print_summary(self, report: Dict):
		"""Print test summary to console"""
		summary = report["summary"]
		
		print("\n" + "=" * 80)
		print("UNIT TEST SUMMARY")
		print("=" * 80)
		print(f"Total Tests: {summary['total_tests']}")
		print(f"Passed: {summary['passed']} ✅")
		print(f"Failed: {summary['failed']} ❌")
		print(f"Errors: {summary['errors']} ⚠️")
		print(f"Skipped: {summary['skipped']} ⏭️")
		print(f"Pass Rate: {summary['pass_rate']:.1f}%")
		print("=" * 80)
		
		if report["status"] == "success":
			print("🎉 ALL TESTS PASSED!")
		else:
			print("❌ SOME TESTS FAILED - Review required")
		
		print("=" * 80)


def main():
	"""Main test execution function"""
	script_dir = Path(__file__).parent
	project_dir = script_dir.parent
	
	print("=" * 80)
	print("FFMQ UNIT TEST RUNNER")
	print("=" * 80)
	
	# Create test runner
	runner = FFMQTestRunner(project_dir)
	
	# Discover and run tests
	print("\n🔍 Discovering tests...")
	suite = runner.discover_tests()
	
	print(f"📝 Found {suite.countTestCases()} test cases\n")
	
	print("🧪 Running tests...\n")
	result = runner.run_tests(suite, verbosity=2)
	
	# Generate and save report
	report = runner.generate_report(result)
	runner.save_report(report)
	runner.print_summary(report)
	
	# Return appropriate exit code
	return 0 if report["status"] == "success" else 1


if __name__ == "__main__":
	sys.exit(main())
