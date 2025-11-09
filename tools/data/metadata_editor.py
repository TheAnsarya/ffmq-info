"""
Game Metadata Editor for Final Fantasy Mystic Quest
Edit game data tables: enemies, items, weapons, armor, spells, shops.
"""

import pygame
import json
from dataclasses import dataclass, field, asdict
from typing import List, Tuple, Optional, Dict
from enum import Enum

# Initialize Pygame
pygame.init()

# Constants
WINDOW_WIDTH = 1800
WINDOW_HEIGHT = 950
FPS = 60

# Colors
COLOR_BG = (30, 30, 40)
COLOR_PANEL_BG = (45, 45, 55)
COLOR_BORDER = (80, 80, 90)
COLOR_TEXT = (220, 220, 230)
COLOR_HIGHLIGHT = (100, 150, 255)
COLOR_SUCCESS = (100, 255, 100)
COLOR_WARNING = (255, 200, 100)
COLOR_ERROR = (255, 100, 100)
COLOR_SELECTED = (255, 200, 50)
COLOR_FIELD_BG = (40, 40, 50)


class DataCategory(Enum):
    """Categories of game data"""
    ENEMY = "Enemies"
    ITEM = "Items"
    WEAPON = "Weapons"
    ARMOR = "Armor"
    SPELL = "Spells"
    SHOP = "Shops"


@dataclass
class Enemy:
    """Enemy data structure"""
    enemy_id: int
    name: str
    hp: int
    attack: int
    defense: int
    speed: int
    magic: int
    exp: int
    gold: int
    level: int
    weakness: str = "None"
    resistance: str = "None"
    drops: List[str] = field(default_factory=list)

    def to_dict(self):
        return asdict(self)


@dataclass
class Item:
    """Item data structure"""
    item_id: int
    name: str
    description: str
    item_type: str  # "Consumable", "Key", "Quest"
    effect: str
    value: int
    sellable: bool = True

    def to_dict(self):
        return asdict(self)


@dataclass
class Weapon:
    """Weapon data structure"""
    weapon_id: int
    name: str
    attack: int
    accuracy: int
    critical_rate: int
    element: str = "None"
    special_effect: str = "None"
    cost: int = 0

    def to_dict(self):
        return asdict(self)


@dataclass
class Armor:
    """Armor data structure"""
    armor_id: int
    name: str
    defense: int
    magic_defense: int
    armor_type: str  # "Helmet", "Armor", "Shield", "Accessory"
    element_resistance: str = "None"
    cost: int = 0

    def to_dict(self):
        return asdict(self)


@dataclass
class Spell:
    """Spell data structure"""
    spell_id: int
    name: str
    mp_cost: int
    power: int
    accuracy: int
    spell_type: str  # "Attack", "Heal", "Buff", "Debuff"
    element: str
    target: str  # "Single", "All Enemies", "All Allies", "Self"
    description: str = ""

    def to_dict(self):
        return asdict(self)


@dataclass
class Shop:
    """Shop data structure"""
    shop_id: int
    name: str
    location: str
    shop_type: str  # "Item", "Weapon", "Armor", "Inn"
    items_for_sale: List[int] = field(default_factory=list)
    prices: Dict[int, int] = field(default_factory=dict)

    def to_dict(self):
        return asdict(self)


class Button:
    """Interactive button"""
    def __init__(self, x, y, width, height, text, callback, enabled=True):
        self.rect = pygame.Rect(x, y, width, height)
        self.text = text
        self.callback = callback
        self.enabled = enabled
        self.hovered = False

    def draw(self, screen, font):
        if not self.enabled:
            color = (60, 60, 70)
            text_color = (100, 100, 110)
        else:
            color = COLOR_HIGHLIGHT if self.hovered else COLOR_BORDER
            text_color = COLOR_TEXT

        pygame.draw.rect(screen, COLOR_PANEL_BG, self.rect)
        pygame.draw.rect(screen, color, self.rect, 2)

        text_surf = font.render(self.text, True, text_color)
        text_rect = text_surf.get_rect(center=self.rect.center)
        screen.blit(text_surf, text_rect)

    def handle_event(self, event):
        if not self.enabled:
            return False

        if event.type == pygame.MOUSEMOTION:
            self.hovered = self.rect.collidepoint(event.pos)
        elif event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
            if self.rect.collidepoint(event.pos):
                self.callback()
                return True
        return False


class TextField:
    """Editable text field"""
    def __init__(self, x, y, width, label, initial_value="", numeric=False):
        self.rect = pygame.Rect(x, y + 20, width, 30)
        self.label_pos = (x, y)
        self.label = label
        self.value = str(initial_value)
        self.numeric = numeric
        self.active = False
        self.cursor_visible = True
        self.cursor_timer = 0

    def draw(self, screen, font, small_font):
        # Label
        label_surf = small_font.render(self.label, True, COLOR_TEXT)
        screen.blit(label_surf, self.label_pos)

        # Field background
        bg_color = COLOR_HIGHLIGHT if self.active else COLOR_FIELD_BG
        pygame.draw.rect(screen, bg_color, self.rect)
        pygame.draw.rect(screen, COLOR_BORDER, self.rect, 2)

        # Value text
        value_surf = font.render(self.value, True, COLOR_TEXT)
        value_rect = value_surf.get_rect(midleft=(self.rect.x + 5, self.rect.centery))
        screen.blit(value_surf, value_rect)

        # Cursor
        if self.active and self.cursor_visible:
            cursor_x = value_rect.right + 2
            pygame.draw.line(screen, COLOR_TEXT,
                           (cursor_x, self.rect.y + 5),
                           (cursor_x, self.rect.bottom - 5), 2)

        # Update cursor blink
        self.cursor_timer += 1
        if self.cursor_timer > 30:
            self.cursor_visible = not self.cursor_visible
            self.cursor_timer = 0

    def handle_event(self, event):
        if event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
            self.active = self.rect.collidepoint(event.pos)
            return self.active

        if self.active and event.type == pygame.KEYDOWN:
            if event.key == pygame.K_BACKSPACE:
                self.value = self.value[:-1]
            elif event.key == pygame.K_RETURN or event.key == pygame.K_TAB:
                self.active = False
            elif event.key == pygame.K_ESCAPE:
                self.active = False
            else:
                char = event.unicode
                if self.numeric:
                    if char.isdigit() or (char == '-' and len(self.value) == 0):
                        self.value += char
                else:
                    if char.isprintable():
                        self.value += char
            return True

        return False

    def get_value(self):
        """Get value with appropriate type"""
        if self.numeric:
            try:
                return int(self.value) if self.value else 0
            except ValueError:
                return 0
        return self.value


class DataList:
    """List of data entries with selection"""
    def __init__(self, x, y, width, height):
        self.rect = pygame.Rect(x, y, width, height)
        self.items: List = []
        self.item_height = 30
        self.selected_index: Optional[int] = None
        self.scroll_y = 0

    def set_items(self, items: List):
        """Update displayed items"""
        self.items = items

    def draw(self, screen, font, small_font):
        # Background
        pygame.draw.rect(screen, COLOR_PANEL_BG, self.rect)
        pygame.draw.rect(screen, COLOR_BORDER, self.rect, 2)

        # Title
        title = font.render("Data Entries", True, COLOR_TEXT)
        screen.blit(title, (self.rect.x + 10, self.rect.y + 10))

        # Count
        count_text = small_font.render(f"{len(self.items)} entries", True, (180, 180, 200))
        screen.blit(count_text, (self.rect.x + 10, self.rect.y + 32))

        # Clip to list area
        clip_rect = pygame.Rect(self.rect.x, self.rect.y + 60, self.rect.width, self.rect.height - 60)
        screen.set_clip(clip_rect)

        # Draw items
        y = self.rect.y + 60 + self.scroll_y
        for i, item in enumerate(self.items):
            item_rect = pygame.Rect(self.rect.x + 5, y, self.rect.width - 10, self.item_height - 2)

            # Only draw if visible
            if item_rect.bottom > self.rect.y + 60 and item_rect.top < self.rect.bottom:
                # Background
                if i == self.selected_index:
                    pygame.draw.rect(screen, COLOR_SELECTED, item_rect)
                elif item_rect.collidepoint(pygame.mouse.get_pos()):
                    pygame.draw.rect(screen, COLOR_HIGHLIGHT, item_rect)
                else:
                    pygame.draw.rect(screen, COLOR_FIELD_BG, item_rect)

                pygame.draw.rect(screen, COLOR_BORDER, item_rect, 1)

                # Text
                if isinstance(item, (Enemy, Item, Weapon, Armor, Spell, Shop)):
                    text = f"{item.name} (ID: {getattr(item, list(asdict(item).keys())[0])})"
                else:
                    text = str(item)

                text_surf = small_font.render(text[:40], True, COLOR_TEXT)
                screen.blit(text_surf, (item_rect.x + 5, item_rect.centery - 8))

            y += self.item_height

        screen.set_clip(None)

    def handle_click(self, pos):
        """Handle click in list"""
        if not self.rect.collidepoint(pos):
            return False

        # Adjust for scroll and header
        local_y = pos[1] - self.rect.y - 60 - self.scroll_y
        index = int(local_y // self.item_height)

        if 0 <= index < len(self.items):
            self.selected_index = index
            return True

        return False

    def scroll(self, amount):
        """Scroll the list"""
        self.scroll_y += amount
        content_height = len(self.items) * self.item_height
        max_scroll = max(0, content_height - (self.rect.height - 60))
        self.scroll_y = max(-max_scroll, min(0, self.scroll_y))

    def get_selected(self):
        """Get selected item"""
        if self.selected_index is not None and 0 <= self.selected_index < len(self.items):
            return self.items[self.selected_index]
        return None


class EditorPanel:
    """Panel for editing data entry fields"""
    def __init__(self, x, y, width, height):
        self.rect = pygame.Rect(x, y, width, height)
        self.fields: List[TextField] = []
        self.current_data = None
        self.data_type = None

    def set_data(self, data, data_type: DataCategory):
        """Set data to edit"""
        self.current_data = data
        self.data_type = data_type
        self.fields = []

        if data is None:
            return

        # Create fields based on data type
        x = self.rect.x + 10
        y = self.rect.y + 60
        field_width = (self.rect.width - 40) // 2

        data_dict = asdict(data)
        col = 0
        row = 0

        for key, value in data_dict.items():
            if key.endswith('_id'):
                continue  # Skip ID field

            field_x = x + col * (field_width + 10)
            field_y = y + row * 60

            # Determine if numeric
            numeric = isinstance(value, int)

            # Create label
            label = key.replace('_', ' ').title()

            field = TextField(field_x, field_y, field_width, label, value, numeric)
            self.fields.append(field)

            col += 1
            if col >= 2:
                col = 0
                row += 1

    def draw(self, screen, font, small_font):
        # Background
        pygame.draw.rect(screen, COLOR_PANEL_BG, self.rect)
        pygame.draw.rect(screen, COLOR_BORDER, self.rect, 2)

        # Title
        if self.data_type:
            title = font.render(f"Edit {self.data_type.value}", True, COLOR_TEXT)
        else:
            title = font.render("Editor", True, COLOR_TEXT)
        screen.blit(title, (self.rect.x + 10, self.rect.y + 10))

        if not self.current_data:
            no_data = small_font.render("No entry selected", True, (150, 150, 150))
            screen.blit(no_data, (self.rect.x + 10, self.rect.y + 50))
            return

        # Draw fields
        for field in self.fields:
            field.draw(screen, font, small_font)

    def handle_event(self, event):
        """Handle input events"""
        for field in self.fields:
            if field.handle_event(event):
                return True
        return False

    def apply_changes(self):
        """Apply field values back to data"""
        if not self.current_data:
            return

        data_dict = asdict(self.current_data)
        field_idx = 0

        for key in data_dict.keys():
            if key.endswith('_id'):
                continue

            if field_idx < len(self.fields):
                field = self.fields[field_idx]
                setattr(self.current_data, key, field.get_value())
                field_idx += 1


class GameMetadataEditor:
    """Main metadata editor application"""
    def __init__(self):
        self.screen = pygame.display.set_mode((WINDOW_WIDTH, WINDOW_HEIGHT))
        pygame.display.set_caption("FFMQ Game Metadata Editor")
        self.clock = pygame.time.Clock()
        self.running = True

        # Fonts
        self.font = pygame.font.Font(None, 24)
        self.small_font = pygame.font.Font(None, 20)
        self.title_font = pygame.font.Font(None, 36)

        # Data storage
        self.enemies: List[Enemy] = self._load_test_enemies()
        self.items: List[Item] = self._load_test_items()
        self.weapons: List[Weapon] = self._load_test_weapons()
        self.armor: List[Armor] = self._load_test_armor()
        self.spells: List[Spell] = self._load_test_spells()
        self.shops: List[Shop] = self._load_test_shops()

        # Current category
        self.current_category = DataCategory.ENEMY

        # UI Components
        self.data_list = DataList(10, 120, 400, 820)
        self.data_list.set_items(self.enemies)

        self.editor_panel = EditorPanel(430, 120, 900, 600)

        # Category buttons
        cat_y = 80
        cat_x = 10
        self.category_buttons = [
            Button(cat_x, cat_y, 120, 35, "Enemies", lambda: self.switch_category(DataCategory.ENEMY)),
            Button(cat_x + 130, cat_y, 120, 35, "Items", lambda: self.switch_category(DataCategory.ITEM)),
            Button(cat_x + 260, cat_y, 120, 35, "Weapons", lambda: self.switch_category(DataCategory.WEAPON)),
            Button(cat_x + 390, cat_y, 120, 35, "Armor", lambda: self.switch_category(DataCategory.ARMOR)),
            Button(cat_x + 520, cat_y, 120, 35, "Spells", lambda: self.switch_category(DataCategory.SPELL)),
            Button(cat_x + 650, cat_y, 120, 35, "Shops", lambda: self.switch_category(DataCategory.SHOP)),
        ]

        # Action buttons
        action_y = 740
        action_x = 430
        self.action_buttons = [
            Button(action_x, action_y, 140, 40, "Apply Changes", self.apply_changes),
            Button(action_x + 150, action_y, 140, 40, "New Entry", self.new_entry),
            Button(action_x + 300, action_y, 140, 40, "Delete Entry", self.delete_entry),
            Button(action_x + 450, action_y, 140, 40, "Export JSON", self.export_json),
            Button(action_x + 600, action_y, 140, 40, "Save to ROM", self.save_rom),
        ]

        # Status message
        self.status_message = ""
        self.status_color = COLOR_TEXT
        self.status_timer = 0

    def _load_test_enemies(self) -> List[Enemy]:
        """Load test enemy data"""
        return [
            Enemy(0, "Brownie", 40, 8, 4, 6, 2, 12, 20, 1, "Fire", "Ice", ["Cure Potion"]),
            Enemy(1, "Mad Plant", 80, 12, 6, 4, 4, 24, 40, 3, "Axe", "None", ["Heal Potion"]),
            Enemy(2, "Troll", 120, 16, 10, 5, 1, 48, 80, 5, "Thunder", "Earth", ["Seed"]),
            Enemy(3, "Skeleton", 100, 14, 8, 7, 3, 36, 60, 4, "Cure", "Dark", ["Life Potion"]),
            Enemy(4, "Ghost", 90, 10, 4, 10, 8, 42, 70, 4, "Cure", "Dark", ["Ether"]),
        ]

    def _load_test_items(self) -> List[Item]:
        """Load test item data"""
        return [
            Item(0, "Cure Potion", "Restores 60 HP", "Consumable", "Heal 60 HP", 30),
            Item(1, "Heal Potion", "Restores 120 HP", "Consumable", "Heal 120 HP", 60),
            Item(2, "Seed", "Restores 30 HP", "Consumable", "Heal 30 HP", 15),
            Item(3, "Life Potion", "Revives KO'd ally", "Consumable", "Revive 50% HP", 300),
            Item(4, "Ether", "Restores 30 MP", "Consumable", "Restore 30 MP", 100),
            Item(5, "Elixir", "Full HP/MP restore", "Consumable", "Full restore", 5000),
            Item(6, "Venus Key", "Opens Venus door", "Key", "Unlock door", 0, False),
        ]

    def _load_test_weapons(self) -> List[Weapon]:
        """Load test weapon data"""
        return [
            Weapon(0, "Steel Sword", 12, 80, 5, "None", "None", 100),
            Weapon(1, "Flame Sword", 20, 85, 10, "Fire", "Burn", 500),
            Weapon(2, "Ice Brand", 24, 85, 10, "Ice", "Freeze", 800),
            Weapon(3, "Thunder Axe", 28, 80, 15, "Thunder", "Stun", 1200),
            Weapon(4, "Cure Sword", 16, 90, 5, "Cure", "Heal", 300),
        ]

    def _load_test_armor(self) -> List[Armor]:
        """Load test armor data"""
        return [
            Armor(0, "Iron Helm", 8, 4, "Helmet", "None", 200),
            Armor(1, "Steel Armor", 16, 8, "Armor", "None", 600),
            Armor(2, "Flame Shield", 12, 10, "Shield", "Fire", 1000),
            Armor(3, "Ice Armor", 20, 12, "Armor", "Ice", 1500),
            Armor(4, "Magic Ring", 2, 20, "Accessory", "All", 3000),
        ]

    def _load_test_spells(self) -> List[Spell]:
        """Load test spell data"""
        return [
            Spell(0, "Fire", 4, 20, 95, "Attack", "Fire", "Single", "Fire damage to one enemy"),
            Spell(1, "Blizzard", 6, 30, 95, "Attack", "Ice", "Single", "Ice damage to one enemy"),
            Spell(2, "Thunder", 8, 40, 95, "Attack", "Thunder", "All Enemies", "Thunder damage to all enemies"),
            Spell(3, "Cure", 4, 40, 100, "Heal", "Cure", "Single", "Restore HP to one ally"),
            Spell(4, "Life", 10, 0, 100, "Heal", "Cure", "Single", "Revive KO'd ally"),
        ]

    def _load_test_shops(self) -> List[Shop]:
        """Load test shop data"""
        return [
            Shop(0, "Foresta Item Shop", "Foresta", "Item", [0, 1, 2], {0: 30, 1: 60, 2: 15}),
            Shop(1, "Foresta Weapon Shop", "Foresta", "Weapon", [0, 1], {0: 100, 1: 500}),
            Shop(2, "Aquaria Armor Shop", "Aquaria", "Armor", [0, 1, 2], {0: 200, 1: 600, 2: 1000}),
        ]

    def switch_category(self, category: DataCategory):
        """Switch data category"""
        self.current_category = category

        # Update data list
        if category == DataCategory.ENEMY:
            self.data_list.set_items(self.enemies)
        elif category == DataCategory.ITEM:
            self.data_list.set_items(self.items)
        elif category == DataCategory.WEAPON:
            self.data_list.set_items(self.weapons)
        elif category == DataCategory.ARMOR:
            self.data_list.set_items(self.armor)
        elif category == DataCategory.SPELL:
            self.data_list.set_items(self.spells)
        elif category == DataCategory.SHOP:
            self.data_list.set_items(self.shops)

        self.data_list.selected_index = None
        self.editor_panel.set_data(None, category)
        self.show_status(f"Switched to {category.value}", COLOR_SUCCESS)

    def apply_changes(self):
        """Apply editor changes to data"""
        self.editor_panel.apply_changes()
        self.show_status("Changes applied", COLOR_SUCCESS)

    def new_entry(self):
        """Create new data entry"""
        # Create default entry based on category
        if self.current_category == DataCategory.ENEMY:
            new_id = max([e.enemy_id for e in self.enemies], default=-1) + 1
            new_entry = Enemy(new_id, "New Enemy", 100, 10, 10, 10, 10, 50, 100, 1)
            self.enemies.append(new_entry)
            self.data_list.set_items(self.enemies)
        elif self.current_category == DataCategory.ITEM:
            new_id = max([i.item_id for i in self.items], default=-1) + 1
            new_entry = Item(new_id, "New Item", "Description", "Consumable", "Effect", 100)
            self.items.append(new_entry)
            self.data_list.set_items(self.items)
        # Add similar for other categories...

        self.show_status("New entry created", COLOR_SUCCESS)

    def delete_entry(self):
        """Delete selected entry"""
        selected = self.data_list.get_selected()
        if not selected:
            self.show_status("No entry selected", COLOR_WARNING)
            return

        # Remove from appropriate list
        if self.current_category == DataCategory.ENEMY:
            self.enemies.remove(selected)
            self.data_list.set_items(self.enemies)
        elif self.current_category == DataCategory.ITEM:
            self.items.remove(selected)
            self.data_list.set_items(self.items)
        # Add similar for other categories...

        self.editor_panel.set_data(None, self.current_category)
        self.show_status("Entry deleted", COLOR_SUCCESS)

    def export_json(self):
        """Export all data to JSON"""
        data = {
            'enemies': [e.to_dict() for e in self.enemies],
            'items': [i.to_dict() for i in self.items],
            'weapons': [w.to_dict() for w in self.weapons],
            'armor': [a.to_dict() for a in self.armor],
            'spells': [s.to_dict() for s in self.spells],
            'shops': [s.to_dict() for s in self.shops],
        }

        filename = 'game_metadata_export.json'
        with open(filename, 'w') as f:
            json.dump(data, f, indent=2)

        total = sum(len(v) for v in data.values())
        self.show_status(f"Exported {total} entries to {filename}", COLOR_SUCCESS)

    def save_rom(self):
        """Save data to ROM (placeholder)"""
        print("Would save data to ROM")
        self.show_status("Saved to ROM", COLOR_SUCCESS)

    def show_status(self, message: str, color):
        """Show status message"""
        self.status_message = message
        self.status_color = color
        self.status_timer = FPS * 3

    def handle_events(self):
        """Handle input events"""
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                self.running = False

            # Handle editor panel first (text fields)
            if self.editor_panel.handle_event(event):
                continue

            # Handle buttons
            for button in self.category_buttons + self.action_buttons:
                if button.handle_event(event):
                    continue

            # Mouse events
            if event.type == pygame.MOUSEBUTTONDOWN:
                if event.button == 1:  # Left click
                    if self.data_list.handle_click(event.pos):
                        selected = self.data_list.get_selected()
                        self.editor_panel.set_data(selected, self.current_category)

                elif event.button == 4:  # Scroll up
                    if self.data_list.rect.collidepoint(event.pos):
                        self.data_list.scroll(30)
                elif event.button == 5:  # Scroll down
                    if self.data_list.rect.collidepoint(event.pos):
                        self.data_list.scroll(-30)

            # Keyboard shortcuts
            elif event.type == pygame.KEYDOWN:
                if event.key == pygame.K_ESCAPE:
                    self.running = False
                elif event.key == pygame.K_s and (event.mod & pygame.KMOD_CTRL):
                    self.apply_changes()
                elif event.key == pygame.K_e and (event.mod & pygame.KMOD_CTRL):
                    self.export_json()

    def draw(self):
        """Draw the editor"""
        self.screen.fill(COLOR_BG)

        # Title bar
        title_bg = pygame.Rect(0, 0, WINDOW_WIDTH, 70)
        pygame.draw.rect(self.screen, COLOR_PANEL_BG, title_bg)
        pygame.draw.line(self.screen, COLOR_BORDER, (0, 70), (WINDOW_WIDTH, 70), 2)

        title = self.title_font.render("Game Metadata Editor", True, COLOR_TEXT)
        self.screen.blit(title, (20, 20))

        # Status message
        if self.status_timer > 0:
            status_text = self.small_font.render(self.status_message, True, self.status_color)
            self.screen.blit(status_text, (WINDOW_WIDTH - status_text.get_width() - 20, 25))
            self.status_timer -= 1

        # Draw components
        self.data_list.draw(self.screen, self.font, self.small_font)
        self.editor_panel.draw(self.screen, self.font, self.small_font)

        # Draw buttons
        for button in self.category_buttons + self.action_buttons:
            button.draw(self.screen, self.small_font)

        # Draw instructions
        inst_y = 810
        inst_x = 430
        instructions = [
            "Click entry to edit • Tab/Enter to move between fields • Ctrl+S to apply • Ctrl+E to export",
        ]
        for line in instructions:
            text = self.small_font.render(line, True, (150, 150, 160))
            self.screen.blit(text, (inst_x, inst_y))
            inst_y += 22

        pygame.display.flip()

    def run(self):
        """Main loop"""
        while self.running:
            self.handle_events()
            self.draw()
            self.clock.tick(FPS)

        pygame.quit()


def main():
    """Entry point"""
    editor = GameMetadataEditor()
    editor.run()


if __name__ == '__main__':
    main()
