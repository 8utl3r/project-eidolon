# API Client Library
#
# This module provides a client library for agents to interact with the REST API.
# It includes methods for all database operations, agent communication, and event streaming.

import std/[times, tables, options, json, strutils, asyncdispatch, httpclient, 
            jsonutils, base64]
import ../types
import ./types

type
  ApiClient* = object
    ## Client for interacting with the knowledge graph API
    base_url*: string
    auth_token*: Option[string]
    agent_id*: string
    http_client*: AsyncHttpClient
    last_request_time*: DateTime

  ClientError* = object
    ## Client error information
    error_code*: string
    error_message*: string
    request_id*: Option[string]

# Constructor
proc newApiClient*(base_url: string, agent_id: string): ApiClient =
  ## Create a new API client
  return ApiClient(
    base_url: base_url.rstrip('/'),
    auth_token: none(string),
    agent_id: agent_id,
    http_client: newAsyncHttpClient(),
    last_request_time: now()
  )

proc setAuthToken*(client: var ApiClient, token: string) =
  ## Set authentication token for the client
  client.auth_token = some(token)
  client.http_client.headers["Authorization"] = "Bearer " & token

# HTTP Request Helpers
proc makeRequest*(client: var ApiClient, method: string, endpoint: string, 
                 body: JsonNode = nil): Future[JsonNode] {.async.} =
  ## Make HTTP request to the API
  let url = client.base_url & endpoint
  client.http_client.headers["Content-Type"] = "application/json"
  client.http_client.headers["User-Agent"] = "KnowledgeGraph-Client/" & client.agent_id
  
  var response: AsyncResponse
  case method.toUpperAscii()
  of "GET":
    response = await client.http_client.get(url)
  of "POST":
    response = await client.http_client.post(url, $body)
  of "PUT":
    response = await client.http_client.put(url, $body)
  of "DELETE":
    response = await client.http_client.delete(url)
  else:
    raise newException(ValueError, "Unsupported HTTP method: " & method)
  
  client.last_request_time = now()
  
  if response.status != Http200:
    let error_body = await response.body
    let error_json = parseJson(error_body)
    raise newException(ValueError, "API Error: " & error_json["error"].getStr)
  
  let response_body = await response.body
  return parseJson(response_body)

# Entity Operations
proc createEntity*(client: var ApiClient, name: string, entity_type: EntityType, 
                  description: string = "", attributes: Table[string, string] = initTable[string, string]()): Future[Entity] {.async.} =
  ## Create a new entity
  let request = %*{
    "name": name,
    "entity_type": $entity_type,
    "description": description,
    "attributes": attributes
  }
  
  let response = await client.makeRequest("POST", "/api/entities", request)
  return response["data"].to(Entity)

proc getEntity*(client: ApiClient, entity_id: string): Future[EntityResponse] {.async.} =
  ## Get entity by ID with relationships and strain summary
  let response = await client.makeRequest("GET", "/api/entities?id=" & entity_id)
  return response["data"].to(EntityResponse)

proc updateEntity*(client: var ApiClient, entity_id: string, updates: JsonNode): Future[Entity] {.async.} =
  ## Update entity
  let response = await client.makeRequest("PUT", "/api/entities/" & entity_id, updates)
  return response["data"].to(Entity)

proc deleteEntity*(client: var ApiClient, entity_id: string): Future[bool] {.async.} =
  ## Delete entity
  let response = await client.makeRequest("DELETE", "/api/entities/" & entity_id)
  return response["data"].getBool

# Query Operations
proc queryEntities*(client: ApiClient, filter: QueryFilter, limit: int = 100, 
                   offset: int = 0, include_relationships: bool = false): Future[QueryResponse] {.async.} =
  ## Query entities with filters
  let request = %*{
    "entity_types": filter.entity_types.map(proc(t: EntityType): string = $t),
    "strain_threshold": filter.strain_threshold,
    "context_ids": filter.context_ids,
    "limit": limit,
    "offset": offset,
    "include_relationships": include_relationships,
    "include_strain_summary": true
  }
  
  let response = await client.makeRequest("POST", "/api/entities/query", request)
  return response["data"].to(QueryResponse)

proc queryHighStrainEntities*(client: ApiClient, threshold: float = 0.7): Future[QueryResult[Entity]] {.async.} =
  ## Query entities with high strain values
  let response = await client.makeRequest("GET", "/api/entities/high-strain?threshold=" & $threshold)
  return response["data"].to(QueryResult[Entity])

proc queryLowStrainEntities*(client: ApiClient, threshold: float = 0.3): Future[QueryResult[Entity]] {.async.} =
  ## Query entities with low strain values
  let response = await client.makeRequest("GET", "/api/entities/low-strain?threshold=" & $threshold)
  return response["data"].to(QueryResult[Entity])

proc queryEntitiesByType*(client: ApiClient, entity_type: EntityType): Future[QueryResult[Entity]] {.async.} =
  ## Query entities by type
  var filter = QueryFilter()
  filter.entity_types = @[entity_type]
  let response = await client.queryEntities(filter)
  return QueryResult[Entity](
    items: response.entities,
    total_count: response.total_count,
    strain_summary: response.strain_summary,
    query_time: response.query_time
  )

proc queryConnectedEntities*(client: ApiClient, entity_id: string, max_depth: int = 1): Future[QueryResult[Entity]] {.async.} =
  ## Query entities connected to a given entity
  # This would need to be implemented in the API server
  # For now, we'll use a simple approach
  let entity_response = await client.getEntity(entity_id)
  var connected_entities: seq[Entity] = @[]
  
  for relationship in entity_response.relationships:
    let target_id = if relationship.from_entity == entity_id: relationship.to_entity else: relationship.from_entity
    let target_entity = await client.getEntity(target_id)
    connected_entities.add(target_entity.entity)
  
  let strain_summary = StrainSummary()  # Would need calculation
  return QueryResult[Entity](
    items: connected_entities,
    total_count: connected_entities.len,
    strain_summary: strain_summary,
    query_time: 0.0
  )

# Relationship Operations
proc createRelationship*(client: var ApiClient, from_entity_id: string, 
                        to_entity_id: string, relationship_type: string): Future[Relationship] {.async.} =
  ## Create a relationship between entities
  let request = %*{
    "from_entity_id": from_entity_id,
    "to_entity_id": to_entity_id,
    "relationship_type": relationship_type
  }
  
  let response = await client.makeRequest("POST", "/api/relationships", request)
  return response["data"].to(Relationship)

# Agent Communication
proc sendMessage*(client: var ApiClient, to_agent: Option[string], message_type: AgentMessageType, 
                 content: JsonNode, priority: MessagePriority = normal): Future[AgentMessage] {.async.} =
  ## Send a message to another agent
  let request = %*{
    "to_agent": if to_agent.isSome: to_agent.get() else: newJNull(),
    "message_type": $message_type,
    "content": content,
    "priority": $priority
  }
  
  let response = await client.makeRequest("POST", "/api/agents/messages", request)
  return response["data"].to(AgentMessage)

proc getMessages*(client: ApiClient): Future[seq[AgentMessage]] {.async.} =
  ## Get messages for this agent
  let response = await client.makeRequest("GET", "/api/agents/messages")
  return response["data"].to(seq[AgentMessage])

proc broadcastMessage*(client: var ApiClient, message_type: AgentMessageType, 
                      content: JsonNode, priority: MessagePriority = normal): Future[AgentMessage] {.async.} =
  ## Broadcast a message to all agents
  return await client.sendMessage(none(string), message_type, content, priority)

# Event Streaming
proc getEventStream*(client: ApiClient): Future[seq[StreamEvent]] {.async.} =
  ## Get events from the stream
  let response = await client.makeRequest("GET", "/api/events/stream")
  return response["data"].to(seq[StreamEvent])

# Statistics
proc getStats*(client: ApiClient): Future[JsonNode] {.async.} =
  ## Get system statistics
  let response = await client.makeRequest("GET", "/api/stats")
  return response["data"]

# Convenience Methods for Agents
proc findContradictions*(client: ApiClient): Future[seq[Entity]] {.async.} =
  ## Find entities with potential contradictions (high strain)
  let high_strain_result = await client.queryHighStrainEntities(0.8)
  return high_strain_result.items

proc getStrainDistribution*(client: ApiClient): Future[Table[string, int]] {.async.} =
  ## Get strain distribution statistics
  let stats = await client.getStats()
  return stats["strain_distribution"].to(Table[string, int])

proc getDatabaseStats*(client: ApiClient): Future[Table[string, int]] {.async.} =
  ## Get database statistics
  let stats = await client.getStats()
  return stats["database_stats"].to(Table[string, int])

# Agent-Specific Methods
proc notifyStrainAlert*(client: var ApiClient, entity_id: string, strain_level: float): Future[AgentMessage] {.async.} =
  ## Notify other agents about strain alert
  let content = %*{
    "entity_id": entity_id,
    "strain_level": strain_level,
    "timestamp": $now()
  }
  return await client.broadcastMessage(strain_alert, content, high)

proc notifyContradictionDetected*(client: var ApiClient, entity_ids: seq[string], 
                                contradiction_type: string): Future[AgentMessage] {.async.} =
  ## Notify other agents about detected contradiction
  let content = %*{
    "entity_ids": entity_ids,
    "contradiction_type": contradiction_type,
    "timestamp": $now()
  }
  return await client.broadcastMessage(contradiction_detected, content, critical)

proc requestAuthority*(client: var ApiClient, throne_id: string, 
                      requested_permissions: seq[string]): Future[AgentMessage] {.async.} =
  ## Request authority from a throne
  let content = %*{
    "throne_id": throne_id,
    "requested_permissions": requested_permissions,
    "agent_id": client.agent_id,
    "timestamp": $now()
  }
  return await client.broadcastMessage(authority_request, content, normal)

proc notifyDreamCycleStart*(client: var ApiClient, cycle_type: string): Future[AgentMessage] {.async.} =
  ## Notify about dream cycle start
  let content = %*{
    "cycle_type": cycle_type,
    "agent_id": client.agent_id,
    "timestamp": $now()
  }
  return await client.broadcastMessage(dream_cycle_start, content, normal)

proc notifyDreamCycleEnd*(client: var ApiClient, cycle_type: string, 
                         modifications: seq[JsonNode]): Future[AgentMessage] {.async.} =
  ## Notify about dream cycle end with modifications
  let content = %*{
    "cycle_type": cycle_type,
    "agent_id": client.agent_id,
    "modifications": modifications,
    "timestamp": $now()
  }
  return await client.broadcastMessage(dream_cycle_end, content, normal)

# Utility Methods
proc isConnected*(client: ApiClient): bool =
  ## Check if client is connected to the API
  return client.last_request_time > now() - initDuration(minutes = 5)

proc getLastRequestTime*(client: ApiClient): DateTime =
  ## Get last request time
  return client.last_request_time

proc close*(client: ApiClient) =
  ## Close the client connection
  client.http_client.close() 