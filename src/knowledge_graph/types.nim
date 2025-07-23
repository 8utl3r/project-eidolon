# Knowledge Graph Types
#
# This module defines types for the integrated knowledge graph system
# that combines entities, relationships, and strain calculations.

import std/[times, tables]
import ../types
import ../entities/manager
import ../thoughts/manager

type
  KnowledgeGraph* = object
    ## Integrated knowledge graph combining entities, relationships, thoughts, and strain
    entity_manager*: EntityManager
    thought_manager*: ThoughtManager
    strain_cache*: Table[string, StrainData]  # Cache for calculated strain values
    last_update*: DateTime
    
  GraphStrainFlow* = object
    ## Represents strain flow between entities in the knowledge graph
    from_entity_id*: string
    to_entity_id*: string
    flow_strength*: float  # How much strain flows (0.0 to 1.0)
    flow_direction*: Vector3  # Direction of strain flow
    timestamp*: DateTime
    
  ConfidenceScore* = object
    ## Confidence scoring based on strain values
    entity_id*: string
    amplitude_score*: float  # Confidence based on amplitude (0.0 to 1.0)
    resistance_score*: float  # Confidence based on resistance (0.0 to 1.0)
    frequency_score*: float  # Confidence based on frequency (0.0 to 1.0)
    overall_score*: float  # Combined confidence score
    last_calculated*: DateTime
    
  GraphNode* = object
    ## Enhanced entity with strain and confidence information
    entity*: Entity
    strain_data*: StrainData
    confidence*: ConfidenceScore
    connected_entities*: seq[string]  # IDs of directly connected entities
    
  GraphOperation* = enum
    ## Types of graph operations for strain calculations
    add_entity, remove_entity, add_relationship, remove_relationship,
    update_strain, propagate_strain, calculate_confidence

proc newKnowledgeGraph*(): KnowledgeGraph =
  ## Create a new knowledge graph
  return KnowledgeGraph(
    entity_manager: newEntityManager(),
    thought_manager: newThoughtManager(),
    strain_cache: initTable[string, StrainData](),
    last_update: now()
  )

proc newGraphStrainFlow*(from_id, to_id: string, strength: float, direction: Vector3): GraphStrainFlow =
  ## Create a new strain flow between entities in the knowledge graph
  return GraphStrainFlow(
    from_entity_id: from_id,
    to_entity_id: to_id,
    flow_strength: clamp(strength, 0.0, 1.0),
    flow_direction: direction,
    timestamp: now()
  )

proc newConfidenceScore*(entity_id: string): ConfidenceScore =
  ## Create a new confidence score for an entity
  return ConfidenceScore(
    entity_id: entity_id,
    amplitude_score: 0.0,
    resistance_score: 0.0,
    frequency_score: 0.0,
    overall_score: 0.0,
    last_calculated: now()
  )

proc newGraphNode*(entity: Entity): GraphNode =
  ## Create a new graph node from an entity
  return GraphNode(
    entity: entity,
    strain_data: entity.strain,
    confidence: newConfidenceScore(entity.id),
    connected_entities: @[]
  ) 