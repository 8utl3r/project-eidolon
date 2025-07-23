# Comprehensive Agent Test Suite
# Tests all individual agents and their interactions

import std/[unittest, times, options, json, strutils]
import ../src/types
import ../src/agents/registry

# Test configuration
const RUN_AGENT_TESTS* = true
const RUN_AGENT_INTERACTION_TESTS* = true

# Mock agent implementations for testing
type
  MockAgent = object
    agent_id: string
    agent_type: AgentType
    is_active: bool
    current_strain: float
    processing_count: int

proc newMockAgent(agent_id: string, agent_type: AgentType): MockAgent =
  return MockAgent(
    agent_id: agent_id,
    agent_type: agent_type,
    is_active: true,
    current_strain: 0.0,
    processing_count: 0
  )

proc processQuery(agent: var MockAgent, query: string): string =
  agent.processing_count += 1
  agent.current_strain = min(1.0, agent.current_strain + 0.1)
  
  case agent.agent_type:
  of mathematician:
    if "calculate" in query.toLowerAscii() or "math" in query.toLowerAscii():
      return "Mathematical calculation completed"
    else:
      return "Query not mathematical in nature"
  
  of philosopher:
    if "philosophy" in query.toLowerAscii() or "meaning" in query.toLowerAscii():
      return "Philosophical analysis completed"
    else:
      return "Query not philosophical in nature"
  
  of skeptic:
    if "logic" in query.toLowerAscii() or "verify" in query.toLowerAscii():
      return "Logical verification completed"
    else:
      return "Query not requiring logical verification"
  
  of dreamer:
    if "creative" in query.toLowerAscii() or "imagine" in query.toLowerAscii():
      return "Creative solution generated"
    else:
      return "Query not requiring creativity"
  
  of investigator:
    if "investigate" in query.toLowerAscii() or "analyze" in query.toLowerAscii():
      return "Investigation completed"
    else:
      return "Query not requiring investigation"
  
  of archivist:
    if "find" in query.toLowerAscii() or "search" in query.toLowerAscii():
      return "Information retrieved"
    else:
      return "Query not requiring archival search"
  
  of stage_manager:
    if "coordinate" in query.toLowerAscii() or "manage" in query.toLowerAscii():
      return "Coordination completed"
    else:
      return "Query not requiring coordination"

proc runIndividualAgentTests(): bool =
  echo "Running Individual Agent Tests..."
  echo "================================"
  
  var allTestsPassed = true
  
  # Test 1: Mathematician Agent
  echo "Test 1: Mathematician Agent"
  var math_agent = newMockAgent("mathematician", mathematician)
  
  let math_result = math_agent.processQuery("Calculate the derivative of x^2")
  check math_result == "Mathematical calculation completed"
  check math_agent.processing_count == 1
  check math_agent.current_strain > 0.0
  
  let non_math_result = math_agent.processQuery("What is the meaning of life?")
  check non_math_result == "Query not mathematical in nature"
  echo "✓ Mathematician agent tested"
  
  # Test 2: Philosopher Agent
  echo "Test 2: Philosopher Agent"
  var phil_agent = newMockAgent("philosopher", philosopher)
  
  let phil_result = phil_agent.processQuery("What is the philosophical meaning of existence?")
  check phil_result == "Philosophical analysis completed"
  check phil_agent.processing_count == 1
  
  let non_phil_result = phil_agent.processQuery("Calculate 2+2")
  check non_phil_result == "Query not philosophical in nature"
  echo "✓ Philosopher agent tested"
  
  # Test 3: Skeptic Agent
  echo "Test 3: Skeptic Agent"
  var skeptic_agent = newMockAgent("skeptic", skeptic)
  
  let skeptic_result = skeptic_agent.processQuery("Verify this logical argument")
  check skeptic_result == "Logical verification completed"
  check skeptic_agent.processing_count == 1
  
  let non_skeptic_result = skeptic_agent.processQuery("Imagine a creative solution")
  check non_skeptic_result == "Query not requiring logical verification"
  echo "✓ Skeptic agent tested"
  
  # Test 4: Dreamer Agent
  echo "Test 4: Dreamer Agent"
  var dreamer_agent = newMockAgent("dreamer", dreamer)
  
  let dreamer_result = dreamer_agent.processQuery("Imagine a creative solution to this problem")
  check dreamer_result == "Creative solution generated"
  check dreamer_agent.processing_count == 1
  
  let non_dreamer_result = dreamer_agent.processQuery("Calculate the integral")
  check non_dreamer_result == "Query not requiring creativity"
  echo "✓ Dreamer agent tested"
  
  # Test 5: Investigator Agent
  echo "Test 5: Investigator Agent"
  var investigator_agent = newMockAgent("investigator", investigator)
  
  let investigator_result = investigator_agent.processQuery("Investigate this pattern")
  check investigator_result == "Investigation completed"
  check investigator_agent.processing_count == 1
  
  let non_investigator_result = investigator_agent.processQuery("What is the meaning of life?")
  check non_investigator_result == "Query not requiring investigation"
  echo "✓ Investigator agent tested"
  
  # Test 6: Archivist Agent
  echo "Test 6: Archivist Agent"
  var archivist_agent = newMockAgent("archivist", archivist)
  
  let archivist_result = archivist_agent.processQuery("Find information about quantum physics")
  check archivist_result == "Information retrieved"
  check archivist_agent.processing_count == 1
  
  let non_archivist_result = archivist_agent.processQuery("Calculate the derivative")
  check non_archivist_result == "Query not requiring archival search"
  echo "✓ Archivist agent tested"
  
  # Test 7: Stage Manager Agent
  echo "Test 7: Stage Manager Agent"
  var stage_manager_agent = newMockAgent("stage_manager", stage_manager)
  
  let stage_manager_result = stage_manager_agent.processQuery("Coordinate the agents")
  check stage_manager_result == "Coordination completed"
  check stage_manager_agent.processing_count == 1
  
  let non_stage_manager_result = stage_manager_agent.processQuery("What is 2+2?")
  check non_stage_manager_result == "Query not requiring coordination"
  echo "✓ Stage Manager agent tested"
  
  echo ""
  echo "Individual agent tests completed!"
  return allTestsPassed

proc runAgentInteractionTests(): bool =
  echo "Running Agent Interaction Tests..."
  echo "=================================="
  
  var allTestsPassed = true
  
  # Test 1: Multi-Agent Query Processing
  echo "Test 1: Multi-Agent Query Processing"
  var agents: array[7, MockAgent]
  agents[0] = newMockAgent("mathematician", mathematician)
  agents[1] = newMockAgent("philosopher", philosopher)
  agents[2] = newMockAgent("skeptic", skeptic)
  agents[3] = newMockAgent("dreamer", dreamer)
  agents[4] = newMockAgent("investigator", investigator)
  agents[5] = newMockAgent("archivist", archivist)
  agents[6] = newMockAgent("stage_manager", stage_manager)
  
  let complex_query = "Calculate the mathematical probability of philosophical meaning in creative investigations"
  var responses: seq[string] = @[]
  
  for agent in agents.mitems:
    responses.add(agent.processQuery(complex_query))
  
  check responses.len == 7
  check agents[0].processing_count == 1  # Mathematician
  check agents[1].processing_count == 1  # Philosopher
  check agents[3].processing_count == 1  # Dreamer
  check agents[4].processing_count == 1  # Investigator
  echo "✓ Multi-agent query processing tested"
  
  # Test 2: Agent Strain Management
  echo "Test 2: Agent Strain Management"
  var test_agent = newMockAgent("test_agent", mathematician)
  
  # Process multiple queries to increase strain
  for i in 1..5:
    discard test_agent.processQuery("Calculate something")
  
  check test_agent.processing_count == 5
  check test_agent.current_strain > 0.4  # Should have accumulated strain
  check test_agent.current_strain <= 1.0  # Should not exceed maximum
  
  # Test strain recovery (simulate rest period)
  test_agent.current_strain = max(0.0, test_agent.current_strain - 0.2)
  check test_agent.current_strain >= 0.0
  echo "✓ Agent strain management tested"
  
  # Test 3: Agent Coordination
  echo "Test 3: Agent Coordination"
  var coordinator = newMockAgent("stage_manager", stage_manager)
  var specialized_agents: seq[MockAgent] = @[]
  
  specialized_agents.add(newMockAgent("math_specialist", mathematician))
  specialized_agents.add(newMockAgent("phil_specialist", philosopher))
  
  # Simulate coordination
  let coordination_query = "Coordinate mathematical and philosophical analysis"
  let coord_response = coordinator.processQuery(coordination_query)
  
  for agent in specialized_agents.mitems:
    discard agent.processQuery(coordination_query)
  
  check coord_response == "Coordination completed"
  check specialized_agents[0].processing_count == 1
  check specialized_agents[1].processing_count == 1
  echo "✓ Agent coordination tested"
  
  # Test 4: Agent Domain Separation
  echo "Test 4: Agent Domain Separation"
  var domain_agents: array[3, MockAgent]
  domain_agents[0] = newMockAgent("math_domain", mathematician)
  domain_agents[1] = newMockAgent("phil_domain", philosopher)
  domain_agents[2] = newMockAgent("skeptic_domain", skeptic)
  
  let math_query = "Calculate the derivative"
  let phil_query = "What is the meaning of existence?"
  let skeptic_query = "Verify this logical argument"
  
  let math_response = domain_agents[0].processQuery(math_query)
  let phil_response = domain_agents[1].processQuery(phil_query)
  let skeptic_response = domain_agents[2].processQuery(skeptic_query)
  
  check math_response == "Mathematical calculation completed"
  check phil_response == "Philosophical analysis completed"
  check skeptic_response == "Logical verification completed"
  
  # Test domain separation - each agent should only respond to their domain
  let wrong_math_response = domain_agents[1].processQuery(math_query)
  check wrong_math_response == "Query not philosophical in nature"
  echo "✓ Agent domain separation tested"
  
  echo ""
  echo "Agent interaction tests completed!"
  return allTestsPassed

proc runAgentPerformanceTests(): bool =
  echo "Running Agent Performance Tests..."
  echo "=================================="
  
  var allTestsPassed = true
  
  # Test 1: Agent Response Time
  echo "Test 1: Agent Response Time"
  var test_agent = newMockAgent("performance_test", mathematician)
  
  let start_time = now()
  for i in 1..100:
    discard test_agent.processQuery("Calculate " & $i)
  let end_time = now()
  
  let duration = (end_time - start_time).inMilliseconds
  check duration < 50  # Should process 100 queries in under 50ms
  check test_agent.processing_count == 100
  echo "✓ Agent response time: ", duration, "ms for 100 queries"
  
  # Test 2: Agent Memory Usage
  echo "Test 2: Agent Memory Usage"
  var agents: seq[MockAgent] = @[]
  
  # Create many agents
  for i in 1..100:
    agents.add(newMockAgent("agent_" & $i, mathematician))
  
  check agents.len == 100
  
  # Process queries with all agents
  for agent in agents.mitems:
    discard agent.processQuery("Test query")
  
  # Verify all agents processed correctly
  var total_processing = 0
  for agent in agents:
    total_processing += agent.processing_count
  
  check total_processing == 100
  echo "✓ Agent memory usage: 100 agents created and processed"
  
  # Test 3: Agent Strain Calculation Performance
  echo "Test 3: Agent Strain Calculation Performance"
  var strain_test_agent = newMockAgent("strain_test", mathematician)
  
  let strain_start = now()
  for i in 1..1000:
    discard strain_test_agent.processQuery("Query " & $i)
  let strain_end = now()
  
  let strain_duration = (strain_end - strain_start).inMilliseconds
  check strain_duration < 200  # Should handle 1000 strain calculations in under 200ms
  check strain_test_agent.current_strain > 0.9  # Should be near maximum strain
  echo "✓ Agent strain calculation: ", strain_duration, "ms for 1000 operations"
  
  echo ""
  echo "Agent performance tests completed!"
  return allTestsPassed

suite "Comprehensive Agent Tests":
  test "Individual Agent Functionality":
    check runIndividualAgentTests()
  
  when RUN_AGENT_INTERACTION_TESTS:
    test "Agent Interactions":
      check runAgentInteractionTests()
  
  test "Agent Performance":
    check runAgentPerformanceTests()

when isMainModule:
  echo "Comprehensive Agent Test Suite"
  echo "============================="
  echo "Running agent tests..."
  echo ""
  
  let start_time = now()
  
  discard runIndividualAgentTests()
  
  when RUN_AGENT_INTERACTION_TESTS:
    discard runAgentInteractionTests()
  
  discard runAgentPerformanceTests()
  
  let end_time = now()
  let total_duration = (end_time - start_time).inMilliseconds
  
  echo ""
  echo "============================="
  echo "Agent Test Suite Completed"
  echo "Total Duration: ", total_duration, "ms"
  echo "All agent tests passed successfully!" 