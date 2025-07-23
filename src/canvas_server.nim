# Canvas Server
#
# This module provides a simple HTTP server for the canvas interface.
# It serves the HTML/CSS/JS frontend and provides API endpoints for
# graph data and agent interactions.

import std/[times, tables, options, json, strutils, asyncdispatch, httpcore, 
            asynchttpserver, jsonutils, base64, mimetypes, os]
import types
import database/operations
import database/word_loader
import entities/manager
import thoughts/manager
import agents/registry
import agents/eidolon/eidolon
import agents/attention_system
import agents/role_prompts
import api/ollama_client
import knowledge_graph/types
import knowledge_graph/operations

type
  CanvasServer* = ref object
    ## Simple HTTP server for canvas interface
    server*: AsyncHttpServer
    port*: int
    entity_manager*: EntityManager
    thought_manager*: ThoughtManager
    agent_registry*: AgentRegistry
    eidolon_agent*: EidolonAgent
    attention_system*: AttentionSystem
    mime_types*: MimeDB
    stage_manager_active*: bool  # Track if Stage Manager is coordinating

# Constructor
proc newCanvasServer*(port: int = 8080): CanvasServer =
  ## Create a new canvas server
  var entity_manager = newEntityManager()
  var thought_manager = newThoughtManager()
  var agent_registry = newAgentRegistry()
  
  # Initialize default agents
  discard agent_registry.initializeDefaultAgents()
  
  # Stage Manager is the default active coordinator
  discard agent_registry.setAgentState("stage_manager", AgentState.active)
  
  # Make background agents available for thought processing
  discard agent_registry.setAgentState("engineer", AgentState.available)
  discard agent_registry.setAgentState("philosopher", AgentState.available)
  discard agent_registry.setAgentState("skeptic", AgentState.available)
  discard agent_registry.setAgentState("dreamer", AgentState.available)
  discard agent_registry.setAgentState("investigator", AgentState.available)
  discard agent_registry.setAgentState("archivist", AgentState.available)
  discard agent_registry.setAgentState("linguist", AgentState.available)
  
  # Eidolon starts inactive - Stage Manager controls when it's active
  discard agent_registry.setAgentState("eidolon", AgentState.inactive)
  
  # Load word data
  try:
    let (entities_loaded, thoughts_loaded) = loadFromFiles(
      entity_manager, thought_manager,
      "tools/word_nodes.json", 
      "tools/verified_thoughts.json"
    )
    echo "Loaded ", entities_loaded, " entities and ", thoughts_loaded, " thoughts"
  except:
    echo "Warning: Could not load word data, using empty graph"
  
  # Create knowledge graph
  var knowledge_graph = newKnowledgeGraph()
  knowledge_graph.entity_manager = entity_manager
  knowledge_graph.thought_manager = thought_manager
  
  # Create Ollama client
  var ollama_client = newOllamaClient()
  
  # Create Eidolon agent
  var eidolon_agent = newEidolonAgent(ollama_client, knowledge_graph, thought_manager, agent_registry)
  
  # Create attention system
  var attention_system = newAttentionSystem()
  
  return CanvasServer(
    server: newAsyncHttpServer(),
    port: port,
    entity_manager: entity_manager,
    thought_manager: thought_manager,
    agent_registry: agent_registry,
    eidolon_agent: eidolon_agent,
    attention_system: attention_system,
    stage_manager_active: true,
    mime_types: newMimetypes()
  )

# Helper function to get MIME type
proc getMimeType*(path: string): string =
  let ext = path.splitFile().ext
  case ext
  of ".html": return "text/html"
  of ".css": return "text/css"
  of ".js": return "application/javascript"
  of ".json": return "application/json"
  of ".png": return "image/png"
  of ".jpg", ".jpeg": return "image/jpeg"
  of ".svg": return "image/svg+xml"
  else: return "text/plain"

# Helper function to determine relevant agents for a thought
proc determineRelevantAgents*(thought: Thought): seq[string] =
  ## Determine which agents should process a given thought based on content
  var relevant_agents: seq[string] = @[]
  let content = thought.description.toLowerAscii()
  
  # Dreamer processes ALL thoughts (universal domain)
  relevant_agents.add("dreamer")
  
  # Check for mathematical content
  if content.contains("=") or content.contains("+") or content.contains("-") or 
     content.contains("*") or content.contains("/") or content.contains("math") or
     content.contains("calculate") or content.contains("equation"):
    relevant_agents.add("engineer")
  
  # Check for logical content
  if content.contains("if") or content.contains("then") or content.contains("therefore") or
     content.contains("contradiction") or content.contains("logic") or content.contains("reasoning"):
    relevant_agents.add("skeptic")
  
  # Check for philosophical content
  if content.contains("meaning") or content.contains("purpose") or content.contains("existence") or
     content.contains("philosophy") or content.contains("ethics") or content.contains("truth"):
    relevant_agents.add("philosopher")
  
  # Check for pattern/causal content
  if content.contains("pattern") or content.contains("cause") or content.contains("effect") or
     content.contains("relationship") or content.contains("connection"):
    relevant_agents.add("investigator")
  
  # Check for organizational content
  if content.contains("category") or content.contains("classify") or content.contains("organize") or
     content.contains("group") or content.contains("sort"):
    relevant_agents.add("archivist")
  
  # Check for linguistic content
  if content.contains("word") or content.contains("language") or content.contains("grammar") or
     content.contains("vocabulary") or content.contains("sentence"):
    relevant_agents.add("linguist")
  
  return relevant_agents

# Thought extraction and processing functions
proc extractThoughtsFromPrompt*(prompt: string): seq[Thought] =
  ## Extract thoughts from user prompt
  var thoughts: seq[Thought] = @[]
  
  # Simple extraction - split into sentences and create thoughts
  let sentences = prompt.split({'.', '!', '?'})
  for i, sentence in sentences:
    if sentence.strip().len > 5:  # Only meaningful sentences
      let thought = newThought(
        "prompt_thought_" & $getTime().toUnix() & "_" & $i,
        "User input: " & sentence.strip(),
        sentence.strip(),
        @[],  # No connections yet
        true,  # verified
        "user_input",  # verification_source
        0.8   # High confidence for user input
      )
      thoughts.add(thought)
  
  return thoughts

proc extractThoughtsFromResponse*(response: string): seq[Thought] =
  ## Extract thoughts from AI response
  var thoughts: seq[Thought] = @[]
  
  # Simple extraction - split into sentences and create thoughts
  let sentences = response.split({'.', '!', '?'})
  for i, sentence in sentences:
    if sentence.strip().len > 5:  # Only meaningful sentences
      let thought = newThought(
        "response_thought_" & $getTime().toUnix() & "_" & $i,
        "AI response: " & sentence.strip(),
        sentence.strip(),
        @[],  # No connections yet
        true,  # verified
        "ai_response",  # verification_source
        0.7   # Medium confidence for AI responses
      )
      thoughts.add(thought)
  
  return thoughts

proc processNewThoughtsWithAgents*(server: CanvasServer, thoughts: seq[Thought]): Future[void] {.async.} =
  ## Process new thoughts with focused, budget-controlled background agents
  for thought in thoughts:
    echo "Stage Manager: Processing thought: ", thought.description
    
    # Stage Manager determines which agents should process this thought
    let relevant_agents = determineRelevantAgents(thought)
    
    for agent_id in relevant_agents:
      if agent_id in server.agent_registry.agents:
        let agent = server.agent_registry.agents[agent_id]
        if agent.state == AgentState.available:
          echo "Stage Manager: Focusing ", agent_id, " on thought with budget 0.3"
          
          # Stage Manager provides focused prompt with budget
          let focus_prompt = GLOBAL_AGENT_PROMPT & "\n\n" & getAgentPrompt(agent.agent_type) & 
                           "\n\nSTAGE MANAGER FOCUS:\nThought ID: " & thought.id & 
                           "\nThought Content: " & thought.description & 
                           "\nResistance Budget: 0.3\n\nProcess this thought within your domain and budget."
          
          # Get agent's focused response
          let ollama_req = newOllamaRequest(server.eidolon_agent.ollama_client.default_model, focus_prompt)
          let agent_response_opt = await server.eidolon_agent.ollama_client.generateResponse(ollama_req)
          
          if agent_response_opt.isSome:
            let agent_response = agent_response_opt.get.response.strip()
            echo "  ", agent_id, ": ", agent_response
            
            # Parse agent response and add thought if needed
            if agent_response.startsWith("PROCESS:"):
              let new_thought_content = agent_response[8..^1].strip()  # Remove "PROCESS: "
              let new_thought = newThought(
                "agent_" & agent_id & "_" & $getTime().toUnix(),
                agent_id & " processed: " & new_thought_content,
                new_thought_content,
                @[thought.id],  # Connect to original thought
                true,  # verified
                agent_id & "_processing",  # verification_source
                0.7  # High confidence for focused processing
              )
              discard server.thought_manager.addThought(new_thought)
              
              # Log thought creation in structured format
              let words = new_thought_content.splitWhitespace()
              var formatted_thought = agent_id & ": ["
              for i, word in words:
                if i > 0: formatted_thought.add("][")
                formatted_thought.add(word)
                formatted_thought.add("]")
              echo "    ", formatted_thought
            elif agent_response.startsWith("SKIP:"):
              echo "    Skipped: ", agent_response[5..^1].strip()
            else:
              echo "    Invalid response format: ", agent_response

# Serve static files
proc serveStaticFile*(req: Request, path: string): Future[void] {.async.} =
  ## Serve a static file
  let file_path = "tools/templates/" & path
  try:
    let content = readFile(file_path)
    let mime_type = getMimeType(path)
    
    var headers = newHttpHeaders()
    headers["Content-Type"] = mime_type
    headers["Content-Length"] = $content.len
    await req.respond(Http200, content, headers)
  except:
    await req.respond(Http404, "File not found: " & path)

# Convert entities to graph nodes
proc entitiesToGraphNodes*(entity_manager: EntityManager): JsonNode =
  ## Convert entities to graph nodes format
  var nodes: seq[JsonNode] = @[]
  
  for entity in entity_manager.entities.values:
    var node = %*{
      "id": entity.id,
      "name": entity.name,
      "type": $entity.entity_type,
      "description": entity.description,
      "strain": {
        "amplitude": entity.strain.amplitude,
        "resistance": entity.strain.resistance,
        "frequency": entity.strain.frequency,
        "access_count": entity.strain.access_count
      },
      "x": entity.strain.access_count.float * 10,  # Simple positioning
      "y": entity.strain.amplitude * 500
    }
    nodes.add(node)
  
  return %*{"nodes": nodes}

# Convert thoughts to graph links
proc thoughtsToGraphLinks*(thought_manager: ThoughtManager): JsonNode =
  ## Convert thoughts to graph links format
  var links: seq[JsonNode] = @[]
  
  for thought in thought_manager.thoughts.values:
    if thought.connections.len >= 2:
      # Create links between consecutive entities in the thought
      for i in 0..<thought.connections.len-1:
        var link = %*{
          "source": thought.connections[i],
          "target": thought.connections[i+1],
          "type": "thought_connection",
          "thought_id": thought.id,
          "confidence": thought.confidence
        }
        links.add(link)
  
  return %*{"links": links}

# API endpoint for graph data
proc handleGraphData*(server: CanvasServer, req: Request): Future[void] {.async.} =
  ## Handle GET /api/graph/data
  let nodes = entitiesToGraphNodes(server.entity_manager)
  let links = thoughtsToGraphLinks(server.thought_manager)
  
  let response = %*{
    "nodes": nodes["nodes"],
    "links": links["links"]
  }
  
  var headers = newHttpHeaders()
  headers["Content-Type"] = "application/json"
  headers["Access-Control-Allow-Origin"] = "*"
  await req.respond(Http200, $response, headers)

# API endpoint for search
proc handleSearch*(server: CanvasServer, req: Request): Future[void] {.async.} =
  ## Handle GET /api/search?q=<query>
  # For now, just return all entities as search results
  # TODO: Implement proper query parameter parsing
  var results: seq[JsonNode] = @[]
  
  # Return all entities as search results
  for entity in server.entity_manager.entities.values:
    results.add(%*{
      "id": entity.id,
      "name": entity.name,
      "type": "entity",
      "description": entity.description
    })
  
  # Also return thoughts
  for thought in server.thought_manager.thoughts.values:
    results.add(%*{
      "id": thought.id,
      "name": thought.name,
      "type": "thought",
      "description": thought.description
    })
  
  let response = %*{"results": results}
  var headers = newHttpHeaders()
  headers["Content-Type"] = "application/json"
  headers["Access-Control-Allow-Origin"] = "*"
  await req.respond(Http200, $response, headers)

# API endpoint for agents
proc handleAgents*(server: CanvasServer, req: Request): Future[void] {.async.} =
  ## Handle GET /api/agents
  var agents: seq[JsonNode] = @[]
  
  for agent_id, agent in server.agent_registry.agents:
    agents.add(%*{
      "id": agent_id,
      "type": $agent.agent_type,
      "state": $agent.state,
      "keywords": agent.keywords,
      "strain": agent.current_strain,
      "max_strain": agent.max_strain,
      "created": $agent.created,
      "last_accessed": $agent.last_accessed
    })
  
  let response = %*{
    "agents": agents,
    "total": agents.len,
    "active": server.agent_registry.getActiveAgents().len,
    "available": server.agent_registry.getAvailableAgents().len,
    "inactive": server.agent_registry.getInactiveAgents().len
  }
  
  var headers = newHttpHeaders()
  headers["Content-Type"] = "application/json"
  headers["Access-Control-Allow-Origin"] = "*"
  await req.respond(Http200, $response, headers)

# API endpoint for toggling agents
proc handleAgentToggle*(server: CanvasServer, req: Request): Future[void] {.async.} =
  ## Handle POST /api/agents/toggle
  try:
    let body = req.body
    let data = parseJson(body)
    
    let agent_id = data["agent_id"].getStr()
    let action = data["action"].getStr()
    
    case action
    of "start":
      # Stage Manager controls all agent states
      if agent_id == "stage_manager":
        # Stage Manager is always active
        discard server.agent_registry.setAgentState(agent_id, AgentState.active)
        echo "Stage Manager: Maintaining coordination role"
      elif agent_id == "eidolon":
        # Stage Manager can activate Eidolon for user interaction
        discard server.agent_registry.setAgentState(agent_id, AgentState.active)
        echo "Stage Manager: Activated Eidolon for user interaction"
      else:
        # Background agents become available for thought processing
        discard server.agent_registry.setAgentState(agent_id, AgentState.available)
        echo "Stage Manager: Made ", agent_id, " available for thought processing"
      
    of "stop":
      if agent_id == "stage_manager":
        # Stage Manager cannot be stopped
        echo "Stage Manager: Cannot be deactivated - maintaining system coordination"
      else:
        discard server.agent_registry.setAgentState(agent_id, AgentState.inactive)
        echo "Stage Manager: Deactivated ", agent_id
      
    else:
      await req.respond(Http400, "Invalid action: " & action)
      return
    
    var headers = newHttpHeaders()
    headers["Content-Type"] = "application/json"
    headers["Access-Control-Allow-Origin"] = "*"
    await req.respond(Http200, "{\"status\": \"success\"}", headers)
    
  except:
    let error_msg = "Error toggling agent: " & getCurrentExceptionMsg()
    await req.respond(Http500, error_msg)

# API endpoint for system state control
proc handleSystemState*(server: CanvasServer, req: Request): Future[void] {.async.} =
  ## Handle POST /api/system/state
  try:
    let body = req.body
    let json = parseJson(body)
    let state = json["state"].getStr()
    
    case state.toLowerAscii()
    of "wake":
      server.attention_system.system_state = SystemState.wake
    of "dream":
      server.attention_system.system_state = SystemState.dream
    of "sleep":
      server.attention_system.system_state = SystemState.sleep
    else:
      let error_response = %*{"status": "error", "message": "Invalid state"}
      var headers = newHttpHeaders()
      headers["Content-Type"] = "application/json"
      await req.respond(Http400, $error_response)
      return
    
    let response = %*{"status": "success", "state": state}
    var headers = newHttpHeaders()
    headers["Content-Type"] = "application/json"
    await req.respond(Http200, $response, headers)
  except:
    echo "Error handling system state: ", getCurrentExceptionMsg()
    await req.respond(Http500, "Internal Server Error")

# API endpoint for triggering dream tasks
proc handleTriggerDreamTasks*(server: CanvasServer, req: Request): Future[void] {.async.} =
  ## Handle POST /api/system/trigger-dream-tasks
  try:
    # Trigger autonomous dream tasks manually
    triggerAutonomousDuties(server.attention_system)
    
    let response = %*{"status": "success", "message": "Dream tasks triggered"}
    var headers = newHttpHeaders()
    headers["Content-Type"] = "application/json"
    await req.respond(Http200, $response, headers)
  except:
    echo "Error triggering dream tasks: ", getCurrentExceptionMsg()
    await req.respond(Http500, "Internal Server Error")

# API endpoint for sending prompts to Eidolon agent
proc handleSendPrompt*(server: CanvasServer, req: Request): Future[void] {.async.} =
  ## Handle POST /api/send-prompt
  try:
    let body = req.body
    let data = parseJson(body)
    let prompt = data["prompt"].getStr()
    
    echo "Received prompt: ", prompt
    
    # Extract thoughts from the prompt and add to graph
    let extracted_thoughts = extractThoughtsFromPrompt(prompt)
    for thought in extracted_thoughts:
      discard server.thought_manager.addThought(thought)
      
      # Log initial thought extraction in structured format
      let words = thought.description.splitWhitespace()
      var formatted_thought = "user: ["
      for i, word in words:
        if i > 0: formatted_thought.add("][")
        formatted_thought.add(word)
        formatted_thought.add("]")
      echo formatted_thought
    
    # Process new thoughts with background agents
    await processNewThoughtsWithAgents(server, extracted_thoughts)
    
    # Activate Eidolon for response generation
    discard server.agent_registry.setAgentState("eidolon", AgentState.active)
    
    # Use the actual Eidolon agent for full AI responses
    let response = await server.eidolon_agent.processUserQuery(prompt)
    
    # Extract thoughts from the response and add to graph
    let response_thoughts = extractThoughtsFromResponse(response)
    for thought in response_thoughts:
      discard server.thought_manager.addThought(thought)
      
      # Log response thought extraction in structured format
      let words = thought.description.splitWhitespace()
      var formatted_thought = "eidolon: ["
      for i, word in words:
        if i > 0: formatted_thought.add("][")
        formatted_thought.add(word)
        formatted_thought.add("]")
      echo formatted_thought
    
    # Process response thoughts with background agents
    await processNewThoughtsWithAgents(server, response_thoughts)
    
    # Deactivate Eidolon after response
    discard server.agent_registry.setAgentState("eidolon", AgentState.inactive)
    
    let response_data = %*{
      "status": "success",
      "response": response,
      "timestamp": $getTime().toUnix()
    }
    
    var headers = newHttpHeaders()
    headers["Content-Type"] = "application/json"
    headers["Access-Control-Allow-Origin"] = "*"
    await req.respond(Http200, $response_data, headers)
    
  except:
    echo "Error processing prompt: ", getCurrentExceptionMsg()
    let error_response = %*{
      "status": "error",
      "response": "Failed to process prompt",
      "error": getCurrentExceptionMsg()
    }
    var error_headers = newHttpHeaders()
    error_headers["Content-Type"] = "application/json"
    error_headers["Access-Control-Allow-Origin"] = "*"
    await req.respond(Http500, $error_response, error_headers)

# Main request handler
proc handleRequest*(server: CanvasServer, req: Request): Future[void] {.async.} =
  ## Handle incoming HTTP requests
  let path = req.url.path
  
  case path
  of "/":
    await serveStaticFile(req, "performance_canvas.html")
  of "/api/graph/data":
    await handleGraphData(server, req)
  of "/api/search":
    await handleSearch(server, req)
  of "/api/agents":
    if req.reqMethod == HttpGet:
      await handleAgents(server, req)
    else:
      await req.respond(Http405, "Method not allowed")
  of "/api/agents/toggle":
    if req.reqMethod == HttpPost:
      await handleAgentToggle(server, req)
    else:
      await req.respond(Http405, "Method not allowed")
  of "/api/system/state":
    if req.reqMethod == HttpPost:
      await handleSystemState(server, req)
    else:
      await req.respond(Http405, "Method not allowed")
  of "/api/system/trigger-dream-tasks":
    if req.reqMethod == HttpPost:
      await handleTriggerDreamTasks(server, req)
    else:
      await req.respond(Http405, "Method not allowed")
  of "/api/send-prompt":
    if req.reqMethod == HttpPost:
      await handleSendPrompt(server, req)
    else:
      await req.respond(Http405, "Method not allowed")
  else:
    # Try to serve as static file
    await serveStaticFile(req, path[1..^1])  # Remove leading slash

# Start the server
proc start*(server: CanvasServer) {.async.} =
  ## Start the canvas server
  echo "Starting Canvas Server on port ", server.port
  echo "Open http://localhost:", server.port, " in your browser"
  
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

# Main entry point
proc main() =
  echo "Project Eidolon - Canvas Server"
  echo "==============================="
  echo "Starting full canvas interface..."
  
  var server = newCanvasServer(8080)
  waitFor server.start()

when isMainModule:
  main() 