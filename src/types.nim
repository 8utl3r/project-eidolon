# Unified Type System for Project Eidolon
#
# This module defines all core types used throughout the project.
# All other modules should import from this central type definition
# to ensure consistency and eliminate duplication.

import std/[times, tables]

type
  AgentType* = enum
    ## Types of agents (foreground and background)
    eidolon,  # Foreground agent for direct user interaction
    engineer, philosopher, skeptic, dreamer, investigator, archivist, stage_manager, linguist

  AgentState* = enum
    ## States of agents
    inactive, available, active

  EntityType* = enum
    ## Types of entities in the knowledge graph
    person, place, concept_type, object_type, event, document

  Vector3* = object
    ## 3D vector for representing direction and position
    x*, y*, z*: float

  StrainData* = object
    ## Core strain metrics for an entity (gravity-based)
    amplitude*: float    ## Cognitive dissonance amplitude (unbounded)
    resistance*: float   ## Resistance to strain (0.0-1.0) - legacy field
    frequency*: int      ## Frequency of access/occurrence - legacy field
    node_resistance*: float  ## Summed strain amplitudes from connections (unbounded)
    musical_frequency*: int  ## Musical note frequency (Hz)
    gravitational_mass*: float  ## Gravitational mass (unbounded)
    direction*: Vector3  ## Direction of gravitational pull
    last_accessed*: DateTime  ## Last time entity was accessed
    access_count*: int   ## Total number of accesses

  Entity* = object
    ## Core entity in the knowledge graph
    id*: string                    ## Unique identifier
    name*: string                  ## Human-readable name
    entity_type*: EntityType       ## Type of entity
    description*: string           ## Description of the entity
    attributes*: Table[string, string]  ## Key-value attributes
    strain*: StrainData            ## Strain metrics
    contexts*: seq[string]         ## Context IDs where entity appears
    created*: DateTime             ## Creation timestamp
    modified*: DateTime            ## Last modification timestamp

  Relationship* = object
    ## Relationship between two entities
    id*: string                    ## Unique identifier
    from_entity*: string           ## Source entity ID
    to_entity*: string             ## Target entity ID
    relationship_type*: string     ## Type of relationship
    attributes*: Table[string, string]  ## Relationship attributes
    strain*: StrainData            ## Strain metrics for the relationship
    created*: DateTime             ## Creation timestamp
    modified*: DateTime            ## Last modification timestamp

  EntityContext* = object
    ## Context in which entities appear
    id*: string                    ## Unique identifier
    name*: string                  ## Context name
    description*: string           ## Context description
    entities*: seq[string]         ## Entity IDs in this context
    created*: DateTime             ## Creation timestamp

  # Database-specific types (extended from core types)
  DatabaseEntity* = object
    ## Extended entity with database-specific fields
    entity*: Entity                ## Core entity data
    vector_embedding*: seq[float]  ## Semantic embedding
    created_at*: DateTime          ## Database creation timestamp
    updated_at*: DateTime          ## Database update timestamp

  DatabaseRelationship* = object
    ## Extended relationship with database-specific fields
    relationship*: Relationship    ## Core relationship data
    created_at*: DateTime          ## Database creation timestamp
    updated_at*: DateTime          ## Database update timestamp

  Event* = object
    ## Event in the knowledge graph
    id*: string                    ## Unique identifier
    event_type*: string           ## Type of event
    description*: string           ## Event description
    timestamp*: DateTime           ## When the event occurred
    entities*: seq[string]         ## Entity IDs involved
    attributes*: Table[string, string]  ## Key-value attributes
    strain*: StrainData           ## Gravitational strain confidence
    created*: DateTime

  CausalRelationship* = object
    ## Causal relationship between events
    id*: string                    ## Unique identifier
    cause_event_id*: string        ## Cause event ID
    effect_event_id*: string       ## Effect event ID
    confidence*: float             ## Confidence in causality (0.0-1.0)
    attributes*: Table[string, string]  ## Key-value attributes
    strain*: StrainData           ## Gravitational strain confidence
    created*: DateTime

  Embedding* = object
    ## Vector embedding for an entity
    id*: string                    ## Unique identifier
    entity_id*: string            ## Associated entity ID
    vector*: seq[float]           ## Vector representation
    embedding_type*: string       ## Type of embedding
    created*: DateTime

  ThroneNode* = object
    ## Throne node representing domain authority
    id*: string                    ## Unique identifier
    throne_type*: string          ## Type of throne (e.g., "ThroneOfTheMathematician")
    domain_authority*: float       ## Authority level (0.0-1.0)
    connected_entities*: seq[string]  ## Entity IDs connected to this throne
    attributes*: Table[string, string]  ## Key-value attributes
    strain*: StrainData           ## Gravitational strain confidence
    created*: DateTime

  DomainAuthority* = object
    ## Domain authority configuration
    id*: string                    ## Unique identifier
    throne_id*: string            ## Associated throne ID
    agent_id*: string             ## Associated agent ID
    authority_level*: float        ## Authority level (0.0-1.0)
    domain_rules*: seq[string]     ## Domain-specific rules
    attributes*: Table[string, string]  ## Key-value attributes
    created*: DateTime
    updated*: DateTime

  Thought* = object
    ## Verified thought - a series of connections in a specific order
    id*: string                    ## Unique identifier
    name*: string                  ## Human-readable name for the thought
    description*: string           ## Description of what this thought represents
    connections*: seq[string]      ## Ordered sequence of entity IDs forming the thought
    verified*: bool                ## Whether this thought has been verified
    verification_source*: string   ## Source of verification (e.g., "dictionary", "encyclopedia")
    confidence*: float             ## Confidence level (0.0-1.0)
    strain*: StrainData            ## Strain metrics for the thought
    created*: DateTime             ## Creation timestamp
    modified*: DateTime            ## Last modification timestamp

# Constructor functions for core types

proc newStrainData*(): StrainData =
  ## Create default strain data for new entities
  return StrainData(
    amplitude: 0.0,
    resistance: 0.5,
    frequency: 0,
    direction: Vector3(x: 0.0, y: 0.0, z: 0.0),
    last_accessed: now(),
    access_count: 0
  )

proc newVector3*(x, y, z: float): Vector3 =
  ## Create a new 3D vector
  return Vector3(x: x, y: y, z: z)

proc newEntity*(id: string, name: string, entity_type: EntityType, description: string = ""): Entity =
  ## Create a new entity with default values
  let now_time = now()
  return Entity(
    id: id,
    name: name,
    entity_type: entity_type,
    description: description,
    attributes: initTable[string, string](),
    strain: newStrainData(),
    contexts: @[],
    created: now_time,
    modified: now_time
  )

proc newEntity*(id: string, name: string, entity_type: EntityType, description: string, strain: StrainData): Entity =
  ## Create a new entity with custom strain data
  let now_time = now()
  return Entity(
    id: id,
    name: name,
    entity_type: entity_type,
    description: description,
    attributes: initTable[string, string](),
    strain: strain,
    contexts: @[],
    created: now_time,
    modified: now_time
  )

proc newRelationship*(id: string, from_entity: string, to_entity: string, 
                     relationship_type: string): Relationship =
  ## Create a new relationship with default values
  let now_time = now()
  return Relationship(
    id: id,
    from_entity: from_entity,
    to_entity: to_entity,
    relationship_type: relationship_type,
    attributes: initTable[string, string](),
    strain: newStrainData(),
    created: now_time,
    modified: now_time
  )

proc newEntityContext*(id: string, name: string, description: string = ""): EntityContext =
  ## Create a new entity context
  return EntityContext(
    id: id,
    name: name,
    description: description,
    entities: @[],
    created: now()
  )

proc newThroneNode*(id: string, throne_type: string): ThroneNode =
  ## Create a new throne node with default strain data
  let now_time = now()
  return ThroneNode(
    id: id,
    throne_type: throne_type,
    domain_authority: 1.0,
    connected_entities: @[],
    attributes: initTable[string, string](),
    strain: StrainData(
      amplitude: 1.0,  # Thrones have maximum amplitude
      resistance: 0.0, # Thrones have no resistance
      frequency: 0,
      direction: Vector3(x: 0.0, y: 0.0, z: 0.0),
      last_accessed: now_time,
      access_count: 0
    ),
    created: now_time
  )

proc newThought*(id: string, name: string, description: string, connections: seq[string], 
                verified: bool = true, verification_source: string = "dictionary", 
                confidence: float = 1.0): Thought =
  ## Create a new verified thought
  let now_time = now()
  return Thought(
    id: id,
    name: name,
    description: description,
    connections: connections,
    verified: verified,
    verification_source: verification_source,
    confidence: clamp(confidence, 0.0, 1.0),
    strain: newStrainData(),
    created: now_time,
    modified: now_time
  ) 