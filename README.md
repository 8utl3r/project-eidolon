# Project Eidolon

**AI platform with emergent behavior through strain-based confidence scoring**

## Overview

Project Eidolon is an advanced AI platform that uses gravitational strain metaphors to model confidence scoring and emergent behavior. The system features a modular agent architecture with throne-based domain authority and comprehensive strain calculation algorithms.

## Technology Stack

- **Language**: Nim 2.2.4
- **Database**: LMDB 0.9.33 (Lightning Memory-Mapped Database)
- **Architecture**: Strain-based confidence scoring with emergent behavior
- **Agents**: Modular AI agents with throne-based domain authority

## Quick Start

### Prerequisites

- macOS (tested on macOS 14.5.0)
- Homebrew
- Nim 2.2.4+
- LMDB 0.9.33+
- **Ollama** (for local LLM agentic reasoning)

### Installation

1. **Install Nim, LMDB, and Ollama**:
   ```bash
   brew install nim lmdb ollama
   ```

2. **Start Ollama server**:
   ```bash
   ollama serve
   # Download and run a model (e.g., Llama 3)
   ollama run llama3
   ```
   Ollama runs a local HTTP API at http://localhost:11434 for agentic LLM queries.

3. **Clone and build**:
   ```bash
   git clone <repository-url>
   cd project-eidolon
   nimble build
   ```

4. **Run tests**:
   ```bash
   nimble test
   ```

5. **Run the application**:
   ```bash
   ./main
   ```

## Project Structure

```
project-eidolon/
├── src/
│   ├── main.nim                 # Main entry point
│   ├── database/                # LMDB database layer
│   ├── agents/                  # AI agent modules
│   │   ├── base/               # Base agent functionality
│   │   ├── mathematician/      # Mathematical operations
│   │   ├── skeptic/            # Logical verification
│   │   ├── stage_manager/      # Context management
│   │   ├── dreamer/            # Creative optimization
│   │   ├── philosopher/        # Abstract reasoning
│   │   ├── investigator/       # Pattern detection
│   │   └── archivist/          # Knowledge management
│   ├── strain/                 # Strain calculation system
│   ├── rag/                    # Retrieval-Augmented Generation
│   ├── api/                    # API layer
│   └── tests/                  # Test modules
├── docs/                       # Documentation
├── tests/                      # Test suite
├── projecteidolon.nimble       # Nimble package configuration
└── README.md                   # This file
```

## Core Concepts

### Strain-Based Confidence Scoring

The system uses gravitational strain metaphors to model confidence:
- **Amplitude**: Strain intensity (0.0-1.0)
- **Resistance**: Strain flow resistance
- **Frequency**: Context indexing frequency
- **Direction**: 3D strain flow vector

### Throne-Based Domain Authority

Agents assert authority through throne nodes:
- Each agent has a throne node in the knowledge graph
- Throne nodes connect to entities under their authority
- Authority can be permanent or triggered
- Enables emergent domain control

### Agent Architecture

- **Foreground Agent**: Primary decision-maker and user interface
- **Background Agents**: Specialized processors activated by context
  - The Engineer: Mathematical operations, systematic processes, and methodologies
  - The Skeptic: Logical verification and anomaly detection
  - The Stage Manager: Context and situational awareness
  - The Dreamer: Creative optimization and problem-solving
  - The Philosopher: Abstract reasoning and conceptual analysis
  - The Investigator: Pattern detection and causal analysis
  - The Archivist: Knowledge management and organization

### Local LLM Integration (Ollama)

- Ollama is used to run local large language models for agentic reasoning.
- Agents send prompts to the Ollama HTTP API (http://localhost:11434) with role-specific instructions.
- See [Ollama API docs](https://github.com/jmorganca/ollama/blob/main/docs/api.md) for details.

## Development

### Building

```bash
nimble build          # Build the project
nimble test           # Run all tests
nimble clean          # Clean build artifacts
```

### Testing

The test suite verifies:
- Environment setup
- Nim version compatibility
- Project structure
- Documentation presence

### Documentation

Comprehensive documentation is available in the `docs/` directory:
- `blueprint.md`: Core concepts and system design
- `technical_architecture.md`: Detailed technical specifications
- `pipeline.md`: Development roadmap and phases
- `environment.md`: Environment setup and configuration
- `standards.md`: Development standards and guidelines

## License

Apache-2.0 License

## Contributing

1. Follow the development standards in `docs/standards.md`
2. Write tests for new features
3. Update documentation as needed
4. Use the strain-based confidence scoring system
5. Follow the throne-based domain authority patterns

## Status

**Current Version**: 0.1.0  
**Status**: Environment setup complete, ready for core implementation  
**Next Phase**: Implement strain calculation system and database layer 