# Database Operations Test Suite
#
# This module tests the comprehensive database operations layer including
# CRUD operations, strain-aware queries, and advanced database management.

import std/[times, tables, options, sequtils, unittest]
import ../src/database/operations
import ../src/types

const RUN_DATABASE_TESTS* = true  # Set to false for performance

when RUN_DATABASE_TESTS:
  suite "Database Operations Tests":
    setup:
      # Initialize test database
      var db = newDatabaseOperations()
    
    test "Entity CRUD Operations":
      ## Test basic entity creation, reading, updating, and deletion
      
      # Create entity
      let entity = db.createEntity("Test Entity", concept_type, "A test entity")
      check entity.id.len > 0
      check entity.name == "Test Entity"
      check entity.entity_type == concept_type
      check entity.description == "A test entity"
      
      # Get entity
      let retrieved = db.getEntity(entity.id)
      check retrieved.isSome
      check retrieved.get().id == entity.id
      check retrieved.get().name == entity.name
      
      # Update entity
      var updated_entity = entity
      updated_entity.name = "Updated Test Entity"
      updated_entity.description = "An updated test entity"
      let update_success = db.updateEntity(updated_entity)
      check update_success == true
      
      # Verify update
      let updated_retrieved = db.getEntity(entity.id)
      check updated_retrieved.isSome
      check updated_retrieved.get().name == "Updated Test Entity"
      check updated_retrieved.get().description == "An updated test entity"
      
      # Delete entity
      let delete_success = db.deleteEntity(entity.id)
      check delete_success == true
      
      # Verify deletion
      let deleted_retrieved = db.getEntity(entity.id)
      check deleted_retrieved.isNone
    
    test "Relationship Operations":
      ## Test relationship creation and querying
      
      # Create entities
      let entity1 = db.createEntity("Entity 1", concept_type, "First entity")
      let entity2 = db.createEntity("Entity 2", concept_type, "Second entity")
      
      # Create relationship
      let relationship = db.createRelationship(entity1.id, entity2.id, "relates_to")
      check relationship.isSome
      check relationship.get().from_entity == entity1.id
      check relationship.get().to_entity == entity2.id
      check relationship.get().relationship_type == "relates_to"
      
      # Get relationships
      let relationships1 = db.getRelationships(entity1.id)
      check relationships1.len == 1
      check relationships1[0].id == relationship.get().id
      
      let relationships2 = db.getRelationships(entity2.id)
      check relationships2.len == 1
      check relationships2[0].id == relationship.get().id
      
      # Get relationships by type
      let typed_relationships = db.getRelationshipsByType(entity1.id, "relates_to")
      check typed_relationships.len == 1
      check typed_relationships[0].relationship_type == "relates_to"
    
    test "Event Operations":
      ## Test event creation and management
      
      # Create entities for events
      let entity1 = db.createEntity("Event Entity 1", person, "Person entity")
      let entity2 = db.createEntity("Event Entity 2", place, "Place entity")
      
      # Create event
      let event = db.createEvent("test_event", "A test event", @[entity1.id, entity2.id])
      check event.id.len > 0
      check event.event_type == "test_event"
      check event.description == "A test event"
      check event.entities.len == 2
      check entity1.id in event.entities
      check entity2.id in event.entities
      
      # Get event
      let retrieved_event = db.getEvent(event.id)
      check retrieved_event.isSome
      check retrieved_event.get().id == event.id
      
      # Update event
      var updated_event = event
      updated_event.description = "An updated test event"
      let update_success = db.updateEvent(updated_event)
      check update_success == true
      
      # Delete event
      let delete_success = db.deleteEvent(event.id)
      check delete_success == true
      
      # Verify deletion
      let deleted_event = db.getEvent(event.id)
      check deleted_event.isNone
    
    test "Causal Relationship Operations":
      ## Test causal relationship creation and querying
      
      # Create events
      let cause_event = db.createEvent("cause", "Cause event")
      let effect_event = db.createEvent("effect", "Effect event")
      
      # Create causal relationship
      let causal = db.createCausalRelationship(cause_event.id, effect_event.id, 0.8)
      check causal.id.len > 0
      check causal.cause_event_id == cause_event.id
      check causal.effect_event_id == effect_event.id
      check causal.confidence == 0.8
      
      # Get causal relationships
      let cause_relationships = db.getCausalRelationships(cause_event.id)
      check cause_relationships.len == 1
      check cause_relationships[0].id == causal.id
      
      let effect_relationships = db.getCausalRelationships(effect_event.id)
      check effect_relationships.len == 1
      check effect_relationships[0].id == causal.id
    
    test "Embedding Operations":
      ## Test embedding creation and retrieval
      
      # Create entity
      let entity = db.createEntity("Embedding Entity", concept_type, "Entity for embeddings")
      
      # Create embedding
      let vector = @[0.1, 0.2, 0.3, 0.4, 0.5]
      let embedding = db.createEmbedding(entity.id, vector, "test_embedding")
      check embedding.id.len > 0
      check embedding.entity_id == entity.id
      check embedding.vector == vector
      check embedding.embedding_type == "test_embedding"
      
      # Get embedding
      let retrieved_embedding = db.getEmbedding(entity.id, "test_embedding")
      check retrieved_embedding.isSome
      check retrieved_embedding.get().id == embedding.id
      check retrieved_embedding.get().vector == vector
    
    test "Throne and Domain Authority Operations":
      ## Test throne node and domain authority management
      
      # Create throne node
      let throne = db.createThroneNode("ThroneOfTheMathematician", 0.9)
      check throne.id.len > 0
      check throne.throne_type == "ThroneOfTheMathematician"
      check throne.domain_authority == 0.9
      
      # Get throne node
      let retrieved_throne = db.getThroneNode(throne.id)
      check retrieved_throne.isSome
      check retrieved_throne.get().id == throne.id
      
      # Create entity and connect to throne
      let entity = db.createEntity("Throne Entity", concept_type, "Entity for throne")
      let connect_success = db.connectEntityToThrone(entity.id, throne.id)
      check connect_success == true
      
      # Verify connection
      let updated_throne = db.getThroneNode(throne.id)
      check updated_throne.isSome
      check entity.id in updated_throne.get().connected_entities
      
      # Create domain authority
      let authority = db.createDomainAuthority(throne.id, "mathematician_agent", 0.8, @["rule1", "rule2"])
      check authority.id.len > 0
      check authority.throne_id == throne.id
      check authority.agent_id == "mathematician_agent"
      check authority.authority_level == 0.8
      check authority.domain_rules.len == 2
      check "rule1" in authority.domain_rules
      check "rule2" in authority.domain_rules
    
    test "Strain-Aware Query System":
      ## Test strain-aware querying capabilities
      
      # Create entities with different strain values
      let entity1 = db.createEntity("High Strain Entity", concept_type, "High strain")
      let entity2 = db.createEntity("Low Strain Entity", concept_type, "Low strain")
      let entity3 = db.createEntity("Medium Strain Entity", concept_type, "Medium strain")
      
      # Set strain values
      var high_strain = entity1
      high_strain.strain.amplitude = 0.9
      high_strain.strain.resistance = 0.1
      discard db.updateEntity(high_strain)
      
      var low_strain = entity2
      low_strain.strain.amplitude = 0.2
      low_strain.strain.resistance = 0.8
      discard db.updateEntity(low_strain)
      
      var medium_strain = entity3
      medium_strain.strain.amplitude = 0.5
      medium_strain.strain.resistance = 0.5
      discard db.updateEntity(medium_strain)
      
      # Test strain summary calculation
      let entities = @[high_strain, low_strain, medium_strain]
      let summary = db.calculateStrainSummary(entities)
      check summary.avg_amplitude > 0.5
      check summary.max_amplitude == 0.9
      check summary.min_amplitude == 0.2
      check summary.high_strain_count == 1
      check summary.low_strain_count == 1
      
      # Test high strain query
      let high_strain_result = db.queryHighStrainEntities(0.7)
      check high_strain_result.total_count == 1
      check high_strain_result.items[0].id == entity1.id
      check high_strain_result.strain_summary.high_strain_count == 1
      
      # Test low strain query
      let low_strain_result = db.queryLowStrainEntities(0.3)
      check low_strain_result.total_count == 1
      check low_strain_result.items[0].id == entity2.id
      check low_strain_result.strain_summary.low_strain_count == 1
      
      # Test query by type
      let concept_result = db.queryEntitiesByType(concept_type)
      check concept_result.total_count == 3
      check concept_result.strain_summary.avg_amplitude > 0.0
    
    test "Connected Entities Query":
      ## Test querying connected entities
      
      # Create entities
      let entity1 = db.createEntity("Central Entity", concept_type, "Central entity")
      let entity2 = db.createEntity("Connected Entity 1", concept_type, "First connected")
      let entity3 = db.createEntity("Connected Entity 2", concept_type, "Second connected")
      let entity4 = db.createEntity("Isolated Entity", concept_type, "Isolated entity")
      
      # Create relationships
      discard db.createRelationship(entity1.id, entity2.id, "connects")
      discard db.createRelationship(entity1.id, entity3.id, "connects")
      
      # Query connected entities
      let connected_result = db.queryConnectedEntities(entity1.id, 1)
      check connected_result.total_count == 2
      
      let connected_ids = connected_result.items.map(proc(e: Entity): string = e.id)
      check entity2.id in connected_ids
      check entity3.id in connected_ids
      check entity4.id notin connected_ids
    
    test "Database Statistics":
      ## Test database statistics and analytics
      
      # Create various entities and relationships
      let entity1 = db.createEntity("Stats Entity 1", person, "Person for stats")
      let entity2 = db.createEntity("Stats Entity 2", place, "Place for stats")
      let entity3 = db.createEntity("Stats Entity 3", concept_type, "Concept for stats")
      
      discard db.createRelationship(entity1.id, entity2.id, "lives_in")
      discard db.createRelationship(entity2.id, entity3.id, "contains")
      
      let event = db.createEvent("stats_event", "Event for stats", @[entity1.id])
      let causal = db.createCausalRelationship(event.id, event.id, 0.5)
      let embedding = db.createEmbedding(entity1.id, @[0.1, 0.2], "stats_embedding")
      let throne = db.createThroneNode("StatsThrone", 0.8)
      let authority = db.createDomainAuthority(throne.id, "stats_agent", 0.7)
      
      # Get database stats
      let stats = db.getDatabaseStats()
      check stats["entities"] >= 3
      check stats["relationships"] >= 2
      check stats["events"] >= 1
      check stats["causal_relationships"] >= 1
      check stats["embeddings"] >= 1
      check stats["throne_nodes"] >= 1
      check stats["domain_authorities"] >= 1
      
      # Get strain distribution
      let distribution = db.getStrainDistribution()
      check distribution["very_low"] >= 0
      check distribution["low"] >= 0
      check distribution["medium"] >= 0
      check distribution["high"] >= 0
      check distribution["very_high"] >= 0
      
      # Verify total distribution equals entity count
      let total_distribution = distribution["very_low"] + distribution["low"] + 
                              distribution["medium"] + distribution["high"] + distribution["very_high"]
      check total_distribution == stats["entities"]
    
    test "Query Filter System":
      ## Test advanced query filtering
      
      # Create entities with different characteristics
      let person_entity = db.createEntity("Person Entity", person, "A person")
      let place_entity = db.createEntity("Place Entity", place, "A place")
      let concept_entity = db.createEntity("Concept Entity", concept_type, "A concept")
      
      # Set different strain values
      var high_strain_person = person_entity
      high_strain_person.strain.amplitude = 0.8
      discard db.updateEntity(high_strain_person)
      
      var low_strain_place = place_entity
      low_strain_place.strain.amplitude = 0.3
      discard db.updateEntity(low_strain_place)
      
      # Test filter by entity type
      var person_filter = QueryFilter()
      person_filter.entity_types = @[person]
      let person_result = db.queryEntities(person_filter)
      check person_result.total_count == 1
      check person_result.items[0].entity_type == person
      
      # Test filter by strain threshold
      var high_strain_filter = QueryFilter()
      high_strain_filter.strain_threshold = 0.7
      let high_strain_result = db.queryEntities(high_strain_filter)
      check high_strain_result.total_count == 1
      check high_strain_result.items[0].strain.amplitude >= 0.7
      
      # Test combined filter
      var combined_filter = QueryFilter()
      combined_filter.entity_types = @[person, place]
      combined_filter.strain_threshold = 0.5
      let combined_result = db.queryEntities(combined_filter)
      check combined_result.total_count == 1  # Only person meets both criteria
      check combined_result.items[0].entity_type == person 