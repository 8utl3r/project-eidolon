#!/bin/bash
# Show Project Eidolon Graph GUI Status

echo "Project Eidolon Graph Visualizer Status"
echo "======================================="

# Check if the Flask app is running
if pgrep -f "graph_visualizer.py" > /dev/null; then
    echo "✅ Graph Visualizer is running"
    
    # Find the port it's using
    PORT=$(lsof -i -P | grep Python | grep LISTEN | grep -o ":[0-9]*" | head -1 | cut -d: -f2)
    
    if [ ! -z "$PORT" ]; then
        echo "🌐 URL: http://localhost:$PORT"
        echo ""
        echo "Open this URL in your browser to access the GUI"
        echo ""
        echo "Features available:"
        echo "  • Dashboard with graph statistics"
        echo "  • Agent visualization and strain data"
        echo "  • Entity exploration and filtering"
        echo "  • Relationship mapping"
        echo "  • Strain analysis"
    else
        echo "⚠️  Server is running but port detection failed"
    fi
else
    echo "❌ Graph Visualizer is not running"
    echo ""
    echo "To start it, run:"
    echo "  ./scripts/start-graph-gui.sh"
fi 