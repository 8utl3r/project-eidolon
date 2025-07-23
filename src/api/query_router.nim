# Strain-Aware Query Router
#
# This module provides intelligent query routing based on strain calculations,
# agent capabilities, and natural language analysis. It integrates with the
# RAG system for knowledge enhancement and routes queries to appropriate agents.

import std/[times, tables, options, json, strutils, sequtils, math]
import ../types
import ../strain/math
import ../strain/types
import ../rag/types
import ../rag/rag_engine
import ./types
import ./response_formats

type
  QueryIntent* = enum
    ## Types of query intent
    mathematical, logical, creative, investigative, philosophical, 
    archival, general, strain_analysis, relationship_query

  AgentCapability* = object
    ## Agent capability for handling specific query types
    agent_id*: string
    agent_type*: string
    capabilities*: seq[QueryIntent]
    current_strain*: float
    authority_level*: float
    is_active*: bool
    last_response_time*: float

  QueryAnalysis* = object
    ## Analysis of a natural language query
    original_query*: string
    detected_intents*: seq[QueryIntent]
    confidence_scores*: Table[QueryIntent, float]
    keywords*: seq[string]
    entities*: seq[string]
    strain_context*: StrainData
    complexity_score*: float

  QueryRoute* = object
    ## Route for a query to specific agents
    primary_agent*: string
    secondary_agents*: seq[string]
    rag_enhancement*: bool
    strain_threshold*: float
    expected_response_time*: float
    confidence*: float

  QueryRouter* = object
    ## Main query router for strain-aware query processing
    rag_engine*: RAGEngine
    knowledge_graph*: KnowledgeGraph
    response_formatter*: ResponseFormatter
    agent_capabilities*: Table[string, AgentCapability]
    intent_keywords*: Table[QueryIntent, seq[string]]
    strain_parameters*: StrainParameters
    query_history*: seq[QueryAnalysis]
    performance_metrics*: Table[string, float]

const
  # Default keywords for intent detection
  MATHEMATICAL_KEYWORDS = @["calculate", "solve", "equation", "formula", "math", "number", "statistics", "probability"]
  LOGICAL_KEYWORDS = @["logic", "reasoning", "argument", "proof", "contradiction", "valid", "invalid", "skeptic"]
  CREATIVE_KEYWORDS = @["creative", "imagine", "dream", "inspire", "artistic", "novel", "original", "vision"]
  INVESTIGATIVE_KEYWORDS = @["investigate", "analyze", "pattern", "anomaly", "evidence", "hypothesis", "research"]
  PHILOSOPHICAL_KEYWORDS = @["philosophy", "meaning", "purpose", "existence", "ethics", "metaphysics", "wisdom"]
  ARCHIVAL_KEYWORDS = @["find", "search", "retrieve", "organize", "categorize", "archive", "memory", "history"]
  STRAIN_KEYWORDS = @["strain", "confidence", "amplitude", "resistance", "flow", "gravitational", "tension"]
  RELATIONSHIP_KEYWORDS = @["relationship", "connection", "link", "between", "related", "associate", "correlate"]

# Constructor functions
proc newQueryRouter*(rag_engine: RAGEngine, knowledge_graph: KnowledgeGraph): QueryRouter =
  ## Create a new query router with RAG integration and response formatting
  var router = QueryRouter(
    rag_engine: rag_engine,
    knowledge_graph: knowledge_graph,
    response_formatter: newResponseFormatter(rag_engine, knowledge_graph),
    agent_capabilities: initTable[string, AgentCapability](),
    intent_keywords: initTable[QueryIntent, seq[string]](),
    strain_parameters: DEFAULT_STRAIN_PARAMETERS,
    query_history: @[],
    performance_metrics: initTable[string, float]()
  )
  
  # Initialize intent keywords
  router.intent_keywords[mathematical] = MATHEMATICAL_KEYWORDS
  router.intent_keywords[logical] = LOGICAL_KEYWORDS
  router.intent_keywords[creative] = CREATIVE_KEYWORDS
  router.intent_keywords[investigative] = INVESTIGATIVE_KEYWORDS
  router.intent_keywords[philosophical] = PHILOSOPHICAL_KEYWORDS
  router.intent_keywords[archival] = ARCHIVAL_KEYWORDS
  router.intent_keywords[strain_analysis] = STRAIN_KEYWORDS
  router.intent_keywords[relationship_query] = RELATIONSHIP_KEYWORDS
  
  return router

proc newAgentCapability*(agent_id: string, agent_type: string, 
                        capabilities: seq[QueryIntent]): AgentCapability =
  ## Create a new agent capability definition
  return AgentCapability(
    agent_id: agent_id,
    agent_type: agent_type,
    capabilities: capabilities,
    current_strain: 0.0,
    authority_level: 1.0,
    is_active: true,
    last_response_time: 0.0
  )

proc newQueryAnalysis*(query: string): QueryAnalysis =
  ## Create a new query analysis
  return QueryAnalysis(
    original_query: query,
    detected_intents: @[],
    confidence_scores: initTable[QueryIntent, float](),
    keywords: @[],
    entities: @[],
    strain_context: newStrainData(),
    complexity_score: 0.0
  )

# Query Analysis Functions
proc analyzeQuery*(router: QueryRouter, query: string): QueryAnalysis =
  ## Analyze a natural language query to determine intent and context
  var analysis = newQueryAnalysis(query)
  let query_lower = query.toLowerAscii()
  
  # Extract keywords
  let words = query_lower.splitWhitespace()
  analysis.keywords = words.filterIt(it.len > 2)  # Filter out short words
  
  # Detect intents based on keywords
  for intent, keywords in router.intent_keywords:
    var score = 0.0
    for keyword in keywords:
      if keyword.toLowerAscii() in query_lower:
        score += 1.0
    
    if score > 0:
      analysis.detected_intents.add(intent)
      analysis.confidence_scores[intent] = score / keywords.len.float
  
  # Calculate complexity score based on query length and word variety
  analysis.complexity_score = min(1.0, (words.len.float / 20.0) + (analysis.keywords.len.float / 10.0))
  
  # Extract potential entities (capitalized words)
  for word in words:
    if word.len > 2 and word[0].isUpperAscii():
      analysis.entities.add(word)
  
  # Calculate strain context based on query complexity and detected intents
  analysis.strain_context.amplitude = analysis.complexity_score
  analysis.strain_context.resistance = 1.0 - (analysis.detected_intents.len.float / 8.0)
  analysis.strain_context.frequency = analysis.keywords.len
  
  return analysis

# Agent Routing Functions
proc findBestAgent*(router: QueryRouter, analysis: QueryAnalysis): QueryRoute =
  ## Find the best agent(s) to handle a query based on analysis
  var best_agent = ""
  var best_score = 0.0
  var secondary_agents: seq[string] = @[]
  
  for agent_id, capability in router.agent_capabilities:
    if not capability.is_active:
      continue
    
    var agent_score = 0.0
    
    # Score based on capability match
    for intent in analysis.detected_intents:
      if intent in capability.capabilities:
        agent_score += analysis.confidence_scores.getOrDefault(intent, 0.0)
    
    # Adjust score based on current strain (prefer less strained agents)
    let strain_penalty = capability.current_strain * 0.5
    agent_score -= strain_penalty
    
    # Adjust score based on authority level
    agent_score *= capability.authority_level
    
    # Adjust score based on response time (prefer faster agents)
    let response_penalty = capability.last_response_time * 0.1
    agent_score -= response_penalty
    
    if agent_score > best_score:
      best_score = agent_score
      best_agent = agent_id
    elif agent_score > best_score * 0.7:  # Secondary agents with 70% of best score
      secondary_agents.add(agent_id)
  
  # Determine if RAG enhancement is needed
  let needs_rag = analysis.complexity_score > 0.5 or analysis.detected_intents.len > 2
  
  return QueryRoute(
    primary_agent: best_agent,
    secondary_agents: secondary_agents,
    rag_enhancement: needs_rag,
    strain_threshold: 0.5,
    expected_response_time: 1.0 + analysis.complexity_score,
    confidence: best_score
  )

# RAG Integration Functions
proc enhanceQueryWithRAG*(router: QueryRouter, analysis: QueryAnalysis): QueryAnalysis =
  ## Enhance query analysis with RAG system knowledge
  if analysis.complexity_score < 0.3:
    return analysis  # Simple queries don't need RAG enhancement
  
  # Query RAG system for relevant knowledge
  let rag_response = router.rag_engine.query(analysis.original_query, 5, 0.5)
  
  # Enhance analysis with RAG results
  var enhanced_analysis = analysis
  
  # Add entities from RAG results
  for chunk in rag_response.retrieved_chunks:
    # Extract potential entities from chunk content
    let words = chunk.content.splitWhitespace()
    for word in words:
      if word.len > 2 and word[0].isUpperAscii():
        enhanced_analysis.entities.add(word)
  
  # Adjust strain context based on RAG confidence
  enhanced_analysis.strain_context.amplitude = max(analysis.strain_context.amplitude, rag_response.confidence)
  enhanced_analysis.strain_context.frequency += rag_response.retrieved_chunks.len
  
  return enhanced_analysis

# Main Query Processing Function
proc processQuery*(router: var QueryRouter, query: string): JsonNode =
  ## Process a natural language query through the strain-aware routing system
  let start_time = now()
  
  # Analyze the query
  var analysis = router.analyzeQuery(query)
  
  # Enhance with RAG if needed
  if analysis.complexity_score > 0.3:
    analysis = router.enhanceQueryWithRAG(analysis)
  
  # Find best agent route
  let route = router.findBestAgent(analysis)
  
  # Calculate strain flow (using a default target with zero amplitude)
  let strain_flow = calculateStrainFlow(
    analysis.strain_context.amplitude,  # from_amplitude
    0.0,                               # to_amplitude (target)
    analysis.strain_context.resistance, # from_resistance
    0.5,                               # to_resistance (default)
    0.1                                # connection_resistance (default)
  )
  
  # Convert confidence scores to string keys for JSON serialization
  var confidence_scores_json: Table[string, float]
  for intent, score in analysis.confidence_scores:
    confidence_scores_json[$intent] = score
  
  # Create response
  let response = %*{
    "query": query,
    "analysis": {
      "intents": analysis.detected_intents.mapIt($it),
      "confidence_scores": confidence_scores_json,
      "complexity_score": analysis.complexity_score,
      "entities": analysis.entities,
      "keywords": analysis.keywords
    },
    "routing": {
      "primary_agent": route.primary_agent,
      "secondary_agents": route.secondary_agents,
      "rag_enhancement": route.rag_enhancement,
      "confidence": route.confidence,
      "expected_response_time": route.expected_response_time
    },
    "strain": {
      "amplitude": analysis.strain_context.amplitude,
      "resistance": analysis.strain_context.resistance,
      "frequency": analysis.strain_context.frequency,
      "flow": strain_flow
    },
    "processing_time": (now() - start_time).inMilliseconds.float / 1000.0
  }
  
  # Update performance metrics
  router.performance_metrics["avg_processing_time"] = 
    (router.performance_metrics.getOrDefault("avg_processing_time", 0.0) + 
     response["processing_time"].getFloat) / 2.0
  
  # Store in query history
  router.query_history.add(analysis)
  if router.query_history.len > 100:  # Keep last 100 queries
    router.query_history = router.query_history[^100..^1]
  
  return response

# Agent Management Functions
proc registerAgent*(router: var QueryRouter, capability: AgentCapability) =
  ## Register an agent with the query router
  router.agent_capabilities[capability.agent_id] = capability

proc updateAgentStatus*(router: var QueryRouter, agent_id: string, 
                       strain: float, response_time: float) =
  ## Update agent status after processing a query
  if router.agent_capabilities.hasKey(agent_id):
    router.agent_capabilities[agent_id].current_strain = strain
    router.agent_capabilities[agent_id].last_response_time = response_time

proc getAgentCapabilities*(router: QueryRouter): seq[AgentCapability] =
  ## Get all registered agent capabilities
  return router.agent_capabilities.values.toSeq

proc getPerformanceMetrics*(router: QueryRouter): Table[string, float] =
  ## Get performance metrics for the query router
  return router.performance_metrics

# Utility Functions
proc calculateQueryStrain*(analysis: QueryAnalysis): float =
  ## Calculate the strain level for a query analysis
  let base_strain = analysis.complexity_score
  let intent_multiplier = 1.0 + (analysis.detected_intents.len.float * 0.2)
  let entity_multiplier = 1.0 + (analysis.entities.len.float * 0.1)
  
  return min(1.0, base_strain * intent_multiplier * entity_multiplier)

proc getQueryHistory*(router: QueryRouter, limit: int = 10): seq[QueryAnalysis] =
  ## Get recent query history
  if router.query_history.len <= limit:
    return router.query_history
  else:
    return router.query_history[^limit..^1]

proc processQueryWithFormat*(router: QueryRouter, query: string, format: ResponseFormat, 
                           user_id: string = ""): FormattedResponse =
  ## Process a query using the specified response format (A/B/C system)
  let start_time = now()
  
  # Analyze the query first
  var analysis = router.analyzeQuery(query)
  
  # Get formatted response
  let formatted_response = router.response_formatter.formatResponse(query, format)
  
  # Update user preference if provided
  if user_id.len > 0:
    router.response_formatter.setFormatPreference(user_id, format)
  
  # Update performance metrics
  router.performance_metrics["avg_format_response_time"] = 
    (router.performance_metrics.getOrDefault("avg_format_response_time", 0.0) + 
     formatted_response.response_time) / 2.0
  
  # Store in query history
  router.query_history.add(analysis)
  if router.query_history.len > 100:  # Keep last 100 queries
    router.query_history = router.query_history[^100..^1]
  
  return formatted_response

proc getResponseFormatSummary*(router: QueryRouter, query: string): string =
  ## Get a summary of all three response formats for a query
  let external_response = router.response_formatter.formatResponse(query, external_only)
  let database_response = router.response_formatter.formatResponse(query, database_only)
  let synthesis_response = router.response_formatter.formatResponse(query, synthesis)
  
  var summary = "Response Format Comparison for: " & query & "\n"
  summary.add("=" ^ 60 & "\n\n")
  
  summary.add("Format A (External Only):\n")
  summary.add("- Confidence: " & formatFloat(external_response.total_confidence, precision = 2) & "\n")
  summary.add("- Response Time: " & formatFloat(external_response.response_time, precision = 3) & "s\n")
  summary.add("- Content Preview: " & external_response.primary_response.content[0..min(100, external_response.primary_response.content.len-1)] & "...\n\n")
  
  summary.add("Format B (Database Only):\n")
  summary.add("- Confidence: " & formatFloat(database_response.total_confidence, precision = 2) & "\n")
  summary.add("- Response Time: " & formatFloat(database_response.response_time, precision = 3) & "s\n")
  summary.add("- Content Preview: " & database_response.primary_response.content[0..min(100, database_response.primary_response.content.len-1)] & "...\n\n")
  
  summary.add("Format C (Synthesis):\n")
  summary.add("- Confidence: " & formatFloat(synthesis_response.total_confidence, precision = 2) & "\n")
  summary.add("- Response Time: " & formatFloat(synthesis_response.response_time, precision = 3) & "s\n")
  summary.add("- Content Preview: " & synthesis_response.primary_response.content[0..min(100, synthesis_response.primary_response.content.len-1)] & "...\n\n")
  
  return summary 