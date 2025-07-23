# Standards

## Table of Contents
- [Development Standards](#development-standards)
  - [Test-First Development](#test-first-development)
  - [Code Quality](#code-quality)
  - [Documentation Standards](#documentation-standards)
- [Architecture Standards](#architecture-standards)
  - [Database Design](#database-design)
  - [Agent Design](#agent-design)
  - [Strain System Standards](#strain-system-standards)
- [Communication Standards](#communication-standards)
  - [Session Management](#session-management)
  - [Documentation Updates](#documentation-updates)
- [Naming Conventions](#naming-conventions)
  - [Code Naming](#code-naming)
  - [File and Directory Naming](#file-and-directory-naming)
- [Performance Standards](#performance-standards)
  - [Strain Calculations](#strain-calculations)
  - [Agent Performance](#agent-performance)
  - [Database Performance](#database-performance)
- [Testing Standards](#testing-standards)
  - [Unit Testing](#unit-testing)
  - [Integration Testing](#integration-testing)
  - [Performance Testing](#performance-testing)
  - [Emergent Behavior Testing](#emergent-behavior-testing)
- [Security Standards](#security-standards)
  - [Data Security](#data-security)
  - [Agent Security](#agent-security)
- [Quality Assurance](#quality-assurance)
  - [Code Review Standards](#code-review-standards)
  - [Documentation Review](#documentation-review)
  - [Performance Review](#performance-review)
- [Project Eidolon Coding Standards](#project-eidolon-coding-standards)
  - [Core Principles](#core-principles)
  - [Implementation Guidelines](#implementation-guidelines)
  - [Performance Considerations](#performance-considerations)
  - [Documentation Requirements](#documentation-requirements)
  - [Error Handling](#error-handling)

This document contains the standards and best practices for this project.

## Development Standards {#development-standards}
**Source**: Development standards from rules.md and Session IRON WOLF

### Test-First Development {#test-first-development}
- All new code must have tests written before implementation
- Tests must validate both functionality and emergent behavior
- Strain calculation tests must verify gravitational flow patterns
- Agent behavior tests must validate domain separation

### Code Quality {#code-quality}
- Follow Nim coding conventions and best practices
- Use descriptive variable and function names
- Implement comprehensive error handling
- Document complex algorithms and strain calculations
- Maintain consistent code formatting

### Documentation Standards {#documentation-standards}
- Update blueprint.md when design decisions change
- Document all agent interactions and domain boundaries
- Maintain environment.md with current dependencies
- Update pipeline.md with progress and blockers
- Log all significant changes in log.md

## Architecture Standards {#architecture-standards}
**Source**: Technical architecture from Session BRAVO CHARLIE

### Database Design {#database-design}
- Use LMDB for all persistent storage
- Implement consistent schema across knowledge, act, and vector graphs
- Maintain strain-based confidence scoring on all entities
- Ensure atomic operations for data integrity

### Agent Design {#agent-design}
- All agents communicate exclusively via database read/writes
- Maintain strict domain separation between agents
- Implement trigger-based activation system
- Use throne nodes for domain authority definition

### Strain System Standards {#strain-system-standards}
- Implement gravitational strain metaphor consistently
- Use amplitude, resistance, and frequency for strain calculations
- Ensure strain flows from high to low confidence nodes
- Maintain strain interference patterns for emergent behavior

## Communication Standards {#communication-standards}
**Source**: User rules and workflow from rules.md

### Session Management {#session-management}
- Use two-word military codename session IDs
- Annotate all sessions with their type (design, code, test, maintenance)
- Start and end every session with proper logging
- Pause tasks outside session context and add to issues

### Documentation Updates {#documentation-updates}
- Read all docs folder contents at conversation start
- Update relevant documentation after significant changes
- Maintain clear communication for future agents
- Document feature completion status for continuity

## Naming Conventions {#naming-conventions}
**Source**: Project naming conventions from rules.md

### Code Naming {#code-naming}
- Use "normal", "visual", and "insert" for Vim modal editing components
- Use "navigate", "edit", and "select" for modal editing components
- Session IDs use two-word military codename style (e.g., ALPHA BRAVO, IRON WOLF)
- Agent names use "The" prefix with descriptive titles (e.g., The Mathematician, The Skeptic, The Stage Manager)
- System states use simple lowercase (e.g., wake, dream, sleep)
- Agent domains are defined by throne nodes with graph connections (e.g., ThroneOfTheMathematician, ThroneOfTheSkeptic)
- Database entities use lowercase with underscores (e.g., strain_calculation, memory_hierarchy)
- Graph components use descriptive terms (nodes, edges, strands, strain)

### File and Directory Naming {#file-and-directory-naming}
- Use lowercase with underscores for source files
- Use descriptive names that indicate purpose
- Maintain consistent directory structure
- Follow Nim module naming conventions

## Performance Standards {#performance-standards}
**Source**: Performance targets from Session IRON WOLF

### Strain Calculations {#strain-calculations}
- Sub-second strain calculation performance
- Efficient memory hierarchy usage
- Optimized gravitational flow algorithms
- Scalable strain interference patterns

### Agent Performance {#agent-performance}
- Responsive agent activation and deactivation
- Efficient database communication
- Minimal memory footprint per agent
- Fast domain authority resolution

### Database Performance {#database-performance}
- Optimized LMDB query patterns
- Efficient graph traversal algorithms
- Fast vector similarity calculations
- Scalable knowledge graph operations

## Testing Standards {#testing-standards}
**Source**: Testing strategy from Session IRON WOLF

### Unit Testing {#unit-testing}
- Test strain behavior patterns, not just calculations
- Validate agent domain separation
- Test database schema integrity
- Verify memory hierarchy functionality

### Integration Testing {#integration-testing}
- Test agent communication via database
- Validate agent independence
- Test Stage Manager coordination
- Verify dream cycle integration

### Performance Testing {#performance-testing}
- Benchmark strain calculation efficiency
- Test memory hierarchy performance
- Validate agent activation timing
- Measure database query optimization

### Emergent Behavior Testing {#emergent-behavior-testing}
- Validate multi-agent interaction patterns
- Test strain-based confidence emergence
- Verify creative problem-solving capabilities
- Test knowledge synthesis functionality

## Security Standards {#security-standards}
**Source**: Security considerations from environment.md

### Data Security {#data-security}
- Implement proper LMDB access controls
- Secure agent communication protocols
- Protect knowledge graph data integrity
- Secure external API connections

### Agent Security {#agent-security}
- Maintain strict domain separation
- Validate all agent inputs and outputs
- Implement proper error handling
- Secure throne node access controls

## Quality Assurance {#quality-assurance}
**Source**: Success criteria from Session IRON WOLF

### Code Review Standards {#code-review-standards}
- Review all code changes before integration
- Validate against established patterns
- Ensure proper error handling
- Verify test coverage

### Documentation Review {#documentation-review}
- Review documentation updates for accuracy
- Ensure consistency across all documents
- Validate source references
- Check for completeness and clarity

### Performance Review {#performance-review}
- Monitor strain calculation performance
- Track memory usage patterns
- Validate agent efficiency metrics
- Review database operation performance

# Project Eidolon Coding Standards {#project-eidolon-coding-standards}

## Core Principles {#core-principles}

### 1. Simplicity First {#1-simplicity-first}
- Write the simplest code that accomplishes the task
- Prefer pure functions over complex object methods
- Separate data from computation
- Use minimal types with only essential fields

### 2. Modularity {#2-modularity}
- Each module should have a single, clear responsibility
- Functions should be small and focused
- Minimize dependencies between modules
- Use dependency injection where possible

### 3. Test-First Development {#3-test-first-development}
- Write tests before implementing features
- Tests must be modular and configurable
- Include test activation/deactivation flags for performance
- Each module should have its own test suite

### 4. Pure Functions Preferred {#4-pure-functions-preferred}
- Write pure math functions that take simple parameters
- Avoid complex object dependencies in core calculations
- Create wrapper functions to handle complex types
- Example: `calculateAmplitude(frequency: int, decay_rate: float)` instead of `calculateAmplitude(entity: Entity)`

### 5. Well-Commented Code {#5-well-commented-code}
- Comment every function with clear purpose and parameters
- Explain complex algorithms step by step
- Document assumptions and limitations
- Include usage examples in comments

## Implementation Guidelines {#implementation-guidelines}

### Type Design {#type-design}
```nim
# Good: Simple, focused types
type
  Vector3* = object
    x*, y*, z*: float

  StrainData* = object
    amplitude*: float
    resistance*: float
    frequency*: int

# Avoid: Overly complex types with too many responsibilities
```

### Function Design {#function-design}
```nim
# Good: Pure function with simple parameters
proc calculateAmplitude*(access_count: int, decay_rate: float, time_elapsed: float): float =
  ## Calculate strain amplitude using decay formula
  ## 
  ## Parameters:
  ## - access_count: Number of times entity was accessed
  ## - decay_rate: Rate of amplitude decay (0.0-1.0)
  ## - time_elapsed: Time since last access in seconds
  ##
  ## Returns: Amplitude value between 0.0 and 1.0
  let decay_factor = pow(decay_rate, time_elapsed)
  let raw_amplitude = float(access_count) * 1.1  # access_factor
  return clamp(raw_amplitude / decay_factor, 0.0, 1.0)

# Good: Wrapper function for complex types
proc updateAmplitude*(entity: var Entity): void =
  ## Update entity amplitude using pure calculation function
  let time_since = now() - entity.strain.last_accessed
  entity.strain.amplitude = calculateAmplitude(
    entity.strain.access_count,
    0.95,  # decay_rate
    time_since.inSeconds.float
  )
```

### Test Design {#test-design}
```nim
# Configurable test activation
const RUN_STRAIN_TESTS* = true  # Set to false for performance

when RUN_STRAIN_TESTS:
  suite "Strain Calculator Tests":
    test "Amplitude Calculation":
      ## Test pure amplitude calculation function
      let result = calculateAmplitude(10, 0.95, 1.0)
      check result > 0.0
      check result <= 1.0
```

## Performance Considerations {#performance-considerations}

### Test Configuration {#test-configuration}
- Use compile-time constants to enable/disable test suites
- Separate unit tests from integration tests
- Allow selective test execution for debugging

### Code Optimization {#code-optimization}
- Profile before optimizing
- Use pure functions for better compiler optimization
- Minimize object creation in hot paths
- Consider using value types over reference types where appropriate

## Documentation Requirements {#documentation-requirements}

### Code Comments {#code-comments}
- Every exported function must have a doc comment
- Include parameter descriptions and return value explanation
- Document any side effects or assumptions
- Provide usage examples for complex functions

### Module Documentation {#module-documentation}
- Each module should have a header comment explaining its purpose
- Document dependencies and usage patterns
- Include performance characteristics where relevant

## Error Handling {#error-handling}

### Graceful Degradation {#graceful-degradation}
- Functions should handle edge cases gracefully
- Use default values for missing parameters
- Log errors but don't crash the system
- Provide meaningful error messages

### Validation {#validation}
- Validate inputs at module boundaries
- Use assertions for internal consistency checks
- Provide clear error messages for invalid inputs

---

**Related Documents**: [Blueprint](blueprint.md#core-concepts-under-evaluation) | [Pipeline](pipeline.md#development-phases) | [Environment](environment.md#technology-stack) | [Rules](rules.md#development-standards) 