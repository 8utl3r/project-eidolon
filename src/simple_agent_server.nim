# Simple Agent Server
#
# This is a simplified version that focuses on getting the background and foreground
# agents running and connected to the canvas terminal.

import std/[times, json, asyncdispatch, asynchttpserver, strutils, tables]
import agents/orchestrator
import agents/activity_monitor
import types

type
  SimpleAgentServer* = ref object
    ## Simple server for agent management
    orchestrator*: AgentOrchestrator
    activity_monitor*: ActivityMonitor
    http_server*: AsyncHttpServer
    server_port*: int
    server_active*: bool

# Constructor
proc newSimpleAgentServer*(port: int = 3001): SimpleAgentServer =
  ## Create a new simple agent server
  let orchestrator = newAgentOrchestrator()
  let activity_monitor = newActivityMonitor(orchestrator)
  
  return SimpleAgentServer(
    orchestrator: orchestrator,
    activity_monitor: activity_monitor,
    http_server: newAsyncHttpServer(),
    server_port: port,
    server_active: false
  )

# HTTP Request Handlers
proc handleRequest(server: SimpleAgentServer, req: Request) {.async.} =
  ## Handle HTTP requests for agent management
  let path = req.url.path
  
  case path
  of "/":
    # Serve main agent status page
    let html = """
    <!DOCTYPE html>
    <html>
    <head>
        <title>Agent Status</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 20px; }
            .agent { border: 1px solid #ccc; padding: 10px; margin: 10px 0; }
            .active { background-color: #e8f5e8; }
            .inactive { background-color: #f5f5f5; }
            .status { font-weight: bold; }
        </style>
    </head>
    <body>
        <h1>Project Eidolon - Agent Status</h1>
        <div id="agents"></div>
        <div id="tasks"></div>
        <script>
            function updateStatus() {
                fetch('/api/status')
                    .then(response => response.json())
                    .then(data => {
                        const agentsDiv = document.getElementById('agents');
                        agentsDiv.innerHTML = '<h2>Active Agents</h2>';
                        data.agents.forEach(agent => {
                            const div = document.createElement('div');
                            div.className = 'agent ' + (agent.is_active ? 'active' : 'inactive');
                            div.innerHTML = `
                                <h3>${agent.agent_id}</h3>
                                <p>Type: ${agent.agent_type}</p>
                                <p class="status">Active: ${agent.is_active}</p>
                                <p>Strain: ${agent.current_strain.toFixed(2)}</p>
                                <p>Keywords: ${agent.keywords.join(', ')}</p>
                            `;
                            agentsDiv.appendChild(div);
                        });
                        
                        const tasksDiv = document.getElementById('tasks');
                        tasksDiv.innerHTML = '<h2>Task Queue</h2>';
                        data.tasks.forEach(task => {
                            const div = document.createElement('div');
                            div.className = 'agent';
                            div.innerHTML = `
                                <h3>Task: ${task.id}</h3>
                                <p>Description: ${task.description}</p>
                                <p>Type: ${task.task_type}</p>
                                <p>Status: ${task.status}</p>
                                <p>Priority: ${task.priority}</p>
                            `;
                            tasksDiv.appendChild(div);
                        });
                    });
            }
            updateStatus();
            setInterval(updateStatus, 2000);
        </script>
    </body>
    </html>
    """
    await req.respond(Http200, html, newHttpHeaders({"Content-Type": "text/html"}))
  
  of "/api/status":
    # Return agent and task status
    try:
      var agent_status: seq[JsonNode] = @[]
      for agent_id, agent in server.orchestrator.registry.agents:
        let is_active = server.orchestrator.isAgentActive(agent_id)
        agent_status.add(%*{
          "agent_id": agent_id,
          "agent_type": $agent.agent_type,
          "is_active": is_active,
          "current_strain": agent.current_strain,
          "keywords": agent.keywords
        })
      
      let response = %*{
        "total_agents": agent_status.len,
        "active_agents": server.orchestrator.active_agents.len,
        "agents": agent_status,
        "tasks": @[]  # TODO: Add task status
      }
      
      var headers = newHttpHeaders()
      headers["Content-Type"] = "application/json"
      headers["Access-Control-Allow-Origin"] = "*"
      await req.respond(Http200, $response, headers)
    except:
      let error_response = %*{"error": "Failed to get status"}
      var headers = newHttpHeaders()
      headers["Content-Type"] = "application/json"
      headers["Access-Control-Allow-Origin"] = "*"
      await req.respond(Http500, $error_response, headers)
  
  of "/api/prompt":
    # Handle prompt submission
    if req.reqMethod == HttpPost:
      try:
        let body = await req.body
        let json_data = parseJson(body)
        let prompt = json_data["prompt"].getStr()
        
        echo "Received prompt: ", prompt
        
        # TODO: Process prompt through orchestrator
        let response = %*{
          "status": "received",
          "response": "Prompt received: " & prompt,
          "timestamp": $getTime().toUnix()
        }
        
        var headers = newHttpHeaders()
        headers["Content-Type"] = "application/json"
        headers["Access-Control-Allow-Origin"] = "*"
        await req.respond(Http200, $response, headers)
      except:
        let error_response = %*{
          "status": "error",
          "response": "Failed to process prompt"
        }
        var headers = newHttpHeaders()
        headers["Content-Type"] = "application/json"
        headers["Access-Control-Allow-Origin"] = "*"
        await req.respond(Http500, $error_response, headers)
    else:
      await req.respond(Http405, "Method Not Allowed")
  
  else:
    await req.respond(Http404, "Not Found")

# Server Management
proc startServer*(server: SimpleAgentServer) {.async.} =
  ## Start the agent server
  server.server_active = true

  # Create request handler
  proc handleClient(request: Request) {.async.} =
    try:
      await handleRequest(server, request)
    except:
      echo "Error handling request: ", getCurrentExceptionMsg()
      try:
        await request.respond(Http500, "Internal Server Error")
      except:
        discard

  # Start HTTP server
  echo "Starting Simple Agent Server on port " & $server.server_port
  echo "Open http://localhost:" & $server.server_port & " in your browser"

  await server.http_server.serve(Port(server.server_port), handleClient)

# Main entry point
when isMainModule:
  # Create and start agent server
  var server = newSimpleAgentServer(3001)
  
  # Start the server
  waitFor server.startServer()
  
  echo "Agent server started successfully!"
  echo "Background and foreground agents are now running."
  echo "Connect to http://localhost:3001 to see agent status." 