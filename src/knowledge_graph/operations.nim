# Knowledge Graph Operations
#
# This module provides operations for the integrated knowledge graph system,
# including strain flow calculations, confidence scoring, and graph operations.

import std/[times, tables, options]
import types
import ../entities/manager
import ../types

proc calculateStrainFlow*(graph: var KnowledgeGraph, from_id, to_id: string): Option[GraphStrainFlow] =
  ## Calculate strain flow between two entities
  ##
  ## Parameters:
  ## - from_id: Source entity ID
  ## - to_id: Target entity ID
  ##
  ## Returns: Some(GraphStrainFlow) if calculation successful, None otherwise
  
  let from_entity = graph.entity_manager.getEntity(from_id)
  let to_entity = graph.entity_manager.getEntity(to_id)
  
  if from_entity.isNone() or to_entity.isNone():
    return none(GraphStrainFlow)
  
  let from_strain = from_entity.get().strain
  let to_strain = to_entity.get().strain
  
  # Calculate flow strength based on amplitude difference
  let amplitude_diff = abs(from_strain.amplitude - to_strain.amplitude)
  let flow_strength = clamp(amplitude_diff / 2.0, 0.0, 1.0)
  
  # Calculate flow direction (from source to target)
  let direction = Vector3(
    x: to_strain.direction.x - from_strain.direction.x,
    y: to_strain.direction.y - from_strain.direction.y,
    z: to_strain.direction.z - from_strain.direction.z
  )
  
  return some(newGraphStrainFlow(from_id, to_id, flow_strength, direction))

proc calculateConfidenceScore*(graph: KnowledgeGraph, entity_id: string): Option[ConfidenceScore] =
  ## Calculate confidence score for an entity based on its strain values
  ##
  ## Parameters:
  ## - entity_id: Entity ID to calculate confidence for
  ##
  ## Returns: Some(ConfidenceScore) if calculation successful, None otherwise
  
  let entity = graph.entity_manager.getEntity(entity_id)
  if entity.isNone():
    return none(ConfidenceScore)
  
  let strain = entity.get().strain
  
  # Calculate individual confidence scores
  let amplitude_score = clamp(strain.amplitude, 0.0, 1.0)
  let resistance_score = clamp(1.0 - strain.resistance, 0.0, 1.0)  # Lower resistance = higher confidence
  let frequency_score = clamp(strain.frequency.float / 10.0, 0.0, 1.0)  # Normalize frequency
  
  # Calculate overall confidence (weighted average)
  let overall_score = (amplitude_score * 0.4 + resistance_score * 0.3 + frequency_score * 0.3)
  
  let confidence = ConfidenceScore(
    entity_id: entity_id,
    amplitude_score: amplitude_score,
    resistance_score: resistance_score,
    frequency_score: frequency_score,
    overall_score: overall_score,
    last_calculated: now()
  )
  
  return some(confidence)

# Global entity access functions for attention system
var global_knowledge_graph*: Option[KnowledgeGraph] = none(KnowledgeGraph)

proc setGlobalKnowledgeGraph*(graph: KnowledgeGraph) =
  ## Set the global knowledge graph for attention system access
  global_knowledge_graph = some(graph)

proc getEntity*(entity_id: string): Option[Entity] =
  ## Get an entity by ID from the global knowledge graph
  if global_knowledge_graph.isNone:
    return none(Entity)
  
  return global_knowledge_graph.get.entity_manager.getEntity(entity_id)

proc getAllEntities*(): seq[Entity] =
  ## Get all entities from the global knowledge graph
  if global_knowledge_graph.isNone:
    return @[]
  
  var entities: seq[Entity] = @[]
  for entity_id in global_knowledge_graph.get.entity_manager.entities.keys:
    let entity = global_knowledge_graph.get.entity_manager.getEntity(entity_id)
    if entity.isSome:
      entities.add(entity.get)
  
  return entities

proc getEntityConnections*(entity_id: string): seq[string] =
  ## Get all connected entity IDs for a given entity
  if global_knowledge_graph.isNone:
    return @[]
  
  var connections: seq[string] = @[]
  let relationships = global_knowledge_graph.get.entity_manager.getRelationships(entity_id)
  
  for relationship in relationships:
    if relationship.from_entity == entity_id:
      connections.add(relationship.to_entity)
    elif relationship.to_entity == entity_id:
      connections.add(relationship.from_entity)
  
  return connections

proc propagateStrain*(graph: var KnowledgeGraph, source_id: string, max_depth: int = 3): bool =
  ## Propagate strain from a source entity to connected entities
  ##
  ## Parameters:
  ## - source_id: Source entity ID
  ## - max_depth: Maximum propagation depth (default: 3)
  ##
  ## Returns: true if propagation successful, false otherwise
  
  if max_depth <= 0:
    return true
  
  let source_entity = graph.entity_manager.getEntity(source_id)
  if source_entity.isNone():
    return false
  
  # Get relationships for the source entity
  let relationships = graph.entity_manager.getRelationships(source_id)
  
  for relationship in relationships:
    let target_id = if relationship.from_entity == source_id: relationship.to_entity else: relationship.from_entity
    
    # Calculate strain flow
    let flow = graph.calculateStrainFlow(source_id, target_id)
    if flow.isNone():
      continue
    
    # Update target entity's strain based on flow
    let target_entity = graph.entity_manager.getEntity(target_id)
    if target_entity.isNone():
      continue
    
    var updated_target = target_entity.get()
    let flow_data = flow.get()
    
    # Apply strain flow to target
    updated_target.strain.amplitude += flow_data.flow_strength * 0.1  # Small increment
    updated_target.strain.amplitude = clamp(updated_target.strain.amplitude, 0.0, 1.0)
    
    # Update target entity
    discard graph.entity_manager.updateEntity(updated_target)
    
    # Cache the updated strain data
    graph.strain_cache[target_id] = updated_target.strain
    
    # Recursively propagate to next level
    discard graph.propagateStrain(target_id, max_depth - 1)
  
  graph.last_update = now()
  return true

proc addEntityToGraph*(graph: var KnowledgeGraph, name: string, entity_type: EntityType, 
                      description: string = ""): Option[GraphNode] =
  ## Add an entity to the knowledge graph
  ##
  ## Parameters:
  ## - name: Entity name
  ## - entity_type: Type of entity
  ## - description: Optional description
  ##
  ## Returns: Some(GraphNode) if successful, None otherwise
  
  let entity = graph.entity_manager.createEntity(name, entity_type, description)
  
  # Calculate initial confidence score
  let confidence = graph.calculateConfidenceScore(entity.id)
  if confidence.isNone():
    return none(GraphNode)
  
  # Create graph node
  let node = GraphNode(
    entity: entity,
    strain_data: entity.strain,
    confidence: confidence.get(),
    connected_entities: @[]
  )
  
  # Cache strain data
  graph.strain_cache[entity.id] = entity.strain
  
  graph.last_update = now()
  return some(node)

proc addRelationshipToGraph*(graph: var KnowledgeGraph, from_id, to_id: string, 
                           relationship_type: string): Option[Relationship] =
  ## Add a relationship to the knowledge graph
  ##
  ## Parameters:
  ## - from_id: Source entity ID
  ## - to_id: Target entity ID
  ## - relationship_type: Type of relationship
  ##
  ## Returns: Some(Relationship) if successful, None otherwise
  
  let relationship = graph.entity_manager.createRelationship(from_id, to_id, relationship_type)
  if relationship.isNone():
    return none(Relationship)
  
  # Propagate strain through the new relationship
  discard graph.propagateStrain(from_id, 2)
  discard graph.propagateStrain(to_id, 2)
  
  graph.last_update = now()
  return relationship

proc getGraphNode*(graph: KnowledgeGraph, entity_id: string): Option[GraphNode] =
  ## Get a graph node by entity ID
  ##
  ## Parameters:
  ## - entity_id: Entity ID to retrieve
  ##
  ## Returns: Some(GraphNode) if found, None otherwise
  
  let entity = graph.entity_manager.getEntity(entity_id)
  if entity.isNone():
    return none(GraphNode)
  
  let confidence = graph.calculateConfidenceScore(entity_id)
  if confidence.isNone():
    return none(GraphNode)
  
  # Get connected entities
  let relationships = graph.entity_manager.getRelationships(entity_id)
  var connected_ids: seq[string] = @[]
  
  for relationship in relationships:
    let other_id = if relationship.from_entity == entity_id: relationship.to_entity else: relationship.from_entity
    connected_ids.add(other_id)
  
  let node = GraphNode(
    entity: entity.get(),
    strain_data: entity.get().strain,
    confidence: confidence.get(),
    connected_entities: connected_ids
  )
  
  return some(node)

proc updateEntityStrain*(graph: var KnowledgeGraph, entity_id: string, 
                        new_strain: StrainData): bool =
  ## Update strain data for an entity and propagate changes
  ##
  ## Parameters:
  ## - entity_id: Entity ID to update
  ## - new_strain: New strain data
  ##
  ## Returns: true if update successful, false otherwise
  
  let entity = graph.entity_manager.getEntity(entity_id)
  if entity.isNone():
    return false
  
  var updated_entity = entity.get()
  updated_entity.strain = new_strain
  
  let success = graph.entity_manager.updateEntity(updated_entity)
  if not success:
    return false
  
  # Cache the new strain data
  graph.strain_cache[entity_id] = new_strain
  
  # Propagate strain changes to connected entities
  discard graph.propagateStrain(entity_id, 2)
  
  graph.last_update = now()
  return true

proc getHighConfidenceEntities*(graph: KnowledgeGraph, min_confidence: float = 0.7): seq[GraphNode] =
  ## Get entities with high confidence scores
  ##
  ## Parameters:
  ## - min_confidence: Minimum confidence threshold (default: 0.7)
  ##
  ## Returns: List of graph nodes with high confidence
  
  var high_confidence_nodes: seq[GraphNode] = @[]
  
  for entity in graph.entity_manager.entities.values:
    let confidence = graph.calculateConfidenceScore(entity.id)
    if confidence.isSome() and confidence.get().overall_score >= min_confidence:
      let node = graph.getGraphNode(entity.id)
      if node.isSome():
        high_confidence_nodes.add(node.get())
  
  return high_confidence_nodes

proc getStrainFlowNetwork*(graph: var KnowledgeGraph, entity_id: string, max_depth: int = 2): seq[GraphStrainFlow] =
  ## Get strain flow network for an entity
  ##
  ## Parameters:
  ## - entity_id: Entity ID to analyze
  ## - max_depth: Maximum depth to analyze (default: 2)
  ##
  ## Returns: List of strain flows in the network
  
  var flows: seq[GraphStrainFlow] = @[]
  var visited: Table[string, bool] = initTable[string, bool]()
  var stack: seq[(string, int)] = @[(entity_id, 0)]
  
  while stack.len > 0:
    let (current_id, depth) = stack.pop()
    if depth > max_depth or visited.hasKey(current_id):
      continue
    visited[current_id] = true
    let relationships = graph.entity_manager.getRelationships(current_id)
    for relationship in relationships:
      let target_id = if relationship.from_entity == current_id: relationship.to_entity else: relationship.from_entity
      if not visited.hasKey(target_id):
        let flow = graph.calculateStrainFlow(current_id, target_id)
        if flow.isSome():
          flows.add(flow.get())
        stack.add((target_id, depth + 1))
  return flows 