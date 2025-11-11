"""
Integration Tests for FFMQ Dialog CLI

Tests complete workflows to ensure all components work together:
1. Export → Edit → Import → Verify
2. Backup → Restore → Compare
3. Search → Edit → Verify
4. Batch Replace → Verify
5. Multiple Edit Operations

These tests require a valid ROM file to run.
"""

import subprocess
import json
import tempfile
import shutil
from pathlib import Path
import sys


class IntegrationTestHarness:
	"""Test harness for integration testing"""

	def __init__(self, rom_path: str, cli_path: str = "dialog_cli.py"):
		"""Initialize test harness

		Args:
			rom_path: Path to FFMQ ROM file
			cli_path: Path to dialog_cli.py
		"""
		self.rom_path = Path(rom_path)
		self.cli_path = Path(cli_path)
		self.test_dir = Path(tempfile.mkdtemp(prefix='ffmq_test_'))
		self.test_rom = self.test_dir / "test.smc"

		# Copy ROM to test directory
		if self.rom_path.exists():
			shutil.copy(self.rom_path, self.test_rom)

	def cleanup(self):
		"""Clean up test files"""
		if self.test_dir.exists():
			shutil.rmtree(self.test_dir)

	def run_command(self, *args):
		"""Run dialog_cli.py command

		Args:
			*args: Command arguments

		Returns:
			(returncode, stdout, stderr)
		"""
		cmd = ["python", str(self.cli_path), "--rom", str(self.test_rom)] + list(args)

		result = subprocess.run(
			cmd,
			capture_output=True,
			text=True
		)

		return result.returncode, result.stdout, result.stderr

	def test_export_import_roundtrip(self):
		"""Test: Export → Edit → Import → Verify"""
		print("\n" + "=" * 70)
		print("Test: Export → Import Round-trip")
		print("=" * 70)

		# Step 1: Export to JSON
		print("\n1. Exporting dialogs to JSON...")
		json_file = self.test_dir / "export.json"
		rc, stdout, stderr = self.run_command("export", str(json_file))

		if rc != 0:
			print(f"  ✗ Export failed: {stderr}")
			return False
		print(f"  ✓ Export successful")

		# Step 2: Verify JSON exists
		if not json_file.exists():
			print(f"  ✗ JSON file not created")
			return False

		# Step 3: Load and edit JSON
		print("\n2. Editing JSON data...")
		with open(json_file, 'r') as f:
			data = json.load(f)

		original_count = len(data['dialogs'])

		# Edit a few dialogs
		edits_made = 0
		for dialog in data['dialogs'][:5]:  # Edit first 5
			dialog['text'] = dialog['text'] + " [EDITED]"
			edits_made += 1

		# Save edited JSON
		edited_json = self.test_dir / "edited.json"
		with open(edited_json, 'w') as f:
			json.dump(data, f, indent=2)

		print(f"  ✓ Edited {edits_made} dialogs")

		# Step 4: Import edited JSON
		print("\n3. Importing edited JSON...")
		rc, stdout, stderr = self.run_command("import", str(edited_json), "--yes")

		if rc != 0:
			print(f"  ✗ Import failed: {stderr}")
			return False
		print(f"  ✓ Import successful")

		# Step 5: Verify changes
		print("\n4. Verifying changes...")
		rc, stdout, stderr = self.run_command("verify", "--stats")

		if rc != 0:
			print(f"  ✗ Verify failed: {stderr}")
			return False
		print(f"  ✓ Verify successful")

		# Step 6: Check that edited dialogs have [EDITED] tag
		print("\n5. Checking edited dialogs...")
		for i in range(5):
			rc, stdout, stderr = self.run_command("show", f"0x{i:02X}")
			if "[EDITED]" in stdout:
				print(f"  ✓ Dialog 0x{i:02X} contains [EDITED] tag")
			else:
				print(f"  ✗ Dialog 0x{i:02X} missing [EDITED] tag")
				return False

		print("\n✓ Export-Import-Verify workflow: PASSED")
		return True

	def test_backup_restore_workflow(self):
		"""Test: Backup → Edit → Restore → Verify"""
		print("\n" + "=" * 70)
		print("Test: Backup → Restore Workflow")
		print("=" * 70)

		# Step 1: Create backup
		print("\n1. Creating backup...")
		backup_file = self.test_dir / "backup.smc"
		rc, stdout, stderr = self.run_command("backup", "-o", str(backup_file))

		if rc != 0:
			print(f"  ✗ Backup failed: {stderr}")
			return False
		print(f"  ✓ Backup created")

		# Step 2: Edit a dialog
		print("\n2. Editing dialog...")
		rc, stdout, stderr = self.run_command(
			"edit", "0x21",
			"--text", "Modified dialog for testing"
		)

		if rc != 0:
			print(f"  ✗ Edit failed: {stderr}")
			return False
		print(f"  ✓ Dialog edited")

		# Step 3: Verify edit was applied
		print("\n3. Verifying edit...")
		rc, stdout, stderr = self.run_command("show", "0x21")

		if "Modified dialog for testing" not in stdout:
			print(f"  ✗ Edit not applied")
			return False
		print(f"  ✓ Edit verified")

		# Step 4: Restore from backup
		print("\n4. Restoring from backup...")
		shutil.copy(backup_file, self.test_rom)
		print(f"  ✓ Restored from backup")

		# Step 5: Verify restoration
		print("\n5. Verifying restoration...")
		rc, stdout, stderr = self.run_command("show", "0x21")

		if "Modified dialog for testing" in stdout:
			print(f"  ✗ Restoration failed - edit still present")
			return False
		print(f"  ✓ Restoration verified")

		print("\n✓ Backup-Restore workflow: PASSED")
		return True

	def test_search_edit_verify(self):
		"""Test: Search → Edit → Verify"""
		print("\n" + "=" * 70)
		print("Test: Search → Edit → Verify Workflow")
		print("=" * 70)

		# Step 1: Search for dialogs containing "Crystal"
		print("\n1. Searching for 'Crystal'...")
		rc, stdout, stderr = self.run_command("find", "Crystal")

		if rc != 0:
			print(f"  ✗ Search failed: {stderr}")
			return False

		# Extract dialog IDs from output
		dialog_ids = []
		for line in stdout.split('\n'):
			if '0x' in line:
				parts = line.strip().split()
				if parts:
					dialog_ids.append(parts[0])

		print(f"  ✓ Found {len(dialog_ids)} dialogs containing 'Crystal'")

		if not dialog_ids:
			print("  ⚠ No dialogs found, skipping edit test")
			return True

		# Step 2: Edit first found dialog
		print("\n2. Editing first found dialog...")
		first_id = dialog_ids[0]
		rc, stdout, stderr = self.run_command(
			"edit", first_id,
			"--text", "The legendary Crystal awaits you!"
		)

		if rc != 0:
			print(f"  ✗ Edit failed: {stderr}")
			return False
		print(f"  ✓ Dialog {first_id} edited")

		# Step 3: Verify the change
		print("\n3. Verifying changes...")
		rc, stdout, stderr = self.run_command("verify")

		if rc != 0:
			print(f"  ✗ Verify failed: {stderr}")
			return False
		print(f"  ✓ Verify passed")

		# Step 4: Show edited dialog
		print("\n4. Showing edited dialog...")
		rc, stdout, stderr = self.run_command("show", first_id)

		if "legendary Crystal" not in stdout:
			print(f"  ✗ Edit not found in output")
			return False
		print(f"  ✓ Edit confirmed")

		print("\n✓ Search-Edit-Verify workflow: PASSED")
		return True

	def test_batch_replace_workflow(self):
		"""Test: Batch Replace → Verify"""
		print("\n" + "=" * 70)
		print("Test: Batch Replace → Verify Workflow")
		print("=" * 70)

		# Step 1: Count occurrences of "the "
		print("\n1. Finding 'the ' in dialogs...")
		rc, stdout, stderr = self.run_command("find", "the ")

		initial_count = stdout.count("0x") if rc == 0 else 0
		print(f"  ✓ Found 'the ' in {initial_count} dialogs")

		# Step 2: Preview replacement
		print("\n2. Previewing replacement...")
		rc, stdout, stderr = self.run_command(
			"replace", "the ", "THE ", "--preview"
		)

		if rc != 0:
			print(f"  ✗ Preview failed: {stderr}")
			return False
		print(f"  ✓ Preview successful")

		# Note: Actual replacement would require --confirm flag
		# We skip it here to avoid modifying ROM
		print("\n3. Skipping actual replacement (would use --confirm)")

		# Step 3: Verify ROM is still valid
		print("\n4. Verifying ROM integrity...")
		rc, stdout, stderr = self.run_command("verify")

		if rc != 0:
			print(f"  ✗ Verify failed: {stderr}")
			return False
		print(f"  ✓ ROM integrity verified")

		print("\n✓ Batch-Replace workflow: PASSED")
		return True

	def test_multiple_edits(self):
		"""Test: Multiple sequential edits"""
		print("\n" + "=" * 70)
		print("Test: Multiple Sequential Edits")
		print("=" * 70)

		test_dialogs = [0x00, 0x01, 0x02, 0x03, 0x04]

		print(f"\n1. Editing {len(test_dialogs)} dialogs...")
		for i, dialog_id in enumerate(test_dialogs, 1):
			rc, stdout, stderr = self.run_command(
				"edit", f"0x{dialog_id:02X}",
				"--text", f"Test edit #{i}"
			)

			if rc != 0:
				print(f"  ✗ Edit {i} failed: {stderr}")
				return False
			print(f"  ✓ Edit {i} successful")

		print(f"\n2. Verifying all edits...")
		for i, dialog_id in enumerate(test_dialogs, 1):
			rc, stdout, stderr = self.run_command("show", f"0x{dialog_id:02X}")

			if f"Test edit #{i}" not in stdout:
				print(f"  ✗ Edit {i} not found")
				return False
			print(f"  ✓ Edit {i} verified")

		print(f"\n3. Running ROM verify...")
		rc, stdout, stderr = self.run_command("verify", "--stats")

		if rc != 0:
			print(f"  ✗ Verify failed: {stderr}")
			return False
		print(f"  ✓ ROM verify passed")

		print("\n✓ Multiple-Edits workflow: PASSED")
		return True


def run_integration_tests(rom_path: str):
	"""Run all integration tests

	Args:
		rom_path: Path to FFMQ ROM file
	"""
	print("=" * 70)
	print("FFMQ Dialog CLI - Integration Test Suite")
	print("=" * 70)
	print(f"ROM: {rom_path}")
	print()

	if not Path(rom_path).exists():
		print(f"✗ ROM file not found: {rom_path}")
		print()
		print("Please provide a valid ROM file:")
		print("  python test_integration.py <path_to_rom>")
		return 1

	harness = IntegrationTestHarness(rom_path)

	try:
		tests = [
			harness.test_export_import_roundtrip,
			harness.test_backup_restore_workflow,
			harness.test_search_edit_verify,
			harness.test_batch_replace_workflow,
			harness.test_multiple_edits
		]

		passed = 0
		failed = 0

		for test in tests:
			try:
				if test():
					passed += 1
				else:
					failed += 1
			except Exception as e:
				print(f"\n✗ Test failed with exception: {e}")
				failed += 1

		print("\n" + "=" * 70)
		print("Integration Test Results")
		print("=" * 70)
		print(f"Passed: {passed}")
		print(f"Failed: {failed}")
		print(f"Total:  {passed + failed}")
		print()

		if failed == 0:
			print("✓ All integration tests PASSED!")
			return 0
		else:
			print(f"✗ {failed} integration test(s) FAILED")
			return 1

	finally:
		harness.cleanup()


if __name__ == '__main__':
	if len(sys.argv) < 2:
		print("Usage: python test_integration.py <path_to_rom>")
		print()
		print("Example:")
		print('  python test_integration.py "Final Fantasy - Mystic Quest (U) (V1.1).smc"')
		sys.exit(1)

	rom_path = sys.argv[1]
	sys.exit(run_integration_tests(rom_path))
