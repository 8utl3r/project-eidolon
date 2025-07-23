# Agent Runner
#
# This module runs the background and foreground agents
# and displays their activity in the terminal.

import std/[times, json, strutils, tables, asyncdispatch, os, options]
import agents/orchestrator
import agents/activity_monitor
import types

type
  AgentRunner* = ref object
    ## Simple agent runner
    orchestrator*: AgentOrchestrator
    activity_monitor*: ActivityMonitor
    running*: bool
    update_interval*: int  # seconds

# Constructor
proc newAgentRunner*(): AgentRunner =
  ## Create a new agent runner
  let orchestrator = newAgentOrchestrator()
  let activity_monitor = newActivityMonitor(orchestrator)
  
  return AgentRunner(
    orchestrator: orchestrator,
    activity_monitor: activity_monitor,
    running: false,
    update_interval: 5
  )

# Display agent status
proc displayAgentStatus*(runner: AgentRunner) =
  ## Display current agent status
  echo "\n" & "=".repeat(80)
  echo "AGENT STATUS - ", now().format("HH:mm:ss")
  echo "=".repeat(80)
  
  # Show registered agents
  echo "\n📋 REGISTERED AGENTS:"
  echo "-".repeat(40)
  for agent_id, agent in runner.orchestrator.registry.agents:
    let status = case agent.state
      of AgentState.active: "🟢 ACTIVE"
      of AgentState.available: "🟡 AVAILABLE"
      of AgentState.inactive: "🔴 INACTIVE"
    echo "  ", agent_id, " (", $agent.agent_type, ") - ", status
    echo "    Strain: ", agent.current_strain
    echo "    Keywords: ", agent.keywords.join(", ")
    echo ""
  
  # Show recent activity
  echo "📊 RECENT ACTIVITY:"
  echo "-".repeat(40)
  let activity_data = runner.activity_monitor.getAgentActivityData()
  let agents = activity_data["agents"]
  if agents.len == 0:
    echo "  No recent activity"
  else:
    for agent_id, agent_data in agents:
      if agent_data["is_active"].getBool:
        echo "  ", agent_id, " - ", agent_data["current_task"].getStr
  echo ""

# Run agent simulation
proc runAgentSimulation*(runner: AgentRunner) =
  ## Run a simple agent simulation
  echo "🤖 Starting Agent Simulation..."
  echo "Press Ctrl+C to stop"
  echo ""
  
  runner.running = true
  
  # Activate some agents
  echo "🔧 Activating agents..."
  for agent_id, agent in runner.orchestrator.registry.agents:
    if agent.agent_type in [AgentType.dreamer, AgentType.stage_manager, AgentType.skeptic]:
      let success = runner.orchestrator.activateAgent(agent_id)
      if success:
        echo "  Activated: ", agent_id
      else:
        echo "  Failed to activate: ", agent_id
  
  echo ""
  
  # Main loop
  while runner.running:
    try:
      # Display status
      displayAgentStatus(runner)
      
      # Simulate some agent activity
      for agent_id, agent in runner.orchestrator.registry.agents:
        if runner.orchestrator.isAgentActive(agent_id):
          # Simulate agent thinking/working
          let activity = case agent.agent_type
            of AgentType.dreamer: "Dreaming about new possibilities..."
            of AgentType.stage_manager: "Managing context and flow..."
            of AgentType.skeptic: "Questioning assumptions..."
            of AgentType.investigator: "Investigating patterns..."
            of AgentType.philosopher: "Contemplating deeper meanings..."
            of AgentType.engineer: "Building and optimizing..."
            else: "Processing..."
          
          runner.activity_monitor.updateAgentActivity(agent_id, true, some(activity))
      
      # Wait for next update
      sleep(runner.update_interval * 1000)
      
    except:
      echo "Error in simulation: ", getCurrentExceptionMsg()
      sleep(1000)

# Main entry point
when isMainModule:
  echo "Project Eidolon - Agent Runner"
  echo "=============================="
  echo ""
  
  var runner = newAgentRunner()
  runner.runAgentSimulation() 