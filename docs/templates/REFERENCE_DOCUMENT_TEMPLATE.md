# [Reference Name] Reference

**Type**: Technical Reference  
**Last Updated**: [Date]  
**Completeness**: [X%]  
**Related**: [Links to related references]

## Quick Lookup

| Name | Address/ID | Type | Description |
|------|------------|------|-------------|
| `item1` | `$0000` | Type | Brief description |
| `item2` | `$0001` | Type | Brief description |
| `item3` | `$0002` | Type | Brief description |

**Search Tips**: Use Ctrl+F to find by name or address

## Table of Contents

- [Overview](#overview)
- [Index](#index)
- [Detailed Reference](#detailed-reference)
- [Cross-References](#cross-references)
- [Usage Examples](#usage-examples)

## Overview

### Purpose
[What this reference documents]

### Scope
[What is included and what is not]

### Organization
[How this reference is structured]

### Notation Conventions

| Convention | Meaning | Example |
|------------|---------|---------|
| `$XXXX` | Hexadecimal address | `$7e0000` |
| `%XXXX` | Binary value | `%10101010` |
| `#$XX` | Immediate value | `#$01` |
| `[name]` | Placeholder | `[value]` |

## Index

### Alphabetical Index
- [A](#section-a)
- [B](#section-b)
- [C](#section-c)
- [...]

### By Category
- [Category 1](#category-1)
- [Category 2](#category-2)
- [Category 3](#category-3)

### By Address Range
- [$0000-$0fff](#range-1)
- [$1000-$1fff](#range-2)
- [$2000-$2fff](#range-3)

## Detailed Reference

### Section A

#### `item_name` / `$address`

**Type**: [Data Type]  
**Size**: [Size in bytes]  
**Access**: [Read/Write/Read-Only]  
**Bank**: [Bank number if applicable]

**Description**:
[Detailed description of what this is and what it does]

**Format**:
```
Offset | Size | Name      | Description
-------|------|-----------|-------------
$00    | 2    | field1    | Description
$02    | 1    | field2    | Description
$03    | 1    | flags     | Bit flags (see below)
```

**Flags** (if applicable):
```
Bit 7: Description
Bit 6: Description
Bit 5: Description
Bit 4: Description
Bit 3: Description
Bit 2: Description
Bit 1: Description
Bit 0: Description
```

**Values**:
| Value | Name | Description |
|-------|------|-------------|
| `$00` | VALUE_NAME | Meaning |
| `$01` | VALUE_NAME | Meaning |
| `$ff` | VALUE_NAME | Meaning |

**Usage**:
```assembly
; Example of typical usage
LDA item_name
CMP #$value
BEQ .label
```

**Notes**:
- Important note 1
- Important note 2
- Gotcha or limitation

**See Also**:
- [Related Item 1](#related-item-1)
- [Related Item 2](#related-item-2)

---

#### `another_item` / `$address`

[Repeat structure for each item]

### Section B

[Repeat structure for each section]

## Cross-References

### By Function/Purpose

#### Purpose Category 1
- `item1` - [Link](#item1)
- `item2` - [Link](#item2)
- `item3` - [Link](#item3)

#### Purpose Category 2
[Grouped items by what they do]

### Dependencies

#### `item_name` depends on:
- `dependency1` - Why
- `dependency2` - Why

#### `item_name` is used by:
- `user1` - How
- `user2` - How

### Memory Map Overview

```
Address Range | Purpose            | Items
--------------|-------------------|--------
$0000-$00ff   | System Variables  | item1, item2, item3
$0100-$01ff   | Game State        | item4, item5
$0200-$02ff   | Character Data    | item6, item7
```

## Usage Examples

### Example 1: [Common Task]

**Goal**: [What we're accomplishing]

**Code**:
```assembly
; Complete working example
LDA #$value
STA item_name
LDA another_item
CMP #$value
BNE .done
  ; Do something
.done
RTS
```

**Explanation**:
1. [Line-by-line explanation]
2. [Why we do this]
3. [What the result is]

### Example 2: [Advanced Usage]

[Another complete example]

### Example 3: [Edge Case]

[Example showing special situation]

## Appendices

### Appendix A: Complete Memory Map

```
Full memory layout table
```

### Appendix B: Bit Flag Reference

Quick reference table of all bit flags

### Appendix C: Value Enumerations

Complete list of all enumerated values

## Version History

| Version | Date | Changes | Updated By |
|---------|------|---------|------------|
| 1.0 | YYYY-MM-DD | Initial version | Name |
| 1.1 | YYYY-MM-DD | Added items X-Y | Name |
| 1.2 | YYYY-MM-DD | Updated item Z | Name |

## Contributing

### How to Add New Items

1. Follow the template structure above
2. Include all required fields
3. Add cross-references
4. Update the index
5. Add usage example if applicable

### Conventions
- Use consistent naming
- Include addresses in both decimal and hex
- Document all fields and flags
- Provide working code examples

---

**Completeness**: [X/Y items documented (Z%)]  
**Last Audit**: [Date]  
**Maintainer**: [Name]  
**Issues**: [Link to issue tracker]
