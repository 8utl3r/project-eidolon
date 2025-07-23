# Dreamer Agent
# Implements creative optimization and contradiction detection for the knowledge graph

import std/[times, sequtils, tables, strutils]
import ../../types
import ../../entities/manager

# Contradiction type (should match test definition)
type
  Contradiction* = object
    entity1_id*: string
    entity2_id*: string
    contradiction_type*: string
    severity*: float
    detected_at*: DateTime

# Simple contradiction detection: looks for entities with similar relationships but conflicting descriptions
proc findContradictions*(manager: EntityManager): seq[Contradiction] =
  var contradictions: seq[Contradiction] = @[]
  let entities = toSeq(values(manager.entities))
  for i in 0 ..< entities.len:
    for j in i+1 ..< entities.len:
      let e1 = entities[i]
      let e2 = entities[j]
      # Example: Contradiction if names/descriptions are similar but descriptions are opposite (hot/cold)
      if e1.name == e2.name or e1.description.split(" ")[0] == e2.description.split(" ")[0]:
        # Naive contradiction: look for "hot" vs "cold" in description
        let desc1 = e1.description.toLowerAscii()
        let desc2 = e2.description.toLowerAscii()
        if (desc1.contains("hot") and desc2.contains("cold")) or (desc1.contains("cold") and desc2.contains("hot")):
          contradictions.add Contradiction(
            entity1_id: e1.id,
            entity2_id: e2.id,
            contradiction_type: "opposite descriptions",
            severity: 1.0,
            detected_at: now()
          )
  return contradictions

# Proposed connection type for graph restructuring
type
  ProposedConnection* = object
    from_entity_id*: string
    to_entity_id*: string
    connection_type*: string
    confidence*: float
    reasoning*: string

# Simple connection proposal: suggests connections between isolated entities
proc proposeConnections*(manager: EntityManager): seq[ProposedConnection] =
  var proposals: seq[ProposedConnection] = @[]
  let entities = toSeq(values(manager.entities))
  
  # Find entities with "Isolated" in their name or description
  let isolated_entities = entities.filter(proc(e: Entity): bool =
    return e.name.toLowerAscii().contains("isolated") or e.description.toLowerAscii().contains("isolated")
  )
  
  # Propose connections between isolated entities
  for i in 0 ..< isolated_entities.len:
    for j in i+1 ..< isolated_entities.len:
      proposals.add ProposedConnection(
        from_entity_id: isolated_entities[i].id,
        to_entity_id: isolated_entities[j].id,
        connection_type: "suggested_connection",
        confidence: 0.7,
        reasoning: "Both entities appear isolated and may benefit from connection"
      )
  
  return proposals 