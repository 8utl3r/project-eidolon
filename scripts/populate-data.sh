#!/bin/bash
# Populate Project Eidolon with real data for testing

echo "Populating Project Eidolon with real data..."
echo "============================================"

# Change to the tools directory
cd "$(dirname "$0")/../tools"

# Run the data population script
python3 populate_real_data.py

echo ""
echo "Data population complete!"
echo "You can now refresh the graph visualizer to see the real data." 