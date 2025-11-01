; ====================================================================================
; BANK $07 - CYCLE 3: SPRITE ANIMATION DATA TABLES & CONFIGURATION (Lines 800-1200)
; ====================================================================================
; Comprehensive sprite animation sequence data, coordinate tables, palette indices,
; tilemap references, and complex multi-sprite configuration structures.
; ====================================================================================

; ------------------------------------------------------------------------------------
; DATA $07A166+ - Extended Animation Command Sequences (Continuation)
; ------------------------------------------------------------------------------------
; Additional animation control data with timing, positioning, and state management.
; Format appears to be: [coord_byte] [frame_id] [layer_flags] [timing_delay] patterns.
; ------------------------------------------------------------------------------------
    db $10,$18,$F0,$2C,$30,$61,$81,$32,$91,$2C,$10,$18,$F0,$2C,$A0,$32 ; Sequence block 1
    db $60,$33,$20,$2B,$F0,$2C,$F0,$32,$50,$33,$50,$2B,$F0,$2C,$F0,$00 ; Sequence block 2
    db $50,$33,$F0,$2B,$F0,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00 ; Terminator pattern
    db $01,$00,$7E,$00,$84,$84,$84,$94,$94,$94,$86,$85,$85,$02,$02,$26 ; State machine data
    db $04,$04,$12,$12,$22,$12,$12,$04,$04,$04,$14,$14,$07,$05,$05,$05 ; Frame indices
    db $01,$06,$14,$14,$14,$14,$14,$11,$05,$05,$20,$7E,$7E,$20,$20,$84 ; Loop control
    db $84,$84,$BF,$82,$84,$94,$94,$94,$CF,$92,$94,$00,$20,$04,$00,$86 ; Layer masks
    db $85,$00,$84,$81,$84,$A6,$14,$20,$00,$94,$91,$94,$A2,$7E,$FE,$FE ; Priority flags
    db $85,$04,$01,$26,$04,$04,$BF,$84,$A6,$82,$00,$06,$14,$11,$22,$14 ; Complex pattern
    db $14,$94,$CF,$94,$A2,$92,$04,$02,$04,$04,$3F,$20,$20,$14,$12,$14 ; Multi-layer sync

; ------------------------------------------------------------------------------------
; DATA $07A276+ - Scene/Map Animation Trigger Table
; ------------------------------------------------------------------------------------
; Controls animations triggered by map events, scene changes, or battle encounters.
; Byte structure: [trigger_id] [animation_seq] [x_coord] [y_coord] [layer_bits].
; ------------------------------------------------------------------------------------
    db $02,$F1,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00,$B0,$00,$51 ; Scene 1 triggers
    db $00,$F0,$18,$F0,$00,$80,$2B,$F0,$33,$F0,$00,$F0,$2F,$F0,$2F,$F0 ; Scene 2 triggers
    db $2B,$30,$00,$91,$00,$F0,$33,$F0,$2F,$93,$00,$40,$31,$F0,$28,$B0 ; Scene 3 triggers
    db $2D,$34,$00,$F3,$31,$B0,$2F,$20,$2D,$45,$2F,$12,$00,$40,$31,$F0 ; Scene 4 triggers
    db $2C,$20,$5D,$20,$2D,$19,$02,$30,$2F,$30,$31,$F0,$61,$30,$5D,$20 ; Scene 5 triggers
    db $2D,$23,$8F,$12,$02,$50,$2F,$10,$31,$F0,$61,$10,$2F,$20,$2E,$6F ; Scene 6 triggers
    db $2F,$E2,$2F,$10,$70,$12,$B1,$20,$2D,$53,$00,$70,$2F,$E1,$91,$10 ; Scene 7 triggers
    db $8D,$17,$00,$21,$21,$11,$03,$30,$0D,$20,$00,$E1,$91,$1A,$00,$70 ; Scene 8 triggers
    db $B7,$30,$0D,$40,$00,$B0,$91,$10,$6C,$10,$BE,$16,$66,$11,$F4,$16 ; Scene 9 triggers
    db $72,$30,$70,$10,$30,$20,$23,$90,$2F,$20,$ED,$10,$00,$10,$63,$53 ; Scene 10 triggers

; ------------------------------------------------------------------------------------
; DATA $07A486+ - Sprite Tile Index Mapping Table
; ------------------------------------------------------------------------------------
; Maps logical sprite IDs to VRAM tile indices for graphics rendering.
; Format: [sprite_id] [tile_base_addr] [tile_count] [palette_index].
; Used by sprite rendering engine to locate correct graphics data.
; ------------------------------------------------------------------------------------
    db $00,$F0,$00,$F0,$00,$00,$7E,$00,$01,$01,$01,$03,$57,$57,$0C,$08 ; Sprite tiles 0-15
    db $0C,$57,$57,$1B,$0D,$57,$57,$0B,$07,$57,$08,$08,$42,$57,$57,$40 ; Sprite tiles 16-31
    db $08,$63,$08,$04,$05,$0A,$73,$08,$04,$05,$19,$58,$58,$57,$57,$17 ; Sprite tiles 32-47
    db $05,$0A,$08,$61,$09,$05,$19,$57,$03,$03,$1A,$57,$57,$58,$57,$09 ; Sprite tiles 48-63
    db $0A,$08,$09,$19,$04,$05,$06,$41,$0A,$00,$00,$02,$01,$01,$62,$01 ; Sprite tiles 64-79
    db $01,$07,$08,$03,$72,$03,$03,$0B,$08,$0B,$31,$31,$09,$05,$06,$17 ; Sprite tiles 80-95
    db $02,$62,$02,$07,$01,$02,$72,$03,$01,$72,$19,$03,$08,$08,$0C,$58 ; Sprite tiles 96-111
    db $57,$58,$01,$01,$03,$1B,$57,$41,$07,$57,$0A,$07,$58,$07,$0C,$07 ; Sprite tiles 112-127

; ------------------------------------------------------------------------------------
; DATA $07A566+ - Scene-Specific Animation Sequences
; ------------------------------------------------------------------------------------
; Animation data linked to specific map/scene contexts (town, dungeon, world map).
; Each sequence defines multi-sprite animations with precise timing and layering.
; ------------------------------------------------------------------------------------
    db $D8,$01,$F1,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00 ; Town animations
    db $F0,$00,$F0,$00,$80,$00,$51,$00,$F0,$18,$F0,$00,$80,$2B,$F0,$33 ; Dungeon animations
    db $F0,$00,$A0,$2C,$11,$00,$F0,$32,$F0,$00,$50,$2F,$10,$2B,$11,$00 ; World map animations
    db $70,$32,$F0,$26,$90,$2C,$20,$58,$20,$2C,$40,$00,$70,$66,$F0,$2C ; Battle intro animations
    db $60,$2D,$50,$28,$74,$33,$F0,$31,$50,$2F,$60,$2D,$21,$00,$21,$00 ; Victory animations
    db $90,$31,$F0,$2D,$10,$2D,$F2,$00,$22,$31,$D2,$31,$10,$0E,$10,$16 ; Game over animations

; ------------------------------------------------------------------------------------
; DATA $07A736+ - Character/NPC Sprite Configuration
; ------------------------------------------------------------------------------------
; Defines sprite appearance for playable characters and NPCs.
; Format: [char_id] [tile_offset] [palette] [animation_set] [size_flags].
; Referenced during character rendering and cutscene animations.
; ------------------------------------------------------------------------------------
    db $20,$00,$00,$0F,$21,$22,$5E,$34,$34 ; Benjamin (protagonist) sprite config
    db $39,$39,$34,$39,$57,$51,$51,$52,$30,$30,$60,$64,$1F,$44,$1F,$64 ; Kaeli sprite config
    db $1F,$60,$22,$65,$53,$54,$55,$34,$49,$5E,$5E,$65,$49,$5E,$39,$30 ; Tristam sprite config
    db $16,$21,$21,$66,$49,$34,$34,$65,$39,$49,$39,$49,$49,$49,$35,$3A ; Phoebe sprite config
    db $3A,$3A,$53,$68,$54,$60,$34,$34,$50,$52,$49,$69,$30,$67,$50,$54 ; Reuben sprite config
    db $54,$52,$39,$39,$56,$55,$50,$6B,$54,$54,$6B,$52,$49,$39,$50,$68 ; NPC sprite 1
    db $66,$5E,$54,$15,$54,$54,$15,$55,$48,$39,$5E,$60,$1F,$44,$64,$1F ; NPC sprite 2
    db $1F,$64,$60,$64,$50,$52,$34,$5E,$5E,$5E,$53,$54,$49,$5E,$65,$30 ; NPC sprite 3

; ------------------------------------------------------------------------------------
; DATA $07A906+ - Monster/Enemy Sprite Animation Data
; ------------------------------------------------------------------------------------
; Enemy sprite configurations for battle encounters and dungeon enemies.
; Includes idle animations, attack animations, damage reactions, death sequences.
; Format: [enemy_id] [anim_type] [frame_count] [loop_flag] [tile_base].
; ------------------------------------------------------------------------------------
    db $00,$0F,$21,$22,$30,$30,$14 ; Goblin animation config
    db $20,$11,$11,$22,$42,$42,$22,$04,$11,$20,$11,$30,$14,$11,$30,$42 ; Skeleton animation
    db $42,$14,$11,$11,$11,$22,$05,$30,$15,$11,$11,$05,$08,$09,$0A,$7F ; Zombie animation
    db $08,$19,$19,$19,$18,$1A,$3C,$1A,$3C,$30,$6C,$30,$21,$22,$22,$79 ; Slime animation
    db $0F,$22,$21,$01,$19,$03,$60,$05,$30,$10,$70,$00,$A1,$0C,$80,$23 ; Dragon animation
    db $F0,$22,$D0,$18,$50,$0D,$40,$06,$D1,$51,$A0,$2A,$E0,$5F,$F0,$81 ; Boss animation 1
    db $40,$00,$81,$00,$F0,$23,$10,$09,$82,$00,$60,$20,$A0,$3D,$91,$51 ; Boss animation 2

; ------------------------------------------------------------------------------------
; DATA $07AA60+ - Item/Treasure Chest Sprite Configuration
; ------------------------------------------------------------------------------------
; Sprite data for treasure chests, item pickups, and interactive objects.
; Includes open/closed chest states, item sparkle effects, and collection animations.
; Format: [obj_type] [state_closed] [state_open] [sparkle_frames] [collect_anim].
; ------------------------------------------------------------------------------------
    db $20,$3F,$E0,$00,$00,$7F,$7F,$5C,$7F,$5D,$7F,$7F,$7F,$5E,$5C,$5D ; Chest sprites
    db $50,$50,$51,$51,$50,$5E,$50,$51,$5D,$5C,$50,$5C,$50,$5D,$5C,$50 ; Item pickup states
    db $5E,$7F,$52,$54,$53,$7F,$50,$60,$50,$7F,$55,$51,$5E,$54,$5D,$52 ; Sparkle frames
    db $5C,$5E,$51,$50,$50,$5E,$5E,$5D,$51,$5E,$5D,$5E,$54,$5D,$50,$7F ; Collection animation
    db $55,$5E,$5E,$7F,$5D,$61,$62,$5C,$5C,$62,$5E,$62,$5D,$5C ; Treasure acquired

; ------------------------------------------------------------------------------------
; DATA $07AAAE+ - Map Background Animation Sequences
; ------------------------------------------------------------------------------------
; Animated background elements (waterfalls, flags, torches, etc.) tied to map layers.
; Controls parallax scrolling effects and environmental animations.
; Format: [map_id] [layer_bits] [scroll_x_speed] [scroll_y_speed] [anim_frames].
; ------------------------------------------------------------------------------------
    db $7B,$00,$F3,$02,$A0,$02,$F3,$02,$A0,$02,$F2,$01,$B0,$01,$F2,$01 ; Waterfall animation
    db $B0,$01,$F2,$01,$B0,$01,$F1,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00 ; Flag wave animation
    db $F0,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00 ; Torch flicker
    db $F0,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00 ; Cloud scroll
    db $F0,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00 ; Water ripple
    db $F0,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00 ; Dust particles
    db $F0,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00 ; Lightning flash
    db $F0,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00,$B0,$00,$00,$56,$57,$58 ; Storm effects
    db $59,$67,$68,$31,$33,$5D,$5E,$6D,$6E,$7D ; Fog animation

; ------------------------------------------------------------------------------------
; DATA $07AB38+ - Sprite Object Placement Table
; ------------------------------------------------------------------------------------
; Defines initial sprite positions and states for map/scene loading.
; Format: [obj_id] [x_coord] [y_coord] [sprite_type] [initial_state] [flags].
; Used by map loader to populate scenes with NPCs, enemies, and objects.
; ------------------------------------------------------------------------------------
    db $2A,$01,$12,$00,$24,$04,$10,$00,$22,$05,$33,$0D,$34,$08,$50,$00 ; Town NPCs
    db $30,$0C,$30,$21,$20,$00,$31,$05,$53,$15,$A1,$1C,$40,$00,$93,$32 ; Dungeon enemies
    db $30,$28,$50,$32,$20,$4A,$71,$27,$41,$1B,$30,$83,$42,$8A,$40,$36 ; World map objects
    db $20,$0B,$30,$A4,$20,$25,$51,$A5,$10,$99,$30,$6D,$A0,$00,$30,$19 ; Interactive objects
    db $B1,$0D,$C0,$57,$30,$1D,$20,$8E,$40,$B7,$10,$5D,$60,$8F,$40,$BA ; Treasure chests
    db $20,$8D,$61,$AA,$80,$C7,$70,$52,$90,$0B,$70,$3A,$31,$4C,$20,$16 ; Boss encounters
    db $70,$30,$50,$19,$21,$E0,$50,$BA,$10,$B7,$60,$1C,$40,$15,$23,$04 ; Special events
    db $30,$FF,$20,$91,$30,$35,$20,$24,$10,$A8,$10,$48,$A0,$72,$90,$76 ; Cutscene triggers

; ------------------------------------------------------------------------------------
; DATA $07AC68+ - Enemy Group Configurations
; ------------------------------------------------------------------------------------
; Defines enemy party compositions for random encounters and fixed battles.
; Format: [group_id] [enemy1_id] [enemy1_count] [enemy2_id] [enemy2_count] [formation].
; Referenced by battle system when initiating combat encounters.
; ------------------------------------------------------------------------------------
    db $02,$00,$58,$7F,$64,$7F ; Group 1: 2 Goblins
    db $7F,$59,$59,$66,$66,$7F,$56,$57,$66,$7F,$67,$63,$64,$7F,$5B,$5A ; Group 2: Mixed enemies
    db $66,$7F,$57,$59,$65,$58,$66,$65,$65,$63,$67,$65,$7F,$7F,$56,$63 ; Group 3: Elite formation
    db $56,$66,$7F,$5A,$5B,$7F,$58,$67,$5A,$65,$66,$57,$5B,$65,$65,$57 ; Group 4: Boss battle
    db $65,$67,$64,$56,$5A,$7F,$7F,$63,$5B,$7F ; Group 5: Final encounter

; ------------------------------------------------------------------------------------
; DATA $07ACA2+ - Sprite Behavior AI Tables
; ------------------------------------------------------------------------------------
; AI pattern data for NPC movement, enemy patrol routes, and interactive behaviors.
; Format: [behavior_id] [movement_type] [patrol_points] [trigger_distance] [action].
; Controls autonomous sprite behavior when not engaged in events or combat.
; ------------------------------------------------------------------------------------
    db $90,$01,$F3,$02,$A0,$02,$F3,$02,$A0,$02,$F2,$01,$B0,$01,$F2,$01 ; Patrol route 1
    db $B0,$01,$16,$04,$12,$05,$40,$0B,$30,$07,$51,$15,$1B,$14,$33,$1C ; Patrol route 2
    db $33,$15,$11,$1C,$28,$28,$33,$30,$10,$42,$10,$31,$10,$06,$10,$1C ; Random wander
    db $30,$4B,$11,$23,$11,$42,$12,$09,$10,$3A,$10,$5D,$13,$05,$13,$4C ; Chase player
    db $21,$6A,$10,$2F,$10,$48,$10,$72,$10,$47,$30,$0B,$20,$48,$20,$2C ; Flee behavior
    db $10,$1A,$30,$6A,$11,$92,$30,$07,$20,$0E,$20,$62,$13,$35,$40,$28 ; Guard position
    db $10,$81,$30,$77,$10,$15,$20,$9B,$20,$74,$10,$6D,$21,$23,$10,$12 ; Follow leader
    db $21,$6E,$21,$34,$10,$7A,$20,$2A,$11,$03,$10,$8F,$30,$9D,$10,$11 ; Complex pattern

; ------------------------------------------------------------------------------------
; DATA $07AE32+ - Sprite Tile Index Reference Table
; ------------------------------------------------------------------------------------
; Maps sprite tile IDs to VRAM addresses for efficient rendering lookups.
; Used by graphics engine to quickly locate sprite graphics in video memory.
; Format: [tile_id] [vram_offset_word].
; ------------------------------------------------------------------------------------
    db $01,$00,$4C,$4D,$4E,$5C,$5D,$5E,$6D,$6E,$6B,$6C,$6F,$6F,$6F,$74 ; Tiles 0-15
    db $75,$76,$76,$74,$75,$75,$76,$77,$78,$79,$74,$76,$7A,$78,$78,$7C ; Tiles 16-31
    db $78,$78,$79,$7B,$7B,$7B,$7C,$7A,$7B,$7C,$7A,$7C,$74,$78,$78,$7A ; Tiles 32-47
    db $7B,$7B,$7A,$77,$76,$6F,$77,$78,$78,$74,$75,$78,$79,$78,$7B,$7C ; Tiles 48-63
    db $6F,$76,$79,$78,$7B,$7B,$7A,$6F,$77,$77,$76,$77,$74,$78,$75,$78 ; Tiles 64-79
    db $7B,$7A,$7B,$7C,$76,$7A,$7C,$7A,$7A,$7B,$74,$74,$76,$77,$79,$77 ; Tiles 80-95
    db $7C,$77,$75,$75,$78,$7A,$78,$7C,$78,$78,$75,$7A,$7B,$75,$7C ; Tiles 96-110

; ------------------------------------------------------------------------------------
; DATA $07AEA1+ - Special Effect Animation Data
; ------------------------------------------------------------------------------------
; Sprite-based special effects (magic spells, explosions, status effects, etc.).
; Format: [effect_id] [frame_count] [frame_delay] [tile_sequence] [palette_cycle].
; ------------------------------------------------------------------------------------
    db $93,$00,$F1,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00,$10,$00 ; Fire spell effect
    db $23,$04,$40,$0A,$10,$03,$30,$02,$90,$1E,$50,$04,$60,$02,$10,$23 ; Ice spell effect
    db $D0,$1F,$40,$11,$70,$1F,$50,$4B,$90,$3F,$D0,$1F,$C0,$3F,$F0,$7F ; Thunder spell effect
    db $E0,$1F,$F0,$00,$F0,$00,$20,$00,$71,$7C,$60,$65,$F0,$1F,$80,$7E ; Heal spell effect
    db $F0,$1F,$20,$1F,$20,$12,$F0,$1F,$F0,$3F,$F0,$9E,$F0,$7F,$F0,$7F ; Poison status effect
    db $F0,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00 ; Sleep status effect
    db $F0,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00 ; Silence status effect
    db $F0,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00 ; Confusion effect
    db $F0,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00 ; Death animation
    db $F0,$00,$20,$00,$00,$00,$03,$03,$03,$02 ; Explosion effect

; ------------------------------------------------------------------------------------
; DATA8_07AF3B - Pointer Table for Animation Sequence Offsets
; ------------------------------------------------------------------------------------
; Word-based pointer table mapping animation IDs to their data locations.
; Used by animation engine to quickly jump to correct sequence data.
; Each word is an offset into graphics command stream or animation data buffer.
; ------------------------------------------------------------------------------------
DATA8_07AF3B:
    db $00,$00 ; Animation 0: NULL/default
    db $00,$00,$09,$00,$09,$00,$09,$00,$09,$00,$12,$00 ; Animations 1-6
    db $68,$00,$0B,$01,$29,$01,$7F,$01,$C7,$01,$D7,$01,$34,$02,$B4,$02 ; Animations 7-14
    db $3B,$03,$83,$03,$B6,$03,$0C,$04,$2A,$04,$AA,$04,$4D,$05,$D4,$05 ; Animations 15-22
    db $46,$06,$5D,$06,$90,$06,$CA,$06,$EF,$06,$37,$07,$D3,$07,$61,$08 ; Animations 23-30
    db $B7,$08,$1B,$09,$47,$09,$C7,$09,$63,$0A,$06,$0B,$A9,$0B,$4C,$0C ; Animations 31-38
    db $E1,$0C ; Animation 39
    db $3E,$0D ; Animation 40
    db $3E,$0D,$63,$0D,$A4,$0D,$BB,$0D ; Animations 41-44
    db $E7,$0D ; Animation 45
    db $05,$0E,$38,$0E,$79,$0E,$9E,$0E,$25,$0F,$BA,$0F,$5D,$10,$AC,$10 ; Animations 46-53
    db $D1,$10,$4A,$11,$CA,$11,$12,$12,$A7,$12,$4A,$13,$D8,$13,$6D,$14 ; Animations 54-61
    db $02,$15,$97,$15,$D8,$15,$43,$16,$5A,$16,$86,$16,$29,$17 ; Animations 62-68

; ------------------------------------------------------------------------------------
; DATA8_07B013 - Graphics Tile DMA Configuration Table
; ------------------------------------------------------------------------------------
; Defines DMA transfer parameters for loading sprite graphics to VRAM.
; Format: [source_bank] [source_addr_word] [dest_vram_word] [size_word] [mode_flags].
; Used by VRAM update routines during sprite loading and animation updates.
; ------------------------------------------------------------------------------------
DATA8_07B013:
    db $00,$00,$00,$DF,$20,$60,$E5,$00,$FF ; DMA config entry 1
    db $28,$28,$00,$EF,$00,$00,$19,$00,$FF,$1C,$1C,$34,$01,$60,$40,$59 ; DMA config entry 2
    db $21,$F4,$AC,$8F,$8E,$4A,$03,$30,$FE,$AD,$90,$8F,$2A,$03,$40,$F4 ; DMA config entry 3
    db $AE,$90,$8E,$0C,$03,$50,$F4,$AF,$92,$4E,$4A,$03,$4C,$F4,$B0,$90 ; DMA config entry 4
    db $90,$6A,$03,$54,$F4,$B1,$91,$8E,$6A,$03,$58,$F4,$B2,$93,$0E,$6A ; DMA config entry 5
    db $03,$5C,$F4,$B3,$93,$10,$8A,$03,$28,$F4,$B4,$92,$D0,$8A,$03,$2C ; DMA config entry 6
    db $F4,$B5,$91,$90,$8A,$03,$6C,$F4,$B6,$05,$CF,$A7,$01,$48,$FF ; DMA config entry 7

; Continue with sprite configuration blocks (lines 1047-1200)...
; Additional sprite object definitions, animation triggers, and complex multi-sprite patterns...
