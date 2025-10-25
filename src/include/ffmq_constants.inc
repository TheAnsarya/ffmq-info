; Final Fantasy Mystic Quest - Constants and Definitions
; Game-specific constants, addresses, and data structures

; === RAM Addresses ===
; Main character data
.define PLAYER_NAME         $7E1000     ; Player name (8 bytes)
.define PLAYER_LEVEL        $7E1010     ; Player level
.define PLAYER_EXPERIENCE   $7E1011     ; Player experience (3 bytes)
.define PLAYER_HP_CURRENT   $7E1014     ; Current HP (2 bytes)
.define PLAYER_HP_MAX       $7E1016     ; Max HP (2 bytes)
.define PLAYER_MP_WHITE_CUR $7E1018     ; Current White MP
.define PLAYER_MP_BLACK_CUR $7E1019     ; Current Black MP
.define PLAYER_MP_WIZARD_CUR $7E101A    ; Current Wizard MP
.define PLAYER_MP_WHITE_MAX $7E101B     ; Max White MP
.define PLAYER_MP_BLACK_MAX $7E101C     ; Max Black MP
.define PLAYER_MP_WIZARD_MAX $7E101D    ; Max Wizard MP

; Player stats
.define PLAYER_ATTACK       $7E101E     ; Attack power (2 bytes)
.define PLAYER_DEFENSE      $7E1020     ; Defense power (2 bytes)
.define PLAYER_SPEED        $7E1022     ; Speed stat (2 bytes)
.define PLAYER_MAGIC        $7E1024     ; Magic power (2 bytes)

; Equipment
.define PLAYER_WEAPON       $7E1026     ; Equipped weapon
.define PLAYER_ARMOR        $7E1027     ; Equipped armor
.define PLAYER_SHIELD       $7E1028     ; Equipped shield
.define PLAYER_HELMET       $7E1029     ; Equipped helmet
.define PLAYER_ACCESSORY    $7E102A     ; Equipped accessory

; Magic spells known
.define PLAYER_WHITE_MAGIC  $7E1037     ; White magic flags
.define PLAYER_BLACK_MAGIC  $7E1038     ; Black magic flags
.define PLAYER_WIZARD_MAGIC $7E1039     ; Wizard magic flags

; World map and location
.define MAP_ID              $7E0E88     ; Current map ID
.define PLAYER_X_POS        $7E0E89     ; Player X position on map
.define PLAYER_Y_POS        $7E0E8A     ; Player Y position on map

; Game progress flags
.define GAME_FLAGS_START    $7E0E8B     ; Game progress flags start
.define CRYSTALS_OBTAINED   $7E0E8C     ; Crystals obtained flags
.define BATTLEFIELDS_CLEAR  $7E0E8D     ; Battlefields cleared flags

; Inventory
.define INVENTORY_START     $7E0E90     ; Inventory start
.define INVENTORY_SIZE      $20         ; Max inventory slots

; === Game Constants ===
; Maximum values
.define MAX_LEVEL           41          ; Maximum player level
.define MAX_EXPERIENCE      $98967F     ; Maximum experience (9,999,999)
.define MAX_HP              999         ; Maximum HP
.define MAX_MP              99          ; Maximum MP per type

; Item types
.define ITEM_TYPE_WEAPON    $01
.define ITEM_TYPE_ARMOR     $02
.define ITEM_TYPE_SHIELD    $03
.define ITEM_TYPE_HELMET    $04
.define ITEM_TYPE_ACCESSORY $05
.define ITEM_TYPE_CONSUMABLE $06
.define ITEM_TYPE_KEY       $07

; Magic types
.define MAGIC_WHITE         $00
.define MAGIC_BLACK         $01
.define MAGIC_WIZARD        $02

; Spell IDs
; White Magic
.define SPELL_CURE          $00
.define SPELL_HEAL          $01
.define SPELL_LIFE          $02
.define SPELL_EXIT          $03

; Black Magic
.define SPELL_FIRE          $04
.define SPELL_BLIZZARD      $05
.define SPELL_THUNDER       $06
.define SPELL_QUAKE         $07

; Wizard Magic
.define SPELL_METEOR        $08
.define SPELL_FLARE         $09
.define SPELL_TELEPORT      $0A

; Monster types
.define MONSTER_TYPE_NORMAL     $00
.define MONSTER_TYPE_BOSS       $01
.define MONSTER_TYPE_CRYSTAL    $02

; Battle states
.define BATTLE_STATE_MENU       $00
.define BATTLE_STATE_ATTACKING  $01
.define BATTLE_STATE_MAGIC      $02
.define BATTLE_STATE_ITEM       $03
.define BATTLE_STATE_DEFEND     $04
.define BATTLE_STATE_RUN        $05

; Menu states
.define MENU_STATE_MAIN         $00
.define MENU_STATE_MAGIC        $01
.define MENU_STATE_ITEMS        $02
.define MENU_STATE_EQUIPMENT    $03
.define MENU_STATE_STATUS       $04

; Map IDs (from game analysis)
.define MAP_HILL_OF_DESTINY     $00
.define MAP_FORESTA             $01
.define MAP_AQUARIA             $02
.define MAP_FIREBURG            $03
.define MAP_WINDIA              $04
.define MAP_LEVEL_FOREST        $05
.define MAP_BONE_DUNGEON        $06
.define MAP_FOCUS_TOWER         $07
.define MAP_ICE_PYRAMID         $08
.define MAP_VOLCANO             $09
.define MAP_LAVA_DOME           $0A
.define MAP_MINE                $0B
.define MAP_SEALED_TEMPLE       $0C
.define MAP_SPENCER_CAVE        $0D
.define MAP_WINDY_CAVE          $0E
.define MAP_MOUNT_GALE          $0F
.define MAP_GIANT_TREE          $10
.define MAP_MYSTIC_PYRAMID      $11
.define MAP_FINAL_CASTLE        $12

; Crystal IDs
.define CRYSTAL_EARTH           $01
.define CRYSTAL_WATER           $02
.define CRYSTAL_FIRE            $04
.define CRYSTAL_WIND            $08

; Battle field IDs
.define BATTLEFIELD_FOREST      $01
.define BATTLEFIELD_DESERT      $02
.define BATTLEFIELD_BEACH       $04
.define BATTLEFIELD_MOUNTAIN    $08

; Sound effect IDs
.define SFX_MENU_SELECT         $01
.define SFX_MENU_CANCEL         $02
.define SFX_MENU_CURSOR         $03
.define SFX_ITEM_GET            $04
.define SFX_LEVEL_UP            $05
.define SFX_SPELL_CAST          $06
.define SFX_ATTACK_HIT          $07
.define SFX_ATTACK_MISS         $08
.define SFX_CRITICAL_HIT        $09
.define SFX_DEATH               $0A

; Music track IDs
.define MUSIC_TITLE             $00
.define MUSIC_OVERWORLD         $01
.define MUSIC_TOWN              $02
.define MUSIC_DUNGEON           $03
.define MUSIC_BATTLE            $04
.define MUSIC_BOSS_BATTLE       $05
.define MUSIC_VICTORY           $06
.define MUSIC_GAME_OVER         $07
.define MUSIC_ENDING            $08

; Graphics addresses (ROM)
.define GFX_FONT_START          $80000   ; Font graphics
.define GFX_SPRITES_START       $85000   ; Sprite graphics
.define GFX_TILES_START         $90000   ; Tile graphics
.define GFX_PORTRAITS_START     $A0000   ; Character portraits

; Text table addresses (ROM)
.define TEXT_TABLE_START        $B0000   ; Main text table
.define TEXT_NAMES_START        $B5000   ; Character/item names
.define TEXT_MENU_START         $B6000   ; Menu text

; Data table addresses (ROM)
.define DATA_MONSTERS_START     $C0000   ; Monster data
.define DATA_ITEMS_START        $C5000   ; Item data
.define DATA_SPELLS_START       $C6000   ; Spell data
.define DATA_MAPS_START         $C7000   ; Map data