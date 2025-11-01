; ============================================================================
; FFMQ Menu System and VBlank Control Analysis
; ============================================================================
; Analyzed from Diztinguish disassembly bank_0C.asm
; Bank $0c ($0c8000-$0cffff) - Menu System, UI, and Display Control
;
; This file documents the menu system, VBlank synchronization, and
; display management routines used throughout the game.
; ============================================================================

; ============================================================================
; VBlank Wait Routine
; ============================================================================
; Address: $0c8000 (Original: CODE_0C8000)
; This is THE most called routine in the entire game!
; Every screen update must wait for vertical blank to avoid visual glitches
; ============================================================================
WaitForVBlank:
	php                             ; Save processor status
	sep #$20                        ; 8-bit accumulator
	pha                             ; Save A register

; Clear VBlank flag
	lda.B #$40                      ; Bit 6 = VBlank flag
	trb.W $00d8                     ; Clear bit in flag byte

	.waitLoop:
; Poll VBlank flag
	lda.B #$40                      ; Check bit 6
	and.W $00d8                     ; Test flag byte
	beq .waitLoop                   ; Loop until VBlank occurs

; VBlank has occurred
	pla                             ; Restore A register
	plp                             ; Restore processor status
	rtl                             ; Return to caller

; VBlank flag at $00d8 bit 6 is set by NMI handler
; Every frame, the NMI sets this bit
; This routine clears it and waits for it to be set again
; Ensures all VRAM/PPU updates happen during safe period

; ============================================================================
; Equipment Window Display Routine
; ============================================================================
; Address: $0c8013 (Original: CODE_0C8013)
; Displays equipment information in battle/status screen
; Input: A = equipment slot index (0-4: weapon, armor, helm, shield, accessory)
; ============================================================================
DisplayEquipmentInfo:
	php                             ; Save status
	phd                             ; Save direct page
	pea.W $0000                     ; Set direct page to $0000
	pld
	rep #$30                        ; 16-bit mode
	phx                             ; Save X

; Calculate equipment data offset
	and.W #$00ff                    ; Mask to byte
	sta.B $64                       ; Store index
	asl a; index * 2
	asl a; index * 4
	adc.B $64                       ; index * 5
	tax                             ; X = index * 5 (offset into table)

	sep #$20                        ; 8-bit mode
	lda.B $64                       ; Get index again
	sta.W $00ef                     ; Store equipment slot

; Load equipment stats from data table
	lda.L DATA8_07ee84,x            ; Equipment ID
	sta.W $015f                     ; Store equipment ID

; Process stat bonuses (ATK/DEF/etc)
	lda.L DATA8_07ee85,x            ; Stat bonus 1
	jsr.W ConvertStatBonus          ; Convert to display format
	sta.W $00b5                     ; Store stat 1

	lda.L DATA8_07ee86,x            ; Stat bonus 2
	jsr.W ConvertStatBonus
	sta.W $00b2                     ; Store stat 2

	lda.L DATA8_07ee87,x            ; Stat bonus 3
	jsr.W ConvertStatBonus
	sta.W $00b4                     ; Store stat 3

	lda.L DATA8_07ee88,x            ; Stat bonus 4
	jsr.W ConvertStatBonus
	sta.W $00b3                     ; Store stat 4

; Render equipment info to screen
	ldx.W #$a433                    ; Graphics data pointer
	stx.B $17                       ; Store pointer
	lda.B #$03                      ; Bank $03
	sta.B $19                       ; Store bank
	jsl.L CODE_009D6B               ; Call rendering routine

	rep #$30                        ; 16-bit mode
	lda.B $15                       ; Get result
	plx                             ; Restore X
	pld                             ; Restore direct page
	plp                             ; Restore status
	rtl

; ============================================================================
; Convert Stat Bonus to Display Value
; ============================================================================
; Address: $0c8071 (Original: CODE_0C8071)
; Converts equipment stat bonus to display format
; Input: A = stat value
; Output: A = display code (0=none, 1=normal, 2=enhanced)
; ============================================================================
ConvertStatBonus:
	beq .noBonus                    ; If 0, no bonus
	jsl.L CODE_009776               ; Check stat type/modifier
	beq .normalBonus                ; If zero result, normal bonus
	lda.B #$02                      ; Enhanced bonus indicator
	bra .done

	.normalBonus:
	lda.B #$01                      ; Normal bonus indicator

	.noBonus:
	.done:
	rts

; ============================================================================
; Menu System Initialization
; ============================================================================
; Address: $0c8080 (Original: CODE_0C8080)
; Called during boot to initialize the menu/status screen system
; This sets up the display mode, clears flags, and prepares UI
; ============================================================================
MenuSystemInit:
; Initialize base system
	jsl.L CODE_00825C               ; Hardware initialization

; Clear save data flag
	lda.W #$0000
	sta.L $7e3665                   ; Clear save loaded flag

; Set direct page to PPU registers
	lda.W #$2100
	tcd                             ; Direct page = $2100 (PPU start)

	sep #$20                        ; 8-bit mode

; Clear menu flags
	stz.W $0111                     ; Clear general flags
	stz.W $00d2                     ; Clear DMA flags
	stz.W $00d4                     ; Clear transfer flags

; Set initial flags
	lda.B #$08                      ; Bit 3
	tsb.W $00d2                     ; Set in DMA flags
	lda.B #$40                      ; Bit 6
	tsb.W $00d6                     ; Set in display flags

; Configure PPU for menu mode
	lda.B #$62                      ; Object base = $6000, size = 16x16
	sta.B SNES_OBJSEL-$2100         ; $2101 = OBJ select

	lda.B #$07                      ; Mode 7
	sta.B SNES_BGMODE-$2100         ; $2105 = BG mode

	lda.B #$80                      ; Mode 7 settings
	sta.B SNES_M7SEL-$2100          ; $211a = Mode 7 select

	lda.B #$11                      ; Enable BG1 and OBJ
	sta.B SNES_TM-$2100             ; $212c = Main screen layers

; Additional menu setup
	jsr.W CODE_0C8D7B               ; Load menu graphics

; Enable interrupts
	lda.W $0112                     ; Get saved interrupt flags
	sta.W $4200                     ; $4200 = Enable NMI/IRQ
	cli                             ; Clear interrupt disable

; Set brightness
	lda.B #$0f                      ; Full brightness
	sta.W $00aa                     ; Store brightness value

; Clear menu state
	stz.W $0110                     ; Clear menu state

; Initialize subsystems
	jsl.L CODE_00C795               ; Initialize palette system
	jsr.W CODE_0C8BAD               ; Load menu fonts
	jsr.W CODE_0C896F               ; Setup menu windows
	jsl.L WaitForVBlank             ; Wait for safe update

; Switch to standard BG mode
	lda.B #$01                      ; Mode 1
	sta.B SNES_BGMODE-$2100         ; $2105 = BG mode

; Configure tilemap addresses
	lda.B #$62                      ; BG1 tilemap at $6200
	sta.B SNES_BG1SC-$2100          ; $2107 = BG1 screen base

	lda.B #$69                      ; BG2 tilemap at $6900
	sta.B SNES_BG2SC-$2100          ; $2108 = BG2 screen base

	lda.B #$44                      ; BG1/BG2 CHR at $4000
	sta.B SNES_BG12NBA-$2100        ; $210b = BG1/2 character base

	lda.B #$13                      ; Enable BG1, BG2, OBJ
	sta.B SNES_TM-$2100             ; $212c = Main screen layers

; Render initial menu
	jsr.W CODE_0C9037               ; Draw menu frame
	jsr.W CODE_0C8103               ; Load menu content

; Finalize initialization
	rep #$30                        ; 16-bit mode
	lda.W #$0001
	sta.L $7e3665                   ; Set menu initialized flag

	jsl.L CODE_00C7B8               ; Final setup routine

; Disable interrupts temporarily
	sei                             ; Set interrupt disable
	lda.W #$0008                    ; Bit 3
	trb.W $00d2                     ; Clear in DMA flags

	rtl                             ; Return

; ============================================================================
; Menu Content Loader
; ============================================================================
; Address: $0c8103 (Original: CODE_0C8103)
; Loads and displays menu content (character stats, items, etc)
; ============================================================================
LoadMenuContent:
; Setup callback for menu rendering
	lda.B #$0c                      ; Bank $0c
	sta.W $005a                     ; Callback bank
	ldx.W #$90d7                    ; Callback address
	stx.W $0058                     ; Store callback pointer

; Request callback execution
	lda.B #$40                      ; Bit 6 = callback pending
	tsb.W $00e2                     ; Set callback flag

	jsl.L WaitForVBlank             ; Wait for update

; Setup display mode 7
	lda.B #$07                      ; Mode 7
	sta.B SNES_BGMODE-$2100         ; Set mode

; Load menu elements
	jsr.W CODE_0C87ED               ; Load character portraits
	jsr.W CODE_0C81DA               ; Load status values
	jsr.W CODE_0C88BE               ; Load equipment icons
	jsr.W CODE_0C8872               ; Load item list
	jsr.W CODE_0C87E9               ; Update display

; Clear display flag
	lda.B #$40                      ; Bit 6
	trb.W $00d6                     ; Clear display pending

	jsl.L WaitForVBlank             ; Final sync

; Return to mode 1
	lda.B #$01                      ; Mode 1
	sta.B SNES_BGMODE-$2100         ; Set mode

; Reset BG1 scroll
	stz.B SNES_BG1VOFS-$2100        ; Vertical scroll = 0
	stz.B SNES_BG1VOFS-$2100        ; (write twice for 16-bit)

; Update menu elements
	jsr.W CODE_0C8767               ; Render menu text
	jsr.W CODE_0C8241               ; Update cursor

	rts

; ============================================================================
; RAM Variables Used by Menu System
; ============================================================================
; $00aa - Screen brightness (0-15)
; $00b2-$00b5 - Equipment stat bonuses (4 bytes)
; $00d2 - DMA/menu flags byte 1
;   Bit 3: Menu DMA active
; $00d4 - DMA/menu flags byte 2
; $00d6 - Display update flags
;   Bit 6: Display update pending
; $00d8 - VBlank synchronization flag
;   Bit 6: VBlank occurred flag (set by NMI, cleared by WaitForVBlank)
; $00ef - Current equipment slot (0-4)
; $0110 - Menu state/mode
; $0111 - General menu flags
; $0112 - Saved interrupt enable flags
; $015f - Current equipment ID
; $0058-$005a - Callback pointer (address+bank)
; $00e2 - Callback pending flags
;   Bit 6: Execute callback
; $7e3665 - Menu system initialized flag
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
