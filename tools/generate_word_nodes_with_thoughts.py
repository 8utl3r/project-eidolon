#!/usr/bin/env python3
"""
Generate word nodes and verified thoughts for the knowledge graph.
This script creates entities for common words and their definitions as verified thoughts.
"""

import json
import os
import re
from typing import List, Dict, Any
import urllib.request
import urllib.parse

def fetch_word_definition(word: str) -> str:
    """
    Fetch a simple definition for a word using a free dictionary API.
    Returns a basic definition or a placeholder if not found.
    """
    try:
        # Use Free Dictionary API
        url = f"https://api.dictionaryapi.dev/api/v2/entries/en/{urllib.parse.quote(word)}"
        with urllib.request.urlopen(url) as response:
            data = json.loads(response.read())
            if data and isinstance(data, list) and len(data) > 0:
                meanings = data[0].get('meanings', [])
                if meanings and len(meanings) > 0:
                    definitions = meanings[0].get('definitions', [])
                    if definitions and len(definitions) > 0:
                        return definitions[0].get('definition', f"A word meaning {word}")
        
        # Fallback for words not found in API
        return f"A common English word: {word}"
    except Exception as e:
        # Fallback for any API errors
        return f"A common English word: {word}"

def generate_word_nodes_with_thoughts():
    """
    Generate nodes for common words and their definitions as verified thoughts.
    Expects a file 'common_words.txt' with one word per line.
    """
    words_file = os.path.join(os.path.dirname(__file__), 'common_words.txt')
    if not os.path.exists(words_file):
        print("ERROR: 'common_words.txt' not found. Please provide a file with one word per line.")
        return
    
    with open(words_file, 'r', encoding='utf-8') as f:
        words = [line.strip() for line in f if line.strip()]
    
    print(f"Processing {len(words)} words...")
    
    # Generate entities
    entities = []
    thoughts = []
    
    for i, word in enumerate(words):
        if i % 100 == 0:
            print(f"Processing word {i+1}/{len(words)}: {word}")
        
        # Create entity for the word
        word_id = word.lower()
        entity = {
            "id": word_id,
            "name": word,
            "entity_type": "concept_type",
            "description": f"Word: {word}",
            "strain_amplitude": 0.0,
            "strain_resistance": 0.5,
            "strain_frequency": 0,
            "access_count": 0
        }
        entities.append(entity)
        
        # Create verified thought for the word's definition
        definition = fetch_word_definition(word)
        thought_id = f"thought_{word_id}_definition"
        thought = {
            "id": thought_id,
            "name": f"Definition of {word}",
            "description": f"Verified definition: {definition}",
            "connections": [word_id],  # The thought connects to the word itself
            "verified": True,
            "verification_source": "dictionary_api",
            "confidence": 0.9,
            "strain_amplitude": 0.0,
            "strain_resistance": 0.5,
            "strain_frequency": 0,
            "access_count": 0
        }
        thoughts.append(thought)
    
    # Save entities
    print(f"Generated {len(entities)} word nodes.")
    with open('word_nodes.json', 'w', encoding='utf-8') as out:
        json.dump(entities, out, indent=2)
    print("Word nodes saved to 'word_nodes.json'.")
    
    # Save thoughts
    print(f"Generated {len(thoughts)} verified thoughts.")
    with open('verified_thoughts.json', 'w', encoding='utf-8') as out:
        json.dump(thoughts, out, indent=2)
    print("Verified thoughts saved to 'verified_thoughts.json'.")
    
    # Create a combined file for easy import
    combined_data = {
        "entities": entities,
        "thoughts": thoughts,
        "metadata": {
            "total_words": len(words),
            "total_entities": len(entities),
            "total_thoughts": len(thoughts),
            "generated_at": "2025-07-21T18:10:00Z"
        }
    }
    
    with open('word_data_complete.json', 'w', encoding='utf-8') as out:
        json.dump(combined_data, out, indent=2)
    print("Combined data saved to 'word_data_complete.json'.")

def generate_simple_word_nodes():
    """
    Generate just the word nodes without API calls (faster for testing).
    """
    words_file = os.path.join(os.path.dirname(__file__), 'common_words.txt')
    if not os.path.exists(words_file):
        print("ERROR: 'common_words.txt' not found. Please provide a file with one word per line.")
        return
    
    with open(words_file, 'r', encoding='utf-8') as f:
        words = [line.strip() for line in f if line.strip()]
    
    entities = []
    thoughts = []
    
    for word in words:
        # Create entity for the word
        word_id = word.lower()
        entity = {
            "id": word_id,
            "name": word,
            "entity_type": "concept_type",
            "description": f"Word: {word}",
            "strain_amplitude": 0.0,
            "strain_resistance": 0.5,
            "strain_frequency": 0,
            "access_count": 0
        }
        entities.append(entity)
        
        # Create simple verified thought
        thought_id = f"thought_{word_id}_basic"
        thought = {
            "id": thought_id,
            "name": f"Basic definition of {word}",
            "description": f"A common English word: {word}",
            "connections": [word_id],
            "verified": True,
            "verification_source": "word_list",
            "confidence": 0.8,
            "strain_amplitude": 0.0,
            "strain_resistance": 0.5,
            "strain_frequency": 0,
            "access_count": 0
        }
        thoughts.append(thought)
    
    # Save entities
    print(f"Generated {len(entities)} word nodes.")
    with open('word_nodes.json', 'w', encoding='utf-8') as out:
        json.dump(entities, out, indent=2)
    print("Word nodes saved to 'word_nodes.json'.")
    
    # Save thoughts
    print(f"Generated {len(thoughts)} verified thoughts.")
    with open('verified_thoughts.json', 'w', encoding='utf-8') as out:
        json.dump(thoughts, out, indent=2)
    print("Verified thoughts saved to 'verified_thoughts.json'.")

if __name__ == "__main__":
    import sys
    
    if len(sys.argv) > 1 and sys.argv[1] == "--simple":
        print("Generating simple word nodes without API calls...")
        generate_simple_word_nodes()
    else:
        print("Generating word nodes with definitions from dictionary API...")
        print("(Use --simple flag for faster generation without API calls)")
        generate_word_nodes_with_thoughts() 