# GitHub Issues to Create

## Priority: High

### Issue 1: GUI Dialog Preview Tool
**Title:** Create GUI preview tool for dialog visualization

**Description:**
Create a graphical preview tool that shows how dialogs will appear in-game.

**Features:**
- Render text using actual FFMQ font graphics
- Show control codes visually ([PARA], [PAGE], etc.)
- Preview dialog box layout (32 chars/line, 3 lines/page)
- Proportional font character width simulation
- Color palette preview ([WHITE], [YELLOW], [GREEN])
- Frame-by-frame animation of [WAIT] pauses
- Export preview as PNG/GIF

**Technical Details:**
- Use pygame or tkinter for rendering
- Extract font tiles from ROM (likely 8x8 or 8x16)
- Implement proportional width calculations
- Support all control codes from complex.tbl

**Acceptance Criteria:**
- [ ] Loads ROM and extracts font data
- [ ] Renders any dialog ID with proper formatting
- [ ] Shows control codes with visual markers
- [ ] Detects and highlights overflow issues
- [ ] Exports preview images

**Labels:** enhancement, gui, tools
**Milestone:** v2.1.0

---

### Issue 2: Translation Memory System
**Title:** Implement translation memory database for localization

**Description:**
Create a translation memory system to track and reuse translations across editing sessions.

**Features:**
- SQLite database for translation storage
- Track source text → translated text mappings
- Suggest reuse of previously translated segments
- Fuzzy matching for similar phrases
- Translation glossary management (consistent term usage)
- Import/export to TMX format (standard translation memory exchange)
- Statistics: coverage, consistency, reuse rate

**Technical Details:**
- Use SQLite for storage
- FTS5 full-text search for fuzzy matching
- Integration with dialog_cli.py edit command
- Optional: TM-sharing between multiple translators

**Acceptance Criteria:**
- [ ] Creates and manages TM database
- [ ] Suggests translations during editing
- [ ] Tracks translation statistics
- [ ] Exports to TMX format
- [ ] Detects inconsistent translations

**Labels:** enhancement, translation, database
**Milestone:** v2.2.0

---

### Issue 3: Dialog Flow Visualization
**Title:** Generate dialog flow diagrams and dependency graphs

**Description:**
Create tool to visualize dialog relationships, branching, and event triggers.

**Features:**
- Generate flowcharts showing dialog chains
- Analyze parameter codes ([P##]) for branching
- Detect dialog dependencies and references
- Find unused dialogs
- Export as graphviz DOT, mermaid, or SVG
- Interactive HTML visualization

**Technical Details:**
- Parse all dialogs for references
- Build dependency graph
- Use graphviz or mermaid for rendering
- Identify branching logic from P## parameters

**Acceptance Criteria:**
- [ ] Generates dependency graph for all dialogs
- [ ] Identifies dialog chains and branches
- [ ] Exports in multiple formats (DOT, mermaid, SVG)
- [ ] Shows parameter usage patterns
- [ ] Detects orphaned/unused dialogs

**Labels:** enhancement, visualization, analysis
**Milestone:** v2.2.0

---

## Priority: Medium

### Issue 4: Web-Based Collaborative Translation Interface
**Title:** Build web interface for collaborative ROM translation

**Description:**
Create a web application for team-based translation work.

**Features:**
- Multi-user translation interface
- Real-time collaboration (WebSockets)
- User accounts and permissions
- Translation assignment and progress tracking
- Inline preview of dialog boxes
- Comment system for translation discussions
- Export to ROM format
- Version control integration

**Technical Details:**
- Backend: Flask or FastAPI
- Frontend: React or Vue.js
- Database: PostgreSQL
- Real-time: Socket.IO or WebSockets
- Authentication: JWT or OAuth2

**Acceptance Criteria:**
- [ ] Multi-user support with authentication
- [ ] Assign dialogs to translators
- [ ] Real-time collaboration features
- [ ] Translation progress tracking
- [ ] Export final ROM
- [ ] Comment and review system

**Labels:** enhancement, web, collaboration
**Milestone:** v3.0.0

---

### Issue 5: Advanced DTE Optimization
**Title:** Machine learning-based DTE compression optimizer

**Description:**
Enhance compression_optimizer.py with ML for better DTE selection.

**Features:**
- Analyze entire corpus for optimal DTE table
- ML-based frequency prediction
- Context-aware compression (dialog vs items vs locations)
- Suggest dynamic DTE table reorganization
- Calculate theoretical maximum compression
- Generate replacement recommendations
- Simulate compression improvements

**Technical Details:**
- Use scikit-learn or TensorFlow
- N-gram analysis for substring prediction
- Markov chain models for text patterns
- Genetic algorithm for DTE optimization

**Acceptance Criteria:**
- [ ] Analyzes full text corpus
- [ ] Suggests DTE table improvements
- [ ] Predicts compression improvement
- [ ] Validates against actual ROM constraints
- [ ] Generates optimized complex.tbl

**Labels:** enhancement, optimization, ml
**Milestone:** v2.3.0

---

### Issue 6: Dialog Quality Checker
**Title:** Automated dialog quality and consistency checker

**Description:**
Tool to validate translation quality, tone, and consistency.

**Features:**
- Grammar checking (LanguageTool API)
- Tone analysis (formal vs casual consistency)
- Character limit validation
- Terminology consistency checking
- Punctuation pattern validation
- Name capitalization consistency
- Style guide enforcement
- Automated suggestions

**Technical Details:**
- Integrate LanguageTool for grammar
- Custom rules engine for game-specific checks
- Configuration file for style guidelines
- Integration with validate command

**Acceptance Criteria:**
- [ ] Checks grammar and spelling
- [ ] Validates tone consistency
- [ ] Enforces style guide rules
- [ ] Detects terminology inconsistencies
- [ ] Generates quality report

**Labels:** enhancement, quality, validation
**Milestone:** v2.3.0

---

### Issue 7: Font Extraction and Editing Tool
**Title:** Extract and edit FFMQ font graphics

**Description:**
Tool to extract, edit, and re-insert font tile graphics.

**Features:**
- Extract font tiles from ROM
- Display current character→tile mappings
- Edit tiles with simple pixel editor
- Support for 8x8 and 8x16 tiles
- Import custom fonts
- Preview font with test text
- Re-insert modified font to ROM

**Technical Details:**
- Locate font data in ROM (research needed)
- Extract 1bpp or 2bpp tile format
- Simple tile editor (pygame or PIL)
- Validate tile format before insertion

**Acceptance Criteria:**
- [ ] Extracts all font tiles
- [ ] Displays tile→character mapping
- [ ] Allows tile editing
- [ ] Previews font appearance
- [ ] Re-inserts to ROM correctly

**Labels:** enhancement, graphics, tools
**Milestone:** v2.4.0

---

## Priority: Low

### Issue 8: Auto-Generate DTE Table from Corpus
**Title:** Automatically generate optimal DTE table from text

**Description:**
Analyze text corpus and auto-generate optimized DTE table.

**Features:**
- Analyze all game text
- Calculate optimal 116 DTE sequences
- Generate complex.tbl automatically
- Compare with current DTE table
- Show compression improvements

**Technical Details:**
- Frequency analysis of n-grams (2-20 chars)
- Greedy algorithm for DTE selection
- Consider byte savings vs table size
- Validate generated table

**Acceptance Criteria:**
- [ ] Analyzes entire text corpus
- [ ] Generates optimal DTE table
- [ ] Shows improvement metrics
- [ ] Creates new complex.tbl
- [ ] Validates encoding/decoding

**Labels:** enhancement, optimization
**Milestone:** v2.5.0

---

### Issue 9: PO/XLIFF Translation Format Support
**Title:** Add support for standard translation file formats

**Description:**
Support industry-standard translation formats.

**Features:**
- Export to Gettext PO format
- Export to XLIFF format
- Import from PO/XLIFF
- Preserve metadata and comments
- Integration with CAT tools (memoQ, Trados, etc.)

**Technical Details:**
- Use polib for PO format
- Use lxml for XLIFF
- Map dialog IDs to msgid
- Preserve control codes as placeholders

**Acceptance Criteria:**
- [ ] Exports to PO format
- [ ] Exports to XLIFF format
- [ ] Imports from both formats
- [ ] Preserves control codes
- [ ] Compatible with CAT tools

**Labels:** enhancement, translation, formats
**Milestone:** v2.5.0

---

### Issue 10: Regression Testing Framework
**Title:** Create comprehensive regression test suite

**Description:**
Automated testing for all tools and features.

**Features:**
- Unit tests for all modules
- Integration tests for workflows
- ROM validation tests
- Encoding/decoding tests
- Performance benchmarks
- CI/CD integration

**Technical Details:**
- Use pytest framework
- Test fixtures with sample ROM data
- Mock ROM for unit tests
- GitHub Actions integration

**Acceptance Criteria:**
- [ ] 80%+ code coverage
- [ ] All critical paths tested
- [ ] CI/CD pipeline configured
- [ ] Performance benchmarks
- [ ] Automated on push

**Labels:** testing, quality
**Milestone:** v2.1.0

---

### Issue 11: Complete DTE Table Reverse Engineering
**Title:** Complete DTE compression table with all 116 sequences

**Description:**
The DTE (Dual Tile Encoding) compression system uses 116 multi-character sequences (bytes 0x3D-0x7E) to compress dialog text. Critical infrastructure bug has been fixed (trailing space preservation), but only 4 sequences have been verified from ROM.

**Verified Sequences:**
- 0x45 = "s "
- 0x49 = "l "
- 0x4B = "er"
- 0x5E = "ea"

**Goals:**
1. Reverse-engineer all 116 sequences from ROM bytes
2. Verify mappings against known dialog text
3. Update `complex.tbl` with correct byte→string mappings
4. Test encoding/decoding round-trip for all dialogs

**Approach:**
- Use `check_rom_bytes.py` to extract dialog bytes for known text
- Work backwards: known text → bytes → build verified mapping table
- Cross-reference with DataCrystal wiki (but verify, don't trust blindly)
- Alternative: Find authoritative .tbl file from TCRF/romhacking.net

**Acceptance Criteria:**
- [ ] All 116 DTE sequences verified from ROM
- [ ] complex.tbl updated with correct mappings
- [ ] Round-trip test passing for all dialogs
- [ ] Documentation of verification process

**Labels:** critical, dialog-system, reverse-engineering
**Milestone:** v2.0.0

---

### Issue 12: Research Dialog Command Functions
**Title:** Map all 69 control codes to their actual game functions

**Description:**
ROM analysis identified 69 unique control codes used in dialogs. Current status:
- **11 confirmed:** END, NEWLINE, WAIT, NAME, ITEM, SPACE, TEXTBOX_BELOW, TEXTBOX_ABOVE, CLEAR, PARA, PAGE
- **39 event parameters:** P10-P3B range (function unknown)
- **14 extended commands:** EXT_80-EXT_8F (multi-byte, function unknown)
- **5 unknown:** UNK_0B-UNK_0F (including 0x0C which is NOT green text)

**High-priority commands to identify:**
1. Shop menu trigger
2. Inn menu trigger  
3. Yes/No prompt command
4. Character movement/positioning commands
5. Character animation triggers

**Research Methods:**
1. Analyze ROM code in banks $00 (text rendering), $03 (script engine), $08 (dialog data)
2. Find command dispatch tables in disassembly
3. Trace command execution in emulator debugger
4. Cross-reference DataCrystal documentation
5. Analyze command context in dialogs (pattern analysis already done)

**Files:**
- `reports/dialog_command_analysis.md` - Frequency and pattern analysis
- `docs/DIALOG_COMMAND_MAPPING.md` - Detailed command contexts
- `tools/analysis/analyze_dialog_commands.py` - Analysis tool

**Acceptance Criteria:**
- [ ] All event parameters (P10-P3B) documented
- [ ] Extended commands (EXT_80-EXT_8F) documented
- [ ] Menu trigger commands identified
- [ ] Movement/positioning commands identified
- [ ] Updated DIALOG_COMMANDS.md with findings

**Labels:** critical, dialog-system, reverse-engineering
**Milestone:** v2.0.0

---

### Issue 13: Identify Menu System Commands
**Title:** Find and document shop/inn/yes-no menu trigger commands

**Description:**
Dialog text contains commands to:
1. Open shop menu
2. Open inn menu
3. Display yes/no prompts
4. Trigger other menu systems

**Current candidates from analysis:**
- Event parameters (P10-P3B range) likely include menu triggers
- Extended commands (EXT_80-EXT_8F) may control menu state
- Multi-byte commands may specify menu type and parameters

**Research approach:**
1. Find shop/inn dialogs in ROM
2. Analyze bytes used in these specific dialogs
3. Compare with regular dialogs to identify unique commands
4. Test in emulator to confirm menu triggers
5. Document parameters (item IDs, prices, etc.)

**Acceptance Criteria:**
- [ ] Shop menu trigger identified
- [ ] Inn menu trigger identified
- [ ] Yes/No prompt identified
- [ ] Menu parameters documented
- [ ] Test cases for each menu type

**Labels:** enhancement, dialog-system, reverse-engineering
**Milestone:** v2.1.0

---

### Issue 14: Dialog Positioning and Movement
**Title:** Implement and document dialog box positioning/movement commands

**Description:**
**Confirmed from DataCrystal:**
- 0x1A: Position textbox below characters
- 0x1B: Position textbox above characters

**Needs Investigation:**
- Character movement commands (0x36 may trigger movement)
- X/Y coordinate parameters for positioning
- Character animation triggers during dialog
- Screen scrolling during events

**Bank $03 analysis shows:**
- Text box configuration with X/Y coordinates in ASM
- Movement patterns linked to dialog events
- Multi-byte positioning commands

**Goals:**
1. Document exact function of positioning commands
2. Implement positioning in dialog editor
3. Test positioning with actual ROM
4. Create visual editor for dialog box placement

**Acceptance Criteria:**
- [ ] All positioning commands documented
- [ ] Movement commands identified
- [ ] Dialog editor supports positioning
- [ ] Visual preview of box placement
- [ ] Test ROM patches verify functionality

**Labels:** enhancement, dialog-system, editor
**Milestone:** v2.2.0

---

## How to Create Issues

For each issue above:

1. Go to https://github.com/TheAnsarya/ffmq-info/issues/new
2. Copy the Title
3. Copy the Description + Features + Technical Details + Acceptance Criteria
4. Add appropriate Labels
5. Assign to Milestone
6. Submit

Or use GitHub CLI:
```bash
gh issue create --title "Title" --body "Description..." --label "enhancement" --milestone "v2.1.0"
```
