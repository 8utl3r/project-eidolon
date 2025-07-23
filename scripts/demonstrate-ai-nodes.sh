#!/bin/bash

echo "🎭 AI Node Interaction Demonstration"
echo "===================================="
echo "This will demonstrate AI agents actually creating and modifying"
echo "knowledge graph nodes through their reasoning processes."
echo ""

# Check if the graph visualizer is running
if ! curl -s http://localhost:5002/api/agents > /dev/null 2>&1; then
    echo "❌ Graph visualizer not running on port 5002"
    echo "Please start the graph visualizer first:"
    echo "  ./scripts/start-graph-gui.sh"
    exit 1
fi

echo "✅ Graph visualizer is running"
echo "🎭 Starting AI node interaction demonstration..."
echo ""

cd tools && python3 ai_node_interaction.py 