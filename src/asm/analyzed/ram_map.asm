; ============================================================================
; FFMQ Complete RAM Variable Map
; ============================================================================
; Comprehensive mapping of RAM variables used throughout FFMQ
; Based on analysis of code patterns across all banks
;
; RAM Layout:
; $0000-$00FF: Zero Page (Direct Page) - Fast access variables
; $0100-$01FF: Stack Page - Also used for variables
; $0200-$1FFF: Low RAM - General purpose variables
; $7E0000-$7FFFFF: Work RAM Bank $7E - Main game data
; $7F0000-$7FFFFF: Work RAM Bank $7F - Additional data/buffers
; $700000-$7FFFFF: SRAM - Save game data
; ============================================================================

; ============================================================================
; Zero Page Variables ($0000-$00FF)
; ============================================================================
; These are in direct page for fast access (no bank byte needed)

; --- Temporary/Scratch Variables ---
$15 = .word                         ; Temporary result/return value
$17 = .word                         ; Pointer/address (low/mid bytes)
$19 = .byte                         ; Pointer bank byte
$53 = .word                         ; Temporary pointer
$58 = .word                         ; Callback routine address
$5A = .byte                         ; Callback routine bank
$64 = .word                         ; Temporary calculation/index

; --- PPU/Display Control ---
$00AA = .byte                       ; Screen brightness (0-15, $0F=full)
$00B2 = .byte                       ; Equipment stat bonus 2
$00B3 = .byte                       ; Equipment stat bonus 4
$00B4 = .byte                       ; Equipment stat bonus 3
$00B5 = .byte                       ; Equipment stat bonus 1

; --- System Flags (Critical!) ---
$00D2 = .byte                       ; DMA/System flags byte 1
    ; Bit 0: Unknown
    ; Bit 1: Unknown
    ; Bit 2: Unknown
    ; Bit 3: Menu DMA active
    ; Bit 4: VRAM transfer mode
    ; Bit 5: Tile transfer pending
    ; Bit 6: Unknown  
    ; Bit 7: Palette DMA requested

$00D4 = .byte                       ; DMA/System flags byte 2
    ; Bit 0: General transfer flag
    ; Bit 1: Tile transfer flag
    ; Bit 2: Unknown
    ; Bit 3: Unknown
    ; Bit 4: Unknown
    ; Bit 5: Unknown
    ; Bit 6: Unknown
    ; Bit 7: Tile DMA requested

$00D6 = .byte                       ; Display update flags
    ; Bit 0-5: Unknown
    ; Bit 6: Display update pending
    ; Bit 7: Unknown

$00D8 = .byte                       ; VBlank/transfer flags
    ; Bit 0: Unknown
    ; Bit 1: Palette mode flag
    ; Bit 2: Unknown
    ; Bit 3: Unknown
    ; Bit 4: Unknown
    ; Bit 5: Unknown
    ; Bit 6: VBlank occurred (set by NMI, cleared by WaitForVBlank)
    ; Bit 7: Special transfer mode

$00D9 = .byte                       ; Additional system flags
$00DA = .word                       ; Hardware configuration flags
$00DD = .byte                       ; VRAM transfer flags
    ; Bit 6: Transfer pending

$00DE = .byte                       ; General flags byte 1
    ; Bit 7: Used in boot sequence

; --- Callback/Interrupt Control ---
$00E2 = .byte                       ; Callback flags
    ; Bit 6: Callback pending (execute $0058-$005A routine)

$00EF = .byte                       ; Current equipment slot (0-4)
$00F0 = .word                       ; Transfer mask word

; ============================================================================
; Page 1 Variables ($0100-$01FF)
; ============================================================================

$0110 = .byte                       ; Menu state/mode
$0111 = .byte                       ; General menu flags
$0112 = .byte                       ; Saved interrupt enable flags (for $4200)
$015F = .byte                       ; Current equipment ID

; --- DMA Parameter Storage ---
$01EB = .word                       ; Palette data size
$01ED = .word                       ; Palette source address (low/mid)
$01EF = .byte                       ; Palette source bank
$01F0 = .word                       ; Unknown parameter
$01F2 = .word                       ; Unknown parameter
$01F4 = .word                       ; General transfer size
$01F6 = .word                       ; General source address
$01F8 = .word                       ; General VRAM destination
$0048 = .word                       ; VRAM destination address
$0062 = .word                       ; Transfer mode type
$0064 = .word                       ; Tile data index

; ============================================================================
; Low RAM Variables ($0200-$1FFF)
; ============================================================================

; --- Menu/Equipment Display ---
$0E08 = .word                       ; Menu window data
$0E0A = .word                       ; Menu window data
$0E0C = .word                       ; Menu window data
$0E88 = .byte                       ; Equipment parameter 1
$0E89 = .word                       ; Equipment parameter 2
$0E92 = .byte                       ; Equipment parameter 3
$0E9C = .word                       ; Unknown data

; --- Character Stats (per character) ---
; Each character has a stat block, likely ~32-64 bytes
; Includes: HP, MP, ATK, DEF, level, experience, etc.

$0C84 = .word                       ; Character data pointer 1
$0C88 = .word                       ; Character data pointer 2
$0C8C = .word                       ; Character data pointer 3
$0C90 = .word                       ; Character data pointer 4
$0CC0 = .word                       ; Character extended data 1
$0CC4 = .word                       ; Character extended data 2
$0CC8 = .word                       ; Character extended data 3
$0CCC = .word                       ; Character extended data 4

; ============================================================================
; Work RAM Bank $7E ($7E0000-$7E7FFF)
; ============================================================================

; --- Boot/Save Flags ---
$7E3659 = .byte                     ; Unknown flag
$7E365A = .word                     ; Unknown data
$7E365C = .word                     ; Unknown data
$7E365E = .byte                     ; Unknown flag
$7E365F = .word                     ; Unknown data
$7E3661 = .word                     ; Unknown data
$7E3663 = .byte                     ; Unknown flag
$7E3665 = .byte                     ; Save data present / Menu initialized flag
                                    ; $00 = no save, $01 = save exists/menu ready
$7E3667 = .byte                     ; Boot flag 1
                                    ; Incremented on each boot
$7E3668 = .byte                     ; Boot flag 2  
                                    ; Incremented on each restart
$7E3367 = .word                     ; Magic number $3369 (checksum/validity?)

; --- Game State Data ---
; $7E3000-$7E3FFF likely contains:
; - Party member data
; - Inventory
; - Equipment
; - Flags for events/progression
; - Current location/map

; --- Graphics Buffers ---
; $7F0000-$7FFFFF used for:
; - DMA source buffers
; - Decompressed graphics
; - Tilemap staging area

$7F075A = .word                     ; Graphics buffer (used in DMA)

; ============================================================================
; SRAM ($700000-$7FFFFF)
; ============================================================================
; Battery-backed save RAM for persistent game data

; --- Save Slots ---
$700000 = .block 140                ; Save slot 1 data
                                    ; Offset $000-$038B (907 bytes)
$70038C = .block 140                ; Save slot 2 data  
                                    ; Offset $38C-$717 (907 bytes)
$700718 = .block 140                ; Save slot 3 data
                                    ; Offset $718-$AA3 (907 bytes)

; Save data format (per slot, ~900 bytes):
; - Character stats (HP, MP, level, exp)
; - Equipment (weapon, armor, helmet, shield, accessory per character)
; - Inventory (items, quantities)
; - Magic spells learned
; - Game progress flags
; - Play time
; - Gold/currency
; - Current location
; - Party formation

; ============================================================================
; Flag Byte Usage Patterns
; ============================================================================

; The game extensively uses bit flags for state management:
;
; Common operations:
; - TSB (Test and Set Bits): Set specific bits to 1
; - TRB (Test and Reset Bits): Clear specific bits to 0  
; - AND: Test if bits are set
; - BEQ/BNE: Branch based on result
;
; Example VBlank synchronization:
;   LDA #$40        ; Bit 6
;   TRB $00D8       ; Clear VBlank flag
; .loop:
;   AND $00D8       ; Test VBlank flag
;   BEQ .loop       ; Loop until set
;
; This pattern appears hundreds of times throughout the code

; ============================================================================
; Critical RAM Addresses Summary
; ============================================================================
; Most frequently accessed:
; 1. $00D8 - VBlank flag (used in every frame update)
; 2. $00D2 - DMA flags (used in all graphics operations)
; 3. $00D4 - Transfer flags (used in VRAM updates)
; 4. $00AA - Brightness (screen fade in/out)
; 5. $7E3665 - Save/init flag (checked often)
; 6. $00DA - Hardware config (checked for features)
; 7. $01F4-$01F8 - DMA parameters (every graphics transfer)

; ============================================================================
; Memory Map Confidence Levels
; ============================================================================
; ✅ High Confidence (verified through multiple code paths):
;    $00AA, $00D2, $00D4, $00D6, $00D8, $00E2, $7E3665, $7E3667, $7E3668
;
; ⚠️ Medium Confidence (inferred from patterns):
;    $00B2-$00B5, $00EF, $015F, $01EB-$01F8, SRAM layout
;
; ❓ Low Confidence (needs more analysis):
;    Character stat block exact layout, inventory structure details
;
; 🔍 Needs Investigation:
;    $7E3000-$7E3600 range (likely game state/progression)
;    $0200-$0800 range (various game systems)
;    $1000-$1FFF range (additional buffers)
; ============================================================================

; ============================================================================
; Next Steps for Complete RAM Map
; ============================================================================
; 1. Analyze save/load routines to understand SRAM structure
; 2. Trace character stat access patterns
; 3. Map inventory system RAM usage
; 4. Document battle system RAM (enemy data, damage calc)
; 5. Map event/script system flags
; 6. Document sound/music RAM usage
; ============================================================================
