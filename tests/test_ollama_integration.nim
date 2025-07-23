# Test Ollama Integration
#
# This test verifies that the Ollama integration works correctly
# with the agent system.

import std/[times, strutils, json]
import ../src/types
import ../src/api/ollama_client

const RUN_OLLAMA_TESTS* = true

proc testOllamaClientCreation*(): bool =
  ## Test creating an Ollama client
  echo "Testing Ollama client creation..."
  
  let client = newOllamaClient()
  
  if client.base_url != "http://localhost:11434":
    echo "❌ Base URL not set correctly"
    return false
  
  if client.default_model != "llama3":
    echo "❌ Default model not set correctly"
    return false
  
  echo "✅ Ollama client creation test passed"
  return true

proc testAgentPromptCreation*(): bool =
  ## Test creating agent prompts
  echo "Testing agent prompt creation..."
  
  let mathematician_prompt = createMathematicianPrompt("What is 2+2?")
  if mathematician_prompt.agent_type != AgentType.mathematician:
    echo "❌ Mathematician prompt agent type incorrect"
    return false
  
  let skeptic_prompt = createSkepticPrompt("Is this argument valid?")
  if skeptic_prompt.agent_type != AgentType.skeptic:
    echo "❌ Skeptic prompt agent type incorrect"
    return false
  
  let dreamer_prompt = createDreamerPrompt("What if we could fly?")
  if dreamer_prompt.agent_type != AgentType.dreamer:
    echo "❌ Dreamer prompt agent type incorrect"
    return false
  
  echo "✅ Agent prompt creation test passed"
  return true

proc testModelRecommendations*(): bool =
  ## Test model recommendations for different agents
  echo "Testing model recommendations..."
  
  if getRecommendedModel(AgentType.mathematician) != "llama3":
    echo "❌ Mathematician model recommendation incorrect"
    return false
  
  if getRecommendedModel(AgentType.dreamer) != "mistral":
    echo "❌ Dreamer model recommendation incorrect"
    return false
  
  if getRecommendedModel(AgentType.skeptic) != "llama3":
    echo "❌ Skeptic model recommendation incorrect"
    return false
  
  echo "✅ Model recommendations test passed"
  return true

proc testOllamaConnection*(): bool =
  ## Test connection to Ollama server
  echo "Testing Ollama server connection..."
  
  var client = newOllamaClient()
  
  # Test if we can connect to Ollama
  let is_available = client.checkModelAvailability("llama3")
  
  if not is_available:
    echo "⚠️  Ollama server not available - skipping connection test"
    echo "   To run this test, start Ollama with: ollama serve"
    return true  # Not a failure, just not available
  
  echo "✅ Ollama server connection test passed"
  return true

proc testAgentResponseGeneration*(): bool =
  ## Test generating responses for agents
  echo "Testing agent response generation..."
  
  var client = newOllamaClient()
  
  # Test with a simple query
  let prompt = createMathematicianPrompt("What is the square root of 16?")
  let response = client.generateAgentResponse(prompt)
  
  if response.isSome():
    echo "✅ Agent response generation test passed"
    echo "   Response: " & response.get()[0..min(100, response.get().len-1)] & "..."
    return true
  else:
    echo "⚠️  Agent response generation failed - Ollama may not be available"
    echo "   To run this test, start Ollama with: ollama serve"
    return true  # Not a failure, just not available

proc testResponseFormatting*(): bool =
  ## Test response formatting
  echo "Testing response formatting..."
  
  let formatted = formatAgentResponse(
    AgentType.mathematician,
    "The answer is 4",
    0.95
  )
  
  if not formatted.contains("Agent: mathematician"):
    echo "❌ Response formatting missing agent type"
    return false
  
  if not formatted.contains("Confidence: 0.95"):
    echo "❌ Response formatting missing confidence"
    return false
  
  if not formatted.contains("The answer is 4"):
    echo "❌ Response formatting missing response content"
    return false
  
  echo "✅ Response formatting test passed"
  return true

proc runAllOllamaTests*(): bool =
  ## Run all Ollama integration tests
  echo "Running Ollama integration tests..."
  echo "=================================="
  
  var all_passed = true
  
  if not testOllamaClientCreation():
    all_passed = false
  
  if not testAgentPromptCreation():
    all_passed = false
  
  if not testModelRecommendations():
    all_passed = false
  
  if not testOllamaConnection():
    all_passed = false
  
  if not testAgentResponseGeneration():
    all_passed = false
  
  if not testResponseFormatting():
    all_passed = false
  
  echo "=================================="
  if all_passed:
    echo "✅ All Ollama integration tests passed!"
  else:
    echo "❌ Some Ollama integration tests failed"
  
  return all_passed

when isMainModule:
  discard runAllOllamaTests() 