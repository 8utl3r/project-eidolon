#!/bin/bash

echo "🎭 Starting Eidolon AI Interaction Interface..."
echo "============================================="
echo "This will start an interactive AI interface that demonstrates"
echo "agent coordination through natural language interaction."
echo ""
echo "The Stage Manager will coordinate responses from all agents."
echo ""

# Check if the graph visualizer is running
if ! curl -s http://localhost:5002/api/agents > /dev/null 2>&1; then
    echo "❌ Graph visualizer not running on port 5002"
    echo "Please start the graph visualizer first:"
    echo "  ./scripts/start-graph-gui.sh"
    exit 1
fi

echo "✅ Graph visualizer is running"
echo "🎭 Starting AI interaction interface..."
echo ""

cd tools && python3 ai_interaction_interface.py 