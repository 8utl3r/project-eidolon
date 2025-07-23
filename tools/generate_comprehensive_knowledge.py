#!/usr/bin/env python3
"""
Generate comprehensive knowledge base for Project Eidolon
"""

import json
import os
from datetime import datetime

def generate_comprehensive_knowledge():
    """Generate a comprehensive knowledge base with foundational concepts"""
    
    print("Generating comprehensive knowledge base for Project Eidolon...")
    
    # Mathematical Foundations
    math_entities = [
        {"id": "arithmetic", "name": "Arithmetic", "entity_type": "concept_type", "description": "Basic operations: addition, subtraction, multiplication, division", "strain_amplitude": 0.9, "strain_resistance": 0.1, "strain_frequency": 20, "access_count": 20},
        {"id": "algebra", "name": "Algebra", "entity_type": "concept_type", "description": "Study of mathematical symbols and rules for manipulating them", "strain_amplitude": 0.85, "strain_resistance": 0.2, "strain_frequency": 18, "access_count": 18},
        {"id": "geometry", "name": "Geometry", "entity_type": "concept_type", "description": "Study of shapes, sizes, and spatial relationships", "strain_amplitude": 0.88, "strain_resistance": 0.15, "strain_frequency": 16, "access_count": 16},
        {"id": "calculus", "name": "Calculus", "entity_type": "concept_type", "description": "Study of continuous change through derivatives and integrals", "strain_amplitude": 0.92, "strain_resistance": 0.3, "strain_frequency": 14, "access_count": 14},
        {"id": "set_theory", "name": "Set Theory", "entity_type": "concept_type", "description": "Foundation of mathematics dealing with collections of objects", "strain_amplitude": 0.87, "strain_resistance": 0.25, "strain_frequency": 12, "access_count": 12},
        {"id": "number_theory", "name": "Number Theory", "entity_type": "concept_type", "description": "Study of integers and their properties", "strain_amplitude": 0.89, "strain_resistance": 0.2, "strain_frequency": 15, "access_count": 15},
        {"id": "probability", "name": "Probability", "entity_type": "concept_type", "description": "Study of uncertainty and random events", "strain_amplitude": 0.83, "strain_resistance": 0.35, "strain_frequency": 13, "access_count": 13},
        {"id": "statistics", "name": "Statistics", "entity_type": "concept_type", "description": "Collection, analysis, and interpretation of data", "strain_amplitude": 0.86, "strain_resistance": 0.3, "strain_frequency": 17, "access_count": 17},
        {"id": "linear_algebra", "name": "Linear Algebra", "entity_type": "concept_type", "description": "Study of vectors, matrices, and linear transformations", "strain_amplitude": 0.91, "strain_resistance": 0.4, "strain_frequency": 11, "access_count": 11},
        {"id": "topology", "name": "Topology", "entity_type": "concept_type", "description": "Study of geometric properties preserved under continuous deformation", "strain_amplitude": 0.94, "strain_resistance": 0.5, "strain_frequency": 9, "access_count": 9}
    ]
    
    # Logical Foundations
    logic_entities = [
        {"id": "propositional_logic", "name": "Propositional Logic", "entity_type": "concept_type", "description": "Study of logical relationships between propositions", "strain_amplitude": 0.88, "strain_resistance": 0.2, "strain_frequency": 16, "access_count": 16},
        {"id": "predicate_logic", "name": "Predicate Logic", "entity_type": "concept_type", "description": "Extension of propositional logic with quantifiers and predicates", "strain_amplitude": 0.92, "strain_resistance": 0.3, "strain_frequency": 12, "access_count": 12},
        {"id": "modal_logic", "name": "Modal Logic", "entity_type": "concept_type", "description": "Logic dealing with necessity and possibility", "strain_amplitude": 0.85, "strain_resistance": 0.4, "strain_frequency": 10, "access_count": 10},
        {"id": "inductive_reasoning", "name": "Inductive Reasoning", "entity_type": "concept_type", "description": "Reasoning from specific observations to general conclusions", "strain_amplitude": 0.80, "strain_resistance": 0.25, "strain_frequency": 18, "access_count": 18},
        {"id": "deductive_reasoning", "name": "Deductive Reasoning", "entity_type": "concept_type", "description": "Reasoning from general principles to specific conclusions", "strain_amplitude": 0.87, "strain_resistance": 0.2, "strain_frequency": 15, "access_count": 15},
        {"id": "fallacies", "name": "Logical Fallacies", "entity_type": "concept_type", "description": "Common errors in reasoning that undermine logic", "strain_amplitude": 0.75, "strain_resistance": 0.3, "strain_frequency": 14, "access_count": 14},
        {"id": "validity", "name": "Logical Validity", "entity_type": "concept_type", "description": "Property of arguments where conclusion follows from premises", "strain_amplitude": 0.90, "strain_resistance": 0.15, "strain_frequency": 13, "access_count": 13},
        {"id": "soundness", "name": "Logical Soundness", "entity_type": "concept_type", "description": "Property of arguments that are valid with true premises", "strain_amplitude": 0.93, "strain_resistance": 0.2, "strain_frequency": 11, "access_count": 11}
    ]
    
    # Physical Sciences
    physics_entities = [
        {"id": "mechanics", "name": "Classical Mechanics", "entity_type": "concept_type", "description": "Study of motion and forces in macroscopic systems", "strain_amplitude": 0.89, "strain_resistance": 0.2, "strain_frequency": 16, "access_count": 16},
        {"id": "thermodynamics", "name": "Thermodynamics", "entity_type": "concept_type", "description": "Study of heat, energy, and their transformations", "strain_amplitude": 0.86, "strain_resistance": 0.3, "strain_frequency": 14, "access_count": 14},
        {"id": "electromagnetism", "name": "Electromagnetism", "entity_type": "concept_type", "description": "Study of electric and magnetic fields and their interactions", "strain_amplitude": 0.91, "strain_resistance": 0.4, "strain_frequency": 12, "access_count": 12},
        {"id": "quantum_mechanics", "name": "Quantum Mechanics", "entity_type": "concept_type", "description": "Physics of matter and energy at atomic and subatomic scales", "strain_amplitude": 0.95, "strain_resistance": 0.6, "strain_frequency": 10, "access_count": 10},
        {"id": "relativity", "name": "Relativity", "entity_type": "concept_type", "description": "Einstein's theories of special and general relativity", "strain_amplitude": 0.94, "strain_resistance": 0.5, "strain_frequency": 11, "access_count": 11},
        {"id": "optics", "name": "Optics", "entity_type": "concept_type", "description": "Study of light and its interactions with matter", "strain_amplitude": 0.84, "strain_resistance": 0.25, "strain_frequency": 13, "access_count": 13},
        {"id": "acoustics", "name": "Acoustics", "entity_type": "concept_type", "description": "Study of sound and mechanical waves", "strain_amplitude": 0.82, "strain_resistance": 0.2, "strain_frequency": 12, "access_count": 12},
        {"id": "fluid_dynamics", "name": "Fluid Dynamics", "entity_type": "concept_type", "description": "Study of fluid flow and its properties", "strain_amplitude": 0.88, "strain_resistance": 0.35, "strain_frequency": 9, "access_count": 9}
    ]
    
    # Chemistry
    chemistry_entities = [
        {"id": "atomic_theory", "name": "Atomic Theory", "entity_type": "concept_type", "description": "Theory that matter is composed of discrete units called atoms", "strain_amplitude": 0.90, "strain_resistance": 0.2, "strain_frequency": 15, "access_count": 15},
        {"id": "periodic_table", "name": "Periodic Table", "entity_type": "concept_type", "description": "Tabular arrangement of chemical elements by atomic number", "strain_amplitude": 0.85, "strain_resistance": 0.15, "strain_frequency": 18, "access_count": 18},
        {"id": "chemical_bonding", "name": "Chemical Bonding", "entity_type": "concept_type", "description": "Attraction between atoms that enables formation of molecules", "strain_amplitude": 0.87, "strain_resistance": 0.3, "strain_frequency": 14, "access_count": 14},
        {"id": "reactions", "name": "Chemical Reactions", "entity_type": "concept_type", "description": "Processes that lead to chemical transformation of substances", "strain_amplitude": 0.83, "strain_resistance": 0.25, "strain_frequency": 16, "access_count": 16},
        {"id": "thermochemistry", "name": "Thermochemistry", "entity_type": "concept_type", "description": "Study of heat changes in chemical reactions", "strain_amplitude": 0.81, "strain_resistance": 0.35, "strain_frequency": 11, "access_count": 11},
        {"id": "kinetics", "name": "Chemical Kinetics", "entity_type": "concept_type", "description": "Study of rates of chemical reactions", "strain_amplitude": 0.84, "strain_resistance": 0.4, "strain_frequency": 10, "access_count": 10}
    ]
    
    # Biology
    biology_entities = [
        {"id": "cell_theory", "name": "Cell Theory", "entity_type": "concept_type", "description": "Theory that all living organisms are composed of cells", "strain_amplitude": 0.88, "strain_resistance": 0.2, "strain_frequency": 16, "access_count": 16},
        {"id": "evolution", "name": "Evolution", "entity_type": "concept_type", "description": "Change in heritable characteristics of biological populations over time", "strain_amplitude": 0.92, "strain_resistance": 0.3, "strain_frequency": 14, "access_count": 14},
        {"id": "genetics", "name": "Genetics", "entity_type": "concept_type", "description": "Study of genes, genetic variation, and heredity", "strain_amplitude": 0.89, "strain_resistance": 0.25, "strain_frequency": 15, "access_count": 15},
        {"id": "ecology", "name": "Ecology", "entity_type": "concept_type", "description": "Study of interactions between organisms and their environment", "strain_amplitude": 0.85, "strain_resistance": 0.3, "strain_frequency": 13, "access_count": 13},
        {"id": "physiology", "name": "Physiology", "entity_type": "concept_type", "description": "Study of functions and mechanisms in living systems", "strain_amplitude": 0.87, "strain_resistance": 0.35, "strain_frequency": 12, "access_count": 12},
        {"id": "biochemistry", "name": "Biochemistry", "entity_type": "concept_type", "description": "Study of chemical processes within living organisms", "strain_amplitude": 0.90, "strain_resistance": 0.4, "strain_frequency": 11, "access_count": 11}
    ]
    
    # Computer Science
    cs_entities = [
        {"id": "algorithms", "name": "Algorithms", "entity_type": "concept_type", "description": "Step-by-step procedures for solving problems", "strain_amplitude": 0.91, "strain_resistance": 0.2, "strain_frequency": 19, "access_count": 19},
        {"id": "data_structures", "name": "Data Structures", "entity_type": "concept_type", "description": "Organized ways of storing and accessing data", "strain_amplitude": 0.89, "strain_resistance": 0.25, "strain_frequency": 17, "access_count": 17},
        {"id": "programming_paradigms", "name": "Programming Paradigms", "entity_type": "concept_type", "description": "Fundamental styles of programming", "strain_amplitude": 0.86, "strain_resistance": 0.3, "strain_frequency": 15, "access_count": 15},
        {"id": "complexity_theory", "name": "Computational Complexity", "entity_type": "concept_type", "description": "Study of resource requirements of algorithms", "strain_amplitude": 0.93, "strain_resistance": 0.4, "strain_frequency": 12, "access_count": 12},
        {"id": "artificial_intelligence", "name": "Artificial Intelligence", "entity_type": "concept_type", "description": "Simulation of human intelligence in machines", "strain_amplitude": 0.94, "strain_resistance": 0.3, "strain_frequency": 18, "access_count": 18},
        {"id": "machine_learning", "name": "Machine Learning", "entity_type": "concept_type", "description": "Algorithms that improve through experience", "strain_amplitude": 0.92, "strain_resistance": 0.25, "strain_frequency": 20, "access_count": 20},
        {"id": "networks", "name": "Computer Networks", "entity_type": "concept_type", "description": "Interconnected computing devices for data exchange", "strain_amplitude": 0.87, "strain_resistance": 0.2, "strain_frequency": 16, "access_count": 16},
        {"id": "databases", "name": "Databases", "entity_type": "concept_type", "description": "Organized collections of structured information", "strain_amplitude": 0.85, "strain_resistance": 0.25, "strain_frequency": 14, "access_count": 14}
    ]
    
    # Philosophy
    philosophy_entities = [
        {"id": "metaphysics", "name": "Metaphysics", "entity_type": "concept_type", "description": "Study of fundamental nature of reality and existence", "strain_amplitude": 0.94, "strain_resistance": 0.5, "strain_frequency": 12, "access_count": 12},
        {"id": "epistemology", "name": "Epistemology", "entity_type": "concept_type", "description": "Study of knowledge, belief, and justification", "strain_amplitude": 0.91, "strain_resistance": 0.4, "strain_frequency": 14, "access_count": 14},
        {"id": "ethics", "name": "Ethics", "entity_type": "concept_type", "description": "Study of moral principles and values", "strain_amplitude": 0.88, "strain_resistance": 0.3, "strain_frequency": 16, "access_count": 16},
        {"id": "aesthetics", "name": "Aesthetics", "entity_type": "concept_type", "description": "Study of beauty, art, and taste", "strain_amplitude": 0.82, "strain_resistance": 0.4, "strain_frequency": 10, "access_count": 10},
        {"id": "logic_philosophy", "name": "Philosophical Logic", "entity_type": "concept_type", "description": "Application of logic to philosophical problems", "strain_amplitude": 0.89, "strain_resistance": 0.35, "strain_frequency": 11, "access_count": 11},
        {"id": "philosophy_of_mind", "name": "Philosophy of Mind", "entity_type": "concept_type", "description": "Study of consciousness and mental phenomena", "strain_amplitude": 0.93, "strain_resistance": 0.45, "strain_frequency": 13, "access_count": 13},
        {"id": "philosophy_of_science", "name": "Philosophy of Science", "entity_type": "concept_type", "description": "Study of foundations and implications of science", "strain_amplitude": 0.90, "strain_resistance": 0.4, "strain_frequency": 12, "access_count": 12}
    ]
    
    # Psychology
    psychology_entities = [
        {"id": "cognitive_psychology", "name": "Cognitive Psychology", "entity_type": "concept_type", "description": "Study of mental processes like thinking, memory, and learning", "strain_amplitude": 0.88, "strain_resistance": 0.3, "strain_frequency": 15, "access_count": 15},
        {"id": "behavioral_psychology", "name": "Behavioral Psychology", "entity_type": "concept_type", "description": "Study of observable behavior and learning processes", "strain_amplitude": 0.85, "strain_resistance": 0.25, "strain_frequency": 14, "access_count": 14},
        {"id": "social_psychology", "name": "Social Psychology", "entity_type": "concept_type", "description": "Study of how people think, feel, and behave in social situations", "strain_amplitude": 0.83, "strain_resistance": 0.3, "strain_frequency": 13, "access_count": 13},
        {"id": "developmental_psychology", "name": "Developmental Psychology", "entity_type": "concept_type", "description": "Study of psychological development across the lifespan", "strain_amplitude": 0.86, "strain_resistance": 0.35, "strain_frequency": 12, "access_count": 12},
        {"id": "neuroscience", "name": "Neuroscience", "entity_type": "concept_type", "description": "Study of the nervous system and brain", "strain_amplitude": 0.91, "strain_resistance": 0.4, "strain_frequency": 11, "access_count": 11}
    ]
    
    # Historical Figures
    historical_figures = [
        {"id": "newton", "name": "Isaac Newton", "entity_type": "person", "description": "Mathematician and physicist who formulated laws of motion and gravity", "strain_amplitude": 0.93, "strain_resistance": 0.2, "strain_frequency": 16, "access_count": 16},
        {"id": "darwin", "name": "Charles Darwin", "entity_type": "person", "description": "Naturalist who developed theory of evolution by natural selection", "strain_amplitude": 0.90, "strain_resistance": 0.3, "strain_frequency": 14, "access_count": 14},
        {"id": "plato", "name": "Plato", "entity_type": "person", "description": "Ancient Greek philosopher who founded the Academy in Athens", "strain_amplitude": 0.88, "strain_resistance": 0.25, "strain_frequency": 13, "access_count": 13},
        {"id": "aristotle", "name": "Aristotle", "entity_type": "person", "description": "Ancient Greek philosopher who made contributions to logic and biology", "strain_amplitude": 0.89, "strain_resistance": 0.2, "strain_frequency": 15, "access_count": 15},
        {"id": "descartes", "name": "René Descartes", "entity_type": "person", "description": "French philosopher and mathematician who developed Cartesian geometry", "strain_amplitude": 0.87, "strain_resistance": 0.3, "strain_frequency": 12, "access_count": 12},
        {"id": "kant", "name": "Immanuel Kant", "entity_type": "person", "description": "German philosopher who wrote Critique of Pure Reason", "strain_amplitude": 0.92, "strain_resistance": 0.4, "strain_frequency": 11, "access_count": 11},
        {"id": "gauss", "name": "Carl Friedrich Gauss", "entity_type": "person", "description": "German mathematician known as the Prince of Mathematicians", "strain_amplitude": 0.91, "strain_resistance": 0.25, "strain_frequency": 13, "access_count": 13},
        {"id": "euler", "name": "Leonhard Euler", "entity_type": "person", "description": "Swiss mathematician who made fundamental contributions to analysis", "strain_amplitude": 0.90, "strain_resistance": 0.2, "strain_frequency": 14, "access_count": 14},
        {"id": "hilbert", "name": "David Hilbert", "entity_type": "person", "description": "German mathematician who formulated 23 problems for 20th century", "strain_amplitude": 0.89, "strain_resistance": 0.3, "strain_frequency": 10, "access_count": 10},
        {"id": "gödel", "name": "Kurt Gödel", "entity_type": "person", "description": "Austrian logician who proved incompleteness theorems", "strain_amplitude": 0.94, "strain_resistance": 0.5, "strain_frequency": 9, "access_count": 9}
    ]
    
    # Combine all entities
    all_entities = (math_entities + logic_entities + physics_entities + chemistry_entities + 
                   biology_entities + cs_entities + philosophy_entities + psychology_entities + 
                   historical_figures)
    
    # Add timestamps
    for entity in all_entities:
        entity["created"] = "2024-01-01T00:00:00"
        entity["modified"] = "2024-12-21T00:00:00"
    
    print(f"✅ Generated {len(all_entities)} foundational entities")
    
    # Create relationships between agents and entities
    relationships = []
    rel_id = 1
    
        # Engineer relationships
    engineer_domains = ["arithmetic", "algebra", "geometry", "calculus", "set_theory", "number_theory", 
                       "probability", "statistics", "linear_algebra", "topology", "newton", "gauss", 
                       "euler", "hilbert", "gödel"]
    for entity_id in engineer_domains:
        relationships.append({
            "id": f"rel_{rel_id}",
            "from": "engineer",
            "to": entity_id,
            "type": "has_authority",
            "authority_strength": 0.95,
            "strain_amplitude": 0.95
        })
        rel_id += 1
    
    # Skeptic relationships
    skeptic_domains = ["propositional_logic", "predicate_logic", "modal_logic", "inductive_reasoning", 
                      "deductive_reasoning", "fallacies", "validity", "soundness", "logic_philosophy"]
    for entity_id in skeptic_domains:
        relationships.append({
            "id": f"rel_{rel_id}",
            "from": "skeptic",
            "to": entity_id,
            "type": "has_authority",
            "authority_strength": 0.98,
            "strain_amplitude": 0.98
        })
        rel_id += 1
    
    # Dreamer relationships
    dreamer_domains = ["artificial_intelligence", "machine_learning", "algorithms", "programming_paradigms", 
                      "complexity_theory", "networks", "databases", "aesthetics", "philosophy_of_mind"]
    for entity_id in dreamer_domains:
        relationships.append({
            "id": f"rel_{rel_id}",
            "from": "dreamer",
            "to": entity_id,
            "type": "has_authority",
            "authority_strength": 0.85,
            "strain_amplitude": 0.85
        })
        rel_id += 1
    
    # Philosopher relationships
    philosopher_domains = ["metaphysics", "epistemology", "ethics", "aesthetics", "logic_philosophy", 
                          "philosophy_of_mind", "philosophy_of_science", "plato", "aristotle", "descartes", "kant"]
    for entity_id in philosopher_domains:
        relationships.append({
            "id": f"rel_{rel_id}",
            "from": "philosopher",
            "to": entity_id,
            "type": "has_authority",
            "authority_strength": 0.92,
            "strain_amplitude": 0.92
        })
        rel_id += 1
    
    # Investigator relationships
    investigator_domains = ["mechanics", "thermodynamics", "electromagnetism", "quantum_mechanics", 
                           "relativity", "optics", "acoustics", "fluid_dynamics", "atomic_theory", 
                           "periodic_table", "chemical_bonding", "reactions", "cell_theory", "evolution", 
                           "genetics", "ecology", "physiology", "biochemistry", "newton", "darwin"]
    for entity_id in investigator_domains:
        relationships.append({
            "id": f"rel_{rel_id}",
            "from": "investigator",
            "to": entity_id,
            "type": "has_authority",
            "authority_strength": 0.88,
            "strain_amplitude": 0.88
        })
        rel_id += 1
    
    # Archivist relationships
    archivist_domains = ["data_structures", "databases", "networks", "cognitive_psychology", 
                        "behavioral_psychology", "social_psychology", "developmental_psychology", "neuroscience"]
    for entity_id in archivist_domains:
        relationships.append({
            "id": f"rel_{rel_id}",
            "from": "archivist",
            "to": entity_id,
            "type": "has_authority",
            "authority_strength": 0.80,
            "strain_amplitude": 0.80
        })
        rel_id += 1
    
    # Stage Manager relationships (coordination across domains)
    stage_manager_domains = ["thermochemistry", "kinetics", "optics", "acoustics", "fluid_dynamics", 
                            "topology", "modal_logic", "philosophy_of_science"]
    for entity_id in stage_manager_domains:
        relationships.append({
            "id": f"rel_{rel_id}",
            "from": "stage_manager",
            "to": entity_id,
            "type": "has_authority",
            "authority_strength": 0.75,
            "strain_amplitude": 0.75
        })
        rel_id += 1
    
    print(f"✅ Generated {len(relationships)} relationships")
    
    # Save comprehensive data
    data = {
        "entities": all_entities,
        "relationships": relationships,
        "created": datetime.now().isoformat(),
        "description": "Comprehensive foundational knowledge base for Project Eidolon agents",
        "statistics": {
            "total_entities": len(all_entities),
            "total_relationships": len(relationships),
            "mathematical_concepts": len(math_entities),
            "logical_concepts": len(logic_entities),
            "physical_concepts": len(physics_entities),
            "chemical_concepts": len(chemistry_entities),
            "biological_concepts": len(biology_entities),
            "computer_science_concepts": len(cs_entities),
            "philosophical_concepts": len(philosophy_entities),
            "psychological_concepts": len(psychology_entities),
            "historical_figures": len(historical_figures)
        }
    }
    
    data_file = os.path.join(os.path.dirname(__file__), 'comprehensive_knowledge.json')
    with open(data_file, 'w') as f:
        json.dump(data, f, indent=2)
    
    print(f"✅ Comprehensive knowledge saved to: {data_file}")
    print(f"📊 Knowledge Base Statistics:")
    print(f"   • Total Entities: {len(all_entities)}")
    print(f"   • Total Relationships: {len(relationships)}")
    print(f"   • Mathematical Concepts: {len(math_entities)}")
    print(f"   • Logical Concepts: {len(logic_entities)}")
    print(f"   • Physical Concepts: {len(physics_entities)}")
    print(f"   • Chemical Concepts: {len(chemistry_entities)}")
    print(f"   • Biological Concepts: {len(biology_entities)}")
    print(f"   • Computer Science Concepts: {len(cs_entities)}")
    print(f"   • Philosophical Concepts: {len(philosophy_entities)}")
    print(f"   • Psychological Concepts: {len(psychology_entities)}")
    print(f"   • Historical Figures: {len(historical_figures)}")
    
    print("\n🎉 Comprehensive knowledge base generation complete!")
    print("Your agents now have a rich foundation to work with!")

def generate_word_nodes():
    """
    Generate nodes for the 35,000 most common English words as entities with no connections.
    Expects a file 'common_words.txt' with one word per line.
    """
    import os
    words_file = os.path.join(os.path.dirname(__file__), 'common_words.txt')
    if not os.path.exists(words_file):
        print("ERROR: 'common_words.txt' not found. Please provide a file with one word per line.")
        return
    
    with open(words_file, 'r', encoding='utf-8') as f:
        words = [line.strip() for line in f if line.strip()]
    
    entities = []
    for word in words:
        entity = {
            "id": word.lower(),
            "name": word,
            "entity_type": "concept_type",
            "description": f"Word: {word}",
            "strain_amplitude": 0.0,
            "strain_resistance": 0.5,
            "strain_frequency": 0,
            "access_count": 0
        }
        entities.append(entity)
    
    print(f"Generated {len(entities)} word nodes.")
    with open('word_nodes.json', 'w', encoding='utf-8') as out:
        import json
        json.dump(entities, out, indent=2)
    print("Word nodes saved to 'word_nodes.json'.")

if __name__ == '__main__':
    generate_comprehensive_knowledge() 