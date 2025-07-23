# Test Eidolon Foreground Agent
#
# This test verifies that the Eidolon foreground agent is properly implemented
# and can process user queries.

import std/[unittest, times, strutils, options, tables, sequtils]
import ../src/types
import ../src/entities/manager
import ../src/thoughts/manager
import ../src/agents/registry
import ../src/agents/eidolon/eidolon
import ../src/api/ollama_client
import ../src/knowledge_graph/types

proc testEidolonAgentCreation() =
  ## Test Eidolon agent creation
  echo "Testing Eidolon agent creation..."
  
  var ollama_client = newOllamaClient()
  var knowledge_graph = newKnowledgeGraph()
  var thought_manager = newThoughtManager()
  var agent_registry = newAgentRegistry()
  
  let eidolon = newEidolonAgent(ollama_client, knowledge_graph, thought_manager, agent_registry)
  
  check eidolon.agent_id == "eidolon"
  check eidolon.agent_type == AgentType.eidolon
  check eidolon.state == AgentState.active
  check eidolon.current_strain == 0.0
  check eidolon.max_strain == 1.0
  echo "✓ Eidolon agent creation successful"

proc testEidolonAgentRegistration() =
  ## Test Eidolon agent registration
  echo "Testing Eidolon agent registration..."
  
  var agent_registry = newAgentRegistry()
  discard agent_registry.initializeDefaultAgents()
  
  let eidolon_agents = agent_registry.getAgentsByType(AgentType.eidolon)
  check eidolon_agents.len > 0
  echo "✓ Eidolon agent registration successful"

proc testEidolonAgentKeywords() =
  ## Test Eidolon agent keyword matching
  echo "Testing Eidolon agent keyword matching..."
  
  var agent_registry = newAgentRegistry()
  discard agent_registry.initializeDefaultAgents()
  
  # Test keyword matching for eidolon agent
  let user_query = "what is the meaning of life"
  let relevant_agents = agent_registry.findAgentsByKeywords(user_query)
  
  # Should find eidolon agent for user queries
  var found_eidolon = false
  for agent_id in relevant_agents:
    if agent_id == "eidolon":
      found_eidolon = true
      break
  
  check found_eidolon
  echo "✓ Eidolon agent keyword matching successful"

proc testEidolonAgentFocus() =
  ## Test Eidolon agent focus management
  echo "Testing Eidolon agent focus management..."
  
  var ollama_client = newOllamaClient()
  var knowledge_graph = newKnowledgeGraph()
  var thought_manager = newThoughtManager()
  var agent_registry = newAgentRegistry()
  
  var eidolon = newEidolonAgent(ollama_client, knowledge_graph, thought_manager, agent_registry)
  
  # Test focus management
  let test_entities = @["entity_1", "entity_2", "entity_3"]
  eidolon.updateFocus(test_entities)
  
  let current_focus = eidolon.getCurrentFocus()
  check current_focus == test_entities
  echo "✓ Eidolon agent focus management successful"

proc testEidolonAgentStatus() =
  ## Test Eidolon agent status reporting
  echo "Testing Eidolon agent status reporting..."
  
  var ollama_client = newOllamaClient()
  var knowledge_graph = newKnowledgeGraph()
  var thought_manager = newThoughtManager()
  var agent_registry = newAgentRegistry()
  
  let eidolon = newEidolonAgent(ollama_client, knowledge_graph, thought_manager, agent_registry)
  
  let status = eidolon.getStatus()
  check status["agent_id"] == "eidolon"
  check status["agent_type"] == "eidolon"
  check status["state"] == "active"
  check status["is_available"] == "true"
  echo "✓ Eidolon agent status reporting successful"

proc testEidolonAgentStrain() =
  ## Test Eidolon agent strain management
  echo "Testing Eidolon agent strain management..."
  
  var ollama_client = newOllamaClient()
  var knowledge_graph = newKnowledgeGraph()
  var thought_manager = newThoughtManager()
  var agent_registry = newAgentRegistry()
  
  var eidolon = newEidolonAgent(ollama_client, knowledge_graph, thought_manager, agent_registry)
  
  # Test initial strain
  check eidolon.getStrain() == 0.0
  
  # Test strain reset
  eidolon.resetStrain()
  check eidolon.getStrain() == 0.0
  
  # Test availability
  check eidolon.isAvailable() == true
  echo "✓ Eidolon agent strain management successful"

proc main() =
  echo "=== Testing Eidolon Foreground Agent ===\n"
  
  try:
    testEidolonAgentCreation()
    testEidolonAgentRegistration()
    testEidolonAgentKeywords()
    testEidolonAgentFocus()
    testEidolonAgentStatus()
    testEidolonAgentStrain()
    
    echo "\n=== All Eidolon Agent Tests Passed ==="
    echo "✓ Eidolon foreground agent is properly implemented"
    
  except Exception as e:
    echo "❌ Test failed: ", e.msg
    quit(1)

when isMainModule:
  main() 