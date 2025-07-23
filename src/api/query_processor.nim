# Query Processor
#
# This module processes queries and returns verified thoughts from the knowledge graph.
# It serves as the interface between the foreground AI and the knowledge graph.

import std/[tables, strutils, algorithm, times]
import ../types
import ../knowledge_graph/types
import ../thoughts/manager

type
  QueryResult* = object
    ## Result of a query against the knowledge graph
    query*: string                    ## Original query
    verified_thoughts*: seq[Thought]  ## Verified thoughts relevant to the query
    confidence*: float                ## Overall confidence in the results
    processing_time*: float           ## Time taken to process the query
    
  QueryProcessor* = object
    ## Processes queries and returns verified thoughts
    knowledge_graph*: KnowledgeGraph
    
  ThoughtRelevance* = object
    ## Relevance score for a thought
    thought*: Thought
    relevance_score*: float
    match_type*: string  # "exact", "partial", "semantic"

proc newQueryProcessor*(knowledge_graph: KnowledgeGraph): QueryProcessor =
  ## Create a new query processor
  return QueryProcessor(
    knowledge_graph: knowledge_graph
  )

proc calculateRelevance*(query: string, thought: Thought): float =
  ## Calculate relevance score between query and thought
  let query_lower = query.toLowerAscii()
  let thought_name_lower = thought.name.toLowerAscii()
  let thought_desc_lower = thought.description.toLowerAscii()
  
  var score = 0.0
  
  # Exact match in thought name
  if query_lower == thought_name_lower:
    score += 1.0
  # Query contains thought name
  elif query_lower.contains(thought_name_lower):
    score += 0.8
  # Thought name contains query
  elif thought_name_lower.contains(query_lower):
    score += 0.7
  # Partial match in description
  elif thought_desc_lower.contains(query_lower):
    score += 0.5
  
  # Boost score for verified thoughts
  if thought.verified:
    score *= 1.2
  
  # Consider confidence
  score *= thought.confidence
  
  return clamp(score, 0.0, 1.0)

proc processQuery*(processor: QueryProcessor, query: string): QueryResult =
  ## Process a query and return relevant verified thoughts
  let start_time = cpuTime()
  
  var relevant_thoughts: seq[ThoughtRelevance] = @[]
  
  # Get all verified thoughts
  let all_thoughts = processor.knowledge_graph.thought_manager.getVerifiedThoughts()
  
  # Calculate relevance for each thought
  for thought in all_thoughts:
    let relevance = calculateRelevance(query, thought)
    if relevance > 0.1:  # Only include thoughts with some relevance
      relevant_thoughts.add(ThoughtRelevance(
        thought: thought,
        relevance_score: relevance,
        match_type: if relevance >= 0.8: "exact" elif relevance >= 0.5: "partial" else: "semantic"
      ))
  
  # Sort by relevance score (highest first)
  relevant_thoughts.sort(proc (a, b: ThoughtRelevance): int =
    if a.relevance_score > b.relevance_score: -1
    elif a.relevance_score < b.relevance_score: 1
    else: 0
  )
  
  # Extract just the thoughts (sorted by relevance)
  var thoughts: seq[Thought] = @[]
  for item in relevant_thoughts:
    thoughts.add(item.thought)
  
  # Calculate overall confidence
  let overall_confidence = if thoughts.len > 0:
    var total_confidence = 0.0
    for thought in thoughts:
      total_confidence += thought.confidence
    total_confidence / float(thoughts.len)
  else:
    0.0
  
  let processing_time = cpuTime() - start_time
  
  return QueryResult(
    query: query,
    verified_thoughts: thoughts,
    confidence: overall_confidence,
    processing_time: processing_time
  )

proc getThoughtsForEntity*(processor: QueryProcessor, entity_id: string): seq[Thought] =
  ## Get all verified thoughts for a specific entity
  return processor.knowledge_graph.thought_manager.getThoughtsForEntity(entity_id)

proc searchThoughts*(processor: QueryProcessor, search_term: string): seq[Thought] =
  ## Search thoughts by term
  return processor.knowledge_graph.thought_manager.searchThoughts(search_term)

proc getThoughtStats*(processor: QueryProcessor): (int, int) =
  ## Get statistics about thoughts
  let total_thoughts = processor.knowledge_graph.thought_manager.getThoughtCount()
  let verified_thoughts = processor.knowledge_graph.thought_manager.getVerifiedThoughtCount()
  return (total_thoughts, verified_thoughts) 