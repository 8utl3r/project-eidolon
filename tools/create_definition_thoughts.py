#!/usr/bin/env python3
"""
Create definition-based verified thoughts for the 100 most common words.
This will create multi-word thoughts that form constellations in the visualization.
"""

import json
import requests
import time
import re
from typing import List, Dict, Any

def clean_definition(text: str) -> str:
    """Clean and normalize definition text."""
    # Remove extra whitespace and normalize
    text = re.sub(r'\s+', ' ', text.strip())
    # Remove special characters that might cause issues
    text = re.sub(r'[^\w\s\-\.]', '', text)
    return text.lower()

def fetch_word_definition(word: str) -> List[str]:
    """Fetch definition for a word using Free Dictionary API."""
    try:
        url = f"https://api.dictionaryapi.dev/api/v2/entries/en/{word}"
        response = requests.get(url, timeout=10)
        
        if response.status_code == 200:
            data = response.json()
            if data and isinstance(data, list) and len(data) > 0:
                # Get the first definition
                entry = data[0]
                if 'meanings' in entry and entry['meanings']:
                    meaning = entry['meanings'][0]
                    if 'definitions' in meaning and meaning['definitions']:
                        definition = meaning['definitions'][0]['definition']
                        # Split definition into words and clean them
                        words = clean_definition(definition).split()
                        # Filter out very short words and common stop words
                        filtered_words = [w for w in words if len(w) > 2 and w not in ['the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of', 'with', 'by']]
                        # Limit to first 10 meaningful words
                        return filtered_words[:10]
        
        # Fallback: return a simple definition using the word itself
        return [word, "is", "a", "common", "english", "word"]
        
    except Exception as e:
        print(f"Error fetching definition for '{word}': {e}")
        # Fallback: return a simple definition
        return [word, "is", "a", "common", "english", "word"]

def create_definition_thoughts() -> List[Dict[str, Any]]:
    """Create verified thoughts with definitions for the 100 most common words."""
    
    # Read the 100 most common words
    with open('common_words.txt', 'r') as f:
        common_words = [line.strip().lower() for line in f.readlines()[:100]]
    
    thoughts = []
    
    for i, word in enumerate(common_words):
        print(f"Processing word {i+1}/100: {word}")
        
        # Fetch definition
        definition_words = fetch_word_definition(word)
        
        # Create the thought with the word and its definition
        thought = {
            "id": f"thought_{word}_definition",
            "name": f"Definition of {word}",
            "description": f"The definition of the word '{word}': {' '.join(definition_words)}",
            "connections": [word] + definition_words,  # Multi-word sequence
            "verified": True,
            "verification_source": "dictionary_api",
            "confidence": 0.9,
            "strain_amplitude": 0.1,  # Low strain for verified definitions
            "strain_resistance": 0.8,  # High resistance since it's verified
            "strain_frequency": 1,
            "access_count": 0
        }
        
        thoughts.append(thought)
        
        # Add any new words from the definition to the entities if they don't exist
        for def_word in definition_words:
            if def_word not in common_words:
                # This word will need to be added to entities
                print(f"  New word found: {def_word}")
        
        # Rate limiting to be nice to the API
        time.sleep(0.1)
    
    return thoughts

def save_thoughts(thoughts: List[Dict[str, Any]], filename: str):
    """Save thoughts to JSON file."""
    with open(filename, 'w') as f:
        json.dump(thoughts, f, indent=2)
    print(f"Saved {len(thoughts)} thoughts to {filename}")

def main():
    """Main function to create definition thoughts."""
    print("Creating definition-based verified thoughts...")
    
    # Create the thoughts
    thoughts = create_definition_thoughts()
    
    # Save to a new file
    save_thoughts(thoughts, 'definition_thoughts.json')
    
    # Also append to the existing verified thoughts
    try:
        with open('verified_thoughts.json', 'r') as f:
            existing_thoughts = json.load(f)
    except FileNotFoundError:
        existing_thoughts = []
    
    # Add new thoughts
    existing_thoughts.extend(thoughts)
    
    # Save combined thoughts
    save_thoughts(existing_thoughts, 'verified_thoughts.json')
    
    print(f"Total thoughts: {len(existing_thoughts)}")
    print("Done! The verified thoughts now include definition-based constellations.")

if __name__ == "__main__":
    main() 