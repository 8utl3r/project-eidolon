# Entity Management Tests
#
# Tests for the entity management system.
# Tests are modular and can be enabled/disabled for performance.

import std/[unittest, times, strutils, options]
import ../src/types
import ../src/entities/manager

# Test configuration - set to false to disable tests for performance
const RUN_ENTITY_TESTS* = true

when RUN_ENTITY_TESTS:
  suite "Entity Management Tests":
    
    test "Entity Creation":
      ## Test basic entity creation
      var manager = newEntityManager()
      
      let entity = manager.createEntity("Test Person", EntityType.person, "A test person")
      check startsWith(entity.id, "entity_")
      check entity.name == "Test Person"
      check entity.entity_type == EntityType.person
      check entity.description == "A test person"
      check entity.strain.amplitude == 0.0
      check entity.strain.resistance == 0.5
      check entity.contexts.len == 0
      check manager.getEntityCount() == 1
    
    test "Entity Retrieval":
      ## Test entity retrieval by ID
      var manager = newEntityManager()
      
      let entity = manager.createEntity("Test Entity", EntityType.concept_type)
      let retrieved = manager.getEntity(entity.id)
      
      check retrieved.isSome()
      check retrieved.get().id == entity.id
      check retrieved.get().name == "Test Entity"
      
      # Test non-existent entity
      let not_found = manager.getEntity("nonexistent")
      check not_found.isNone()
    
    test "Entity Update":
      ## Test entity update functionality
      var manager = newEntityManager()
      
      let entity = manager.createEntity("Original Name", EntityType.object_type)
      var updated_entity = entity
      updated_entity.name = "Updated Name"
      updated_entity.description = "Updated description"
      
      let success = manager.updateEntity(updated_entity)
      check success == true
      
      let retrieved = manager.getEntity(entity.id)
      check retrieved.get().name == "Updated Name"
      check retrieved.get().description == "Updated description"
      check retrieved.get().modified > entity.modified
    
    test "Entity Deletion":
      ## Test entity deletion
      var manager = newEntityManager()
      
      let entity = manager.createEntity("To Delete", EntityType.event)
      check manager.getEntityCount() == 1
      
      let success = manager.deleteEntity(entity.id)
      check success == true
      check manager.getEntityCount() == 0
      
      let retrieved = manager.getEntity(entity.id)
      check retrieved.isNone()
      
      # Test deleting non-existent entity
      let delete_fail = manager.deleteEntity("nonexistent")
      check delete_fail == false
    
    test "Relationship Creation":
      ## Test relationship creation between entities
      var manager = newEntityManager()
      
      let entity1 = manager.createEntity("Entity 1", EntityType.person)
      let entity2 = manager.createEntity("Entity 2", EntityType.place)
      
      let relationship = manager.createRelationship(entity1.id, entity2.id, "lives_at")
      check relationship.isSome()
      check relationship.get().from_entity == entity1.id
      check relationship.get().to_entity == entity2.id
      check relationship.get().relationship_type == "lives_at"
      check manager.getRelationshipCount() == 1
      
      # Test creating relationship with non-existent entities
      let bad_relationship = manager.createRelationship("nonexistent", entity2.id, "test")
      check bad_relationship.isNone()
    
    test "Relationship Retrieval":
      ## Test retrieving relationships for an entity
      var manager = newEntityManager()
      
      let entity1 = manager.createEntity("Entity 1", EntityType.person)
      let entity2 = manager.createEntity("Entity 2", EntityType.place)
      let entity3 = manager.createEntity("Entity 3", EntityType.concept_type)
      
      discard manager.createRelationship(entity1.id, entity2.id, "lives_at")
      discard manager.createRelationship(entity1.id, entity3.id, "knows_about")
      
      let relationships = manager.getRelationships(entity1.id)
      check relationships.len == 2
      
      let entity2_relationships = manager.getRelationships(entity2.id)
      check entity2_relationships.len == 1
      check entity2_relationships[0].relationship_type == "lives_at"
    
    test "Context Management":
      ## Test context creation and entity addition
      var manager = newEntityManager()
      
      let context = manager.createContext("Test Context", "A test context")
      check startsWith(context.id, "ctx_")
      check context.name == "Test Context"
      check context.description == "A test context"
      check context.entities.len == 0
      check manager.getContextCount() == 1
      
      let entity = manager.createEntity("Test Entity", EntityType.concept_type)
      let success = manager.addEntityToContext(entity.id, context.id)
      check success == true
      
      # Check that entity was added to context
      let updated_context = manager.getContext(context.id)
      check updated_context.isSome()
      check updated_context.get().entities.len == 1
      check updated_context.get().entities[0] == entity.id
      
      # Check that context was added to entity
      let updated_entity = manager.getEntity(entity.id)
      check updated_entity.isSome()
      check updated_entity.get().contexts.len == 1
      check updated_entity.get().contexts[0] == context.id
      check updated_entity.get().strain.frequency == 1
    
    test "Entity Search":
      ## Test entity search functionality
      var manager = newEntityManager()
      
      let entity1 = manager.createEntity("Alice Johnson", EntityType.person, "A software developer")
      let entity2 = manager.createEntity("Bob Smith", EntityType.person, "A data scientist")
      let entity3 = manager.createEntity("Python Programming", EntityType.concept_type, "Programming language")
      
      # Search by name
      let alice_results = manager.searchEntities("Alice")
      check alice_results.len == 1
      check alice_results[0].name == "Alice Johnson"
      
      # Search by description
      let developer_results = manager.searchEntities("developer")
      check developer_results.len == 1
      check developer_results[0].name == "Alice Johnson"
      
      # Search by concept
      let python_results = manager.searchEntities("Python")
      check python_results.len == 1
      check python_results[0].name == "Python Programming"
      
      # Search with no results
      let no_results = manager.searchEntities("nonexistent")
      check no_results.len == 0
    
    test "Strain Data Integration":
      ## Test that entities have proper strain data
      var manager = newEntityManager()
      
      let entity = manager.createEntity("Test Entity", EntityType.concept_type)
      check entity.strain.amplitude == 0.0
      check entity.strain.resistance == 0.5
      check entity.strain.frequency == 0
      check entity.strain.access_count == 0
      check entity.strain.direction.x == 0.0
      check entity.strain.direction.y == 0.0
      check entity.strain.direction.z == 0.0
      
      # Test that frequency updates when adding to context
      let context = manager.createContext("Test Context")
      discard manager.addEntityToContext(entity.id, context.id)
      
      let updated_entity = manager.getEntity(entity.id)
      check updated_entity.isSome()
      check updated_entity.get().strain.frequency == 1
    
    test "ID Generation":
      ## Test that IDs are generated correctly and uniquely
      var manager = newEntityManager()
      
      let entity1 = manager.createEntity("Entity 1", EntityType.person)
      let entity2 = manager.createEntity("Entity 2", EntityType.person)
      let entity3 = manager.createEntity("Entity 3", EntityType.person)
      
      check entity1.id == "entity_1"
      check entity2.id == "entity_2"
      check entity3.id == "entity_3"
      
      let relationship = manager.createRelationship(entity1.id, entity2.id, "test")
      check relationship.get().id == "rel_1"
      
      let context = manager.createContext("Test Context")
      check context.id == "ctx_1" 