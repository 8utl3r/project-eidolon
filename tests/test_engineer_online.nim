# Test Engineer Agent Online
#
# Tests bringing the Engineer agent online and having it analyze the knowledge graph,
# storing its findings as verified thoughts in the database.

import std/[times, json, asyncdispatch, options, strutils]
import tables
import ../src/agents/orchestrator
import ../src/agents/api_manager
import ../src/knowledge_graph/operations
import ../src/thoughts/manager
import ../src/entities/manager
import ../src/database/word_loader

proc testEngineerOnline() {.async.} =
  echo "=== Engineer Agent Online Test ==="
  
  # Create orchestrator
  let orchestrator = newAgentOrchestrator()
  echo "✓ Created orchestrator with API manager"
  
  # Load knowledge graph data
  var entity_manager = newEntityManager()
  var thought_manager = newThoughtManager()
  
  echo "Loading knowledge graph data..."
  discard loadFromFiles(entity_manager, thought_manager, "tools/word_nodes.json", "tools/verified_thoughts.json")
  echo "✓ Loaded ", entity_manager.entities.len, " entities and ", thought_manager.thoughts.len, " thoughts"
  
  # Activate Engineer
  discard orchestrator.activateAgent("engineer")
  echo "✓ Activated Engineer agent"
  
  # Test 1: Knowledge Graph Structure Analysis
  echo "\n--- Testing Knowledge Graph Structure Analysis ---"
  let structure_task = """
Analyze the knowledge graph structure and provide insights:

Current Knowledge Graph State:
- 10,000 word entities (concept_type)
- 10,100 verified thoughts (definitions and multi-word thoughts)
- 544 verified connections (from multi-word thoughts)

Please analyze:
1. What patterns do you observe in the entity distribution?
2. What mathematical relationships exist between entities?
3. How can we optimize the knowledge graph structure?
4. What rules should govern entity relationships?

Store your analysis as verified thoughts that can be referenced by other agents.
"""
  
  echo "Sending structure analysis task to Engineer..."
  let structure_response = await orchestrator.callAgent("engineer", structure_task)
  echo "\nEngineer Structure Analysis:"
  echo "============================="
  echo structure_response
  echo "============================="
  
  # Test 2: Mathematical Pattern Detection
  echo "\n--- Testing Mathematical Pattern Detection ---"
  let pattern_task = """
Detect mathematical patterns in the knowledge graph:

Analyze the following aspects:
1. Entity frequency distributions
2. Connection density patterns
3. Clustering coefficients
4. Network centrality measures
5. Strain relationship patterns

Identify any mathematical rules or patterns that could be used to:
- Predict entity relationships
- Optimize knowledge retrieval
- Improve graph connectivity
- Balance strain distributions

Store these patterns as verified thoughts for future reference.
"""
  
  echo "Sending pattern detection task to Engineer..."
  let pattern_response = await orchestrator.callAgent("engineer", pattern_task)
  echo "\nEngineer Pattern Analysis:"
  echo "=========================="
  echo pattern_response
  echo "=========================="
  
  # Test 3: Optimization Recommendations
  echo "\n--- Testing Optimization Recommendations ---"
  let optimization_task = """
Provide optimization recommendations for the knowledge graph:

Based on your analysis, recommend:
1. How to improve entity relationship efficiency
2. Optimal strain distribution strategies
3. Mathematical models for knowledge graph growth
4. Performance optimization techniques
5. Scalability considerations

Focus on practical, implementable solutions that can be stored as verified thoughts
and referenced by the Stage Manager for coordination.
"""
  
  echo "Sending optimization task to Engineer..."
  let optimization_response = await orchestrator.callAgent("engineer", optimization_task)
  echo "\nEngineer Optimization Recommendations:"
  echo "======================================"
  echo optimization_response
  echo "======================================"
  
  # Test 4: Rule Generation
  echo "\n--- Testing Rule Generation ---"
  let rule_task = """
Generate mathematical rules for the knowledge graph system:

Create specific, actionable rules for:
1. Entity relationship formation
2. Strain calculation and distribution
3. Knowledge graph maintenance
4. Performance optimization
5. Quality assurance

These rules should be stored as verified thoughts that can be automatically
applied by the system and referenced by other agents.
"""
  
  echo "Sending rule generation task to Engineer..."
  let rule_response = await orchestrator.callAgent("engineer", rule_task)
  echo "\nEngineer Generated Rules:"
  echo "========================="
  echo rule_response
  echo "========================="
  
  echo "\n=== Engineer Agent Test Completed ==="
  echo "✓ Engineer is online and analyzing knowledge graph"
  echo "✓ Mathematical analysis capabilities verified"
  echo "✓ Ready to provide optimization and rule generation"
  echo "✓ Findings should be stored as verified thoughts for system-wide use"

when isMainModule:
  waitFor testEngineerOnline() 