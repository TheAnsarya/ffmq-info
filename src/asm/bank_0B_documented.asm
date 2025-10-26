; ==============================================================================
; Bank $0B - Battle Graphics and Animation Routines
; ==============================================================================
; This bank contains executable code for battle graphics management,
; sprite animation, and visual effects during combat.
;
; Memory Range: $0B8000-$0BFFFF (32 KB)
;
; Major Sections:
; - Graphics loading routines
; - Sprite animation controllers
; - Battle effect rendering
; - OAM (Object Attribute Memory) management
; - DMA transfer routines for graphics
;
; Key Routines:
; - CODE_0B8000: Graphics setup based on battle type
; - CODE_0B803F: Sprite animation handler
; - CODE_0B8077: OAM data update routine
;
; Related Files:
; - Bank $09/$0A: Graphics data used by these routines
; - Bank $0C: Display/screen management code
; ==============================================================================

	ORG $0B8000

; ==============================================================================
; Graphics Setup Routine
; ==============================================================================
; Sets up graphics pointers based on battle encounter type.
; Input: $0E8B = Battle type index
; ==============================================================================

CODE_0B8000:
	LDA.W $0E8B								;0B8000	; Load battle type
	BEQ CODE_0B8017							;0B8003	; Branch if type 0
	DEC A									;0B8005	; Decrement type
	BEQ CODE_0B8023							;0B8006	; Branch if type 1
	DEC A									;0B8008	; Decrement type
	BEQ CODE_0B802F							;0B8009	; Branch if type 2

	; Type 3: Setup pointers
	LDA.B #$4A								;0B800B	; Graphics pointer low
	STA.W $0507								;0B800D	; Store to pointer
	LDA.B #$1B								;0B8010	; Graphics pointer high
	STA.W $0506								;0B8012	; Store to pointer
	BRA CODE_0B8039							;0B8015	; Jump to common setup

CODE_0B8017:
	; Type 0: Default graphics
	LDA.B #$A1								;0B8017	; Graphics pointer low
	STA.W $0507								;0B8019	; Store to pointer
	LDA.B #$1F								;0B801C	; Graphics pointer high
	STA.W $0506								;0B801E	; Store to pointer
	BRA CODE_0B8039							;0B8021	; Jump to common setup

CODE_0B8023:
	; Type 1: Alternate graphics
	LDA.B #$B6								;0B8023	; Graphics pointer low
	STA.W $0507								;0B8025	; Store to pointer
	LDA.B #$1B								;0B8028	; Graphics pointer high
	STA.W $0506								;0B802A	; Store to pointer
	BRA CODE_0B8039							;0B802D	; Jump to common setup

CODE_0B802F:
	; Type 2: Special graphics
	LDA.B #$5F								;0B802F	; Graphics pointer low
	STA.W $0507								;0B8031	; Store to pointer
	LDA.B #$1F								;0B8034	; Graphics pointer high
	STA.W $0506								;0B8036	; Store to pointer

CODE_0B8039:
	; Common graphics setup
	LDA.B #$0A								;0B8039	; Bank $0A (graphics bank)
	STA.W $0505								;0B803B	; Store bank number
	RTL										;0B803E	; Return

; ==============================================================================
; Sprite Animation Handler
; ==============================================================================
; Main routine for updating sprite animations during battle.
; Manages OAM data, animation frames, and DMA transfers.
; ==============================================================================

CODE_0B803F:
	PHP										;0B803F	; Save processor status
	PHB										;0B8040	; Save data bank
	PHX										;0B8041	; Save X register
	PHY										;0B8042	; Save Y register
	SEP #$20								;0B8043	; 8-bit accumulator
	REP #$10								;0B8045	; 16-bit index
	PHK										;0B8047	; Push program bank
	PLB										;0B8048	; Pull to data bank
	JSR.W CODE_0B80D9						;0B8049	; Call animation update
	LDX.W $192B								;0B804C	; Load sprite index
	CPX.W #$FFFF							;0B804F	; Check for invalid
	BEQ CODE_0B80A1							;0B8052	; Branch if invalid
	LDA.W $1A80,X							;0B8054	; Load sprite flags
	AND.B #$CF								;0B8057	; Mask off animation bits
	ORA.B #$10								;0B8059	; Set animation active flag
	STA.W $1A80,X							;0B805B	; Store updated flags
	LDA.W $1A82,X							;0B805E	; Load animation ID
	REP #$30								;0B8061	; 16-bit mode
	AND.W #$00FF							;0B8063	; Mask to byte
	ASL A									;0B8066	; Multiply by 2
	PHX										;0B8067	; Save sprite index
	TAX										;0B8068	; Transfer to X
	LDA.L DATA8_00FDCA,X					;0B8069	; Load animation data pointer
	CLC										;0B806D	; Clear carry
	ADC.W #$0008							;0B806E	; Add offset
	TAY										;0B8071	; Transfer to Y
	PLX										;0B8072	; Restore sprite index
	JSL.L CODE_01AE86						;0B8073	; Call animation loader

; ==============================================================================
; OAM Data Update Routine
; ==============================================================================
; Updates Object Attribute Memory with current sprite positions and tiles.
; ==============================================================================

CODE_0B8077:
	REP #$30								;0B8077	; 16-bit mode
	LDA.W $192D								;0B8079	; Load OAM table index
	AND.W #$00FF							;0B807C	; Mask to byte
	ASL A									;0B807F	; Multiply by 4
	ASL A									;0B8080	; (4 bytes per OAM entry)
	PHX										;0B8081	; Save X
	TAX										;0B8082	; Transfer to X
	LDA.L DATA8_01A63A,X					;0B8083	; Load OAM base address
	TAY										;0B8087	; Transfer to Y
	PLX										;0B8088	; Restore X
	LDA.W $1A73,X							;0B8089	; Load sprite X position
	STA.W $0C02,Y							;0B808C	; Store to OAM
	LDA.W $1A75,X							;0B808F	; Load sprite Y position
	STA.W $0C06,Y							;0B8092	; Store to OAM
	LDA.W $1A77,X							;0B8095	; Load sprite tile index
	STA.W $0C0A,Y							;0B8098	; Store to OAM
	LDA.W $1A79,X							;0B809B	; Load sprite attributes
	STA.W $0C0E,Y							;0B809E	; Store to OAM

CODE_0B80A1:
	PLY										;0B80A1	; Restore Y
	PLX										;0B80A2	; Restore X
	PLB										;0B80A3	; Restore data bank
	PLP										;0B80A4	; Restore processor status
	RTL										;0B80A5	; Return

; ==============================================================================
; [Additional Battle Graphics Routines]
; ==============================================================================
; The remaining code (CODE_0B80D9 onwards) includes:
; - Animation frame updates
; - Effect rendering routines
; - DMA transfer management
; - Palette rotation for effects
; - Sprite priority management
;
; Complete code available in original bank_0B.asm
; Total bank size: ~3,700 lines of battle graphics code
; ==============================================================================

; [Remaining battle graphics code continues to $0BFFFF]
; See original bank_0B.asm for complete implementation

; ==============================================================================
; End of Bank $0B
; ==============================================================================
; Total size: 32 KB (complete bank)
; Primary content: Battle graphics/animation code
; Related banks: $09/$0A (graphics data), $0C (display management)
;
; Key functions documented:
; - Graphics setup by battle type
; - Sprite animation handling
; - OAM data management
;
; Remaining work:
; - Complete disassembly of animation routines
; - Document effect rendering algorithms
; - Map all sprite animation sequences
; ==============================================================================
