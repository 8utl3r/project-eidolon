#!/usr/bin/env python3
"""
AI Interaction Interface for Project Eidolon
Demonstrates agent coordination through natural language interaction using Cursor AI
"""

import requests
import json
import random
from datetime import datetime
import re
from cursor_ai_integration import create_ai_system, AI_CONFIG

class EidolonAI:
    def __init__(self):
        self.base_url = "http://localhost:5002"
        self.agents = {}
        self.entities = {}
        self.relationships = {}
        self.ai_system = create_ai_system()
        self.load_knowledge_base()
        
    def load_knowledge_base(self):
        """Load all agents, entities, and relationships"""
        try:
            # Load agents
            response = requests.get(f"{self.base_url}/api/agents")
            self.agents = {agent['id']: agent for agent in response.json()}
            
            # Load entities
            response = requests.get(f"{self.base_url}/api/entities")
            self.entities = {entity['id']: entity for entity in response.json()}
            
            # Load relationships
            response = requests.get(f"{self.base_url}/api/relationships")
            self.relationships = response.json()
            
            # Load knowledge base into AI system
            self.ai_system.load_knowledge_base(self.base_url)
            
            print(f"✅ Loaded {len(self.agents)} agents, {len(self.entities)} entities, {len(self.relationships)} relationships")
            print(f"🎭 AI Provider: {AI_CONFIG['current_provider']}")
            
        except Exception as e:
            print(f"❌ Error loading knowledge base: {e}")
    
    def get_agent_by_domain(self, domain_keywords):
        """Find the most appropriate agent for a given domain"""
        domain_mapping = {
            'math': 'engineer',
'mathematical': 'engineer',
'calculation': 'engineer',
'equation': 'engineer',
            'logic': 'skeptic',
            'logical': 'skeptic',
            'reasoning': 'skeptic',
            'argument': 'skeptic',
            'dream': 'dreamer',
            'creative': 'dreamer',
            'imagination': 'dreamer',
            'vision': 'dreamer',
            'investigate': 'investigator',
            'research': 'investigator',
            'explore': 'investigator',
            'discover': 'investigator',
            'philosophy': 'philosopher',
            'philosophical': 'philosopher',
            'ethics': 'philosopher',
            'meaning': 'philosopher',
            'coordinate': 'stage_manager',
            'coordination': 'stage_manager',
            'manage': 'stage_manager',
            'orchestrate': 'stage_manager',
            'archive': 'archivist',
            'record': 'archivist',
            'store': 'archivist',
            'memory': 'archivist'
        }
        
        for keyword in domain_keywords:
            if keyword.lower() in domain_mapping:
                return domain_mapping[keyword.lower()]
        
        return 'stage_manager'  # Default to stage manager for coordination
    
    def get_related_entities(self, query):
        """Find entities related to the query"""
        query_lower = query.lower()
        related = []
        
        for entity_id, entity in self.entities.items():
            if (query_lower in entity['name'].lower() or 
                query_lower in entity['description'].lower() or
                any(query_lower in keyword.lower() for keyword in entity.get('keywords', []))):
                related.append(entity)
        
        return related
    
    def get_agent_response(self, agent_id, query, context=None):
        """Generate a response from a specific agent using AI"""
        agent = self.agents.get(agent_id)
        if not agent:
            return f"Agent {agent_id} not found."
        
        # Use AI system to get response
        ai_response = self.ai_system.get_agent_response(agent_id, query)
        
        # Add strain information
        current_strain = agent.get('current_strain', 0)
        max_strain = agent.get('max_strain', 1.0)
        strain_percentage = (current_strain / max_strain) * 100
        
        return f"{ai_response} (Strain: {strain_percentage:.1f}%)"
    
    def coordinate_response(self, query):
        """Coordinate a response across multiple agents using AI"""
        # Use AI system for coordinated response
        ai_response = self.ai_system.get_coordinated_response(query)
        
        # Find related entities for context
        related_entities = self.get_related_entities(query)
        
        # Build response
        response_parts = [ai_response]
        
        if related_entities:
            entity_names = [e['name'] for e in related_entities[:3]]
            response_parts.append(f"📋 **Related Concepts:** {', '.join(entity_names)}")
        
        return "\n\n".join(response_parts)
    
    def process_query(self, query):
        """Process a user query and return coordinated response"""
        print(f"\n🎭 Processing: '{query}'")
        print("=" * 60)
        
        # Check for special commands
        if query.lower().startswith('/help'):
            return self.show_help()
        elif query.lower().startswith('/agents'):
            return self.list_agents()
        elif query.lower().startswith('/entities'):
            return self.list_entities()
        elif query.lower().startswith('/strain'):
            return self.show_strain_status()
        elif query.lower().startswith('/ai'):
            return self.show_ai_status()
        elif query.lower().startswith('/switch'):
            return self.switch_ai_provider(query)
        
        # Generate coordinated response using AI
        return self.coordinate_response(query)
    
    def show_help(self):
        """Show available commands"""
        return """
🎭 **Eidolon AI Interface - Available Commands:**

**Interaction:**
• Ask any question about knowledge, concepts, or domains
• The Stage Manager will coordinate responses across agents using AI

**Special Commands:**
• `/help` - Show this help message
• `/agents` - List all available agents and their status
• `/entities` - Show available knowledge entities
• `/strain` - Show current strain levels across agents
• `/ai` - Show current AI provider status
• `/switch <provider>` - Switch AI provider (cursor/openai/custom)

**Example Questions:**
• "What is the relationship between mathematics and physics?"
• "How does logic apply to creative thinking?"
• "Explain the concept of fluid dynamics"
• "What are the philosophical implications of computation?"

**AI Coordination:**
The Stage Manager automatically coordinates AI responses from the most relevant agents based on your query.
Current AI Provider: {provider}
        """.format(provider=AI_CONFIG['current_provider'])
    
    def list_agents(self):
        """List all agents and their status"""
        agent_list = []
        for agent_id, agent in self.agents.items():
            strain_pct = (agent['current_strain'] / agent['max_strain']) * 100
            agent_list.append(f"🎭 **{agent['agent']}** ({agent_id})")
            agent_list.append(f"   Domain: {agent['domain']}")
            agent_list.append(f"   Strain: {strain_pct:.1f}%")
            agent_list.append(f"   Keywords: {', '.join(agent['keywords'])}")
            agent_list.append("")
        
        return "\n".join(agent_list)
    
    def list_entities(self):
        """List available knowledge entities"""
        domains = {}
        for entity in self.entities.values():
            domain = entity.get('domain', 'Unknown')
            if domain not in domains:
                domains[domain] = []
            domains[domain].append(entity['name'])
        
        entity_list = ["📚 **Available Knowledge Domains:**\n"]
        for domain, entities in domains.items():
            entity_list.append(f"**{domain.title()}:**")
            entity_list.append(f"  {', '.join(entities[:5])}{'...' if len(entities) > 5 else ''}")
            entity_list.append("")
        
        return "\n".join(entity_list)
    
    def show_strain_status(self):
        """Show current strain levels"""
        strain_info = ["🎭 **Agent Strain Status:**\n"]
        
        for agent_id, agent in self.agents.items():
            strain_pct = (agent['current_strain'] / agent['max_strain']) * 100
            status = "🟢 Low" if strain_pct < 30 else "🟡 Medium" if strain_pct < 70 else "🔴 High"
            strain_info.append(f"**{agent['agent']}:** {strain_pct:.1f}% {status}")
        
        return "\n".join(strain_info)
    
    def show_ai_status(self):
        """Show current AI provider status"""
        current_provider = AI_CONFIG['current_provider']
        providers = AI_CONFIG['providers']
        
        status = [f"🤖 **AI Provider Status:**\n"]
        status.append(f"**Current Provider:** {current_provider}")
        status.append(f"**Available Providers:** {', '.join(providers.keys())}")
        
        if current_provider == 'cursor':
            status.append("**Status:** Using Cursor's built-in AI capabilities")
        elif current_provider == 'openai':
            api_key = providers['openai'].get('api_key', '')
            status.append(f"**Status:** OpenAI API {'configured' if api_key else 'not configured'}")
        elif current_provider == 'custom':
            model_path = providers['custom'].get('model_path', '')
            status.append(f"**Status:** Custom models at {model_path}")
        
        return "\n".join(status)
    
    def switch_ai_provider(self, query):
        """Switch AI provider"""
        parts = query.split()
        if len(parts) < 2:
            return "Usage: /switch <provider> (cursor/openai/custom)"
        
        new_provider = parts[1].lower()
        if new_provider not in AI_CONFIG['providers']:
            return f"Unknown provider: {new_provider}. Available: {', '.join(AI_CONFIG['providers'].keys())}"
        
        # Update configuration
        AI_CONFIG['current_provider'] = new_provider
        
        # Recreate AI system with new provider
        self.ai_system = create_ai_system()
        self.ai_system.load_knowledge_base(self.base_url)
        
        return f"✅ Switched to {new_provider} AI provider"

def main():
    """Main interaction loop"""
    print("🎭 Eidolon AI Interaction Interface")
    print("=" * 50)
    print("The Stage Manager is coordinating AI responses...")
    print("Type '/help' for available commands")
    print("Type 'quit' to exit")
    print("=" * 50)
    
    ai = EidolonAI()
    
    while True:
        try:
            query = input("\n🎭 You: ").strip()
            
            if query.lower() in ['quit', 'exit', 'q']:
                print("🎭 Thank you for interacting with the Eidolon AI system!")
                break
            
            if not query:
                continue
            
            response = ai.process_query(query)
            print(f"\n{response}")
            
        except KeyboardInterrupt:
            print("\n\n🎭 Session ended. Thank you!")
            break
        except Exception as e:
            print(f"\n❌ Error: {e}")

if __name__ == '__main__':
    main() 