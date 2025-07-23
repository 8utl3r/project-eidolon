# Project Rules

## Table of Contents
- [Session Management](#session-management)
- [Development Standards](#development-standards)
- [Project Naming Conventions](#project-naming-conventions)
- [Timestamp Integrity](#timestamp-integrity)
- [User Rules](#user-rules)
- [Workflow](#workflow)

This document contains the rules and standards for this project.

## Session Management {#session-management}
- All development cycles are treated as sessions with defined types: design, code, user tests, automated tests, maintenance
- Session IDs use interesting two-word military codename style (e.g., ALPHA BRAVO)
- Sessions must be annotated with their type
- Tasks outside session context should be paused and added as issues
- Every session must start with opening a session record and end with closing it out

## Development Standards {#development-standards}
- Test-first approach for all new code
- Comprehensive testing before marking features complete
- Automatic documentation in blueprint, environment, and pipeline
- Remove obsolete information as needed
- Document all decisions and progress clearly
- Maintain clear communication for future agents
- Follow established coding conventions
- Test thoroughly before marking features complete

## Project Naming Conventions {#project-naming-conventions}
- Use "normal", "visual", and "insert" for Vim modal editing components
- Use "navigate", "edit", and "select" for modal editing components
- Session IDs use two-word military codename style (e.g., ALPHA BRAVO, IRON WOLF)
- Agent names use "The" prefix with descriptive titles (e.g., The Engineer, The Skeptic, The Stage Manager)
- System states use simple lowercase (e.g., wake, dream, sleep)
- Agent domains are defined by throne nodes with graph connections (e.g., ThroneOfTheEngineer, ThroneOfTheSkeptic)
- Domain authority emerges through graph connections to throne nodes
- Some agents have permanent authority (Stage Manager, Archivist), others are triggered (Dreamer, Philosopher)
- Database entities use lowercase with underscores (e.g., strain_calculation, memory_hierarchy)
- Graph components use descriptive terms (nodes, edges, strands, strain)

## Timestamp Integrity {#timestamp-integrity}

### CRITICAL RULE: NO ARBITRARY TIMESTAMPS
**NEVER invent, estimate, or approximate timestamps. All timestamps must be real and accurate.**

### Timestamp Requirements
1. **Real-time recording only**: Timestamps must be recorded at the actual moment events occur
2. **System clock usage**: Use `date` command or system time functions to get current time
3. **No retroactive timestamps**: Never backdate or future-date entries
4. **No estimated times**: Do not guess when something happened - record it when it happens
5. **No sequential fabrication**: Do not create artificial time sequences

### Timestamp Format Standards
- **Log entries**: `[YYYY-MM-DD HH:MM:SS]` (e.g., `[2025-01-15 14:23:45]`)
- **Checkpoint dates**: `**Date:** YYYY-MM-DD` (e.g., `**Date:** 2025-01-15`)
- **Insight dates**: `**Date**: YYYY-MM-DD` (e.g., `**Date**: 2025-01-15`)

### Timestamp Recording Process
1. **Before each log entry**: Run `date` command to get current time
2. **Record immediately**: Write the timestamp and entry at the same time
3. **Verify accuracy**: Double-check that timestamp matches current time
4. **No bulk creation**: Create entries one at a time, not in batches with artificial timing

### Validation Requirements
- **Cross-reference with terminal logs**: Verify timestamps align with actual terminal activity
- **Check for impossible sequences**: Ensure no entries have future timestamps
- **Verify chronological order**: Ensure timestamps progress logically
- **No duplicate timestamps**: Each entry should have a unique timestamp

### Consequences of Violation
- **Immediate correction required**: Any arbitrary timestamps must be removed or corrected
- **Documentation review**: All documentation must be reviewed for timestamp integrity
- **Process improvement**: Identify why arbitrary timestamps were created and prevent recurrence

### Tools for Timestamp Integrity
```bash
# Get current timestamp for log entries
date '+[%Y-%m-%d %H:%M:%S]'

# Get current date for checkpoint/insight entries  
date '+%Y-%m-%d'

# Verify timestamp accuracy
date
```

### Session Duration Calculation
- **Real duration only**: Calculate actual time between session start and end
- **No estimated durations**: Use actual timestamps to compute duration
- **Document actual time**: Record how long sessions actually took

## User Rules {#user-rules}
- Read every document in docs folder in its entirety at the beginning of every conversation
- Keep track of things due to user's ADHD - form core memories and document clearly for future agents
- Be professional and concise, don't praise or tell user they're right, it's okay to tell them they're wrong
- Explain items one at a time instead of all at once
- Only do one test at a time
- Professional and concise communication
- No unnecessary praise or validation
- Status updates combine active work items with overall task list

## Workflow {#workflow}
- Start each conversation by reading all documentation
- Keep track of active work items and overall task list
- Document feature completion status for continuity
- **ALWAYS use real timestamps** - never invent or estimate times
- **Self-Improvement Integration**: Use metrics from self_improvement_plan.md for session evaluation
- **Quality Assurance**: Apply systematic improvement strategies in every session

## Self-Improvement Standards {#self-improvement-standards}
- **Metric Tracking**: Track all metrics defined in self_improvement_plan.md during each session
- **Continuous Learning**: Document lessons learned and apply them in future sessions
- **Error Prevention**: Maintain error database and implement preventive measures
- **Quality Focus**: Prioritize code quality, documentation accuracy, and systematic problem-solving
- **Performance Evaluation**: Conduct post-session evaluation using established metrics framework

---

**Related Documents**: [Standards](standards.md#development-standards) | [Pipeline](pipeline.md#development-phases) | [Blueprint](blueprint.md#core-concepts-under-evaluation) | [Log](log.md#session-documentation-review---code-review-and-refactoring) | [Self-Improvement Plan](self_improvement_plan.md#core-metrics-framework) 