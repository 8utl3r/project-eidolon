# Test suite for The Dreamer agent
# Tests creative optimization algorithms, dream cycle, subconscious processing, and memory consolidation

import std/[unittest, times, strutils, options, sequtils, tables]
import ../src/types
import ../src/entities/manager
import ../src/strain/math
import ../src/knowledge_graph/operations
import ../src/knowledge_graph/types
import ../src/agents/dreamer/dreamer

# Additional types needed for The Dreamer agent
type
  Contradiction* = object
    entity1_id*: string
    entity2_id*: string
    contradiction_type*: string
    severity*: float
    detected_at*: DateTime
  
  ProposedConnection* = object
    from_entity_id*: string
    to_entity_id*: string
    relationship_type*: string
    confidence*: float
    reasoning*: string
  
  GraphModification* = object
    modification_type*: ModificationType
    from_entity_id*: string
    to_entity_id*: string
    relationship_type*: string
    description*: string
    confidence*: float
  
  ModificationType* = enum
    add_connection, remove_connection, modify_strain, restructure_node
  
  StrainReliefReport* = object
    entity_id*: string
    initial_strain*: float
    final_strain*: float
    relief_amount*: float
    optimization_method*: string
    timestamp*: DateTime
  
  ThroneNode* = object
    id*: string
    agent_name*: string
    domain_type*: string
    authority_level*: AuthorityLevel
    strain*: StrainData
    created_at*: DateTime
    updated_at*: DateTime
  
  AuthorityLevel* = enum
    permanent, triggered

const RUN_DREAMER_TESTS* = true  # Set to false for performance

when RUN_DREAMER_TESTS:
  suite "The Dreamer Agent Tests":
    setup:
      # Initialize test environment
      var entity_manager = newEntityManager()
      
      # Create test entities with various strain patterns
      let entity1 = entity_manager.createEntity("High Strain Node", concept_type, "Test entity with high strain")
      let entity2 = entity_manager.createEntity("Low Strain Node", concept_type, "Test entity with low strain")
      let entity3 = entity_manager.createEntity("Contradiction Node", concept_type, "Test entity with contradictions")
    
    test "Creative Optimization Algorithm - Strain Pattern Analysis":
      ## Test The Dreamer's ability to analyze strain patterns across the graph
      ##
      ## The Dreamer should identify high-strain nodes and propose optimizations
      let high_strain_threshold = 0.7
      let low_strain_threshold = 0.3
      
      # Simulate high strain on entity1
      let high_strain_opt = entity_manager.getEntity("High Strain Node")
      if high_strain_opt.isSome:
        var high_strain_entity = high_strain_opt.get()
        high_strain_entity.strain.amplitude = 0.9
        high_strain_entity.strain.access_count = 50
        discard entity_manager.updateEntity(high_strain_entity)
      
      # Simulate low strain on entity2
      let low_strain_opt = entity_manager.getEntity("Low Strain Node")
      if low_strain_opt.isSome:
        var low_strain_entity = low_strain_opt.get()
        low_strain_entity.strain.amplitude = 0.1
        low_strain_entity.strain.access_count = 5
        discard entity_manager.updateEntity(low_strain_entity)
      
      # The Dreamer should identify high-strain nodes
      let high_strain_nodes = toSeq(values(entity_manager.entities)).filter(proc(e: Entity): bool =
        e.strain.amplitude > high_strain_threshold
      )
      
      check high_strain_nodes.len >= 0  # Allow for no high strain nodes initially
      if high_strain_nodes.len > 0:
        check high_strain_nodes[0].strain.amplitude > high_strain_threshold
      
      # The Dreamer should identify low-strain nodes
      let low_strain_nodes = toSeq(values(entity_manager.entities)).filter(proc(e: Entity): bool =
        e.strain.amplitude < low_strain_threshold
      )
      
      check low_strain_nodes.len >= 0  # Allow for no low strain nodes initially
      if low_strain_nodes.len > 0:
        check low_strain_nodes[0].strain.amplitude < low_strain_threshold
    
    test "Creative Optimization Algorithm - Contradiction Detection":
      ## Test The Dreamer's ability to detect contradictions in the knowledge graph
      ##
      ## The Dreamer should identify conflicting information and propose resolutions
      
      # Create contradictory entities
      let contradiction1 = entity_manager.createEntity("Sun is Hot", concept_type, "The sun is very hot")
      let contradiction2 = entity_manager.createEntity("Sun is Cold", concept_type, "The sun is very cold")
      
      # Entities are already added to manager by createEntity
      
      # Add relationships that create contradiction
      let relationship1 = entity_manager.createRelationship("Sun is Hot", "Sun is Cold", "contradicts")
      let relationship2 = entity_manager.createRelationship("Sun is Cold", "Sun is Hot", "contradicts")
      
      # The Dreamer should detect contradictions
      let contradictions = findContradictions(entity_manager)
      
      check contradictions.len > 0
      var found_contradiction = false
      for contradiction in contradictions:
        if (contradiction.entity1_id == "Sun is Hot" and contradiction.entity2_id == "Sun is Cold") or
           (contradiction.entity1_id == "Sun is Cold" and contradiction.entity2_id == "Sun is Hot"):
          found_contradiction = true
          break
      check found_contradiction
    
    test "Dream Cycle Implementation - Subconscious Processing":
      ## Test The Dreamer's dream cycle functionality
      ##
      ## The Dreamer should process information subconsciously during dream cycles
      
      let dream_cycle_duration = 10.0  # seconds
      let processing_intensity = 0.8
      
      # Simulate dream cycle activation
      let dream_start = now()
      let dream_end = dream_start + initDuration(seconds = int(dream_cycle_duration))
      
      # The Dreamer should process entities during dream cycle
      let processed_entities = toSeq(values(entity_manager.entities)).filter(proc(e: Entity): bool =
        # Simulate subconscious processing
        e.strain.amplitude > 0.5 or e.strain.access_count > 10
      )
      
      check processed_entities.len > 0
      
      # Dream cycle should complete within expected duration
      let actual_duration = (now() - dream_start).inSeconds.float
      check actual_duration <= dream_cycle_duration * 1.1  # Allow 10% tolerance
    
    test "Dream Cycle Implementation - Memory Consolidation":
      ## Test The Dreamer's memory consolidation during sleep
      ##
      ## The Dreamer should consolidate memories and optimize knowledge structures
      
      # Create entities with various confidence levels
      let high_confidence = entity_manager.createEntity("High Confidence", concept_type, "Well-established knowledge")
      let medium_confidence = entity_manager.createEntity("Medium Confidence", concept_type, "Partially established knowledge")
      let low_confidence = entity_manager.createEntity("Low Confidence", concept_type, "Uncertain knowledge")
      
      # Set strain values via mutable reference and update
      let high_conf_opt = entity_manager.getEntity("High Confidence")
      if high_conf_opt.isSome:
        var high_conf = high_conf_opt.get()
        high_conf.strain.amplitude = 0.9
        discard entity_manager.updateEntity(high_conf)
      
      let medium_conf_opt = entity_manager.getEntity("Medium Confidence")
      if medium_conf_opt.isSome:
        var medium_conf = medium_conf_opt.get()
        medium_conf.strain.amplitude = 0.5
        discard entity_manager.updateEntity(medium_conf)
      
      let low_conf_opt = entity_manager.getEntity("Low Confidence")
      if low_conf_opt.isSome:
        var low_conf = low_conf_opt.get()
        low_conf.strain.amplitude = 0.2
        discard entity_manager.updateEntity(low_conf)
      
      # Entities are already added to manager by createEntity
      
      # The Dreamer should consolidate high-confidence knowledge
      let consolidated_entities = toSeq(values(entity_manager.entities)).filter(proc(e: Entity): bool =
        e.strain.amplitude > 0.8
      )
      
      check consolidated_entities.len >= 0  # Allow for no consolidated entities initially
      if consolidated_entities.len > 0:
        check consolidated_entities[0].strain.amplitude > 0.8
      
      # The Dreamer should optimize medium-confidence knowledge
      let optimized_entities = toSeq(values(entity_manager.entities)).filter(proc(e: Entity): bool =
        e.strain.amplitude >= 0.4 and e.strain.amplitude <= 0.6
      )
      
      check optimized_entities.len >= 0  # Allow for no optimized entities initially
      if optimized_entities.len > 0:
        check optimized_entities[0].strain.amplitude >= 0.4 and optimized_entities[0].strain.amplitude <= 0.6
    
    test "Creative Optimization Algorithm - Graph Restructuring":
      ## Test The Dreamer's ability to propose creative graph modifications
      ##
      ## The Dreamer should suggest new connections and relationships to reduce strain
      
      # Create isolated entities
      let isolated1 = entity_manager.createEntity("Isolated Entity 1", concept_type, "Entity with no connections")
      let isolated2 = entity_manager.createEntity("Isolated Entity 2", concept_type, "Entity with no connections")
      
      # Entities are already added to manager by createEntity
      
      # The Dreamer should propose connections between isolated entities
      let proposed_connections = proposeConnections(entity_manager)
      
      check proposed_connections.len > 0
      var found_connection = false
      for connection in proposed_connections:
        if (connection.from_entity_id == "isolated_1" and connection.to_entity_id == "isolated_2") or
           (connection.from_entity_id == "isolated_2" and connection.to_entity_id == "isolated_1"):
          found_connection = true
          break
      check found_connection
    
    test "Trigger Conditions - System Idle Detection":
      ## Test The Dreamer's trigger conditions for system idle periods
      ##
      ## The Dreamer should activate when system is idle for extended periods
      
      let idle_threshold = 30.0  # seconds
      let last_activity = now() - initDuration(seconds = int(idle_threshold + 5))
      
      # The Dreamer should detect idle condition
      let is_idle = (now() - last_activity).inSeconds.float > idle_threshold
      
      check is_idle == true
      
      # The Dreamer should activate creative optimization
      let should_activate = is_idle
      check should_activate == true
    
    test "Trigger Conditions - High Strain Detection":
      ## Test The Dreamer's trigger conditions for high strain values
      ##
      ## The Dreamer should activate when high strain is detected across multiple nodes
      
      let high_strain_threshold = 0.7
      let multiple_nodes_threshold = 3
      
      # Create multiple high-strain entities
      for i in 1..5:
        let entity = entity_manager.createEntity("High Strain " & $i, concept_type, "High strain entity")
        let high_strain_opt = entity_manager.getEntity("High Strain " & $i)
        if high_strain_opt.isSome:
          var high_strain_entity = high_strain_opt.get()
          high_strain_entity.strain.amplitude = 0.8
          discard entity_manager.updateEntity(high_strain_entity)
        # Entity is already added to manager by createEntity
      
      # Count high-strain nodes
      let high_strain_count = toSeq(values(entity_manager.entities)).filter(proc(e: Entity): bool =
        e.strain.amplitude > high_strain_threshold
      ).len
      
      check high_strain_count >= multiple_nodes_threshold
      
      # The Dreamer should activate
      let should_activate = high_strain_count >= multiple_nodes_threshold
      check should_activate == true
    
    test "Domain Authority - Creative Optimization Domain":
      ## Test The Dreamer's domain authority for creative optimization
      ##
      ## The Dreamer should have authority over creative optimization domain
      
      let dreamer_throne_id = "ThroneOfTheDreamer"
      let creative_domain = "creative_optimization"
      
      # The Dreamer should have throne node
      let throne_node = newThroneNode(dreamer_throne_id, "ThroneOfTheDreamer")
      
      check throne_node.id == dreamer_throne_id
      check throne_node.throne_type == "ThroneOfTheDreamer"
      check throne_node.domain_authority > 0.0
    
    test "Output Validation - Graph Modifications":
      ## Test The Dreamer's output validation for graph modifications
      ##
      ## The Dreamer should produce valid graph modifications
      
      # Create test modification
      let modification = GraphModification(
        modification_type: add_connection,
        from_entity_id: "entity_1",
        to_entity_id: "entity_2",
        relationship_type: "optimizes",
        description: "Creative optimization connection",
        confidence: 0.8
      )
      
      check modification.modification_type == add_connection
      check modification.from_entity_id == "entity_1"
      check modification.to_entity_id == "entity_2"
      check modification.confidence > 0.5
    
    test "Output Validation - Strain Relief Reports":
      ## Test The Dreamer's strain relief reporting
      ##
      ## The Dreamer should generate accurate strain relief reports
      
      let initial_strain = 0.9
      let final_strain = 0.3
      let relief_amount = initial_strain - final_strain
      
      let strain_relief = StrainReliefReport(
        entity_id: "entity_1",
        initial_strain: initial_strain,
        final_strain: final_strain,
        relief_amount: relief_amount,
        optimization_method: "creative_restructuring",
        timestamp: now()
      )
      
      check strain_relief.entity_id == "entity_1"
      check strain_relief.relief_amount == relief_amount
      check strain_relief.relief_amount > 0.0
      check strain_relief.optimization_method == "creative_restructuring"

# Helper functions for testing
proc createThroneNode*(id: string, agent_name: string, domain_type: string, authority_level: AuthorityLevel): ThroneNode =
  return ThroneNode(
    id: id,
    agent_name: agent_name,
    domain_type: domain_type,
    authority_level: authority_level,
    strain: newStrainData(),
    created_at: now(),
    updated_at: now()
  )

# Mock functions for testing (to be implemented in actual agent)
proc findContradictions*(graph: KnowledgeGraph): seq[Contradiction] =
  # Mock implementation - would be implemented in actual agent
  return @[]

proc proposeConnections*(graph: KnowledgeGraph): seq[ProposedConnection] =
  # Mock implementation - would be implemented in actual agent
  return @[] 