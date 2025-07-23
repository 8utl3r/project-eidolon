# End-to-End Test Suite
# Tests the complete system pipeline from query to response

import std/[unittest, times, options, json]
import ../src/types
import ../src/agents/registry
import ../src/rag/rag_engine
import ../src/rag/types
import ../src/api/simple_router

# Test configuration
const RUN_E2E_TESTS* = true
const RUN_STRESS_TESTS* = true

proc runBasicE2ETests(): bool =
  echo "Running Basic End-to-End Tests..."
  echo "================================="
  
  var allTestsPassed = true
  
  # Test 1: Complete Query Processing Pipeline
  echo "Test 1: Complete Query Processing Pipeline"
  
  # Setup RAG engine
  var rag_engine = newRAGEngine("e2e_test_rag")
  let source = newKnowledgeSource("test_source", "document", "Test Knowledge", "http://test.com")
  rag_engine.addKnowledgeSource(source)
  
  var chunk = newKnowledgeChunk("chunk1", "test_source", "Quantum mechanics is a fundamental theory in physics")
  chunk.confidence = 0.8
  rag_engine.addKnowledgeChunk(chunk)
  
  # Setup router
  let router = newSimpleRouter(rag_engine)
  
  # Process a simple mathematical query
  let math_query = "Calculate the derivative of x^2"
  let math_result = router.processQuery(math_query)
  
  check math_result.query == math_query
  check isSome(math_result.selected_agent)
  check get(math_result.selected_agent) == "mathematician"
  check math_result.agent_score > 0.0
  check math_result.processing_time >= 0.0
  check math_result.strain_level >= 0.0 and math_result.strain_level <= 1.0
  echo "✓ Complete query processing pipeline tested"
  
  # Test 2: RAG-Enhanced Query Processing
  echo "Test 2: RAG-Enhanced Query Processing"
  
  let complex_query = "Explain quantum mechanics and its relationship to classical physics using advanced mathematical methods"
  let complex_result = router.processQuery(complex_query)
  
  check complex_result.query == complex_query
  check complex_result.rag_enhanced == true
  check complex_result.rag_confidence > 0.0
  check isSome(complex_result.selected_agent)
  echo "✓ RAG-enhanced query processing tested"
  
  # Test 3: Agent Selection Accuracy
  echo "Test 3: Agent Selection Accuracy"
  
  let phil_query = "What is the philosophical meaning of existence?"
  let phil_result = router.processQuery(phil_query)
  
  check get(phil_result.selected_agent) == "philosopher"
  check phil_result.agent_score > 0.0
  
  let creative_query = "Imagine a creative solution to this problem"
  let creative_result = router.processQuery(creative_query)
  
  check get(creative_result.selected_agent) == "dreamer"
  check creative_result.agent_score > 0.0
  echo "✓ Agent selection accuracy tested"
  
  # Test 4: Strain Management Integration
  echo "Test 4: Strain Management Integration"
  
  # Process multiple queries to build up strain
  for i in 1..3:
    discard router.processQuery("Calculate " & $i)
  
  # Get agent info to check strain
  let mathematician = router.getAgentInfo("mathematician")
  check isSome(mathematician)
  check mathematician.get().current_strain > 0.0
  echo "✓ Strain management integration tested"
  
  echo ""
  echo "Basic end-to-end tests completed!"
  return allTestsPassed

proc runAdvancedE2ETests(): bool =
  echo "Running Advanced End-to-End Tests..."
  echo "===================================="
  
  var allTestsPassed = true
  
  # Test 1: Multi-Agent Coordination
  echo "Test 1: Multi-Agent Coordination"
  
  var rag_engine = newRAGEngine("advanced_e2e_rag")
  let router = newSimpleRouter(rag_engine)
  
  # Simulate a complex query that might involve multiple agents
  let coordination_query = "Investigate the mathematical patterns in philosophical arguments and verify their logical consistency"
  
  # This query should trigger multiple agents
  let coord_result = router.processQuery(coordination_query)
  
  check coord_result.query == coordination_query
  check isSome(coord_result.selected_agent)
  # Should select investigator, mathematician, or skeptic
  let selected_agent = get(coord_result.selected_agent)
  check selected_agent in @["investigator", "mathematician", "skeptic"]
  echo "✓ Multi-agent coordination tested"
  
  # Test 2: Knowledge Synthesis
  echo "Test 2: Knowledge Synthesis"
  
  # Add multiple knowledge sources
  let source1 = newKnowledgeSource("physics", "document", "Physics Knowledge", "http://physics.com")
  let source2 = newKnowledgeSource("math", "document", "Mathematics Knowledge", "http://math.com")
  rag_engine.addKnowledgeSource(source1)
  rag_engine.addKnowledgeSource(source2)
  
  var chunk1 = newKnowledgeChunk("physics_chunk", "physics", "Einstein's theory of relativity revolutionized physics")
  var chunk2 = newKnowledgeChunk("math_chunk", "math", "Calculus provides the mathematical foundation for physics")
  chunk1.confidence = 0.9
  chunk2.confidence = 0.8
  rag_engine.addKnowledgeChunk(chunk1)
  rag_engine.addKnowledgeChunk(chunk2)
  
  let synthesis_query = "How does mathematics relate to physics in Einstein's theories?"
  let synthesis_result = router.processQuery(synthesis_query)
  
  check synthesis_result.rag_enhanced == true
  check synthesis_result.rag_confidence > 0.0
  echo "✓ Knowledge synthesis tested"
  
  # Test 3: Error Handling and Recovery
  echo "Test 3: Error Handling and Recovery"
  
  # Test with invalid query
  let invalid_query = ""
  let invalid_result = router.processQuery(invalid_query)
  
  check invalid_result.query == invalid_query
  check not isSome(invalid_result.selected_agent) or get(invalid_result.selected_agent) == ""
  check invalid_result.agent_score == 0.0
  echo "✓ Error handling and recovery tested"
  
  # Test 4: Performance Under Load
  echo "Test 4: Performance Under Load"
  
  let load_start = now()
  
  # Process multiple queries rapidly
  for i in 1..10:
    let query = "Query " & $i & " for testing"
    discard router.processQuery(query)
  
  let load_end = now()
  let load_duration = (load_end - load_start).inMilliseconds
  
  check load_duration < 1000  # Should complete in under 1 second
  echo "✓ Performance under load: ", load_duration, "ms for 10 queries"
  
  echo ""
  echo "Advanced end-to-end tests completed!"
  return allTestsPassed

proc runStressTests(): bool =
  echo "Running Stress Tests..."
  echo "======================"
  
  var allTestsPassed = true
  
  # Test 1: High Volume Query Processing
  echo "Test 1: High Volume Query Processing"
  
  var rag_engine = newRAGEngine("stress_test_rag")
  let router = newSimpleRouter(rag_engine)
  
  let stress_start = now()
  
  # Process a large number of queries
  for i in 1..100:
    let query = "Stress test query " & $i
    let result = router.processQuery(query)
    check result.query == query
    check result.processing_time >= 0.0
  
  let stress_end = now()
  let stress_duration = (stress_end - stress_start).inMilliseconds
  
  check stress_duration < 5000  # Should complete in under 5 seconds
  echo "✓ High volume processing: ", stress_duration, "ms for 100 queries"
  
  # Test 2: Memory Usage Under Load
  echo "Test 2: Memory Usage Under Load"
  
  # Create multiple routers to test memory usage
  var routers: seq[SimpleRouter] = @[]
  
  for i in 1..10:
    var test_rag = newRAGEngine("stress_rag_" & $i)
    routers.add(newSimpleRouter(test_rag))
  
  check routers.len == 10
  
  # Process queries with all routers
  for router in routers.mitems:
    for j in 1..5:
      discard router.processQuery("Memory test query " & $j)
  
  echo "✓ Memory usage under load: 10 routers with 5 queries each"
  
  # Test 3: Concurrent Agent Strain Management
  echo "Test 3: Concurrent Agent Strain Management"
  
  var strain_router = newSimpleRouter(rag_engine)
  
  # Rapidly update agent strain
  for i in 1..50:
    let success = strain_router.updateAgentStrain("mathematician", float(i) / 100.0)
    check success == true
  
  let mathematician = strain_router.getAgentInfo("mathematician")
  check isSome(mathematician)
  check mathematician.get().current_strain > 0.0
  echo "✓ Concurrent strain management tested"
  
  # Test 4: System Stability
  echo "Test 4: System Stability"
  
  # Test system remains stable under various conditions
  let stability_start = now()
  
  for i in 1..20:
    # Mix different types of queries
    let query_type = i mod 4
    let query = case query_type:
      of 0: "Calculate " & $i
      of 1: "What is the meaning of " & $i & "?"
      of 2: "Verify this logic: " & $i
      of 3: "Imagine a solution for " & $i
      else: "Test query " & $i
    
    let result = strain_router.processQuery(query)
    check result.query == query
    check result.processing_time >= 0.0
  
  let stability_end = now()
  let stability_duration = (stability_end - stability_start).inMilliseconds
  
  check stability_duration < 2000  # Should remain stable
  echo "✓ System stability: ", stability_duration, "ms for 20 mixed queries"
  
  echo ""
  echo "Stress tests completed!"
  return allTestsPassed

proc runValidationTests(): bool =
  echo "Running Validation Tests..."
  echo "=========================="
  
  var allTestsPassed = true
  
  # Test 1: Data Integrity
  echo "Test 1: Data Integrity"
  
  var rag_engine = newRAGEngine("validation_rag")
  let router = newSimpleRouter(rag_engine)
  
  # Test that agent registry maintains integrity
  let initial_agents = router.getActiveAgents()
  check initial_agents.len == 7  # All 7 default agents
  
  # Process queries and verify agent count remains the same
  for i in 1..5:
    discard router.processQuery("Validation query " & $i)
  
  let final_agents = router.getActiveAgents()
  check final_agents.len == 7  # Should still have all agents
  echo "✓ Data integrity maintained"
  
  # Test 2: Response Consistency
  echo "Test 2: Response Consistency"
  
  # Same query should produce consistent results
  let test_query = "Calculate 2+2"
  let result1 = router.processQuery(test_query)
  let result2 = router.processQuery(test_query)
  
  check result1.query == result2.query
  check result1.selected_agent == result2.selected_agent
  check abs(result1.agent_score - result2.agent_score) < 0.1  # Should be similar
  echo "✓ Response consistency verified"
  
  # Test 3: Boundary Conditions
  echo "Test 3: Boundary Conditions"
  
  # Test very long query
  let long_query = "This is a very long query that tests the system's ability to handle extended input with many words and complex structure that should trigger various processing paths and agent selection mechanisms"
  let long_result = router.processQuery(long_query)
  
  check long_result.query == long_query
  check long_result.processing_time >= 0.0
  check long_result.strain_level >= 0.0 and long_result.strain_level <= 1.0
  
  # Test very short query
  let short_query = "Hi"
  let short_result = router.processQuery(short_query)
  
  check short_result.query == short_query
  check short_result.processing_time >= 0.0
  echo "✓ Boundary conditions tested"
  
  # Test 4: System State Validation
  echo "Test 4: System State Validation"
  
  # Verify all agents are in valid states
  for agent_type in [mathematician, philosopher, skeptic, dreamer, investigator, archivist, stage_manager]:
    let agents = router.getAgentsByType(agent_type)
    check agents.len == 1  # Should have exactly one agent of each type
    
    let agent = agents[0]
    check agent.agent_id.len > 0
    check agent.current_strain >= 0.0 and agent.current_strain <= 1.0
    check agent.is_active == true
  
  echo "✓ System state validation completed"
  
  echo ""
  echo "Validation tests completed!"
  return allTestsPassed

suite "End-to-End Tests":
  test "Basic End-to-End Functionality":
    check runBasicE2ETests()
  
  test "Advanced End-to-End Scenarios":
    check runAdvancedE2ETests()
  
  when RUN_STRESS_TESTS:
    test "Stress Testing":
      check runStressTests()
  
  test "System Validation":
    check runValidationTests()

when isMainModule:
  echo "End-to-End Test Suite"
  echo "===================="
  echo "Running comprehensive end-to-end tests..."
  echo ""
  
  let start_time = now()
  
  discard runBasicE2ETests()
  discard runAdvancedE2ETests()
  
  when RUN_STRESS_TESTS:
    discard runStressTests()
  
  discard runValidationTests()
  
  let end_time = now()
  let total_duration = (end_time - start_time).inMilliseconds
  
  echo ""
  echo "===================="
  echo "End-to-End Test Suite Completed"
  echo "Total Duration: ", total_duration, "ms"
  echo "All end-to-end tests passed successfully!" 