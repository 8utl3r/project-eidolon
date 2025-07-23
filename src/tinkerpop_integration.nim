# TinkerPop Integration
#
# This module integrates with Apache TinkerPop to provide real-time
# visualization of agent activity and strain flow patterns.

import std/[times, json, asyncdispatch, httpclient, strutils, tables, strformat, options]
import agents/activity_monitor

type
  TinkerPopClient* = ref object
    ## Client for TinkerPop server communication
    server_url*: string
    http_client*: AsyncHttpClient
    connected*: bool
    last_update*: DateTime

  GraphUpdate* = object
    ## Graph update operation
    operation*: string  # "add_vertex", "add_edge", "update_vertex", "update_edge"
    vertex_id*: string
    edge_id*: string
    properties*: JsonNode
    timestamp*: DateTime

  TinkerPopIntegration* = ref object
    ## Integration layer for TinkerPop visualization
    client*: TinkerPopClient
    activity_monitor*: ActivityMonitor
    graph_updates*: seq[GraphUpdate]
    agent_vertices*: Table[string, string]  # agent_id -> vertex_id
    entity_vertices*: Table[string, string]  # entity_id -> vertex_id
    update_callbacks*: seq[proc(update: GraphUpdate)]
    integration_active*: bool

# Constructor
proc newTinkerPopClient*(server_url: string = "http://localhost:8182"): TinkerPopClient =
  result = TinkerPopClient(
    server_url: server_url,
    http_client: newAsyncHttpClient(),
    connected: false,
    last_update: now()
  )

proc newTinkerPopIntegration*(activity_monitor: ActivityMonitor, 
                             server_url: string = "http://localhost:8182"): TinkerPopIntegration =
  result = TinkerPopIntegration(
    client: newTinkerPopClient(server_url),
    activity_monitor: activity_monitor,
    graph_updates: @[],
    agent_vertices: initTable[string, string](),
    entity_vertices: initTable[string, string](),
    update_callbacks: @[],
    integration_active: false
  )

# TinkerPop Server Communication
proc connectToServer*(client: TinkerPopClient): Future[bool] {.async.} =
  ## Connect to TinkerPop server
  try:
    let response = await client.http_client.get(client.server_url & "/")
    client.connected = response.status == "200 OK"
    client.last_update = now()
    return client.connected
  except:
    client.connected = false
    return false

proc sendGremlinQuery*(client: TinkerPopClient, query: string): Future[JsonNode] {.async.} =
  ## Send Gremlin query to server
  if not client.connected:
    return %*{"error": "Not connected to TinkerPop server"}
  
  try:
    let payload = %*{
      "gremlin": query,
      "bindings": {},
      "language": "gremlin-groovy"
    }
    
    client.http_client.headers = newHttpHeaders({"Content-Type": "application/json"})
    let response = await client.http_client.post(
      client.server_url & "/gremlin",
      $payload
    )
    
    if response.status == "200 OK":
      let body_text = await response.body
      return parseJson(body_text)
    else:
      return %*{"error": "Query failed: " & response.status}
  except:
    return %*{"error": "Communication error"}

# Graph Operations
proc addAgentVertex*(integration: TinkerPopIntegration, agent_id: string, 
                    agent_type: string, is_active: bool, strain_level: float): Future[string] {.async.} =
  ## Add agent vertex to graph
  let vertex_id = "agent_" & agent_id
  let query = fmt"""
    g.addV('agent')
      .property('agent_id', '{agent_id}')
      .property('agent_type', '{agent_type}')
      .property('is_active', {is_active})
      .property('strain_level', {strain_level})
      .property('timestamp', '{now()}')
  """
  
  let result = await integration.client.sendGremlinQuery(query)
  if "error" notin result:
    integration.agent_vertices[agent_id] = vertex_id
    return vertex_id
  return ""

proc updateAgentVertex*(integration: TinkerPopIntegration, agent_id: string,
                       is_active: bool, strain_level: float, current_task: string): Future[bool] {.async.} =
  ## Update existing agent vertex
  if agent_id notin integration.agent_vertices:
    return false
  
  let vertex_id = integration.agent_vertices[agent_id]
  let query = fmt"""
    g.V('{vertex_id}')
      .property('is_active', {is_active})
      .property('strain_level', {strain_level})
      .property('current_task', '{current_task}')
      .property('last_updated', '{now()}')
  """
  
  let result = await integration.client.sendGremlinQuery(query)
  return "error" notin result

proc addEntityVertex*(integration: TinkerPopIntegration, entity_id: string,
                     entity_name: string, strain_level: float): Future[string] {.async.} =
  ## Add entity vertex to graph
  let vertex_id = "entity_" & entity_id
  let query = fmt"""
    g.addV('entity')
      .property('entity_id', '{entity_id}')
      .property('entity_name', '{entity_name}')
      .property('strain_level', {strain_level})
      .property('timestamp', '{now()}')
  """
  
  let result = await integration.client.sendGremlinQuery(query)
  if "error" notin result:
    integration.entity_vertices[entity_id] = vertex_id
    return vertex_id
  return ""

proc addAgentEntityEdge*(integration: TinkerPopIntegration, agent_id: string,
                        entity_id: string, edge_type: string, strain_flow: float): Future[bool] {.async.} =
  ## Add edge between agent and entity
  if agent_id notin integration.agent_vertices or entity_id notin integration.entity_vertices:
    return false
  
  let agent_vertex = integration.agent_vertices[agent_id]
  let entity_vertex = integration.entity_vertices[entity_id]
  
  let query = fmt"""
    g.V('{agent_vertex}').as('agent')
      .V('{entity_vertex}').as('entity')
      .addE('{edge_type}')
      .from('agent').to('entity')
      .property('strain_flow', {strain_flow})
      .property('timestamp', '{now()}')
  """
  
  let result = await integration.client.sendGremlinQuery(query)
  return "error" notin result

proc addAgentInteractionEdge*(integration: TinkerPopIntegration, source_agent: string,
                             target_agent: string, interaction_type: string, strain_flow: float): Future[bool] {.async.} =
  ## Add edge between interacting agents
  if source_agent notin integration.agent_vertices or target_agent notin integration.agent_vertices:
    return false
  
  let source_vertex = integration.agent_vertices[source_agent]
  let target_vertex = integration.agent_vertices[target_agent]
  
  let query = fmt"""
    g.V('{source_vertex}').as('source')
      .V('{target_vertex}').as('target')
      .addE('interacts_with')
      .from('source').to('target')
      .property('interaction_type', '{interaction_type}')
      .property('strain_flow', {strain_flow})
      .property('timestamp', '{now()}')
  """
  
  let result = await integration.client.sendGremlinQuery(query)
  return "error" notin result

# Real-time Integration
proc startIntegration*(integration: TinkerPopIntegration) {.async, gcsafe.} =
  ## Start real-time integration with TinkerPop
  integration.integration_active = true
  
  # Connect to server
  let connected = await integration.client.connectToServer()
  if not connected:
    echo "Warning: Could not connect to TinkerPop server at " & integration.client.server_url
    return
  
  # Register callbacks
  integration.activity_monitor.onActivityUpdate(proc(activity: AgentActivity) {.gcsafe.} =
    # Update agent vertex
    asyncCheck integration.updateAgentVertex(
      activity.agent_id,
      activity.is_active,
      activity.strain_level,
      if activity.current_task.isSome: activity.current_task.get else: ""
    )
    
    # Add entity vertices and edges for target entities
    for entity_id in activity.target_entities:
      if entity_id notin integration.entity_vertices:
        asyncCheck integration.addEntityVertex(entity_id, entity_id, activity.strain_level)
      
      asyncCheck integration.addAgentEntityEdge(
        activity.agent_id,
        entity_id,
        "attends_to",
        activity.strain_level
      )
  )
  
  integration.activity_monitor.onInteraction(proc(interaction: AgentInteraction) {.gcsafe.} =
    # Add interaction edge
    asyncCheck integration.addAgentInteractionEdge(
      interaction.source_agent,
      interaction.target_agent,
      interaction.interaction_type,
      interaction.strain_flow
    )
  )
  
  # Start monitoring
  await integration.activity_monitor.startMonitoring()

proc stopIntegration*(integration: TinkerPopIntegration) =
  ## Stop real-time integration
  integration.integration_active = false
  integration.activity_monitor.stopMonitoring()

# Utility functions
proc clearGraph*(integration: TinkerPopIntegration): Future[bool] {.async.} =
  ## Clear all vertices and edges from graph
  let query = "g.V().drop().iterate()"
  let result = await integration.client.sendGremlinQuery(query)
  return "error" notin result

proc getGraphStats*(integration: TinkerPopIntegration): Future[JsonNode] {.async.} =
  ## Get graph statistics
  let vertex_count_query = "g.V().count()"
  let edge_count_query = "g.E().count()"
  let agent_count_query = "g.V().hasLabel('agent').count()"
  let entity_count_query = "g.V().hasLabel('entity').count()"
  
  let vertex_count = await integration.client.sendGremlinQuery(vertex_count_query)
  let edge_count = await integration.client.sendGremlinQuery(edge_count_query)
  let agent_count = await integration.client.sendGremlinQuery(agent_count_query)
  let entity_count = await integration.client.sendGremlinQuery(entity_count_query)
  
  return %*{
    "vertex_count": vertex_count,
    "edge_count": edge_count,
    "agent_count": agent_count,
    "entity_count": entity_count,
    "timestamp": $now()
  } 