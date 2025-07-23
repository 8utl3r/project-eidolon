# API Server
#
# This module provides the main REST API server for the knowledge graph system.
# It includes endpoints for database operations, agent communication, and event streaming.

import std/[times, tables, options, json, strutils, asyncdispatch, httpcore, 
            asynchttpserver, jsonutils, base64]
import ../types
import ../database/operations
import ../rag/rag_engine
import ./types
import ./simple_router

type
  ApiServer* = object
    ## Main API server for the knowledge graph system
    database*: DatabaseOperations
    rag_engine*: RAGEngine
    simple_router*: SimpleRouter
    server*: AsyncHttpServer
    port*: int
    auth_tokens*: Table[string, AuthToken]
    agent_status*: Table[string, AgentStatus]
    event_streams*: Table[string, seq[StreamEvent]]
    message_queue*: seq[AgentMessage]

  RequestContext* = object
    ## Context for API request processing
    request_id*: string
    agent_id*: Option[string]
    token*: Option[AuthToken]
    timestamp*: DateTime

# Constructor
proc newApiServer*(port: int = 8080): ApiServer =
  ## Create a new API server
  let rag_engine = newRAGEngine("api_server_rag")
  let simple_router = newSimpleRouter(rag_engine)
  
  return ApiServer(
    database: newDatabaseOperations(),
    rag_engine: rag_engine,
    simple_router: simple_router,
    server: newAsyncHttpServer(),
    port: port,
    auth_tokens: initTable[string, AuthToken](),
    agent_status: initTable[string, AgentStatus](),
    event_streams: initTable[string, seq[StreamEvent]](),
    message_queue: @[]
  )

# Helper function to convert ApiError to string
proc errorToString*(error: ApiError): string =
  ## Convert ApiError to string for API response
  return error.error_message

# Authentication and Authorization
proc authenticateRequest*(server: ApiServer, headers: HttpHeaders): Option[AuthToken] =
  ## Authenticate request using Authorization header
  let auth_header = headers.getOrDefault("Authorization")
  if auth_header.len == 0:
    return none(AuthToken)
  
  if not auth_header.startsWith("Bearer "):
    return none(AuthToken)
  
  let token_str = auth_header[7..^1]  # Remove "Bearer " prefix
  if server.auth_tokens.hasKey(token_str):
    let token = server.auth_tokens[token_str]
    if token.isValid:
      return some(token)
  
  return none(AuthToken)

proc requireAuth*(server: ApiServer, headers: HttpHeaders, 
                 permission: Permission): Option[AuthToken] =
  ## Require authentication and specific permission
  let token = server.authenticateRequest(headers)
  if token.isNone:
    return none(AuthToken)
  
  if not token.get().hasPermission(permission):
    return none(AuthToken)
  
  return token

# Entity Endpoints
proc handleCreateEntity*(server: var ApiServer, req: Request, ctx: RequestContext): JsonNode =
  ## Handle POST /api/entities
  try:
    let body = parseJson(req.body)
    let request = CreateEntityRequest(
      name: body["name"].getStr,
      entity_type: parseEnum[EntityType](body["entity_type"].getStr),
      description: body.getOrDefault("description").getStr,
      attributes: initTable[string, string]()
    )
    
    if not request.isValid:
      return newApiResponse[Entity]("Invalid entity request").toJson
    
    let entity = server.database.createEntity(request.name, request.entity_type, request.description)
    
    # Add attributes if provided
    if body.hasKey("attributes"):
      var updated_entity = entity
      for key, value in body["attributes"].pairs:
        updated_entity.attributes[key] = value.getStr
      discard server.database.updateEntity(updated_entity)
    
    # Create stream event
    let event = newStreamEvent(entity_created, %*{"entity_id": entity.id, "name": entity.name})
    server.broadcastEvent(event)
    
    return newApiResponse(entity).toJson
    
  except:
    return newApiResponse[Entity]("Invalid JSON").toJson

proc handleGetEntity*(server: ApiServer, req: Request, ctx: RequestContext): JsonNode =
  ## Handle GET /api/entities/{id}
  let entity_id = req.params.getOrDefault("id")
  if entity_id.len == 0:
    return newApiResponse[Entity]("Missing entity ID").toJson
  
  let entity = server.database.getEntity(entity_id)
  if entity.isNone:
    return newApiResponse[Entity]("Entity not found").toJson
  
  let relationships = server.database.getRelationships(entity_id)
  let strain_summary = server.database.calculateStrainSummary(@[entity.get()])
  
  let response = EntityResponse(
    entity: entity.get(),
    relationships: relationships,
    strain_summary: strain_summary
  )
  
  return newApiResponse(response).toJson

proc handleUpdateEntity*(server: var ApiServer, req: Request, ctx: RequestContext): JsonNode =
  ## Handle PUT /api/entities/{id}
  let entity_id = req.params.getOrDefault("id")
  if entity_id.len == 0:
    return newApiResponse[Entity]("Missing entity ID").toJson
  
  let existing_entity = server.database.getEntity(entity_id)
  if existing_entity.isNone:
    return newApiResponse[Entity]("Entity not found").toJson
  
  try:
    let body = parseJson(req.body)
    var updated_entity = existing_entity.get()
    
    if body.hasKey("name"):
      updated_entity.name = body["name"].getStr
    if body.hasKey("description"):
      updated_entity.description = body["description"].getStr
    if body.hasKey("attributes"):
      updated_entity.attributes = initTable[string, string]()
      for key, value in body["attributes"].pairs:
        updated_entity.attributes[key] = value.getStr
    
    let success = server.database.updateEntity(updated_entity)
    if not success:
      return newApiResponse[Entity]("Failed to update entity").toJson
    
    # Create stream event
    let event = newStreamEvent(entity_updated, %*{"entity_id": entity_id})
    server.broadcastEvent(event)
    
    return newApiResponse(updated_entity).toJson
    
  except:
    return newApiResponse[Entity]("Invalid JSON").toJson

proc handleDeleteEntity*(server: var ApiServer, req: Request, ctx: RequestContext): JsonNode =
  ## Handle DELETE /api/entities/{id}
  let entity_id = req.params.getOrDefault("id")
  if entity_id.len == 0:
    return newApiResponse[bool]("Missing entity ID").toJson
  
  let success = server.database.deleteEntity(entity_id)
  if not success:
    return newApiResponse[bool]("Entity not found").toJson
  
  # Create stream event
  let event = newStreamEvent(entity_deleted, %*{"entity_id": entity_id})
  server.broadcastEvent(event)
  
  return newApiResponse(true).toJson

# Query Endpoints
proc handleQueryEntities*(server: ApiServer, req: Request, ctx: RequestContext): JsonNode =
  ## Handle POST /api/entities/query
  try:
    let body = parseJson(req.body)
    var filter = QueryFilter()
    
    if body.hasKey("entity_types"):
      for entity_type_str in body["entity_types"]:
        filter.entity_types.add(parseEnum[EntityType](entity_type_str.getStr))
    
    if body.hasKey("strain_threshold"):
      filter.strain_threshold = body["strain_threshold"].getFloat
    
    if body.hasKey("context_ids"):
      for context_id in body["context_ids"]:
        filter.context_ids.add(context_id.getStr)
    
    let limit = body.getOrDefault("limit").getInt(100)
    let offset = body.getOrDefault("offset").getInt(0)
    let include_relationships = body.getOrDefault("include_relationships").getBool(false)
    let include_strain_summary = body.getOrDefault("include_strain_summary").getBool(true)
    
    let query_result = server.database.queryEntities(filter)
    
    var relationships: seq[Relationship] = @[]
    if include_relationships:
      for entity in query_result.items:
        relationships.add(server.database.getRelationships(entity.id))
    
    let response = QueryResponse(
      entities: query_result.items[offset..min(offset + limit - 1, query_result.items.high)],
      total_count: query_result.total_count,
      strain_summary: if include_strain_summary: query_result.strain_summary else: StrainSummary(),
      query_time: query_result.query_time,
      relationships: relationships
    )
    
    return newApiResponse(response).toJson
    
  except:
    return newApiResponse[QueryResponse]("Invalid query request").toJson

proc handleQueryHighStrain*(server: ApiServer, req: Request, ctx: RequestContext): JsonNode =
  ## Handle GET /api/entities/high-strain
  let threshold = req.params.getOrDefault("threshold").parseFloat(0.7)
  let result = server.database.queryHighStrainEntities(threshold)
  return newApiResponse(result).toJson

proc handleQueryLowStrain*(server: ApiServer, req: Request, ctx: RequestContext): JsonNode =
  ## Handle GET /api/entities/low-strain
  let threshold = req.params.getOrDefault("threshold").parseFloat(0.3)
  let result = server.database.queryLowStrainEntities(threshold)
  return newApiResponse(result).toJson

proc handleNaturalLanguageQuery*(server: var ApiServer, req: Request, ctx: RequestContext): JsonNode =
  ## Handle POST /api/query - Natural language query processing
  try:
    let body = parseJson(req.body)
    let query = body["query"].getStr
    
    if query.len == 0:
      return newApiResponse[JsonNode]("Query cannot be empty").toJson
    
    # Process query through simple router
    let result = server.simple_router.processQuery(query)
    let response = toJson(result)
    
    # Create stream event for query processing
    let event = newStreamEvent(event_notification, %*{
      "query": query,
      "processing_time": result.processing_time,
      "selected_agent": if isSome(result.selected_agent): get(result.selected_agent) else: ""
    })
    server.broadcastEvent(event)
    
    return response
    
  except:
    return newApiResponse[JsonNode]("Invalid query request").toJson

proc handleAgentRegistration*(server: var ApiServer, req: Request, ctx: RequestContext): JsonNode =
  ## Handle POST /api/agents/register - Register agent capabilities
  try:
    let body = parseJson(req.body)
    let agent_id = body["agent_id"].getStr
    let agent_type_str = body["agent_type"].getStr
    let keywords = body.getOrDefault("keywords").getElems.mapIt(it.getStr)
    
    let agent_type = parseEnum[AgentType](agent_type_str)
    let capability = newAgentCapability(agent_id, agent_type, keywords)
    
    let success = server.simple_router.agent_registry.registerAgent(capability)
    
    if success:
      return newApiResponse(true).toJson
    else:
      return newApiResponse[JsonNode]("Failed to register agent").toJson
    
  except:
    return newApiResponse[JsonNode]("Invalid agent registration").toJson

proc handleSimpleRouterStats*(server: ApiServer, req: Request, ctx: RequestContext): JsonNode =
  ## Handle GET /api/simple-router/stats - Get simple router statistics
  let active_agents = server.simple_router.getActiveAgents()
  let rag_stats = server.rag_engine.getKnowledgeSourceStats()
  
  let stats = %*{
    "active_agents": active_agents.len,
    "total_agents": 7,  # Default agents
    "rag_engine_stats": rag_stats
  }
  
  return newApiResponse(stats).toJson

# Relationship Endpoints
proc handleCreateRelationship*(server: var ApiServer, req: Request, ctx: RequestContext): JsonNode =
  ## Handle POST /api/relationships
  try:
    let body = parseJson(req.body)
    let from_entity_id = body["from_entity_id"].getStr
    let to_entity_id = body["to_entity_id"].getStr
    let relationship_type = body["relationship_type"].getStr
    
    let relationship = server.database.createRelationship(from_entity_id, to_entity_id, relationship_type)
    if relationship.isNone:
      return newApiResponse[Relationship]("Failed to create relationship").toJson
    
    # Create stream event
    let event = newStreamEvent(relationship_created, %*{
      "relationship_id": relationship.get().id,
      "from_entity": from_entity_id,
      "to_entity": to_entity_id
    })
    server.broadcastEvent(event)
    
    return newApiResponse(relationship.get()).toJson
    
  except:
    return newApiResponse[Relationship]("Invalid relationship request").toJson

# Agent Communication Endpoints
proc handleSendMessage*(server: var ApiServer, req: Request, ctx: RequestContext): JsonNode =
  ## Handle POST /api/agents/messages
  try:
    let body = parseJson(req.body)
    let to_agent = if body.hasKey("to_agent"): some(body["to_agent"].getStr) else: none(string)
    let message_type = parseEnum[AgentMessageType](body["message_type"].getStr)
    let content = body["content"]
    let priority = if body.hasKey("priority"): parseEnum[MessagePriority](body["priority"].getStr) else: normal
    
    let message = AgentMessage(
      message_id: "msg_" & $now().toUnix(),
      from_agent: ctx.agent_id.get("system"),
      to_agent: to_agent,
      message_type: message_type,
      content: content,
      priority: priority,
      timestamp: now(),
      expires_at: none(DateTime)
    )
    
    server.message_queue.add(message)
    
    return newApiResponse(message).toJson
    
  except:
    return newApiResponse[AgentMessage]("Invalid message request").toJson

proc handleGetMessages*(server: ApiServer, req: Request, ctx: RequestContext): JsonNode =
  ## Handle GET /api/agents/messages
  let agent_id = ctx.agent_id.get("system")
  var messages: seq[AgentMessage] = @[]
  
  for message in server.message_queue:
    if message.to_agent.isNone or message.to_agent.get() == agent_id:
      messages.add(message)
  
  return newApiResponse(messages).toJson

# Event Streaming Endpoints
proc handleEventStream*(server: ApiServer, req: Request, ctx: RequestContext): JsonNode =
  ## Handle GET /api/events/stream
  let agent_id = ctx.agent_id.get("system")
  
  if not server.event_streams.hasKey(agent_id):
    server.event_streams[agent_id] = @[]
  
  let events = server.event_streams[agent_id]
  return newApiResponse(events).toJson

proc broadcastEvent*(server: var ApiServer, event: StreamEvent) =
  ## Broadcast event to all agents
  for agent_id in server.event_streams.keys:
    server.event_streams[agent_id].add(event)

# Statistics Endpoints
proc handleGetStats*(server: ApiServer, req: Request, ctx: RequestContext): JsonNode =
  ## Handle GET /api/stats
  let stats = server.database.getDatabaseStats()
  let distribution = server.database.getStrainDistribution()
  
  let response = %*{
    "database_stats": stats,
    "strain_distribution": distribution,
    "agent_count": server.agent_status.len,
    "message_queue_size": server.message_queue.len
  }
  
  return newApiResponse(response).toJson

# Main Request Handler
proc handleRequest*(server: var ApiServer, req: Request, res: Response) {.async.} =
  ## Main request handler for the API server
  let request_id = "req_" & $now().toUnix()
  let ctx = RequestContext(
    request_id: request_id,
    agent_id: none(string),
    timestamp: now()
  )
  
  # Set CORS headers
  res.headers["Access-Control-Allow-Origin"] = "*"
  res.headers["Access-Control-Allow-Methods"] = "GET, POST, PUT, DELETE, OPTIONS"
  res.headers["Access-Control-Allow-Headers"] = "Content-Type, Authorization"
  
  # Handle preflight requests
  if req.reqMethod == HttpOptions:
    res.status = Http200
    await res.respond("")
    return
  
  # Authenticate request (except for public endpoints)
  let public_endpoints = @["/api/auth/login", "/api/stats"]
  if req.url.path notin public_endpoints:
    let token = server.authenticateRequest(req.headers)
    if token.isNone:
      res.status = Http401
      await res.respond(newApiResponse[JsonNode]("Authentication required").toJson.pretty)
      return
    ctx.agent_id = some(token.get().agent_id)
    ctx.token = token
  
  var response: JsonNode
  
  # Route requests
  case req.reqMethod
  of HttpGet:
    case req.url.path
    of "/api/entities":
      if req.params.hasKey("id"):
        response = server.handleGetEntity(req, ctx)
      else:
        response = newApiResponse[seq[Entity]]("Entity ID required").toJson
    of "/api/entities/high-strain":
      response = server.handleQueryHighStrain(req, ctx)
    of "/api/entities/low-strain":
      response = server.handleQueryLowStrain(req, ctx)
    of "/api/agents/messages":
      response = server.handleGetMessages(req, ctx)
    of "/api/events/stream":
      response = server.handleEventStream(req, ctx)
    of "/api/stats":
      response = server.handleGetStats(req, ctx)
    of "/api/simple-router/stats":
      response = server.handleSimpleRouterStats(req, ctx)
    else:
      response = newApiResponse[JsonNode]("Endpoint not found").toJson
  
  of HttpPost:
    case req.url.path
    of "/api/entities":
      response = server.handleCreateEntity(req, ctx)
    of "/api/entities/query":
      response = server.handleQueryEntities(req, ctx)
    of "/api/relationships":
      response = server.handleCreateRelationship(req, ctx)
    of "/api/agents/messages":
      response = server.handleSendMessage(req, ctx)
    of "/api/query":
      response = server.handleNaturalLanguageQuery(req, ctx)
    of "/api/agents/register":
      response = server.handleAgentRegistration(req, ctx)
    else:
      response = newApiResponse[JsonNode]("Endpoint not found").toJson
  
  of HttpPut:
    if req.url.path.startsWith("/api/entities/"):
      response = server.handleUpdateEntity(req, ctx)
    else:
      response = newApiResponse[JsonNode]("Endpoint not found").toJson
  
  of HttpDelete:
    if req.url.path.startsWith("/api/entities/"):
      response = server.handleDeleteEntity(req, ctx)
    else:
      response = newApiResponse[JsonNode]("Endpoint not found").toJson
  
  else:
    response = newApiResponse[JsonNode]("Method not allowed").toJson
  
  # Set response
  res.headers["Content-Type"] = "application/json"
  res.status = Http200
  await res.respond(response.pretty)

# Server Management
proc start*(server: var ApiServer) {.async.} =
  ## Start the API server
  echo "Starting API server on port ", server.port
  await server.server.serve(Port(server.port), handleRequest)

proc stop*(server: ApiServer) =
  ## Stop the API server
  server.server.close() 