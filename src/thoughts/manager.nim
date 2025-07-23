# Thought Manager
#
# This module manages verified thoughts in the knowledge graph system.
# Thoughts are ordered sequences of entity connections that represent
# verified knowledge about concepts.

import std/[tables, times, strutils, options, sequtils]
import ../types

type
  ThoughtManager* = object
    ## Manages verified thoughts in the knowledge graph
    thoughts*: Table[string, Thought]  # Map of thought ID to Thought
    entity_thoughts*: Table[string, seq[string]]  # Map of entity ID to thought IDs
    last_update*: DateTime

proc newThoughtManager*(): ThoughtManager =
  ## Create a new thought manager
  return ThoughtManager(
    thoughts: initTable[string, Thought](),
    entity_thoughts: initTable[string, seq[string]](),
    last_update: now()
  )

proc addThought*(manager: var ThoughtManager, thought: Thought): bool =
  ## Add a thought to the manager
  if manager.thoughts.hasKey(thought.id):
    return false  # Thought already exists
  
  manager.thoughts[thought.id] = thought
  
  # Index the thought by its constituent entities
  for entity_id in thought.connections:
    if not manager.entity_thoughts.hasKey(entity_id):
      manager.entity_thoughts[entity_id] = @[]
    manager.entity_thoughts[entity_id].add(thought.id)
  
  manager.last_update = now()
  return true

proc getThought*(manager: ThoughtManager, thought_id: string): Option[Thought] =
  ## Get a thought by ID
  if manager.thoughts.hasKey(thought_id):
    return some(manager.thoughts[thought_id])
  return none(Thought)

proc getThoughtsForEntity*(manager: ThoughtManager, entity_id: string): seq[Thought] =
  ## Get all thoughts that contain a specific entity
  var thoughts: seq[Thought] = @[]
  if manager.entity_thoughts.hasKey(entity_id):
    for thought_id in manager.entity_thoughts[entity_id]:
      if manager.thoughts.hasKey(thought_id):
        thoughts.add(manager.thoughts[thought_id])
  return thoughts

proc getVerifiedThoughts*(manager: ThoughtManager): seq[Thought] =
  ## Get all verified thoughts
  var verified_thoughts: seq[Thought] = @[]
  for thought in manager.thoughts.values:
    if thought.verified:
      verified_thoughts.add(thought)
  return verified_thoughts

proc searchThoughts*(manager: ThoughtManager, query: string): seq[Thought] =
  ## Search thoughts by name or description
  var matching_thoughts: seq[Thought] = @[]
  let query_lower = query.toLowerAscii()
  
  for thought in manager.thoughts.values:
    if query_lower in thought.name.toLowerAscii() or 
       query_lower in thought.description.toLowerAscii():
      matching_thoughts.add(thought)
  
  return matching_thoughts

proc removeThought*(manager: var ThoughtManager, thought_id: string): bool =
  ## Remove a thought from the manager
  if not manager.thoughts.hasKey(thought_id):
    return false
  
  let thought = manager.thoughts[thought_id]
  
  # Remove from entity index
  for entity_id in thought.connections:
    if manager.entity_thoughts.hasKey(entity_id):
      var filtered_thoughts: seq[string] = @[]
      for existing_thought_id in manager.entity_thoughts[entity_id]:
        if existing_thought_id != thought_id:
          filtered_thoughts.add(existing_thought_id)
      manager.entity_thoughts[entity_id] = filtered_thoughts
      if manager.entity_thoughts[entity_id].len == 0:
        manager.entity_thoughts.del(entity_id)
  
  # Remove the thought
  manager.thoughts.del(thought_id)
  manager.last_update = now()
  return true

proc getAllThoughts*(manager: ThoughtManager): seq[Thought] =
  ## Get all thoughts in the manager
  return toSeq(manager.thoughts.values)

proc getThoughtCount*(manager: ThoughtManager): int =
  ## Get the total number of thoughts
  return manager.thoughts.len

proc getVerifiedThoughtCount*(manager: ThoughtManager): int =
  ## Get the number of verified thoughts
  var count = 0
  for thought in manager.thoughts.values:
    if thought.verified:
      count += 1
  return count 