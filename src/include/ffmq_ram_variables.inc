; ============================================================================
; FFMQ WRAM Variables
; ============================================================================
; Comprehensive memory label definitions for Final Fantasy: Mystic Quest
; Based on Issue #28: High Priority WRAM Labels
; Last Updated: November 1, 2025
; ============================================================================

; ============================================================================
; ZERO PAGE ($00-$ff) - Fast Direct Page Access
; ============================================================================

; ----------------------------------------------------------------------------
; General Purpose / Temporary Variables ($00-$1f)
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

!temp_word_1        = $09       ; Temporary word (2 bytes: $09-$0a)
!temp_word_1_lo     = $09       ; Temporary word (low byte)
!temp_word_1_hi     = $0a       ; Temporary word (high byte)

!temp_index         = $0b       ; Temporary index/counter
!temp_flags         = $0c       ; Temporary flag byte

; Additional temporary variables (Medium Priority - Issue #29)
!temp_byte_4        = $0e       ; Temporary byte storage 4 (text engine)
!temp_byte_5        = $14       ; Temporary byte storage 5

!graphics_ptr       = $10       ; Graphics system pointer (2 bytes: $10-$11)
!graphics_ptr_lo    = $10       ; Graphics system pointer (low byte)
!graphics_ptr_hi    = $11       ; Graphics system pointer (high byte)

!text_ptr           = $12       ; Text system pointer (2 bytes: $12-$13)
!text_ptr_lo        = $12       ; Text system pointer (low byte)
!text_ptr_hi        = $13       ; Text system pointer (high byte)

!general_address    = $0017     ; General purpose address (legacy label)

; ----------------------------------------------------------------------------
; Graphics System ($20-$3f)
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
!bg_mode            = $2a       ; Background mode setting
!mosaic_enable      = $2b       ; Mosaic effect enable flags

!bg_scroll_x        = $2c       ; BG scroll X (4 bytes total: $2c-$2f)
!bg1_scroll_x_lo    = $2c       ; BG1 X scroll (low byte)
!bg1_scroll_x_hi    = $2d       ; BG1 X scroll (high byte)
!bg2_scroll_x_lo    = $2e       ; BG2 X scroll (low byte)
!bg2_scroll_x_hi    = $2f       ; BG2 X scroll (high byte)

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
; Player State ($40-$5f)
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
!map_y_pos          = $4a       ; Map Y coordinate (tile)
!collision_flags    = $4b       ; Collision check results

; ----------------------------------------------------------------------------
; Input / Controller ($60-$6f)
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
; Game State ($70-$8f)
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
!text_char_index    = $7a       ; Current character index in text
!text_line          = $7b       ; Current text line number

!fade_state         = $7c       ; Screen fade state
!fade_timer         = $7d       ; Fade timer counter

!music_track        = $7e       ; Current music track ID
!sfx_queue          = $7f       ; Sound effect queue

; ----------------------------------------------------------------------------
; Battle System ($90-$bf)
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

!damage_value       = $99       ; Damage calculation (2 bytes: $99-$9a)
!damage_value_lo    = $99       ; Damage calculation (low byte)
!damage_value_hi    = $9a       ; Damage calculation (high byte)

!hit_chance         = $9b       ; Hit probability calculation
!critical_flag      = $9c       ; Critical hit flag
!status_effect      = $9d       ; Applied status effect ID

!exp_gained         = $9e       ; EXP gained in battle (2 bytes: $9e-$9f)
!exp_gained_lo      = $9e       ; EXP gained (low byte)
!exp_gained_hi      = $9f       ; EXP gained (high byte)

; ----------------------------------------------------------------------------
; Legacy / Historical Labels
; ----------------------------------------------------------------------------
!flags_d8           = $00d8     ; Legacy flag byte

!color_data_source_offset   = $00f4    ; Legacy color data offset
!color_data_source_offset_2 = $00f7    ; Legacy color data offset 2

!ram_0111           = $0111     ; Legacy RAM address

; ============================================================================
; LOW RAM ($7e0100-$7e01ff) - Character & Party Data
; ============================================================================

; ----------------------------------------------------------------------------
; Character 1 (Benjamin) Stats ($7e0100-$7e011f)
; ----------------------------------------------------------------------------
!char1_hp_current       = $7e0100   ; Benjamin current HP (2 bytes)
!char1_hp_max           = $7e0102   ; Benjamin maximum HP (2 bytes)

!char1_white_magic      = $7e0104   ; Benjamin white magic power
!char1_black_magic      = $7e0105   ; Benjamin black magic power
!char1_wizard_magic     = $7e0106   ; Benjamin wizard magic power

!char1_speed            = $7e0107   ; Benjamin speed stat
!char1_strength         = $7e0108   ; Benjamin strength stat
!char1_defense          = $7e0109   ; Benjamin defense stat

!char1_level            = $7e010a   ; Benjamin level (1-41)

!char1_exp              = $7e010b   ; Benjamin EXP (3 bytes: $010b-$010d)
!char1_exp_lo           = $7e010b   ; Benjamin EXP (low byte)
!char1_exp_mid          = $7e010c   ; Benjamin EXP (middle byte)
!char1_exp_hi           = $7e010d   ; Benjamin EXP (high byte)

!char1_weapon_id        = $7e010e   ; Benjamin equipped weapon ID
!char1_armor_id         = $7e010f   ; Benjamin equipped armor ID
!char1_accessory_id     = $7e0110   ; Benjamin equipped accessory ID

!char1_status_flags     = $7e0111   ; Benjamin status effect flags

; ----------------------------------------------------------------------------
; Character 2 (Companion) Stats ($7e0120-$7e013f)
; ----------------------------------------------------------------------------
!char2_data             = $7e0120   ; Companion character data (32 bytes)
!char2_hp_current       = $7e0120   ; Companion current HP (2 bytes)
!char2_hp_max           = $7e0122   ; Companion maximum HP (2 bytes)

; ============================================================================
; MID RAM ($7e0200-$7e0fff) - Game Data
; ============================================================================

; ----------------------------------------------------------------------------
; Inventory System ($7e0200-$7e02ff)
; ----------------------------------------------------------------------------
!inventory_weapons      = $7e0200   ; Weapon inventory (32 slots)
!inventory_armor        = $7e0220   ; Armor inventory (32 slots)
!inventory_accessories  = $7e0240   ; Accessory inventory (32 slots)
!inventory_consumables  = $7e0260   ; Consumable items (64 slots)
!inventory_key_items    = $7e02a0   ; Key items (32 slots)
!inventory_counts       = $7e02c0   ; Item quantity counters (16 bytes)

; ----------------------------------------------------------------------------
; Progress Flags ($7e0300-$7e03ff)
; ----------------------------------------------------------------------------
!story_flags            = $7e0300   ; Story progression flags (32 bytes)
!event_flags            = $7e0320   ; Event completion flags (32 bytes)
!treasure_flags         = $7e0340   ; Treasure chest opened flags (32 bytes)
!npc_flags              = $7e0360   ; NPC interaction flags (32 bytes)
!boss_defeated_flags    = $7e0380   ; Boss defeat flags (32 bytes)
!crystal_flags          = $7e03a0   ; Crystal-related flags (32 bytes)

; ----------------------------------------------------------------------------
; Map System ($7e0400-$7e07ff)
; ----------------------------------------------------------------------------
!map_cache_1            = $7e0400   ; Map data cache slot 1 (256 bytes)
!map_cache_2            = $7e0500   ; Map data cache slot 2 (256 bytes)
!map_cache_3            = $7e0600   ; Map data cache slot 3 (256 bytes)
!npc_positions          = $7e0700   ; NPC position data (128 bytes)
!event_data             = $7e0780   ; Event state data (128 bytes)

; ----------------------------------------------------------------------------
; Tilemap / Graphics ($7e0800-$7e0fff)
; ----------------------------------------------------------------------------
!tilemap_wram_source_start      = $0800     ; Tilemap source start (legacy label)

; Medium Priority Graphics Variables (Issue #29)
!wram_data_ptr      = $06bf     ; WRAM data pointer/offset
!rom_function_ptr   = $0b83     ; ROM function pointer base

; Context/Multi-Purpose Variables
!context_param      = $0e88     ; Multi-purpose context parameter (equipment param, enemy ID, formation type, graphics context)

; Map/Player Position Variables
!player_map_x       = $0e89     ; Player X coordinate on current map / Tilemap index
!player_map_y       = $0e8a     ; Player Y coordinate on current map
!tilemap_index      = $0e89     ; Tilemap indexing variable (alias for !player_map_x)
!tilemap_counter    = $0e91     ; Tilemap operation counter

!tilemap_wram_source_start_2    = $0900     ; Tilemap source start 2 (legacy label)
!ram_0900                       = $0900     ; Legacy label

!ram_1031                       = $1031     ; Legacy label
!ram_1031_long                  = $001031   ; Legacy label (long address)

; ============================================================================
; Graphics System Variables ($1900-$1aff)
; ============================================================================

; ----------------------------------------------------------------------------
; Map Chunk and Tilemap Control ($191a-$192e)
; ----------------------------------------------------------------------------
!map_chunk_control      = $191a     ; Map chunk load control array[8] (negative=$00 fill, else ROM offset)
!tilemap_x_offset       = $192d     ; Tilemap rendering X offset (player_map_x - 8)
!tilemap_y_offset       = $192e     ; Tilemap rendering Y offset (player_map_y - 6)

; Graphics-related legacy labels
!ram_1924           = $1924     ; Legacy graphics variable
!ram_1925           = $1925     ; Conditional offset (used in add/subtract operations)
!ram_195f           = $195f     ; Legacy graphics variable
!ram_19a5           = $19a5     ; Legacy graphics variable

; ----------------------------------------------------------------------------
; Graphics Mode and Parameters ($19b4-$19f6)
; ----------------------------------------------------------------------------
!graphics_mode_flags    = $19b4     ; Graphics mode flags (bit 3 determines priority $80/$00)
!ram_19b4               = $19b4     ; Legacy alias - if bit 3 = 1 then !ram_1a33 => $80 else $00
!data_source_offset     = $19b5     ; Calculated data source offset from ROM tables
!calculated_source_offset = $19b7   ; Final calculated offset ($1911 * $0a)
!source_pointer         = $19b9     ; Source data pointer ($ffff or calculated from $1912 * 2)
!ram_19bd               = $19bd     ; bottom 4 bits inversed are a DMA transfer size variable
!ram_19bf               = $19bf     ; Legacy graphics variable
!graphics_index         = $19d7     ; Graphics data index (lower 2 bits * 2)

; Medium Priority Graphics Control (Issue #29)
!graphics_temp_1    = $19ee     ; Graphics temporary variable 1
!map_param_1        = $19f0     ; Map initialization parameter 1
!map_param_2        = $19f1     ; Map initialization parameter 2
!map_param_zero     = $19f6     ; Temporary zero flag (cleared to $00)

; ----------------------------------------------------------------------------
; Tileset Data Loading ($1910-$191f)
; ----------------------------------------------------------------------------
!graphics_table_data    = $1910     ; Data loaded from ROM table $07b013
!source_address_index   = $1911     ; Source address index (multiplied by $0a for offset calc)
!source_offset_index    = $1912     ; Source offset index ($ff = skip, else calculate)
!graphics_param_1       = $1915     ; Graphics parameter (top 3 bits used in packing)
!graphics_param_2       = $1916     ; Graphics parameter (top 3 bits used in packing)
!tileset_copy_buffer    = $1918     ; Tileset data copy buffer[10 bytes]

; ----------------------------------------------------------------------------
; Tile Data Processing ($1a2f-$1a5b)
; ----------------------------------------------------------------------------
!dma_offset         = $1a2f     ; DMA transfer offset / cleared temp variable
!bg_control         = $1a3b     ; Background control flags / Tile calculation result
!graphics_flags     = $1a3d     ; Graphics system flags / Tile data working array[8]
!sprite_control     = $1a45     ; Sprite control variable / Graphics init flag
!layer_flags        = $1a55     ; Layer enable/disable flags / Packed graphics flags
!temp_zero_flag     = $1a5b     ; Temporary variable (cleared to $00)

; New documented names for tile processing
!temp_graphics_calc     = $1a2f     ; Cleared to $00, used in calculations (alias for !dma_offset)
!graphics_priority_flag = $1a33     ; Conditional value: (bit 3 of $19b4) ? $80 : $00
!graphics_param_store   = $1a34     ; Stores $1a52 value
!tile_data_temp_1       = $1a35     ; Data from $7fcef4[x]
!tile_data_temp_2       = $1a37     ; Data from $7fcef4[x+2]
!tile_lookup_value      = $1a39     ; Tile data lookup value
!temp_accumulator       = $1a3a     ; Temporary accumulator storage
!tile_calc_result       = $1a3b     ; Calculated tile value (alias for !bg_control)
!tile_data_copy         = $1a3c     ; Tile data copy
!tile_data_array        = $1a3d     ; Array of tile/graphics data (alias for !graphics_flags)
!graphics_init_flag     = $1a45     ; Initialization complete flag (alias for !sprite_control)
!copy_routine_selector  = $1a4c     ; If $01, call second copy routine
!graphics_param         = $1a52     ; Graphics parameter value
!packed_graphics_flags  = $1a55     ; Packed byte: 2 zero bits + top 3 bits of $1915 + top 3 bits of $1916

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
; Menu / UI ($7e0e00-$7e0fff)
; ----------------------------------------------------------------------------
!menu_color         = $0e9c     ; Menu color setting (2 bytes: $0e9c-$0e9d)
!menu_color_lo      = $0e9c     ; Menu color setting (low byte)
!menu_color_hi      = $0e9d     ; Menu color setting (high byte)

; ============================================================================
; HIGH RAM ($7e1000-$7effff) - Buffers
; ============================================================================

; ----------------------------------------------------------------------------
; Sprite / Graphics Buffers ($7e1000-$7e6fff)
; ----------------------------------------------------------------------------
!oam_buffer         = $7e1000   ; Sprite OAM buffer (512 bytes, 128 sprites)

!bg1_tilemap_buffer = $7e1200   ; BG1 tilemap buffer (3584 bytes)
!bg2_tilemap_buffer = $7e2000   ; BG2 tilemap buffer (4096 bytes)
!bg3_tilemap_buffer = $7e3000   ; BG3 tilemap buffer / text layer (4096 bytes)

!tile_buffer        = $7e4000   ; Tile data decompression buffer (4096 bytes)
!sprite_buffer      = $7e5000   ; Sprite data buffer (4096 bytes)
!palette_buffer     = $7e6000   ; Palette staging buffer (4096 bytes)

; ----------------------------------------------------------------------------
; Audio Buffers ($7e8000-$7e8fff)
; ----------------------------------------------------------------------------
!audio_command_buffer   = $7e8000   ; Audio command queue (256 bytes)
!music_data_buffer      = $7e8100   ; Music sequence buffer (256 bytes)
!sfx_data_buffer        = $7e8200   ; Sound effect data buffer (256 bytes)

; ----------------------------------------------------------------------------
; Working Memory ($7e9000-$7effff)
; ----------------------------------------------------------------------------
!general_work_1     = $7e9000   ; General working memory block 1 (4096 bytes)
!general_work_2     = $7ea000   ; General working memory block 2 (4096 bytes)
!general_work_3     = $7eb000   ; General working memory block 3 (4096 bytes)
!decompression_buffer = $7ec000 ; Data decompression working buffer (4096 bytes)

; ----------------------------------------------------------------------------
; Battle System Extended ($7e0800-$7e0bff)
; ----------------------------------------------------------------------------

; DMA Control Variables
!dma_control_flags      = $0ec6     ; DMA operation control flags (modified by TRB)
!dma_channel_array      = $0ec8     ; DMA channel status array (cleared to $00)
!vram_transfer_array    = $0f28     ; VRAM transfer queue array (cleared to $00)

; ============================================================================
; Battle System Extended ($7e0800-$7e0bff)
; ============================================================================

!enemy_data_1       = $7e0800   ; Enemy 1 complete battle data (128 bytes)
!enemy_data_2       = $7e0880   ; Enemy 2 complete battle data (128 bytes)
!enemy_data_3       = $7e0900   ; Enemy 3 complete battle data (128 bytes, optional)
!enemy_data_4       = $7e0980   ; Enemy 4 complete battle data (128 bytes, optional)

!battle_state_data  = $7e0a00   ; Battle state variables (128 bytes)
!command_queue      = $7e0a80   ; Battle command queue (128 bytes)

; ============================================================================
; Text System ($7e0c00-$7e0fff)
; ============================================================================

!text_buffer        = $7e0c00   ; Decompressed text buffer (256 bytes)
!dialog_buffer      = $7e0d00   ; Dialog display buffer (256 bytes)
!menu_buffer        = $7e0e00   ; Menu text buffer (256 bytes)

; ============================================================================
; End of RAM Variables
; ============================================================================


