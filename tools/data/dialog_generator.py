"""
AI-Assisted Dialog Generation and Translation System for FFMQ
Generate contextual dialog, translate text, and manage localization.
"""

import json
import re
from dataclasses import dataclass, field
from typing import List, Tuple, Optional, Dict, Set
from enum import Enum
import random


class DialogTone(Enum):
    """Dialog tone/mood"""
    FORMAL = "formal"
    CASUAL = "casual"
    FRIENDLY = "friendly"
    HOSTILE = "hostile"
    MYSTERIOUS = "mysterious"
    COMEDIC = "comedic"
    DRAMATIC = "dramatic"
    INFORMATIVE = "informative"


class CharacterArchetype(Enum):
    """Character personality types"""
    HERO = "hero"
    VILLAIN = "villain"
    MENTOR = "mentor"
    COMIC_RELIEF = "comic_relief"
    MERCHANT = "merchant"
    GUARD = "guard"
    VILLAGER = "villager"
    NOBLE = "noble"
    CHILD = "child"
    ELDER = "elder"


@dataclass
class Character:
    """Character profile for dialog generation"""
    character_id: int
    name: str
    archetype: CharacterArchetype
    traits: List[str] = field(default_factory=list)
    speech_patterns: List[str] = field(default_factory=list)
    vocabulary_level: int = 5  # 1-10
    catch_phrases: List[str] = field(default_factory=list)
    
    def to_dict(self):
        return {
            'character_id': self.character_id,
            'name': self.name,
            'archetype': self.archetype.value,
            'traits': self.traits,
            'speech_patterns': self.speech_patterns,
            'vocabulary_level': self.vocabulary_level,
            'catch_phrases': self.catch_phrases
        }


@dataclass
class DialogContext:
    """Context for dialog generation"""
    location: str
    situation: str
    characters_present: List[str]
    tone: DialogTone
    player_action: Optional[str] = None
    quest_stage: Optional[str] = None
    time_of_day: Optional[str] = None
    
    def to_dict(self):
        return {
            'location': self.location,
            'situation': self.situation,
            'characters_present': self.characters_present,
            'tone': self.tone.value,
            'player_action': self.player_action,
            'quest_stage': self.quest_stage,
            'time_of_day': self.time_of_day
        }


@dataclass
class DialogLine:
    """Single line of generated dialog"""
    character: Character
    text: str
    emotion: str
    tags: List[str] = field(default_factory=list)
    
    def to_dict(self):
        return {
            'character_id': self.character.character_id,
            'character_name': self.character.name,
            'text': self.text,
            'emotion': self.emotion,
            'tags': self.tags
        }


class DialogTemplateEngine:
    """Template-based dialog generation"""
    
    def __init__(self):
        self.templates = self._load_templates()
        self.variables = {}
        
    def _load_templates(self) -> Dict[str, List[str]]:
        """Load dialog templates by category"""
        return {
            'greeting': [
                "Hello, {player_name}!",
                "Greetings, traveler.",
                "Welcome to {location}.",
                "Good {time_of_day}, {player_name}.",
                "Ah, you've arrived at last."
            ],
            'quest_offer': [
                "I have a task that needs your attention.",
                "Will you help me with something?",
                "There's trouble in {location}. Can you investigate?",
                "I need a brave {player_class} like you.",
                "The {enemy_type} have been causing problems. Will you help?"
            ],
            'quest_complete': [
                "Excellent work, {player_name}!",
                "You've done it! Thank you!",
                "I knew I could count on you.",
                "Your bravery has saved us all.",
                "Here's your reward, as promised."
            ],
            'shop': [
                "Welcome to my shop!",
                "Looking to buy or sell?",
                "I have the finest {item_category} in the land!",
                "What can I get for you today?",
                "These prices won't last long!"
            ],
            'information': [
                "Have you heard about {topic}?",
                "They say {rumor}.",
                "The {location} is {state}.",
                "Be careful of {danger}.",
                "Did you know that {fact}?"
            ],
            'farewell': [
                "Safe travels, {player_name}.",
                "May fortune favor you.",
                "Come back anytime!",
                "Good luck on your journey.",
                "Take care out there."
            ],
            'hostile': [
                "You shouldn't be here!",
                "Leave now, or else!",
                "I won't let you pass!",
                "Prepare to face my wrath!",
                "You'll regret this!"
            ],
            'mysterious': [
                "The truth is not what it seems...",
                "In time, you will understand.",
                "The {artifact} holds great power.",
                "Some secrets are better left buried.",
                "Destiny has brought you here."
            ]
        }
    
    def generate(self, template_category: str, context: DialogContext,
                 character: Character) -> str:
        """Generate dialog from template"""
        templates = self.templates.get(template_category, ["..."])
        template = random.choice(templates)
        
        # Build variable substitutions
        vars_dict = {
            'player_name': "Hero",
            'location': context.location,
            'time_of_day': context.time_of_day or "day",
            'player_class': "warrior",
            'enemy_type': "monsters",
            'item_category': "weapons",
            'topic': "the Crystal",
            'rumor': "the tower is dangerous",
            'state': "peaceful",
            'danger': "the wild creatures",
            'fact': "magic flows through the land",
            'artifact': "amulet"
        }
        
        # Apply character speech patterns
        text = template.format(**vars_dict)
        text = self._apply_character_style(text, character)
        
        return text
    
    def _apply_character_style(self, text: str, character: Character) -> str:
        """Apply character-specific speech patterns"""
        if character.archetype == CharacterArchetype.ELDER:
            # Add wisdom/age markers
            if random.random() < 0.3:
                text = f"In my many years, I've learned that {text.lower()}"
        
        elif character.archetype == CharacterArchetype.MERCHANT:
            # Add sales pitch
            if "shop" in text.lower() or "buy" in text.lower():
                text += " Today only!"
        
        elif character.archetype == CharacterArchetype.CHILD:
            # Simpler language
            text = text.replace("investigate", "check out")
            text = text.replace("bravery", "courage")
        
        elif character.archetype == CharacterArchetype.NOBLE:
            # Formal language
            text = text.replace("Hi", "Greetings")
            text = text.replace("you", "thou")
        
        # Add catch phrases occasionally
        if character.catch_phrases and random.random() < 0.2:
            text += f" {random.choice(character.catch_phrases)}"
        
        return text


class DialogGenerator:
    """Advanced context-aware dialog generation"""
    
    def __init__(self):
        self.template_engine = DialogTemplateEngine()
        self.characters = {}
        self.conversation_history = []
        
    def register_character(self, character: Character):
        """Register character for dialog generation"""
        self.characters[character.character_id] = character
    
    def generate_conversation(self, context: DialogContext,
                              num_exchanges: int = 3) -> List[DialogLine]:
        """Generate multi-turn conversation"""
        conversation = []
        
        # Get characters
        char_names = context.characters_present
        if not char_names:
            return conversation
        
        # Find registered characters
        active_chars = [
            char for char in self.characters.values()
            if char.name in char_names
        ]
        
        if not active_chars:
            return conversation
        
        # Generate exchanges
        for i in range(num_exchanges):
            char = active_chars[i % len(active_chars)]
            
            # Choose template category based on context
            if i == 0:
                category = "greeting"
            elif context.tone == DialogTone.HOSTILE:
                category = "hostile"
            elif context.tone == DialogTone.MYSTERIOUS:
                category = "mysterious"
            elif context.situation == "shop":
                category = "shop"
            elif "quest" in context.situation.lower():
                category = "quest_offer"
            else:
                category = "information"
            
            text = self.template_engine.generate(category, context, char)
            
            # Determine emotion
            emotion = self._determine_emotion(context.tone, char)
            
            line = DialogLine(
                character=char,
                text=text,
                emotion=emotion,
                tags=[context.tone.value, category]
            )
            conversation.append(line)
        
        self.conversation_history.extend(conversation)
        return conversation
    
    def _determine_emotion(self, tone: DialogTone,
                           character: Character) -> str:
        """Determine character emotion from context"""
        if tone == DialogTone.HOSTILE:
            return "angry"
        elif tone == DialogTone.FRIENDLY:
            return "happy"
        elif tone == DialogTone.MYSTERIOUS:
            return "neutral"
        elif tone == DialogTone.DRAMATIC:
            return "surprised"
        elif character.archetype == CharacterArchetype.MERCHANT:
            return "happy"
        else:
            return "normal"
    
    def export_conversation(self, filepath: str):
        """Export conversation history"""
        data = {
            'conversations': [
                line.to_dict() for line in self.conversation_history
            ]
        }
        with open(filepath, 'w') as f:
            json.dump(data, f, indent=2)


class TranslationSystem:
    """Simple translation and localization"""
    
    def __init__(self):
        self.dictionaries = {}
        self.load_default_dictionaries()
        
    def load_default_dictionaries(self):
        """Load basic translation dictionaries"""
        # English to Spanish (simplified)
        self.dictionaries['es'] = {
            'Hello': 'Hola',
            'Goodbye': 'Adiós',
            'Yes': 'Sí',
            'No': 'No',
            'Thank you': 'Gracias',
            'Hero': 'Héroe',
            'Crystal': 'Cristal',
            'Tower': 'Torre',
            'Forest': 'Bosque',
            'Shop': 'Tienda',
            'Weapon': 'Arma',
            'Armor': 'Armadura',
            'Potion': 'Poción',
            'Gold': 'Oro'
        }
        
        # English to French (simplified)
        self.dictionaries['fr'] = {
            'Hello': 'Bonjour',
            'Goodbye': 'Au revoir',
            'Yes': 'Oui',
            'No': 'Non',
            'Thank you': 'Merci',
            'Hero': 'Héros',
            'Crystal': 'Cristal',
            'Tower': 'Tour',
            'Forest': 'Forêt',
            'Shop': 'Magasin',
            'Weapon': 'Arme',
            'Armor': 'Armure',
            'Potion': 'Potion',
            'Gold': 'Or'
        }
        
        # English to Japanese (romanized, simplified)
        self.dictionaries['ja'] = {
            'Hello': 'Konnichiwa',
            'Goodbye': 'Sayonara',
            'Yes': 'Hai',
            'No': 'Iie',
            'Thank you': 'Arigatou',
            'Hero': 'Yuusha',
            'Crystal': 'Kurisutaru',
            'Tower': 'Tou',
            'Forest': 'Mori',
            'Shop': 'Mise',
            'Weapon': 'Buki',
            'Armor': 'Yoroi',
            'Potion': 'Kusuri',
            'Gold': 'Kin'
        }
    
    def translate(self, text: str, target_lang: str) -> str:
        """Translate text to target language"""
        if target_lang not in self.dictionaries:
            return text
        
        dictionary = self.dictionaries[target_lang]
        translated = text
        
        # Word-by-word translation (simplified)
        for english, foreign in dictionary.items():
            translated = re.sub(
                r'\b' + re.escape(english) + r'\b',
                foreign,
                translated,
                flags=re.IGNORECASE
            )
        
        return translated
    
    def add_translation(self, english: str, target_lang: str, translation: str):
        """Add custom translation"""
        if target_lang not in self.dictionaries:
            self.dictionaries[target_lang] = {}
        self.dictionaries[target_lang][english] = translation
    
    def export_dictionary(self, target_lang: str, filepath: str):
        """Export translation dictionary"""
        if target_lang in self.dictionaries:
            with open(filepath, 'w', encoding='utf-8') as f:
                json.dump(self.dictionaries[target_lang], f,
                          ensure_ascii=False, indent=2)


class TextAnalyzer:
    """Analyze dialog for readability and consistency"""
    
    def __init__(self):
        self.common_words = set([
            'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at',
            'to', 'for', 'of', 'with', 'by', 'from', 'is', 'are',
            'was', 'were', 'be', 'been', 'have', 'has', 'had'
        ])
    
    def analyze_readability(self, text: str) -> Dict[str, any]:
        """Analyze text readability"""
        words = text.split()
        sentences = text.split('.')
        
        # Basic metrics
        word_count = len(words)
        sentence_count = len(sentences)
        avg_word_length = sum(len(w) for w in words) / max(1, word_count)
        avg_sentence_length = word_count / max(1, sentence_count)
        
        # Vocabulary diversity
        unique_words = set(w.lower() for w in words)
        diversity = len(unique_words) / max(1, word_count)
        
        # Complexity score (simplified)
        complexity = 0
        if avg_word_length > 6:
            complexity += 1
        if avg_sentence_length > 15:
            complexity += 1
        if diversity > 0.7:
            complexity += 1
        
        return {
            'word_count': word_count,
            'sentence_count': sentence_count,
            'avg_word_length': round(avg_word_length, 1),
            'avg_sentence_length': round(avg_sentence_length, 1),
            'vocabulary_diversity': round(diversity, 2),
            'complexity_score': complexity,
            'reading_level': self._get_reading_level(complexity)
        }
    
    def _get_reading_level(self, complexity: int) -> str:
        """Get reading level description"""
        if complexity == 0:
            return "Simple"
        elif complexity == 1:
            return "Moderate"
        elif complexity == 2:
            return "Complex"
        else:
            return "Advanced"
    
    def find_inconsistencies(self, texts: List[str]) -> List[Dict[str, any]]:
        """Find inconsistencies in dialog"""
        inconsistencies = []
        
        # Check for spelling variations
        word_forms = {}
        for text in texts:
            words = set(text.split())
            for word in words:
                lower = word.lower()
                if lower not in word_forms:
                    word_forms[lower] = set()
                word_forms[lower].add(word)
        
        # Find words with multiple capitalizations
        for word, forms in word_forms.items():
            if len(forms) > 1:
                inconsistencies.append({
                    'type': 'capitalization',
                    'word': word,
                    'forms': list(forms)
                })
        
        return inconsistencies


def main():
    """Test dialog generation system"""
    
    # Create characters
    elder = Character(
        0, "Village Elder",
        CharacterArchetype.ELDER,
        traits=["wise", "kind"],
        catch_phrases=["May the Crystal guide you."]
    )
    
    merchant = Character(
        1, "Shop Keeper",
        CharacterArchetype.MERCHANT,
        traits=["greedy", "friendly"],
        catch_phrases=["Best prices in town!"]
    )
    
    # Create generator
    generator = DialogGenerator()
    generator.register_character(elder)
    generator.register_character(merchant)
    
    # Generate conversation
    context = DialogContext(
        location="Village Square",
        situation="quest",
        characters_present=["Village Elder"],
        tone=DialogTone.FRIENDLY,
        time_of_day="morning"
    )
    
    conversation = generator.generate_conversation(context, num_exchanges=5)
    
    print("Generated Conversation:")
    for line in conversation:
        print(f"{line.character.name}: {line.text} [{line.emotion}]")
    
    # Test translation
    translator = TranslationSystem()
    spanish = translator.translate(conversation[0].text, 'es')
    print(f"\nSpanish: {spanish}")
    
    # Export
    generator.export_conversation("sample_dialog.json")
    translator.export_dictionary('es', "spanish_dict.json")
    
    print("\nFiles exported: sample_dialog.json, spanish_dict.json")


if __name__ == '__main__':
    main()
