#!/bin/bash
# Start Agent Visualization System
# Real-time agent activity monitoring with TinkerPop integration

echo "Starting Agent Visualization System..."
echo "====================================="

# Set the project directory (using symlink to avoid path issues)
PROJECT_DIR="/tmp/project-eidolon"

# Create symlink if it doesn't exist
if [ ! -L "$PROJECT_DIR" ]; then
    echo "Creating symlink for project directory..."
    ln -sf "$(pwd)" "$PROJECT_DIR"
fi

# Check if TinkerPop is available
TINKERPOP_SERVER_DIR="$PROJECT_DIR/tools/tinkerpop/apache-tinkerpop-gremlin-server-3.7.0"
if [ ! -d "$TINKERPOP_SERVER_DIR" ]; then
    echo "Error: TinkerPop server not found at $TINKERPOP_SERVER_DIR"
    echo "Please ensure TinkerPop is properly installed"
    exit 1
fi

# Check if Nim is available
if ! command -v nim &> /dev/null; then
    echo "Error: Nim compiler not found"
    echo "Please install Nim: https://nim-lang.org/install.html"
    exit 1
fi

# Function to start TinkerPop server in background
start_tinkerpop_server() {
    echo "Starting TinkerPop server..."
    cd "$TINKERPOP_SERVER_DIR"
    unset JAVA_HOME
    export CLASSPATH=""
    ./bin/gremlin-server.sh conf/gremlin-server-min.yaml > /tmp/tinkerpop-server.log 2>&1 &
    TINKERPOP_PID=$!
    echo "TinkerPop server started with PID: $TINKERPOP_PID"
    
    # Wait for server to be ready
    echo "Waiting for TinkerPop server to be ready..."
    for i in {1..30}; do
        if curl -s http://localhost:8182 > /dev/null 2>&1; then
            echo "TinkerPop server is ready at http://localhost:8182"
            break
        fi
        sleep 1
    done
}

# Function to start agent visualization server
start_agent_visualization() {
    echo "Starting Agent Visualization Server..."
    cd "$PROJECT_DIR"
    
    # Compile and run the visualization server
    nim c -r src/agent_visualization_server.nim
}

# Function to cleanup on exit
cleanup() {
    echo ""
    echo "Shutting down Agent Visualization System..."
    
    if [ ! -z "$TINKERPOP_PID" ]; then
        echo "Stopping TinkerPop server (PID: $TINKERPOP_PID)..."
        kill $TINKERPOP_PID 2>/dev/null
    fi
    
    echo "Cleanup complete"
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

# Start TinkerPop server
start_tinkerpop_server

# Wait a moment for TinkerPop to fully initialize
sleep 3

# Start agent visualization server
start_agent_visualization

# Keep script running
echo ""
echo "Agent Visualization System is running:"
echo "- Web Interface: http://localhost:3001"
echo "- TinkerPop Graph: http://localhost:8182"
echo ""
echo "Press Ctrl+C to stop all services"
echo ""

# Wait for user interrupt
wait 