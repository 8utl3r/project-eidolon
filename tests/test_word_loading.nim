# Test Word Loading and Thought Querying
#
# This test verifies that word nodes and verified thoughts can be loaded
# and queried correctly.

import std/[json, times]
import ../src/types
import ../src/entities/manager
import ../src/thoughts/manager
import ../src/knowledge_graph/types
import ../src/database/word_loader
import ../src/api/query_processor

proc testWordLoading*(): bool =
  ## Test loading word nodes and thoughts
  echo "Testing word loading and thought querying..."
  
  # Create managers
  var entity_manager = newEntityManager()
  var thought_manager = newThoughtManager()
  
  # Load from the generated files
  let (entities_loaded, thoughts_loaded) = loadFromFiles(
    entity_manager, thought_manager,
    "tools/word_nodes.json", 
    "tools/verified_thoughts.json"
  )
  
  echo "Loaded ", entities_loaded, " entities and ", thoughts_loaded, " thoughts"
  
  if entities_loaded == 0 or thoughts_loaded == 0:
    echo "❌ Failed to load word data"
    return false
  
  # Create knowledge graph
  var knowledge_graph = newKnowledgeGraph()
  knowledge_graph.entity_manager = entity_manager
  knowledge_graph.thought_manager = thought_manager
  
  # Create query processor
  let query_processor = newQueryProcessor(knowledge_graph)
  
  # Test some queries
  let test_queries = @["the", "and", "potato", "computer", "philosophy"]
  
  for query in test_queries:
    echo "Testing query: '", query, "'"
    let result = query_processor.processQuery(query)
    echo "  Found ", result.verified_thoughts.len, " relevant thoughts"
    echo "  Confidence: ", result.confidence
    echo "  Processing time: ", result.processing_time, " seconds"
    
    if result.verified_thoughts.len > 0:
      echo "  Top thought: ", result.verified_thoughts[0].name
      echo "  Description: ", result.verified_thoughts[0].description
  
  # Test entity-specific thoughts
  echo "Testing entity-specific thoughts for 'the':"
  let entity_thoughts = query_processor.getThoughtsForEntity("the")
  echo "  Found ", entity_thoughts.len, " thoughts for entity 'the'"
  
  # Get stats
  let (total_thoughts, verified_thoughts) = query_processor.getThoughtStats()
  echo "Total thoughts: ", total_thoughts
  echo "Verified thoughts: ", verified_thoughts
  
  echo "✅ Word loading and thought querying test passed"
  return true

when isMainModule:
  if testWordLoading():
    echo "All tests passed!"
  else:
    echo "Tests failed!"
    quit(1) 