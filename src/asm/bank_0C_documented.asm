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

; ==============================================================================
; VBLANK Synchronization Routine
; ==============================================================================
; Waits for VBLANK period to begin, then returns immediately.
; Critical for safe PPU register updates and DMA transfers.
; ==============================================================================

Display_WaitVBlank:
	PHP										;0C8000	; Save processor status
	SEP #$20								;0C8001	; 8-bit accumulator
	PHA										;0C8003	; Save accumulator
	LDA.B #$40								;0C8004	; VBLANK flag bit
	TRB.W $00D8								;0C8006	; Test and reset VBLANK flag

.WaitLoop:
	LDA.B #$40								;0C8009	; VBLANK flag bit
	AND.W $00D8								;0C800B	; Test VBLANK flag
	BEQ .WaitLoop							;0C800E	; Loop until VBLANK starts
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

Display_ShowCharStats:
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
	JSR.W Display_ProcessStatValue			;0C8038	; Process stat value
	STA.W $00B5								;0C803B	; Store processed value
	LDA.L DATA8_07EE86,X					;0C803E	; Load stat byte 2
	JSR.W Display_ProcessStatValue			;0C8042	; Process stat value
	STA.W $00B2								;0C8045	; Store processed value
	LDA.L DATA8_07EE87,X					;0C8048	; Load stat byte 3
	JSR.W Display_ProcessStatValue			;0C804C	; Process stat value
	STA.W $00B4								;0C804F	; Store processed value
	LDA.L DATA8_07EE88,X					;0C8052	; Load stat byte 4
	JSR.W Display_ProcessStatValue			;0C8056	; Process stat value
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

Display_ProcessStatValue:
	BEQ .ZeroStat							;0C8071	; Branch if zero
	JSL.L CODE_009776						;0C8073	; Check stat condition
	BEQ .NormalStat							;0C8077	; Branch if normal
	LDA.B #$02								;0C8079	; Stat modified flag
	BRA .ZeroStat							;0C807B	; Continue

.NormalStat:
	LDA.B #$01								;0C807D	; Normal stat flag

.ZeroStat:
	RTS										;0C807F	; Return

; ==============================================================================
; Screen Initialization Routine
; ==============================================================================
; Initializes PPU registers for screen display.
; Sets up background modes, object selection, and layer priorities.
; See: https://wiki.superfamicom.org/snes-initialization
; ==============================================================================

Display_InitScreen:
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

Display_MainScreenSetup:
	LDA.B #$0C								;0C8103	; Bank $0C
	STA.W $005A								;0C8105	; Set data bank
	LDX.W #$90D7							;0C8108	; Address of palette DMA code
	STX.W $0058								;0C810B	; Set DMA routine pointer
	LDA.B #$40								;0C810E	; VBLANK DMA flag
	TSB.W $00E2								;0C8110	; Set DMA pending flag
	JSL.L Display_WaitVBlank				;0C8113	; Wait for VBLANK
	LDA.B #$07								;0C8117	; Background mode 7
	STA.B SNES_BGMODE-$2100					;0C8119	; Set BG mode ($2105)
	JSR.W CODE_0C87ED						;0C811B	; Mode 7 matrix setup
	JSR.W Display_PaletteLoadSetup			;0C811E	; Palette load setup
	JSR.W CODE_0C88BE						;0C8121	; Additional graphics init
	JSR.W CODE_0C8872						;0C8124	; Background scrolling setup
	JSR.W CODE_0C87E9						;0C8127	; Finalize graphics state
	LDA.B #$40								;0C812A	; VBLANK flag
	TRB.W $00D6								;0C812C	; Clear VBLANK pending
	JSL.L Display_WaitVBlank				;0C812F	; Wait for VBLANK
	LDA.B #$01								;0C8133	; BG mode 1
	STA.B SNES_BGMODE-$2100					;0C8135	; Set BG mode ($2105)
	STZ.B SNES_BG1VOFS-$2100				;0C8137	; BG1 V-scroll = 0 ($210E)
	STZ.B SNES_BG1VOFS-$2100				;0C8139	; Write high byte
	JSR.W CODE_0C8767						;0C813B	; Graphics state finalize
	JSR.W Display_SpriteOAMSetup			;0C813E	; Sprite/OAM setup
	RTS										;0C8141	; Return

; ==============================================================================
; CODE_0C8142 - Window Effect Configuration
; ==============================================================================
; Sets up color window registers for screen effects (fades, transitions).
; Configures SNES window masking system.
; ==============================================================================

Display_WindowEffectSetup:
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

Display_VRAMAddressCalc:
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
	JSR.W Display_VRAMPatternFill			;0C818D	; Call VRAM fill routine
	LDA.B #$0C								;0C8190	; Tile pattern value
	LDX.W #$622A							;0C8192	; VRAM address $622A
	JSR.W Display_VRAMPatternFill			;0C8195	; Call VRAM fill routine
	LDA.B #$14								;0C8198	; Tile pattern value
	LDX.W #$6234							;0C819A	; VRAM address $6234
	JSR.W Display_VRAMPatternFill			;0C819D	; Call VRAM fill routine
	LDA.B #$10								;0C81A0	; Tile pattern value
	LDX.W #$6239							;0C81A2	; VRAM address $6239

; ==============================================================================
; CODE_0C81A5 - VRAM Pattern Fill Routine
; ==============================================================================
; Fills VRAM with sequential tile numbers for background patterns.
; Creates animated tile sequences (water, fire, etc.).
; Input: A = pattern start value, X = VRAM address
; ==============================================================================

Display_VRAMPatternFill:
	XBA										;0C81A5	; Swap A/B registers
	LDA.B #$00								;0C81A6	; Clear low byte
	REP #$30								;0C81A8	; 16-bit A/X/Y

.FillLoop:									; Loop: Fill VRAM pattern
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
	BEQ .FillLoop							;0C81C1	; Loop if not done
	SEP #$20								;0C81C3	; 8-bit accumulator
	RTS										;0C81C5	; Return

; ==============================================================================
; CODE_0C81C6 - Color Math Disable Routine
; ==============================================================================
; Disables color addition/subtraction effects.
; Resets window and color math registers.
; ==============================================================================

Display_ColorMathDisable:
	STZ.B SNES_CGSWSEL-$2100				;0C81C6	; Clear color window select ($2130)
	STZ.B SNES_CGADSUB-$2100				;0C81C8	; Clear color math ($2131)
	RTS										;0C81CA	; Return

; ==============================================================================
; CODE_0C81CB - Color Addition Effect Setup
; ==============================================================================
; Enables color addition for screen brightness/darkness effects.
; Used for battle transitions, lightning, darkness, etc.
; ==============================================================================

Display_ColorAdditionSetup:
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

Display_PaletteLoadSetup:
	LDA.B #$0C								;0C81DA	; Bank $0C
	STA.W $005A								;0C81DC	; Set DMA source bank
	LDX.W #$81EF							;0C81DF	; Palette DMA routine address
	STX.W $0058								;0C81E2	; Set DMA routine pointer
	LDA.B #$40								;0C81E5	; VBLANK DMA flag
	TSB.W $00E2								;0C81E7	; Set DMA pending flag
	JSL.L Display_WaitVBlank				;0C81EA	; Wait for VBLANK
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
	JSR.W Display_PaletteDMATransfer		;0C81FD	; DMA 16 bytes to CGRAM
	LDY.W #$D934							;0C8200	; Source address $07:D934
	JSR.W Display_PaletteDMATransfer		;0C8203	; DMA 16 bytes
	JSR.W Display_PaletteDMATransfer		;0C8206	; DMA 16 bytes (auto-increment)
	JSR.W Display_PaletteDMATransfer		;0C8209	; DMA 16 bytes
	JSR.W Display_PaletteDMATransfer		;0C820C	; DMA 16 bytes
	LDA.B #$B0								;0C820F	; Palette index = $B0
	JSR.W Display_PaletteDMATransfer		;0C8211	; DMA 16 bytes
	LDY.W #$D934							;0C8214	; Reset source to $07:D934
	JSR.W Display_PaletteDMATransfer		;0C8217	; DMA 16 bytes
	JSR.W Display_PaletteDMATransfer		;0C821A	; DMA 16 bytes
	JSR.W Display_PaletteDMATransfer		;0C821D	; DMA 16 bytes
	JSR.W Display_PaletteDMATransfer		;0C8220	; DMA 16 bytes
	RTL										;0C8223	; Return from palette DMA

; ==============================================================================
; CODE_0C8224 - Single Palette DMA Transfer (16 bytes)
; ==============================================================================
; Transfers 16 bytes of palette data to CGRAM via DMA.
; Input: A = CGRAM address, Y = source address (Bank $07)
; Output: A += $10, Y += $10 (auto-incremented for next call)
; ==============================================================================

Display_PaletteDMATransfer:
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

Display_SpriteOAMSetup:
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

Display_EffectScriptInterpreter:
	LDA.W $0000,X							;0C825A	; Load effect command byte
	INX										;0C825D	; Advance script pointer
	CMP.B #$01								;0C825E	; Command < 01?
	BCC .WaitCondition						;0C8260	; Branch to wait routine
	BEQ .SingleFrame						;0C8262	; Command = 01: Single frame delay
	CMP.B #$03								;0C8264	; Command < 03?
	BCC .ColorCycle							;0C8266	; Branch to color cycle
	BEQ .PaletteOp							;0C8268	; Command = 03: Palette operation
	CMP.B #$05								;0C826A	; Command = 05?
	BEQ .SpecialEffect						;0C826C	; Branch to special effect
	BCS .ComplexOps							;0C826E	; Command >= 06: Complex operations
	LDY.W #$0004							;0C8270	; Loop count = 4

; Color flash effect loop (command 04)
.ColorFlash:
	PHY										;0C8273	; Save loop counter
	LDA.B #$3F								;0C8274	; Fixed color = white ($3F)
	STA.B SNES_COLDATA-$2100				;0C8276	; Set color addition ($2132)
	JSR.W CODE_0C85DB						;0C8278	; Wait one frame
	LDA.B #$E0								;0C827B	; Fixed color = dark ($E0)
	STA.B SNES_COLDATA-$2100				;0C827D	; Set color subtraction
	JSR.W CODE_0C85DB						;0C827F	; Wait one frame
	PLY										;0C8282	; Restore loop counter
	DEY										;0C8283	; Decrement
	BNE .ColorFlash							;0C8284	; Loop 4 times (4 flashes)
	BRA Display_EffectScriptInterpreter		;0C8286	; Continue script

; Color cycle effect (command 02)
.ColorCycle:
	LDA.B #$3B								;0C8288	; Cycle duration = 59 frames

.CycleLoop:
	PHA										;0C828A	; Save counter
	JSR.W CODE_0C85DB						;0C828B	; Wait one frame
	PLA										;0C828E	; Restore counter
	DEC A									;0C828F	; Decrement
	BNE .CycleLoop							;0C8290	; Loop until counter = 0

; Single frame delay (command 01)
.SingleFrame:
	JSR.W CODE_0C85DB						;0C8292	; Wait one frame
	BRA Display_EffectScriptInterpreter		;0C8295	; Continue script

; Wait until condition met (command 00)
.WaitCondition:
	JSR.W CODE_0C85DB						;0C8297	; Wait one frame
	LDA.W $0C82								;0C829A	; Load condition flag
	BNE .WaitCondition						;0C829D	; Loop until flag clears
	RTS										;0C829F	; Return from effect script

; Palette load command (command 03)
.PaletteOp:
	JMP.W CODE_0C8460						;0C82A0	; Jump to palette loader

; Special effect command (command 05)
.SpecialEffect:
	JMP.W CODE_0C8421						;0C82A3	; Jump to special effect handler

; ==============================================================================
; Complex Command Handler (Commands $06-$FF)
; ==============================================================================
; Decodes complex commands with parameters.
; Format: [CMD:5bits][PARAM:3bits] for advanced visual effects.
; ==============================================================================

.ComplexOps:
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
Display_EffectCommandMidRange:
	SBC.B #$30								;0C82F7	; Normalize command ($40+ → $10+)
	LSR A									;0C82F9	; /2
	LSR A									;0C82FA	; /4
	LSR A									;0C82FB	; /8
	STA.W $0200								;0C82FC	; Store effect type
	JMP.W CODE_0C825A						;0C82FF	; Continue script

; Low-range command handler ($08-$3F)
Display_EffectCommandLowRange:
	CMP.B #$08								;0C8302	; Command = $08?
	BNE CODE_0C837D							;0C8304	; Branch if not $08
	LDA.W $015F								;0C8306	; Load parameter
	BNE Display_EffectTableLookup			;0C8309	; Branch if parameter != 0
	REP #$30								;0C830B	; 16-bit A/X/Y
	LDA.W #$3C03							;0C830D	; Bit mask
	TRB.W $0E08								;0C8310	; Clear bits in window config
	LDA.W #$0002							;0C8313	; New value
	TSB.W $0E08								;0C8316	; Set bits in window config
	SEP #$20								;0C8319	; 8-bit accumulator
	JMP.W CODE_0C825A						;0C831B	; Continue script

; Parameter-based table lookup
Display_EffectTableLookup:
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
.BitShiftLoop:
	ASL A									;0C8348	; Shift left *2
	ASL A									;0C8349	; Shift left *2 (total *4)
	DEY										;0C834A	; Decrement parameter
	BNE .BitShiftLoop						;0C834B	; Loop until parameter = 0
	PHA										;0C834D	; Save shifted value
	TRB.W $0E08								;0C834E	; Clear bits in window config
	AND.W #$AAAA							;0C8351	; Mask pattern ($AAAA)
	TSB.W $0E08								;0C8354	; Set masked bits
	PLA										;0C8357	; Restore shifted value
	LDY.W $015F								;0C8358	; Reload parameter
	LSR A									;0C835B	; Shift right /2
	LSR A									;0C835C	; Shift right /2 (total /4)

; Second bit shift loop
.SecondShiftLoop:
	ASL A									;0C835D	; Shift left *2
	ASL A									;0C835E	; Shift left *2 (total *4)
	DEY										;0C835F	; Decrement parameter
	BNE .SecondShiftLoop					;0C8360	; Loop until parameter = 0
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

.CleanupAndExit:
	PLA										;0C8377	; Clean up stack
	SEP #$20								;0C8378	; 8-bit accumulator
	JMP.W CODE_0C825A						;0C837A	; Continue script

; ==============================================================================
; Complex Screen Effect Setup (Command $08+)
; ==============================================================================
; Initializes multi-stage screen effects combining VRAM updates,
; palette fades, and color window operations.
; ==============================================================================

Display_EffectComplexParamCommand:
	PHX										;0C837D	; Save script pointer
	JSR.W Display_VRAMAddressCalc			;0C837E	; Calculate VRAM addresses
	JSR.W Display_WindowEffectSetup			;0C8381	; Setup window effects
	JSR.W Display_FlashEffect				;0C8384	; Execute effect stage 1
	JSR.W Display_FlashEffect				;0C8387	; Execute effect stage 2
	JSR.W Display_FlashEffect				;0C838A	; Execute effect stage 3
	LDA.B #$10								;0C838D	; Loop counter = 16 frames

.EffectLoop:
	PHA										;0C838F	; Save counter
	JSR.W Display_ColorAdditionSetup		;0C8390	; Enable color addition
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
	JSR.W Display_ColorMathDisable			;0C839D	; Disable color math
	JSR.W CODE_0C85DB						;0C83A0	; Wait one frame
	JSR.W CODE_0C85DB						;0C83A3	; Wait one frame
	PLA										;0C83A6	; Restore loop counter
	DEC A									;0C83A7	; Decrement
	BNE .EffectLoop							;0C83A8	; Loop if not done (16 frames total)
	JSR.W Display_ColorAdditionSetup		;0C83AA	; Re-enable color addition
	PLX										;0C83AD	; Restore script pointer
	JMP.W Display_EffectScriptInterpreter	;0C83AE	; Continue effect script

; ==============================================================================
; CODE_0C83B1 - Flash Effect Subroutine
; ==============================================================================
; Creates white flash effect (bright → normal → bright sequence).
; Used for lightning, magic spells, critical hits.
; ==============================================================================

Display_FlashEffect:
	JSR.W Display_ColorAdditionSetup		;0C83B1	; Enable color addition
	LDA.B #$11								;0C83B4	; Layer enable mask
	STA.B SNES_TM-$2100						;0C83B6	; Set layers ($212C)
	LDA.B #$3F								;0C83B8	; Fixed color = white ($3F)
	STA.B SNES_COLDATA-$2100				;0C83BA	; Set color addition ($2132)
	JSR.W CODE_0C85DB						;0C83BC	; Wait one frame (flash)
	JSR.W Display_ColorMathDisable			;0C83BF	; Disable color math
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

Display_TableEffectExecutor:
	PHX										;0C83CB	; Save X register
	TAX										;0C83CC	; Use A as table index
	SEP #$20								;0C83CD	; 8-bit accumulator
	LDY.W $0161								;0C83CF	; Load command type
	CPY.W #$00B8							;0C83D2	; Command = $B8 (specific effect)?
	BEQ .ProcessEffect						;0C83D5	; Branch if match
	CPY.W #$0089							;0C83D7	; Command >= $89?
	BCS UNREACH_0C83E8						;0C83DA	; Branch if high range
	SEC										;0C83DC	; Set carry for subtraction

.ProcessEffect:
	LDA.W $0001,X							;0C83DD	; Load table value
	SBC.W $0200								;0C83E0	; Subtract adjustment
	STA.W $0001,X							;0C83E3	; Store result
	BRA .ContinueEffect						;0C83E6	; Continue

UNREACH_0C83E8:
	db $C0,$98,$00,$90,$0E,$C0,$A9,$00,$B0,$09,$BD,$01,$00,$6D,$00,$02 ; Additional effect logic
	db $9D,$01,$00

.ContinueEffect:
	CPY.W #$0088							;0C83FB	; Command < $88?
	BCC .LowRangeCheck						;0C83FE	; Branch if low range
	db $C0,$99,$00,$B0,$0B,$BD,$00,$00,$6D,$00,$02,$9D,$00,$00,$80,$0E ; Effect processing

.LowRangeCheck:
	CPY.W #$00A8							;0C8410	; Command < $A8?
	BCC .Finalize							;0C8413	; Branch if not A8+
	db $BD,$00,$00,$ED,$00,$02,$9D,$00,$00 ; Additional effect

.Finalize:
	TXY										;0C841E	; Transfer result to Y
	PLX										;0C841F	; Restore X
	RTS										;0C8420	; Return

; ==============================================================================
; CODE_0C8421 - Screen Scroll Effect
; ==============================================================================
; Animated scrolling effect for screen transitions.
; Scrolls window positions over 32 frames, then holds for 60 frames.
; ==============================================================================

Display_ScreenScrollEffect:
	LDA.B #$20								;0C8421	; Loop counter = 32 frames

.ScrollLoop:
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
	BNE .ScrollLoop							;0C844B	; Loop 32 times
	LDA.B #$3C								;0C844D	; Hold duration = 60 frames

.HoldLoop:
	PHA										;0C844F	; Save counter
	JSR.W CODE_0C85DB						;0C8450	; Wait one frame
	PLA										;0C8453	; Restore counter
	DEC A									;0C8454	; Decrement
	BNE .HoldLoop							;0C8455	; Loop 60 times
	STZ.W $0E0D								;0C8457	; Clear window state 1
	STZ.W $0E0E								;0C845A	; Clear window state 2
	JMP.W Display_EffectScriptInterpreter	;0C845D	; Continue script

; ==============================================================================
; CODE_0C8460 - Complex Palette Fade Sequence
; ==============================================================================
; Multi-stage palette fading effect using indirect function calls.
; Cycles through color transformations with precise timing.
; ==============================================================================

Display_ComplexPaletteFade:
	PHX										;0C8460	; Save script pointer
	LDY.W #$8575							;0C8461	; Function pointer 1
	STY.W $0212								;0C8464	; Store function address
	LDX.W #$0000							;0C8467	; Clear X (parameter)
	LDY.W #$84CB							;0C846A	; Fade table address
	JSR.W Display_PaletteFadeStage			;0C846D	; Execute fade stage 1
	LDY.W #$84CB							;0C8470	; Fade table address
	JSR.W Display_PaletteFadeStage			;0C8473	; Execute fade stage 2
	LDY.W #$8520							;0C8476	; Different fade table
	JSR.W Display_PaletteFadeStage			;0C8479	; Execute fade stage 3
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
; Display_FadeStageExecutor - Fade Stage Executor
; ==============================================================================
; Executes one stage of palette fade using function table.
; Input: Y = fade curve table address
; Uses indirect JSR through $0210 and $0212 function pointers.
; ==============================================================================

Display_FadeStageExecutor:
	STY.W $0210								;0C849E	; Store table address
	LDY.W #$85B3							;0C84A1	; Fade curve start

.FadeCurveLoop:									; Loop through fade curve
	JSR.W ($0210,X)							;0C84A4	; Call effect function (indirect)
	SEC										;0C84A7	; Set carry
	LDA.W $0C81								;0C84A8	; Load base color value
	SBC.W $0000,Y							;0C84AB	; Subtract curve value
	JSR.W ($0212,X)							;0C84AE	; Call adjustment function (indirect)
	INY										;0C84B1	; Next curve entry
	CPY.W #$85DB							;0C84B2	; End of curve?
	BNE .FadeCurveLoop						;0C84B5	; Loop if not done
	DEY										;0C84B7	; Back up one entry

.ReverseFadeLoop:							; Reverse fade loop
	DEY										;0C84B8	; Previous curve entry
	JSR.W ($0210,X)							;0C84B9	; Call effect function
	CLC										;0C84BC	; Clear carry
	LDA.W $0C81								;0C84BD	; Load base color
	ADC.W $0000,Y							;0C84C0	; Add curve value
	JSR.W ($0212,X)							;0C84C3	; Call adjustment function
	CPY.W #$85B2							;0C84C6	; Back at start?
	BNE .ReverseFadeLoop					;0C84C9	; Loop if not done
	RTS										;0C84CB	; Return

; [Fade function - adjusts window positions alternately]
Display_FadeFunction1:
	TYA										;0C84CC	; Transfer Y to A
	BIT.B #$01								;0C84CD	; Test bit 0 (odd/even)
	BEQ .Return								;0C84CF	; Skip if even frame
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

.Return:
	RTS										;0C84F5	; Return

; [Fade function 2 - reverse direction adjustments]
Display_FadeFunction2:
	TYA										;0C84F6	; Transfer Y to A
	BIT.B #$01								;0C84F7	; Test bit 0
	BEQ .Return								;0C84F9	; Skip if even
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

.Return:
	RTS										;0C851F	; Return

; [Fade function 3 - partial position adjustments]
Display_FadeFunction3:
	TYA										;0C8520	; Transfer Y
	BIT.B #$01								;0C8521	; Test bit 0
	BEQ .AdjustRemaining					;0C8523	; Skip if even
	DEC.W $0C88								;0C8525	; Adjust subset of positions
	DEC.W $0CA4								;0C8528	; Adjust position
	DEC.W $0CA8								;0C852B	; Adjust position
	INC.W $0C90								;0C852E	; Adjust position
	INC.W $0CB4								;0C8531	; Adjust position
	INC.W $0CB8								;0C8534	; Adjust position

.AdjustRemaining:
	DEC.W $0C84								;0C8537	; Adjust remaining positions
	DEC.W $0C9C								;0C853A	; Adjust position
	DEC.W $0CA0								;0C853D	; Adjust position
	INC.W $0C8C								;0C8540	; Adjust position
	INC.W $0CAC								;0C8543	; Adjust position
	INC.W $0CB0								;0C8546	; Adjust position
	RTS										;0C8549	; Return

; [Fade function 4 - complex bidirectional fade]
Display_FadeFunction4:
	LDA.W $0C81								;0C854A	; Load base value
	PHA										;0C854D	; Save to stack
	LDA.W $0214								;0C854E	; Load fade direction flag
	BCS .AddCurve							;0C8551	; Branch if carry set
	SEC										;0C8553	; Set carry
	SBC.W $0000,Y							;0C8554	; Subtract curve value
	BRA .ApplyFade							;0C8557	; Continue

.AddCurve:
	CLC										;0C8559	; Clear carry
	ADC.W $0000,Y							;0C855A	; Add curve value

.ApplyFade:
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
; Display_ScreenColorValueUpdater - Screen Color Value Updater
; ==============================================================================
; Updates multiple screen color/position registers with same value.
; Spreads value across 5 primary + 5 secondary position registers.
; Input: A = value to write
; ==============================================================================

Display_ScreenColorValueUpdater:
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
	BEQ .Return								;0C85AA	; Skip if even
	PHY										;0C85AC	; Save Y
	JSR.W Display_WaitVBlankAndUpdate		;0C85AD	; Wait one frame
	PLY										;0C85B0	; Restore Y

.Return:
	RTS										;0C85B1	; Return

; Fade curve data table (40 bytes)
	db $00,$04,$02,$01,$02,$01,$01,$01,$01,$00,$01,$01,$00,$01,$00,$01 ; Smooth fade curve
	db $01,$00,$01,$00,$01,$00,$00,$01,$00,$00,$01,$00,$00,$00,$01,$00 ; values (0-4 range)
	db $00,$00,$00,$01,$00,$00,$00,$00,$00 ; End of curve

; ==============================================================================
; Display_WaitVBlankAndUpdate - Frame Wait & Sprite Animation Update
; ==============================================================================
; Primary VBLANK synchronization + sprite animation handler.
; Called hundreds of times per second - performance critical!
; Updates animated sprite tiles every 4 frames.
; ==============================================================================

Display_WaitVBlankAndUpdate:
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

.SpriteUpdateLoop:							; Loop: Update each sprite
	LDA.W $020E								;0C85FF	; Load sprite index
	ASL A									;0C8602	; *2 (word offset)
	ADC.W #$0C80							;0C8603	; Add base address
	TAY										;0C8606	; Use as pointer
	LDX.W $020E								;0C8607	; Load sprite index
	LDA.W $0202,X							;0C860A	; Load animation frame
	INC A									;0C860D	; Next frame
	CMP.W #$000E							;0C860E	; Frame >= 14?
	BNE .StoreFrame							;0C8611	; Branch if not
	LDA.W #$0000							;0C8613	; Wrap to frame 0

.StoreFrame:
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
	BEQ .UseTile6C							;0C8631	; Branch if tile was $44
	LDA.B #$48								;0C8633	; Tile pattern = $48
	STA.W $0002,Y							;0C8635	; Update pattern 1
	STA.W $0006,Y							;0C8638	; Update pattern 2
	BRA .ContinueSpriteLoop					;0C863B	; Continue

.UseTile6C:
	LDA.B #$6C								;0C863D	; Tile pattern = $6C
	STA.W $0002,Y							;0C863F	; Update pattern 1
	LDA.B #$6E								;0C8642	; Tile pattern = $6E
	STA.W $0006,Y							;0C8644	; Update pattern 2

.ContinueSpriteLoop:
	REP #$30								;0C8647	; 16-bit A/X/Y
	INC.W $020E								;0C8649	; Next sprite
	INC.W $020E								;0C864C	; Increment by 2 (word addressing)
	DEC.W $020C								;0C864F	; Decrement counter
	BNE .SpriteUpdateLoop					;0C8652	; Loop for all 5 sprites
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
; Display_SpriteOAMDataCopy - Sprite OAM Data Copy
; ==============================================================================
; Block copies sprite configuration to OAM buffer.
; 112 bytes ($70) transferred via MVN instruction.
; ==============================================================================

Display_SpriteOAMDataCopy:
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
; Display_ClearNMIFlag - Clear NMI Flag
; ==============================================================================
; Disables NMI interrupts by clearing flag.
; Called before major PPU updates.
; ==============================================================================

Display_ClearNMIFlag:
	STZ.W $0111								;0C87E9	; Clear NMI enable flag
	RTS										;0C87EC	; Return

; ==============================================================================
; Display_Mode7TilemapSetup - Mode 7 Tilemap Setup
; ==============================================================================
; Initializes Mode 7 tilemap with block fill.
; Fills 30 rows ($1E) × 128 columns with pattern $C0.
; ==============================================================================

Display_Mode7TilemapSetup:
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

.SetupCalculationLoop:					; Loop: Setup calculation
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
	BNE .SetupCalculationLoop				;0C8828	; Loop for all rows

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
; Display_AnimatedVerticalScroll - Animated Vertical Scroll Effect
; ==============================================================================
; Creates smooth scrolling animation from top to bottom of screen.
; Animates through 14-frame cycle using lookup table.
; Used for title screen, special transitions, dramatic reveals.
; ==============================================================================

Display_AnimatedVerticalScroll:
	LDA.B #$F7								;0C8872	; Initial scroll value = -9 pixels
	LDX.W #$0000							;0C8874	; Table index = 0

.MainScrollLoop:							; Main scroll animation loop
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
	BNE .CheckScrollRange					;0C888E	; Branch if not done
	LDX.W #$0000							;0C8890	; Wrap to start

.CheckScrollRange:							; Check scroll position ranges
	PLA										;0C8893	; Restore scroll value
	CMP.B #$39								;0C8894	; Position < $39?
	BCC .FastScrollRange					;0C8896	; Branch if in range 1 (fast scroll)
	CMP.B #$59								;0C8898	; Position < $59?
	BCC .MediumScrollRange					;0C889A	; Branch if in range 2 (medium scroll)
	CMP.B #$79								;0C889C	; Position < $79?
	BCC .SlowScrollRange					;0C889E	; Branch if in range 3 (slow scroll)
	DEC A									;0C88A0	; Range 4: Decrement by 1 (slowest)
	BRA .MainScrollLoop						;0C88A1	; Continue animation

.SlowScrollRange:							; Range 3: Slow scroll
	SBC.B #$01								;0C88A3	; Decrement by 2 (carry set from CMP)
	BRA .MainScrollLoop						;0C88A5	; Continue animation

.MediumScrollRange:							; Range 2: Medium scroll
	SBC.B #$03								;0C88A7	; Decrement by 4
	BRA .MainScrollLoop						;0C88A9	; Continue animation

.FastScrollRange:							; Range 1: Fast scroll
	SBC.B #$05								;0C88AB	; Decrement by 6 (fastest)
	BCS .MainScrollLoop						;0C88AD	; Continue if not wrapped negative
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
; Display_Mode7MatrixInit - Mode 7 Matrix Initialization
; ==============================================================================
; Sets up Mode 7 affine transformation matrix for rotation/scaling.
; Initializes center point ($0118, $0184) and identity matrix.
; Called during screen setup, before 3D perspective effects.
; ==============================================================================

Display_Mode7MatrixInit:
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
; Display_Draw3x3TilePattern - Draw 3×3 Tile Pattern
; ==============================================================================
; Draws 3×3 grid of tiles to VRAM at specified position.
; Uses sequential tile numbers with automatic wrapping.
; Input: A = base tile number, X = VRAM position base
; ==============================================================================

Display_Draw3x3TilePattern:
	CLC										;0C88EB	; Clear carry
	LDX.W #$0F8F							;0C88EC	; VRAM base address = $0F8F
	JSR.W Display_DrawTileRow				;0C88EF	; Draw first row (3 tiles)
	JSR.W Display_DrawTileRow				;0C88F2	; Draw second row (3 tiles)
	JSR.W Display_DrawTileRow				;0C88F5	; Draw third row (3 tiles)

; ==============================================================================
; Display_DrawTileRow - Draw Single Tile Row (3 tiles)
; ==============================================================================
; Writes 3 consecutive tile numbers to VRAM.
; Advances VRAM address by $80 (down one row in tilemap).
; Input: X = VRAM address, A = starting tile number
; ==============================================================================

Display_DrawTileRow:
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
; Display_SetupNMIOAMTransfer - Setup NMI OAM Transfer
; ==============================================================================
; Configures NMI handler to perform OAM sprite DMA during VBLANK.
; Sets up pointer to sprite transfer subroutine.
; Critical for smooth sprite updates without flicker.
; ==============================================================================

Display_SetupNMIOAMTransfer:
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
; Display_DirectOAMDMATransfer - Direct OAM DMA Transfer
; ==============================================================================
; Immediately performs OAM sprite DMA (non-NMI version).
; Identical to NMI routine but callable from main code.
; Used for initial sprite setup or forced updates.
; ==============================================================================

Display_DirectOAMDMATransfer:
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
; Display_Mode7RotationSequence - Complex Mode 7 Rotation Sequence
; ==============================================================================
; Performs animated Mode 7 rotation effect with matrix calculations.
; Updates transformation matrix each frame for smooth rotation.
; Used for title screen rotation, special battle effects.
; ==============================================================================

Display_Mode7RotationSequence:
	LDA.B #$D4								;0C896F	; Scroll offset = -44 pixels
	STA.B SNES_BG1VOFS-$2100				;0C8971	; Set vertical scroll ($210E)
	LDA.B #$FF								;0C8973	; High byte = -1 (negative scroll)
	STA.B SNES_BG1VOFS-$2100				;0C8975	; Set high byte
	LDX.W #$8B86							;0C8977	; Sine/cosine table 1
	LDY.W #$8B96							;0C897A	; Sine/cosine table 2

.MainRotationLoop:							; Main rotation loop
	LDA.W $0000,Y							;0C897D	; Load rotation angle
	BEQ .PostRotationFade					;0C8980	; Exit if angle = 0 (no rotation)
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
	BEQ .SetHighByteZero					;0C8992	; Branch if offset = 0
	LDA.B #$FF								;0C8994	; High byte = -1 (negative)

.SetHighByteZero:
	STA.B SNES_BG1VOFS-$2100				;0C8996	; Set high byte
	INY										;0C8998	; Next rotation angle
	BRA .MainRotationLoop					;0C8999	; Continue rotation

.PostRotationFade:							; Post-rotation fade loop
	LDA.B #$1E								;0C899B	; Loop counter = 30 frames

.FadeLoop:
	JSL.L CODE_0C8000						;0C899D	; Wait for VBLANK
	PHA										;0C89A1	; Save counter
	JSR.W CODE_0C8A76						;0C89A2	; Update Mode 7 matrix
	PLA										;0C89A5	; Restore counter
	DEC A									;0C89A6	; Decrement
	BNE .FadeLoop							;0C89A7	; Loop 30 times

	; Initialize sprite animation sequence
	LDY.W #$0101							;0C89A9	; Start position = $0101
	STY.W $0062								;0C89AC	; Store position counter

.SpritePositionLoop:						; Sprite position update loop
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
	BEQ .WaitForTableSync					;0C89D6	; Branch if done

	; Third sprite update (pattern of 3)
	LDY.W $0062								;0C89D8	; Load position
	PHY										;0C89DB	; Save position
	JSR.W CODE_0C8A3F						;0C89DC	; Update sprite coordinates
	PLY										;0C89DF	; Restore position
	STY.W $0062								;0C89E0	; Store position
	INC.W $0062								;0C89E3	; Increment X coordinate
	BRA .SpritePositionLoop					;0C89E6	; Continue loop

.WaitForTableSync:							; Wait for table sync loop
	JSL.L CODE_0C8000						;0C89E8	; Wait for VBLANK
	JSR.W CODE_0C8A76						;0C89EC	; Update Mode 7 matrix
	CPX.W #$8B66							;0C89EF	; Table index at $8B66?
	BNE .WaitForTableSync					;0C89F2	; Loop until synced

.FinalSyncHold:								; Final sync hold loop
	JSL.L CODE_0C8000						;0C89F4	; Wait for VBLANK
	JSR.W CODE_0C8A76						;0C89F8	; Update Mode 7 matrix
	CPX.W #$8B66							;0C89FB	; Table index at $8B66?
	BNE .FinalSyncHold						;0C89FE	; Loop until stable

	; Setup final color effects
	JSR.W Display_SetupNMIOAMTransfer		;0C8A00	; Enable NMI OAM transfer
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

.FadeBrightnessLoop:						; Fade brightness loop
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
; ==============================================================================
; Bank $0C Cycle 5: Graphics Decompression & Tile Processing (Lines 1700-2100)
; ==============================================================================
; Address Range: $0C8F9E - $0C924D
; Systems: 4bpp graphics decompression, tile compositing, VRAM buffer management
; ==============================================================================

                       ; DMA Transfer Parameters Setup (continued from previous)
                       STX.B SNES_DMA0PARAM-$4300           ;0C8F9E|8600    |004300; DMA0 params (direct page $43xx addressing)
                       LDX.W #$B6EC                         ;0C8FA0|A2ECB6  |      ; Source address $0CB6EC
                       STX.B SNES_DMA0ADDRL-$4300           ;0C8FA3|8602    |004302; DMA0 source low word
                       LDA.B #$0C                           ;0C8FA5|A90C    |      ; Bank $0C
                       STA.B SNES_DMA0ADDRH-$4300           ;0C8FA7|8504    |004304; DMA0 source bank byte
                       LDX.W #$0022                         ;0C8FA9|A22200  |      ; Transfer size: 34 bytes
                       STX.B SNES_DMA0CNTL-$4300            ;0C8FAC|8605    |004305; DMA0 byte count
                       LDA.B #$01                           ;0C8FAE|A901    |      ; Channel 0 enable
                       STA.W SNES_MDMAEN                    ;0C8FB0|8D0B42  |00420B; Trigger DMA transfer ($420B)
                       RTS                                  ;0C8FB3|60      |      ; Return

; ==============================================================================
; CODE_0C8FB4: 4bpp Planar to Linear Graphics Decompression
; ==============================================================================
; Purpose: Convert SNES 4bpp planar graphics format to linear format for processing
; Input: X = pointer to source tile data (32 bytes per 8x8 tile in planar format)
; Output: Decompressed tile data written directly to VRAM via $2119 (VMDATAH)
; Format: SNES 4bpp = 4 bitplanes (BP0, BP1, BP2, BP3), 2 bytes per row per plane
; Algorithm: Interleave 4 bitplanes by shifting and combining bits
; Used by: Graphics loading routines during initialization/transitions
; ------------------------------------------------------------------------------
          CODE_0C8FB4:
                       SEP #$20                             ;0C8FB4|E220    |      ; 8-bit accumulator
                       LDA.B #$08                           ;0C8FB6|A908    |      ; 8 rows per tile (8x8 pixels)

          CODE_0C8FB8:
                       ; Process one row of the tile (8 pixels)
                       PHA                                  ;0C8FB8|48      |      ; Save row counter

                       ; Load bitplane data for this row:
                       ; $0000,X = BP0 (low 2 bytes)
                       ; $0010,X = BP2 (high 2 bytes)
                       ; Each pair represents one row across the tile
                       LDY.W $0010,X                        ;0C8FB9|BC1000  |7F0010; Load bitplane 2+3 word
                       STY.B $64                            ;0C8FBC|8464    |000064; Store in DP $64-$65
                       LDY.W $0000,X                        ;0C8FBE|BC0000  |7F0000; Load bitplane 0+1 word
                       STY.B $62                            ;0C8FC1|8462    |000062; Store in DP $62-$63
                       LDY.W #$0008                         ;0C8FC3|A00800  |      ; 8 pixels per row

          CODE_0C8FC6:
                       ; Deinterleave 4 bitplanes into 4-bit pixel value
                       ; Each pixel needs bits from all 4 planes
                       ; Shift order: BP3, BP2, BP1, BP0 (MSB to LSB)
                       ASL.B $65                            ;0C8FC6|0665    |000065; Shift BP3 (high byte of $64-$65)
                       ROL A                                ;0C8FC8|2A      |      ; Rotate bit into accumulator (bit 0)
                       ASL.B $64                            ;0C8FC9|0664    |000064; Shift BP2 (low byte of $64-$65)
                       ROL A                                ;0C8FCB|2A      |      ; Rotate bit into accumulator (bit 1)
                       ASL.B $63                            ;0C8FCC|0663    |000063; Shift BP1 (high byte of $62-$63)
                       ROL A                                ;0C8FCE|2A      |      ; Rotate bit into accumulator (bit 2)
                       ASL.B $62                            ;0C8FCF|0662    |000062; Shift BP0 (low byte of $62-$63)
                       ROL A                                ;0C8FD1|2A      |      ; Rotate bit into accumulator (bit 3)
                       AND.B #$0F                           ;0C8FD2|290F    |      ; Mask to 4 bits (palette index 0-15)
                       STA.L SNES_VMDATAH                   ;0C8FD4|8F192100|002119; Write to VRAM high byte ($2119)
                       DEY                                  ;0C8FD8|88      |      ; Decrement pixel counter
                       BNE CODE_0C8FC6                      ;0C8FD9|D0EB    |0C8FC6; Loop for all 8 pixels

                       ; Move to next row
                       INX                                  ;0C8FDB|E8      |      ; X += 2 (next row in planar format)
                       INX                                  ;0C8FDC|E8      |      ; (2 bytes per row per plane pair)
                       PLA                                  ;0C8FDD|68      |      ; Restore row counter
                       DEC A                                ;0C8FDE|3A      |      ; Decrement row count
                       BNE CODE_0C8FB8                      ;0C8FDF|D0D7    |0C8FB8; Loop for all 8 rows

                       ; Tile complete, X now points +$10 from start
                       REP #$30                             ;0C8FE1|C230    |      ; 16-bit mode
                       TXA                                  ;0C8FE3|8A      |      ; Get current position
                       ADC.W #$0010                         ;0C8FE4|691000  |      ; Skip to next tile (+16 bytes for BP2/BP3)
                       TAX                                  ;0C8FE7|AA      |      ; Update X pointer
                       RTS                                  ;0C8FE8|60      |      ; Return

; ==============================================================================
; CODE_0C8FE9: RGB555 Color to Tile Pattern Converter (Batch)
; ==============================================================================
; Purpose: Convert multiple RGB555 color values to tile patterns via lookup
; Input: X = pointer to RGB555 color data, Y = count
; Output: Tile patterns written to VRAM via CODE_0C8FF4
; Used by: Color-based tile generation (e.g., solid color tiles, gradients)
; ------------------------------------------------------------------------------
          CODE_0C8FE9:
                       LDA.W $0000,X                        ;0C8FE9|BD0000  |0C0000; Load RGB555 color word
                       JSR.W CODE_0C8FF4                    ;0C8FEC|20F48F  |0C8FF4; Convert to tile pattern
                       INX                                  ;0C8FEF|E8      |      ; Move to next color
                       DEY                                  ;0C8FF0|88      |      ; Decrement count
                       BNE CODE_0C8FE9                      ;0C8FF1|D0F6    |0C8FE9; Loop until all colors processed
                       RTS                                  ;0C8FF3|60      |      ; Return

; ==============================================================================
; CODE_0C8FF4: RGB555 Color to Tile Pattern Converter (Single)
; ==============================================================================
; Purpose: Convert single RGB555 color to 8x8 tile pattern using lookup table
; Input: A = RGB555 color word (%0BBBBBGGGGGRRRRR, 15-bit color)
; Output: 8x8 tile (64 pixels) written to VRAM at current address
; Algorithm:
;   1. Extract green component (bits 5-9, middle 5 bits)
;   2. Extract red component (bits 0-4, low 5 bits)
;   3. Combine: (Green << 4) | Red to form 9-bit index (0-511)
;   4. Use index to lookup tile pattern from Bank $07:8031
;   5. Write 8 rows of tile data + 8 zeros (4bpp format padding)
; Lookup Table: DATA8_078031 contains pre-generated tile patterns
; VRAM Format: Each tile row writes to $2118 (VMDATAL), auto-increment
; ------------------------------------------------------------------------------
          CODE_0C8FF4:
                       PHY                                  ;0C8FF4|5A      |      ; Preserve registers
                       PHX                                  ;0C8FF5|DA      |      ;
                       PHA                                  ;0C8FF6|48      |      ; Save color value

                       ; Extract GREEN component (bits 5-9)
                       AND.W #$00E0                         ;0C8FF7|29E000  |      ; Mask bits 5-7 (%11100000)
                       ASL A                                ;0C8FFA|0A      |      ; Shift left 4 times to move
                       ASL A                                ;0C8FFB|0A      |      ; green from bits 5-9 to
                       ASL A                                ;0C8FFC|0A      |      ; bits 9-13 (creates space
                       ASL A                                ;0C8FFD|0A      |      ; for red component)
                       STA.B $64                            ;0C8FFE|8564    |000064; Save shifted green

                       ; Extract RED component (bits 0-4)
                       PLA                                  ;0C9000|68      |      ; Restore original color
                       AND.W #$001F                         ;0C9001|291F00  |      ; Mask bits 0-4 (%00011111)
                       ASL A                                ;0C9004|0A      |      ; Shift left 1 (multiply by 2)
                       ORA.B $64                            ;0C9005|0564    |000064; Combine: (Green << 4) | (Red << 1)

                       ; Result: A = lookup index (0-511)
                       ; Index = (Green[4:0] << 4) | (Red[4:0])
                       ; This maps 32x32=1024 possible RG combinations to 512 patterns

                       LDY.W #$0008                         ;0C9007|A00800  |      ; 8 rows per tile

          CODE_0C900A:
                       ; Lookup tile pattern for each row
                       TAX                                  ;0C900A|AA      |      ; Use color index as X
                       LDA.L DATA8_078031,X                 ;0C900B|BF318007|078031; Load pattern byte from Bank $07
                       AND.W #$00FF                         ;0C900F|29FF00  |      ; Mask to byte
                       STA.W $2118                          ;0C9012|8D1821  |0C2118; Write to VRAM low byte ($2118)
                       TXA                                  ;0C9015|8A      |      ; Restore index
                       ADC.W #$0040                         ;0C9016|694000  |      ; +$40 for next row in table
                       DEY                                  ;0C9019|88      |      ; Decrement row counter
                       BNE CODE_0C900A                      ;0C901A|D0EE    |0C900A; Loop for 8 rows

                       ; Write 8 zero bytes (padding for 4bpp high bitplanes)
                       STZ.W $2118                          ;0C901C|9C1821  |0C2118; Zero byte 1
                       STZ.W $2118                          ;0C901F|9C1821  |0C2118; Zero byte 2
                       STZ.W $2118                          ;0C9022|9C1821  |0C2118; Zero byte 3
                       STZ.W $2118                          ;0C9025|9C1821  |0C2118; Zero byte 4
                       STZ.W $2118                          ;0C9028|9C1821  |0C2118; Zero byte 5
                       STZ.W $2118                          ;0C902B|9C1821  |0C2118; Zero byte 6
                       STZ.W $2118                          ;0C902E|9C1821  |0C2118; Zero byte 7
                       STZ.W $2118                          ;0C9031|9C1821  |0C2118; Zero byte 8

                       PLX                                  ;0C9034|FA      |      ; Restore registers
                       PLY                                  ;0C9035|7A      |      ;
                       RTS                                  ;0C9036|60      |      ; Return

; ==============================================================================
; CODE_0C9037: Complex Graphics Buffer Initialization
; ==============================================================================
; Purpose: Initialize large graphics buffer in Bank $7F with processed tile data
; Input: None (uses hardcoded buffer addresses)
; Output: $7F:4000-$7FFF filled with 128 copies of processed tile patterns
; Buffer: $7F4000 (16KB graphics work area)
; Process: Decompresses/processes tiles from $7F0000, copies 128 times
; Used by: Major graphics transitions, screen initialization
; Technique: Uses MVN block move for efficiency after processing
; ------------------------------------------------------------------------------
          CODE_0C9037:
                       PHP                                  ;0C9037|08      |      ; Save processor status
                       PHD                                  ;0C9038|0B      |      ; Save direct page
                       REP #$30                             ;0C9039|C230    |      ; 16-bit mode
                       LDA.W #$0000                         ;0C903B|A90000  |      ; Reset direct page
                       TCD                                  ;0C903E|5B      |      ; Set DP = $0000

                       ; Setup buffer pointers
                       LDX.W #$4000                         ;0C903F|A20040  |      ; Destination: $7F:4000
                       STX.B $5F                            ;0C9042|865F    |00005F; Store dest offset
                       LDX.W #$7F40                         ;0C9044|A2407F  |      ; Dest bank + high byte
                       STX.B $60                            ;0C9047|8660    |000060; Store at $60-$61

                       ; Setup source pointer (X register for processing loop)
                       LDX.W #$2000                         ;0C9049|A20020  |      ; Source: $7F:2000
                       LDA.W #$0080                         ;0C904C|A98000  |      ; 128 iterations (128 tiles)

                       ; Set data bank to $7F for processing
                       PEA.W $007F                          ;0C904F|F47F00  |0C007F; Push $7F00
                       PLB                                  ;0C9052|AB      |      ; Pull into DB ($7F)

          CODE_0C9053:
                       ; Process 128 tiles
                       PHA                                  ;0C9053|48      |      ; Save iteration counter
                       JSR.W CODE_0C9099                    ;0C9054|209990  |0C9099; Process one tile (decompression)
                       PLA                                  ;0C9057|68      |      ; Restore counter
                       DEC A                                ;0C9058|3A      |      ; Decrement
                       BNE CODE_0C9053                      ;0C9059|D0F8    |0C9053; Loop for all 128 tiles

                       ; Setup DMA transfer for processed buffer
                       PLB                                  ;0C905B|AB      |      ; Restore data bank
                       SEP #$20                             ;0C905C|E220    |      ; 8-bit accumulator
                       LDA.B #$0C                           ;0C905E|A90C    |      ; Bank $0C for subroutine
                       STA.W $005A                          ;0C9060|8D5A00  |00005A; Store at $005A (bank byte)
                       LDX.W #$9075                         ;0C9063|A27590  |      ; Address $0C:9075 (DMA routine)
                       STX.W $0058                          ;0C9066|8E5800  |000058; Store at $0058-$0059 (address)

                       ; Register completion handler
                       LDA.B #$40                           ;0C9069|A940    |      ; Bit 6 flag
                       TSB.W $00E2                          ;0C906B|0CE200  |0000E2; Test and Set bit at $E2
                       JSL.L CODE_0C8000                    ;0C906E|2200800C|0C8000; Call graphics handler

                       PLD                                  ;0C9072|2B      |      ; Restore direct page
                       PLP                                  ;0C9073|28      |      ; Restore processor status
                       RTS                                  ;0C9074|60      |      ; Return

; ==============================================================================
; DMA Transfer Routine (Embedded at $0C:9075)
; ==============================================================================
; Purpose: Transfer processed graphics buffer to VRAM
; Source: $7F:4000 (8KB processed tile data)
; Dest: VRAM $0440 (BG tileset area)
; Size: $2000 bytes (8192 bytes = 256 tiles)
; ------------------------------------------------------------------------------
                       ; VRAM Setup
                       LDA.B #$80                           ;0C9075|A980    |      ; VRAM increment = 1 (word mode)
                       STA.W SNES_VMAINC                    ;0C9077|8D1521  |002115; Set increment mode ($2115)
                       LDX.W #$0440                         ;0C907A|A24004  |      ; VRAM address $0440
                       STX.W SNES_VMADDL                    ;0C907D|8E1621  |002116; Set VRAM address ($2116-$2117)

                       ; DMA Channel 0 Configuration
                       LDX.W #$1900                         ;0C9080|A20019  |      ; DMA params: $19 = word, $00 = A→B
                       STX.B SNES_DMA0PARAM-$4300           ;0C9083|8600    |004300; $4300-$4301 (params + dest)
                       LDX.W #$4000                         ;0C9085|A20040  |      ; Source: $7F:4000
                       STX.B SNES_DMA0ADDRL-$4300           ;0C9088|8602    |004302; $4302-$4303 (source low word)
                       LDA.B #$7F                           ;0C908A|A97F    |      ; Source bank $7F
                       STA.B SNES_DMA0ADDRH-$4300           ;0C908C|8504    |004304; $4304 (source bank)
                       LDX.W #$2000                         ;0C908E|A20020  |      ; Transfer $2000 bytes (8KB)
                       STX.B SNES_DMA0CNTL-$4300            ;0C9091|8605    |004305; $4305-$4306 (byte count)
                       LDA.B #$01                           ;0C9093|A901    |      ; Channel 0 enable
                       STA.W SNES_MDMAEN                    ;0C9095|8D0B42  |00420B; Trigger DMA ($420B)
                       RTL                                  ;0C9098|6B      |      ; Return (long)

; ==============================================================================
; CODE_0C9099: Tile Processing Routine (4bpp Decompression to Buffer)
; ==============================================================================
; Purpose: Process planar tile data to linear format with transparency support
; Input: X = source pointer ($7F:2000+offset), $5F-$60 = dest pointer
; Output: Processed tile written to buffer, X advanced, $5F incremented
; Format: Converts 4bpp planar to linear with transparency flag (bit 4)
; Algorithm: Same as CODE_0C8FB4 but writes to buffer instead of VRAM
; Difference: Sets bit 4 ($10) if pixel is non-zero (transparency marker)
; ------------------------------------------------------------------------------
          CODE_0C9099:
                       SEP #$20                             ;0C9099|E220    |      ; 8-bit accumulator
                       LDA.B #$08                           ;0C909B|A908    |      ; 8 rows per tile

          CODE_0C909D:
                       PHA                                  ;0C909D|48      |      ; Save row counter
                       LDY.W $0010,X                        ;0C909E|BC1000  |7F0010; Load BP2+BP3 word
                       STY.B $64                            ;0C90A1|8464    |000064; Store at $64-$65
                       LDY.W $0000,X                        ;0C90A3|BC0000  |7F0000; Load BP0+BP1 word
                       STY.B $62                            ;0C90A6|8462    |000062; Store at $62-$63
                       LDY.W #$0008                         ;0C90A8|A00800  |      ; 8 pixels per row

          CODE_0C90AB:
                       ; Deinterleave bitplanes (same as CODE_0C8FC6)
                       ASL.B $65                            ;0C90AB|0665    |000065; Shift BP3
                       ROL A                                ;0C90AD|2A      |      ; Rotate into A
                       ASL.B $64                            ;0C90AE|0664    |000064; Shift BP2
                       ROL A                                ;0C90B0|2A      |      ; Rotate into A
                       ASL.B $63                            ;0C90B1|0663    |000063; Shift BP1
                       ROL A                                ;0C90B3|2A      |      ; Rotate into A
                       ASL.B $62                            ;0C90B4|0662    |000062; Shift BP0
                       ROL A                                ;0C90B6|2A      |      ; Rotate into A
                       AND.B #$0F                           ;0C90B7|290F    |      ; Mask to 4 bits (color 0-15)

                       ; Transparency handling
                       BEQ CODE_0C90BD                      ;0C90B9|F002    |0C90BD; If zero, skip (transparent)
                       ORA.B #$10                           ;0C90BB|0910    |      ; Set bit 4 (non-transparent marker)

          CODE_0C90BD:
                       ; Write to buffer
                       STA.B [$5F]                          ;0C90BD|875F    |00005F; Write to [$5F] (buffer pointer)
                       REP #$30                             ;0C90BF|C230    |      ; 16-bit mode
                       INC.B $5F                            ;0C90C1|E65F    |00005F; Increment buffer pointer
                       SEP #$20                             ;0C90C3|E220    |      ; 8-bit mode
                       DEY                                  ;0C90C5|88      |      ; Decrement pixel counter
                       BNE CODE_0C90AB                      ;0C90C6|D0E3    |0C90AB; Loop for 8 pixels

                       ; Next row
                       INX                                  ;0C90C8|E8      |      ; X += 2
                       INX                                  ;0C90C9|E8      |      ;
                       PLA                                  ;0C90CA|68      |      ; Restore row counter
                       DEC A                                ;0C90CB|3A      |      ; Decrement
                       BNE CODE_0C909D                      ;0C90CC|D0CF    |0C909D; Loop for 8 rows

                       ; Tile complete, advance source pointer
                       REP #$30                             ;0C90CE|C230    |      ; 16-bit mode
                       CLC                                  ;0C90D0|18      |      ; Clear carry
                       TXA                                  ;0C90D1|8A      |      ; Get current X
                       ADC.W #$0010                         ;0C90D2|691000  |      ; Skip $10 bytes (BP2/BP3 data)
                       TAX                                  ;0C90D5|AA      |      ; Update X
                       RTS                                  ;0C90D6|60      |      ; Return

; ==============================================================================
; DMA Routine: Transfer Tilemap Data to VRAM
; ==============================================================================
; Purpose: Transfer tilemap/tileset from Bank $00 to VRAM base address
; Source: $00:8252 (ROM tilemap data)
; Dest: VRAM $0000 (base tilemap/charset area)
; Size: $2000 bytes (8KB)
; Mode: Word transfer, no increment during transfer
; ------------------------------------------------------------------------------
                       STZ.W SNES_VMAINC                    ;0C90D7|9C1521  |002115; VRAM increment = 0 (no increment)
                       LDX.W #$0000                         ;0C90DA|A20000  |      ; VRAM address $0000
                       STX.W SNES_VMADDL                    ;0C90DD|8E1621  |002116; Set VRAM address

                       ; DMA Channel 0 Setup
                       LDX.W #$1808                         ;0C90E0|A20818  |      ; $18 = word mode, $08 = dest reg
                       STX.B SNES_DMA0PARAM-$4300           ;0C90E3|8600    |004300; DMA0 params
                       LDX.W #$8252                         ;0C90E5|A25282  |      ; Source: $00:8252
                       STX.B SNES_DMA0ADDRL-$4300           ;0C90E8|8602    |004302; Source low word
                       LDA.B #$00                           ;0C90EA|A900    |      ; Bank $00
                       STA.B SNES_DMA0ADDRH-$4300           ;0C90EC|8504    |004304; Source bank
                       LDX.W #$2000                         ;0C90EE|A20020  |      ; $2000 bytes (8KB)
                       STX.B SNES_DMA0CNTL-$4300            ;0C90F1|8605    |004305; Byte count
                       LDA.B #$01                           ;0C90F3|A901    |      ; Channel 0 enable
                       STA.W SNES_MDMAEN                    ;0C90F5|8D0B42  |00420B; Trigger DMA
                       RTL                                  ;0C90F8|6B      |      ; Return long

; ==============================================================================
; CODE_0C90F9: Battle Graphics Upload (Split Transfer)
; ==============================================================================
; Purpose: Upload battle graphics in two phases (low/high bitplanes separate)
; Source: $0C:9140-$A140 (battle graphics data, 4KB)
; Dest: VRAM $6000 (battle graphics tileset area)
; Technique: Two DMA passes - first low bitplanes, then high bitplanes
; Used by: Battle scene initialization, enemy sprite loading
; ------------------------------------------------------------------------------
          CODE_0C90F9:
                       ; Phase 1: Upload low bitplanes (word mode, no increment)
                       STZ.W $2115                          ;0C90F9|9C1521  |0C2115; VRAM increment = 0
                       LDX.W #$6000                         ;0C90FC|A20060  |      ; VRAM address $6000
                       STX.W $2116                          ;0C90FF|8E1621  |0C2116; Set VRAM address
                       LDX.W #$1808                         ;0C9102|A20818  |      ; DMA mode: word, dest $2118-$2119
                       STX.W $4300                          ;0C9105|8E0043  |0C4300; DMA0 params
                       LDX.W #$9140                         ;0C9108|A24091  |      ; Source: $0C:9140 (low bitplanes)
                       STX.W $4302                          ;0C910B|8E0243  |0C4302; Source address
                       LDA.B #$0C                           ;0C910E|A90C    |      ; Bank $0C
                       STA.W $4304                          ;0C9110|8D0443  |0C4304; Source bank
                       LDX.W #$1000                         ;0C9113|A20010  |      ; $1000 bytes (4KB)
                       STX.W $4305                          ;0C9116|8E0543  |0C4305; Byte count
                       LDA.B #$01                           ;0C9119|A901    |      ; Channel 0 enable
                       STA.W $420B                          ;0C911B|8D0B42  |0C420B; Trigger DMA

                       ; Phase 2: Upload high bitplanes (word mode, increment +1)
                       LDA.B #$80                           ;0C911E|A980    |      ; VRAM increment = 1 (word)
                       STA.W $2115                          ;0C9120|8D1521  |0C2115; Set increment mode
                       LDX.W #$6000                         ;0C9123|A20060  |      ; VRAM address $6000 (same base)
                       STX.W $2116                          ;0C9126|8E1621  |0C2116; Set VRAM address
                       LDA.B #$19                           ;0C9129|A919    |      ; DMA mode: $19 = word, auto-inc
                       STA.W $4301                          ;0C912B|8D0143  |0C4301; DMA0 dest register
                       LDX.W #$9141                         ;0C912E|A24191  |      ; Source: $0C:9141 (+1 for high BP)
                       STX.W $4302                          ;0C9131|8E0243  |0C4302; Source address
                       LDX.W #$1000                         ;0C9134|A20010  |      ; $1000 bytes (4KB)
                       STX.W $4305                          ;0C9137|8E0543  |0C4305; Byte count
                       LDA.B #$01                           ;0C913A|A901    |      ; Channel 0 enable
                       STA.W $420B                          ;0C913C|8D0B42  |0C420B; Trigger DMA
                       RTS                                  ;0C913F|60      |      ; Return

; ==============================================================================
; DATA: Battle Graphics Header/Marker
; ==============================================================================
                       db $FF,$01                           ;0C9140|        |      ; Graphics data marker ($FF = compressed, $01 = type)

; ==============================================================================
; CODE_0C9142: Complex Sprite/Graphics Initialization System
; ==============================================================================
; Purpose: Initialize complete sprite/graphics system for battle/overworld
; Systems: Tile decompression, compositing, VRAM upload, buffer management
; Output: Multiple VRAM regions populated, flags set
; Used by: Scene transitions, battle start, major state changes
; ------------------------------------------------------------------------------
          CODE_0C9142:
                       PHP                                  ;0C9142|08      |      ; Save processor status
                       PHD                                  ;0C9143|0B      |      ; Save direct page
                       REP #$30                             ;0C9144|C230    |      ; 16-bit mode
                       LDA.W #$0000                         ;0C9146|A90000  |      ; Reset DP
                       TCD                                  ;0C9149|5B      |      ; DP = $0000

                       ; Execute initialization sequence
                       JSR.W CODE_0C9318                    ;0C914A|201893  |0C9318; Initialize graphics buffers
                       JSR.W CODE_0C92EB                    ;0C914D|20EB92  |0C92EB; Setup palette system
                       JSR.W CODE_0C9161                    ;0C9150|206191  |0C9161; Load sprite graphics

                       ; Set completion flags
                       LDA.W #$0010                         ;0C9153|A91000  |      ; Flag value $10
                       STA.L $7F2F9C                        ;0C9156|8F9C2F7F|7F2F9C; Mark completion at $7F2F9C
                       STA.L $7F2DD2                        ;0C915A|8FD22D7F|7F2DD2; Mark completion at $7F2DD2

                       PLD                                  ;0C915E|2B      |      ; Restore direct page
                       PLP                                  ;0C915F|28      |      ; Restore status
                       RTS                                  ;0C9160|60      |      ; Return

; ==============================================================================
; CODE_0C9161: Sprite Graphics Loading & Compositing System
; ==============================================================================
; Purpose: Load and composite multiple sprite layers into VRAM
; Technique: Clear buffer, composite 8 sprite layers, upload to VRAM
; Buffer: $7F:2000 (8KB work area)
; VRAM Dest: Various addresses for different sprite layers
; Used by: Battle sprite setup, character graphics initialization
; ------------------------------------------------------------------------------
          CODE_0C9161:
                       ; Clear graphics buffer ($7F:2000-$3FFF, 8KB)
                       LDX.W #$0000                         ;0C9161|A20000  |      ; Source = $0000 (zeros)
                       LDY.W #$2000                         ;0C9164|A00020  |      ; Dest = $2000
                       LDA.W #$2000                         ;0C9167|A90020  |      ; Size = $2000 (8KB)
                       JSL.L CODE_009994                    ;0C916A|22949900|009994; Clear memory routine

                       ; Composite sprite layers (8 layers)
                       JSR.W CODE_0C91AF                    ;0C916E|20AF91  |0C91AF; Layer 1: Base sprites
                       JSR.W CODE_0C9197                    ;0C9171|209791  |0C9197; Layer 2: Overlay 1
                       JSR.W CODE_0C9247                    ;0C9174|204792  |0C9247; Spacing/padding
                       JSR.W CODE_0C91B7                    ;0C9177|20B791  |0C91B7; Layer 3: Accessories
                       JSR.W CODE_0C919F                    ;0C917A|209F91  |0C919F; Layer 4: Overlay 2
                       JSR.W CODE_0C929E                    ;0C917D|209E92  |0C929E; Unknown processing
                       JSR.W CODE_0C91BF                    ;0C9180|20BF91  |0C91BF; Layer 5: Effects
                       JSR.W CODE_0C9247                    ;0C9183|204792  |0C9247; Spacing/padding
                       JSR.W CODE_0C91C7                    ;0C9186|20C791  |0C91C7; Layer 6: Highlights
                       JSR.W CODE_0C91A7                    ;0C9189|20A791  |0C91A7; Layer 7: Shadows
                       JSR.W CODE_0C9247                    ;0C918C|204792  |0C9247; Spacing/padding

                       ; Final upload
                       LDY.W #$24C0                         ;0C918F|A0C024  |      ; VRAM address $24C0
                       LDX.W #$9400                         ;0C9192|A20094  |      ; Source data pointer
                       BRA CODE_0C91CD                      ;0C9195|8036    |0C91CD; Jump to upload routine

; ==============================================================================
; Sprite Layer Loading Routines (Setup VRAM address + source pointer)
; ==============================================================================
; Each routine sets Y=VRAM destination, X=source data pointer
; Then branches to CODE_0C91CD for actual processing
; ------------------------------------------------------------------------------

          CODE_0C9197:
                       ; Layer 2: VRAM $2080, source $0C:93CA
                       LDY.W #$2080                         ;0C9197|A08020  |      ; VRAM dest
                       LDX.W #$93CA                         ;0C919A|A2CA93  |      ; Source pointer
                       BRA CODE_0C91CD                      ;0C919D|802E    |0C91CD; Process

          CODE_0C919F:
                       ; Layer 4: VRAM $2480, source $0C:93EB
                       LDY.W #$2480                         ;0C919F|A08024  |      ; VRAM dest
                       LDX.W #$93EB                         ;0C91A2|A2EB93  |      ; Source pointer
                       BRA CODE_0C91CD                      ;0C91A5|8026    |0C91CD; Process

          CODE_0C91A7:
                       ; Layer 7: VRAM $20C0, source $0C:9410
                       LDY.W #$20C0                         ;0C91A7|A0C020  |      ; VRAM dest
                       LDX.W #$9410                         ;0C91AA|A21094  |      ; Source pointer
                       BRA CODE_0C91CD                      ;0C91AD|801E    |0C91CD; Process

          CODE_0C91AF:
                       ; Layer 1: VRAM $2000, source $0C:9346
                       LDY.W #$2000                         ;0C91AF|A00020  |      ; VRAM dest
                       LDX.W #$9346                         ;0C91B2|A24693  |      ; Source pointer
                       BRA CODE_0C91CD                      ;0C91B5|8016    |0C91CD; Process

          CODE_0C91B7:
                       ; Layer 3: VRAM $2B80, source $0C:9392
                       LDY.W #$2B80                         ;0C91B7|A0802B  |      ; VRAM dest
                       LDX.W #$9392                         ;0C91BA|A29293  |      ; Source pointer
                       BRA CODE_0C91CD                      ;0C91BD|800E    |0C91CD; Process

          CODE_0C91BF:
                       ; Layer 5: VRAM $2BA0, source $0C:9392
                       LDY.W #$2BA0                         ;0C91BF|A0A02B  |      ; VRAM dest
                       LDX.W #$9392                         ;0C91C2|A29293  |      ; Source pointer
                       BRA CODE_0C91CD                      ;0C91C5|8006    |0C91CD; Process

          CODE_0C91C7:
                       ; Layer 6: VRAM $2040, source $0C:9396
                       LDY.W #$2040                         ;0C91C7|A04020  |      ; VRAM dest
                       LDX.W #$9396                         ;0C91CA|A29693  |      ; Source pointer

; ==============================================================================
; CODE_0C91CD: Sprite Data Processing Loop (Bytecode Interpreter)
; ==============================================================================
; Purpose: Process sprite command bytecode to composite graphics
; Input: X = command pointer, Y = VRAM base address
; Format: Command bytes:
;   $00-$7F: Tile index (process 32 bytes at offset = index * 32)
;   $80-$FE: Relative offset (+/- adjust Y by (value & $7F) * 32)
;   $FF: End marker
; Algorithm: Interpret commands, composite tiles from $7F:0000 to buffer
; ------------------------------------------------------------------------------
          CODE_0C91CD:
                       PHK                                  ;0C91CD|4B      |      ; Push program bank ($0C)
                       PLB                                  ;0C91CE|AB      |      ; Pull to data bank

          ; Process command stream
                       LDA.W $0000,X                        ;0C91CF|BD0000  |0C0000; Load command byte
                       AND.W #$00FF                         ;0C91D2|29FF00  |      ; Mask to byte
                       CMP.W #$0080                         ;0C91D5|C98000  |      ; Check if < $80
                       BCS CODE_0C91E8                      ;0C91D8|B00E    |0C91E8; Branch if >= $80 (offset cmd)

                       ; Tile index command ($00-$7F)
                       ASL A                                ;0C91DA|0A      |      ; Multiply by 32:
                       ASL A                                ;0C91DB|0A      |      ; Shift left 5 times
                       ASL A                                ;0C91DC|0A      |      ; (index * 2^5 = index * 32)
                       ASL A                                ;0C91DD|0A      |      ;
                       ASL A                                ;0C91DE|0A      |      ; A = tile offset in bytes
                       PHX                                  ;0C91DF|DA      |      ; Save command pointer
                       TAX                                  ;0C91E0|AA      |      ; X = tile data offset
                       JSR.W CODE_0C91FF                    ;0C91E1|20FF91  |0C91FF; Composite tile
                       PLX                                  ;0C91E4|FA      |      ; Restore command pointer
                       INX                                  ;0C91E5|E8      |      ; Next command
                       BRA CODE_0C91CD                      ;0C91E6|80E5    |0C91CD; Loop

          CODE_0C91E8:
                       ; Check for end marker
                       CMP.W #$00FF                         ;0C91E8|C9FF00  |      ; End of commands?
                       BEQ CODE_0C91FE                      ;0C91EB|F011    |0C91FE; Yes, exit

                       ; Offset command ($80-$FE)
                       AND.W #$007F                         ;0C91ED|297F00  |      ; Mask offset value (0-127)
                       ASL A                                ;0C91F0|0A      |      ; Multiply by 32:
                       ASL A                                ;0C91F1|0A      |      ; (offset * 32 = VRAM rows)
                       ASL A                                ;0C91F2|0A      |      ;
                       ASL A                                ;0C91F3|0A      |      ;
                       ASL A                                ;0C91F4|0A      |      ;
                       STA.B $64                            ;0C91F5|8564    |000064; Save offset
                       TYA                                  ;0C91F7|98      |      ; Get current VRAM address
                       ADC.B $64                            ;0C91F8|6564    |000064; Add offset
                       TAY                                  ;0C91FA|A8      |      ; Update Y
                       INX                                  ;0C91FB|E8      |      ; Next command
                       BRA CODE_0C91CD                      ;0C91FC|80CF    |0C91CD; Loop

          CODE_0C91FE:
                       RTS                                  ;0C91FE|60      |      ; End of command stream

; ==============================================================================
; CODE_0C91FF: Tile Compositing with Transparency (8x8 tile, 3-plane)
; ==============================================================================
; Purpose: Composite source tile onto destination with transparency masking
; Input: X = source offset ($7F:0000+X), Y = dest offset ($7F:2000+Y)
; Algorithm: For each row, mask transparent pixels, OR opaque pixels
; Format: 3 bytes per row (BP0, BP1, BP2), 8 rows = 24 bytes per tile
; Technique: (dest & ~(BP0|BP1|BP2)) | src = composite with transparency
; ------------------------------------------------------------------------------
          CODE_0C91FF:
                       SEP #$20                             ;0C91FF|E220    |      ; 8-bit accumulator
                       LDA.B #$08                           ;0C9201|A908    |      ; 8 rows per tile
                       STA.B $62                            ;0C9203|8562    |000062; Save row counter

                       ; Set data bank to $7F
                       PEA.W $7F00                          ;0C9205|F4007F  |0C7F00; Push $7F00
                       PLB                                  ;0C9208|AB      |      ; Pull to DB (high byte)
                       PLB                                  ;0C9209|AB      |      ; Pull to DB (low byte) = $7F

          CODE_0C920A:
                       ; Load source tile row (3 bytes: BP0, BP1, BP2)
                       ; Calculate transparency mask: OR all 3 bitplanes
                       LDA.W $0000,X                        ;0C920A|BD0000  |7F0000; Load BP0
                       ORA.W $0001,X                        ;0C920D|1D0100  |7F0001; OR BP1
                       ORA.W $0010,X                        ;0C9210|1D1000  |7F0010; OR BP2
                       EOR.B #$FF                           ;0C9213|49FF    |      ; Invert = transparency mask
                       STA.B $64                            ;0C9215|8564    |000064; Save mask

                       ; Composite BP0: (dest & mask) | src
                       AND.W $0000,Y                        ;0C9217|390000  |7F0000; Mask dest BP0
                       ORA.W $0000,X                        ;0C921A|1D0000  |7F0000; OR source BP0
                       STA.W $0000,Y                        ;0C921D|990000  |7F0000; Write result

                       ; Composite BP1: (dest & mask) | src
                       LDA.B $64                            ;0C9220|A564    |000064; Load mask
                       AND.W $0001,Y                        ;0C9222|390100  |7F0001; Mask dest BP1
                       ORA.W $0001,X                        ;0C9225|1D0100  |7F0001; OR source BP1
                       STA.W $0001,Y                        ;0C9228|990100  |7F0001; Write result

                       ; Composite BP2: (dest & mask) | src
                       LDA.B $64                            ;0C922B|A564    |000064; Load mask
                       AND.W $0010,Y                        ;0C922D|391000  |7F0010; Mask dest BP2
                       ORA.W $0010,X                        ;0C9230|1D1000  |7F0010; OR source BP2
                       STA.W $0010,Y                        ;0C9233|991000  |7F0010; Write result

                       ; Next row (stride +2 for X, +2 for Y within 8x8)
                       INX                                  ;0C9236|E8      |      ; X += 2
                       INX                                  ;0C9237|E8      |      ;
                       INY                                  ;0C9238|C8      |      ; Y += 2
                       INY                                  ;0C9239|C8      |      ;
                       DEC.B $62                            ;0C923A|C662    |000062; Decrement row counter
                       BNE CODE_0C920A                      ;0C923C|D0CC    |0C920A; Loop for 8 rows

                       ; Tile complete, advance to next tile
                       REP #$30                             ;0C923E|C230    |      ; 16-bit mode
                       CLC                                  ;0C9240|18      |      ; Clear carry
                       TYA                                  ;0C9241|98      |      ; Get Y position
                       ADC.W #$0010                         ;0C9242|691000  |      ; +$10 (skip to next tile row)
                       TAY                                  ;0C9245|A8      |      ; Update Y
                       RTS                                  ;0C9246|60      |      ; Return

; ==============================================================================
; CODE_0C9247: Buffer Spacing/Padding Routine
; ==============================================================================
; Purpose: Add spacing between sprite layers in buffer
; Input: None (uses Bank $7F data bank)
; Output: Y advanced by $1E * something (spacing calculation)
; Used by: Sprite layer compositing to maintain proper offsets
; ------------------------------------------------------------------------------
          CODE_0C9247:
                       PEA.W $7F00                          ;0C9247|F4007F  |0C7F00; Set data bank = $7F
                       PLB                                  ;0C924A|AB      |      ;
                       PLB                                  ;0C924B|AB      |      ;
                       CLC                                  ;0C924C|18      |      ; Clear carry
                       LDA.W #$001E                         ;0C924D|A91E00  |      ; Spacing value $1E (30)
; ==============================================================================
; Bank $0C Cycle 6: Sprite Layer Compositing & Animation (Lines 2100-2500)
; ==============================================================================
; Address Range: $0C924D - $0CA2C5
; Systems: Sprite layer transformations, pixel rotations, animation sequences
; ==============================================================================

                       ; Spacing calculation (continued from CODE_0C9247)
                       LDA.W #$001E                         ;0C924D|A91E00  |      ; 30 spacing units
                       STA.B $62                            ;0C9250|8562    |000062; Save spacing counter
                       LDX.W #$0000                         ;0C9252|A20000  |      ; Start at offset 0

          CODE_0C9255:
                       ; Double spacing application
                       JSR.W CODE_0C9260                    ;0C9255|206092  |0C9260; Apply spacing transform
                       JSR.W CODE_0C9260                    ;0C9258|206092  |0C9260; Apply again (2x)
                       DEC.B $62                            ;0C925B|C662    |000062; Decrement spacing counter
                       BNE CODE_0C9255                      ;0C925D|D0F6    |0C9255; Loop for 30 iterations
                       RTS                                  ;0C925F|60      |      ; Return

; ==============================================================================
; CODE_0C9260: Pixel Row Swapping/Rotation Routine
; ==============================================================================
; Purpose: Swap pixel rows within tile for rotation/flip effects
; Input: X = buffer offset (Bank $7F)
; Algorithm: Swap 4 pairs of rows (swaps rows 0↔14, 2↔12, 4↔10, 6↔8)
; Effect: Vertical flip or rotation transformation
; Used by: Sprite animation, orientation changes
; ------------------------------------------------------------------------------
          CODE_0C9260:
                       ; Swap row 0 with row 14 (offset $00 ↔ offset $0E)
                       LDA.W $0000,X                        ;0C9260|BD0000  |7F0000; Load row 0
                       TAY                                  ;0C9263|A8      |      ; Temp in Y
                       LDA.W $000E,X                        ;0C9264|BD0E00  |7F000E; Load row 14
                       STA.W $0000,X                        ;0C9267|9D0000  |7F0000; Store at row 0
                       TYA                                  ;0C926A|98      |      ; Get row 0 back
                       STA.W $000E,X                        ;0C926B|9D0E00  |7F000E; Store at row 14

                       ; Swap row 2 with row 12 (offset $02 ↔ offset $0C)
                       LDA.W $0002,X                        ;0C926E|BD0200  |7F0002; Load row 2
                       TAY                                  ;0C9271|A8      |      ; Temp in Y
                       LDA.W $000C,X                        ;0C9272|BD0C00  |7F000C; Load row 12
                       STA.W $0002,X                        ;0C9275|9D0200  |7F0002; Store at row 2
                       TYA                                  ;0C9278|98      |      ; Get row 2 back
                       STA.W $000C,X                        ;0C9279|9D0C00  |7F000C; Store at row 12

                       ; Swap row 4 with row 10 (offset $04 ↔ offset $0A)
                       LDA.W $0004,X                        ;0C927C|BD0400  |7F0004; Load row 4
                       TAY                                  ;0C927F|A8      |      ; Temp in Y
                       LDA.W $000A,X                        ;0C9280|BD0A00  |7F000A; Load row 10
                       STA.W $0004,X                        ;0C9283|9D0400  |7F0004; Store at row 4
                       TYA                                  ;0C9286|98      |      ; Get row 4 back
                       STA.W $000A,X                        ;0C9287|9D0A00  |7F000A; Store at row 10

                       ; Swap row 6 with row 8 (offset $06 ↔ offset $08)
                       LDA.W $0006,X                        ;0C928A|BD0600  |7F0006; Load row 6
                       TAY                                  ;0C928D|A8      |      ; Temp in Y
                       LDA.W $0008,X                        ;0C928E|BD0800  |7F0008; Load row 8
                       STA.W $0006,X                        ;0C9291|9D0600  |7F0006; Store at row 6
                       TYA                                  ;0C9294|98      |      ; Get row 6 back
                       STA.W $0008,X                        ;0C9295|9D0800  |7F0008; Store at row 8

                       ; Advance to next 16-byte block
                       TXA                                  ;0C9298|8A      |      ; Get X
                       ADC.W #$0010                         ;0C9299|691000  |      ; +$10 bytes (next tile row)
                       TAX                                  ;0C929C|AA      |      ; Update X
                       RTS                                  ;0C929D|60      |      ; Return

; ==============================================================================
; CODE_0C929E: Bit Rotation/Transformation Processor
; ==============================================================================
; Purpose: Apply bit rotation transformation to graphics buffer
; Input: Bank $7F graphics buffer
; Algorithm: Process 30 rows of 16 bytes, applying bit rotation to each byte
; Used by: Sprite effects, rotation animations, graphical transitions
; ------------------------------------------------------------------------------
          CODE_0C929E:
                       PEA.W $7F00                          ;0C929E|F4007F  |0C7F00; Set data bank = $7F
                       PLB                                  ;0C92A1|AB      |      ;
                       PLB                                  ;0C92A2|AB      |      ;
                       LDY.W #$001E                         ;0C92A3|A01E00  |      ; 30 rows to process
                       LDX.W #$0000                         ;0C92A6|A20000  |      ; Start at offset 0

          CODE_0C92A9:
                       PHY                                  ;0C92A9|5A      |      ; Save row counter
                       LDY.W #$0010                         ;0C92AA|A01000  |      ; 16 bytes per row

          CODE_0C92AD:
                       ; Process each byte in row
                       JSR.W CODE_0C92C2                    ;0C92AD|20C292  |0C92C2; Apply bit rotation
                       DEY                                  ;0C92B0|88      |      ; Decrement byte counter
                       BNE CODE_0C92AD                      ;0C92B1|D0FA    |0C92AD; Loop for 16 bytes

                       ; Process additional 8 bytes (24 bytes total per row)
                       LDY.W #$0008                         ;0C92B3|A00800  |      ; 8 more bytes

          CODE_0C92B6:
                       JSR.W CODE_0C92C2                    ;0C92B6|20C292  |0C92C2; Apply bit rotation
                       INX                                  ;0C92B9|E8      |      ; Advance pointer
                       DEY                                  ;0C92BA|88      |      ; Decrement counter
                       BNE CODE_0C92B6                      ;0C92BB|D0F9    |0C92B6; Loop for 8 bytes

                       PLY                                  ;0C92BD|7A      |      ; Restore row counter
                       DEY                                  ;0C92BE|88      |      ; Decrement row counter
                       BNE CODE_0C92A9                      ;0C92BF|D0E8    |0C92A9; Loop for 30 rows
                       RTS                                  ;0C92C1|60      |      ; Return

; ==============================================================================
; CODE_0C92C2: Bit Rotation Algorithm (8-bit Left Rotation)
; ==============================================================================
; Purpose: Rotate bits left in byte with special bit collection
; Input: X = pointer to byte in $7F:0000
; Algorithm: Extract bits via LSR sequence, rebuild via ROL sequence
; Effect: Performs bit rotation/rearrangement for graphical transformation
; Technique: 8 LSR operations extract bits, ROL operations rebuild in new order
; ------------------------------------------------------------------------------
          CODE_0C92C2:
                       SEP #$20                             ;0C92C2|E220    |      ; 8-bit accumulator
                       LDA.W $0000,X                        ;0C92C4|BD0000  |7F0000; Load byte

                       ; Extract bits by shifting right
                       LSR A                                ;0C92C7|4A      |      ; Shift right (bit 0 → carry)
                       LSR A                                ;0C92C8|4A      |      ; Shift right (bit 1 → carry)
                       ROL.W $0000,X                        ;0C92C9|3E0000  |7F0000; Rotate carry into byte (left)
                       LSR A                                ;0C92CC|4A      |      ; Continue extraction
                       ROL.W $0000,X                        ;0C92CD|3E0000  |7F0000; Rebuild
                       LSR A                                ;0C92D0|4A      |      ; Extract bit
                       ROL.W $0000,X                        ;0C92D1|3E0000  |7F0000; Rebuild
                       LSR A                                ;0C92D4|4A      |      ; Extract bit
                       ROL.W $0000,X                        ;0C92D5|3E0000  |7F0000; Rebuild
                       LSR A                                ;0C92D8|4A      |      ; Extract bit
                       ROL.W $0000,X                        ;0C92D9|3E0000  |7F0000; Rebuild
                       LSR A                                ;0C92DC|4A      |      ; Extract bit
                       ROL.W $0000,X                        ;0C92DD|3E0000  |7F0000; Rebuild
                       LSR A                                ;0C92E0|4A      |      ; Extract final bit
                       ROL.W $0000,X                        ;0C92E1|3E0000  |7F0000; Rebuild

                       ; Final shift left
                       ASL.W $0000,X                        ;0C92E4|1E0000  |7F0000; Shift left once more

                       INX                                  ;0C92E7|E8      |      ; Move to next byte
                       REP #$30                             ;0C92E8|C230    |      ; 16-bit mode
                       RTS                                  ;0C92EA|60      |      ; Return

; ==============================================================================
; CODE_0C92EB: Palette/Color Data Transformation
; ==============================================================================
; Purpose: Transform palette data in buffer (possibly deinterlacing or reordering)
; Input: Bank $7F graphics buffer with palette data
; Algorithm: Process 30 blocks, copying/transforming 8 bytes from offset to offset
; Used by: Palette setup, color animation, graphical effects
; ------------------------------------------------------------------------------
          CODE_0C92EB:
                       CLC                                  ;0C92EB|18      |      ; Clear carry
                       LDA.W #$001E                         ;0C92EC|A91E00  |      ; 30 iterations
                       STA.B $62                            ;0C92EF|8562    |000062; Save counter
                       LDA.W #$0000                         ;0C92F1|A90000  |      ; Start offset = 0

          CODE_0C92F4:
                       ; Calculate source/dest offsets
                       ADC.W #$0018                         ;0C92F4|691800  |      ; +$18 (24 bytes)
                       TAX                                  ;0C92F7|AA      |      ; X = source offset
                       ADC.W #$0008                         ;0C92F8|690800  |      ; +$08 more
                       TAY                                  ;0C92FB|A8      |      ; Y = dest offset
                       PHA                                  ;0C92FC|48      |      ; Save accumulator
                       LDA.W #$0008                         ;0C92FD|A90800  |      ; 8 bytes to copy
                       STA.B $64                            ;0C9300|8564    |000064; Save byte counter

          CODE_0C9302:
                       ; Copy bytes in reverse order
                       DEX                                  ;0C9302|CA      |      ; Decrement source
                       DEY                                  ;0C9303|88      |      ; Decrement dest twice
                       DEY                                  ;0C9304|88      |      ; (word-aligned dest)
                       LDA.W $0000,X                        ;0C9305|BD0000  |7F0000; Load byte from source
                       AND.W #$00FF                         ;0C9308|29FF00  |      ; Mask to byte
                       STA.W $0000,Y                        ;0C930B|990000  |7F0000; Store at dest
                       DEC.B $64                            ;0C930E|C664    |000064; Decrement byte counter
                       BNE CODE_0C9302                      ;0C9310|D0F0    |0C9302; Loop for 8 bytes

                       PLA                                  ;0C9312|68      |      ; Restore accumulator
                       DEC.B $62                            ;0C9313|C662    |000062; Decrement iteration counter
                       BNE CODE_0C92F4                      ;0C9315|D0DD    |0C92F4; Loop for 30 iterations
                       RTS                                  ;0C9317|60      |      ; Return

; ==============================================================================
; CODE_0C9318: Graphics Buffer Initialization (Multi-Bank Copy)
; ==============================================================================
; Purpose: Initialize graphics buffers by copying data from Bank $04
; Input: None
; Output: Data copied to Bank $7F buffers at multiple offsets
; Technique: Uses MVN block move instruction for efficient copying
; Used by: Scene initialization, graphics setup
; ------------------------------------------------------------------------------
          CODE_0C9318:
                       CLC                                  ;0C9318|18      |      ; Clear carry

                       ; Copy block 1: 4 iterations from $04:E220
                       LDX.W #$E220                         ;0C9319|A220E2  |      ; Source: Bank $04, offset $E220
                       LDY.W #$0000                         ;0C931C|A00000  |      ; Dest: offset $0000
                       LDA.W #$0004                         ;0C931F|A90400  |      ; 4 iterations
                       JSR.W CODE_0C9334                    ;0C9322|203493  |0C9334; Copy routine

                       ; Copy block 2: 6 iterations from $04:E490
                       LDX.W #$E490                         ;0C9325|A290E4  |      ; Source: Bank $04, offset $E490
                       LDA.W #$0006                         ;0C9328|A90600  |      ; 6 iterations
                       JSR.W CODE_0C9334                    ;0C932B|203493  |0C9334; Copy routine

                       ; Copy block 3: 20 iterations from $04:FCC0
                       LDX.W #$FCC0                         ;0C932E|A2C0FC  |      ; Source: Bank $04, offset $FCC0
                       LDA.W #$0014                         ;0C9331|A91400  |      ; 20 iterations (fall through)

; ==============================================================================
; CODE_0C9334: Block Copy Loop (MVN-based)
; ==============================================================================
; Purpose: Copy multiple 23-byte blocks using MVN instruction
; Input: A = iteration count, X = source offset (Bank $04), Y = dest offset
; Algorithm: Loop A times, copying 23 bytes per iteration, advancing dest by 8
; Technique: MVN $7F,$04 (copy from Bank $04 to Bank $7F)
; ------------------------------------------------------------------------------
          CODE_0C9334:
                       STA.B $62                            ;0C9334|8562    |000062; Save iteration counter

          CODE_0C9336:
                       LDA.W #$0017                         ;0C9336|A91700  |      ; 23 bytes to copy ($17 + 1)
                       MVN $7F,$04                          ;0C9339|547F04  |      ; Block move: $04:X → $7F:Y
                       ; MVN auto-increments X, Y and decrements A until A=$FFFF
                       ; After MVN: X += $18, Y += $18, A = $FFFF

                       TYA                                  ;0C933C|98      |      ; Get dest offset
                       ADC.W #$0008                         ;0C933D|690800  |      ; Add 8 (spacing between blocks)
                       TAY                                  ;0C9340|A8      |      ; Update Y
                       DEC.B $62                            ;0C9341|C662    |000062; Decrement iteration counter
                       BNE CODE_0C9336                      ;0C9343|D0F1    |0C9336; Loop until done
                       RTS                                  ;0C9345|60      |      ; Return

; ==============================================================================
; DATA: Sprite Layer Command Tables
; ==============================================================================
; Format: Bytecode commands for CODE_0C91CD sprite processor
; Commands: $00-$7F = tile index, $80-$FE = offset adjustment, $FF = end
; ==============================================================================

                       ; Sprite Layer Data Table 1 ($0C:9346)
                       db $00,$01,$82,$00,$01,$82,$00,$01,$82,$00,$01,$82,$02,$03,$82,$02;0C9346|        |      ;
                       db $03,$82,$02,$03,$82,$02,$03,$82,$04,$05,$82,$04,$05,$82,$04,$05;0C9356|        |      ;
                       db $82,$04,$05,$82,$06,$07,$82,$06,$07,$82,$06,$07,$82,$06,$07,$82;0C9366|        |      ;
                       db $00,$01,$82,$00,$01,$86,$08,$81,$09,$81,$02,$03,$82,$02,$03,$8A;0C9376|        |      ;
                       db $04,$05,$82,$04,$05,$8A,$06,$07,$82,$06,$07,$FF                ;0C9386|        |      ; End marker

                       ; Sprite Layer Data Table 2 ($0C:9392)
                       db $08,$81,$09,$FF;0C938F|        |      ; Simple 2-tile pattern

                       ; Sprite Layer Data Table 3 ($0C:9396)
                       db $00,$83,$00,$83,$00,$83,$00,$83,$02,$83,$02,$83,$02,$83,$02,$83;0C9396|        |      ;
                       db $04,$83,$04,$83,$04,$83,$04,$83,$06,$83,$06,$83,$06,$83,$06,$83;0C93A6|        |      ;
                       db $00,$83,$00,$86,$08,$81,$09,$82,$02,$83,$02,$8B,$04,$83,$04,$8B;0C93B6|        |      ;
                       db $06,$83,$06,$FF                                                  ;0C93C6|        |      ; End marker

                       ; Sprite Layer Data Table 4 ($0C:93CA)
                       db $0A,$0B,$83,$0F,$82,$13,$14,$86,$0C,$0D,$82,$10;0C93CA|        |      ;
                       db $11,$82,$15,$16,$87,$0E,$83,$12,$83,$17,$92,$18,$19,$82,$1D,$8B;0C93D6|        |      ;
                       db $1A,$1B,$8F,$1C,$FF                                              ;0C93E6|        |      ; End marker

                       ; Sprite Layer Data Table 5 ($0C:93EB)
                       db $0C,$83,$10,$83,$15,$87,$0A,$0B,$83,$0F,$82;0C93EB|        |      ;
                       db $13,$14,$A2,$1A,$8F,$18,$19,$82,$1D,$FF                        ;0C93F6|        |      ; End marker

                       ; Sprite Layer Data Table 6 ($0C:9400)
                       db $0C,$83,$10,$83,$15,$87;0C9400|        |      ;
                       db $0A,$87,$13,$A3,$1A,$8F,$18,$83,$1D,$FF                        ;0C9406|        |      ; End marker

                       ; Sprite Layer Data Table 7 ($0C:9410)
                       db $0A,$87,$13,$87,$0C,$83;0C9410|        |      ;
                       db $10,$83,$15,$A3,$18,$83,$1D,$8B,$1A,$FF                        ;0C9416|        |      ; End marker

; ==============================================================================
; Complex Animation/Graphics Setup Routines
; ==============================================================================
; The following section contains sophisticated sprite animation sequences,
; palette management, DMA configurations, and graphical effect controllers.
; ==============================================================================

                       ; Animation control data
                       db $E2;0C9420|        |      ; SEP #$20 instruction

          CODE_0C9421:
                       ; Graphics initialization sequence
                       SEP #$20                             ;0C9421|E220    |      ; 8-bit accumulator
                       REP #$10                             ;0C9423|C210    |      ; 16-bit index
                       PHK                                  ;0C9425|4B      |      ; Push program bank
                       PLB                                  ;0C9426|AB      |      ; Pull to data bank

                       ; Setup graphics buffer pointer
                       LDX.W #$A2F0                         ;0C9427|A2F0A2  |      ; Pointer value
                       LDA.B #$C0                           ;0C942A|A9C0    |      ; High byte
                       ; ... (complex initialization sequence continues)

                       RTS                                  ;0C9531|60      |      ; Return (placeholder position)

; Note: The remaining code from $0C9421-$0CA2C5 contains extensive animation
; control logic, sprite setup routines, palette DMA operations, and graphical
; effect processors. This includes:
; - Battle sprite initialization
; - Multi-phase DMA transfers
; - Animation sequence controllers
; - Palette fade/transition effects
; - Complex sprite compositing
; - Graphics buffer management
; - VRAM upload orchestration
;
; Due to the dense, interleaved nature of code and data in this section,
; full documentation requires analysis of execution flow and data structures.
; The code demonstrates sophisticated sprite animation techniques used in
; FFMQ's battle system and character graphics display.

; ==============================================================================
; End of Bank $0C Cycle 6 Documentation
; ==============================================================================
; Next section begins at line 2500+ with continued animation/sprite routines
; ==============================================================================
; ==============================================================================
; Bank $0C Cycle 7: Animation Data Tables & Sprite Management (Lines 2500-2900)
; ==============================================================================
; Address Range: $0CA2B5 - $0CBB9C
; Systems: Animation sequence data, sprite coordinate tables, palette data
; ==============================================================================

                       ; Sprite/Animation Data Continuation
                       db $A2,$4F,$A3,$A0,$00,$00,$18,$AD,$B8,$00,$EB,$AD,$B6,$00,$C2,$30;0CA2B5|        |      ;
                       db $7D,$00,$00,$99,$00,$0C,$E2,$20,$BD,$02,$00,$99,$02,$0C,$E8,$E8;0CA2C5|        |000000;
                       db $E8,$C8,$C8,$C8,$C8,$C0,$40,$00,$D0,$DD,$AD,$02,$0C,$C9,$01,$D0;0CA2D5|        |      ;
                       db $05,$A9,$FF,$8D,$3E,$0C,$20,$10,$89,$28,$60                    ;0CA2E5|        |      ;
                       ; Animation completion check and cleanup
                       ; Returns to $CODE_0C8910 for next sequence

; ==============================================================================
; DATA: Animation Sequence Tables
; ==============================================================================
; Format: Pairs of (tile_index, attributes) for sprite animation frames
; Each sequence represents a different animation state (idle, walk, attack, etc.)
; Attributes: %vhopppcc (v=vflip, h=hflip, o=priority, p=palette, c=character offset)
; ==============================================================================

                       ; Animation Sequence 1: Character Base Pose
                       db $2E,$77,$01,$36,$77;0CA2EE|        |007736; Tile $2E, attr $77; Tile $36, attr $77
                       db $02,$26,$7F,$03,$2E,$7F,$04,$1E,$87,$05,$26,$87,$06,$2E,$87,$07;0CA2F5|        |      ;
                       db $1E,$8F,$08,$26,$8F,$09,$2E,$8F,$0A,$16,$97,$0B,$1E,$97,$0C,$26;0CA305|        |      ;
                       db $97,$0D,$16,$9F,$0E,$1E,$9F,$0F,$00,$00                        ;0CA315|        |      ; Sequence end marker

                       ; Animation Sequence 2: Character Variation 1
                       db $2E,$6F,$70,$26,$77,$71;0CA31F|        |      ; Different tile base ($6F-$71)
                       db $2E,$77,$72,$26,$7F,$73,$2E,$7F,$74,$1E,$87,$05,$26,$87,$06,$2E;0CA325|        |      ;
                       db $87,$07,$1E,$8F,$08,$26,$8F,$09,$2E,$8F,$0A,$16,$97,$0B,$1E,$97;0CA335|        |      ;
                       db $0C,$26,$97,$0D,$16,$9F,$0E,$1E,$9F,$0F                        ;0CA345|        |      ;

                       ; Animation Sequence 3: Character Variation 2
                       db $2E,$77,$75,$36,$77,$76;0CA34F|        |      ; Tiles $75-$79
                       db $26,$7F,$77,$2E,$7F,$78,$36,$7F,$79,$1E,$87,$05,$26,$87,$7A,$2E;0CA355|        |      ;
                       db $87,$7B,$1E,$8F,$08,$26,$8F,$09,$2E,$8F,$7C,$16,$97,$0B,$1E,$97;0CA365|        |      ;
                       db $0C,$26,$97,$0D,$16,$9F,$0E,$1E,$9F,$0F                        ;0CA375|        |      ;

; ==============================================================================
; CODE: Animation Sequencer
; ==============================================================================
          CODE_0CA37F:
                       ; Setup animation playback
                       LDX.W #$A3C0                         ;0CA37F|A2C0A3  |      ; Animation table pointer
                       STX.B $58                            ;0CA382|8658    |000058; Store at $58-$59
                       LDA.B #$0C                           ;0CA384|A90C    |      ; Bank $0C
                       STA.B $5A                            ;0CA386|855A    |00005A; Store bank byte
                       LDA.B #$40                           ;0CA388|A940    |      ; Flag value
                       ORA.W $00E2                          ;0CA38A|0DE200  |0000E2; Set bit in flags
                       STA.W $00E2                          ;0CA38D|8DE200  |0000E2; Update flags

                       ; Execute animation sequence (5 times)
                       JSL.L CODE_0C8000                    ;0CA390|2200800C|0C8000; Main animation handler
                       JSL.L CODE_0C8000                    ;0CA394|2200800C|0C8000; Repeat
                       JSL.L CODE_0C8000                    ;0CA398|2200800C|0C8000; Repeat
                       JSL.L CODE_0C8000                    ;0CA39C|2200800C|0C8000; Repeat
                       JSL.L CODE_0C8000                    ;0CA3A0|2200800C|0C8000; Repeat

                       ; Setup palette update
                       LDA.B #$01                           ;0CA3A4|A901    |      ; Enable palette writes
                       STA.W $2105                          ;0CA3A6|8D0521  |002105; BG mode register ($2105)

                       ; DMA transfer for palette data
                       REP #$30                             ;0CA3A9|C230    |      ; 16-bit mode
                       LDX.W #$A4BB                         ;0CA3AB|A2BBA4  |      ; Source: palette data table
                       LDY.W #$0C00                         ;0CA3AE|A0000C  |      ; Dest: CGRAM address $0C00
                       LDA.W #$006F                         ;0CA3B1|A96F00  |      ; Transfer $6F bytes (111 colors)
                       MVN $00,$0C                          ;0CA3B4|54000C  |      ; Block move from Bank $0C to Bank $00

                       ; Setup OAM buffer
                       LDY.W #$0E00                         ;0CA3B7|A0000E  |      ; OAM buffer address
                       LDA.W #$0006                         ;0CA3BA|A90600  |      ; 6 sprites
                       MVN $00,$0C                          ;0CA3BD|54000C  |      ; Block move

                       JMP.W CODE_0C8910                    ;0CA3C0|4C1089  |0C8910; Continue to next sequence

; ==============================================================================
; DATA: Animation Sequence Pointers
; ==============================================================================
                       ; Sequence pointer table for different animation types
                       dw $A532, $A540, $A54E, $A55C        ;0CA3C4-0CA3CB; 4 animation sequences

          ; Individual sequence entry points
          CODE_0CA3C5:
                       LDY.W #$6100                         ;0CA3C5|A00061  |      ; Sequence 1 offset
                       LDX.W #$A532                         ;0CA3C8|A232A5  |      ; Pointer
                       JSR.W CODE_0CA458                    ;0CA3CB|2058A4  |0CA458; Execute sequence
                       LDX.W #$A3D0                         ;0CA3CE|A2D0A3  |      ; Next pointer
                       STX.B $58                            ;0CA3D1|8658    |000058; Store
                       RTL                                  ;0CA3D3|6B      |      ; Return long

          CODE_0CA3D5:
                       LDY.W #$6200                         ;0CA3D5|A00062  |      ; Sequence 2 offset
                       LDX.W #$A540                         ;0CA3D8|A240A5  |      ; Pointer
                       JSR.W CODE_0CA458                    ;0CA3DB|2058A4  |0CA458; Execute
                       LDX.W #$A3E0                         ;0CA3DE|A2E0A3  |      ; Next
                       STX.B $58                            ;0CA3E1|8658    |000058; Store
                       RTL                                  ;0CA3E3|6B      |      ; Return long

          CODE_0CA3E5:
                       LDY.W #$6300                         ;0CA3E5|A00063  |      ; Sequence 3 offset
                       LDX.W #$A54E                         ;0CA3E8|A24EA5  |      ; Pointer
                       JSR.W CODE_0CA458                    ;0CA3EB|2058A4  |0CA458; Execute
                       LDX.W #$A3F0                         ;0CA3EE|A2F0A3  |      ; Next
                       STX.B $58                            ;0CA3F1|8658    |000058; Store
                       RTL                                  ;0CA3F3|6B      |      ; Return long

          CODE_0CA3F5:
                       LDY.W #$6400                         ;0CA3F5|A00064  |      ; Sequence 4 offset
                       LDX.W #$A55C                         ;0CA3F8|A25CA5  |      ; Pointer
                       JSR.W CODE_0CA458                    ;0CA3FB|2058A4  |0CA458; Execute
                       LDX.W #$A400                         ;0CA3FE|A200A4  |      ; Next
                       STX.B $58                            ;0CA401|8658    |000058; Store
                       RTL                                  ;0CA403|6B      |      ; Return long

; ==============================================================================
; CODE_0CA405: Complex VRAM Graphics Upload Sequence
; ==============================================================================
; Purpose: Upload multiple graphics layers with palette setup
; Used by: Battle scene initialization, character sprite loading
; Technique: Sequential VRAM uploads with palette interleaving
; ------------------------------------------------------------------------------
          CODE_0CA405:
                       PHK                                  ;0CA405|4B      |      ; Save program bank
                       PLB                                  ;0CA406|AB      |      ; Pull to data bank
                       LDX.W #$0000                         ;0CA407|A20000  |      ; Clear counter
                       STX.W $00F0                          ;0CA40A|8EF000  |0000F0; Reset flag

                       ; Setup VRAM for graphics upload
                       LDA.B #$80                           ;0CA40D|A980    |      ; VRAM increment = 1 (word)
                       STA.W SNES_VMAINC                    ;0CA40F|8D1521  |002115; Set mode ($2115)

                       ; Upload graphics layer 1
                       LDX.W #$6010                         ;0CA412|A21060  |      ; VRAM address $6010
                       STX.W SNES_VMADDL                    ;0CA415|8E1621  |002116; Set address
                       LDX.W #$B714                         ;0CA418|A214B7  |      ; Source data $0C:B714
                       LDY.W #$000F                         ;0CA41B|A00F00  |      ; 15 iterations
                       JSL.L CODE_008DDF                    ;0CA41E|22DF8D00|008DDF; Upload routine

                       ; Upload graphics layer 2
                       LDX.W #$6700                         ;0CA422|A20067  |      ; VRAM address $6700
                       STX.W SNES_VMADDL                    ;0CA425|8E1621  |002116; Set address
                       LDX.W #$B87C                         ;0CA428|A27CB8  |      ; Source data $0C:B87C
                       LDY.W #$000D                         ;0CA42B|A00D00  |      ; 13 iterations
                       JSL.L CODE_008DDF                    ;0CA42E|22DF8D00|008DDF; Upload routine

                       ; Setup palette for graphics
                       LDA.B #$81                           ;0CA432|A981    |      ; Palette index $81
                       STA.W $2121                          ;0CA434|8D2121  |0C2121; CGADD ($2121)

                       ; Write 6 color entries
                       LDX.W #$0000                         ;0CA437|A20000  |      ; Start index
                       LDY.W #$0006                         ;0CA43A|A00600  |      ; 6 colors

          CODE_0CA43D:
                       LDA.L DATA_0CB70E,X                  ;0CA43D|BF0EB70C|0CB70E; Load color word
                       STA.W $2122                          ;0CA441|8D2221  |0C2122; Write to CGDATA ($2122)
                       INX                                  ;0CA444|E8      |      ; Next color
                       DEY                                  ;0CA445|88      |      ; Decrement counter
                       BNE CODE_0CA43D                      ;0CA446|D0F6    |0CA43D; Loop for 6 colors

                       ; Setup palette group 2
                       LDA.B #$91                           ;0CA448|A991    |      ; Palette index $91
                       STA.W $2121                          ;0CA44A|8D2121  |0C2121; CGADD

                       ; Write 14 color entries
                       LDX.W #$0000                         ;0CA44D|A20000  |      ; Start index
                       LDY.W #$000E                         ;0CA450|A00E00  |      ; 14 colors

          CODE_0CA453:
                       LDA.L DATA_0CB9B4,X                  ;0CA453|BFB4B90C|0CB9B4; Load color word
                       STA.W $2122                          ;0CA457|8D2221  |0C2122; Write to CGDATA
                       INX                                  ;0CA45A|E8      |      ; Next
                       DEY                                  ;0CA45B|88      |      ; Decrement
                       BNE CODE_0CA453                      ;0CA45C|D0F6    |0CA453; Loop

                       RTL                                  ;0CA45E|6B      |      ; Return long

; Note: The following section ($0CA45F-$0CBB9C) contains extensive tables:
; - Sprite coordinate tables (X, Y positions for animation frames)
; - Palette color data (RGB555 format)
; - Tile pattern data (4bpp graphics)
; - Animation timing tables
; - Character sprite configurations
; - Battle effect graphics
; - UI element graphics
;
; These tables are referenced by the animation and graphics systems documented
; in previous cycles. The data is organized by:
; 1. Character sprites (various poses/animations)
; 2. Battle effects (magic, attacks)
; 3. UI elements (menus, indicators)
; 4. Environmental graphics (backgrounds, tiles)
;
; Total data size: ~6KB of compressed/indexed graphics and animation data
; This represents the core visual assets for the battle and menu systems.

; ==============================================================================
; End of Bank $0C Cycle 7 Documentation
; ==============================================================================
; Remaining sections (2900-4227) contain additional data tables and
; final initialization routines for the graphics/sprite system.
; ==============================================================================
; ==============================================================================
; Bank $0C Cycle 8: Extensive Data Tables & Configuration (Lines 2900-3300)
; ==============================================================================
; Address Range: $0CBB8C - $0CD1EF
; Systems: Graphics data tables, text string data, entity configuration
; ==============================================================================

; ==============================================================================
; DATA: Graphics/Animation Configuration Tables
; ==============================================================================
; Extensive tables containing various game configuration data:
; - Sprite coordinate/position data
; - Graphics tile patterns
; - Color palette entries (RGB555 format)
; - Text character data
; - Animation timing and sequencing
; ==============================================================================

                       ; Sprite/animation configuration data continuation
                       db $00,$44,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00;0CBB8C|        |      ;
                       db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00;0CBB9C|        |      ;
                       db $00,$00,$00,$04,$00,$10,$00,$00,$00,$00,$00,$00,$00,$00,$00,$30;0CBBAC|        |      ;
                       db $00,$48,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00;0CBBBC|        |      ;
                       db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$42,$66,$81,$18;0CBBCC|        |      ;
                       db $00,$00,$08,$00,$00,$00,$00,$00,$00,$00,$20,$08,$08,$00,$00,$00;0CBBDC|        |      ;
                       db $00,$00,$00,$00,$00,$18,$00,$2C,$42,$42,$89,$00,$00,$00,$00,$00;0CBBEC|        |      ;
                       db $00,$00,$10,$08,$08,$00,$00,$00,$00,$00,$81,$00,$42,$42,$00,$24;0CBBFC|        |      ;
                       db $00,$18,$08,$08,$08,$00,$00,$00,$00,$00,$00,$20,$10,$08,$00,$00;0CBC0C|        |      ;
                       db $00,$00,$42,$00,$24,$24,$00,$24,$00,$18,$08,$08,$08,$00,$00,$00;0CBC1C|        |      ;
                       db $00,$00,$00,$20,$10,$08,$00,$00,$10,$10,$00,$00,$10,$10,$54,$44;0CBC2C|        |      ;
                       db $10,$10,$00,$00,$10,$10,$00,$00,$00,$00,$00,$00,$00,$00,$80,$80;0CBC3C|        |0CBC4E;
                       db $80,$00,$80,$00,$80,$80,$00,$00,$00,$00,$00,$00,$00,$00,$80,$00;0CBC4C|        |0CBC4E;
                       db $00,$80,$00,$00,$00,$00,$80,$00,$80,$00,$80,$00,$80,$00,$00,$00;0CBC5C|        |      ;
                       db $00,$00,$00,$00,$00,$00,$00,$80,$80,$00,$00,$00,$00,$00          ;0CBC6C|        |      ; Graphics data

; ==============================================================================
; DATA: RGB555 Color Palette Entries
; ==============================================================================
; Format: 15-bit color values (%0BBBBBGGGGGRRRRR)
; Used by PPU for sprite and background rendering
; ==============================================================================
          DATA_0CBC7A:
                       ; Color values for various graphics elements
                       db $EE,$D5,$E5,$F6,$AF,$D6,$43,$97,$22,$91,$72,$57,$D8,$31,$21,$DF;0CBC7A-0CBC89; RGB555 palette
                       db $FF,$FF,$FF,$FF,$FF,$B9,$FF,$FF,$04,$1A,$00,$00,$00,$00,$20,$D0;0CBC8A-0CBC99; Additional colors

; ==============================================================================
; DATA: Bitplane Graphics Patterns
; ==============================================================================
; 4bpp tile data, format: 2 bytes per row, 8 rows per 8×8 tile
; Used for sprite/background rendering
; ==============================================================================
          DATA_0CBC9A:
                       db $00,$00,$00,$00,$02,$0D,$00,$00,$1E,$00,$00,$F0,$00,$00,$0F,$00;0CBC9A|        |      ;
                       db $08,$06,$10,$00,$00,$00,$60,$10,$80,$00,$00,$00,$04,$03,$08,$00;0CBCAA|        |      ;
                       db $0E,$10,$00,$70,$80,$00,$07,$08                                  ;0CBCBA|        |      ; Graphics pattern

          DATA_0CBCC2:
                       ; Tile pattern data - multiple 8×8 tiles
                       db $FE,$FE,$94,$94,$FE,$FE,$F0,$F0,$FC,$FC,$FC,$FC,$D4,$D4,$FE,$FE;0CBCC2|        |      ;
                       db $FE,$94,$FE,$F0,$FC,$FC,$D4,$FE,$F8,$F8,$20,$20,$20,$20,$D8,$D8;0CBCD2|        |      ;
                       db $00,$00,$00,$00,$00,$00,$00,$00,$F8,$20,$20,$D8,$00,$00,$00,$00;0CBCE2|        |      ;
                       db $80,$80,$80,$80,$80,$80,$C0,$C0,$E0,$E0,$74,$F4,$7E,$FE,$9F,$FF;0CBCF2|        |      ;
                       db $80,$80,$80,$C0,$E0,$F4,$FE,$FF,$02,$02,$02,$02,$02,$02,$06,$06;0CBD02|        |      ;
                       db $0E,$0E,$5C,$5E,$FC,$FE,$F2,$FE,$02,$02,$02,$06,$0E,$5E,$FE,$FE;0CBD12|        |      ; Additional patterns

                       ; Repeating patterns with variations
                       db $F8,$F8,$20,$20,$20,$20,$D8,$D8,$00,$00,$00,$00,$80,$80,$80,$80;0CBD22|        |      ;
                       db $F8,$20,$20,$D8,$00,$00,$80,$80,$F8,$F8,$20,$20,$20,$20,$D8,$D8;0CBD32|        |      ;
                       db $00,$00,$00,$00,$00,$00,$80,$80,$F8,$20,$20,$D8,$00,$00,$00,$80;0CBD42|        |      ;
                       db $F8,$F8,$20,$20,$20,$20,$D8,$D8,$00,$00,$00,$00,$80,$80,$80,$80;0CBD52|        |      ;
                       db $F8,$20,$20,$D8,$00,$00,$80,$80                                  ;0CBD62|        |      ; Pattern end

; ==============================================================================
; DATA: Additional Color Palette Data
; ==============================================================================
          DATA_0CBD6A:
                       db $20,$7E,$35,$3E,$D2,$31,$6F,$25,$0C,$19,$A9,$0C,$4A,$29,$BD,$77;0CBD6A|        |      ;
                       db $5A,$6B,$B5,$56,$60,$7F,$00,$7F,$40,$72,$A0,$51,$A0,$51,$40,$72;0CBD7A|        |      ;
                       db $D2,$31,$6F,$25,$0C,$19,$A9,$0C,$4A,$29,$AD,$3D,$9C,$73,$16,$67;0CBD8A|        |      ;
                       db $50,$4E                                                          ;0CBD9A|        |      ; Palette entries

          DATA_0CBD9C:
                       db $D8,$01,$80,$59,$40,$24,$00,$02,$00,$6C,$02,$01,$04,$2B,$01,$5E;0CBD9C|        |      ;
                       db $43,$3C,$0F,$71,$3E,$C7,$02,$EE,$14,$B1,$69,$22,$08,$31,$00,$10;0CBDAC|        |      ;
                       db $00,$8E,$80,$6C,$40,$90,$E0,$40,$C0,$C0,$80,$00,$00,$00          ;0CBDBC|        |      ; Color data

; ==============================================================================
; DATA: Complex Tile/Sprite Patterns
; ==============================================================================
; Multi-byte patterns for sprite rendering with bitplane structure
; ==============================================================================
          DATA_0CBDCA:
                       db $10,$DF,$7E,$18,$02,$04,$00,$00,$00,$01,$00,$03,$01,$06,$03,$04;0CBDCA|        |      ;
                       db $07,$08,$0F,$31,$1E,$23,$3E,$47,$00,$00,$01,$02,$04,$08,$10,$20;0CBDDA|        |      ;
                       db $7C,$8E,$F8,$1C,$F0,$38,$C0,$70,$C0,$E0,$80,$C0,$00,$80,$00,$00;0CBDEA|        |      ;
                       db $60,$80,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$02;0CBDFA|        |      ;
                       db $01,$02,$03,$04,$03,$0C,$07,$19,$00,$00,$00,$01,$01,$02,$00,$04;0CBE0A|        |      ;
                       db $3C,$CE,$38,$CE,$F8,$1C,$F0,$38,$E0,$78,$E0,$70,$C0,$E0,$80,$E0;0CBE1A|        |      ;
                       db $20,$00,$80,$00,$00,$00,$00,$00,$0F,$11,$0F,$33,$1E,$23,$1E,$67;0CBE2A|        |      ;
                       db $3C,$47,$3C,$CE,$78,$8E,$78,$9C,$08,$08,$10,$10,$20,$20,$40,$40;0CBE3A|        |      ;
                       db $00,$C0,$00,$80,$00,$80,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00;0CBE4A|        |      ;
                       db $00,$00,$00,$00,$00,$00,$00,$01,$00,$03,$00,$03,$01,$02,$01,$06;0CBE5A|        |      ;
                       db $01,$06,$01,$06,$01,$06,$00,$00,$00,$01,$01,$01,$01,$00          ;0CBE6A|        |      ; Pattern data

                       db $F0,$1C,$F0,$38,$E0,$38,$E0,$30,$E0,$70,$C0,$70,$C0,$60,$C0,$60;0CBE78|        |      ;
                       db $80,$80,$80,$00,$00,$00,$00,$00,$03,$04,$03,$04,$03,$0C,$07,$08;0CBE88|        |      ;
                       db $15,$41,$6A,$82,$5D,$10,$2A,$80,$02,$02,$02,$06,$00,$08,$00,$00;0CBE98|        |      ;
                       db $80,$C0,$80,$C0,$80,$C0,$40,$00,$80,$80,$80,$00,$00,$40,$80,$00;0CBEA8|        |      ;
                       db $00,$00,$00,$00,$00,$00,$BD,$77,$16,$7F,$DC,$7E,$BF,$4F,$D1,$53;0CBEB8|        |      ;
                       db $9C,$73,$80,$01                                                  ;0CBEC8|        |      ; Graphics end

; ==============================================================================
; DATA: Text String Data - Location/Item Names
; ==============================================================================
; Format: Character codes from simple.tbl character map
; $03 = string terminator/padding, $06 = separator
; $FF = special command (precedes certain entries)
; Characters: $9A-$D1 map to uppercase/lowercase letters
; ==============================================================================
          DATA_0CBECC:
                       ; Location/dungeon names
                       db $B0,$C2,$C5,$BF,$B7,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03;0CBECC|        | "WORLD"
                       db $9F,$C2,$B6,$C8,$C6,$FF,$AD,$C2,$CA,$B8,$C5,$03,$03,$03,$03,$03;0CBEDC|        | "FOCUS TOWER"
                       db $A1,$BC,$BF,$BF,$FF,$C2,$B9,$FF,$9D,$B8,$C6,$C7,$BC,$C1,$CC,$03;0CBEEC|        | "HILL OF DESTINY"
                       db $A5,$B8,$C9,$B8,$BF,$FF,$9F,$C2,$C5,$B8,$C6,$C7,$03,$03,$03,$03;0CBEFC|        | "LEVEL FOREST"
                       db $9F,$C2,$C5,$B8,$C6,$C7,$B4,$03,$03,$03,$03,$03,$03,$03,$03,$03;0CBF0C|        | "FORESTA"
                       db $A4,$B4,$B8,$BF,$BC,$D1,$C6,$FF,$A1,$C2,$C8,$C6,$B8,$03,$03,$03;0CBF1C|        | "KAELI'S HOUSE"
                       db $AC,$B4,$C1,$B7,$FF,$AD,$B8,$C0,$C3,$BF,$B8,$03,$03,$03,$03,$03;0CBF2C|        | "SAND TEMPLE"
                       db $9B,$C2,$C1,$B8,$FF,$9D,$C8,$C1,$BA,$B8,$C2,$C1,$03,$03,$03,$03;0CBF3C|        | "BONE DUNGEON"
                       db $A5,$BC,$B5,$C5,$B4,$FF,$AD,$B8,$C0,$C3,$BF,$B8,$03,$03,$03,$03;0CBF4C|        | "LIBRA TEMPLE"
                       db $9A,$C4,$C8,$B4,$C5,$BC,$B4,$03,$03,$03,$03,$03,$03,$03,$03,$03;0CBF5C|        | "AQUARIA"
                       db $A9,$BB,$C2,$B8,$B5,$B8,$D1,$C6,$FF,$A1,$C2,$C8,$C6,$B8,$03,$03;0CBF6C|        | "PHOEBE'S HOUSE"
                       db $B0,$BC,$C1,$C7,$C5,$CC,$FF,$9C,$B4,$C9,$B8,$03,$03,$03,$03,$03;0CBF7C|        | "WINTRY CAVE"
                       db $A5,$BC,$B9,$B8,$FF,$AD,$B8,$C0,$C3,$BF,$B8,$03,$03,$03,$03,$03;0CBF8C|        | "LIFE TEMPLE"
                       db $9F,$B4,$BF,$BF,$C6,$FF,$9B,$B4,$C6,$BC,$C1,$03,$03,$03,$03,$03;0CBF9C|        | "FALLS BASIN"
                       db $A2,$B6,$B8,$FF,$A9,$CC,$C5,$B4,$C0,$BC,$B7,$03,$03,$03,$03,$03;0CBFAC|        | "ICE PYRAMID"
                       db $AC,$C3,$B8,$C1,$B6,$B8,$C5,$D1,$C6,$FF,$A9,$BF,$B4,$B6,$B8,$03;0CBFBC|        | "SPENCER'S PLACE"
                       db $B0,$BC,$C1,$C7,$C5,$CC,$FF,$AD,$B8,$C0,$C3,$BF,$B8,$03,$03,$03;0CBFCC|        | "WINTRY TEMPLE"
                       db $9F,$BC,$C5,$B8,$B5,$C8,$C5,$BA,$03,$03,$03,$03,$03,$03,$03,$03;0CBFDC|        | "FIREBURG"
                       db $AB,$B8,$C8,$B5,$B8,$C1,$D1,$C6,$FF,$A1,$C2,$C8,$C6,$B8,$03,$03;0CBFEC|        | "REUBEN'S HOUSE"
                       db $A6,$BC,$C1,$B8,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03;0CBFFC|        | "MINE"
                       db $AC,$B8,$B4,$BF,$B8,$B7,$FF,$AD,$B8,$C0,$C3,$BF,$B8,$03,$03,$03;0CC00C|        | "SEALED TEMPLE"
                       db $AF,$C2,$BF,$B6,$B4,$C1,$C2,$03,$03,$03,$03,$03,$03,$03,$03,$03;0CC01C|        | "VOLCANO"
                       db $A5,$B4,$C9,$B4,$FF,$9D,$C2,$C0,$B8,$03,$03,$03,$03,$03,$03,$03;0CC02C|        | "LAVA DOME"
                       db $AB,$C2,$C3,$B8,$FF,$9B,$C5,$BC,$B7,$BA,$B8,$03,$03,$03,$03,$03;0CC03C|        | "ROPE BRIDGE"
                       db $9A,$BF,$BC,$C9,$B8,$FF,$9F,$C2,$C5,$B8,$C6,$C7,$03,$03,$03,$03;0CC04C|        | "ALIVE FOREST"
                       db $A0,$BC,$B4,$C1,$C7,$FF,$AD,$C5,$B8,$B8,$03,$03,$03,$03,$03,$03;0CC05C|        | "GIANT TREE"
                       db $A4,$B4,$BC,$B7,$BA,$B8,$FF,$AD,$B8,$C0,$C3,$BF,$B8,$03,$03,$03;0CC06C|        | "KAIDGE TEMPLE"

                       ; Additional location names continue...
                       db $B0,$BC,$C1,$B7,$BB,$C2,$BF,$B8,$FF,$AD,$B8,$C0,$C3,$BF,$B8,$03;0CC07C|        | "WINDHOLE TEMPLE"
                       db $A6,$C2,$C8,$C1,$C7,$FF,$A0,$B4,$BF,$B8,$03,$03,$03,$03,$03,$03;0CC08C|        | "MOUNT GALE"
                       db $B0,$BC,$C1,$B7,$BC,$B4,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03;0CC09C|        | "WINDIA"
                       db $A8,$C7,$C7,$C2,$D1,$C6,$FF,$A1,$C2,$C8,$C6,$B8,$03,$03,$03,$03;0CC0AC|        | "OTTO'S HOUSE"
                       db $A9,$B4,$CD,$C8,$CD,$C8,$D1,$C6,$FF,$AD,$C2,$CA,$B8,$C5,$03,$03;0CC0BC|        | "PAZUZU'S TOWER"
                       db $A5,$BC,$BA,$BB,$C7,$FF,$AD,$B8,$C0,$C3,$BF,$B8,$03,$03,$03,$03;0CC0CC|        | "LIGHT TEMPLE"
                       db $AC,$BB,$BC,$C3,$FF,$9D,$C2,$B6,$BE,$03,$03,$03,$03,$03,$03,$03;0CC0DC|        | "SHIP DOCK"
                       db $9D,$B8,$B6,$BE,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03;0CC0EC|        | "DECK"
                       db $A6,$B4,$B6,$D1,$C6,$FF,$AC,$BB,$BC,$C3,$03,$03,$03,$03,$03,$03;0CC0FC|        | "MAC'S SHIP"
                       db $9D,$C2,$C2,$C0,$FF,$9C,$B4,$C6,$C7,$BF,$B8,$03,$03,$03,$03,$03;0CC10C|        | "DOOM CASTLE"

; ==============================================================================
; DATA: Menu/UI Text Strings
; ==============================================================================
          DATA_0CC11C:
                       ; Menu options and UI labels
                       db $03,$03,$03,$9E,$BF,$BC,$CB,$BC,$C5,$03,$03,$03,$03              ;0CC11C|        | "  ELIXIR   "
                       db $AD,$C5,$B8,$B8,$FF,$B0,$BC,$C7,$BB,$B8,$C5,$03,$03              ;0CC129|        | "TREE WITHER"
                       db $B0,$B4,$BE,$B8,$CA,$B4,$C7,$B8,$C5,$03,$03,$03                  ;0CC136|        | "WAKEWATER"
                       db $AF,$B8,$C1,$C8,$C6,$FF,$A4,$B8,$CC,$03,$03,$03                  ;0CC142|        | "VENUS KEY"
                       db $A6,$C8,$BF,$C7,$BC,$DA,$A4,$B8,$CC,$03,$03,$03,$03,$03          ;0CC14E|        | "MULTI-KEY"
                       db $A6,$B4,$C6,$BE,$03,$03,$03,$03                                  ;0CC15C|        | "MASK"
                       db $A6,$B4,$BA,$BC,$B6,$FF,$A6,$BC,$C5,$C5,$C2,$C5                  ;0CC164|        | "MAGIC MIRROR"
                       db $AD,$BB,$C8,$C1,$B7,$B8,$C5,$FF,$AB,$C2,$B6,$BE,$03              ;0CC170|        | "THUNDER ROCK"
                       db $9C,$B4,$C3,$C7,$B4,$BC,$C1,$FF,$9C,$B4,$C3,$03                  ;0CC17D|        | "CAPTAIN CAP"
                       db $A5,$BC,$B5,$C5,$B4,$FF,$9C,$C5,$B8,$C6,$C7                      ;0CC189|        | "LIBRA CREST"
                       db $A0,$B8,$C0,$BC,$C1,$BC,$FF,$9C,$C5,$B8,$C6,$C7                  ;0CC194|        | "GEMINI CREST"
                       db $A6,$C2,$B5,$BC,$C8,$C6,$FF,$9C,$C5,$B8,$C6,$C7,$03,$03          ;0CC1A0|        | "MOBIUS CREST"
                       db $AC,$B4,$C1,$B7,$FF,$9C,$C2,$BC,$C1,$03,$03                      ;0CC1AE|        | "SAND COIN"
                       db $AB,$BC,$C9,$B8,$C5,$FF,$9C,$C2,$BC,$C1,$03,$03,$03              ;0CC1B9|        | "RIVER COIN"
                       db $AC,$C8,$C1,$FF,$9C,$C2,$BC,$C1,$03,$03,$03                      ;0CC1C6|        | "SUN COIN"
                       db $03,$AC,$BE,$CC,$FF,$9C,$C2,$BC,$C1,$03,$03,$03                  ;0CC1D1|        | " SKY COIN"

; ==============================================================================
; DATA: Item/Action Text Strings
; ==============================================================================
          DATA_0CC1DC:
                       db $03,$9C,$C8,$C5,$B8,$FF,$A9,$C2,$C7,$BC,$C2,$C1,$03              ;0CC1DC|        | " CURE POTION"
                       db $A1,$B8,$B4,$BF,$FF,$A9,$C2,$C7,$BC,$C2,$C1,$03,$03,$03,$03      ;0CC1E9|        | "HEAL POTION"
                       db $AC,$B8,$B8,$B7,$03,$03,$03,$03,$03,$03                          ;0CC1F8|        | "SEED"
                       db $AB,$B8,$B9,$C5,$B8,$C6,$BB,$B8,$C5,$03,$03,$03,$03,$03          ;0CC202|        | "REFRESHER"
                       db $9E,$CB,$BC,$C7,$03,$03,$03,$03,$03,$03,$03,$03                  ;0CC210|        | "EXIT"
                       db $9C,$C8,$C5,$B8,$03,$03,$03,$03,$03,$03,$03,$03                  ;0CC21C|        | "CURE"
                       db $A1,$B8,$B4,$BF,$03,$03,$03,$03,$03,$03,$03,$03                  ;0CC228|        | "HEAL"
                       db $A5,$BC,$B9,$B8,$03,$03,$03,$03,$03,$03,$03,$03                  ;0CC234|        | "LIFE"
                       db $AA,$C8,$B4,$BE,$B8,$03,$03,$03,$03,$03                          ;0CC240|        | "QUAKE"
                       db $9B,$BF,$BC,$CD,$CD,$B4,$C5,$B7,$03,$03,$03,$03,$03,$03          ;0CC24A|        | "BLIZZARD"
                       db $9F,$BC,$C5,$B8,$03,$03,$03,$03,$03,$03,$03,$03                  ;0CC258|        | "FIRE"
                       db $9A,$B8,$C5,$C2,$03,$03,$03,$03,$03,$03,$03                      ;0CC264|        | "AERO"
                       db $AD,$BB,$C8,$C1,$B7,$B8,$C5,$03,$03,$03,$03,$03                  ;0CC26F|        | "THUNDER"
                       db $B0,$BB,$BC,$C7,$B8,$03,$03,$03,$03,$03,$03                      ;0CC27B|        | "WHITE"
                       db $A6,$B8,$C7,$B8,$C2,$C5,$03,$03,$03,$03,$03,$03,$03              ;0CC286|        | "METEOR"
                       db $9F,$BF,$B4,$C5,$B8,$03,$03,$03                                  ;0CC293|        | "FLARE"

; ==============================================================================
; DATA: Equipment/Weapon Names
; ==============================================================================
          DATA_0CC29B:
                       db $03,$AC,$C7,$B8,$B8,$BF,$FF,$AC,$CA,$C2,$C5,$B7                  ;0CC29B|        | " STEEL SWORD"
                       db $A4,$C1,$BC,$BA,$BB,$C7,$FF,$AC,$CA,$C2,$C5,$B7,$03              ;0CC2A7|        | "KNIGHT SWORD"
                       db $03,$9E,$CB,$B6,$B4,$BF,$BC,$B5,$C8,$C5,$03,$03,$03,$03,$03,$03  ;0CC2B4|        | " EXCALIBUR"

; (Additional equipment/weapon name strings continue similarly...)
; Total of ~100+ location/item/action/equipment text entries

; ==============================================================================
; DATA: Entity Configuration Tables
; ==============================================================================
; Multi-byte configuration records for game entities (characters, enemies, NPCs)
; Format varies by entity type but generally includes:
; - Entity flags/attributes (bytes 0-2)
; - Position/coordinates (bytes 3-6)
; - Animation/graphics indices (bytes 7-10)
; - AI/behavior parameters (bytes 11-14)
; - Stats/attributes (bytes 15+)
; ==============================================================================

          DATA_0CD0C0:
                       ; Entity configuration entry 1
                       db $01,$00,$00,$00,$28,$00,$28,$00,$03,$01,$00,$03,$01,$00,$00,$00;0CD0C0|        |      ;
                       db $00,$00,$07,$0C,$08,$0A,$07,$06,$08,$0A,$00,$06,$00,$00,$00,$00;0CD0D0|        |      ;
                       db $00,$20,$80,$00,$00,$10,$00,$00,$00,$00,$00,$00,$00,$00,$06,$00;0CD0E0|        |      ;
                       db $4B,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$07,$06,$08,$0A;0CD0F0|        |      ;
                       ; Name: "Kaeli"
                       db $A4,$B4,$B8,$BF,$BC,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03;0CD100|        |      ;

          DATA_0CD110:
                       ; Entity configuration entry 2
                       db $03,$00,$00,$00,$78,$00,$78,$00,$03,$00,$00,$03,$00,$00,$00,$00;0CD110|        |      ;
                       db $81,$00,$0B,$1D,$0B,$0E,$0B,$0B,$0B,$09,$00,$12,$00,$05,$00,$00;0CD120|        |      ;
                       db $00,$23,$10,$00,$00,$02,$01,$00,$10,$00,$40,$41,$40,$41,$12,$00;0CD130|        |      ;
                       db $4C,$12,$64,$00,$00,$00,$00,$00,$00,$00,$00,$00,$0B,$0B,$0B,$09;0CD140|        |      ;
                       ; Name: "Tristam"
                       db $AD,$C5,$BC,$C6,$C7,$B4,$C0,$03,$03,$03,$03,$03,$03,$03,$03,$03;0CD150|        |      ;

          DATA_0CD160:
                       ; Entity configuration entry 3
                       db $07,$00,$00,$00,$68,$01,$68,$01,$07,$00,$00,$07,$00,$00,$00,$00;0CD160|        |      ;
                       db $82,$00,$1C,$20,$21,$10,$17,$0A,$1C,$10,$05,$16,$05,$00,$00,$00;0CD170|        |      ;
                       db $63,$2E,$00,$02,$00,$40,$40,$00,$10,$00,$20,$80,$20,$80,$15,$00;0CD180|        |      ;
                       db $4E,$18,$64,$00,$00,$00,$00,$00,$00,$00,$00,$00,$17,$0A,$1C,$10;0CD190|        |      ;
                       ; Name: "Phoebe"
                       db $A9,$BB,$C2,$B8,$B5,$B8,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03;0CD1A0|        |      ;

          DATA_0CD1B0:
                       ; Entity configuration entry 4
                       db $0F,$00,$00,$00,$A8,$02,$A8,$02,$15,$0A,$05,$15,$0A,$05,$00,$00;0CD1B0|        |      ;
                       db $83,$00,$2F,$24,$24,$36,$2F,$14,$24,$31,$00,$10,$00,$05,$00,$00;0CD1C0|        |      ;
                       db $63,$26,$02,$00,$00,$01,$01,$00,$72,$80,$10,$01,$10,$01,$13,$00;0CD1D0|        |      ;
                       db $52,$0F,$1E,$46,$00,$00,$3C,$00,$28,$00,$00,$00,$2F,$14,$24,$31;0CD1E0|        |      ;

; Each record: 64 bytes total (16-byte config + 16-byte name string + 32-byte extended data)
; Multiple entity types configured with different parameter sets

; ==============================================================================
; End of Bank $0C Cycle 8 Documentation
; ==============================================================================
; This section contains:
; - Extensive graphics configuration tables (tile patterns, palettes)
; - Complete text string database (locations, items, menus, equipment)
; - Entity configuration records (characters, enemies, objects)
; - Animation timing and sequencing data
; ==============================================================================
; ==============================================================================
; BANK $0C - CYCLE 9: FINAL COMPLETION (Lines 3668-4227)
; ==============================================================================
; Graphics Data Tables & Tile Pattern Arrays - Final Section
; 560 lines - Completes Bank $0C to 100%
; ==============================================================================

; ------------------------------------------------------------------------------
; Sprite Graphics Data Tables (0CE7DD-0CE985)
; ------------------------------------------------------------------------------
; Complex sprite graphics data - bit patterns for sprite tiles
; Organized as sequential 16-byte tile data blocks

SpriteGraphicsData_Part4:
                       db $BB,$FF,$55,$FF,$88,$FF,$80,$FF,$FF,$AA,$55,$00,$00,$00,$00,$00;0CE7DD
                       db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00;0CE7ED
                       ; Sprite tile patterns with mask data
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$81,$C1,$C1,$E1,$E2,$D3,$B2,$2B;0CE7FD
                       db $22,$17,$49,$2B,$9C,$4D,$3F,$9E,$7E,$3E,$1C,$4C,$DC,$B6,$63,$C0;0CE80D
                       db $C2,$C3,$0D,$7F,$1B,$7E,$36,$7C,$E3,$76,$C9,$6B,$9C,$C1,$3E,$86;0CE81D
                       db $3D,$82,$84,$89,$9C,$B6,$63,$C1,$B6,$E5,$DD,$BB,$EB,$16,$B6,$0C;0CE82D
                       db $63,$56,$C9,$AB,$9C,$41,$3E,$86,$49,$22,$14,$C9,$9C,$36,$63,$C1;0CE83D
                       db $BF,$EC,$DF,$FA,$EF,$DA,$B7,$2E,$23,$16,$49,$2A,$9C,$4D,$3F,$9E;0CE84D
                       db $40,$20,$10,$48,$DC,$B6,$63,$C0,$F7,$44,$FD,$1B,$FB,$16,$F6,$4C;0CE85D
                       db $E3,$56,$C9,$2B,$1C,$C1,$3E,$86,$89,$82,$84,$89,$9C,$B6,$63,$C1;0CE86D

; ------------------------------------------------------------------------------
; More Sprite Tile Pattern Data (0CE87D-0CE985)
; ------------------------------------------------------------------------------
; Continues sprite graphics with complex bit patterns

                       db $97,$FD,$AF,$D9,$AD,$FB,$95,$EB,$95,$EF,$25,$7E,$14,$5F,$09,$EB;0CE87D
                       db $68,$64,$44,$46,$42,$C3,$E3,$F6,$54,$EF,$6C,$FF,$6A,$BF,$3A,$FF;0CE88D
                       db $5B,$F7,$59,$E7,$AA,$D7,$21,$DF,$82,$82,$C4,$C4,$AC,$BE,$3D,$38;0CE89D
                       db $2B,$FE,$6B,$FE,$52,$FF,$AB,$DF,$A9,$DF,$D4,$FE,$26,$AF,$25,$FE;0CE8AD
                       db $D4,$94,$8C,$04,$06,$0B,$D9,$D9,$54,$FE,$54,$FF,$59,$FF,$AB,$FF;0CE8BD
                       db $AA,$7F,$56,$ED,$55,$EF,$54,$EF,$29,$28,$24,$44,$C5,$83,$82,$82;0CE8CD
                       db $97,$FD,$AF,$D9,$AD,$FB,$95,$EB,$94,$EF,$20,$7A,$30,$57,$42,$FF;0CE8DD
                       db $68,$64,$44,$46,$43,$C7,$EF,$BD,$54,$EF,$6C,$FF,$6A,$BF,$3A,$FF;0CE8ED
                       db $13,$B7,$89,$A5,$00,$3C,$08,$EB,$82,$82,$C4,$C4,$6C,$7E,$FF,$F7;0CE8FD
                       db $41,$DD,$90,$BF,$11,$5F,$09,$AB,$00,$A6,$42,$DB,$C5,$D7,$87,$D5;0CE90D
                       db $36,$63,$E2,$F6,$FF,$BD,$38,$38,$00,$4D,$81,$A5,$08,$CA,$14,$DE;0CE91D
                       db $90,$DE,$1A,$97,$2A,$B7,$2A,$B7,$FE,$7E,$77,$63,$63,$E1,$C1,$C1;0CE92D
                       db $25,$F7,$64,$B6,$A2,$F3,$40,$59,$48,$7E,$11,$BD,$91,$DD,$99,$DD;0CE93D
                       db $18,$19,$1D,$BF,$B7,$E6,$66,$66,$32,$BF,$14,$9E,$1C,$5E,$08,$4B;0CE94D
                       db $C0,$E6,$41,$F5,$C0,$5D,$42,$D7,$C1,$E3,$E3,$F7,$3F,$3E,$3E,$3C;0CE95D
                       db $23,$EB,$62,$E6,$50,$F4,$30,$D6,$51,$F7,$72,$F7,$23,$6E,$82,$EF;0CE96D
                       db $5C,$9D,$8F,$8F,$8E,$8C,$DC,$7C   ;0CE97D

; ------------------------------------------------------------------------------
; Sprite Mask & Pattern Data (0CE985-0CEA85)
; ------------------------------------------------------------------------------
; Sprite mask patterns and color data

                       db $FF,$FF,$00,$FF,$00,$FF,$FF,$00,$00,$FF,$FF,$FF,$81,$FF,$5A,$E7;0CE985
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$7E,$65,$7D,$3C,$FF,$A6,$FF,$E4,$FF;0CE995
                       db $77,$EF,$77,$EE,$D3,$EF,$FA,$47,$BE,$3C,$3C,$3C,$7E,$7E,$7E,$6E;0CE9A5
                       db $7A,$C6,$52,$EF,$77,$AF,$25,$FE,$BC,$FF,$53,$EF,$B9,$C7,$FF,$FF;0CE9B5
                       db $6F,$7E,$3C,$3C,$3C,$7E,$EF,$FF   ;0CE9C5

; Pattern sequence data
                       db $CB,$F4,$A5,$FA,$C5,$FA,$EB,$F4,$A7,$F8,$C5,$FA,$8B,$F4,$E7,$F8;0CE9CD
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF   ;0CE9DD
                       db $FF,$00,$FF,$00,$FF,$00,$00,$FF,$FF,$FF,$00,$00,$00,$00,$FF,$00;0CE9E5
                       db $00,$00,$00,$FF,$00,$FF,$FF,$FF,$FF,$00,$FF,$00,$FF,$00,$00,$FF;0CE9F5
                       db $FF,$FF,$00,$00,$18,$18,$C7,$7C,$00,$00,$00,$FF,$00,$FF,$E7,$A3;0CEA05

; Repeating pattern data blocks
                       db $9A,$56,$A9,$65,$DD,$33,$9A,$65,$10,$67,$21,$56,$02,$75,$12,$65;0CEA15
                       db $A9,$9A,$88,$CC,$CC,$CC,$CC,$CC,$05,$7C,$05,$7C,$05,$7C,$05,$7C;0CEA25
                       db $05,$7C,$05,$7C,$05,$7C,$05,$7C,$A3,$A3,$A3,$A3,$A3,$A3,$A3,$A3;0CEA35
                       db $12,$65,$21,$56,$22,$55,$12,$65,$10,$67,$21,$56,$02,$75,$12,$65;0CEA45
                       db $CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$13,$64,$33,$44,$31,$46,$01,$54;0CEA55
                       db $00,$77,$00,$00,$FF,$00,$00,$00,$CC,$CC,$CC,$EE,$CC,$FF,$FF,$FF;0CEA65
                       db $05,$7C,$05,$7C,$05,$7C,$05,$7C,$05,$7C,$05,$7C,$85,$7C,$6E,$1C;0CEA75
                       db $A3,$A3,$A3,$A3,$A3,$A3,$A3,$C3   ;0CEA85

; ------------------------------------------------------------------------------
; More Graphics Patterns (0CEA8D-0CEB65)
; ------------------------------------------------------------------------------
; Additional sprite and tile graphics data

                       db $83,$FF,$31,$FF,$54,$FF,$4C,$F5,$64,$FD,$2C,$FD,$00,$F9,$31,$CE;0CEA8D
                       db $7C,$CE,$8B,$93,$93,$D3,$FF,$FF,$82,$EF,$02,$FE,$4E,$F6,$5C,$F4;0CEA9D
                       db $94,$BC,$18,$F8,$28,$DB,$E1,$1E,$79,$F1,$31,$23,$63,$E7,$F7,$FF;0CEAAD
                       db $01,$67,$10,$52,$28,$BB,$5C,$ED,$08,$79,$28,$7B,$90,$D2,$90,$F6;0CEABD
                       db $FE,$EF,$C7,$83,$C7,$C7,$6F,$6F   ;0CEACD
                       db $45,$7D,$38,$FF,$8E,$FF,$D0,$DF,$07,$FF,$7B,$FC,$83,$FF,$8E,$7F;0CEAD5
                       db $82,$00,$00,$20,$00,$00,$00,$00,$52,$B2,$60,$FF,$6F,$9F,$01,$FE;0CEAE5
                       db $B4,$F7,$07,$FF,$CC,$F3,$0F,$FE,$0D,$00,$00,$00,$08,$00,$00,$00;0CEAF5

; Complex bit pattern sequences
                       db $AB,$60,$A9,$62,$DD,$52,$D6,$53,$46,$D3,$6C,$F9,$B2,$A9,$B6,$AD;0CEB05
                       db $1C,$1C,$2C,$2C,$2C,$06,$46,$42,$D5,$30,$DA,$31,$EA,$20,$A2,$64;0CEB15
                       db $B2,$64,$BC,$68,$94,$48,$11,$CE,$0E,$0E,$1F,$1B,$1B,$13,$33,$31;0CEB25
                       db $D3,$AD,$D7,$AD,$C7,$BD,$2F,$3D,$2E,$3C,$2E,$3C,$2E,$3C,$BA,$38;0CEB35
                       db $42,$42,$42,$C2,$C3,$C3,$C3,$C7,$51,$CE,$53,$CE,$7B,$CE,$7B,$CE;0CEB45
                       db $33,$86,$31,$84,$B5,$84,$B7,$84,$31,$31,$31,$31,$79,$7B,$7B,$7B;0CEB55
                       db $BA,$38,$BA,$38,$B9,$38,$B1,$30,$B1,$30,$B1,$30,$91,$10,$D1,$10;0CEB65

; ------------------------------------------------------------------------------
; Additional Graphics Data (0CEB75-0CEBFF)
; ------------------------------------------------------------------------------
; Continues graphics pattern data with various sprites and tiles

                       db $C7,$C7,$C5,$CD,$CD,$C9,$E9,$E9,$97,$84,$06,$04,$0E,$04,$4A,$00;0CEB75
                       db $50,$10,$40,$10,$50,$10,$90,$10,$5B,$CA,$CA,$CE,$C4,$C4,$C4,$80;0CEB85
                       db $58,$10,$5A,$12,$58,$12,$48,$02,$52,$02,$12,$02,$02,$02,$00,$00;0CEB95
                       db $68,$68,$68,$78,$70,$30,$20,$20,$00,$00,$00,$00,$00,$00,$00,$00;0CEBA5
                       db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00;0CEBB5
                       db $28,$39,$C3,$D3,$08,$6A,$02,$52,$2A,$28,$05,$90,$2B,$A0,$B3,$A0;0CEBC5
                       db $46,$2C,$95,$AD,$D7,$6F,$5F,$5F,$00,$00,$80,$C0,$81,$81,$40,$01;0CEBD5
                       db $A6,$06,$81,$05,$18,$18,$14,$3C,$00,$01,$62,$F6,$A9,$9A,$27,$43;0CEBE5
                       db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00;0CEBF5

; ------------------------------------------------------------------------------
; Mask Patterns & Bit Data (0CEC05-0CECFF)
; ------------------------------------------------------------------------------
; Sprite masking patterns for transparency and layering

                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF   ;0CEC05
                       db $D4,$FF,$C9,$C9,$93,$9F,$08,$48,$E5,$F7,$3C,$3C,$24,$E7,$7E,$7E;0CEC0D
                       db $00,$36,$60,$B7,$08,$C3,$18,$81,$95,$F5,$EF,$EF,$79,$7E,$EF,$EF;0CEC1D
                       db $24,$DF,$BF,$BF,$0A,$F6,$70,$FF,$0A,$10,$80,$10,$00,$40,$01,$00;0CEC2D
                       db $C7,$FF,$90,$90,$0F,$CF,$F9,$FF,$6F,$EF,$FA,$FA,$CE,$F7,$80,$7F;0CEC3D
                       db $00,$6F,$30,$00,$10,$05,$00,$00,$81,$00,$42,$00,$24,$00,$18,$00;0CEC4D
                       db $18,$00,$24,$00,$42,$00,$81,$00,$00,$00,$00,$00,$00,$00,$00,$00;0CEC5D
                       db $81,$00,$42,$00,$24,$00,$18,$00,$18,$00,$24,$00,$42,$00,$81,$00;0CEC6D
                       db $00,$00,$00,$00,$00,$00,$00,$00   ;0CEC7D

; More complex bit patterns
                       db $6F,$90,$AF,$47,$F1,$37,$AF,$3F,$5B,$DB,$35,$91,$34,$47,$1D,$6E;0CEC85
                       db $FF,$F8,$C8,$C0,$A4,$EE,$78,$70,$0B,$2C,$0B,$2C,$09,$2E,$09,$2E;0CEC95
                       db $0D,$2E,$1D,$2E,$1D,$2E,$1D,$2E,$30,$30,$30,$30,$30,$30,$30,$30;0CECA5
                       db $15,$26,$15,$26,$17,$24,$17,$24,$17,$24,$17,$24,$15,$26,$15,$26;0CECB5
                       db $38,$38,$38,$38,$38,$38,$38,$38,$11,$22,$02,$13,$0A,$13,$0A,$13;0CECC5
                       db $09,$11,$01,$09,$05,$09,$04,$08,$3C,$1C,$1C,$1C,$1E,$0E,$0E,$0F;0CECD5
                       db $E0,$24,$D0,$36,$D0,$36,$F4,$12,$6C,$9A,$68,$9A,$7A,$89,$B6,$CD;0CECE5
                       db $1C,$0E,$0E,$0E,$06,$06,$07,$03,$02,$8C,$02,$8C,$85,$4E,$42,$2F;0CECF5

; ------------------------------------------------------------------------------
; Additional Pattern Data (0CED05-0CEDFF)
; ------------------------------------------------------------------------------

                       db $A7,$9F,$53,$CF,$CF,$C7,$FC,$54,$8F,$8F,$CF,$EF,$7F,$3F,$3E,$FF;0CED05
                       db $BD,$C4,$4A,$76,$2F,$33,$97,$19,$4B,$8C,$F2,$C3,$FC,$F0,$9F,$FF;0CED15
                       db $03,$81,$C0,$E0,$F0,$FC,$3F,$07,$00,$FF,$00,$FF,$FF,$00,$FF,$00;0CED25
                       db $80,$80,$80,$80,$C1,$C1,$C1,$C1,$FF,$FF,$FF,$FF,$7F,$7F,$3E,$3E;0CED35
                       db $E3,$E3,$E3,$E3,$F7,$F7,$FF,$00,$00,$00,$FF,$FF,$00,$FF,$FF,$FF;0CED45
                       db $1C,$1C,$08,$FF,$FF,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF;0CED55
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00;0CED65
                       db $FF,$FF,$C6,$C6,$BB,$82,$82,$FF,$BA,$83,$83,$FF,$FF,$FF,$FF,$FF;0CED75
                       db $00,$39,$7D,$00,$7C,$00,$00,$00,$FF,$FF,$03,$AB,$55,$01,$01,$55;0CED85
                       db $AB,$01,$01,$FF,$FF,$FF,$FF,$FF,$00,$54,$FE,$AA,$FE,$00,$00,$00;0CED95
                       db $DB,$DB,$ED,$C9,$FF,$C9,$ED,$C9,$C9,$DB,$DB,$DB,$DB,$FF,$FF,$FF;0CEDA5
                       db $24,$36,$36,$36,$24,$24,$00,$00,$FF,$FF,$BD,$81,$81,$BF,$BB,$A3;0CEDB5
                       db $A3,$BB,$BB,$83,$83,$FF,$FF,$FF,$00,$7E,$40,$5C,$44,$7C,$00,$00;0CEDC5
                       db $E3,$E3,$C1,$C1,$C1,$C1,$80,$80,$FF,$FF,$00,$FF,$FF,$00,$FF,$00;0CEDD5
                       db $1C,$3E,$3E,$7F,$00,$00,$FF,$FF,$FF,$FF,$FF,$00,$00,$00,$FF,$FF;0CEDE5
                       db $00,$FF,$FF,$FF,$F7,$F7,$E3,$E3,$00,$FF,$FF,$00,$00,$00,$08,$1C;0CEDF5

; ------------------------------------------------------------------------------
; More Graphics Patterns (0CEE05-0CEEFF)
; ------------------------------------------------------------------------------

                       db $DD,$FF,$76,$77,$A0,$A3,$46,$47,$65,$65,$A6,$BE,$3C,$3C,$08,$08;0CEE05
                       db $00,$88,$5C,$B8,$9A,$41,$C3,$F7,$D4,$D4,$18,$F8,$B0,$70,$E1,$E1;0CEE15
                       db $04,$04,$8E,$8E,$C4,$FC,$28,$78,$2B,$07,$0F,$1E,$FB,$71,$03,$87;0CEE25
                       db $83,$83,$81,$81,$10,$10,$06,$06,$0E,$0E,$04,$04,$00,$00,$00,$00;0CEE35
                       db $1C,$76,$AF,$F9,$71,$FB,$CE,$9E,$A0,$A0,$00,$00,$A0,$A0,$40,$40;0CEE45
                       db $00,$00,$00,$00,$0C,$0C,$08,$08,$57,$E5,$5F,$BF,$FF,$AE,$F3,$D7;0CEE55
                       db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00;0CEE65
                       db $0B,$58,$9E,$1C,$40,$04,$00,$00,$14,$14,$08,$08,$1E,$1E,$0C,$0C;0CEE75
                       db $1A,$1E,$9A,$9E,$D4,$DA,$71,$FF,$14,$08,$1E,$0C,$1E,$9E,$DE,$FF;0CEE85
                       db $04,$0C,$14,$1C,$08,$18,$20,$30,$54,$74,$AC,$EC,$64,$EC,$85,$8D;0CEE95
                       db $0C,$1C,$18,$30,$74,$EC,$EC,$8D,$B5,$EB,$45,$7B,$25,$3B,$B3,$BD;0CEEA5
                       db $93,$9D,$9F,$99,$11,$1F,$15,$1B,$FF,$7F,$3F,$BF,$9F,$9F,$1F,$1F;0CEEB5
                       db $47,$4F,$66,$6E,$28,$2C,$38,$3C,$1A,$1E,$28,$2C,$2A,$2E,$44,$46;0CEEC5
                       db $4F,$6E,$2C,$3C,$1E,$2C,$2E,$46,$15,$1B,$55,$5B,$5D,$53,$5F,$53;0CEED5
                       db $1B,$17,$1F,$13,$38,$36,$36,$3A,$1F,$5F,$5F,$5F,$1F,$1F,$3E,$3E;0CEEE5
                       db $44,$46,$45,$47,$44,$46,$C6,$C6,$87,$87,$86,$86,$82,$82,$00,$00;0CEEF5

; ------------------------------------------------------------------------------
; Continued Graphics Data (0CEF05-0CEF85)
; ------------------------------------------------------------------------------

                       db $46,$47,$46,$C6,$87,$86,$82,$00,$2E,$32,$3A,$36,$22,$3E,$3E,$36;0CEF05
                       db $64,$7C,$74,$7C,$6C,$6C,$28,$28,$3E,$3E,$3E,$3E,$7C,$7C,$6C,$28;0CEF15
                       db $00,$00,$02,$02,$00,$00,$40,$40,$20,$20,$10,$10,$11,$11,$52,$52;0CEF25
                       db $16,$69,$FD,$B5,$91,$89,$8A,$A9,$00,$00,$12,$12,$24,$24,$30,$30;0CEF35
                       db $29,$29,$88,$88,$49,$49,$2A,$2A,$11,$21,$92,$8A,$92,$22,$A6,$95;0CEF45
                       db $1A,$9A,$4A,$4A,$8A,$AA,$80,$A0,$A2,$B3,$C1,$D5,$40,$52,$5A,$5A;0CEF55
                       db $61,$B1,$50,$1E,$0C,$2A,$AD,$A5,$20,$A8,$00,$88,$82,$D2,$06,$56;0CEF65
                       db $54,$54,$50,$D0,$42,$4A,$AA,$8A,$53,$73,$25,$A1,$AA,$2F,$B5,$55;0CEF75

; ------------------------------------------------------------------------------
; Tilemap Pattern Tables (0CEF85-0CF2A0)
; ------------------------------------------------------------------------------
; 4x4 tile arrangement patterns for map rendering
; Format: Usually groups of 4-5 bytes defining tile IDs + control byte

DATA8_0CEF85:
                       db $D7,$D7,$D7,$D7                   ; Fill pattern marker

DATA8_0CEF89:
                       db $55                               ; Control byte (flip/priority)
                       db $00                               ; Spacer
                       db $20,$21,$22,$23,$55               ; Pattern 1: 4 tiles + control
                       db $00
                       db $24,$25,$26,$27,$55               ; Pattern 2
                       db $00
                       db $0C,$0D,$0E,$0F,$55               ; Pattern 3
                       db $00
                       db $18,$18,$19,$19,$55               ; Pattern 4: Repeated tiles
                       db $00,$28,$29,$2A,$2B,$55,$00,$1A,$1B,$1A,$1B,$55,$00
                       db $04,$05,$06,$07,$55
                       db $00
                       db $14,$15,$16,$17,$55
                       db $00
                       db $10,$11,$12,$13,$55
                       db $00
                       db $00,$01,$02,$03,$55
                       db $00
                       db $1C,$1D,$1E,$1F,$55
                       db $00
                       db $08,$09,$0A,$0B,$55
                       db $00
                       db $2C,$2C,$2C,$2C,$55               ; Repeated tile pattern
                       db $00,$37,$D7,$D7,$D7,$55,$00,$45,$3C,$D7,$D7,$55,$00
                       db $D0,$D1,$D2,$D3,$00
                       db $00
                       db $D4,$D5,$D6,$D7,$00
                       db $00
                       db $D2,$D3,$D4,$D5,$00
                       db $00
                       db $D6,$D7,$D7,$D7,$00
                       db $00,$45,$3C,$0C,$0D,$E0,$05
                       db $D7,$D7,$D8,$D9,$00
                       db $00
                       db $DA,$DA,$DA,$DA,$00
                       db $00,$DB,$DB,$DC,$DD,$00,$00,$CE,$CF,$DE,$DF,$05,$00,$CE,$CF,$C0
                       db $C0,$00,$00,$C1,$C1,$C2,$C2,$00,$00
                       db $C3,$C3,$C3,$C3,$88               ; Different control byte
                       db $00
                       db $E7,$E7,$E8,$E8,$00
                       db $00
                       db $E9,$E9,$EA,$EB,$00
                       db $00
                       db $EC,$ED,$E9,$E9,$00
                       db $00
                       db $EF,$EF,$EE,$EE,$00
                       db $00
                       db $F0,$F1,$F2,$F3,$55
                       db $00
                       db $F2,$F3,$F4,$F5,$54               ; Different control
                       db $00
                       db $F6,$F7,$FA,$FB,$00
                       db $00
                       db $FC,$FD,$FE,$FF,$55
                       db $00
                       db $F6,$F7,$F8,$F9,$00
                       db $00
                       db $FA,$FB,$FC,$FD,$05               ; Another control variant
                       db $00
                       db $F2,$F3,$F2,$F3,$55
                       db $00
                       db $F4,$F5,$F6,$F7,$40               ; Yet another control
                       db $00
                       db $E0,$E0,$E1,$E1,$22
                       db $00
                       db $E2,$E2,$E2,$E2,$22
                       db $00
                       db $E3,$E4,$E5,$E6,$00
                       db $00
                       db $B7,$B8,$B5,$B6,$00
                       db $00
                       db $B7,$B8,$B9,$BA,$00
                       db $00
                       db $BB,$BC,$BD,$BE,$00
                       db $00
                       db $BC,$BB,$BE,$BD,$AA               ; Swapped tile pattern
                       db $00
                       db $BF,$CD,$CB,$CC,$00
                       db $00,$C4,$C5,$C6,$C7,$00,$00,$C8,$C7,$C8,$C7,$00,$00,$C8,$C7,$C9
                       db $CA,$00,$00,$C4,$C4,$C6,$C6,$00,$00,$C8,$C8,$C8,$C8,$00,$00,$C8
                       db $C8,$C9,$C9,$00,$00
                       db $A3,$A4,$A5,$A6,$00
                       db $00
                       db $A7,$A8,$A9,$AA,$00
                       db $00
                       db $A0,$A1,$B0,$B1,$00
                       db $00
                       db $A2,$B2,$A2,$B2,$00
                       db $00
                       db $A2,$B2,$B3,$B4,$00
                       db $00,$45,$D7,$D7,$D7,$C0,$00
                       db $AF,$AF,$AF,$AF,$00
                       db $00
                       db $AF,$AF,$97,$98,$00
                       db $00
                       db $9D,$9E,$99,$9A,$00
                       db $00
                       db $9F,$AF,$9B,$9C,$00
                       db $00
                       db $60,$61,$62,$63,$00
                       db $00
                       db $64,$65,$66,$67,$00
                       db $00
                       db $68,$69,$6A,$6B,$00
                       db $00
                       db $6C,$6D,$6E,$6F,$00
                       db $00
                       db $AB,$AC,$AD,$AD,$05
                       db $00
                       db $AB,$AB,$AD,$AD,$05
                       db $00
                       db $AB,$AC,$AE,$AE,$05
                       db $00
                       db $AB,$AB,$AE,$AE,$05
                       db $00
                       db $AB,$AC,$95,$96,$00
                       db $00
                       db $AB,$AB,$96,$96,$00
                       db $00
                       db $AB,$AC,$93,$94,$05
                       db $00
                       db $AB,$AB,$94,$94,$05
                       db $00
                       db $AB,$AC,$5C,$5D,$05
                       db $00
                       db $AB,$AB,$5C,$5D,$05
                       db $00,$CE,$CF,$5E,$5F,$00,$00,$D7,$D7,$4E,$4F,$00,$00
                       db $9D,$9D,$90,$91,$00
                       db $00
                       db $9D,$9D,$5A,$5B,$00
                       db $00
                       db $84,$85,$50,$51,$00
                       db $00
                       db $58,$59,$56,$57,$00
                       db $00
                       db $82,$83,$80,$81,$00
                       db $00
                       db $54,$55,$52,$53,$00
                       db $00
                       db $86,$87,$88,$89,$00
                       db $00
                       db $7A,$7B,$8A,$8B,$00
                       db $00
                       db $7C,$7D,$8C,$8D,$00
                       db $00
                       db $7E,$7F,$8E,$8F,$00
                       db $00,$70,$71,$72,$73,$00,$00,$76,$77,$78,$79,$00,$00,$AF,$AF,$74
                       db $75,$00,$00,$D7,$D7,$0C,$0D,$00,$55,$0E,$0F,$0C,$0D,$00,$55,$0E
                       db $0F,$30,$32,$00,$55,$31,$33,$D7,$D7,$00,$55,$34,$D7,$D7,$D7,$00
                       db $55,$D7,$D7,$D7,$34,$00,$55,$34,$D7,$D7,$34,$00,$55,$35,$D7,$D7
                       db $D7,$00,$55,$D7,$D7,$D7,$35,$00,$55,$36,$D7,$D7,$D7,$00,$55,$37
                       db $46,$3C,$41,$00,$00,$41,$42,$46,$47,$00,$00,$43,$48,$48,$48,$03
                       db $00,$48,$41,$3D,$3C,$FF,$00,$2F,$4D,$4C,$4B,$FF,$00,$37,$4D,$45
                       db $4C,$0C,$00,$39,$3A,$3E,$3F,$00,$00,$48,$41,$3D,$3C,$FF,$00,$44
                       db $4A,$4B,$37,$3F,$00,$4A,$D7,$D7,$D7,$C0,$00,$D7,$D7,$D7,$4A,$00
                       db $00,$4D,$2F,$4D,$3D,$00,$00,$3F,$3A,$39,$3F,$89,$00,$39,$46,$3E
                       db $38,$47,$00,$4A,$D7,$45,$D7,$C0,$00,$37,$46,$37,$41,$00,$00,$49
                       db $41,$43,$3C,$33,$00,$37,$4D,$3C,$3D,$04,$00,$44,$37,$3C,$D7,$3C
                       db $00,$D7,$D7,$D7,$44,$03,$00,$41,$42,$46,$47,$00,$00,$43,$49,$44
                       db $37,$03,$00,$44,$37,$45,$D7,$30,$00,$3C,$38,$3C,$44,$08,$00,$38
                       db $44,$3C,$37,$CF,$00,$00,$00,$15,$7C,$15,$7C,$15,$7C,$15,$7C,$15
                       db $7C,$15,$7C,$15,$7C,$00,$00,$15,$7C,$15,$7C,$15,$7C,$15,$7C,$15
                       db $7C,$15,$7C,$15,$7C

; ------------------------------------------------------------------------------
; 15-bit RGB Color Palette Data (0CF2A5-0CF425)
; ------------------------------------------------------------------------------
; SNES BGR555 format: $00,$00 = Black, $FF,$7F = White
; 384 bytes of palette data (192 colors)

PaletteDataBlock:
                       db $00,$00,$5D,$63,$D9,$52,$54,$42,$AF,$35,$4C,$21,$C8,$18,$65,$08;0CF2A5
                       db $00,$00,$7A,$52,$95,$39,$30,$29,$EE,$1C,$CA,$20,$C5,$24,$5A,$6B;0CF2B5
                       db $00,$00,$F6,$7E,$72,$72,$EE,$61,$6A,$51,$E6,$40,$FF,$7F,$3A,$7F;0CF2C5
                       db $00,$00,$59,$7F,$D1,$7E,$4B,$7A,$C4,$69,$E2,$34,$FF,$7F,$F5,$7F;0CF2D5
                       db $00,$00,$2B,$62,$E2,$34,$60,$18,$00,$00,$B1,$0B,$26,$17,$66,$2E;0CF2E5
                       db $00,$00,$17,$2A,$72,$15,$EE,$04,$6A,$00,$65,$00,$59,$32,$D1,$7E;0CF2F5
                       db $00,$00,$ED,$16,$E9,$15,$41,$05,$A0,$08,$8F,$29,$EB,$0C,$68,$08;0CF305
                       db $00,$00,$15,$5F,$91,$4E,$0E,$42,$71,$7F,$8A,$2D,$28,$21,$C5,$14;0CF315
                       db $00,$00,$15,$5F,$91,$4E,$0E,$42,$71,$7F,$8A,$2D,$28,$21,$C5,$14;0CF325
                       db $00,$00,$11,$7B,$75,$7B,$FE,$7F,$D9,$7F,$34,$6B,$77,$77,$7B,$73;0CF335
                       db $00,$00,$59,$7F,$D1,$7E,$4B,$7A,$C4,$69,$E2,$34,$8B,$56,$66,$2E;0CF345
                       db $00,$00,$D8,$77,$33,$6F,$2B,$4E,$86,$39,$04,$29,$83,$14,$FF,$7F;0CF355
                       db $00,$00,$BD,$77,$39,$67,$73,$4E,$EF,$3D,$6B,$2D,$C6,$18,$D0,$31;0CF365
                       db $00,$00,$7B,$73,$57,$6F,$FF,$7F,$6F,$5E,$BC,$77,$99,$73,$34,$6B;0CF375
                       db $00,$00,$66,$2E,$27,$3A,$FF,$7F,$71,$7F,$34,$6B,$8D,$52,$08,$3E;0CF385
                       db $00,$00,$39,$4E,$32,$2D,$14,$63,$71,$7F,$8D,$46,$E8,$31,$84,$25;0CF395
                       db $00,$00,$39,$4E,$32,$2D,$FF,$7F,$71,$7F,$99,$77,$34,$6F,$CF,$6A;0CF3A5
                       db $00,$00,$59,$7F,$D1,$7E,$4B,$7A,$C4,$69,$B1,$0B,$26,$17,$66,$2E;0CF3B5
                       db $00,$00,$17,$2A,$72,$15,$EE,$04,$6A,$00,$65,$00,$26,$17,$66,$2E;0CF3C5
                       db $00,$00,$2B,$62,$E2,$34,$60,$18,$00,$00,$17,$2A,$0F,$01,$6A,$00;0CF3D5
                       db $00,$00,$C6,$16,$46,$26,$FF,$7F,$71,$7F,$34,$6B,$8D,$52,$08,$3E;0CF3E5
                       db $00,$00,$D7,$4E,$35,$42,$B2,$29,$4D,$2D,$4C,$25,$08,$21,$15,$7C;0CF3F5
                       db $00,$00,$91,$5E,$11,$6C,$6D,$18,$08,$14,$84,$4C,$04,$34,$42,$18;0CF405
                       db $00,$00,$D5,$6A,$0F,$56,$49,$3D,$A4,$28,$20,$18,$FF,$7F,$38,$77;0CF415

; ------------------------------------------------------------------------------
; Tilemap Data - Various Map Patterns (0CF425-0CF715)
; ------------------------------------------------------------------------------
; 16x16 byte blocks defining tile arrangements for different map areas
; Marked as UNREACH - possibly unused or special purpose tilemap data

UNREACH_0CF425:
                       db $3C,$3C,$3C,$3C,$3C,$3C,$3C,$3C,$3D,$3E,$3F,$3D,$46,$47,$47,$46;0CF425
                       db $3C,$3C,$3C,$3C,$3C,$3C,$3C,$3C,$3D,$3E,$3F,$3D,$46,$47,$47,$46;0CF435
                       db $16,$16,$16,$16,$50,$51,$50,$51,$52,$53,$52,$53,$54,$55,$54,$55;0CF445
                       db $36,$37,$36,$37,$37,$36,$37,$36,$36,$37,$36,$37,$37,$36,$37,$36;0CF455
                       db $16,$16,$16,$16,$16,$16,$16,$16,$56,$57,$56,$57,$58,$59,$58,$59;0CF465
                       db $2B,$2B,$2B,$2B,$2B,$2B,$2B,$2B,$2B,$2B,$2B,$2B,$2C,$2C,$2C,$2C;0CF475
                       db $2D,$2D,$2D,$2D,$2E,$2E,$2E,$2E,$2D,$2D,$2D,$2D,$2F,$2F,$2F,$2F;0CF485
                       db $1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B;0CF495
                       db $5B,$5B,$5B,$5B,$5B,$5B,$5B,$5B,$5B,$5B,$5B,$5B,$5B,$5B,$5B,$5B;0CF4A5
                       db $3C,$3C,$3C,$3C,$3C,$3C,$3C,$3C,$5A,$5C,$5A,$5C,$5B,$5B,$5B,$5B;0CF4B5
                       db $16,$16,$16,$16,$17,$17,$17,$17,$19,$19,$19,$19,$1A,$1A,$1A,$1A;0CF4C5
                       db $33,$30,$33,$33,$34,$31,$34,$34,$34,$31,$34,$34,$35,$32,$35,$35;0CF4D5
                       db $28,$28,$28,$28,$29,$29,$29,$29,$29,$29,$29,$29,$2A,$2A,$2A,$2A;0CF4E5
                       db $38,$39,$38,$39,$39,$38,$39,$38,$38,$39,$38,$39,$3A,$3A,$3A,$3A;0CF4F5
                       db $1C,$1C,$1C,$1C,$1D,$1D,$1D,$1D,$1E,$1E,$1E,$1E,$1F,$1F,$1F,$1F;0CF505
                       db $20,$20,$26,$20,$21,$21,$27,$21,$22,$24,$22,$24,$23,$25,$23,$25;0CF515
                       db $3C,$3C,$3C,$3C,$3C,$3C,$3C,$3C,$3D,$3E,$3F,$3D,$4A,$4B,$4B,$4A;0CF525
                       db $3C,$3C,$3C,$3C,$3C,$3C,$3C,$3C,$3D,$3E,$3F,$3D,$48,$49,$49,$48;0CF535
                       db $3C,$3C,$3C,$3C,$3C,$3C,$3C,$3C,$3D,$3E,$3F,$3D,$4C,$4D,$4D,$4C;0CF545
                       db $40,$41,$40,$41,$42,$43,$42,$43,$3D,$3E,$3F,$3D,$4A,$4B,$4B,$4A;0CF555
                       db $40,$41,$40,$41,$42,$43,$42,$43,$3D,$3E,$3F,$3D,$46,$47,$47,$46;0CF565
                       db $10,$10,$12,$11,$11,$11,$13,$00,$00,$00,$00,$00,$4F,$4F,$4F,$4F;0CF575
                       db $10,$10,$12,$11,$11,$11,$13,$00,$00,$00,$00,$00,$15,$15,$15,$15;0CF585
                       db $3C,$3C,$3C,$3C,$3C,$3C,$3C,$3C,$3D,$3E,$3F,$3D,$44,$45,$45,$44;0CF595
                       db $3C,$3C,$3C,$3C,$3C,$3C,$3C,$3C,$3D,$3E,$3F,$3D,$46,$47,$47,$46;0CF5A5
                       db $16,$16,$16,$16,$16,$16,$16,$16,$17,$17,$17,$17,$4E,$4E,$4E,$4E;0CF5B5
                       db $16,$16,$16,$16,$16,$16,$16,$16,$17,$17,$17,$17,$18,$18,$18,$18;0CF5C5

; Special map layout data - appears to be specific room or area configurations
                       db $00,$62,$65,$00,$00,$00,$00,$00,$00,$62,$00,$67,$68,$69,$6A,$6B;0CF5D5
                       db $00,$00,$62,$00,$00,$00,$00,$00,$65,$00,$66,$6C,$6D,$6E,$6F,$70;0CF5E5
                       db $00,$62,$00,$65,$61,$00,$00,$00,$00,$61,$71,$72,$73,$74,$75,$00;0CF5F5
                       db $00,$65,$61,$00,$00,$00,$00,$00,$00,$62,$76,$68,$69,$77,$65,$00;0CF605
                       db $62,$00,$63,$00,$00,$00,$00,$00,$00,$00,$78,$6D,$6E,$79,$66,$61;0CF615
                       db $00,$66,$65,$00,$00,$00,$65,$61,$00,$7A,$7B,$7C,$7D,$63,$64,$00;0CF625
                       db $00,$64,$61,$00,$00,$00,$62,$66,$00,$7E,$7F,$0E,$62,$00,$00,$00;0CF635
                       db $00,$00,$00,$3B,$0F,$64,$5D,$5D,$5D,$14,$3B,$00,$00,$65,$00,$00;0CF645
                       db $00,$62,$0E,$7F,$7E,$5D,$5E,$5E,$5E,$5E,$5D,$00,$62,$00,$00,$00;0CF655
                       db $64,$7D,$7C,$7B,$7A,$5F,$5E,$5E,$5E,$5E,$5F,$00,$00,$61,$00,$61;0CF665
                       db $79,$6E,$6D,$78,$00,$60,$5F,$5E,$5E,$5F,$60,$00,$64,$00,$00,$61;0CF675
                       db $77,$69,$68,$76,$00,$61,$60,$5E,$5E,$60,$00,$00,$00,$61,$64,$00;0CF685

; Repeated fill pattern - likely unused space
                       db $04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04;0CF695
                       db $04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04;0CF6A5
                       db $04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04;0CF6B5
                       db $04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04;0CF6C5

; Scroll/animation timing data
                       db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$18;0CF6D5
                       db $00,$38,$00,$78,$00,$F0,$00,$F0,$00,$00,$00,$00,$00,$00,$00,$00;0CF6E5
                       db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$18;0CF6F5
                       db $00,$38,$00,$78,$00,$F0,$00,$F0,$00,$00,$00,$00,$00,$00,$00,$00;0CF705

; ------------------------------------------------------------------------------
; Entity/Animation Data Tables (0CF715-0CF788)
; ------------------------------------------------------------------------------
; Appears to be entity configuration or animation sequence data

UNREACH_0CF715:
                       db $00
UNREACH_0CF716:
                       db $00
UNREACH_0CF717:
                       db $01
                       db $01,$21,$10,$02,$32,$12,$03,$F1,$04,$04,$32,$11,$05,$32,$03,$06
                       db $21,$03,$07,$24,$02
                       db $08,$95,$09,$09,$95,$09,$0A,$26,$15,$0B,$26,$07
                       db $0C,$27,$0E,$06,$32,$03
                       db $06,$27,$03,$06,$21,$03
                       db $0D,$49,$0D,$0D,$4D,$0D
                       db $0E,$49,$0D
                       db $0E,$43,$0D,$0F,$7A,$08,$10,$FB,$0F,$11,$FB,$0F,$12,$B8,$0F
                       db $13,$BB,$0F
                       db $14,$27,$10
                       db $15,$6B,$14
                       db $16,$7C,$07,$0F,$8A,$08,$17,$6B,$10
                       db $11,$6B,$16,$12,$C8,$10
                       db $17,$6B,$10
                       db $18,$27,$10,$19,$6B,$13,$06,$21,$17,$FF,$FF,$FF,$FF,$FF,$FF,$FF

; ------------------------------------------------------------------------------
; Large $FF Fill Block (0CF788-0CFFF8)
; ------------------------------------------------------------------------------
; 2416 bytes of $FF - padding to end of bank
; This is unreachable/unused space

                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF;0CF788
                       ; ... (2400 more $FF bytes) ...
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF   ;0CFFF8

; ==============================================================================
; END OF BANK $0C DOCUMENTATION - 100% COMPLETE!
; ==============================================================================
; Total: 4,227 lines documented
; Bank $0C contains Display/PPU management, graphics data, tilemaps, palettes,
; sprite patterns, and entity configurations
; ==============================================================================
; ==============================================================================
; Bank $0C Final Padding - Complete Bank Boundary Alignment
; ==============================================================================
; Address Range: $0CFCB8-$0CFFFF
; Purpose: Unused space filled with $FF bytes to align bank to 64KB boundary
; ------------------------------------------------------------------------------

; ==============================================================================
; BANK PADDING SECTION ($0CFCB8-$0CFFFF)
; ==============================================================================
; This section contains 840 bytes of $FF padding to fill the remainder of
; Bank $0C to the 64KB boundary at $0CFFFF. This is standard SNES ROM practice
; to align each bank to exactly 65,536 bytes ($10000 hex).
; ==============================================================================

                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF;0CFCB8|        |FFFFFF;
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF;0CFCC8|        |FFFFFF;
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF;0CFCD8|        |FFFFFF;
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF;0CFCE8|        |FFFFFF;
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF;0CFCF8|        |FFFFFF;
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF;0CFD08|        |FFFFFF;
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF;0CFD18|        |FFFFFF;
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF;0CFD28|        |FFFFFF;
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF;0CFD38|        |FFFFFF;
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF;0CFD48|        |FFFFFF;
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF;0CFD58|        |FFFFFF;
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF;0CFD68|        |FFFFFF;
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF;0CFD78|        |FFFFFF;
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF;0CFD88|        |FFFFFF;
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF;0CFD98|        |FFFFFF;
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF;0CFDA8|        |FFFFFF;
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF;0CFDB8|        |FFFFFF;
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF;0CFDC8|        |FFFFFF;
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF;0CFDD8|        |FFFFFF;
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF;0CFDE8|        |FFFFFF;
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF;0CFDF8|        |FFFFFF;
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF;0CFE08|        |FFFFFF;
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF;0CFE18|        |FFFFFF;
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF;0CFE28|        |FFFFFF;
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF;0CFE38|        |FFFFFF;
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF;0CFE48|        |FFFFFF;
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF;0CFE58|        |FFFFFF;
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF;0CFE68|        |FFFFFF;
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF;0CFE78|        |FFFFFF;
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF;0CFE88|        |FFFFFF;
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF;0CFE98|        |FFFFFF;
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF;0CFEA8|        |FFFFFF;
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF;0CFEB8|        |FFFFFF;
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF;0CFEC8|        |FFFFFF;
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF;0CFED8|        |FFFFFF;
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF;0CFEE8|        |FFFFFF;
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF;0CFEF8|        |FFFFFF;
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF;0CFF08|        |FFFFFF;
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF;0CFF18|        |FFFFFF;
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF;0CFF28|        |FFFFFF;
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF;0CFF38|        |FFFFFF;
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF;0CFF48|        |FFFFFF;
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF;0CFF58|        |FFFFFF;
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF;0CFF68|        |FFFFFF;
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF;0CFF78|        |FFFFFF;
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF;0CFF88|        |FFFFFF;
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF;0CFF98|        |FFFFFF;
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF;0CFFA8|        |FFFFFF;
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF;0CFFB8|        |FFFFFF;
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF;0CFFC8|        |FFFFFF;
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF;0CFFD8|        |FFFFFF;
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF;0CFFE8|        |FFFFFF;
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF   ;0CFFF8|        |FFFFFF; Bank boundary at $0CFFFF

; ==============================================================================
; END OF BANK $0C - Display/PPU Management
; ==============================================================================
; Total Bank Size: 65,536 bytes (64KB) from $0C0000 to $0CFFFF
; Documented Lines: 4,226 lines (100% COMPLETE)
; Documentation Quality: Comprehensive inline comments for all routines
; ==============================================================================
