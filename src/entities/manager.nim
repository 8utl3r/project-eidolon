# Entity Manager
#
# This module provides functions for creating, managing, and querying entities.
# All functions are simple and focused on single responsibilities.

import std/[times, tables, strutils, options]
import ../types

type
  EntityManager* = object
    ## Manages entities and relationships in memory
    # NOTE: In Nim, all fields of an object are mutable if the object is passed as 'var'.
    # Do NOT use 'var' in field declarations; just pass the manager as 'var' to mutating procs.
    entities*: Table[string, Entity]
    relationships*: Table[string, Relationship]
    contexts*: Table[string, EntityContext]
    next_entity_id*: int
    next_relationship_id*: int
    next_context_id*: int

proc newEntityManager*(): EntityManager =
  ## Create a new entity manager
  return EntityManager(
    entities: initTable[string, Entity](),
    relationships: initTable[string, Relationship](),
    contexts: initTable[string, EntityContext](),
    next_entity_id: 1,
    next_relationship_id: 1,
    next_context_id: 1
  )

proc generateEntityId*(manager: var EntityManager): string =
  ## Generate a unique entity ID
  let id = "entity_" & $manager.next_entity_id
  manager.next_entity_id += 1
  return id

proc generateRelationshipId*(manager: var EntityManager): string =
  ## Generate a unique relationship ID
  let id = "rel_" & $manager.next_relationship_id
  manager.next_relationship_id += 1
  return id

proc generateContextId*(manager: var EntityManager): string =
  ## Generate a unique context ID
  let id = "ctx_" & $manager.next_context_id
  manager.next_context_id += 1
  return id

proc createEntity*(manager: var EntityManager, name: string, entity_type: EntityType, 
                  description: string = ""): Entity =
  ## Create a new entity
  ##
  ## Parameters:
  ## - name: Human-readable name for the entity
  ## - entity_type: Type of entity to create
  ## - description: Optional description
  ##
  ## Returns: Newly created entity
  let id = manager.generateEntityId()
  let now_time = now()
  
  let entity = Entity(
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
  
  manager.entities[id] = entity
  return entity

proc getEntity*(manager: EntityManager, id: string): Option[Entity] =
  ## Get an entity by ID
  ##
  ## Parameters:
  ## - id: Entity ID to retrieve
  ##
  ## Returns: Some(entity) if found, None otherwise
  if manager.entities.hasKey(id):
    return some(manager.entities[id])
  else:
    return none(Entity)

proc updateEntity*(manager: var EntityManager, entity: Entity): bool =
  ## Update an existing entity
  ##
  ## Parameters:
  ## - entity: Entity to update
  ##
  ## Returns: true if updated successfully, false if entity not found
  if manager.entities.hasKey(entity.id):
    var updated_entity = entity
    updated_entity.modified = now()
    manager.entities[entity.id] = updated_entity
    return true
  else:
    return false

proc deleteEntity*(manager: var EntityManager, id: string): bool =
  ## Delete an entity by ID
  ##
  ## Parameters:
  ## - id: Entity ID to delete
  ##
  ## Returns: true if deleted successfully, false if entity not found
  if manager.entities.hasKey(id):
    manager.entities.del(id)
    return true
  else:
    return false

proc createRelationship*(manager: var EntityManager, from_entity_id: string, 
                        to_entity_id: string, relationship_type: string): Option[Relationship] =
  ## Create a relationship between two entities
  ##
  ## Parameters:
  ## - from_entity_id: Source entity ID
  ## - to_entity_id: Target entity ID
  ## - relationship_type: Type of relationship
  ##
  ## Returns: Some(relationship) if created successfully, None if entities not found
  if not manager.entities.hasKey(from_entity_id) or not manager.entities.hasKey(to_entity_id):
    return none(Relationship)
  
  let id = manager.generateRelationshipId()
  let now_time = now()
  
  let relationship = Relationship(
    id: id,
    from_entity: from_entity_id,
    to_entity: to_entity_id,
    relationship_type: relationship_type,
    attributes: initTable[string, string](),
    strain: newStrainData(),
    created: now_time,
    modified: now_time
  )
  
  manager.relationships[id] = relationship
  return some(relationship)

proc getRelationships*(manager: EntityManager, entity_id: string): seq[Relationship] =
  ## Get all relationships for an entity
  ##
  ## Parameters:
  ## - entity_id: Entity ID to get relationships for
  ##
  ## Returns: List of relationships where entity is source or target
  var relationships: seq[Relationship] = @[]
  
  for relationship in manager.relationships.values:
    if relationship.from_entity == entity_id or relationship.to_entity == entity_id:
      relationships.add(relationship)
  
  return relationships

proc createContext*(manager: var EntityManager, name: string, description: string = ""): EntityContext =
  ## Create a new context
  ##
  ## Parameters:
  ## - name: Context name
  ## - description: Optional description
  ##
  ## Returns: Newly created context
  let id = manager.generateContextId()
  let now_time = now()
  
  let context = EntityContext(
    id: id,
    name: name,
    description: description,
    entities: @[],
    created: now_time
  )
  
  manager.contexts[id] = context
  return context

proc addEntityToContext*(manager: var EntityManager, entity_id: string, context_id: string): bool =
  ## Add an entity to a context
  ##
  ## Parameters:
  ## - entity_id: Entity ID to add
  ## - context_id: Context ID to add entity to
  ##
  ## Returns: true if added successfully, false if entity or context not found
  if not manager.entities.hasKey(entity_id) or not manager.contexts.hasKey(context_id):
    return false
  
  # Add entity to context
  var context = manager.contexts[context_id]
  if not context.entities.contains(entity_id):
    context.entities.add(entity_id)
    manager.contexts[context_id] = context
  
  # Add context to entity
  var entity = manager.entities[entity_id]
  if not entity.contexts.contains(context_id):
    entity.contexts.add(context_id)
    entity.strain.frequency = len(entity.contexts)
    entity.modified = now()
    manager.entities[entity_id] = entity
  
  return true

proc searchEntities*(manager: EntityManager, query: string): seq[Entity] =
  ## Search entities by name or description
  ##
  ## Parameters:
  ## - query: Search query string
  ##
  ## Returns: List of entities matching the query
  var matching_entities: seq[Entity] = @[]
  let query_lower = query.toLowerAscii()
  
  for entity in manager.entities.values:
    if entity.name.toLowerAscii().contains(query_lower) or 
       entity.description.toLowerAscii().contains(query_lower):
      matching_entities.add(entity)
  
  return matching_entities

proc getEntityCount*(manager: EntityManager): int =
  ## Get total number of entities
  return len(manager.entities)

proc getRelationshipCount*(manager: EntityManager): int =
  ## Get total number of relationships
  return len(manager.relationships)

proc getContextCount*(manager: EntityManager): int =
  ## Get total number of contexts
  return len(manager.contexts)

proc getContext*(manager: EntityManager, id: string): Option[EntityContext] =
  ## Get a context by ID
  ##
  ## Parameters:
  ## - id: Context ID to retrieve
  ##
  ## Returns: Some(context) if found, None otherwise
  if manager.contexts.hasKey(id):
    return some(manager.contexts[id])
  else:
    return none(EntityContext) 