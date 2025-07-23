# Word Loader
#
# This module loads word nodes and verified thoughts from JSON files
# into the knowledge graph system.
#
# Refactored per project standards: use pure functions, pass managers as var parameters.
# See cursor/insights/insights.md for rationale and best practices.

import std/[json, times, tables]
import ../types
import ../entities/manager
import ../thoughts/manager

proc loadWordNodes*(manager: var EntityManager, json_data: JsonNode): int =
  ## Load word nodes from JSON data
  var loaded_count = 0
  for entity_data in json_data:
    let entity_id = entity_data["id"].getStr()
    let name = entity_data["name"].getStr()
    let description = entity_data["description"].getStr()
    var strain = newStrainData()
    if entity_data.hasKey("strain_amplitude"):
      strain.amplitude = entity_data["strain_amplitude"].getFloat()
    if entity_data.hasKey("strain_resistance"):
      strain.resistance = entity_data["strain_resistance"].getFloat()
    if entity_data.hasKey("strain_frequency"):
      strain.frequency = entity_data["strain_frequency"].getInt()
    if entity_data.hasKey("access_count"):
      strain.access_count = entity_data["access_count"].getInt()
    
    # Create complete Entity with all required fields
    let now_time = now()
    let entity = Entity(
      id: entity_id,
      name: name,
      entity_type: concept_type,
      description: description,
      attributes: initTable[string, string](),
      strain: strain,
      contexts: @[],
      created: now_time,
      modified: now_time
    )
    manager.entities[entity_id] = entity
    loaded_count += 1
  return loaded_count

proc loadVerifiedThoughts*(manager: var ThoughtManager, json_data: JsonNode): int =
  ## Load verified thoughts from JSON data
  var loaded_count = 0
  for thought_data in json_data:
    let thought_id = thought_data["id"].getStr()
    let name = thought_data["name"].getStr()
    let description = thought_data["description"].getStr()
    let verified = thought_data["verified"].getBool()
    let verification_source = thought_data["verification_source"].getStr()
    let confidence = thought_data["confidence"].getFloat()
    var connections: seq[string] = @[]
    for connection in thought_data["connections"]:
      connections.add(connection.getStr())
    var strain = newStrainData()
    if thought_data.hasKey("strain_amplitude"):
      strain.amplitude = thought_data["strain_amplitude"].getFloat()
    if thought_data.hasKey("strain_resistance"):
      strain.resistance = thought_data["strain_resistance"].getFloat()
    if thought_data.hasKey("strain_frequency"):
      strain.frequency = thought_data["strain_frequency"].getInt()
    if thought_data.hasKey("access_count"):
      strain.access_count = thought_data["access_count"].getInt()
    var thought = newThought(thought_id, name, description, connections, verified, verification_source, confidence)
    thought.strain = strain
    if manager.addThought(thought):
      loaded_count += 1
  return loaded_count

proc loadFromFiles*(entity_manager: var EntityManager, thought_manager: var ThoughtManager, entities_file: string, thoughts_file: string): (int, int) =
  ## Load word data from JSON files
  var entities_loaded = 0
  var thoughts_loaded = 0
  try:
    let entities_json = parseJson(readFile(entities_file))
    entities_loaded = loadWordNodes(entity_manager, entities_json)
    echo "Loaded ", entities_loaded, " word entities"
  except Exception as e:
    echo "Error loading entities: ", e.msg
  try:
    let thoughts_json = parseJson(readFile(thoughts_file))
    thoughts_loaded = loadVerifiedThoughts(thought_manager, thoughts_json)
    echo "Loaded ", thoughts_loaded, " verified thoughts"
  except Exception as e:
    echo "Error loading thoughts: ", e.msg
  return (entities_loaded, thoughts_loaded)

proc loadFromCombinedFile*(entity_manager: var EntityManager, thought_manager: var ThoughtManager, combined_file: string): (int, int) =
  ## Load word data from a combined JSON file
  try:
    let combined_json = parseJson(readFile(combined_file))
    var entities_loaded = 0
    var thoughts_loaded = 0
    if combined_json.hasKey("entities"):
      entities_loaded = loadWordNodes(entity_manager, combined_json["entities"])
      echo "Loaded ", entities_loaded, " word entities"
    if combined_json.hasKey("thoughts"):
      thoughts_loaded = loadVerifiedThoughts(thought_manager, combined_json["thoughts"])
      echo "Loaded ", thoughts_loaded, " verified thoughts"
    return (entities_loaded, thoughts_loaded)
  except Exception as e:
    echo "Error loading combined file: ", e.msg
    return (0, 0) 