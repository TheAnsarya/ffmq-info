#!/usr/bin/env python3
"""
Shop & Merchant System Editor

Comprehensive shop management system for RPG games.
Features include:
- Shop inventory management
- Dynamic pricing system
- Stock and availability control
- Conditional item access (flags, level, progression)
- Buy/sell price ratios
- Item categories and filtering
- Shop types (weapon, armor, item, inn, special)
- NPC merchant profiles
- Shop dialog customization
- Regional price variations
- Sale and discount systems
- Limited stock tracking
- Export to multiple formats

Shop Types:
- Weapon Shop: Equipment and weapons
- Armor Shop: Defensive equipment
- Item Shop: Consumables and tools
- Inn: Rest and recovery services
- Special: Unique/rare items
- Black Market: High prices, rare goods
"""

from dataclasses import dataclass, field
from enum import Enum
from typing import Dict, List, Optional, Tuple, Any
import pygame
import json


class ShopType(Enum):
    """Shop category types"""
    WEAPON = "weapon"
    ARMOR = "armor"
    ITEM = "item"
    INN = "inn"
    MAGIC = "magic"
    SPECIAL = "special"
    BLACK_MARKET = "black_market"
    GENERAL = "general"


class ItemCategory(Enum):
    """Item category types"""
    WEAPON = "weapon"
    ARMOR = "armor"
    ACCESSORY = "accessory"
    CONSUMABLE = "consumable"
    KEY_ITEM = "key_item"
    MATERIAL = "material"
    SPELL = "spell"
    SPECIAL = "special"


@dataclass
class ItemData:
    """Item information"""
    item_id: int
    name: str
    category: ItemCategory
    description: str
    base_price: int
    icon_id: int = 0
    stackable: bool = True
    max_stack: int = 99

    def get_sell_price(self, sell_ratio: float = 0.5) -> int:
        """Calculate sell price"""
        return int(self.base_price * sell_ratio)


@dataclass
class ShopItem:
    """Item in shop inventory"""
    item: ItemData
    stock: Optional[int] = None  # None = infinite
    discount: float = 0.0  # 0.0 to 1.0
    markup: float = 0.0  # Additional price multiplier
    available: bool = True
    unlock_flag: Optional[str] = None
    min_level: int = 1

    def get_price(self) -> int:
        """Calculate current selling price"""
        price = self.item.base_price
        price = int(price * (1 + self.markup))
        price = int(price * (1 - self.discount))
        return max(1, price)

    def is_available(self, player_level: int = 99, flags: set = None) -> bool:
        """Check if item is available for purchase"""
        if not self.available:
            return False

        if player_level < self.min_level:
            return False

        if self.unlock_flag and flags and self.unlock_flag not in flags:
            return False

        if self.stock is not None and self.stock <= 0:
            return False

        return True

    def purchase(self, quantity: int = 1) -> bool:
        """Purchase item, update stock"""
        if self.stock is None:
            return True

        if self.stock >= quantity:
            self.stock -= quantity
            return True

        return False


@dataclass
class Shop:
    """Shop definition"""
    shop_id: int
    name: str
    shop_type: ShopType
    inventory: List[ShopItem] = field(default_factory=list)
    sell_ratio: float = 0.5  # How much you get selling items
    greeting: str = "Welcome to my shop!"
    farewell: str = "Thank you! Come again!"

    # Shop properties
    buys_items: bool = True
    sells_items: bool = True
    can_rest: bool = False  # For inns
    rest_price: int = 50

    # Appearance
    merchant_sprite: int = 0
    shop_music: int = 0

    def add_item(self, item: ShopItem):
        """Add item to shop inventory"""
        self.inventory.append(item)

    def remove_item(self, item: ShopItem):
        """Remove item from shop"""
        if item in self.inventory:
            self.inventory.remove(item)

    def get_available_items(
        self,
        player_level: int = 99,
        flags: set = None,
        category: Optional[ItemCategory] = None
    ) -> List[ShopItem]:
        """Get list of available items"""
        items = [
            item for item in self.inventory
            if item.is_available(player_level, flags)
        ]

        if category:
            items = [item for item in items if item.item.category == category]

        return items

    def get_total_value(self) -> int:
        """Calculate total inventory value"""
        total = 0
        for shop_item in self.inventory:
            if shop_item.stock is None:
                total += shop_item.get_price() * 10  # Estimate for infinite
            else:
                total += shop_item.get_price() * shop_item.stock
        return total

    def to_dict(self) -> dict:
        """Convert to dictionary"""
        return {
            "shop_id": self.shop_id,
            "name": self.name,
            "shop_type": self.shop_type.value,
            "inventory": [
                {
                    "item_id": si.item.item_id,
                    "stock": si.stock,
                    "discount": si.discount,
                    "markup": si.markup,
                    "available": si.available,
                    "unlock_flag": si.unlock_flag,
                    "min_level": si.min_level,
                }
                for si in self.inventory
            ],
            "sell_ratio": self.sell_ratio,
            "greeting": self.greeting,
            "farewell": self.farewell,
            "buys_items": self.buys_items,
            "sells_items": self.sells_items,
            "can_rest": self.can_rest,
            "rest_price": self.rest_price,
            "merchant_sprite": self.merchant_sprite,
            "shop_music": self.shop_music,
        }


@dataclass
class ItemDatabase:
    """Database of all items"""
    items: Dict[int, ItemData] = field(default_factory=dict)

    def add(self, item: ItemData):
        """Add item to database"""
        self.items[item.item_id] = item

    def get(self, item_id: int) -> Optional[ItemData]:
        """Get item by ID"""
        return self.items.get(item_id)

    def get_by_category(self, category: ItemCategory) -> List[ItemData]:
        """Get all items in category"""
        return [item for item in self.items.values() if item.category == category]


class ShopDatabase:
    """Database of all shops"""

    def __init__(self):
        self.shops: Dict[int, Shop] = {}
        self.item_db = ItemDatabase()
        self._init_sample_data()

    def _init_sample_data(self):
        """Initialize sample shops and items"""
        # Create sample items
        items = [
            ItemData(1, "Potion", ItemCategory.CONSUMABLE,
                     "Restores 50 HP", 50),
            ItemData(2, "Hi-Potion", ItemCategory.CONSUMABLE,
                     "Restores 150 HP", 200),
            ItemData(3, "Ether", ItemCategory.CONSUMABLE,
                     "Restores 50 MP", 150),
            ItemData(4, "Phoenix Down", ItemCategory.CONSUMABLE,
                     "Revives KO'd ally", 300),
            ItemData(5, "Antidote", ItemCategory.CONSUMABLE,
                     "Cures poison", 30),
            ItemData(10, "Bronze Sword", ItemCategory.WEAPON,
                     "ATK +10", 100),
            ItemData(11, "Iron Sword", ItemCategory.WEAPON,
                     "ATK +20", 500),
            ItemData(12, "Steel Sword", ItemCategory.WEAPON,
                     "ATK +35", 1500),
            ItemData(13, "Mythril Sword", ItemCategory.WEAPON,
                     "ATK +55", 4000),
            ItemData(20, "Leather Armor", ItemCategory.ARMOR,
                     "DEF +8", 80),
            ItemData(21, "Chain Mail", ItemCategory.ARMOR,
                     "DEF +18", 400),
            ItemData(22, "Plate Mail", ItemCategory.ARMOR,
                     "DEF +32", 1200),
            ItemData(30, "Power Ring", ItemCategory.ACCESSORY,
                     "STR +5", 800),
            ItemData(31, "Guard Ring", ItemCategory.ACCESSORY,
                     "DEF +10", 1000),
        ]

        for item in items:
            self.item_db.add(item)

        # Item shop
        item_shop = Shop(
            shop_id=1,
            name="Village Item Shop",
            shop_type=ShopType.ITEM,
            greeting="Welcome! Looking for supplies?",
            farewell="Take care on your journey!"
        )

        for item_id in [1, 2, 3, 4, 5]:
            item = self.item_db.get(item_id)
            if item:
                item_shop.add_item(ShopItem(item=item))

        self.shops[1] = item_shop

        # Weapon shop
        weapon_shop = Shop(
            shop_id=2,
            name="Town Weapon Shop",
            shop_type=ShopType.WEAPON,
            greeting="Looking for a fine blade?",
            sell_ratio=0.4
        )

        for item_id in [10, 11, 12]:
            item = self.item_db.get(item_id)
            if item:
                weapon_shop.add_item(ShopItem(item=item))

        # Mythril sword requires level 10
        mythril = self.item_db.get(13)
        if mythril:
            weapon_shop.add_item(
                ShopItem(item=mythril, min_level=10, unlock_flag="found_mythril"))

        self.shops[2] = weapon_shop

        # Armor shop
        armor_shop = Shop(
            shop_id=3,
            name="Town Armor Shop",
            shop_type=ShopType.ARMOR,
            greeting="Protect yourself with quality armor!",
        )

        for item_id in [20, 21, 22]:
            item = self.item_db.get(item_id)
            if item:
                armor_shop.add_item(ShopItem(item=item))

        self.shops[3] = armor_shop

        # Special shop with limited stock
        special_shop = Shop(
            shop_id=4,
            name="Rare Goods Trader",
            shop_type=ShopType.SPECIAL,
            greeting="I deal in rare items...",
            sell_ratio=0.3
        )

        for item_id in [30, 31]:
            item = self.item_db.get(item_id)
            if item:
                special_shop.add_item(
                    ShopItem(item=item, stock=3, markup=0.5))

        self.shops[4] = special_shop

        # Inn
        inn = Shop(
            shop_id=5,
            name="Cozy Inn",
            shop_type=ShopType.INN,
            greeting="Rest your weary bones!",
            buys_items=False,
            can_rest=True,
            rest_price=50
        )

        # Inns can also sell basic items
        for item_id in [1, 5]:
            item = self.item_db.get(item_id)
            if item:
                inn.add_item(ShopItem(item=item, markup=0.2))

        self.shops[5] = inn

    def add_shop(self, shop: Shop):
        """Add shop to database"""
        self.shops[shop.shop_id] = shop

    def get_shop(self, shop_id: int) -> Optional[Shop]:
        """Get shop by ID"""
        return self.shops.get(shop_id)

    def save_json(self, filename: str):
        """Save to JSON"""
        data = {
            "items": [
                {
                    "item_id": item.item_id,
                    "name": item.name,
                    "category": item.category.value,
                    "description": item.description,
                    "base_price": item.base_price,
                    "icon_id": item.icon_id,
                    "stackable": item.stackable,
                    "max_stack": item.max_stack,
                }
                for item in self.item_db.items.values()
            ],
            "shops": [shop.to_dict() for shop in self.shops.values()]
        }

        with open(filename, 'w') as f:
            json.dump(data, f, indent=2)

    def load_json(self, filename: str):
        """Load from JSON"""
        with open(filename, 'r') as f:
            data = json.load(f)

        # Load items
        self.item_db.items = {}
        for item_data in data.get("items", []):
            item = ItemData(
                item_id=item_data["item_id"],
                name=item_data["name"],
                category=ItemCategory(item_data["category"]),
                description=item_data["description"],
                base_price=item_data["base_price"],
                icon_id=item_data.get("icon_id", 0),
                stackable=item_data.get("stackable", True),
                max_stack=item_data.get("max_stack", 99),
            )
            self.item_db.add(item)

        # Load shops
        self.shops = {}
        for shop_data in data.get("shops", []):
            shop = Shop(
                shop_id=shop_data["shop_id"],
                name=shop_data["name"],
                shop_type=ShopType(shop_data["shop_type"]),
                sell_ratio=shop_data.get("sell_ratio", 0.5),
                greeting=shop_data.get("greeting", "Welcome!"),
                farewell=shop_data.get("farewell", "Thank you!"),
                buys_items=shop_data.get("buys_items", True),
                sells_items=shop_data.get("sells_items", True),
                can_rest=shop_data.get("can_rest", False),
                rest_price=shop_data.get("rest_price", 50),
                merchant_sprite=shop_data.get("merchant_sprite", 0),
                shop_music=shop_data.get("shop_music", 0),
            )

            # Load inventory
            for item_data in shop_data.get("inventory", []):
                item = self.item_db.get(item_data["item_id"])
                if item:
                    shop_item = ShopItem(
                        item=item,
                        stock=item_data.get("stock"),
                        discount=item_data.get("discount", 0.0),
                        markup=item_data.get("markup", 0.0),
                        available=item_data.get("available", True),
                        unlock_flag=item_data.get("unlock_flag"),
                        min_level=item_data.get("min_level", 1),
                    )
                    shop.add_item(shop_item)

            self.shops[shop.shop_id] = shop


class ShopSystemEditor:
    """Main shop system editor with UI"""

    def __init__(self, width: int = 1400, height: int = 900):
        self.width = width
        self.height = height
        self.running = True

        pygame.init()
        self.screen = pygame.display.set_mode((width, height))
        pygame.display.set_caption("Shop System Editor")
        self.clock = pygame.time.Clock()

        self.font = pygame.font.Font(None, 24)
        self.small_font = pygame.font.Font(None, 18)

        # Database
        self.database = ShopDatabase()
        self.current_shop: Optional[Shop] = None
        self.selected_shop_id: Optional[int] = None
        self.selected_item: Optional[ShopItem] = None

        # UI state
        self.shop_scroll = 0
        self.inventory_scroll = 0
        self.item_list_scroll = 0
        self.current_tab = "inventory"  # inventory, settings, items

        # Preview
        self.preview_level = 1
        self.preview_flags: set = set()

        # Select first shop
        if self.database.shops:
            first_id = min(self.database.shops.keys())
            self.current_shop = self.database.shops[first_id]
            self.selected_shop_id = first_id

    def run(self):
        """Main editor loop"""
        while self.running:
            self._handle_events()
            self._render()
            self.clock.tick(60)

        pygame.quit()

    def _handle_events(self):
        """Handle input events"""
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                self.running = False

            elif event.type == pygame.KEYDOWN:
                self._handle_command_input(event)

            elif event.type == pygame.MOUSEBUTTONDOWN:
                self._handle_mouse_click(event.pos, event.button)

            elif event.type == pygame.MOUSEWHEEL:
                if event.y != 0:
                    self.shop_scroll = max(0, self.shop_scroll - event.y * 30)

    def _handle_command_input(self, event):
        """Handle command input"""
        if event.key == pygame.K_ESCAPE:
            self.running = False

        # Tabs
        elif event.key == pygame.K_1:
            self.current_tab = "inventory"
        elif event.key == pygame.K_2:
            self.current_tab = "settings"
        elif event.key == pygame.K_3:
            self.current_tab = "items"

        # Preview level
        elif event.key == pygame.K_EQUALS or event.key == pygame.K_PLUS:
            self.preview_level = min(99, self.preview_level + 1)
        elif event.key == pygame.K_MINUS:
            self.preview_level = max(1, self.preview_level - 1)

        # Save/Load
        elif event.key == pygame.K_s and pygame.key.get_mods() & pygame.KMOD_CTRL:
            self.database.save_json("shops.json")
            print("Shops saved to shops.json")

        elif event.key == pygame.K_o and pygame.key.get_mods() & pygame.KMOD_CTRL:
            try:
                self.database.load_json("shops.json")
                print("Shops loaded from shops.json")
            except FileNotFoundError:
                print("No shops.json file found")

        # Navigation
        elif event.key == pygame.K_UP:
            shop_ids = sorted(self.database.shops.keys())
            if self.selected_shop_id in shop_ids:
                idx = shop_ids.index(self.selected_shop_id)
                if idx > 0:
                    self.selected_shop_id = shop_ids[idx - 1]
                    self.current_shop = self.database.shops[self.selected_shop_id]

        elif event.key == pygame.K_DOWN:
            shop_ids = sorted(self.database.shops.keys())
            if self.selected_shop_id in shop_ids:
                idx = shop_ids.index(self.selected_shop_id)
                if idx < len(shop_ids) - 1:
                    self.selected_shop_id = shop_ids[idx + 1]
                    self.current_shop = self.database.shops[self.selected_shop_id]

    def _handle_mouse_click(self, pos: Tuple[int, int], button: int):
        """Handle mouse click"""
        x, y = pos

        # Check shop list
        if x < 250 and button == 1:
            y_offset = 80 - self.shop_scroll

            for shop_id in sorted(self.database.shops.keys()):
                if y_offset <= y < y_offset + 60:
                    self.current_shop = self.database.shops[shop_id]
                    self.selected_shop_id = shop_id
                    self.selected_item = None
                    break
                y_offset += 65

        # Check tabs
        if 250 < x < self.width - 400 and 50 < y < 90:
            tab_width = (self.width - 650) // 3
            tab_index = (x - 250) // tab_width
            tabs = ["inventory", "settings", "items"]
            if 0 <= tab_index < len(tabs):
                self.current_tab = tabs[tab_index]

    def _render(self):
        """Render editor"""
        self.screen.fill((25, 25, 35))

        # Draw shop list
        self._draw_shop_list()

        # Draw tabs
        self._draw_tabs()

        # Draw current tab content
        if self.current_tab == "inventory":
            self._draw_inventory_tab()
        elif self.current_tab == "settings":
            self._draw_settings_tab()
        elif self.current_tab == "items":
            self._draw_items_tab()

        # Draw preview panel
        self._draw_preview_panel()

        # Draw toolbar
        self._draw_toolbar()

        pygame.display.flip()

    def _draw_shop_list(self):
        """Draw shop list panel"""
        panel_x = 0
        panel_y = 50
        panel_width = 250
        panel_height = self.height - 100

        # Background
        pygame.draw.rect(self.screen, (35, 35, 45),
                         (panel_x, panel_y, panel_width, panel_height))
        pygame.draw.rect(self.screen, (80, 80, 100),
                         (panel_x, panel_y, panel_width, panel_height), 2)

        # Title
        title = self.font.render("Shops", True, (255, 255, 255))
        self.screen.blit(title, (panel_x + 10, panel_y + 10))

        # Shop list
        y_offset = panel_y + 50 - self.shop_scroll

        for shop_id in sorted(self.database.shops.keys()):
            shop = self.database.shops[shop_id]

            if y_offset + 60 < panel_y or y_offset > panel_y + panel_height:
                y_offset += 65
                continue

            # Background
            bg_color = (60, 60, 80) if shop_id == self.selected_shop_id else (
                45, 45, 55)
            pygame.draw.rect(self.screen, bg_color,
                             (panel_x + 5, y_offset, panel_width - 10, 60))
            pygame.draw.rect(self.screen, (100, 100, 120),
                             (panel_x + 5, y_offset, panel_width - 10, 60), 1)

            # Shop ID and type
            id_text = self.small_font.render(
                f"#{shop_id} [{shop.shop_type.value}]", True, (180, 180, 180))
            self.screen.blit(id_text, (panel_x + 10, y_offset + 5))

            # Shop name
            name_text = self.small_font.render(
                shop.name, True, (200, 200, 255))
            self.screen.blit(name_text, (panel_x + 10, y_offset + 25))

            # Item count
            count_text = self.small_font.render(
                f"{len(shop.inventory)} items", True, (150, 150, 150))
            self.screen.blit(count_text, (panel_x + 10, y_offset + 42))

            y_offset += 65

    def _draw_tabs(self):
        """Draw tab bar"""
        tab_y = 50
        tab_x = 250
        tab_width = (self.width - 650) // 3
        tab_height = 35

        tabs = [
            ("Inventory", "inventory"),
            ("Settings", "settings"),
            ("All Items", "items"),
        ]

        for i, (label, tab_id) in enumerate(tabs):
            x = tab_x + i * tab_width

            # Background
            bg_color = (60, 60, 80) if tab_id == self.current_tab else (
                45, 45, 55)
            pygame.draw.rect(self.screen, bg_color,
                             (x, tab_y, tab_width, tab_height))
            pygame.draw.rect(self.screen, (100, 100, 120),
                             (x, tab_y, tab_width, tab_height), 2)

            # Label
            text = self.small_font.render(label, True, (255, 255, 255))
            text_rect = text.get_rect(
                center=(x + tab_width // 2, tab_y + tab_height // 2))
            self.screen.blit(text, text_rect)

    def _draw_inventory_tab(self):
        """Draw shop inventory tab"""
        if not self.current_shop:
            return

        panel_x = 250
        panel_y = 90
        panel_width = self.width - 650
        panel_height = self.height - 140

        # Background
        pygame.draw.rect(self.screen, (35, 35, 45),
                         (panel_x, panel_y, panel_width, panel_height))
        pygame.draw.rect(self.screen, (80, 80, 100),
                         (panel_x, panel_y, panel_width, panel_height), 2)

        # Inventory list
        y_offset = panel_y + 10 - self.inventory_scroll

        for shop_item in self.current_shop.inventory:
            if y_offset + 70 < panel_y or y_offset > panel_y + panel_height:
                y_offset += 75
                continue

            # Background
            bg_color = (55, 55, 70) if shop_item == self.selected_item else (
                45, 45, 55)
            pygame.draw.rect(self.screen, bg_color,
                             (panel_x + 10, y_offset, panel_width - 20, 70))
            pygame.draw.rect(self.screen, (100, 100, 120),
                             (panel_x + 10, y_offset, panel_width - 20, 70), 1)

            # Item name
            name_text = self.small_font.render(
                shop_item.item.name, True, (200, 200, 255))
            self.screen.blit(name_text, (panel_x + 20, y_offset + 5))

            # Price
            price = shop_item.get_price()
            price_text = self.small_font.render(
                f"Price: {price}G", True, (255, 255, 100))
            self.screen.blit(price_text, (panel_x + 20, y_offset + 25))

            # Stock
            if shop_item.stock is not None:
                stock_text = self.small_font.render(
                    f"Stock: {shop_item.stock}", True, (150, 150, 150))
            else:
                stock_text = self.small_font.render(
                    "Stock: Unlimited", True, (150, 150, 150))
            self.screen.blit(stock_text, (panel_x + 150, y_offset + 25))

            # Availability
            available = shop_item.is_available(
                self.preview_level, self.preview_flags)
            avail_color = (100, 255, 100) if available else (255, 100, 100)
            avail_text = "Available" if available else "Locked"
            avail_surf = self.small_font.render(
                avail_text, True, avail_color)
            self.screen.blit(avail_surf, (panel_x + 20, y_offset + 45))

            # Conditions
            conditions = []
            if shop_item.min_level > 1:
                conditions.append(f"Lv{shop_item.min_level}+")
            if shop_item.unlock_flag:
                conditions.append(f"Flag:{shop_item.unlock_flag}")
            if shop_item.discount > 0:
                conditions.append(f"-{int(shop_item.discount*100)}%")
            if shop_item.markup > 0:
                conditions.append(f"+{int(shop_item.markup*100)}%")

            if conditions:
                cond_text = self.small_font.render(
                    " | ".join(conditions), True, (150, 150, 150))
                self.screen.blit(cond_text, (panel_x + 150, y_offset + 45))

            y_offset += 75

    def _draw_settings_tab(self):
        """Draw shop settings tab"""
        if not self.current_shop:
            return

        panel_x = 250
        panel_y = 90
        panel_width = self.width - 650
        panel_height = self.height - 140

        # Background
        pygame.draw.rect(self.screen, (35, 35, 45),
                         (panel_x, panel_y, panel_width, panel_height))
        pygame.draw.rect(self.screen, (80, 80, 100),
                         (panel_x, panel_y, panel_width, panel_height), 2)

        # Settings
        settings = [
            ("Shop Name", self.current_shop.name),
            ("Shop Type", self.current_shop.shop_type.value),
            ("", ""),
            ("Greeting", self.current_shop.greeting),
            ("Farewell", self.current_shop.farewell),
            ("", ""),
            ("Sell Ratio", f"{int(self.current_shop.sell_ratio * 100)}%"),
            ("Buys Items", "Yes" if self.current_shop.buys_items else "No"),
            ("Sells Items", "Yes" if self.current_shop.sells_items else "No"),
            ("", ""),
            ("Can Rest", "Yes" if self.current_shop.can_rest else "No"),
            ("Rest Price", f"{self.current_shop.rest_price}G"),
            ("", ""),
            ("Merchant Sprite", str(self.current_shop.merchant_sprite)),
            ("Shop Music", str(self.current_shop.shop_music)),
        ]

        y_offset = panel_y + 20
        for label, value in settings:
            if not label:
                pygame.draw.line(self.screen, (60, 60, 80),
                                 (panel_x + 10, y_offset),
                                 (panel_x + panel_width - 10, y_offset), 1)
                y_offset += 10
                continue

            label_surf = self.small_font.render(
                f"{label}:", True, (200, 200, 200))
            self.screen.blit(label_surf, (panel_x + 20, y_offset))

            value_surf = self.small_font.render(
                value, True, (150, 150, 150))
            self.screen.blit(value_surf, (panel_x + 200, y_offset))

            y_offset += 25

    def _draw_items_tab(self):
        """Draw all items database tab"""
        panel_x = 250
        panel_y = 90
        panel_width = self.width - 650
        panel_height = self.height - 140

        # Background
        pygame.draw.rect(self.screen, (35, 35, 45),
                         (panel_x, panel_y, panel_width, panel_height))
        pygame.draw.rect(self.screen, (80, 80, 100),
                         (panel_x, panel_y, panel_width, panel_height), 2)

        # Item list
        y_offset = panel_y + 10 - self.item_list_scroll

        for item in sorted(self.database.item_db.items.values(),
                           key=lambda i: i.item_id):
            if y_offset + 60 < panel_y or y_offset > panel_y + panel_height:
                y_offset += 65
                continue

            # Background
            pygame.draw.rect(self.screen, (45, 45, 55),
                             (panel_x + 10, y_offset, panel_width - 20, 60))
            pygame.draw.rect(self.screen, (100, 100, 120),
                             (panel_x + 10, y_offset, panel_width - 20, 60), 1)

            # Item ID and name
            id_text = self.small_font.render(
                f"#{item.item_id}", True, (180, 180, 180))
            self.screen.blit(id_text, (panel_x + 20, y_offset + 5))

            name_text = self.small_font.render(
                item.name, True, (200, 200, 255))
            self.screen.blit(name_text, (panel_x + 80, y_offset + 5))

            # Category
            cat_text = self.small_font.render(
                item.category.value, True, (150, 200, 150))
            self.screen.blit(cat_text, (panel_x + 20, y_offset + 25))

            # Price
            price_text = self.small_font.render(
                f"{item.base_price}G", True, (255, 255, 100))
            self.screen.blit(price_text, (panel_x + 150, y_offset + 25))

            # Description
            desc_text = self.small_font.render(
                item.description, True, (150, 150, 150))
            self.screen.blit(desc_text, (panel_x + 20, y_offset + 42))

            y_offset += 65

    def _draw_preview_panel(self):
        """Draw shop preview panel"""
        panel_x = self.width - 400
        panel_y = 50
        panel_width = 400
        panel_height = self.height - 100

        # Background
        pygame.draw.rect(self.screen, (35, 35, 45),
                         (panel_x, panel_y, panel_width, panel_height))
        pygame.draw.rect(self.screen, (80, 80, 100),
                         (panel_x, panel_y, panel_width, panel_height), 2)

        if not self.current_shop:
            return

        # Title
        title = self.font.render(
            f"Shop Preview (Lv{self.preview_level})", True, (255, 255, 255))
        self.screen.blit(title, (panel_x + 10, panel_y + 10))

        # Available items
        available = self.current_shop.get_available_items(
            self.preview_level, self.preview_flags)

        count_text = self.small_font.render(
            f"Available: {len(available)}/{len(self.current_shop.inventory)}",
            True, (200, 200, 200))
        self.screen.blit(count_text, (panel_x + 10, panel_y + 40))

        # Total value
        total_value = self.current_shop.get_total_value()
        value_text = self.small_font.render(
            f"Total Value: {total_value}G", True, (255, 255, 100))
        self.screen.blit(value_text, (panel_x + 10, panel_y + 60))

        # Available items list
        y_offset = panel_y + 90

        for shop_item in available[:15]:  # Show first 15
            item_text = f"{shop_item.item.name}: {shop_item.get_price()}G"
            item_surf = self.small_font.render(
                item_text, True, (180, 180, 180))
            self.screen.blit(item_surf, (panel_x + 20, y_offset))
            y_offset += 20

        # Shop info
        y_offset = panel_y + panel_height - 150

        info_label = self.font.render("Shop Info", True, (200, 200, 255))
        self.screen.blit(info_label, (panel_x + 10, y_offset))
        y_offset += 30

        info_items = [
            f"Type: {self.current_shop.shop_type.value}",
            f"Sell Ratio: {int(self.current_shop.sell_ratio * 100)}%",
            f"Buys: {'Yes' if self.current_shop.buys_items else 'No'}",
            f"Sells: {'Yes' if self.current_shop.sells_items else 'No'}",
        ]

        if self.current_shop.can_rest:
            info_items.append(
                f"Rest: {self.current_shop.rest_price}G")

        for info in info_items:
            info_surf = self.small_font.render(
                info, True, (150, 150, 150))
            self.screen.blit(info_surf, (panel_x + 20, y_offset))
            y_offset += 20

    def _draw_toolbar(self):
        """Draw top toolbar"""
        toolbar_height = 40
        pygame.draw.rect(self.screen, (45, 45, 55),
                         (0, 0, self.width, toolbar_height))
        pygame.draw.rect(self.screen, (80, 80, 100),
                         (0, 0, self.width, toolbar_height), 2)

        # Title
        if self.current_shop:
            title = self.font.render(
                f"Shop: {self.current_shop.name}", True, (255, 255, 255))
            self.screen.blit(title, (10, 10))

        # Instructions
        help_text = "1-3:Tabs | ↑↓:Navigate | +/-:Preview Level | Ctrl+S:Save | Ctrl+O:Load"
        help_surf = self.small_font.render(help_text, True, (180, 180, 180))
        self.screen.blit(help_surf, (350, 12))


def main():
    """Run shop system editor"""
    editor = ShopSystemEditor()
    editor.run()


if __name__ == "__main__":
    main()
