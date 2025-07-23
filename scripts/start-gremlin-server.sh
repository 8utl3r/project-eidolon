#!/bin/bash
# Start Gremlin Server for Project Eidolon
# Apache TinkerPop 3.7.0

echo "Starting Gremlin Server for Project Eidolon..."
echo "=============================================="

# Set the TinkerPop directory (using symlink to avoid path issues)
TINKERPOP_DIR="/tmp/project-eidolon/tools/tinkerpop/apache-tinkerpop-gremlin-server-3.7.0"

# Check if TinkerPop is installed
if [ ! -d "$TINKERPOP_DIR" ]; then
    echo "Error: TinkerPop not found at $TINKERPOP_DIR"
    echo "Please run the TinkerPop setup first"
    exit 1
fi

# Start the Gremlin Server
echo "Starting Gremlin Server..."
echo "Server will be available at: http://localhost:8182"
echo "Press Ctrl+C to stop the server"
echo ""

cd "$TINKERPOP_DIR"
# Use system Java directly to avoid path issues
unset JAVA_HOME
export CLASSPATH=""
./bin/gremlin-server.sh conf/gremlin-server-min.yaml 