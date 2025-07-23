# Agent Activity Monitor
#
# This module monitors agent activity in real-time and provides data
# for TinkerPop visualization of agent states and interactions.

import std/[times, tables, json, asyncdispatch, options, strutils]
import ../types
import registry
import attention_system
import orchestrator

type
  AgentActivity* = object
    ## Real-time agent activity data
    agent_id*: string
    agent_type*: AgentType
    is_active*: bool
    current_task*: Option[string]
    target_entities*: seq[string]
    strain_level*: float
    last_activity*: DateTime
    activity_duration*: float  # seconds
    ollama_calls*: int
    nodes_created*: int
    nodes_modified*: int

  AgentInteraction* = object
    ## Interaction between agents
    timestamp*: DateTime
    source_agent*: string
    target_agent*: string
    interaction_type*: string
    shared_entities*: seq[string]
    strain_flow*: float

  ActivityMonitor* = ref object
    ## Monitors agent activity for real-time visualization
    orchestrator*: AgentOrchestrator
    agent_activities*: Table[string, AgentActivity]
    interactions*: seq[AgentInteraction]
    activity_history*: seq[AgentActivity]
    update_callbacks*: seq[proc(activity: AgentActivity) {.gcsafe.}]
    interaction_callbacks*: seq[proc(interaction: AgentInteraction) {.gcsafe.}]
    monitoring_active*: bool
    update_interval*: float  # seconds

# Constructor
proc newActivityMonitor*(orchestrator: AgentOrchestrator): ActivityMonitor =
  result = ActivityMonitor(
    orchestrator: orchestrator,
    agent_activities: initTable[string, AgentActivity](),
    interactions: @[],
    activity_history: @[],
    update_callbacks: @[],
    interaction_callbacks: @[],
    monitoring_active: false,
    update_interval: 1.0  # 1 second updates
  )

# Activity tracking
proc updateAgentActivity*(monitor: ActivityMonitor, agent_id: string, 
                         is_active: bool, task: Option[string] = none(string),
                         entities: seq[string] = @[], strain: float = 0.0) =
  ## Update agent activity status
  let now_time = now()
  
  if agent_id notin monitor.agent_activities:
    # Initialize new agent activity
    let agent_type = if agent_id in monitor.orchestrator.registry.agents:
                       monitor.orchestrator.registry.agents[agent_id].agent_type
                     else:
                       AgentType.engineer
    
    monitor.agent_activities[agent_id] = AgentActivity(
      agent_id: agent_id,
      agent_type: agent_type,
      is_active: is_active,
      current_task: task,
      target_entities: entities,
      strain_level: strain,
      last_activity: now_time,
      activity_duration: 0.0,
      ollama_calls: 0,
      nodes_created: 0,
      nodes_modified: 0
    )
  else:
    # Update existing agent activity
    var activity = monitor.agent_activities[agent_id]
    let previous_active = activity.is_active
    
    activity.is_active = is_active
    activity.current_task = task
    activity.target_entities = entities
    activity.strain_level = strain
    
    if is_active and previous_active:
      # Continue active session
      activity.activity_duration = now_time.toTime().toUnixFloat() - activity.last_activity.toTime().toUnixFloat()
    elif is_active and not previous_active:
      # Start new active session
      activity.last_activity = now_time
      activity.activity_duration = 0.0
    
    monitor.agent_activities[agent_id] = activity
    
    # Trigger callbacks
    for callback in monitor.update_callbacks:
      callback(activity)

proc recordAgentInteraction*(monitor: ActivityMonitor, source_agent: string,
                            target_agent: string, interaction_type: string,
                            shared_entities: seq[string], strain_flow: float) {.gcsafe.} =
  ## Record interaction between agents
  let interaction = AgentInteraction(
    timestamp: now(),
    source_agent: source_agent,
    target_agent: target_agent,
    interaction_type: interaction_type,
    shared_entities: shared_entities,
    strain_flow: strain_flow
  )
  
  monitor.interactions.add(interaction)
  
  # Keep only last 1000 interactions
  if monitor.interactions.len > 1000:
    let start_idx = max(0, monitor.interactions.len - 500)
    monitor.interactions = monitor.interactions[start_idx..^1]
  
  # Trigger callbacks
  for callback in monitor.interaction_callbacks:
    callback(interaction)

# Real-time monitoring
proc startMonitoring*(monitor: ActivityMonitor) {.async, gcsafe.} =
  ## Start real-time activity monitoring
  monitor.monitoring_active = true
  
  while monitor.monitoring_active:
    # Update agent activities based on orchestrator state
    for agent_id, agent in monitor.orchestrator.registry.agents:
      let is_active = agent.state == AgentState.active
      let attention_entities = if agent_id in monitor.orchestrator.attention_system.agent_attention:
                                monitor.orchestrator.attention_system.agent_attention[agent_id]
                              else:
                                @[]
      
      let current_strain = if agent_id in monitor.orchestrator.registry.agents:
                            monitor.orchestrator.registry.agents[agent_id].current_strain
                          else:
                            0.0
      
      monitor.updateAgentActivity(agent_id, is_active, none(string), attention_entities, current_strain)
    
    # Check for agent interactions based on shared attention
    var agent_attention_map: Table[string, seq[string]] = initTable[string, seq[string]]()
    for agent_id, entities in monitor.orchestrator.attention_system.agent_attention:
      agent_attention_map[agent_id] = entities
    
    # Find overlapping attention (potential interactions)
    for agent1 in agent_attention_map.keys:
      for agent2 in agent_attention_map.keys:
        if agent1 < agent2:  # Avoid duplicate pairs
          let entities1 = agent_attention_map[agent1]
          let entities2 = agent_attention_map[agent2]
          
          # Find shared entities
          var shared: seq[string] = @[]
          for entity in entities1:
            if entity in entities2:
              shared.add(entity)
          
          if shared.len > 0:
            # Record interaction
            let strain_flow = float(shared.len) / float(max(entities1.len, entities2.len))
            monitor.recordAgentInteraction(agent1, agent2, "shared_attention", shared, strain_flow)
    
    await sleepAsync(int(monitor.update_interval * 1000))

proc stopMonitoring*(monitor: ActivityMonitor) =
  ## Stop real-time activity monitoring
  monitor.monitoring_active = false

# Data export for TinkerPop
proc getAgentActivityData*(monitor: ActivityMonitor): JsonNode =
  ## Export agent activity data for TinkerPop visualization
  var data = %*{
    "timestamp": $now(),
    "agents": {},
    "interactions": []
  }
  
  # Export agent activities
  for agent_id, activity in monitor.agent_activities:
    data["agents"][agent_id] = %*{
      "agent_type": $activity.agent_type,
      "is_active": activity.is_active,
      "current_task": if activity.current_task.isSome: activity.current_task.get else: "",
      "target_entities": activity.target_entities,
      "strain_level": activity.strain_level,
      "last_activity": $activity.last_activity,
      "activity_duration": activity.activity_duration,
      "ollama_calls": activity.ollama_calls,
      "nodes_created": activity.nodes_created,
      "nodes_modified": activity.nodes_modified
    }
  
  # Export recent interactions
  if monitor.interactions.len > 0:
    let start_idx = max(0, monitor.interactions.len - 50)
    for interaction in monitor.interactions[start_idx..^1]:  # Last 50 interactions
      data["interactions"].add(%*{
        "timestamp": $interaction.timestamp,
        "source_agent": interaction.source_agent,
        "target_agent": interaction.target_agent,
        "interaction_type": interaction.interaction_type,
        "shared_entities": interaction.shared_entities,
        "strain_flow": interaction.strain_flow
      })
  
  return data

# Callback registration
proc onActivityUpdate*(monitor: ActivityMonitor, callback: proc(activity: AgentActivity) {.gcsafe.}) =
  ## Register callback for activity updates
  monitor.update_callbacks.add(callback)

proc onInteraction*(monitor: ActivityMonitor, callback: proc(interaction: AgentInteraction) {.gcsafe.}) =
  ## Register callback for interaction events
  monitor.interaction_callbacks.add(callback) 