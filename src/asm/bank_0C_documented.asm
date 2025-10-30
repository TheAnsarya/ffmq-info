; ==============================================================================
; Bank $0C - Display and Graphics Management
; ==============================================================================
; This bank contains executable code for screen management, graphics transfers,
; PPU (Picture Processing Unit) control, and visual effects.
;
; Memory Range: $0C8000-$0CFFFF (32 KB)
;
; Major Sections:
; - VBLANK synchronization routines
; - DMA transfer management
; - Screen mode setup
; - Palette loading
; - Background layer management
; - HDMA (Horizontal DMA) effects
;
; Key Routines:
; - CODE_0C8000: VBLANK wait routine
; - CODE_0C8013: Character/monster stat display
; - CODE_0C8080: Screen initialization
;
; Related Files:
; - Bank $0B: Battle graphics routines
; - Bank $09/$0A: Graphics data
; ==============================================================================

	ORG $0C8000

; ==============================================================================
; VBLANK Wait Routine
; ==============================================================================
; Waits for VBLANK (vertical blanking interval) before proceeding.
; Critical for safe PPU access - prevents screen tearing.
; See: https://wiki.superfamicom.org/vblank-and-nmi
; ==============================================================================

CODE_0C8000:
	PHP										;0C8000	; Save processor status
	SEP #$20								;0C8001	; 8-bit accumulator
	PHA										;0C8003	; Save accumulator
	LDA.B #$40								;0C8004	; VBLANK flag bit
	TRB.W $00D8								;0C8006	; Test and reset VBLANK flag

CODE_0C8009:
	LDA.B #$40								;0C8009	; VBLANK flag bit
	AND.W $00D8								;0C800B	; Test VBLANK flag
	BEQ CODE_0C8009							;0C800E	; Loop until VBLANK starts
	PLA										;0C8010	; Restore accumulator
	PLP										;0C8011	; Restore processor status
	RTL										;0C8012	; Return

; ==============================================================================
; Character/Monster Stat Display Routine
; ==============================================================================
; Displays character or monster statistics on screen.
; Input: Accumulator = Character/monster index
; Uses stat lookup tables at $07EE84+
; ==============================================================================

CODE_0C8013:
	PHP										;0C8013	; Save processor status
	PHD										;0C8014	; Save direct page
	PEA.W $0000								;0C8015	; Push $0000
	PLD										;0C8018	; Pull to direct page (set DP=$0000)
	REP #$30								;0C8019	; 16-bit mode
	PHX										;0C801B	; Save X
	AND.W #$00FF							;0C801C	; Mask to byte
	STA.B $64								;0C801F	; Store character index
	ASL A									;0C8021	; Multiply by 5
	ASL A									;0C8022	; (shift left)
	ADC.B $64								;0C8023	; Add original (×5 total)
	TAX										;0C8025	; Transfer to X
	SEP #$20								;0C8026	; 8-bit accumulator
	LDA.B $64								;0C8028	; Load character index
	STA.W $00EF								;0C802A	; Store to temp variable
	LDA.L DATA8_07EE84,X					;0C802D	; Load stat byte 0
	STA.W $015F								;0C8031	; Store to display buffer
	LDA.L DATA8_07EE85,X					;0C8034	; Load stat byte 1
	JSR.W CODE_0C8071						;0C8038	; Process stat value
	STA.W $00B5								;0C803B	; Store processed value
	LDA.L DATA8_07EE86,X					;0C803E	; Load stat byte 2
	JSR.W CODE_0C8071						;0C8042	; Process stat value
	STA.W $00B2								;0C8045	; Store processed value
	LDA.L DATA8_07EE87,X					;0C8048	; Load stat byte 3
	JSR.W CODE_0C8071						;0C804C	; Process stat value
	STA.W $00B4								;0C804F	; Store processed value
	LDA.L DATA8_07EE88,X					;0C8052	; Load stat byte 4
	JSR.W CODE_0C8071						;0C8056	; Process stat value
	STA.W $00B3								;0C8059	; Store processed value
	LDX.W #$A433							;0C805C	; Load display routine address
	STX.B $17								;0C805F	; Store to jump pointer
	LDA.B #$03								;0C8061	; Bank $03
	STA.B $19								;0C8063	; Store bank to jump pointer
	JSL.L CODE_009D6B						;0C8065	; Call display routine
	REP #$30								;0C8069	; 16-bit mode
	LDA.B $15								;0C806B	; Load return value
	PLX										;0C806D	; Restore X
	PLD										;0C806E	; Restore direct page
	PLP										;0C806F	; Restore processor status
	RTL										;0C8070	; Return

; ==============================================================================
; Stat Value Processing Subroutine
; ==============================================================================
; Processes stat values for display (checks flags, conditions).
; Input: Accumulator = Raw stat value
; Output: Accumulator = Processed value
; ==============================================================================

CODE_0C8071:
	BEQ CODE_0C807F							;0C8071	; Branch if zero
	JSL.L CODE_009776						;0C8073	; Check stat condition
	BEQ CODE_0C807D							;0C8077	; Branch if normal
	LDA.B #$02								;0C8079	; Stat modified flag
	BRA CODE_0C807F							;0C807B	; Continue

CODE_0C807D:
	LDA.B #$01								;0C807D	; Normal stat flag

CODE_0C807F:
	RTS										;0C807F	; Return

; ==============================================================================
; Screen Initialization Routine
; ==============================================================================
; Initializes PPU registers for screen display.
; Sets up background modes, object selection, and layer priorities.
; See: https://wiki.superfamicom.org/snes-initialization
; ==============================================================================

CODE_0C8080:
	JSL.L CODE_00825C						;0C8080	; Call initialization helper
	LDA.W #$0000							;0C8084	; Clear value
	STA.L $7E3665							;0C8087	; Clear WRAM variable
	LDA.W #$2100							;0C808B	; PPU register base address
	TCD										;0C808E	; Transfer to direct page
	SEP #$20								;0C808F	; 8-bit accumulator
	STZ.W $0111								;0C8091	; Clear NMI flag
	STZ.W $00D2								;0C8094	; Clear screen mode flag
	STZ.W $00D4								;0C8097	; Clear layer enable flag
	LDA.B #$08								;0C809A	; Mode 7 enable bit
	TSB.W $00D2								;0C809C	; Set mode 7 flag
	LDA.B #$40								;0C809F	; VBLANK enable bit
	TSB.W $00D6								;0C80A1	; Enable VBLANK NMI
	LDA.B #$62								;0C80A4	; Object config value
	STA.B SNES_OBJSEL-$2100					;0C80A6	; Set object selection ($2101)
	LDA.B #$07								;0C80A8	; Background mode 7
	STA.B SNES_BGMODE-$2100					;0C80AA	; Set BG mode ($2105)
	LDA.B #$80								;0C80AC	; Mode 7 settings
	STA.B SNES_M7SEL-$2100					;0C80AE	; Set Mode 7 select ($211A)
	LDA.B #$11								;0C80B0	; Layer enable mask
	STA.B SNES_TM-$2100						;0C80B2	; Set main screen layers ($212C)

; ==============================================================================
; [Additional Display Management Routines]
; ==============================================================================
; The remaining code includes:
; - Palette loading and fading
; - Background layer scrolling
; - DMA transfer setup and execution
; - HDMA effect configuration
; - Mode 7 matrix calculations
; - Window/masking effects
;
; Complete code available in original bank_0C.asm
; Total bank size: ~4,200 lines of display management code
; ==============================================================================

; [Remaining display code continues to $0CFFFF]
; See original bank_0C.asm for complete implementation

; ==============================================================================
; End of Bank $0C
; ==============================================================================
; Total size: 32 KB (complete bank)
; Primary content: Display/PPU management code
; Related banks: $0B (battle graphics), $09/$0A (graphics data)
;
; Key functions documented:
; - VBLANK synchronization
; - Character/monster stat display
; - Screen initialization
; - PPU register management
;
; Remaining work:
; - Complete disassembly of DMA routines
; - Document HDMA effects
; - Map all Mode 7 calculations
; - Document palette management
; ==============================================================================
; ==============================================================================
; BANK $0C CYCLE 1 - Screen Initialization & Graphics Management (Lines 100-500)
; ==============================================================================
; Continuation from address $0C80B2
; Major systems: Screen mode setup, VRAM initialization, palette DMA, window effects
; ==============================================================================

; [Continued from documented section ending at $0C80B2]

	STA.B SNES_TM-$2100						;0C80B2	; Set main screen layers ($212C) = $11 (BG1+Obj)
	JSR.W CODE_0C8D7B						;0C80B4	; Call graphics setup routine
	LDA.W $0112								;0C80B7	; Load NMI enable flags
	STA.W $4200								;0C80BA	; Set NMI/IRQ/Auto-Joypad ($4200)
	CLI										;0C80BD	; Enable interrupts
	LDA.B #$0F								;0C80BE	; Brightness = 15 (full)
	STA.W $00AA								;0C80C0	; Store brightness value
	STZ.W $0110								;0C80C3	; Clear screen state flag
	JSL.L CODE_00C795						;0C80C6	; Call main game loop handler
	JSR.W CODE_0C8BAD						;0C80CA	; Graphics state update
	JSR.W CODE_0C896F						;0C80CD	; Background layer setup
	JSL.L CODE_0C8000						;0C80D0	; Wait for VBLANK
	LDA.B #$01								;0C80D4	; BG mode 1
	STA.B SNES_BGMODE-$2100					;0C80D6	; Set background mode ($2105)
	LDA.B #$62								;0C80D8	; BG1 tilemap config
	STA.B SNES_BG1SC-$2100					;0C80DA	; BG1 screen config ($2107)
	LDA.B #$69								;0C80DC	; BG2 tilemap config
	STA.B SNES_BG2SC-$2100					;0C80DE	; BG2 screen config ($2108)
	LDA.B #$44								;0C80E0	; Character address config
	STA.B SNES_BG12NBA-$2100				;0C80E2	; BG1/BG2 char address ($210B)
	LDA.B #$13								;0C80E4	; Layer enable mask
	STA.B SNES_TM-$2100						;0C80E6	; Set main screen layers ($212C)
	JSR.W CODE_0C9037						;0C80E8	; Additional graphics setup
	JSR.W CODE_0C8103						;0C80EB	; Call main screen init
	REP #$30								;0C80EE	; 16-bit A/X/Y
	LDA.W #$0001							;0C80F0	; Screen initialized flag
	STA.L $7E3665							;0C80F3	; Set screen ready flag (WRAM)
	JSL.L CODE_00C7B8						;0C80F7	; Game state handler
	SEI										;0C80FB	; Disable interrupts
	LDA.W #$0008							;0C80FC	; VBLANK processing flag
	TRB.W $00D2								;0C80FF	; Reset VBLANK flag
	RTL										;0C8102	; Return

; ==============================================================================
; CODE_0C8103 - Main Screen Initialization Routine
; ==============================================================================
; Sets up Mode 7 screen, loads palettes, initializes display registers.
; Called during screen transitions and battle entry.
; ==============================================================================

CODE_0C8103:
	LDA.B #$0C								;0C8103	; Bank $0C
	STA.W $005A								;0C8105	; Set data bank
	LDX.W #$90D7							;0C8108	; Address of palette DMA code
	STX.W $0058								;0C810B	; Set DMA routine pointer
	LDA.B #$40								;0C810E	; VBLANK DMA flag
	TSB.W $00E2								;0C8110	; Set DMA pending flag
	JSL.L CODE_0C8000						;0C8113	; Wait for VBLANK
	LDA.B #$07								;0C8117	; Background mode 7
	STA.B SNES_BGMODE-$2100					;0C8119	; Set BG mode ($2105)
	JSR.W CODE_0C87ED						;0C811B	; Mode 7 matrix setup
	JSR.W CODE_0C81DA						;0C811E	; Palette load setup
	JSR.W CODE_0C88BE						;0C8121	; Additional graphics init
	JSR.W CODE_0C8872						;0C8124	; Background scrolling setup
	JSR.W CODE_0C87E9						;0C8127	; Finalize graphics state
	LDA.B #$40								;0C812A	; VBLANK flag
	TRB.W $00D6								;0C812C	; Clear VBLANK pending
	JSL.L CODE_0C8000						;0C812F	; Wait for VBLANK
	LDA.B #$01								;0C8133	; BG mode 1
	STA.B SNES_BGMODE-$2100					;0C8135	; Set BG mode ($2105)
	STZ.B SNES_BG1VOFS-$2100				;0C8137	; BG1 V-scroll = 0 ($210E)
	STZ.B SNES_BG1VOFS-$2100				;0C8139	; Write high byte
	JSR.W CODE_0C8767						;0C813B	; Graphics state finalize
	JSR.W CODE_0C8241						;0C813E	; Sprite/OAM setup
	RTS										;0C8141	; Return

; ==============================================================================
; CODE_0C8142 - Window Effect Configuration
; ==============================================================================
; Sets up color window registers for screen effects (fades, transitions).
; Configures SNES window masking system.
; ==============================================================================

CODE_0C8142:
	LDX.W #$4156							;0C8142	; Window config value 1
	STX.W $0E08								;0C8145	; Store window settings
	LDX.W #$5555							;0C8148	; Window config value 2
	STX.W $0E0A								;0C814B	; Additional window data
	LDX.W #$5500							;0C814E	; Window config value 3
	STX.W $0E0C								;0C8151	; Final window settings
	JMP.W CODE_0C8910						;0C8154	; Jump to window apply routine

; ==============================================================================
; CODE_0C8157 - VRAM Address Calculation Routine
; ==============================================================================
; Calculates VRAM addresses for tile placement.
; Adds offset $0804 to base addresses for proper tile positioning.
; ==============================================================================

CODE_0C8157:
	CLC										;0C8157	; Clear carry
	REP #$30								;0C8158	; 16-bit A/X/Y
	LDA.W $0C84								;0C815A	; Load VRAM base address 1
	ADC.W #$0804							;0C815D	; Add tile offset
	STA.W $0CC0								;0C8160	; Store calculated address
	LDA.W $0C88								;0C8163	; Load VRAM base address 2
	ADC.W #$0804							;0C8166	; Add tile offset
	STA.W $0CC4								;0C8169	; Store calculated address
	LDA.W $0C8C								;0C816C	; Load VRAM base address 3
	ADC.W #$0804							;0C816F	; Add tile offset
	STA.W $0CC8								;0C8172	; Store calculated address
	LDA.W $0C90								;0C8175	; Load VRAM base address 4
	ADC.W #$0C90							;0C8178	; Add tile offset
	STA.W $0CCC								;0C817B	; Store calculated address
	SEP #$20								;0C817E	; 8-bit accumulator
	LDA.B #$80								;0C8180	; VRAM increment mode (increment on $2119 write)
	JSL.L CODE_0C8000						;0C8182	; Wait for VBLANK
	STA.B SNES_VMAINC-$2100					;0C8186	; Set VRAM increment ($2115)
	LDA.B #$08								;0C8188	; Tile pattern value
	LDX.W #$6225							;0C818A	; VRAM address $6225
	JSR.W CODE_0C81A5						;0C818D	; Call VRAM fill routine
	LDA.B #$0C								;0C8190	; Tile pattern value
	LDX.W #$622A							;0C8192	; VRAM address $622A
	JSR.W CODE_0C81A5						;0C8195	; Call VRAM fill routine
	LDA.B #$14								;0C8198	; Tile pattern value
	LDX.W #$6234							;0C819A	; VRAM address $6234
	JSR.W CODE_0C81A5						;0C819D	; Call VRAM fill routine
	LDA.B #$10								;0C81A0	; Tile pattern value
	LDX.W #$6239							;0C81A2	; VRAM address $6239

; ==============================================================================
; CODE_0C81A5 - VRAM Pattern Fill Routine
; ==============================================================================
; Fills VRAM with sequential tile numbers for background patterns.
; Creates animated tile sequences (water, fire, etc.).
; Input: A = pattern start value, X = VRAM address
; ==============================================================================

CODE_0C81A5:
	XBA										;0C81A5	; Swap A/B registers
	LDA.B #$00								;0C81A6	; Clear low byte
	REP #$30								;0C81A8	; 16-bit A/X/Y

CODE_0C81AA:									; Loop: Fill VRAM pattern
	STX.B SNES_VMADDL-$2100					;0C81AA	; Set VRAM address ($2116)
	STA.B SNES_VMDATAL-$2100				;0C81AC	; Write tile number ($2118)
	INC A									;0C81AE	; Next tile
	STA.B SNES_VMDATAL-$2100				;0C81AF	; Write tile number
	INC A									;0C81B1	; Next tile
	STA.B SNES_VMDATAL-$2100				;0C81B2	; Write tile number
	TAY										;0C81B4	; Save tile counter to Y
	TXA										;0C81B5	; Load VRAM address
	ADC.W #$0020							;0C81B6	; Move to next row (+32 tiles)
	TAX										;0C81B9	; Update VRAM address
	TYA										;0C81BA	; Restore tile counter
	ADC.W #$000E							;0C81BB	; Advance tile pattern
	BIT.W #$0040							;0C81BE	; Test completion bit
	BEQ CODE_0C81AA							;0C81C1	; Loop if not done
	SEP #$20								;0C81C3	; 8-bit accumulator
	RTS										;0C81C5	; Return

; ==============================================================================
; CODE_0C81C6 - Color Math Disable Routine
; ==============================================================================
; Disables color addition/subtraction effects.
; Resets window and color math registers.
; ==============================================================================

CODE_0C81C6:
	STZ.B SNES_CGSWSEL-$2100				;0C81C6	; Clear color window select ($2130)
	STZ.B SNES_CGADSUB-$2100				;0C81C8	; Clear color math ($2131)
	RTS										;0C81CA	; Return

; ==============================================================================
; CODE_0C81CB - Color Addition Effect Setup
; ==============================================================================
; Enables color addition for screen brightness/darkness effects.
; Used for battle transitions, lightning, darkness, etc.
; ==============================================================================

CODE_0C81CB:
	LDX.W #$7002							;0C81CB	; Color window config
	STX.B SNES_CGSWSEL-$2100				;0C81CE	; Set color window ($2130-$2131)
	LDA.B #$E0								;0C81D0	; Fixed color data (brightness)
	STA.B SNES_COLDATA-$2100				;0C81D2	; Set fixed color value ($2132)
	LDX.W #$0110							;0C81D4	; Layer enable mask
	STX.B SNES_TM-$2100						;0C81D7	; Set main/sub screen layers ($212C-$212D)
	RTS										;0C81D9	; Return

; ==============================================================================
; CODE_0C81DA - Palette DMA Setup Routine
; ==============================================================================
; Prepares palette data for DMA transfer during VBLANK.
; Sets up indirect DMA from Bank $0C address $81EF.
; ==============================================================================

CODE_0C81DA:
	LDA.B #$0C								;0C81DA	; Bank $0C
	STA.W $005A								;0C81DC	; Set DMA source bank
	LDX.W #$81EF							;0C81DF	; Palette DMA routine address
	STX.W $0058								;0C81E2	; Set DMA routine pointer
	LDA.B #$40								;0C81E5	; VBLANK DMA flag
	TSB.W $00E2								;0C81E7	; Set DMA pending flag
	JSL.L CODE_0C8000						;0C81EA	; Wait for VBLANK
	RTS										;0C81EE	; Return

; ==============================================================================
; Palette DMA Transfer Code (Embedded at $0C81EF)
; ==============================================================================
; Direct palette load routine executed during VBLANK.
; Transfers 16-byte palette chunks from Bank $07 to CGRAM.
; ==============================================================================

; [Palette DMA routine starts here]
	LDX.W #$2200							;0C81EF	; DMA params: A→B, increment
	STX.B SNES_DMA0PARAM-$4300				;0C81F2	; DMA0 params ($4300)
	LDA.B #$07								;0C81F4	; Source bank = Bank $07 (palette data)
	STA.B SNES_DMA0ADDRH-$4300				;0C81F6	; DMA0 source bank ($4304)
	LDA.B #$10								;0C81F8	; Starting palette index = $10
	LDY.W #$D974							;0C81FA	; Source address $07:D974
	JSR.W CODE_0C8224						;0C81FD	; DMA 16 bytes to CGRAM
	LDY.W #$D934							;0C8200	; Source address $07:D934
	JSR.W CODE_0C8224						;0C8203	; DMA 16 bytes
	JSR.W CODE_0C8224						;0C8206	; DMA 16 bytes (auto-increment)
	JSR.W CODE_0C8224						;0C8209	; DMA 16 bytes
	JSR.W CODE_0C8224						;0C820C	; DMA 16 bytes
	LDA.B #$B0								;0C820F	; Palette index = $B0
	JSR.W CODE_0C8224						;0C8211	; DMA 16 bytes
	LDY.W #$D934							;0C8214	; Reset source to $07:D934
	JSR.W CODE_0C8224						;0C8217	; DMA 16 bytes
	JSR.W CODE_0C8224						;0C821A	; DMA 16 bytes
	JSR.W CODE_0C8224						;0C821D	; DMA 16 bytes
	JSR.W CODE_0C8224						;0C8220	; DMA 16 bytes
	RTL										;0C8223	; Return from palette DMA

; ==============================================================================
; CODE_0C8224 - Single Palette DMA Transfer (16 bytes)
; ==============================================================================
; Transfers 16 bytes of palette data to CGRAM via DMA.
; Input: A = CGRAM address, Y = source address (Bank $07)
; Output: A += $10, Y += $10 (auto-incremented for next call)
; ==============================================================================

CODE_0C8224:
	PHA										;0C8224	; Save CGRAM address
	STA.W SNES_CGADD						;0C8225	; Set CGRAM address ($2121)
	STY.B SNES_DMA0ADDRL-$4300				;0C8228	; DMA0 source address ($4302)
	LDX.W #$0010							;0C822A	; Transfer size = 16 bytes
	STX.B SNES_DMA0CNTL-$4300				;0C822D	; DMA0 byte count ($4305)
	LDA.B #$01								;0C822F	; Enable DMA channel 0
	STA.W SNES_MDMAEN						;0C8231	; Start DMA ($420B)
	REP #$30								;0C8234	; 16-bit A/X/Y
	TYA										;0C8236	; Load source address
	ADC.W #$0010							;0C8237	; Advance +16 bytes
	TAY										;0C823A	; Update source address
	SEP #$20								;0C823B	; 8-bit accumulator
	PLA										;0C823D	; Restore CGRAM address
	ADC.B #$10								;0C823E	; Advance +16 colors
	RTS										;0C8240	; Return

; ==============================================================================
; CODE_0C8241 - OAM/Sprite Initialization Routine
; ==============================================================================
; Copies sprite configuration data to OAM buffer.
; Uses MVN (block move) for fast 9-byte transfer.
; ==============================================================================

CODE_0C8241:
	REP #$30								;0C8241	; 16-bit A/X/Y
	LDX.W #$8667							;0C8243	; Source address $0C:8667
	LDY.W #$0202							;0C8246	; Destination address $00:0202
	LDA.W #$0009							;0C8249	; Transfer 10 bytes (9+1 for MVN)
	MVN $0C,$0C								;0C824C	; Block move within bank $0C
	SEP #$20								;0C824F	; 8-bit accumulator
	STZ.W $0160								;0C8251	; Clear sprite state flag
	STZ.W $0201								;0C8254	; Clear OAM control byte
	LDX.W #$8671							;0C8257	; Effect script address

; ==============================================================================
; CODE_0C825A - Visual Effect Script Interpreter
; ==============================================================================
; Interprets bytecode commands for screen effects (fades, flashes, transitions).
; Commands: 00=wait, 01=fade step, 02=color cycle, 03=palette load, etc.
; ==============================================================================

CODE_0C825A:
	LDA.W $0000,X							;0C825A	; Load effect command byte
	INX										;0C825D	; Advance script pointer
	CMP.B #$01								;0C825E	; Command < 01?
	BCC CODE_0C8297							;0C8260	; Branch to wait routine
	BEQ CODE_0C8292							;0C8262	; Command = 01: Single frame delay
	CMP.B #$03								;0C8264	; Command < 03?
	BCC CODE_0C8288							;0C8266	; Branch to color cycle
	BEQ CODE_0C82A0							;0C8268	; Command = 03: Palette operation
	CMP.B #$05								;0C826A	; Command = 05?
	BEQ CODE_0C82A3							;0C826C	; Branch to special effect
	BCS CODE_0C82A6							;0C826E	; Command >= 06: Complex operations
	LDY.W #$0004							;0C8270	; Loop count = 4

; Color flash effect loop (command 04)
CODE_0C8273:
	PHY										;0C8273	; Save loop counter
	LDA.B #$3F								;0C8274	; Fixed color = white ($3F)
	STA.B SNES_COLDATA-$2100				;0C8276	; Set color addition ($2132)
	JSR.W CODE_0C85DB						;0C8278	; Wait one frame
	LDA.B #$E0								;0C827B	; Fixed color = dark ($E0)
	STA.B SNES_COLDATA-$2100				;0C827D	; Set color subtraction
	JSR.W CODE_0C85DB						;0C827F	; Wait one frame
	PLY										;0C8282	; Restore loop counter
	DEY										;0C8283	; Decrement
	BNE CODE_0C8273							;0C8284	; Loop 4 times (4 flashes)
	BRA CODE_0C825A							;0C8286	; Continue script

; Color cycle effect (command 02)
CODE_0C8288:
	LDA.B #$3B								;0C8288	; Cycle duration = 59 frames

CODE_0C828A:
	PHA										;0C828A	; Save counter
	JSR.W CODE_0C85DB						;0C828B	; Wait one frame
	PLA										;0C828E	; Restore counter
	DEC A									;0C828F	; Decrement
	BNE CODE_0C828A							;0C8290	; Loop until counter = 0

; Single frame delay (command 01)
CODE_0C8292:
	JSR.W CODE_0C85DB						;0C8292	; Wait one frame
	BRA CODE_0C825A							;0C8295	; Continue script

; Wait until condition met (command 00)
CODE_0C8297:
	JSR.W CODE_0C85DB						;0C8297	; Wait one frame
	LDA.W $0C82								;0C829A	; Load condition flag
	BNE CODE_0C8297							;0C829D	; Loop until flag clears
	RTS										;0C829F	; Return from effect script

; Palette load command (command 03)
CODE_0C82A0:
	JMP.W CODE_0C8460						;0C82A0	; Jump to palette loader

; Special effect command (command 05)
CODE_0C82A3:
	JMP.W CODE_0C8421						;0C82A3	; Jump to special effect handler

; ==============================================================================
; Complex Command Handler (Commands $06-$FF)
; ==============================================================================
; Decodes complex commands with parameters.
; Format: [CMD:5bits][PARAM:3bits] for advanced visual effects.
; ==============================================================================

CODE_0C82A6:
	PHA										;0C82A6	; Save command byte
	AND.B #$07								;0C82A7	; Extract parameter (bits 0-2)
	STA.W $015F								;0C82A9	; Store parameter
	PLA										;0C82AC	; Restore command byte
	AND.B #$F8								;0C82AD	; Extract command (bits 3-7)
	CMP.B #$40								;0C82AF	; Command < $40?
	BCC CODE_0C8302							;0C82B1	; Branch to low-range handler
	CMP.B #$80								;0C82B3	; Command < $80?
	BCC CODE_0C82F7							;0C82B5	; Branch to mid-range handler
	CMP.B #$C0								;0C82B7	; Command < $C0?
	BCC CODE_0C82CF							;0C82B9	; Branch to high-range handler
	SBC.B #$40								;0C82BB	; Normalize command ($C0+ → $80+)
	STA.W $0161								;0C82BD	; Store normalized command
	REP #$30								;0C82C0	; 16-bit A/X/Y
	LDA.W $015F								;0C82C2	; Load parameter
	ASL A									;0C82C5	; *2
	ASL A									;0C82C6	; *4 (table offset)
	ADC.W #$0CBC							;0C82C7	; Add table base address
	JSR.W CODE_0C83CB						;0C82CA	; Execute table entry
	BRA CODE_0C825A							;0C82CD	; Continue script

; High-range command handler ($80-$BF)
CODE_0C82CF:
	STA.W $0161								;0C82CF	; Store command
	REP #$30								;0C82D2	; 16-bit A/X/Y
	LDA.W $015F								;0C82D4	; Load parameter
	ASL A									;0C82D7	; *2
	ASL A									;0C82D8	; *4
	PHA										;0C82D9	; Save offset
	ADC.W #$0C80							;0C82DA	; Add table base 1
	JSR.W CODE_0C83CB						;0C82DD	; Execute table entry 1
	REP #$30								;0C82E0	; 16-bit A/X/Y
	PLA										;0C82E2	; Restore offset
	ASL A									;0C82E3	; *2 again (*8 total)
	ADC.W #$0C94							;0C82E4	; Add table base 2
	JSR.W CODE_0C83CB						;0C82E7	; Execute table entry 2
	REP #$30								;0C82EA	; 16-bit A/X/Y
	TYA										;0C82EC	; Load Y (result from previous call)
	CLC										;0C82ED	; Clear carry
	ADC.W #$0004							;0C82EE	; Add 4
	JSR.W CODE_0C83CB						;0C82F1	; Execute table entry 3
	JMP.W CODE_0C825A						;0C82F4	; Continue script

; Mid-range command handler ($40-$7F)
CODE_0C82F7:
	SBC.B #$30								;0C82F7	; Normalize command ($40+ → $10+)
	LSR A									;0C82F9	; /2
	LSR A									;0C82FA	; /4
	LSR A									;0C82FB	; /8
	STA.W $0200								;0C82FC	; Store effect type
	JMP.W CODE_0C825A						;0C82FF	; Continue script

; Low-range command handler ($08-$3F)
CODE_0C8302:
	CMP.B #$08								;0C8302	; Command = $08?
	BNE CODE_0C837D							;0C8304	; Branch if not $08
	LDA.W $015F								;0C8306	; Load parameter
	BNE CODE_0C831E							;0C8309	; Branch if parameter != 0
	REP #$30								;0C830B	; 16-bit A/X/Y
	LDA.W #$3C03							;0C830D	; Bit mask
	TRB.W $0E08								;0C8310	; Clear bits in window config
	LDA.W #$0002							;0C8313	; New value
	TSB.W $0E08								;0C8316	; Set bits in window config
	SEP #$20								;0C8319	; 8-bit accumulator
	JMP.W CODE_0C825A						;0C831B	; Continue script

; Parameter-based table lookup
CODE_0C831E:
	REP #$30								;0C831E	; 16-bit A/X/Y
	LDA.W $015F								;0C8320	; Load parameter
	ASL A									;0C8323	; *2
	ASL A									;0C8324	; *4
	PHA										;0C8325	; Save offset
	ADC.W #$0C80							;0C8326	; Add table base 1
	TAY										;0C8329	; Use as index
	LDA.W $0C80								;0C832A	; Load value from table
	STA.W $0000,Y							;0C832D	; Store to destination
	PLA										;0C8330	; Restore offset
	ASL A									;0C8331	; *2 (*8 total)
	ADC.W #$0C94							;0C8332	; Add table base 2
	TAY										;0C8335	; Use as index
	LDA.W $0C94								;0C8336	; Load first value
	STA.W $0000,Y							;0C8339	; Store to destination
	LDA.W $0C98								;0C833C	; Load second value
	STA.W $0004,Y							;0C833F	; Store to destination+4
	LDY.W $015F								;0C8342	; Load parameter
	LDA.W #$0003							;0C8345	; Bit shift value = 3

; Bit shift loop
CODE_0C8348:
	ASL A									;0C8348	; Shift left *2
	ASL A									;0C8349	; Shift left *2 (total *4)
	DEY										;0C834A	; Decrement parameter
	BNE CODE_0C8348							;0C834B	; Loop until parameter = 0
	PHA										;0C834D	; Save shifted value
	TRB.W $0E08								;0C834E	; Clear bits in window config
	AND.W #$AAAA							;0C8351	; Mask pattern ($AAAA)
	TSB.W $0E08								;0C8354	; Set masked bits
	PLA										;0C8357	; Restore shifted value
	LDY.W $015F								;0C8358	; Reload parameter
	LSR A									;0C835B	; Shift right /2
	LSR A									;0C835C	; Shift right /2 (total /4)

; Second bit shift loop
CODE_0C835D:
	ASL A									;0C835D	; Shift left *2
	ASL A									;0C835E	; Shift left *2 (total *4)
	DEY										;0C835F	; Decrement parameter
	BNE CODE_0C835D							;0C8360	; Loop until parameter = 0
	LSR A									;0C8362	; Shift right /2
	LSR A									;0C8363	; Shift right /2 (total /4)
	PHA										;0C8364	; Save value
	LSR A									;0C8365	; Shift right /2
	LSR A									;0C8366	; Shift right /2
	ORA.B $01,S								;0C8367	; OR with stack value
	TRB.W $0E0A								;0C8369	; Clear bits in second window config
	CMP.W #$0003							;0C836C	; Compare to 3
	BNE CODE_0C8377							;0C836F	; Branch if not equal
	LDA.W #$C000							;0C8371	; Top bits mask
	TRB.W $0E08								;0C8374	; Clear top bits in first window config

CODE_0C8377:
	PLA										;0C8377	; Clean up stack
	SEP #$20								;0C8378	; 8-bit accumulator
	JMP.W CODE_0C825A						;0C837A	; Continue script

; ==============================================================================
; Complex Screen Effect Setup (Command $08+)
; ==============================================================================
; Initializes multi-stage screen effects combining VRAM updates,
; palette fades, and color window operations.
; ==============================================================================

CODE_0C837D:
	PHX										;0C837D	; Save script pointer
	JSR.W CODE_0C8157						;0C837E	; Calculate VRAM addresses
	JSR.W CODE_0C8142						;0C8381	; Setup window effects
	JSR.W CODE_0C83B1						;0C8384	; Execute effect stage 1
	JSR.W CODE_0C83B1						;0C8387	; Execute effect stage 2
	JSR.W CODE_0C83B1						;0C838A	; Execute effect stage 3
	LDA.B #$10								;0C838D	; Loop counter = 16 frames

CODE_0C838F:
	PHA										;0C838F	; Save counter
	JSR.W CODE_0C81CB						;0C8390	; Enable color addition
	JSR.W CODE_0C85DB						;0C8393	; Wait one frame
	JSR.W CODE_0C85DB						;0C8396	; Wait one frame

; [Additional effect code continues...]

; ==============================================================================
; End of Bank $0C Cycle 1
; ==============================================================================
; Lines documented: 400 source lines (100-500)
; Address range: $0C80B2-$0C8399 (partial)
; Major systems: Screen init, VRAM management, palette DMA, effect scripts
; ==============================================================================
; ==============================================================================
; BANK $0C CYCLE 2 - Graphics Effects & Screen Transitions (Lines 500-900)
; ==============================================================================
; Address range: $0C8396-$0C8813
; Systems: Screen effects, window animations, visual transitions, Mode 7 setup
; ==============================================================================

; [Continued from Cycle 1 ending at $0C8399]

	JSR.W CODE_0C85DB						;0C8396	; Wait one frame (VBLANK sync)
	LDA.B #$11								;0C8399	; Layer enable mask
	STA.B SNES_TM-$2100						;0C839B	; Set main screen layers ($212C)
	JSR.W CODE_0C81C6						;0C839D	; Disable color math
	JSR.W CODE_0C85DB						;0C83A0	; Wait one frame
	JSR.W CODE_0C85DB						;0C83A3	; Wait one frame
	PLA										;0C83A6	; Restore loop counter
	DEC A									;0C83A7	; Decrement
	BNE CODE_0C838F							;0C83A8	; Loop if not done (16 frames total)
	JSR.W CODE_0C81CB						;0C83AA	; Re-enable color addition
	PLX										;0C83AD	; Restore script pointer
	JMP.W CODE_0C825A						;0C83AE	; Continue effect script

; ==============================================================================
; CODE_0C83B1 - Flash Effect Subroutine
; ==============================================================================
; Creates white flash effect (bright → normal → bright sequence).
; Used for lightning, magic spells, critical hits.
; ==============================================================================

CODE_0C83B1:
	JSR.W CODE_0C81CB						;0C83B1	; Enable color addition
	LDA.B #$11								;0C83B4	; Layer enable mask
	STA.B SNES_TM-$2100						;0C83B6	; Set layers ($212C)
	LDA.B #$3F								;0C83B8	; Fixed color = white ($3F)
	STA.B SNES_COLDATA-$2100				;0C83BA	; Set color addition ($2132)
	JSR.W CODE_0C85DB						;0C83BC	; Wait one frame (flash)
	JSR.W CODE_0C81C6						;0C83BF	; Disable color math
	JSR.W CODE_0C85DB						;0C83C2	; Wait one frame
	JSR.W CODE_0C85DB						;0C83C5	; Wait one frame
	JMP.W CODE_0C85DB						;0C83C8	; Wait one frame and return

; ==============================================================================
; CODE_0C83CB - Table-Based Effect Executor
; ==============================================================================
; Executes visual effects from data tables.
; Modifies screen position/color values based on command and parameter.
; Input: A = table offset, $0161 = command type, $0200 = adjustment value
; ==============================================================================

CODE_0C83CB:
	PHX										;0C83CB	; Save X register
	TAX										;0C83CC	; Use A as table index
	SEP #$20								;0C83CD	; 8-bit accumulator
	LDY.W $0161								;0C83CF	; Load command type
	CPY.W #$00B8							;0C83D2	; Command = $B8 (specific effect)?
	BEQ CODE_0C83DD							;0C83D5	; Branch if match
	CPY.W #$0089							;0C83D7	; Command >= $89?
	BCS UNREACH_0C83E8						;0C83DA	; Branch if high range
	SEC										;0C83DC	; Set carry for subtraction

CODE_0C83DD:
	LDA.W $0001,X							;0C83DD	; Load table value
	SBC.W $0200								;0C83E0	; Subtract adjustment
	STA.W $0001,X							;0C83E3	; Store result
	BRA CODE_0C83FB							;0C83E6	; Continue

UNREACH_0C83E8:
	db $C0,$98,$00,$90,$0E,$C0,$A9,$00,$B0,$09,$BD,$01,$00,$6D,$00,$02 ; Additional effect logic
	db $9D,$01,$00

CODE_0C83FB:
	CPY.W #$0088							;0C83FB	; Command < $88?
	BCC CODE_0C8410							;0C83FE	; Branch if low range
	db $C0,$99,$00,$B0,$0B,$BD,$00,$00,$6D,$00,$02,$9D,$00,$00,$80,$0E ; Effect processing

CODE_0C8410:
	CPY.W #$00A8							;0C8410	; Command < $A8?
	BCC CODE_0C841E							;0C8413	; Branch if not A8+
	db $BD,$00,$00,$ED,$00,$02,$9D,$00,$00 ; Additional effect

CODE_0C841E:
	TXY										;0C841E	; Transfer result to Y
	PLX										;0C841F	; Restore X
	RTS										;0C8420	; Return

; ==============================================================================
; CODE_0C8421 - Screen Scroll Effect
; ==============================================================================
; Animated scrolling effect for screen transitions.
; Scrolls window positions over 32 frames, then holds for 60 frames.
; ==============================================================================

CODE_0C8421:
	LDA.B #$20								;0C8421	; Loop counter = 32 frames

CODE_0C8423:
	PHA										;0C8423	; Save counter
	SEC										;0C8424	; Set carry for subtraction
	LDA.W $0CC1								;0C8425	; Load window position 1
	SBC.B #$04								;0C8428	; Scroll -4 pixels
	STA.W $0CC1								;0C842A	; Update position 1
	STA.W $0CC5								;0C842D	; Update position 2
	STA.W $0CC9								;0C8430	; Update position 3
	STA.W $0CCD								;0C8433	; Update position 4
	LDA.W $0CCC								;0C8436	; Load position 5
	SBC.B #$04								;0C8439	; Scroll -4 pixels
	STA.W $0CCC								;0C843B	; Update position 5
	LDA.W $0CC0								;0C843E	; Load position 6
	ADC.B #$03								;0C8441	; Scroll +3 pixels
	STA.W $0CC0								;0C8443	; Update position 6
	JSR.W CODE_0C85DB						;0C8446	; Wait one frame
	PLA										;0C8449	; Restore counter
	DEC A									;0C844A	; Decrement
	BNE CODE_0C8423							;0C844B	; Loop 32 times
	LDA.B #$3C								;0C844D	; Hold duration = 60 frames

CODE_0C844F:
	PHA										;0C844F	; Save counter
	JSR.W CODE_0C85DB						;0C8450	; Wait one frame
	PLA										;0C8453	; Restore counter
	DEC A									;0C8454	; Decrement
	BNE CODE_0C844F							;0C8455	; Loop 60 times
	STZ.W $0E0D								;0C8457	; Clear window state 1
	STZ.W $0E0E								;0C845A	; Clear window state 2
	JMP.W CODE_0C825A						;0C845D	; Continue script

; ==============================================================================
; CODE_0C8460 - Complex Palette Fade Sequence
; ==============================================================================
; Multi-stage palette fading effect using indirect function calls.
; Cycles through color transformations with precise timing.
; ==============================================================================

CODE_0C8460:
	PHX										;0C8460	; Save script pointer
	LDY.W #$8575							;0C8461	; Function pointer 1
	STY.W $0212								;0C8464	; Store function address
	LDX.W #$0000							;0C8467	; Clear X (parameter)
	LDY.W #$84CB							;0C846A	; Fade table address
	JSR.W CODE_0C849E						;0C846D	; Execute fade stage 1
	LDY.W #$84CB							;0C8470	; Fade table address
	JSR.W CODE_0C849E						;0C8473	; Execute fade stage 2
	LDY.W #$8520							;0C8476	; Different fade table
	JSR.W CODE_0C849E						;0C8479	; Execute fade stage 3
	LDY.W #$84CC							;0C847C	; Fade table address
	JSR.W CODE_0C849E						;0C847F	; Execute fade stage 4
	LDY.W #$84F6							;0C8482	; Fade table address
	JSR.W CODE_0C849E						;0C8485	; Execute fade stage 5
	STZ.W $0214								;0C8488	; Clear fade state
	LDY.W #$854A							;0C848B	; Function pointer 2
	STY.W $0212								;0C848E	; Update function address
	LDY.W #$84CB							;0C8491	; Final fade table
	JSR.W CODE_0C849E						;0C8494	; Execute final stage
	JSR.W CODE_0C85DB						;0C8497	; Wait one frame
	PLX										;0C849A	; Restore script pointer
	JMP.W CODE_0C825A						;0C849B	; Continue script

; ==============================================================================
; CODE_0C849E - Fade Stage Executor
; ==============================================================================
; Executes one stage of palette fade using function table.
; Input: Y = fade curve table address
; Uses indirect JSR through $0210 and $0212 function pointers.
; ==============================================================================

CODE_0C849E:
	STY.W $0210								;0C849E	; Store table address
	LDY.W #$85B3							;0C84A1	; Fade curve start

CODE_0C84A4:									; Loop through fade curve
	JSR.W ($0210,X)							;0C84A4	; Call effect function (indirect)
	SEC										;0C84A7	; Set carry
	LDA.W $0C81								;0C84A8	; Load base color value
	SBC.W $0000,Y							;0C84AB	; Subtract curve value
	JSR.W ($0212,X)							;0C84AE	; Call adjustment function (indirect)
	INY										;0C84B1	; Next curve entry
	CPY.W #$85DB							;0C84B2	; End of curve?
	BNE CODE_0C84A4							;0C84B5	; Loop if not done
	DEY										;0C84B7	; Back up one entry

CODE_0C84B8:									; Reverse fade loop
	DEY										;0C84B8	; Previous curve entry
	JSR.W ($0210,X)							;0C84B9	; Call effect function
	CLC										;0C84BC	; Clear carry
	LDA.W $0C81								;0C84BD	; Load base color
	ADC.W $0000,Y							;0C84C0	; Add curve value
	JSR.W ($0212,X)							;0C84C3	; Call adjustment function
	CPY.W #$85B2							;0C84C6	; Back at start?
	BNE CODE_0C84B8							;0C84C9	; Loop if not done
	RTS										;0C84CB	; Return

; [Fade function - adjusts window positions alternately]
	TYA										;0C84CC	; Transfer Y to A
	BIT.B #$01								;0C84CD	; Test bit 0 (odd/even)
	BEQ CODE_0C84F5							;0C84CF	; Skip if even frame
	DEC.W $0C88								;0C84D1	; Adjust position 1
	DEC.W $0CA4								;0C84D4	; Adjust position 2
	DEC.W $0CA8								;0C84D7	; Adjust position 3
	INC.W $0C90								;0C84DA	; Adjust position 4
	INC.W $0CB4								;0C84DD	; Adjust position 5
	INC.W $0CB8								;0C84E0	; Adjust position 6
	INC.W $0C84								;0C84E3	; Adjust position 7
	INC.W $0C9C								;0C84E6	; Adjust position 8
	INC.W $0CA0								;0C84E9	; Adjust position 9
	DEC.W $0C8C								;0C84EC	; Adjust position 10
	DEC.W $0CAC								;0C84EF	; Adjust position 11
	DEC.W $0CB0								;0C84F2	; Adjust position 12

CODE_0C84F5:
	RTS										;0C84F5	; Return

; [Fade function 2 - reverse direction adjustments]
	TYA										;0C84F6	; Transfer Y to A
	BIT.B #$01								;0C84F7	; Test bit 0
	BEQ CODE_0C851F							;0C84F9	; Skip if even
	INC.W $0C88								;0C84FB	; Adjust opposite direction
	INC.W $0CA4								;0C84FE	; Adjust position
	INC.W $0CA8								;0C8501	; Adjust position
	DEC.W $0C90								;0C8504	; Adjust position
	DEC.W $0CB4								;0C8507	; Adjust position
	DEC.W $0CB8								;0C850A	; Adjust position
	DEC.W $0C84								;0C850D	; Adjust position
	DEC.W $0C9C								;0C8510	; Adjust position
	DEC.W $0CA0								;0C8513	; Adjust position
	INC.W $0C8C								;0C8516	; Adjust position
	INC.W $0CAC								;0C8519	; Adjust position
	INC.W $0CB0								;0C851C	; Adjust position

CODE_0C851F:
	RTS										;0C851F	; Return

; [Fade function 3 - partial position adjustments]
	TYA										;0C8520	; Transfer Y
	BIT.B #$01								;0C8521	; Test bit 0
	BEQ CODE_0C8537							;0C8523	; Skip if even
	DEC.W $0C88								;0C8525	; Adjust subset of positions
	DEC.W $0CA4								;0C8528	; Adjust position
	DEC.W $0CA8								;0C852B	; Adjust position
	INC.W $0C90								;0C852E	; Adjust position
	INC.W $0CB4								;0C8531	; Adjust position
	INC.W $0CB8								;0C8534	; Adjust position

CODE_0C8537:
	DEC.W $0C84								;0C8537	; Adjust remaining positions
	DEC.W $0C9C								;0C853A	; Adjust position
	DEC.W $0CA0								;0C853D	; Adjust position
	INC.W $0C8C								;0C8540	; Adjust position
	INC.W $0CAC								;0C8543	; Adjust position
	INC.W $0CB0								;0C8546	; Adjust position
	RTS										;0C8549	; Return

; [Fade function 4 - complex bidirectional fade]
	LDA.W $0C81								;0C854A	; Load base value
	PHA										;0C854D	; Save to stack
	LDA.W $0214								;0C854E	; Load fade direction flag
	BCS CODE_0C8559							;0C8551	; Branch if carry set
	SEC										;0C8553	; Set carry
	SBC.W $0000,Y							;0C8554	; Subtract curve value
	BRA CODE_0C855D							;0C8557	; Continue

CODE_0C8559:
	CLC										;0C8559	; Clear carry
	ADC.W $0000,Y							;0C855A	; Add curve value

CODE_0C855D:
	STA.W $0214								;0C855D	; Store new fade value
	LSR A									;0C8560	; Divide by 2
	PHA										;0C8561	; Save to stack
	LDA.B $02,S								;0C8562	; Load original value
	SEC										;0C8564	; Set carry
	SBC.B $01,S								;0C8565	; Subtract half-fade value
	JSR.W CODE_0C8575						;0C8567	; Apply to screen
	PLA										;0C856A	; Clean up stack
	PLA										;0C856B	; Clean up stack
	PHY										;0C856C	; Save Y
	LDY.W #$0000							;0C856D	; Clear Y
	JSR.W CODE_0C8575						;0C8570	; Apply secondary effect
	PLY										;0C8573	; Restore Y
	RTS										;0C8574	; Return

; ==============================================================================
; CODE_0C8575 - Screen Color Value Updater
; ==============================================================================
; Updates multiple screen color/position registers with same value.
; Spreads value across 5 primary + 5 secondary position registers.
; Input: A = value to write
; ==============================================================================

CODE_0C8575:
	SEC										;0C8575	; Set carry
	STA.W $0C81								;0C8576	; Store to register 1
	STA.W $0C85								;0C8579	; Store to register 2
	STA.W $0C89								;0C857C	; Store to register 3
	STA.W $0C8D								;0C857F	; Store to register 4
	STA.W $0C91								;0C8582	; Store to register 5
	SBC.B #$10								;0C8585	; Subtract offset
	STA.W $0C95								;0C8587	; Store to secondary register 1
	STA.W $0C9D								;0C858A	; Store to secondary register 2
	STA.W $0CA5								;0C858D	; Store to secondary register 3
	STA.W $0CAD								;0C8590	; Store to secondary register 4
	STA.W $0CB5								;0C8593	; Store to secondary register 5
	ADC.B #$2F								;0C8596	; Add different offset
	STA.W $0C99								;0C8598	; Store to tertiary register 1
	STA.W $0CA1								;0C859B	; Store to tertiary register 2
	STA.W $0CA9								;0C859E	; Store to tertiary register 3
	STA.W $0CB1								;0C85A1	; Store to tertiary register 4
	STA.W $0CB9								;0C85A4	; Store to tertiary register 5
	TYA										;0C85A7	; Transfer Y to A
	BIT.B #$01								;0C85A8	; Test bit 0
	BEQ CODE_0C85B1							;0C85AA	; Skip if even
	PHY										;0C85AC	; Save Y
	JSR.W CODE_0C85DB						;0C85AD	; Wait one frame
	PLY										;0C85B0	; Restore Y

CODE_0C85B1:
	RTS										;0C85B1	; Return

; Fade curve data table (40 bytes)
	db $00,$04,$02,$01,$02,$01,$01,$01,$01,$00,$01,$01,$00,$01,$00,$01 ; Smooth fade curve
	db $01,$00,$01,$00,$01,$00,$00,$01,$00,$00,$01,$00,$00,$00,$01,$00 ; values (0-4 range)
	db $00,$00,$00,$01,$00,$00,$00,$00,$00 ; End of curve

; ==============================================================================
; CODE_0C85DB - Frame Wait & Sprite Animation Update
; ==============================================================================
; Primary VBLANK synchronization + sprite animation handler.
; Called hundreds of times per second - performance critical!
; Updates animated sprite tiles every 4 frames.
; ==============================================================================

CODE_0C85DB:
	PHK										;0C85DB	; Push data bank
	PLB										;0C85DC	; Set data bank = current bank
	PHX										;0C85DD	; Save X register
	LDA.W $0E97								;0C85DE	; Load animation timer
	AND.B #$04								;0C85E1	; Test bit 2 (every 4 frames)
	LSR A									;0C85E3	; Shift to bit 1
	ADC.B #$4C								;0C85E4	; Base tile number = $4C or $4E
	STA.W $0CC2								;0C85E6	; Update sprite tile 1
	STA.W $0CCA								;0C85E9	; Update sprite tile 2
	EOR.B #$02								;0C85EC	; Toggle between tiles ($4C↔$4E)
	STA.W $0CC6								;0C85EE	; Update sprite tile 3
	STA.W $0CCE								;0C85F1	; Update sprite tile 4
	REP #$30								;0C85F4	; 16-bit A/X/Y
	LDA.W #$0005							;0C85F6	; Loop counter = 5 sprites
	STA.W $020C								;0C85F9	; Store counter
	STZ.W $020E								;0C85FC	; Clear sprite index

CODE_0C85FF:									; Loop: Update each sprite
	LDA.W $020E								;0C85FF	; Load sprite index
	ASL A									;0C8602	; *2 (word offset)
	ADC.W #$0C80							;0C8603	; Add base address
	TAY										;0C8606	; Use as pointer
	LDX.W $020E								;0C8607	; Load sprite index
	LDA.W $0202,X							;0C860A	; Load animation frame
	INC A									;0C860D	; Next frame
	CMP.W #$000E							;0C860E	; Frame >= 14?
	BNE CODE_0C8616							;0C8611	; Branch if not
	LDA.W #$0000							;0C8613	; Wrap to frame 0

CODE_0C8616:
	STA.W $0202,X							;0C8616	; Store new frame number
	TAX										;0C8619	; Use frame as index
	SEP #$20								;0C861A	; 8-bit accumulator
	LDA.W DATA8_0C8659,X					;0C861C	; Load tile number from table
	STA.W $0002,Y							;0C861F	; Update sprite tile
	CMP.B #$44								;0C8622	; Tile = $44?
	PHP										;0C8624	; Save comparison result
	REP #$30								;0C8625	; 16-bit A/X/Y
	LDA.W $020E								;0C8627	; Load sprite index
	ASL A									;0C862A	; *2
	ASL A									;0C862B	; *4 (dword offset)
	ADC.W #$0C94							;0C862C	; Add base address
	TAY										;0C862F	; Use as pointer
	PLP										;0C8630	; Restore comparison
	BEQ CODE_0C863D							;0C8631	; Branch if tile was $44
	LDA.B #$48								;0C8633	; Tile pattern = $48
	STA.W $0002,Y							;0C8635	; Update pattern 1
	STA.W $0006,Y							;0C8638	; Update pattern 2
	BRA CODE_0C8647							;0C863B	; Continue

CODE_0C863D:
	LDA.B #$6C								;0C863D	; Tile pattern = $6C
	STA.W $0002,Y							;0C863F	; Update pattern 1
	LDA.B #$6E								;0C8642	; Tile pattern = $6E
	STA.W $0006,Y							;0C8644	; Update pattern 2

CODE_0C8647:
	REP #$30								;0C8647	; 16-bit A/X/Y
	INC.W $020E								;0C8649	; Next sprite
	INC.W $020E								;0C864C	; Increment by 2 (word addressing)
	DEC.W $020C								;0C864F	; Decrement counter
	BNE CODE_0C85FF							;0C8652	; Loop for all 5 sprites
	JSR.W CODE_0C8910						;0C8654	; Update PPU registers
	PLX										;0C8657	; Restore X
	RTS										;0C8658	; Return

; ==============================================================================
; Animation Frame Table (14 frames of sprite tile numbers)
; ==============================================================================

DATA8_0C8659:
	db $00,$04,$04,$00,$00,$08,$08,$08,$0C,$40,$40,$44,$44,$00,$00,$00 ; Sprite animation sequence

; [Additional sprite configuration data continues...]
	db $06,$00,$02,$00,$08,$00,$04,$00,$02,$08,$01,$68,$80,$01,$80,$01
	db $80,$01,$80,$01,$80,$01,$80,$01,$80,$01,$80,$01,$80,$01,$80,$01
	db $80,$01,$80,$01,$09,$0A,$0B,$0C,$03,$02,$02,$02,$10,$40,$02,$02
	db $C1,$C3,$01,$01,$C1,$C3,$01,$01,$C1,$C3,$01,$01,$C1,$C3,$01,$01
	db $C1,$C3,$01,$01,$C1,$C3,$01,$01,$C1,$C3,$01,$01,$C1,$C3,$01,$01
	db $C1,$C3,$01,$01,$C1,$C3,$01,$01,$C1,$C3,$01,$01,$C1,$C3,$01,$01
	db $C1,$C3,$01,$01,$C1,$C3,$01,$01,$C1,$C3,$01,$01,$C1,$C3,$01,$01
	db $C1,$C3,$01,$01,$C1,$C3,$01,$01,$C1,$C3,$01,$01,$C1,$C3,$01,$01
	db $C1,$C3,$01,$01,$C1,$C3,$01,$01,$C1,$C3,$01,$01,$C1,$C3,$01,$01
	db $C1,$C3,$01,$01,$C1,$C3,$01,$01,$C1,$C3,$01,$01,$C1,$C3,$01,$01
	db $C2,$C4,$01,$01,$C2,$C4,$01,$01,$C2,$C4,$01,$01,$C2,$C4,$01,$01
	db $C2,$C4,$01,$01,$C2,$C4,$01,$01,$C2,$C4,$01,$01,$C2,$C4,$01,$01
	db $C2,$C4,$01,$01,$C2,$C4,$01,$01,$C2,$C4,$01,$01,$C2,$C4,$01,$01
	db $C2,$C4,$01,$01,$C2,$C4,$01,$01,$C2,$C4,$01,$01,$C2,$C4,$01,$01
	db $C2,$C4,$01,$01,$C2,$C4,$01,$01,$C2,$C4,$01,$01,$C2,$C4,$01,$01
	db $C2,$C4,$01,$01,$C2,$C4,$01,$01,$C2,$C4,$01,$01,$C2,$C4,$01,$01
	db $02,$04,$01,$01,$05,$02,$02,$02,$02,$02,$02,$02,$02,$00

; ==============================================================================
; CODE_0C8767 - Sprite OAM Data Copy
; ==============================================================================
; Block copies sprite configuration to OAM buffer.
; 112 bytes ($70) transferred via MVN instruction.
; ==============================================================================

CODE_0C8767:
	REP #$30								;0C8767	; 16-bit A/X/Y
	LDX.W #$8779							;0C8769	; Source address
	LDY.W #$0C80							;0C876C	; Destination address (OAM buffer)
	LDA.W #$006F							;0C876F	; Transfer size = 112 bytes
	MVN $00,$0C								;0C8772	; Block move (Bank $0C → Bank $00)
	JSR.W CODE_0C8910						;0C8775	; Update PPU registers
	RTS										;0C8778	; Return

; OAM sprite configuration data (112 bytes)
	db $74,$CF,$00,$36,$74,$CF,$00,$38,$74,$CF,$00,$3A,$74,$CF,$00,$3C
	db $74,$CF,$00,$3E,$7C,$BF,$00,$36,$7C,$EF,$00,$36,$7C,$BF,$00,$38
	db $7C,$EF,$00,$38,$7C,$BF,$00,$3A,$7C,$EF,$00,$3A,$7C,$BF,$00,$3C
	db $7C,$EF,$00,$3C,$7C,$BF,$00,$3E,$7C,$EF,$00,$3E,$78,$8F,$4C,$06
	db $78,$8F,$4C,$08,$78,$8F,$4C,$0A,$78,$8F,$4C,$0C,$78,$8F,$4C,$0E
	db $40,$6F,$C0,$00,$50,$6F,$C2,$00,$60,$6F,$C4,$00,$70,$6F,$C6,$00
	db $80,$6F,$C8,$00,$90,$6F,$CA,$00,$A0,$6F,$CC,$00,$B0,$6F,$CE,$00

; ==============================================================================
; CODE_0C87E9 - Clear NMI Flag
; ==============================================================================
; Disables NMI interrupts by clearing flag.
; Called before major PPU updates.
; ==============================================================================

CODE_0C87E9:
	STZ.W $0111								;0C87E9	; Clear NMI enable flag
	RTS										;0C87EC	; Return

; ==============================================================================
; CODE_0C87ED - Mode 7 Tilemap Setup
; ==============================================================================
; Initializes Mode 7 tilemap with block fill.
; Fills 30 rows ($1E) × 128 columns with pattern $C0.
; ==============================================================================

CODE_0C87ED:
	REP #$30								;0C87ED	; 16-bit A/X/Y
	PEA.W $0C7F								;0C87EF	; Push bank $0C
	PLB										;0C87F2	; Pull to data bank register
	LDX.W #$4000							;0C87F3	; VRAM start address
	LDY.W #$001E							;0C87F6	; Row count = 30
	LDA.W #$00C0							;0C87F9	; Fill pattern = $C0
	JSL.L CODE_009994						;0C87FC	; Call tilemap fill routine
	PLB										;0C8800	; Restore data bank
	SEP #$20								;0C8801	; 8-bit accumulator
	STZ.W $4204								;0C8803	; Clear multiply/divide register
	LDX.W #$00CE							;0C8806	; Table offset = $CE
	LDY.W #$0082							;0C8809	; Y parameter = $82

CODE_0C880C:									; Loop: Setup calculation
	TYA										;0C880C	; Transfer Y to A
	ASL A									;0C880D	; *2
	STA.W $4205								;0C880E	; Store to multiply register
	LDA.B #$20								;0C8811	; Value = $20
	JSL.L CODE_009726						;0C8813	; Call calculation routine
	; [Additional Mode 7 setup continues...]

; ==============================================================================
; End of Bank $0C Cycle 2
; ==============================================================================
; Lines documented: 400 source lines (500-900)
; Address range: $0C8396-$0C8813 (partial)
; Systems: Screen effects, palette fades, sprite animation, Mode 7 tilemap
; ==============================================================================
; ==============================================================================
; BANK $0C CYCLE 3 - DMA/HDMA & Mode 7 Math (Lines 900-1300)
; ==============================================================================
; Address range: $0C8813-$0C8AF1
; Systems: HDMA setup, Mode 7 rotation/scaling, DMA transfers, OAM management
; ==============================================================================

; [Continued from Cycle 2 ending at $0C8813]

	JSL.L CODE_009726						;0C8813	; Call hardware multiply routine
	REP #$30								;0C8817	; 16-bit A/X/Y
	LDA.W $4214								;0C8819	; Read quotient from hardware divider
	STA.L $7F0010,X							;0C881C	; Store to Mode 7 calculation buffer
	SEP #$20								;0C8820	; 8-bit accumulator
	INY										;0C8822	; Next Y value
	INX										;0C8823	; Next X offset
	INX										;0C8824	; (word addressing)
	CPY.W #$00E8							;0C8825	; Processed 232 values?
	BNE CODE_0C880C							;0C8828	; Loop for all rows

; ==============================================================================
; HDMA Channel Configuration - Perspective Effect Setup
; ==============================================================================
; Configures two HDMA channels for Mode 7 scanline effects.
; Channel 1 ($4310): Controls horizontal scroll register ($211B)
; Channel 2 ($4320): Controls vertical scroll register ($211E)
; ==============================================================================

	REP #$30								;0C882A	; 16-bit A/X/Y
	LDX.W #$886B							;0C882C	; HDMA data table address
	LDY.W #$0000							;0C882F	; Destination = $7F0000
	LDA.W #$0009							;0C8832	; Transfer 10 bytes
	MVN $7F,$0C								;0C8835	; Block move Bank $0C → Bank $7F
	PHK										;0C8838	; Push current bank
	PLB										;0C8839	; Set data bank
	SEP #$20								;0C883A	; 8-bit accumulator

	; Configure HDMA Channel 1 (Mode 7 X scroll)
	LDA.B #$42								;0C883C	; Transfer mode = Write 2 bytes
	STA.W $4310								;0C883E	; Set DMA1 parameters ($4310)
	STA.W $4320								;0C8841	; Set DMA2 parameters ($4320)
	LDA.B #$1B								;0C8844	; PPU register = $211B (SNES_M7HOFS)
	STA.W $4311								;0C8846	; DMA1 destination = Mode 7 H offset
	LDA.B #$1E								;0C8849	; PPU register = $211E (SNES_M7VOFS)
	STA.W $4321								;0C884B	; DMA2 destination = Mode 7 V offset

	; Set HDMA table addresses (Bank $7F)
	LDX.W #$0000							;0C884E	; Table offset = $7F0000
	STX.W $4312								;0C8851	; DMA1 source address low
	STX.W $4322								;0C8854	; DMA2 source address low
	LDA.B #$7F								;0C8857	; Source bank = $7F
	STA.W $4314								;0C8859	; DMA1 source bank
	STA.W $4324								;0C885C	; DMA2 source bank
	STA.W $4317								;0C885F	; DMA1 indirect address bank
	STA.W $4327								;0C8862	; DMA2 indirect address bank

	LDA.B #$06								;0C8865	; Enable channels 1 and 2
	STA.W $0111								;0C8867	; Set HDMA enable flag (NMI handler)
	RTS										;0C886A	; Return

; ==============================================================================
; HDMA Table Header Data
; ==============================================================================
; Format: [scanline_count] [register_value_low] [register_value_high]
; Controls Mode 7 scroll offsets per scanline for perspective effect.
; ==============================================================================

DATA8_0C886B:
	db $FF,$10,$00,$D1,$0E,$01,$00		;0C886B	; HDMA: 255 lines, value=$0010, then $01D1

; ==============================================================================
; CODE_0C8872 - Animated Vertical Scroll Effect
; ==============================================================================
; Creates smooth scrolling animation from top to bottom of screen.
; Animates through 14-frame cycle using lookup table.
; Used for title screen, special transitions, dramatic reveals.
; ==============================================================================

CODE_0C8872:
	LDA.B #$F7								;0C8872	; Initial scroll value = -9 pixels
	LDX.W #$0000							;0C8874	; Table index = 0

CODE_0C8877:									; Main scroll animation loop
	PHK										;0C8877	; Push data bank
	PLB										;0C8878	; Set data bank
	PHA										;0C8879	; Save scroll value
	JSL.L CODE_0C8000						;0C887A	; Wait for VBLANK
	STA.B SNES_BG1VOFS-$2100				;0C887E	; Set BG1 vertical scroll ($210E)
	STZ.B SNES_BG1VOFS-$2100				;0C8880	; High byte = 0
	LDA.W DATA8_0C88B0,X					;0C8882	; Load animation tile pattern
	INX										;0C8885	; Next table entry
	PHX										;0C8886	; Save index
	JSR.W CODE_0C88EB						;0C8887	; Draw tile pattern (3×3 grid)
	PLX										;0C888A	; Restore index
	CPX.W #$000E							;0C888B	; End of 14-entry table?
	BNE CODE_0C8893							;0C888E	; Branch if not done
	LDX.W #$0000							;0C8890	; Wrap to start

CODE_0C8893:									; Check scroll position ranges
	PLA										;0C8893	; Restore scroll value
	CMP.B #$39								;0C8894	; Position < $39?
	BCC CODE_0C88AB							;0C8896	; Branch if in range 1 (fast scroll)
	CMP.B #$59								;0C8898	; Position < $59?
	BCC CODE_0C88A7							;0C889A	; Branch if in range 2 (medium scroll)
	CMP.B #$79								;0C889C	; Position < $79?
	BCC CODE_0C88A3							;0C889E	; Branch if in range 3 (slow scroll)
	DEC A									;0C88A0	; Range 4: Decrement by 1 (slowest)
	BRA CODE_0C8877							;0C88A1	; Continue animation

CODE_0C88A3:								; Range 3: Slow scroll
	SBC.B #$01								;0C88A3	; Decrement by 2 (carry set from CMP)
	BRA CODE_0C8877							;0C88A5	; Continue animation

CODE_0C88A7:								; Range 2: Medium scroll
	SBC.B #$03								;0C88A7	; Decrement by 4
	BRA CODE_0C8877							;0C88A9	; Continue animation

CODE_0C88AB:								; Range 1: Fast scroll
	SBC.B #$05								;0C88AB	; Decrement by 6 (fastest)
	BCS CODE_0C8877							;0C88AD	; Continue if not wrapped negative
	RTS										;0C88AF	; Exit when scroll completes

; ==============================================================================
; Animation Tile Pattern Table (14 entries)
; ==============================================================================
; Sprite tile numbers for scroll animation frames.
; Values correspond to VRAM tile addresses for 3×3 pattern drawing.
; ==============================================================================

DATA8_0C88B0:
	db $11,$15,$15,$11,$11,$19,$19,$19,$1D,$51,$51,$55,$55,$11 ;0C88B0

; ==============================================================================
; CODE_0C88BE - Mode 7 Matrix Initialization
; ==============================================================================
; Sets up Mode 7 affine transformation matrix for rotation/scaling.
; Initializes center point ($0118, $0184) and identity matrix.
; Called during screen setup, before 3D perspective effects.
; ==============================================================================

CODE_0C88BE:
	PHK										;0C88BE	; Push data bank
	PLB										;0C88BF	; Set data bank
	CLC										;0C88C0	; Clear carry
	LDA.B #$84								;0C88C1	; Center Y = $84 (132 decimal)
	JSL.L CODE_0C8000						;0C88C3	; Wait for VBLANK
	STZ.B SNES_VMAINC-$2100					;0C88C7	; VRAM address increment = 1

	; Set Mode 7 center point (X coordinate)
	STA.B SNES_M7X-$2100					;0C88C9	; M7X low byte = $00 ($211F)
	STZ.B SNES_M7X-$2100					;0C88CB	; M7X high byte = $00
	LDA.B #$18								;0C88CD	; Center X low = $18
	STA.B SNES_M7Y-$2100					;0C88CF	; M7Y low byte ($2120)
	LDA.B #$01								;0C88D1	; Center X high = $01
	STA.B SNES_M7Y-$2100					;0C88D3	; M7Y high byte (X = $0118 = 280)

	; Initialize Mode 7 matrix to identity (no rotation/scale)
	STZ.B SNES_M7B-$2100					;0C88D5	; M7B = $0000 ($211C)
	STZ.B SNES_M7B-$2100					;0C88D7	; Matrix element B = 0
	STZ.B SNES_M7C-$2100					;0C88D9	; M7C = $0000 ($211D)
	STZ.B SNES_M7C-$2100					;0C88DB	; Matrix element C = 0

	; Set initial scroll offset
	LDA.B #$04								;0C88DD	; H scroll = 4 pixels right
	STA.B SNES_BG1HOFS-$2100				;0C88DF	; BG1 horizontal offset ($210D)
	STZ.B SNES_BG1HOFS-$2100				;0C88E1	; High byte = 0
	LDA.B #$F8								;0C88E3	; V scroll = -8 pixels
	STA.B SNES_BG1VOFS-$2100				;0C88E5	; BG1 vertical offset ($210E)
	STZ.B SNES_BG1VOFS-$2100				;0C88E7	; High byte = 0
	LDA.B #$11								;0C88E9	; Base tile pattern

; ==============================================================================
; CODE_0C88EB - Draw 3×3 Tile Pattern
; ==============================================================================
; Draws 3×3 grid of tiles to VRAM at specified position.
; Uses sequential tile numbers with automatic wrapping.
; Input: A = base tile number, X = VRAM position base
; ==============================================================================

CODE_0C88EB:
	CLC										;0C88EB	; Clear carry
	LDX.W #$0F8F							;0C88EC	; VRAM base address = $0F8F
	JSR.W CODE_0C88F8						;0C88EF	; Draw first row (3 tiles)
	JSR.W CODE_0C88F8						;0C88F2	; Draw second row (3 tiles)
	JSR.W CODE_0C88F8						;0C88F5	; Draw third row (3 tiles)

; ==============================================================================
; CODE_0C88F8 - Draw Single Tile Row (3 tiles)
; ==============================================================================
; Writes 3 consecutive tile numbers to VRAM.
; Advances VRAM address by $80 (down one row in tilemap).
; Input: X = VRAM address, A = starting tile number
; ==============================================================================

CODE_0C88F8:
	STX.B SNES_VMADDL-$2100					;0C88F8	; Set VRAM address ($2116)
	STA.B SNES_VMDATAL-$2100				;0C88FA	; Write tile 1 ($2118)
	INC A									;0C88FC	; Next tile
	STA.B SNES_VMDATAL-$2100				;0C88FD	; Write tile 2
	INC A									;0C88FF	; Next tile
	STA.B SNES_VMDATAL-$2100				;0C8900	; Write tile 3
	ADC.B #$0E								;0C8902	; Advance tile base (+16 total from start)
	PHA										;0C8904	; Save next row tile number
	REP #$30								;0C8905	; 16-bit A/X/Y
	TXA										;0C8907	; Transfer VRAM address to A
	ADC.W #$0080							;0C8908	; Move down one tilemap row (32 tiles * 2 bytes)
	TAX										;0C890B	; Update VRAM address
	SEP #$20								;0C890C	; 8-bit accumulator
	PLA										;0C890E	; Restore tile number
	RTS										;0C890F	; Return

; ==============================================================================
; CODE_0C8910 - Setup NMI OAM Transfer
; ==============================================================================
; Configures NMI handler to perform OAM sprite DMA during VBLANK.
; Sets up pointer to sprite transfer subroutine.
; Critical for smooth sprite updates without flicker.
; ==============================================================================

CODE_0C8910:
	PHK										;0C8910	; Push data bank
	PLB										;0C8911	; Set data bank
	SEP #$20								;0C8912	; 8-bit accumulator
	LDA.B #$0C								;0C8914	; Handler bank = $0C
	STA.W $005A								;0C8916	; Store NMI handler bank
	LDX.W #$8929							;0C8919	; Handler address = $0C8929
	STX.W $0058								;0C891C	; Store NMI handler pointer
	LDA.B #$40								;0C891F	; Flag bit 6
	TSB.W $00E2								;0C8921	; Set NMI control flag (enable OAM transfer)
	JSL.L CODE_0C8000						;0C8924	; Wait for VBLANK
	RTS										;0C8928	; Return

; ==============================================================================
; NMI OAM DMA Routine - Executed during VBLANK
; ==============================================================================
; Called automatically by NMI handler when bit 6 of $00E2 is set.
; Transfers 544 bytes ($220) from $0C00 to OAM ($2104).
; Uses DMA channel 5 for maximum speed (single VBLANK period).
; ==============================================================================

	LDX.W #$0000							;0C8929	; OAM address = 0
	STX.W SNES_OAMADDL						;0C892C	; Set OAM write address ($2102)
	LDX.W #$0400							;0C892F	; DMA mode: CPU→PPU, auto-increment
	STX.B SNES_DMA5PARAM-$4300				;0C8932	; Set DMA5 parameters ($4350)
	LDX.W #$0C00							;0C8934	; Source address = $0C00 (sprite buffer)
	STX.B SNES_DMA5ADDRL-$4300				;0C8937	; Set DMA5 source address ($4352)
	LDA.B #$00								;0C8939	; Source bank = $00
	STA.B SNES_DMA5ADDRH-$4300				;0C893B	; Set DMA5 source bank ($4354)
	LDX.W #$0220							;0C893D	; Transfer size = 544 bytes (512 OAM + 32 table)
	STX.B SNES_DMA5CNTL-$4300				;0C8940	; Set DMA5 byte count ($4355)
	LDA.B #$20								;0C8942	; Enable DMA channel 5
	STA.W SNES_MDMAEN						;0C8944	; Start DMA transfer ($420B)
	RTL										;0C8947	; Return from NMI handler

; ==============================================================================
; CODE_0C8948 - Direct OAM DMA Transfer
; ==============================================================================
; Immediately performs OAM sprite DMA (non-NMI version).
; Identical to NMI routine but callable from main code.
; Used for initial sprite setup or forced updates.
; ==============================================================================

CODE_0C8948:
	SEP #$20								;0C8948	; 8-bit accumulator
	LDX.W #$0000							;0C894A	; OAM address = 0
	STX.W SNES_OAMADDL						;0C894D	; Set OAM write address ($2102)
	LDX.W #$0400							;0C8950	; DMA mode: CPU→PPU, auto-increment
	STX.W SNES_DMA5PARAM					;0C8953	; Set DMA5 parameters ($4350)
	LDX.W #$0C00							;0C8956	; Source address = $0C00
	STX.W SNES_DMA5ADDRL					;0C8959	; Set DMA5 source address ($4352)
	LDA.B #$00								;0C895C	; Source bank = $00
	STA.W SNES_DMA5ADDRH					;0C895E	; Set DMA5 source bank ($4354)
	LDX.W #$0220							;0C8961	; Transfer size = 544 bytes
	STX.W SNES_DMA5CNTL						;0C8964	; Set DMA5 byte count ($4355)
	LDA.B #$20								;0C8967	; Enable DMA channel 5
	STA.W SNES_MDMAEN						;0C8969	; Start DMA transfer ($420B)
	PHK										;0C896C	; Push data bank
	PLB										;0C896D	; Set data bank
	RTS										;0C896E	; Return

; ==============================================================================
; CODE_0C896F - Complex Mode 7 Rotation Sequence
; ==============================================================================
; Performs animated Mode 7 rotation effect with matrix calculations.
; Updates transformation matrix each frame for smooth rotation.
; Used for title screen rotation, special battle effects.
; ==============================================================================

CODE_0C896F:
	LDA.B #$D4								;0C896F	; Scroll offset = -44 pixels
	STA.B SNES_BG1VOFS-$2100				;0C8971	; Set vertical scroll ($210E)
	LDA.B #$FF								;0C8973	; High byte = -1 (negative scroll)
	STA.B SNES_BG1VOFS-$2100				;0C8975	; Set high byte
	LDX.W #$8B86							;0C8977	; Sine/cosine table 1
	LDY.W #$8B96							;0C897A	; Sine/cosine table 2

CODE_0C897D:									; Main rotation loop
	LDA.W $0000,Y							;0C897D	; Load rotation angle
	BEQ CODE_0C899B							;0C8980	; Exit if angle = 0 (no rotation)
	PHY										;0C8982	; Save table pointer
	JSL.L CODE_0C8000						;0C8983	; Wait for VBLANK
	JSR.W CODE_0C8A78						;0C8987	; Update Mode 7 matrix ($4202 multiply)
	PLY										;0C898A	; Restore table pointer

	; Calculate vertical scroll based on rotation progress
	TYA										;0C898B	; Transfer table offset to A
	SEC										;0C898C	; Set carry for subtraction
	SBC.B #$AB								;0C898D	; Subtract table base ($8B96 - $AB = $8BEB)
	ASL A									;0C898F	; Multiply by 2 (pixel offset)
	STA.B SNES_BG1VOFS-$2100				;0C8990	; Set vertical scroll ($210E)
	BEQ CODE_0C8996							;0C8992	; Branch if offset = 0
	LDA.B #$FF								;0C8994	; High byte = -1 (negative)

CODE_0C8996:
	STA.B SNES_BG1VOFS-$2100				;0C8996	; Set high byte
	INY										;0C8998	; Next rotation angle
	BRA CODE_0C897D							;0C8999	; Continue rotation

CODE_0C899B:									; Post-rotation fade loop
	LDA.B #$1E								;0C899B	; Loop counter = 30 frames

CODE_0C899D:
	JSL.L CODE_0C8000						;0C899D	; Wait for VBLANK
	PHA										;0C89A1	; Save counter
	JSR.W CODE_0C8A76						;0C89A2	; Update Mode 7 matrix
	PLA										;0C89A5	; Restore counter
	DEC A									;0C89A6	; Decrement
	BNE CODE_0C899D							;0C89A7	; Loop 30 times

	; Initialize sprite animation sequence
	LDY.W #$0101							;0C89A9	; Start position = $0101
	STY.W $0062								;0C89AC	; Store position counter

CODE_0C89AF:									; Sprite position update loop
	LDY.W $0062								;0C89AF	; Load position
	PHY										;0C89B2	; Save position
	JSR.W CODE_0C8A3F						;0C89B3	; Update sprite coordinates
	PLY										;0C89B6	; Restore position
	STY.W $0062								;0C89B7	; Store position
	INC.W $0062								;0C89BA	; Increment X coordinate
	INC.W $0063								;0C89BD	; Increment Y coordinate

	; Second sprite update (staggered)
	LDY.W $0062								;0C89C0	; Load updated position
	PHY										;0C89C3	; Save position
	JSR.W CODE_0C8A3F						;0C89C4	; Update sprite coordinates
	PLY										;0C89C7	; Restore position
	STY.W $0062								;0C89C8	; Store position
	INC.W $0062								;0C89CB	; Increment X coordinate
	INC.W $0063								;0C89CE	; Increment Y coordinate

	; Check for triple update (every 3 cycles)
	LDA.W $0062								;0C89D1	; Load X coordinate
	CMP.B #$0C								;0C89D4	; Reached position $0C?
	BEQ CODE_0C89E8							;0C89D6	; Branch if done

	; Third sprite update (pattern of 3)
	LDY.W $0062								;0C89D8	; Load position
	PHY										;0C89DB	; Save position
	JSR.W CODE_0C8A3F						;0C89DC	; Update sprite coordinates
	PLY										;0C89DF	; Restore position
	STY.W $0062								;0C89E0	; Store position
	INC.W $0062								;0C89E3	; Increment X coordinate
	BRA CODE_0C89AF							;0C89E6	; Continue loop

CODE_0C89E8:									; Wait for table sync loop
	JSL.L CODE_0C8000						;0C89E8	; Wait for VBLANK
	JSR.W CODE_0C8A76						;0C89EC	; Update Mode 7 matrix
	CPX.W #$8B66							;0C89EF	; Table index at $8B66?
	BNE CODE_0C89E8							;0C89F2	; Loop until synced

CODE_0C89F4:									; Final sync hold loop
	JSL.L CODE_0C8000						;0C89F4	; Wait for VBLANK
	JSR.W CODE_0C8A76						;0C89F8	; Update Mode 7 matrix
	CPX.W #$8B66							;0C89FB	; Table index at $8B66?
	BNE CODE_0C89F4							;0C89FE	; Loop until stable

	; Setup final color effects
	JSR.W CODE_0C8910						;0C8A00	; Enable NMI OAM transfer
	LDA.B #$30								;0C8A03	; Flag value = $30
	STA.W $0505								;0C8A05	; Store effect state
	LDX.W #$2100							;0C8A08	; Color math mode
	STX.B SNES_CGSWSEL-$2100				;0C8A0B	; Set color window ($2130)
	LDA.B #$FF								;0C8A0D	; Maximum brightness
	STA.B SNES_COLDATA-$2100				;0C8A0F	; Set fixed color ($2132)

	; Fade-in sequence (8 steps)
	LDA.B #$08								;0C8A11	; Loop counter = 8 brightness levels
	LDY.W #$000C							;0C8A13	; Sprite count = 12
	LDX.W #$0C04							;0C8A16	; Sprite data buffer base

CODE_0C8A19:									; Fade brightness loop
	PHA										;0C8A19	; Save brightness level
	PHY										;0C8A1A	; Save sprite count
	PHX										;0C8A1B	; Save buffer pointer

CODE_0C8A1C:									; Decrement sprite brightness
	DEC.W $0000,X							;0C8A1C	; Decrease sprite brightness
	INX										;0C8A1F	; Next sprite
	INX										;0C8A20	; (skip 2 bytes)
	INX										;0C8A21	; (skip 2 bytes)
	INX										;0C8A22	; (word + word structure)
	DEY										;0C8A23	; Decrement sprite counter
	BNE CODE_0C8A1C							;0C8A24	; Loop for all sprites

	JSR.W CODE_0C8910						;0C8A26	; Update OAM via NMI
	JSL.L CODE_0C8000						;0C8A29	; Wait for VBLANK
	PLX										;0C8A2D	; Restore buffer pointer
	PLY										;0C8A2E	; Restore sprite count
	LDA.B $01,S								;0C8A2F	; Load brightness level from stack
	DEC A									;0C8A31	; Decrease brightness
	ASL A									;0C8A32	; *2
	ASL A									;0C8A33	; *4 (multiply by 4)
	ORA.B #$E0								;0C8A34	; OR with color mask ($E0 = red channel)
	STA.B SNES_COLDATA-$2100				;0C8A36	; Update fixed color ($2132)
	PLA										;0C8A38	; Clean up brightness from stack
	DEC A									;0C8A39	; Decrement loop counter
	BNE CODE_0C8A19							;0C8A3A	; Loop for all 8 brightness levels

	STZ.B SNES_CGADSUB-$2100				;0C8A3C	; Disable color math ($2131)
	RTS										;0C8A3E	; Return

; ==============================================================================
; CODE_0C8A3F - Update Sprite Position
; ==============================================================================
; Calculates and sets sprite screen coordinates.
; Converts logical position to screen-relative offset.
; Input: $0062 = X position, $0063 = Y position
; ==============================================================================

CODE_0C8A3F:
	REP #$30								;0C8A3F	; 16-bit A/X/Y
	SEC										;0C8A41	; Set carry for subtraction
	LDA.W $0062								;0C8A42	; Load X position
	AND.W #$00FF							;0C8A45	; Mask to 8-bit
	EOR.W #$FFFF							;0C8A48	; Invert bits (two's complement prep)
	ADC.W #$040F							;0C8A4B	; Add screen offset ($0410 - 1)
	STA.W $0400								;0C8A4E	; Store screen X coordinate

	LDA.W $0063								;0C8A51	; Load Y position
	AND.W #$00FF							;0C8A54	; Mask to 8-bit
	EOR.W #$FFFF							;0C8A57	; Invert bits
	ADC.W #$603F							;0C8A5A	; Add screen offset ($6040 - 1)
	STA.W $0402								;0C8A5D	; Store screen Y coordinate

	SEP #$20								;0C8A60	; 8-bit accumulator
	LDA.B #$0C								;0C8A62	; NMI handler bank
	STA.W $005A								;0C8A64	; Store handler bank
	LDY.W #$8B0C							;0C8A67	; Handler routine address
	STY.W $0058								;0C8A6A	; Store handler pointer
	LDA.B #$40								;0C8A6D	; Flag bit 6
	TSB.W $00E2								;0C8A6F	; Set NMI enable flag
	JSL.L CODE_0C8000						;0C8A72	; Wait for VBLANK

; ==============================================================================
; CODE_0C8A76 - Hardware Multiply Setup
; ==============================================================================
; Initializes hardware multiplier for Mode 7 calculations.
; Input: A = multiplicand value (typically $30 for 48×48 matrix)
; ==============================================================================

CODE_0C8A76:
	LDA.B #$30								;0C8A76	; Multiplicand = 48

CODE_0C8A78:
	STA.W $4202								;0C8A78	; Set multiplicand register ($4202)
	STA.W $0064								;0C8A7B	; Store to variable
	JSR.W CODE_0C8AC8						;0C8A7E	; Read Mode 7 matrix element
	STY.W $0062								;0C8A81	; Store matrix A value
	INX										;0C8A84	; Next matrix element
	INX										;0C8A85	; (word offset)
	JSR.W CODE_0C8AC8						;0C8A86	; Read Mode 7 matrix element
	STY.W $0064								;0C8A89	; Store matrix B value
	INX										;0C8A8C	; Next matrix element
	INX										;0C8A8D	; (word offset)

	; Check for table wrap
	CPX.W #$8B96							;0C8A8E	; End of sine/cosine table?
	BNE CODE_0C8A96							;0C8A91	; Branch if not
	LDX.W #$8B66							;0C8A93	; Wrap to table start

CODE_0C8A96:									; Write Mode 7 matrix registers
	JSL.L CODE_0C8000						;0C8A96	; Wait for VBLANK

	; Update Mode 7 matrix A register ($211B)
	LDA.W $0062								;0C8A9A	; Load matrix A low byte
	STA.B SNES_M7A-$2100					;0C8A9D	; Write M7A low ($211B)
	LDA.W $0063								;0C8A9F	; Load matrix A high byte
	STA.B SNES_M7A-$2100					;0C8AA2	; Write M7A high

	; Update Mode 7 matrix D register ($211E)
	LDA.W $0062								;0C8AA4	; Load matrix D low byte
	STA.B SNES_M7D-$2100					;0C8AA7	; Write M7D low ($211E)
	LDA.W $0063								;0C8AA9	; Load matrix D high byte
	STA.B SNES_M7D-$2100					;0C8AAC	; Write M7D high

	; Update Mode 7 matrix B register ($211C)
	LDA.W $0064								;0C8AAE	; Load matrix B low byte
	STA.B SNES_M7B-$2100					;0C8AB1	; Write M7B low ($211C)
	XBA										;0C8AB3	; Swap A/B bytes
	LDA.W $0065								;0C8AB4	; Load matrix B high byte
	STA.B SNES_M7B-$2100					;0C8AB7	; Write M7B high
	XBA										;0C8AB9	; Restore byte order

	; Calculate and set matrix C (negative of B)
	REP #$30								;0C8ABA	; 16-bit A/X/Y
	EOR.W #$FFFF							;0C8ABC	; Invert all bits
	INC A									;0C8ABF	; Increment (two's complement = -B)
	SEP #$20								;0C8AC0	; 8-bit accumulator
	STA.B SNES_M7C-$2100					;0C8AC2	; Write M7C low ($211D)
	XBA										;0C8AC4	; Swap bytes
	STA.B SNES_M7C-$2100					;0C8AC5	; Write M7C high
	RTS										;0C8AC7	; Return

; ==============================================================================
; CODE_0C8AC8 - Read & Multiply Matrix Element
; ==============================================================================
; Reads sine/cosine value from table and performs hardware multiply.
; Used for Mode 7 rotation matrix calculation.
; Input: X = table offset
; Output: Y = result from hardware multiplier
; ==============================================================================

CODE_0C8AC8:
	LDA.W $0001,X							;0C8AC8	; Load matrix value high byte
	BMI CODE_0C8AF1							;0C8ACB	; Branch if negative (sign extend)
	BNE CODE_0C8AE6							;0C8ACD	; Branch if non-zero high byte
	LDA.W $0000,X							;0C8ACF	; Load low byte only

CODE_0C8AD2:									; Small positive value path
	JSL.L CODE_00971E						;0C8AD2	; Setup hardware multiply/divide
	LDY.W $4216								;0C8AD6	; Read division remainder
	STY.W $4204								;0C8AD9	; Store to dividend register

CODE_0C8ADC:									; Common multiply path
	LDA.B #$30								;0C8ADC	; Multiplier = 48
	JSL.L CODE_009726						;0C8ADE	; Perform hardware multiply
	LDY.W $4214								;0C8AE2	; Read product result ($4214)
	RTS										;0C8AE5	; Return with result in Y

CODE_0C8AE6:									; Large positive value path
	STZ.W $4204								;0C8AE6	; Clear dividend high byte
	LDA.W $0064								;0C8AE9	; Load multiplier value
	STA.W $4205								;0C8AEC	; Set divisor register
	BRA CODE_0C8ADC							;0C8AEF	; Continue to multiply

CODE_0C8AF1:									; Negative value path (sign extend)
	LDA.W $0000,X							;0C8AF1	; Load matrix value low byte
	; [Additional processing continues...]

; ==============================================================================
; End of Bank $0C Cycle 3
; ==============================================================================
; Lines documented: 400 source lines (900-1300)
; Address range: $0C8813-$0C8AF1
; Systems: HDMA setup, Mode 7 rotation/scaling, DMA transfers, OAM management
; ==============================================================================
; ==============================================================================
; BANK $0C CYCLE 4 - VRAM Fill & Title Screen Setup (Lines 1300-1700)
; ==============================================================================
; Address range: $0C8AF1-$0C8F98
; Systems: VRAM tile fill, palette DMA, title screen initialization, tilemap setup
; ==============================================================================

; [Continued from Cycle 3 ending at $0C8AF1]

	LDA.W $0000,X							;0C8AF1	; Load matrix value (continued from CODE_0C8AC8)
	BEQ CODE_0C8B07							;0C8AF4	; Branch if zero (no processing needed)
	EOR.B #$FF								;0C8AF6	; Invert bits (two's complement step 1)
	INC A									;0C8AF8	; Increment (two's complement = negate)
	JSR.W CODE_0C8AD2						;0C8AF9	; Process small positive value path

CODE_0C8AFC:								; Negate result and return
	REP #$30								;0C8AFC	; 16-bit A/X/Y
	TYA										;0C8AFE	; Transfer result to A
	EOR.W #$FFFF							;0C8AFF	; Invert all bits
	INC A									;0C8B02	; Increment (negate)
	TAY										;0C8B03	; Return result in Y
	SEP #$20								;0C8B04	; 8-bit accumulator
	RTS										;0C8B06	; Return

CODE_0C8B07:								; Zero value path
	JSR.W CODE_0C8AE6						;0C8B07	; Process large positive value
	BRA CODE_0C8AFC							;0C8B0A	; Negate and return

; ==============================================================================
; NMI Sprite Position Update Handler
; ==============================================================================
; Called from NMI when sprite positions need updating.
; Uses DMA to transfer sprite coordinate data to VRAM during VBLANK.
; ==============================================================================

	LDY.W #$1800							;0C8B0C	; DMA mode: A→A, increment both
	STY.B SNES_DMA0PARAM-$4300				;0C8B0F	; Set DMA0 parameters ($4300)
	STZ.B SNES_DMA1CNTL-$4300				;0C8B11	; Clear DMA1 count ($4315)
	LDA.B #$7F								;0C8B13	; Source bank = $7F
	STA.B SNES_DMA0ADDRH-$4300				;0C8B15	; Set DMA0 source bank ($4304)
	LDY.W $0402								;0C8B17	; Load Y coordinate offset
	LDX.W #$0008							;0C8B1A	; Row count = 8
	STX.W $0064								;0C8B1D	; Store row counter
	LDX.W #$0414							;0C8B20	; Data buffer address
	LDA.W $0063								;0C8B23	; Load Y position
	JSR.W CODE_0C8B3C						;0C8B26	; Update vertical sprite positions
	
	; Update horizontal sprite positions
	LDX.W #$000B							;0C8B29	; Column count = 11
	STX.W $0064								;0C8B2C	; Store column counter
	LDY.W #$6000							;0C8B2F	; VRAM address = $6000
	LDX.W $0400								;0C8B32	; Load X coordinate offset
	LDA.W $0062								;0C8B35	; Load X position
	JSR.W CODE_0C8B3C						;0C8B38	; Update horizontal sprite positions
	RTL										;0C8B3B	; Return from NMI handler

; ==============================================================================
; CODE_0C8B3C - Sprite Coordinate DMA Transfer
; ==============================================================================
; Transfers sprite coordinate data to VRAM using DMA.
; Writes 5 bytes per row/column, advancing VRAM address by $80 each iteration.
; Input: A = coordinate value, X = VRAM address, Y = source buffer address
; ==============================================================================

CODE_0C8B3C:
	CLC										;0C8B3C	; Clear carry
	XBA										;0C8B3D	; Swap bytes (prep for DMA count)
	LDA.B #$05								;0C8B3E	; Transfer size = 5 bytes

CODE_0C8B40:								; DMA transfer loop
	STX.W SNES_VMADDL						;0C8B40	; Set VRAM address ($2116)
	XBA										;0C8B43	; Swap to get count
	STA.B SNES_DMA0CNTL-$4300				;0C8B44	; Set DMA byte count low ($4305)
	STZ.B SNES_DMA0CNTH-$4300				;0C8B46	; Set DMA byte count high ($4306)
	STY.B SNES_DMA0ADDRL-$4300				;0C8B48	; Set DMA source address ($4302)
	PHA										;0C8B4A	; Save count
	LDA.B #$01								;0C8B4B	; Enable DMA channel 0
	STA.W SNES_MDMAEN						;0C8B4D	; Start DMA transfer ($420B)
	PLA										;0C8B50	; Restore count
	
	; Advance to next row/column
	REP #$30								;0C8B51	; 16-bit A/X/Y
	PHA										;0C8B53	; Save count
	TXA										;0C8B54	; Transfer VRAM address to A
	ADC.W #$0080							;0C8B55	; Advance by 128 (next row in 32×32 tilemap)
	TAX										;0C8B58	; Update VRAM address
	TYA										;0C8B59	; Transfer source address to A
	ADC.W $0064								;0C8B5A	; Add row/column stride
	TAY										;0C8B5D	; Update source address
	PLA										;0C8B5E	; Restore count
	SEP #$20								;0C8B5F	; 8-bit accumulator
	XBA										;0C8B61	; Swap back
	DEC A									;0C8B62	; Decrement row/column counter
	BNE CODE_0C8B40							;0C8B63	; Loop for all rows/columns
	RTS										;0C8B65	; Return

; ==============================================================================
; Mode 7 Rotation Sine/Cosine Lookup Tables
; ==============================================================================
; Two 48-entry tables for smooth rotation animation.
; Values represent fixed-point sine/cosine for 360° rotation.
; Format: Signed 16-bit fixed-point (8.8 format)
; ==============================================================================

DATA16_0C8B66:								; Sine/cosine table 1 (48 entries)
	db $DD,$00,$80,$00,$80,$00,$DD,$00,$00,$00 ;0C8B66	; Angles 0-9
	db $00										;0C8B70
	db $01,$80,$FF,$DD,$00,$23,$FF,$80,$00,$00,$FF,$00,$00,$23,$FF,$80 ;0C8B71	; Angles 10-25
	db $FF,$80,$FF,$23,$FF,$00,$00,$00,$FF,$80,$00,$23,$FF,$DD,$00,$80 ;0C8B81	; Angles 26-41
	db $FF										;0C8B91
	db $00										;0C8B92

DATA8_0C8B93:								; Animation speed table (30 bytes)
	db $01,$00,$00,$01,$02,$03,$04,$05,$06,$07,$08,$0A,$0C,$0E,$10,$12 ;0C8B93
	db $14,$16,$18,$1C,$20,$24,$28,$2C,$30,$00 ;0C8BA3

; ==============================================================================
; CODE_0C8BAD - Title Screen Initialization
; ==============================================================================
; Sets up title screen graphics, sprites, and tilemaps.
; Initializes Mode 7 perspective effect for logo animation.
; Uses multiple MVN block moves for efficient data transfer.
; ==============================================================================

CODE_0C8BAD:
	LDA.B #$18								;0C8BAD	; Effect timer = 24 frames
	STA.W $0500								;0C8BAF	; Store effect state
	REP #$30								;0C8BB2	; 16-bit A/X/Y
	
	; Transfer title screen configuration data
	LDX.W #$8CE2							;0C8BB4	; Source: Title config table
	LDY.W #$0D00							;0C8BB7	; Dest: $0D00 (config buffer)
	LDA.W #$0037							;0C8BBA	; Transfer 56 bytes
	MVN $00,$0C								;0C8BBD	; Block move Bank $0C → Bank $00
	
	LDY.W #$0E10							;0C8BC0	; Dest: $0E10 (secondary buffer)
	LDA.W #$0003							;0C8BC3	; Transfer 4 bytes
	MVN $00,$0C								;0C8BC6	; Block move
	
	; Transfer sprite attribute data
	LDX.W #$8C5E							;0C8BC9	; Source: Sprite data table
	LDY.W #$0C04							;0C8BCC	; Dest: $0C04 (sprite buffer)
	LDA.W #$007B							;0C8BCF	; Transfer 124 bytes
	MVN $00,$0C								;0C8BD2	; Block move
	
	LDY.W #$0E00							;0C8BD5	; Dest: $0E00 (effect params)
	LDA.W #$0007							;0C8BD8	; Transfer 8 bytes
	MVN $00,$0C								;0C8BDB	; Block move
	
	SEP #$20								;0C8BDE	; 8-bit accumulator
	PEA.W $0C7F								;0C8BE0	; Push bank $7F
	PLB										;0C8BE3	; Set data bank = $7F
	
	; Initialize tile pattern buffer ($7F6000-$7F6xxx)
	LDY.W #$6000							;0C8BE4	; Buffer address = $7F6000
	LDA.B #$40								;0C8BE7	; Starting tile = $40
	CLC										;0C8BE9	; Clear carry

CODE_0C8BEA:								; Outer loop: Process 11 tile rows
	LDX.W #$000B							;0C8BEA	; Column count = 11

CODE_0C8BED:								; Inner loop: Fill tile row
	STA.W $0000,Y							;0C8BED	; Write tile number to buffer
	INC A									;0C8BF0	; Next tile
	INY										;0C8BF1	; Next buffer position
	DEX										;0C8BF2	; Decrement column counter
	BNE CODE_0C8BED							;0C8BF3	; Loop for all columns
	ADC.B #$05								;0C8BF5	; Advance to next row base (+16 total)
	CMP.B #$90								;0C8BF7	; Reached tile $90?
	BNE CODE_0C8BEA							;0C8BF9	; Loop for all rows
	
	; Initialize secondary tile pattern buffer (8-column layout)
	LDY.W #$6037							;0C8BFB	; Buffer address = $7F6037 (offset)
	LDA.B #$A0								;0C8BFE	; Starting tile = $A0
	CLC										;0C8C00	; Clear carry

CODE_0C8C01:								; Outer loop: Process 8 tile rows
	LDX.W #$0008							;0C8C01	; Column count = 8

CODE_0C8C04:								; Inner loop: Fill tile row
	STA.W $0000,Y							;0C8C04	; Write tile number
	INC A									;0C8C07	; Next tile
	INY										;0C8C08	; Next buffer position
	DEX										;0C8C09	; Decrement column counter
	BNE CODE_0C8C04							;0C8C0A	; Loop for all columns
	ADC.B #$08								;0C8C0C	; Advance to next row base (+16 total)
	CMP.B #$F0								;0C8C0E	; Reached tile $F0?
	BNE CODE_0C8C01							;0C8C10	; Loop for all rows
	
	PLB										;0C8C12	; Restore data bank
	CLC										;0C8C13	; Clear carry
	JSL.L CODE_0C8000						;0C8C14	; Wait for VBLANK
	STZ.B SNES_VMAINC-$2100					;0C8C18	; VRAM address increment = 1
	
	; Set Mode 7 center point
	LDA.B #$8C								;0C8C1A	; Center X = $8C (140 decimal)
	STA.B SNES_M7X-$2100					;0C8C1C	; Write M7 center X low ($211F)
	STZ.B SNES_M7X-$2100					;0C8C1E	; Write M7 center X high
	LDA.B #$50								;0C8C20	; Center Y = $50 (80 decimal)
	STA.B SNES_M7Y-$2100					;0C8C22	; Write M7 center Y low ($2120)
	STZ.B SNES_M7Y-$2100					;0C8C24	; Write M7 center Y high
	
	; Initialize Mode 7 identity matrix
	LDA.B #$01								;0C8C26	; Matrix diagonal = 1.0
	STA.B SNES_M7A-$2100					;0C8C28	; M7A = $0100 ($211B)
	STZ.B SNES_M7A-$2100					;0C8C2A	; High byte
	STA.B SNES_M7D-$2100					;0C8C2C	; M7D = $0100 ($211E)
	STZ.B SNES_M7D-$2100					;0C8C2E	; High byte
	
	; Process tilemap fill commands from table
	LDX.W #$0285							;0C8C30	; Initial VRAM address
	LDY.W #$8D1E							;0C8C33	; Command table address
	PHX										;0C8C36	; Save base VRAM address

CODE_0C8C37:								; Tilemap fill loop
	STX.B SNES_VMADDL-$2100					;0C8C37	; Set VRAM address ($2116)
	LDA.B #$00								;0C8C39	; Clear high byte
	XBA										;0C8C3B	; Swap (A = 0)
	LDA.W $0000,Y							;0C8C3C	; Load repeat count
	TAX										;0C8C3F	; Use as counter
	LDA.W $0001,Y							;0C8C40	; Load starting tile number

CODE_0C8C43:								; Fill repeat loop
	STA.B SNES_VMDATAL-$2100				;0C8C43	; Write tile to VRAM ($2118)
	INC A									;0C8C45	; Increment tile number
	DEX										;0C8C46	; Decrement counter
	BNE CODE_0C8C43							;0C8C47	; Loop for repeat count
	
	; Check for next command
	LDA.W $0002,Y							;0C8C49	; Load VRAM offset for next fill
	BEQ CODE_0C8C5C							;0C8C4C	; Exit if offset = 0 (end marker)
	INY										;0C8C4E	; Next command entry
	INY										;0C8C4F	; (3 bytes per entry)
	INY										;0C8C50	; Advance to next
	REP #$30								;0C8C51	; 16-bit A/X/Y
	ADC.B $01,S								;0C8C53	; Add offset to base VRAM address
	STA.B $01,S								;0C8C55	; Update base address on stack
	TAX										;0C8C57	; Use as VRAM address
	SEP #$20								;0C8C58	; 8-bit accumulator
	BRA CODE_0C8C37							;0C8C5A	; Continue with next command

CODE_0C8C5C:								; Cleanup and return
	PLX										;0C8C5C	; Clean up stack
	RTS										;0C8C5D	; Return

; ==============================================================================
; Title Screen Sprite Configuration Data (124 bytes)
; ==============================================================================
; Format: [X_pos] [Y_pos] [tile] [attr] - 31 sprites × 4 bytes
; Defines sprite positions and attributes for title screen logo/effects.
; ==============================================================================

DATA8_0C8C5E:
	db $28,$27,$10,$01,$38,$27,$12,$01,$48,$27,$14,$01,$58,$27,$16,$01 ;0C8C5E
	db $68,$27,$18,$01,$80,$27,$10,$01,$90,$27,$16,$01,$A0,$27,$14,$01 ;0C8C6E
	db $B0,$27,$1A,$01,$C0,$27,$16,$01,$D0,$27,$1C,$01,$E0,$27,$1E,$01 ;0C8C7E
	db $20,$5F,$80,$31,$40,$5F,$84,$31,$68,$5F,$89,$31,$80,$57,$7C,$31 ;0C8C8E
	db $90,$57,$7E,$31,$A0,$5F,$E0,$31,$C0,$5F,$E4,$31,$78,$B7,$86,$30 ;0C8C9E
	db $20,$B7,$E0,$30,$30,$B7,$E2,$30,$40,$B7,$E4,$30,$20,$3F,$40,$31 ;0C8CAE
	db $40,$3F,$44,$31,$60,$3F,$48,$31,$80,$37,$3C,$31,$A0,$3F,$A0,$31 ;0C8CBE
	db $C0,$3F,$A4,$31,$58,$B7,$82,$30,$68,$B7,$84,$30 ;0C8CCE
	db $01,$00,$00,$00 ;0C8CD6	; End marker + padding
	db $00,$00,$AA,$0A ;0C8CDA

; ==============================================================================
; Title Screen Configuration Data (56 bytes)
; ==============================================================================
; Additional sprite/effect configuration for title animation.
; ==============================================================================

DATA8_0C8CDE:
	db $90,$B7,$A0,$30,$A0,$B7,$A2,$30,$B8,$B7,$A4,$30 ;0C8CDE
	db $C8,$B7,$A6,$30,$30,$C3,$A8,$30,$40,$C3,$AA,$30,$50,$C3,$AC,$30 ;0C8CEA
	db $60,$C3,$AE,$30,$78,$C3,$E6,$30,$90,$C3,$E8,$30,$A0,$C3,$EA,$30 ;0C8CFA
	db $B0,$C3,$EC,$30,$C0,$C3,$EE,$30,$E0,$57,$80,$30,$00,$00,$00,$50 ;0C8D0A

; ==============================================================================
; Tilemap Fill Command Table
; ==============================================================================
; Format: [repeat_count] [start_tile] [vram_offset]
; Used by CODE_0C8C37 to efficiently fill VRAM tilemaps.
; Offset = 0 marks end of table.
; ==============================================================================

DATA8_0C8D1E:
	db $01,$FF,$02,$01,$FF,$02,$01,$FF,$02,$01,$FF,$02,$01,$FF,$03,$01 ;0C8D1E
	db $FF,$02,$01,$FF,$02,$01,$FF,$02,$01,$FF,$02,$01,$FF,$02,$01,$FF ;0C8D2E
	db $02,$01,$FF,$69,$01,$FF,$02,$01,$FF,$02,$01,$FF,$02,$01,$FF,$02 ;0C8D3E
	db $01,$FF,$03,$01,$FF,$02,$01,$FF,$02,$01,$FF,$02,$01,$FF,$02,$01 ;0C8D4E
	db $FF,$02,$01,$FF,$02,$01,$FF,$74,$03,$3C,$7F,$05,$4B,$80,$05,$5B ;0C8D5E
	db $80,$05,$6B,$80,$05,$7B,$81,$04,$8C,$04,$01,$E0,$00 ;0C8D6E	; End marker

; ==============================================================================
; CODE_0C8D7B - Complex Title Screen VRAM Setup
; ==============================================================================
; Initializes complete title screen graphics system.
; Sets up 3 palette groups, fills OAM, configures DMA for tilemap transfer.
; Highly optimized using DMA channel 0 for maximum VBLANK efficiency.
; ==============================================================================

CODE_0C8D7B:
	PHP										;0C8D7B	; Save processor status
	PHD										;0C8D7C	; Save direct page
	REP #$30								;0C8D7D	; 16-bit A/X/Y
	LDA.W #$4300							;0C8D7F	; Direct page = DMA registers
	TCD										;0C8D82	; Set direct page to $4300
	STZ.W SNES_VMADDL						;0C8D83	; Clear VRAM address ($2116)
	SEP #$20								;0C8D86	; 8-bit accumulator
	LDA.B #$80								;0C8D88	; VRAM increment = +128 (vertical)
	STA.W SNES_VMAINC						;0C8D8A	; Set increment mode ($2115)
	
	; Transfer palette group 1
	LDA.B #$00								;0C8D8D	; Palette offset = 0
	JSR.W CODE_0C8F98						;0C8D8F	; Transfer palette via DMA
	
	; Transfer palette group 2
	LDA.B #$80								;0C8D92	; Palette offset = $80 (128 colors)
	JSR.W CODE_0C8F98						;0C8D94	; Transfer palette via DMA
	
	; Transfer palette group 3
	LDA.B #$C0								;0C8D97	; Palette offset = $C0 (192 colors)
	JSR.W CODE_0C8F98						;0C8D99	; Transfer palette via DMA
	
	; Fill OAM sprite buffer with pattern
	REP #$30								;0C8D9C	; 16-bit A/X/Y
	LDA.W #$5555							;0C8D9E	; Fill pattern = $5555
	STA.W $0C00								;0C8DA1	; Write to sprite buffer start
	LDX.W #$0C00							;0C8DA4	; Source = $0C00
	LDY.W #$0C02							;0C8DA7	; Dest = $0C02
	LDA.W #$021D							;0C8DAA	; Transfer 542 bytes (fill entire OAM)
	MVN $00,$00								;0C8DAD	; Block move within Bank $00
	
	JSR.W CODE_0C8948						;0C8DB0	; Perform OAM DMA transfer
	
	; Setup tilemap DMA transfer
	LDX.W #$1809							;0C8DB3	; DMA mode: Word, A→A, increment
	STX.B SNES_DMA0PARAM-$4300				;0C8DB6	; Set DMA0 parameters ($4300)
	LDX.W #$8F12							;0C8DB8	; Source address = $0C8F12
	STX.B SNES_DMA0ADDRL-$4300				;0C8DBB	; Set DMA0 source ($4302)
	LDA.B #$0C								;0C8DBD	; Source bank = $0C
	STA.B SNES_DMA0ADDRH-$4300				;0C8DBF	; Set DMA0 bank ($4304)
	LDX.W #$0000							;0C8DC1	; Transfer size = 64KB (full auto)
	STX.B SNES_DMA0CNTL-$4300				;0C8DC4	; Set DMA0 count ($4305)
	LDA.B #$01								;0C8DC6	; Enable DMA channel 0
	STA.W $420B								;0C8DC8	; Start DMA transfer ($420B)
	
	JSR.W CODE_0C90F9						;0C8DCB	; Additional VRAM setup routine
	JSR.W CODE_0C9142						;0C8DCE	; Secondary graphics initialization
	
	; Transfer large graphics block to VRAM $4000
	LDX.W #$1801							;0C8DD1	; DMA mode: Byte, A→A
	STX.B SNES_DMA0PARAM-$4300				;0C8DD4	; Set DMA0 parameters
	LDX.W #$4000							;0C8DD6	; VRAM address = $4000
	STX.W $2116								;0C8DD9	; Set VRAM address ($2116)
	LDX.W #$2000							;0C8DDC	; Source address = $7F2000
	STX.B SNES_DMA0ADDRL-$4300				;0C8DDF	; Set DMA0 source
	LDA.B #$7F								;0C8DE1	; Source bank = $7F
	STA.B SNES_DMA0ADDRH-$4300				;0C8DE3	; Set DMA0 bank
	LDX.W #$1000							;0C8DE5	; Transfer size = 4096 bytes
	STX.B SNES_DMA0CNTL-$4300				;0C8DE8	; Set DMA0 count
	LDA.B #$01								;0C8DEA	; Enable DMA channel 0
	STA.W $420B								;0C8DEC	; Start DMA transfer
	
	; Process graphics command table
	LDA.B #$0C								;0C8DEF	; Source bank = $0C
	STA.B SNES_DMA0ADDRH-$4300				;0C8DF1	; Set DMA0 bank
	LDY.W #$5100							;0C8DF3	; VRAM base address = $5100
	LDX.W #$8F14							;0C8DF6	; Command table address

CODE_0C8DF9:								; Graphics command processing loop
	REP #$30								;0C8DF9	; 16-bit A/X/Y
	STY.W $2116								;0C8DFB	; Set VRAM address ($2116)
	
	; Calculate DMA transfer size (entry byte 0 × 32)
	LDA.W $0000,X							;0C8DFE	; Load entry byte 0
	AND.W #$00FF							;0C8E01	; Mask to 8-bit
	ASL A									;0C8E04	; ×2
	ASL A									;0C8E05	; ×4
	ASL A									;0C8E06	; ×8
	ASL A									;0C8E07	; ×16
	ASL A									;0C8E08	; ×32 (tile size)
	STA.B SNES_DMA0CNTL-$4300				;0C8E09	; Set DMA transfer size ($4305)
	
	; Calculate source address (entry byte 1 × 32 + $AA4C base)
	LDA.W $0001,X							;0C8E0B	; Load entry byte 1
	AND.W #$00FF							;0C8E0E	; Mask to 8-bit
	ASL A									;0C8E11	; ×2
	ASL A									;0C8E12	; ×4
	ASL A									;0C8E13	; ×8
	ASL A									;0C8E14	; ×16
	ASL A									;0C8E15	; ×32
	ADC.W #$AA4C							;0C8E16	; Add base address
	STA.B SNES_DMA0ADDRL-$4300				;0C8E19	; Set DMA source address ($4302)
	
	; Calculate VRAM offset (entry byte 2 × 16 + current VRAM)
	LDA.W $0002,X							;0C8E1B	; Load entry byte 2
	AND.W #$00FF							;0C8E1E	; Mask to 8-bit
	ASL A									;0C8E21	; ×2
	ASL A									;0C8E22	; ×4
	ASL A									;0C8E23	; ×8
	ASL A									;0C8E24	; ×16
	PHY										;0C8E25	; Save current VRAM address
	ADC.B $01,S								;0C8E26	; Add offset to VRAM address
	TAY										;0C8E28	; Update VRAM address
	PLA										;0C8E29	; Clean up stack
	
	SEP #$20								;0C8E2A	; 8-bit accumulator
	LDA.B #$01								;0C8E2C	; Enable DMA channel 0
	STA.W $420B								;0C8E2E	; Start DMA transfer ($420B)
	
	; Check for next command (entry byte 2 != 0)
	LDA.W $0002,X							;0C8E31	; Load entry byte 2
	PHP										;0C8E34	; Save flags (check for zero)
	INX										;0C8E35	; Next entry
	INX										;0C8E36	; (3 bytes per entry)
	INX										;0C8E37	; Advance pointer
	PLP										;0C8E38	; Restore flags
	BNE CODE_0C8DF9							;0C8E39	; Continue if not end marker
	
	; Copy graphics data to Bank $7F buffer
	REP #$30								;0C8E3B	; 16-bit A/X/Y
	LDA.W #$0000							;0C8E3D	; Clear A
	TCD										;0C8E40	; Restore direct page to $0000
	LDX.W #$AA4C							;0C8E41	; Source = $0CAA4C
	LDY.W #$0000							;0C8E44	; Dest = $7F0000
	LDA.W #$0D5F							;0C8E47	; Transfer 3424 bytes
	MVN $7F,$0C								;0C8E4A	; Block move Bank $0C → Bank $7F
	
	; Additional tilemap fill from command table
	LDX.W #$0000							;0C8E4D	; Clear X
	LDA.W #$0400							;0C8E50	; VRAM base address
	PHA										;0C8E53	; Save base address

CODE_0C8E54:								; Tilemap command loop
	STA.L SNES_VMADDL						;0C8E54	; Set VRAM address ($2116)
	LDA.L DATA8_0C8F14,X					;0C8E58	; Load command entry
	AND.W #$00FF							;0C8E5C	; Get repeat count (low byte)
	TAY										;0C8E5F	; Use as counter
	LDA.L DATA8_0C8F14,X					;0C8E60	; Reload entry
	AND.W #$FF00							;0C8E64	; Get tile base (high byte)
	LSR A									;0C8E67	; ÷2
	LSR A									;0C8E68	; ÷4
	LSR A									;0C8E69	; ÷8 (shift to position)
	ADC.W #$0000							;0C8E6A	; Add carry from previous ops
	PHX										;0C8E6D	; Save command pointer
	TAX										;0C8E6E	; Use tile base as index

CODE_0C8E6F:								; Tile fill loop
	PHY										;0C8E6F	; Save counter
	JSR.W CODE_0C8FB4						;0C8E70	; Write tile pattern (subroutine)
	PLY										;0C8E73	; Restore counter
	DEY										;0C8E74	; Decrement
	BNE CODE_0C8E6F							;0C8E75	; Loop for repeat count
	
	PLX										;0C8E77	; Restore command pointer
	LDA.L DATA8_0C8F15,X					;0C8E78	; Load next command offset
	AND.W #$FF00							;0C8E7C	; Check high byte
	BEQ CODE_0C8E8C							;0C8E7F	; Exit if zero (end marker)
	INX										;0C8E81	; Next command entry
	INX										;0C8E82	; (3 bytes)
	INX										;0C8E83	; Advance pointer
	LSR A									;0C8E84	; Shift offset
	LSR A									;0C8E85	; (calculate VRAM offset)
	ADC.B $01,S								;0C8E86	; Add to base VRAM address
	STA.B $01,S								;0C8E88	; Update base on stack
	BRA CODE_0C8E54							;0C8E8A	; Continue with next command

CODE_0C8E8C:								; Cleanup and finalize
	PLA										;0C8E8C	; Clean up stack
	PHK										;0C8E8D	; Push data bank
	PLB										;0C8E8E	; Set data bank
	JSR.W CODE_0C8EA8						;0C8E8F	; Additional text/logo setup
	
	; Fill bottom screen area with pattern $10
	SEP #$20								;0C8E92	; 8-bit accumulator
	LDX.W #$3FC0							;0C8E94	; VRAM address = $3FC0
	STX.W $2116								;0C8E97	; Set VRAM address
	LDX.W #$0040							;0C8E9A	; Fill count = 64 tiles
	LDA.B #$10								;0C8E9D	; Fill pattern = tile $10

CODE_0C8E9F:								; Fill loop
	STA.W $2119								;0C8E9F	; Write to VRAM data ($2119)
	DEX										;0C8EA2	; Decrement counter
	BNE CODE_0C8E9F							;0C8EA3	; Loop for all tiles
	
	PLD										;0C8EA5	; Restore direct page
	PLP										;0C8EA6	; Restore processor status
	RTS										;0C8EA7	; Return

; [Additional text/logo transfer routines continue at CODE_0C8EA8...]
; [Palette DMA setup continues at CODE_0C8F98...]

; ==============================================================================
; End of Bank $0C Cycle 4
; ==============================================================================
; Lines documented: 400 source lines (1300-1700)
; Address range: $0C8AF1-$0C8F98
; Systems: VRAM fill, palette DMA, title screen setup, tilemap initialization
; ==============================================================================
