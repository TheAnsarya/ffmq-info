# Unreachable Code Analysis Report

**Project**: Final Fantasy Mystic Quest - Complete ROM Disassembly  
**Report Date**: November 4, 2025 (Updated)  
**Report Type**: Phase 2 Progress Report  
**Related Issue**: GitHub Issue #67

---

## Executive Summary

This report tracks the ongoing disassembly and analysis of unreachable code across the Final Fantasy Mystic Quest ROM. **Bank $00 is now 100% complete** with all reachable sections disassembled and renamed, and all dead code properly documented.

### Key Achievements

- ✅ **Bank $00 Complete**: 37 sections analyzed (28 reachable, 9 dead code)
- ✅ **Bank $01 Progress**: 4 sections analyzed (3 reachable, 1 dead code)
- ✅ **41 total sections** processed out of 117 (35.0% complete)
- ✅ **31 reachable sections** fully disassembled and renamed
- ✅ **10 dead code sections** documented with proper headers
- ✅ **5 git commits** for Bank $00 completion

### Updated Statistics

- **117 total `UNREACH_*` labels** across 10 ROM banks
- **41 sections processed** (35.0% complete)
- **31 reachable sections** (75.6% of processed sections)
- **10 dead code sections** (24.4% of processed sections)
- **76 sections remaining** for analysis (Banks $02-$0D)

---

## Statistics by Bank

| Bank | Description          | Total | Reachable | Dead Code | % Reachable | Status |
|------|---------------------|-------|-----------|-----------|-------------|--------|
| $00  | Core Engine         | 37    | 28        | 9         | 75.7%       | ✅ 100% |
| $01  | Battle System       | 4     | 3         | 1         | 75.0%       | 🔍 75%  |
| $02  | Battle (Extended)   | 33    | ?         | ?         | ?           | ⏳ 0%   |
| $03  | Graphics/Data       | 1     | ?         | ?         | ?           | ⏳ 0%   |
| $04  | —                   | 0     | —         | —         | —           | N/A     |
| $05  | Unknown             | 2     | ?         | ?         | ?           | ⏳ 0%   |
| $06  | Unknown             | 2     | ?         | ?         | ?           | ⏳ 0%   |
| $07  | Unknown             | 1     | ?         | ?         | ?           | ⏳ 0%   |
| $08  | —                   | 0     | —         | —         | —           | N/A     |
| $09  | —                   | 0     | —         | —         | —           | N/A     |
| $0A  | —                   | 0     | —         | —         | —           | N/A     |
| $0B  | Battle Graphics     | 4     | ?         | ?         | ?           | ⏳ 0%   |
| $0C  | Unknown             | 10    | ?         | ?         | ?           | ⏳ 0%   |
| $0D  | Audio/SPC700        | 5     | ?         | ?         | ?           | ⏳ 0%   |
| $0E  | —                   | 0     | —         | —         | —           | N/A     |
| $0F  | —                   | 0     | —         | —         | —           | N/A     |
| **TOTAL** | **All Banks**  | **117** | **31**  | **10**    | **26.5%**   | **35.0%** |

**Status Legend**:
- ✅ Complete - All sections analyzed and processed
- 🔍 In Progress - Partial analysis complete  
- ⏳ Pending - Not yet analyzed

### Distribution Chart

```
Bank $00: ████████████████████████████████ 37 (31.6%) [100% ✅]
Bank $01: ██ 4 (3.4%) [75% 🔍]
Bank $02: ████████████████████████████████ 33 (28.2%) [0% ⏳]
Bank $03: █ 1 (0.9%) [0% ⏳]
Bank $05: █ 2 (1.7%) [0% ⏳]
Bank $06: █ 2 (1.7%) [0% ⏳]
Bank $07: █ 1 (0.9%) [0% ⏳]
Bank $0B: ██ 4 (3.4%) [0% ⏳]
Bank $0C: ███████ 10 (8.5%) [0% ⏳]
Bank $0D: ███ 5 (4.3%) [0% ⏳]

Overall Progress: █████████████░░░░░░░░░░░░░░░░░░░░░░░ 35.0%
```

**Top 3 Banks by Unreachable Sections**:
1. **Bank $00** (Core Engine) - 37 sections (31.6%) - ✅ **COMPLETE**
2. Bank $02 (Battle System) - 33 sections (28.2%) - Next priority
3. Bank $0C (Unknown) - 10 sections (8.5%)

**Analysis Progress**:
- ✅ **Completed**: Bank $00 (37 sections)
- 🔍 **In Progress**: Bank $01 (4 sections, 3/4 done)
- ⏳ **Remaining**: Banks $02-$0D (76 sections)

---

## Categorization Analysis (Updated)

Based on complete analysis of Banks $00 and $01, unreachable sections fall into clear categories:

### � Reachable Code (75.6% of processed sections)

**Bank $00 Examples** (28 sections):
- `Map_InvalidPositionReturn` - Error return for invalid map coordinates
- `Graphics_CommandDispatch_IndexPath` - Table-driven graphics dispatch
- `Menu_Spell_Slot0Handler` - Complex spell validation (47 bytes)
- `SaveData_ChecksumMismatch` - Save data error handling
- `WRAM_SetupSprites_IncrementY2` - Simple utility (2 bytes)

**Bank $01 Examples** (3 sections):
- `Battle_CharacterSystemJumpTable` - 38 function pointers
- `BattleAI_SpecialCase` - Conditional AI handler
- `Battle_AnimationModeTable` - Data table

**Characteristics**:
- Conditionally reachable via branches (beq, bne, bcc, etc.)
- Table-driven access (jump tables, dispatch tables)
- Error handlers and edge case paths
- Actually executable and used in normal gameplay

**Total**: 31 sections (26.5% of all 117 sections)

### � Dead Code (24.4% of processed sections)

**Bank $00 Examples** (9 sections):
- `UNREACH_008C81` - Orphaned function epilogue (PLP, RTS)
- `UNREACH_00BDCA` - Orphaned error sound handler
- `UNREACH_00BEE5` - Orphaned menu polling (25 bytes)
- `UNREACH_00C1EB` - Duplicate error sound handler

**Bank $01 Examples** (1 section):
- `UNREACH_01EF3B` - No references found

**Characteristics**:
- No call sites or branch references
- Development artifacts or cut content
- Duplicate functionality removed during development
- Verified via comprehensive grep searches

**Total**: 10 sections (8.5% of all 117 sections)

### ❓ Unknown (Requires Analysis)

**Remaining Banks**: $02, $03, $05, $06, $07, $0B, $0C, $0D  
**Total**: 76 sections (65.0% of all 117 sections)

**Projected Distribution** (based on Banks $00-$01 patterns):
- Expected Reachable: ~57 sections (75% of remaining)
- Expected Dead Code: ~19 sections (25% of remaining)

---

## Pattern Recognition

### Common `db` Patterns Identified as Code

During initial inspection, the following `db` directive patterns were identified as valid 65816 opcodes:

| Pattern | Bytes | Disassembly | Context |
|---------|-------|-------------|---------|
| `$28, $60` | 2 | `plp; rts` | Function epilogue |
| `$a2, $ff, $ff, $60` | 4 | `ldx #$ffff; rts` | Error return |
| `$a9, $XX, $9d, $XX, $XX` | 5 | `lda #$XX; sta $XXXX,X` | Indexed write |
| `$eb` | 1 | `xba` | Accumulator swap |
| `$80, $XX` | 2 | `bra $XX` | Unconditional branch |

### Examples from Bank $00

**UNREACH_008C81**: `db $28,$60`
```asm
plp                              ; Pull processor status
rts                              ; Return from subroutine
```

**UNREACH_008D93**: `db $a2,$ff,$ff,$60`
```asm
ldx.W #$ffff                     ; Load X with $FFFF
rts                              ; Return from subroutine
```

**UNREACH_008D06**: `db $a9,$45,$9d,$00,$00,$eb,$9d,$01,$00,$80,$0f`
```asm
lda.B #$45                       ; Load immediate $45
sta.W $0000,X                    ; Store to $0000 indexed by X
xba                              ; Exchange B and A accumulators
sta.W $0001,X                    ; Store to $0001 indexed by X
bra $+$11                        ; Branch forward 17 bytes
```

---

## Cross-Bank Dependencies

### Bank $07 ↔ Bank $0B Communication

**Bank $0B → Bank $07**:
- `UNREACH_07F7C3` referenced by Bank $0B battle system
- Formation data pointer
- Battle system queries formation data from Bank $07

**Implication**: `UNREACH_07F7C3` is **definitely reachable** (Category 4)

### Bank $07 ↔ Bank $0C Communication

**Bank $07 → Bank $0C**:
- `UNREACH_0CD500` referenced by Bank $07
- `UNREACH_0CD501` referenced by Bank $07
- Data access from Bank $07 to Bank $0C

**Implication**: Both `UNREACH_0CD500` and `UNREACH_0CD501` are **definitely reachable** (Category 4)

### Analysis Impact

Cross-bank references indicate that:
1. Static analysis within single bank files misses inter-module calls
2. Disassembler trace logic doesn't follow cross-bank jumps
3. At least 3-4 "unreachable" sections are **actually reachable**
4. Need to search for `UNREACH_*` references across **all** bank files

---

## Code Quality Observations

### Documented Comments

Several unreachable sections already have descriptive comments:

| Address | Comment | Implication |
|---------|---------|-------------|
| `UNREACH_03D5E5` | "Orphaned Jump Table (Development Artifact / Cut Content)" | Dead code |
| `UNREACH_02A92C` | "Unreachable Error Handler" | Conditionally reachable |
| `UNREACH_02D269` | "Unreachable Code Section" | Unknown |
| `UNREACH_02D89B` | "Unreachable Special Case Handler" | Conditionally reachable |
| `UNREACH_02DBBD` | "Unreachable Alternate Renderer Path" | Conditionally reachable |
| `UNREACH_0DBDAE` | "UNREACHABLE DATA - Post-Padding Lookup Tables" | Data tables |

**Finding**: Some analysis has already been done, but not systematically applied.

### File Duplicates

Multiple versions of Bank files exist:
- `bank_00_documented.asm` vs `banks/bank_00.asm`
- `bank_02_documented.asm` vs `banks/bank_02.asm` vs `banks/bank_02.backup_20251102_205802.asm`

**Recommendation**: 
1. Identify canonical version for each bank
2. Apply changes to canonical version only
3. Remove or clearly mark backup/alternate files

---

## Estimated Effort Breakdown

Based on 117 unreachable sections + large data blocks:

### Phase 1: Discovery & Cataloging (Current)
- **Status**: 40% complete
- **Time Spent**: 4 hours
- **Remaining**: 6 hours
- **Tasks**:
  - ✅ Create catalog document
  - ✅ Scan for `UNREACH_*` labels (117 found)
  - ⏳ Read context for each section (20% done)
  - ⏳ Document call sites and references (10% done)
  - ⏳ Cross-reference between banks (30% done)

### Phase 2: Analysis & Classification
- **Status**: 0% complete
- **Estimated Time**: 12-16 hours
- **Tasks**:
  - Categorize all 117 sections (Categories 1-4)
  - Trace jump tables and dispatch tables
  - Identify all `db` blocks that are code
  - Search for cross-bank references
  - Compare with FFMQ community research

### Phase 3: Disassembly
- **Status**: 0% complete
- **Estimated Time**: 16-24 hours
- **Tasks**:
  - Disassemble all `UNREACH_*` sections
  - Replace `db` with proper opcodes
  - Add descriptive comments
  - Rename labels where appropriate
  - Test ROM build after each bank

### Phase 4: Documentation
- **Status**: 10% complete (catalog started)
- **Estimated Time**: 4-8 hours
- **Tasks**:
  - Complete all catalog entries
  - Finalize this report
  - Add header comments to ASM files
  - Update bank documentation
  - Document discoveries

### Phase 5: Verification
- **Status**: 0% complete
- **Estimated Time**: 4-6 hours
- **Tasks**:
  - Byte-perfect ROM verification
  - Community review
  - Update `.diz` file
  - Final QA check

**Total Estimated Effort**: 40-60 hours  
**Current Progress**: ~7% complete (4 of 54 hours)

---

## Next Steps (Immediate)

### Short-Term (Next Session)
1. ✅ Complete catalog document creation
2. ⏳ Read context around top 10 most suspicious sections
3. ⏳ Identify all cross-bank `UNREACH_*` references
4. ⏳ Start categorizing Bank $00 sections (33 sections)
5. ⏳ Disassemble first 3-5 simple `db` blocks as proof of concept

### Medium-Term (Next 2-3 Sessions)
1. Complete categorization of all 117 sections
2. Disassemble all Bank $00 unreachable sections
3. Disassemble all Bank $02 unreachable sections
4. Test ROM build with changes
5. Document any discoveries (debug modes, cut features)

### Long-Term (Project Completion)
1. Disassemble all remaining banks
2. Complete documentation
3. Final verification
4. Community review
5. Close issue #67

---

## Risk Assessment

### Low Risk
- ✅ Discovery phase (read-only analysis)
- ✅ Creating documentation
- ✅ Categorization

### Medium Risk
- ⚠️ Disassembling code (must verify opcodes)
- ⚠️ ROM build testing (must remain byte-perfect)
- ⚠️ Cross-bank analysis (complex dependencies)

### High Risk
- 🔴 Changing `.diz` file (affects future disassembly)
- 🔴 Removing "dead code" without verification
- 🔴 Misidentifying data as code (or vice versa)

### Mitigation Strategies
1. **Byte-perfect verification** after every change
2. **Git commits** after each bank completion
3. **Community review** for major discoveries
4. **Conservative approach** - when in doubt, mark as "Unknown"
5. **ROM testing** with emulator/hardware for critical sections

---

## Expected Outcomes

### Quantitative Goals
- ✅ 117 `UNREACH_*` sections documented
- ⏳ 100% categorization (Categories 1-4)
- ⏳ All `db` blocks analyzed
- ⏳ Byte-perfect ROM build maintained
- ⏳ True 100% code disassembly achieved

### Qualitative Goals
- ⏳ Complete understanding of unreachable code
- ⏳ Discovery of debug features/cut content
- ⏳ Improved disassembly accuracy
- ⏳ Better modding support
- ⏳ Authoritative "complete disassembly" status

### Potential Discoveries
- **Debug modes** - Unreachable menu options, test functions
- **Cut content** - Unused battle animations, enemy types
- **Development tools** - ROM verification, debug logging
- **Error handling** - Overflow checks, sanity tests
- **Optimization** - Dead code from refactoring

---

## References

- **Related Issue**: [GitHub Issue #67](https://github.com/TheAnsarya/ffmq-info/issues/67)
- **Catalog Document**: `docs/UNREACHABLE_CODE_CATALOG.md`
- **Search Results**: 117 `UNREACH_*` labels found (grep search November 4, 2025)
- **ASM Files**: `src/asm/bank_*.asm`, `src/asm/banks/bank_*.asm`

### External Resources
- [65816 Opcode Reference](https://wiki.superfamicom.org/65816-reference)
- [SNES Development Wiki](https://wiki.superfamicom.org/)
- FFMQ Community Research: [TBD]

---

## Appendix: Search Commands

### Find All UNREACH_* Labels
```powershell
grep -r "^UNREACH_" src/asm/**/*.asm
```

### Find Unreachable Comments
```powershell
grep -r "; (unreachable|dead code|never called|orphan|unused)" src/asm/**/*.asm
```

### Find db Directive Patterns
```powershell
grep -r "db.*; \$[0-9a-fA-F]" src/asm/**/*.asm
```

---

**Report Status**: 📊 Phase 1 Discovery - Initial statistics compiled, detailed analysis in progress  
**Last Updated**: November 4, 2025  
**Next Update**: After Phase 2 categorization completion
