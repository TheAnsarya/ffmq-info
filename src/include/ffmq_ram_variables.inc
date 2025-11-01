; ============================================================================
; FFMQ WRAM Variables
; ============================================================================
; Comprehensive memory label definitions for Final Fantasy: Mystic Quest
; Based on Issue #28: High Priority WRAM Labels
; Last Updated: November 1, 2025
; ============================================================================

; ============================================================================
; ZERO PAGE ($00-$FF) - Fast Direct Page Access
; ============================================================================

; ----------------------------------------------------------------------------
; General Purpose / Temporary Variables ($00-$1F)
; ----------------------------------------------------------------------------
!temp_ptr_1         = $00       ; Temporary pointer 1 (2 bytes: $00-$01)
!temp_ptr_1_lo      = $00       ; Temporary pointer 1 (low byte)
!temp_ptr_1_hi      = $01       ; Temporary pointer 1 (high byte)

!temp_ptr_2         = $02       ; Temporary pointer 2 (2 bytes: $02-$03)
!temp_ptr_2_lo      = $02       ; Temporary pointer 2 (low byte)
!temp_ptr_2_hi      = $03       ; Temporary pointer 2 (high byte)

!temp_ptr_3         = $04       ; Temporary pointer 3 (2 bytes: $04-$05)
!temp_ptr_3_lo      = $04       ; Temporary pointer 3 (low byte)
!temp_ptr_3_hi      = $05       ; Temporary pointer 3 (high byte)

!temp_byte_1        = $06       ; Temporary byte storage 1
!temp_byte_2        = $07       ; Temporary byte storage 2
!temp_byte_3        = $08       ; Temporary byte storage 3

!temp_word_1        = $09       ; Temporary word (2 bytes: $09-$0A)
!temp_word_1_lo     = $09       ; Temporary word (low byte)
!temp_word_1_hi     = $0A       ; Temporary word (high byte)

!temp_index         = $0B       ; Temporary index/counter
!temp_flags         = $0C       ; Temporary flag byte

!general_address    = $0017     ; General purpose address (legacy label)

; ----------------------------------------------------------------------------
; Graphics System ($20-$3F)
; ----------------------------------------------------------------------------
!vram_write_lo      = $20       ; VRAM write address (low byte)
!vram_write_hi      = $21       ; VRAM write address (high byte)
!vram_write_addr    = $20       ; VRAM write address (2 bytes: $20-$21)

!dma_channel        = $22       ; Current DMA channel in use
!dma_mode           = $23       ; DMA transfer mode

!dma_source         = $24       ; DMA source address (2 bytes: $24-$25)
!dma_source_lo      = $24       ; DMA source address (low byte)
!dma_source_hi      = $25       ; DMA source address (high byte)
!dma_source_bank    = $26       ; DMA source bank

!dma_size           = $27       ; DMA transfer size (2 bytes: $27-$28)
!dma_size_lo        = $27       ; DMA transfer size (low byte)
!dma_size_hi        = $28       ; DMA transfer size (high byte)

!screen_brightness  = $29       ; Screen brightness (0=black, 15=full)
!bg_mode            = $2A       ; Background mode setting
!mosaic_enable      = $2B       ; Mosaic effect enable flags

!bg_scroll_x        = $2C       ; BG scroll X (4 bytes total: $2C-$2F)
!bg1_scroll_x_lo    = $2C       ; BG1 X scroll (low byte)
!bg1_scroll_x_hi    = $2D       ; BG1 X scroll (high byte)
!bg2_scroll_x_lo    = $2E       ; BG2 X scroll (low byte)
!bg2_scroll_x_hi    = $2F       ; BG2 X scroll (high byte)

!bg_scroll_y        = $30       ; BG scroll Y (4 bytes total: $30-$33)
!bg1_scroll_y_lo    = $30       ; BG1 Y scroll (low byte)
!bg1_scroll_y_hi    = $31       ; BG1 Y scroll (high byte)
!bg2_scroll_y_lo    = $32       ; BG2 Y scroll (low byte)
!bg2_scroll_y_hi    = $33       ; BG2 Y scroll (high byte)

!window_1_left      = $34       ; Window 1 left boundary position
!window_1_right     = $35       ; Window 1 right boundary position
!window_2_left      = $36       ; Window 2 left boundary position
!window_2_right     = $37       ; Window 2 right boundary position

; ----------------------------------------------------------------------------
; Player State ($40-$5F)
; ----------------------------------------------------------------------------
!player_x_pos       = $40       ; Player X position (2 bytes: $40-$41)
!player_x_pos_lo    = $40       ; Player X position (low byte)
!player_x_pos_hi    = $41       ; Player X position (high byte)

!player_y_pos       = $42       ; Player Y position (2 bytes: $42-$43)
!player_y_pos_lo    = $42       ; Player Y position (low byte)
!player_y_pos_hi    = $43       ; Player Y position (high byte)

!player_direction   = $44       ; Facing direction (0=up, 1=down, 2=left, 3=right)
!player_speed       = $45       ; Movement speed
!player_state       = $46       ; Current player state (walk/run/etc)
!player_animation   = $47       ; Animation frame counter

!map_id             = $48       ; Current map ID
!map_x_pos          = $49       ; Map X coordinate (tile)
!map_y_pos          = $4A       ; Map Y coordinate (tile)
!collision_flags    = $4B       ; Collision check results

; ----------------------------------------------------------------------------
; Input / Controller ($60-$6F)
; ----------------------------------------------------------------------------
!joy1_current       = $60       ; Controller 1 current button state
!joy1_previous      = $61       ; Controller 1 previous button state
!joy1_pressed       = $62       ; Controller 1 newly pressed buttons
!joy1_held          = $63       ; Controller 1 held buttons

!loop_counter_62    = $62       ; Legacy: Loop counter alias (conflicts with joy1_pressed)
!temp_62            = $62       ; Legacy: Temp variable alias (conflicts with joy1_pressed)
!temp_63            = $63       ; Legacy: Temp variable alias (conflicts with joy1_held)
!loop_counter_64    = $64       ; Legacy: Loop counter alias (conflicts with joy2_current)
!temp_64            = $64       ; Legacy: Temp variable alias (conflicts with joy2_current)
!temp_65            = $65       ; Legacy: Temp variable alias (conflicts with joy2_previous)

!joy2_current       = $64       ; Controller 2 current button state
!joy2_previous      = $65       ; Controller 2 previous button state
!joy2_pressed       = $66       ; Controller 2 newly pressed buttons
!joy2_held          = $67       ; Controller 2 held buttons

; ----------------------------------------------------------------------------
; Game State ($70-$8F)
; ----------------------------------------------------------------------------
!frame_counter      = $70       ; Frame counter (2 bytes: $70-$71)
!frame_counter_lo   = $70       ; Frame counter (low byte)
!frame_counter_hi   = $71       ; Frame counter (high byte)

!rng_seed           = $72       ; Random number generator seed (2 bytes: $72-$73)
!rng_seed_lo        = $72       ; RNG seed (low byte)
!rng_seed_hi        = $73       ; RNG seed (high byte)

!game_mode          = $74       ; Current game mode (title/field/battle/menu)
!game_state         = $75       ; Current game state
!menu_selection     = $76       ; Current menu selection
!menu_index         = $77       ; Menu cursor index

!dialog_state       = $78       ; Dialog system state
!dialog_speed       = $79       ; Text display speed
!text_char_index    = $7A       ; Current character index in text
!text_line          = $7B       ; Current text line number

!fade_state         = $7C       ; Screen fade state
!fade_timer         = $7D       ; Fade timer counter

!music_track        = $7E       ; Current music track ID
!sfx_queue          = $7F       ; Sound effect queue

; ----------------------------------------------------------------------------
; Battle System ($90-$BF)
; ----------------------------------------------------------------------------
!battle_state       = $90       ; Current battle state
!battle_phase       = $91       ; Battle phase (init/main/end)
!active_character   = $92       ; Currently acting character in battle
!target_index       = $93       ; Current target index
!command_index      = $94       ; Selected battle command

!atb_gauge_char1    = $95       ; Character 1 ATB gauge (0-255)
!atb_gauge_char2    = $96       ; Character 2 ATB gauge (0-255)
!atb_gauge_enemy1   = $97       ; Enemy 1 ATB gauge (0-255)
!atb_gauge_enemy2   = $98       ; Enemy 2 ATB gauge (0-255)

!damage_value       = $99       ; Damage calculation (2 bytes: $99-$9A)
!damage_value_lo    = $99       ; Damage calculation (low byte)
!damage_value_hi    = $9A       ; Damage calculation (high byte)

!hit_chance         = $9B       ; Hit probability calculation
!critical_flag      = $9C       ; Critical hit flag
!status_effect      = $9D       ; Applied status effect ID

!exp_gained         = $9E       ; EXP gained in battle (2 bytes: $9E-$9F)
!exp_gained_lo      = $9E       ; EXP gained (low byte)
!exp_gained_hi      = $9F       ; EXP gained (high byte)

; ----------------------------------------------------------------------------
; Legacy / Historical Labels
; ----------------------------------------------------------------------------
!flags_d8           = $00D8     ; Legacy flag byte

!color_data_source_offset   = $00F4    ; Legacy color data offset
!color_data_source_offset_2 = $00F7    ; Legacy color data offset 2

!ram_0111           = $0111     ; Legacy RAM address

; ============================================================================
; LOW RAM ($7E0100-$7E01FF) - Character & Party Data
; ============================================================================

; ----------------------------------------------------------------------------
; Character 1 (Benjamin) Stats ($7E0100-$7E011F)
; ----------------------------------------------------------------------------
!char1_hp_current       = $7E0100   ; Benjamin current HP (2 bytes)
!char1_hp_max           = $7E0102   ; Benjamin maximum HP (2 bytes)

!char1_white_magic      = $7E0104   ; Benjamin white magic power
!char1_black_magic      = $7E0105   ; Benjamin black magic power
!char1_wizard_magic     = $7E0106   ; Benjamin wizard magic power

!char1_speed            = $7E0107   ; Benjamin speed stat
!char1_strength         = $7E0108   ; Benjamin strength stat
!char1_defense          = $7E0109   ; Benjamin defense stat

!char1_level            = $7E010A   ; Benjamin level (1-41)

!char1_exp              = $7E010B   ; Benjamin EXP (3 bytes: $010B-$010D)
!char1_exp_lo           = $7E010B   ; Benjamin EXP (low byte)
!char1_exp_mid          = $7E010C   ; Benjamin EXP (middle byte)
!char1_exp_hi           = $7E010D   ; Benjamin EXP (high byte)

!char1_weapon_id        = $7E010E   ; Benjamin equipped weapon ID
!char1_armor_id         = $7E010F   ; Benjamin equipped armor ID
!char1_accessory_id     = $7E0110   ; Benjamin equipped accessory ID

!char1_status_flags     = $7E0111   ; Benjamin status effect flags

; ----------------------------------------------------------------------------
; Character 2 (Companion) Stats ($7E0120-$7E013F)
; ----------------------------------------------------------------------------
!char2_data             = $7E0120   ; Companion character data (32 bytes)
!char2_hp_current       = $7E0120   ; Companion current HP (2 bytes)
!char2_hp_max           = $7E0122   ; Companion maximum HP (2 bytes)

; ============================================================================
; MID RAM ($7E0200-$7E0FFF) - Game Data
; ============================================================================

; ----------------------------------------------------------------------------
; Inventory System ($7E0200-$7E02FF)
; ----------------------------------------------------------------------------
!inventory_weapons      = $7E0200   ; Weapon inventory (32 slots)
!inventory_armor        = $7E0220   ; Armor inventory (32 slots)
!inventory_accessories  = $7E0240   ; Accessory inventory (32 slots)
!inventory_consumables  = $7E0260   ; Consumable items (64 slots)
!inventory_key_items    = $7E02A0   ; Key items (32 slots)
!inventory_counts       = $7E02C0   ; Item quantity counters (16 bytes)

; ----------------------------------------------------------------------------
; Progress Flags ($7E0300-$7E03FF)
; ----------------------------------------------------------------------------
!story_flags            = $7E0300   ; Story progression flags (32 bytes)
!event_flags            = $7E0320   ; Event completion flags (32 bytes)
!treasure_flags         = $7E0340   ; Treasure chest opened flags (32 bytes)
!npc_flags              = $7E0360   ; NPC interaction flags (32 bytes)
!boss_defeated_flags    = $7E0380   ; Boss defeat flags (32 bytes)
!crystal_flags          = $7E03A0   ; Crystal-related flags (32 bytes)

; ----------------------------------------------------------------------------
; Map System ($7E0400-$7E07FF)
; ----------------------------------------------------------------------------
!map_cache_1            = $7E0400   ; Map data cache slot 1 (256 bytes)
!map_cache_2            = $7E0500   ; Map data cache slot 2 (256 bytes)
!map_cache_3            = $7E0600   ; Map data cache slot 3 (256 bytes)
!npc_positions          = $7E0700   ; NPC position data (128 bytes)
!event_data             = $7E0780   ; Event state data (128 bytes)

; ----------------------------------------------------------------------------
; Tilemap / Graphics ($7E0800-$7E0FFF)
; ----------------------------------------------------------------------------
!tilemap_wram_source_start      = $0800     ; Tilemap source start (legacy label)
!tilemap_wram_source_start_2    = $0900     ; Tilemap source start 2 (legacy label)
!ram_0900                       = $0900     ; Legacy label

!ram_1031                       = $1031     ; Legacy label
!ram_1031_long                  = $001031   ; Legacy label (long address)

; Graphics-related legacy labels
!ram_1924           = $1924     ; Legacy graphics variable
!ram_1925           = $1925     ; Legacy graphics variable
!ram_195f           = $195f     ; Legacy graphics variable
!ram_19a5           = $19a5     ; Legacy graphics variable

!ram_19b4           = $19b4     ; if bit 3 = 1 then !ram_1a33 => $80 else $00
!ram_19bd           = $19bd     ; bottom 4 bits inversed are a DMA transfer size variable
!ram_19bf           = $19bf     ; Legacy graphics variable

; Tilemap VRAM control structures
!tilemap_vram_control               = $19fa     ; VMAIN flags (known: $80, $81)
!tilemap_vram_destination_addresses = $19fb     ; VRAM dest addresses (8 bytes, 4×2-byte pairs)
!tilemap_wram_source_addresses      = $1a03     ; WRAM source addresses (8 bytes, 4×2-byte pairs)
!tilemap_dma_transfer_sizes         = $1a0b     ; DMA transfer sizes (8 bytes, 4×2-byte pairs)

!tilemap_vram_control_2                 = $1a13 ; VMAIN flags set 2 (known: $80, $81)
!tilemap_vram_destination_addresses_2   = $1a14 ; VRAM dest addresses 2 (8 bytes, 4×2-byte pairs)
!tilemap_wram_source_addresses_2        = $1a1c ; WRAM source addresses 2 (8 bytes, 4×2-byte pairs)
!tilemap_dma_transfer_sizes_2           = $1a24 ; DMA transfer sizes 2 (8 bytes, 4×2-byte pairs)

!ram_1a2d           = $1a2d     ; Legacy label
!ram_1a31           = $1a31     ; Legacy label
!ram_1a32           = $1a32     ; Legacy label
!ram_1a33           = $1a33     ; Legacy label
!ram_1a34           = $1a34     ; Legacy label
!ram_1a3d           = $1a3d     ; Legacy label
!ram_1a46           = $1a46     ; Legacy label
!ram_1a4c           = $1a4c     ; Legacy label

; ----------------------------------------------------------------------------
; Menu / UI ($7E0E00-$7E0FFF)
; ----------------------------------------------------------------------------
!menu_color         = $0e9c     ; Menu color setting
!menu_color_high    = $0e9d     ; Menu color (high byte)

; ============================================================================
; HIGH RAM ($7E1000-$7EFFFF) - Buffers
; ============================================================================

; ----------------------------------------------------------------------------
; Sprite / Graphics Buffers ($7E1000-$7E6FFF)
; ----------------------------------------------------------------------------
!oam_buffer         = $7E1000   ; Sprite OAM buffer (512 bytes, 128 sprites)

!bg1_tilemap_buffer = $7E1200   ; BG1 tilemap buffer (3584 bytes)
!bg2_tilemap_buffer = $7E2000   ; BG2 tilemap buffer (4096 bytes)
!bg3_tilemap_buffer = $7E3000   ; BG3 tilemap buffer / text layer (4096 bytes)

!tile_buffer        = $7E4000   ; Tile data decompression buffer (4096 bytes)
!sprite_buffer      = $7E5000   ; Sprite data buffer (4096 bytes)
!palette_buffer     = $7E6000   ; Palette staging buffer (4096 bytes)

; ----------------------------------------------------------------------------
; Audio Buffers ($7E8000-$7E8FFF)
; ----------------------------------------------------------------------------
!audio_command_buffer   = $7E8000   ; Audio command queue (256 bytes)
!music_data_buffer      = $7E8100   ; Music sequence buffer (256 bytes)
!sfx_data_buffer        = $7E8200   ; Sound effect data buffer (256 bytes)

; ----------------------------------------------------------------------------
; Working Memory ($7E9000-$7EFFFF)
; ----------------------------------------------------------------------------
!general_work_1     = $7E9000   ; General working memory block 1 (4096 bytes)
!general_work_2     = $7EA000   ; General working memory block 2 (4096 bytes)
!general_work_3     = $7EB000   ; General working memory block 3 (4096 bytes)
!decompression_buffer = $7EC000 ; Data decompression working buffer (4096 bytes)

; ============================================================================
; Battle System Extended ($7E0800-$7E0BFF)
; ============================================================================

!enemy_data_1       = $7E0800   ; Enemy 1 complete battle data (128 bytes)
!enemy_data_2       = $7E0880   ; Enemy 2 complete battle data (128 bytes)
!enemy_data_3       = $7E0900   ; Enemy 3 complete battle data (128 bytes, optional)
!enemy_data_4       = $7E0980   ; Enemy 4 complete battle data (128 bytes, optional)

!battle_state_data  = $7E0A00   ; Battle state variables (128 bytes)
!command_queue      = $7E0A80   ; Battle command queue (128 bytes)

; ============================================================================
; Text System ($7E0C00-$7E0FFF)
; ============================================================================

!text_buffer        = $7E0C00   ; Decompressed text buffer (256 bytes)
!dialog_buffer      = $7E0D00   ; Dialog display buffer (256 bytes)
!menu_buffer        = $7E0E00   ; Menu text buffer (256 bytes)

; ============================================================================
; End of RAM Variables
; ============================================================================


