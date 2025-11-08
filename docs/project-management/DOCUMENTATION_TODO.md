# Function Documentation TODO List
**Last Updated:** November 6, 2025  
**Current Progress:** 2,303/8,153 functions (28.2%)  
**Remaining:** 5,850 functions to document

---

## 📊 Current Session Status (Updates #34-36)

### ✅ Completed This Session
- **Update #34:** Bank $07 Animation System (13 functions) - Commit: e1588ab ✅ Pushed
- **Update #35:** Bank $0D SPC700 Sound Driver (11 functions) - Commit: 6fd9973 ✅ Pushed  
- **Update #36:** Bank $0D Audio Management (10 functions) - Commit: 44fb100 ✅ Pushed
- **Total:** 34 functions, ~7,300 lines, 64K tokens used (6.4%)

### 🎯 Documentation Strategy
- **Comprehensive docs:** Complex systems with protocol/algorithm details (~400-500 lines)
- **Standard docs:** Helper functions, buffer operations (~100-150 lines)
- **Efficiency target:** ~2,000-3,000 tokens per function
- **Session goal:** Use 90%+ of 1M token budget per session

---

## 🔍 PRIORITY QUEUE: High-Value Undocumented Functions

### Priority 1: Bank $02 System Management (83 functions) ⭐⭐⭐
**Location:** `src/asm/bank_02_documented.asm`  
**Address Range:** $E600-$F736  
**Estimated Value:** Very High (core system functions)

#### Partially Documented (check before documenting):
- ✅ CODE_02E6B4 (System_TimingCoordUpdate) - DOCUMENTED
- ✅ CODE_02E6ED (Memory_MultiThreadInit) - DOCUMENTED
- ✅ CODE_02E8B5 (System_StateReset) - DOCUMENTED
- ✅ CODE_02E8CD (Entity_ConfigCrossBank) - DOCUMENTED
- ✅ CODE_02E905 (Validation_CrossReference) - DOCUMENTED
- ✅ CODE_02E930 (CrossRef_ProcessMatch) - DOCUMENTED

#### To Document (77 functions):
```
CODE_02E969, CODE_02E983, CODE_02E992, CODE_02E9ED, CODE_02E9F7
CODE_02EA41, CODE_02EA42, CODE_02EA60, CODE_02EA66, CODE_02EA72
CODE_02EA7F, CODE_02EA87, CODE_02EA9F, CODE_02EAA2, CODE_02EABF
CODE_02EACA, CODE_02EB14, CODE_02EB30, CODE_02EB4A, CODE_02EB55
CODE_02EB7E, CODE_02EBA0, CODE_02EBAD, CODE_02EBB1, CODE_02EBC3
CODE_02EBCC, CODE_02EBD2, CODE_02EBE8, CODE_02EBF1, CODE_02EBF3
CODE_02EC08, CODE_02EC27, CODE_02EC3B, CODE_02EC42, CODE_02EC45
CODE_02EC4A, CODE_02EC68, CODE_02EC84, CODE_02EC98, CODE_02ECA0
CODE_02ECA5, CODE_02ECBA, CODE_02ECC8, CODE_02ECD0, CODE_02ECD5
CODE_02ECD8, CODE_02ECD9, CODE_02ECF0, CODE_02ED03, CODE_02ED16
CODE_02ED1A, CODE_02ED2C, CODE_02ED56, CODE_02ED58, CODE_02EE5D
CODE_02EE60, CODE_02EE6B, CODE_02EE6E, CODE_02EE6F, CODE_02EE7D
CODE_02EE84, CODE_02EE91, CODE_02EE9C, CODE_02EEBD, CODE_02EEE7
CODE_02EEFB, CODE_02EF05, CODE_02EF0D, CODE_02EF16, CODE_02EF31
CODE_02EF8D, CODE_02EFA8, CODE_02EFDB, CODE_02F5C3, CODE_02F5D9
CODE_02F5E3, CODE_02F5F9, CODE_02F605
(Plus 18 more in $F6xx range)
```

**System Categories:**
- Thread management and synchronization
- Memory allocation and validation
- Entity state management
- Cross-bank data coordination
- Graphics and PPU control
- Real-time processing loops

**Resumption Instructions:**
1. Search: `grep "^CODE_02E969:" src/asm/bank_02_documented.asm` to find starting line
2. Read lines 7458-7550 for CODE_02E969 context
3. Analyze code structure (thread operations, state management, etc.)
4. Document 15-20 functions per update (mix of related functions)
5. Group by functionality (e.g., all thread functions together)
6. Add to "System Coordination Functions" section in FUNCTION_REFERENCE.md
7. Commit as "Update #37: Bank $02 system functions (part N)"

---

### Priority 2: Bank $01 Graphics/DMA Functions (32 functions) ⭐⭐
**Location:** `src/asm/bank_01_documented.asm`  
**Address Range:** $8272-$858C  
**Estimated Value:** High (graphics, DMA, screen management)

#### Known Functions to Document:
```
CODE_018321, CODE_018272, CODE_0182A9, CODE_0182BE, CODE_0182C9
CODE_0182D0, CODE_0182D9, CODE_0182E3, CODE_0182E6, CODE_0182F2
CODE_01832D, CODE_018358, CODE_01836D, CODE_018372, CODE_0183BF
CODE_0183CB, CODE_0183CC, CODE_0183CF, CODE_018400, CODE_018401
CODE_018404, CODE_018435, CODE_018436, CODE_01845E, CODE_018463
CODE_018493, CODE_0184B9, CODE_0184E1, CODE_018547, CODE_018554
CODE_018568, CODE_01858C
```

**Likely Categories:**
- DMA transfer routines
- VRAM/OAM management
- Screen effect initialization
- Graphics buffer operations
- PPU register configuration

**Resumption Instructions:**
1. Check which are already documented: `grep "01:8272" docs/FUNCTION_REFERENCE.md`
2. Read code starting at line 528 in bank_01_documented.asm
3. Look for DMA patterns ($43xx registers, VRAM access)
4. Document in batches of 10-12 functions
5. Add to appropriate section (create "Graphics/DMA Functions (Bank $01)" if needed)

---

### Priority 3: Bank $0D Remaining Audio (0 functions - COMPLETE!) ✅
**Status:** Bank $0D audio system fully documented in Updates #35-36!
- ✅ SPC700 driver upload (11 functions)
- ✅ Audio management (10 functions)
- ✅ Total: 21 functions covering complete audio subsystem

---

### Priority 4: Bank $07 Remaining Animation (Unknown count) ⭐
**Location:** `src/asm/bank_07_documented.asm`  
**Estimated:** ~20-30 more functions beyond Update #34

**Search Command:**
```bash
grep "^CODE_07[0-9A-F]{4}:" src/asm/bank_07_documented.asm | wc -l
```

**Resumption Instructions:**
1. Run search to find all CODE_07 labels
2. Compare against documented functions in FUNCTION_REFERENCE.md
3. Focus on addresses beyond $9100 (Update #34 covered $9030-$90xx range)
4. Look for related animation/graphics processing functions

---

## 📋 SYSTEMATIC BANK SWEEP PLAN

### Phase 1: High-Priority Banks (Weeks 1-2)
- [x] **Bank $07:** Animation system (13 done, ~20 remain)
- [x] **Bank $0D:** Audio/SPC700 (21 done, COMPLETE ✅)
- [ ] **Bank $02:** System core (6 done, 77 remain) ← **START HERE**
- [ ] **Bank $01:** Graphics/DMA (unknown documented, 32 found)

### Phase 2: Medium-Priority Banks (Weeks 3-4)
- [ ] **Bank $0C:** Command handlers (check documentation status)
- [ ] **Bank $0B:** Battle/combat system (check documentation status)
- [ ] **Bank $03-$06:** Game logic banks (full sweep needed)

### Phase 3: Comprehensive Sweep (Weeks 5-8)
- [ ] **Banks $08-$0A:** Various systems
- [ ] **Banks $0E-$0F:** Late-game or special systems
- [ ] **Bank $00:** Core engine (check for CODE labels)

---

## 🔧 RESUMPTION WORKFLOW

### Starting a New Documentation Session

#### Step 1: Status Check (5 minutes)
```bash
# Navigate to repo
cd C:\Users\me\source\repos\ffmq-info

# Check git status
git status
git log --oneline -5

# Verify coverage
grep "^Coverage:" docs/FUNCTION_REFERENCE.md | tail -1
```

#### Step 2: Find Next Function Set (10 minutes)
```bash
# Option A: Continue Bank $02 (recommended)
grep "^CODE_02E969:" src/asm/bank_02_documented.asm

# Option B: Check Bank $01
grep "^CODE_018272:" src/asm/bank_01_documented.asm

# Option C: Find undocumented Bank $07
grep "^CODE_07[0-9A-F]{4}:" src/asm/bank_07_documented.asm > bank07_all.txt
grep "Bank \$07" docs/FUNCTION_REFERENCE.md > bank07_documented.txt
# Compare the two files
```

#### Step 3: Read Context (15 minutes)
```bash
# Read 100-200 lines around target function
# Example for CODE_02E969 at line 7458:
# Read lines 7400-7600 in bank_02_documented.asm
```

#### Step 4: Document Functions (120-180 minutes)
**Target:** 15-20 functions per session

**Standard Function Template:**
```markdown
#### FunctionName @ `$BANK:$ADDR`
**Location:** Bank $XX @ $ADDR

**Purpose:** [One sentence description]

**Inputs:**
- Register/memory locations

**Outputs:**
- Modified registers/memory

**Process:**
1. Step-by-step algorithm
2. Key operations
3. Branch conditions

**Performance:** ~XXX cycles

**Use Cases:** Where this is called from
```

**Comprehensive Function Template:**
```markdown
#### MajorSystem_MainFunction @ `$BANK:$ADDR` (COMPREHENSIVE)
**Location:** Bank $XX @ $ADDR

**Purpose:** [2-3 sentence detailed description]

**Inputs:**
- Detailed input descriptions
- Memory layouts
- Expected states

**Outputs:**
- All modifications
- State changes
- Side effects

**Algorithm:**
```
Pseudocode or detailed step list
Protocol descriptions
State machine diagrams
```

**Technical Details:**
- Hardware interactions
- Timing considerations
- Edge cases
- Performance characteristics

**Process:**
[Detailed numbered steps]

**Performance:**
- Best case: XXX cycles
- Typical: XXX cycles  
- Worst case: XXX cycles

**Use Cases:** [Detailed scenarios]

**Notes:** [Special considerations]
```

#### Step 5: Update Function List
Add new functions to the appropriate bank section in FUNCTION_REFERENCE.md:
```markdown
#### Bank $XX: [System Name] Functions

##### Function List
- `FunctionName1` @ $ADDR1 - Brief description
- `FunctionName2` @ $ADDR2 - Brief description
[... continue for all functions]

##### Detailed Documentation

[Full documentation for each function]
```

#### Step 6: Commit & Push (5 minutes)
```bash
git add docs/FUNCTION_REFERENCE.md
git commit -m "docs: Add Bank \$XX [system] functions (Update #YY)

Added N functions:
- FunctionName1 ($ADDR1): Description
- FunctionName2 ($ADDR2): Description
[... list all]

Technical details:
- [Key system features]
- [Important patterns discovered]
- [Performance notes]

Coverage: X,XXX → Y,YYY (ZZ.Z%)"

git push origin master
```

---

## 📈 EFFICIENCY GUIDELINES

### Token Budget Management
- **1M tokens per session** (Anthropic Claude limit)
- **Target usage:** 90-95% per session (~900K-950K tokens)
- **Reserve:** 5-10% for overhead (50K-100K tokens)

### Documentation Speed
- **Comprehensive function:** ~15-20K tokens (~30-40 min)
- **Standard function:** ~2-3K tokens (~5-10 min)
- **Ratio:** 1 comprehensive : 15-20 standard per session

### Quality Metrics
- **Accuracy:** All register names, addresses, and operations must be exact
- **Completeness:** All inputs, outputs, and side effects documented
- **Context:** Explain WHY the function exists, not just WHAT it does
- **Performance:** Include cycle counts when possible

---

## 🎯 MILESTONE TARGETS

### Short-Term (2-3 sessions)
- [ ] Complete Bank $02 system functions (77 remaining → ~5 updates)
- [ ] Document Bank $01 graphics/DMA (32 functions → ~2 updates)
- [ ] **Target:** 2,400+ functions (29.5%)

### Medium-Term (10-15 sessions)
- [ ] Complete all high-priority banks ($01, $02, $07, $0D)
- [ ] Sweep Banks $03-$06 for CODE labels
- [ ] **Target:** 3,000+ functions (36.8%)

### Long-Term (30-50 sessions)
- [ ] Complete all CODE/UNREACH labels across all banks
- [ ] Document all major game systems comprehensively
- [ ] **Target:** 5,000+ functions (61.3%)

### Ultimate Goal (100+ sessions)
- [ ] Document all 8,153 functions
- [ ] Create comprehensive system architecture documentation
- [ ] **Target:** 100% coverage

---

## 🔍 SEARCH COMMANDS REFERENCE

### Find All CODE Labels in a Bank
```bash
grep "^CODE_XX[0-9A-F]{4}:" src/asm/bank_XX_documented.asm
```

### Count Undocumented Functions
```bash
# Get all CODE labels
grep "^CODE_02[0-9A-F]{4}:" src/asm/bank_02_documented.asm > all_code.txt

# Get documented addresses
grep "Bank \$02 @" docs/FUNCTION_REFERENCE.md | sed 's/.*@ \$//' | sed 's/ .*//' > documented.txt

# Compare (manual or with script)
```

### Find Specific Function Documentation
```bash
grep -A 20 "@ \$02:\$E969" docs/FUNCTION_REFERENCE.md
```

### Check Coverage Stats
```bash
grep "Coverage:" docs/FUNCTION_REFERENCE.md | tail -1
```

---

## 📝 NOTES FOR FUTURE SESSIONS

### Code Analysis Tips
1. **Look for patterns:**
   - PHx/PLx sequences indicate register preservation
   - REP/SEP indicate register width changes
   - MVN instructions = block memory operations
   - JSL = cross-bank calls (important system functions)

2. **Identify function types:**
   - **Initialization:** Clears memory, sets up state
   - **Processing:** Loops, conditionals, transformations
   - **Transfer:** DMA, VRAM uploads, data movement
   - **Validation:** Comparisons, error checking
   - **Coordination:** Multi-system synchronization

3. **Performance estimation:**
   - Simple operation: ~10-50 cycles
   - Memory loop: ~100-500 cycles  
   - DMA transfer: ~1000-5000 cycles
   - Cross-bank call: +overhead of target function

### Documentation Quality Checklist
- [ ] Function name is descriptive and follows naming convention
- [ ] All register inputs/outputs documented
- [ ] All memory addresses identified (with symbolic names if possible)
- [ ] Algorithm steps are clear and ordered
- [ ] Performance estimate included
- [ ] Use cases or calling contexts mentioned
- [ ] Special cases or edge conditions noted

### Naming Conventions
- **System_OperationTarget** (e.g., System_TimingCoordUpdate)
- **Target_Operation** (e.g., Memory_MultiThreadInit)
- **System_Target** (e.g., Thread_SyncWait)
- **Operation_Target** (e.g., Validation_CrossReference)

---

## 🚀 QUICK START FOR NEXT SESSION

**Recommended starting point: Bank $02 system functions**

```bash
# 1. Navigate and update
cd C:\Users\me\source\repos\ffmq-info
git pull origin master

# 2. Open files
code src/asm/bank_02_documented.asm  # Line 7458 (CODE_02E969)
code docs/FUNCTION_REFERENCE.md      # Find "System Coordination Functions"

# 3. Read context
# Read bank_02_documented.asm lines 7450-7550

# 4. Start documenting
# Begin with CODE_02E969 and related functions
# Target: 15-20 functions for Update #37

# 5. Estimated session time: 2-3 hours
# 6. Expected output: ~40K-60K tokens, 1,500-2,000 lines
```

---

## 📚 REFERENCE DOCUMENTATION LOCATIONS

### Current Documentation
- **Main reference:** `docs/FUNCTION_REFERENCE.md` (17,608 lines)
- **Coverage tracking:** Search file for "Coverage: X,XXX/8,153"
- **Bank sections:** Search for "Bank $XX" to find section headers

### Source Code
- **Bank files:** `src/asm/bank_XX_documented.asm`
- **Bank $02:** 9,280 lines, system core
- **Bank $01:** 9,703 lines, graphics/DMA
- **Bank $07:** Variable, animation system
- **Bank $0D:** 2,984 lines, audio/SPC700

### Project Files
- **Build scripts:** `build.ps1`, `modern-build.ps1`
- **Progress tracking:** `PROGRESS_REPORT.md`, `STATUS.md`
- **Session logs:** `SESSION_LOG.md`, `SESSION_SUMMARY.md`

---

## 🎓 LEARNING RESOURCES

### SNES Hardware
- **SPC700:** Sony audio processor, separate from main CPU
- **PPU:** Picture Processing Unit (graphics)
- **DMA:** Direct Memory Access for fast transfers
- **VRAM:** Video RAM for graphics data
- **OAM:** Object Attribute Memory for sprites

### 65816 Assembly
- **Register sizes:** 8-bit (SEP) or 16-bit (REP)
- **Addressing modes:** Direct, indexed, indirect, long
- **Banks:** 64KB segments in 24-bit address space
- **MVN:** Block move instruction (very fast)

### Common Patterns
- **Thread system:** Multi-tasking on single CPU
- **State machines:** Entity behavior control
- **Validation loops:** Cross-reference checking
- **Buffer operations:** Graphics data manipulation

---

**Last Session:** November 6, 2025 (Updates #34-36)  
**Next Session:** Continue with Bank $02 (CODE_02E969+)  
**Estimated Remaining Time:** 200-300 hours (100-150 sessions)

**Remember:** Quality over quantity, but use full token budget!
