#!/usr/bin/env python3
"""
AI Node Interaction System for Project Eidolon
Demonstrates AI agents actually manipulating knowledge graph nodes
"""

import requests
import json
import random
import time
from datetime import datetime
from typing import Dict, List, Any, Optional
from cursor_ai_integration import create_ai_system, AI_CONFIG

class AINodeInteraction:
    def __init__(self):
        self.base_url = "http://localhost:5002"
        self.ai_system = create_ai_system()
        self.load_knowledge_base()
        
    def load_knowledge_base(self):
        """Load current knowledge base"""
        try:
            response = requests.get(f"{self.base_url}/api/agents")
            self.agents = {agent['id']: agent for agent in response.json()}
            
            response = requests.get(f"{self.base_url}/api/entities")
            self.entities = {entity['id']: entity for entity in response.json()}
            
            response = requests.get(f"{self.base_url}/api/relationships")
            self.relationships = response.json()
            
            self.ai_system.load_knowledge_base(self.base_url)
            
            print(f"✅ Loaded {len(self.agents)} agents, {len(self.entities)} entities, {len(self.relationships)} relationships")
            
        except Exception as e:
            print(f"❌ Error loading knowledge base: {e}")
    
    def save_entities_to_visualizer(self):
        """Save entities back to the graph visualizer"""
        try:
            # Convert entities dict to list
            entities_list = list(self.entities.values())
            
            # Save to a temporary file that the visualizer can load
            with open('comprehensive_knowledge_ai_enhanced.json', 'w') as f:
                json.dump({
                    'entities': entities_list,
                    'relationships': self.relationships
                }, f, indent=2)
            
            print(f"💾 Saved {len(entities_list)} entities and {len(self.relationships)} relationships to visualizer")
            
        except Exception as e:
            print(f"❌ Error saving to visualizer: {e}")
    
    def create_new_entity(self, agent_id: str, entity_data: Dict[str, Any]) -> Optional[str]:
        """Create a new entity through AI agent reasoning"""
        try:
            # Generate unique ID
            entity_id = f"entity_{len(self.entities) + 1}"
            
            # Add metadata
            entity_data.update({
                'id': entity_id,
                'created_by': agent_id,
                'created_at': datetime.now().isoformat(),
                'strain_amplitude': random.uniform(0.1, 0.9),
                'strain_resistance': random.uniform(0.1, 0.8),
                'strain_frequency': random.randint(1, 10)
            })
            
            # Add to entities
            self.entities[entity_id] = entity_data
            
            print(f"🎭 {self.agents[agent_id]['agent']} created new entity: {entity_data['name']}")
            return entity_id
            
        except Exception as e:
            print(f"❌ Error creating entity: {e}")
            return None
    
    def create_relationship(self, agent_id: str, from_entity: str, to_entity: str, relationship_type: str) -> Optional[str]:
        """Create a new relationship through AI agent reasoning"""
        try:
            # Generate unique ID
            rel_id = f"rel_{len(self.relationships) + 1}"
            
            # Create relationship
            relationship = {
                'id': rel_id,
                'from': from_entity,
                'to': to_entity,
                'type': relationship_type,
                'created_by': agent_id,
                'created_at': datetime.now().isoformat(),
                'authority_strength': random.uniform(0.3, 0.9),
                'strain_amplitude': random.uniform(0.1, 0.8)
            }
            
            # Add to relationships
            self.relationships.append(relationship)
            
            print(f"🎭 {self.agents[agent_id]['agent']} created relationship: {from_entity} -> {to_entity} ({relationship_type})")
            return rel_id
            
        except Exception as e:
            print(f"❌ Error creating relationship: {e}")
            return None
    
    def modify_entity(self, agent_id: str, entity_id: str, modifications: Dict[str, Any]) -> bool:
        """Modify an existing entity through AI agent reasoning"""
        try:
            if entity_id not in self.entities:
                print(f"❌ Entity {entity_id} not found")
                return False
            
            # Apply modifications
            for key, value in modifications.items():
                self.entities[entity_id][key] = value
            
            # Add modification metadata
            self.entities[entity_id]['modified_by'] = agent_id
            self.entities[entity_id]['modified_at'] = datetime.now().isoformat()
            
            print(f"🎭 {self.agents[agent_id]['agent']} modified entity: {entity_id}")
            return True
            
        except Exception as e:
            print(f"❌ Error modifying entity: {e}")
            return False
    
    def agent_reasoning_session(self, agent_id: str, query: str) -> Dict[str, Any]:
        """Have an agent reason about a query and potentially create/modify nodes"""
        agent = self.agents.get(agent_id)
        if not agent:
            return {"error": f"Agent {agent_id} not found"}
        
        print(f"\n🧠 {agent['agent']} is reasoning about: '{query}'")
        print("=" * 60)
        
        # Get AI response
        ai_response = self.ai_system.get_agent_response(agent_id, query)
        print(f"AI Response: {ai_response}")
        
        # Agent-specific reasoning and actions
        actions = []
        
        if agent_id == 'engineer':
            actions = self._engineer_reasoning(query)
        elif agent_id == 'skeptic':
            actions = self._skeptic_reasoning(query)
        elif agent_id == 'dreamer':
            actions = self._dreamer_reasoning(query)
        elif agent_id == 'investigator':
            actions = self._investigator_reasoning(query)
        elif agent_id == 'philosopher':
            actions = self._philosopher_reasoning(query)
        elif agent_id == 'archivist':
            actions = self._archivist_reasoning(query)
        elif agent_id == 'stage_manager':
            actions = self._stage_manager_reasoning(query)
        
        # Execute actions
        results = []
        for action in actions:
            result = self._execute_action(agent_id, action)
            if result:
                results.append(result)
        
        return {
            'agent': agent['agent'],
            'query': query,
            'ai_response': ai_response,
            'actions_taken': actions,
            'results': results
        }
    
    def _engineer_reasoning(self, query: str) -> List[Dict]:
        """Engineer's reasoning and potential actions"""
        actions = []
        
        # Look for mathematical concepts in query
        math_keywords = ['calculation', 'equation', 'formula', 'theorem', 'proof', 'number', 'function', 'mathematics', 'math']
        if any(keyword in query.lower() for keyword in math_keywords):
            # Create mathematical concept entity
            concept_name = f"Mathematical Concept {len(self.entities) + 1}"
            actions.append({
                'type': 'create_entity',
                'data': {
                    'name': concept_name,
                    'description': f'Mathematical concept related to: {query}',
                    'domain': 'mathematical concepts',
                    'keywords': ['mathematics', 'calculation', 'formal']
                }
            })
            
            # Connect to existing mathematical entities
            math_entities = [e for e in self.entities.values() if 'math' in e.get('domain', '').lower()]
            if math_entities:
                target = random.choice(math_entities)
                actions.append({
                    'type': 'create_relationship',
                    'data': {
                        'from': concept_name,
                        'to': target['id'],
                        'type': 'mathematical_connection'
                    }
                })
        
        return actions
    
    def _skeptic_reasoning(self, query: str) -> List[Dict]:
        """Skeptic's reasoning and potential actions"""
        actions = []
        
        # Look for logical concepts in query
        logic_keywords = ['logic', 'reasoning', 'argument', 'evidence', 'proof', 'assumption', 'logical']
        if any(keyword in query.lower() for keyword in logic_keywords):
            # Create logical analysis entity
            analysis_name = f"Logical Analysis {len(self.entities) + 1}"
            actions.append({
                'type': 'create_entity',
                'data': {
                    'name': analysis_name,
                    'description': f'Logical analysis of: {query}',
                    'domain': 'logical concepts',
                    'keywords': ['logic', 'reasoning', 'critical']
                }
            })
            
            # Question existing entities (modify strain)
            existing_entities = list(self.entities.values())[:3]  # Take first 3
            for entity in existing_entities:
                actions.append({
                    'type': 'modify_entity',
                    'data': {
                        'entity_id': entity['id'],
                        'modifications': {
                            'strain_amplitude': entity.get('strain_amplitude', 0.5) * 1.2  # Increase strain
                        }
                    }
                })
        
        return actions
    
    def _dreamer_reasoning(self, query: str) -> List[Dict]:
        """Dreamer's reasoning and potential actions"""
        actions = []
        
        # Create imaginative connections
        creative_name = f"Creative Vision {len(self.entities) + 1}"
        actions.append({
            'type': 'create_entity',
            'data': {
                'name': creative_name,
                'description': f'Creative interpretation of: {query}',
                'domain': 'creative concepts',
                'keywords': ['creative', 'imagination', 'vision']
            }
        })
        
        # Connect to random entities (creative synthesis)
        if self.entities:
            random_entities = random.sample(list(self.entities.values()), min(3, len(self.entities)))
            for entity in random_entities:
                actions.append({
                    'type': 'create_relationship',
                    'data': {
                        'from': creative_name,
                        'to': entity['id'],
                        'type': 'creative_synthesis'
                    }
                })
        
        return actions
    
    def _investigator_reasoning(self, query: str) -> List[Dict]:
        """Investigator's reasoning and potential actions"""
        actions = []
        
        # Create research entity
        research_name = f"Research Investigation {len(self.entities) + 1}"
        actions.append({
            'type': 'create_entity',
            'data': {
                'name': research_name,
                'description': f'Research investigation into: {query}',
                'domain': 'investigative concepts',
                'keywords': ['research', 'investigation', 'exploration']
            }
        })
        
        # Find related entities and create investigation connections
        query_words = query.lower().split()
        related_entities = [e for e in self.entities.values() 
                          if any(word in e.get('name', '').lower() or word in e.get('description', '').lower() 
                                for word in query_words)]
        
        for entity in related_entities[:5]:  # Limit to 5 connections
            actions.append({
                'type': 'create_relationship',
                'data': {
                    'from': research_name,
                    'to': entity['id'],
                    'type': 'investigation_connection'
                }
            })
        
        return actions
    
    def _philosopher_reasoning(self, query: str) -> List[Dict]:
        """Philosopher's reasoning and potential actions"""
        actions = []
        
        # Create philosophical reflection entity
        reflection_name = f"Philosophical Reflection {len(self.entities) + 1}"
        actions.append({
            'type': 'create_entity',
            'data': {
                'name': reflection_name,
                'description': f'Philosophical reflection on: {query}',
                'domain': 'philosophical concepts',
                'keywords': ['philosophy', 'ethics', 'meaning']
            }
        })
        
        # Connect to philosophical entities
        philosophical_entities = [e for e in self.entities.values() 
                                if 'philosoph' in e.get('domain', '').lower() or 'ethical' in e.get('keywords', [])]
        
        for entity in philosophical_entities[:3]:
            actions.append({
                'type': 'create_relationship',
                'data': {
                    'from': reflection_name,
                    'to': entity['id'],
                    'type': 'philosophical_connection'
                }
            })
        
        return actions
    
    def _archivist_reasoning(self, query: str) -> List[Dict]:
        """Archivist's reasoning and potential actions"""
        actions = []
        
        # Create archival record entity
        record_name = f"Archival Record {len(self.entities) + 1}"
        actions.append({
            'type': 'create_entity',
            'data': {
                'name': record_name,
                'description': f'Archival record of: {query}',
                'domain': 'archival concepts',
                'keywords': ['archive', 'record', 'memory']
            }
        })
        
        # Preserve existing entities (reduce strain)
        existing_entities = list(self.entities.values())[:5]  # Take first 5
        for entity in existing_entities:
            actions.append({
                'type': 'modify_entity',
                'data': {
                    'entity_id': entity['id'],
                    'modifications': {
                        'strain_amplitude': entity.get('strain_amplitude', 0.5) * 0.8  # Reduce strain
                    }
                }
            })
        
        return actions
    
    def _stage_manager_reasoning(self, query: str) -> List[Dict]:
        """Stage Manager's reasoning and coordination actions"""
        actions = []
        
        # Create coordination hub entity
        hub_name = f"Coordination Hub {len(self.entities) + 1}"
        actions.append({
            'type': 'create_entity',
            'data': {
                'name': hub_name,
                'description': f'Coordination hub for: {query}',
                'domain': 'coordination concepts',
                'keywords': ['coordination', 'synthesis', 'integration']
            }
        })
        
        # Connect to agents' recent entities
        recent_entities = [e for e in self.entities.values() 
                          if 'created_by' in e and e['created_by'] in self.agents.keys()]
        
        for entity in recent_entities[:3]:
            actions.append({
                'type': 'create_relationship',
                'data': {
                    'from': hub_name,
                    'to': entity['id'],
                    'type': 'coordination_connection'
                }
            })
        
        return actions
    
    def _execute_action(self, agent_id: str, action: Dict) -> Optional[Dict]:
        """Execute a single action"""
        try:
            action_type = action['type']
            
            if action_type == 'create_entity':
                entity_id = self.create_new_entity(agent_id, action['data'])
                return {'type': 'entity_created', 'entity_id': entity_id, 'data': action['data']}
            
            elif action_type == 'create_relationship':
                rel_id = self.create_relationship(agent_id, action['data']['from'], 
                                                action['data']['to'], action['data']['type'])
                return {'type': 'relationship_created', 'rel_id': rel_id, 'data': action['data']}
            
            elif action_type == 'modify_entity':
                success = self.modify_entity(agent_id, action['data']['entity_id'], 
                                           action['data']['modifications'])
                return {'type': 'entity_modified', 'success': success, 'data': action['data']}
            
            else:
                print(f"❌ Unknown action type: {action_type}")
                return None
                
        except Exception as e:
            print(f"❌ Error executing action: {e}")
            return None
    
    def coordinated_ai_session(self, query: str) -> Dict[str, Any]:
        """Have multiple agents coordinate on a query and interact with nodes"""
        print(f"\n🎭 Coordinated AI Session: '{query}'")
        print("=" * 70)
        
        # Get coordinated AI response
        ai_response = self.ai_system.get_coordinated_response(query)
        print(f"🎭 Stage Manager Coordination: {ai_response}")
        
        # Have each agent reason about the query
        agent_results = {}
        for agent_id in self.agents.keys():
            if agent_id != 'stage_manager':  # Stage Manager coordinates, doesn't create nodes directly
                result = self.agent_reasoning_session(agent_id, query)
                agent_results[agent_id] = result
                time.sleep(1)  # Brief pause between agents
        
        # Stage Manager creates coordination connections
        stage_manager_result = self.agent_reasoning_session('stage_manager', query)
        agent_results['stage_manager'] = stage_manager_result
        
        # Save changes to visualizer
        self.save_entities_to_visualizer()
        
        return {
            'query': query,
            'coordinated_response': ai_response,
            'agent_results': agent_results,
            'total_entities': len(self.entities),
            'total_relationships': len(self.relationships)
        }
    
    def demonstrate_node_evolution(self, queries: List[str]):
        """Demonstrate how the knowledge graph evolves through AI interactions"""
        print("🎭 AI Node Evolution Demonstration")
        print("=" * 50)
        
        initial_entities = len(self.entities)
        initial_relationships = len(self.relationships)
        
        print(f"📊 Initial State: {initial_entities} entities, {initial_relationships} relationships")
        
        for i, query in enumerate(queries, 1):
            print(f"\n🔄 Evolution Step {i}: {query}")
            print("-" * 40)
            
            result = self.coordinated_ai_session(query)
            
            current_entities = len(self.entities)
            current_relationships = len(self.relationships)
            
            print(f"📈 Growth: +{current_entities - initial_entities} entities, +{current_relationships - initial_relationships} relationships")
            
            # Update counts
            initial_entities = current_entities
            initial_relationships = current_relationships
            
            time.sleep(2)  # Pause between queries
        
        print(f"\n🎯 Final State: {len(self.entities)} entities, {len(self.relationships)} relationships")
        print("✅ Node evolution demonstration complete!")

def main():
    """Main demonstration function"""
    print("🎭 Project Eidolon - AI Node Interaction Demonstration")
    print("=" * 60)
    
    # Create AI node interaction system
    ai_interaction = AINodeInteraction()
    
    # Demonstration queries that will trigger different agent behaviors
    demonstration_queries = [
        "What is the relationship between mathematics and creativity?",
        "How can we apply logical reasoning to ethical dilemmas?",
        "What are the philosophical implications of artificial intelligence?",
        "How does scientific investigation connect to human imagination?",
        "What patterns emerge when we synthesize knowledge across domains?"
    ]
    
    # Run the demonstration
    ai_interaction.demonstrate_node_evolution(demonstration_queries)
    
    print("\n🎭 To see the updated graph:")
    print("  Visit: http://localhost:5002/graph-canvas")
    print("\n🎭 To interact with the AI system:")
    print("  python3 tools/ai_interaction_interface.py")

if __name__ == '__main__':
    main() 