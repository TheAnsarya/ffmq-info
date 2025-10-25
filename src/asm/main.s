; Final Fantasy Mystic Quest (SNES) - Main Assembly File
; Modern SNES Development Environment
; Assembled with ca65/asar

.include "snes_header.inc"
.include "snes_registers.inc"
.include "ffmq_constants.inc"
.include "ffmq_macros.inc"

; ROM Configuration
.p816                           ; 65816 processor
.smart                          ; Smart mode for ca65

; Memory Map - LoROM
.memorymap
  defaultslot 0
  slot 0 $8000 $ffff size $8000
  slot 1 $0000 $7fff size $8000
  slot 2 $fe00 $ffff size $200
.endme

.rombankmap
  bankstotal 16
  banksize $8000
  banks 16
.endro

; ROM Header (SNES format)
.orga $00FFC0
.db "FF MYSTIC QUEST     "      ; ROM Title (21 bytes)
.db $30                         ; ROM Speed/Type: LoROM, FastROM
.db $02                         ; Cartridge Type: ROM + SRAM
.db $09                         ; ROM Size: 512KB (2^9 * 1024)
.db $03                         ; SRAM Size: 8KB (2^3 * 1024)
.db $01                         ; Country: USA
.db $33                         ; Developer: Square
.db $01                         ; Version: 1.1

; Checksums (will be calculated by assembler)
.dw $0000, $0000               ; Complement, Checksum

; Interrupt Vectors
.orga $00FFE4
.dw EmulationCOP               ; COP (Emulation)
.dw EmulationBRK               ; BRK (Emulation)
.dw EmulationABORT             ; ABORT (Emulation)
.dw EmulationNMI               ; NMI (Emulation)
.dw EmulationRESET             ; RESET (Emulation)
.dw EmulationIRQ_BRK           ; IRQ/BRK (Emulation)

.dw NativeCOP                  ; COP (Native)
.dw NativeBRK                  ; BRK (Native)
.dw NativeABORT                ; ABORT (Native)
.dw NativeNMI                  ; NMI (Native)
.dw NativeRESET                ; RESET (Native)
.dw NativeIRQ                  ; IRQ (Native)

; Bank 00 - Main Code
.bank 0 slot 0
.org $8000

; Game Entry Point
GameStart:
    sei                         ; Disable interrupts
    clc                         ; Clear carry
    xce                         ; Switch to native mode
    
    ; Initialize processor state
    rep #$38                    ; 16-bit A, X, Y; decimal mode off
    ldx #$1fff                  ; Stack pointer
    txs
    
    ; Clear work RAM
    jsr ClearWRAM
    
    ; Initialize PPU
    jsr InitializePPU
    
    ; Initialize sound system
    jsr InitializeSound
    
    ; Load game data
    jsr LoadGameData
    
    ; Start main game loop
    jmp MainGameLoop

; Include other source files
.include "init.s"              ; Initialization routines
.include "main_loop.s"         ; Main game loop
.include "graphics.s"          ; Graphics routines
.include "sound.s"             ; Sound routines
.include "input.s"             ; Input handling
.include "battle.s"            ; Battle system
.include "menu.s"              ; Menu system
.include "text.s"              ; Text engine
.include "map.s"               ; Map system
.include "npc.s"               ; NPC routines
.include "items.s"             ; Item system
.include "magic.s"             ; Magic system
.include "save.s"              ; Save/load system

; Bank 01-0F - Game Data
.bank 1 slot 0
.include "data/graphics_data.s"

.bank 2 slot 0
.include "data/map_data.s"

.bank 3 slot 0
.include "data/text_data.s"

.bank 4 slot 0
.include "data/music_data.s"

.bank 5 slot 0
.include "data/character_data.s"

.bank 6 slot 0
.include "data/item_data.s"

.bank 7 slot 0
.include "data/monster_data.s"

.bank 8 slot 0
.include "data/battle_data.s"

.bank 9 slot 0
.include "data/spell_data.s"

.bank 10 slot 0
.include "data/event_data.s"

.bank 11 slot 0
.include "data/misc_data.s"

; Banks 12-15 reserved for future expansion
.bank 12 slot 0
.org $8000
.db "EXPANSION_BANK_12"

.bank 13 slot 0
.org $8000
.db "EXPANSION_BANK_13"

.bank 14 slot 0
.org $8000
.db "EXPANSION_BANK_14"

.bank 15 slot 0
.org $8000
.db "EXPANSION_BANK_15"