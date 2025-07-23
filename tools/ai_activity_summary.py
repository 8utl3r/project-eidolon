#!/usr/bin/env python3
"""
AI Activity Summary for Project Eidolon
Shows what the AI agents accomplished and how the knowledge graph evolved
"""

import requests
import json
from collections import defaultdict
from datetime import datetime

class AIActivitySummary:
    def __init__(self):
        self.base_url = "http://localhost:5002"
        self.load_data()
    
    def load_data(self):
        """Load current knowledge base data"""
        try:
            response = requests.get(f"{self.base_url}/api/agents")
            self.agents = {agent['id']: agent for agent in response.json()}
            
            response = requests.get(f"{self.base_url}/api/entities")
            self.entities = {entity['id']: entity for entity in response.json()}
            
            response = requests.get(f"{self.base_url}/api/relationships")
            self.relationships = response.json()
            
            print(f"✅ Loaded {len(self.agents)} agents, {len(self.entities)} entities, {len(self.relationships)} relationships")
            
        except Exception as e:
            print(f"❌ Error loading data: {e}")
    
    def analyze_ai_created_entities(self):
        """Analyze entities created by AI agents"""
        print("\n🎭 AI-Created Entities Analysis")
        print("=" * 40)
        
        ai_entities = {}
        for entity_id, entity in self.entities.items():
            if 'created_by' in entity and entity['created_by'] in self.agents:
                agent_id = entity['created_by']
                if agent_id not in ai_entities:
                    ai_entities[agent_id] = []
                ai_entities[agent_id].append(entity)
        
        total_ai_entities = sum(len(entities) for entities in ai_entities.values())
        print(f"📊 Total AI-created entities: {total_ai_entities}")
        
        for agent_id, entities in ai_entities.items():
            agent_name = self.agents[agent_id]['agent']
            print(f"\n🔹 {agent_name} created {len(entities)} entities:")
            for entity in entities:
                print(f"   • {entity['name']} ({entity.get('domain', 'unknown domain')})")
    
    def analyze_ai_created_relationships(self):
        """Analyze relationships created by AI agents"""
        print("\n🔗 AI-Created Relationships Analysis")
        print("=" * 40)
        
        ai_relationships = defaultdict(list)
        for rel in self.relationships:
            if 'created_by' in rel and rel['created_by'] in self.agents:
                agent_id = rel['created_by']
                ai_relationships[agent_id].append(rel)
        
        total_ai_relationships = sum(len(rels) for rels in ai_relationships.values())
        print(f"📊 Total AI-created relationships: {total_ai_relationships}")
        
        for agent_id, relationships in ai_relationships.items():
            agent_name = self.agents[agent_id]['agent']
            print(f"\n🔹 {agent_name} created {len(relationships)} relationships:")
            
            # Group by relationship type
            rel_types = defaultdict(list)
            for rel in relationships:
                rel_types[rel['type']].append(rel)
            
            for rel_type, rels in rel_types.items():
                print(f"   • {rel_type}: {len(rels)} connections")
    
    def analyze_entity_modifications(self):
        """Analyze entities modified by AI agents"""
        print("\n🔧 AI Entity Modifications Analysis")
        print("=" * 40)
        
        modified_entities = {}
        for entity_id, entity in self.entities.items():
            if 'modified_by' in entity and entity['modified_by'] in self.agents:
                agent_id = entity['modified_by']
                if agent_id not in modified_entities:
                    modified_entities[agent_id] = []
                modified_entities[agent_id].append(entity)
        
        total_modifications = sum(len(entities) for entities in modified_entities.values())
        print(f"📊 Total entity modifications: {total_modifications}")
        
        for agent_id, entities in modified_entities.items():
            agent_name = self.agents[agent_id]['agent']
            print(f"\n🔹 {agent_name} modified {len(entities)} entities:")
            for entity in entities:
                print(f"   • {entity['name']} (strain: {entity.get('strain_amplitude', 'unknown'):.2f})")
    
    def show_knowledge_graph_evolution(self):
        """Show how the knowledge graph evolved"""
        print("\n📈 Knowledge Graph Evolution")
        print("=" * 40)
        
        # Count entities by domain
        domains = defaultdict(int)
        for entity in self.entities.values():
            domain = entity.get('domain', 'unknown')
            domains[domain] += 1
        
        print("📊 Entities by Domain:")
        for domain, count in sorted(domains.items(), key=lambda x: x[1], reverse=True):
            print(f"   • {domain}: {count} entities")
        
        # Count relationships by type
        rel_types = defaultdict(int)
        for rel in self.relationships:
            rel_type = rel.get('type', 'unknown')
            rel_types[rel_type] += 1
        
        print(f"\n📊 Relationships by Type:")
        for rel_type, count in sorted(rel_types.items(), key=lambda x: x[1], reverse=True):
            print(f"   • {rel_type}: {count} connections")
    
    def show_agent_activity_summary(self):
        """Show summary of each agent's activities"""
        print("\n🎭 Agent Activity Summary")
        print("=" * 40)
        
        for agent_id, agent in self.agents.items():
            agent_name = agent['agent']
            
            # Count entities created by this agent
            entities_created = len([e for e in self.entities.values() 
                                  if e.get('created_by') == agent_id])
            
            # Count relationships created by this agent
            relationships_created = len([r for r in self.relationships 
                                       if r.get('created_by') == agent_id])
            
            # Count entities modified by this agent
            entities_modified = len([e for e in self.entities.values() 
                                   if e.get('modified_by') == agent_id])
            
            print(f"\n🔹 {agent_name}:")
            print(f"   • Entities created: {entities_created}")
            print(f"   • Relationships created: {relationships_created}")
            print(f"   • Entities modified: {entities_modified}")
            print(f"   • Domain: {agent.get('domain', 'unknown')}")
    
    def show_network_connectivity(self):
        """Show network connectivity analysis"""
        print("\n🌐 Network Connectivity Analysis")
        print("=" * 40)
        
        # Find most connected entities
        entity_connections = defaultdict(int)
        for rel in self.relationships:
            entity_connections[rel['from']] += 1
            entity_connections[rel['to']] += 1
        
        # Show top connected entities
        top_connected = sorted(entity_connections.items(), key=lambda x: x[1], reverse=True)[:10]
        print("🔗 Most Connected Entities:")
        for entity_id, connections in top_connected:
            entity_name = self.entities.get(entity_id, {}).get('name', entity_id)
            print(f"   • {entity_name}: {connections} connections")
        
        # Show AI-created hubs
        ai_hubs = []
        for entity_id, connections in entity_connections.items():
            entity = self.entities.get(entity_id, {})
            if entity.get('created_by') in self.agents and connections >= 3:
                ai_hubs.append((entity_id, connections, entity))
        
        if ai_hubs:
            print(f"\n🎭 AI-Created Network Hubs:")
            for entity_id, connections, entity in sorted(ai_hubs, key=lambda x: x[1], reverse=True):
                agent_name = self.agents[entity['created_by']]['agent']
                print(f"   • {entity['name']} ({agent_name}): {connections} connections")
    
    def generate_summary_report(self):
        """Generate a comprehensive summary report"""
        print("🎭 Project Eidolon - AI Activity Summary Report")
        print("=" * 60)
        print(f"📅 Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        
        # Basic statistics
        print(f"\n📊 Basic Statistics:")
        print(f"   • Total agents: {len(self.agents)}")
        print(f"   • Total entities: {len(self.entities)}")
        print(f"   • Total relationships: {len(self.relationships)}")
        
        # AI-created content
        ai_entities = [e for e in self.entities.values() if 'created_by' in e and e['created_by'] in self.agents]
        ai_relationships = [r for r in self.relationships if 'created_by' in r and r['created_by'] in self.agents]
        
        print(f"   • AI-created entities: {len(ai_entities)}")
        print(f"   • AI-created relationships: {len(ai_relationships)}")
        
        # Run all analyses
        self.analyze_ai_created_entities()
        self.analyze_ai_created_relationships()
        self.analyze_entity_modifications()
        self.show_knowledge_graph_evolution()
        self.show_agent_activity_summary()
        self.show_network_connectivity()
        
        print(f"\n🎯 Summary:")
        print(f"   • AI agents successfully expanded the knowledge graph")
        print(f"   • Each agent contributed unique perspectives and connections")
        print(f"   • The Stage Manager coordinated cross-domain synthesis")
        print(f"   • The network shows emergent patterns of interdisciplinary knowledge")

def main():
    """Main function"""
    summary = AIActivitySummary()
    summary.generate_summary_report()
    
    print(f"\n🎭 To explore the evolved graph:")
    print(f"   Visit: http://localhost:5002/graph-canvas")
    print(f"\n🎭 To interact with the AI system:")
    print(f"   python3 tools/ai_interaction_interface.py")

if __name__ == '__main__':
    main() 