# API Types and Structures
#
# This module defines types for the REST API foundation, including
# request/response types, agent communication protocols, and event streaming.

import std/[times, tables, options, json, strutils, unittest]
import ../types
import ../database/operations

type
  # HTTP API Types
  ApiResponse*[T] = object
    ## Standard API response wrapper
    success*: bool
    data*: Option[T]
    error*: Option[string]
    timestamp*: DateTime
    request_id*: string

  ApiRequest* = object
    ## Standard API request wrapper
    request_id*: string
    timestamp*: DateTime
    agent_id*: Option[string]
    session_id*: Option[string]

  # Entity API Types
  CreateEntityRequest* = object
    name*: string
    entity_type*: EntityType
    description*: string
    attributes*: Table[string, string]

  UpdateEntityRequest* = object
    id*: string
    name*: Option[string]
    description*: Option[string]
    attributes*: Option[Table[string, string]]
    strain*: Option[StrainData]

  EntityResponse* = object
    entity*: Entity
    relationships*: seq[Relationship]
    strain_summary*: StrainSummary

  # Query API Types
  QueryFilter* = object
    ## Filter criteria for entity queries
    entity_types*: seq[EntityType]
    strain_threshold*: float
    context_ids*: seq[string]
    name_pattern*: Option[string]
    created_after*: Option[DateTime]
    created_before*: Option[DateTime]

  StrainSummary* = object
    ## Summary of strain metrics across entities
    total_entities*: int
    average_amplitude*: float
    average_resistance*: float
    total_frequency*: int
    strain_distribution*: Table[string, int]  # amplitude ranges -> count

  QueryRequest* = object
    filter*: QueryFilter
    limit*: int
    offset*: int
    include_relationships*: bool
    include_strain_summary*: bool

  QueryResponse* = object
    entities*: seq[Entity]
    total_count*: int
    strain_summary*: StrainSummary
    query_time*: float
    relationships*: seq[Relationship]

  # Agent Communication Types
  AgentMessage* = object
    ## Message between agents
    message_id*: string
    from_agent*: string
    to_agent*: Option[string]  # None for broadcast
    message_type*: AgentMessageType
    content*: JsonNode
    priority*: MessagePriority
    timestamp*: DateTime
    expires_at*: Option[DateTime]

  AgentMessageType* = enum
    ## Types of agent messages
    query_request, query_response, strain_alert, contradiction_detected,
    dream_cycle_start, dream_cycle_end, authority_request, authority_granted,
    graph_modification, event_notification, causal_inference

  MessagePriority* = enum
    ## Message priority levels
    low, normal, high, critical, emergency

  AgentStatus* = object
    ## Agent status information
    agent_id*: string
    agent_type*: string
    status*: AgentStatusType
    last_active*: DateTime
    current_task*: Option[string]
    strain_level*: float
    authority_level*: float

  AgentStatusType* = enum
    ## Agent status types
    idle, active, busy, sleeping, error, disabled

  # Event Streaming Types
  StreamEvent* = object
    ## Real-time streaming event
    event_id*: string
    event_type*: StreamEventType
    entity_id*: Option[string]
    agent_id*: Option[string]
    data*: JsonNode
    timestamp*: DateTime

  StreamEventType* = enum
    ## Types of streaming events
    entity_created, entity_updated, entity_deleted,
    relationship_created, relationship_deleted,
    strain_changed, contradiction_detected,
    agent_activated, agent_deactivated,
    dream_cycle_started, dream_cycle_ended

  # Authentication and Authorization Types
  AuthToken* = object
    ## Authentication token
    token*: string
    agent_id*: string
    permissions*: seq[string]
    created_at*: DateTime
    expires_at*: DateTime

  Permission* = enum
    ## API permissions
    read_entities, write_entities, delete_entities,
    read_relationships, write_relationships, delete_relationships,
    read_events, write_events, delete_events,
    read_thrones, write_thrones, delete_thrones,
    query_strain, modify_strain, full_access

  # Request Context Types
  RequestContext* = object
    ## Context for API requests
    request_id*: string
    agent_id*: Option[string]
    token*: Option[AuthToken]
    timestamp*: DateTime

  # Error Types
  ApiError* = object
    ## API error information
    error_code*: string
    error_message*: string
    details*: Option[JsonNode]
    timestamp*: DateTime
    request_id*: Option[string]

  ErrorCode* = enum
    ## Standard error codes
    invalid_request, entity_not_found, relationship_not_found,
    permission_denied, strain_calculation_error, agent_not_found,
    invalid_token, rate_limit_exceeded, internal_error

# Constructor Functions
proc newApiResponse*[T](data: T): ApiResponse[T] =
  ## Create a successful API response
  return ApiResponse[T](
    success: true,
    data: some(data),
    error: none(string),
    timestamp: now(),
    request_id: ""
  )

proc newApiResponse*[T](error: string): ApiResponse[T] =
  ## Create an error API response
  return ApiResponse[T](
    success: false,
    data: none(T),
    error: some(error),
    timestamp: now(),
    request_id: ""
  )

proc newAgentMessage*(from_agent: string, message_type: AgentMessageType, 
                     content: JsonNode, priority: MessagePriority = normal): AgentMessage =
  ## Create a new agent message
  return AgentMessage(
    message_id: "msg_" & $now().toTime().toUnix(),
    from_agent: from_agent,
    to_agent: none(string),
    message_type: message_type,
    content: content,
    priority: priority,
    timestamp: now(),
    expires_at: none(DateTime)
  )

proc newStreamEvent*(event_type: StreamEventType, data: JsonNode): StreamEvent =
  ## Create a new streaming event
  return StreamEvent(
    event_id: "stream_" & $now().toTime().toUnix(),
    event_type: event_type,
    entity_id: none(string),
    agent_id: none(string),
    data: data,
    timestamp: now()
  )

proc newAuthToken*(agent_id: string, permissions: seq[string], 
                  expires_in_hours: int = 24): AuthToken =
  ## Create a new authentication token
  let now_time = now()
  return AuthToken(
    token: "token_" & $now_time.toTime().toUnix() & "_" & agent_id,
    agent_id: agent_id,
    permissions: permissions,
    created_at: now_time,
    expires_at: now_time + initDuration(hours = expires_in_hours)
  )

proc newApiError*(error_code: ErrorCode, message: string, 
                 request_id: string = ""): ApiError =
  ## Create a new API error
  return ApiError(
    error_code: $error_code,
    error_message: message,
    details: none(JsonNode),
    timestamp: now(),
    request_id: if request_id.len > 0: some(request_id) else: none(string)
  )

proc newQueryFilter*(): QueryFilter =
  ## Create a new empty query filter
  return QueryFilter(
    entity_types: @[],
    strain_threshold: 0.0,
    context_ids: @[],
    name_pattern: none(string),
    created_after: none(DateTime),
    created_before: none(DateTime)
  )



# JSON Serialization Helpers
proc toJson*[T](response: ApiResponse[T]): JsonNode =
  ## Convert API response to JSON
  var json = %*{
    "success": response.success,
    "request_id": response.request_id
  }
  json["timestamp"] = %($response.timestamp)
  
  if response.data.isSome:
    when T is Entity:
      json["data"] = response.data.get().toJson
    elif T is Relationship:
      json["data"] = response.data.get().toJson
    elif T is StrainData:
      json["data"] = response.data.get().toJson
    else:
      json["data"] = %response.data.get()
  else:
    json["data"] = newJNull()
  
  if response.error.isSome:
    json["error"] = %response.error.get()
  else:
    json["error"] = newJNull()
  
  return json

# Custom JSON serialization for types with DateTime fields
proc toJson*(strain: StrainData): JsonNode =
  result = %*{
    "amplitude": strain.amplitude,
    "resistance": strain.resistance,
    "frequency": strain.frequency,
    "access_count": strain.access_count
  }
  result["direction"] = %*{
    "x": strain.direction.x,
    "y": strain.direction.y,
    "z": strain.direction.z
  }
  result["last_accessed"] = %($strain.last_accessed)

proc toJson*(entity: Entity): JsonNode =
  result = %*{
    "id": entity.id,
    "name": entity.name,
    "entity_type": $entity.entity_type,
    "description": entity.description,
    "attributes": entity.attributes,
    "contexts": entity.contexts
  }
  result["strain"] = entity.strain.toJson
  result["created"] = %($entity.created)
  result["modified"] = %($entity.modified)

proc toJson*(relationship: Relationship): JsonNode =
  result = %*{
    "id": relationship.id,
    "from_entity": relationship.from_entity,
    "to_entity": relationship.to_entity,
    "relationship_type": relationship.relationship_type,
    "attributes": relationship.attributes
  }
  result["strain"] = relationship.strain.toJson
  result["created"] = %($relationship.created)
  result["modified"] = %($relationship.modified)

proc toJson*(context: EntityContext): JsonNode =
  result = %*{
    "id": context.id,
    "name": context.name,
    "description": context.description,
    "entities": context.entities
  }
  result["created"] = %($context.created)

proc toJson*(status: AgentStatus): JsonNode =
  result = %*{
    "agent_id": status.agent_id,
    "agent_type": status.agent_type,
    "status": $status.status,
    "current_task": status.current_task,
    "strain_level": status.strain_level,
    "authority_level": status.authority_level
  }
  result["last_active"] = %($status.last_active)

proc toJson*(token: AuthToken): JsonNode =
  result = %*{
    "token": token.token,
    "agent_id": token.agent_id,
    "permissions": token.permissions
  }
  result["created_at"] = %($token.created_at)
  result["expires_at"] = %($token.expires_at)

proc toJson*(event: ApiError): JsonNode =
  result = %*{
    "error_code": event.error_code,
    "error_message": event.error_message,
    "details": event.details,
    "request_id": if event.request_id.isSome: event.request_id.get() else: ""
  }
  result["timestamp"] = %($event.timestamp)

proc toJson*(message: AgentMessage): JsonNode =
  var json = %*{
    "message_id": message.message_id,
    "from_agent": message.from_agent,
    "message_type": $message.message_type,
    "content": message.content,
    "priority": $message.priority
  }
  if message.to_agent.isSome:
    json["to_agent"] = %message.to_agent.get()
  else:
    json["to_agent"] = newJNull()
  if message.expires_at.isSome:
    json["expires_at"] = %($message.expires_at.get())
  else:
    json["expires_at"] = newJNull()
  json["timestamp"] = %($message.timestamp)
  return json

proc toJson*(event: StreamEvent): JsonNode =
  var json = %*{
    "event_id": event.event_id,
    "event_type": $event.event_type,
    "data": event.data
  }
  if event.entity_id.isSome:
    json["entity_id"] = %event.entity_id.get()
  else:
    json["entity_id"] = newJNull()
  if event.agent_id.isSome:
    json["agent_id"] = %event.agent_id.get()
  else:
    json["agent_id"] = newJNull()
  json["timestamp"] = %($event.timestamp)
  return json



# Validation Functions
proc isValid*(request: CreateEntityRequest): bool =
  ## Validate create entity request
  return request.name.len > 0 and request.name.len <= 100

proc isValid*(request: UpdateEntityRequest): bool =
  ## Validate update entity request
  return request.id.len > 0

proc isValid*(request: QueryRequest): bool =
  ## Validate query request
  return request.limit >= 0 and request.limit <= 1000 and request.offset >= 0

proc isValid*(token: AuthToken): bool =
  ## Check if auth token is valid and not expired
  return now() < token.expires_at

proc hasPermission*(token: AuthToken, permission: Permission): bool =
  ## Check if token has specific permission
  return $permission in token.permissions or "full_access" in token.permissions 