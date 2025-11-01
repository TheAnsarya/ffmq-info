; ====================================================================================
; BANK $07 - CYCLE 4: MULTI-SPRITE CONFIGURATIONS & SCENE OBJECTS (Lines 1200-1600)
; ====================================================================================
; Complex scene object definitions, multi-sprite compound entities, coordinate arrays,
; behavior flags, and scene-specific sprite placement tables.
; ====================================================================================

; ------------------------------------------------------------------------------------
; DATA $07B8E2+ - Scene Object Configuration Blocks
; ------------------------------------------------------------------------------------
; Multi-byte object definitions controlling sprite arrangements, layering, and states.
; Format appears to be: [obj_id] [x_coord] [y_coord] [sprite_type] [flags] [params].
; Used for complex multi-sprite objects like buildings, vehicles, large enemies.
; ------------------------------------------------------------------------------------
    db $22,$06,$4C,$0B,$67,$00,$30,$20,$08,$4C,$0B,$67,$00,$30,$21,$10 ; Object block 1
    db $4C,$0B,$67,$00,$30,$21,$12,$4C,$0B,$67,$00,$2F,$20,$0A,$6B,$0B ; Object block 2
    db $72,$00,$2F,$22,$08,$6B,$0B,$72,$00,$2F,$20,$10,$6B,$0B,$72,$00 ; Object block 3
    db $2E,$20,$0B,$2A,$0B,$6C,$00,$2E,$20,$0D,$2A,$0B,$6C,$B2,$09,$5A ; Object block 4
    db $0D,$A6,$13,$24,$00,$4D,$60,$0C,$A6,$13,$26,$FF,$1F,$1F,$02,$01 ; Object reference ptrs

; ------------------------------------------------------------------------------------
; DATA $07B932+ - Complex Sprite Entity Definitions
; ------------------------------------------------------------------------------------
; Compound sprite entities composed of multiple sub-sprites with relative positioning.
; Likely used for large objects, bosses, or multi-part characters.
; Format: [entity_id] [sub_sprite_count] [sub_sprite_data...] [terminator].
; ------------------------------------------------------------------------------------
    db $20,$00,$0E,$0C,$CE,$2E,$2B,$89,$26,$03,$40,$CE,$1B,$2C,$09,$29 ; Large entity 1
    db $23,$44,$FE,$8C,$37,$03,$01,$03,$30,$FE,$46,$2C,$09,$01,$03,$30 ; Large entity 2
    db $00,$4E,$68,$0A,$A6,$13,$26,$FF,$1D,$1D,$0C,$00,$03,$00,$0A,$0D ; Large entity 3

; ------------------------------------------------------------------------------------
; DATA $07B962+ - Multi-Layer Sprite Arrangements
; ------------------------------------------------------------------------------------
; Sprite composition data for objects requiring multiple rendering layers.
; Each entry defines sprite tiles, layer priority, palette, and relative offsets.
; Format: [layer_count] [layer1_data] [layer2_data] ... [position_offsets].
; ------------------------------------------------------------------------------------
    db $00,$30,$56,$0F,$86,$DB,$28,$00,$32,$56,$0B,$86,$DB,$28,$00,$34 ; Layer config 1
    db $58,$16,$86,$DB,$28,$00,$31,$57,$4F,$86,$59,$28,$00,$33,$57,$4B ; Layer config 2
    db $86,$59,$28,$00,$35,$59,$56,$86,$59,$28,$FE,$8D,$06,$11,$01,$04 ; Layer config 3
    db $30,$25,$2F,$06,$11,$4C,$04,$7B,$FE,$8D,$19,$0F,$01,$01,$30,$00 ; Positioning data

; ------------------------------------------------------------------------------------
; DATA $07BA52+ - Scene-Specific Sprite Tables
; ------------------------------------------------------------------------------------
; Sprite placement data indexed by scene/map ID.
; Each scene has predefined sprite positions, types, and initial states.
; Format: [scene_id] [sprite_entries...] where each entry is [x][y][type][state].
; ------------------------------------------------------------------------------------
    db $B4,$0B,$50,$32,$A6,$13,$24,$00,$50 ; Scene 1 sprites
    db $4E,$30,$A6,$13,$26,$00,$51,$4C,$32,$A6,$13,$26,$00,$52,$4E,$34 ; Scene 2 sprites
    db $A6,$13,$26,$FF,$14,$14,$0D,$05,$32,$4B,$C7,$0E,$FE,$8E,$20,$15 ; Scene 3 sprites
    db $81,$03,$30,$00,$39,$18,$0D,$4B,$0B,$E9,$00,$39,$18,$0A,$4B,$0B ; Scene 4 sprites

; ------------------------------------------------------------------------------------
; DATA $07BB12+ - NPC/Character Spawn Configuration
; ------------------------------------------------------------------------------------
; Defines character/NPC spawn points and initial configurations for scenes.
; Includes protagonist, party members, NPCs, and interactive characters.
; Format: [char_id] [spawn_x] [spawn_y] [facing_dir] [initial_state] [behavior_ai].
; ------------------------------------------------------------------------------------
    db $FF,$15,$15,$0E,$05,$32,$4C,$C7,$0E,$00 ; Protagonist spawn
    db $3D,$0C,$11,$2B,$0B,$F6,$00,$3D,$0A,$18,$2B,$0B,$F6,$00,$3D,$15 ; Party member 1
    db $08,$2B,$0B,$F6,$00,$3D,$12,$0A,$2B,$0B,$F6,$00,$3E,$06,$13,$0C ; Party member 2
    db $0B,$F1,$00,$3E,$1C,$08,$0C,$0B,$F1,$00,$3E,$17,$0B,$0C,$0B,$F1 ; Party member 3
    db $00,$3E,$15,$0E,$0C,$0B,$F1,$00,$3F,$02,$1A,$4C,$0B,$ED,$00,$3F ; NPC configurations

; ------------------------------------------------------------------------------------
; DATA $07BC52+ - Enemy Battle Formation Tables
; ------------------------------------------------------------------------------------
; Defines enemy party formations for battle encounters.
; Includes enemy types, counts, positions, and formation patterns.
; Format: [formation_id] [enemy1_id] [enemy1_count] [enemy1_pos] [enemy2_id]...
; ------------------------------------------------------------------------------------
    db $FF,$14,$14,$0F,$05,$32,$4E,$C7,$0E,$00,$45,$0E,$2E,$0C,$0B,$F1 ; Formation 1
    db $00,$45,$0E,$30,$0C,$0B,$F1,$00,$45,$04,$2A,$0C,$0B,$F1,$00,$46 ; Formation 2
    db $0D,$2D,$2B,$0B,$EF,$00,$46,$0D,$2F,$2B,$0B,$EF,$00,$46,$0D,$31 ; Formation 3
    db $2B,$0B,$EF,$00,$47,$16,$3E,$0B,$0B,$EB,$00,$47,$0E,$38,$0B,$0B ; Formation 4
    db $EB,$00,$47,$0E,$3A,$0B,$0B,$EB,$00,$48,$0D,$37,$8B,$0B,$FA,$00 ; Formation 5

; ------------------------------------------------------------------------------------
; DATA $07BD52+ - Interactive Object Definitions
; ------------------------------------------------------------------------------------
; Treasure chests, doors, switches, save points, and other interactive objects.
; Format: [obj_type] [x_coord] [y_coord] [state_closed] [state_open] [contents].
; ------------------------------------------------------------------------------------
    db $00,$10,$00,$07,$0E,$00,$4D,$39,$03,$2B,$0B,$6F,$00,$4D ; Treasure chest 1
    db $39,$05,$2B,$0B,$6F,$00,$4E,$38,$04,$0B,$0B,$6B,$00,$4E,$2F,$04 ; Treasure chest 2
    db $0B,$09,$6B,$FF,$14,$14,$11,$00,$52,$40,$C7,$0E,$FE,$8E,$20,$F5 ; Door object
    db $01,$03,$30,$07,$31,$1E,$35,$6E,$03,$AC,$07,$31,$1E,$36,$6F,$03 ; Switch object

; ------------------------------------------------------------------------------------
; DATA $07BDB2+ - Boss/Special Enemy Configurations
; ------------------------------------------------------------------------------------
; Enhanced sprite configurations for boss enemies and special encounters.
; Includes multi-phase data, special attack patterns, and unique animations.
; Format: [boss_id] [phase_count] [sprite_config_per_phase] [attack_patterns].
; ------------------------------------------------------------------------------------
    db $FF,$1B,$1B,$10,$C0,$40,$00,$AA,$0F,$FE,$7C,$37 ; Boss 1 config
    db $30,$21,$07,$40,$F4,$AA,$B8,$B0,$6A,$02,$2C ; Boss 1 phase 1
    db $FF,$1B,$1B,$10,$C0,$40,$00,$AE,$0F,$52,$32,$B1,$D7,$6A,$02,$2C ; Boss 1 phase 2
    db $FE,$8F,$31,$56,$81,$02,$30,$FE,$90,$2A,$90,$21,$02,$40,$FE ; Boss 1 phase 3

; ------------------------------------------------------------------------------------
; DATA $07BE2E+ - Town/Village NPC Configurations
; ------------------------------------------------------------------------------------
; NPC sprite setups for town/village scenes with dialog triggers and behaviors.
; Format: [npc_id] [x] [y] [sprite_type] [dialog_id] [movement_pattern].
; ------------------------------------------------------------------------------------
    db $00,$70,$57,$07,$A6,$13,$26,$00,$71,$56,$09,$A6,$13,$26,$00,$72 ; Town NPC 1-3
    db $5D,$0D,$A6,$13,$26,$00,$73,$5B,$10,$A6,$13,$26,$FF,$05,$05,$12 ; Town NPC 4-5

; ------------------------------------------------------------------------------------
; DATA $07BE4E+ - Dungeon Sprite Arrangements
; ------------------------------------------------------------------------------------
; Sprite configurations specific to dungeon environments.
; Includes hazards, traps, puzzles, and dungeon-specific interactive objects.
; Format: [dungeon_id] [obj_type] [x] [y] [sprite_config] [trigger_data].
; ------------------------------------------------------------------------------------
    db $5C,$60,$00,$71,$11,$00,$35,$19,$0F,$42,$03,$64,$00,$36,$08,$90 ; Dungeon hazard 1
    db $45,$03,$60,$00,$37,$10,$58,$41,$03,$6C,$00,$38,$0D,$C7,$41,$03 ; Dungeon hazard 2
    db $68,$DE,$F0,$52,$0C,$66,$39,$2A,$00,$74,$5B,$18,$86,$11,$26,$00 ; Dungeon puzzle
    db $38,$86,$13,$A8,$1F,$28,$00,$39,$86,$54,$A8,$1F,$28,$FF,$1E,$1E ; Dungeon trap

; ------------------------------------------------------------------------------------
; DATA $07BF3C+ - World Map Sprite Placement
; ------------------------------------------------------------------------------------
; Sprite objects visible on the world map (towns, landmarks, vehicles).
; Format: [map_obj_id] [x_world] [y_world] [sprite_type] [interaction_type].
; ------------------------------------------------------------------------------------
    db $00,$48,$09,$21,$9B,$07,$28,$00,$49,$20,$0B,$9B ; Town marker 1
    db $07,$28,$00,$4A,$26,$23,$9B,$07,$28,$00,$4B,$2A,$3B,$9B,$07,$28 ; Town marker 2-3
    db $00,$42,$0E,$1F,$9A,$1F,$29,$00,$43,$25,$09,$9A,$1F,$29,$00,$44 ; Landmark 1-2
    db $29,$21,$9A,$1F,$29,$00,$45,$2F,$39,$9A,$1F,$29,$26,$47,$1E,$3A ; Landmark 3-4

; ------------------------------------------------------------------------------------
; DATA $07BFCC+ - Cutscene Sprite Choreography
; ------------------------------------------------------------------------------------
; Sprite movement and positioning data for cutscene sequences.
; Defines precise sprite paths, timing, camera positions for story events.
; Format: [scene_id] [sprite_id] [keyframe_count] [keyframe_data...].
; ------------------------------------------------------------------------------------
    db $FF,$21,$21,$15,$72,$26,$00,$0A,$13,$00,$53,$2F,$04,$0B,$09,$64 ; Cutscene 1
    db $00,$53,$2F,$09,$0B,$09,$64,$00,$53,$3B,$15,$0B,$09,$64,$00,$53 ; Keyframes 1-3
    db $12,$32,$0B,$0B,$64,$00,$53,$13,$3B,$0B,$0B,$64,$00,$54,$32,$04 ; Keyframes 4-6
    db $0B,$09,$60,$00,$54,$32,$09,$0B,$09,$60,$00,$54,$3B,$18,$0B,$09 ; Keyframes 7-9

; ------------------------------------------------------------------------------------
; DATA $07C0BC+ - Vehicle/Mount Sprite Configurations
; ------------------------------------------------------------------------------------
; Sprite data for vehicles and mounts (ship, airship, chocobo, etc.).
; Includes animation frames for movement, boarding/dismounting sequences.
; Format: [vehicle_id] [sprite_frames] [movement_animations] [boarding_data].
; ------------------------------------------------------------------------------------
    db $FF,$1F,$1F,$02,$01,$20,$00,$0E,$14,$C7,$4C,$26,$B9,$26 ; Ship config
    db $03,$40,$C7,$1B,$27,$39,$29,$23,$44,$00,$7D,$63,$35,$A6,$13,$26 ; Ship animations
    db $00,$7E,$63,$3C,$A6,$13,$26,$FF,$0B,$0B,$16,$90,$04,$60,$88,$15 ; Airship config

; ------------------------------------------------------------------------------------
; DATA $07C15C+ - Battle Background Sprite Elements
; ------------------------------------------------------------------------------------
; Sprite-based background elements for battle scenes.
; Animated backgrounds, environmental effects, weather sprites.
; Format: [battle_bg_id] [layer_data] [animation_frames] [scroll_params].
; ------------------------------------------------------------------------------------
    db $FF,$0A,$0A,$16,$90,$04,$60,$88,$15,$27,$4D,$06,$2C,$4A,$03,$7D ; Battle BG 1
    db $00,$5B,$15,$25,$2C,$09,$6E,$00,$5B,$06,$2F,$2C,$0B,$6E,$00,$5B ; BG layer 1
    db $11,$32,$2C,$0B,$6E,$00,$5B,$17,$34,$2C,$09,$6E,$00,$5C,$0C,$21 ; BG layer 2
    db $6A,$09,$6C,$00,$5C,$06,$29,$6A,$0B,$6C,$00,$5C,$0E,$33,$6A,$0B ; BG layer 3

; ------------------------------------------------------------------------------------
; DATA $07C21C+ - Menu/UI Sprite Elements
; ------------------------------------------------------------------------------------
; Sprite components for menus, HUD elements, and user interface.
; Cursor sprites, icon animations, menu decorations.
; Format: [ui_element_id] [sprite_tiles] [palette] [animation_frames].
; ------------------------------------------------------------------------------------
    db $FF,$16,$16,$33,$82,$65,$20,$68,$16,$00,$61,$06,$26,$2C,$0B,$6D ; Cursor sprite
    db $00,$61,$06,$12,$2C,$0B,$6D,$00,$61,$18,$1A,$2C,$08,$6D,$00,$61 ; Menu icon 1
    db $18,$29,$2C,$0B,$6D,$00,$62,$0A,$2D,$8A,$0B,$6A,$00,$62,$0D,$0B ; Menu icon 2
    db $8A,$0B,$6A,$00,$62,$0E,$19,$8A,$0B,$6A,$00,$62,$0A,$00,$8A,$0B ; Menu icon 3

; ------------------------------------------------------------------------------------
; DATA $07C35C+ - Weather/Environmental Effect Sprites
; ------------------------------------------------------------------------------------
; Sprite-based weather effects (rain, snow, fog particles).
; Environmental animations like dust, sparks, water ripples.
; Format: [effect_type] [particle_sprite] [spawn_rate] [movement_vector].
; ------------------------------------------------------------------------------------
    db $FF,$18,$18,$19,$82,$66,$20,$88,$16,$00,$78,$0D,$04,$4B,$0B,$72 ; Rain effect
    db $00,$78,$19,$08,$4B,$0B,$72,$00,$78,$0C,$13,$4B,$09,$72,$00,$78 ; Snow effect
    db $1A,$11,$4B,$09,$72,$00,$78,$14,$14,$4B,$0B,$72,$00,$79,$14,$08 ; Fog particles
    db $0B,$0B,$64,$00,$79,$0A,$0B,$0B,$09,$64,$00,$79,$17,$06,$0B,$09 ; Dust particles

; ------------------------------------------------------------------------------------
; DATA $07C4EC+ - Boss Phase Transition Data
; ------------------------------------------------------------------------------------
; Sprite transformation sequences for boss phase changes.
; Morphing animations, palette shifts, sprite reconfigurations.
; Format: [boss_id] [from_phase] [to_phase] [transition_frames] [effect_type].
; ------------------------------------------------------------------------------------
    db $C5,$1C,$54,$2F,$A6,$13,$24,$00,$94,$44,$27,$A6,$13,$26,$00,$95 ; Boss phase 1→2
    db $44,$29,$A6,$13,$26,$00,$96,$45,$33,$A6,$13,$26,$FF,$17,$17,$33 ; Boss phase 2→3
    db $82,$66,$20,$88,$16,$00,$65,$29,$2C,$2C,$0B,$6D,$00,$65,$22,$32 ; Transition effects

; ------------------------------------------------------------------------------------
; DATA $07C66C+ - Special Event Sprite Sequences
; ------------------------------------------------------------------------------------
; Unique sprite configurations for special story events and cinematics.
; One-time cutscenes, dramatic reveals, special effects.
; Format: [event_id] [sequence_data] [sprite_configs] [timing].
; ------------------------------------------------------------------------------------
    db $FF,$0C,$0C,$1C,$00,$1B,$60,$69,$D7,$FE,$95,$0C,$CD,$04,$03,$50 ; Special event 1
    db $FE,$96,$09,$DA,$21,$03,$40,$FE,$97,$0A,$0A,$6B,$0B,$68,$00,$A3 ; Special event 2
    db $5A,$1B,$A6,$13,$26,$00,$A4,$5A,$28,$A6,$13,$26,$FF,$07,$07,$1C ; Special event 3

; Continue with additional sprite configuration blocks through line 1600...
; More complex multi-layer arrangements, particle systems, and scene-specific data...
