# Simple Router Tests
#
# Comprehensive tests for the simple query routing system.
# Tests agent registry, simple router, and integration with RAG.

import std/[unittest, tables, json, options]
import ../src/types
import ../src/agents/registry
import ../src/api/simple_router
import ../src/rag/types
import ../src/rag/rag_engine
import ../src/knowledge_graph/types

const RUN_SIMPLE_ROUTER_TESTS* = true

when RUN_SIMPLE_ROUTER_TESTS:
  suite "Agent Registry Tests":
    test "Registry Creation":
      let registry = newAgentRegistry()
      check registry.agents.len == 0
      check registry.keyword_index.len == 0
    
    test "Agent Capability Creation":
      let capability = newAgentCapability("test_agent", engineer, @["calculate", "solve"])
      
      check capability.agent_id == "test_agent"
      check capability.agent_type == engineer
      check capability.keywords.len == 2
      check capability.state == available
      check capability.current_strain == 0.0
    
    test "Agent Registration":
      var registry = newAgentRegistry()
      let capability = newAgentCapability("test_agent", philosopher, @["philosophy", "meaning"])
      
      let success = registry.registerAgent(capability)
      check success == true
      check registry.agents.len == 1
      check registry.agents.hasKey("test_agent")
      check registry.keyword_index.hasKey("philosophy")
      check registry.keyword_index.hasKey("meaning")
    
    test "Agent Registration Failure":
      var registry = newAgentRegistry()
      let capability = newAgentCapability("", philosopher, @["philosophy"])
      
      let success = registry.registerAgent(capability)
      check success == false
      check registry.agents.len == 0
    
    test "Keyword Indexing":
      var registry = newAgentRegistry()
      let capability = newAgentCapability("test_agent", engineer, @["calculate", "solve"])
      
      discard registry.registerAgent(capability)
      
      check registry.keyword_index.hasKey("calculate")
      check registry.keyword_index.hasKey("solve")
      check registry.keyword_index["calculate"].len == 1
      check registry.keyword_index["calculate"][0] == "test_agent"
    
    test "Find Agents By Keywords":
      var registry = newAgentRegistry()
      let math_agent = newAgentCapability("engineer", engineer, @["calculate", "solve"])
      let phil_agent = newAgentCapability("philosopher", philosopher, @["philosophy", "meaning"])
      
      discard registry.registerAgent(math_agent)
      discard registry.registerAgent(phil_agent)
      
      let math_results = registry.findAgentsByKeywords("calculate the derivative")
      let phil_results = registry.findAgentsByKeywords("what is the philosophical meaning")
      
      check math_results.len > 0
      check phil_results.len > 0
      check math_results[0] == "engineer"
      check phil_results[0] == "philosopher"
    
    test "Agent Score Calculation":
      let agent = newAgentCapability("test_agent", engineer, @["calculate", "solve", "equation"])
      
      let perfect_score = calculateAgentScore(agent, "calculate the equation")
      let partial_score = calculateAgentScore(agent, "calculate something")
      let no_match_score = calculateAgentScore(agent, "philosophy meaning")
      
      check perfect_score > 0.6
      check partial_score > 0.3
      check partial_score < perfect_score
      check no_match_score == 0.0
    
    test "Strain Penalty":
      var agent = newAgentCapability("test_agent", engineer, @["calculate", "solve"])
      agent.current_strain = 0.8  # High strain
      
      let high_strain_score = calculateAgentScore(agent, "calculate the equation")
      agent.current_strain = 0.2  # Low strain
      let low_strain_score = calculateAgentScore(agent, "calculate the equation")
      
      check low_strain_score > high_strain_score
    
    test "Find Best Agent":
      var registry = newAgentRegistry()
      let math_agent = newAgentCapability("engineer", engineer, @["calculate", "solve"])
      let phil_agent = newAgentCapability("philosopher", philosopher, @["philosophy", "meaning"])
      
      discard registry.registerAgent(math_agent)
      discard registry.registerAgent(phil_agent)
      
      let math_result = registry.findBestAgent("calculate the derivative")
      let phil_result = registry.findBestAgent("what is the philosophical meaning")
      let no_match = registry.findBestAgent("random query with no keywords")
      
      check isSome(math_result)
      check isSome(phil_result)
      check get(math_result) == "engineer"
      check get(phil_result) == "philosopher"
      check not isSome(no_match)
    
    test "Agent Strain Update":
      var registry = newAgentRegistry()
      let agent = newAgentCapability("test_agent", engineer, @["calculate"])
      
      discard registry.registerAgent(agent)
      let success = registry.updateAgentStrain("test_agent", 0.9)  # High strain
      check success == true
      var engineer_agent = registry.agents["test_agent"]
      engineer_agent.state = inactive
      registry.agents["test_agent"] = engineer_agent
      
      let inactive_result = registry.findBestAgent("calculate the equation")
      check not isSome(inactive_result)
    
    test "Agent Type Filtering":
      var registry = newAgentRegistry()
      let math_agent = newAgentCapability("math_specialist", engineer, @["calculate"])
      let phil_agent = newAgentCapability("phil_specialist", philosopher, @["philosophy"])
      
      discard registry.registerAgent(math_agent)
      discard registry.registerAgent(phil_agent)
      
      let engineers = registry.getAgentsByType(engineer)
      let philosophers = registry.getAgentsByType(philosopher)
      
      check engineers.len == 1
      check philosophers.len == 1
      check engineers[0].agent_id == "math_specialist"
      check philosophers[0].agent_id == "phil_specialist"
    
    test "Agent JSON Serialization":
      let agent = newAgentCapability("test_agent", engineer, @["calculate", "solve"])
      let json_agent = agentToJson(agent)
      
      check json_agent.hasKey("agent_id")
      check json_agent.hasKey("agent_type")
      check json_agent.hasKey("keywords")
      check json_agent["agent_id"].getStr == "test_agent"
      check json_agent["agent_type"].getStr == "engineer"
      check json_agent["keywords"].len == 2

  suite "Simple Router Tests":
    test "Router Creation":
      var mock_rag = newRAGEngine("test_engine")
      let router = newSimpleRouter(mock_rag)
      
      check router.rag_engine.engine_id == "test_engine"
      check router.agent_registry.agents.len == 0
    
    test "Query Processing":
      var mock_rag = newRAGEngine("test_engine")
      var router = newSimpleRouter(mock_rag)
      
      let agent = newAgentCapability("test_agent", engineer, @["calculate", "solve"])
      discard router.agent_registry.registerAgent(agent)
      
      let result = router.processQuery("calculate the derivative")
      
      check result.query == "calculate the derivative"
      check isSome(result.selected_agent)
      check result.agent_score > 0.0
      check get(result.selected_agent) == "test_agent"
    
    test "RAG Enhancement":
      var mock_rag = newRAGEngine("test_engine")
      var router = newSimpleRouter(mock_rag)
      
      let agent = newAgentCapability("test_agent", engineer, @["calculate", "solve"])
      discard router.agent_registry.registerAgent(agent)
      
      let result = router.processQuery("calculate the derivative")
      
      check result.rag_enhanced == false  # Simple query shouldn't need RAG
      check result.rag_confidence == 0.0
    
    test "Agent Selection Logic":
      var mock_rag = newRAGEngine("test_engine")
      var router = newSimpleRouter(mock_rag)
      
      let math_agent = newAgentCapability("math_specialist", engineer, @["calculate"])
      let phil_agent = newAgentCapability("phil_specialist", philosopher, @["philosophy"])
      
      discard router.agent_registry.registerAgent(math_agent)
      discard router.agent_registry.registerAgent(phil_agent)
      
      let math_result = router.processQuery("calculate the derivative")
      let phil_result = router.processQuery("what is the philosophical meaning")
      
      check get(math_result.selected_agent) == "math_specialist"
      check get(phil_result.selected_agent) == "phil_specialist"
    
    test "Agent Information Retrieval":
      var mock_rag = newRAGEngine("test_engine")
      var router = newSimpleRouter(mock_rag)
      
      let agent = newAgentCapability("test_agent", engineer, @["calculate"])
      discard router.agent_registry.registerAgent(agent)
      
      let agent_info = router.getAgentInfo("test_agent")
      
      check isSome(agent_info)
      check agent_info.get().agent_type == AgentType.engineer
    
    test "Agent Strain Management":
      var mock_rag = newRAGEngine("test_engine")
      var router = newSimpleRouter(mock_rag)
      
      let agent = newAgentCapability("test_agent", engineer, @["calculate"])
      discard router.agent_registry.registerAgent(agent)
      
      let success = router.updateAgentStrain("test_agent", 0.7)
      check success == true
      
      let agent_info = router.getAgentInfo("test_agent")
      check agent_info.get().current_strain == 0.7
    
    test "Agent Type Filtering":
      var mock_rag = newRAGEngine("test_engine")
      var router = newSimpleRouter(mock_rag)
      
      let math_agent = newAgentCapability("math_specialist", engineer, @["calculate"])
      let phil_agent = newAgentCapability("phil_specialist", philosopher, @["philosophy"])
      
      discard router.agent_registry.registerAgent(math_agent)
      discard router.agent_registry.registerAgent(phil_agent)
      
      let engineers = router.getAgentsByType(engineer)
      let philosophers = router.getAgentsByType(philosopher)
      
      check engineers.len == 1
      check philosophers.len == 1
      check engineers[0].agent_id == "math_specialist"
      check philosophers[0].agent_id == "phil_specialist"
    
 