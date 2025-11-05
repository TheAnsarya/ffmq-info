# Documentation Update Checklist

Use this checklist when making changes to ensure documentation stays current.

## When Adding/Modifying Code

### Required Updates
- [ ] Add/update function header comments
  - [ ] Purpose and description
  - [ ] Parameters and their types
  - [ ] Return values
  - [ ] Side effects (RAM/register modifications)
- [ ] Update inline comments for complex logic
- [ ] Check if change affects any `.md` file in `docs/`

### System-Specific Documentation
Check and update relevant documentation files:

**Battle System Changes** → `docs/BATTLE_SYSTEM.md`, `docs/BATTLE_MECHANICS.md`
**Graphics Changes** → `docs/GRAPHICS_SYSTEM.md`, `docs/GRAPHICS_EXTRACTION_GUIDE.md`
**Text/Dialogue** → `docs/TEXT_SYSTEM.md`, `docs/TEXT_EDITING.md`
**Maps** → `docs/MAP_SYSTEM.md`, `docs/MAP_EDITING.md`
**Build System** → `docs/BUILD_GUIDE.md`, `BUILD_QUICK_START.md`
**Data Structures** → `docs/DATA_STRUCTURES.md`
**RAM/ROM Addresses** → `docs/RAM_MAP.md`, `docs/ROM_DATA_MAP.md`

### Tool/Script Changes
- [ ] Update tool's docstring/header comment
- [ ] Update `tools/README.md` if adding new tool
- [ ] Add usage examples to tool file or docs
- [ ] Update any related tutorial/guide documents

### Data Extraction Changes
- [ ] Update extraction guide (`docs/GRAPHICS_EXTRACTION_GUIDE.md`, etc.)
- [ ] Regenerate sample outputs if format changed
- [ ] Update schema/format documentation
- [ ] Update any JSON schema files

## When Adding New Features

### Core Documentation
- [ ] Add entry to `CHANGELOG.md`
- [ ] Update `README.md` if user-facing
- [ ] Add to relevant system documentation
- [ ] Consider if tutorial/example needed

### Asset Changes
- [ ] Document file formats
- [ ] Provide extraction/import examples
- [ ] Update build pipeline docs if affected

## Monthly Documentation Review

### General Health Check
- [ ] Verify all links work (internal and external)
- [ ] Check for outdated version numbers
- [ ] Review TODOs and fix/remove completed ones
- [ ] Update date stamps ("Last Updated:" headers)
- [ ] Check code examples still compile/work

### Coverage Check
- [ ] Identify undocumented systems
- [ ] Find functions without header comments
- [ ] Look for incomplete documentation sections
- [ ] Review issue tracker for doc-related issues

### Consistency Check
- [ ] Verify naming conventions followed
- [ ] Check formatting consistency
- [ ] Ensure cross-references are accurate
- [ ] Validate technical accuracy

## Documentation Standards

### File Headers
All `.md` files should have:
```markdown
# Title

**Last Updated:** YYYY-MM-DD  
**Status:** [Active/Draft/Deprecated]  
**Related:** Links to related docs/issues
```

### Code Comments
```asm
; ==============================================================================
; FunctionName - Brief description
; ==============================================================================
; Purpose: What the function does
; 
; Inputs:
;   A = Parameter description
;   X = Parameter description
;   
; Outputs:
;   Y = Return value description
;   
; Side Effects:
;   - Modifies $1234 (description)
;   - Calls external routine
; ==============================================================================
```

### Documentation Coverage Priority
1. **Critical (must document)**: Public APIs, data structures, build system
2. **High**: Complex algorithms, battle/graphics systems, extraction tools
3. **Medium**: Utility functions, data tables, minor systems
4. **Low**: Trivial helpers, temporary code

## Automation Opportunities

### Automated Documentation Generation
- [ ] Extract function signatures from ASM files
- [ ] Generate data structure reference from code
- [ ] Auto-update cross-references
- [ ] Generate table of contents
- [ ] Link validation script

### CI/CD Integration
- [ ] Markdown linter
- [ ] Link checker
- [ ] Example code validator
- [ ] Documentation coverage reporter

## Quick Reference

**Before committing:**
1. Did I update relevant `.md` files?
2. Did I add/update code comments?
3. Did I update `CHANGELOG.md`?
4. Do code examples still work?
5. Are cross-references accurate?

**PR Template automatically reminds you of documentation updates!**

---

**Remember:** Good documentation is as important as good code. Future you (and others) will thank present you!
