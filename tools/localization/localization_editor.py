#!/usr/bin/env python3
"""
Localization Editor

Comprehensive multi-language localization system.
Features include:
- Multi-language text tables
- String ID management
- Translation status tracking
- Character set validation
- String length warnings
- Context notes
- Fuzzy search
- Export to game format
- Import from CSV/JSON

Supported Languages:
- English (en)
- Japanese (ja)
- Spanish (es)
- French (fr)
- German (de)
- Italian (it)
- Portuguese (pt)
- Chinese Simplified (zh-CN)
- Chinese Traditional (zh-TW)
- Korean (ko)
"""

from dataclasses import dataclass, field
from enum import Enum
from typing import Dict, List, Optional, Set, Tuple
import pygame
import json
import csv


class TranslationStatus(Enum):
    """Translation completion status"""
    MISSING = "missing"
    DRAFT = "draft"
    REVIEW = "review"
    FINAL = "final"


class StringCategory(Enum):
    """String category types"""
    DIALOG = "dialog"
    UI = "ui"
    ITEM = "item"
    SKILL = "skill"
    CHARACTER = "character"
    LOCATION = "location"
    QUEST = "quest"
    SYSTEM = "system"
    TUTORIAL = "tutorial"
    ERROR = "error"


@dataclass
class LocalizedString:
    """Localized string with multi-language support"""
    string_id: str
    category: StringCategory
    context: str = ""  # Context/usage notes
    max_length: Optional[int] = None  # Character limit warning
    translations: Dict[str, str] = field(default_factory=dict)
    status: Dict[str, TranslationStatus] = field(default_factory=dict)

    def get_translation(self, language: str) -> str:
        """Get translation for language"""
        return self.translations.get(language, f"[{self.string_id}]")

    def set_translation(self, language: str, text: str, status: TranslationStatus = TranslationStatus.DRAFT):
        """Set translation"""
        self.translations[language] = text
        self.status[language] = status

    def get_status(self, language: str) -> TranslationStatus:
        """Get translation status"""
        if language not in self.translations:
            return TranslationStatus.MISSING
        return self.status.get(language, TranslationStatus.DRAFT)

    def is_complete(self, language: str) -> bool:
        """Check if translation is complete"""
        return self.get_status(language) == TranslationStatus.FINAL

    def is_over_length(self, language: str) -> bool:
        """Check if translation exceeds max length"""
        if self.max_length is None:
            return False
        text = self.get_translation(language)
        return len(text) > self.max_length

    def to_dict(self) -> dict:
        """Convert to dictionary"""
        return {
            "string_id": self.string_id,
            "category": self.category.value,
            "context": self.context,
            "max_length": self.max_length,
            "translations": self.translations,
            "status": {k: v.value for k, v in self.status.items()},
        }

    @staticmethod
    def from_dict(data: dict) -> 'LocalizedString':
        """Create from dictionary"""
        return LocalizedString(
            string_id=data["string_id"],
            category=StringCategory(data.get("category", "dialog")),
            context=data.get("context", ""),
            max_length=data.get("max_length"),
            translations=data.get("translations", {}),
            status={k: TranslationStatus(v) for k, v in data.get("status", {}).items()},
        )


@dataclass
class LanguageInfo:
    """Language metadata"""
    code: str
    name: str
    native_name: str
    font_family: Optional[str] = None
    requires_unicode: bool = False
    text_direction: str = "ltr"  # ltr or rtl


class LocalizationDatabase:
    """Database of localized strings"""

    # Supported languages
    LANGUAGES = {
        "en": LanguageInfo("en", "English", "English"),
        "ja": LanguageInfo("ja", "Japanese", "日本語", requires_unicode=True),
        "es": LanguageInfo("es", "Spanish", "Español"),
        "fr": LanguageInfo("fr", "French", "Français"),
        "de": LanguageInfo("de", "German", "Deutsch"),
        "it": LanguageInfo("it", "Italian", "Italiano"),
        "pt": LanguageInfo("pt", "Portuguese", "Português"),
        "zh-CN": LanguageInfo("zh-CN", "Chinese (Simplified)", "简体中文", requires_unicode=True),
        "zh-TW": LanguageInfo("zh-TW", "Chinese (Traditional)", "繁體中文", requires_unicode=True),
        "ko": LanguageInfo("ko", "Korean", "한국어", requires_unicode=True),
    }

    def __init__(self):
        self.strings: Dict[str, LocalizedString] = {}
        self.default_language = "en"
        self._init_sample_data()

    def _init_sample_data(self):
        """Initialize sample localization data"""
        # System strings
        self.add_string(LocalizedString(
            string_id="system.new_game",
            category=StringCategory.SYSTEM,
            context="Main menu option",
            max_length=20,
            translations={
                "en": "New Game",
                "ja": "新しいゲーム",
                "es": "Nuevo Juego",
                "fr": "Nouvelle Partie",
                "de": "Neues Spiel",
            },
            status={
                "en": TranslationStatus.FINAL,
                "ja": TranslationStatus.FINAL,
                "es": TranslationStatus.REVIEW,
                "fr": TranslationStatus.REVIEW,
                "de": TranslationStatus.DRAFT,
            }
        ))

        self.add_string(LocalizedString(
            string_id="system.continue",
            category=StringCategory.SYSTEM,
            context="Main menu option",
            max_length=20,
            translations={
                "en": "Continue",
                "ja": "続ける",
                "es": "Continuar",
                "fr": "Continuer",
                "de": "Fortsetzen",
            },
            status={
                "en": TranslationStatus.FINAL,
                "ja": TranslationStatus.FINAL,
                "es": TranslationStatus.FINAL,
                "fr": TranslationStatus.FINAL,
                "de": TranslationStatus.REVIEW,
            }
        ))

        # Dialog strings
        self.add_string(LocalizedString(
            string_id="dialog.welcome",
            category=StringCategory.DIALOG,
            context="Opening dialog from village elder",
            max_length=100,
            translations={
                "en": "Welcome, traveler! The kingdom is in great peril.",
                "ja": "ようこそ、旅人よ！王国は大きな危機にあります。",
                "es": "¡Bienvenido, viajero! El reino está en grave peligro.",
                "fr": "Bienvenue, voyageur! Le royaume est en grand péril.",
                "de": "Willkommen, Reisender! Das Königreich ist in großer Gefahr.",
            },
            status={
                "en": TranslationStatus.FINAL,
                "ja": TranslationStatus.REVIEW,
                "es": TranslationStatus.REVIEW,
                "fr": TranslationStatus.DRAFT,
                "de": TranslationStatus.DRAFT,
            }
        ))

        # Item strings
        self.add_string(LocalizedString(
            string_id="item.potion.name",
            category=StringCategory.ITEM,
            context="Basic healing potion name",
            max_length=30,
            translations={
                "en": "Healing Potion",
                "ja": "回復のポーション",
                "es": "Poción Curativa",
                "fr": "Potion de Soin",
                "de": "Heiltrank",
            },
            status={
                "en": TranslationStatus.FINAL,
                "ja": TranslationStatus.FINAL,
                "es": TranslationStatus.FINAL,
                "fr": TranslationStatus.FINAL,
                "de": TranslationStatus.FINAL,
            }
        ))

        self.add_string(LocalizedString(
            string_id="item.potion.desc",
            category=StringCategory.ITEM,
            context="Basic healing potion description",
            max_length=80,
            translations={
                "en": "Restores 50 HP. A basic remedy for minor injuries.",
                "ja": "HPを50回復する。軽い怪我に効く基本的な薬。",
                "es": "Restaura 50 PV. Un remedio básico para heridas menores.",
                "fr": "Restaure 50 PV. Un remède de base pour les blessures mineures.",
            },
            status={
                "en": TranslationStatus.FINAL,
                "ja": TranslationStatus.FINAL,
                "es": TranslationStatus.REVIEW,
                "fr": TranslationStatus.DRAFT,
            }
        ))

        # Quest strings
        self.add_string(LocalizedString(
            string_id="quest.tutorial.title",
            category=StringCategory.QUEST,
            context="First tutorial quest",
            max_length=50,
            translations={
                "en": "The Hero's Journey Begins",
                "ja": "英雄の旅の始まり",
                "es": "El Viaje del Héroe Comienza",
            },
            status={
                "en": TranslationStatus.FINAL,
                "ja": TranslationStatus.REVIEW,
                "es": TranslationStatus.DRAFT,
            }
        ))

        # UI strings
        self.add_string(LocalizedString(
            string_id="ui.hp",
            category=StringCategory.UI,
            context="Health points abbreviation",
            max_length=5,
            translations={
                "en": "HP",
                "ja": "HP",
                "es": "PV",
                "fr": "PV",
                "de": "LP",
            },
            status={
                "en": TranslationStatus.FINAL,
                "ja": TranslationStatus.FINAL,
                "es": TranslationStatus.FINAL,
                "fr": TranslationStatus.FINAL,
                "de": TranslationStatus.FINAL,
            }
        ))

        # Character strings
        self.add_string(LocalizedString(
            string_id="character.hero.name",
            category=StringCategory.CHARACTER,
            context="Main character default name",
            max_length=15,
            translations={
                "en": "Hero",
                "ja": "勇者",
                "es": "Héroe",
                "fr": "Héros",
                "de": "Held",
            },
            status={
                "en": TranslationStatus.FINAL,
                "ja": TranslationStatus.FINAL,
                "es": TranslationStatus.FINAL,
                "fr": TranslationStatus.FINAL,
                "de": TranslationStatus.FINAL,
            }
        ))

    def add_string(self, localized_string: LocalizedString):
        """Add localized string"""
        self.strings[localized_string.string_id] = localized_string

    def get_string(self, string_id: str) -> Optional[LocalizedString]:
        """Get localized string by ID"""
        return self.strings.get(string_id)

    def search_strings(self, query: str, language: Optional[str] = None) -> List[LocalizedString]:
        """Search for strings containing query"""
        query_lower = query.lower()
        results = []

        for string in self.strings.values():
            # Search in string ID
            if query_lower in string.string_id.lower():
                results.append(string)
                continue

            # Search in context
            if query_lower in string.context.lower():
                results.append(string)
                continue

            # Search in translations
            if language:
                text = string.get_translation(language).lower()
                if query_lower in text:
                    results.append(string)
            else:
                for text in string.translations.values():
                    if query_lower in text.lower():
                        results.append(string)
                        break

        return results

    def get_strings_by_category(self, category: StringCategory) -> List[LocalizedString]:
        """Get all strings in category"""
        return [s for s in self.strings.values() if s.category == category]

    def get_translation_stats(self, language: str) -> Dict[str, int]:
        """Get translation statistics for language"""
        stats = {
            "total": len(self.strings),
            "missing": 0,
            "draft": 0,
            "review": 0,
            "final": 0,
        }

        for string in self.strings.values():
            status = string.get_status(language)
            if status == TranslationStatus.MISSING:
                stats["missing"] += 1
            elif status == TranslationStatus.DRAFT:
                stats["draft"] += 1
            elif status == TranslationStatus.REVIEW:
                stats["review"] += 1
            elif status == TranslationStatus.FINAL:
                stats["final"] += 1

        return stats

    def export_csv(self, filename: str, languages: List[str]):
        """Export to CSV"""
        with open(filename, 'w', newline='', encoding='utf-8') as f:
            writer = csv.writer(f)

            # Header
            header = ["String ID", "Category", "Context", "Max Length"]
            for lang in languages:
                header.append(f"{lang} Text")
                header.append(f"{lang} Status")
            writer.writerow(header)

            # Data
            for string_id in sorted(self.strings.keys()):
                string = self.strings[string_id]
                row = [
                    string.string_id,
                    string.category.value,
                    string.context,
                    string.max_length or "",
                ]

                for lang in languages:
                    row.append(string.get_translation(lang))
                    row.append(string.get_status(lang).value)

                writer.writerow(row)

    def import_csv(self, filename: str):
        """Import from CSV"""
        with open(filename, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)

            for row in reader:
                string_id = row["String ID"]
                category = StringCategory(row["Category"])
                context = row.get("Context", "")
                max_length = int(row["Max Length"]) if row.get("Max Length") else None

                loc_string = LocalizedString(
                    string_id=string_id,
                    category=category,
                    context=context,
                    max_length=max_length,
                )

                # Import translations
                for key, value in row.items():
                    if key.endswith(" Text"):
                        lang = key.replace(" Text", "")
                        if value:
                            loc_string.translations[lang] = value
                    elif key.endswith(" Status"):
                        lang = key.replace(" Status", "")
                        if value:
                            loc_string.status[lang] = TranslationStatus(value)

                self.add_string(loc_string)

    def save_json(self, filename: str):
        """Save to JSON"""
        data = {
            "default_language": self.default_language,
            "strings": [s.to_dict() for s in self.strings.values()],
        }

        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)

    def load_json(self, filename: str):
        """Load from JSON"""
        with open(filename, 'r', encoding='utf-8') as f:
            data = json.load(f)

        self.default_language = data.get("default_language", "en")
        self.strings = {}

        for string_data in data.get("strings", []):
            loc_string = LocalizedString.from_dict(string_data)
            self.add_string(loc_string)


class LocalizationEditor:
    """Main localization editor with UI"""

    def __init__(self, width: int = 1600, height: int = 900):
        self.width = width
        self.height = height
        self.running = True

        pygame.init()
        self.screen = pygame.display.set_mode((width, height))
        pygame.display.set_caption("Localization Editor")
        self.clock = pygame.time.Clock()

        self.font = pygame.font.Font(None, 24)
        self.small_font = pygame.font.Font(None, 18)

        # Database
        self.database = LocalizationDatabase()

        # View state
        self.current_language = "en"
        self.filter_category: Optional[StringCategory] = None
        self.search_query = ""
        self.selected_string: Optional[LocalizedString] = None

        # UI state
        self.string_scroll = 0
        self.show_stats = True

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
                self.string_scroll = max(0, self.string_scroll - event.y * 30)

    def _handle_command_input(self, event):
        """Handle command input"""
        if event.key == pygame.K_ESCAPE:
            self.running = False

        # Save/Load
        elif event.key == pygame.K_s and pygame.key.get_mods() & pygame.KMOD_CTRL:
            self.database.save_json("localization.json")
            print("Localization saved to localization.json")

        elif event.key == pygame.K_o and pygame.key.get_mods() & pygame.KMOD_CTRL:
            try:
                self.database.load_json("localization.json")
                print("Localization loaded from localization.json")
            except FileNotFoundError:
                print("No localization.json file found")

        # Export CSV
        elif event.key == pygame.K_e and pygame.key.get_mods() & pygame.KMOD_CTRL:
            languages = ["en", "ja", "es", "fr", "de"]
            self.database.export_csv("localization.csv", languages)
            print("Exported to localization.csv")

        # Toggle stats
        elif event.key == pygame.K_t:
            self.show_stats = not self.show_stats

        # Language shortcuts (1-5)
        elif event.key == pygame.K_1:
            self.current_language = "en"
        elif event.key == pygame.K_2:
            self.current_language = "ja"
        elif event.key == pygame.K_3:
            self.current_language = "es"
        elif event.key == pygame.K_4:
            self.current_language = "fr"
        elif event.key == pygame.K_5:
            self.current_language = "de"

    def _handle_mouse_click(self, pos: Tuple[int, int], button: int):
        """Handle mouse click"""
        x, y = pos

        # Check string list
        if 50 < x < 600 and 80 < y < self.height - 50:
            strings = self._get_filtered_strings()
            y_offset = 80 - self.string_scroll

            for string in strings:
                if y_offset <= y < y_offset + 80:
                    self.selected_string = string
                    break
                y_offset += 85

        # Check category filters (top bar)
        elif 50 < y < 80:
            category_x = 50
            categories = [None] + list(StringCategory)

            for cat in categories:
                cat_name = "All" if cat is None else cat.value.title()
                cat_width = len(cat_name) * 10 + 20

                if category_x <= x < category_x + cat_width:
                    self.filter_category = cat
                    self.string_scroll = 0
                    break

                category_x += cat_width + 10

    def _get_filtered_strings(self) -> List[LocalizedString]:
        """Get filtered string list"""
        strings = list(self.database.strings.values())

        # Filter by category
        if self.filter_category is not None:
            strings = [s for s in strings if s.category == self.filter_category]

        # Search filter
        if self.search_query:
            strings = self.database.search_strings(
                self.search_query, self.current_language)

        # Sort by ID
        strings.sort(key=lambda s: s.string_id)

        return strings

    def _render(self):
        """Render editor"""
        self.screen.fill((25, 25, 35))

        # Draw toolbar
        self._draw_toolbar()

        # Draw category filters
        self._draw_category_filters()

        # Draw string list
        self._draw_string_list()

        # Draw properties panel
        self._draw_properties_panel()

        # Draw stats panel
        if self.show_stats:
            self._draw_stats_panel()

        pygame.display.flip()

    def _draw_toolbar(self):
        """Draw top toolbar"""
        toolbar_height = 40
        pygame.draw.rect(self.screen, (45, 45, 55),
                         (0, 0, self.width, toolbar_height))
        pygame.draw.rect(self.screen, (80, 80, 100),
                         (0, 0, self.width, toolbar_height), 2)

        # Title
        title = self.font.render("Localization Editor", True, (255, 255, 255))
        self.screen.blit(title, (10, 10))

        # Current language
        lang_info = LocalizationDatabase.LANGUAGES.get(self.current_language)
        if lang_info:
            lang_text = f"Language: {lang_info.name} ({lang_info.native_name})"
            lang_surf = self.small_font.render(lang_text, True, (180, 255, 180))
            self.screen.blit(lang_surf, (350, 12))

        # Help text
        help_text = "1-5:Language | T:Stats | Ctrl+S:Save Ctrl+O:Load Ctrl+E:ExportCSV"
        help_surf = self.small_font.render(help_text, True, (180, 180, 180))
        self.screen.blit(help_surf, (750, 12))

    def _draw_category_filters(self):
        """Draw category filter buttons"""
        filter_y = 50
        filter_height = 30

        pygame.draw.rect(self.screen, (35, 35, 45),
                         (0, filter_y, self.width, filter_height))

        category_x = 50
        categories = [None] + list(StringCategory)

        for cat in categories:
            cat_name = "All" if cat is None else cat.value.title()
            cat_width = len(cat_name) * 10 + 20

            # Button background
            bg_color = (80, 80, 120) if cat == self.filter_category else (50, 50, 70)
            pygame.draw.rect(self.screen, bg_color,
                             (category_x, filter_y + 5, cat_width, filter_height - 10))
            pygame.draw.rect(self.screen, (100, 100, 140),
                             (category_x, filter_y + 5, cat_width, filter_height - 10), 1)

            # Button text
            text_color = (255, 255, 100) if cat == self.filter_category else (200, 200, 200)
            cat_surf = self.small_font.render(cat_name, True, text_color)
            text_x = category_x + (cat_width - cat_surf.get_width()) // 2
            self.screen.blit(cat_surf, (text_x, filter_y + 10))

            category_x += cat_width + 10

    def _draw_string_list(self):
        """Draw string list panel"""
        panel_x = 0
        panel_y = 80
        panel_width = 600
        panel_height = self.height - 130

        # Background
        pygame.draw.rect(self.screen, (35, 35, 45),
                         (panel_x, panel_y, panel_width, panel_height))
        pygame.draw.rect(self.screen, (80, 80, 100),
                         (panel_x, panel_y, panel_width, panel_height), 2)

        # Get filtered strings
        strings = self._get_filtered_strings()

        # Draw strings
        y_offset = panel_y - self.string_scroll

        for string in strings:
            if y_offset + 80 < panel_y or y_offset > panel_y + panel_height:
                y_offset += 85
                continue

            # Background
            bg_color = (60, 60, 80) if string == self.selected_string else (45, 45, 55)
            pygame.draw.rect(self.screen, bg_color,
                             (panel_x + 5, y_offset, panel_width - 10, 80))
            pygame.draw.rect(self.screen, (100, 100, 120),
                             (panel_x + 5, y_offset, panel_width - 10, 80), 1)

            # Category badge
            category_colors = {
                StringCategory.DIALOG: (100, 150, 255),
                StringCategory.UI: (255, 200, 100),
                StringCategory.ITEM: (150, 255, 150),
                StringCategory.SKILL: (255, 150, 150),
                StringCategory.CHARACTER: (200, 150, 255),
                StringCategory.LOCATION: (150, 200, 200),
                StringCategory.QUEST: (255, 220, 150),
                StringCategory.SYSTEM: (180, 180, 180),
                StringCategory.TUTORIAL: (150, 255, 200),
                StringCategory.ERROR: (255, 100, 100),
            }
            cat_color = category_colors.get(string.category, (150, 150, 150))
            pygame.draw.circle(self.screen, cat_color,
                               (panel_x + 20, y_offset + 15), 8)

            # String ID
            id_text = self.small_font.render(
                string.string_id, True, (200, 200, 255))
            self.screen.blit(id_text, (panel_x + 35, y_offset + 8))

            # Translation text
            text = string.get_translation(self.current_language)
            if len(text) > 60:
                text = text[:57] + "..."

            text_surf = self.small_font.render(text, True, (180, 180, 180))
            self.screen.blit(text_surf, (panel_x + 35, y_offset + 28))

            # Status indicator
            status = string.get_status(self.current_language)
            status_colors = {
                TranslationStatus.MISSING: (255, 100, 100),
                TranslationStatus.DRAFT: (255, 200, 100),
                TranslationStatus.REVIEW: (150, 200, 255),
                TranslationStatus.FINAL: (150, 255, 150),
            }
            status_color = status_colors.get(status, (150, 150, 150))
            status_text = self.small_font.render(
                status.value.upper(), True, status_color)
            self.screen.blit(status_text, (panel_x + 35, y_offset + 48))

            # Length warning
            if string.is_over_length(self.current_language):
                warning_text = self.small_font.render(
                    "⚠ TOO LONG", True, (255, 100, 100))
                self.screen.blit(warning_text, (panel_x + 450, y_offset + 48))

            # Context preview
            if string.context:
                context_preview = string.context
                if len(context_preview) > 50:
                    context_preview = context_preview[:47] + "..."
                context_surf = self.small_font.render(
                    context_preview, True, (120, 120, 140))
                self.screen.blit(context_surf, (panel_x + 35, y_offset + 65))

            y_offset += 85

    def _draw_properties_panel(self):
        """Draw properties panel"""
        panel_x = 600
        panel_y = 80
        panel_width = 700
        panel_height = self.height - 130

        # Background
        pygame.draw.rect(self.screen, (35, 35, 45),
                         (panel_x, panel_y, panel_width, panel_height))
        pygame.draw.rect(self.screen, (80, 80, 100),
                         (panel_x, panel_y, panel_width, panel_height), 2)

        if not self.selected_string:
            # No selection message
            msg = self.font.render(
                "Select a string to view details", True, (150, 150, 150))
            self.screen.blit(
                msg, (panel_x + (panel_width - msg.get_width()) // 2, panel_y + 100))
            return

        # String ID
        y_offset = panel_y + 15
        id_label = self.font.render("String ID:", True, (200, 200, 255))
        self.screen.blit(id_label, (panel_x + 15, y_offset))
        y_offset += 30

        id_text = self.small_font.render(
            self.selected_string.string_id, True, (180, 180, 180))
        self.screen.blit(id_text, (panel_x + 25, y_offset))
        y_offset += 30

        # Category
        cat_label = self.font.render("Category:", True, (200, 200, 255))
        self.screen.blit(cat_label, (panel_x + 15, y_offset))
        y_offset += 30

        cat_text = self.small_font.render(
            self.selected_string.category.value.title(), True, (180, 180, 180))
        self.screen.blit(cat_text, (panel_x + 25, y_offset))
        y_offset += 30

        # Context
        if self.selected_string.context:
            ctx_label = self.font.render("Context:", True, (200, 200, 255))
            self.screen.blit(ctx_label, (panel_x + 15, y_offset))
            y_offset += 30

            # Word wrap context
            words = self.selected_string.context.split()
            line = ""
            for word in words:
                test_line = line + word + " "
                if len(test_line) > 60:
                    ctx_text = self.small_font.render(
                        line, True, (180, 180, 180))
                    self.screen.blit(ctx_text, (panel_x + 25, y_offset))
                    y_offset += 20
                    line = word + " "
                else:
                    line = test_line

            if line:
                ctx_text = self.small_font.render(line, True, (180, 180, 180))
                self.screen.blit(ctx_text, (panel_x + 25, y_offset))
                y_offset += 20

            y_offset += 10

        # Max length
        if self.selected_string.max_length:
            max_label = self.font.render("Max Length:", True, (200, 200, 255))
            self.screen.blit(max_label, (panel_x + 15, y_offset))

            max_text = self.small_font.render(
                f"{self.selected_string.max_length} characters",
                True, (180, 180, 180))
            self.screen.blit(max_text, (panel_x + 200, y_offset + 3))
            y_offset += 35

        # Translations
        trans_label = self.font.render("Translations:", True, (200, 200, 255))
        self.screen.blit(trans_label, (panel_x + 15, y_offset))
        y_offset += 35

        # Show all available translations
        for lang_code in ["en", "ja", "es", "fr", "de", "it", "pt"]:
            lang_info = LocalizationDatabase.LANGUAGES.get(lang_code)
            if not lang_info:
                continue

            # Language name
            lang_name = f"{lang_info.name}:"
            lang_surf = self.small_font.render(
                lang_name, True, (150, 200, 255))
            self.screen.blit(lang_surf, (panel_x + 25, y_offset))
            y_offset += 22

            # Translation text
            text = self.selected_string.get_translation(lang_code)

            # Word wrap
            words = text.split()
            line = ""
            for word in words:
                test_line = line + word + " "
                if len(test_line) > 55:
                    text_surf = self.small_font.render(
                        line, True, (180, 180, 180))
                    self.screen.blit(text_surf, (panel_x + 35, y_offset))
                    y_offset += 18
                    line = word + " "
                else:
                    line = test_line

            if line:
                text_surf = self.small_font.render(line, True, (180, 180, 180))
                self.screen.blit(text_surf, (panel_x + 35, y_offset))
                y_offset += 18

            # Status
            status = self.selected_string.get_status(lang_code)
            status_colors = {
                TranslationStatus.MISSING: (255, 100, 100),
                TranslationStatus.DRAFT: (255, 200, 100),
                TranslationStatus.REVIEW: (150, 200, 255),
                TranslationStatus.FINAL: (150, 255, 150),
            }
            status_color = status_colors.get(status, (150, 150, 150))
            status_surf = self.small_font.render(
                f"Status: {status.value.upper()}", True, status_color)
            self.screen.blit(status_surf, (panel_x + 35, y_offset))

            # Length check
            if self.selected_string.is_over_length(lang_code):
                current_len = len(text)
                max_len = self.selected_string.max_length
                warning_surf = self.small_font.render(
                    f"⚠ {current_len}/{max_len} chars", True, (255, 100, 100))
                self.screen.blit(warning_surf, (panel_x + 250, y_offset))

            y_offset += 30

    def _draw_stats_panel(self):
        """Draw statistics panel"""
        panel_x = 1300
        panel_y = 80
        panel_width = 300
        panel_height = 400

        # Background
        pygame.draw.rect(self.screen, (35, 35, 45),
                         (panel_x, panel_y, panel_width, panel_height))
        pygame.draw.rect(self.screen, (80, 80, 100),
                         (panel_x, panel_y, panel_width, panel_height), 2)

        # Title
        title = self.font.render("Statistics", True, (255, 255, 255))
        self.screen.blit(title, (panel_x + 10, panel_y + 10))

        y_offset = panel_y + 45

        # Get stats for current language
        stats = self.database.get_translation_stats(self.current_language)

        # Total strings
        total_text = self.small_font.render(
            f"Total Strings: {stats['total']}", True, (200, 200, 255))
        self.screen.blit(total_text, (panel_x + 15, y_offset))
        y_offset += 30

        # Completion percentage
        if stats['total'] > 0:
            completion = (stats['final'] / stats['total']) * 100
            comp_text = self.small_font.render(
                f"Completion: {completion:.1f}%", True, (150, 255, 150))
            self.screen.blit(comp_text, (panel_x + 15, y_offset))
            y_offset += 35

        # Status breakdown
        status_info = [
            ("Final", stats['final'], (150, 255, 150)),
            ("Review", stats['review'], (150, 200, 255)),
            ("Draft", stats['draft'], (255, 200, 100)),
            ("Missing", stats['missing'], (255, 100, 100)),
        ]

        for label, count, color in status_info:
            # Label
            label_surf = self.small_font.render(
                f"{label}:", True, (180, 180, 180))
            self.screen.blit(label_surf, (panel_x + 20, y_offset))

            # Count
            count_surf = self.small_font.render(str(count), True, color)
            self.screen.blit(count_surf, (panel_x + 150, y_offset))

            # Progress bar
            if stats['total'] > 0:
                bar_width = int((count / stats['total']) * 200)
                pygame.draw.rect(self.screen, color,
                                 (panel_x + 20, y_offset + 20, bar_width, 10))
                pygame.draw.rect(self.screen, (100, 100, 120),
                                 (panel_x + 20, y_offset + 20, 200, 10), 1)

            y_offset += 40


def main():
    """Run localization editor"""
    editor = LocalizationEditor()
    editor.run()


if __name__ == "__main__":
    main()
