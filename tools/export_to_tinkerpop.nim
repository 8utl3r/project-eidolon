# Export Project Eidolon Data to TinkerPop
# 
# This script exports our strain-based knowledge graph data to TinkerPop format
# for visualization and analysis.

import std/[times, json, strformat, strutils, options, tables]
import ../src/types
import ../src/agents/registry
import ../src/entities/manager
import ../src/knowledge_graph/operations
import ../src/database/operations

type
  TinkerPopExport = object
    vertices: seq[JsonNode]
    edges: seq[JsonNode]
    metadata: JsonNode

proc exportAgentsToTinkerPop(): seq[JsonNode] =
  ## Export agent registry data to TinkerPop vertices
  var vertices: seq[JsonNode] = @[]
  
  # Create agent registry
  var registry = newAgentRegistry()
  discard registry.initializeDefaultAgents()
  
  # Export each agent as a throne vertex
  for agent in registry.getActiveAgents():
    var vertex = %*{
      "id": agent.agent_id,
      "label": "throne",
      "properties": {
        "name": "ThroneOfThe" & capitalizeAscii(agent.agent_id),
        "agent": "The " & capitalizeAscii(agent.agent_id),
        "domain": $agent.agent_type,
        "authority_level": "triggered",
        "current_strain": agent.current_strain,
        "max_strain": agent.max_strain,
        "keywords": agent.keywords,
        "is_active": agent.is_active,
        "created": $agent.created,
        "last_accessed": $agent.last_accessed
      }
    }
    vertices.add(vertex)
  
  return vertices

proc exportEntitiesToTinkerPop(): seq[JsonNode] =
  ## Export entity data to TinkerPop vertices
  var vertices: seq[JsonNode] = @[]
  
  # Create entity manager
  var manager = newEntityManager()
  
  # Create some sample entities for demonstration
  let sample_entities = @[
    ("mathematical_theorem", "Pythagorean Theorem", concept_type, "a² + b² = c²", 0.85, 0.3, 5),
    ("logical_rule", "Modus Ponens", concept_type, "If P then Q, P, therefore Q", 0.92, 0.1, 8),
    ("context_info", "Quantum Mechanics Context", concept_type, "Physics domain context", 0.45, 0.7, 3),
    ("creative_concept", "Neural Network Architecture", concept_type, "AI system design", 0.23, 0.9, 1),
    ("person", "Albert Einstein", person, "Theoretical physicist", 0.78, 0.4, 6),
    ("place", "MIT", place, "Massachusetts Institute of Technology", 0.65, 0.6, 4),
    ("event", "Quantum Revolution", event, "Early 20th century physics", 0.89, 0.2, 7)
  ]
  
  for (entity_id, name, entity_type, description, amplitude, resistance, frequency) in sample_entities:
    let entity = manager.createEntity(name, entity_type, description)
    
    # Update strain data
    var strain_data = entity.strain
    strain_data.amplitude = amplitude
    strain_data.resistance = resistance
    strain_data.frequency = frequency
    strain_data.last_accessed = now()
    strain_data.access_count = frequency
    
    var updated_entity = entity
    updated_entity.strain = strain_data
    discard manager.updateEntity(updated_entity)
    
    # Create TinkerPop vertex
    var vertex = %*{
      "id": entity.id,
      "label": "entity",
      "properties": {
        "name": entity.name,
        "entity_type": $entity.entity_type,
        "description": entity.description,
        "strain_amplitude": strain_data.amplitude,
        "strain_resistance": strain_data.resistance,
        "strain_frequency": strain_data.frequency,
        "access_count": strain_data.access_count,
        "created": $entity.created,
        "modified": $entity.modified
      }
    }
    vertices.add(vertex)
  
  return vertices

proc exportRelationshipsToTinkerPop(): seq[JsonNode] =
  ## Export relationship data to TinkerPop edges
  var edges: seq[JsonNode] = @[]
  # Create entity manager as mutable
  var manager = newEntityManager()
  
  # Create sample relationships
  let sample_relationships = @[
    ("mathematical_theorem", "logical_rule", "logical_implication", 0.78),
    ("logical_rule", "context_info", "context_dependency", 0.65),
    ("context_info", "creative_concept", "creative_inspiration", 0.34),
    ("person", "mathematical_theorem", "discovered", 0.91),
    ("place", "person", "educated", 0.72),
    ("event", "person", "involved", 0.83),
    ("event", "creative_concept", "influenced", 0.56)
  ]
  
  for (from_id, to_id, rel_type, strain_amplitude) in sample_relationships:
    let relationship_opt = manager.createRelationship(from_id, to_id, rel_type)
    var edge: JsonNode
    if relationship_opt.isSome():
      let relationship = relationship_opt.get()
      # Update strain data
      var strain_data = relationship.strain
      strain_data.amplitude = strain_amplitude
      strain_data.last_accessed = now()
      var updated_relationship = relationship
      updated_relationship.strain = strain_data
      # Mutate the manager at the top level
      manager.relationships[updated_relationship.id] = updated_relationship
      # Create TinkerPop edge
      edge = %*{
        "id": updated_relationship.id,
        "label": "related_to",
        "outV": updated_relationship.from_entity,
        "inV": updated_relationship.to_entity,
        "properties": {
          "relationship_type": updated_relationship.relationship_type,
          "strain_amplitude": strain_data.amplitude,
          "strain_resistance": strain_data.resistance,
          "strain_frequency": strain_data.frequency,
          "created": $updated_relationship.created,
          "modified": $updated_relationship.modified
        }
      }
      edges.add(edge)
  
  return edges

proc exportAuthorityRelationships(): seq[JsonNode] =
  ## Export agent authority relationships to TinkerPop edges
  var edges: seq[JsonNode] = @[]
  
  # Create agent registry
  var registry = newAgentRegistry()
  discard registry.initializeDefaultAgents()
  
  # Define authority mappings
  let authority_mappings = @[
    ("mathematician", "mathematical_theorem", 0.9),
    ("skeptic", "logical_rule", 0.95),
    ("stage_manager", "context_info", 0.7),
    ("dreamer", "creative_concept", 0.6),
    ("philosopher", "person", 0.8),
    ("investigator", "event", 0.85),
    ("archivist", "place", 0.75)
  ]
  
  for (agent_id, entity_id, authority_strength) in authority_mappings:
    var edge = %*{
      "id": "auth_" & agent_id & "_" & entity_id,
      "label": "has_authority",
      "outV": agent_id,
      "inV": entity_id,
      "properties": {
        "authority_strength": authority_strength,
        "strain_amplitude": authority_strength * 0.8,  # Scale down for visualization
        "created": $(now())
      }
    }
    edges.add(edge)
  
  return edges

proc generateTinkerPopScript(): string =
  ## Generate a Gremlin script for loading the exported data
  var script = """
// Project Eidolon Data Export - Generated by export_to_tinkerpop.nim
// Apache TinkerPop 3.7.0

println "Loading Project Eidolon data into TinkerPop..."

// Clear existing graph
g.V().drop().iterate()
g.E().drop().iterate()

println "Creating vertices..."

"""
  
  # Add vertices
  let agent_vertices = exportAgentsToTinkerPop()
  let entity_vertices = exportEntitiesToTinkerPop()
  
  for vertex in agent_vertices:
    script.add("// Agent: " & vertex["properties"]["name"].getStr() & "\n")
    script.add("g.addV('" & vertex["label"].getStr() & "')")
    for key, value in vertex["properties"].pairs:
      if value.kind == JString:
        script.add(".property('" & key & "', '" & value.getStr() & "')")
      elif value.kind == JFloat:
        script.add(".property('" & key & "', " & $value.getFloat() & ")")
      elif value.kind == JInt:
        script.add(".property('" & key & "', " & $value.getInt() & ")")
      elif value.kind == JBool:
        script.add(".property('" & key & "', " & $value.getBool() & ")")
    script.add(".next()\n")
  
  for vertex in entity_vertices:
    script.add("// Entity: " & vertex["properties"]["name"].getStr() & "\n")
    script.add("g.addV('" & vertex["label"].getStr() & "')")
    for key, value in vertex["properties"].pairs:
      if value.kind == JString:
        script.add(".property('" & key & "', '" & value.getStr() & "')")
      elif value.kind == JFloat:
        script.add(".property('" & key & "', " & $value.getFloat() & ")")
      elif value.kind == JInt:
        script.add(".property('" & key & "', " & $value.getInt() & ")")
      elif value.kind == JBool:
        script.add(".property('" & key & "', " & $value.getBool() & ")")
    script.add(".next()\n")
  
  script.add("\nprintln \"Creating edges...\"\n")
  
  # Add edges
  let relationship_edges = exportRelationshipsToTinkerPop()
  let authority_edges = exportAuthorityRelationships()
  
  for edge in authority_edges:
    script.add("// Authority: " & edge["outV"].getStr() & " -> " & edge["inV"].getStr() & "\n")
    script.add("g.addE('" & edge["label"].getStr() & "')")
    script.add(".from(g.V().has('id', '" & edge["outV"].getStr() & "').next())")
    script.add(".to(g.V().has('id', '" & edge["inV"].getStr() & "').next())")
    for key, value in edge["properties"].pairs:
      if value.kind == JString:
        script.add(".property('" & key & "', '" & value.getStr() & "')")
      elif value.kind == JFloat:
        script.add(".property('" & key & "', " & $value.getFloat() & ")")
      elif value.kind == JInt:
        script.add(".property('" & key & "', " & $value.getInt() & ")")
      elif value.kind == JBool:
        script.add(".property('" & key & "', " & $value.getBool() & ")")
    script.add(".next()\n")
  
  for edge in relationship_edges:
    script.add("// Relationship: " & edge["outV"].getStr() & " -> " & edge["inV"].getStr() & "\n")
    script.add("g.addE('" & edge["label"].getStr() & "')")
    script.add(".from(g.V().has('id', '" & edge["outV"].getStr() & "').next())")
    script.add(".to(g.V().has('id', '" & edge["inV"].getStr() & "').next())")
    for key, value in edge["properties"].pairs:
      if value.kind == JString:
        script.add(".property('" & key & "', '" & value.getStr() & "')")
      elif value.kind == JFloat:
        script.add(".property('" & key & "', " & $value.getFloat() & ")")
      elif value.kind == JInt:
        script.add(".property('" & key & "', " & $value.getInt() & ")")
      elif value.kind == JBool:
        script.add(".property('" & key & "', " & $value.getBool() & ")")
    script.add(".next()\n")
  
  script.add("println \"Data loading complete!\"\n")
  script.add("println \"\"\n")
  script.add("\n")
  script.add("// Display graph statistics\n")
  script.add("println \"Project Eidolon Graph Statistics:\"\n")
  script.add("println \"==================================\"\n")
  script.add("println \"Total vertices: \" + g.V().count().next()\n")
  script.add("println \"Total edges: \" + g.E().count().next()\n")
  script.add("println \"Throne nodes: \" + g.V().hasLabel('throne').count().next()\n")
  script.add("println \"Entity nodes: \" + g.V().hasLabel('entity').count().next()\n")
  script.add("println \"\"\n")
  script.add("\n")
  script.add("// Display strain analysis\n")
  script.add("println \"Strain Analysis:\"\n")
  script.add("println \"===============\"\n")
  script.add("println \"High strain entities (>0.8):\"\n")
  script.add("g.V().hasLabel('entity').has('strain_amplitude', gt(0.8)).values('name').next()\n")
  script.add("println \"\"\n")
  script.add("\n")
  script.add("println \"Low resistance entities (<0.5):\"\n")
  script.add("g.V().hasLabel('entity').has('strain_resistance', lt(0.5)).values('name').next()\n")
  script.add("println \"\"\n")
  script.add("\n")
  script.add("println \"High frequency entities (>5):\"\n")
  script.add("g.V().hasLabel('entity').has('strain_frequency', gt(5)).values('name').next()\n")
  script.add("println \"\"\n")
  script.add("\n")
  script.add("// Display agent authority\n")
  script.add("println \"Agent Authority:\"\n")
  script.add("println \"===============\"\n")
  script.add("g.V().hasLabel('throne').values('name').next()\n")
  script.add("g.V().hasLabel('throne').values('agent').next()\n")
  script.add("println \"\"\n")
  script.add("\n")
  script.add("println \"Project Eidolon data ready for visualization!\"\n")
  script.add("println \"Use ':exit' to quit the console\"\n")
  
  return script

when isMainModule:
  echo "Project Eidolon - TinkerPop Data Export"
  echo "======================================="
  echo ""
  
  # Generate the TinkerPop script
  let script = generateTinkerPopScript()
  
  # Write to file
  writeFile("tools/project-eidolon-data.groovy", script)
  
  echo "✅ Generated TinkerPop script: tools/project-eidolon-data.groovy"
  echo ""
  echo "To load the data in Gremlin Console:"
  echo "1. Start Gremlin Console: ./scripts/start-gremlin-console.sh"
  echo "2. Load the data: :load tools/project-eidolon-data.groovy"
  echo ""
  echo "To view in web interface:"
  echo "1. Start Gremlin Server: ./scripts/start-gremlin-server.sh"
  echo "2. Open: http://localhost:8182"
  echo ""
  echo "Sample queries:"
  echo "- g.V().hasLabel('throne')  // View all agents"
  echo "- g.V().hasLabel('entity').has('strain_amplitude', gt(0.8))  // High strain entities"
  echo "- g.V().hasLabel('throne').out('has_authority')  // Agent authority"
  echo "" 