---
name: Graphics Extraction Verification
about: Track verification of extracted graphics against reference screenshots
title: 'Verify [Graphic Type]: [Specific Element]'
labels: graphics, verification, asset-extraction
assignees: ''
---

## Graphics Element

**Type:** (Character Sprite / Enemy Sprite / UI Element / Background / Effect)  
**Name:** (e.g., "Benjamin Walking North Animation")  
**VRAM Range:** (e.g., $0000-$01FF)  
**Palette:** (e.g., Palette 0)

## Reference Screenshot

**Location:** `assets/screenshots/vram_dumps/[path]/[filename].png`  
**Frame Count:** (e.g., 4 frames for walking animation)  
**Resolution:** (e.g., 16×16 pixels per frame)

## Extraction Status

- [ ] Reference screenshot captured from emulator
- [ ] Graphics data extracted from ROM
- [ ] Converted to PNG format
- [ ] Palette applied correctly
- [ ] Pixel-perfect comparison passed
- [ ] Documentation updated

## Verification Method

- [ ] Manual visual comparison
- [ ] Automated pixel comparison (compare_extracted_sprites.py)
- [ ] In-game re-insertion test
- [ ] Emulator VRAM viewer validation

## Files

**Reference:** `assets/screenshots/vram_dumps/[category]/[name].png`  
**Extracted:** `build/extracted_graphics/[category]/[name].png`  
**Source Data:** `data/graphics/[name].bin` (ROM offset: $______)

## Notes

<!-- Add any notes about palette quirks, compression, animation timing, etc. -->

## Acceptance Criteria

- [ ] Extracted graphics match reference screenshot (>99% pixel accuracy)
- [ ] Re-inserted graphics display correctly in-game
- [ ] Graphics documented in code comments with screenshot link
- [ ] Extraction process documented for future reference
