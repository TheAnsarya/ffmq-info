; SNES ROM Header Template
; Standard SNES cartridge header definitions

; ROM Header Structure (Located at $00ffc0-$00ffdf)
.struct snes_header
    title       .byte 21        ; Game title (21 characters)
    map_mode    .byte 1         ; ROM layout mode
    cart_type   .byte 1         ; Cartridge type
    rom_size    .byte 1         ; ROM size code
    sram_size   .byte 1         ; SRAM size code
    country     .byte 1         ; Destination country
    developer   .byte 1         ; Developer ID
    version     .byte 1         ; ROM version
    checksum_c  .word 1         ; Checksum complement
    checksum    .word 1         ; Checksum
.endstruct

; ROM Layout Modes
.define LOROM       $20         ; LoROM mapping
.define HIROM       $21         ; HiROM mapping
.define LOROM_FAST  $30         ; LoROM + FastROM
.define HIROM_FAST  $31         ; HiROM + FastROM

; Cartridge Types
.define CART_ROM                $00    ; ROM only
.define CART_ROM_SRAM           $01    ; ROM + SRAM
.define CART_ROM_SRAM_BATTERY   $02    ; ROM + SRAM + Battery
.define CART_ROM_DSP            $03    ; ROM + DSP chip
.define CART_ROM_DSP_SRAM       $04    ; ROM + DSP + SRAM
.define CART_ROM_DSP_SRAM_BAT   $05    ; ROM + DSP + SRAM + Battery

; ROM Size Codes (2^n KB)
.define ROM_32KB    $05         ; 32KB
.define ROM_64KB    $06         ; 64KB
.define ROM_128KB   $07         ; 128KB
.define ROM_256KB   $08         ; 256KB
.define ROM_512KB   $09         ; 512KB (FFMQ)
.define ROM_1MB     $0a         ; 1MB
.define ROM_2MB     $0b         ; 2MB
.define ROM_4MB     $0c         ; 4MB

; SRAM Size Codes (2^n KB)
.define SRAM_NONE   $00         ; No SRAM
.define SRAM_2KB    $01         ; 2KB
.define SRAM_8KB    $03         ; 8KB (FFMQ)
.define SRAM_32KB   $05         ; 32KB

; Country Codes
.define COUNTRY_JAPAN       $00
.define COUNTRY_USA         $01    ; FFMQ
.define COUNTRY_EUROPE      $02
.define COUNTRY_SWEDEN      $03
.define COUNTRY_FINLAND     $04
.define COUNTRY_DENMARK     $05
.define COUNTRY_FRANCE      $06
.define COUNTRY_NETHERLANDS $07
.define COUNTRY_SPAIN       $08
.define COUNTRY_GERMANY     $09
.define COUNTRY_ITALY       $0a
.define COUNTRY_CHINA       $0b
.define COUNTRY_KOREA       $0d
.define COUNTRY_COMMON      $0e
.define COUNTRY_CANADA      $0f
.define COUNTRY_BRAZIL      $10
.define COUNTRY_AUSTRALIA   $11

; Developer Codes (Notable ones)
.define DEV_NINTENDO    $01
.define DEV_SQUARE      $33     ; FFMQ
.define DEV_ENIX        $18
.define DEV_CAPCOM      $08
.define DEV_KONAMI      $0a
.define DEV_NAMCO       $28