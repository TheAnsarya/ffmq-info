# GitHub Issues to Create - Based on FFMQ Randomizer Research

This document lists all GitHub issues that should be created to expand our data extraction capabilities based on findings from the FFMQ Randomizer codebase.

**Project Management:** All issues are tracked in [GitHub Project #3](https://github.com/users/TheAnsarya/projects/3)

## High Priority Issues

### Issue 1: Add Enemy Data Extraction Tool
**Title:** Add enemy stats data extraction tool (ROM $C275)  
**Priority:** High  
**Estimated Time:** 4-6 hours  
**Labels:** enhancement, data-extraction, research  

**Description:**
Create a comprehensive enemy data extraction tool based on FFMQ Randomizer findings.

**ROM Location:**
- Address: $C275 (Bank $02, File address $0C275)
- Entry Size: 14 bytes
- Entry Count: 83 enemies (0x53)

**Data Structure:**
```
Byte 0-1: HP (2 bytes, little endian)
Byte 2: Attack
Byte 3: Defense
Byte 4: Speed
Byte 5: Magic
Byte 6-7: Resistances (2 bytes, bitfield)
Byte 8: Magic Defense
Byte 9: Magic Evade
Byte 10: Accuracy
Byte 11: Evade
Byte 12: Weaknesses (1 byte, bitfield)
Byte 13: Special byte (unknown purpose)
```

**Related Data:**
- Enemy IDs: 83 enemies from Brownie (0x00) to DarkKingSpider (0x52)
- Level/Multiplier data: Bank $02, offset $C17C, 3 bytes per enemy
  - Byte 0: Level
  - Byte 1: XP Multiplier
  - Byte 2: GP Multiplier

**Deliverables:**
- [ ] Create `tools/extraction/extract_enemies.py`
- [ ] Extract HP, stats, resistances, weaknesses
- [ ] Decode element type bitfields for resistances/weaknesses
- [ ] Include level/multiplier data
- [ ] Export to CSV and JSON
- [ ] Create `data/extracted/enemies/` directory
- [ ] Update documentation

**Reference:**
- FFMQ Randomizer: `FFMQRLib/Enemies.cs`
- External references: docs/EXTERNAL_REFERENCES.md

---

### Issue 2: Add Attack Data Extraction Tool
**Title:** Add attack/battle action data extraction tool (ROM $BC78)  
**Priority:** High  
**Estimated Time:** 3-5 hours  
**Labels:** enhancement, data-extraction, research  

**Description:**
Create attack data extraction tool for all battle actions (player, companion, and enemy attacks).

**ROM Location:**
- Address: $BC78 (Bank $02, File address $0BC78)
- Entry Size: 7 bytes
- Entry Count: 169 attacks

**Data Structure:**
```
Byte 0: Unknown1 (targeting?)
Byte 1: Unknown2 
Byte 2: Power
Byte 3: Attack Type
Byte 4: Attack Sound
Byte 5: Unknown3
Byte 6: Attack Target Animation
```

**Attack Categories:**
- Player spells: 0x14-0x1F (Exit through Flare)
- Player weapons: 0x20-0x3F
- Enemy attacks: 0x40-0xFF

**Deliverables:**
- [ ] Create `tools/extraction/extract_attacks.py`
- [ ] Extract all 169 attack entries
- [ ] Map attack IDs to names (from randomizer)
- [ ] Include power, type, sound, animation
- [ ] Export to CSV and JSON
- [ ] Create `data/extracted/attacks/` directory
- [ ] Cross-reference with spell data

**Reference:**
- FFMQ Randomizer: `FFMQRLib/Enemizer.cs`, `FFMQRLib/battlesim/BattleSimulator.cs`
- Battle actions dictionary: 400+ entries with names, power, elements

---

### Issue 3: Add Enemy Attack Links Extraction
**Title:** Extract enemy attack link data (ROM $C6FF)  
**Priority:** Medium  
**Estimated Time:** 2-3 hours  
**Labels:** enhancement, data-extraction, research  

**Description:**
Extract the data that links enemies to their available attack patterns.

**ROM Location:**
- Address: $C6FF (Bank $02, File address $0C6FF)
- Entry Size: 9 bytes
- Entry Count: 82 entries

**Data Structure:**
```
Byte 0: Unknown
Byte 1-6: Attack IDs (6 possible attacks per enemy)
Byte 7-8: Unknown (possibly AI flags or probabilities)
```

**Purpose:**
Links enemy IDs to their available attacks, determining what actions each enemy can use in battle.

**Deliverables:**
- [ ] Create `tools/extraction/extract_enemy_attack_links.py`
- [ ] Extract all 82 enemy attack link entries
- [ ] Map to enemy IDs
- [ ] Map to attack IDs (from attack extraction)
- [ ] Export to CSV and JSON
- [ ] Create visualization of enemy → attacks relationships

**Reference:**
- FFMQ Randomizer: `FFMQRLib/Enemizer.cs` (EnemiesAttackLinksAddress)
- docs/tables.md: Attack General Info table

---

## Medium Priority Issues

### Issue 4: Document Comprehensive Element Type System
**Title:** Add comprehensive element type definitions to all schemas  
**Priority:** Medium  
**Estimated Time:** 2-3 hours  
**Labels:** documentation, schema, enhancement  

**Description:**
Update all data schemas with complete element type bitfield definitions from FFMQ Randomizer.

**Element Types (Bitfield 0x0001-0x8000):**

**Status Effects:**
- 0x0001: Silence
- 0x0002: Blind
- 0x0004: Poison
- 0x0008: Confusion
- 0x0010: Sleep
- 0x0020: Paralysis
- 0x0040: Stone
- 0x0080: Doom

**Damage Types:**
- 0x0100: Projectile
- 0x0200: Bomb
- 0x0400: Axe
- 0x0800: Zombie

**Elements:**
- 0x1000: Air
- 0x2000: Fire
- 0x4000: Water
- 0x8000: Earth

**Deliverables:**
- [ ] Create `data/schemas/element_types.json`
- [ ] Update `data/schemas/spells_schema.json` with element types
- [ ] Update `data/schemas/enemies_schema.json` (when created)
- [ ] Update `data/schemas/attacks_schema.json` (when created)
- [ ] Add element type reference documentation
- [ ] Update extraction tools to use canonical element type names

**Reference:**
- FFMQ Randomizer: `FFMQRLib/Enemies.cs` (ElementsType enum)

---

### Issue 5: Add Battle Mechanics Documentation
**Title:** Document battle mechanics and damage formulas  
**Priority:** Medium  
**Estimated Time:** 3-4 hours  
**Labels:** documentation, research, game-mechanics  

**Description:**
Create comprehensive documentation of FFMQ battle mechanics based on randomizer implementation.

**Topics to Cover:**

1. **Damage Formulas:**
   - Physical damage: Varies by routine (PhysicalDamage1-9)
   - Magic damage: MagicDamage2 = Power × 3, MagicDamage3 = Power × 9
   - Pure damage: Direct damage (no modifiers)

2. **Action Routines:**
   - None, Punch, Sword, Axe, Claw, Bomb, Projectile
   - MagicDamage1, MagicDamage2, MagicDamage3
   - Life, Heal, Cure
   - PhysicalDamage1-9
   - SelfDestruct, Multiply, Seed
   - PureDamage1, PureDamage2

3. **Resistance/Weakness:**
   - Resistance: Halves damage (reverses for Zombie)
   - Weakness: Doubles damage
   - Element matching logic

4. **Targeting Types:**
   - SingleEnemy, MultipleEnemy, SelectionEnemy
   - SingleAlly, MultipleAlly, SelectionAlly
   - SingleAny, MultipleAny, SelectionAny

**Deliverables:**
- [ ] Create `docs/BATTLE_MECHANICS.md`
- [ ] Document all action routines
- [ ] Explain damage formulas
- [ ] Document resistance/weakness calculations
- [ ] Include examples from randomizer code
- [ ] Add damage calculation examples

**Reference:**
- FFMQ Randomizer: `FFMQRLib/battlesim/BattleAction.cs`, `FFMQRLib/battlesim/Enums.cs`

---

## Low Priority Issues

### Issue 6: Investigate Spell Data Unknown Fields
**Title:** Research spell data unknown bytes (byte 1-2)  
**Priority:** Low  
**Estimated Time:** 2-4 hours  
**Labels:** research, investigation  

**Description:**
Investigate the purpose of unknown bytes in spell data structure.

**Current Status:**
- Byte 0: Power ✅ KNOWN
- Byte 1: Unknown (values 1-20, possibly level requirement)
- Byte 2: Unknown (proven NOT element)
- Byte 3: Strong Against flags ✅ KNOWN
- Byte 4: Target Type flags ✅ KNOWN
- Byte 5: Special Flags ✅ KNOWN

**Research Methods:**
1. Search FFMQ Randomizer for spell data address or spell ROM structure
2. ROM tracing during spell casting
3. Compare byte values with game behavior
4. Analyze companion spell learning levels

**Hypothesis for Byte 1:**
- Possible level requirement for companions
- Matches spell learning progression (lower values = earlier spells)

**Deliverables:**
- [ ] ROM trace spell data access
- [ ] Search randomizer for spell data structure
- [ ] Test hypothesis with in-game spell learning
- [ ] Document findings
- [ ] Update spell extraction if fields identified

---

### Issue 7: Create Data Relationship Visualizations
**Title:** Add data visualization tools for enemy/attack relationships  
**Priority:** Low  
**Estimated Time:** 3-5 hours  
**Labels:** enhancement, visualization, tools  

**Description:**
Create visualization tools to understand relationships between enemies, attacks, and element types.

**Visualizations to Create:**

1. **Enemy Attack Network:**
   - Nodes: Enemies and attacks
   - Edges: Which attacks each enemy can use
   - Export to GraphML or DOT format

2. **Element Type Matrix:**
   - Enemies × Element types (resistances/weaknesses)
   - Heatmap visualization

3. **Spell Effectiveness Chart:**
   - Spells × Enemy types (based on enemy type flags)
   - Show which spells are strong against which enemies

4. **Attack Power Distribution:**
   - Histogram of attack power values
   - Categorize by action routine type

**Deliverables:**
- [ ] Create `tools/visualize_enemy_attacks.py`
- [ ] Create `tools/visualize_elements.py`
- [ ] Create `tools/visualize_spell_effectiveness.py`
- [ ] Generate PNG/SVG outputs
- [ ] Add to documentation

**Dependencies:**
- Requires: Enemy data extraction (Issue #1)
- Requires: Attack data extraction (Issue #2)
- Requires: Enemy attack links extraction (Issue #3)

---

### Issue 8: Validate All Extracted Data Against Randomizer
**Title:** Cross-validate all extracted data with FFMQ Randomizer  
**Priority:** Low  
**Estimated Time:** 2-3 hours  
**Labels:** validation, testing  

**Description:**
Create validation suite that compares our extracted data against FFMQ Randomizer's data.

**Validation Checks:**
1. Spell IDs match (ExitBook=0x00 through FlareSeal=0x0B)
2. Enemy count correct (83 enemies)
3. Attack count correct (169 attacks)
4. Element type bitfields match
5. Power values consistent
6. Enemy stats structure matches

**Deliverables:**
- [ ] Create `tools/validation/validate_against_randomizer.py`
- [ ] Compare spell data
- [ ] Compare enemy data (when extracted)
- [ ] Compare attack data (when extracted)
- [ ] Generate validation report
- [ ] Document any discrepancies

**Reference:**
- Compare against: wildham0/FFMQRando repository data

---

## Summary

**Total Issues to Create: 8**

**By Priority:**
- High: 3 issues (Enemy data, Attack data, Attack links)
- Medium: 2 issues (Element types, Battle mechanics)
- Low: 3 issues (Unknown fields, Visualizations, Validation)

**Estimated Total Time: 21-33 hours**

**Dependencies:**
- Issues 7 (Visualizations) depends on Issues 1, 2, 3
- Issue 8 (Validation) benefits from Issues 1, 2, 3 being complete

---

## ✅ GitHub Issues Created

**Date Created:** November 2, 2025

| Priority | Issue # | Title | Status |
|----------|---------|-------|--------|
| High | [#53](https://github.com/TheAnsarya/ffmq-info/issues/53) | Add enemy stats data extraction tool (ROM $C275) | ✅ Created |
| High | [#61](https://github.com/TheAnsarya/ffmq-info/issues/61) | Add attack/battle action data extraction tool (ROM $BC78) | ✅ Created |
| Medium | [#62](https://github.com/TheAnsarya/ffmq-info/issues/62) | Extract enemy attack link data (ROM $C6FF) | ✅ Created |
| Medium | [#56](https://github.com/TheAnsarya/ffmq-info/issues/56) | Add comprehensive element type definitions to all schemas | ✅ Created |
| Medium | [#57](https://github.com/TheAnsarya/ffmq-info/issues/57) | Document battle mechanics and damage formulas | ✅ Created |
| Low | [#58](https://github.com/TheAnsarya/ffmq-info/issues/58) | Research spell data unknown bytes (byte 1-2) | ✅ Created |
| Low | [#59](https://github.com/TheAnsarya/ffmq-info/issues/59) | Create data relationship visualizations | ✅ Created |
| Low | [#60](https://github.com/TheAnsarya/ffmq-info/issues/60) | Cross-validate all extracted data with FFMQ Randomizer | ✅ Created |

**All 8 issues successfully created!** 🎉

**Next Steps:**
1. ✅ ~~Create these issues on GitHub~~
2. Prioritize high-priority data extraction issues
3. Begin with enemy data extraction (builds on spell data research)

---

**Date:** 2025-11-01  
**Updated:** 2025-11-02  
**Reference:** docs/EXTERNAL_REFERENCES.md
