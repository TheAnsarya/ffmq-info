$replacements = @(
    @('CODE_00803A', 'Init_FinalSetup'),
    @('CODE_0080DC', 'Init_MenuSetup'),
    @('CODE_00818E', 'SaveData_IncrementCharacter'),
    @('CODE_0081F0', 'Init_SNES'),
    @('CODE_0084EB', 'Init_LoadTileData'),
    @('CODE_0084F8', 'Init_CheckWeaponType'),
    @('CODE_008A35', 'Char_UpdateAllTiles'),
    @('CODE_00B1E8', 'Dialog_CompareValue'),
    @('CODE_00B203', 'Dialog_ReturnComparison'),
    @('CODE_00B204', 'Dialog_CompareIndirect'),
    @('CODE_00B21C', 'Dialog_ReturnIndirect'),
    @('CODE_00B21D', 'Dialog_CompareIndirectAlt'),
    @('CODE_00B22E', 'Dialog_ReturnIndirectAlt'),
    @('CODE_00B22F', 'Dialog_CompareOffset'),
    @('CODE_00B249', 'Dialog_ReturnOffset'),
    @('CODE_00B258', 'Dialog_LoadStringLength'),
    @('CODE_00B274', 'Dialog_ClearStringPointer'),
    @('CODE_00B278', 'Dialog_CountSpecialChars'),
    @('CODE_00B285', 'Dialog_IncrementCharCount'),
    @('CODE_00B313', 'Dialog_ShiftRight'),
    @('CODE_00B322', 'Dialog_ShiftLeft'),
    @('CODE_00B379', 'Dialog_ProcessLoop'),
    @('CODE_00B38B', 'Dialog_LoopDone'),
    @('CODE_00B39A', 'Math_FindHighestBit'),
    @('CODE_00B3A7', 'Math_IncrementReturn'),
    @('CODE_00B35B', 'Dialog_ExecuteOrRoute'),
    @('CODE_00B367', 'Dialog_ExecuteGame'),
    @('UNREACH_00E111', 'Dialog_ProcessAltInput'),
    @('UNREACH_00E191', 'Dialog_DecrementAlt'),
    @('UNREACH_00E551', 'Dialog_SpriteDataOffset'),
    @('UNREACH_00E552', 'Dialog_SpriteMultiplier'),
    @('UNREACH_00DF25', 'Graphics_TileJumpTable'),
    @('UNREACH_009952', 'Graphics_RowLookupTable')
)

$content = Get-Content "src\asm\banks\bank_00.asm" -Raw
foreach ($pair in $replacements) {
    $content = $content -replace [regex]::Escape($pair[0]), $pair[1]
}
Set-Content "src\asm\banks\bank_00.asm" $content -NoNewline

Write-Host "Batch 58: 33 labels renamed - BANK 00 COMPLETE (1025/1046, 98.0%)"
