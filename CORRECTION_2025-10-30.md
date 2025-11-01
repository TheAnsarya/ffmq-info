# CRITICAL CORRECTION - October 30, 2025

## Issue Discovered: Bad Reference Import

### Problem
The "import" from DiztinGUIsh reference (commit 5ea9173) imported **8,053 lines of `db` (data byte) statements**, NOT actual disassembled 65816 instructions. Banks $04-$0F in the DiztinGUIsh reference contain mostly graphics/music/data, not executable code.

### What Was Imported (INCORRECTLY)
```asm
; This is NOT useful disassembly - just raw data bytes!
db $01,$01,$02,$03,$03,$02,$01,$01,$02,$03,$02,$03,$00,$00,$04,$06
db $00,$00,$00,$00,$00,$00,$01,$01,$80,$80,$40,$C0,$C0,$40,$80,$80
db $40,$C0,$40,$C0,$00,$00,$20,$60,$00,$00,$00,$00,$00,$00,$80,$80
...thousands more lines of db statements...
```

### What SHOULD Be Imported (from Banks $00-$03)
```asm
; Actual disassembled 65816 instructions
LDA.B #$00
STA.W $00D4
JSR.W CODE_008247
REP #$30
LDX.W #$1FFF
```

### Analysis
- ✅ Banks $00-$03: Have **real disassembled code** (LDA, STA, JSR, etc.)
- ❌ Banks $04-$0F: Only have **`db` data statements** (graphics, music, tables)
- Banks $04-$0F are primarily **data banks**, not code banks
- DiztinGUIsh couldn't auto-disassemble them (correctly, as they're data)

### Action Taken
1. ✅ **Restored backups** of banks $04, $05, $06, $0F
2. ✅ **Reverted to 71.56%** completion (from false 85%)
3. ✅ **Removed useless temp import files**
4. ✅ **Documented the issue** for future reference

### Correct Strategy Going Forward

#### Banks to Import (Have Real Code)
- Bank $00: 14,017 lines of disassembled code ✨
- Bank $01: 15,480 lines of disassembled code ✨  
- Bank $02: 12,469 lines of disassembled code ✨
- Bank $03: 2,351 lines of disassembled code ✨

**These CAN be imported** if we want better documentation for already-complete banks.

#### Banks NOT to Import (Data Only)
- Banks $04-$0F: Graphics, music, sound, data tables
- These need **manual analysis** to identify:
  * Graphics tile data
  * Music/SPC700 data
  * Lookup tables
  * String/text data
  * Palette data

### Lessons Learned
1. **Always verify import quality** - check that it's actual disassembly, not just `db` statements
2. **Data banks need different approach** - can't auto-disassemble graphics/music
3. **Reference is still valuable** - banks $00-$03 have excellent disassembly
4. **72% completion is accurate** - the "85%" was inflated by useless data

### Current Accurate Status
- **Completion: 71.56%** (correct)
- **Complete Banks**: 8/16 (banks $00-$03, $0B-$0E)
- **In Progress**: 8/16 (banks $04-$0A, $0F)
- **ROM Match**: 99.996% (21 bytes differ)

### Next Steps (Corrected)
1. **Analyze data banks $04-$0F** to identify:
   - Graphics data regions
   - Music/audio data
   - Lookup tables
   - Text strings
   
2. **Consider importing banks $00-$03** reference for better documentation
   (Would replace our existing code with DiztinGUIsh's more complete version)

3. **Manual disassembly** of any code sections in banks $04-$0F
   (Use our Aggressive-Disassemble.ps1 tool for heuristic detection)

4. **Focus on banks $07-$0A** which are 75% complete
   (These likely have actual code mixed with data)

---

**Commit**: Will revert commit 5ea9173 and 2466980  
**Status**: Correction documented, backups restored  
**Impact**: No harm done - we have backups and can learn from this  

The good news: We have excellent reference material for banks $00-$03!  
The reality: Banks $04-$0F need careful manual analysis, not bulk import.
