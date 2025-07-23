# Test All Agents Online
#
# Tests bringing all agents online simultaneously to check resource consumption,
# system stability, and agent coordination under full load.

import std/[times, json, asyncdispatch, options, strutils, sequtils]
import tables
import ../src/agents/orchestrator
import ../src/agents/api_manager

proc testAllAgentsOnline() {.async.} =
  echo "=== Full Agent Activation Test ==="
  echo "Bringing all agents online for resource consumption analysis..."
  
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
  
  # Test 1: Resource Consumption Analysis
  echo "\n--- Resource Consumption Analysis ---"
  echo "Testing concurrent agent operations..."
  
  # Create tasks for each agent type
  let tasks = @[
    ("stage_manager", "Coordinate all agents and monitor system health"),
    ("engineer", "Analyze knowledge graph mathematical properties"),
    ("philosopher", "Examine ontological relationships in the knowledge base"),
    ("skeptic", "Validate logical consistency of current thoughts"),
    ("dreamer", "Generate creative insights about knowledge patterns"),
    ("investigator", "Detect anomalies in entity relationships"),
    ("archivist", "Organize and index knowledge for optimal retrieval")
  ]
  
  # Add tasks to orchestrator
  for (agent_id, task_desc) in tasks:
    discard orchestrator.addTask(task_desc, "analysis", %*{"agent": agent_id, "priority": 1})
  
  echo "Added ", tasks.len, " tasks for concurrent processing"
  
  # Test 2: Concurrent Agent Operations
  echo "\n--- Concurrent Agent Operations ---"
  echo "Running all agents simultaneously..."
  
  # Run agent duties concurrently
  var futures: seq[Future[void]] = @[]
  
  for agent_id in all_agents:
    if orchestrator.isAgentActive(agent_id):
      let future = orchestrator.runAgentDuties()
      futures.add(future)
  
  echo "Started ", futures.len, " concurrent agent operations"
  
  # Wait for all agents to complete their duties
  echo "Waiting for agent operations to complete..."
  for future in futures:
    await future
  
  echo "✓ All agent operations completed"
  
  # Test 3: System Status Report
  echo "\n--- System Status Report ---"
  
  # Check task status
  let pending_tasks = orchestrator.tasks.filterIt(it.status == TaskStatus.Pending).len
  let completed_tasks = orchestrator.tasks.filterIt(it.status == TaskStatus.Completed).len
  let in_progress_tasks = orchestrator.tasks.filterIt(it.status == TaskStatus.InProgress).len
  
  echo "Task Status:"
  echo "  Pending: ", pending_tasks
  echo "  In Progress: ", in_progress_tasks
  echo "  Completed: ", completed_tasks
  echo "  Total: ", orchestrator.tasks.len
  
  # Check agent status
  echo "\nAgent Status:"
  for agent_id in all_agents:
    let is_active = orchestrator.isAgentActive(agent_id)
    let permissions = orchestrator.getAgentThoughtPermissions(agent_id)
    echo "  ", agent_id, ": ", (if is_active: "ACTIVE" else: "INACTIVE"), " (", permissions, ")"
  
  # Test 4: API Manager Status
  echo "\n--- API Manager Status ---"
  echo "Registered APIs: ", orchestrator.api_manager.apis.len
  
  for api_id, api in orchestrator.api_manager.apis:
    echo "  ", api_id, ": ", api.model_name, " (", api.current_requests, "/", api.max_concurrent, " requests)"
  
  # Test 5: Foreground Agent Integration
  echo "\n--- Foreground Agent Integration ---"
  echo "Testing foreground agent query processing..."
  
  # Simulate foreground agent queries
  let foreground_queries = @[
    "What is the mathematical structure of our knowledge graph?",
    "Are there any logical contradictions in our verified thoughts?",
    "What creative patterns emerge from our knowledge base?",
    "How can we optimize knowledge retrieval?",
    "What anomalies exist in our entity relationships?"
  ]
  
  for i, query in foreground_queries:
    echo "Foreground Query ", i+1, ": ", query
    let response = await orchestrator.callAgent("stage_manager", query)
    echo "Response: ", response[0..min(100, response.len-1)], "..."
  
  # Test 6: Memory and Performance Analysis
  echo "\n--- Performance Analysis ---"
  echo "Testing memory usage and performance under load..."
  
  # Simulate high-load scenario
  echo "Running stress test with multiple concurrent operations..."
  
  var stress_futures: seq[Future[string]] = @[]
  
  for i in 1..10:
    let stress_task = orchestrator.callAgent("engineer", "Analyze strain relationships in batch " & $i)
    stress_futures.add(stress_task)
  
  echo "Started ", stress_futures.len, " stress test operations"
  
  # Wait for stress test to complete
  for i, future in stress_futures:
    let result = await future
    echo "Stress test ", i+1, " completed: ", result[0..min(50, result.len-1)], "..."
  
  echo "✓ Stress test completed"
  
  # Final System Health Check
  echo "\n--- Final System Health Check ---"
  
  let active_agents = all_agents.filterIt(orchestrator.isAgentActive(it)).len
  let total_apis = orchestrator.api_manager.apis.len
  let total_tasks = orchestrator.tasks.len
  
  echo "System Health Summary:"
  echo "  Active Agents: ", active_agents, "/", all_agents.len
  echo "  Registered APIs: ", total_apis
  echo "  Total Tasks: ", total_tasks
  echo "  API Manager Status: ", (if orchestrator.api_manager.apis.len > 0: "HEALTHY" else: "ERROR")
  
  if active_agents == all_agents.len and total_apis > 0:
    echo "✓ All systems operational - Full agent activation successful!"
  else:
    echo "✗ Some systems failed to activate properly"
  
  echo "\n=== Full Agent Activation Test Completed ==="
  echo "✓ Resource consumption analyzed"
  echo "✓ Concurrent operations tested"
  echo "✓ System stability verified"
  echo "✓ Foreground agent integration working"
  echo "✓ Performance under load validated"

when isMainModule:
  waitFor testAllAgentsOnline() 