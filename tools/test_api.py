#!/usr/bin/env python3
"""
Test the Project Eidolon Graph Visualizer API endpoints
"""

import requests
import json

def test_api():
    """Test the API endpoints"""
    base_url = "http://localhost:5002"
    
    print("Testing Project Eidolon Graph Visualizer API...")
    print("=" * 50)
    
    # Test agents endpoint
    try:
        response = requests.get(f"{base_url}/api/agents")
        if response.status_code == 200:
            agents = response.json()
            print(f"✅ Agents API: {len(agents)} agents loaded")
            for agent in agents:
                print(f"   • {agent['agent']} (strain: {agent['current_strain']})")
        else:
            print(f"❌ Agents API failed: {response.status_code}")
    except Exception as e:
        print(f"❌ Agents API error: {e}")
    
    print()
    
    # Test entities endpoint
    try:
        response = requests.get(f"{base_url}/api/entities")
        if response.status_code == 200:
            entities = response.json()
            print(f"✅ Entities API: {len(entities)} entities loaded")
            for entity in entities[:5]:  # Show first 5
                print(f"   • {entity['name']} ({entity['entity_type']})")
            if len(entities) > 5:
                print(f"   ... and {len(entities) - 5} more")
        else:
            print(f"❌ Entities API failed: {response.status_code}")
    except Exception as e:
        print(f"❌ Entities API error: {e}")
    
    print()
    
    # Test relationships endpoint
    try:
        response = requests.get(f"{base_url}/api/relationships")
        if response.status_code == 200:
            relationships = response.json()
            print(f"✅ Relationships API: {len(relationships)} relationships loaded")
            for rel in relationships[:5]:  # Show first 5
                print(f"   • {rel['from']} -> {rel['to']} ({rel['type']})")
            if len(relationships) > 5:
                print(f"   ... and {len(relationships) - 5} more")
        else:
            print(f"❌ Relationships API failed: {response.status_code}")
    except Exception as e:
        print(f"❌ Relationships API error: {e}")
    
    print()
    
    # Test graph data endpoint
    try:
        response = requests.get(f"{base_url}/api/graph-data")
        if response.status_code == 200:
            graph_data = response.json()
            nodes = graph_data.get('nodes', [])
            links = graph_data.get('links', [])
            print(f"✅ Graph Data API: {len(nodes)} nodes, {len(links)} links")
            
            # Count agent vs entity nodes
            agent_nodes = [n for n in nodes if n.get('isAgent', False)]
            entity_nodes = [n for n in nodes if not n.get('isAgent', False)]
            print(f"   • Agent nodes: {len(agent_nodes)}")
            print(f"   • Entity nodes: {len(entity_nodes)}")
        else:
            print(f"❌ Graph Data API failed: {response.status_code}")
    except Exception as e:
        print(f"❌ Graph Data API error: {e}")
    
    print()
    print("🎉 API testing complete!")
    print(f"Open {base_url}/graph-canvas in your browser to see the visualization")

if __name__ == '__main__':
    test_api() 