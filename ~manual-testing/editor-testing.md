# Editor Testing Guide

Testing data editors (monsters, items, spells) in FFMQ.

## Monster Editor Testing

### TC-1: View Monster Stats

```powershell
python tools/enemy_editor.py --view 0
```

**Expected:** Behemoth stats displayed correctly.

### TC-2: Modify Monster HP

1. Edit monster HP value
2. Build ROM
3. Encounter monster in-game
4. Verify HP matches edit

### TC-3: Monster AI

1. Modify AI pattern
2. Test in battle
3. Verify behavior change

## Item Editor Testing

### TC-1: View Item Data

```powershell
python tools/item_editor.py --list
```

**Expected:** All items listed with stats.

### TC-2: Weapon Stats

1. Modify weapon attack value
2. Equip in-game
3. Verify damage output

## Spell Editor Testing

### TC-1: View Spells

```powershell
python tools/spell_editor.py --list
```

### TC-2: Spell Power

1. Modify spell damage
2. Cast in battle
3. Verify damage matches

## In-Emulator Test Locations

| Test | Save Location | Notes |
|------|---------------|-------|
| Early monsters | Level Tower | Low level enemies |
| Mid monsters | Ice Pyramid | Ice elemental |
| Late monsters | Doom Castle | Boss encounters |

## Related Documentation

- [GameInfo FFMQ Testing](https://github.com/TheAnsarya/GameInfo/tree/main/~manual-testing/game-specific/ffmq-snes)
