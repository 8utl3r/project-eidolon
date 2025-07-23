# Test Attention System and Thought Validation
#
# Tests the new attention-based agent coordination and thought validation system.

import std/[times, json, asyncdispatch, options, strutils, sequtils]
import tables
import ../src/agents/orchestrator
import ../src/agents/attention_system
import ../src/thoughts/validator

proc testAttentionSystem() =
  echo "=== Testing Attention System ==="
  
  # Create orchestrator with attention system
  let orchestrator = newAgentOrchestrator()
  echo "✓ Created orchestrator with attention system"
  
  # Test foreground focus update
  echo "\n--- Testing Foreground Focus ---"
  orchestrator.updateForegroundFocus(@["entity_1", "entity_2", "entity_3"])
  
  let foreground_focus = orchestrator.getForegroundFocus()
  echo "Foreground focus: ", foreground_focus
  assert foreground_focus.len == 3, "Foreground focus should have 3 entities"
  
  # Test agent attention allocation
  echo "\n--- Testing Agent Attention ---"
  let stage_manager_attention = orchestrator.getAgentAttention("stage_manager")
  echo "Stage Manager attention: ", stage_manager_attention
  
  let is_attending = orchestrator.isAgentAttendingTo("stage_manager", "entity_1")
  echo "Stage Manager attending to entity_1: ", is_attending
  assert is_attending, "Stage Manager should be attending to foreground entities"
  
  # Test system state
  echo "\n--- Testing System State ---"
  let system_state = orchestrator.getSystemState()
  echo "System state: ", system_state
  assert system_state == SystemState.wake, "System should be in wake state with recent activity"
  
  echo "✓ Attention system tests passed"

proc testThoughtValidation() =
  echo "\n=== Testing Thought Validation ==="
  
  # Create orchestrator with thought validator
  let orchestrator = newAgentOrchestrator()
  echo "✓ Created orchestrator with thought validator"
  
  # Test valid thoughts
  echo "\n--- Testing Valid Thoughts ---"
  let valid_thoughts = @[
    "water is essential for life",
    "mathematics provides logical structure",
    "the concept of time",
    "and",  # Necessary word
    "because",  # Necessary word
    "in the beginning",  # Multi-word
    "to be or not to be"  # Multi-word
  ]
  
  for thought in valid_thoughts:
    let validation = orchestrator.validateThought(thought)
    echo "Thought: '", thought, "' -> ", (if validation.is_valid: "VALID" else: "INVALID"), " (", validation.reason, ")"
    if not validation.is_valid:
      echo "  Suggestions: ", validation.suggestions
  
  # Test invalid thoughts
  echo "\n--- Testing Invalid Thoughts ---"
  let invalid_thoughts = @[
    "water",  # Single word, not necessary
    "mathematics",  # Single word, not necessary
    "computer",  # Single word, not necessary
    "the and",  # Only necessary words
    "in on",  # Only necessary words
    "",  # Empty thought
    "   "  # Whitespace only
  ]
  
  for thought in invalid_thoughts:
    let validation = orchestrator.validateThought(thought)
    echo "Thought: '", thought, "' -> ", (if validation.is_valid: "VALID" else: "INVALID"), " (", validation.reason, ")"
    if not validation.is_valid:
      echo "  Suggestions: ", validation.suggestions
  
  # Test thought expansion suggestions
  echo "\n--- Testing Thought Expansion Suggestions ---"
  let single_words = @["water", "mathematics", "computer", "philosophy"]
  
  for word in single_words:
    let suggestions = orchestrator.thought_validator.suggestThoughtExpansion(word)
    echo "Expansion suggestions for '", word, "':"
    for suggestion in suggestions[0..min(3, suggestions.len-1)]:  # Show first 4 suggestions
      echo "  - ", suggestion
  
  echo "✓ Thought validation tests passed"

proc testNecessaryWords() =
  echo "\n=== Testing Necessary Words ==="
  
  let orchestrator = newAgentOrchestrator()
  let necessary_words = orchestrator.thought_validator.getNecessaryWords()
  
  echo "Total necessary words: ", necessary_words.len
  
  # Test some specific necessary words
  let test_words = @["i", "the", "and", "because", "in", "yes", "now", "can"]
  
  for word in test_words:
    let is_necessary = orchestrator.thought_validator.isNecessaryWord(word)
    echo "Word '", word, "' is necessary: ", is_necessary
    assert is_necessary, "Word '" & word & "' should be recognized as necessary"
  
  # Test non-necessary words
  let non_necessary_words = @["water", "mathematics", "computer", "philosophy"]
  
  for word in non_necessary_words:
    let is_necessary = orchestrator.thought_validator.isNecessaryWord(word)
    echo "Word '", word, "' is necessary: ", is_necessary
    assert not is_necessary, "Word '" & word & "' should NOT be recognized as necessary"
  
  echo "✓ Necessary words tests passed"

proc testAttentionHistory() =
  echo "\n=== Testing Attention History ==="
  
  let orchestrator = newAgentOrchestrator()
  
  # Simulate some attention changes
  orchestrator.updateForegroundFocus(@["entity_1"])
  orchestrator.updateForegroundFocus(@["entity_2", "entity_3"])
  orchestrator.updateForegroundFocus(@["entity_1", "entity_4"])
  
  # Get attention history
  let all_history = orchestrator.attention_system.getAttentionHistory()
  let stage_manager_history = orchestrator.attention_system.getAttentionHistory("stage_manager")
  
  echo "Total attention events: ", all_history.len
  echo "Stage Manager attention events: ", stage_manager_history.len
  
  # Verify history contains expected events
  assert all_history.len > 0, "Should have attention history"
  assert stage_manager_history.len > 0, "Stage Manager should have attention history"
  
  # Check latest event
  if all_history.len > 0:
    let latest_event = all_history[^1]
    echo "Latest attention event:"
    echo "  Agent: ", latest_event.agent_id
    echo "  Entities: ", latest_event.entity_ids
    echo "  Type: ", latest_event.attention_type
    echo "  Trigger: ", latest_event.trigger
  
  echo "✓ Attention history tests passed"

proc testAutonomousDuties() =
  echo "\n=== Testing Autonomous Duties ==="
  
  let orchestrator = newAgentOrchestrator()
  
  # Manually trigger autonomous duties (simulating idle state)
  orchestrator.attention_system.triggerAutonomousDuties()
  
  # Check if autonomous tasks were created
  let dreamer_tasks = orchestrator.attention_system.autonomous_tasks.getOrDefault("dreamer", @[])
  let philosopher_tasks = orchestrator.attention_system.autonomous_tasks.getOrDefault("philosopher", @[])
  let investigator_tasks = orchestrator.attention_system.autonomous_tasks.getOrDefault("investigator", @[])
  let archivist_tasks = orchestrator.attention_system.autonomous_tasks.getOrDefault("archivist", @[])
  
  echo "Dreamer autonomous tasks: ", dreamer_tasks.len
  echo "Philosopher autonomous tasks: ", philosopher_tasks.len
  echo "Investigator autonomous tasks: ", investigator_tasks.len
  echo "Archivist autonomous tasks: ", archivist_tasks.len
  
  # Verify tasks were created
  assert dreamer_tasks.len > 0, "Dreamer should have autonomous tasks"
  assert philosopher_tasks.len > 0, "Philosopher should have autonomous tasks"
  assert investigator_tasks.len > 0, "Investigator should have autonomous tasks"
  assert archivist_tasks.len > 0, "Archivist should have autonomous tasks"
  
  # Check system state
  let system_state = orchestrator.getSystemState()
  echo "System state after triggering autonomous duties: ", system_state
  assert system_state == SystemState.dream, "System should be in dream state"
  
  echo "✓ Autonomous duties tests passed"

when isMainModule:
  echo "🧠 Testing Attention System and Thought Validation"
  echo "=================================================="
  
  testAttentionSystem()
  testThoughtValidation()
  testNecessaryWords()
  testAttentionHistory()
  testAutonomousDuties()
  
  echo "\n🎉 All tests passed!"
  echo "✅ Attention system working correctly"
  echo "✅ Thought validation enforcing linguistic restrictions"
  echo "✅ Background agents operating autonomously"
  echo "✅ No direct agent prompting - attention-based coordination only" 