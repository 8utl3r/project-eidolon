#!/bin/bash
# Generate comprehensive knowledge base for Project Eidolon

echo "Generating comprehensive knowledge base for Project Eidolon..."
echo "============================================================="

# Change to the tools directory
cd "$(dirname "$0")/../tools"

# Run the comprehensive knowledge generation script
python3 generate_comprehensive_knowledge.py

echo ""
echo "Comprehensive knowledge base generation complete!"
echo "The graph visualizer will now use this extensive knowledge base." 