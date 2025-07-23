# Agent Orchestrator
#
# This module orchestrates agent activities, manages Ollama integration,
# and coordinates agent attention based on foreground focus and autonomous duties.
# Background agents are NOT directly prompted - they operate autonomously.

import std/[times, json, asyncdispatch, options, algorithm, tables, strutils]
import std/[asynchttpserver, asyncnet, httpclient]
import ../types
import registry
import api_manager
import attention_system
import ../thoughts/validator
import ../knowledge_graph/operations
import role_prompts
import ../knowledge_graph/types
import ../thoughts/manager

type
  AgentOrchestrator* = ref object
    registry*: AgentRegistry
    attention_system*: AttentionSystem
    thought_validator*: ThoughtValidator
    api_manager*: AgentAPIManager
    # State management is now handled through the registry
    foreground_agent*: string  # ID of the foreground agent
    knowledge_graph*: KnowledgeGraph

  AgentTask* = object
    id*: string
    description*: string
    task_type*: string
    parameters*: JsonNode
    priority*: int
    status*: TaskStatus
    assigned_agent*: Option[string]
    created*: int64
    completed*: Option[int64]
    result*: Option[string]

  TaskStatus* = enum
    Pending, InProgress, Completed, Failed

  OllamaResponse* = object
    model*: string
    created_at*: string
    response*: string
    done*: bool

# Constructor
proc newAgentOrchestrator*(ollama_url: string = "http://localhost:11434"): AgentOrchestrator =
  ## Create a new agent orchestrator with attention system
  var api_manager = newAgentAPIManager()
  var registry = newAgentRegistry()
  var attention_system = newAttentionSystem()
  var thought_validator = newThoughtValidator()
  
  # Initialize default agents
  discard registry.initializeDefaultAgents()
  
  # Register APIs with different permission levels and role prompts
  let eidolon_api = newAgentAPI("eidolon_api", "llama3.2:3b", ollama_url, 
                                role_prompts.getRolePrompt("eidolon"), "", Full)
  let stage_manager_api = newAgentAPI("stage_manager_api", "llama3.2:3b", ollama_url, 
                                      role_prompts.getRolePrompt("stage_manager"), "", Full)
  let engineer_api = newAgentAPI("engineer_api", "llama3.2:3b", ollama_url, 
                                 role_prompts.getRolePrompt("engineer"), "", Suggest)
  let philosopher_api = newAgentAPI("philosopher_api", "llama3.2:3b", ollama_url, 
                                    role_prompts.getRolePrompt("philosopher"), "", Suggest)
  let skeptic_api = newAgentAPI("skeptic_api", "llama3.2:3b", ollama_url, 
                                role_prompts.getRolePrompt("skeptic"), "", Suggest)
  let dreamer_api = newAgentAPI("dreamer_api", "llama3.2:3b", ollama_url, 
                                role_prompts.getRolePrompt("dreamer"), "", Draft)
  let investigator_api = newAgentAPI("investigator_api", "llama3.2:3b", ollama_url, 
                                     role_prompts.getRolePrompt("investigator"), "", Suggest)
  let archivist_api = newAgentAPI("archivist_api", "llama3.2:3b", ollama_url, 
                                  role_prompts.getRolePrompt("archivist"), "", Suggest)
  
  # Register all APIs
  discard api_manager.registerAPI(eidolon_api)
  discard api_manager.registerAPI(stage_manager_api)
  discard api_manager.registerAPI(engineer_api)
  discard api_manager.registerAPI(philosopher_api)
  discard api_manager.registerAPI(skeptic_api)
  discard api_manager.registerAPI(dreamer_api)
  discard api_manager.registerAPI(investigator_api)
  discard api_manager.registerAPI(archivist_api)
  
  var knowledge_graph = newKnowledgeGraph()
  
  result = AgentOrchestrator(
    registry: registry,
    attention_system: attention_system,
    thought_validator: thought_validator,
    api_manager: api_manager,
    # active_agents table removed - state managed through registry
    foreground_agent: "eidolon",
    knowledge_graph: knowledge_graph
  )

# Ollama Integration
proc callOllama*(orchestrator: AgentOrchestrator, prompt: string): Future[string] {.async.} =
  ## Call Ollama with a prompt
  try:
    let api = orchestrator.api_manager.getAvailableAPI()
    if api.isNone:
      return "Error: No available API"
    
    let selected_api = api.get()
    orchestrator.api_manager.incrementRequestCount(selected_api.api_id)
    
    defer: orchestrator.api_manager.decrementRequestCount(selected_api.api_id)
    
    let request_body = %*{
      "model": selected_api.model_name,
      "prompt": prompt,
      "stream": false
    }
    
    var client = newAsyncHttpClient()
    let response = await client.postContent(
      selected_api.base_url & "/api/generate",
      $request_body
    )
    
    let response_json = parseJson(response)
    if response_json.hasKey("response"):
      return response_json["response"].getStr()
    else:
      return "Error: No response from Ollama"
      
  except Exception as e:
    return "Error calling Ollama: " & e.msg



# Attention-Based Agent Coordination
proc updateForegroundFocus*(orchestrator: var AgentOrchestrator, entity_ids: seq[string]) =
  ## Update foreground agent focus and trigger background agent attention
  orchestrator.attention_system.updateForegroundFocus(entity_ids)
  
  # Update system state
  orchestrator.attention_system.updateSystemState()
  
  # Check for strain alerts
  orchestrator.attention_system.checkStrainAlerts()
  
  # Check if system is idle and trigger autonomous duties
  discard orchestrator.attention_system.checkIdleState()

proc getAgentAttention*(orchestrator: AgentOrchestrator, agent_id: string): seq[string] =
  ## Get entities an agent is currently attending to
  return orchestrator.attention_system.getAgentAttention(agent_id)

proc getForegroundFocus*(orchestrator: AgentOrchestrator): seq[string] =
  ## Get entities the foreground agent is currently examining
  return orchestrator.attention_system.getForegroundFocus()

proc isAgentAttendingTo*(orchestrator: AgentOrchestrator, agent_id: string, entity_id: string): bool =
  ## Check if an agent is attending to a specific entity
  return orchestrator.attention_system.isAgentAttendingTo(agent_id, entity_id)

proc getSystemState*(orchestrator: AgentOrchestrator): SystemState =
  ## Get current system state (wake, dream, sleep)
  return orchestrator.attention_system.getSystemState()

# Thought Validation Functions
proc validateThought*(orchestrator: AgentOrchestrator, thought_text: string): ThoughtValidationResult =
  ## Validate a thought to ensure it meets linguistic requirements
  return orchestrator.thought_validator.validateThought(thought_text)

proc validateAllThoughts*(orchestrator: AgentOrchestrator): Table[string, ThoughtValidationResult] =
  ## Validate all thoughts in the knowledge graph
  let all_thoughts = orchestrator.knowledge_graph.thought_manager.getAllThoughts()
  return orchestrator.thought_validator.validateThoughts(all_thoughts)

proc getInvalidThoughts*(orchestrator: AgentOrchestrator): seq[Thought] =
  ## Get all invalid thoughts for cleanup
  let all_thoughts = orchestrator.knowledge_graph.thought_manager.getAllThoughts()
  return orchestrator.thought_validator.getInvalidThoughts(all_thoughts)

proc countValidThoughts*(orchestrator: AgentOrchestrator): int =
  ## Count how many thoughts are valid
  let all_thoughts = orchestrator.knowledge_graph.thought_manager.getAllThoughts()
  return orchestrator.thought_validator.countValidThoughts(all_thoughts)

proc countInvalidThoughts*(orchestrator: AgentOrchestrator): int =
  ## Count how many thoughts are invalid
  let all_thoughts = orchestrator.knowledge_graph.thought_manager.getAllThoughts()
  return orchestrator.thought_validator.countInvalidThoughts(all_thoughts)

proc cleanupInvalidThoughts*(orchestrator: var AgentOrchestrator): int =
  ## Remove invalid thoughts and return count of removed thoughts
  let invalid_thoughts = orchestrator.getInvalidThoughts()
  var removed_count = 0
  
  for thought in invalid_thoughts:
    if orchestrator.knowledge_graph.thought_manager.removeThought(thought.id):
      removed_count += 1
  
  return removed_count

# Stage Manager Coordination Functions
proc assignDutyToAgent*(orchestrator: var AgentOrchestrator, duty: AgentDuty) =
  ## Assign a duty to an agent through the attention system
  orchestrator.attention_system.addAutonomousTask(duty.agent_id, duty.duty_type, duty.target_entities, duty.priority)
  
  # Update agent attention to the target entities
  orchestrator.attention_system.allocateAttention(duty.agent_id, duty.target_entities, 
                                                  AttentionType.autonomous_duty, AttentionTrigger.scheduled)

proc coordinateAgentDuties*(orchestrator: var AgentOrchestrator, foreground_entities: seq[string]) =
  ## Stage Manager coordinates agent duties based on foreground focus
  orchestrator.updateForegroundFocus(foreground_entities)
  
  # Stage Manager analyzes the entities and directs appropriate agents
  for entity_id in foreground_entities:
    let entity = getEntity(entity_id)
    if entity.isSome:
      let entity_data = entity.get
      let strain = entity_data.strain
      let connections = getEntityConnections(entity_id)
      
      # Create duty directives based on entity characteristics
      if entity_data.entity_type == EntityType.concept_type:
        if entity_data.name.contains("math") or entity_data.name.contains("calculation"):
          # Direct Engineer to mathematical entities
          let duty = createDutyDirective("engineer", DutyType.mathematical_analysis, @[entity_id], 0.8)
          orchestrator.assignDutyToAgent(duty)
        
        elif strain.frequency > 10:
          # Direct Philosopher to high-frequency conceptual entities
          let duty = createDutyDirective("philosopher", DutyType.pattern_analysis, @[entity_id], 0.6)
          orchestrator.assignDutyToAgent(duty)
      
      # Direct Skeptic to high-strain entities
      if strain.amplitude > 0.8:
        let duty = createDutyDirective("skeptic", DutyType.logical_verification, @[entity_id], 0.9)
        orchestrator.assignDutyToAgent(duty)
      
      # Direct Investigator to entities with many connections
      if connections.len > 5:
        let duty = createDutyDirective("investigator", DutyType.investigation, @[entity_id], 0.7)
        orchestrator.assignDutyToAgent(duty)
      
      # Direct Archivist to well-established entities
      if strain.frequency > 20 and strain.amplitude < 0.3:
        let duty = createDutyDirective("archivist", DutyType.knowledge_organization, @[entity_id], 0.5)
        orchestrator.assignDutyToAgent(duty)

proc getAgentDuties*(orchestrator: AgentOrchestrator, agent_id: string): seq[AutonomousTask] =
  ## Get current duties for a specific agent
  return orchestrator.attention_system.autonomous_tasks.getOrDefault(agent_id, @[])

proc triggerIdleDuties*(orchestrator: var AgentOrchestrator) =
  ## Trigger autonomous duties when system is idle
  orchestrator.attention_system.triggerAutonomousDuties()
  
  # Stage Manager can also create specific idle duties
  let idle_duties = @[
    createDutyDirective("dreamer", DutyType.creative_optimization, @[], 0.8),
    createDutyDirective("philosopher", DutyType.pattern_analysis, @[], 0.6),
    createDutyDirective("investigator", DutyType.investigation, @[], 0.7),
    createDutyDirective("archivist", DutyType.knowledge_organization, @[], 0.5)
  ]
  
  for duty in idle_duties:
    orchestrator.assignDutyToAgent(duty)

proc getSystemStatus*(orchestrator: AgentOrchestrator): JsonNode =
  ## Get comprehensive system status including agent attention and duties
  var status = %*{
    "system_state": $orchestrator.getSystemState(),
    "foreground_focus": orchestrator.getForegroundFocus(),
    "agent_attention": {},
    "agent_duties": {},
    "attention_history_count": orchestrator.attention_system.attention_history.len
  }
  
  # Add agent attention information
  for agent_id in @["stage_manager", "engineer", "philosopher", "skeptic", "dreamer", "investigator", "archivist"]:
    let attention = orchestrator.getAgentAttention(agent_id)
    let duties = orchestrator.getAgentDuties(agent_id)
    
    status["agent_attention"][agent_id] = %attention
    status["agent_duties"][agent_id] = %duties.len
  
  return status

# Task Management - REMOVED
# All task management functionality has been removed to fix compilation errors

# Agent Management
proc activateAgent*(orchestrator: AgentOrchestrator, agent_id: string): bool =
  ## Activate an agent and set up appropriate permissions
  if agent_id notin orchestrator.registry.agents:
    echo "Agent not found: ", agent_id
    return false
  
  discard orchestrator.registry.setAgentState(agent_id, AgentState.active)
  
  # Assign agent to specific API based on type
  case agent_id.toLowerAscii()
  of "stage_manager":
    discard orchestrator.api_manager.assignAgentToAPI(agent_id, "stage_manager_api")
    echo "Activated agent: ", agent_id, " (Full thought permissions)"
  of "engineer":
    discard orchestrator.api_manager.assignAgentToAPI(agent_id, "engineer_api")
    echo "Activated agent: ", agent_id, " (Suggest thought permissions)"
  of "philosopher":
    discard orchestrator.api_manager.assignAgentToAPI(agent_id, "philosopher_api")
    echo "Activated agent: ", agent_id, " (Suggest thought permissions)"
  of "skeptic":
    discard orchestrator.api_manager.assignAgentToAPI(agent_id, "skeptic_api")
    echo "Activated agent: ", agent_id, " (Suggest thought permissions)"
  of "dreamer":
    discard orchestrator.api_manager.assignAgentToAPI(agent_id, "dreamer_api")
    echo "Activated agent: ", agent_id, " (Draft thought permissions)"
  else:
    # Default to no thought permissions
    echo "Activated agent: ", agent_id, " (No thought permissions)"
  
  return true

proc deactivateAgent*(orchestrator: AgentOrchestrator, agent_id: string): bool =
  ## Deactivate an agent
  if agent_id in orchestrator.registry.agents:
    discard orchestrator.registry.setAgentState(agent_id, AgentState.available)
    echo "Deactivated agent: ", agent_id
    return true
  else:
    echo "Agent not found: ", agent_id
    return false

proc isAgentActive*(orchestrator: AgentOrchestrator, agent_id: string): bool =
  ## Check if an agent is active
  if agent_id in orchestrator.registry.agents:
    return orchestrator.registry.agents[agent_id].state == AgentState.active
  return false

proc callAgent*(orchestrator: AgentOrchestrator, agent_id: string, prompt: string): Future[string] {.async.} =
  ## Call a specific agent with a prompt
  if not orchestrator.isAgentActive(agent_id):
    return "Error: Agent not active: " & agent_id
  
  # Get the agent's role prompt
  let role_prompt = role_prompts.getRolePrompt(agent_id)
  let full_prompt = role_prompt & "\n\n" & prompt
  
  # Call Ollama with the full prompt
  return await orchestrator.callOllama(full_prompt)

# Context-Based Agent Selection
proc selectAgentForTask*(orchestrator: AgentOrchestrator, task_description: string): Option[string] =
  ## Select the best agent for a given task
  var best_agent: Option[string] = none(string)
  var best_score = 0
  
  let query_words = task_description.toLowerAscii().splitWhitespace()
  
  for agent_id, capability in orchestrator.registry.agents.pairs:
    if orchestrator.isAgentActive(agent_id):
      var score = 0
      for word in query_words:
        for keyword in capability.keywords:
          if word.contains(keyword) or keyword.contains(word):
            score += 1
      
      if score > best_score:
        best_score = score
        best_agent = some(agent_id)
  
  return best_agent

# Agent Duties - REMOVED
# All agent duty processing functionality has been removed to fix compilation errors

# Main orchestration loop - REMOVED
# Agent duty cycle functionality has been removed to fix compilation errors

# Utility functions - REMOVED
# Task status functionality has been removed to fix compilation errors 

# Thought Creation and Verification
proc requestThoughtVerification*(orchestrator: AgentOrchestrator, from_agent: string, 
                                thought_content: string, thought_type: string = "analysis"): Future[string] {.async.} =
  ## Request thought verification from Stage Manager
  let from_api = orchestrator.api_manager.getAPIForAgent(from_agent)
  if from_api.isNone:
    return "Error: Agent not found"
  
  let api = from_api.get()
  if not api.canSuggestThoughts():
    return "Error: Agent does not have permission to suggest thoughts"
  
  # Create verification request for Stage Manager
  let verification_request = """
As Stage Manager, please review and verify the following thought from """ & from_agent & """:

Thought Type: """ & thought_type & """
Content: """ & thought_content & """

Please:
1. Evaluate the thought for accuracy and consistency
2. Check for conflicts with existing verified thoughts
3. Determine if it should be verified or needs modification
4. Provide your decision and reasoning

If verified, this thought will be added to the knowledge graph as a verified thought.
"""
  
  return await orchestrator.callAgent("stage_manager", verification_request)

proc createVerifiedThought*(orchestrator: AgentOrchestrator, agent_id: string, 
                           thought_content: string, connections: seq[string]): Future[string] {.async.} =
  ## Create a verified thought (only Stage Manager can do this)
  let api = orchestrator.api_manager.getAPIForAgent(agent_id)
  if api.isNone:
    return "Error: Agent not found"
  
  let selected_api = api.get()
  if not selected_api.canCreateVerifiedThoughts():
    return "Error: Agent does not have permission to create verified thoughts"
  
  # Stage Manager can create verified thoughts directly
  let thought_creation_task = """
Create a verified thought with the following content and connections:

Content: """ & thought_content & """
Connections: """ & connections.join(", ") & """

This thought should be:
1. Accurate and well-formed
2. Properly connected to existing entities
3. Ready for immediate addition to the knowledge graph
4. Stored as a verified thought that other agents can reference

Provide the final verified thought in a format suitable for database storage.
"""
  
  return await orchestrator.callAgent(agent_id, thought_creation_task)

proc getAgentThoughtPermissions*(orchestrator: AgentOrchestrator, agent_id: string): string =
  ## Get the thought permissions for an agent
  let api = orchestrator.api_manager.getAPIForAgent(agent_id)
  if api.isNone:
    return "Agent not found"
  
  let selected_api = api.get()
  case selected_api.getThoughtPermission()
  of None:
    return "No thought permissions"
  of Draft:
    return "Can create draft thoughts"
  of Suggest:
    return "Can suggest thoughts to Stage Manager"
  of Verify:
    return "Can verify thoughts"
  of Full:
    return "Full thought creation and verification permissions" 