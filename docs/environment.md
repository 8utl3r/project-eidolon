# Environment

## Table of Contents
- [Technology Stack](#technology-stack)
  - [Core Technologies](#core-technologies)
  - [Development Tools](#development-tools)
  - [External Dependencies](#external-dependencies)
- [Development Environment](#development-environment)
  - [System Requirements](#system-requirements)
  - [Installation](#installation)
  - [Configuration](#configuration)
- [Project Structure](#project-structure)
  - [Directory Layout](#directory-layout)
  - [File Organization](#file-organization)
- [Build System](#build-system)
  - [Nimble Configuration](#nimble-configuration)
  - [Build Targets](#build-targets)
  - [Testing Framework](#testing-framework)
- [Database Setup](#database-setup)
  - [LMDB Configuration](#lmdb-configuration)
  - [TinkerPop Integration](#tinkerpop-integration)
- [Agent Framework](#agent-framework)
  - [Agent Architecture](#agent-architecture)
  - [Communication Protocol](#communication-protocol)
- [Strain System](#strain-system)
  - [Strain Calculation Engine](#strain-calculation-engine)
  - [Performance Optimization](#performance-optimization)
- [Security Considerations](#security-considerations)
  - [Data Protection](#data-protection)
  - [Access Controls](#access-controls)
- [Deployment](#deployment)
  - [Production Environment](#production-environment)
  - [Monitoring and Logging](#monitoring-and-logging)

This document describes the complete development environment and technology stack for Project Eidolon.

## Technology Stack {#technology-stack}

### Core Technologies {#core-technologies}
- **Language**: Nim 2.2.4 (latest stable)
- **Database**: LMDB 0.9.33 (Lightning Memory-Mapped Database)
- **Package Manager**: Nimble 0.18.2
- **Build System**: Nim compiler with Nimble
- **Testing**: Nim's unittest framework

### Development Tools {#development-tools}
- **Version Control**: Git
- **IDE**: Any text editor with Nim support (VS Code, Vim, etc.)
- **Graph Visualization**: Apache TinkerPop 3.7.0 (Gremlin Console/Server)
- **Documentation**: Markdown with anchor links
- **Local LLM Runner**: Ollama (for running local large language models and agentic reasoning)

### External Dependencies {#external-dependencies}
- **LMDB**: `lmdb >= 0.1.2`
- **Testing**: `testutils >= 0.8.0`
- **Java**: Required for TinkerPop tools (version 1.8+)
- **Ollama**: Required for local LLM agent reasoning (`brew install ollama`)

## Development Environment {#development-environment}

### System Requirements {#system-requirements}
- **Operating System**: macOS, Linux, or Windows
- **Memory**: 8GB RAM minimum, 16GB recommended
- **Storage**: 10GB free space for development environment
- **Java**: Version 1.8 or higher (for TinkerPop tools)

### Installation {#installation}
1. **Nim Installation**:
   ```bash
   # macOS with Homebrew
   brew install nim
   
   # Linux
   curl https://nim-lang.org/choosenim/init.sh -sSf | sh
   
   # Windows
   # Download from https://nim-lang.org/install_windows.html
   ```

2. **LMDB Installation**:
   ```bash
   # macOS with Homebrew
   brew install lmdb
   
   # Linux
   sudo apt-get install liblmdb-dev
   
   # Windows
   # Use vcpkg or build from source
   ```

3. **Ollama Installation (Local LLMs)**:
   ```bash
   # macOS with Homebrew
   brew install ollama
   # Or download from https://ollama.com/
   # Start the Ollama server (runs on http://localhost:11434)
   ollama serve
   # Download and run a model (e.g., Llama 3)
   ollama run llama3
   ```
   - Ollama provides a local HTTP API for agentic LLM queries.
   - See [Ollama API docs](https://github.com/jmorganca/ollama/blob/main/docs/api.md) for usage.

4. **Project Setup**:
   ```bash
   git clone <repository-url>
   cd project-eidolon
   nimble install
   ```

### Configuration {#configuration}
- **Environment Variables**: None required for basic development
- **Nim Configuration**: Uses default Nim configuration
- **LMDB Configuration**: Automatic configuration via Nimble package

## Project Structure {#project-structure}

### Directory Layout {#directory-layout}
```
project-eidolon/
├── docs/                    # Documentation
│   ├── blueprint.md        # Concept and design decisions
│   ├── pipeline.md         # Development phases and progress
│   ├── standards.md        # Coding standards and best practices
│   ├── environment.md      # This file
│   ├── rules.md           # Project rules and conventions
│   ├── log.md             # Session logs and change tracking
│   ├── checkpoint.md      # Open loops and handoff notes
│   ├── issues.md          # Issue tracking
│   ├── checklists.md      # Development checklists
│   └── technical_architecture.md  # System architecture
├── src/                    # Source code
│   ├── main.nim           # Application entry point
│   ├── types.nim          # Unified type system
│   ├── entities/          # Entity management
│   ├── strain/            # Strain calculation system
│   ├── knowledge_graph/   # Knowledge graph integration
│   ├── agents/            # Agent framework
│   ├── database/          # Database layer
│   ├── api/               # API layer
│   └── rag/               # RAG system
├── tests/                 # Test suite
│   ├── test_all.nim      # Main test runner
│   ├── test_entities.nim # Entity tests
│   └── test_knowledge_graph.nim  # Knowledge graph tests
├── tools/                 # Development tools
│   └── tinkerpop/        # TinkerPop graph tools
├── cursor/                # Cursor-specific files
│   └── insights/         # Development insights
├── projecteidolon.nimble # Nimble package configuration
└── README.md             # Project overview
```

### File Organization {#file-organization}
- **Source Files**: Organized by functionality with clear separation of concerns
- **Test Files**: Mirror source structure with comprehensive coverage
- **Documentation**: Centralized in docs/ with cross-references
- **Configuration**: Nimble-based with minimal external dependencies

## Build System {#build-system}

### Nimble Configuration {#nimble-configuration}
```nim
# Package
version       = "0.1.0"
author        = "Project Eidolon Team"
description   = "AI platform with emergent behavior through strain-based confidence scoring"
license       = "Apache-2.0"
srcDir        = "src"

# Dependencies
requires "nim >= 2.2.4"
requires "lmdb >= 0.1.2"
requires "testutils >= 0.8.0"

# Build targets
bin = @["main"]

# Tasks
task test, "Run all tests":
  exec "nim c -r tests/test_all.nim"

task build, "Build the project":
  exec "nim c -d:release src/main.nim"
```

### Build Targets {#build-targets}
- **Development Build**: `nimble build` (debug mode)
- **Release Build**: `nimble run build` (optimized)
- **Testing**: `nimble test` (run all tests)
- **Clean**: `nimble clean` (remove build artifacts)

### Testing Framework {#testing-framework}
- **Framework**: Nim's built-in unittest
- **Coverage**: Comprehensive unit and integration tests
- **Configuration**: Modular test activation/deactivation
- **Performance**: Configurable test suites for development vs. production

## Database Setup {#database-setup}

### LMDB Configuration {#lmdb-configuration}
- **Storage**: Memory-mapped database for maximum performance
- **Transactions**: ACID-compliant with automatic recovery
- **Scaling**: Single-writer, multiple-reader model
- **Persistence**: Automatic durability with configurable sync options

### TinkerPop Integration {#tinkerpop-integration}
- **Version**: Apache TinkerPop 3.7.0
- **Tools**: Gremlin Console and Server
- **Purpose**: Graph visualization and querying
- **Integration**: Custom strain-based graph scripts

## Agent Framework {#agent-framework}

### Agent Architecture {#agent-architecture}
- **Communication**: Database-only communication protocol
- **Threading**: Multithreaded with strict domain separation
- **Activation**: Trigger-based system with throne node authority
- **Persistence**: All state stored in LMDB

### Communication Protocol {#communication-protocol}
- **Messages**: Structured data with strain-based priorities
- **Synchronization**: Database transactions for consistency
- **Error Handling**: Graceful degradation with logging
- **Performance**: Optimized for high-frequency updates

## Strain System {#strain-system}

### Strain Calculation Engine {#strain-calculation-engine}
- **Algorithm**: Gravitational strain metaphor
- **Components**: Amplitude, resistance, frequency, direction
- **Performance**: Sub-second calculation times
- **Scalability**: Efficient algorithms for large graphs

### Performance Optimization {#performance-optimization}
- **Caching**: Strain value caching for frequently accessed entities
- **Batch Processing**: Efficient bulk strain updates
- **Memory Management**: Optimized data structures
- **Parallelization**: Multi-threaded strain propagation

## Security Considerations {#security-considerations}

### Data Protection {#data-protection}
- **Encryption**: LMDB supports encryption at rest
- **Access Control**: File system permissions for database files
- **Validation**: Input validation at all boundaries
- **Auditing**: Comprehensive logging of all operations

### Access Controls {#access-controls}
- **Agent Isolation**: Strict domain separation
- **Throne Authority**: Centralized authority management
- **Error Handling**: Secure error messages without information disclosure
- **Monitoring**: Real-time security monitoring

## Deployment {#deployment}

### Production Environment {#production-environment}
- **Platform**: Cross-platform (macOS, Linux, Windows)
- **Resource Requirements**: Configurable based on graph size
- **Monitoring**: Built-in performance metrics
- **Backup**: LMDB automatic backup capabilities

### Monitoring and Logging {#monitoring-and-logging}
- **Metrics**: Strain calculation performance, agent activity
- **Logging**: Structured logging with configurable levels
- **Alerts**: Performance threshold monitoring
- **Debugging**: Comprehensive debugging information

---

**Related Documents**: [Blueprint](blueprint.md#core-concepts-under-evaluation) | [Pipeline](pipeline.md#development-phases) | [Standards](standards.md#architecture-standards) | [Technical Architecture](technical_architecture.md#system-overview) 