#!/usr/bin/env python3
"""
Populate Project Eidolon with real data for testing the graph visualizer
"""

import json
import os
from datetime import datetime

def populate_real_data():
    """Create sample data file for the graph visualizer"""
    
    print("Creating sample data for Project Eidolon Graph Visualizer...")
    
    # Create sample entities that match the agent domains
    entities = [
        {
            "id": "math_theorem",
            "name": "Fermat's Last Theorem",
            "entity_type": "concept_type",
            "description": "xn + yn = zn has no integer solutions for n > 2",
            "strain_amplitude": 0.95,
            "strain_resistance": 0.1,
            "strain_frequency": 10,
            "access_count": 10,
            "created": "2024-01-01T00:00:00",
            "modified": "2024-12-21T00:00:00"
        },
        {
            "id": "logic_rule",
            "name": "Law of Non-Contradiction",
            "entity_type": "concept_type", 
            "description": "A statement cannot be both true and false",
            "strain_amplitude": 0.88,
            "strain_resistance": 0.2,
            "strain_frequency": 8,
            "access_count": 8,
            "created": "2024-01-01T00:00:00",
            "modified": "2024-12-21T00:00:00"
        },
        {
            "id": "physics_concept",
            "name": "Quantum Entanglement",
            "entity_type": "concept_type",
            "description": "Particles remain connected regardless of distance",
            "strain_amplitude": 0.92,
            "strain_resistance": 0.3,
            "strain_frequency": 12,
            "access_count": 12,
            "created": "2024-01-01T00:00:00",
            "modified": "2024-12-21T00:00:00"
        },
        {
            "id": "ai_algorithm",
            "name": "Neural Network Backpropagation",
            "entity_type": "concept_type",
            "description": "Algorithm for training neural networks",
            "strain_amplitude": 0.85,
            "strain_resistance": 0.4,
            "strain_frequency": 7,
            "access_count": 7,
            "created": "2024-01-01T00:00:00",
            "modified": "2024-12-21T00:00:00"
        },
        {
            "id": "philosophy_concept",
            "name": "Epistemology",
            "entity_type": "concept_type",
            "description": "Study of knowledge and justified belief",
            "strain_amplitude": 0.78,
            "strain_resistance": 0.5,
            "strain_frequency": 6,
            "access_count": 6,
            "created": "2024-01-01T00:00:00",
            "modified": "2024-12-21T00:00:00"
        },
        {
            "id": "einstein",
            "name": "Albert Einstein",
            "entity_type": "person",
            "description": "Theoretical physicist who developed relativity",
            "strain_amplitude": 0.90,
            "strain_resistance": 0.2,
            "strain_frequency": 15,
            "access_count": 15,
            "created": "2024-01-01T00:00:00",
            "modified": "2024-12-21T00:00:00"
        },
        {
            "id": "turing",
            "name": "Alan Turing",
            "entity_type": "person",
            "description": "Computer scientist and cryptanalyst",
            "strain_amplitude": 0.87,
            "strain_resistance": 0.3,
            "strain_frequency": 11,
            "access_count": 11,
            "created": "2024-01-01T00:00:00",
            "modified": "2024-12-21T00:00:00"
        },
        {
            "id": "mit",
            "name": "Massachusetts Institute of Technology",
            "entity_type": "place",
            "description": "Research university in Cambridge, MA",
            "strain_amplitude": 0.75,
            "strain_resistance": 0.6,
            "strain_frequency": 9,
            "access_count": 9,
            "created": "2024-01-01T00:00:00",
            "modified": "2024-12-21T00:00:00"
        },
        {
            "id": "quantum_revolution",
            "name": "Quantum Physics Revolution",
            "entity_type": "event",
            "description": "Early 20th century physics breakthroughs",
            "strain_amplitude": 0.93,
            "strain_resistance": 0.1,
            "strain_frequency": 14,
            "access_count": 14,
            "created": "2024-01-01T00:00:00",
            "modified": "2024-12-21T00:00:00"
        },
        {
            "id": "ai_boom",
            "name": "AI Renaissance",
            "entity_type": "event",
            "description": "Current resurgence in artificial intelligence",
            "strain_amplitude": 0.82,
            "strain_resistance": 0.4,
            "strain_frequency": 8,
            "access_count": 8,
            "created": "2024-01-01T00:00:00",
            "modified": "2024-12-21T00:00:00"
        }
    ]
    
    # Create relationships between agents and entities
    relationships = [
        {
            "id": "rel_1",
            "from": "engineer",
            "to": "math_theorem",
            "type": "has_authority",
            "authority_strength": 0.95,
            "strain_amplitude": 0.95
        },
        {
            "id": "rel_2",
            "from": "skeptic",
            "to": "logic_rule",
            "type": "has_authority",
            "authority_strength": 0.98,
            "strain_amplitude": 0.98
        },
        {
            "id": "rel_3",
            "from": "engineer",
            "to": "physics_concept",
            "type": "has_authority",
            "authority_strength": 0.85,
            "strain_amplitude": 0.85
        },
        {
            "id": "rel_4",
            "from": "dreamer",
            "to": "ai_algorithm",
            "type": "has_authority",
            "authority_strength": 0.75,
            "strain_amplitude": 0.75
        },
        {
            "id": "rel_5",
            "from": "philosopher",
            "to": "philosophy_concept",
            "type": "has_authority",
            "authority_strength": 0.90,
            "strain_amplitude": 0.90
        },
        {
            "id": "rel_6",
            "from": "philosopher",
            "to": "einstein",
            "type": "has_authority",
            "authority_strength": 0.80,
            "strain_amplitude": 0.80
        },
        {
            "id": "rel_7",
            "from": "investigator",
            "to": "turing",
            "type": "has_authority",
            "authority_strength": 0.85,
            "strain_amplitude": 0.85
        },
        {
            "id": "rel_8",
            "from": "archivist",
            "to": "mit",
            "type": "has_authority",
            "authority_strength": 0.70,
            "strain_amplitude": 0.70
        },
        {
            "id": "rel_9",
            "from": "investigator",
            "to": "quantum_revolution",
            "type": "has_authority",
            "authority_strength": 0.88,
            "strain_amplitude": 0.88
        },
        {
            "id": "rel_10",
            "from": "dreamer",
            "to": "ai_boom",
            "type": "has_authority",
            "authority_strength": 0.82,
            "strain_amplitude": 0.82
        }
    ]
    
    # Save data to a JSON file
    data = {
        "entities": entities,
        "relationships": relationships,
        "created": datetime.now().isoformat(),
        "description": "Sample Project Eidolon data for graph visualization"
    }
    
    data_file = os.path.join(os.path.dirname(__file__), 'sample_data.json')
    with open(data_file, 'w') as f:
        json.dump(data, f, indent=2)
    
    print(f"✅ Created {len(entities)} entities")
    print(f"✅ Created {len(relationships)} relationships")
    print(f"✅ Data saved to: {data_file}")
    print("\n🎉 Sample data creation complete!")
    print("The graph visualizer will now use this real sample data.")

if __name__ == '__main__':
    populate_real_data() 