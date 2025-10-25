; Final Fantasy Mystic Quest - Assembly Macros
; Convenient macros for SNES development and FFMQ-specific operations

; === Processor State Macros ===
.macro SetA8
    sep #$20                    ; Set A to 8-bit
.endmacro

.macro SetA16
    rep #$20                    ; Set A to 16-bit
.endmacro

.macro SetXY8
    sep #$10                    ; Set X,Y to 8-bit
.endmacro

.macro SetXY16
    rep #$10                    ; Set X,Y to 16-bit
.endmacro

.macro SetAXY8
    sep #$30                    ; Set A,X,Y to 8-bit
.endmacro

.macro SetAXY16
    rep #$30                    ; Set A,X,Y to 16-bit
.endmacro

; === PPU Control Macros ===
.macro ScreenOff
    lda #$80
    sta INIDISP                 ; Turn screen off
.endmacro

.macro ScreenOn brightness
    lda #brightness
    sta INIDISP                 ; Turn screen on with brightness
.endmacro

.macro SetBGMode mode
    lda #mode
    sta BGMODE                  ; Set background mode
.endmacro

.macro VBlankWait
@wait:
    lda STAT78                  ; Check PPU status
    and #$80                    ; Test VBlank flag
    beq @wait                   ; Wait for VBlank
.endmacro

; === VRAM Access Macros ===
.macro SetVRAMAddr addr
    .if .blank(addr)
        .error "VRAM address required"
    .endif
    lda #<addr
    sta VMADDL
    lda #>addr
    sta VMADDH
.endmacro

.macro WriteVRAM16 data
    lda #<data
    sta VMDATAL
    lda #>data
    sta VMDATAH
.endmacro

.macro WriteVRAM8 data
    lda #data
    sta VMDATAL
.endmacro

; === DMA Macros ===
.macro DMATransfer channel, mode, source, dest, size
    ; Setup DMA channel
    lda #mode
    sta DMA0_DMAP + (channel * $10)
    
    lda #dest
    sta DMA0_BBAD + (channel * $10)
    
    lda #<source
    sta DMA0_A1T0L + (channel * $10)
    lda #>source
    sta DMA0_A1T0H + (channel * $10)
    lda #^source
    sta DMA0_A1B0 + (channel * $10)
    
    lda #<size
    sta DMA0_DAS0L + (channel * $10)
    lda #>size
    sta DMA0_DAS0H + (channel * $10)
    
    ; Start DMA
    lda #(1 << channel)
    sta MDMAEN
.endmacro

; === Memory Operations ===
.macro ClearMemory addr, size
    SetA16
    lda #$0000
    ldx #size
@loop:
    sta addr, x
    dex
    dex
    bpl @loop
.endmacro

.macro CopyMemory source, dest, size
    SetA8
    ldx #$00
@loop:
    lda source, x
    sta dest, x
    inx
    cpx #size
    bne @loop
.endmacro

; === Game-Specific Macros ===
.macro LoadPlayerStats
    ; Load player data into registers/memory
    SetA16
    lda PLAYER_HP_CURRENT
    sta $10                     ; Store current HP in DP
    lda PLAYER_HP_MAX
    sta $12                     ; Store max HP in DP
    SetA8
    lda PLAYER_LEVEL
    sta $14                     ; Store level in DP
.endmacro

.macro SavePlayerStats
    ; Save player data from registers/memory
    SetA16
    lda $10
    sta PLAYER_HP_CURRENT       ; Save current HP
    lda $12
    sta PLAYER_HP_MAX           ; Save max HP
    SetA8
    lda $14
    sta PLAYER_LEVEL            ; Save level
.endmacro

.macro PlaySound effect_id
    lda #effect_id
    jsr PlaySoundEffect
.endmacro

.macro PlayMusic track_id
    lda #track_id
    jsr PlayMusicTrack
.endmacro

.macro ShowMessage message_id
    lda #message_id
    jsr DisplayMessage
.endmacro

.macro GiveItem item_id, quantity
    lda #item_id
    ldx #quantity
    jsr AddItemToInventory
.endmacro

.macro LearnSpell spell_type, spell_id
    lda #spell_type
    ldx #spell_id
    jsr LearnSpellSubroutine
.endmacro

; === Battle System Macros ===
.macro CalculateDamage attacker_power, defender_defense
    ; Simple damage calculation
    SetA16
    lda #attacker_power
    sec
    sbc #defender_defense
    bpl @positive
    lda #$0001                  ; Minimum 1 damage
@positive:
    sta $20                     ; Store result in DP
.endmacro

.macro ApplyDamage target_hp, damage_amount
    SetA16
    lda target_hp
    sec
    sbc #damage_amount
    bpl @alive
    lda #$0000                  ; Dead
@alive:
    sta target_hp
.endmacro

; === Menu System Macros ===
.macro InitMenuCursor x_pos, y_pos
    lda #x_pos
    sta $30                     ; Cursor X position
    lda #y_pos
    sta $31                     ; Cursor Y position
.endmacro

.macro MoveCursor direction
    lda $30                     ; Current cursor position
    .if direction = "up"
        dec
    .elif direction = "down"
        inc
    .elif direction = "left"
        ; Handle left movement
    .elif direction = "right"
        ; Handle right movement
    .endif
    sta $30
.endmacro

; === Text System Macros ===
.macro PrintText text_ptr
    SetA16
    lda #text_ptr
    jsr PrintTextString
.endmacro

.macro PrintNumber number, digits
    lda #number
    ldx #digits
    jsr PrintNumberRoutine
.endmacro

; === Map System Macros ===
.macro LoadMap map_id
    lda #map_id
    jsr LoadMapData
.endmacro

.macro SetPlayerPosition x_pos, y_pos
    lda #x_pos
    sta PLAYER_X_POS
    lda #y_pos
    sta PLAYER_Y_POS
.endmacro

; === Debug Macros ===
.macro DebugBreak
    .ifdef DEBUG
        brk                     ; Break for debugging
    .endif
.endmacro

.macro DebugPrint message
    .ifdef DEBUG
        ; Print debug message (implementation depends on debug setup)
    .endif
.endmacro

; === Interrupt Handlers ===
.macro DisableInterrupts
    sei                         ; Set interrupt disable flag
    lda #$00
    sta NMITIMEN               ; Disable NMI and IRQ
.endmacro

.macro EnableNMI
    lda #$80
    sta NMITIMEN               ; Enable NMI (VBlank)
.endmacro

.macro EnableIRQ
    lda #$20
    sta NMITIMEN               ; Enable IRQ (H/V-Timer)
.endmacro