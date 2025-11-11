# Create GitHub issues from the `GITHUB_ISSUES.md` definitions
# Requires `gh` CLI (https://cli.github.com) and an authenticated user (`gh auth login`).

$issues = @(
	@{
		title = 'Fix DTE table - complex.tbl inaccuracies'
		body = @'
The `complex.tbl` DTE mappings do not match ROM data; many entries miss trailing spaces (e.g. `0x41` = "the ") and others are incorrect. This blocks dialog extraction and editing.

Steps to reproduce:
1. Extract dialog 0x59 and compare bytes vs expected text.
2. Validate known DTE sequences from DataCrystal/TCRF.
3. Update `complex.tbl` and run extraction tests.
'@
		labels = 'text,dte,priority/high'
	},
	@{
		title = 'Simple text extractor - regenerate data/text_fixed/*'
		body = @'
Simple fixed-length tables (items, spells, monsters) are produced incorrectly. Update `tools/extraction/*` to use `simple.tbl` and correct ROM addresses; regenerate CSVs in `data/text_fixed`.

Suggested tasks:
- Fix addresses for item/spell/monster tables
- Ensure `simple.tbl` is used for fixed-length decoding
- Re-run extraction and commit regenerated CSVs
'@
		labels = 'tooling,extraction,priority/medium'
	},
	@{
		title = 'Reverse-engineer remaining control codes'
		body = @'
Map all control codes (0x00-0x3B, 0x80-0x8F) to engine behavior (textbox positioning, screen shake, map change, movement). Produce `docs/CONTROL_CODES.md` with byte-level semantics and assembly references.
'@
		labels = 'research,engine,priority/medium'
	},
	@{
		title = 'Dialog re-insertion tooling and validation'
		body = @'
Add safe re-insertion scripts, pointer validation, and unit tests for round-trip encode/decode. Add `tools/import/import_text.py` enhancements and tests.
'@
		labels = 'tooling,testing,priority/high'
	},
	@{
		title = 'Add CI to run extraction tests'
		body = @'
Add a GitHub Actions workflow to run `test_text_systems.py` on push/PR to detect regressions.
'@
		labels = 'ci,testing,priority/low'
	}
)

foreach ($issue in $issues) {
	Write-Host "Ready to create issue:`n  Title: $($issue.title)`n  Labels: $($issue.labels)`n" -ForegroundColor Cyan
	$resp = Read-Host "Create this issue on GitHub? (y/N)"
	if ($resp -match '^[Yy]') {
		# Create issue using gh CLI
		gh issue create --title "$($issue.title)" --body "$($issue.body)" --label $($issue.labels.Split(','))
		Write-Host "Issue created: $($issue.title)" -ForegroundColor Green
	} else {
		Write-Host "Skipped: $($issue.title)" -ForegroundColor Yellow
	}
}
