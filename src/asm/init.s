; Final Fantasy Mystic Quest - Initialization Routines
; Hardware and game initialization

; Clear all Work RAM
ClearWRAM:
    php                         ; Save processor status
    SetAXY16
    
    ; Clear $7E0000-$7FFFFF (128KB)
    lda #$0000
    ldx #$0000
@clear_7e:
    sta $7E0000, x
    inx
    inx
    cpx #$0000                  ; Will wrap to 0 after $FFFF
    bne @clear_7e
    
    ; Clear $7F0000-$7FFFFF (64KB)
    ldx #$0000
@clear_7f:
    sta $7F0000, x
    inx
    inx
    cpx #$0000
    bne @clear_7f
    
    plp                         ; Restore processor status
    rts

; Initialize PPU (Picture Processing Unit)
InitializePPU:
    php
    SetA8
    
    ; Turn screen off
    ScreenOff
    
    ; Reset all PPU registers to safe values
    stz OBSEL                   ; 8x8 and 16x16 sprites, name base $0000
    stz OAMADDL                 ; OAM address = $0000
    stz OAMADDH
    stz BGMODE                  ; BG Mode 0
    stz MOSAIC                  ; No mosaic
    stz BG1SC                   ; BG1 tilemap at VRAM $0000
    stz BG2SC                   ; BG2 tilemap at VRAM $0000
    stz BG3SC                   ; BG3 tilemap at VRAM $0000
    stz BG4SC                   ; BG4 tilemap at VRAM $0000
    stz BG12NBA                 ; BG1&2 name base at $0000
    stz BG34NBA                 ; BG3&4 name base at $0000
    
    ; Clear scroll registers
    stz BG1HOFS
    stz BG1HOFS                 ; Write twice for 16-bit
    stz BG1VOFS
    stz BG1VOFS
    stz BG2HOFS
    stz BG2HOFS
    stz BG2VOFS
    stz BG2VOFS
    stz BG3HOFS
    stz BG3HOFS
    stz BG3VOFS
    stz BG3VOFS
    stz BG4HOFS
    stz BG4HOFS
    stz BG4VOFS
    stz BG4VOFS
    
    ; Set VRAM increment mode
    lda #$80                    ; Increment on high byte write
    sta VMAIN
    
    ; Clear VRAM
    jsr ClearVRAM
    
    ; Clear OAM
    jsr ClearOAM
    
    ; Clear CGRAM (palette)
    jsr ClearCGRAM
    
    ; Setup initial display settings
    stz TM                      ; No layers on main screen initially
    stz TS                      ; No layers on sub screen
    stz TMW                     ; No window masking
    stz TSW
    stz CGWSEL                  ; No color math
    stz CGADSUB
    stz COLDATA
    stz SETINI                  ; Normal screen mode
    
    ; Window settings
    stz W12SEL
    stz W34SEL
    stz WOBJSEL
    stz WH0
    stz WH1
    stz WH2
    stz WH3
    stz WBGLOG
    stz WOBJLOG
    
    plp
    rts

; Clear VRAM (Video RAM)
ClearVRAM:
    php
    SetA16
    
    ; Set VRAM address to $0000
    stz VMADDL
    stz VMADDH
    
    ; Clear all 64KB of VRAM
    lda #$0000
    ldx #$8000                  ; 32K words = 64KB
@clear_loop:
    sta VMDATAL                 ; Write low byte
    dex
    bne @clear_loop
    
    plp
    rts

; Clear OAM (Object Attribute Memory)
ClearOAM:
    php
    SetA8
    
    ; Set OAM address to $0000
    stz OAMADDL
    stz OAMADDH
    
    ; Clear 512 bytes of OAM data
    lda #$E0                    ; Y position off-screen
    ldx #$00
@clear_oam_loop:
    sta OAMDATA                 ; Y position
    stz OAMDATA                 ; X position
    stz OAMDATA                 ; Character
    stz OAMDATA                 ; Attributes
    inx
    cpx #$80                    ; 128 sprites * 4 bytes = 512 bytes
    bne @clear_oam_loop
    
    ; Clear 32 bytes of OAM high table
    ldx #$00
@clear_oam_high:
    stz OAMDATA
    inx
    cpx #$20
    bne @clear_oam_high
    
    plp
    rts

; Clear CGRAM (Color Generator RAM)
ClearCGRAM:
    php
    SetA8
    
    ; Set CGRAM address to $00
    stz CGADD
    
    ; Clear all 512 bytes of CGRAM (256 colors * 2 bytes)
    ldx #$00
@clear_cgram_loop:
    stz CGDATA                  ; Low byte
    stz CGDATA                  ; High byte
    inx
    cpx #$00                    ; Will wrap after 256
    bne @clear_cgram_loop
    
    plp
    rts

; Initialize Sound System (APU)
InitializeSound:
    php
    SetA8
    
    ; Reset APU
    stz APUIO0
    stz APUIO1
    stz APUIO2
    stz APUIO3
    
    ; Wait for APU acknowledgment
    ldx #$00
@apu_wait:
    lda APUIO0
    cmp #$AA                    ; Wait for APU ready signal
    beq @apu_ready
    inx
    bne @apu_wait
    bra @apu_timeout
    
@apu_ready:
    ; APU is ready, load sound driver
    jsr LoadSoundDriver
    
@apu_timeout:
    plp
    rts

; Load Sound Driver (placeholder)
LoadSoundDriver:
    ; TODO: Implement sound driver upload
    rts

; Load default game data
LoadGameData:
    php
    
    ; Load default palette
    jsr LoadDefaultPalette
    
    ; Load font graphics
    jsr LoadFontGraphics
    
    ; Load UI graphics
    jsr LoadUIGraphics
    
    ; Initialize player data
    jsr InitializePlayerData
    
    ; Load initial map
    jsr LoadInitialMap
    
    plp
    rts

; Load default color palette
LoadDefaultPalette:
    php
    SetA8
    
    ; Set CGRAM address to $00
    stz CGADD
    
    ; Load basic 16-color palette
    ; Color 0: Transparent/Black
    stz CGDATA
    stz CGDATA
    
    ; Color 1: White
    lda #$FF
    sta CGDATA
    lda #$7F
    sta CGDATA
    
    ; Color 2: Red
    lda #$1F
    sta CGDATA
    stz CGDATA
    
    ; Color 3: Green
    lda #$E0
    sta CGDATA
    lda #$03
    sta CGDATA
    
    ; Color 4: Blue
    stz CGDATA
    lda #$7C
    sta CGDATA
    
    ; Add more colors as needed...
    
    plp
    rts

; Load font graphics to VRAM
LoadFontGraphics:
    php
    
    ; TODO: Load font from ROM to VRAM
    ; This would typically involve DMA transfer
    
    plp
    rts

; Load UI graphics
LoadUIGraphics:
    php
    
    ; TODO: Load UI elements (borders, cursors, etc.)
    
    plp
    rts

; Initialize player data with defaults
InitializePlayerData:
    php
    SetA8
    
    ; Set default player name
    ldx #$00
@name_loop:
    lda DefaultPlayerName, x
    sta PLAYER_NAME, x
    inx
    cpx #$08
    bne @name_loop
    
    ; Set initial stats
    lda #$01
    sta PLAYER_LEVEL            ; Level 1
    
    SetA16
    lda #$0000
    sta PLAYER_EXPERIENCE       ; 0 experience
    
    lda #$20
    sta PLAYER_HP_CURRENT       ; 32 HP
    sta PLAYER_HP_MAX
    
    SetA8
    lda #$05
    sta PLAYER_MP_WHITE_CUR     ; 5 White MP
    sta PLAYER_MP_WHITE_MAX
    lda #$03
    sta PLAYER_MP_BLACK_CUR     ; 3 Black MP
    sta PLAYER_MP_BLACK_MAX
    stz PLAYER_MP_WIZARD_CUR    ; 0 Wizard MP
    stz PLAYER_MP_WIZARD_MAX
    
    ; Set initial equipment (basic gear)
    lda #$01
    sta PLAYER_WEAPON           ; Steel Sword
    lda #$01
    sta PLAYER_ARMOR            ; Steel Armor
    stz PLAYER_SHIELD           ; No shield
    stz PLAYER_HELMET           ; No helmet
    stz PLAYER_ACCESSORY        ; No accessory
    
    ; Clear magic flags
    stz PLAYER_WHITE_MAGIC
    stz PLAYER_BLACK_MAGIC
    stz PLAYER_WIZARD_MAGIC
    
    plp
    rts

; Load initial map (Hill of Destiny)
LoadInitialMap:
    php
    
    lda #MAP_HILL_OF_DESTINY
    sta MAP_ID
    
    lda #$80                    ; Starting X position
    sta PLAYER_X_POS
    lda #$80                    ; Starting Y position
    sta PLAYER_Y_POS
    
    ; TODO: Load actual map data
    
    plp
    rts

; Default player name
DefaultPlayerName:
    .byte "Benjamin"             ; 8 characters (padded with space if needed)

; Interrupt handlers (placeholders)
EmulationCOP:
EmulationBRK:
EmulationABORT:
EmulationNMI:
EmulationRESET:
EmulationIRQ_BRK:
NativeCOP:
NativeBRK:
NativeABORT:
NativeIRQ:
    rti                         ; Return from interrupt

; Main NMI handler (VBlank)
NativeNMI:
    pha                         ; Save A
    phx                         ; Save X
    phy                         ; Save Y
    php                         ; Save processor status
    
    ; VBlank processing goes here
    ; - Update OAM
    ; - Update VRAM
    ; - Update CGRAM
    ; - Update scroll registers
    
    plp                         ; Restore processor status
    ply                         ; Restore Y
    plx                         ; Restore X
    pla                         ; Restore A
    rti

; Reset handler
NativeRESET:
    sei                         ; Disable interrupts
    clc                         ; Clear carry
    xce                         ; Switch to native mode
    jmp GameStart               ; Jump to main entry point