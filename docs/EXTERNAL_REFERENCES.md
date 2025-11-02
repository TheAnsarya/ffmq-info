# External References

This document catalogs all external resources used as references for FFMQ reverse engineering and documentation.

## Project Management

**GitHub Project:** https://github.com/users/TheAnsarya/projects/3  
**Repository:** https://github.com/TheAnsarya/ffmq-info  
**Owner:** TheAnsarya

All issues, tasks, and project tracking are managed through GitHub Project #3.

## GitHub Repositories

### FFMQ Randomizer
**Repository:** https://github.com/wildham0/FFMQRando  
**License:** MIT  
**Language:** C# (80.3%), JavaScript (11.9%), HTML (5.7%), Assembly (1.5%)  
**Contributors:** wildham0, Oipo, Alchav  
**Stars:** 9 | **Forks:** 7 | **Commits:** 583  

**Description:**  
A comprehensive randomizer for Final Fantasy Mystic Quest (NA v1.1). The repository contains extensive ROM data structure documentation, implementations, and research that serves as a crucial reference for understanding FFMQ's internal data organization.

**ROM Compatibility:**  
- Compatible with NA v1.1 ROM
- MD5: `f7faeae5a847c098d677070920769ca2`

**Key Files Referenced:**

1. **FFMQRLib/Enemies.cs**
   - Enemy stats structure (Bank $02, offset $C275, 14 bytes, 83 enemies)
   - Enemy data fields: HP, Attack, Defense, Speed, Magic, Accuracy, Evade, MagicDefense, MagicEvade
   - Resistances (2 bytes), Weaknesses (1 byte)
   - Level/multiplier data (Bank $02, offset $C17C, 3 bytes per enemy)
   - Element types enum (bitfield 0x0001-0x8000)

2. **FFMQRLib/Enums.cs**
   - Spell flags enum: ExitBook=0x00 through FlareSeal=0x0B
   - Item IDs: Complete item enumeration
   - Elements types: Status effects, damage types, and elements as bitfield

3. **FFMQRLib/EnumsEnemies.cs**
   - Enemy IDs: 83 enemies from Brownie (0x00) to DarkKingSpider (0x52)
   - Enemy attack IDs: Comprehensive attack enumeration

4. **FFMQRLib/Enemizer.cs**
   - Attack structure (Bank $02, offset $BC78, 7 bytes per entry)
   - Attack fields: Unknown1, Unknown2, Power, AttackType, AttackSound, Unknown3, AttackTargetAnimation
   - Enemy attack links (Bank $02, offset $C6FF, 9 bytes, 82 entries)

5. **FFMQRLib/battlesim/BattleSimulator.cs**
   - Complete battle actions dictionary (400+ entries)
   - Action routines: MagicDamage1/2/3, PhysicalDamage1-9, etc.
   - Element types per attack
   - Power values per attack

6. **FFMQRLib/battlesim/Enums.cs**
   - Action routines enum: None, Punch, Sword, Axe, Claw, Bomb, Projectile, MagicDamage1-3, etc.
   - Targeting types: SingleEnemy, MultipleEnemy, SelectionEnemy, etc.

7. **docs/tables.md**
   - Enemy Attack General Info table documentation
   - Attack data structure (Start address 0xC6FF, Bank 2, File address 0x146FF)
   - Attack General Info (Start address 0xBC78, Bank 2, File address 0x13C78, Amount 169, Length 7)

**Data Structure Findings:**

| Data Type | ROM Address | Bank | Size (bytes) | Count | File Address |
|-----------|-------------|------|--------------|-------|--------------|
| Enemy Stats | $C275 | $02 | 14 | 83 | $0C275 |
| Enemy Attacks | $BC78 | $02 | 7 | 169 | $0BC78 |
| Enemy Attack Links | $C6FF | $02 | 9 | 82 | $0C6FF |
| Enemy Level/Mult | $C17C | $02 | 3 | 83 | $0C17C |
| Spell Data | $0F36 | $0C | 6 | 16 | $060F36 |

**Element Types (Bitfield):**
- **Status Effects:** Silence (0x0001), Blind (0x0002), Poison (0x0004), Confusion (0x0008), Sleep (0x0010), Paralysis (0x0020), Stone (0x0040), Doom (0x0080)
- **Damage Types:** Projectile (0x0100), Bomb (0x0200), Axe (0x0400), Zombie (0x0800)
- **Elements:** Air (0x1000), Fire (0x2000), Water (0x4000), Earth (0x8000)

**Spell Information:**
- Spell IDs match our findings: 0x00-0x0B
- Spell types: White (Exit, Cure, Heal, Life), Black (Quake, Blizzard, Fire, Aero), Wizard (Thunder, White, Meteor, Flare)
- MP cost: Always 1 (not stored in ROM table)
- Power levels: Level 0 (Cure, Fire), Level 1 (Blizzard, Thunder, Aero), Level 2 (White, Meteor, Flare)

**Battle Mechanics:**
- Magic damage formulas:
  - MagicDamage2: Power × 3
  - MagicDamage3: Power × 9
- Resistance: Halves damage (or reverses for Zombie type)
- Weakness: Doubles damage
- Critical hit system implemented

**Validation Status:**
- ✅ Spell flags enum matches our spell data extraction
- ✅ Element types confirmed (status + damage + elements)
- ✅ Enemy count verified (83 enemies)
- ✅ Attack structure documented
- 🔄 Spell data ROM address not explicitly documented in randomizer (our finding at $060F36 needs cross-verification)

**Use Cases:**
- Cross-reference data structures and ROM addresses
- Verify extracted data against established randomizer implementation
- Understand game mechanics (battle formulas, damage calculation, element interactions)
- Identify missing data fields or structures in our extraction tools
- Validate enemy/attack/spell relationships

## Documentation Sites

### DataCrystal - Final Fantasy Mystic Quest
**URL:** https://datacrystal.romhacking.net/wiki/Final_Fantasy_Mystic_Quest  
**Type:** Community wiki for ROM hacking  

**Description:**  
Community-maintained documentation for FFMQ ROM structures, including memory addresses, data tables, and technical information.

**Status:** To be explored further

## Tools and Utilities

### Mesen-SX
**URL:** https://github.com/NovaSquirrel/Mesen-SX  
**Type:** SNES emulator with debugging capabilities  

**Description:**  
Used for ROM tracing, memory analysis, and debugging during data extraction research.

**Use Cases:**
- Trace ROM access patterns
- Monitor memory reads/writes
- Debug extraction scripts
- Verify data structure locations

## Research Methodology

### Data Discovery Process
1. **Code Analysis:** Review SNES assembly disassembly for data table references
2. **Pattern Matching:** Search ROM for known value sequences (e.g., spell power values)
3. **Validation:** Cross-reference with game behavior and external sources
4. **Documentation:** Record findings in structured markdown files
5. **Tool Development:** Create Python extraction scripts for verified data structures

### Verification Workflow
1. Extract data using custom tools
2. Compare against FFMQ Randomizer implementation
3. Test in-game using emulator
4. Document discrepancies or confirmations
5. Update schemas and extraction tools

## Related Projects

### Similar Reverse Engineering Projects
- **FF6 ROM Documentation** - Similar reverse engineering efforts for Final Fantasy 6
- **Super Metroid Disassembly** - Methodologies for SNES game reverse engineering

## Version History

- **2025-11-01:** Initial creation
  - Added FFMQ Randomizer (wildham0/FFMQRando) with comprehensive data structure findings
  - Documented enemy stats, attacks, attack links, spell data
  - Cataloged element types, spell IDs, and battle mechanics
  - Verified spell flags match our extraction (Issue #52)

---

**Note:** This document is maintained as part of the FFMQ reverse engineering project. All external resources are credited appropriately. When using information from these sources, please respect their respective licenses and attribution requirements.

**Last Updated:** 2025-11-01
