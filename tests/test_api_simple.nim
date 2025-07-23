# Simple API Foundation Test
#
# This module tests the basic API foundation functionality without complex DateTime serialization.

import std/[times, tables, options, json, strutils, unittest]
import ../src/api/types
import ../src/types

const RUN_SIMPLE_API_TESTS* = true

when RUN_SIMPLE_API_TESTS:
  suite "Simple API Foundation Tests":
    test "API Types and Constructors":
      ## Test basic API type constructors
      
      # Test API response
      let response = newApiResponse[int](42)
      check response.success == true
      check response.data.isSome
      check response.data.get() == 42
      check response.error.isNone
      
      # Test error response
      let error_response = newApiResponse[int]("test_error")
      check error_response.success == false
      check error_response.data.isNone
      check error_response.error.isSome
      check error_response.error.get() == "test_error"
      
      # Test agent message
      let content = %*{"key": "value"}
      let message = newAgentMessage("test_agent", AgentMessageType.query_request, content, MessagePriority.high)
      check message.from_agent == "test_agent"
      check message.message_type == AgentMessageType.query_request
      check message.priority == MessagePriority.high
      check message.content == content
      
      # Test stream event
      let event = newStreamEvent(StreamEventType.entity_created, %*{"entity_id": "test_entity"})
      check event.event_type == StreamEventType.entity_created
      check event.data["entity_id"].getStr == "test_entity"
      
      # Test auth token
      let token = newAuthToken("test_agent", @["read_entities", "write_entities"], 24)
      check token.agent_id == "test_agent"
      check token.permissions.len == 2
      check "read_entities" in token.permissions
      check token.isValid == true
    
    test "API Type Validation":
      ## Test validation functions
      
      # Test create entity request validation
      let valid_request = CreateEntityRequest(
        name: "Test Entity",
        entity_type: concept_type,
        description: "A test entity",
        attributes: initTable[string, string]()
      )
      check valid_request.isValid == true
      
      let invalid_request = CreateEntityRequest(
        name: "",  # Empty name
        entity_type: concept_type,
        description: "A test entity",
        attributes: initTable[string, string]()
      )
      check invalid_request.isValid == false
      
      # Test update entity request validation
      let valid_update = UpdateEntityRequest(id: "test_id")
      check valid_update.isValid == true
      
      let invalid_update = UpdateEntityRequest(id: "")  # Empty ID
      check invalid_update.isValid == false
      
      # Test query request validation
      let valid_query = QueryRequest(limit: 100, offset: 0)
      check valid_query.isValid == true
      
      let invalid_query = QueryRequest(limit: -1, offset: 0)  # Negative limit
      check invalid_query.isValid == false
    
    test "Authentication and Authorization":
      ## Test authentication and permission system
      
      # Test token validation
      let token = newAuthToken("test_agent", @["read_entities"], 1)
      check token.isValid == true
      
      # Test permission checking
      check token.hasPermission(Permission.read_entities) == true
      check token.hasPermission(Permission.write_entities) == false
      check token.hasPermission(Permission.full_access) == false
      
      # Test full access token
      let full_access_token = newAuthToken("admin_agent", @["full_access"], 1)
      check full_access_token.hasPermission(Permission.read_entities) == true
      check full_access_token.hasPermission(Permission.write_entities) == true
      check full_access_token.hasPermission(Permission.delete_entities) == true
    
    test "Error Handling":
      ## Test error handling in API types
      
      # Test API error creation
      let error = newApiError(ErrorCode.invalid_request, "Test error message", "req_123")
      check error.error_code == "invalid_request"
      check error.error_message == "Test error message"
      check error.request_id.isSome
      check error.request_id.get() == "req_123"
      
      # Test error without request ID
      let error_no_id = newApiError(ErrorCode.permission_denied, "Permission denied")
      check error_no_id.request_id.isNone
    
    test "Agent Message Types":
      ## Test agent message type system
      
      # Test all message types
      let message_types = @[
        AgentMessageType.query_request, AgentMessageType.query_response, AgentMessageType.strain_alert, AgentMessageType.contradiction_detected,
        AgentMessageType.dream_cycle_start, AgentMessageType.dream_cycle_end, AgentMessageType.authority_request, AgentMessageType.authority_granted,
        AgentMessageType.graph_modification, AgentMessageType.event_notification, AgentMessageType.causal_inference
      ]
      
      for msg_type in message_types:
        let content = %*{"test": "data"}
        let message = newAgentMessage("test_agent", msg_type, content)
        check message.message_type == msg_type
        check message.content == content
    
    test "Stream Event Types":
      ## Test stream event type system
      
      # Test all event types
      let event_types = @[
        entity_created, entity_updated, entity_deleted,
        relationship_created, relationship_deleted,
        strain_changed, contradiction_detected,
        agent_activated, agent_deactivated,
        dream_cycle_started, dream_cycle_ended
      ]
      
      for event_type in event_types:
        let data = %*{"test": "data"}
        let event = newStreamEvent(event_type, data)
        check event.event_type == event_type
        check event.data == data
    
    test "Permission System":
      ## Test permission enumeration and checking
      
      # Test all permissions
      let permissions = @[
        read_entities, write_entities, delete_entities,
        read_relationships, write_relationships, delete_relationships,
        read_events, write_events, delete_events,
        read_thrones, write_thrones, delete_thrones,
        query_strain, modify_strain, full_access
      ]
      
      for permission in permissions:
        let token = newAuthToken("test_agent", @[$permission], 1)
        check token.hasPermission(permission) == true
    
    test "Query Filter System":
      ## Test query filter functionality
      
      # Test empty filter
      let empty_filter = newQueryFilter()
      check empty_filter.entity_types.len == 0
      check empty_filter.strain_threshold == 0.0
      check empty_filter.context_ids.len == 0
      
      # Test populated filter
      var populated_filter = newQueryFilter()
      populated_filter.entity_types = @[person, place]
      populated_filter.strain_threshold = 0.7
      populated_filter.context_ids = @["ctx_1", "ctx_2"]
      
      check populated_filter.entity_types.len == 2
      check populated_filter.strain_threshold == 0.7
      check populated_filter.context_ids.len == 2
      check person in populated_filter.entity_types
      check place in populated_filter.entity_types
      check "ctx_1" in populated_filter.context_ids
    
    test "Message Priority System":
      ## Test message priority levels
      
      # Test all priority levels
      let priorities = @[MessagePriority.low, MessagePriority.normal, MessagePriority.high, MessagePriority.critical, MessagePriority.emergency]
      
      for priority in priorities:
        let content = %*{"test": "data"}
        let message = newAgentMessage("test_agent", AgentMessageType.query_request, content, priority)
        check message.priority == priority
    
    test "Agent Status System":
      ## Test agent status functionality
      
      # Test agent status creation
      let status = AgentStatus(
        agent_id: "test_agent",
        agent_type: "dreamer",
        status: AgentStatusType.idle,
        last_active: now(),
        current_task: none(string),
        strain_level: 0.5,
        authority_level: 0.8
      )
      
      check status.agent_id == "test_agent"
      check status.agent_type == "dreamer"
      check status.status == AgentStatusType.idle
      check status.strain_level == 0.5
      check status.authority_level == 0.8
      
      # Test all status types
      let status_types = @[AgentStatusType.idle, AgentStatusType.active, AgentStatusType.busy, AgentStatusType.sleeping, AgentStatusType.error, AgentStatusType.disabled]
      
      for status_type in status_types:
        let test_status = AgentStatus(
          agent_id: "test_agent",
          agent_type: "test",
          status: status_type,
          last_active: now(),
          current_task: none(string),
          strain_level: 0.0,
          authority_level: 0.0
        )
        check test_status.status == status_type
    
    test "Request Context":
      ## Test request context functionality
      
      # Test request context creation
      let ctx = RequestContext(
        request_id: "req_123",
        agent_id: some("test_agent"),
        token: none(AuthToken),
        timestamp: now()
      )
      
      check ctx.request_id == "req_123"
      check ctx.agent_id.isSome
      check ctx.agent_id.get() == "test_agent"
      check ctx.token.isNone
      
      # Test with token
      let token = newAuthToken("test_agent", @["read_entities"], 1)
      let ctx_with_token = RequestContext(
        request_id: "req_456",
        agent_id: some("test_agent"),
        token: some(token),
        timestamp: now()
      )
      
      check ctx_with_token.token.isSome
      check ctx_with_token.token.get().agent_id == "test_agent" 