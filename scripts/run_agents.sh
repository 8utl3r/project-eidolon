#!/bin/bash

echo "Project Eidolon - Agent System"
echo "=============================="

# Check if Nim is installed
if ! command -v nim &> /dev/null; then
    echo "Error: Nim is not installed or not in PATH"
    exit 1
fi

# Check if Ollama is running
echo "Checking Ollama status..."
if ! curl -s http://127.0.0.1:11434/api/tags > /dev/null; then
    echo "Error: Ollama is not running on port 11434"
    echo "Please start Ollama with: ollama serve"
    exit 1
fi

echo "✅ Ollama is running"

# Kill any existing agent servers
echo "Stopping any existing agent servers..."
pkill -f agent_server 2>/dev/null || true

# Compile and run agent server
echo "Starting Agent Server on port 3001..."
echo "This will run in the background and start agent duties..."
echo ""

# Run agent server in background
nim c -r src/agent_server.nim &
AGENT_PID=$!

echo "Agent Server started with PID: $AGENT_PID"
echo "Agent Server running on: http://localhost:3001"
echo ""
echo "API Endpoints:"
echo "  POST http://localhost:3001/api/tasks/add - Add a new task"
echo "  GET  http://localhost:3001/api/tasks/status - Get task status"
echo "  GET  http://localhost:3001/api/agents/status - Get agent status"
echo "  POST http://localhost:3001/api/agents/activate - Activate an agent"
echo "  POST http://localhost:3001/api/agents/deactivate - Deactivate an agent"
echo ""
echo "Example: Add a math task:"
echo "curl -X POST http://localhost:3001/api/tasks/add \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"description\": \"Calculate the derivative of x^2\", \"type\": \"math_calculation\", \"input_data\": {\"expression\": \"x^2\"}}'"
echo ""
echo "Press Ctrl+C to stop the agent server"
echo ""

# Wait for the background process
wait $AGENT_PID 