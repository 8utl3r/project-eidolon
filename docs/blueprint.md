# AI Platform Concept Blueprint

## Table of Contents
- [Session: ALPHA BRAVO (Design)](#session-alpha-bravo-design)
- [Core Concepts Under Evaluation](#core-concepts-under-evaluation)
  - [1. Retrieval Augmented Generation (RAG)](#1-retrieval-augmented-generation-rag)
  - [2. Knowledge Graphs](#2-knowledge-graphs)
  - [3. Act Graphs](#3-act-graphs)
  - [4. Vector Graphs & Databases](#4-vector-graphs--databases)
  - [5. Graph Neural Networks (GNNs)](#5-graph-neural-networks-gnns)
  - [6. Modular AI Structure](#6-modular-ai-structure)
  - [7. Advanced Learning Methods](#7-advanced-learning-methods)
  - [8. Trust & Confidence Systems](#8-trust--confidence-systems)
  - [9. Cutting-Edge Concepts](#9-cutting-edge-concepts)
- [Glossary](#glossary)

## Session: ALPHA BRAVO (Design) {#session-alpha-bravo-design}
**Status**: In Progress  
**Goal**: Evaluate AI concepts for platform feasibility and prioritization

## Core Concepts Under Evaluation {#core-concepts-under-evaluation}

### 1. Retrieval Augmented Generation (RAG) {#1-retrieval-augmented-generation-rag}
**Definition**: Technique that enhances AI models by pulling information from external sources  
**Evaluation Status**: APPROVED  
**Priority**: HIGH  
**Decision**: Essential for AI platform - mature technology with proven value

### 2. Knowledge Graphs {#2-knowledge-graphs}
**Definition**: Network representation of entities and relationships  
**Evaluation Status**: APPROVED  
**Priority**: HIGH  
**Decision**: Essential for emergent complexity - core component of RAG + Graph + Act system

### 3. Act Graphs {#3-act-graphs}
**Definition**: Maps actions and events showing who, what, when, where  
**Evaluation Status**: APPROVED  
**Priority**: HIGH  
**Decision**: Core innovation component for emergent complexity - custom development required

### 4. Vector Graphs & Databases {#4-vector-graphs--databases}
**Definition**: Storage and querying based on relationships  
**Selected**: LMDB (Lightning Memory-Mapped Database) + Nim  
**Evaluation Status**: APPROVED  
**Priority**: HIGH  
**Decision**: Custom hybrid knowledge/vector/act graph architecture using LMDB for maximum performance and customization

### 5. Graph Neural Networks (GNNs) {#5-graph-neural-networks-gnns}
**Definition**: ML models operating directly on graph data  
**Evaluation Status**: DEFERRED  
**Priority**: LOW  
**Decision**: Back burner for now - reserved for future "dreaming" subconscious processing

### 6. Modular AI Structure {#6-modular-ai-structure}
**Definition**: Foreground conscious + background unconscious minds  
**Background Agents**: The Engineer, The Skeptic, The Stage Manager, The Dreamer, The Philosopher, The Investigator, The Archivist  
**Evaluation Status**: APPROVED  
**Priority**: HIGH  
**Decision**: Core architecture with 7 specialized background agents using multithreaded, database-only communication

### 10. Local LLM Backend (Ollama)
**Definition**: Ollama is used to run local large language models for agentic reasoning. Agents send prompts to the Ollama HTTP API (http://localhost:11434) with role-specific instructions and receive LLM completions for reasoning and node creation.
**Evaluation Status**: APPROVED
**Priority**: HIGH
**Decision**: Ollama is the default local LLM backend for all agentic reasoning in Project Eidolon.

### 7. Advanced Learning Methods {#7-advanced-learning-methods}
**Components**: Reinforcement Learning, Continual Learning, Backpropagation strategies  
**Evaluation Status**: PARTIAL APPROVE  
**Priority**: MEDIUM  
**Decision**: Start with simple RL and continual learning, defer advanced backpropagation

### 8. Trust & Confidence Systems {#8-trust--confidence-systems}
**Definition**: Confidence values and verified knowledge base  
**Implementation**: Gravitational strain-based system with amplitude representation  
**Evaluation Status**: APPROVED  
**Priority**: HIGH  
**Decision**: Use strain patterns for confidence scoring, enabling emergent behavior and dream sequences

### 9. Cutting-Edge Concepts {#9-cutting-edge-concepts}
**Components**: DNNs, Multimodal AI, Federated Learning, Transfer Learning, Neuromorphic Computing, SNNs  
**Evaluation Status**: DEFERRED  
**Priority**: LOW  
**Decision**: Future research items - focus on core graph system first

## Glossary {#glossary}
- **Normal/Visual/Insert**: Vim modal editing components
- **Navigate/Edit/Select**: Modal editing components
- **Nodes**: Knowledge entities in the graph
- **Edges**: Actions and relationships between nodes
- **Strands**: Modifiers that quantify strain between nodes
- **Strain**: Gravitational strain analogy for confidence scoring
- **Agents**: Specialized AI components with multithreaded, database-only communication
- **Foreground Agent**: Primary decision-maker with database synthesis
- **Background Agents**: Independent agents working in separate threads
- **System States**: wake, dream, sleep
- **Domains**: Defined by throne nodes with graph connections (e.g., ThroneOfTheMathematician)
- **Ollama**: Local LLM backend for agentic reasoning. Agents interact with Ollama via HTTP API for prompt-based reasoning and node creation.
- **Engineer**: Background agent responsible for mathematical operations, systematic processes, and methodologies (formerly 'Mathematician').

---

**Related Documents**: [Pipeline](pipeline.md#development-phases) | [Standards](standards.md#architecture-standards) | [Technical Architecture](technical_architecture.md#system-overview) 