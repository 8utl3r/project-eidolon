# Knowledge Graph Integration Tests
#
# Tests for the integrated knowledge graph system that combines
# entities, relationships, and strain calculations.

import std/[unittest, times, options, tables]
import ../src/knowledge_graph/types
import ../src/knowledge_graph/operations
import ../src/entities/manager  # for getEntityCount
import ../src/types  # for EntityType and other core types
import ../src/strain/math

# Test configuration - set to false to disable tests for performance
const RUN_KNOWLEDGE_GRAPH_TESTS* = true

when RUN_KNOWLEDGE_GRAPH_TESTS:
  suite "Knowledge Graph Integration Tests":
    
    test "Knowledge Graph Creation":
      ## Test basic knowledge graph creation
      var graph = newKnowledgeGraph()
      
      check graph.entity_manager.getEntityCount() == 0
      check len(graph.strain_cache) == 0
      check graph.last_update > now() - initDuration(seconds = 5)
    
    test "Entity Addition to Graph":
      ## Test adding entities to the knowledge graph
      var graph = newKnowledgeGraph()
      
      let node = graph.addEntityToGraph("Test Entity", EntityType.concept_type, "A test entity")
      check node.isSome()
      check node.get().entity.name == "Test Entity"
      check node.get().entity.entity_type == EntityType.concept_type
      check node.get().confidence.entity_id == node.get().entity.id
      check node.get().connected_entities.len == 0
      check graph.entity_manager.getEntityCount() == 1
      check graph.strain_cache.hasKey(node.get().entity.id)
    
    test "Confidence Score Calculation":
      ## Test confidence score calculation
      var graph = newKnowledgeGraph()
      
      let node = graph.addEntityToGraph("Test Entity", EntityType.concept_type)
      check node.isSome()
      
      let confidence = graph.calculateConfidenceScore(node.get().entity.id)
      check confidence.isSome()
      check confidence.get().entity_id == node.get().entity.id
      check confidence.get().amplitude_score >= 0.0
      check confidence.get().amplitude_score <= 1.0
      check confidence.get().resistance_score >= 0.0
      check confidence.get().resistance_score <= 1.0
      check confidence.get().frequency_score >= 0.0
      check confidence.get().frequency_score <= 1.0
      check confidence.get().overall_score >= 0.0
      check confidence.get().overall_score <= 1.0
    
    test "Strain Flow Calculation":
      ## Test strain flow calculation between entities
      var graph = newKnowledgeGraph()
      
      let node1 = graph.addEntityToGraph("Entity 1", EntityType.person)
      let node2 = graph.addEntityToGraph("Entity 2", EntityType.place)
      check node1.isSome()
      check node2.isSome()
      
      # Create different strain values for the entities
      var strain1 = newStrainData()
      strain1.amplitude = 0.8
      strain1.resistance = 0.2
      strain1.direction = Vector3(x: 1.0, y: 0.0, z: 0.0)
      
      var strain2 = newStrainData()
      strain2.amplitude = 0.3
      strain2.resistance = 0.7
      strain2.direction = Vector3(x: 0.0, y: 1.0, z: 0.0)
      
      discard graph.updateEntityStrain(node1.get().entity.id, strain1)
      discard graph.updateEntityStrain(node2.get().entity.id, strain2)
      
      let flow = graph.calculateStrainFlow(node1.get().entity.id, node2.get().entity.id)
      check flow.isSome()
      check flow.get().from_entity_id == node1.get().entity.id
      check flow.get().to_entity_id == node2.get().entity.id
      check flow.get().flow_strength > 0.0
      check flow.get().flow_strength <= 1.0
      check flow.get().flow_direction.x == -1.0  # From (1,0,0) to (0,1,0)
      check flow.get().flow_direction.y == 1.0
    
    test "Relationship Addition and Strain Propagation":
      ## Test adding relationships and strain propagation
      var graph = newKnowledgeGraph()
      
      let node1 = graph.addEntityToGraph("Person", EntityType.person)
      let node2 = graph.addEntityToGraph("Place", EntityType.place)
      check node1.isSome()
      check node2.isSome()
      
      # Set different initial strain values
      var strain1 = newStrainData()
      strain1.amplitude = 0.9
      strain1.resistance = 0.1
      
      var strain2 = newStrainData()
      strain2.amplitude = 0.2
      strain2.resistance = 0.8
      
      discard graph.updateEntityStrain(node1.get().entity.id, strain1)
      discard graph.updateEntityStrain(node2.get().entity.id, strain2)
      
      # Get initial strain values
      let initial_strain1 = graph.entity_manager.getEntity(node1.get().entity.id).get().strain
      let initial_strain2 = graph.entity_manager.getEntity(node2.get().entity.id).get().strain
      
      # Add relationship
      let relationship = graph.addRelationshipToGraph(node1.get().entity.id, node2.get().entity.id, "lives_at")
      check relationship.isSome()
      
      # Check that strain propagated
      let final_strain2 = graph.entity_manager.getEntity(node2.get().entity.id).get().strain
      check final_strain2.amplitude > initial_strain2.amplitude  # Should have increased
      check final_strain2.amplitude <= 1.0  # Should be clamped
    
    test "Graph Node Retrieval":
      ## Test retrieving graph nodes with full information
      var graph = newKnowledgeGraph()
      
      let node1 = graph.addEntityToGraph("Entity 1", EntityType.concept_type)
      let node2 = graph.addEntityToGraph("Entity 2", EntityType.concept_type)
      check node1.isSome()
      check node2.isSome()
      
      # Add relationship
      discard graph.addRelationshipToGraph(node1.get().entity.id, node2.get().entity.id, "related_to")
      
      # Retrieve graph nodes
      let retrieved_node1 = graph.getGraphNode(node1.get().entity.id)
      let retrieved_node2 = graph.getGraphNode(node2.get().entity.id)
      
      check retrieved_node1.isSome()
      check retrieved_node2.isSome()
      check retrieved_node1.get().connected_entities.len == 1
      check retrieved_node2.get().connected_entities.len == 1
      check retrieved_node1.get().connected_entities[0] == node2.get().entity.id
      check retrieved_node2.get().connected_entities[0] == node1.get().entity.id
      check retrieved_node1.get().confidence.entity_id == node1.get().entity.id
      check retrieved_node2.get().confidence.entity_id == node2.get().entity.id
    
    test "High Confidence Entity Retrieval":
      ## Test retrieving entities with high confidence scores
      var graph = newKnowledgeGraph()
      
      # Add entities with different strain values
      let node1 = graph.addEntityToGraph("High Confidence", EntityType.concept_type)
      let node2 = graph.addEntityToGraph("Low Confidence", EntityType.concept_type)
      check node1.isSome()
      check node2.isSome()
      
      # Set high confidence strain for first entity
      var high_strain = newStrainData()
      high_strain.amplitude = 0.9
      high_strain.resistance = 0.1
      high_strain.frequency = 8
      
      # Set low confidence strain for second entity
      var low_strain = newStrainData()
      low_strain.amplitude = 0.2
      low_strain.resistance = 0.8
      low_strain.frequency = 1
      
      discard graph.updateEntityStrain(node1.get().entity.id, high_strain)
      discard graph.updateEntityStrain(node2.get().entity.id, low_strain)
      
      # Get high confidence entities
      let high_confidence = graph.getHighConfidenceEntities(0.7)
      check high_confidence.len >= 1
      
      # Check that high confidence entity is included
      var found_high = false
      for node in high_confidence:
        if node.entity.id == node1.get().entity.id:
          found_high = true
          check node.confidence.overall_score >= 0.7
          break
      check found_high
    
    test "Strain Flow Network Analysis":
      ## Test analyzing strain flow networks
      var graph = newKnowledgeGraph()
      
      # Create a simple network: A -> B -> C
      let node_a = graph.addEntityToGraph("A", EntityType.concept_type)
      let node_b = graph.addEntityToGraph("B", EntityType.concept_type)
      let node_c = graph.addEntityToGraph("C", EntityType.concept_type)
      check node_a.isSome()
      check node_b.isSome()
      check node_c.isSome()
      
      # Set different strain values
      var strain_a = newStrainData()
      strain_a.amplitude = 0.8
      var strain_b = newStrainData()
      strain_b.amplitude = 0.5
      var strain_c = newStrainData()
      strain_c.amplitude = 0.3
      
      discard graph.updateEntityStrain(node_a.get().entity.id, strain_a)
      discard graph.updateEntityStrain(node_b.get().entity.id, strain_b)
      discard graph.updateEntityStrain(node_c.get().entity.id, strain_c)
      
      # Add relationships
      discard graph.addRelationshipToGraph(node_a.get().entity.id, node_b.get().entity.id, "connects_to")
      discard graph.addRelationshipToGraph(node_b.get().entity.id, node_c.get().entity.id, "connects_to")
      
      # Analyze strain flow network from A
      let flows = graph.getStrainFlowNetwork(node_a.get().entity.id, 2)
      check flows.len >= 2  # Should have flows to both B and C
      
      # Check that flows are properly calculated
      for flow in flows:
        check flow.from_entity_id == node_a.get().entity.id or flow.from_entity_id == node_b.get().entity.id
        check flow.to_entity_id == node_b.get().entity.id or flow.to_entity_id == node_c.get().entity.id
        check flow.flow_strength > 0.0
        check flow.flow_strength <= 1.0
    
    test "Strain Propagation Depth Control":
      ## Test that strain propagation respects depth limits
      var graph = newKnowledgeGraph()
      
      # Create a chain: A -> B -> C -> D
      let node_a = graph.addEntityToGraph("A", EntityType.concept_type)
      let node_b = graph.addEntityToGraph("B", EntityType.concept_type)
      let node_c = graph.addEntityToGraph("C", EntityType.concept_type)
      let node_d = graph.addEntityToGraph("D", EntityType.concept_type)
      check node_a.isSome()
      check node_b.isSome()
      check node_c.isSome()
      check node_d.isSome()
      
      # Set high strain for A
      var high_strain = newStrainData()
      high_strain.amplitude = 0.9
      discard graph.updateEntityStrain(node_a.get().entity.id, high_strain)
      
      # Add relationships
      discard graph.addRelationshipToGraph(node_a.get().entity.id, node_b.get().entity.id, "connects_to")
      discard graph.addRelationshipToGraph(node_b.get().entity.id, node_c.get().entity.id, "connects_to")
      discard graph.addRelationshipToGraph(node_c.get().entity.id, node_d.get().entity.id, "connects_to")
      
      # Propagate with limited depth
      discard graph.propagateStrain(node_a.get().entity.id, 2)
      
      # Check that strain propagated to B and C but not D
      let strain_b = graph.entity_manager.getEntity(node_b.get().entity.id).get().strain
      let strain_c = graph.entity_manager.getEntity(node_c.get().entity.id).get().strain
      let strain_d = graph.entity_manager.getEntity(node_d.get().entity.id).get().strain
      
      check strain_b.amplitude > 0.0  # Should have propagated
      check strain_c.amplitude > 0.0  # Should have propagated
      check abs(strain_d.amplitude) < 1e-2  # Should not have propagated (depth limit)
    
    test "Strain Cache Management":
      ## Test that strain cache is properly maintained
      var graph = newKnowledgeGraph()
      
      let node = graph.addEntityToGraph("Test Entity", EntityType.concept_type)
      check node.isSome()
      
      # Check initial cache entry
      check graph.strain_cache.hasKey(node.get().entity.id)
      check graph.strain_cache[node.get().entity.id].amplitude == 0.0
      
      # Update strain and check cache
      var new_strain = newStrainData()
      new_strain.amplitude = 0.7
      new_strain.resistance = 0.3
      
      discard graph.updateEntityStrain(node.get().entity.id, new_strain)
      check graph.strain_cache[node.get().entity.id].amplitude == 0.7
      check graph.strain_cache[node.get().entity.id].resistance == 0.3
    
    test "Error Handling":
      ## Test error handling for invalid operations
      var graph = newKnowledgeGraph()
      
      # Test with non-existent entity
      let non_existent_flow = graph.calculateStrainFlow("nonexistent1", "nonexistent2")
      check non_existent_flow.isNone()
      
      let non_existent_confidence = graph.calculateConfidenceScore("nonexistent")
      check non_existent_confidence.isNone()
      
      let non_existent_node = graph.getGraphNode("nonexistent")
      check non_existent_node.isNone()
      
      # Test invalid strain update
      let invalid_update = graph.updateEntityStrain("nonexistent", newStrainData())
      check invalid_update == false
      
      # Test invalid relationship
      let invalid_relationship = graph.addRelationshipToGraph("nonexistent1", "nonexistent2", "test")
      check invalid_relationship.isNone() 