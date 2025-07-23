# Stage Manager Agent
#
# The Stage Manager agent coordinates other agents, manages system workflow,
# and orchestrates the overall knowledge graph operations. It acts as the
# central coordinator for the multi-agent system.

import std/[times, tables, options, json, strutils, math, sequtils, algorithm]
import ../../types
import ../../strain/math
import ../../strain/types  # Import musical frequency types
import ../../knowledge_graph/operations
import ../../api/types

const RUN_STAGE_MANAGER_TESTS* = true

type
  StageManagerAgent* = object
    ## The Stage Manager agent for coordinating other agents and system workflow
    agent_id*: string
    status*: AgentStatusType
    current_task*: Option[string]
    strain_level*: float
    authority_level*: float
    last_active*: DateTime
    active_agents*: Table[string, AgentStatus]  # Agent ID -> Status
    workflow_queue*: seq[WorkflowTask]          # Pending tasks
    coordination_rules*: seq[CoordinationRule]  # Agent coordination rules
    system_metrics*: Table[string, float]       # System performance metrics

  WorkflowTask* = object
    ## Task in the workflow queue
    task_id*: string
    task_type*: string  # "strain_calculation", "contradiction_check", "pattern_analysis", etc.
    priority*: TaskPriority
    assigned_agent*: Option[string]
    status*: TaskStatus
    created*: DateTime
    deadline*: Option[DateTime]
    parameters*: JsonNode
    result*: Option[JsonNode]

  CoordinationRule* = object
    ## Rule for coordinating agents
    rule_id*: string
    trigger_condition*: string
    target_agent*: string
    action*: string  # "activate", "deactivate", "prioritize"
    priority*: float
    enabled*: bool
    created*: DateTime

  TaskPriority* = enum
    ## Task priority levels
    low, normal, high, critical, emergency

  TaskStatus* = enum
    ## Task status
    pending, assigned, in_progress, completed, failed, cancelled

  SystemEvent* = object
    ## System event for coordination
    event_id*: string
    event_type*: string  # "agent_activation", "task_completion", "error", "strain_threshold", "frequency_adjustment"
    source_agent*: string
    target_agent*: Option[string]
    timestamp*: DateTime
    data*: JsonNode
    severity*: float

  MusicalFrequencyAssignment* = object
    ## Musical frequency assignment for an entity
    entity_id*: string
    current_note*: MusicalNote
    current_octave*: int
    suggested_note*: MusicalNote
    suggested_octave*: int
    reason*: string  # Why the change is suggested
    harmony_score*: float  # Current harmony with related entities
    created*: DateTime

  AgentCoordination* = object
    ## Agent coordination configuration
    coordination_id*: string
    primary_agent*: string
    secondary_agents*: seq[string]
    coordination_type*: string  # "sequential", "parallel", "conditional"
    conditions*: seq[string]
    created*: DateTime

# Constructor Functions
proc newStageManagerAgent*(agent_id: string = "stage_manager"): StageManagerAgent =
  ## Create a new Stage Manager agent
  return StageManagerAgent(
    agent_id: agent_id,
    status: AgentStatusType.idle,
    current_task: none(string),
    strain_level: 0.0,
    authority_level: 0.9,
    last_active: now(),
    active_agents: initTable[string, AgentStatus](),
    workflow_queue: @[],
    coordination_rules: @[],
    system_metrics: initTable[string, float]()
  )

proc newWorkflowTask*(task_id: string, task_type: string, priority: TaskPriority): WorkflowTask =
  ## Create a new workflow task
  return WorkflowTask(
    task_id: task_id,
    task_type: task_type,
    priority: priority,
    assigned_agent: none(string),
    status: TaskStatus.pending,
    created: now(),
    deadline: none(DateTime),
    parameters: newJObject(),
    result: none(JsonNode)
  )

proc newCoordinationRule*(rule_id: string, trigger: string, target: string, action: string): CoordinationRule =
  ## Create a new coordination rule
  return CoordinationRule(
    rule_id: rule_id,
    trigger_condition: trigger,
    target_agent: target,
    action: action,
    priority: 0.5,
    enabled: true,
    created: now()
  )

proc newSystemEvent*(event_id: string, event_type: string, source_agent: string): SystemEvent =
  ## Create a new system event
  return SystemEvent(
    event_id: event_id,
    event_type: event_type,
    source_agent: source_agent,
    target_agent: none(string),
    timestamp: now(),
    data: newJObject(),
    severity: 0.5
  )

proc newAgentCoordination*(coordination_id: string, primary_agent: string, coordination_type: string): AgentCoordination =
  ## Create a new agent coordination
  return AgentCoordination(
    coordination_id: coordination_id,
    primary_agent: primary_agent,
    secondary_agents: @[],
    coordination_type: coordination_type,
    conditions: @[],
    created: now()
  )

# Core Stage Manager Operations
proc registerAgent*(agent: var StageManagerAgent, agent_status: AgentStatus) =
  ## Register an agent with the stage manager
  agent.last_active = now()
  agent.current_task = some("agent_registration")
  
  agent.active_agents[agent_status.agent_id] = agent_status
  
  # Update system metrics
  agent.system_metrics["total_agents"] = agent.active_agents.len.float
  agent.system_metrics["active_agents"] = agent.active_agents.values.toSeq.filterIt(it.status == AgentStatusType.active).len.float
  
  agent.current_task = none(string)
  agent.strain_level = min(agent.strain_level + 0.02, 1.0)

proc unregisterAgent*(agent: var StageManagerAgent, agent_id: string) =
  ## Unregister an agent from the stage manager
  agent.last_active = now()
  agent.current_task = some("agent_unregistration")
  
  if agent.active_agents.hasKey(agent_id):
    agent.active_agents.del(agent_id)
    
    # Update system metrics
    agent.system_metrics["total_agents"] = agent.active_agents.len.float
    agent.system_metrics["active_agents"] = agent.active_agents.values.toSeq.filterIt(it.status == AgentStatusType.active).len.float
  
  agent.current_task = none(string)
  agent.strain_level = min(agent.strain_level + 0.02, 1.0)

proc addWorkflowTask*(agent: var StageManagerAgent, task: WorkflowTask) =
  ## Add a task to the workflow queue
  agent.last_active = now()
  agent.current_task = some("task_addition")
  
  agent.workflow_queue.add(task)
  
  # Sort queue by priority
  sort(agent.workflow_queue, proc(a, b: WorkflowTask): int =
    if a.priority > b.priority: return -1
    elif a.priority < b.priority: return 1
    else: return 0
  )
  
  # Update system metrics
  agent.system_metrics["pending_tasks"] = agent.workflow_queue.filterIt(it.status == TaskStatus.pending).len.float
  agent.system_metrics["total_tasks"] = agent.workflow_queue.len.float
  
  agent.current_task = none(string)
  agent.strain_level = min(agent.strain_level + 0.03, 1.0)

proc assignTaskToAgent*(agent: var StageManagerAgent, task_id: string, agent_id: string): bool =
  ## Assign a task to a specific agent
  agent.last_active = now()
  agent.current_task = some("task_assignment")
  
  for i, task in agent.workflow_queue:
    if task.task_id == task_id and task.status == TaskStatus.pending:
      agent.workflow_queue[i].assigned_agent = some(agent_id)
      agent.workflow_queue[i].status = TaskStatus.assigned
      
      # Update system metrics
      agent.system_metrics["assigned_tasks"] = agent.workflow_queue.filterIt(it.status == TaskStatus.assigned).len.float
      agent.system_metrics["pending_tasks"] = agent.workflow_queue.filterIt(it.status == TaskStatus.pending).len.float
      
      agent.current_task = none(string)
      agent.strain_level = min(agent.strain_level + 0.05, 1.0)
      return true
  
  agent.current_task = none(string)
  agent.strain_level = min(agent.strain_level + 0.02, 1.0)
  return false

proc completeTask*(agent: var StageManagerAgent, task_id: string, result: JsonNode) =
  ## Mark a task as completed with results
  agent.last_active = now()
  agent.current_task = some("task_completion")
  
  for i, task in agent.workflow_queue:
    if task.task_id == task_id:
      agent.workflow_queue[i].status = TaskStatus.completed
      agent.workflow_queue[i].result = some(result)
      
      # Update system metrics
      agent.system_metrics["completed_tasks"] = agent.workflow_queue.filterIt(it.status == TaskStatus.completed).len.float
      agent.system_metrics["assigned_tasks"] = agent.workflow_queue.filterIt(it.status == TaskStatus.assigned).len.float
      
      break
  
  agent.current_task = none(string)
  agent.strain_level = min(agent.strain_level + 0.05, 1.0)

proc evaluateCoordinationRules*(agent: var StageManagerAgent, event: SystemEvent) =
  ## Evaluate coordination rules based on system events
  agent.last_active = now()
  agent.current_task = some("rule_evaluation")
  
  for rule in agent.coordination_rules:
    if not rule.enabled:
      continue
    
    # Simple rule evaluation based on event type
    if rule.trigger_condition == event.event_type:
      case rule.action
      of "activate":
        if agent.active_agents.hasKey(rule.target_agent):
          var agent_status = agent.active_agents[rule.target_agent]
          agent_status.status = AgentStatusType.active
          agent.active_agents[rule.target_agent] = agent_status
      
      of "deactivate":
        if agent.active_agents.hasKey(rule.target_agent):
          var agent_status = agent.active_agents[rule.target_agent]
          agent_status.status = AgentStatusType.idle
          agent.active_agents[rule.target_agent] = agent_status
      
      of "prioritize":
        # Increase priority of tasks for this agent
        for i, task in agent.workflow_queue:
          if task.assigned_agent.isSome and task.assigned_agent.get == rule.target_agent:
            if task.priority < TaskPriority.critical:
              agent.workflow_queue[i].priority = TaskPriority(int(task.priority) + 1)
      
      else:
        discard
  
  agent.current_task = none(string)
  agent.strain_level = min(agent.strain_level + 0.03, 1.0)

proc getSystemStatus*(agent: var StageManagerAgent): JsonNode =
  ## Get comprehensive system status
  agent.last_active = now()
  agent.current_task = some("status_reporting")
  
  var status = %*{
    "timestamp": $now(),
    "agent_id": agent.agent_id,
    "system_health": {
      "total_agents": agent.active_agents.len,
      "active_agents": agent.active_agents.values.toSeq.filterIt(it.status == AgentStatusType.active).len,
      "total_tasks": agent.workflow_queue.len,
      "pending_tasks": agent.workflow_queue.filterIt(it.status == TaskStatus.pending).len,
      "completed_tasks": agent.workflow_queue.filterIt(it.status == TaskStatus.completed).len,
      "failed_tasks": agent.workflow_queue.filterIt(it.status == TaskStatus.failed).len
    },
    "agent_statuses": [],
    "workflow_summary": {
      "high_priority_tasks": agent.workflow_queue.filterIt(it.priority >= TaskPriority.high).len,
      "critical_tasks": agent.workflow_queue.filterIt(it.priority == TaskPriority.critical).len,
      "emergency_tasks": agent.workflow_queue.filterIt(it.priority == TaskPriority.emergency).len
    },
    "system_metrics": agent.system_metrics
  }
  
  # Add agent statuses
  for agent_status in agent.active_agents.values:
    status["agent_statuses"].add(%*{
      "agent_id": agent_status.agent_id,
      "agent_type": agent_status.agent_type,
      "status": $agent_status.status,
      "strain_level": agent_status.strain_level,
      "authority_level": agent_status.authority_level,
      "last_active": $agent_status.last_active
    })
  
  agent.current_task = none(string)
  agent.strain_level = min(agent.strain_level + 0.1, 1.0)
  
  return status

proc optimizeWorkflow*(agent: var StageManagerAgent) =
  ## Optimize the workflow queue and agent assignments
  agent.last_active = now()
  agent.current_task = some("workflow_optimization")
  
  # Reassign tasks based on agent availability and strain levels
  for i, task in agent.workflow_queue:
    if task.status == TaskStatus.pending:
      # Find the best available agent
      var best_agent: Option[string]
      var best_score = 0.0
      
      for agent_id, agent_status in agent.active_agents:
        if agent_status.status == AgentStatusType.active:
          # Calculate agent score based on strain level and authority
          let score = agent_status.authority_level * (1.0 - agent_status.strain_level)
          if score > best_score:
            best_score = score
            best_agent = some(agent_id)
      
      if best_agent.isSome:
        agent.workflow_queue[i].assigned_agent = best_agent
        agent.workflow_queue[i].status = TaskStatus.assigned
  
  # Update metrics
  agent.system_metrics["optimized_tasks"] = agent.workflow_queue.filterIt(it.status == TaskStatus.assigned).len.float
  
  agent.current_task = none(string)
  agent.strain_level = min(agent.strain_level + 0.08, 1.0)

proc adjustMusicalFrequency*(agent: var StageManagerAgent, entity_id: string, 
                           related_entities: seq[string], 
                           existing_assignments: Table[string, MusicalFrequency]): MusicalFrequencyAssignment =
  ## Adjust musical frequency assignment for an entity to form pleasant chords
  ##
  ## Parameters:
  ## - entity_id: ID of entity to adjust frequency for
  ## - related_entities: IDs of related entities
  ## - existing_assignments: Current musical frequency assignments
  ##
  ## Returns: MusicalFrequencyAssignment with suggested changes
  agent.last_active = now()
  agent.current_task = some("frequency_adjustment")
  
  # Get current assignment if it exists
  var current_note = C
  var current_octave = 4
  
  if existing_assignments.hasKey(entity_id):
    let current_assignment = existing_assignments[entity_id]
    current_note = current_assignment.note
    current_octave = current_assignment.octave
  
  # Find related entities' frequencies
  var related_frequencies: seq[MusicalFrequency]
  for related_id in related_entities:
    if existing_assignments.hasKey(related_id):
      related_frequencies.add(existing_assignments[related_id])
  
  # Calculate current harmony score
  let current_harmony = calculateChordHarmony(related_frequencies)
  
  # Try different notes to find the most harmonious combination
  var best_note = current_note
  var best_octave = current_octave
  var best_harmony = current_harmony
  var best_reason = "no change needed"
  
  for note in MusicalNote.low..MusicalNote.high:
    for octave in 2..6:  # Reasonable octave range
      # Create test frequency
      let test_frequency = MusicalFrequency(
        note: note,
        octave: octave,
        frequency_hz: NOTE_FREQUENCIES[note] * pow(2.0, float(octave - 4)),
        chord_membership: @[]
      )
      
      # Test harmony with related frequencies
      var test_frequencies = related_frequencies
      test_frequencies.add(test_frequency)
      let test_harmony = calculateChordHarmony(test_frequencies)
      
      if test_harmony > best_harmony:
        best_harmony = test_harmony
        best_note = note
        best_octave = octave
        best_reason = "improved harmony with related entities"
  
  # Create assignment suggestion
  let assignment = MusicalFrequencyAssignment(
    entity_id: entity_id,
    current_note: current_note,
    current_octave: current_octave,
    suggested_note: best_note,
    suggested_octave: best_octave,
    reason: best_reason,
    harmony_score: best_harmony,
    created: now()
  )
  
  # Update system metrics
  agent.system_metrics["frequency_adjustments"] = agent.system_metrics.getOrDefault("frequency_adjustments", 0.0) + 1.0
  agent.system_metrics["average_harmony_score"] = (agent.system_metrics.getOrDefault("average_harmony_score", 0.0) + best_harmony) / 2.0
  
  agent.current_task = none(string)
  agent.strain_level = min(agent.strain_level + 0.05, 1.0)
  
  return assignment

proc optimizeChordFormation*(agent: var StageManagerAgent, entity_groups: seq[seq[string]], 
                           existing_assignments: Table[string, MusicalFrequency]): seq[MusicalFrequencyAssignment] =
  ## Optimize chord formation for groups of related entities
  ##
  ## Parameters:
  ## - entity_groups: Groups of related entity IDs
  ## - existing_assignments: Current musical frequency assignments
  ##
  ## Returns: Sequence of frequency assignment suggestions
  agent.last_active = now()
  agent.current_task = some("chord_optimization")
  
  var assignments: seq[MusicalFrequencyAssignment]
  
  for group in entity_groups:
    if group.len < 2:
      continue  # Need at least 2 entities to form a chord
    
    # Try different chord types for this group
    var best_chord_type = major
    var best_harmony = 0.0
    var best_assignments: seq[MusicalFrequencyAssignment]
    
    for chord_type in MusicalChord.low..MusicalChord.high:
      let chord_intervals = PLEASANT_CHORDS[chord_type]
      
      # Assign notes based on chord intervals
      var test_assignments: seq[MusicalFrequencyAssignment]
      var test_frequencies: seq[MusicalFrequency]
      
      for i, entity_id in group:
        if i < chord_intervals.len:
          let note_index = chord_intervals[i]
          let note = case note_index
            of 0: C
            of 1: C_sharp
            of 2: D
            of 3: D_sharp
            of 4: E
            of 5: F
            of 6: F_sharp
            of 7: G
            of 8: G_sharp
            of 9: A
            of 10: A_sharp
            of 11: B
            else: C
          
          let octave = 4  # Middle octave
          let frequency = MusicalFrequency(
            note: note,
            octave: octave,
            frequency_hz: NOTE_FREQUENCIES[note],
            chord_membership: group
          )
          
          test_frequencies.add(frequency)
          
          # Create assignment suggestion
          let current_note = if existing_assignments.hasKey(entity_id): existing_assignments[entity_id].note else: C
          let current_octave = if existing_assignments.hasKey(entity_id): existing_assignments[entity_id].octave else: 4
          
          let assignment = MusicalFrequencyAssignment(
            entity_id: entity_id,
            current_note: current_note,
            current_octave: current_octave,
            suggested_note: note,
            suggested_octave: octave,
            reason: "chord formation: " & $chord_type,
            harmony_score: 0.0,  # Will be calculated below
            created: now()
          )
          
          test_assignments.add(assignment)
      
      # Calculate harmony for this chord
      let harmony = calculateChordHarmony(test_frequencies)
      
      if harmony > best_harmony:
        best_harmony = harmony
        best_chord_type = chord_type
        best_assignments = test_assignments
    
    # Update harmony scores for best assignments
    for i in 0..<best_assignments.len:
      best_assignments[i].harmony_score = best_harmony
    
    assignments.add(best_assignments)
  
  # Update system metrics
  agent.system_metrics["chord_optimizations"] = agent.system_metrics.getOrDefault("chord_optimizations", 0.0) + 1.0
  
  agent.current_task = none(string)
  agent.strain_level = min(agent.strain_level + 0.1, 1.0)
  
  return assignments

proc getCurrentlyPlayingNotes*(agent: var StageManagerAgent, active_entities: seq[string], 
                             existing_assignments: Table[string, MusicalFrequency]): seq[MusicalFrequency] =
  ## Get musical frequencies for currently accessed entities
  ##
  ## Parameters:
  ## - active_entities: IDs of entities currently being accessed
  ## - existing_assignments: Current musical frequency assignments
  ##
  ## Returns: Musical frequencies for currently playing notes
  agent.last_active = now()
  agent.current_task = some("note_retrieval")
  
  var playing_notes: seq[MusicalFrequency]
  
  for entity_id in active_entities:
    if existing_assignments.hasKey(entity_id):
      playing_notes.add(existing_assignments[entity_id])
  
  # Update system metrics
  agent.system_metrics["currently_playing_notes"] = playing_notes.len.float
  
  agent.current_task = none(string)
  agent.strain_level = min(agent.strain_level + 0.02, 1.0)
  
  return playing_notes

proc handleSystemEvent*(agent: var StageManagerAgent, event: SystemEvent) =
  ## Handle system events and coordinate responses
  agent.last_active = now()
  agent.current_task = some("event_handling")
  
  # Evaluate coordination rules
  agent.evaluateCoordinationRules(event)
  
  # Handle specific event types
  case event.event_type
  of "agent_activation":
    # Agent was activated
    agent.system_metrics["agent_activations"] = agent.system_metrics.getOrDefault("agent_activations", 0.0) + 1.0
  
  of "task_completion":
    # Task was completed
    agent.system_metrics["task_completions"] = agent.system_metrics.getOrDefault("task_completions", 0.0) + 1.0
  
  of "error":
    # System error occurred
    agent.system_metrics["errors"] = agent.system_metrics.getOrDefault("errors", 0.0) + 1.0
    
    # Activate error handling agents if available
    if agent.active_agents.hasKey("skeptic"):
      var skeptic_status = agent.active_agents["skeptic"]
      skeptic_status.status = AgentStatusType.active
      agent.active_agents["skeptic"] = skeptic_status
  
  of "strain_threshold":
    # Strain threshold exceeded
    let strain_value = event.data.getOrDefault("strain_level").getFloat
    if strain_value > 0.8:
      # High strain - activate stress management
      agent.system_metrics["high_strain_events"] = agent.system_metrics.getOrDefault("high_strain_events", 0.0) + 1.0
  
  else:
    # Unknown event type
    agent.system_metrics["unknown_events"] = agent.system_metrics.getOrDefault("unknown_events", 0.0) + 1.0
  
  agent.current_task = none(string)
  agent.strain_level = min(agent.strain_level + 0.05, 1.0)

# Agent Status Management
proc activate*(agent: var StageManagerAgent) =
  ## Activate the Stage Manager agent
  agent.status = AgentStatusType.active
  agent.last_active = now()
  agent.strain_level = 0.0

proc deactivate*(agent: var StageManagerAgent) =
  ## Deactivate the Stage Manager agent
  agent.status = AgentStatusType.idle
  agent.current_task = none(string)
  agent.strain_level = 0.0

proc isActive*(agent: StageManagerAgent): bool =
  ## Check if the agent is active
  return agent.status == AgentStatusType.active

proc getStatus*(agent: StageManagerAgent): AgentStatus =
  ## Get the current status of the agent
  return AgentStatus(
    agent_id: agent.agent_id,
    agent_type: "stage_manager",
    status: agent.status,
    last_active: agent.last_active,
    current_task: agent.current_task,
    strain_level: agent.strain_level,
    authority_level: agent.authority_level
  )

when RUN_STAGE_MANAGER_TESTS:
  import std/unittest
  
  suite "Stage Manager Agent Tests":
    test "Agent Creation and Status":
      var agent = newStageManagerAgent("test_stage_manager")
      check agent.agent_id == "test_stage_manager"
      check agent.status == AgentStatusType.idle
      check agent.authority_level == 0.9
      check agent.strain_level == 0.0
      check agent.active_agents.len == 0
      check agent.workflow_queue.len == 0
      
      agent.activate()
      check agent.status == AgentStatusType.active
      check agent.isActive == true
      
      agent.deactivate()
      check agent.status == AgentStatusType.idle
      check agent.isActive == false
    
    test "Agent Registration":
      var agent = newStageManagerAgent()
      agent.activate()
      
      var agent_status = AgentStatus(
        agent_id: "test_agent",
        agent_type: "test",
        status: AgentStatusType.active,
        last_active: now(),
        current_task: none(string),
        strain_level: 0.5,
        authority_level: 0.7
      )
      
      agent.registerAgent(agent_status)
      check agent.active_agents.len == 1
      check agent.active_agents.hasKey("test_agent")
      check agent.system_metrics["total_agents"] == 1.0
      check agent.system_metrics["active_agents"] == 1.0
      
      agent.unregisterAgent("test_agent")
      check agent.active_agents.len == 0
      check agent.system_metrics["total_agents"] == 0.0
    
    test "Workflow Task Management":
      var agent = newStageManagerAgent()
      agent.activate()
      
      let task = newWorkflowTask("task_1", "strain_calculation", TaskPriority.high)
      agent.addWorkflowTask(task)
      
      check agent.workflow_queue.len == 1
      check agent.workflow_queue[0].task_id == "task_1"
      check agent.workflow_queue[0].status == TaskStatus.pending
      check agent.system_metrics["pending_tasks"] == 1.0
      
      # Register an agent and assign task
      var agent_status = AgentStatus(
        agent_id: "mathematician",
        agent_type: "mathematician",
        status: AgentStatusType.active,
        last_active: now(),
        current_task: none(string),
        strain_level: 0.0,
        authority_level: 0.8
      )
      agent.registerAgent(agent_status)
      
      let assigned = agent.assignTaskToAgent("task_1", "mathematician")
      check assigned == true
      check agent.workflow_queue[0].status == TaskStatus.assigned
      check agent.workflow_queue[0].assigned_agent.get == "mathematician"
      
      # Complete the task
      let result = %*{"amplitude": 0.75, "confidence": 0.8}
      agent.completeTask("task_1", result)
      check agent.workflow_queue[0].status == TaskStatus.completed
      check agent.workflow_queue[0].result.isSome
    
    test "Coordination Rules":
      var agent = newStageManagerAgent()
      agent.activate()
      
      # Add a coordination rule
      let rule = newCoordinationRule("rule_1", "high_strain", "skeptic", "activate")
      agent.coordination_rules.add(rule)
      
      # Register the target agent
      var skeptic_status = AgentStatus(
        agent_id: "skeptic",
        agent_type: "skeptic",
        status: AgentStatusType.idle,
        last_active: now(),
        current_task: none(string),
        strain_level: 0.0,
        authority_level: 0.7
      )
      agent.registerAgent(skeptic_status)
      
      # Create and handle a system event
      var event = newSystemEvent("event_1", "high_strain", "mathematician")
      event.data = %*{"strain_level": 0.9}
      
      agent.handleSystemEvent(event)
      check agent.active_agents["skeptic"].status == AgentStatusType.active
    
    test "System Status Report":
      var agent = newStageManagerAgent()
      agent.activate()
      
      # Add some test data
      var agent_status = AgentStatus(
        agent_id: "test_agent",
        agent_type: "test",
        status: AgentStatusType.active,
        last_active: now(),
        current_task: none(string),
        strain_level: 0.5,
        authority_level: 0.7
      )
      agent.registerAgent(agent_status)
      
      let task = newWorkflowTask("task_1", "test_task", TaskPriority.normal)
      agent.addWorkflowTask(task)
      
      let status = agent.getSystemStatus()
      check status.hasKey("system_health")
      check status.hasKey("agent_statuses")
      check status.hasKey("workflow_summary")
      check status["system_health"]["total_agents"].getInt == 1
      check status["system_health"]["total_tasks"].getInt == 1
    
    test "Workflow Optimization":
      var agent = newStageManagerAgent()
      agent.activate()
      
      # Add multiple agents with different strain levels
      var agent1_status = AgentStatus(
        agent_id: "agent1",
        agent_type: "test",
        status: AgentStatusType.active,
        last_active: now(),
        current_task: none(string),
        strain_level: 0.2,  # Low strain
        authority_level: 0.8
      )
      
      var agent2_status = AgentStatus(
        agent_id: "agent2",
        agent_type: "test",
        status: AgentStatusType.active,
        last_active: now(),
        current_task: none(string),
        strain_level: 0.8,  # High strain
        authority_level: 0.6
      )
      
      agent.registerAgent(agent1_status)
      agent.registerAgent(agent2_status)
      
      # Add pending tasks
      let task1 = newWorkflowTask("task_1", "test_task", TaskPriority.normal)
      let task2 = newWorkflowTask("task_2", "test_task", TaskPriority.high)
      agent.addWorkflowTask(task1)
      agent.addWorkflowTask(task2)
      
      # Optimize workflow
      agent.optimizeWorkflow()
      
      # Check that tasks were assigned to the agent with lower strain
      var assigned_to_agent1 = 0
      for task in agent.workflow_queue:
        if task.assigned_agent.isSome and task.assigned_agent.get == "agent1":
          assigned_to_agent1 += 1
      
      check assigned_to_agent1 > 0  # At least one task should be assigned to agent1
      check agent.system_metrics["optimized_tasks"] > 0.0 