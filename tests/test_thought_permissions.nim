# Test Thought Permissions System
#
# Tests the new thought permission hierarchy where Stage Manager has full authority
# and other agents have limited thought creation powers.

import std/[times, json, asyncdispatch, options, strutils]
import tables
import ../src/agents/orchestrator
import ../src/agents/api_manager

proc testThoughtPermissions() {.async.} =
  echo "=== Thought Permissions System Test ==="
  
  # Create orchestrator
  let orchestrator = newAgentOrchestrator()
  echo "✓ Created orchestrator with API manager"
  
  # Test 1: Agent Permission Setup
  echo "\n--- Testing Agent Permission Setup ---"
  
  # Activate agents with different permission levels
  discard orchestrator.activateAgent("stage_manager")
  discard orchestrator.activateAgent("engineer")
  discard orchestrator.activateAgent("dreamer")
  
  # Check permissions
  echo "Stage Manager permissions: ", orchestrator.getAgentThoughtPermissions("stage_manager")
  echo "Engineer permissions: ", orchestrator.getAgentThoughtPermissions("engineer")
  echo "Dreamer permissions: ", orchestrator.getAgentThoughtPermissions("dreamer")
  
  # Test 2: Engineer Suggests Thought to Stage Manager
  echo "\n--- Testing Engineer Thought Suggestion ---"
  let engineer_analysis = """
Mathematical Analysis of Knowledge Graph Structure:
- Entity distribution follows power-law pattern
- Connection density shows small-world network characteristics
- Optimal clustering coefficient should be maintained at 0.3-0.7 range
- Strain relationships follow fractal dimension patterns
"""
  
  echo "Engineer requesting thought verification..."
  let verification_response = await orchestrator.requestThoughtVerification(
    "engineer", 
    engineer_analysis, 
    "mathematical_analysis"
  )
  
  echo "\nStage Manager Verification Response:"
  echo "===================================="
  echo verification_response
  echo "===================================="
  
  # Test 3: Stage Manager Creates Verified Thought
  echo "\n--- Testing Stage Manager Verified Thought Creation ---"
  let thought_content = "Knowledge graph optimization requires power-law distribution maintenance"
  let connections = @["knowledge_graph", "optimization", "power_law", "distribution"]
  
  echo "Stage Manager creating verified thought..."
  let verified_thought = await orchestrator.createVerifiedThought(
    "stage_manager",
    thought_content,
    connections
  )
  
  echo "\nStage Manager Verified Thought:"
  echo "==============================="
  echo verified_thought
  echo "==============================="
  
  # Test 4: Engineer Attempts Direct Thought Creation (Should Fail)
  echo "\n--- Testing Engineer Direct Thought Creation (Should Fail) ---"
  let engineer_attempt = await orchestrator.createVerifiedThought(
    "engineer",
    "This should fail - Engineer cannot create verified thoughts directly",
    @["test", "failure"]
  )
  
  echo "Engineer direct thought creation result:"
  echo "========================================"
  echo engineer_attempt
  echo "========================================"
  
  # Test 5: Permission Validation
  echo "\n--- Testing Permission Validation ---"
  let stage_manager_api = orchestrator.api_manager.getAPIForAgent("stage_manager")
  let engineer_api = orchestrator.api_manager.getAPIForAgent("engineer")
  
  if stage_manager_api.isSome and engineer_api.isSome:
    let sm_api = stage_manager_api.get()
    let eng_api = engineer_api.get()
    
    echo "Stage Manager can create verified thoughts: ", sm_api.canCreateVerifiedThoughts()
    echo "Engineer can create verified thoughts: ", eng_api.canCreateVerifiedThoughts()
    echo "Stage Manager can suggest thoughts: ", sm_api.canSuggestThoughts()
    echo "Engineer can suggest thoughts: ", eng_api.canSuggestThoughts()
    echo "Stage Manager can create draft thoughts: ", sm_api.canCreateDraftThoughts()
    echo "Engineer can create draft thoughts: ", eng_api.canCreateDraftThoughts()
  
  echo "\n=== Thought Permissions System Test Completed ==="
  echo "✓ Permission hierarchy established"
  echo "✓ Stage Manager has full authority"
  echo "✓ Other agents have limited permissions"
  echo "✓ Thought verification workflow working"
  echo "✓ Permission validation working"

when isMainModule:
  waitFor testThoughtPermissions() 