#!/usr/bin/env python3
"""
Cursor AI Integration for Project Eidolon Agents
Provides AI capabilities using Cursor's built-in AI with easy transition to external APIs
"""

import json
import os
import subprocess
import tempfile
from typing import Dict, List, Optional, Any
from abc import ABC, abstractmethod

class AIProvider(ABC):
    """Abstract base class for AI providers - enables easy swapping"""
    
    @abstractmethod
    def get_response(self, agent_id: str, query: str, context: Dict[str, Any]) -> str:
        """Get AI response for a specific agent"""
        pass
    
    @abstractmethod
    def get_coordinated_response(self, query: str, agents: List[str], context: Dict[str, Any]) -> str:
        """Get coordinated response from multiple agents"""
        pass

class CursorAIProvider(AIProvider):
    """AI provider using Cursor's built-in AI capabilities"""
    
    def __init__(self):
        self.agent_prompts = {
            'engineer': """You are The Engineer, an expert in mathematical reasoning, analysis, and systematic processes.
Your domain: mathematical concepts, calculations, formal structures, quantitative methods.
Respond with precise mathematical insights and systematic analysis.
Current query: {query}
Context: {context}
Provide a mathematical perspective:""",
            
            'skeptic': """You are The Skeptic, an expert in logical reasoning and critical analysis.
Your domain: logical concepts, reasoning, arguments, critical examination.
Respond with skeptical inquiry and rigorous logical examination.
Current query: {query}
Context: {context}
Provide a skeptical analysis:""",
            
            'dreamer': """You are The Dreamer, an expert in creative thinking and imaginative approaches.
Your domain: creative concepts, imagination, vision, innovative thinking.
Respond with creative insights and imaginative perspectives.
Current query: {query}
Context: {context}
Provide a creative perspective:""",
            
            'investigator': """You are The Investigator, an expert in research and exploration.
Your domain: investigative concepts, research, exploration, discovery.
Respond with investigative approaches and systematic research.
Current query: {query}
Context: {context}
Provide an investigative perspective:""",
            
            'philosopher': """You are The Philosopher, an expert in philosophical reasoning and ethical consideration.
Your domain: philosophical concepts, ethics, meaning, metaphysical inquiry.
Respond with philosophical reflection and ethical consideration.
Current query: {query}
Context: {context}
Provide a philosophical perspective:""",
            
            'archivist': """You are The Archivist, an expert in knowledge preservation and historical patterns.
Your domain: archival concepts, records, memory, knowledge preservation.
Respond with archival insights and historical pattern analysis.
Current query: {query}
Context: {context}
Provide an archival perspective:""",
            
            'stage_manager': """You are The Stage Manager, an expert in coordination and interdisciplinary synthesis.
Your domain: context coordination, management, orchestration across domains.
Respond with coordination insights and interdisciplinary synthesis.
Current query: {query}
Context: {context}
Provide a coordination perspective:"""
        }
    
    def get_response(self, agent_id: str, query: str, context: Dict[str, Any]) -> str:
        """Get AI response using Cursor's AI capabilities"""
        prompt = self.agent_prompts.get(agent_id, f"Agent {agent_id} response to: {query}")
        formatted_prompt = prompt.format(query=query, context=json.dumps(context, indent=2))
        
        # Use Cursor's AI through command line interface
        return self._call_cursor_ai(formatted_prompt)
    
    def get_coordinated_response(self, query: str, agents: List[str], context: Dict[str, Any]) -> str:
        """Get coordinated response from multiple agents"""
        coordination_prompt = f"""You are The Stage Manager coordinating responses from multiple agents.

Query: {query}
Context: {json.dumps(context, indent=2)}

The following agents are available: {', '.join(agents)}

Provide a coordinated response that synthesizes perspectives from the most relevant agents.
Structure your response as:
1. Stage Manager coordination overview
2. Primary agent response
3. Supporting agent responses (if relevant)
4. Synthesis and conclusions

Response:"""
        
        return self._call_cursor_ai(coordination_prompt)
    
    def _call_cursor_ai(self, prompt: str) -> str:
        """Call Cursor's AI using command line interface"""
        try:
            # Create a temporary file with the prompt
            with tempfile.NamedTemporaryFile(mode='w', suffix='.txt', delete=False) as f:
                f.write(prompt)
                temp_file = f.name
            
            # Use Cursor's CLI to get AI response
            # Note: This is a placeholder - actual Cursor CLI commands may vary
            cmd = f"cursor ai --prompt-file {temp_file}"
            
            # For now, return a simulated response
            # In production, this would call the actual Cursor AI
            response = self._simulate_cursor_response(prompt)
            
            # Clean up temp file
            os.unlink(temp_file)
            
            return response
            
        except Exception as e:
            return f"AI response error: {str(e)}"
    
    def _simulate_cursor_response(self, prompt: str) -> str:
        """Simulate Cursor AI response for development"""
        # This simulates what Cursor AI would return
        # In production, replace with actual Cursor AI call
        
        # Extract the actual query from the coordination prompt
        query_start = prompt.find("Query: ")
        if query_start != -1:
            query_end = prompt.find("\n", query_start)
            if query_end != -1:
                actual_query = prompt[query_start + 7:query_end].strip()
            else:
                actual_query = prompt[query_start + 7:].strip()
        else:
            actual_query = prompt
        
        # Analyze the actual query content, not the coordination prompt
        query_lower = actual_query.lower()
        
        # Check for specific query content
        if any(word in query_lower for word in ['math', 'mathematical', 'calculation', 'equation', 'number', 'calculate']):
            return "🔢 **Mathematical Analysis:** This query involves precise calculations and formal structures that can be modeled using quantitative methods. The Engineer would approach this through rigorous mathematical frameworks and computational analysis."
        
        elif any(word in query_lower for word in ['logic', 'logical', 'reasoning', 'argument', 'critical', 'think']):
            return "🤔 **Skeptical Inquiry:** This query requires rigorous logical examination. The Skeptic would analyze assumptions, identify potential fallacies, and apply systematic reasoning to evaluate the validity of claims."
        
        elif any(word in query_lower for word in ['creative', 'imagination', 'vision', 'dream', 'innovative', 'art', 'design']):
            return "💭 **Creative Vision:** This query opens possibilities for innovative approaches. The Dreamer would explore imaginative perspectives, consider unconventional solutions, and envision new possibilities beyond conventional thinking."
        
        elif any(word in query_lower for word in ['research', 'explore', 'investigate', 'discover', 'analyze', 'study', 'examine']):
            return "🔍 **Investigative Approach:** This query requires systematic exploration. The Investigator would gather evidence, examine underlying mechanisms, and apply research methods to uncover deeper insights."
        
        elif any(word in query_lower for word in ['philosophy', 'ethical', 'meaning', 'purpose', 'moral', 'value', 'existential']):
            return "🧠 **Philosophical Reflection:** This query raises fundamental questions about meaning and purpose. The Philosopher would examine ethical dimensions, explore conceptual frameworks, and consider the deeper implications."
        
        elif any(word in query_lower for word in ['record', 'memory', 'archive', 'store', 'history', 'past', 'document']):
            return "📚 **Archival Perspective:** This connects to historical patterns and represents important knowledge to preserve. The Archivist would identify relevant historical context and ensure proper documentation of insights."
        
        elif any(word in query_lower for word in ['cook', 'food', 'recipe', 'kitchen', 'ingredient']):
            return "🍳 **Practical Knowledge:** This query involves practical, hands-on knowledge. The Stage Manager would coordinate insights from multiple domains: the Investigator for research methods, the Philosopher for cultural significance, and practical experience for implementation."
        
        elif any(word in query_lower for word in ['chocolate', 'sweet', 'candy', 'dessert']):
            return "🍫 **Multidisciplinary Analysis:** This query spans multiple domains. The Stage Manager coordinates: the Investigator for scientific properties, the Philosopher for cultural significance, the Dreamer for creative applications, and the Archivist for historical context."
        
        else:
            return "🎭 **Coordinated Response:** The Stage Manager has analyzed your query and determined it requires interdisciplinary synthesis. Multiple agents have been consulted to provide a comprehensive perspective that integrates mathematical precision, logical reasoning, creative insights, and practical knowledge."

class OpenAIProvider(AIProvider):
    """AI provider using OpenAI API (for future use)"""
    
    def __init__(self, api_key: str):
        self.api_key = api_key
        # OpenAI integration would go here
    
    def get_response(self, agent_id: str, query: str, context: Dict[str, Any]) -> str:
        """Get AI response using OpenAI API"""
        # Placeholder for OpenAI integration
        return f"OpenAI response for {agent_id}: {query}"
    
    def get_coordinated_response(self, query: str, agents: List[str], context: Dict[str, Any]) -> str:
        """Get coordinated response using OpenAI API"""
        # Placeholder for OpenAI integration
        return f"OpenAI coordinated response: {query}"

class CustomAIProvider(AIProvider):
    """AI provider using custom trained models (for future use)"""
    
    def __init__(self, model_path: str):
        self.model_path = model_path
        # Custom model integration would go here
    
    def get_response(self, agent_id: str, query: str, context: Dict[str, Any]) -> str:
        """Get AI response using custom model"""
        # Placeholder for custom model integration
        return f"Custom AI response for {agent_id}: {query}"
    
    def get_coordinated_response(self, query: str, agents: List[str], context: Dict[str, Any]) -> str:
        """Get coordinated response using custom model"""
        # Placeholder for custom model integration
        return f"Custom AI coordinated response: {query}"

class AIProviderFactory:
    """Factory for creating AI providers"""
    
    @staticmethod
    def create_provider(provider_type: str, **kwargs) -> AIProvider:
        """Create an AI provider based on type"""
        if provider_type == "cursor":
            return CursorAIProvider()
        elif provider_type == "openai":
            return OpenAIProvider(kwargs.get('api_key', ''))
        elif provider_type == "custom":
            return CustomAIProvider(kwargs.get('model_path', ''))
        else:
            raise ValueError(f"Unknown AI provider type: {provider_type}")

class AgentAISystem:
    """Main AI system for agent coordination"""
    
    def __init__(self, provider_type: str = "cursor", **provider_kwargs):
        self.provider = AIProviderFactory.create_provider(provider_type, **provider_kwargs)
        self.agents = {}
        self.entities = {}
        self.relationships = {}
    
    def load_knowledge_base(self, base_url: str):
        """Load agents, entities, and relationships from API"""
        import requests
        
        try:
            # Load agents
            response = requests.get(f"{base_url}/api/agents")
            self.agents = {agent['id']: agent for agent in response.json()}
            
            # Load entities
            response = requests.get(f"{base_url}/api/entities")
            self.entities = {entity['id']: entity for entity in response.json()}
            
            # Load relationships
            response = requests.get(f"{base_url}/api/relationships")
            self.relationships = response.json()
            
            print(f"✅ Loaded {len(self.agents)} agents, {len(self.entities)} entities, {len(self.relationships)} relationships")
            
        except Exception as e:
            print(f"❌ Error loading knowledge base: {e}")
    
    def get_agent_response(self, agent_id: str, query: str) -> str:
        """Get AI response from a specific agent"""
        agent = self.agents.get(agent_id)
        if not agent:
            return f"Agent {agent_id} not found."
        
        context = {
            'agent': agent,
            'related_entities': self._find_related_entities(query),
            'agent_relationships': self._get_agent_relationships(agent_id)
        }
        
        return self.provider.get_response(agent_id, query, context)
    
    def get_coordinated_response(self, query: str) -> str:
        """Get coordinated response from multiple agents"""
        # Determine relevant agents
        relevant_agents = self._determine_relevant_agents(query)
        
        context = {
            'query': query,
            'relevant_agents': relevant_agents,
            'related_entities': self._find_related_entities(query),
            'all_agents': self.agents
        }
        
        return self.provider.get_coordinated_response(query, relevant_agents, context)
    
    def _find_related_entities(self, query: str) -> List[Dict]:
        """Find entities related to the query"""
        query_lower = query.lower()
        related = []
        
        for entity_id, entity in self.entities.items():
            if (query_lower in entity['name'].lower() or 
                query_lower in entity['description'].lower()):
                related.append(entity)
        
        return related[:5]  # Limit to 5 most relevant
    
    def _get_agent_relationships(self, agent_id: str) -> List[Dict]:
        """Get relationships for a specific agent"""
        return [rel for rel in self.relationships if rel.get('from') == agent_id]
    
    def _determine_relevant_agents(self, query: str) -> List[str]:
        """Determine which agents are most relevant to the query"""
        words = query.lower().split()
        
        # Simple keyword matching - could be enhanced with more sophisticated NLP
        agent_keywords = {
            'engineer': ['math', 'mathematical', 'calculation', 'equation', 'number', 'how do i', 'process', 'method', 'procedure'],
            'skeptic': ['logic', 'logical', 'reasoning', 'argument', 'critical'],
            'dreamer': ['creative', 'imagination', 'vision', 'dream', 'innovative'],
            'investigator': ['research', 'explore', 'investigate', 'discover', 'analyze'],
            'philosopher': ['philosophy', 'ethical', 'meaning', 'purpose', 'moral'],
            'archivist': ['record', 'memory', 'archive', 'store', 'history'],
            'stage_manager': ['coordinate', 'manage', 'orchestrate', 'synthesize']
        }
        
        relevant_agents = []
        for agent_id, keywords in agent_keywords.items():
            if any(word in keywords for word in words):
                relevant_agents.append(agent_id)
        
        # Always include stage manager for coordination
        if 'stage_manager' not in relevant_agents:
            relevant_agents.append('stage_manager')
        
        return relevant_agents[:3]  # Limit to 3 most relevant agents

# Configuration for easy provider switching
AI_CONFIG = {
    'current_provider': 'cursor',  # Change this to switch providers
    'providers': {
        'cursor': {},
        'openai': {'api_key': os.getenv('OPENAI_API_KEY', '')},
        'custom': {'model_path': './models/'}
    }
}

def create_ai_system() -> AgentAISystem:
    """Create AI system with current configuration"""
    config = AI_CONFIG
    provider_type = config['current_provider']
    provider_kwargs = config['providers'].get(provider_type, {})
    
    return AgentAISystem(provider_type, **provider_kwargs)

if __name__ == '__main__':
    # Example usage
    ai_system = create_ai_system()
    ai_system.load_knowledge_base("http://localhost:5002")
    
    # Test single agent response
    response = ai_system.get_agent_response('engineer', 'What is calculus?')
    print(f"Engineer: {response}")
    
    # Test coordinated response
    response = ai_system.get_coordinated_response('How does mathematics relate to philosophy?')
    print(f"Coordinated: {response}") 