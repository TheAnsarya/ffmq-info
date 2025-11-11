# Dialog ASM Analysis Report

This report analyzes control code usage found in `assets/text/dialog.asm`.

Total control-code instances found: 501

## Top control codes by frequency

| Hex | Count | Example contexts |
|-----|------:|------------------|
| 0x00 | 245 | dlg 0 pos 13 (..adfefe99 [00] ..); dlg 1 pos 58 (..fefea0fe [00] ..); dlg 2 pos 187 (..05fefea9 [00] ..) |
| 0x02 | 62 | dlg 3 pos 112 (..9caffea9 [02] fefefea9..); dlg 5 pos 17 (..9caffea9 [02] fefefea9..); dlg 9 pos 12 (..adfefefe [02] feadfefe..) |
| 0x03 | 60 | dlg 9 pos 18 (..adfefefe [03] feadfefe..); dlg 15 pos 18 (..adfefefe [03] feadfefe..); dlg 19 pos 54 (..adfefec9 [03] fe039cfe..) |
| 0x06 | 40 | dlg 8 pos 104 (..a9fe01fe [06] fec2fea9..); dlg 8 pos 174 (..fefefea9 [06] fea9fefe..); dlg 8 pos 182 (..fefefea9 [06] fea9fefe..) |
| 0x01 | 37 | dlg 8 pos 102 (..c2fea9fe [01] fe06fec2..); dlg 8 pos 110 (..c2fea9fe [01] fefefefe..); dlg 14 pos 102 (..c2fea9fe [01] fe06fec2..) |
| 0x05 | 33 | dlg 2 pos 61 (..fefec59c [05] fea9fefe..); dlg 2 pos 71 (..fea9fefe [05] fefea9fe..); dlg 2 pos 148 (..fefec59c [05] fea9fefe..) |
| 0x04 | 24 | dlg 37 pos 49 (..fe93fea0 [04] 00..); dlg 58 pos 3 (..fefe9d [04] fe9dfefe..); dlg 66 pos 26 (..cdfefe90 [04] fefefefe..) |

## Suggested mappings (based on patterns)

- 0x00 = [END] (terminator)
- 0x01 = {newline} (line break)
- 0x02 = [WAIT] (wait for button)
- 0x03 = [ASTERISK] or special marker
- 0x23 = [CLEAR] (clear box)
- 0x30 = [PARA] (paragraph/line break)

## Next steps

- Cross-check these results with `tools/map-editor/dialog_database.py` and `tools/map-editor/utils/dialog_text.py`.
- Use the data to prioritize reverse-engineering of top-used parameterized codes (0x10-0x3B).
