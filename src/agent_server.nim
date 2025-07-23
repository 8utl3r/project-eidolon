# Agent Server
#
# HTTP server for the agent orchestrator that provides API endpoints
# for task management and agent status.

import std/[asynchttpserver, asyncdispatch, json, times, strutils]
import ./agents/orchestrator
import ./types

type
  AgentServer* = object
    ## HTTP server for agent orchestration
    server*: AsyncHttpServer
    port*: int
    orchestrator*: AgentOrchestrator

proc newAgentServer*(port: int = 3001): AgentServer =
  ## Create a new agent server
  return AgentServer(
    server: newAsyncHttpServer(),
    port: port,
    orchestrator: newAgentOrchestrator()
  )

proc handleAddTask*(server: AgentServer, req: Request): Future[void] {.async.} =
  ## Handle POST /api/tasks/add
  try:
    let body = await req.body
    let request_data = parseJson(body)
    
    let task_description = request_data["description"].getStr()
    let task_type = request_data["type"].getStr()
    let input_data = if request_data.hasKey("input_data"): request_data["input_data"] else: %*{}
    let priority = if request_data.hasKey("priority"): request_data["priority"].getInt() else: 1
    
    var mutable_orchestrator = server.orchestrator
    let task_id = mutable_orchestrator.addTask(task_description, task_type, input_data, priority)
    
    let response = %*{
      "success": true,
      "task_id": task_id,
      "message": "Task added successfully"
    }
    
    var headers = newHttpHeaders()
    headers["Content-Type"] = "application/json"
    headers["Access-Control-Allow-Origin"] = "*"
    await req.respond(Http200, $response, headers)
    
  except Exception as e:
    let error_response = %*{
      "success": false,
      "error": e.msg
    }
    var headers = newHttpHeaders()
    headers["Content-Type"] = "application/json"
    headers["Access-Control-Allow-Origin"] = "*"
    await req.respond(Http500, $error_response, headers)

proc handleTaskStatus*(server: AgentServer, req: Request): Future[void] {.async.} =
  ## Handle GET /api/tasks/status
  try:
    let status = server.orchestrator.getTaskStatus()
    
    var headers = newHttpHeaders()
    headers["Content-Type"] = "application/json"
    headers["Access-Control-Allow-Origin"] = "*"
    await req.respond(Http200, $status, headers)
    
  except Exception as e:
    let error_response = %*{
      "success": false,
      "error": e.msg
    }
    var headers = newHttpHeaders()
    headers["Content-Type"] = "application/json"
    headers["Access-Control-Allow-Origin"] = "*"
    await req.respond(Http500, $error_response, headers)

proc handleAgentStatus*(server: AgentServer, req: Request): Future[void] {.async.} =
  ## Handle GET /api/agents/status
  try:
    var agent_status: seq[JsonNode] = @[]
    for agent in server.orchestrator.registry.getActiveAgents():
      let is_active = server.orchestrator.isAgentActive(agent.agent_id)
      agent_status.add(%*{
        "agent_id": agent.agent_id,
        "agent_type": $agent.agent_type,
        "is_active": is_active,
        "current_strain": agent.current_strain,
        "keywords": agent.keywords
      })
    
    let response = %*{
      "total_agents": agent_status.len,
      "active_agents": server.orchestrator.active_agents.len,
      "agents": agent_status
    }
    
    var headers = newHttpHeaders()
    headers["Content-Type"] = "application/json"
    headers["Access-Control-Allow-Origin"] = "*"
    await req.respond(Http200, $response, headers)
    
  except Exception as e:
    let error_response = %*{
      "success": false,
      "error": e.msg
    }
    var headers = newHttpHeaders()
    headers["Content-Type"] = "application/json"
    headers["Access-Control-Allow-Origin"] = "*"
    await req.respond(Http500, $error_response, headers)

proc handleActivateAgent*(server: AgentServer, req: Request): Future[void] {.async.} =
  ## Handle POST /api/agents/activate
  try:
    let body = await req.body
    let request_data = parseJson(body)
    let agent_id = request_data["agent_id"].getStr()
    
    var mutable_orchestrator = server.orchestrator
    let success = mutable_orchestrator.activateAgent(agent_id)
    
    let response = %*{
      "success": success,
      "agent_id": agent_id,
      "message": if success: "Agent activated" else: "Agent not found"
    }
    
    var headers = newHttpHeaders()
    headers["Content-Type"] = "application/json"
    headers["Access-Control-Allow-Origin"] = "*"
    await req.respond(Http200, $response, headers)
    
  except Exception as e:
    let error_response = %*{
      "success": false,
      "error": e.msg
    }
    var headers = newHttpHeaders()
    headers["Content-Type"] = "application/json"
    headers["Access-Control-Allow-Origin"] = "*"
    await req.respond(Http500, $error_response, headers)

proc handleDeactivateAgent*(server: AgentServer, req: Request): Future[void] {.async.} =
  ## Handle POST /api/agents/deactivate
  try:
    let body = await req.body
    let request_data = parseJson(body)
    let agent_id = request_data["agent_id"].getStr()
    
    var mutable_orchestrator = server.orchestrator
    let success = mutable_orchestrator.deactivateAgent(agent_id)
    
    let response = %*{
      "success": success,
      "agent_id": agent_id,
      "message": if success: "Agent deactivated" else: "Agent not found"
    }
    
    var headers = newHttpHeaders()
    headers["Content-Type"] = "application/json"
    headers["Access-Control-Allow-Origin"] = "*"
    await req.respond(Http200, $response, headers)
    
  except Exception as e:
    let error_response = %*{
      "success": false,
      "error": e.msg
    }
    var headers = newHttpHeaders()
    headers["Content-Type"] = "application/json"
    headers["Access-Control-Allow-Origin"] = "*"
    await req.respond(Http500, $error_response, headers)

proc handleRequest*(server: AgentServer, req: Request): Future[void] {.async.} =
  ## Handle incoming HTTP requests
  case req.url.path
  of "/api/tasks/add":
    if req.reqMethod == HttpPost:
      await handleAddTask(server, req)
    else:
      await req.respond(Http405, "Method not allowed")
      
  of "/api/tasks/status":
    if req.reqMethod == HttpGet:
      await handleTaskStatus(server, req)
    else:
      await req.respond(Http405, "Method not allowed")
      
  of "/api/agents/status":
    if req.reqMethod == HttpGet:
      await handleAgentStatus(server, req)
    else:
      await req.respond(Http405, "Method not allowed")
      
  of "/api/agents/activate":
    if req.reqMethod == HttpPost:
      await handleActivateAgent(server, req)
    else:
      await req.respond(Http405, "Method not allowed")
      
  of "/api/agents/deactivate":
    if req.reqMethod == HttpPost:
      await handleDeactivateAgent(server, req)
    else:
      await req.respond(Http405, "Method not allowed")
      
  else:
    await req.respond(Http404, "Not found")

proc start*(server: AgentServer) {.async.} =
  ## Start the agent server
  echo "Starting Agent Server on port ", server.port
  echo "API Endpoints:"
  echo "  POST /api/tasks/add - Add a new task"
  echo "  GET  /api/tasks/status - Get task status"
  echo "  GET  /api/agents/status - Get agent status"
  echo "  POST /api/agents/activate - Activate an agent"
  echo "  POST /api/agents/deactivate - Deactivate an agent"
  
  # Start agent duty cycle in background
  asyncCheck server.orchestrator.runAgentDuties()
  
  proc handleClient(request: Request) {.async.} =
    try:
      await handleRequest(server, request)
    except:
      echo "Error handling request: ", getCurrentExceptionMsg()
      try:
        await request.respond(Http500, "Internal Server Error")
      except:
        discard
  
  await server.server.serve(Port(server.port), handleClient)

when isMainModule:
  let server = newAgentServer(3001)
  waitFor server.start() 