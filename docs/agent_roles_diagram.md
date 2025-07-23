# Agent Roles & System Architecture Diagram

## 🎭 **Agent Role Hierarchy & Permissions**

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           PROJECT EIDOLON AGENT SYSTEM                     │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                              FOREGROUND AGENT                              │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    USER INTERFACE LAYER                            │   │
│  │                                                                     │   │
│  │  • Direct user interaction                                         │   │
│  │  • Query processing                                               │   │
│  │  • Response synthesis                                             │   │
│  │  • Knowledge graph visualization                                  │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                              BACKGROUND AGENTS                             │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    STAGE MANAGER (COORDINATOR)                    │   │
│  │                                                                     │   │
│  │  🎯 ROLE: System coordination & workflow management               │   │
│  │  🔑 PERMISSIONS: Full (Verify, Suggest, Draft, None)             │   │
│  │  🧠 DOMAIN: Agent registration, task distribution, coordination   │   │
│  │  🔗 RELATIONSHIPS: Manages all other agents                      │   │
│  │  📊 STATUS: ACTIVE                                                │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                       │
│                                    ▼                                       │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    THOUGHT PERMISSION HIERARCHY                   │   │
│  │                                                                     │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐ │   │
│  │  │    FULL     │  │  SUGGEST    │  │   DRAFT     │  │    NONE     │ │   │
│  │  │             │  │             │  │             │  │             │ │   │
│  │  │ • Verify    │  │ • Suggest   │  │ • Create    │  │ • Read      │ │   │
│  │  │ • Suggest   │  │ • Draft     │  │ • Read      │  │ • Observe   │ │   │
│  │  │ • Draft     │  │ • Read      │  │ • Observe   │  │             │ │   │
│  │  │ • Read      │  │ • Observe   │  │             │  │             │ │   │
│  │  │ • Observe   │  │             │  │             │  │             │ │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘ │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                       │
│                                    ▼                                       │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    SPECIALIZED AGENTS                             │   │
│  │                                                                     │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐ │   │
│  │  │  ENGINEER   │  │PHILOSOPHER  │  │   SKEPTIC   │  │   DREAMER   │ │   │
│  │  │             │  │             │  │             │  │             │ │   │
│  │  │ 🎯 Pattern  │  │ 🎯 Wisdom   │  │ 🎯 Logic    │  │ 🎯 Creative │ │   │
│  │  │   Analysis  │  │  & Insight  │  │ Validation  │  │  Generation │ │   │
│  │  │             │  │             │  │             │  │             │ │   │
│  │  │ 🔑 Suggest  │  │ 🔑 Suggest  │  │ 🔑 Suggest  │  │ 🔑 Draft    │ │   │
│  │  │ 📊 ACTIVE   │  │ 📊 ACTIVE   │  │ 📊 ACTIVE   │  │ 📊 ACTIVE   │ │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘ │   │
│  │                                                                     │   │
│  │  ┌─────────────┐  ┌─────────────┐                                  │   │
│  │  │INVESTIGATOR │  │  ARCHIVIST  │                                  │   │
│  │  │             │  │             │                                  │   │
│  │  │ 🎯 Evidence │  │ 🎯 Knowledge│                                  │   │
│  │  │  Collection │  │ Organization│                                  │   │
│  │  │             │  │             │                                  │   │
│  │  │ 🔑 Full     │  │ 🔑 Full     │                                  │   │
│  │  │ 📊 ACTIVE   │  │ 📊 ACTIVE   │                                  │   │
│  │  └─────────────┘  └─────────────┘                                  │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                              INFRASTRUCTURE LAYER                          │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    AGENT ORCHESTRATOR                               │   │
│  │                                                                     │   │
│  │  • Agent lifecycle management                                      │   │
│  │  • Task distribution & load balancing                              │   │
│  │  • Permission enforcement                                          │   │
│  │  • Inter-agent communication                                       │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                       │
│                                    ▼                                       │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    API MANAGER                                     │   │
│  │                                                                     │   │
│  │  • LLM interface management                                        │   │
│  │  • Model allocation (llama3.2:3b)                                 │   │
│  │  • Request queuing & load balancing                                │   │
│  │  • Concurrent request handling (0/10 per API)                      │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                       │
│                                    ▼                                       │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    KNOWLEDGE GRAPH                                 │   │
│  │                                                                     │   │
│  │  • Entity management (10,033 words)                                │   │
│  │  • Thought management (10,100 verified thoughts)                   │   │
│  │  • Relationship tracking (544 verified connections)                │   │
│  │  • Strain system (cognitive dissonance & confidence)               │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                              EXTERNAL INTERFACES                           │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    OLLAMA INTEGRATION                              │   │
│  │                                                                     │   │
│  │  • Local LLM runtime (llama3.2:3b)                                 │   │
│  │  • HTTP API communication                                          │   │
│  │  • Role-based prompting                                            │   │
│  │  • Single LLM, multiple agent roles                                │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                       │
│                                    ▼                                       │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    CANVAS VISUALIZATION                            │   │
│  │                                                                     │   │
│  │  • 2D node visualization (10,033 nodes)                            │   │
│  │  • Physics simulation (attraction/repulsion)                       │   │
│  │  • Verified thought constellations (544 connections)               │   │
│  │  • Real-time interaction & exploration                             │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 🔄 **Agent Communication Flow**

```
USER QUERY
    │
    ▼
┌─────────────────┐
│  FOREGROUND     │ ← Direct user interaction
│  AGENT          │
└─────────────────┘
    │
    ▼
┌─────────────────┐
│  STAGE MANAGER  │ ← Coordinates response
│  (COORDINATOR)  │
└─────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────┐
│                SPECIALIZED AGENTS                      │
│                                                         │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐   │
│  │ENGINEER │  │PHILOSOPH│  │ SKEPTIC │  │ DREAMER │   │
│  │         │  │   ER    │  │         │  │         │   │
│  └─────────┘  └─────────┘  └─────────┘  └─────────┘   │
│                                                         │
│  ┌─────────┐  ┌─────────┐                              │
│  │INVESTIG │  │ARCHIVIST│                              │
│  │  ATOR   │  │         │                              │
│  └─────────┘  └─────────┘                              │
└─────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────┐
│  KNOWLEDGE      │ ← Data storage & retrieval
│  GRAPH          │
└─────────────────┘
    │
    ▼
┌─────────────────┐
│  OLLAMA LLM     │ ← AI reasoning
│  (llama3.2:3b)  │
└─────────────────┘
    │
    ▼
┌─────────────────┐
│  RESPONSE       │ ← Synthesized answer
│  SYNTHESIS      │
└─────────────────┘
    │
    ▼
USER RESPONSE
```

## 🎯 **Agent Specializations & Domains**

### **Stage Manager (Coordinator)**
- **Domain**: System coordination, workflow management, agent registration
- **Capabilities**: Full thought permissions, agent lifecycle management
- **Relationships**: Manages all other agents, coordinates responses

### **Engineer**
- **Domain**: Pattern analysis, model optimization, strain prediction
- **Capabilities**: Suggest thoughts, technical analysis, system optimization
- **Relationships**: Reports to Stage Manager, collaborates with other agents

### **Philosopher**
- **Domain**: Wisdom accumulation, ontological analysis, insight generation
- **Capabilities**: Suggest thoughts, philosophical reasoning, wisdom synthesis
- **Relationships**: Reports to Stage Manager, provides philosophical perspective

### **Skeptic**
- **Domain**: Logical validation, contradiction detection, suspicion assessment
- **Capabilities**: Suggest thoughts, logical analysis, error detection
- **Relationships**: Reports to Stage Manager, validates other agents' outputs

### **Dreamer**
- **Domain**: Creative generation, imaginative exploration, novel connections
- **Capabilities**: Draft thoughts, creative synthesis, pattern discovery
- **Relationships**: Reports to Stage Manager, provides creative insights

### **Investigator**
- **Domain**: Evidence collection, pattern detection, hypothesis generation
- **Capabilities**: Full permissions, investigative analysis, case building
- **Relationships**: Reports to Stage Manager, conducts deep investigations

### **Archivist**
- **Domain**: Knowledge organization, retrieval optimization, memory management
- **Capabilities**: Full permissions, knowledge structuring, information indexing
- **Relationships**: Reports to Stage Manager, manages knowledge organization

## 🔧 **Technical Architecture**

### **Permission System**
- **Full**: Verify, suggest, draft, read, observe
- **Suggest**: Suggest, draft, read, observe
- **Draft**: Draft, read, observe
- **None**: Read, observe

### **API Management**
- **5 APIs**: One per agent type (excluding Investigator/Archivist)
- **Model**: llama3.2:3b (shared)
- **Concurrency**: 0/10 requests per API
- **Load Balancing**: Round-robin distribution

### **Knowledge Graph**
- **Entities**: 10,033 word nodes
- **Thoughts**: 10,100 verified thoughts
- **Connections**: 544 verified connections
- **Strain System**: Cognitive dissonance & confidence tracking

### **Visualization**
- **Canvas**: 2D physics-based visualization
- **Nodes**: 10,033 word entities
- **Connections**: 544 verified thought constellations
- **Physics**: Attraction/repulsion based on strain relationships

## 🎯 **System Status: FULLY OPERATIONAL**

- ✅ **All 7 agents online**
- ✅ **Permission system working**
- ✅ **API management functional**
- ✅ **Knowledge graph populated**
- ✅ **Ollama integration active**
- ✅ **Canvas visualization running**
- ✅ **Resource consumption optimized** 