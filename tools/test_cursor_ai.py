#!/usr/bin/env python3
"""
Test Cursor AI Integration for Project Eidolon
Demonstrates AI provider switching and agent coordination
"""

import json
import os
from cursor_ai_integration import create_ai_system, AI_CONFIG

def test_ai_integration():
    """Test the AI integration system"""
    print("🎭 Testing Cursor AI Integration")
    print("=" * 50)
    
    # Create AI system
    ai_system = create_ai_system()
    
    # Load knowledge base
    print("📚 Loading knowledge base...")
    ai_system.load_knowledge_base("http://localhost:5002")
    
    # Test queries
    test_queries = [
        "What is calculus?",
        "How does logic apply to creative thinking?",
        "What are the philosophical implications of computation?",
        "Explain the relationship between mathematics and physics"
    ]
    
    print("\n🧪 Testing AI Responses:")
    print("-" * 30)
    
    for i, query in enumerate(test_queries, 1):
        print(f"\n{i}. Query: {query}")
        print("-" * 20)
        
        # Test coordinated response
        response = ai_system.get_coordinated_response(query)
        print(f"Coordinated Response: {response}")
        
        # Test individual agent responses
        agents = ['engineer', 'skeptic', 'dreamer']
        for agent in agents:
            response = ai_system.get_agent_response(agent, query)
            print(f"{agent.title()}: {response}")
    
    print("\n✅ AI Integration Test Complete!")

def test_provider_switching():
    """Test switching between AI providers"""
    print("\n🔄 Testing Provider Switching")
    print("=" * 40)
    
    providers = ['cursor', 'openai', 'custom']
    
    for provider in providers:
        print(f"\n📡 Switching to {provider} provider...")
        
        # Update configuration
        AI_CONFIG['current_provider'] = provider
        
        # Create new AI system
        ai_system = create_ai_system()
        ai_system.load_knowledge_base("http://localhost:5002")
        
        # Test response
        query = "What is the nature of consciousness?"
        response = ai_system.get_coordinated_response(query)
        print(f"Response: {response}")
    
    # Reset to cursor
    AI_CONFIG['current_provider'] = 'cursor'
    print(f"\n✅ Reset to {AI_CONFIG['current_provider']} provider")

def show_configuration():
    """Show current AI configuration"""
    print("\n⚙️ Current AI Configuration:")
    print("=" * 40)
    
    config_file = "ai_config.json"
    if os.path.exists(config_file):
        with open(config_file, 'r') as f:
            config = json.load(f)
        
        current_provider = config['current_provider']
        providers = config['providers']
        
        print(f"Current Provider: {current_provider}")
        print(f"Provider Details: {providers[current_provider]['name']}")
        print(f"Description: {providers[current_provider]['description']}")
        print(f"Enabled: {providers[current_provider]['enabled']}")
        
        print(f"\nAvailable Providers:")
        for provider_id, provider_info in providers.items():
            status = "✅" if provider_info['enabled'] else "❌"
            print(f"  {status} {provider_id}: {provider_info['name']}")
    else:
        print("❌ Configuration file not found")

def demonstrate_transition_path():
    """Demonstrate how to transition to other AI providers"""
    print("\n🛤️ Transition Path to Other AI Providers:")
    print("=" * 50)
    
    transition_steps = {
        "OpenAI API": [
            "1. Get OpenAI API key from https://platform.openai.com",
            "2. Set environment variable: export OPENAI_API_KEY='your-key'",
            "3. Update ai_config.json: set 'current_provider' to 'openai'",
            "4. Restart the AI system"
        ],
        "Anthropic Claude": [
            "1. Get Anthropic API key from https://console.anthropic.com",
            "2. Set environment variable: export ANTHROPIC_API_KEY='your-key'",
            "3. Update ai_config.json: set 'current_provider' to 'anthropic'",
            "4. Restart the AI system"
        ],
        "Custom Models": [
            "1. Train or obtain custom AI models",
            "2. Place models in ./models/ directory",
            "3. Update ai_config.json: set 'current_provider' to 'custom'",
            "4. Configure model paths and parameters",
            "5. Restart the AI system"
        ]
    }
    
    for provider, steps in transition_steps.items():
        print(f"\n📋 {provider}:")
        for step in steps:
            print(f"  {step}")

def main():
    """Main test function"""
    print("🎭 Project Eidolon - Cursor AI Integration Test")
    print("=" * 60)
    
    # Show configuration
    show_configuration()
    
    # Test AI integration
    test_ai_integration()
    
    # Test provider switching
    test_provider_switching()
    
    # Show transition path
    demonstrate_transition_path()
    
    print("\n🎭 Test Complete!")
    print("\nTo start the interactive AI interface:")
    print("  python3 tools/ai_interaction_interface.py")
    print("\nTo switch AI providers:")
    print("  Edit tools/ai_config.json and change 'current_provider'")

if __name__ == '__main__':
    main() 