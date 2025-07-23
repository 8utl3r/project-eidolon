# Agent API Manager
#
# Manages LLM API connections and role-based prompting for agents.
# Supports flexible allocation from single-model to multi-model setups.

import std/[tables, json, asyncdispatch, options, strutils]
import ../types

type
  ThoughtPermission* = enum
    None,           # Cannot create or modify thoughts
    Draft,          # Can create draft thoughts only
    Suggest,        # Can suggest thoughts to Stage Manager
    Verify,         # Can verify thoughts (Stage Manager only)
    Full            # Full thought creation and verification (Stage Manager only)

  AgentAPI* = ref object
    ## API configuration for an agent
    api_id*: string
    model_name*: string
    base_url*: string
    api_key*: string
    role_prompt*: string
    is_available*: bool
    max_concurrent*: int
    current_requests*: int
    thought_permission*: ThoughtPermission  # New field for thought permissions

  LoadBalancer* = ref object
    ## Simple load balancer for API distribution
    round_robin_index*: int
    api_weights*: Table[string, float]  # api_id -> weight

  AgentAPIManager* = ref object
    ## Manages all agent API connections
    apis*: Table[string, AgentAPI]  # api_id -> API
    agent_assignments*: Table[string, string]  # agent_id -> api_id
    default_api*: AgentAPI
    load_balancer*: LoadBalancer

# Role prompts for different agent types
const
  ENGINEER_ROLE_PROMPT* = """
You are an Engineer agent specializing in:
- Mathematical calculations and analysis
- Pattern recognition and optimization
- Model performance evaluation
- Technical problem-solving
- Data structure optimization

Always respond with precise, analytical thinking and provide step-by-step reasoning.
"""

  PHILOSOPHER_ROLE_PROMPT* = """
You are a Philosopher agent focused on:
- Ontological analysis and meaning
- Wisdom accumulation and insight
- Philosophical inquiry and reasoning
- Ethical considerations
- Deep conceptual understanding

Always respond with reflective, wisdom-oriented thinking and explore underlying principles.
"""

  SKEPTIC_ROLE_PROMPT* = """
You are a Skeptic agent specializing in:
- Contradiction detection and validation
- Logical consistency checking
- Evidence evaluation and verification
- Critical analysis and questioning
- Fact-checking and proof validation

Always respond with careful scrutiny and demand evidence for claims.
"""

  DREAMER_ROLE_PROMPT* = """
You are a Dreamer agent focused on:
- Creative thinking and innovation
- Inspiration and vision generation
- Possibility exploration
- Imaginative problem-solving
- Future-oriented thinking

Always respond with creative, imaginative thinking and explore new possibilities.
"""

  INVESTIGATOR_ROLE_PROMPT* = """
You are an Investigator agent specializing in:
- Pattern detection and analysis
- Anomaly identification
- Hypothesis generation and testing
- Evidence collection and synthesis
- Case investigation and reporting

Always respond with thorough investigative thinking and systematic analysis.
"""

  ARCHIVIST_ROLE_PROMPT* = """
You are an Archivist agent focused on:
- Knowledge organization and categorization
- Information retrieval optimization
- Storage strategy and indexing
- Memory hierarchy management
- Knowledge preservation and access

Always respond with organizational thinking and focus on information management.
"""

  STAGE_MANAGER_ROLE_PROMPT* = """
You are a Stage Manager agent specializing in:
- Agent coordination and orchestration
- Workflow management and optimization
- Task distribution and scheduling
- System status monitoring
- Process facilitation and direction

Always respond with coordination-focused thinking and focus on system-wide optimization.
"""

# Constructor functions
proc newAgentAPI*(api_id: string, model_name: string, base_url: string = "http://localhost:11434", 
                  role_prompt: string = "", api_key: string = "", 
                  thought_permission: ThoughtPermission = None): AgentAPI =
  ## Create a new agent API configuration
  result = AgentAPI(
    api_id: api_id,
    model_name: model_name,
    base_url: base_url,
    api_key: api_key,
    role_prompt: role_prompt,
    is_available: true,
    max_concurrent: 10,
    current_requests: 0,
    thought_permission: thought_permission
  )

proc newLoadBalancer*(): LoadBalancer =
  ## Create a new load balancer
  result = LoadBalancer(
    round_robin_index: 0,
    api_weights: initTable[string, float]()
  )

proc newAgentAPIManager*(): AgentAPIManager =
  ## Create a new API manager
  result = AgentAPIManager(
    apis: initTable[string, AgentAPI](),
    agent_assignments: initTable[string, string](),
    load_balancer: newLoadBalancer()
  )

# API Management
proc registerAPI*(manager: AgentAPIManager, api: AgentAPI): bool =
  ## Register an API with the manager
  if api.api_id in manager.apis:
    return false  # API already exists
  
  manager.apis[api.api_id] = api
  manager.load_balancer.api_weights[api.api_id] = 1.0
  
  # Set as default if it's the first one
  if manager.default_api.isNil:
    manager.default_api = api
  
  return true

proc assignAgentToAPI*(manager: AgentAPIManager, agent_id: string, api_id: string): bool =
  ## Assign an agent to a specific API
  if api_id notin manager.apis:
    return false
  
  manager.agent_assignments[agent_id] = api_id
  return true

proc getAPIForAgent*(manager: AgentAPIManager, agent_id: string): Option[AgentAPI] =
  ## Get the API assigned to an agent
  if agent_id in manager.agent_assignments:
    let api_id = manager.agent_assignments[agent_id]
    if api_id in manager.apis:
      return some(manager.apis[api_id])
  
  # Fall back to default API
  if not manager.default_api.isNil:
    return some(manager.default_api)
  
  return none(AgentAPI)

proc getAvailableAPI*(manager: AgentAPIManager): Option[AgentAPI] =
  ## Get an available API using load balancing
  var available_apis: seq[AgentAPI] = @[]
  
  for api in manager.apis.values:
    if api.is_available and api.current_requests < api.max_concurrent:
      available_apis.add(api)
  
  if available_apis.len == 0:
    return none(AgentAPI)
  
  # Simple round-robin selection
  let selected_index = manager.load_balancer.round_robin_index mod available_apis.len
  manager.load_balancer.round_robin_index = (manager.load_balancer.round_robin_index + 1) mod 1000
  
  return some(available_apis[selected_index])

# Role prompt management
proc getRolePrompt*(agent_type: string): string =
  ## Get the role prompt for an agent type
  case agent_type.toLowerAscii()
  of "engineer":
    return ENGINEER_ROLE_PROMPT
  of "philosopher":
    return PHILOSOPHER_ROLE_PROMPT
  of "skeptic":
    return SKEPTIC_ROLE_PROMPT
  of "dreamer":
    return DREAMER_ROLE_PROMPT
  of "investigator":
    return INVESTIGATOR_ROLE_PROMPT
  of "archivist":
    return ARCHIVIST_ROLE_PROMPT
  of "stage_manager":
    return STAGE_MANAGER_ROLE_PROMPT
  else:
    return "You are an AI assistant. Please help with the given task."

proc createAgentPrompt*(api: AgentAPI, task: string): string =
  ## Create a complete prompt for an agent
  let role_prompt = if api.role_prompt.len > 0: api.role_prompt else: "You are an AI assistant."
  return role_prompt & "\n\nTask: " & task & "\n\nResponse:"

# API status management
proc markAPIUnavailable*(manager: AgentAPIManager, api_id: string) =
  ## Mark an API as unavailable
  if api_id in manager.apis:
    manager.apis[api_id].is_available = false

proc markAPIAvailable*(manager: AgentAPIManager, api_id: string) =
  ## Mark an API as available
  if api_id in manager.apis:
    manager.apis[api_id].is_available = true

proc incrementRequestCount*(manager: AgentAPIManager, api_id: string) =
  ## Increment the request count for an API
  if api_id in manager.apis:
    manager.apis[api_id].current_requests += 1

proc decrementRequestCount*(manager: AgentAPIManager, api_id: string) =
  ## Decrement the request count for an API
  if api_id in manager.apis:
    if manager.apis[api_id].current_requests > 0:
      manager.apis[api_id].current_requests -= 1 

# Thought permission management
proc canCreateVerifiedThoughts*(api: AgentAPI): bool =
  ## Check if an agent can create verified thoughts
  return api.thought_permission in [Verify, Full]

proc canCreateDraftThoughts*(api: AgentAPI): bool =
  ## Check if an agent can create draft thoughts
  return api.thought_permission in [Draft, Suggest, Verify, Full]

proc canSuggestThoughts*(api: AgentAPI): bool =
  ## Check if an agent can suggest thoughts to Stage Manager
  return api.thought_permission in [Suggest, Verify, Full]

proc getThoughtPermission*(api: AgentAPI): ThoughtPermission =
  ## Get the thought permission level for an agent
  return api.thought_permission

# Agent-specific permission setup
proc setupStageManagerPermissions*(manager: AgentAPIManager, api_id: string): bool =
  ## Set up Stage Manager with full thought permissions
  if api_id in manager.apis:
    manager.apis[api_id].thought_permission = Full
    return true
  return false

proc setupAgentPermissions*(manager: AgentAPIManager, agent_id: string, permission: ThoughtPermission): bool =
  ## Set up agent with specific thought permissions
  let api = manager.getAPIForAgent(agent_id)
  if api.isSome:
    api.get().thought_permission = permission
    return true
  return false 