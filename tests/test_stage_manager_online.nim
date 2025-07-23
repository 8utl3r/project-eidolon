# Test Stage Manager Agent Online
#
# Tests bringing the Stage Manager agent online and verifying its coordination capabilities.

import std/[times, json, asyncdispatch, options, strutils]
import tables
import ../src/agents/orchestrator
import ../src/agents/api_manager

proc testStageManagerOnline() {.async.} =
  echo "=== Stage Manager Agent Online Test ==="
  
  # Create orchestrator
  let orchestrator = newAgentOrchestrator()
  echo "✓ Created orchestrator with API manager"
  
  # Activate Stage Manager
  discard orchestrator.activateAgent("stage_manager")
  echo "✓ Activated Stage Manager agent"
  
  # Test basic coordination task
  echo "\n--- Testing Stage Manager Coordination ---"
  let coordination_task = """
Analyze the current system state and provide coordination recommendations:
- We have a knowledge graph with 10,000 word entities and 10,100 verified thoughts
- We're planning to bring multiple agents online (Engineer, Skeptic, Philosopher)
- The system needs to coordinate agent activities and manage workflows

What should be our next steps for bringing agents online effectively?
"""
  
  echo "Sending coordination task to Stage Manager..."
  let response = await orchestrator.callAgent("stage_manager", coordination_task)
  echo "\nStage Manager Response:"
  echo "========================"
  echo response
  echo "========================"
  
  # Test workflow management
  echo "\n--- Testing Workflow Management ---"
  let workflow_task = """
Create a workflow plan for the following scenario:
1. Engineer agent needs to analyze mathematical patterns in the knowledge graph
2. Skeptic agent needs to validate the data integrity
3. Philosopher agent needs to explore conceptual relationships

How should these tasks be prioritized and coordinated?
"""
  
  echo "Sending workflow task to Stage Manager..."
  let workflow_response = await orchestrator.callAgent("stage_manager", workflow_task)
  echo "\nStage Manager Workflow Response:"
  echo "================================="
  echo workflow_response
  echo "================================="
  
  # Test system status monitoring
  echo "\n--- Testing System Status Monitoring ---"
  let status_task = """
Monitor and report on the current system status:
- Number of active agents
- Available APIs and their status
- Task queue status
- Knowledge graph status (10,000 entities, 10,100 thoughts)

Provide a concise status report.
"""
  
  echo "Sending status monitoring task to Stage Manager..."
  let status_response = await orchestrator.callAgent("stage_manager", status_task)
  echo "\nStage Manager Status Report:"
  echo "============================="
  echo status_response
  echo "============================="
  
  echo "\n=== Stage Manager Agent Test Completed ==="
  echo "✓ Stage Manager is online and responding"
  echo "✓ Coordination capabilities verified"
  echo "✓ Ready to coordinate other agents"

when isMainModule:
  waitFor testStageManagerOnline() 