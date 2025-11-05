#!/usr/bin/env python3
"""
FFMQ Testing Framework

Automated testing suite for extraction tools and build pipeline.
Includes unit tests, integration tests, and data validation tests.
"""

import sys
import json
import subprocess
from pathlib import Path
from typing import List, Dict, Tuple
from dataclasses import dataclass


@dataclass
class TestResult:
	"""Container for test results"""
	name: str
	category: str
	passed: bool
	message: str
	duration_ms: int = 0


class FFMQTestFramework:
	"""Automated testing framework for FFMQ tools"""
	
	def __init__(self, project_dir: Path):
		self.project_dir = project_dir
		self.data_dir = project_dir / "data"
		self.tools_dir = project_dir / "tools"
		self.roms_dir = project_dir / "roms"
		self.results: List[TestResult] = []
	
	def test_data_files_exist(self) -> List[TestResult]:
		"""Test that all expected data files exist"""
		print("\n📁 Testing data file existence...")
		
		required_files = [
			("data/spells/spells.json", "Spell data"),
			("data/extracted/enemies/enemies.json", "Enemy data"),
			("data/extracted/attacks/attacks.json", "Attack data"),
			("data/extracted/enemy_attack_links/enemy_attack_links.json", "Enemy-attack links"),
			("data/element_types.json", "Element types"),
		]
		
		results = []
		for file_path, description in required_files:
			full_path = self.project_dir / file_path
			passed = full_path.exists()
			
			results.append(TestResult(
				name=f"Data file: {description}",
				category="Data Integrity",
				passed=passed,
				message=f"{file_path} {'exists' if passed else 'NOT FOUND'}"
			))
		
		return results
	
	def test_data_file_structure(self) -> List[TestResult]:
		"""Test that data files have correct JSON structure"""
		print("🔍 Testing data file structure...")
		
		results = []
		
		# Test spell data structure
		try:
			spells_file = self.data_dir / "spells" / "spells.json"
			with open(spells_file, 'r', encoding='utf-8') as f:
				data = json.load(f)
			
			has_spells = 'spells' in data
			spell_count = len(data.get('spells', []))
			
			results.append(TestResult(
				name="Spell data structure",
				category="Data Structure",
				passed=has_spells and spell_count > 0,
				message=f"Found {spell_count} spells"
			))
		except Exception as e:
			results.append(TestResult(
				name="Spell data structure",
				category="Data Structure",
				passed=False,
				message=f"Error: {str(e)}"
			))
		
		# Test enemy data structure
		try:
			enemies_file = self.data_dir / "extracted" / "enemies" / "enemies.json"
			with open(enemies_file, 'r', encoding='utf-8') as f:
				data = json.load(f)
			
			has_enemies = 'enemies' in data
			has_metadata = 'metadata' in data
			enemy_count = len(data.get('enemies', []))
			
			results.append(TestResult(
				name="Enemy data structure",
				category="Data Structure",
				passed=has_enemies and has_metadata and enemy_count == 83,
				message=f"Found {enemy_count} enemies (expected 83)"
			))
		except Exception as e:
			results.append(TestResult(
				name="Enemy data structure",
				category="Data Structure",
				passed=False,
				message=f"Error: {str(e)}"
			))
		
		# Test attack data structure
		try:
			attacks_file = self.data_dir / "extracted" / "attacks" / "attacks.json"
			with open(attacks_file, 'r', encoding='utf-8') as f:
				data = json.load(f)
			
			has_attacks = 'attacks' in data
			has_metadata = 'metadata' in data
			attack_count = len(data.get('attacks', []))
			
			results.append(TestResult(
				name="Attack data structure",
				category="Data Structure",
				passed=has_attacks and has_metadata and attack_count == 169,
				message=f"Found {attack_count} attacks (expected 169)"
			))
		except Exception as e:
			results.append(TestResult(
				name="Attack data structure",
				category="Data Structure",
				passed=False,
				message=f"Error: {str(e)}"
			))
		
		return results
	
	def test_rom_integrity(self) -> List[TestResult]:
		"""Test ROM file integrity"""
		print("🎮 Testing ROM integrity...")
		
		results = []
		
		# Check original ROM exists
		original_rom = self.roms_dir / "Final Fantasy - Mystic Quest (U) (V1.1).sfc"
		results.append(TestResult(
			name="Original ROM exists",
			category="ROM Integrity",
			passed=original_rom.exists(),
			message=f"Original ROM {'found' if original_rom.exists() else 'NOT FOUND'}"
		))
		
		# Check rebuilt ROM exists
		rebuilt_rom = self.roms_dir / "ffmq_rebuilt.sfc"
		results.append(TestResult(
			name="Rebuilt ROM exists",
			category="ROM Integrity",
			passed=rebuilt_rom.exists(),
			message=f"Rebuilt ROM {'found' if rebuilt_rom.exists() else 'NOT FOUND'}"
		))
		
		# Check ROM sizes match
		if original_rom.exists() and rebuilt_rom.exists():
			orig_size = original_rom.stat().st_size
			rebuilt_size = rebuilt_rom.stat().st_size
			expected_size = 524288  # 512KB
			
			results.append(TestResult(
				name="ROM size validation",
				category="ROM Integrity",
				passed=orig_size == rebuilt_size == expected_size,
				message=f"Original: {orig_size}, Rebuilt: {rebuilt_size}, Expected: {expected_size}"
			))
		
		return results
	
	def test_validation_tools(self) -> List[TestResult]:
		"""Test validation tools can run successfully"""
		print("🧪 Testing validation tools...")
		
		results = []
		
		# Test ROM integrity validator
		validator_path = self.tools_dir / "validation" / "validate_rom_integrity.py"
		if validator_path.exists():
			try:
				result = subprocess.run(
					[sys.executable, str(validator_path)],
					capture_output=True,
					text=True,
					timeout=30,
					cwd=str(self.project_dir)
				)
				
				results.append(TestResult(
					name="ROM integrity validator",
					category="Validation Tools",
					passed=result.returncode == 0,
					message=f"Exit code: {result.returncode}"
				))
			except Exception as e:
				results.append(TestResult(
					name="ROM integrity validator",
					category="Validation Tools",
					passed=False,
					message=f"Error: {str(e)}"
				))
		
		# Test randomizer data validator
		validator_path = self.tools_dir / "validation" / "validate_against_randomizer_corrected.py"
		if validator_path.exists():
			try:
				result = subprocess.run(
					[sys.executable, str(validator_path)],
					capture_output=True,
					text=True,
					timeout=30,
					cwd=str(self.project_dir)
				)
				
				results.append(TestResult(
					name="Randomizer data validator",
					category="Validation Tools",
					passed=result.returncode == 0,
					message=f"Exit code: {result.returncode}"
				))
			except Exception as e:
				results.append(TestResult(
					name="Randomizer data validator",
					category="Validation Tools",
					passed=False,
					message=f"Error: {str(e)}"
				))
		
		return results
	
	def test_visualization_tools(self) -> List[TestResult]:
		"""Test visualization tools can run successfully"""
		print("📊 Testing visualization tools...")
		
		results = []
		
		viz_tools = [
			("visualize_enemy_attacks.py", "Enemy-Attack Network"),
			("visualize_elements.py", "Element Matrix"),
			("visualize_spell_effectiveness.py", "Spell Effectiveness")
		]
		
		for tool_file, tool_name in viz_tools:
			tool_path = self.tools_dir / tool_file
			if tool_path.exists():
				try:
					result = subprocess.run(
						[sys.executable, str(tool_path)],
						capture_output=True,
						text=True,
						timeout=30,
						cwd=str(self.project_dir)
					)
					
					results.append(TestResult(
						name=f"{tool_name} visualizer",
						category="Visualization Tools",
						passed=result.returncode == 0,
						message=f"Exit code: {result.returncode}"
					))
				except Exception as e:
					results.append(TestResult(
						name=f"{tool_name} visualizer",
						category="Visualization Tools",
						passed=False,
						message=f"Error: {str(e)}"
					))
		
		return results
	
	def test_build_system(self) -> List[TestResult]:
		"""Test build system components"""
		print("🔧 Testing build system...")
		
		results = []
		
		# Check Makefile exists
		makefile = self.project_dir / "Makefile"
		results.append(TestResult(
			name="Makefile exists",
			category="Build System",
			passed=makefile.exists(),
			message=f"Makefile {'found' if makefile.exists() else 'NOT FOUND'}"
		))
		
		# Check build.ps1 exists
		build_script = self.project_dir / "build.ps1"
		results.append(TestResult(
			name="Build script exists",
			category="Build System",
			passed=build_script.exists(),
			message=f"build.ps1 {'found' if build_script.exists() else 'NOT FOUND'}"
		))
		
		# Check source directory exists
		src_dir = self.project_dir / "src"
		results.append(TestResult(
			name="Source directory exists",
			category="Build System",
			passed=src_dir.exists() and src_dir.is_dir(),
			message=f"src/ {'found' if src_dir.exists() else 'NOT FOUND'}"
		))
		
		return results
	
	def run_all_tests(self) -> Dict[str, any]:
		"""Run all tests and generate report"""
		print("=" * 80)
		print("FFMQ AUTOMATED TESTING FRAMEWORK")
		print("=" * 80)
		
		# Run all test categories
		self.results.extend(self.test_data_files_exist())
		self.results.extend(self.test_data_file_structure())
		self.results.extend(self.test_rom_integrity())
		self.results.extend(self.test_validation_tools())
		self.results.extend(self.test_visualization_tools())
		self.results.extend(self.test_build_system())
		
		# Generate summary
		total_tests = len(self.results)
		passed_tests = sum(1 for r in self.results if r.passed)
		failed_tests = total_tests - passed_tests
		pass_rate = (passed_tests / total_tests * 100) if total_tests > 0 else 0
		
		print("\n" + "=" * 80)
		print("TEST RESULTS SUMMARY")
		print("=" * 80)
		print(f"Total Tests: {total_tests}")
		print(f"Passed: {passed_tests} ✅")
		print(f"Failed: {failed_tests} ❌")
		print(f"Pass Rate: {pass_rate:.1f}%")
		print()
		
		# Group results by category
		categories = {}
		for result in self.results:
			if result.category not in categories:
				categories[result.category] = []
			categories[result.category].append(result)
		
		# Print results by category
		for category, results in categories.items():
			cat_passed = sum(1 for r in results if r.passed)
			cat_total = len(results)
			print(f"\n{category}: {cat_passed}/{cat_total} passed")
			print("-" * 60)
			
			for result in results:
				status = "✅" if result.passed else "❌"
				print(f"{status} {result.name}")
				print(f"   {result.message}")
		
		# Overall status
		print("\n" + "=" * 80)
		if failed_tests == 0:
			print("🎉 ALL TESTS PASSED!")
			status = "success"
		elif pass_rate >= 80:
			print("⚠️  MOSTLY PASSING - Some tests failed")
			status = "warning"
		else:
			print("❌ MULTIPLE FAILURES - Review required")
			status = "failure"
		
		print("=" * 80)
		
		return {
			"status": status,
			"total_tests": total_tests,
			"passed": passed_tests,
			"failed": failed_tests,
			"pass_rate": pass_rate,
			"results": self.results
		}
	
	def save_report(self, output_file: Path, results: Dict):
		"""Save test report to JSON file"""
		report_data = {
			"status": results["status"],
			"summary": {
				"total_tests": results["total_tests"],
				"passed": results["passed"],
				"failed": results["failed"],
				"pass_rate": results["pass_rate"]
			},
			"tests": [
				{
					"name": r.name,
					"category": r.category,
					"passed": r.passed,
					"message": r.message
				}
				for r in results["results"]
			]
		}
		
		with open(output_file, 'w', encoding='utf-8') as f:
			json.dump(report_data, f, indent=2)
		
		print(f"\n📄 Test report saved to: {output_file}")


def main():
	"""Main testing function"""
	script_dir = Path(__file__).parent
	project_dir = script_dir.parent
	
	# Run tests
	framework = FFMQTestFramework(project_dir)
	results = framework.run_all_tests()
	
	# Save report
	output_file = project_dir / "reports" / "test_results.json"
	output_file.parent.mkdir(parents=True, exist_ok=True)
	framework.save_report(output_file, results)
	
	# Return appropriate exit code
	return 0 if results["status"] == "success" else 1


if __name__ == "__main__":
	sys.exit(main())
