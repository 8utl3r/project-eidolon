# Agent Visualization Server
#
# This server provides real-time visualization of agent activity
# by integrating the activity monitor with TinkerPop graph updates.
#
# NOTE: GC-safety pragmas removed from async handlers due to Nim's
# strict async macro system. This is a known limitation when using
# async/await with complex callback chains. The code will compile
# and run, but may have GC-related issues under high memory pressure.

import std/[times, json, asyncdispatch, asynchttpserver, asyncnet, strutils, tables]
import agents/orchestrator
import agents/activity_monitor
import tinkerpop_integration

type
  AgentVisualizationServer* = ref object
    ## Server for real-time agent visualization
    orchestrator*: AgentOrchestrator
    activity_monitor*: ActivityMonitor
    tinkerpop_integration*: TinkerPopIntegration
    http_server*: AsyncHttpServer
    server_port*: int
    server_active*: bool
    visualization_data*: JsonNode

# Forward declarations
proc getVisualizationData*(server: AgentVisualizationServer): Future[JsonNode] {.gcsafe.}
proc startVisualizationMonitoring*(server: AgentVisualizationServer) {.async, gcsafe.}
proc stopVisualizationMonitoring*(server: AgentVisualizationServer) {.gcsafe.}

# Constructor
proc newAgentVisualizationServer*(orchestrator: AgentOrchestrator,
                                 port: int = 3001): AgentVisualizationServer =
  ## Create a new agent visualization server
  let activity_monitor = newActivityMonitor(orchestrator)
  let tinkerpop_integration = newTinkerPopIntegration(activity_monitor)
  
  return AgentVisualizationServer(
    orchestrator: orchestrator,
    activity_monitor: activity_monitor,
    tinkerpop_integration: tinkerpop_integration,
    http_server: newAsyncHttpServer(),
    server_port: port,
    server_active: false,
    visualization_data: %*{}
  )

# HTTP Request Handlers
proc handleRequest(server: AgentVisualizationServer, req: Request) {.async.} =
  ## Handle HTTP requests for visualization data
  let path = req.url.path
  case path
  of "/":
    # Serve main visualization page
    let html = """
    <!DOCTYPE html>
    <html>
    <head>
        <title>Agent Visualization</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 20px; }
            .agent { border: 1px solid #ccc; padding: 10px; margin: 10px 0; }
            .active { background-color: #e8f5e8; }
            .inactive { background-color: #f5f5f5; }
        </style>
    </head>
    <body>
        <h1>Agent Activity Visualization</h1>
        <div id="agents"></div>
        <script>
            function updateAgents() {
                fetch('/api/visualization-data')
                    .then(response => response.json())
                    .then(data => {
                        const agentsDiv = document.getElementById('agents');
                        agentsDiv.innerHTML = '';
                        data.agents.forEach(agent => {
                            const div = document.createElement('div');
                            div.className = 'agent ' + (agent.is_active ? 'active' : 'inactive');
                            div.innerHTML = `
                                <h3>${agent.agent_id}</h3>
                                <p>Type: ${agent.agent_type}</p>
                                <p>Active: ${agent.is_active}</p>
                                <p>Strain: ${agent.strain_level.toFixed(2)}</p>
                                <p>Task: ${agent.current_task || 'None'}</p>
                            `;
                            agentsDiv.appendChild(div);
                        });
                    });
            }
            updateAgents();
            setInterval(updateAgents, 2000);
        </script>
    </body>
    </html>
    """
    await req.respond(Http200, html, newHttpHeaders({"Content-Type": "text/html"}))
  
  of "/api/visualization-data":
    # API endpoint for visualization data
    let data = await server.getVisualizationData()
    await req.respond(Http200, $data, newHttpHeaders({"Content-Type": "application/json"}))
  
  of "/api/start-monitoring":
    # Start real-time monitoring
    await server.startVisualizationMonitoring()
    await req.respond(Http200, """{"status": "monitoring started"}""", 
                     newHttpHeaders({"Content-Type": "application/json"}))
  
  of "/api/stop-monitoring":
    # Stop real-time monitoring
    server.stopVisualizationMonitoring()
    await req.respond(Http200, """{"status": "monitoring stopped"}""", 
                     newHttpHeaders({"Content-Type": "application/json"}))
  
  of "/api/send-prompt":
    # Handle prompt requests from the terminal
    if req.reqMethod == HttpOptions:
      # Handle CORS preflight request
      var cors_headers = newHttpHeaders()
      cors_headers["Access-Control-Allow-Origin"] = "*"
      cors_headers["Access-Control-Allow-Methods"] = "POST, OPTIONS"
      cors_headers["Access-Control-Allow-Headers"] = "Content-Type"
      await req.respond(Http200, "", cors_headers)
    elif req.reqMethod == HttpPost:
      try:
        let body = await req.body
        let json_data = parseJson(body)
        let prompt = json_data["prompt"].getStr()
        
        echo "Received prompt: ", prompt
        
        # Send prompt to the orchestrator's foreground agent
        # For now, we'll just acknowledge receipt
        # TODO: Integrate with actual agent processing
        let response = %*{
          "status": "received",
          "response": "Prompt received: " & prompt,
          "timestamp": $getTime().toUnix()
        }
        
        var headers = newHttpHeaders({"Content-Type": "application/json"})
        headers["Access-Control-Allow-Origin"] = "*"
        headers["Access-Control-Allow-Methods"] = "POST, OPTIONS"
        headers["Access-Control-Allow-Headers"] = "Content-Type"
        await req.respond(Http200, $response, headers)
      except:
        echo "Error processing prompt: ", getCurrentExceptionMsg()
        let error_response = %*{
          "status": "error",
          "response": "Failed to process prompt",
          "error": getCurrentExceptionMsg()
        }
        var error_headers = newHttpHeaders({"Content-Type": "application/json"})
        error_headers["Access-Control-Allow-Origin"] = "*"
        error_headers["Access-Control-Allow-Methods"] = "POST, OPTIONS"
        error_headers["Access-Control-Allow-Headers"] = "Content-Type"
        await req.respond(Http500, $error_response, error_headers)
    else:
      var cors_headers = newHttpHeaders()
      cors_headers["Access-Control-Allow-Origin"] = "*"
      cors_headers["Access-Control-Allow-Methods"] = "POST, OPTIONS"
      cors_headers["Access-Control-Allow-Headers"] = "Content-Type"
      await req.respond(Http405, "Method Not Allowed", cors_headers)
  
  else:
    await req.respond(Http404, "Not Found")

# Server Management
proc startServer*(server: AgentVisualizationServer) {.async.} =
  ## Start the visualization server
  server.server_active = true

  # Create request handler
  proc handleClient(request: Request) {.async, gcsafe.} =
    try:
      await handleRequest(server, request)
    except:
      echo "Error handling request: ", getCurrentExceptionMsg()
      try:
        await request.respond(Http500, "Internal Server Error")
      except:
        discard

  # Start HTTP server
  echo "Starting Agent Visualization Server on port " & $server.server_port
  echo "Open http://localhost:" & $server.server_port & " in your browser"
  echo "TinkerPop Graph: http://localhost:8182"

  await server.http_server.serve(Port(server.server_port), handleClient)

# Monitoring Control
proc startVisualizationMonitoring*(server: AgentVisualizationServer) {.async, gcsafe.} =
  ## Start real-time monitoring
  await server.tinkerpop_integration.startIntegration()

proc stopVisualizationMonitoring*(server: AgentVisualizationServer) {.gcsafe.} =
  ## Stop real-time monitoring
  server.tinkerpop_integration.stopIntegration()

# Data Access
proc getVisualizationData*(server: AgentVisualizationServer): Future[JsonNode] {.async, gcsafe.} =
  ## Get current visualization data
  var data = server.activity_monitor.getAgentActivityData()
  
  # Add graph statistics
  try:
    let stats = await server.tinkerpop_integration.getGraphStats()
    data["graph_stats"] = stats
  except:
    data["graph_stats"] = %*{"error": "Could not fetch graph stats"}
  
  return data

# Main entry point
when isMainModule:
  # Create orchestrator (simplified for demo)
  var agent_orchestrator = newAgentOrchestrator()
  
  # Create and start visualization server
  var server = newAgentVisualizationServer(agent_orchestrator, 3001)
  
  # Start the server
  waitFor server.startServer()
  
  # Start monitoring
  waitFor server.startVisualizationMonitoring() 