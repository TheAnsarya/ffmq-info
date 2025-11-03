;==============================================================================
; Battle Data Integration
; Includes converted battle data (enemies, attacks, attack links)
;==============================================================================
; This file integrates the converted JSON→ASM battle data into the ROM build.
;
; The data is generated from:
;   - data/extracted/enemies/enemies.json
;   - data/extracted/attacks/attacks.json
;   - data/extracted/enemy_attack_links/enemy_attack_links.json
;
; To rebuild the converted ASM files:
;   make convert-data
;   OR
;   python tools/conversion/convert_all.py
;==============================================================================

; Enemy Stats Table (14 bytes × 83 enemies)
; Bank $02, ROM $C275
incsrc "../../../data/converted/enemies/enemies_stats.asm"

; Enemy Level/Multiplier Table (3 bytes × 83 enemies)
; Bank $02, ROM $C17C
incsrc "../../../data/converted/enemies/enemies_level.asm"

; Attack Data Table (7 bytes × 169 attacks)
; Bank $02, ROM $BC78
incsrc "../../../data/converted/attacks/attacks_data.asm"

; Enemy-Attack Links Table (6 bytes × 82 enemies)
; Bank $02, ROM $BE94
incsrc "../../../data/converted/attacks/enemy_attack_links.asm"
