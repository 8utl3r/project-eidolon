#!/bin/bash

# Run Canvas Server
# This script compiles and runs the canvas server for the full-page interface

echo "Project Eidolon - Canvas Server"
echo "==============================="

# Check if Nim is installed
if ! command -v nim &> /dev/null; then
    echo "Error: Nim is not installed or not in PATH"
    exit 1
fi

# Compile and run the canvas server
echo "Compiling canvas server..."
nim c -r src/canvas_server.nim

echo "Canvas server stopped." 