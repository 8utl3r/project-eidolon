# Simple Agent Activation Test
#
# Tests bringing all agents online to check if activation works without hanging.

import std/[times, json, asyncdispatch, options, strutils, sequtils]
import tables
import ../src/agents/orchestrator
import ../src/agents/api_manager

proc testAgentActivationSimple() {.async.} =
  echo "=== Simple Agent Activation Test ==="
  echo "Testing basic agent activation without complex operations..."
  
  # Create orchestrator
  let orchestrator = newAgentOrchestrator()
  echo "✓ Created orchestrator with API manager"
  
  # List of all agents to activate
  let all_agents = @[
    "stage_manager",
    "engineer", 
    "philosopher",
    "skeptic",
    "dreamer",
    "investigator",
    "archivist"
  ]
  
  echo "\n--- Activating All Agents ---"
  var activated_count = 0
  
  for agent_id in all_agents:
    if orchestrator.activateAgent(agent_id):
      activated_count += 1
      echo "✓ Activated: ", agent_id
    else:
      echo "✗ Failed to activate: ", agent_id
  
  echo "\nTotal agents activated: ", activated_count, "/", all_agents.len
  
  # Check agent status
  echo "\n--- Agent Status Check ---"
  for agent_id in all_agents:
    let is_active = orchestrator.isAgentActive(agent_id)
    let permissions = orchestrator.getAgentThoughtPermissions(agent_id)
    echo "  ", agent_id, ": ", (if is_active: "ACTIVE" else: "INACTIVE"), " (", permissions, ")"
  
  # Check API Manager Status
  echo "\n--- API Manager Status ---"
  echo "Registered APIs: ", orchestrator.api_manager.apis.len
  
  for api_id, api in orchestrator.api_manager.apis:
    echo "  ", api_id, ": ", api.model_name, " (", api.current_requests, "/", api.max_concurrent, " requests)"
  
  # Simple test of one agent call
  echo "\n--- Testing Single Agent Call ---"
  echo "Testing Stage Manager with simple query..."
  
  let response = await orchestrator.callAgent("stage_manager", "What is your current status?")
  echo "Stage Manager Response: ", response[0..min(100, response.len-1)], "..."
  
  # Final System Health Check
  echo "\n--- Final System Health Check ---"
  
  let active_agents = all_agents.filterIt(orchestrator.isAgentActive(it)).len
  let total_apis = orchestrator.api_manager.apis.len
  
  echo "System Health Summary:"
  echo "  Active Agents: ", active_agents, "/", all_agents.len
  echo "  Registered APIs: ", total_apis
  echo "  API Manager Status: ", (if orchestrator.api_manager.apis.len > 0: "HEALTHY" else: "ERROR")
  
  if active_agents == all_agents.len and total_apis > 0:
    echo "✓ All systems operational - Agent activation successful!"
  else:
    echo "✗ Some systems failed to activate properly"
  
  echo "\n=== Simple Agent Activation Test Completed ==="
  echo "✓ Basic activation tested"
  echo "✓ Status verification completed"
  echo "✓ Single agent call tested"
  echo "✓ System health validated"

when isMainModule:
  waitFor testAgentActivationSimple() 