# DataCrystal Wiki Documentation

This folder contains wikitext files for the Final Fantasy: Mystic Quest DataCrystal wiki pages.

## Purpose

These wikitext files serve as:
1. **Local documentation** - Complete reference for ROM/RAM/SRAM structures
2. **Wiki source** - Can be uploaded to DataCrystal wiki
3. **Integration bridge** - Links between wiki and GitHub repository

## DataCrystal Wiki Pages

- **Main Page**: https://datacrystal.tcrf.net/wiki/Final_Fantasy:_Mystic_Quest
- **ROM Map**: https://datacrystal.tcrf.net/wiki/Final_Fantasy:_Mystic_Quest/ROM_map
- **RAM Map**: https://datacrystal.tcrf.net/wiki/Final_Fantasy:_Mystic_Quest/RAM_map
- **SRAM Map**: https://datacrystal.tcrf.net/wiki/Final_Fantasy:_Mystic_Quest/SRAM_map
- **Text Table**: https://datacrystal.tcrf.net/wiki/Final_Fantasy:_Mystic_Quest/TBL
- **Notes**: https://datacrystal.tcrf.net/wiki/Final_Fantasy:_Mystic_Quest/Notes

## Files in This Folder

### Current Wikitext Files
- `Main.wikitext` - Main game page with ROM info, utilities, hacks
- `ROM_map.wikitext` - Complete ROM memory map with data structures
- `RAM_map.wikitext` - Runtime RAM map (partial - see GameInfo for complete)
- `SRAM_map.wikitext` - Save file structure map

### Planned Files
- `TBL.wikitext` - Text table/encoding (to be downloaded)
- `Notes.wikitext` - Hacking notes and research
- `Values.wikitext` - Enums and value lists (new page)

## Integration with Repository

### GitHub → DataCrystal Links

The wikitext files contain direct links to:
- **Source code**: `src/asm/*.asm`
- **Data files**: `data/extracted/*/*.json`, `data/converted/*/*.asm`
- **Tools**: `tools/extraction/*.py`, `tools/conversion/*.py`, `tools/*.py`
- **Documentation**: `docs/*.md`, `MODDING_QUICK_REFERENCE.md`

### DataCrystal → GitHub Links

From the main repository, link to wiki pages in:
- README.md "Documentation" section
- Tool script headers/docstrings
- Code comments referencing data structures
- `docs/DATACRYSTAL_LINKS.md` (to be created)

## Wikitext Format

These files use MediaWiki wikitext syntax:

### Common Syntax
```mediawiki
== Heading 2 ==
=== Heading 3 ===

* Bullet list
# Numbered list

[[Link to page]]
[https://example.com External link]

{| class="wikitable"
!  Header 1  !!  Header 2
|-
|  Cell 1  ||  Cell 2
|}

{{Template}}
{{Todo | Task description}}
```

### Special Templates
- `{{rommap}}` - ROM map designation
- `{{rammap}}` - RAM map designation
- `{{srammap}}` - SRAM map designation
- `{{Todo | text}}` - Mark incomplete sections
- `{{subpage|Name}}` - Link to subpages
- `{{Internal Data}}` - Standard footer

## Updating the Wiki

### Process
1. Edit `.wikitext` files locally
2. Test changes (validate syntax)
3. Commit to repository
4. Copy-paste wikitext to DataCrystal wiki editor
5. Preview changes
6. Save with edit summary

### Edit Summaries
Use descriptive edit summaries when updating wiki:
- "Add battle data structure documentation with GitHub links"
- "Complete enemy stats field descriptions"
- "Link extraction/conversion tools from repository"

## Documentation TODO

See `DATACRYSTAL_TODO.md` for comprehensive improvement plan.

### High Priority
- [ ] Complete ROM map battle data section
- [ ] Fill RAM map unknown gaps
- [ ] Add GitHub repository links throughout
- [ ] Create Values subpage

### Medium Priority
- [ ] Expand graphics documentation
- [ ] Complete SPC/music documentation
- [ ] Fill SRAM map gaps
- [ ] Add visual diagrams

### Low Priority  
- [ ] Advanced code documentation
- [ ] Modding tutorial subpages
- [ ] Complete cross-references

## Related Resources

### Official References
- DataCrystal Wiki: https://datacrystal.tcrf.net
- MediaWiki Help: https://www.mediawiki.org/wiki/Help:Formatting

### Community Resources
- GameFAQs Guides: https://gamefaqs.gamespot.com/snes/532476-final-fantasy-mystic-quest/faqs
- Mike's RPG Center: https://mikesrpgcenter.com/ffmq/
- Mesen Label File: https://raw.githubusercontent.com/TheAnsarya/GameInfo/refs/heads/main/Final%20Fantasy%20Mystic%20Quest%20(SNES)/Files/Final%20Fantasy%20-%20Mystic%20Quest%20(U)%20(V1.1).mlb

### GitHub Repositories
- **ffmq-info** (this repo): https://github.com/TheAnsarya/ffmq-info
- **GameInfo** (research): https://github.com/TheAnsarya/GameInfo/tree/main/Final%20Fantasy%20Mystic%20Quest%20(SNES)

## Contributing

To contribute to the DataCrystal documentation:

1. **Research**: Use disassembly, RAM viewers (Mesen), hex editors
2. **Document**: Update appropriate `.wikitext` file
3. **Verify**: Cross-check with multiple ROM versions
4. **Test**: Build ROM to verify offsets work
5. **Submit**: Create pull request or upload directly to wiki

## License

DataCrystal content is available under [GNU Free Documentation License 1.2](http://www.gnu.org/copyleft/fdl.html).

Repository code and tools are under MIT License (see main LICENSE file).

---

**Last Updated**: 2025-11-03  
**Status**: Initial creation, ROM map enhanced with GitHub integration  
**Next Steps**: Complete battle data documentation, fill RAM gaps
