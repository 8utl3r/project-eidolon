# Apache TinkerPop Integration

**Graph visualization and traversal for Project Eidolon's strain-based knowledge graph**

## Overview

Apache TinkerPop 3.7.0 provides powerful graph visualization and traversal capabilities for our strain-based confidence scoring system. This integration allows us to visualize the knowledge graph, throne-based domain authority, and strain flow patterns.

## Components

### Gremlin Server
- **Location**: `apache-tinkerpop-gremlin-server-3.7.0/`
- **Purpose**: Web-based graph server for visualization
- **Port**: 8182 (http://localhost:8182)
- **Features**: REST API, WebSocket support, graph traversal

### Gremlin Console
- **Location**: `apache-tinkerpop-gremlin-console-3.7.0/`
- **Purpose**: Interactive command-line graph exploration
- **Features**: Real-time traversal, script execution, debugging

### Sample Graph Script
- **File**: `sample-strain-graph.groovy`
- **Purpose**: Demonstrates strain-based graph creation
- **Features**: Throne nodes, entity nodes, strain properties, authority relationships

## Quick Start

### 1. Start Gremlin Console
```bash
./scripts/start-gremlin-console.sh
```

### 2. Load Sample Graph
```bash
# In Gremlin Console
:load tools/tinkerpop/sample-strain-graph.groovy
```

### 3. Start Gremlin Server
```bash
./scripts/start-gremlin-server.sh
```

## Graph Structure

### Node Types

#### Throne Nodes (Agent Domains)
- **Label**: `throne`
- **Properties**:
  - `name`: Throne identifier (e.g., "ThroneOfTheMathematician")
  - `agent`: Agent name (e.g., "The Mathematician")
  - `domain`: Domain type (e.g., "mathematical")
  - `authority_level`: "permanent" or "triggered"

#### Entity Nodes (Knowledge Items)
- **Label**: `entity`
- **Properties**:
  - `name`: Entity name
  - `strain_amplitude`: Strain intensity (0.0-1.0)
  - `strain_resistance`: Strain flow resistance (0.0-1.0)
  - `strain_frequency`: Context indexing frequency

### Edge Types

#### Authority Relationships
- **Label**: `has_authority`
- **Direction**: Throne → Entity
- **Properties**:
  - `authority_strength`: Authority strength (0.0-1.0)
  - `strain_amplitude`: Relationship strain

#### Entity Relationships
- **Label**: `related_to`
- **Direction**: Entity → Entity
- **Properties**:
  - `relationship_type`: Type of relationship
  - `strain_amplitude`: Relationship strain

## Strain Visualization

### Strain Properties
- **Amplitude**: Visualized as node size or color intensity
- **Resistance**: Visualized as node border thickness
- **Frequency**: Visualized as node label size
- **Direction**: Visualized as edge arrows

### Strain Flow Patterns
- High strain → Low strain flow
- Resistance affects flow rate
- Interference patterns from multiple connections

## Gremlin Queries

### Basic Queries
```groovy
// Count all vertices
g.V().count()

// Count all edges
g.E().count()

// Find high strain entities
g.V().hasLabel('entity').has('strain_amplitude', gt(0.8))

// Find throne nodes
g.V().hasLabel('throne')
```

### Strain Analysis Queries
```groovy
// High strain entities
g.V().hasLabel('entity').has('strain_amplitude', gt(0.8)).values('name')

// Low resistance entities
g.V().hasLabel('entity').has('strain_resistance', lt(0.5)).values('name')

// High frequency entities
g.V().hasLabel('entity').has('strain_frequency', gt(5)).values('name')
```

### Authority Queries
```groovy
// Entities under mathematician authority
g.V().hasLabel('throne').has('agent', 'The Mathematician').out('has_authority')

// Authority strength by throne
g.V().hasLabel('throne').outE('has_authority').values('authority_strength')
```

## Integration with Project Eidolon

### Future Integration Points
1. **LMDB Data Export**: Export strain data from LMDB to TinkerPop
2. **Real-time Updates**: Live strain flow visualization
3. **Agent Activity**: Visualize agent activation and domain authority
4. **Strain Interference**: Show interference patterns in real-time

### Visualization Features
- **Throne Visualization**: Agent domain authority areas
- **Strain Flow Animation**: Real-time confidence flow
- **Interference Patterns**: Multi-agent interaction visualization
- **Performance Metrics**: Strain calculation performance

## Troubleshooting

### Path Issues
If you encounter path-related errors, the scripts use a symlink approach:
- Symlink: `/tmp/project-eidolon` → Actual project directory
- This avoids issues with spaces in the Google Drive path

### Java Requirements
- **Version**: Java 1.8.0_451 or higher
- **Path**: Must be in system PATH
- **Memory**: Default JVM settings should be sufficient

### Common Commands
```bash
# Check Java version
java -version

# Test TinkerPop installation
./scripts/start-gremlin-console.sh

# Load sample graph
cat tools/tinkerpop/sample-strain-graph.groovy | ./scripts/start-gremlin-console.sh
```

## License

Apache TinkerPop is licensed under the Apache License 2.0 - completely free for use in Project Eidolon.

## Next Steps

1. **LMDB Integration**: Connect TinkerPop to our LMDB database
2. **Web Interface**: Create web-based visualization
3. **Real-time Updates**: Live strain flow monitoring
4. **Custom Visualizations**: Strain-specific graph layouts 