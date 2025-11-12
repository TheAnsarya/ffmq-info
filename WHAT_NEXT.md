# What's Next - Immediate Action Guide

**Your next steps after this session - practical and actionable.**

---

## 🎯 Session Complete - Here's What You Have

### ✅ **Manual Testing Infrastructure** (READY TO USE)
- **MANUAL_TESTING_TASKS.md**: 24 core tasks + 5 optional, 8-13 hours total
- **GITHUB_ISSUES.md**: 30 issues documented and ready
- **CREATE_GITHUB_ISSUES.md**: Automation scripts ready to run

### ✅ **Event System Analysis Tool** (PRODUCTION-READY)
- **event_system_analyzer.py**: 988-line analyzer, fully functional
- **EVENT_SYSTEM_ARCHITECTURE.md**: 3,500+ line comprehensive documentation
- **EVENT_SYSTEM_QUICK_START.md**: 2,000+ line practical guide

---

## 🚀 STEP 1: Run the Event System Analyzer (5 Minutes)

**What**: Analyze all 256 dialogs in the ROM as event scripts

**Why**: Get comprehensive data about the event system before anything else

**How**:
```powershell
# Open PowerShell in project root
cd c:\Users\me\source\repos\ffmq-info

# Run the analyzer
python tools/analysis/event_system_analyzer.py --rom roms/ffmq.sfc --table simple.tbl

# Wait for completion (30-60 seconds)
# Results will be in: output/
```

**Expected Output**:
```
EVENT SYSTEM ANALYSIS COMPLETE
================================
Summary:
  Dialogs analyzed: 256
  Event commands found: 2,450
  Unique commands used: 48
  Subroutine calls: 532
  Memory modifications: 124

Results exported to: output/

Generated files:
  ✓ output/event_system_statistics.json
  ✓ output/event_scripts.json
  ✓ output/EVENT_COMMAND_REFERENCE.md
  ✓ output/subroutine_call_graph.csv
  ✓ output/memory_modification_map.csv
  ✓ output/parameter_patterns.csv
```

**What to Do Next**:
1. Open `output/event_system_statistics.json` in VS Code
2. Look for highest-use commands
3. Identify unknown commands (UNK_07, UNK_09, etc.)
4. Note the counts - prioritize high-use unknowns

**Time**: 5 minutes

---

## 📊 STEP 2: Review Analysis Results (10 Minutes)

### 2A. Check Overall Statistics

```powershell
# Open statistics file
code output/event_system_statistics.json
```

**What to Look For**:
- **Total commands**: Should be ~2,450
- **Most used command**: Should be 0x08 (CALL_SUBROUTINE) with 500+ uses
- **Second most used**: Should be 0x0E (MEMORY_WRITE) with 100+ uses
- **Unknown commands**: Note which UNK_* commands have high usage

### 2B. Review Command Reference

```powershell
# Open auto-generated documentation
code output/EVENT_COMMAND_REFERENCE.md
```

**What to Look For**:
- Command usage statistics table
- Parameter pattern examples
- Special analysis sections for 0x08 and 0x0E

### 2C. Check Subroutine Call Graph

```powershell
# Open in Excel or spreadsheet app
start output/subroutine_call_graph.csv
```

**What to Look For**:
- Sort by "Call Count" (descending)
- Top 5-10 targets are most-reused components
- These are candidates for "common dialog fragments"

**Example**:
```
Target Address: 0x8FA0, Call Count: 25
→ This subroutine is called by 25 different dialogs
→ Likely a common greeting or standard dialog fragment
```

**Time**: 10 minutes

---

## 🎫 STEP 3: Create GitHub Issues (10 Minutes)

**What**: Create all 30 documented GitHub issues

**Why**: Track manual testing work in GitHub

**How**:

### Option A: Batch Creation (Recommended)

```powershell
# Authenticate with GitHub
gh auth login

# Follow prompts to authenticate

# Open CREATE_GITHUB_ISSUES.md
code CREATE_GITHUB_ISSUES.md

# Copy the PowerShell batch script (lines 20-180)
# Paste into PowerShell and run
# All 24 issues will be created automatically
```

### Option B: Manual Creation

```powershell
# Create issues one at a time using commands from CREATE_GITHUB_ISSUES.md
# Example:
gh issue create --title "Test format codes 0x1D vs 0x1E" --body "..." --label "testing,emulator,priority/critical"
```

### Verify Issues Created

```powershell
# List all issues
gh issue list

# Should show 30 new issues
```

**Time**: 10 minutes

---

## 🧪 STEP 4: Priority 1 Testing (2-3 Hours)

**What**: Test the 5 critical ROM patches in emulator

**Why**: Validate control code behavior before further analysis

**Test ROMs Location**: `roms/test/`

### Task 1.1: Test Format Codes 0x1D vs 0x1E (30 min)

**Test ROM**: `roms/test/test_format_1d_vs_1e.sfc`

**Procedure**:
1. Load ROM in Mesen-S: `mesen.exe roms/test/test_format_1d_vs_1e.sfc`
2. Start game
3. Talk to NPC to trigger test dialog
4. **Observe**: How items are formatted with 0x1D vs 0x1E
5. **Screenshot**: Name as `test_format_1d_vs_1e_result.png`
6. **Document**: Update `docs/ROM_TEST_RESULTS.md` with findings

**Success Criteria**:
- [ ] ROM loads without errors
- [ ] Test dialog displays correctly
- [ ] Can observe difference between 0x1D and 0x1E formatting
- [ ] Screenshot captured
- [ ] Results documented

### Task 1.2: Test Memory Write 0x0E (30 min)

**Test ROM**: `roms/test/test_memory_write_0e.sfc`

**Procedure**:
1. Load ROM in Mesen-S with debugger
2. Open Memory Viewer (Tools → Memory Viewer)
3. Watch address `0x1A50` (or test-specific address)
4. Talk to NPC to trigger memory write
5. **Observe**: Memory value changes
6. **Screenshot**: Memory viewer showing change
7. **Document**: Confirm 0x0E writes to correct address with correct value

**Success Criteria**:
- [ ] ROM loads
- [ ] Can view memory before write
- [ ] Memory write occurs when dialog executed
- [ ] Write address and value are correct
- [ ] Screenshot captured
- [ ] Results documented

### Task 1.3: Test Subroutine Call 0x08 (30 min)

**Test ROM**: `roms/test/test_subroutine_0x08.sfc`

**Procedure**:
1. Load ROM in Mesen-S
2. Talk to NPC to trigger main dialog
3. **Observe**: Nested dialog execution (subroutine called)
4. **Verify**: Control returns to main dialog after subroutine
5. **Screenshot**: Both main and subroutine dialogs
6. **Document**: Confirm 0x08 calls and returns correctly

**Success Criteria**:
- [ ] ROM loads
- [ ] Main dialog displays
- [ ] Subroutine dialog executes
- [ ] Control returns to main dialog
- [ ] Screenshot captured
- [ ] Results documented

### Task 1.4: Test Equipment Slots 0x10/0x17/0x18 (30 min)

**Test ROM**: `roms/test/test_equipment_slots.sfc`

**Procedure**:
1. Load ROM in Mesen-S
2. Talk to NPC to trigger test dialog
3. **Observe**: Item names (0x10), weapon names (0x17), armor names (0x18)
4. **Verify**: Names display correctly from equipment tables
5. **Screenshot**: Dialog showing all three types
6. **Document**: Confirm dynamic insertion working

**Success Criteria**:
- [ ] ROM loads
- [ ] Item name displays (0x10)
- [ ] Weapon name displays (0x17)
- [ ] Armor name displays (0x18)
- [ ] All names are correct
- [ ] Screenshot captured
- [ ] Results documented

### Task 1.5: Test Unused Codes 0x15/0x19 (30 min)

**Test ROM**: `roms/test/test_unused_codes.sfc`

**Procedure**:
1. Load ROM in Mesen-S with debugger
2. Set breakpoint on dialog handler
3. Talk to NPC to trigger test dialog
4. **Observe**: What happens when unused codes executed
5. **Document**: Behavior (crashes, no-op, unknown effect)

**Success Criteria**:
- [ ] ROM loads
- [ ] Test dialog triggers
- [ ] Behavior observed (crash, no-op, or effect)
- [ ] Screenshot if applicable
- [ ] Results documented

**Total Time**: 2-3 hours (30 min × 5 tasks + setup/documentation)

**Documentation**: Update `docs/ROM_TEST_RESULTS.md` after each task

---

## 📝 STEP 5: Document Your Findings (30 Minutes)

### Update ROM_TEST_RESULTS.md

```powershell
# Open test results file
code docs/ROM_TEST_RESULTS.md
```

**For each test, add**:
```markdown
## Test: [Test Name]

**ROM**: test_format_1d_vs_1e.sfc
**Date**: 2025-11-12
**Emulator**: Mesen-S 0.4.0

**Procedure**:
1. Loaded ROM
2. Triggered test dialog
3. Observed behavior

**Results**:
- ✅ ROM loaded successfully
- ✅ Dialog displayed correctly
- ✅ 0x1D formats with article: "a sword"
- ✅ 0x1E formats without article: "sword"

**Conclusion**: 0x1D and 0x1E confirmed to control article display

**Screenshot**: test_format_1d_vs_1e_result.png

**Notes**: [Any additional observations]
```

### Update CONTROL_CODE_IDENTIFICATION.md

```powershell
code docs/CONTROL_CODE_IDENTIFICATION.md
```

**Update status for confirmed commands**:
```markdown
### 0x1D: FORMAT_ITEM_E1
**Status**: ✅ CONFIRMED (was: PARTIAL)
**Parameters**: 1 byte (formatting mode)
**Usage**: 25 times
**Test**: test_format_1d_vs_1e.sfc (2025-11-12)

**Behavior**: Sets article display mode for dictionary entry 0x50
- 0x00: Normal (no article)
- 0x01: With article ("a ", "an ")
```

**Time**: 30 minutes

---

## 🔍 STEP 6: Analyze Unknown Commands (1-2 Hours)

**What**: Use analysis results to identify unknown commands

**Which unknowns to prioritize**:
```
From parameter_patterns.csv, sort by usage:
1. UNK_09 (if high usage)
2. UNK_07 (if high usage)
3. UNK_0A, UNK_0B, UNK_0C, UNK_0D, UNK_0F
4. UNK_1C
5. UNK_20-UNK_2F (as needed)
```

### Workflow for Each Unknown Command

**Example: UNK_09**

1. **Check parameter patterns**:
   ```powershell
   start output/parameter_patterns.csv
   # Find row for UNK_09
   # Note: Pattern count, unique patterns, sample pattern
   ```

2. **Examine usage context**:
   ```powershell
   code output/event_scripts.json
   # Search for "opcode": 9
   # Look at "follows" and "precedes" fields
   # Check surrounding commands
   ```

3. **Analyze parameter values**:
   - Do they match known ranges (item IDs 0-255, spell IDs 0-63, etc.)?
   - Are they addresses (0x0000-0x1FFF RAM, 0x8000-0xFFFF ROM)?
   - Are they small values (0-10 = likely flags/modes)?

4. **Form hypothesis**:
   ```
   Example hypothesis for UNK_09:
   "Based on 3-byte parameters with first byte = 0xA0,
   this might write value (param 3) to address (param 1+2)"
   ```

5. **Create test ROM** (if tools available):
   ```powershell
   python tools/testing/rom_test_patcher.py --test-command 0x09 --params 0xA0 0x00 0x05
   ```

6. **Test in emulator with memory viewer**

7. **Document findings in CONTROL_CODE_IDENTIFICATION.md**

**Time per command**: 30-60 minutes

**Recommended**: Start with 2-3 highest-use unknowns

---

## 📚 STEP 7: Read Documentation (30 Minutes)

### Essential Reading

**1. EVENT_SYSTEM_QUICK_START.md** (10 min skim)
```powershell
code docs/EVENT_SYSTEM_QUICK_START.md
```
- Jump to "Common Analysis Tasks" section
- Read Task 1: Identify Unknown Commands
- Read Task 2: Find Reusable Components

**2. EVENT_SYSTEM_ARCHITECTURE.md** (20 min)
```powershell
code docs/EVENT_SYSTEM_ARCHITECTURE.md
```
- Read "System Overview"
- Read "Event Commands (Control Codes)" table
- Read "Parameter-Based Commands" examples
- Skim "Control Flow" section (subroutine calls)
- Skim "State Modification" section (memory write)

**Time**: 30 minutes

---

## 🎯 Summary: Your First 4 Hours

| Step | Task | Time | Status |
|------|------|------|--------|
| 1 | Run event_system_analyzer.py | 5 min | ⬜ |
| 2 | Review analysis results | 10 min | ⬜ |
| 3 | Create GitHub issues | 10 min | ⬜ |
| 4 | Priority 1 testing (5 test ROMs) | 2-3 hours | ⬜ |
| 5 | Document findings | 30 min | ⬜ |
| 6 | Analyze 2-3 unknown commands | 1-2 hours | ⬜ |
| 7 | Read documentation | 30 min | ⬜ |
| **TOTAL** | | **4-6 hours** | |

---

## 📋 Checklist

### Immediate (Today)
- [ ] Run event_system_analyzer.py
- [ ] Review output/event_system_statistics.json
- [ ] Review output/EVENT_COMMAND_REFERENCE.md
- [ ] Check output/subroutine_call_graph.csv
- [ ] Create 30 GitHub issues
- [ ] Verify issues with `gh issue list`

### Priority 1 Testing (This Week)
- [ ] Test format codes 0x1D vs 0x1E
- [ ] Test memory write 0x0E
- [ ] Test subroutine call 0x08
- [ ] Test equipment slots 0x10/0x17/0x18
- [ ] Test unused codes 0x15/0x19

### Documentation (This Week)
- [ ] Update ROM_TEST_RESULTS.md with all test results
- [ ] Update CONTROL_CODE_IDENTIFICATION.md with confirmed findings
- [ ] Take screenshots for all tests
- [ ] Document any unexpected behavior

### Analysis (This Week)
- [ ] Identify 2-3 highest-use unknown commands
- [ ] Analyze parameter patterns for unknowns
- [ ] Form hypotheses about command behavior
- [ ] Create test ROMs if possible
- [ ] Test and document findings

### Reading (This Week)
- [ ] Read EVENT_SYSTEM_QUICK_START.md
- [ ] Read EVENT_SYSTEM_ARCHITECTURE.md (at least overview)
- [ ] Review MANUAL_TESTING_TASKS.md for all tasks

---

## 🆘 If You Get Stuck

### Issue: event_system_analyzer.py won't run

**Solution**:
```powershell
# Check Python version (need 3.8+)
python --version

# Check ROM file exists
dir roms/ffmq.sfc

# Check character table exists
dir simple.tbl

# Try absolute path
python tools/analysis/event_system_analyzer.py --rom "c:\Users\me\source\repos\ffmq-info\roms\ffmq.sfc" --table "c:\Users\me\source\repos\ffmq-info\simple.tbl"
```

### Issue: Test ROMs don't exist

**Solution**:
```powershell
# Check if test ROMs are in roms/test/
dir roms/test/

# If not, they need to be generated first
# See tools/testing/rom_test_patcher.py
```

### Issue: GitHub CLI not working

**Solution**:
```powershell
# Install GitHub CLI
winget install GitHub.cli

# Or download from: https://cli.github.com/

# Authenticate
gh auth login

# Follow prompts
```

### Issue: Don't know what to do next

**Solution**: Open this file (`WHAT_NEXT.md`) and follow Step 1

---

## 📞 Quick Reference

### Key Files
- **MANUAL_TESTING_TASKS.md** - All testing procedures
- **EVENT_SYSTEM_QUICK_START.md** - Analysis workflows
- **EVENT_SYSTEM_ARCHITECTURE.md** - System documentation
- **GITHUB_ISSUES.md** - All 30 issues documented
- **CREATE_GITHUB_ISSUES.md** - Issue creation scripts

### Key Commands
```powershell
# Run analyzer
python tools/analysis/event_system_analyzer.py --rom roms/ffmq.sfc --table simple.tbl

# Create GitHub issues
gh issue create --title "..." --body "..." --label "testing"

# List issues
gh issue list

# View issue
gh issue view 1

# Open emulator with ROM
mesen.exe roms/test/test_format_1d_vs_1e.sfc

# Open file in VS Code
code docs/EVENT_SYSTEM_QUICK_START.md
```

### Key Directories
- `output/` - Analysis results (6 files)
- `roms/test/` - Test ROMs
- `docs/` - All documentation
- `tools/analysis/` - Analysis tools
- `tools/testing/` - Testing tools

---

*Last Updated: 2025-11-12*  
*Next Action: Run event_system_analyzer.py (Step 1)*  
*Estimated Time to First Results: 5 minutes*
