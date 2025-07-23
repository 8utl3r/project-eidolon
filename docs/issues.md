# Issues

This document tracks detailed issues with context for understanding and resolution.

## Current Issues

### Issue 1: Technology Stack Inconsistency
**Source**: Technical architecture review
**Status**: Resolved
**Priority**: High
**Resolution**: Session RAVEN STORM

**Description**: The technical_architecture.md file references ArangoDB as the database layer, but the blueprint.md and our discussions specify LMDB + Nim as the chosen technology stack.

**Context**: 
- Session ALPHA BRAVO decided on LMDB + Nim for performance and customization
- Technical architecture document still showed ArangoDB schema examples
- This created a fundamental inconsistency in the database design

**Impact**: 
- Database schema design was based on wrong technology
- Implementation roadmap assumed LMDB but architecture showed ArangoDB
- Could have led to significant rework if not resolved

**Resolution**: 
- Updated technical_architecture.md to use LMDB schema design
- Replaced ArangoDB JSON collections with Nim type definitions
- Aligned database schema with LMDB capabilities and strain system
- Updated system states to use simple lowercase naming convention

### Issue 2: System State Naming Convention Conflict
**Source**: Naming convention updates
**Status**: Resolved
**Priority**: Medium
**Resolution**: Session RAVEN STORM

**Description**: Technical architecture and other documents used SCREAMING_SNAKE_CASE for system states (WAKE_CYCLE, DREAM_CYCLE, DEEP_SLEEP_CYCLE), but the updated naming conventions specify simple lowercase (wake, dream, sleep).

**Context**:
- User preference for simple lowercase naming
- Technical architecture document was using old naming convention
- Needed to update all references for consistency

**Impact**:
- Inconsistent naming across documentation
- Potential confusion during implementation
- Code examples could use wrong naming convention

**Resolution**:
- Updated technical_architecture.md system state references to simple lowercase
- Updated SystemState enum to use wake, dream, sleep
- Updated AgentDomain enum to use simple lowercase naming
- Updated experimentation parameters to use consistent naming
- All documents now use consistent simple lowercase naming convention

### Issue 3: Domain Authority System Implementation
**Source**: Throne-based domain discussion
**Status**: Resolved
**Priority**: High
**Resolution**: Session RAVEN STORM

**Description**: The throne-based domain authority system was defined in rules.md but not fully integrated into the technical architecture or implementation plans.

**Context**:
- New throne-based system replaces rigid domain categories
- Technical architecture was referencing old domain system
- Implementation roadmap didn't include throne node development

**Impact**:
- Architecture didn't reflect new domain authority approach
- Implementation plan was missing key component
- Agent domain separation may not have worked as intended

**Resolution**:
- Added throne-based domain storage to database schema
- Created ThroneNode and DomainAuthority type definitions
- Added throne information to all agent specifications
- Integrated domain authority mechanism with emergent behavior
- Added domain authority operations for dynamic authority management

### Issue 4: Agent Communication Protocol Details
**Source**: Agent architecture review
**Status**: Resolved
**Priority**: Medium
**Resolution**: Session RAVEN STORM

**Description**: While we specify "database-only communication" for agents, the technical details of this protocol were not fully defined.

**Context**:
- Agents communicate via database read/writes
- Needed specific protocol for agent coordination
- Stage Manager attention system needed detailed specification

**Impact**:
- Implementation could have been unclear
- Agent coordination could have been inefficient
- Potential for communication bottlenecks

**Resolution**:
- Defined specific database communication patterns with AgentMessage types
- Specified Stage Manager attention system with AttentionRequest/Response
- Documented agent trigger/activation protocols with AgentTrigger system
- Added multithreaded agent coordination with thread safety
- Integrated strain-based communication priorities

### Issue 5: Strain Calculation Implementation Details
**Source**: Strain system review
**Status**: Resolved
**Priority**: High
**Resolution**: Session RAVEN STORM

**Description**: While we have the gravitational strain metaphor defined, the specific mathematical implementation details were not fully specified.

**Context**:
- Strain flows from high to low confidence
- Uses amplitude, resistance, frequency concepts
- Needed specific formulas and algorithms

**Impact**:
- Implementation could have been inconsistent
- Performance targets may not have been achievable
- Testing strategy needed specific test cases

**Resolution**:
- Defined specific strain calculation formulas for amplitude, resistance, frequency, and direction
- Specified strain flow algorithms between nodes with resistance calculations
- Created strain interference patterns for emergent behavior
- Added strain system integration with global parameters and performance optimization
- Implemented strain-based decision making and prediction capabilities

## Resolved Issues

### Issue 6: Documentation Structure Setup
**Source**: Session SHADOW FOX
**Status**: Resolved
**Resolution**: Successfully copied all template files and created comprehensive documentation suite

### Issue 7: Rules File Consolidation
**Source**: Rules file management
**Status**: Resolved
**Resolution**: Successfully combined root and docs rules files, removed duplicates

### Issue 8: Blueprint File Consolidation
**Source**: Blueprint file management
**Status**: Resolved
**Resolution**: Successfully transplanted concept_blueprint.md content into blueprint.md and deleted duplicate

## Future Considerations

### Issue 9: RAG System Integration Details
**Source**: RAG system planning
**Status**: Future
**Priority**: Medium

**Description**: While RAG is approved as essential, the specific external knowledge sources and embedding models are not yet specified.

**Context**:
- RAG integration planned for Phase 3
- Need to specify external knowledge sources
- Embedding model selection needed

**Impact**:
- Implementation planning incomplete
- Performance requirements unclear
- Integration testing strategy needs refinement

### Issue 10: Performance Benchmarking Strategy
**Source**: Performance standards review
**Status**: Future
**Priority**: Medium

**Description**: Performance targets are defined but specific benchmarking methodology is not detailed.

**Context**:
- Sub-second strain calculations target set
- Need specific benchmarking approach
- Performance monitoring tools not specified

**Impact**:
- Success criteria may be unclear
- Performance optimization approach undefined
- Testing strategy needs performance benchmarks 