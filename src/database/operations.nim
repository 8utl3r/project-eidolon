# Database Operations Layer
#
# This module provides comprehensive database operations for the knowledge graph system.
# It includes CRUD operations, strain-aware queries, and advanced database management
# that all agents will use for integration.

import std/[times, tables, options, sequtils]
import ../types
import ../entities/manager
import ../knowledge_graph/types
import ../knowledge_graph/operations
import ../strain/math

type
  DatabaseOperations* = object
    ## Centralized database operations manager
    entity_manager*: EntityManager
    knowledge_graph*: KnowledgeGraph
    events*: Table[string, Event]
    causal_relationships*: Table[string, CausalRelationship]
    embeddings*: Table[string, Embedding]
    throne_nodes*: Table[string, ThroneNode]
    domain_authorities*: Table[string, DomainAuthority]
    next_event_id*: int
    next_causal_id*: int
    next_embedding_id*: int
    next_throne_id*: int
    next_authority_id*: int

  QueryFilter* = object
    ## Filter for database queries
    entity_types*: seq[EntityType]
    strain_threshold*: float
    date_range_start*: DateTime
    date_range_end*: DateTime
    context_ids*: seq[string]
    relationship_types*: seq[string]

  QueryResult*[T] = object
    ## Result of a database query
    items*: seq[T]
    total_count*: int
    strain_summary*: StrainSummary
    query_time*: float

  StrainSummary* = object
    ## Summary of strain values in query results
    avg_amplitude*: float
    avg_resistance*: float
    max_amplitude*: float
    min_amplitude*: float
    high_strain_count*: int
    low_strain_count*: int

# Constructor
proc newDatabaseOperations*(): DatabaseOperations =
  ## Create a new database operations manager
  return DatabaseOperations(
    entity_manager: newEntityManager(),
    knowledge_graph: newKnowledgeGraph(),
    events: initTable[string, Event](),
    causal_relationships: initTable[string, CausalRelationship](),
    embeddings: initTable[string, Embedding](),
    throne_nodes: initTable[string, ThroneNode](),
    domain_authorities: initTable[string, DomainAuthority](),
    next_event_id: 1,
    next_causal_id: 1,
    next_embedding_id: 1,
    next_throne_id: 1,
    next_authority_id: 1
  )

# ID Generation
proc generateEventId*(db: var DatabaseOperations): string =
  let id = "event_" & $db.next_event_id
  db.next_event_id += 1
  return id

proc generateCausalId*(db: var DatabaseOperations): string =
  let id = "causal_" & $db.next_causal_id
  db.next_causal_id += 1
  return id

proc generateEmbeddingId*(db: var DatabaseOperations): string =
  let id = "emb_" & $db.next_embedding_id
  db.next_embedding_id += 1
  return id

proc generateThroneId*(db: var DatabaseOperations): string =
  let id = "throne_" & $db.next_throne_id
  db.next_throne_id += 1
  return id

proc generateAuthorityId*(db: var DatabaseOperations): string =
  let id = "auth_" & $db.next_authority_id
  db.next_authority_id += 1
  return id

# Entity Operations
proc createEntity*(db: var DatabaseOperations, name: string, entity_type: EntityType, 
                  description: string = ""): Entity =
  ## Create a new entity with strain initialization
  let entity = db.entity_manager.createEntity(name, entity_type, description)
  
  # Initialize strain with default values
  var updated_entity = entity
  updated_entity.strain = newStrainData()
  discard db.entity_manager.updateEntity(updated_entity)
  
  return updated_entity

proc getEntity*(db: DatabaseOperations, id: string): Option[Entity] =
  ## Get entity by ID
  return db.entity_manager.getEntity(id)

proc updateEntity*(db: var DatabaseOperations, entity: Entity): bool =
  ## Update entity with strain recalculation
  if db.entity_manager.updateEntity(entity):
    # Recalculate strain flow to connected entities
    discard db.knowledge_graph.propagateStrain(entity.id, 2)
    return true
  return false

proc deleteEntity*(db: var DatabaseOperations, id: string): bool =
  ## Delete entity and clean up related data
  if db.entity_manager.deleteEntity(id):
    # Remove from events
    for event_id, event in db.events:
      if id in event.entities:
        var updated_event = event
        updated_event.entities = event.entities.filter(proc(e: string): bool = e != id)
        db.events[event_id] = updated_event
    
    # Remove from throne connections
    for throne_id, throne in db.throne_nodes:
      if id in throne.connected_entities:
        var updated_throne = throne
        updated_throne.connected_entities = throne.connected_entities.filter(proc(e: string): bool = e != id)
        db.throne_nodes[throne_id] = updated_throne
    
    return true
  return false

# Relationship Operations
proc createRelationship*(db: var DatabaseOperations, from_entity_id: string, 
                        to_entity_id: string, relationship_type: string): Option[Relationship] =
  ## Create relationship with strain flow calculation
  let relationship = db.entity_manager.createRelationship(from_entity_id, to_entity_id, relationship_type)
  if relationship.isSome:
    # Calculate initial strain flow
    discard db.knowledge_graph.calculateStrainFlow(from_entity_id, to_entity_id)
  return relationship

proc getRelationships*(db: DatabaseOperations, entity_id: string): seq[Relationship] =
  ## Get all relationships for an entity
  return db.entity_manager.getRelationships(entity_id)

proc getRelationshipsByType*(db: DatabaseOperations, entity_id: string, relationship_type: string): seq[Relationship] =
  ## Get relationships of specific type for an entity
  return db.entity_manager.getRelationships(entity_id).filter(proc(r: Relationship): bool =
    r.relationship_type == relationship_type
  )

# Event Operations
proc createEvent*(db: var DatabaseOperations, event_type: string, description: string, 
                 entity_ids: seq[string] = @[]): Event =
  ## Create a new event
  let id = db.generateEventId()
  let now_time = now()
  
  let event = Event(
    id: id,
    event_type: event_type,
    description: description,
    timestamp: now_time,
    entities: entity_ids,
    attributes: initTable[string, string](),
    strain: newStrainData(),
    created: now_time
  )
  
  db.events[id] = event
  return event

proc getEvent*(db: DatabaseOperations, id: string): Option[Event] =
  ## Get event by ID
  if db.events.hasKey(id):
    return some(db.events[id])
  return none(Event)

proc updateEvent*(db: var DatabaseOperations, event: Event): bool =
  ## Update event
  if db.events.hasKey(event.id):
    var updated_event = event
    updated_event.strain.last_accessed = now()
    db.events[event.id] = updated_event
    return true
  return false

proc deleteEvent*(db: var DatabaseOperations, id: string): bool =
  ## Delete event
  if db.events.hasKey(id):
    db.events.del(id)
    return true
  return false

# Causal Relationship Operations
proc createCausalRelationship*(db: var DatabaseOperations, cause_event_id: string, 
                              effect_event_id: string, confidence: float): CausalRelationship =
  ## Create a causal relationship between events
  let id = db.generateCausalId()
  let now_time = now()
  
  let causal = CausalRelationship(
    id: id,
    cause_event_id: cause_event_id,
    effect_event_id: effect_event_id,
    confidence: confidence,
    attributes: initTable[string, string](),
    strain: newStrainData(),
    created: now_time
  )
  
  db.causal_relationships[id] = causal
  return causal

proc getCausalRelationships*(db: DatabaseOperations, event_id: string): seq[CausalRelationship] =
  ## Get causal relationships for an event
  return toSeq(db.causal_relationships.values).filter(proc(c: CausalRelationship): bool =
    c.cause_event_id == event_id or c.effect_event_id == event_id
  )

# Embedding Operations
proc createEmbedding*(db: var DatabaseOperations, entity_id: string, vector: seq[float], 
                     embedding_type: string): Embedding =
  ## Create an embedding for an entity
  let id = db.generateEmbeddingId()
  let now_time = now()
  
  let embedding = Embedding(
    id: id,
    entity_id: entity_id,
    vector: vector,
    embedding_type: embedding_type,
    created: now_time
  )
  
  db.embeddings[id] = embedding
  return embedding

proc getEmbedding*(db: DatabaseOperations, entity_id: string, embedding_type: string): Option[Embedding] =
  ## Get embedding for an entity and type
  for embedding in db.embeddings.values:
    if embedding.entity_id == entity_id and embedding.embedding_type == embedding_type:
      return some(embedding)
  return none(Embedding)

# Throne and Domain Authority Operations
proc createThroneNode*(db: var DatabaseOperations, throne_type: string, 
                      domain_authority: float = 1.0): ThroneNode =
  ## Create a throne node
  let id = db.generateThroneId()
  let now_time = now()
  
  let throne = ThroneNode(
    id: id,
    throne_type: throne_type,
    domain_authority: domain_authority,
    connected_entities: @[],
    attributes: initTable[string, string](),
    strain: newStrainData(),
    created: now_time
  )
  
  db.throne_nodes[id] = throne
  return throne

proc getThroneNode*(db: DatabaseOperations, id: string): Option[ThroneNode] =
  ## Get throne node by ID
  if db.throne_nodes.hasKey(id):
    return some(db.throne_nodes[id])
  return none(ThroneNode)

proc connectEntityToThrone*(db: var DatabaseOperations, entity_id: string, throne_id: string): bool =
  ## Connect an entity to a throne
  let throne_opt = db.getThroneNode(throne_id)
  let entity_opt = db.getEntity(entity_id)
  
  if throne_opt.isNone or entity_opt.isNone:
    return false
  
  var throne = throne_opt.get()
  if not throne.connected_entities.contains(entity_id):
    throne.connected_entities.add(entity_id)
    db.throne_nodes[throne_id] = throne
    return true
  return false

proc createDomainAuthority*(db: var DatabaseOperations, throne_id: string, agent_id: string, 
                           authority_level: float, domain_rules: seq[string] = @[]): DomainAuthority =
  ## Create domain authority for an agent
  let id = db.generateAuthorityId()
  let now_time = now()
  
  let authority = DomainAuthority(
    id: id,
    throne_id: throne_id,
    agent_id: agent_id,
    authority_level: authority_level,
    domain_rules: domain_rules,
    attributes: initTable[string, string](),
    created: now_time,
    updated: now_time
  )
  
  db.domain_authorities[id] = authority
  return authority

# Strain-Aware Query System
proc calculateStrainSummary*(db: DatabaseOperations, entities: seq[Entity]): StrainSummary =
  ## Calculate strain summary for a set of entities
  if entities.len == 0:
    return StrainSummary(
      avg_amplitude: 0.0,
      avg_resistance: 0.0,
      max_amplitude: 0.0,
      min_amplitude: 0.0,
      high_strain_count: 0,
      low_strain_count: 0
    )
  
  var total_amplitude = 0.0
  var total_resistance = 0.0
  var max_amp = 0.0
  var min_amp = 1.0
  var high_count = 0
  var low_count = 0
  
  for entity in entities:
    let amplitude = entity.strain.amplitude
    let resistance = entity.strain.resistance
    
    total_amplitude += amplitude
    total_resistance += resistance
    max_amp = max(max_amp, amplitude)
    min_amp = min(min_amp, amplitude)
    
    if amplitude > 0.7:
      high_count += 1
    elif amplitude < 0.3:
      low_count += 1
  
  return StrainSummary(
    avg_amplitude: total_amplitude / entities.len.float,
    avg_resistance: total_resistance / entities.len.float,
    max_amplitude: max_amp,
    min_amplitude: min_amp,
    high_strain_count: high_count,
    low_strain_count: low_count
  )

proc queryEntities*(db: DatabaseOperations, filter: QueryFilter = QueryFilter()): QueryResult[Entity] =
  ## Query entities with strain-aware filtering
  let start_time = cpuTime()
  var entities = toSeq(db.entity_manager.entities.values)
  
  # Apply filters
  if filter.entity_types.len > 0:
    entities = entities.filter(proc(e: Entity): bool = e.entity_type in filter.entity_types)
  
  if filter.strain_threshold > 0.0:
    entities = entities.filter(proc(e: Entity): bool = e.strain.amplitude >= filter.strain_threshold)
  
  if filter.context_ids.len > 0:
    entities = entities.filter(proc(e: Entity): bool =
      any(filter.context_ids, proc(ctx: string): bool = ctx in e.contexts)
    )
  
  # Calculate strain summary
  let strain_summary = db.calculateStrainSummary(entities)
  let query_time = cpuTime() - start_time
  
  return QueryResult[Entity](
    items: entities,
    total_count: entities.len,
    strain_summary: strain_summary,
    query_time: query_time
  )

proc queryHighStrainEntities*(db: DatabaseOperations, threshold: float = 0.7): QueryResult[Entity] =
  ## Query entities with high strain values
  var filter = QueryFilter()
  filter.strain_threshold = threshold
  return db.queryEntities(filter)

proc queryLowStrainEntities*(db: DatabaseOperations, threshold: float = 0.3): QueryResult[Entity] =
  ## Query entities with low strain values
  let entities = toSeq(db.entity_manager.entities.values).filter(proc(e: Entity): bool =
    e.strain.amplitude <= threshold
  )
  
  let strain_summary = db.calculateStrainSummary(entities)
  return QueryResult[Entity](
    items: entities,
    total_count: entities.len,
    strain_summary: strain_summary,
    query_time: 0.0
  )

proc queryEntitiesByType*(db: DatabaseOperations, entity_type: EntityType): QueryResult[Entity] =
  ## Query entities by type
  var filter = QueryFilter()
  filter.entity_types = @[entity_type]
  return db.queryEntities(filter)

proc queryConnectedEntities*(db: DatabaseOperations, entity_id: string, max_depth: int = 1): QueryResult[Entity] =
  ## Query entities connected to a given entity
  var connected_ids: seq[string] = @[entity_id]
  var visited: seq[string] = @[entity_id]
  
  for depth in 1..max_depth:
    var new_connections: seq[string] = @[]
    for id in connected_ids:
      let relationships = db.getRelationships(id)
      for rel in relationships:
        let target_id = if rel.from_entity == id: rel.to_entity else: rel.from_entity
        if target_id notin visited:
          new_connections.add(target_id)
          visited.add(target_id)
    connected_ids = new_connections
    if connected_ids.len == 0:
      break
  
  let entities = visited.filter(proc(id: string): bool = id != entity_id).map(proc(id: string): Entity =
    db.getEntity(id).get()
  )
  
  let strain_summary = db.calculateStrainSummary(entities)
  return QueryResult[Entity](
    items: entities,
    total_count: entities.len,
    strain_summary: strain_summary,
    query_time: 0.0
  )

# Statistics and Analytics
proc getDatabaseStats*(db: DatabaseOperations): Table[string, int] =
  ## Get database statistics
  var stats = initTable[string, int]()
  stats["entities"] = db.entity_manager.getEntityCount()
  stats["relationships"] = db.entity_manager.getRelationshipCount()
  stats["contexts"] = db.entity_manager.getContextCount()
  stats["events"] = db.events.len
  stats["causal_relationships"] = db.causal_relationships.len
  stats["embeddings"] = db.embeddings.len
  stats["throne_nodes"] = db.throne_nodes.len
  stats["domain_authorities"] = db.domain_authorities.len
  return stats

proc getStrainDistribution*(db: DatabaseOperations): Table[string, int] =
  ## Get distribution of strain values
  var distribution = initTable[string, int]()
  distribution["very_low"] = 0    # 0.0 - 0.2
  distribution["low"] = 0         # 0.2 - 0.4
  distribution["medium"] = 0      # 0.4 - 0.6
  distribution["high"] = 0        # 0.6 - 0.8
  distribution["very_high"] = 0   # 0.8 - 1.0
  
  for entity in db.entity_manager.entities.values:
    let amplitude = entity.strain.amplitude
    if amplitude < 0.2:
      distribution["very_low"] += 1
    elif amplitude < 0.4:
      distribution["low"] += 1
    elif amplitude < 0.6:
      distribution["medium"] += 1
    elif amplitude < 0.8:
      distribution["high"] += 1
    else:
      distribution["very_high"] += 1
  
  return distribution 