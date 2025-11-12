================================================================================
Dictionary Compression Optimization Report
Final Fantasy Mystic Quest
================================================================================

## Compression Metrics

**Total Dictionary References**: 912
**Reference Bytes** (1 byte each): 912
**Expanded Bytes** (full text): 4,288
**Bytes Saved**: 3,376
**Compression Ratio**: 4.70:1
**Space Efficiency**: 78.7%

--------------------------------------------------------------------------------
## Efficiency Ranking (Top 20)

| Rank | Entry | Text | Length | Uses | Bytes Saved |
|------|-------|------|--------|------|-------------|
| 1 | 0x30 | [CMD:08][CMD:0E]O | 17 | 24 | 384 |
| 2 | 0x38 | [CMD:26][END][END]ieli#80i#8Bj | 91 | 4 | 360 |
| 3 | 0x50 | [ITEM][CMD:1D]E[END][NAME] | 26 | 13 | 325 |
| 4 | 0x36 | [CMD:08]ha#84 | 13 | 23 | 276 |
| 5 | 0x3C | [CMD:10][CMD:1D][END][ITEM]es[ | 46 | 6 | 270 |
| 6 | 0x32 | [CMD:08]#F7#83 | 14 | 17 | 221 |
| 7 | 0x34 | [CMD:0D]you[END][CMD:0D]to[END | 41 | 4 | 160 |
| 8 | 0x3A | [CMD:26][END][END]ieli#80i#8Bj | 141 | 1 | 140 |
| 9 | 0x51 | [ITEM][CMD:1E]E[END][NAME] | 26 | 5 | 125 |
| 10 | 0x44 | you | 3 | 50 | 100 |
| 11 | 0x53 | ... | 3 | 40 | 80 |
| 12 | 0x70 | that | 4 | 25 | 75 |
| 13 | 0x61 | [CMD:08][CMD:08]#8A#87#81 | 25 | 3 | 72 |
| 14 | 0x35 | [ITEM][CMD:18][END][CMD:10][CM | 35 | 2 | 68 |
| 15 | 0x60 | es | 2 | 58 | 58 |
| 16 | 0x41 | the | 3 | 27 | 54 |
| 17 | 0x48 | ing | 3 | 24 | 48 |
| 18 | 0x52 | ight | 4 | 15 | 45 |
| 19 | 0x6D | ust | 3 | 17 | 34 |
| 20 | 0x31 | [CMD:08]#E7#83 | 14 | 2 | 26 |

--------------------------------------------------------------------------------
## Underused Entries (25 total)

Entries with < 5 occurrences (candidates for replacement):

| Entry | Text | Length | Uses | Total Bytes |
|-------|------|--------|------|-------------|
| 0x31 | [CMD:08]#E7#83 | 14 | 2 | 26 |
| 0x33 | [CMD:08]o#84 | 12 | 1 | 11 |
| 0x34 | [CMD:0D]you[END][CMD:0D]to[END][END][END | 41 | 4 | 160 |
| 0x35 | [ITEM][CMD:18][END][CMD:10][CMD:08] | 35 | 2 | 68 |
| 0x37 | [CMD:26][END][CMD:20]'t | 23 | 0 | 0 |
| 0x38 | [CMD:26][END][END]ieli#80i#8Bjank[CMD:0E | 91 | 4 | 360 |
| 0x39 | [CMD:26][END][CMD:10]ieli#80i#8Bjank[CMD | 94 | 0 | 0 |
| 0x3A | [CMD:26][END][END]ieli#80i#8Bjank[CMD:0E | 141 | 1 | 140 |
| 0x3B | [CMD:26][END][CMD:10]ieli#80i#8Bjank[CMD | 151 | 0 | 0 |
| 0x3D | Crystal | 7 | 1 | 6 |
| 0x3E | RainbowRoad | 11 | 0 | 0 |
| 0x56 | en | 2 | 3 | 3 |
| 0x5D | I'll | 4 | 4 | 12 |
| 0x61 | [CMD:08][CMD:08]#8A#87#81 | 25 | 3 | 72 |
| 0x62 | [CMD:08]#8A#87 | 14 | 2 | 26 |
| 0x67 | ve | 2 | 1 | 1 |
| 0x6E | ![CMD:08]ha#84 | 14 | 0 | 0 |
| 0x6F | !\n | 2 | 4 | 4 |
| 0x71 | prophecy | 8 | 0 | 0 |
| 0x72 | o | 1 | 3 | 0 |
| 0x74 | .[CMD:08]ha#84 | 14 | 0 | 0 |
| 0x77 | with | 4 | 2 | 6 |
| 0x79 | Spencer | 7 | 1 | 6 |
| 0x7B | in | 2 | 3 | 3 |
| 0x7F | ieli#80i#8Bjank[CMD:0E]l[CMD:27]mNm[CMD: | 73 | 0 | 0 |

--------------------------------------------------------------------------------
## Optimization Recommendations

### For Fan Translators

1. **Preserve High-Value Entries**
   - Keep entries 0x30-0x45 (top 20 by efficiency)
   - These provide maximum compression benefit

2. **Replace Low-Value Entries**
   - 25 entries used < 5 times
   - Replace with common target language phrases
   - Prioritize long, frequently-used phrases

3. **Maintain Compression Ratio**
   - Current ratio: 4.70:1
   - Target: Maintain at least 2:1 for good efficiency

4. **Formatting Codes Integration**
   - Entries 0x50-0x51 use special formatting (codes 0x1D, 0x1E)
   - Test carefully if modifying these entries

### For ROM Hackers

1. **Expand Dictionary Space**
   - Current: 80 entries (0x30-0x7F)
   - Potential: Could extend if space allows

2. **Optimize Code 0x08 Usage**
   - Subroutine calls used 500+ times
   - Combine with dictionary for maximum efficiency

3. **Unused Entries**
   - 8 entries never used
   - Safe to replace without ROM testing

================================================================================
End of Report
================================================================================
