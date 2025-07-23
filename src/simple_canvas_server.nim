# Simple Canvas Server
#
# Minimal server for displaying nodes in the full canvas interface.

import std/[times, tables, json, strutils, asyncdispatch, asynchttpserver, os]
import ./types
import ./entities/manager
import ./thoughts/manager
import ./database/word_loader

type
  SimpleCanvasServer* = object
    server*: AsyncHttpServer
    port*: int
    entity_manager*: EntityManager
    thought_manager*: ThoughtManager

# Constructor
proc newSimpleCanvasServer*(port: int = 3000): SimpleCanvasServer =
  ## Create a new simple canvas server
  var entity_manager = newEntityManager()
  var thought_manager = newThoughtManager()
  
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
  
  return SimpleCanvasServer(
    server: newAsyncHttpServer(),
    port: port,
    entity_manager: entity_manager,
    thought_manager: thought_manager
  )

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
      }
    }
    nodes.add(node)
  
  return %*{"nodes": nodes}

# API endpoint for graph data
proc handleGraphData*(server: SimpleCanvasServer, req: Request): Future[void] {.async.} =
  ## Handle GET /api/graph/data
  let nodes = entitiesToGraphNodes(server.entity_manager)
  
  # Convert verified thoughts to connections
  var verified_connections: seq[JsonNode] = @[]
  let verified_thoughts = server.thought_manager.getVerifiedThoughts()
  echo "Found ", verified_thoughts.len, " verified thoughts"
  
  for thought in verified_thoughts:
    # Only create connections for multi-word thoughts (actual sequences)
    if thought.connections.len > 1:
      for i in 0..<thought.connections.len - 1:
        let from_id = thought.connections[i]
        let to_id = thought.connections[i + 1]
        # Only create connection if both entities exist
        if server.entity_manager.entities.hasKey(from_id) and server.entity_manager.entities.hasKey(to_id):
          let connection = %*{
            "from": from_id,
            "to": to_id,
            "verified": true,
            "thought_id": thought.id,
            "strain": thought.strain.amplitude
          }
          verified_connections.add(connection)
  
  echo "Created ", verified_connections.len, " verified connections (only from multi-word thoughts)"
  
  let response = %*{
    "nodes": nodes["nodes"],
    "verified_connections": verified_connections,
    "links": @[]  # Regular links for future use
  }
  
  var headers = newHttpHeaders()
  headers["Content-Type"] = "application/json"
  headers["Access-Control-Allow-Origin"] = "*"
  await req.respond(Http200, $response, headers)

# Serve static files
proc serveStaticFile*(req: Request, path: string): Future[void] {.async.} =
  ## Serve a static file
  let file_path = "tools/templates/" & path
  try:
    let content = readFile(file_path)
    var headers = newHttpHeaders()
    headers["Content-Type"] = "text/html"
    await req.respond(Http200, content, headers)
  except:
    await req.respond(Http404, "File not found: " & path)

# Main request handler
proc handleRequest*(server: SimpleCanvasServer, req: Request): Future[void] {.async.} =
  ## Handle incoming HTTP requests
  let path = req.url.path
  
  case path
  of "/":
    await serveStaticFile(req, "performance_canvas.html")
  of "/api/graph/data":
    await handleGraphData(server, req)
  else:
    await req.respond(Http404, "Not found")

# Start the server
proc start*(server: SimpleCanvasServer) {.async.} =
  ## Start the canvas server
  echo "Starting Simple Canvas Server on port ", server.port
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
  echo "Project Eidolon - Simple Canvas Server"
  echo "======================================"
  echo "Starting full canvas interface..."
  
  let server = newSimpleCanvasServer(3000)
  waitFor server.start()

when isMainModule:
  main() 