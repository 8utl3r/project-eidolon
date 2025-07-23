#!/bin/bash
# Start Gremlin Console for Project Eidolon
# Apache TinkerPop 3.7.0

echo "Starting Gremlin Console for Project Eidolon..."
echo "=============================================="

# Set the TinkerPop directory (using symlink to avoid path issues)
TINKERPOP_DIR="/tmp/project-eidolon/tools/tinkerpop/apache-tinkerpop-gremlin-console-3.7.0"

# Check if TinkerPop is installed
if [ ! -d "$TINKERPOP_DIR" ]; then
    echo "Error: TinkerPop not found at $TINKERPOP_DIR"
    echo "Please run the TinkerPop setup first"
    exit 1
fi

# Start the Gremlin Console
echo "Starting Gremlin Console..."
echo "Use ':help' for commands, ':exit' to quit"
echo ""

cd "$TINKERPOP_DIR"
./bin/gremlin.sh 