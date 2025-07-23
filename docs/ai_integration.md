# AI Integration System for Project Eidolon

## Overview

The AI Integration System provides a flexible, pluggable architecture for connecting Project Eidolon agents to various AI providers. The system is designed to work seamlessly with Cursor's built-in AI capabilities while maintaining easy transition paths to external APIs or custom AI models.

## Architecture

### Core Components

1. **AIProvider Interface**: Abstract base class defining the interface for all AI providers
2. **Provider Implementations**: Concrete implementations for different AI systems
3. **AgentAISystem**: Main coordination system that manages agent-AI interactions
4. **Configuration System**: JSON-based configuration for easy provider switching

### Design Principles

- **Pluggable Architecture**: Easy to swap AI providers without changing core logic
- **Provider Agnostic**: Core system doesn't depend on specific AI implementations
- **Configuration Driven**: All settings managed through configuration files
- **Transition Ready**: Built-in support for migrating between AI providers

## Current AI Providers

### 1. Cursor AI (Default)
- **Status**: ✅ Active
- **Description**: Uses Cursor's built-in AI capabilities
- **Advantages**: No API keys needed, integrated with development environment
- **Use Case**: Development, testing, and immediate AI functionality

### 2. OpenAI API
- **Status**: 🔧 Ready for configuration
- **Description**: Uses OpenAI GPT models via API
- **Requirements**: OpenAI API key
- **Use Case**: Production deployment, advanced reasoning

### 3. Anthropic Claude
- **Status**: 🔧 Ready for configuration
- **Description**: Uses Anthropic Claude via API
- **Requirements**: Anthropic API key
- **Use Case**: Ethical AI, safety-focused applications

### 4. Custom Models
- **Status**: 🔧 Ready for configuration
- **Description**: Uses locally trained or custom AI models
- **Requirements**: Custom model files
- **Use Case**: Domain-specific AI, privacy requirements

### 5. Simulated AI
- **Status**: 🔧 Ready for configuration
- **Description**: Uses simulated responses for testing
- **Use Case**: Testing, development without AI dependencies

## Configuration

### Main Configuration File: `tools/ai_config.json`

```json
{
  "current_provider": "cursor",
  "providers": {
    "cursor": {
      "name": "Cursor AI",
      "description": "Using Cursor's built-in AI capabilities",
      "enabled": true,
      "config": {}
    },
    "openai": {
      "name": "OpenAI API",
      "description": "Using OpenAI GPT models via API",
      "enabled": false,
      "config": {
        "api_key": "",
        "model": "gpt-4",
        "temperature": 0.7,
        "max_tokens": 1000
      }
    }
  }
}
```

### Agent-Specific Configuration

Each agent has specialized prompts and configurations:

```json
{
  "agent_configs": {
    "mathematician": {
      "specialization": "mathematical reasoning",
      "response_style": "precise and analytical",
      "domain_keywords": ["math", "calculation", "equation", "number", "formula"]
    }
  }
}
```

## Usage

### Starting the AI Interface

```bash
# Start the interactive AI interface
python3 tools/ai_interaction_interface.py

# Or use the convenience script
./scripts/start-ai-interface.sh
```

### Available Commands

- `/help` - Show available commands
- `/agents` - List all agents and their status
- `/entities` - Show available knowledge entities
- `/strain` - Show current strain levels
- `/ai` - Show current AI provider status
- `/switch <provider>` - Switch AI provider

### Example Interactions

```
🎭 You: What is calculus?
🎭 AI Response: 🔢 Mathematical analysis: This query involves precise calculations and formal structures that can be modeled using quantitative methods.

🎭 You: How does logic apply to creative thinking?
🎭 AI Response: 🤔 Skeptical inquiry: Let's examine the assumptions behind this query and apply rigorous logical examination.
```

## Transition Paths

### Switching to OpenAI API

1. **Get API Key**:
   ```bash
   # Visit https://platform.openai.com
   # Create account and get API key
   ```

2. **Set Environment Variable**:
   ```bash
   export OPENAI_API_KEY='your-api-key-here'
   ```

3. **Update Configuration**:
   ```json
   {
     "current_provider": "openai",
     "providers": {
       "openai": {
         "enabled": true,
         "config": {
           "api_key": "${OPENAI_API_KEY}",
           "model": "gpt-4"
         }
       }
     }
   }
   ```

4. **Restart System**:
   ```bash
   python3 tools/ai_interaction_interface.py
   ```

### Switching to Anthropic Claude

1. **Get API Key**:
   ```bash
   # Visit https://console.anthropic.com
   # Create account and get API key
   ```

2. **Set Environment Variable**:
   ```bash
   export ANTHROPIC_API_KEY='your-api-key-here'
   ```

3. **Update Configuration**:
   ```json
   {
     "current_provider": "anthropic",
     "providers": {
       "anthropic": {
         "enabled": true,
         "config": {
           "api_key": "${ANTHROPIC_API_KEY}",
           "model": "claude-3-sonnet-20240229"
         }
       }
     }
   }
   ```

### Switching to Custom Models

1. **Prepare Models**:
   ```bash
   mkdir -p tools/models/
   # Place your custom model files in tools/models/
   ```

2. **Update Configuration**:
   ```json
   {
     "current_provider": "custom",
     "providers": {
       "custom": {
         "enabled": true,
         "config": {
           "model_path": "./models/",
           "model_type": "transformer",
           "device": "cpu"
         }
       }
     }
   }
   ```

## Development

### Adding New AI Providers

1. **Create Provider Class**:
   ```python
   class NewAIProvider(AIProvider):
       def __init__(self, config):
           self.config = config
       
       def get_response(self, agent_id: str, query: str, context: Dict[str, Any]) -> str:
           # Implement AI response logic
           return "AI response"
       
       def get_coordinated_response(self, query: str, agents: List[str], context: Dict[str, Any]) -> str:
           # Implement coordinated response logic
           return "Coordinated response"
   ```

2. **Update Factory**:
   ```python
   class AIProviderFactory:
       @staticmethod
       def create_provider(provider_type: str, **kwargs) -> AIProvider:
           if provider_type == "new_provider":
               return NewAIProvider(kwargs)
           # ... existing providers
   ```

3. **Add Configuration**:
   ```json
   {
     "providers": {
       "new_provider": {
         "name": "New AI Provider",
         "description": "Description of new provider",
         "enabled": true,
         "config": {}
       }
     }
   }
   ```

### Testing

```bash
# Test AI integration
python3 tools/test_cursor_ai.py

# Test specific provider
python3 -c "
from cursor_ai_integration import create_ai_system
ai = create_ai_system('openai')
ai.load_knowledge_base('http://localhost:5002')
response = ai.get_coordinated_response('Test query')
print(response)
"
```

## Agent Coordination

### How Agents Work with AI

1. **Query Analysis**: System analyzes user query to determine relevant agents
2. **Agent Selection**: Most relevant agents are selected based on keywords and context
3. **AI Processing**: Each agent processes the query through their specialized AI prompts
4. **Coordination**: Stage Manager synthesizes responses from multiple agents
5. **Response Generation**: Final coordinated response is generated

### Agent Specializations

- **Mathematician**: Mathematical reasoning, calculations, formal structures
- **Skeptic**: Logical reasoning, critical analysis, evidence evaluation
- **Dreamer**: Creative thinking, imagination, innovative approaches
- **Investigator**: Research, exploration, systematic investigation
- **Philosopher**: Philosophical reasoning, ethics, meaning
- **Archivist**: Knowledge preservation, historical patterns
- **Stage Manager**: Coordination, interdisciplinary synthesis

## Performance Considerations

### Response Times
- **Cursor AI**: ~1-3 seconds (local processing)
- **OpenAI API**: ~2-5 seconds (network dependent)
- **Anthropic Claude**: ~3-7 seconds (network dependent)
- **Custom Models**: Variable (depends on model size and hardware)

### Cost Considerations
- **Cursor AI**: Free (included with Cursor)
- **OpenAI API**: Pay-per-token (~$0.03 per 1K tokens for GPT-4)
- **Anthropic Claude**: Pay-per-token (~$0.015 per 1K tokens)
- **Custom Models**: One-time training cost, then free

## Troubleshooting

### Common Issues

1. **API Key Errors**:
   ```bash
   # Check environment variables
   echo $OPENAI_API_KEY
   echo $ANTHROPIC_API_KEY
   ```

2. **Configuration Errors**:
   ```bash
   # Validate JSON configuration
   python3 -m json.tool tools/ai_config.json
   ```

3. **Network Issues**:
   ```bash
   # Test API connectivity
   curl -H "Authorization: Bearer $OPENAI_API_KEY" https://api.openai.com/v1/models
   ```

### Debug Mode

```python
# Enable debug logging
import logging
logging.basicConfig(level=logging.DEBUG)

# Test with debug output
ai_system = create_ai_system()
ai_system.load_knowledge_base("http://localhost:5002")
response = ai_system.get_coordinated_response("Debug test")
```

## Future Enhancements

### Planned Features

1. **Multi-Provider Fallback**: Automatic fallback if primary provider fails
2. **Response Caching**: Cache common responses to reduce API calls
3. **Streaming Responses**: Real-time response streaming for better UX
4. **Custom Training**: Tools for training domain-specific models
5. **Advanced Coordination**: More sophisticated agent coordination algorithms

### Integration Opportunities

1. **Cursor Extensions**: Deep integration with Cursor's extension system
2. **IDE Integration**: Direct integration with other IDEs
3. **Cloud Deployment**: Deploy as cloud service for team collaboration
4. **API Gateway**: Expose agent coordination as REST API

## Conclusion

The AI Integration System provides a robust foundation for Project Eidolon's agent coordination while maintaining flexibility for future AI provider transitions. The system is designed to grow with your needs, from simple Cursor AI integration to complex multi-provider deployments.

For questions or contributions, please refer to the project documentation or create an issue in the repository. 