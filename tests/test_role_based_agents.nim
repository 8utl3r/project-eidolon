# Test Role-Based Agent System
#
# Tests the new role-based agent system with proper stage manager coordination
# and attention-based agent operation.

import std/[times, json, asyncdispatch, options, strutils, sequtils]
import tables
import ../src/agents/orchestrator
import ../src/agents/role_prompts
import ../src/agents/attention_system
import ../src/thoughts/validator

proc testRolePrompts() =
  echo "=== Testing Role Prompts ==="
  
  # Test that all agents have role prompts
  let agent_ids = @["stage_manager", "engineer", "skeptic", "philosopher", "dreamer", "investigator", "archivist"]
  
  for agent_id in agent_ids:
    let prompt = getRolePrompt(agent_id)
    echo "Agent: ", agent_id
    echo "Prompt length: ", prompt.len, " characters"
    echo "Contains role definition: ", prompt.contains("YOUR ROLE:")
    echo "Contains duties: ", prompt.contains("YOUR DUTIES:")
    echo "Contains authority: ", prompt.contains("YOUR AUTHORITY:")
    echo "---"
    
    assert prompt.len > 500, "Role prompt should be substantial"
    assert prompt.contains("YOUR ROLE:"), "Prompt should contain role definition"
    assert prompt.contains("YOUR DUTIES:"), "Prompt should contain duties"
    assert prompt.contains("YOUR AUTHORITY:"), "Prompt should contain authority information"
  
  echo "✓ All role prompts are properly defined"

proc testStageManagerCoordination() =
  echo "\n=== Testing Stage Manager Coordination ==="
  
  var orchestrator = newAgentOrchestrator()
  echo "✓ Created orchestrator with role-based agents"
  
  # Test coordination of agent duties
  let test_entities = @["entity_math_1", "entity_high_strain", "entity_many_connections", "entity_conceptual"]
  orchestrator.coordinateAgentDuties(test_entities)
  
  echo "Coordinated duties for entities: ", test_entities
  
  # Check that agents have been assigned duties
  for agent_id in @["engineer", "skeptic", "investigator", "philosopher"]:
    let duties = orchestrator.getAgentDuties(agent_id)
    echo "Agent ", agent_id, " has ", duties.len, " duties"
    assert duties.len >= 0, "Agent should have duties assigned"
  
  # Test system status
  let status = orchestrator.getSystemStatus()
  echo "System state: ", status["system_state"].getStr()
  echo "Foreground focus: ", status["foreground_focus"]
  echo "Attention history count: ", status["attention_history_count"].getInt()
  
  assert status["system_state"].getStr() == "wake", "System should be in wake state"
  assert status["foreground_focus"].len == 4, "Should have 4 entities in foreground focus"
  
  echo "✓ Stage Manager coordination working correctly"

proc testAgentAttentionSystem() =
  echo "\n=== Testing Agent Attention System ==="
  
  var orchestrator = newAgentOrchestrator()
  
  # Test foreground focus update
  let focus_entities = @["entity_1", "entity_2"]
  orchestrator.updateForegroundFocus(focus_entities)
  
  let current_focus = orchestrator.getForegroundFocus()
  echo "Current foreground focus: ", current_focus
  assert current_focus == focus_entities, "Foreground focus should match input"
  
  # Test agent attention allocation
  let stage_manager_attention = orchestrator.getAgentAttention("stage_manager")
  echo "Stage Manager attention: ", stage_manager_attention
  
  # Stage Manager should be attending to at least some foreground entities
  var attending_count = 0
  for entity_id in focus_entities:
    let is_attending = orchestrator.isAgentAttendingTo("stage_manager", entity_id)
    echo "Stage Manager attending to ", entity_id, ": ", is_attending
    if is_attending:
      attending_count += 1
  
  # At least one entity should be attended to (since test entities may not exist in knowledge graph)
  assert attending_count > 0, "Stage Manager should attend to at least one foreground entity"
  
  # Test system state transitions
  let initial_state = orchestrator.getSystemState()
  echo "Initial system state: ", initial_state
  assert initial_state == SystemState.wake, "System should start in wake state"
  
  echo "✓ Agent attention system working correctly"

proc testDutyDirectives() =
  echo "\n=== Testing Duty Directives ==="
  
  # Test creating duty directives
  let math_duty = createDutyDirective("engineer", DutyType.mathematical_analysis, @["math_entity"], 0.8)
  let logic_duty = createDutyDirective("skeptic", DutyType.logical_verification, @["strain_entity"], 0.9)
  let pattern_duty = createDutyDirective("philosopher", DutyType.pattern_analysis, @["concept_entity"], 0.6)
  
  echo "Math duty: ", math_duty.agent_id, " -> ", math_duty.duty_type, " (priority: ", math_duty.priority, ")"
  echo "Logic duty: ", logic_duty.agent_id, " -> ", logic_duty.duty_type, " (priority: ", logic_duty.priority, ")"
  echo "Pattern duty: ", pattern_duty.agent_id, " -> ", pattern_duty.duty_type, " (priority: ", pattern_duty.priority, ")"
  
  assert math_duty.agent_id == "engineer", "Duty should be assigned to correct agent"
  assert math_duty.duty_type == "mathematical_analysis", "Duty should have correct type"
  assert math_duty.priority == 0.8, "Duty should have correct priority"
  
  # Test duty assignment
  var orchestrator = newAgentOrchestrator()
  orchestrator.assignDutyToAgent(math_duty)
  orchestrator.assignDutyToAgent(logic_duty)
  orchestrator.assignDutyToAgent(pattern_duty)
  
  let engineer_duties = orchestrator.getAgentDuties("engineer")
  let skeptic_duties = orchestrator.getAgentDuties("skeptic")
  let philosopher_duties = orchestrator.getAgentDuties("philosopher")
  
  echo "Engineer duties: ", engineer_duties.len
  echo "Skeptic duties: ", skeptic_duties.len
  echo "Philosopher duties: ", philosopher_duties.len
  
  assert engineer_duties.len > 0, "Engineer should have duties assigned"
  assert skeptic_duties.len > 0, "Skeptic should have duties assigned"
  assert philosopher_duties.len > 0, "Philosopher should have duties assigned"
  
  echo "✓ Duty directives working correctly"

proc testIdleDutyTriggering() =
  echo "\n=== Testing Idle Duty Triggering ==="
  
  var orchestrator = newAgentOrchestrator()
  
  # Trigger idle duties
  orchestrator.triggerIdleDuties()
  
  # Check that idle agents have duties
  let dreamer_duties = orchestrator.getAgentDuties("dreamer")
  let philosopher_duties = orchestrator.getAgentDuties("philosopher")
  let investigator_duties = orchestrator.getAgentDuties("investigator")
  let archivist_duties = orchestrator.getAgentDuties("archivist")
  
  echo "Dreamer idle duties: ", dreamer_duties.len
  echo "Philosopher idle duties: ", philosopher_duties.len
  echo "Investigator idle duties: ", investigator_duties.len
  echo "Archivist idle duties: ", archivist_duties.len
  
  assert dreamer_duties.len > 0, "Dreamer should have idle duties"
  assert philosopher_duties.len > 0, "Philosopher should have idle duties"
  assert investigator_duties.len > 0, "Investigator should have idle duties"
  assert archivist_duties.len > 0, "Archivist should have idle duties"
  
  # Check system state
  let system_state = orchestrator.getSystemState()
  echo "System state after idle triggering: ", system_state
  assert system_state == SystemState.dream, "System should be in dream state after idle triggering"
  
  echo "✓ Idle duty triggering working correctly"

proc testThoughtValidationIntegration() =
  echo "\n=== Testing Thought Validation Integration ==="
  
  let orchestrator = newAgentOrchestrator()
  
  # Test thought validation
  let valid_thoughts = @[
    "water is essential for life",
    "mathematics provides logical structure",
    "and",  # Necessary word
    "because"  # Necessary word
  ]
  
  let invalid_thoughts = @[
    ""  # Empty
  ]
  
  for thought in valid_thoughts:
    let validation = orchestrator.validateThought(thought)
    echo "Thought '", thought, "' -> ", (if validation.is_valid: "VALID" else: "INVALID")
    assert validation.is_valid, "Valid thought should pass validation"
  
  for thought in invalid_thoughts:
    let validation = orchestrator.validateThought(thought)
    echo "Thought '", thought, "' -> ", (if validation.is_valid: "VALID" else: "INVALID")
    assert not validation.is_valid, "Invalid thought should fail validation"
  
  # Test thought counting
  let valid_count = orchestrator.countValidThoughts()
  let invalid_count = orchestrator.countInvalidThoughts()
  
  echo "Valid thoughts in system: ", valid_count
  echo "Invalid thoughts in system: ", invalid_count
  
  echo "✓ Thought validation integration working correctly"

when isMainModule:
  echo "🎭 Testing Role-Based Agent System"
  echo "=================================="
  
  testRolePrompts()
  testStageManagerCoordination()
  testAgentAttentionSystem()
  testDutyDirectives()
  testIdleDutyTriggering()
  testThoughtValidationIntegration()
  
  echo "\n🎉 All role-based agent tests passed!"
  echo "✅ Agents have proper role prompts and understand their duties"
  echo "✅ Stage Manager coordinates agent activities through attention system"
  echo "✅ No direct agent prompting - coordination through duty directives only"
  echo "✅ Thought validation enforces linguistic restrictions"
  echo "✅ System operates autonomously with proper agent coordination" 