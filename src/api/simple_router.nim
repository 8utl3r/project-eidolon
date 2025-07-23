# Simple Router
#
# This module provides a simple query router that selects the best agent
# for processing queries and integrates with the RAG system.

import std/[times, options, json, strutils, tables]
import ../types
import ../agents/registry
import ../rag/rag_engine

type
  QueryResult* = object
    ## Simple query result
    query*: string
    selected_agent*: Option[string]
    agent_score*: float
    rag_enhanced*: bool
    rag_confidence*: float
    processing_time*: float
    strain_level*: float

  SimpleRouter* = object
    ## Simple query router
    agent_registry*: AgentRegistry
    rag_engine*: RAGEngine
    # Performance optimizations
    query_cache*: Table[string, QueryResult]  # Cache for repeated queries
    analysis_cache*: Table[string, tuple[keywords: seq[string], complexity: float]]  # Cache query analysis

# Constructor functions
proc newSimpleRouter*(rag_engine: RAGEngine): SimpleRouter =
  ## Create a new simple router
  var registry = newAgentRegistry()
  discard registry.initializeDefaultAgents()
  
  return SimpleRouter(
    agent_registry: registry,
    rag_engine: rag_engine,
    query_cache: initTable[string, QueryResult](),
    analysis_cache: initTable[string, tuple[keywords: seq[string], complexity: float]]()
  )

# Pure functions for query processing
proc analyzeQuery*(query: string): tuple[keywords: seq[string], complexity: float] =
  ## Analyze a query to extract keywords and complexity
  let words = query.toLowerAscii().splitWhitespace()
  var keywords: seq[string] = @[]
  
  # Filter short words manually
  for word in words:
    if word.len > 2:
      keywords.add(word)
  
  # Simple complexity calculation
  let complexity = min(1.0, (words.len.float / 15.0) + (keywords.len.float / 8.0))
  
  return (keywords: keywords, complexity: complexity)

proc needsRAGEnhancement*(complexity: float, keywords: seq[string]): bool =
  ## Determine if query needs RAG enhancement
  return complexity > 0.3 or keywords.len > 4

proc enhanceQueryWithRAG*(rag_engine: RAGEngine, query: string): tuple[enhanced: bool, confidence: float] =
  ## Enhance query with RAG system
  let rag_response = rag_engine.query(query, 3, 0.1)  # Lower threshold for better matching
  
  if rag_response.retrieved_chunks.len > 0:
    return (enhanced: true, confidence: rag_response.confidence)
  else:
    return (enhanced: false, confidence: 0.0)

proc calculateStrainLevel*(query: string, agent_score: float, rag_confidence: float): float =
  ## Calculate strain level for query processing
  let base_strain = 1.0 - agent_score  # Lower agent score = higher strain
  let rag_strain = 1.0 - rag_confidence  # Lower RAG confidence = higher strain
  let query_complexity = min(1.0, query.len.float / 100.0)
  
  # Combine factors with weights
  let strain = (base_strain * 0.4) + (rag_strain * 0.3) + (query_complexity * 0.3)
  return min(1.0, strain)

# Main query processing function
proc processQuery*(router: SimpleRouter, query: string): QueryResult =
  ## Process a query through the simple router with caching
  let start_time = now()
  
  # Check cache first
  if router.query_cache.hasKey(query):
    return router.query_cache[query]
  
  # Analyze query (with caching)
  let (keywords, complexity) = if router.analysis_cache.hasKey(query):
    router.analysis_cache[query]
  else:
    let analysis = analyzeQuery(query)
    var mutable_router = router
    mutable_router.analysis_cache[query] = analysis
    analysis
  
  # Find best agent
  let best_agent = router.agent_registry.findBestAgent(query)
  let agent_score = if best_agent.isSome:
    let agent = router.agent_registry.getAgentById(best_agent.get()).get()
    calculateAgentScore(agent, query)
  else:
    0.0
  
  # Enhance with RAG if needed
  let (rag_enhanced, rag_confidence) = if needsRAGEnhancement(complexity, keywords):
    enhanceQueryWithRAG(router.rag_engine, query)
  else:
    (false, 0.0)
  
  # Calculate strain level
  let strain_level = calculateStrainLevel(query, agent_score, rag_confidence)
  
  # Calculate processing time (ensure minimum measurable time)
  let end_time = now()
  let time_diff = end_time - start_time
  let processing_time = max(0.001, time_diff.inMilliseconds.float / 1000.0)  # Minimum 1ms
  
  var queryResult: QueryResult
  queryResult = QueryResult(
    query: query,
    selected_agent: best_agent,
    agent_score: agent_score,
    rag_enhanced: rag_enhanced,
    rag_confidence: rag_confidence,
    processing_time: processing_time,
    strain_level: strain_level
  )
  
  # Cache the result
  var mutable_router = router
  mutable_router.query_cache[query] = queryResult
  
  return queryResult

# Agent management functions
proc getAgentInfo*(router: SimpleRouter, agent_id: string): Option[AgentCapability] =
  ## Get agent information
  return router.agent_registry.getAgentById(agent_id)

proc updateAgentStrain*(router: var SimpleRouter, agent_id: string, strain: float): bool =
  ## Update agent strain
  return router.agent_registry.updateAgentStrain(agent_id, strain)

proc getActiveAgents*(router: SimpleRouter): seq[AgentCapability] =
  ## Get all active agents
  return router.agent_registry.getActiveAgents()

proc getAgentsByType*(router: SimpleRouter, agent_type: AgentType): seq[AgentCapability] =
  ## Get agents by type
  return router.agent_registry.getAgentsByType(agent_type)

# JSON conversion
proc toJson*(queryResult: QueryResult): JsonNode =
  ## Convert query result to JSON
  var json = %*{
    "query": queryResult.query,
    "selected_agent": if isSome(queryResult.selected_agent): get(queryResult.selected_agent) else: "",
    "agent_score": queryResult.agent_score,
    "rag_enhanced": queryResult.rag_enhanced,
    "rag_confidence": queryResult.rag_confidence,
    "processing_time": queryResult.processing_time,
    "strain_level": queryResult.strain_level
  }
  return json

proc agentToJson*(agent: AgentCapability): JsonNode =
  ## Convert agent to JSON
  var json = %*{
    "agent_id": agent.agent_id,
    "agent_type": $agent.agent_type,
    "keywords": agent.keywords,
    "state": $agent.state,
    "current_strain": agent.current_strain,
    "max_strain": agent.max_strain,
    "created": $agent.created,
    "last_accessed": $agent.last_accessed
  }
  return json 