# DTE Sequence Extraction Report

Analyzed 116 dialogs

## DTE Usage Summary

Total unique DTE bytes: 61
Expected DTE bytes (0x3D-0x7E): 66

### Most Common DTE Sequences

| Byte | Hex | Uses | Sample Contexts |
|------|-----|------|----------------|
|  64 | 0x40 |   67 | D33:4d54b6[40]41bb5e, D33:4d54b6[40]41bb5e |
|  65 | 0x41 |   55 | D0:46[41]464246, D6:46[41]464246 |
|  70 | 0x46 |   54 | D0:[46]414642, D0:[46]414642 |
|  68 | 0x44 |   38 | D33:305410[44]ffff1a, D57:362c11[44]1a15a5 |
|  77 | 0x4D |   35 | D33:411f01[4D]54b640, D33:411f01[4D]54b640 |
|  66 | 0x42 |   34 | D0:464146[42]464346, D6:464146[42]464346 |
|  69 | 0x45 |   32 | D3:fe05[45]620112, D22:[45]b55ec8 |
|  76 | 0x4C |   28 | D30:c8454f[4C]41c7c5, D33:ffc2bf[4C]a9c5c2 |
|  79 | 0x4F |   27 | D30:48c845[4F]4c41c7, D33:584b4d[4F]4cb7bc |
|  67 | 0x43 |   26 | D0:464246[43]46ffff, D6:464246[43]46ffff |
|  84 | 0x54 |   25 | D25:050d0e[54]9a160b, D33:1f014d[54]b64041 |
|  75 | 0x4B |   23 | D22:45b8c9[4B]ce00, D26:45b8c9[4B]ce00 |
|  92 | 0x5C |   22 | D33:5a41b0[5C]bfb7d2, D33:5a41b0[5C]bfb7d2 |
|  94 | 0x5E |   19 | D22:45b5[5E]c8c7bc, D26:45b5[5E]c8c7bc |
|  91 | 0x5B |   17 | D33:4bb873[5B]b4c74e, D33:4bb873[5B]b4c74e |
| 104 | 0x68 |   16 | D5:8b0524[68]011a00, D17:8b0524[68]011a00 |
|  96 | 0x60 |   16 | D30:c7c5b8[60]ce00, D33:ff4f4c[60]b6b4c3 |
| 105 | 0x69 |   16 | D33:58ffb6[69]40c7c5, D33:58ffb6[69]40c7c5 |
|  95 | 0x5F |   15 | D33:5cbf4c[5F]7bb657, D36:1e02ff[5F]7b3f5f |
|  87 | 0x57 |   14 | D33:b8b659[57]45c158, D33:b8b659[57]45c158 |
|  80 | 0x50 |   13 | D36:134110[50]4346ff, D63:2b0e2c[50]ff00 |
|  83 | 0x53 |   13 | D54:67c0b8[53]3166b7, D57:4da669[53]362bfd |
|  85 | 0x55 |   12 | D25:0b050a[55]9affff, D33:54bf59[55]b64fff |
|  88 | 0x58 |   12 | D33:4941a9[58]4b4d4f, D33:4941a9[58]4b4d4f |
|  71 | 0x47 |   12 | D33:b5b8bb[47]4c94ff, D33:b5b8bb[47]4c94ff |
|  86 | 0x56 |   12 | D33:3059a0[56]424630, D57:a5bc65[56]4da669 |
|  72 | 0x48 |   11 | D30:c6b4c9[48]c8454f, D33:c5b447[48]41bf52 |
|  63 | 0x3F |   11 | D33:c2c96a[3F]4bb873, D33:c2c96a[3F]4bb873 |
|  90 | 0x5A |   11 | D33:5ec542[5A]41b05c, D33:5ec542[5A]41b05c |
|  89 | 0x59 |   11 | D33:bbb8b6[59]c6b4cc, D33:bbb8b6[59]c6b4cc |

## Detailed DTE Analysis


### 0x3D (61)

**Uses:** 5

**Sample contexts:**
```
Dialog  33: <41><94><FF>[3D]<45><5A><41>
Dialog  33: <41><94><FF>[3D]<45><5A><41>
Dialog  65: <41><94><FF>[3D]<45><5A><41>
```

### 0x3F (63)

**Uses:** 11

**Often preceded by:** 'e' (1 times)

**Often followed by:** 'a' (2 times)

**Sample contexts:**
```
Dialog  33: ov<6A>[3F]<4B>e<73>
Dialog  33: ov<6A>[3F]<4B>e<73>
Dialog  36: <FF><5F><7B>[3F]<5F>ba
```

### 0x40 (64)

**Uses:** 67

**Often preceded by:** 'c' (24 times)

**Often followed by:** 'b' (9 times)

**Sample contexts:**
```
Dialog  33: <4D><54>c[40]<41>h<5E>
Dialog  33: <4D><54>c[40]<41>h<5E>
Dialog  33: <4D><54>c[40]<41>h<5E>
```

### 0x41 (65)

**Uses:** 55

**Often followed by:** 't' (7 times)

**Sample contexts:**
```
Dialog   0: <46>[41]<46><42><46>
Dialog   6: <46>[41]<46><42><46>
Dialog  12: <46>[41]<46><42><46>
```

### 0x42 (66)

**Uses:** 34

**Often preceded by:** 'r' (6 times)

**Often followed by:** 'h' (6 times)

**Sample contexts:**
```
Dialog   0: <46><41><46>[42]<46><43><46>
Dialog   6: <46><41><46>[42]<46><43><46>
Dialog  12: <46><41><46>[42]<46><43><46>
```

### 0x43 (67)

**Uses:** 26

**Often preceded by:** 'w' (6 times)

**Often followed by:** 'n' (7 times)

**Sample contexts:**
```
Dialog   0: <46><42><46>[43]<46><FF><FF>
Dialog   6: <46><42><46>[43]<46><FF><FF>
Dialog  12: <46><42><46>[43]<46><FF><FF>
```

### 0x44 (68)

**Uses:** 38

**Often preceded by:** '
' (1 times)

**Sample contexts:**
```
Dialog  33: <30><54><10>[44]<FF><FF><1A>
Dialog  57: <36><2C><11>[44]<1A><15>L
Dialog  57: <36><2C><11>[44]<1A><15>L
```

### 0x45 (69)

**Uses:** 32

**Often preceded by:** '
' (8 times)

**Often followed by:** 'n' (10 times)

**Sample contexts:**
```
Dialog   3: <FE><05>[45]<62>
<12>
Dialog  22: [45]b<5E>u
Dialog  22: [45]b<5E>u
```

### 0x46 (70)

**Uses:** 54

**Often followed by:** 'r' (3 times)

**Sample contexts:**
```
Dialog   0: [46]<41><46><42>
Dialog   0: [46]<41><46><42>
Dialog   0: [46]<41><46><42>
```

### 0x47 (71)

**Uses:** 12

**Often preceded by:** 'h' (4 times)

**Often followed by:** 'g' (5 times)

**Sample contexts:**
```
Dialog  33: beh[47]<4C><94><FF>
Dialog  33: beh[47]<4C><94><FF>
Dialog  54: <54><7E><3F>[47]<7D>so
```

### 0x48 (72)

**Uses:** 11

**Often preceded by:** 'y' (3 times)

**Often followed by:** 'm' (2 times)

**Sample contexts:**
```
Dialog  30: sav[48]u<45><4F>
Dialog  33: ra<47>[48]<41>l<52>
Dialog  62: <63>it[48]f<5C><FF>
```

### 0x49 (73)

**Uses:** 4

**Often preceded by:** 'u' (2 times)

**Often followed by:** 'a' (2 times)

**Sample contexts:**
```
Dialog  22: ifu[49]a<45>e
Dialog  26: ifu[49]a<45>e
Dialog  33: <4A><65><5E>[49]<41>P<58>
```

### 0x4A (74)

**Uses:** 10

**Often preceded by:** 'i' (5 times)

**Often followed by:** '[END]' (1 times)

**Sample contexts:**
```
Dialog  29: <14><12>[4A][END]
Dialog  33: <FF>wi[4A]<65><5E><49>
Dialog  33: <FF>wi[4A]<65><5E><49>
```

### 0x4B (75)

**Uses:** 23

**Often preceded by:** 'h' (9 times)

**Often followed by:** 'e' (10 times)

**Sample contexts:**
```
Dialog  22: <45>ev[4B]![END]
Dialog  26: <45>ev[4B]![END]
Dialog  33: v<6A><3F>[4B]e<73><5B>
```

### 0x4C (76)

**Uses:** 28

**Often preceded by:** 'l' (16 times)

**Often followed by:** 'P' (16 times)

**Sample contexts:**
```
Dialog  30: u<45><4F>[4C]<41>tr
Dialog  33: <FF>ol[4C]Pro
Dialog  33: <FF>ol[4C]Pro
```

### 0x4D (77)

**Uses:** 35

**Often preceded by:** '
' (10 times)

**Often followed by:** 'M' (8 times)

**Sample contexts:**
```
Dialog  33: <41><1F>
[4D]<54>c<40>
Dialog  33: <41><1F>
[4D]<54>c<40>
Dialog  33: <41><1F>
[4D]<54>c<40>
```

### 0x4E (78)

**Uses:** 8

**Often preceded by:** 'c' (5 times)

**Often followed by:** 'b' (4 times)

**Sample contexts:**
```
Dialog  33: <5B>at[4E]<41><1F>

Dialog  65: <5B>at[4E]<41><1F>

Dialog  74: Mac[4E]new
```

### 0x4F (79)

**Uses:** 27

**Often preceded by:** 'c' (5 times)

**Often followed by:** 'y' (4 times)

**Sample contexts:**
```
Dialog  30: <48>u<45>[4F]<4C><41>t
Dialog  33: <58><4B><4D>[4F]<4C>di
Dialog  33: <58><4B><4D>[4F]<4C>di
```

### 0x50 (80)

**Uses:** 13

**Often preceded by:** '
' (4 times)

**Sample contexts:**
```
Dialog  36: <13><41><10>[50]<43><46><FF>
Dialog  63: <2B><0E><2C>[50]<FF>[END]
Dialog  74: <2A><33><44>[50]<54><23><42>
```

### 0x51 (81)

**Uses:** 1

**Sample contexts:**
```
Dialog  75: m<56><10>[51]<40><46>[END]
```

### 0x52 (82)

**Uses:** 10

**Often preceded by:** 'n' (5 times)

**Often followed by:** '?' (2 times)

**Sample contexts:**
```
Dialog  33: <41>Kn[52]<FF>wi
Dialog  33: <41>Kn[52]<FF>wi
Dialog  39: <6C><4D>r[52]?<1B><89>
```

### 0x53 (83)

**Uses:** 13

**Often preceded by:** 'y' (2 times)

**Sample contexts:**
```
Dialog  54: <67>me[53]<31><66>d
Dialog  57: <4D>M<69>[53]<36><2B><FD>
Dialog  66: cy[53]<36><2A><27>
```

### 0x54 (84)

**Uses:** 25

**Often preceded by:** 'd' (2 times)

**Often followed by:** 'c' (6 times)

**Sample contexts:**
```
Dialog  25: <05><0D><0E>[54]A<16><0B>
Dialog  33: <1F>
<4D>[54]c<40><41>
Dialog  33: <1F>
<4D>[54]c<40><41>
```

### 0x55 (85)

**Uses:** 12

**Often followed by:** 'w' (4 times)

**Sample contexts:**
```
Dialog  25: <0B><05><0A>[55]A<FF><FF>
Dialog  33: <54>l<59>[55]c<4F><FF>
Dialog  54: n<58><FF>[55]wi<4A>
```

### 0x56 (86)

**Uses:** 12

**Often preceded by:** 'e' (4 times)

**Often followed by:** 's' (1 times)

**Sample contexts:**
```
Dialog  33: <30><59>G[56]<42><46><30>
Dialog  57: Li<65>[56]<4D>M<69>
Dialog  65: <30><59>G[56]<42><46><30>
```

### 0x57 (87)

**Uses:** 14

**Often preceded by:** 's' (1 times)

**Often followed by:** 'r' (2 times)

**Sample contexts:**
```
Dialog  33: ec<59>[57]<45>n<58>
Dialog  33: ec<59>[57]<45>n<58>
Dialog  33: ec<59>[57]<45>n<58>
```

### 0x58 (88)

**Uses:** 12

**Often preceded by:** 'H' (5 times)

**Sample contexts:**
```
Dialog  33: <49><41>P[58]<4B><4D><4F>
Dialog  33: <49><41>P[58]<4B><4D><4F>
Dialog  54: <4F><4C>n[58]<FF><55>w
```

### 0x59 (89)

**Uses:** 11

**Often preceded by:** 'c' (8 times)

**Often followed by:** 's' (8 times)

**Sample contexts:**
```
Dialog  33: hec[59]say
Dialog  33: hec[59]say
Dialog  33: hec[59]say
```

### 0x5A (90)

**Uses:** 11

**Often followed by:** 'D' (1 times)

**Sample contexts:**
```
Dialog  33: <5E>r<42>[5A]<41>W<5C>
Dialog  33: <5E>r<42>[5A]<41>W<5C>
Dialog  33: <5E>r<42>[5A]<41>W<5C>
```

### 0x5B (91)

**Uses:** 17

**Often followed by:** 'a' (15 times)

**Sample contexts:**
```
Dialog  33: <4B>e<73>[5B]at<4E>
Dialog  33: <4B>e<73>[5B]at<4E>
Dialog  33: <4B>e<73>[5B]at<4E>
```

### 0x5C (92)

**Uses:** 22

**Often preceded by:** 'W' (16 times)

**Often followed by:** 'l' (16 times)

**Sample contexts:**
```
Dialog  33: <5A><41>W[5C]ld.
Dialog  33: <5A><41>W[5C]ld.
Dialog  33: <5A><41>W[5C]ld.
```

### 0x5D (93)

**Uses:** 5

**Often followed by:** '.' (4 times)

**Sample contexts:**
```
Dialog  20: <25><2C><09>[5D].[END]
Dialog  51: <25><2C><09>[5D].[END]
Dialog  60: <25><2C><09>[5D].[END]
```

### 0x5E (94)

**Uses:** 19

**Often preceded by:** 'h' (8 times)

**Often followed by:** 'r' (11 times)

**Sample contexts:**
```
Dialog  22: <45>b[5E]uti
Dialog  26: <45>b[5E]uti
Dialog  28: [5E][END]
```

### 0x5F (95)

**Uses:** 15

**Often preceded by:** 'h' (5 times)

**Often followed by:** '
' (5 times)

**Sample contexts:**
```
Dialog  33: <5C>l<4C>[5F]<7B>c<57>
Dialog  36: <1E><02><FF>[5F]<7B><3F><5F>
Dialog  36: <1E><02><FF>[5F]<7B><3F><5F>
```

### 0x60 (96)

**Uses:** 16

**Often preceded by:** 'e' (3 times)

**Often followed by:** 'c' (4 times)

**Sample contexts:**
```
Dialog  30: tre[60]![END]
Dialog  33: <FF><4F><4C>[60]cap
Dialog  33: <FF><4F><4C>[60]cap
```

### 0x61 (97)

**Uses:** 3

**Often followed by:** 'A' (1 times)

**Sample contexts:**
```
Dialog  25: <05><0D><0F>[61]A<16><0A>
Dialog  74: <44>.<36>[61]<2A><33><44>
Dialog 110: <45><FF><FF>[61]<1A>TY
```

### 0x62 (98)

**Uses:** 9

**Often preceded by:** '
' (2 times)

**Often followed by:** '
' (4 times)

**Sample contexts:**
```
Dialog   3: <FE><05><45>[62]
<12><1A>
Dialog  25: <0A><05><0A>[62]A<FF>[END]
Dialog  36: 
<02>
[62]<2B>!<2A>
```

### 0x63 (99)

**Uses:** 8

**Sample contexts:**
```
Dialog  57: <2B><62><23>[63]<2B><6C>[END]
Dialog  62: <ED><FC><66>[63]<45><63>i
Dialog  62: <ED><FC><66>[63]<45><63>i
```

### 0x65 (101)

**Uses:** 10

**Often preceded by:** 'i' (2 times)

**Often followed by:** 'a' (2 times)

**Sample contexts:**
```
Dialog  33: wi<4A>[65]<5E><49><41>
Dialog  54: g<72><66>[65]art
Dialog  57: <15>Li[65]<56><4D>M
```

### 0x66 (102)

**Uses:** 10

**Often preceded by:** 'U' (2 times)

**Often followed by:** 'd' (3 times)

**Sample contexts:**
```
Dialog  54: e<53><31>[66]d<54><7E>
Dialog  54: e<53><31>[66]d<54><7E>
Dialog  54: e<53><31>[66]d<54><7E>
```

### 0x67 (103)

**Uses:** 6

**Often preceded by:** ''' (1 times)

**Often followed by:** 'l' (4 times)

**Sample contexts:**
```
Dialog  33: <4B><45><57>[67]loc
Dialog  33: <4B><45><57>[67]loc
Dialog  54: <4A>s<4B>[67]me<53>
```

### 0x68 (104)

**Uses:** 16

**Often preceded by:** 'k' (6 times)

**Often followed by:** '
' (3 times)

**Sample contexts:**
```
Dialog   5: <8B><05><24>[68]
<1A>[END]
Dialog  17: <8B><05><24>[68]
<1A>[END]
Dialog  33: ock[68]<41>do
```

### 0x69 (105)

**Uses:** 16

**Often preceded by:** 'c' (5 times)

**Often followed by:** 'e' (1 times)

**Sample contexts:**
```
Dialog  33: <58><FF>c[69]<40>tr
Dialog  33: <58><FF>c[69]<40>tr
Dialog  54: W<76>c[69]<40><46><41>
```

### 0x6A (106)

**Uses:** 3

**Often preceded by:** 'v' (2 times)

**Sample contexts:**
```
Dialog  33: <7D>ov[6A]<3F><4B>e
Dialog  54: <41>p<58>[6A]<5A>Da
Dialog  65: <7D>ov[6A]<3F><4B>e
```

### 0x6B (107)

**Uses:** 4

**Often preceded by:** 'u' (3 times)

**Often followed by:** '[END]' (1 times)

**Sample contexts:**
```
Dialog  74: <2B><69><23>[6B][END]
Dialog  89: i<68>u[6B]<4F><4C>h
Dialog  89: i<68>u[6B]<4F><4C>h
```

### 0x6C (108)

**Uses:** 7

**Often preceded by:** 'b' (5 times)

**Often followed by:** '[END]' (2 times)

**Sample contexts:**
```
Dialog  36: g<72>b[6C]<FF><46><1F>
Dialog  39: <60><42>b[6C]<4D>r<52>
Dialog  57: <23><63><2B>[6C][END]
```

### 0x6D (109)

**Uses:** 4

**Often preceded by:** 'm' (3 times)

**Often followed by:** 'b' (2 times)

**Sample contexts:**
```
Dialog  54: <4D><66>m[6D]s<57>r
Dialog  57: <60><FF>m[6D]b<40>s
Dialog  67: <60><FF>m[6D]b<40>s
```

### 0x6F (111)

**Uses:** 7

**Often preceded by:** 'y' (4 times)

**Often followed by:** 'W' (1 times)

**Sample contexts:**
```
Dialog  54: <7D>so[6F]W<40>w
Dialog  57: Hey[6F]<5B>a<42>
Dialog  57: Hey[6F]<5B>a<42>
```

### 0x70 (112)

**Uses:** 4

**Often followed by:** 't' (2 times)

**Sample contexts:**
```
Dialog  33: <73>A<42>[70]tim
Dialog  54: rt<68>[70]rum
Dialog  65: <73>A<42>[70]tim
```

### 0x71 (113)

**Uses:** 1

**Sample contexts:**
```
Dialog  39: <FF><FF><23>[71]<23><4D>[END]
```

### 0x72 (114)

**Uses:** 5

**Often preceded by:** 'g' (2 times)

**Often followed by:** 'b' (1 times)

**Sample contexts:**
```
Dialog  36: <4F><4C>g[72]b<6C><FF>
Dialog  39: <FF><FF>T[72]<41><1F><0B>
Dialog  54: <FF>ag[72]<66><65>a
```

### 0x73 (115)

**Uses:** 10

**Often preceded by:** 'e' (7 times)

**Often followed by:** 'I' (2 times)

**Sample contexts:**
```
Dialog  33: <3F><4B>e[73]<5B>at
Dialog  33: <3F><4B>e[73]<5B>at
Dialog  33: <3F><4B>e[73]<5B>at
```

### 0x75 (117)

**Uses:** 1

**Often followed by:** 's' (1 times)

**Sample contexts:**
```
Dialog  74: <FF><1A><60>[75]sur
```

### 0x76 (118)

**Uses:** 7

**Often preceded by:** 'h' (2 times)

**Often followed by:** 'p' (2 times)

**Sample contexts:**
```
Dialog  33: <68><5A>h[76]p.<30>
Dialog  54: !<30>W[76]c<69><40>
Dialog  65: <68><5A>h[76]p.<30>
```

### 0x77 (119)

**Uses:** 5

**Often followed by:** 's' (3 times)

**Sample contexts:**
```
Dialog  33: ap<68>[77]<41>ke
Dialog  65: ap<68>[77]<41>ke
Dialog  74: h<4B><40>[77]suc
```

### 0x78 (120)

**Uses:** 6

**Often followed by:** 'P' (3 times)

**Sample contexts:**
```
Dialog  54: <57>r<40>[78]t<4B>r
Dialog  74: ch<FF>[78]ba<4C>
Dialog  75: se<40>[78]swi
```

### 0x7A (122)

**Uses:** 2

**Often preceded by:** 'u' (1 times)

**Often followed by:** 'n' (1 times)

**Sample contexts:**
```
Dialog  54: <59>hu[7A]ns<4D>
Dialog  74: s<68><55>[7A]d<40>i
```

### 0x7B (123)

**Uses:** 9

**Often preceded by:** 'u' (1 times)

**Often followed by:** 'c' (4 times)

**Sample contexts:**
```
Dialog  33: l<4C><5F>[7B]c<57>o
Dialog  33: l<4C><5F>[7B]c<57>o
Dialog  36: <02><FF><5F>[7B]<3F><5F>b
```

### 0x7C (124)

**Uses:** 4

**Often followed by:** '
' (2 times)

**Sample contexts:**
```
Dialog  33: <30><94><FF>[7C]<4B><45><57>
Dialog  57: <8B><0E><05>[7C]
<08>&
Dialog  65: <30><94><FF>[7C]<4B><45><57>
```

### 0x7D (125)

**Uses:** 5

**Often preceded by:** 'o' (2 times)

**Often followed by:** 'o' (2 times)

**Sample contexts:**
```
Dialog  33: Loo[7D]ov<6A>
Dialog  54: <7E><3F><47>[7D]so<6F>
Dialog  65: Loo[7D]ov<6A>
```

### 0x7E (126)

**Uses:** 8

**Often followed by:** 'w' (2 times)

**Sample contexts:**
```
Dialog  38: <5F>
<05>[7E]<11><5F>

Dialog  54: <66>d<54>[7E]<3F><47><7D>
Dialog  54: <66>d<54>[7E]<3F><47><7D>
```

## Sample Dialog Decoding

First 10 dialogs with DTE sequences decoded using known characters:


### Dialog 0

**Bytes (10):** `46414642464346ffff00`

**Decoded:** [46][41][46][42][46][43][46]<FF><FF>[END]


### Dialog 1

**Bytes (10):** `06053608080808080700`

**Decoded:**  <05><36><08><08><08><08><08><07>[END]


### Dialog 2

**Bytes (4):** `cc230300`

**Decoded:** y<23><03>[END]


### Dialog 3

**Bytes (8):** `fe05456201121a00`

**Decoded:** <FE><05>{s }[62]
<12><1A>[END]


### Dialog 4

**Bytes (2):** `0200`

**Decoded:** <02>[END]


### Dialog 5

**Bytes (8):** `058b052468011a00`

**Decoded:** <05><8B><05><24>[68]
<1A>[END]


### Dialog 6

**Bytes (10):** `46414642464346ffff00`

**Decoded:** [46][41][46][42][46][43][46]<FF><FF>[END]


### Dialog 7

**Bytes (10):** `06053608080808080700`

**Decoded:**  <05><36><08><08><08><08><08><07>[END]


### Dialog 8

**Bytes (8):** `2a12272901ffff00`

**Decoded:** <2A><12><27><29>
<FF><FF>[END]


### Dialog 9

**Bytes (10):** `070882810acf88101d00`

**Decoded:** <07><08><82><81><0A>?<88><10><1D>[END]

