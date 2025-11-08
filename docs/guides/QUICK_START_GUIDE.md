# Quick Start Guide for Function Documentation Sessions

**Last Updated:** November 6, 2025  
**Current Status:** 2,303/8,153 functions (28.2%)  
**Last Update:** #36 (Bank $0D audio management)

---

## 🚀 START A NEW SESSION (5-10 minutes)

### 1. Environment Setup
```powershell
# Navigate to repository
cd C:\Users\me\source\repos\ffmq-info

# Pull latest changes
git pull origin master

# Verify status
git status
git log --oneline -5

# Check current coverage
grep "Coverage:" docs/FUNCTION_REFERENCE.md | tail -1
```

### 2. Choose Next Function Set

**RECOMMENDED: Bank $02 System Functions (Update #37)**
```powershell
# Open source file at line 7458 (CODE_02E969)
code src/asm/bank_02_documented.asm

# Open documentation file
code docs/FUNCTION_REFERENCE.md

# Search for "System Coordination Functions" section
```

**Read:** `DOCUMENTATION_TODO.md` for complete function list

---

## 📝 DOCUMENTATION WORKFLOW

### Phase 1: Analysis (30-45 min)
1. **Read source code** (100-200 lines around target function)
2. **Identify function type:**
   - Initialization? (clears memory, sets state)
   - Processing? (loops, transforms data)
   - Transfer? (DMA, VRAM)
   - Validation? (checks, comparisons)
   - Coordination? (multi-system sync)
3. **Map inputs/outputs:**
   - Which registers are used? (A, X, Y)
   - Which memory locations? ($0ABC, $7EXXXX)
   - What's preserved? (PH_/PL_ patterns)
4. **Trace algorithm:**
   - Step through branch logic
   - Note loop structures
   - Identify exit conditions

### Phase 2: Documentation (60-90 min)
1. **Create function entry** in FUNCTION_REFERENCE.md
2. **Write clear purpose** (1-2 sentences)
3. **List all inputs** (registers, memory, expected states)
4. **List all outputs** (modified registers/memory)
5. **Document process** (step-by-step algorithm)
6. **Estimate performance** (cycle count)
7. **Note use cases** (where it's called from)

### Phase 3: Batch & Commit (15-30 min)
1. **Document 15-20 functions** (mix of related functions)
2. **Review for accuracy** (check register names, addresses)
3. **Update function list** (add to bank section)
4. **Commit with details** (see commit template below)
5. **Push to GitHub**

---

## 📋 TEMPLATES

### Standard Function Documentation
```markdown
#### FunctionName @ `$0X:$XXXX`
**Location:** Bank $0X @ $XXXX

**Purpose:** [Clear one-sentence description of what it does]

**Inputs:**
- `A` (byte/word) = [Description]
- `X` (word) = [Description]  
- `$0ABC` (word) = [Description]

**Outputs:**
- `A` (byte) = [Result]
- `$7EXXXX,X` = [Modified data]

**Process:**
1. [First step with register/memory operations]
2. [Second step with branch conditions]
3. [Continue until function returns]

**Performance:** ~XXX cycles

**Use Cases:** [Where this is called, what triggers it]

---
```

### Comprehensive Function Documentation
```markdown
#### SystemName_MainFunction @ `$0X:$XXXX` (COMPREHENSIVE)
**Location:** Bank $0X @ $XXXX

**Purpose:** [2-3 sentence detailed description explaining the system and why this function exists]

**Inputs:**
- [Detailed input descriptions with memory layouts]
- [Expected states and preconditions]
- [Configuration data locations]

**Outputs:**
- [All modifications including side effects]
- [State changes and flags set]
- [Memory buffers updated]

**Algorithm:**
```
[Pseudocode or protocol description]
1. Initialization phase
2. Main processing loop
3. Cleanup and return
```

**Technical Details:**
- [Hardware interactions (PPU, DMA, APU)]
- [Timing considerations and synchronization]
- [Edge cases and error handling]
- [Performance characteristics]

**Process:**
[Detailed numbered steps with register operations]

**Performance:**
- Best case: XXX cycles (~XX μs)
- Typical: XXX cycles (~XX μs)
- Worst case: XXX cycles (~XX μs)

**Use Cases:**
[Detailed scenarios with context]

**Notes:**
[Special considerations, gotchas, optimization notes]

---
```

### Git Commit Template
```bash
git add docs/FUNCTION_REFERENCE.md
git commit -m "docs: Add Bank \$XX [system] functions (Update #YY)

Added N functions:
- FunctionName1 (\$ADDR): One-line description
- FunctionName2 (\$ADDR): One-line description
- FunctionName3 (\$ADDR): One-line description
[... continue for all functions]

Technical details:
- [Key discovery 1]
- [Key discovery 2]
- [Performance notes]

Coverage: X,XXX → Y,YYY (ZZ.Z%)"

git push origin master
```

---

## 🎯 SESSION TARGETS

### Per-Session Goals
- **Functions documented:** 15-20 (standard) or 1 comprehensive + 10 standard
- **Documentation lines:** 1,500-2,500 lines
- **Token usage:** 900K-950K (90-95% of budget)
- **Time:** 2-3 hours
- **Coverage increase:** ~0.2-0.3%

### Efficiency Metrics
- **Standard function:** ~2-3K tokens (~5-10 min each)
- **Comprehensive function:** ~15-20K tokens (~30-40 min each)
- **Target rate:** ~2,000-3,000 tokens per function average

---

## 🔍 QUICK REFERENCE

### Find Undocumented Functions
```bash
# Bank $02 (recommended starting point)
grep "^CODE_02E[9A-F][0-9A-F]{2}:" src/asm/bank_02_documented.asm

# Bank $01
grep "^CODE_01[0-9A-F]{4}:" src/asm/bank_01_documented.asm

# Bank $07
grep "^CODE_07[0-9A-F]{4}:" src/asm/bank_07_documented.asm
```

### Check if Function is Documented
```bash
# Replace XXXX with address (e.g., E969)
grep "\$02:\$XXXX" docs/FUNCTION_REFERENCE.md
```

### Common Code Patterns

**Register Preservation:**
```asm
php         ; Preserve processor status
phx         ; Preserve X
phy         ; Preserve Y
...
ply         ; Restore Y
plx         ; Restore X
plp         ; Restore processor status
```

**Register Width Change:**
```asm
rep #$20    ; 16-bit accumulator (A)
rep #$10    ; 16-bit index (X, Y)
rep #$30    ; Both 16-bit
sep #$20    ; 8-bit accumulator
sep #$10    ; 8-bit index
sep #$30    ; Both 8-bit
```

**Direct Page Change:**
```asm
phd         ; Preserve direct page
pea.w $0A00 ; Push new DP
pld         ; Load new DP
...
pld         ; Restore original DP
```

**Block Memory Operations:**
```asm
mvn $7E,$7E ; Move memory (source bank, dest bank)
            ; X = source addr, Y = dest addr, A = length-1
```

**DMA Setup:**
```asm
lda #$01
sta $420B   ; Trigger DMA on channel 0
```

---

## 📚 BANK OVERVIEW

### Bank $02 - System Core ⭐⭐⭐
- **Functions:** 101 CODE labels
- **Documented:** ~24
- **Remaining:** ~77
- **Priority:** HIGHEST
- **Systems:** Threading, memory management, validation, entity control

### Bank $01 - Graphics/DMA ⭐⭐
- **Functions:** 32 CODE labels
- **Documented:** Unknown (verify)
- **Remaining:** ~32
- **Priority:** HIGH
- **Systems:** DMA transfers, VRAM management, screen effects

### Bank $07 - Animation ⭐⭐
- **Functions:** Unknown total
- **Documented:** 13 (Update #34)
- **Remaining:** ~20-30 estimated
- **Priority:** MEDIUM-HIGH
- **Systems:** Multi-layer animation, frame buffers, sprite control

### Bank $0D - Audio ✅
- **Functions:** 74 CODE labels
- **Documented:** 21 (Updates #35-36)
- **Remaining:** 0 (COMPLETE!)
- **Systems:** SPC700 driver, music/SFX playback, channel management

---

## ⚡ PRODUCTIVITY TIPS

### Code Reading
1. **Start with function entry** - understand inputs
2. **Find the exit points** - RTS, RTL, branches to exits
3. **Map the flow** - follow branch logic
4. **Identify loops** - BNE/BEQ going backwards
5. **Note hardware access** - $2xxx (PPU), $4xxx (DMA/controller)

### Documentation Writing
1. **Purpose first** - what does it do in one sentence?
2. **Inputs/outputs** - be specific with register sizes
3. **Algorithm steps** - numbered, clear actions
4. **Performance** - rough cycle count helps
5. **Context** - mention calling functions or use cases

### Batch Processing
1. **Group related functions** - all thread functions together
2. **Document helpers first** - understand building blocks
3. **Save complex for last** - build context first
4. **Verify as you go** - check register names, addresses
5. **Commit frequently** - every 15-20 functions

### Token Management
1. **Track usage** - aim for 90-95% by session end
2. **Mix documentation types** - 1 comprehensive + many standard
3. **Don't rush** - quality over quantity
4. **Use full budget** - document until ~950K tokens used

---

## 🎓 HELPFUL CONCEPTS

### SNES Memory Map
- `$00:0000-$1FFF` - Low RAM (8KB, fast)
- `$7E:0000-$FFFF` - Work RAM (64KB)
- `$7F:0000-$FFFF` - Extended RAM (64KB)
- `$00:2100-$213F` - PPU registers (graphics)
- `$00:4200-$421F` - DMA/controller registers

### Cycle Timing (Approximate)
- Simple instruction (LDA, STA): 2-4 cycles
- Branch (BNE, BEQ): 2-4 cycles
- Jump (JMP, JSR): 3-6 cycles
- Long jump (JSL, RTL): 8-9 cycles
- Memory clear loop: ~5 cycles per byte
- DMA transfer: ~2.7 cycles per byte

### Function Categories
- **Init:** Sets up system, clears memory
- **Process:** Main logic, loops, transforms
- **Transfer:** DMA, VRAM uploads
- **Validate:** Checks, comparisons, error detection
- **Coordinate:** Multi-system sync, thread management

---

## 📞 HELP & RESOURCES

### If Stuck
1. **Read surrounding code** - context helps
2. **Look for similar functions** - patterns repeat
3. **Check PPU/DMA registers** - hardware manuals
4. **Trace backwards** - find calling functions
5. **Document what you know** - partial is better than none

### Documentation
- **SNES Dev Manual:** Hardware reference
- **65816 Reference:** CPU instruction set
- **This Project:** `DOCUMENTATION_TODO.md` for strategy

### File Locations
- **Documentation:** `docs/FUNCTION_REFERENCE.md`
- **Source:** `src/asm/bank_XX_documented.asm`
- **Progress:** `PROGRESS_REPORT.md`, `STATUS.md`
- **Todo:** `DOCUMENTATION_TODO.md` (this session's creation!)

---

## ✅ PRE-SESSION CHECKLIST

Before starting documentation:
- [ ] Repository is up to date (`git pull`)
- [ ] You know which bank to work on (Bank $02 recommended)
- [ ] You've identified starting function (CODE_02E969 recommended)
- [ ] You have 2-3 hours available
- [ ] `DOCUMENTATION_TODO.md` is open for reference
- [ ] Source and documentation files are open in editor

After session:
- [ ] All functions documented with required sections
- [ ] Function list updated in appropriate bank section
- [ ] Git commit created with proper message format
- [ ] Changes pushed to GitHub
- [ ] Coverage increase noted in commit message
- [ ] Todo list updated for next session

---

## 🎯 RECOMMENDED NEXT STEPS

**For immediate continuation:**
1. Open `src/asm/bank_02_documented.asm` at line 7458
2. Read CODE_02E969 and next 10-15 functions
3. Document as Update #37
4. Target: 15-20 Bank $02 system functions

**Target functions for Update #37:**
```
CODE_02E969 (Thread processing)
CODE_02E983 (Thread state)
CODE_02E992 (Thread cleanup)
CODE_02E9ED (Entity management)
CODE_02E9F7 (Entity validation)
CODE_02EA41-EA87 (Entity operations)
... continue with related functions
```

**Estimated session:**
- Time: 2-3 hours
- Output: ~1,800-2,500 lines
- Tokens: ~40K-60K
- Coverage: 28.2% → 28.4%

---

**Remember:** Quality documentation helps future developers understand this complex SNES game engine. Take time to understand the code, explain it clearly, and use the full token budget!

**Good luck with Update #37!** 🚀
