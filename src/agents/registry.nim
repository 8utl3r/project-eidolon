# Agent Registry
#
# This module manages agent capabilities, registration, and selection.
# It provides a centralized registry for all background agents.

import std/[tables, options, times, strutils, algorithm]
import ../types

type
  AgentCapability* = object
    ## Agent capability definition
    agent_id*: string
    agent_type*: AgentType
    keywords*: seq[string]
    state*: AgentState
    current_strain*: float
    max_strain*: float
    created*: DateTime
    last_accessed*: DateTime

  AgentRegistry* = object
    ## Registry for managing agent capabilities
    agents*: Table[string, AgentCapability]
    keyword_index*: Table[string, seq[string]]  # keyword -> agent_ids
    agent_types*: Table[AgentType, seq[string]]  # agent_type -> agent_ids
    created*: DateTime
    last_updated*: DateTime
    # Performance optimizations
    search_cache*: Table[string, seq[string]]  # query -> agent_ids
    strain_cache*: Table[string, float]  # agent_id -> cached_strain

# Constructor functions
proc newAgentCapability*(agent_id: string, agent_type: AgentType, keywords: seq[string]): AgentCapability =
  ## Create a new agent capability
  return AgentCapability(
    agent_id: agent_id,
    agent_type: agent_type,
    keywords: keywords,
    state: AgentState.available,
    current_strain: 0.0,
    max_strain: 1.0,
    created: now(),
    last_accessed: now()
  )

proc newAgentRegistry*(): AgentRegistry =
  ## Create a new agent registry
  return AgentRegistry(
    agents: initTable[string, AgentCapability](),
    keyword_index: initTable[string, seq[string]](),
    agent_types: initTable[AgentType, seq[string]](),
    created: now(),
    last_updated: now(),
    search_cache: initTable[string, seq[string]](),
    strain_cache: initTable[string, float]()
  )

# Core registry functions
proc registerAgent*(registry: var AgentRegistry, capability: AgentCapability): bool =
  ## Register an agent capability
  if capability.agent_id in registry.agents:
    return false  # Agent already exists
  
  registry.agents[capability.agent_id] = capability
  
  # Index by keywords for fast lookup
  for keyword in capability.keywords:
    if not registry.keyword_index.hasKey(keyword):
      registry.keyword_index[keyword] = @[]
    registry.keyword_index[keyword].add(capability.agent_id)
  
  # Index by agent type
  if not registry.agent_types.hasKey(capability.agent_type):
    registry.agent_types[capability.agent_type] = @[]
  registry.agent_types[capability.agent_type].add(capability.agent_id)
  
  registry.last_updated = now()
  return true

proc findAgentsByKeywords*(registry: AgentRegistry, query: string): seq[string] =
  ## Find agents by keywords using optimized search
  # Check cache first
  if registry.search_cache.hasKey(query):
    return registry.search_cache[query]
  
  var matching_agents: seq[string] = @[]
  var agent_scores: Table[string, int] = initTable[string, int]()
  
  let query_words = query.toLowerAscii().splitWhitespace()
  
  # Score agents based on keyword matches
  for word in query_words:
    if word.len > 2 and registry.keyword_index.hasKey(word):
      for agent_id in registry.keyword_index[word]:
        if agent_id notin agent_scores:
          agent_scores[agent_id] = 0
        agent_scores[agent_id] += 1
  
  # Sort by score and return top matches
  var scored_agents: seq[tuple[agent_id: string, score: int]] = @[]
  for agent_id, score in agent_scores:
    scored_agents.add((agent_id: agent_id, score: score))
  
  # Sort by score (descending)
  scored_agents.sort(proc(a, b: tuple[agent_id: string, score: int]): int =
    if a.score > b.score: -1
    elif a.score < b.score: 1
    else: 0
  )
  
  for scored_agent in scored_agents:
    matching_agents.add(scored_agent.agent_id)
  
  # Cache the result
  var mutable_registry = registry
  mutable_registry.search_cache[query] = matching_agents
  
  return matching_agents

proc calculateAgentScore*(agent: AgentCapability, query: string): float =
  ## Calculate agent score for a query with strain penalty
  let keyword_matches = agent.keywords.len
  let query_words = query.toLowerAscii().splitWhitespace()
  
  var match_count = 0
  for keyword in agent.keywords:
    for word in query_words:
      if keyword.toLowerAscii() == word.toLowerAscii():
        match_count += 1
  
  let base_score = if keyword_matches > 0: float(match_count) / float(keyword_matches) else: 0.0
  
  # Apply strain penalty (higher strain = lower score)
  let strain_penalty = agent.current_strain * 0.3  # 30% penalty at max strain
  let final_score = base_score * (1.0 - strain_penalty)
  
  return clamp(final_score, 0.0, 1.0)

proc findBestAgent*(registry: AgentRegistry, query: string): Option[string] =
  ## Find the best agent for a query
  let matching_agents = registry.findAgentsByKeywords(query)
  
  if matching_agents.len == 0:
    return none(string)
  
  var best_agent_id = ""
  var best_score = 0.0
  
  for agent_id in matching_agents:
    if agent_id in registry.agents:
      let agent = registry.agents[agent_id]
      if agent.state == AgentState.active:
        let score = calculateAgentScore(agent, query)
        if score > best_score:
          best_score = score
          best_agent_id = agent_id
  
  if best_agent_id.len > 0:
    return some(best_agent_id)
  else:
    return none(string)

proc updateAgentStrain*(registry: var AgentRegistry, agent_id: string, strain: float): bool =
  ## Update agent strain with caching
  if agent_id notin registry.agents:
    return false
  
  var agent = registry.agents[agent_id]
  agent.current_strain = clamp(strain, 0.0, agent.max_strain)
  agent.last_accessed = now()
  registry.agents[agent_id] = agent
  
  # Update strain cache
  registry.strain_cache[agent_id] = agent.current_strain
  
  registry.last_updated = now()
  return true

proc getAgentById*(registry: AgentRegistry, agent_id: string): Option[AgentCapability] =
  ## Get agent by ID
  if agent_id in registry.agents:
    return some(registry.agents[agent_id])
  else:
    return none(AgentCapability)

proc getActiveAgents*(registry: AgentRegistry): seq[AgentCapability] =
  ## Get all active agents
  var active_agents: seq[AgentCapability] = @[]
  for agent in registry.agents.values:
    if agent.state == AgentState.active:
      active_agents.add(agent)
  return active_agents

proc getAvailableAgents*(registry: AgentRegistry): seq[AgentCapability] =
  ## Get all available agents
  var available_agents: seq[AgentCapability] = @[]
  for agent in registry.agents.values:
    if agent.state == AgentState.available:
      available_agents.add(agent)
  return available_agents

proc getInactiveAgents*(registry: AgentRegistry): seq[AgentCapability] =
  ## Get all inactive agents
  var inactive_agents: seq[AgentCapability] = @[]
  for agent in registry.agents.values:
    if agent.state == AgentState.inactive:
      inactive_agents.add(agent)
  return inactive_agents

proc setAgentState*(registry: var AgentRegistry, agent_id: string, state: AgentState): bool =
  ## Set agent state
  if agent_id notin registry.agents:
    return false
  
  var agent = registry.agents[agent_id]
  agent.state = state
  agent.last_accessed = now()
  registry.agents[agent_id] = agent
  
  registry.last_updated = now()
  return true

proc getAgentsByType*(registry: AgentRegistry, agent_type: AgentType): seq[AgentCapability] =
  ## Get agents by type
  var type_agents: seq[AgentCapability] = @[]
  if agent_type in registry.agent_types:
    for agent_id in registry.agent_types[agent_type]:
      if agent_id in registry.agents:
        type_agents.add(registry.agents[agent_id])
  return type_agents

# Default agent initialization
proc initializeDefaultAgents*(registry: var AgentRegistry): bool =
  ## Initialize default agents (foreground and background)
  let default_agents = @[
    newAgentCapability("eidolon", eidolon, @["user", "query", "help", "assist", "explain", "what", "how", "why", "when", "where", "who", "interact", "conversation", "response", "synthesize", "coordinate", "foreground", "interface"]),
    newAgentCapability("engineer", engineer, @["calculate", "solve", "equation", "math", "derivative", "integral", "algebra", "geometry", "statistics", "how do i", "process", "method", "procedure"]),
    newAgentCapability("philosopher", philosopher, @["philosophy", "meaning", "existence", "ethics", "logic", "reasoning", "wisdom", "truth", "knowledge", "reality"]),
    newAgentCapability("skeptic", skeptic, @["verify", "validate", "check", "confirm", "logic", "reasoning", "evidence", "proof", "analysis", "scrutiny"]),
    newAgentCapability("dreamer", dreamer, @["imagine", "creative", "inspiration", "vision", "possibility", "innovation", "artistic", "fantasy", "dream", "inspire"]),
    newAgentCapability("investigator", investigator, @["investigate", "analyze", "examine", "research", "explore", "discover", "pattern", "evidence", "clue", "mystery"]),
    newAgentCapability("archivist", archivist, @["find", "search", "retrieve", "organize", "catalog", "index", "store", "memory", "archive", "record"]),
    newAgentCapability("stage_manager", stage_manager, @["coordinate", "manage", "organize", "direct", "orchestrate", "facilitate", "guide", "lead", "supervise", "oversee"]),
    newAgentCapability("linguist", linguist, @["vocabulary", "translate", "translation", "colloquial", "idiom", "slang", "language", "speech", "phrase", "expression", "meaning", "definition", "lexicon", "paraphrase", "interpret", "understand", "word", "words", "linguistics"])
  ]
  
  for agent in default_agents:
    discard registry.registerAgent(agent)
  
  return true 