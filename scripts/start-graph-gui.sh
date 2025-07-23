#!/bin/bash
# Start Project Eidolon Graph Visualizer GUI
# A web-based interface for exploring the strain-based knowledge graph

echo "Starting Project Eidolon Graph Visualizer..."
echo "============================================"

# Check if Python is available
if ! command -v python3 &> /dev/null; then
    echo "Error: Python 3 is required but not installed"
    echo "Please install Python 3 and try again"
    exit 1
fi

# Check if Flask is installed
if ! python3 -c "import flask" &> /dev/null; then
    echo "Installing Flask..."
    pip3 install flask
fi

# Change to the tools directory
cd "$(dirname "$0")/../tools"

echo "Starting web interface..."
echo "The application will automatically find an available port"
echo "Press Ctrl+C to stop the server"
echo ""

# Start the Flask application
python3 graph_visualizer.py 