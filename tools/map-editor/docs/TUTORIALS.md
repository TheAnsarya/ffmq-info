# FFMQ Map Editor Tutorial Series

## Tutorial 1: Getting Started (10 Minutes)

### Introduction

Welcome to the Final Fantasy Mystic Quest Map Editor! This tutorial will guide you through creating your first map in just 10 minutes.

### Prerequisites

- Python 3.8 or higher installed
- Basic understanding of tile-based maps
- FFMQ ROM file (optional, for loading existing maps)

### Step 1: Installation (2 minutes)

```bash
# Navigate to the map editor directory
cd tools/map-editor

# Install dependencies
pip install -r requirements.txt

# Verify installation
python -c "import pygame, numpy; print('Ready!')"
```

### Step 2: Launch the Editor (1 minute)

```bash
python main.py
```

You should see the map editor window with:
- Main map view (center)
- Toolbar (left)
- Tileset panel (right)
- Layer panel (right)
- Properties panel (bottom-right)

### Step 3: Create a New Map (2 minutes)

1. Click **File → New** or press `Ctrl+N`
2. In the New Map dialog:
   - Name: "My First Map"
   - Type: Town
   - Width: 32 tiles
   - Height: 32 tiles
   - Tileset: 0
   - Palette: 0
3. Click **Create**

You now have a blank 32x32 map!

### Step 4: Select a Tile (1 minute)

1. Look at the **Tileset Panel** on the right
2. Click on any tile to select it
3. The selected tile will be highlighted
4. Tile information appears at the bottom of the panel

### Step 5: Paint Tiles (2 minutes)

1. Select the **Pencil Tool** (or press `P`)
2. Click and drag on the map to paint tiles
3. Try different tiles from the tileset
4. Use the **Eraser Tool** (`E`) to remove tiles

### Step 6: Use Layers (1 minute)

1. Look at the **Layer Panel**
2. Three layers are available:
   - **BG1 (Ground)**: Base terrain
   - **BG2 (Upper)**: Buildings, trees, etc.
   - **BG3 (Events)**: NPCs, triggers, etc.
3. Click a layer to select it
4. Paint on different layers to create depth

### Step 7: Save Your Map (1 minute)

1. Click **File → Save** or press `Ctrl+S`
2. Choose a location and filename
3. Your map is saved!

### Keyboard Shortcuts Reference

**File Operations:**
- `Ctrl+N`: New map
- `Ctrl+O`: Open map
- `Ctrl+S`: Save map
- `Ctrl+Z`: Undo
- `Ctrl+Y` or `Ctrl+Shift+Z`: Redo

**Tools:**
- `P`: Pencil (draw individual tiles)
- `B`: Bucket (flood fill)
- `E`: Eraser
- `R`: Rectangle
- `I`: Eyedropper (pick tile from map)

**Layers:**
- `1`: Select BG1 (Ground) layer
- `2`: Select BG2 (Upper) layer
- `3`: Select BG3 (Events) layer

**View:**
- `+` or Mouse Wheel Up: Zoom in
- `-` or Mouse Wheel Down: Zoom out
- `0`: Reset zoom
- `G`: Toggle grid
- Middle Mouse Button + Drag: Pan view

### Next Steps

Congratulations! You've created your first map. Continue to **Tutorial 2: Building a Town** to learn more advanced techniques.

---

## Tutorial 2: Building a Town (30 Minutes)

### What You'll Learn

- Creating structured layouts
- Using multiple layers effectively
- Adding buildings and decorations
- Setting up collision
- Placing NPCs and objects

### Part 1: Planning Your Town (5 minutes)

Before you start, sketch out your town layout:

```
# Example Town Layout
+------------------+
|  F    F      F   |  F = Fountain
|      INN         |  H = House
|   H    H         |  S = Shop
|      SHOP        |  * = Path
|   H    H    H    |
| *  *  *  *  *  * |
|         H        |
+------------------+
```

**Key Design Principles:**
- Leave space for paths (3 tiles wide is ideal)
- Group buildings by function
- Add open spaces for decorations
- Consider where player will enter

### Part 2: Create Ground Layer (5 minutes)

1. Create new map: 40x40 tiles, type "Town"
2. Select **BG1 (Ground)** layer
3. Use **Bucket Tool** (`B`):
   - Select grass tile (tile 1)
   - Click map to fill with grass
4. Create main path:
   - Select path tile (tile 2)
   - Select **Rectangle Tool** (`R`)
   - Draw path from bottom to top (3 tiles wide)
5. Add crosspath:
   - Draw horizontal path across middle

Your ground layer is complete!

### Part 3: Add Buildings (10 minutes)

1. Select **BG2 (Upper)** layer
2. Create town border wall:
   - Select wall tile (tile 10)
   - Use Rectangle Tool
   - Draw along edges (leave gaps for entrances)
   
3. Add Inn (top-left area):
   ```
   Building pattern (6x6 tiles):
   W W W W W W
   W         W
   W         W
   W         W
   W    D    W    (D = door)
   W W W W W W
   ```
   - Select building tile (tile 20)
   - Draw 6x6 rectangle
   - Select door tile (tile 21)
   - Place at bottom-center

4. Add Shop (top-right area):
   - Repeat building pattern
   - Use tile 22 for shop sign

5. Add Houses (4 small buildings):
   - Use 4x4 pattern for houses
   - Distribute around town
   - Add doors (tile 21)

### Part 4: Decorations (5 minutes)

Still on **BG2 layer**:

1. Add flowers (tile 5):
   - Place randomly on grass
   - Not on paths!
   - Clustered near buildings looks nice

2. Add fountain (tile 30-33):
   - Center of town square
   - Use 2x2 pattern

3. Add trees (tile 53):
   - Around town borders
   - Creates natural boundary

### Part 5: Set Up Collision (3 minutes)

Currently, you can't edit collision in the UI, but it's automatically set:
- Walls block movement
- Doors allow passage
- Decorations are walkable or blocking based on tile

To manually set collision (advanced):
- Use map data editor (coming in future update)
- Or edit in code/external tool

### Part 6: Add NPCs (2 minutes)

1. Click **Objects** panel
2. Select **NPC** type
3. Click on map to place NPCs:
   - Shopkeeper inside shop
   - Innkeeper inside inn
   - 3-4 townspeople around town
   - Guard at entrance

### Finishing Touches

1. Test your map:
   - Zoom out to see full layout
   - Check for tile errors
   - Verify paths connect

2. Set map properties:
   - Click **Properties** panel
   - Set music ID (1 for town music)
   - Set spawn point (entrance)

3. Save your map:
   - `Ctrl+S`
   - Name it "my_town.ffmap"

### Next Steps

Your town is complete! Try:
- Adding more detail
- Creating interior maps for buildings
- Connecting maps with warps
- **Tutorial 3: Dungeon Design** for different challenges

---

## Tutorial 3: Dungeon Design (45 Minutes)

### Introduction

Dungeons require different design approach than towns. You'll learn:
- Room-and-corridor layouts
- Puzzle elements
- Enemy encounters
- Treasure placement
- Multi-floor connections

### Part 1: Dungeon Theory (5 minutes)

**Good Dungeon Design:**
- Clear main path with optional areas
- Puzzles that aren't too obscure
- Balanced encounter rate
- Rewarding exploration
- Logical layout (no random mazes)

**FFMQ Dungeon Structure:**
```
Entrance → Room 1 → Corridor → Room 2 → Mini-Boss
                ↓
           Optional Room (Treasure)
                ↓
           Room 3 → Boss Room
```

### Part 2: Create Dungeon Framework (10 minutes)

1. New map: 64x64 tiles, type "Dungeon"
2. **BG1 (Ground)** layer:
   - Fill with stone floor (tile 30)
   
3. **BG2 (Upper)** layer - Create room structure:

**Room Layout Planning:**
```
[Entrance]───[Room 1]───[Corridor]───[Room 2]
                |                        |
           [Treasure]               [Mini-Boss]
                                        |
                                   [Corridor]
                                        |
                                    [Boss]
```

4. Draw rooms using Rectangle Tool:
   - Entrance room: 10x10
   - Main rooms: 12x12 each
   - Corridors: 3 tiles wide
   - Boss room: 16x16

### Part 3: Add Walls and Obstacles (10 minutes)

1. Create outer walls:
   - Wall tile (tile 31)
   - Draw perimeter of each room
   - Leave doorways (3 tiles wide)

2. Add internal pillars:
   - Pillar tile (tile 33)
   - Place in room corners
   - Creates navigation obstacles

3. Add breakable walls (puzzle element):
   - Cracked wall tile (tile 34)
   - Player must find switch/bomb
   - Blocks optional treasure

4. Add lava/hazards:
   - Lava tile (tile 35)
   - In corridors as obstacles
   - Damage player if touched

### Part 4: Puzzle Elements (10 minutes)

**Switch Puzzle:**
1. Place floor switches (tile 40)
   - In Room 1, three switches
   - Must all be pressed

2. Place locked door (tile 41)
   - Blocks path to Room 2
   - Opens when all switches pressed

**Block Pushing Puzzle:**
1. Place pushable blocks (tile 42)
   - In Treasure room
   - Must push onto switches

**Key and Door:**
1. Place colored doors (tiles 43-46)
   - Red door in corridor
   - Blue door to boss

2. Place keys in previous rooms
   - Red key in Room 1
   - Blue key in Room 2

### Part 5: Enemy Encounters (5 minutes)

1. Set map properties:
   - Encounter rate: 30 (medium)
   - Encounter group: 1 (dungeon enemies)

2. Add enemy spawn points (BG3 layer):
   - Spawn tile (tile 60)
   - Place in corridors
   - Place in open room areas
   - Higher density near boss

3. Add mini-boss position:
   - Boss tile (tile 61)
   - Center of mini-boss room

### Part 6: Treasure and Rewards (3 minutes)

1. Add treasure chests:
   - Use **Objects** panel
   - Select **Chest** type
   - Place strategically:
     - Hidden behind breakable walls
     - End of side paths
     - After tough enemy areas
     - 1-2 in each major room

2. Chest contents (set in properties):
   - Common chests: Potions, small gold
   - Hidden chests: Equipment, rare items
   - Boss chest: Key item or best reward

### Part 7: Visual Polish (2 minutes)

1. Add decorative elements:
   - Torches on walls (tile 36)
   - Bones/debris (tile 37)
   - Spider webs (tile 38)
   - Cracks in floor (tile 39)

2. Vary floor tiles:
   - Mix tile 30 and 31
   - Creates texture
   - Not too random though!

### Testing Your Dungeon

1. Walk through the full path:
   - Can you reach all areas?
   - Are puzzles solvable?
   - Is difficulty fair?

2. Check difficulty curve:
   - Early rooms easier
   - Gradual increase
   - Boss room hardest

3. Verify treasure:
   - Enough healing items?
   - Rewards match effort?
   - Optional areas worth exploring?

### Advanced Techniques

**Multi-Floor Dungeons:**
- Create separate map for each floor
- Use warp tiles to connect
- Maintain consistent theme

**Secret Areas:**
- Hidden paths (tile looks like wall)
- Breakable walls
- Switch-revealed rooms

**Boss Room Setup:**
- Large open space
- No obstacles (fair fight)
- Healing point before boss
- Save point before boss

### Next Steps

You've created a complete dungeon! Try:
- Adding more complex puzzles
- Creating themed dungeons (ice, fire, etc.)
- Multi-floor mega-dungeons
- **Tutorial 4: Overworld Design** for large-scale maps

---

## Tutorial 4: Overworld Design (60 Minutes)

### Introduction

The overworld is the largest, most complex map type. You'll learn:
- Large-scale map design (128x128+)
- Terrain variety and transitions
- Town and dungeon placement
- Path creation
- Balancing exploration and direction

### Coming Soon!

This tutorial is under development. Check back for:
- Continent design
- Terrain types and biomes
- Transportation systems
- Encounter zones
- Secret areas and Easter eggs

---

## Tutorial 5: Advanced Techniques

### Coming Soon!

- Custom tilesets
- Event scripting
- Complex warp systems
- Animated tiles
- Weather effects
- Day/night cycles

---

## Troubleshooting Guide

### Editor Won't Start

**Problem:** `ImportError: No module named pygame`
**Solution:**
```bash
pip install pygame numpy
```

**Problem:** Editor crashes on startup
**Solution:**
- Check Python version (3.8+ required)
- Update graphics drivers
- Try running from command line to see error

### Map Won't Save

**Problem:** "Permission denied" error
**Solution:**
- Check folder permissions
- Don't save to ROM directory
- Try different location

**Problem:** File size very large
**Solution:**
- Large maps create large files
- Use compression (FFMAP format)
- Consider splitting into multiple maps

### Performance Issues

**Problem:** Editor is slow/laggy
**Solution:**
- Reduce zoom level
- Close other applications
- Use smaller maps during editing
- Upgrade RAM if possible

### Rendering Issues

**Problem:** Tiles appear wrong colors
**Solution:**
- Tileset not loaded correctly
- Try reloading tileset
- Check palette settings

**Problem:** Grid lines missing
**Solution:**
- Press `G` to toggle grid
- Check zoom level (grid hides when too far out)

### Getting Help

- Check README.md for documentation
- Run test suite: `python tests/test_all.py`
- Submit bug reports on GitHub
- Join community Discord

---

## Tips and Tricks

### Keyboard Efficiency

Learn these shortcuts to work 10x faster:
- `Space + Drag`: Quick pan
- `Ctrl+D`: Duplicate selection
- `Shift+Click`: Select range
- `Alt+Click`: Pick tile under cursor

### Design Patterns

**The Rule of Thirds:**
- Divide map into 3x3 grid
- Place important elements at intersections
- Creates balanced, interesting layout

**Breadcrumb Trail:**
- Use visual cues to guide player
- Path of flowers
- Torch sequence
- Building alignment

**Rhythm and Pacing:**
- Safe area → danger → reward → repeat
- Don't overwhelm player
- Balance exploration and combat

### Performance Optimization

**For Large Maps:**
- Work on sections separately
- Merge when complete
- Use layers efficiently
- Minimize unique tiles

**Testing Workflow:**
- Test frequently (every 10 minutes)
- Make backups before major changes
- Use version control (git)
- Name files descriptively

### Creative Inspiration

**When Stuck:**
- Look at original FFMQ maps
- Study other RPGs
- Take breaks
- Start with simple shape, add detail

**Reference Real World:**
- Medieval towns for dungeon design
- Nature photos for overworld
- Architecture for buildings

---

## Appendix: Map Design Checklist

Before finalizing any map, check:

**Technical:**
- [ ] Map loads without errors
- [ ] All layers present
- [ ] Collision set correctly
- [ ] No tile glitches
- [ ] Proper boundaries
- [ ] File saves successfully

**Gameplay:**
- [ ] Player spawn point set
- [ ] All areas reachable
- [ ] Puzzles solvable
- [ ] Difficulty appropriate
- [ ] Treasures placed
- [ ] NPCs positioned
- [ ] Warps functional

**Polish:**
- [ ] Visual variety
- [ ] Consistent theme
- [ ] Decorations added
- [ ] No empty spaces
- [ ] Path obvious
- [ ] Tested by others

**Optimization:**
- [ ] File size reasonable
- [ ] Performance good
- [ ] No excessive unique tiles
- [ ] Compression enabled

Good luck with your map editing! 🎮
