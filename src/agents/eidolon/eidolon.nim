# Eidolon - Foreground Agent
#
# This module implements the Eidolon foreground agent, which serves as the primary
# interface for direct user interaction. Eidolon processes user queries, coordinates
# with background agents, and synthesizes responses.

import std/[tables, options, times, strutils, asyncdispatch]
import std/sequtils
import ../../types
import ../../api/ollama_client
import ../../knowledge_graph/types
import ../../thoughts/manager
import ../registry
import ../role_prompts

type
  EidolonAgent* = ref object
    ## Foreground agent for direct user interaction
    agent_id*: string
    agent_type*: AgentType
    state*: AgentState
    current_strain*: float
    max_strain*: float
    created*: DateTime
    last_accessed*: DateTime
    
    # Foreground-specific fields
    current_focus*: seq[string]  # Entity IDs currently being examined
    query_history*: seq[string]  # Recent user queries
    response_cache*: Table[string, string]  # Cached responses
    context_window*: int  # Number of recent interactions to maintain
    
    # Integration points
    ollama_client*: OllamaClient
    knowledge_graph*: KnowledgeGraph
    thought_manager*: ThoughtManager
    agent_registry*: AgentRegistry

proc newEidolonAgent*(
  ollama_client: OllamaClient,
  knowledge_graph: KnowledgeGraph,
  thought_manager: ThoughtManager,
  agent_registry: AgentRegistry
): EidolonAgent =
  ## Create a new Eidolon foreground agent
  return EidolonAgent(
    agent_id: "eidolon",
    agent_type: AgentType.eidolon,
    state: AgentState.active,
    current_strain: 0.0,
    max_strain: 1.0,
    created: now(),
    last_accessed: now(),
    current_focus: @[],
    query_history: @[],
    response_cache: initTable[string, string](),
    context_window: 10,
    ollama_client: ollama_client,
    knowledge_graph: knowledge_graph,
    thought_manager: thought_manager,
    agent_registry: agent_registry
  )

proc processUserQuery*(eidolon: EidolonAgent, query: string): Future[string] {.async.} =
  ## Process a user query by consulting the knowledge graph only
  eidolon.last_accessed = now()
  eidolon.query_history.add(query)
  
  # Maintain context window
  if eidolon.query_history.len > eidolon.context_window:
    let start_index = eidolon.query_history.len - eidolon.context_window
    eidolon.query_history = eidolon.query_history[start_index..^1]
  
  # Check cache first
  if eidolon.response_cache.hasKey(query):
    return eidolon.response_cache[query]
  
  # Extract entities from query and find relevant thoughts
  var relevant_entities: seq[Entity] = @[]
  var relevant_thoughts: seq[Thought] = @[]
  
  # Simple keyword matching for entities
  let query_words = query.toLowerAscii().splitWhitespace()
  let entity_manager = eidolon.knowledge_graph.entity_manager
  for entity_id, entity in entity_manager.entities:
    for word in query_words:
      if word.len > 2 and entity.name.toLowerAscii().contains(word):
        relevant_entities.add(entity)
        break
  
  # Find relevant thoughts
  let thought_manager = eidolon.knowledge_graph.thought_manager
  for thought_id, thought in thought_manager.thoughts:
    for word in query_words:
      if word.len > 2 and (thought.description.toLowerAscii().contains(word) or 
                          thought.name.toLowerAscii().contains(word)):
        relevant_thoughts.add(thought)
        break
  
  eidolon.current_focus = @[]
  for entity in relevant_entities:
    eidolon.current_focus.add(entity.id)
  
  # Build context from knowledge graph only
  var context = "User Query: " & query & "\n\n"
  context.add("Relevant Entities from Database:\n")
  for entity in relevant_entities:
    context.add("- " & entity.name & ": " & entity.description & "\n")
  
  context.add("\nRelevant Thoughts from Database:\n")
  for thought in relevant_thoughts:
    context.add("- " & thought.name & ": " & thought.description & "\n")
  
  # Create response using only database information
  let eidolon_prompt = """
You are Eidolon, the foreground agent of Project Eidolon. Your role is to:

1. Process user queries by consulting the knowledge graph
2. Provide answers based on available database information
3. Return three different perspectives as requested:
   A) Pure reasoning (no database access)
   B) Hybrid approach (database + reasoning)
   C) Database-only (only knowledge graph data)

Context from Knowledge Graph:
""" & context & """

Provide your response in the three-answer format as specified in your role prompt.
"""
  
  let eidolon_req = newOllamaRequest(eidolon.ollama_client.default_model, eidolon_prompt)
  let eidolon_response_opt = await eidolon.ollama_client.generateResponse(eidolon_req)
  var response = ""
  if eidolon_response_opt.isSome:
    response = eidolon_response_opt.get.response
  
  # Cache the response
  eidolon.response_cache[query] = response
  
  # Update strain based on query complexity
  let complexity = float(query.len) / 100.0  # Simple complexity metric
  eidolon.current_strain = min(eidolon.current_strain + complexity * 0.1, eidolon.max_strain)
  
  return response

proc updateFocus*(eidolon: EidolonAgent, entity_ids: seq[string]) =
  ## Update the entities Eidolon is currently focusing on
  eidolon.current_focus = entity_ids
  eidolon.last_accessed = now()

proc getCurrentFocus*(eidolon: EidolonAgent): seq[string] =
  ## Get the entities Eidolon is currently focusing on
  return eidolon.current_focus

proc getQueryHistory*(eidolon: EidolonAgent): seq[string] =
  ## Get recent query history
  return eidolon.query_history

proc clearCache*(eidolon: EidolonAgent) =
  ## Clear the response cache
  eidolon.response_cache.clear()

proc getStrain*(eidolon: EidolonAgent): float =
  ## Get current strain level
  return eidolon.current_strain

proc resetStrain*(eidolon: EidolonAgent) =
  ## Reset strain to zero
  eidolon.current_strain = 0.0
  eidolon.last_accessed = now()

proc isAvailable*(eidolon: EidolonAgent): bool =
  ## Check if Eidolon is available for processing
  return eidolon.state == AgentState.active and eidolon.current_strain < eidolon.max_strain

proc getStatus*(eidolon: EidolonAgent): Table[string, string] =
  ## Get current status information
  var status = initTable[string, string]()
  status["agent_id"] = eidolon.agent_id
  status["agent_type"] = $eidolon.agent_type
  status["state"] = $eidolon.state
  status["current_strain"] = $eidolon.current_strain
  status["max_strain"] = $eidolon.max_strain
  status["focus_count"] = $eidolon.current_focus.len
  status["query_history_count"] = $eidolon.query_history.len
  status["cache_size"] = $eidolon.response_cache.len
  status["is_available"] = $eidolon.isAvailable()
  return status 