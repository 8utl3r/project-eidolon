# Test Agent Orchestrator
#
# Tests the agent orchestrator functionality including Ollama integration
# and agent duty performance.

import std/[times, json, asyncdispatch, options, strutils]
import tables
import ../src/agents/orchestrator
import ../src/agents/registry

proc testAgentOrchestrator() {.async.} =
  echo "Testing Agent Orchestrator..."
  
  # Create orchestrator
  let orchestrator = newAgentOrchestrator()
  echo "Created orchestrator"
  
  # Test Ollama connection
  echo "Testing Ollama connection..."
  let response = await orchestrator.callOllama("Hello, this is a test.")
  echo "Ollama response: ", response
  
  # Test agent activation
  echo "Testing agent activation..."
  for agent_id in tables.keys(orchestrator.registry.agents):
    discard orchestrator.activateAgent(agent_id)
  
  echo "Active agents: ", orchestrator.active_agents.len
  
  # Add some test tasks
  discard orchestrator.addTask("Calculate 2+2", "math_calculation", %*{"expression": "2+2"})
  discard orchestrator.addTask("What is the meaning of life?", "philosophy_question", %*{"question": "meaning of life"})
  discard orchestrator.addTask("Verify this claim", "verification_task", %*{"claim": "test claim"})
  
  echo "Added test tasks, running duties..."
  
  # Run agent duties
  await orchestrator.runAgentDuties()
  
  # Check task status
  let status = orchestrator.getTaskStatus()
  echo "Task status: ", status
  
  echo "Agent Orchestrator test completed!"

when isMainModule:
  waitFor testAgentOrchestrator() 