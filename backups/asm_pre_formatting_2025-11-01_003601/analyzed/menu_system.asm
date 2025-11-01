; ============================================================================
; FFMQ Menu System and VBlank Control Analysis
; ============================================================================
; Analyzed from Diztinguish disassembly bank_0C.asm
; Bank $0C ($0C8000-$0CFFFF) - Menu System, UI, and Display Control
;
; This file documents the menu system, VBlank synchronization, and
; display management routines used throughout the game.
; ============================================================================

; ============================================================================
; VBlank Wait Routine
; ============================================================================
; Address: $0C8000 (Original: CODE_0C8000)
; This is THE most called routine in the entire game!
; Every screen update must wait for vertical blank to avoid visual glitches
; ============================================================================
WaitForVBlank:
    PHP                             ; Save processor status
    SEP #$20                        ; 8-bit accumulator
    PHA                             ; Save A register
    
    ; Clear VBlank flag
    LDA.B #$40                      ; Bit 6 = VBlank flag
    TRB.W $00D8                     ; Clear bit in flag byte
    
.waitLoop:
    ; Poll VBlank flag
    LDA.B #$40                      ; Check bit 6
    AND.W $00D8                     ; Test flag byte
    BEQ .waitLoop                   ; Loop until VBlank occurs
    
    ; VBlank has occurred
    PLA                             ; Restore A register
    PLP                             ; Restore processor status
    RTL                             ; Return to caller

; VBlank flag at $00D8 bit 6 is set by NMI handler
; Every frame, the NMI sets this bit
; This routine clears it and waits for it to be set again
; Ensures all VRAM/PPU updates happen during safe period

; ============================================================================
; Equipment Window Display Routine
; ============================================================================
; Address: $0C8013 (Original: CODE_0C8013)
; Displays equipment information in battle/status screen
; Input: A = equipment slot index (0-4: weapon, armor, helm, shield, accessory)
; ============================================================================
DisplayEquipmentInfo:
    PHP                             ; Save status
    PHD                             ; Save direct page
    PEA.W $0000                     ; Set direct page to $0000
    PLD
    REP #$30                        ; 16-bit mode
    PHX                             ; Save X
    
    ; Calculate equipment data offset
    AND.W #$00FF                    ; Mask to byte
    STA.B $64                       ; Store index
    ASL A                           ; index * 2
    ASL A                           ; index * 4
    ADC.B $64                       ; index * 5
    TAX                             ; X = index * 5 (offset into table)
    
    SEP #$20                        ; 8-bit mode
    LDA.B $64                       ; Get index again
    STA.W $00EF                     ; Store equipment slot
    
    ; Load equipment stats from data table
    LDA.L DATA8_07EE84,X            ; Equipment ID
    STA.W $015F                     ; Store equipment ID
    
    ; Process stat bonuses (ATK/DEF/etc)
    LDA.L DATA8_07EE85,X            ; Stat bonus 1
    JSR.W ConvertStatBonus          ; Convert to display format
    STA.W $00B5                     ; Store stat 1
    
    LDA.L DATA8_07EE86,X            ; Stat bonus 2
    JSR.W ConvertStatBonus
    STA.W $00B2                     ; Store stat 2
    
    LDA.L DATA8_07EE87,X            ; Stat bonus 3
    JSR.W ConvertStatBonus
    STA.W $00B4                     ; Store stat 3
    
    LDA.L DATA8_07EE88,X            ; Stat bonus 4
    JSR.W ConvertStatBonus
    STA.W $00B3                     ; Store stat 4
    
    ; Render equipment info to screen
    LDX.W #$A433                    ; Graphics data pointer
    STX.B $17                       ; Store pointer
    LDA.B #$03                      ; Bank $03
    STA.B $19                       ; Store bank
    JSL.L CODE_009D6B               ; Call rendering routine
    
    REP #$30                        ; 16-bit mode
    LDA.B $15                       ; Get result
    PLX                             ; Restore X
    PLD                             ; Restore direct page
    PLP                             ; Restore status
    RTL

; ============================================================================
; Convert Stat Bonus to Display Value
; ============================================================================
; Address: $0C8071 (Original: CODE_0C8071)
; Converts equipment stat bonus to display format
; Input: A = stat value
; Output: A = display code (0=none, 1=normal, 2=enhanced)
; ============================================================================
ConvertStatBonus:
    BEQ .noBonus                    ; If 0, no bonus
    JSL.L CODE_009776               ; Check stat type/modifier
    BEQ .normalBonus                ; If zero result, normal bonus
    LDA.B #$02                      ; Enhanced bonus indicator
    BRA .done
    
.normalBonus:
    LDA.B #$01                      ; Normal bonus indicator
    
.noBonus:
.done:
    RTS

; ============================================================================
; Menu System Initialization
; ============================================================================
; Address: $0C8080 (Original: CODE_0C8080)
; Called during boot to initialize the menu/status screen system
; This sets up the display mode, clears flags, and prepares UI
; ============================================================================
MenuSystemInit:
    ; Initialize base system
    JSL.L CODE_00825C               ; Hardware initialization
    
    ; Clear save data flag
    LDA.W #$0000
    STA.L $7E3665                   ; Clear save loaded flag
    
    ; Set direct page to PPU registers
    LDA.W #$2100
    TCD                             ; Direct page = $2100 (PPU start)
    
    SEP #$20                        ; 8-bit mode
    
    ; Clear menu flags
    STZ.W $0111                     ; Clear general flags
    STZ.W $00D2                     ; Clear DMA flags
    STZ.W $00D4                     ; Clear transfer flags
    
    ; Set initial flags
    LDA.B #$08                      ; Bit 3
    TSB.W $00D2                     ; Set in DMA flags
    LDA.B #$40                      ; Bit 6
    TSB.W $00D6                     ; Set in display flags
    
    ; Configure PPU for menu mode
    LDA.B #$62                      ; Object base = $6000, size = 16x16
    STA.B SNES_OBJSEL-$2100         ; $2101 = OBJ select
    
    LDA.B #$07                      ; Mode 7
    STA.B SNES_BGMODE-$2100         ; $2105 = BG mode
    
    LDA.B #$80                      ; Mode 7 settings
    STA.B SNES_M7SEL-$2100          ; $211A = Mode 7 select
    
    LDA.B #$11                      ; Enable BG1 and OBJ
    STA.B SNES_TM-$2100             ; $212C = Main screen layers
    
    ; Additional menu setup
    JSR.W CODE_0C8D7B               ; Load menu graphics
    
    ; Enable interrupts
    LDA.W $0112                     ; Get saved interrupt flags
    STA.W $4200                     ; $4200 = Enable NMI/IRQ
    CLI                             ; Clear interrupt disable
    
    ; Set brightness
    LDA.B #$0F                      ; Full brightness
    STA.W $00AA                     ; Store brightness value
    
    ; Clear menu state
    STZ.W $0110                     ; Clear menu state
    
    ; Initialize subsystems
    JSL.L CODE_00C795               ; Initialize palette system
    JSR.W CODE_0C8BAD               ; Load menu fonts
    JSR.W CODE_0C896F               ; Setup menu windows
    JSL.L WaitForVBlank             ; Wait for safe update
    
    ; Switch to standard BG mode
    LDA.B #$01                      ; Mode 1
    STA.B SNES_BGMODE-$2100         ; $2105 = BG mode
    
    ; Configure tilemap addresses
    LDA.B #$62                      ; BG1 tilemap at $6200
    STA.B SNES_BG1SC-$2100          ; $2107 = BG1 screen base
    
    LDA.B #$69                      ; BG2 tilemap at $6900
    STA.B SNES_BG2SC-$2100          ; $2108 = BG2 screen base
    
    LDA.B #$44                      ; BG1/BG2 CHR at $4000
    STA.B SNES_BG12NBA-$2100        ; $210B = BG1/2 character base
    
    LDA.B #$13                      ; Enable BG1, BG2, OBJ
    STA.B SNES_TM-$2100             ; $212C = Main screen layers
    
    ; Render initial menu
    JSR.W CODE_0C9037               ; Draw menu frame
    JSR.W CODE_0C8103               ; Load menu content
    
    ; Finalize initialization
    REP #$30                        ; 16-bit mode
    LDA.W #$0001
    STA.L $7E3665                   ; Set menu initialized flag
    
    JSL.L CODE_00C7B8               ; Final setup routine
    
    ; Disable interrupts temporarily
    SEI                             ; Set interrupt disable
    LDA.W #$0008                    ; Bit 3
    TRB.W $00D2                     ; Clear in DMA flags
    
    RTL                             ; Return

; ============================================================================
; Menu Content Loader
; ============================================================================
; Address: $0C8103 (Original: CODE_0C8103)
; Loads and displays menu content (character stats, items, etc)
; ============================================================================
LoadMenuContent:
    ; Setup callback for menu rendering
    LDA.B #$0C                      ; Bank $0C
    STA.W $005A                     ; Callback bank
    LDX.W #$90D7                    ; Callback address
    STX.W $0058                     ; Store callback pointer
    
    ; Request callback execution
    LDA.B #$40                      ; Bit 6 = callback pending
    TSB.W $00E2                     ; Set callback flag
    
    JSL.L WaitForVBlank             ; Wait for update
    
    ; Setup display mode 7
    LDA.B #$07                      ; Mode 7
    STA.B SNES_BGMODE-$2100         ; Set mode
    
    ; Load menu elements
    JSR.W CODE_0C87ED               ; Load character portraits
    JSR.W CODE_0C81DA               ; Load status values
    JSR.W CODE_0C88BE               ; Load equipment icons
    JSR.W CODE_0C8872               ; Load item list
    JSR.W CODE_0C87E9               ; Update display
    
    ; Clear display flag
    LDA.B #$40                      ; Bit 6
    TRB.W $00D6                     ; Clear display pending
    
    JSL.L WaitForVBlank             ; Final sync
    
    ; Return to mode 1
    LDA.B #$01                      ; Mode 1
    STA.B SNES_BGMODE-$2100         ; Set mode
    
    ; Reset BG1 scroll
    STZ.B SNES_BG1VOFS-$2100        ; Vertical scroll = 0
    STZ.B SNES_BG1VOFS-$2100        ; (write twice for 16-bit)
    
    ; Update menu elements
    JSR.W CODE_0C8767               ; Render menu text
    JSR.W CODE_0C8241               ; Update cursor
    
    RTS

; ============================================================================
; RAM Variables Used by Menu System
; ============================================================================
; $00AA - Screen brightness (0-15)
; $00B2-$00B5 - Equipment stat bonuses (4 bytes)
; $00D2 - DMA/menu flags byte 1
;   Bit 3: Menu DMA active
; $00D4 - DMA/menu flags byte 2
; $00D6 - Display update flags
;   Bit 6: Display update pending
; $00D8 - VBlank synchronization flag
;   Bit 6: VBlank occurred flag (set by NMI, cleared by WaitForVBlank)
; $00EF - Current equipment slot (0-4)
; $0110 - Menu state/mode
; $0111 - General menu flags
; $0112 - Saved interrupt enable flags
; $015F - Current equipment ID
; $0058-$005A - Callback pointer (address+bank)
; $00E2 - Callback pending flags
;   Bit 6: Execute callback
; $7E3665 - Menu system initialized flag
; ============================================================================

; ============================================================================
; Display Modes Used
; ============================================================================
; Mode 1: Standard gameplay, BG1+BG2+OBJ, 4-color layers
; Mode 7: Menu/status screens, rotation/scaling, special effects
;
; BG1 Tilemap: $6200 (in VRAM)
; BG2 Tilemap: $6900 (in VRAM)
; BG1/BG2 CHR: $4000 (in VRAM)
; OBJ Base: $6000 (in VRAM)
; ============================================================================

; ============================================================================
; Menu System Flow
; ============================================================================
; 1. MenuSystemInit called during boot
; 2. Sets up PPU registers for Mode 7 initially
; 3. Loads menu graphics and fonts
; 4. Switches to Mode 1 for standard display
; 5. Renders menu frame and content
; 6. LoadMenuContent displays character/item data
; 7. All updates synchronized with WaitForVBlank
; ============================================================================

; ============================================================================
; Key Insights
; ============================================================================
; - VBlank synchronization is critical - used everywhere
; - Menu system uses Mode 7 for special effects
; - Standard gameplay uses Mode 1 (4-color BGs)
; - Equipment data stored in 5-byte records
; - Stats converted to display codes (0/1/2)
; - Callback system for deferred rendering
; - Direct page set to $2100 for fast PPU access
; ============================================================================
