# DataCrystal Wiki Documentation Update Plan
## Final Fantasy: Mystic Quest (SNES)

**Project Repository:** https://github.com/TheAnsarya/ffmq-info  
**DataCrystal Main Page:** https://datacrystal.tcrf.net/wiki/Final_Fantasy:_Mystic_Quest  
**GameInfo Reference:** https://github.com/TheAnsarya/GameInfo/tree/main/Final%20Fantasy%20Mystic%20Quest%20(SNES)

---

## Phase 1: Wikitext File Creation ✅ IN PROGRESS

### Status: STARTED
- [x] Create `datacrystal/` folder in ffmq-info repository
- [x] Download Main.wikitext
- [x] Download ROM_map.wikitext (Enhanced with GitHub links)
- [ ] Download RAM_map.wikitext
- [ ] Download TBL.wikitext (Text Table)
- [ ] Download Notes.wikitext
- [ ] Download SRAM_map.wikitext
- [ ] Download Values.wikitext (if exists)

---

## Phase 2: ROM Map Enhancement

### 2.1 Battle Data Documentation
**Priority: HIGH** | **Effort: Medium** | **Impact: Critical**

#### Current State
- Basic offset listings exist
- No data structure documentation
- Missing field descriptions
- No links to modding tools

#### Enhancement Tasks
- [ ] **Enemy Stats Structure** ($014275-$01469F)
  - [ ] Document complete 74-byte ($4A) enemy structure
  - [ ] Add field-by-field breakdown with offsets
  - [ ] Link to `tools/extraction/extract_enemies.py` script
  - [ ] Link to extracted JSON data: `data/extracted/enemies/enemies.json`
  - [ ] Add conversion script reference: `tools/conversion/convert_enemies.py`
  - [ ] Document element resistance bitfield (16 bits)
  - [ ] Document status effect bitfield
  - [ ] Add example enemy data (Brownie, Dragon, Dark King)
  - [ ] Create enemy stat ranges table (min/max values)

- [ ] **Enemy Level Data** ($01417C-$0141FC)
  - [ ] Document 2-byte structure per enemy
  - [ ] Explain level calculation/display
  - [ ] Link to level extraction code
  - [ ] Add level ranges by enemy type

- [ ] **Attack Data** ($014678-$014776)
  - [ ] Document attack structure (bytes per attack)
  - [ ] Field breakdown: power, element, targeting, animation
  - [ ] Link to `tools/extraction/extract_attacks.py`
  - [ ] Link to `data/extracted/attacks/attacks.json`
  - [ ] Document attack types and categories
  - [ ] Add attack effect descriptions

- [ ] **Enemy-Attack Links** (New Section)
  - [ ] Document how enemies reference attacks
  - [ ] Link to `tools/extraction/extract_enemy_attack_links.py`
  - [ ] Explain AI attack selection logic (if known)
  - [ ] Link to extracted link data JSON

#### References Needed
- `src/asm/ffmq_working.asm` lines for battle data patches
- `data/converted/enemies/*.asm` for ASM structure
- `tools/enemy_editor_gui.py` for field validation ranges

---

### 2.2 Graphics Data Documentation
**Priority: MEDIUM** | **Effort: High** | **Impact: High**

#### Current State
- Basic offset listings
- No format specifications
- Missing compression info
- No tile arrangement docs

#### Enhancement Tasks
- [ ] **Character & NPC Graphics** ($062C4C-$0638EB)
  - [ ] Document 4BPP format specification
  - [ ] Tile arrangement/grouping
  - [ ] Palette assignment details
  - [ ] Link to graphics extraction tools (if available)
  - [ ] Add sample tile layouts

- [ ] **Enemy Graphics** ($00050818+)
  - [ ] Document 3BPP SNES format
  - [ ] Enemy graphics structure (frames, animations)
  - [ ] Specific enemy locations (Brownie, Dragons, Bosses)
  - [ ] Frame count per enemy
  - [ ] Animation frame ordering

- [ ] **Tile Graphics**
  - [ ] Borders ($0212C0-$0281FF): FC-NES x8 3BPP format
  - [ ] Town/Dungeon ($028E80-$02F480): 3BPP format
  - [ ] Spell Animations ($0341C1-$037DC0): FC-NES x16 3BPP
  - [ ] Battle Backgrounds ($00065bc4): 3BPP format
  - [ ] Document tile indices and tilemap structure

- [ ] **Palette Data**
  - [ ] Document SNES palette format (15-bit RGB)
  - [ ] Palette locations for each graphics type
  - [ ] Color assignment per graphics set
  - [ ] Dynamic palette effects (if any)

#### References Needed
- Graphics extraction tools from GameInfo repo
- Existing tile viewers/editors
- Palette editors (WindHex, SNESPal, etc.)

---

### 2.3 Music/SPC Data Documentation
**Priority: MEDIUM** | **Effort: Medium** | **Impact: Medium**

#### Current State
- Good SPC sequence offset list
- Partial command documentation
- Sample index documented
- Missing detailed format specs

#### Enhancement Tasks
- [ ] **SPC700 Format Documentation**
  - [ ] Complete command reference (all opcodes)
  - [ ] Document unknown commands (D3, E1-E3, F0, F1, F4, F6, F7)
  - [ ] Channel structure and layout
  - [ ] Timing and tempo mechanics
  - [ ] Loop points and markers

- [ ] **BRR Sample Format**
  - [ ] BRR compression/encoding details
  - [ ] Sample rate and pitch
  - [ ] Loop point encoding
  - [ ] Link to BRR sample data ($6C201+)

- [ ] **Instrument Samples**
  - [ ] Expand sample index with more details
  - [ ] Document internal SPC samples (00-3F)
  - [ ] Sample usage per track
  - [ ] Instrument index location ($6BEA1-$6C1E1)

- [ ] **Music Sequences**
  - [ ] Add track names/descriptions for all 30 sequences
  - [ ] Document track length/size
  - [ ] Loop points for each track
  - [ ] Instrument usage per track

#### References Needed
- SPC700 programming reference
- BRR format specification
- SPC extraction/editing tools
- JCE3000GT's SPC Editor documentation

---

### 2.4 Map/Level Data Documentation
**Priority: LOW-MEDIUM** | **Effort: High** | **Impact: Medium**

#### Current State
- Minimal documentation
- Only offsets listed
- No structure details

#### Enhancement Tasks
- [ ] **Tile Properties** ($032B00)
  - [ ] Document property bitfield structure
  - [ ] Walkability flags
  - [ ] Character movement effects (ice, lava, etc.)
  - [ ] Interaction triggers
  - [ ] Damage tiles

- [ ] **Location Data** ($03B218)
  - [ ] Document 2-byte pointer structure
  - [ ] List all location pointers
  - [ ] Location data structure breakdown
  - [ ] Map dimensions and layout
  - [ ] Tile arrangement format

- [ ] **Palette Assignments** ($034084)
  - [ ] Document palette assignment per location
  - [ ] List all locations with palette IDs
  - [ ] Location-specific palette effects

- [ ] **Menu Palettes** ($038200)
  - [ ] Menu palette structure
  - [ ] Color assignments for UI elements
  - [ ] Window color customization

#### References Needed
- Map viewing tools
- Location/tileset editors
- Existing map documentation

---

## Phase 3: RAM Map Enhancement

### 3.1 Complete RAM Map Documentation
**Priority: HIGH** | **Effort: High** | **Impact: Critical**

#### Current State (from RAM_map page)
- Good structure for known addresses
- Many "???" gaps ($0000-$0e87, etc.)
- Partial documentation of key structs

#### Enhancement Tasks
- [ ] **Fill Unknown Regions**
  - [ ] Research $0000-$0e87 (3,720 bytes)
  - [ ] Research $0e8c-$0e96 gap
  - [ ] Research $0ec1-$0ec5 gap
  - [ ] Research $0ec7-$0fd3 gap (large! 781 bytes)
  - [ ] Research $0fe8-$0fff gap
  - [ ] Research $1008-$100f gap
  - [ ] Research $101e-$1020 gap
  - [ ] Research $102a-$102f gap
  - [ ] Research various weapon/armor bitfield gaps

- [ ] **Player Character Structure** ($1000-$103F)
  - [ ] Complete all unknown bytes
  - [ ] Document calculated vs base stats
  - [ ] Equipment bonus calculations
  - [ ] Status effect mechanics
  - [ ] Link to SRAM equivalent structure

- [ ] **Companion Structure** ($1080-$10BF)
  - [ ] Complete all unknown bytes
  - [ ] Document companion-specific fields
  - [ ] AI behavior flags (if RAM-based)
  - [ ] Companion type/ID system

- [ ] **Inventory & Items**
  - [ ] Complete item storage structure
  - [ ] Document item ID system (link to Values page)
  - [ ] Equipment bitfield complete mapping
  - [ ] Magic spell bitfield complete mapping

- [ ] **Chest & Event Flags**
  - [ ] Complete all chest location documentation
  - [ ] Missing chest coordinates filled in
  - [ ] Event flag documentation
  - [ ] Battlefield reward flags

- [ ] **Map & Location Data**
  - [ ] Battlefield rounds counters documentation
  - [ ] Map transition mechanics
  - [ ] Player position/facing mechanics
  - [ ] Camera/scroll RAM addresses

#### Reference Assets
- Mesen-S RAM viewer captures
- [https://github.com/TheAnsarya/GameInfo/.../Final%20Fantasy%20-%20Mystic%20Quest%20(U)%20(V1.1).mlb Mesen label file] with RAM labels
- Diz disassembly exports with RAM references
- `labels.asm` from Diz exports

---

### 3.2 Cross-Reference with Disassembly
**Priority: MEDIUM** | **Effort: Medium** | **Impact: High**

#### Tasks
- [ ] Extract all RAM address usages from Diz disassembly
  - [ ] Use `labels.asm` exports from GameInfo repo
  - [ ] Cross-reference with RAM map addresses
  - [ ] Find code that reads/writes each RAM location
  
- [ ] Document RAM Usage Patterns
  - [ ] Which routines access which RAM
  - [ ] Call chains for important RAM (HP, stats, etc.)
  - [ ] Timing of RAM updates (frame-based, event-based)

- [ ] Link RAM to ROM Code
  - [ ] Create "Used By" sections for important RAM
  - [ ] Link to specific ROM routines/functions
  - [ ] Document register usage (A, X, Y) with RAM operations

#### Reference Files
- `bank_00.asm` through `bank_0F.asm` from Diz exports
- `labels.asm` - all defined labels
- `defines.asm` - auto-generated defines

---

## Phase 4: SRAM Map Enhancement

### 4.1 Complete SRAM Documentation
**Priority: MEDIUM** | **Effort: Medium** | **Impact: Medium**

#### Current State
- Basic save slot structure documented
- Character data structure partially complete
- Many "???" gaps

#### Enhancement Tasks
- [ ] **Save Slot Structure** ($38C bytes each)
  - [ ] Research $0a9-$0aa gap (2 bytes)
  - [ ] Research $0ae-$0b2 gap (5 bytes)
  - [ ] Research $0b4-$0b8 gap (5 bytes)
  - [ ] Research $0bc-$0c0 gap (5 bytes)
  - [ ] Research $0c2-$38b gap (682 bytes! - CRITICAL)
  
- [ ] **Character Data Structure** ($50 bytes)
  - [ ] Research $08-$0f gap (8 bytes)
  - [ ] Research $32-$4f gap (30 bytes! - large gap)
  - [ ] Document equipment storage format
  - [ ] Document magic spell storage

- [ ] **Checksum System**
  - [ ] Document checksum algorithm (2 bytes at $000)
  - [ ] "FF0!" marker meaning
  - [ ] Checksum validation logic
  - [ ] How to recalculate checksum

- [ ] **Save Slot Verification**
  - [ ] Slots A/B/C system explanation
  - [ ] Why 3 copies of each save?
  - [ ] Corruption detection/recovery
  - [ ] Active slot selection

#### Reference Assets
- Save state captures at various game points
- Hex editor comparisons of save files
- Save editor tools (if available)

---

## Phase 5: Text Table/TBL Enhancement

### 5.1 Complete TBL Documentation
**Priority: MEDIUM** | **Effort: Low-Medium** | **Impact: Medium**

#### Current State
- Good coverage of English, German, Japanese tables
- Simple and complex (DTE) tables documented
- Some TODOs noted in existing doc

#### Enhancement Tasks
- [ ] **Complete TODO Items**
  - [ ] Finish English table grid
  - [ ] Verify German DTE entries marked [TODO]
  - [ ] Complete Japanese simple table notes
  - [ ] Add control codes section (currently empty)

- [ ] **Control Codes**
  - [ ] Document text box control codes
  - [ ] Newline/line break codes
  - [ ] Color change codes
  - [ ] Delay/wait codes
  - [ ] Character name insertion codes
  - [ ] Number formatting codes

- [ ] **DTE Compression**
  - [ ] Explain DTE (Dual Tile Encoding) system
  - [ ] How DTE saves space
  - [ ] Most common 2-character pairs
  - [ ] DTE usage statistics per language

- [ ] **Text Pointer System**
  - [ ] Document text pointer table location
  - [ ] Pointer format and structure
  - [ ] How to add new text strings
  - [ ] Text expansion limitations

#### Reference Assets
- `.tbl` files from GameInfo repo
- Text dumping tools
- Text editors (Cartographer, Atlas, etc.)

---

## Phase 6: Notes Page Enhancement

### 6.1 Expand Graphics Notes
**Priority: LOW** | **Effort: Low** | **Impact: Low**

#### Current State
- Basic graphics offsets from Zeemis
- Limited palette info
- No comprehensive notes

#### Enhancement Tasks
- [ ] Organize existing Zeemis notes into categories
- [ ] Add complete graphics format specifications
- [ ] Document compression (if any)
- [ ] Add palette organization notes
- [ ] Link to extraction tools

---

### 6.2 Add Code/Engine Notes
**Priority: MEDIUM** | **Effort: Medium** | **Impact: Medium**

#### New Section
- [ ] **Battle System**
  - [ ] Damage calculation formulas
  - [ ] Element effectiveness multipliers
  - [ ] Status effect mechanics
  - [ ] Critical hit system
  - [ ] Defense calculation

- [ ] **AI System**
  - [ ] Enemy AI patterns
  - [ ] Attack selection logic
  - [ ] Behavior conditions
  - [ ] Boss-specific AI

- [ ] **Level/Experience System**
  - [ ] XP calculation formulas
  - [ ] Level-up stat increases
  - [ ] Max level mechanics
  - [ ] Companion level scaling

- [ ] **Equipment System**
  - [ ] Stat bonus calculations
  - [ ] Element resistance stacking
  - [ ] Accessory effects
  - [ ] Weapon targeting mechanics

#### References
- Disassembled battle code
- GameFAQs guides for formulas
- Community research

---

## Phase 7: Create New Subpages

### 7.1 Values Subpage (if not exists)
**Priority: HIGH** | **Effort: Medium** | **Impact: High**

Create comprehensive value/enum documentation:

- [ ] **Item IDs**
  - [ ] All 256 possible item IDs
  - [ ] Weapons, Armor, Accessories, Consumables
  - [ ] Link to RAM ($1031) and SRAM usage

- [ ] **Enemy IDs**
  - [ ] All 83 enemy IDs (0-82, $00-$52)
  - [ ] Enemy names by ID
  - [ ] Link to enemy data ($014275)

- [ ] **Attack IDs**
  - [ ] All attack move IDs
  - [ ] Attack names
  - [ ] Link to attack data ($014678)

- [ ] **Map IDs**
  - [ ] All location/map IDs
  - [ ] Map names
  - [ ] Link to RAM $0e88

- [ ] **Status Effects**
  - [ ] Status bitfield breakdown
  - [ ] Effect descriptions
  - [ ] Duration mechanics

- [ ] **Elements**
  - [ ] Element bitfield (16 elements)
  - [ ] Element names: Silence, Blind, Poison, Sleep, Paralyze, Confusion, Petrify, Fatal, Toad, Pygmy, Curse, Transparent, Berserk, Death Sentence, Doom, Zombie
  - [ ] Element effectiveness values

- [ ] **Message Speed**
  - [ ] Speed value meanings
  - [ ] Link to RAM $0e9b

- [ ] **Window Colors**
  - [ ] Color value list
  - [ ] Link to RAM $0e9c-$0e9d

- [ ] **Player Facing Directions**
  - [ ] Direction values
  - [ ] Link to RAM $0e8b

---

### 7.2 Code Subpage
**Priority: LOW-MEDIUM** | **Effort: Very High** | **Impact: High**

Document major code routines:

- [ ] **Initialization**
  - [ ] Boot/reset sequence
  - [ ] RAM initialization
  - [ ] SRAM loading

- [ ] **Main Game Loop**
  - [ ] Frame timing
  - [ ] Input handling
  - [ ] State machine

- [ ] **Battle Engine**
  - [ ] Battle init
  - [ ] Turn order
  - [ ] Damage calculation routines
  - [ ] AI execution
  - [ ] Victory/defeat handling

- [ ] **Menu System**
  - [ ] Menu rendering
  - [ ] Input handling
  - [ ] Item usage
  - [ ] Equipment changes

- [ ] **Map Engine**
  - [ ] Tile collision detection
  - [ ] Character movement
  - [ ] NPC interaction
  - [ ] Event triggers

---

### 7.3 Subpage Organization
**Priority: MEDIUM** | **Effort: Low** | **Impact: Medium**

Create additional organizational subpages:

- [ ] **ROM map/Characters** - Character sprite/stats data
- [ ] **ROM map/Enemies** - Enemy data (link to existing battle data)
- [ ] **ROM map/Graphics** - All graphics data organized
- [ ] **ROM map/Maps** - Map/tileset data
- [ ] **ROM map/Menus** - Menu graphics/text
- [ ] **ROM map/Sound** - SPC/BRR data (link to existing music section)
- [ ] **ROM map/Text** - Text pointer and string data
- [ ] **ROM map/Code** - Code organization by bank
- [ ] **ROM map/Full Map** - Complete memory map visualization

---

## Phase 8: Integration with GitHub Repository

### 8.1 Add Repository Links Throughout
**Priority: HIGH** | **Effort: Low** | **Impact: Critical**

#### Tasks
- [x] Link to main repository on Main page ✅ DONE
- [x] Link to specific asset files on ROM map ✅ DONE
- [x] Link to extraction scripts ✅ DONE
- [x] Link to conversion scripts ✅ DONE
- [x] Link to editing tools ✅ DONE
- [ ] Link to Mesen label file (.mlb)
- [ ] Link to disassembly source files
- [ ] Link to documentation files
- [ ] Link to test scripts

#### Link Strategy
- Direct links to `main` branch files (stable)
- Use `blob` URLs for viewing files
- Use `raw` URLs for downloadable files (.tbl, .mlb, etc.)
- Add descriptive link text
- Organize links by category (extraction, conversion, viewing, etc.)

---

### 8.2 Create Bidirectional Documentation
**Priority: MEDIUM** | **Effort: Low** | **Impact: Medium**

#### In ffmq-info Repository
- [ ] Add `docs/DATACRYSTAL_LINKS.md`
  - [ ] Link to Main DataCrystal page
  - [ ] Link to ROM map page
  - [ ] Link to RAM map page
  - [ ] Link to all subpages
  - [ ] Explain DataCrystal documentation purpose

- [ ] Update README.md
  - [ ] Add "Documentation" section
  - [ ] Link to DataCrystal pages
  - [ ] Explain relationship between repo and wiki

- [ ] Add DataCrystal links in code comments
  - [ ] Reference wiki pages in extraction scripts
  - [ ] Link to RAM map in label files
  - [ ] Link to ROM map in build scripts

---

## Phase 9: Add Visual Assets

### 9.1 Screenshots & Diagrams
**Priority: LOW-MEDIUM** | **Effort: Medium** | **Impact: Medium**

#### Create & Upload
- [ ] **Data Structure Diagrams**
  - [ ] Enemy stats structure visual
  - [ ] Attack data structure visual
  - [ ] Save file structure diagram
  - [ ] RAM layout map

- [ ] **Screenshots**
  - [ ] Text table in RAM (already exists for some versions)
  - [ ] Battle screen with stat display
  - [ ] Menu screens
  - [ ] Enemy graphics samples

- [ ] **Memory Maps**
  - [ ] ROM bank visualization
  - [ ] RAM usage visualization
  - [ ] SRAM layout visualization

#### Image Hosting
- Upload to DataCrystal wiki
- Use proper file naming: "Final Fantasy Mystic Quest (SNES) - [description].png"
- Add image descriptions and credits

---

## Phase 10: Community & Validation

### 10.1 Cross-Reference with Existing Research
**Priority: MEDIUM** | **Effort: Medium** | **Impact: High**

#### Sources to Check
- [ ] GameFAQs guides
  - [ ] DrProctor's Enemy Guide
  - [ ] Stat/formula guides
  - [ ] Item/equipment guides

- [ ] Mike's RPG Center
  - [ ] Maps and tables
  - [ ] Enemy data
  - [ ] Item data

- [ ] ROM Hacking community
  - [ ] FF6Hacking forums posts
  - [ ] ROMHacking.net resources
  - [ ] Discord channels

- [ ] JCE3000GT's Tools
  - [ ] Mystic Quest Multi Editor documentation
  - [ ] SPC Editor documentation
  - [ ] Hard Type hack insights

#### Validation
- [ ] Compare extracted data with GameFAQs data
- [ ] Verify formulas with community research
- [ ] Cross-check addresses with Mesen label file
- [ ] Validate against Multiple ROM versions (U 1.0, U 1.1, J, E, G)

---

### 10.2 Contribution Guidelines
**Priority: LOW** | **Effort: Low** | **Impact: Low**

- [ ] Create CONTRIBUTING.md in ffmq-info repo
  - [ ] How to update DataCrystal wiki
  - [ ] Wikitext formatting guide
  - [ ] Where to find assets
  - [ ] Testing/validation process

- [ ] Create issue templates
  - [ ] Documentation update request
  - [ ] Data discrepancy report
  - [ ] New discovery submission

---

## Phase 11: Advanced Documentation

### 11.1 Assembly Code Documentation
**Priority: LOW** | **Effort: Very High** | **Impact: Medium**

#### Tasks
- [ ] Annotate major routines in Diz exports
- [ ] Document function parameters
- [ ] Document return values
- [ ] Add code flow comments
- [ ] Create call graphs for complex systems

#### Focus Areas
- Battle damage calculation
- AI decision making
- Level-up stat increases
- Equipment effect application
- Menu rendering

---

### 11.2 Modding Tutorials
**Priority: MEDIUM** | **Effort: Medium** | **Impact: High**

Create tutorial subpages:

- [ ] **Beginner: Edit Enemy Stats**
  - [ ] Using the GUI editor
  - [ ] Step-by-step with screenshots
  - [ ] Building and testing

- [ ] **Intermediate: Create Custom Enemy**
  - [ ] JSON editing
  - [ ] Graphics replacement (if possible)
  - [ ] Testing with build system

- [ ] **Advanced: Add New Attacks**
  - [ ] Attack data structure
  - [ ] Linking to enemies
  - [ ] Animation considerations

- [ ] **Advanced: Text Editing**
  - [ ] Using TBL files
  - [ ] Pointer management
  - [ ] DTE considerations

- [ ] **Expert: Code Modifications**
  - [ ] Assembly editing
  - [ ] Free space finding
  - [ ] Recompiling with asar

---

## Timeline & Priorities

### Immediate (Week 1-2)
1. ✅ Create wikitext files ✅ STARTED
2. ✅ Add GitHub repository links ✅ DONE (Main, ROM map)
3. [ ] Complete ROM map battle data section
4. [ ] Start RAM map gap filling

### Short Term (Week 3-4)
5. [ ] Complete RAM map documentation
6. [ ] Finish TBL control codes
7. [ ] Create Values subpage
8. [ ] Add music/SPC details

### Medium Term (Month 2)
9. [ ] Complete SRAM map gaps
10. [ ] Add graphics documentation
11. [ ] Create subpage organization
12. [ ] Add visual assets

### Long Term (Month 3+)
13. [ ] Advanced code documentation
14. [ ] Modding tutorials
15. [ ] Cross-reference validation
16. [ ] Community contributions

---

## Success Metrics

### Completeness
- [ ] All "???" gaps documented or marked as "unused/unknown"
- [ ] All TODO items resolved
- [ ] All data structures fully documented
- [ ] All offsets verified across ROM versions

### Quality
- [ ] Every data field has description
- [ ] Examples provided for complex structures
- [ ] Cross-references between pages
- [ ] Links to GitHub assets functional
- [ ] Images/diagrams for visual clarity

### Usefulness
- [ ] Modders can find what they need quickly
- [ ] Researchers can understand ROM structure
- [ ] Tools builders have complete reference
- [ ] Beginners have tutorials to follow

---

## Key Resources

### External References
- DataCrystal Wiki Syntax: https://datacrystal.tcrf.net/wiki/Help:Contents
- MediaWiki Formatting: https://www.mediawiki.org/wiki/Help:Formatting
- SNES Development Manual (for hardware specs)
- SPC700 Reference Manual
- 65816 CPU Reference

### GitHub Repositories
- **ffmq-info**: https://github.com/TheAnsarya/ffmq-info (Main disassembly + tools)
- **GameInfo**: https://github.com/TheAnsarya/GameInfo/tree/main/Final%20Fantasy%20Mystic%20Quest%20(SNES) (Original research + Diz exports)

### Community Resources
- FF6Hacking Forum: https://www.ff6hacking.com/forums/
- ROMHacking.net: https://www.romhack.ing/
- TCRF Discord: https://discord.com/invite/SGeE8dcWR6
- RHDI Discord: https://discord.com/invite/uAufcgz

---

## Notes & Decisions

### Wikitext Format Guidelines
- Use proper MediaWiki syntax
- Link between subpages with [[Page]] syntax
- Use tables for structured data
- Add categories at bottom of pages
- Use {{Todo}} template for work in progress
- Use {{subpage|Name}} for subpage links

### Naming Conventions
- Pages: "Final Fantasy: Mystic Quest/Subpage Name"
- Images: "Final Fantasy Mystic Quest (SNES) - Description.png"
- Files: "Final Fantasy Mystic Quest (SNES) - Description.tbl"

### Address Format
- Use SNES addresses ($XXXXXX) in RAM/SRAM maps
- Use PC offsets (XXXXXX) in ROM map when helpful
- Always specify "SNES address" vs "PC offset" when ambiguous
- Use LoROM formula: SNES $AB:$CDEF = PC offset (AB-80)*8000 + CDEF

### Data Verification
- Cross-check with multiple ROM versions when possible
- Verify against community data (GameFAQs, Mike's RPG Center)
- Test with actual ROM modifications
- Document discrepancies between versions

---

## Version History

### v1.0 - 2025-11-03
- Initial TODO plan created
- Phase 1 started: Wikitext files creation
- Main page enhanced with GitHub links
- ROM map enhanced with modding tools section

### Future Updates
- [ ] Add completion percentages per phase
- [ ] Track contributor credits
- [ ] Log significant discoveries
- [ ] Update timeline based on progress

---

**END OF TODO PLAN**

Total Estimated Effort: ~200-300 hours for complete documentation
Priority: Document what enables modding first (battle data, RAM/SRAM), then expand to comprehensive coverage.
