# Map System Architecture

Complete documentation of the Final Fantasy Mystic Quest map and world navigation system.

## Table of Contents

- [System Overview](#system-overview)
- [Map Types](#map-types)
- [Map Data Structure](#map-data-structure)
- [Collision System](#collision-system)
- [Event System](#event-system)
- [NPC System](#npc-system)
- [Door and Warp System](#door-and-warp-system)
- [Treasure and Items](#treasure-and-items)
- [Map Loading](#map-loading)
- [Code Locations](#code-locations)

## System Overview

FFMQ's map system manages all explorable areas:

- **World map** (Mode 7 rotation)
- **Towns and dungeons** (top-down view)
- **Collision detection** (tile-based)
- **Event triggers** (automatic and interactive)
- **NPC placement** and behavior
- **Door/warp connections**
- **Treasure chests** and items

### Map Architecture

```
┌──────────────────────┐
│   Player Input       │
└──────────┬───────────┘
           │
           v
┌──────────────────────┐
│  Movement System     │
├──────────────────────┤
│ - Check collision    │
│ - Update position    │
│ - Trigger events     │
└──────────┬───────────┘
           │
           v
┌──────────────────────┐
│   Map Engine         │
├──────────────────────┤
│ - Load map data      │
│ - Render tiles       │
│ - Spawn NPCs         │
│ - Handle events      │
└──────────────────────┘
```

## Map Types

### Map Categories

```
1. World Map
   - Mode 7 rotated view
   - Large scrolling area
   - No walls (water is barrier)
   - Town/dungeon entry points

2. Towns
   - Top-down view (Mode 1)
   - NPCs and shops
   - Safe areas (no battles)
   - Multiple buildings/interiors

3. Dungeons
   - Top-down view (Mode 1)
   - Random encounters
   - Puzzle elements
   - Boss arenas

4. Battle Backgrounds
   - Static images
   - Used during battles
   - Match dungeon theme
```

### Map Dimensions

```
World Map:
  - 512×512 tiles (4096×4096 pixels)
  - Mode 7 tilemap
  - Single layer
  
Town/Dungeon Maps:
  - 32×32 to 64×64 tiles
  - Mode 1 tilemap
  - 2-3 layers (BG1, BG2, BG3)
  - Typical: 64×64 tiles (512×512 pixels)
```

## Map Data Structure

### Map Header

```
Map Header (32 bytes):
  Byte 0:    Map ID
  Byte 1:    Map type (0=world, 1=town, 2=dungeon)
  Bytes 2-3: Width (tiles)
  Bytes 4-5: Height (tiles)
  Bytes 6-7: Tileset ID
  Bytes 8-9: Music ID
  Byte 10:   Encounter rate (0-255)
  Byte 11:   Encounter group ID
  Bytes 12-13: Default spawn X
  Bytes 14-15: Default spawn Y
  Byte 16:   Flags
    Bit 0: Enable encounters
    Bit 1: Enable running
    Bit 2: Town (safe area)
    Bit 3: Show minimap
    Bit 4-7: Reserved
  Bytes 17-31: Reserved for future use
```

### Tilemap Data

```
Tilemap Format:
  Each tile: 2 bytes
  
  Byte 0: Tile ID (0-255)
  Byte 1: Attributes
    Bits 0-2: Palette (0-7)
    Bit 3: Priority
    Bit 4: Flip H
    Bit 5: Flip V
    Bit 6-7: Special flags
  
Special Flags:
  00 = Normal tile
  01 = Collision tile
  10 = Event trigger tile
  11 = Reserved
```

### Layer Organization

```
BG1 (Main Layer):
  - Ground tiles
  - Walls and obstacles
  - Decorative elements
  - Primary collision

BG2 (Upper Layer):
  - Roofs and overhangs
  - High priority graphics
  - Special effects
  - Secondary decorations

BG3 (Event Layer):
  - Event triggers (invisible)
  - Warp zones
  - Special collision
  - Region markers
```

## Collision System

### Collision Types

```
Collision Flags (per tile):
  $00 = Walkable
  $01 = Wall (solid)
  $02 = Water (can't walk, can swim)
  $03 = Door (trigger event)
  $04 = Counter (talk over)
  $05 = Pit/Damage (lose HP)
  $06 = Ice (slide)
  $07 = Spikes (damage + knockback)
  $08-$0f = Reserved
  
Directional Collision:
  $10 = Block North
  $20 = Block East
  $40 = Block South
  $80 = Block West
  
Can combine: $c0 = Block South+West
```

### Collision Detection

```asm
; ==============================================================================
; CheckCollision - Test if movement is valid
; ==============================================================================
; Inputs:
;   $00-$01 = Target X position (pixels)
;   $02-$03 = Target Y position (pixels)
; Outputs:
;   Carry = Set if collision, Clear if walkable
; ==============================================================================
CheckCollision:
    ; Convert pixel position to tile coordinates
    lda $01                 ; X high byte
    lsr a                   ; /256
    lsr a                   ; /128
    lsr a                   ; /64
    lsr a                   ; /32
    lsr a                   ; /16
    lsr a                   ; /8 (tile X)
    sta $10
    
    lda $03                 ; Y high byte  
    lsr a
    lsr a
    lsr a
    sta $11                 ; Tile Y
    
    ; Calculate tilemap offset
    ; Offset = (Y × MapWidth) + X
    lda $11
    sta $12
    lda MapWidth
    jsr Multiply8x8         ; A × $12 → $14
    lda $14
    clc
    adc $10
    sta $14                 ; Tilemap offset
    
    ; Read collision byte
    tax
    lda CollisionMap,x      ; Get collision flags
    beq .walkable           ; $00 = no collision
    
    ; Check if it's a special tile
    cmp #$03                ; Door?
    beq .door
    
    cmp #$04                ; Counter?
    beq .counter
    
    ; Solid collision
    sec                     ; Set carry = blocked
    rts
    
.door:
    ; Trigger door event
    jsr TriggerDoorEvent
    clc                     ; Allow walking through
    rts
    
.counter:
    ; Can walk here but can talk over it
    clc
    rts
    
.walkable:
    clc                     ; Clear carry = walkable
    rts
```

### Special Collision Tiles

**Ice Tiles**:
```
When player steps on ice:
1. Continue moving in same direction
2. Slide until hitting non-ice tile
3. Cannot change direction while sliding
4. Can activate events while sliding
```

**Damage Tiles**:
```
Spike/lava tiles:
1. Player takes damage (HP × 5%)
2. Knockback 1 tile
3. Damage sound effect
4. Brief invincibility (1 second)
```

## Event System

### Event Types

```
Event Categories:
  $00 = None
  $01 = NPC dialogue
  $02 = Treasure chest
  $03 = Door/warp
  $04 = Story cutscene
  $05 = Save point
  $06 = Shop
  $07 = Inn
  $08 = Battle trigger (boss)
  $09 = Item acquisition
  $0a = Switch/lever
  $0b = Puzzle element
  $0c-$ff = Custom events
```

### Event Triggers

```
Trigger Methods:

1. Auto-trigger (step on tile)
   - Story events
   - Warp zones
   - Battle triggers

2. Interact trigger (press A)
   - NPCs
   - Chests
   - Signs/objects

3. Conditional trigger
   - Requires item
   - Requires story flag
   - Time-based

4. One-time trigger
   - Sets completion flag
   - Won't trigger again
```

### Event Data Structure

```
Event Entry (16 bytes):
  Bytes 0-1: Event ID
  Bytes 2-3: X position (tile)
  Bytes 4-5: Y position (tile)
  Byte 6: Trigger type
    $00 = Auto (step on)
    $01 = Interact (press A)
    $02 = Conditional
  Byte 7: Event type (dialogue, chest, etc.)
  Bytes 8-9: Event data pointer
  Bytes 10-11: Required flag ID (0 = none)
  Byte 12: Completion flag ID
  Byte 13: Repeat behavior
    $00 = One-time only
    $01 = Repeatable
    $02 = Once per map visit
  Bytes 14-15: Reserved
```

### Event Processing

```asm
; ==============================================================================
; CheckEventTriggers - Check for events at position
; ==============================================================================
; Inputs:
;   $00 = Player X (tiles)
;   $01 = Player Y (tiles)
;   $02 = Trigger type (0=auto, 1=interact)
; ==============================================================================
CheckEventTriggers:
    ; Loop through event table
    ldx #$00
.eventLoop:
    ; Check if event is at player position
    lda EventTableX,x
    cmp $00
    bne .nextEvent
    
    lda EventTableY,x
    cmp $01
    bne .nextEvent
    
    ; Check trigger type matches
    lda EventTableTrigger,x
    cmp $02
    bne .nextEvent
    
    ; Check if already completed
    lda EventTableCompletionFlag,x
    beq .notCompleted
    
    jsr CheckFlag           ; Check if flag is set
    bcs .nextEvent          ; Already done? Skip
    
.notCompleted:
    ; Check required flags
    lda EventTableRequiredFlag,x
    beq .execute            ; No requirement? Execute
    
    jsr CheckFlag
    bcc .nextEvent          ; Requirement not met? Skip
    
.execute:
    ; Execute event
    jsr ExecuteEvent
    
    ; Set completion flag if one-time
    lda EventTableRepeat,x
    bne .done
    
    lda EventTableCompletionFlag,x
    jsr SetFlag
    
.done:
    rts
    
.nextEvent:
    inx
    cpx EventCount
    bcc .eventLoop
    
    rts
```

## NPC System

### NPC Data

```
NPC Entry (32 bytes):
  Bytes 0-1: NPC ID
  Bytes 2-3: X position (pixels)
  Bytes 4-5: Y position (pixels)
  Byte 6: Sprite ID
  Byte 7: Palette
  Byte 8: Movement type
    $00 = Stationary
    $01 = Random walk
    $02 = Patrol path
    $03 = Follow player
    $04 = Flee from player
  Byte 9: Movement speed
  Bytes 10-11: Dialogue pointer
  Byte 12: Direction facing (0-3)
  Byte 13: Animation frame
  Byte 14: Flags
    Bit 0: Enabled
    Bit 1: Interactable
    Bit 2: Block movement
    Bit 3: Show on minimap
  Bytes 15-31: Movement data (path, etc.)
```

### NPC Movement

```
Movement Types:

Stationary:
  - No movement
  - Can face player when talked to
  
Random Walk:
  - Move randomly every N frames
  - Change direction at obstacles
  - Don't walk off map
  
Patrol Path:
  - Follow predefined waypoints
  - Loop or reverse at end
  - Fixed timing between points
  
Follow Player:
  - Move toward player position
  - Stop at certain distance
  - Used for allies/pets
  
Flee from Player:
  - Move away from player
  - Used for scared NPCs
  - Stop at safe distance
```

### NPC Update

```asm
; ==============================================================================
; UpdateNPCs - Update all NPCs on current map
; ==============================================================================
UpdateNPCs:
    ldx #$00
.npcLoop:
    ; Check if NPC is enabled
    lda NPCFlags,x
    and #$01
    beq .nextNPC
    
    ; Get movement type
    lda NPCMovementType,x
    beq .noMovement         ; Stationary
    
    cmp #$01
    beq .randomWalk
    
    cmp #$02
    beq .patrolPath
    
    ; ... handle other movement types
    
.randomWalk:
    ; Decrement movement timer
    dec NPCMoveTimer,x
    bne .nextNPC
    
    ; Reset timer (random interval)
    jsr Random
    and #$3f                ; 0-63 frames
    clc
    adc #$20                ; +32 = 32-95 frames
    sta NPCMoveTimer,x
    
    ; Choose random direction
    jsr Random
    and #$03                ; 0-3 (N,E,S,W)
    sta NPCDirection,x
    
    ; Try to move
    jsr MoveNPC
    
.noMovement:
.nextNPC:
    inx
    cpx NPCCount
    bcc .npcLoop
    
    rts
```

## Door and Warp System

### Warp Types

```
Warp Categories:

1. Doors (building entrances)
   - Same town, different interior
   - Visual fade transition
   - Auto-save after entering
   
2. Stairs (floor changes)
   - Same dungeon, different floor
   - Quick fade
   - Maintain player direction
   
3. World Map Exits
   - Dungeon to world map
   - Place at dungeon entrance
   - Save progress
   
4. Fast Travel
   - Town to town (unlocked)
   - Teleport spell
   - No animation (instant)
```

### Warp Data

```
Warp Entry (16 bytes):
  Bytes 0-1: Warp ID
  Bytes 2-3: Source X (tiles)
  Bytes 4-5: Source Y (tiles)
  Bytes 6-7: Destination map ID
  Bytes 8-9: Destination X (tiles)
  Bytes 10-11: Destination Y (tiles)
  Byte 12: Warp type (see above)
  Byte 13: Direction after warp
  Byte 14: Required key/item (0=none)
  Byte 15: Flags
    Bit 0: Requires interaction (not auto)
    Bit 1: Two-way warp
    Bit 2: Save after warp
```

### Warp Execution

```asm
; ==============================================================================
; ExecuteWarp - Teleport to different map
; ==============================================================================
; Inputs:
;   X = Warp table index
; ==============================================================================
ExecuteWarp:
    ; Check required item
    lda WarpRequiredItem,x
    beq .noRequirement
    
    jsr CheckInventory      ; Do we have it?
    bcc .cantWarp           ; No? Can't warp
    
.noRequirement:
    ; Save warp destination
    lda WarpDestMap,x
    sta $10
    lda WarpDestMap+1,x
    sta $11
    
    lda WarpDestX,x
    sta $12
    lda WarpDestX+1,x
    sta $13
    
    lda WarpDestY,x
    sta $14
    lda WarpDestY+1,x
    sta $15
    
    ; Fade out
    jsr FadeScreen
    
    ; Save game if flag set
    lda WarpFlags,x
    and #$04                ; Save flag?
    beq .noSave
    jsr AutoSaveGame
    
.noSave:
    ; Load new map
    lda $10
    jsr LoadMap
    
    ; Set player position
    lda $12
    sta PlayerX
    lda $13
    sta PlayerX+1
    
    lda $14
    sta PlayerY
    lda $15
    sta PlayerY+1
    
    ; Set facing direction
    lda WarpDirection,x
    sta PlayerDirection
    
    ; Fade in
    jsr UnfadeScreen
    
.cantWarp:
    rts
```

## Treasure and Items

### Treasure Chest System

```
Chest Data (8 bytes):
  Bytes 0-1: Chest ID
  Bytes 2-3: X position (tiles)
  Bytes 4-5: Y position (tiles)
  Byte 6: Contents type
    $00 = Gold
    $01 = Item
    $02 = Equipment
    $03 = Key item
  Byte 7: Contents ID/amount
  
Chest States:
  - Unopened (show closed sprite)
  - Opened (show open sprite, no interaction)
  - Hidden (invisible until flag set)
```

### Opening Chests

```asm
; ==============================================================================
; OpenTreasureChest - Get item from chest
; ==============================================================================
; Inputs:
;   X = Chest index
; ==============================================================================
OpenTreasureChest:
    ; Check if already opened
    lda ChestID,x
    jsr CheckFlag
    bcs .alreadyOpen
    
    ; Mark as opened
    lda ChestID,x
    jsr SetFlag
    
    ; Get contents
    lda ChestContentsType,x
    cmp #$00
    beq .gold
    
    cmp #$01
    beq .item
    
    ; Equipment or key item
    lda ChestContentsID,x
    jsr AddToInventory
    jsr ShowItemGet
    rts
    
.gold:
    ; Add gold
    lda ChestContentsID,x   ; Amount
    clc
    adc PartyGold
    sta PartyGold
    bcc .showGold
    inc PartyGold+1
    
.showGold:
    jsr ShowGoldGet
    rts
    
.item:
    ; Add item
    lda ChestContentsID,x
    jsr AddToInventory
    jsr ShowItemGet
    rts
    
.alreadyOpen:
    ; Already opened, do nothing
    rts
```

### Item Placement

```
Ground Items:
  - Items lying on ground (not in chests)
  - Visible sprite
  - Walk over to collect
  - Usually one-time pickup
  
Hidden Items:
  - Invisible until found
  - Search with special ability
  - Optional collectibles
  - May require specific character
```

## Map Loading

### Map Load Sequence

```
1. Fade screen to black
   ↓
2. Unload current map
   │
   ├─ Free NPC sprites
   ├─ Clear event table
   └─ Reset collision map
   ↓
3. Load new map data
   │
   ├─ Read map header
   ├─ Load tileset graphics
   ├─ Load tilemap data
   └─ Decompress if needed
   ↓
4. Initialize map state
   │
   ├─ Spawn NPCs
   ├─ Setup events
   ├─ Load collision map
   └─ Place treasure chests
   ↓
5. Set player position
   ↓
6. Start music
   ↓
7. Fade screen in
```

### Map Caching

```
Map Cache System:
  - Keep last 3 maps in RAM
  - Fast transitions between cached maps
  - Evict oldest when cache full
  - World map always cached
  
Cache Priority:
  1. Current map
  2. Connected maps (doors/warps)
  3. Recent maps
  4. Important maps (towns)
```

## Code Locations

### Map Engine

**File**: `src/asm/bank_01_documented.asm`

```asm
LoadMap:                    ; Load map data
    ; Located at $01:D000
    
InitializeMap:              ; Setup map state
    ; Located at $01:D123
    
UpdateMap:                  ; Per-frame map update
    ; Located at $01:D234
    
RenderMap:                  ; Draw map to screen
    ; Located at $01:D345
```

### Collision System

**File**: `src/asm/bank_01_documented.asm`

```asm
CheckCollision:             ; Test movement collision
    ; Located at $01:E000
    
GetCollisionTile:           ; Get tile collision data
    ; Located at $01:E123
    
ProcessSpecialTiles:        ; Handle ice, damage, etc.
    ; Located at $01:E234
```

### Event System

**File**: `src/asm/bank_02_documented.asm`

```asm
CheckEventTriggers:         ; Check for events
    ; Located at $02:D000
    
ExecuteEvent:               ; Run event script
    ; Located at $02:D123
    
ProcessDialogue:            ; Show NPC dialogue
    ; Located at $02:D234
```

### NPC System

**File**: `src/asm/bank_02_documented.asm`

```asm
UpdateNPCs:                 ; Update all NPCs
    ; Located at $02:E000
    
MoveNPC:                    ; Move NPC to new position
    ; Located at $02:E123
    
NPCInteraction:             ; Handle talking to NPC
    ; Located at $02:E234
```

### Warp System

**File**: `src/asm/bank_01_documented.asm`

```asm
ExecuteWarp:                ; Teleport to new map
    ; Located at $01:F000
    
CheckWarpTriggers:          ; Check for warp zones
    ; Located at $01:F123
    
LoadMapData:                ; Load map from ROM
    ; Located at $01:F234
```

## Performance Considerations

### Map Rendering

```
Rendering optimizations:
  - Only redraw changed tiles
  - Use tile animation for effects
  - Limit visible area (32×28 tiles)
  - Scroll smoothly (pixel-by-pixel)
  
VBlank usage:
  - Update 4-8 tiles per frame max
  - DMA tilemap changes
  - Batch sprite updates
```

### Memory Management

```
Map RAM usage:
  - Tilemap buffer: 4KB
  - Collision map: 1KB
  - Event table: 512B
  - NPC data: 1KB
  - Warp table: 256B
  
Total: ~7KB per map
```

## Debug Tools

### Map Debugging (Mesen-S)

- **Tilemap Viewer**: See all map layers
- **Memory Viewer**: Inspect collision data
- **Event Viewer**: Track event triggers
- **Debugger**: Breakpoint on collisions

### Debug Commands

```asm
; Disable collision (walk through walls)
DebugNoClip:
    lda #$01
    sta NoClipMode
    rts

; Teleport to coordinates
DebugWarp:
    lda #$20            ; X = 32
    sta PlayerX
    lda #$30            ; Y = 48
    sta PlayerY
    rts
```

## See Also

- **[MODDING_GUIDE.md](MODDING_GUIDE.md#maps-and-levels)** - How to modify maps
- **[data_formats.md](data_formats.md)** - Map data structures
- **[GRAPHICS_SYSTEM.md](GRAPHICS_SYSTEM.md)** - Map rendering

---

**For modding maps**, see [MODDING_GUIDE.md](MODDING_GUIDE.md#maps-and-levels).

**For map data format**, see [data_formats.md](data_formats.md).
