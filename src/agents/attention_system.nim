# Agent Attention System
#
# This module implements the attention system that manages how background agents
# focus on nodes based on foreground agent attention and perform autonomous duties.

import std/[times, tables, options, json, strutils, sequtils]
import ../types
import ../knowledge_graph/operations
import ../strain/math

type
  AttentionSystem* = ref object
    ## Manages agent attention and autonomous operation
    foreground_focus*: seq[string]  # Entity IDs the foreground is currently examining
    agent_attention*: Table[string, seq[string]]  # Agent ID -> Entity IDs they're attending to
    attention_history*: seq[AttentionEvent]  # History of attention changes
    autonomous_tasks*: Table[string, seq[AutonomousTask]]  # Agent ID -> pending autonomous tasks
    system_state*: SystemState  # Current system state (wake, dream, sleep)
    last_foreground_activity*: DateTime  # Last foreground agent activity
    idle_threshold*: float  # Seconds before system considered idle

  AttentionEvent* = object
    ## Record of an attention change
    timestamp*: DateTime
    agent_id*: string
    entity_ids*: seq[string]
    attention_type*: AttentionType
    trigger*: AttentionTrigger
    strain_context*: StrainData

  AttentionType* = enum
    foreground_follow  # Agent following foreground focus
    autonomous_duty    # Agent performing autonomous duty
    strain_alert       # Agent responding to strain alert
    coordination       # Agent coordinating with others

  AttentionTrigger* = enum
    foreground_activity    # Foreground agent accessed entities
    idle_timeout          # System idle, trigger autonomous duties
    strain_threshold      # High strain detected
    pattern_detected      # Pattern requiring attention
    scheduled             # Scheduled autonomous task

  AutonomousTask* = object
    ## Task for autonomous agent operation
    task_id*: string
    agent_id*: string
    task_type*: string
    target_entities*: seq[string]
    priority*: float
    created*: DateTime
    completed*: Option[DateTime]
    parameters*: JsonNode

  SystemState* = enum
    wake, dream, sleep

# Constructor
proc newAttentionSystem*(): AttentionSystem =
  result = AttentionSystem(
    foreground_focus: @[],
    agent_attention: initTable[string, seq[string]](),
    attention_history: @[],
    autonomous_tasks: initTable[string, seq[AutonomousTask]](),
    system_state: SystemState.wake,
    last_foreground_activity: now(),
    idle_threshold: 30.0  # 30 seconds idle threshold
  )

# Attention Allocation (defined first to avoid compilation order issues)
proc allocateAttention*(attention: var AttentionSystem, agent_id: string, entity_ids: seq[string], 
                       attention_type: AttentionType, trigger: AttentionTrigger) =
  ## Allocate attention for an agent to specific entities
  attention.agent_attention[agent_id] = entity_ids
  
  # Record attention event
  let event = AttentionEvent(
    timestamp: now(),
    agent_id: agent_id,
    entity_ids: entity_ids,
    attention_type: attention_type,
    trigger: trigger,
    strain_context: StrainData()  # TODO: Calculate actual strain context
  )
  
  attention.attention_history.add(event)
  
  # Limit history to last 100 events
  if attention.attention_history.len > 100:
    attention.attention_history = attention.attention_history[^100..^1]

# Foreground Focus Management
proc triggerForegroundFollowing*(attention: var AttentionSystem) =
  ## Trigger background agents to attend to foreground focus
  for entity_id in attention.foreground_focus:
    # Stage Manager should always track foreground focus
    attention.allocateAttention("stage_manager", @[entity_id], AttentionType.foreground_follow, AttentionTrigger.foreground_activity)
    
    # Other agents attend based on their domain and current strain
    let entity = getEntity(entity_id)
    if entity.isSome:
      let strain = entity.get.strain
      
      # Engineer attends to mathematical entities or high-strain technical entities
      if entity.get.entity_type == EntityType.concept_type and 
         (entity.get.name.contains("math") or entity.get.name.contains("calculation") or strain.amplitude > 0.7):
        attention.allocateAttention("engineer", @[entity_id], AttentionType.foreground_follow, AttentionTrigger.foreground_activity)
      
      # Skeptic attends to high-strain entities or contradictory information
      if strain.amplitude > 0.8 or strain.node_resistance > 0.6:
        attention.allocateAttention("skeptic", @[entity_id], AttentionType.foreground_follow, AttentionTrigger.foreground_activity)
      
      # Philosopher attends to conceptual entities or pattern-rich areas
      if entity.get.entity_type == EntityType.concept_type and strain.frequency > 10:
        attention.allocateAttention("philosopher", @[entity_id], AttentionType.foreground_follow, AttentionTrigger.foreground_activity)
      
      # Investigator attends to entities with many connections or anomalies
      let connections = getEntityConnections(entity_id)
      if connections.len > 5 or strain.amplitude > 0.6:
        attention.allocateAttention("investigator", @[entity_id], AttentionType.foreground_follow, AttentionTrigger.foreground_activity)
      
      # Archivist attends to high-frequency, well-established entities
      if strain.frequency > 20 and strain.amplitude < 0.3:
        attention.allocateAttention("archivist", @[entity_id], AttentionType.foreground_follow, AttentionTrigger.foreground_activity)

proc updateForegroundFocus*(attention: var AttentionSystem, entity_ids: seq[string]) =
  ## Update what entities the foreground agent is currently examining
  attention.foreground_focus = entity_ids
  attention.last_foreground_activity = now()
  
  # Trigger background agents to follow foreground focus
  triggerForegroundFollowing(attention)

# Autonomous Duty Management
proc addAutonomousTask*(attention: var AttentionSystem, agent_id: string, task_type: string, 
                       target_entities: seq[string], priority: float) =
  ## Add an autonomous task for an agent
  let task = AutonomousTask(
    task_id: "autonomous_" & agent_id & "_" & $now().toTime.toUnix(),
    agent_id: agent_id,
    task_type: task_type,
    target_entities: target_entities,
    priority: priority,
    created: now(),
    completed: none(DateTime),
    parameters: %*{}
  )
  
  if agent_id notin attention.autonomous_tasks:
    attention.autonomous_tasks[agent_id] = @[]
  
  attention.autonomous_tasks[agent_id].add(task)

proc triggerAutonomousDuties*(attention: var AttentionSystem) =
  ## Trigger autonomous duties for background agents when system is idle
  attention.system_state = SystemState.dream
  
  # Dreamer performs creative optimization when idle
  attention.addAutonomousTask("dreamer", "creative_optimization", @[], 0.8)
  
  # Philosopher analyzes patterns when idle
  attention.addAutonomousTask("philosopher", "pattern_analysis", @[], 0.6)
  
  # Investigator explores knowledge gaps when idle
  attention.addAutonomousTask("investigator", "knowledge_exploration", @[], 0.7)
  
  # Archivist organizes knowledge when idle
  attention.addAutonomousTask("archivist", "knowledge_organization", @[], 0.5)

proc checkIdleState*(attention: var AttentionSystem): bool =
  ## Check if system is idle and trigger autonomous duties
  # Autonomous duties are now controlled manually via UI, not automatically
  # This function is kept for compatibility but does not trigger automatically
  return false

# Strain-Based Attention
proc checkStrainAlerts*(attention: var AttentionSystem) =
  ## Check for high-strain entities that need attention
  let all_entities = getAllEntities()
  
  for entity in all_entities:
    if entity.strain.amplitude > 0.9:  # Critical strain threshold
      attention.allocateAttention("skeptic", @[entity.id], AttentionType.strain_alert, AttentionTrigger.strain_threshold)
      
    elif entity.strain.amplitude > 0.7:  # High strain threshold
      # Engineer for technical entities
      if entity.entity_type == EntityType.concept_type:
        attention.allocateAttention("engineer", @[entity.id], AttentionType.strain_alert, AttentionTrigger.strain_threshold)
      
      # Investigator for entities with many connections
      let connections = getEntityConnections(entity.id)
      if connections.len > 3:
        attention.allocateAttention("investigator", @[entity.id], AttentionType.strain_alert, AttentionTrigger.strain_threshold)

# Agent Status Queries
proc getAgentAttention*(attention: AttentionSystem, agent_id: string): seq[string] =
  ## Get entities an agent is currently attending to
  return attention.agent_attention.getOrDefault(agent_id, @[])

proc getForegroundFocus*(attention: AttentionSystem): seq[string] =
  ## Get entities the foreground agent is currently examining
  return attention.foreground_focus

proc isAgentAttendingTo*(attention: AttentionSystem, agent_id: string, entity_id: string): bool =
  ## Check if an agent is attending to a specific entity
  let attention_entities = attention.getAgentAttention(agent_id)
  return entity_id in attention_entities

proc getAttentionHistory*(attention: AttentionSystem, agent_id: string = ""): seq[AttentionEvent] =
  ## Get attention history, optionally filtered by agent
  if agent_id == "":
    return attention.attention_history
  else:
    return attention.attention_history.filterIt(it.agent_id == agent_id)

# System State Management
proc updateSystemState*(attention: var AttentionSystem) =
  ## Update system state based on current conditions
  # System state is now controlled manually via UI, not automatically
  # This function is kept for compatibility but does not change state automatically
  discard

proc getSystemState*(attention: AttentionSystem): SystemState =
  ## Get current system state
  return attention.system_state 