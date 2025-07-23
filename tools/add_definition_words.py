#!/usr/bin/env python3
"""
Add new words discovered in definitions to the entities database.
"""

import json
import re
from typing import Set

def extract_new_words_from_thoughts() -> Set[str]:
    """Extract all unique words from the definition thoughts."""
    new_words = set()
    
    try:
        with open('definition_thoughts.json', 'r') as f:
            thoughts = json.load(f)
        
        for thought in thoughts:
            if 'connections' in thought:
                for word in thought['connections']:
                    # Clean the word
                    clean_word = re.sub(r'[^\w]', '', word.lower())
                    if len(clean_word) > 2:  # Only words longer than 2 characters
                        new_words.add(clean_word)
        
        print(f"Found {len(new_words)} unique words in definitions")
        return new_words
        
    except FileNotFoundError:
        print("definition_thoughts.json not found")
        return set()

def get_existing_words() -> Set[str]:
    """Get all existing words from the word_nodes.json file."""
    try:
        with open('word_nodes.json', 'r') as f:
            entities = json.load(f)
        
        existing_words = set()
        for entity in entities:
            if 'id' in entity:
                existing_words.add(entity['id'].lower())
        
        print(f"Found {len(existing_words)} existing words")
        return existing_words
        
    except FileNotFoundError:
        print("word_nodes.json not found")
        return set()

def create_new_entities(new_words: Set[str], existing_words: Set[str]) -> list:
    """Create new entity entries for words that don't exist yet."""
    new_entities = []
    
    for word in new_words:
        if word not in existing_words:
            entity = {
                "id": word,
                "name": word,
                "entity_type": "concept_type",
                "description": f"Word discovered in definition: {word}",
                "strain_amplitude": 0.0,
                "strain_resistance": 0.5,
                "strain_frequency": 0,
                "access_count": 0
            }
            new_entities.append(entity)
    
    print(f"Created {len(new_entities)} new entities")
    return new_entities

def main():
    """Main function to add new words to entities."""
    print("Adding new words from definitions to entities...")
    
    # Extract new words from definition thoughts
    new_words = extract_new_words_from_thoughts()
    
    # Get existing words
    existing_words = get_existing_words()
    
    # Create new entities
    new_entities = create_new_entities(new_words, existing_words)
    
    if new_entities:
        # Load existing entities
        try:
            with open('word_nodes.json', 'r') as f:
                existing_entities = json.load(f)
        except FileNotFoundError:
            existing_entities = []
        
        # Add new entities
        existing_entities.extend(new_entities)
        
        # Save updated entities
        with open('word_nodes.json', 'w') as f:
            json.dump(existing_entities, f, indent=2)
        
        print(f"Added {len(new_entities)} new entities to word_nodes.json")
        print(f"Total entities: {len(existing_entities)}")
        
        # Show some examples of new words
        print("\nExamples of new words added:")
        for i, entity in enumerate(new_entities[:10]):
            print(f"  {i+1}. {entity['id']}")
        if len(new_entities) > 10:
            print(f"  ... and {len(new_entities) - 10} more")
    else:
        print("No new words to add")

if __name__ == "__main__":
    main() 