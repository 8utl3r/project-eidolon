# Query Router Tests
#
# This module tests the strain-aware query routing system including
# natural language analysis, agent routing, and RAG integration.

import std/[unittest, tables, json, strutils]
import ../src/api/query_router
import ../src/rag/types
import ../src/rag/rag_engine
import ../src/strain/types

const RUN_QUERY_ROUTER_TESTS* = true

when RUN_QUERY_ROUTER_TESTS:
  suite "Query Router Tests":
    test "Query Router Creation":
      let rag_engine = newRAGEngine("test_rag")
      let router = newQueryRouter(rag_engine)
      
      check router.rag_engine.engine_id == "test_rag"
      check router.agent_capabilities.len == 0
      check router.query_history.len == 0
      check router.intent_keywords.len > 0
    
    test "Agent Capability Creation":
      let capability = newAgentCapability("mathematician", "Mathematician", @[mathematical, logical])
      
      check capability.agent_id == "mathematician"
      check capability.agent_type == "Mathematician"
      check capability.capabilities.len == 2
      check mathematical in capability.capabilities
      check logical in capability.capabilities
      check capability.is_active == true
      check capability.current_strain == 0.0
    
    test "Query Analysis Creation":
      let analysis = newQueryAnalysis("What is the meaning of life?")
      
      check analysis.original_query == "What is the meaning of life?"
      check analysis.detected_intents.len == 0
      check analysis.keywords.len == 0
      check analysis.complexity_score == 0.0
    
    test "Mathematical Query Analysis":
      let rag_engine = newRAGEngine("test_rag")
      let router = newQueryRouter(rag_engine)
      
      let analysis = router.analyzeQuery("Calculate the derivative of x^2")
      
      check mathematical in analysis.detected_intents
      check analysis.confidence_scores[mathematical] > 0.0
      check analysis.complexity_score > 0.0
      check "Calculate" in analysis.keywords
      check "derivative" in analysis.keywords
    
    test "Philosophical Query Analysis":
      let rag_engine = newRAGEngine("test_rag")
      let router = newQueryRouter(rag_engine)
      
      let analysis = router.analyzeQuery("What is the philosophical meaning of existence?")
      
      check philosophical in analysis.detected_intents
      check analysis.confidence_scores[philosophical] > 0.0
      check analysis.complexity_score > 0.0
      check "philosophical" in analysis.keywords
      check "existence" in analysis.keywords
    
    test "Creative Query Analysis":
      let rag_engine = newRAGEngine("test_rag")
      let router = newQueryRouter(rag_engine)
      
      let analysis = router.analyzeQuery("Imagine a creative solution to climate change")
      
      check creative in analysis.detected_intents
      check analysis.confidence_scores[creative] > 0.0
      check "creative" in analysis.keywords
      check "Imagine" in analysis.keywords
    
    test "Investigative Query Analysis":
      let rag_engine = newRAGEngine("test_rag")
      let router = newQueryRouter(rag_engine)
      
      let analysis = router.analyzeQuery("Investigate the pattern in this data")
      
      check investigative in analysis.detected_intents
      check analysis.confidence_scores[investigative] > 0.0
      check "Investigate" in analysis.keywords
      check "pattern" in analysis.keywords
    
    test "Strain Analysis Query":
      let rag_engine = newRAGEngine("test_rag")
      let router = newQueryRouter(rag_engine)
      
      let analysis = router.analyzeQuery("Analyze the strain flow between entities")
      
      check strain_analysis in analysis.detected_intents
      check analysis.confidence_scores[strain_analysis] > 0.0
      check "strain" in analysis.keywords
      check "flow" in analysis.keywords
    
    test "Entity Extraction":
      let rag_engine = newRAGEngine("test_rag")
      let router = newQueryRouter(rag_engine)
      
      let analysis = router.analyzeQuery("What is the relationship between Alice and Bob?")
      
      check "Alice" in analysis.entities
      check "Bob" in analysis.entities
      check relationship_query in analysis.detected_intents
    
    test "Complexity Score Calculation":
      let rag_engine = newRAGEngine("test_rag")
      let router = newQueryRouter(rag_engine)
      
      let simple_analysis = router.analyzeQuery("Hello")
      let complex_analysis = router.analyzeQuery("Calculate the mathematical relationship between quantum mechanics and classical physics using advanced statistical methods")
      
      check simple_analysis.complexity_score < complex_analysis.complexity_score
      check complex_analysis.complexity_score > 0.5
    
    test "Agent Registration":
      let rag_engine = newRAGEngine("test_rag")
      var router = newQueryRouter(rag_engine)
      
      let mathematician = newAgentCapability("mathematician", "Mathematician", @[mathematical, logical])
      let philosopher = newAgentCapability("philosopher", "Philosopher", @[philosophical, logical])
      
      router.registerAgent(mathematician)
      router.registerAgent(philosopher)
      
      check router.agent_capabilities.len == 2
      check router.agent_capabilities.hasKey("mathematician")
      check router.agent_capabilities.hasKey("philosopher")
    
    test "Best Agent Selection":
      let rag_engine = newRAGEngine("test_rag")
      var router = newQueryRouter(rag_engine)
      
      # Register agents
      let mathematician = newAgentCapability("mathematician", "Mathematician", @[mathematical, logical])
      let philosopher = newAgentCapability("philosopher", "Philosopher", @[philosophical, logical])
      let dreamer = newAgentCapability("dreamer", "Dreamer", @[creative])
      
      router.registerAgent(mathematician)
      router.registerAgent(philosopher)
      router.registerAgent(dreamer)
      
      # Test mathematical query
      let math_analysis = router.analyzeQuery("Calculate the integral of x^2")
      let math_route = router.findBestAgent(math_analysis)
      
      check math_route.primary_agent == "mathematician"
      check math_route.confidence > 0.0
      
      # Test philosophical query
      let phil_analysis = router.analyzeQuery("What is the meaning of existence?")
      let phil_route = router.findBestAgent(phil_analysis)
      
      check phil_route.primary_agent == "philosopher"
      check phil_route.confidence > 0.0
      
      # Test creative query
      let creative_analysis = router.analyzeQuery("Imagine a creative solution")
      let creative_route = router.findBestAgent(creative_analysis)
      
      check creative_route.primary_agent == "dreamer"
      check creative_route.confidence > 0.0
    
    test "Strain-Based Agent Selection":
      let rag_engine = newRAGEngine("test_rag")
      var router = newQueryRouter(rag_engine)
      
      # Register agents with different strain levels
      var mathematician = newAgentCapability("mathematician", "Mathematician", @[mathematical, logical])
      var philosopher = newAgentCapability("philosopher", "Philosopher", @[philosophical, logical])
      
      mathematician.current_strain = 0.8  # High strain
      philosopher.current_strain = 0.2    # Low strain
      
      router.registerAgent(mathematician)
      router.registerAgent(philosopher)
      
      # Query that both agents can handle
      let analysis = router.analyzeQuery("What is the logical foundation of mathematics?")
      let route = router.findBestAgent(analysis)
      
      # Should prefer the philosopher due to lower strain
      check route.primary_agent == "philosopher"
    
    test "RAG Enhancement":
      let rag_engine = newRAGEngine("test_rag")
      var router = newQueryRouter(rag_engine)
      
      # Add some knowledge to RAG
      let source = newKnowledgeSource("test_source", "document", "Test Source", "http://test.com")
      router.rag_engine.addKnowledgeSource(source)
      
      var chunk = newKnowledgeChunk("chunk1", "test_source", "Quantum mechanics is a fundamental theory in physics")
      chunk.confidence = 0.8
      router.rag_engine.addKnowledgeChunk(chunk)
      
      # Test complex query that should trigger RAG enhancement
      let analysis = router.analyzeQuery("Explain quantum mechanics and its relationship to classical physics")
      let enhanced_analysis = router.enhanceQueryWithRAG(analysis)
      
      check enhanced_analysis.strain_context.frequency > analysis.strain_context.frequency
      check enhanced_analysis.strain_context.amplitude >= analysis.strain_context.amplitude
    
    test "Query Processing Pipeline":
      let rag_engine = newRAGEngine("test_rag")
      var router = newQueryRouter(rag_engine)
      
      # Register an agent
      let mathematician = newAgentCapability("mathematician", "Mathematician", @[mathematical, logical])
      router.registerAgent(mathematician)
      
      # Process a query
      let response = router.processQuery("Calculate the derivative of x^2")
      
      check response["query"].getStr == "Calculate the derivative of x^2"
      check response["analysis"]["intents"].len > 0
      check response["routing"]["primary_agent"].getStr == "mathematician"
      check response["processing_time"].getFloat > 0.0
      check response["strain"]["amplitude"].getFloat > 0.0
    
    test "Performance Metrics":
      let rag_engine = newRAGEngine("test_rag")
      var router = newQueryRouter(rag_engine)
      
      # Process several queries
      for i in 1..5:
        discard router.processQuery("Test query " & $i)
      
      let metrics = router.getPerformanceMetrics()
      check metrics.hasKey("avg_processing_time")
      check metrics["avg_processing_time"] > 0.0
    
    test "Query History":
      let rag_engine = newRAGEngine("test_rag")
      var router = newQueryRouter(rag_engine)
      
      # Process queries
      discard router.processQuery("First query")
      discard router.processQuery("Second query")
      discard router.processQuery("Third query")
      
      let history = router.getQueryHistory(2)
      check history.len == 2
      check history[0].original_query == "Second query"
      check history[1].original_query == "Third query"
    
    test "Agent Status Update":
      let rag_engine = newRAGEngine("test_rag")
      var router = newQueryRouter(rag_engine)
      
      let mathematician = newAgentCapability("mathematician", "Mathematician", @[mathematical])
      router.registerAgent(mathematician)
      
      # Update agent status
      router.updateAgentStatus("mathematician", 0.7, 1.5)
      
      check router.agent_capabilities["mathematician"].current_strain == 0.7
      check router.agent_capabilities["mathematician"].last_response_time == 1.5
    
    test "Query Strain Calculation":
      let rag_engine = newRAGEngine("test_rag")
      let router = newQueryRouter(rag_engine)
      
      let simple_analysis = router.analyzeQuery("Hello")
      let complex_analysis = router.analyzeQuery("Calculate the complex mathematical relationship between quantum mechanics and classical physics using advanced statistical methods and analyze the patterns")
      
      let simple_strain = calculateQueryStrain(simple_analysis)
      let complex_strain = calculateQueryStrain(complex_analysis)
      
      check simple_strain < complex_strain
      check complex_strain > 0.5
      check simple_strain <= 1.0
      check complex_strain <= 1.0

when isMainModule:
  echo "Running Query Router Tests..." 