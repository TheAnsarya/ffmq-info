# GitHub Issues for ffmq-info

This file lists the high-priority issues for the repository and provides ready-to-run `gh` CLI commands to create issues on GitHub.

Guidance:
- Install GitHub CLI (`gh`) and authenticate (run `gh auth login`).
- Run `.	ools\gh\create_issues.ps1` in PowerShell to create the issues described below.

---

### ISSUE: Fix DTE table - `complex.tbl` inaccuracies

Description:
Tabs: The `complex.tbl` DTE mappings do not match ROM data; many entries miss trailing spaces (e.g. `0x41` = "the ") and others are incorrect (e.g. `0x5C` mapping ambiguous). This blocks dialog extraction and editing.

Proposed labels: text, dte, priority/high

---

### ISSUE: Simple text extractor - regenerate `data/text_fixed/*`

Description:
Simple fixed-length tables (items, spells, monsters) are produced incorrectly. Update `tools/extraction/*` to use `simple.tbl` and correct ROM addresses; regenerate CSVs in `data/text_fixed`.

Proposed labels: tooling, extraction, priority/medium

---

### ISSUE: Reverse-engineer remaining control codes

Description:
Map all control codes (0x00-0x3B, 0x80-0x8F) to engine behavior (textbox positioning, screen shake, map change, movement). Produce `docs/CONTROL_CODES.md` with byte-level semantics and assembly references.

Proposed labels: research, engine, priority/medium

---

### ISSUE: Dialog re-insertion tooling and validation

Description:
Add safe re-insertion scripts, pointer validation, and unit tests for round-trip encode/decode. Add `tools/import/import_text.py` enhancements and tests.

Proposed labels: tooling, testing, priority/high

---

### ISSUE: Add CI to run extraction tests

Description:
Add a GitHub Actions workflow to run `test_text_systems.py` on push/PR to detect regressions.

Proposed labels: ci, testing, priority/low

---

## References

- DataCrystal: https://datacrystal.tcrf.net/wiki/Final_Fantasy:_Mystic_Quest/TBL
- TCRF: https://tcrf.net/Final_Fantasy:_Mystic_Quest

---

## How to create issues locally

Run the PowerShell script included at `tools\gh\create_issues.ps1`. It will create the issues above using the `gh` CLI. You will be prompted before each create.
