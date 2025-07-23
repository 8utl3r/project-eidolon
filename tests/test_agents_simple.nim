# Simple Agent Test
#
# This script initializes the background and foreground agents
# and shows their status without running a complex HTTP server.

import std/[times, json, strutils, tables]
import agents/orchestrator
import agents/activity_monitor
import types

proc main() =
  echo "Project Eidolon - Agent System Test"
  echo "==================================="
  echo ""
  
  # Create orchestrator
  echo "Initializing agent orchestrator..."
  var orchestrator = newAgentOrchestrator()
  echo "✅ Orchestrator created"
  
  # Create activity monitor
  echo "Initializing activity monitor..."
  var activity_monitor = newActivityMonitor(orchestrator)
  echo "✅ Activity monitor created"
  
  echo ""
  echo "Agent Registry Status:"
  echo "====================="
  
  # Show all registered agents
  for agent_id, agent in orchestrator.registry.agents:
    let is_active = orchestrator.isAgentActive(agent_id)
    let permissions = orchestrator.getAgentThoughtPermissions(agent_id)
    
    echo "Agent: ", agent_id
    echo "  Type: ", $agent.agent_type
    echo "  Active: ", if is_active: "✅" else: "❌"
    echo "  Permissions: ", permissions
    echo "  Keywords: ", agent.keywords.join(", ")
    echo "  Current Strain: ", agent.current_strain.formatFloat(ffDecimal, 2)
    echo ""
  
  echo "API Manager Status:"
  echo "=================="
  
  # Show API status
  for api_name, api in orchestrator.api_manager.apis:
    echo "API: ", api_name
    echo "  Model: ", api.model_name
    echo "  URL: ", api.base_url
    echo "  Permissions: ", $api.getThoughtPermission()
    echo "  Active: ", if api.is_active: "✅" else: "❌"
    echo ""
  
  echo "System Status:"
  echo "=============="
  echo "Total Agents: ", orchestrator.registry.agents.len
  echo "Active Agents: ", orchestrator.active_agents.len
  echo "Total APIs: ", orchestrator.api_manager.apis.len
  
  echo ""
  echo "Agent System is ready!"
  echo "Canvas server is running on http://localhost:9090"
  echo "You can now interact with the agents through the canvas interface."
  echo ""
  echo "Press Enter to exit..."
  discard readLine(stdin)

when isMainModule:
  main() 