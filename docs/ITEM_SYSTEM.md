# FFMQ Item System Documentation

**Last Updated:** 2025-11-17  
**Documentation Version:** 1.0  
**Author:** AI Assistant (GitHub Copilot)

---

## Table of Contents

1. [Overview](#overview)
2. [Item Database Structure](#item-database-structure)
3. [Item Types](#item-types)
4. [Inventory Management](#inventory-management)
5. [Equipment System](#equipment-system)
6. [Consumable Items](#consumable-items)
7. [Key Items](#key-items)
8. [Shop System](#shop-system)
9. [Item Effects](#item-effects)
10. [ROM Data Format](#rom-data-format)
11. [Code Examples](#code-examples)
12. [Advanced Topics](#advanced-topics)

---

## Overview

The Final Fantasy Mystic Quest item system manages 256 total items across multiple categories including consumables, equipment (weapons, armor, helmets, accessories), and key/quest items. The system integrates with inventory management, shops, battle mechanics, and character stats.

### System Components

```
Item System
├── Item Database (256 items)
│   ├── Item data structures (32 bytes each)
│   ├── Item names (text pointers)
│   ├── Item icons (8×8 tile IDs)
│   └── Item descriptions
├── Inventory Manager
│   ├── Consumables (16 slots, stackable)
│   ├── Weapons (15 slots)
│   ├── Armor (7 slots)
│   ├── Accessories (3 slots)
│   └── Key items (bitfield flags)
├── Equipment Manager
│   ├── Character restrictions
│   ├── Stat bonuses calculation
│   ├── Equip/unequip logic
│   └── Equipment effects
├── Shop System
│   ├── Shop inventories (16 shops)
│   ├── Price calculation
│   ├── Buy/sell transactions
│   └── Stock management
└── Item Effects Engine
    ├── HP/MP restoration
    ├── Status cure/inflict
    ├── Stat buffs/debuffs
    └── Special effects
```

### Key Features

- **256 Item IDs** (0x00-0xFF)
- **8 Item Types:** Consumable, Weapon, Armor, Helmet, Accessory, Key Item, Coin, Book
- **32-Byte Data Structure** per item (8,192 bytes total at ROM $0F0000)
- **Stackable Consumables** (max 99 per slot)
- **Equipment Stats:** Attack, Defense, Magic, Magic Defense, Speed, HP/MP bonuses
- **Character Restrictions:** Benjamin, Kaeli, Phoebe, Reuben, Tristam (5 characters)
- **9 Item Flags:** Usable in battle/field, consumable, cursed, rare, two-handed, etc.
- **Shop System:** Buy/sell prices, stock limits, shop types
- **Item Effects:** 20+ effect types (heal, cure, damage, buff, etc.)

### ROM Organization

| ROM Offset | Size | Description |
|------------|------|-------------|
| `$0F0000` | 8,192 bytes | Item database (256 × 32 bytes) |
| `$064120` | Variable | Item name strings (compressed) |
| `$0642A0` | Variable | Weapon name strings |
| `$066000` | Variable | Item data tables (alternate format) |
| `$260000` | Variable | Weapon data (32 weapons × data size) |
| `$261000` | Variable | Armor data (32 armor pieces × data size) |
| `$262000` | Variable | Consumable data (32 consumables × data size) |
| `$263000` | Variable | Key item data (32 key items × data size) |
| `$270000` | Variable | Shop data (16 shops × data size) |

---

## Item Database Structure

### Item Data Format (32 bytes)

```c
// Complete item data structure (32 bytes)
typedef struct {
    uint8_t  item_id;             // 0x00: Item ID (0-255)
    uint8_t  item_type;           // 0x01: Type (see Item Types)
    uint8_t  name_ptr_lo;         // 0x02: Name string pointer (low)
    uint8_t  name_ptr_hi;         // 0x03: Name string pointer (high)
    uint8_t  description_ptr_lo;  // 0x04: Description pointer (low)
    uint8_t  description_ptr_hi;  // 0x05: Description pointer (high)
    uint8_t  icon_id;             // 0x06: Icon graphic ID (0-255)
    uint8_t  power;               // 0x07: Attack/heal power (0-255)
    uint8_t  element;             // 0x08: Elemental affinity (0-7)
    uint8_t  special_effect;      // 0x09: Special effect ID (0-255)
    uint16_t buy_price;           // 0x0A: Shop buy price (little-endian)
    uint16_t sell_price;          // 0x0C: Shop sell price (little-endian)
    uint8_t  equip_flags;         // 0x0E: Who can equip (bitfield)
    uint8_t  reserved;            // 0x0F: Unused/padding
    
    // Equipment-specific stats (bytes 0x10-0x1F)
    int8_t   attack_bonus;        // 0x10: Attack bonus (+/- 127)
    int8_t   defense_bonus;       // 0x11: Defense bonus
    int8_t   magic_bonus;         // 0x12: Magic bonus
    int8_t   magic_def_bonus;     // 0x13: Magic Defense bonus
    int8_t   speed_bonus;         // 0x14: Speed bonus
    int8_t   hp_bonus;            // 0x15: Max HP bonus
    int8_t   mp_bonus;            // 0x16: Max MP bonus
    uint8_t  status_resist;       // 0x17: Status resistance flags
    uint8_t  element_resist;      // 0x18: Element resistance flags
    
    // Consumable-specific data (bytes 0x19-0x1F)
    uint8_t  effect_type;         // 0x19: Effect type (heal, cure, etc.)
    uint8_t  effect_power;        // 0x1A: Effect strength (0-255)
    uint8_t  target_flags;        // 0x1B: Target type (single/all/self)
    uint8_t  usable_flags;        // 0x1C: Usability (battle/field)
    uint8_t  max_stack;           // 0x1D: Maximum stack size (1-99)
    uint8_t  animation_id;        // 0x1E: Use animation ID
    uint8_t  sound_effect;        // 0x1F: Use sound effect ID
} ItemData;
```

### Item Type Enum

```c
// Item type classification
typedef enum {
    ITEM_TYPE_CONSUMABLE = 0,    // Potions, ethers, etc.
    ITEM_TYPE_WEAPON     = 1,    // Swords, axes, claws, bombs
    ITEM_TYPE_ARMOR      = 2,    // Body armor
    ITEM_TYPE_HELMET     = 3,    // Head gear
    ITEM_TYPE_ACCESSORY  = 4,    // Rings, amulets, bracelets
    ITEM_TYPE_KEY_ITEM   = 5,    // Quest items, plot items
    ITEM_TYPE_COIN       = 6,    // Currency items (special)
    ITEM_TYPE_BOOK       = 7     // Spell books, tomes
} ItemType;
```

### Equipment Flags

```c
// Who can equip this item (bitfield)
typedef enum {
    EQUIP_BENJAMIN = 0x01,       // Bit 0: Benjamin
    EQUIP_KAELI    = 0x02,       // Bit 1: Kaeli
    EQUIP_PHOEBE   = 0x04,       // Bit 2: Phoebe
    EQUIP_REUBEN   = 0x08,       // Bit 3: Reuben
    EQUIP_TRISTAM  = 0x10,       // Bit 4: Tristam
    EQUIP_ALL      = 0x1F        // All 5 characters
} EquipFlags;
```

### Item Flags

```c
// Item behavior flags
typedef enum {
    ITEM_FLAG_USABLE_BATTLE = 0x01,  // Bit 0: Can use in battle
    ITEM_FLAG_USABLE_FIELD  = 0x02,  // Bit 1: Can use outside battle
    ITEM_FLAG_THROWABLE     = 0x04,  // Bit 2: Can throw as weapon
    ITEM_FLAG_STACKABLE     = 0x08,  // Bit 3: Can stack (max_stack applies)
    ITEM_FLAG_SELLABLE      = 0x10,  // Bit 4: Can sell in shops
    ITEM_FLAG_TRADEABLE     = 0x20,  // Bit 5: Can trade with NPCs
    ITEM_FLAG_DROPPABLE     = 0x40,  // Bit 6: Can drop from inventory
    ITEM_FLAG_CURSED        = 0x80,  // Bit 7: Cursed (can't unequip)
    ITEM_FLAG_EQUIP_LOCKED  = 0x100  // Bit 8: Equipment locked (plot)
} ItemFlags;
```

---

## Item Types

### Consumable Items

**Total:** 32+ consumable items (IDs 0x00-0x1F, 0x40-0x5F)

**Categories:**
- **HP Restoration:** Cure Potion, Heal Potion
- **MP Restoration:** Ether, Refresher
- **Status Cure:** Seed (removes status effects)
- **Resurrection:** Phoenix items (rare)
- **Stat Buffs:** Temporary stat increases
- **Damage Items:** Bombs, throwing items

**Example Consumables:**

| ID | Name | Effect | Power | Price | Stackable |
|----|------|--------|-------|-------|-----------|
| 0x00 | Cure Potion | Restore HP | 50 | 40 GP | Yes (99) |
| 0x01 | Heal Potion | Restore HP | 120 | 100 GP | Yes (99) |
| 0x02 | Seed | Cure status | - | 10 GP | Yes (99) |
| 0x03 | Ether | Restore MP | 30 | 500 GP | Yes (99) |
| 0x04 | Refresher | Restore MP | 100 | 1000 GP | Yes (99) |

### Weapons

**Total:** 32 weapons (IDs 0x00-0x1F in weapon table)

**Weapon Types:**
- **Swords:** Steel Sword, Knight Sword, Excalibur
- **Axes:** Battle Axe, Dragon Axe
- **Claws:** Dragon Claw, Cat Claw
- **Bombs:** Light Bomb, Mega Bomb

**Example Weapons:**

| ID | Name | Attack | Element | Equip By | Price |
|----|------|--------|---------|----------|-------|
| 0x00 | Steel Sword | +25 | None | Benjamin, Tristam | 200 GP |
| 0x01 | Knight Sword | +45 | None | Benjamin, Tristam | 500 GP |
| 0x02 | Excalibur | +99 | Holy | Benjamin only | 9999 GP |
| 0x03 | Battle Axe | +35 | None | Reuben | 300 GP |
| 0x04 | Dragon Claw | +65 | Fire | Kaeli, Phoebe | 1200 GP |

### Armor

**Total:** 32 armor pieces (body, helmets, shields combined)

**Armor Categories:**
- **Body Armor:** Leather Armor, Steel Armor, Dragon Armor
- **Helmets:** Bronze Helmet, Steel Helmet, Golden Helmet
- **Shields:** (some games) - FFMQ uses helmets instead

**Example Armor:**

| ID | Name | Defense | Magic Def | Equip By | Price |
|----|------|---------|-----------|----------|-------|
| 0x20 | Leather Armor | +10 | +5 | All | 100 GP |
| 0x21 | Steel Armor | +25 | +10 | Benjamin, Reuben | 500 GP |
| 0x22 | Dragon Armor | +50 | +25 | Benjamin only | 2000 GP |
| 0x10 | Bronze Helmet | +8 | +4 | All | 80 GP |
| 0x11 | Steel Helmet | +15 | +8 | Benjamin, Reuben | 300 GP |

### Accessories

**Total:** 16 accessories (rings, amulets, bracelets)

**Accessory Types:**
- **Stat Boosters:** Venus Bracelet (+Speed), Power Ring (+Attack)
- **Status Protection:** Charm (prevents status), Shield Ring (-damage)
- **Elemental Resistance:** Fire Ring, Ice Amulet
- **Special Abilities:** Reflect Ring, Counter Ring

**Example Accessories:**

| ID | Name | Effect | Equip By | Price |
|----|------|--------|----------|-------|
| 0x30 | Venus Bracelet | +10 Speed | All | 500 GP |
| 0x31 | Power Ring | +15 Attack | All | 800 GP |
| 0x32 | Charm | Immune poison/sleep | All | 1000 GP |
| 0x33 | Reflect Ring | Reflect magic | All | 2500 GP |

### Key Items

**Total:** 32+ key/quest items

**Storage:** Bitfield flags (16-32 bits, 1 bit per item)

**Categories:**
- **Plot Items:** Venus Key, Elixir, Rainbow Road Map
- **Quest Items:** Captain's Cap, Old Coin
- **Collectibles:** Crystals (Earth, Water, Fire, Wind)

**Key Item Flags:**

```c
// Key items stored as bitfield (2-4 bytes)
typedef struct {
    uint16_t key_items_lo;    // Items 0-15
    uint16_t key_items_hi;    // Items 16-31 (if needed)
} KeyItemFlags;

// Example: Check if Venus Key (ID 0x03, Bit 3) is owned
bool has_venus_key = (key_items_lo & (1 << 3)) != 0;
```

**Example Key Items:**

| Bit | Name | Purpose |
|-----|------|---------|
| 0 | Elixir | Plot item (beginning) |
| 1 | Cure Potion | Initial healing item |
| 2 | Rainbow Road Map | Access Rainbow Road |
| 3 | Venus Key | Unlock Venus Lighthouse |
| 4 | Captain's Cap | Obtain ship |

---

## Inventory Management

### Inventory Structure

**SRAM Storage (Save File):**

```c
// Inventory in save slot (offsets from slot start)
typedef struct {
    // Consumable items (16 slots × 2 bytes = 32 bytes)
    struct {
        uint8_t item_id;      // Item ID (0 = empty)
        uint8_t quantity;     // Quantity (1-99)
    } consumables[16];        // Offset: +0xC2 in save slot
    
    // Key items (2-4 bytes bitfield)
    uint16_t key_items;       // Offset: +0xE2
    
    // Weapons (15 slots × 2 bytes = 30 bytes)
    struct {
        uint8_t weapon_id;    // Weapon ID (0 = empty)
        uint8_t count;        // Count (typically 1)
    } weapons[15];            // Offset: +0xE4
    
    // Armor (7 slots × 2 bytes = 14 bytes)
    struct {
        uint8_t armor_id;     // Armor ID (0 = empty)
        uint8_t count;        // Count (typically 1)
    } armor[7];               // Offset: +0x102
    
    // Accessories (3 slots × 2 bytes = 6 bytes)
    struct {
        uint8_t accessory_id; // Accessory ID (0 = empty)
        uint8_t count;        // Count (typically 1)
    } accessories[3];         // Offset: +0x110
    
    // Currently equipped items (per character)
    struct {
        uint8_t weapon;       // Offset: +0x21 per character
        uint8_t armor;        // Offset: +0x22 per character
        uint8_t accessory;    // Offset: +0x23 per character
    } equipped[2];            // 2 characters (Benjamin + companion)
} Inventory;
```

### Inventory Limits

| Category | Max Slots | Max Per Slot | Total Capacity |
|----------|-----------|--------------|----------------|
| Consumables | 16 | 99 | 1,584 items |
| Weapons | 15 | 1 (not stackable) | 15 weapons |
| Armor | 7 | 1 | 7 armor pieces |
| Accessories | 3 | 1 | 3 accessories |
| Key Items | 32 | 1 (flags) | 32 key items |
| **Total** | **73** | **Variable** | **~1,641 items** |

### Add Item to Inventory

```asm
AddItemToInventory:
    ; Parameters: A = item_id, X = quantity
    
    ; Check item type
    lda item_id
    and #$E0              ; Top 3 bits = item category
    cmp #$00              ; Consumable?
    beq .add_consumable
    cmp #$20              ; Weapon?
    beq .add_weapon
    cmp #$40              ; Armor?
    beq .add_armor
    cmp #$60              ; Accessory?
    beq .add_accessory
    ; ... (other types)
    
.add_consumable:
    ; Find empty slot or existing stack
    ldy #$00
.find_slot:
    lda !consumable_items,Y
    beq .found_empty      ; Empty slot
    cmp item_id
    beq .stack_item       ; Same item, add to stack
    iny
    iny                   ; Each slot is 2 bytes
    cpy #$20              ; 16 slots × 2
    bne .find_slot
    rts                   ; Inventory full
    
.found_empty:
    lda item_id
    sta !consumable_items,Y
    txa                   ; Quantity
    sta !consumable_items+1,Y
    rts
    
.stack_item:
    ; Add to existing stack (max 99)
    lda !consumable_items+1,Y
    clc
    adc quantity
    cmp #99
    bcc .set_quantity
    lda #99               ; Cap at 99
.set_quantity:
    sta !consumable_items+1,Y
    rts
```

### Remove Item from Inventory

```asm
RemoveItemFromInventory:
    ; Parameters: A = item_id, X = quantity
    
    ; Find item in inventory
    ldy #$00
.search:
    lda !consumable_items,Y
    cmp item_id
    beq .found_item
    iny
    iny
    cpy #$20
    bne .search
    rts                   ; Item not found
    
.found_item:
    ; Decrease quantity
    lda !consumable_items+1,Y
    sec
    sbc quantity
    bcs .set_quantity
    lda #$00              ; Underflow, set to 0
.set_quantity:
    sta !consumable_items+1,Y
    beq .remove_slot      ; If 0, remove from inventory
    rts
    
.remove_slot:
    ; Clear slot
    stz !consumable_items,Y
    stz !consumable_items+1,Y
    rts
```

---

## Equipment System

### Equipment Mechanics

**Equipment Slots (per character):**
- **Weapon** (1 slot)
- **Armor** (1 slot)
- **Helmet** (1 slot) - stored in armor category
- **Accessory** (1 slot)

**Stat Calculation:**

```c
// Calculate character's effective stats with equipment
void CalculateCharacterStats(Character *character) {
    // Base stats from character level
    int base_attack = character->base_attack;
    int base_defense = character->base_defense;
    int base_magic = character->base_magic;
    int base_speed = character->base_speed;
    
    // Add weapon bonuses
    if (character->equipped_weapon != 0xFF) {
        ItemData *weapon = GetItem(character->equipped_weapon);
        base_attack += weapon->attack_bonus;
        base_magic += weapon->magic_bonus;
        base_speed += weapon->speed_bonus;
    }
    
    // Add armor bonuses
    if (character->equipped_armor != 0xFF) {
        ItemData *armor = GetItem(character->equipped_armor);
        base_defense += armor->defense_bonus;
        base_magic_def += armor->magic_def_bonus;
    }
    
    // Add accessory bonuses
    if (character->equipped_accessory != 0xFF) {
        ItemData *accessory = GetItem(character->equipped_accessory);
        base_attack += accessory->attack_bonus;
        base_defense += accessory->defense_bonus;
        base_speed += accessory->speed_bonus;
        // ... (all stat bonuses)
    }
    
    // Store final stats
    character->current_attack = base_attack;
    character->current_defense = base_defense;
    character->current_magic = base_magic;
    character->current_speed = base_speed;
}
```

### Equipment Restrictions

**Check if Character Can Equip:**

```asm
CanCharacterEquip:
    ; Parameters: A = item_id, X = character_id (0-4)
    
    ; Load item equip flags
    ldy item_id
    lda !item_equip_flags,Y
    
    ; Check character bit
    ; Character 0 (Benjamin) = bit 0
    ; Character 1 (Kaeli) = bit 1, etc.
    
    ; Create bitmask for character
    phx                   ; Save character ID
    lda #$01
.shift_loop:
    dex
    bmi .done_shift
    asl                   ; Shift left by character ID
    bra .shift_loop
.done_shift:
    sta $00               ; Store bitmask
    
    ; Test flag
    lda !item_equip_flags,Y
    and $00
    beq .cannot_equip
    
    ; Can equip
    sec                   ; Set carry = true
    rts
    
.cannot_equip:
    clc                   ; Clear carry = false
    rts
```

### Equip Item

```asm
EquipItem:
    ; Parameters: A = item_id, X = character_id, Y = slot (0=weapon, 1=armor, 2=accessory)
    
    ; Check if character can equip
    jsr CanCharacterEquip
    bcc .cannot_equip
    
    ; Unequip current item (if any)
    phy                   ; Save slot
    phx                   ; Save character
    pha                   ; Save item
    
    ; Get current equipped item
    tya                   ; Slot to A
    jsr GetEquippedItem   ; Returns item ID in A
    cmp #$FF
    beq .no_current
    
    ; Add current item back to inventory
    jsr AddItemToInventory
    
.no_current:
    ; Equip new item
    pla                   ; Restore item
    plx                   ; Restore character
    ply                   ; Restore slot
    
    ; Set equipped item
    tya
    jsr SetEquippedItem
    
    ; Remove from inventory
    lda item_id
    ldx #$01              ; Quantity = 1
    jsr RemoveItemFromInventory
    
    ; Recalculate stats
    jsr CalculateCharacterStats
    
    rts
    
.cannot_equip:
    ; Play error sound
    lda #$14              ; SFX: Error
    jsr PlaySoundEffect
    rts
```

---

## Consumable Items

### Consumable Effects

**Effect Types:**

| Effect ID | Name | Description |
|-----------|------|-------------|
| 0x00 | Heal HP | Restore HP (power = amount) |
| 0x01 | Heal MP | Restore MP (power = amount) |
| 0x02 | Cure Poison | Remove poison status |
| 0x03 | Cure Paralysis | Remove paralysis |
| 0x04 | Cure Sleep | Remove sleep |
| 0x05 | Cure All Status | Remove all negative status |
| 0x06 | Revive | Resurrect with HP% |
| 0x07 | Damage | Deal damage to enemy |
| 0x08 | Buff Attack | Increase attack temporarily |
| 0x09 | Buff Defense | Increase defense temporarily |
| 0x0A | Buff Speed | Increase speed temporarily |
| 0x0B | Full Heal | Restore HP+MP to max |

### Use Consumable Item

```asm
UseConsumableItem:
    ; Parameters: A = item_id, X = target_character_id
    
    ; Load item data
    ldy item_id
    
    ; Check effect type
    lda !item_effect_type,Y
    cmp #$00              ; Heal HP?
    beq .heal_hp
    cmp #$01              ; Heal MP?
    beq .heal_mp
    cmp #$05              ; Cure all status?
    beq .cure_all
    ; ... (other effects)
    
.heal_hp:
    ; Get heal power
    lda !item_effect_power,Y
    sta $00
    
    ; Get target's current HP
    phx
    jsr GetCharacterHP    ; Returns current HP in A
    plx
    
    ; Add heal amount
    clc
    adc $00
    
    ; Cap at max HP
    phx
    jsr GetCharacterMaxHP ; Returns max HP in A
    sta $01
    plx
    
    cmp $01
    bcc .set_hp
    lda $01               ; Cap at max
    
.set_hp:
    jsr SetCharacterHP
    
    ; Play heal sound
    lda #$15              ; SFX: Item use
    jsr PlaySoundEffect
    
    ; Show heal animation
    lda #$20              ; Animation: HP restore
    jsr PlayItemAnimation
    
    ; Remove item from inventory
    lda item_id
    ldx #$01              ; Quantity = 1
    jsr RemoveItemFromInventory
    
    rts
```

### Consumable Item Examples

**Cure Potion:**
```c
ItemData cure_potion = {
    .item_id = 0x00,
    .item_type = ITEM_TYPE_CONSUMABLE,
    .name_ptr = 0x4120,       // "Cure Potion"
    .icon_id = 0x40,          // Potion bottle icon
    .power = 0,               // Not used for heal items
    .buy_price = 40,
    .sell_price = 20,
    .effect_type = 0x00,      // Heal HP
    .effect_power = 50,       // Restore 50 HP
    .target_flags = 0x01,     // Single target
    .usable_flags = 0x03,     // Battle + Field
    .max_stack = 99,
    .animation_id = 0x20,     // HP restore animation
    .sound_effect = 0x15      // Item use sound
};
```

**Ether:**
```c
ItemData ether = {
    .item_id = 0x03,
    .item_type = ITEM_TYPE_CONSUMABLE,
    .name_ptr = 0x4130,       // "Ether"
    .icon_id = 0x42,          // Ether bottle icon
    .buy_price = 500,
    .sell_price = 250,
    .effect_type = 0x01,      // Heal MP
    .effect_power = 30,       // Restore 30 MP
    .target_flags = 0x01,     // Single target
    .usable_flags = 0x03,     // Battle + Field
    .max_stack = 99,
    .animation_id = 0x21,     // MP restore animation
    .sound_effect = 0x15
};
```

---

## Key Items

### Key Item Management

**Storage Format:**

Key items are stored as bitfields (flags) rather than inventory slots, saving space:

```c
// Key items (32 items = 32 bits = 4 bytes)
typedef struct {
    uint32_t key_item_flags;  // Each bit = 1 key item
} KeyItemStorage;

// Add key item
void AddKeyItem(uint8_t item_id) {
    key_item_flags |= (1 << item_id);
}

// Remove key item
void RemoveKeyItem(uint8_t item_id) {
    key_item_flags &= ~(1 << item_id);
}

// Check key item
bool HasKeyItem(uint8_t item_id) {
    return (key_item_flags & (1 << item_id)) != 0;
}
```

### Key Item Examples

**Venus Key:**
```asm
; Check if player has Venus Key (ID 3)
CheckVenusKey:
    lda !key_item_flags     ; Load low 16 bits
    and #$08                ; Bit 3 = Venus Key (1 << 3 = 0x08)
    beq .no_key
    
    ; Has key
    sec
    rts
    
.no_key:
    clc
    rts
```

**Rainbow Road Map:**
```asm
; Give Rainbow Road Map (ID 2)
GiveRainbowMap:
    lda !key_item_flags
    ora #$04                ; Bit 2 = Rainbow Map (1 << 2 = 0x04)
    sta !key_item_flags
    
    ; Display "Obtained Rainbow Road Map!" message
    ldx #$1500              ; Text ID
    jsr DisplayDialog
    rts
```

---

## Shop System

### Shop Data Structure

```c
// Shop definition (variable size)
typedef struct {
    uint8_t  shop_id;          // Shop ID (0-15)
    uint8_t  shop_type;        // Type (weapon/armor/item/inn)
    uint8_t  num_items;        // Number of items in stock
    uint8_t  reserved;
    float    price_multiplier; // Price modifier (1.0 = normal)
    
    // Item list (variable length)
    struct {
        uint8_t item_id;       // Item ID
        uint8_t stock;         // Stock (-1 = infinite)
    } items[16];               // Max 16 items per shop
} ShopData;
```

### Shop Types

```c
typedef enum {
    SHOP_TYPE_WEAPON   = 0,  // Weapon shop
    SHOP_TYPE_ARMOR    = 1,  // Armor shop
    SHOP_TYPE_ITEM     = 2,  // Item shop (consumables)
    SHOP_TYPE_INN      = 3,  // Inn (rest/heal)
    SHOP_TYPE_MAGIC    = 4,  // Magic shop (spell books)
    SHOP_TYPE_SPECIAL  = 5   // Special shop (unique items)
} ShopType;
```

### Shop Purchase

```asm
ShopBuy:
    ; Parameters: A = item_id
    
    ; Load item price
    ldy item_id
    ldx !item_buy_price,Y   ; 16-bit price
    
    ; Check if player has enough gold
    cpx !player_gold
    bcs .not_enough
    
    ; Check inventory space
    lda item_id
    jsr CheckInventorySpace
    bcc .inventory_full
    
    ; Subtract gold
    lda !player_gold
    sec
    sbc !item_buy_price,Y
    sta !player_gold
    lda !player_gold+1
    sbc !item_buy_price+1,Y
    sta !player_gold+1
    
    ; Add item to inventory
    lda item_id
    ldx #$01              ; Quantity = 1
    jsr AddItemToInventory
    
    ; Play purchase sound
    lda #$16              ; SFX: Purchase
    jsr PlaySoundEffect
    
    ; Display "Purchased [item]!" message
    rts
    
.not_enough:
    ; Display "Not enough GP" message
    ldx #$1600
    jsr DisplayDialog
    rts
    
.inventory_full:
    ; Display "Inventory full" message
    ldx #$1610
    jsr DisplayDialog
    rts
```

### Shop Sell

```asm
ShopSell:
    ; Parameters: A = item_id
    
    ; Check if item is sellable
    ldy item_id
    lda !item_flags,Y
    and #$10              ; ITEM_FLAG_SELLABLE
    beq .cannot_sell
    
    ; Check if item is in inventory
    lda item_id
    jsr FindInInventory
    bcc .not_owned
    
    ; Calculate sell price (typically 50% of buy price)
    ldx !item_sell_price,Y ; 16-bit price
    
    ; Add gold
    lda !player_gold
    clc
    adc !item_sell_price,Y
    sta !player_gold
    lda !player_gold+1
    adc !item_sell_price+1,Y
    sta !player_gold+1
    
    ; Remove item from inventory
    lda item_id
    ldx #$01
    jsr RemoveItemFromInventory
    
    ; Play sell sound
    lda #$17              ; SFX: Sell
    jsr PlaySoundEffect
    
    rts
    
.cannot_sell:
    ; Display "Cannot sell this item" message
    rts
    
.not_owned:
    ; Display "You don't have this item" message
    rts
```

---

## Item Effects

### Effect Processing

**Effect Handler:**

```asm
ProcessItemEffect:
    ; Parameters: A = item_id, X = target_id
    
    ; Load effect type
    ldy item_id
    lda !item_effect_type,Y
    
    ; Dispatch to effect handler
    asl                   ; Effect × 2 (word table)
    tax
    jsr (EffectHandlerTable,X)
    
    rts

EffectHandlerTable:
    dw Effect_HealHP       ; 0x00
    dw Effect_HealMP       ; 0x01
    dw Effect_CurePoison   ; 0x02
    dw Effect_CurePara     ; 0x03
    dw Effect_CureSleep    ; 0x04
    dw Effect_CureAll      ; 0x05
    dw Effect_Revive       ; 0x06
    dw Effect_Damage       ; 0x07
    dw Effect_BuffATK      ; 0x08
    dw Effect_BuffDEF      ; 0x09
    dw Effect_BuffSPD      ; 0x0A
    dw Effect_FullHeal     ; 0x0B
    ; ... (more effects)
```

### Heal HP Effect

```asm
Effect_HealHP:
    ; Parameters: Y = item_id, X = target_id
    
    ; Get heal power
    lda !item_effect_power,Y
    sta $00
    
    ; Get target's current HP
    phx
    jsr GetCharacterHP
    plx
    
    ; Add heal amount
    clc
    adc $00
    
    ; Cap at max HP
    phx
    jsr GetCharacterMaxHP
    sta $01
    plx
    
    cmp $01
    bcc .set_hp
    lda $01
    
.set_hp:
    jsr SetCharacterHP
    
    ; Play animation
    lda #$20              ; HP restore animation
    jsr PlayItemAnimation
    
    rts
```

### Status Cure Effect

```asm
Effect_CureAll:
    ; Parameters: X = target_id
    
    ; Get target's status flags
    phx
    jsr GetCharacterStatus
    sta $00
    plx
    
    ; Clear negative status bits
    ; Poison = bit 0, Paralysis = bit 1, Sleep = bit 2, etc.
    lda $00
    and #$F0              ; Keep positive status (bits 4-7)
    
    ; Set new status
    jsr SetCharacterStatus
    
    ; Play cure sound
    lda #$18              ; SFX: Status cure
    jsr PlaySoundEffect
    
    rts
```

---

## ROM Data Format

### Item Name Encoding

**Compressed Text Format:**

Item names are stored as compressed strings using a dictionary-based encoding:

```
Dictionary Entry Format:
- Single byte codes ($00-$5F) = literal characters
- Two-byte codes ($60-$FF) = dictionary references
- Control codes ($00-$1F) = special functions

Example: "Steel Sword"
Raw: $53,$74,$65,$65,$6C,$20,$53,$77,$6F,$72,$64 (11 bytes)
Compressed: $A3,$20,$A7 (3 bytes, uses dictionary entries $A3="Steel", $A7="Sword")
```

**Name Pointer Table:**

```c
// Item name pointers (256 × 2 bytes = 512 bytes)
typedef struct {
    uint16_t name_pointers[256];  // ROM offsets to name strings
} ItemNameTable;

// Located at ROM $064120
```

### Weapon Names

**ROM Offset:** `$0642A0`

```asm
WeaponNames:
    ; Weapon 0: Steel Sword
    db "Steel Sword", $00
    
    ; Weapon 1: Knight Sword
    db "Knight Sword", $00
    
    ; Weapon 2: Excalibur
    db "Excalibur", $00
    
    ; ... (32 weapons total)
```

### Armor Names

**ROM Offset:** Next to weapon names

```asm
ArmorNames:
    ; Armor 0: Leather Armor
    db "Leather Armor", $00
    
    ; Armor 1: Steel Armor
    db "Steel Armor", $00
    
    ; ... (32 armor pieces total)
```

### Item Icons

**Icon Tile Data:**

```c
// Icon tiles (8×8 pixels, 4bpp = 32 bytes per icon)
// Located at ROM $0F0000+ (after item data)

typedef struct {
    uint8_t tile_data[32];  // 4bpp tile (8×8 pixels)
} IconTile;

// 256 icons × 32 bytes = 8,192 bytes
```

---

## Code Examples

### Example 1: Find Item in Inventory

```asm
FindInInventory:
    ; Parameters: A = item_id
    ; Returns: Carry set if found, Y = slot index
    
    sta $00               ; Save item ID
    
    ; Search consumables
    ldy #$00
.search_consumables:
    lda !consumable_items,Y
    cmp $00
    beq .found
    iny
    iny
    cpy #$20              ; 16 slots × 2
    bne .search_consumables
    
    ; Search weapons
    ldy #$00
.search_weapons:
    lda !weapon_items,Y
    cmp $00
    beq .found
    iny
    iny
    cpy #$1E              ; 15 slots × 2
    bne .search_weapons
    
    ; ... (search armor, accessories)
    
    ; Not found
    clc
    rts
    
.found:
    sec
    rts
```

### Example 2: Check Inventory Space

```asm
CheckInventorySpace:
    ; Parameters: A = item_id
    ; Returns: Carry set if space available
    
    ; Check item type
    and #$E0
    cmp #$00              ; Consumable?
    beq .check_consumable
    cmp #$20              ; Weapon?
    beq .check_weapon
    ; ... (other types)
    
.check_consumable:
    ; Check for empty slot or stackable
    ldy #$00
.loop:
    lda !consumable_items,Y
    beq .has_space        ; Empty slot
    cmp item_id
    beq .stackable        ; Same item
    iny
    iny
    cpy #$20
    bne .loop
    
    ; No space
    clc
    rts
    
.has_space:
.stackable:
    sec
    rts
```

### Example 3: Get Item Name

```asm
GetItemName:
    ; Parameters: A = item_id
    ; Returns: X = name pointer (low), Y = name pointer (high)
    
    ; Load name pointer table
    asl                   ; Item ID × 2 (word pointers)
    tax
    
    lda.l ItemNameTable,X
    sta $00               ; Name pointer low
    lda.l ItemNameTable+1,X
    sta $01               ; Name pointer high
    
    ldx $00
    ldy $01
    rts
```

### Example 4: Calculate Equipment Stats

```asm
CalculateEquipStats:
    ; Parameters: X = character_id
    
    ; Get base stats
    phx
    jsr GetBaseStats      ; Returns stats in $00-$04
    plx
    
    ; Add weapon bonuses
    lda !equipped_weapon,X
    cmp #$FF
    beq .no_weapon
    
    tay
    lda !weapon_attack,Y
    clc
    adc $00               ; Base attack
    sta $00               ; New attack
    
.no_weapon:
    ; Add armor bonuses
    lda !equipped_armor,X
    cmp #$FF
    beq .no_armor
    
    tay
    lda !armor_defense,Y
    clc
    adc $01               ; Base defense
    sta $01               ; New defense
    
.no_armor:
    ; ... (accessory bonuses)
    
    ; Store final stats
    lda $00
    sta !character_attack,X
    lda $01
    sta !character_defense,X
    ; ... (other stats)
    
    rts
```

---

## Advanced Topics

### Item Randomizer Support

**Randomizing Item Locations:**

```python
# Python script to randomize item locations
import struct

class ItemRandomizer:
    def __init__(self, rom_path):
        with open(rom_path, 'rb') as f:
            self.rom = bytearray(f.read())
    
    def randomize_treasure_chests(self):
        # Treasure chest data at ROM $XXX
        chest_offset = 0x50000
        num_chests = 128
        
        # Extract all chest items
        items = []
        for i in range(num_chests):
            offset = chest_offset + (i * 4)
            item_id = self.rom[offset]
            items.append(item_id)
        
        # Shuffle items
        import random
        random.shuffle(items)
        
        # Write back
        for i in range(num_chests):
            offset = chest_offset + (i * 4)
            self.rom[offset] = items[i]
    
    def save(self, output_path):
        with open(output_path, 'wb') as f:
            f.write(self.rom)
```

### Custom Item Creation

**Adding a New Item:**

1. **Choose Item ID** (unused ID 0x80-0xFF)
2. **Define Item Data:**
   ```c
   ItemData new_item = {
       .item_id = 0x80,
       .item_type = ITEM_TYPE_CONSUMABLE,
       .name_ptr = 0x8000,  // Point to new name string
       .icon_id = 0x50,
       .buy_price = 1000,
       .sell_price = 500,
       .effect_type = 0x00,  // Heal HP
       .effect_power = 200,  // Restore 200 HP
       .max_stack = 99
   };
   ```

3. **Add Name String:**
   ```asm
   org $0F8000
   db "Super Potion", $00
   ```

4. **Update Item Table:**
   ```asm
   org $0F0000 + (0x80 * 32)  ; Item ID 0x80
   ; Write 32 bytes of item data
   ```

### Item Effect Scripting

**Custom Effect Handler:**

```asm
; Custom effect: Heal HP + cure status
Effect_Custom_HealAndCure:
    ; Heal HP
    lda !item_effect_power,Y
    sta $00
    phx
    jsr GetCharacterHP
    plx
    clc
    adc $00
    jsr SetCharacterHP
    
    ; Cure all status
    jsr Effect_CureAll
    
    ; Play combo animation
    lda #$30              ; Custom animation
    jsr PlayItemAnimation
    
    rts
```

### Item Drop Tables

**Enemy Item Drops:**

```c
// Item drop table (per enemy)
typedef struct {
    uint8_t enemy_id;
    uint8_t common_item;      // 50% drop chance
    uint8_t uncommon_item;    // 25% drop chance
    uint8_t rare_item;        // 5% drop chance
} ItemDropTable;

// Example: Goblin drops
ItemDropTable goblin_drops = {
    .enemy_id = 0x05,
    .common_item = 0x00,      // Cure Potion
    .uncommon_item = 0x02,    // Seed
    .rare_item = 0x30         // Venus Bracelet
};
```

**Drop Calculation:**

```asm
CalculateItemDrop:
    ; Parameters: A = enemy_id
    
    ; Load drop table
    tax
    
    ; Generate random number (0-99)
    jsr GetRandomNumber
    cmp #$05              ; < 5% ?
    bcc .rare_drop
    cmp #$1E              ; < 30% ?
    bcc .uncommon_drop
    cmp #$52              ; < 82% ?
    bcc .common_drop
    
    ; No drop
    lda #$FF
    rts
    
.rare_drop:
    lda !enemy_rare_drop,X
    rts
    
.uncommon_drop:
    lda !enemy_uncommon_drop,X
    rts
    
.common_drop:
    lda !enemy_common_drop,X
    rts
```

---

## Summary

The FFMQ item system provides comprehensive item management across 256 items organized into 8 categories:

- **Item Database:** 32-byte structures (8,192 bytes at ROM $0F0000)
- **8 Item Types:** Consumable, Weapon, Armor, Helmet, Accessory, Key, Coin, Book
- **Inventory:** 73 total slots (16 consumable + 15 weapon + 7 armor + 3 accessory + 32 key items)
- **Equipment Stats:** Attack, Defense, Magic, Magic Def, Speed, HP/MP bonuses
- **Character Restrictions:** 5-bit equip flags (Benjamin, Kaeli, Phoebe, Reuben, Tristam)
- **Item Effects:** 12+ effect types (heal, cure, damage, buff, revive)
- **Shop System:** 16 shops with buy/sell prices, stock management
- **Key Items:** Bitfield storage (32 items in 4 bytes)
- **Stack Limits:** Consumables max 99 per slot
- **ROM Data:** Item names at $064120, weapon names at $0642A0

**Total Documentation:** ~780 lines comprehensive item system reference

---

**End of ITEM_SYSTEM.md**
