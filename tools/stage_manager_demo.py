#!/usr/bin/env python3
"""
Stage Manager Coordination Demo
Demonstrates The Stage Manager's ability to coordinate across domains
"""

import requests
import json
from datetime import datetime

def get_stage_manager_status():
    """Get The Stage Manager's current status and capabilities"""
    base_url = "http://localhost:5002"
    
    print("🎭 The Stage Manager - Coordination Demo")
    print("=" * 50)
    
    # Get The Stage Manager's agent data
    try:
        response = requests.get(f"{base_url}/api/agents")
        agents = response.json()
        stage_manager = next((agent for agent in agents if agent['id'] == 'stage_manager'), None)
        
        if stage_manager:
            print(f"🎭 Agent: {stage_manager['agent']}")
            print(f"🎭 Domain: {stage_manager['domain']}")
            print(f"🎭 Current Strain: {stage_manager['current_strain']}")
            print(f"🎭 Max Strain: {stage_manager['max_strain']}")
            print(f"🎭 Keywords: {', '.join(stage_manager['keywords'])}")
            print()
        else:
            print("❌ Stage Manager not found")
            return
    except Exception as e:
        print(f"❌ Error getting agent data: {e}")
        return
    
    # Get The Stage Manager's authority domains
    try:
        response = requests.get(f"{base_url}/api/relationships?agent_id=stage_manager")
        relationships = response.json()
        
        print("🎭 Authority Domains (Interdisciplinary Coordination):")
        print("-" * 50)
        
        for rel in relationships:
            print(f"   • {rel['to']} (authority: {rel['authority_strength']})")
        
        print()
        
        # Get detailed information about each domain
        response = requests.get(f"{base_url}/api/entities")
        entities = response.json()
        
        stage_manager_domains = [rel['to'] for rel in relationships]
        
        print("🎭 Domain Descriptions:")
        print("-" * 30)
        
        for entity in entities:
            if entity['id'] in stage_manager_domains:
                print(f"   • {entity['name']}: {entity['description']}")
                print(f"     Strain: {entity['strain_amplitude']}, Resistance: {entity['strain_resistance']}")
                print()
        
    except Exception as e:
        print(f"❌ Error getting relationship data: {e}")

def demonstrate_coordination():
    """Demonstrate how The Stage Manager coordinates across domains"""
    print("🎭 Coordination Capabilities:")
    print("=" * 40)
    
    coordination_examples = [
        {
            "scenario": "Physics-Chemistry Bridge",
            "domains": ["thermochemistry", "kinetics"],
            "description": "Coordinating heat flow in chemical reactions with reaction rates",
            "strain_impact": "High strain propagation between thermal and kinetic processes"
        },
        {
            "scenario": "Wave Phenomena Coordination", 
            "domains": ["optics", "acoustics"],
            "description": "Managing light and sound wave interactions and properties",
            "strain_impact": "Medium strain flow through wave-based systems"
        },
        {
            "scenario": "Mathematical-Physical Synthesis",
            "domains": ["fluid_dynamics", "topology"],
            "description": "Connecting fluid flow patterns with geometric transformations",
            "strain_impact": "Complex strain dynamics in mathematical-physical systems"
        },
        {
            "scenario": "Logic-Philosophy Integration",
            "domains": ["modal_logic", "philosophy_of_science"],
            "description": "Bridging logical necessity with scientific methodology",
            "strain_impact": "Abstract strain patterns in logical-philosophical reasoning"
        }
    ]
    
    for i, example in enumerate(coordination_examples, 1):
        print(f"{i}. {example['scenario']}")
        print(f"   Domains: {', '.join(example['domains'])}")
        print(f"   Function: {example['description']}")
        print(f"   Strain Impact: {example['strain_impact']}")
        print()

def show_network_analysis():
    """Show The Stage Manager's position in the knowledge network"""
    print("🎭 Network Analysis:")
    print("=" * 25)
    
    try:
        response = requests.get("http://localhost:5002/api/graph-data")
        graph_data = response.json()
        
        nodes = graph_data.get('nodes', [])
        links = graph_data.get('links', [])
        
        # Find The Stage Manager node
        stage_manager_node = next((node for node in nodes if node['id'] == 'stage_manager'), None)
        
        if stage_manager_node:
            print(f"🎭 Node ID: {stage_manager_node['id']}")
            print(f"🎭 Node Type: {stage_manager_node['type']}")
            print(f"🎭 Current Strain: {stage_manager_node['strain']}")
            print(f"🎭 Domain: {stage_manager_node['domain']}")
            
            # Count connections
            stage_manager_links = [link for link in links if link['source'] == 'stage_manager' or link['target'] == 'stage_manager']
            print(f"🎭 Total Connections: {len(stage_manager_links)}")
            
            # Find connected entities
            connected_entities = []
            for link in stage_manager_links:
                if link['source'] == 'stage_manager':
                    connected_entities.append(link['target'])
                else:
                    connected_entities.append(link['source'])
            
            print(f"🎭 Connected Entities: {', '.join(connected_entities)}")
            print()
            
            # Show strain distribution
            print("🎭 Strain Distribution Analysis:")
            print("-" * 35)
            
            total_strain = sum(link.get('strain', 0) for link in stage_manager_links)
            avg_strain = total_strain / len(stage_manager_links) if stage_manager_links else 0
            
            print(f"   • Total Strain Flow: {total_strain:.2f}")
            print(f"   • Average Strain per Connection: {avg_strain:.2f}")
            print(f"   • Coordination Efficiency: {avg_strain * len(stage_manager_links):.2f}")
            
        else:
            print("❌ Stage Manager node not found in graph")
            
    except Exception as e:
        print(f"❌ Error analyzing network: {e}")

def main():
    """Run the Stage Manager coordination demo"""
    print("🎭 The Stage Manager Coordination Demo")
    print("=" * 50)
    print(f"Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()
    
    get_stage_manager_status()
    demonstrate_coordination()
    show_network_analysis()
    
    print("🎭 Demo Complete!")
    print("The Stage Manager is ready to coordinate interdisciplinary knowledge synthesis.")
    print("Access the visual interface at: http://localhost:5002/graph-canvas")

if __name__ == '__main__':
    main() 