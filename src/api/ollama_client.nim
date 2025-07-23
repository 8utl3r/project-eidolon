# Ollama Client
#
# This module provides integration with Ollama for local LLM agentic reasoning.
# Agents use this client to send prompts to Ollama and receive LLM completions.

import std/[httpclient, json, times, strutils, options, tables, asyncdispatch]
import ../types

const
  OLLAMA_BASE_URL* = "http://localhost:11434"
  OLLAMA_GENERATE_ENDPOINT* = "/api/generate"
  OLLAMA_CHAT_ENDPOINT* = "/api/chat"
  DEFAULT_MODEL* = "llama3.2:3b"
  DEFAULT_TIMEOUT* = 30000  # 30 seconds

type
  OllamaRequest* = object
    ## Request to Ollama API
    model*: string
    prompt*: string
    system*: Option[string]
    template_name*: Option[string]
    context*: Option[seq[int]]
    options*: Option[JsonNode]
    format*: Option[string]
    raw*: Option[bool]
    stream*: Option[bool]

  OllamaResponse* = object
    ## Response from Ollama API
    model*: string
    created_at*: string
    response*: string
    done*: bool
    context*: Option[seq[int]]
    total_duration*: Option[int64]
    load_duration*: Option[int64]
    prompt_eval_count*: Option[int]
    prompt_eval_duration*: Option[int64]
    eval_count*: Option[int]
    eval_duration*: Option[int64]

  OllamaClient* = ref object
    ## Client for communicating with Ollama
    base_url*: string
    default_model*: string
    timeout*: int
    http_client*: HttpClient
    model_cache*: Table[string, bool]  # model_name -> available

  AgentPrompt* = object
    ## Structured prompt for agent-AI communication
    agent_type*: AgentType
    agent_id*: string
    system_prompt*: string
    user_prompt*: string
    context*: seq[string]
    constraints*: seq[string]
    expected_format*: string

# Constructor functions
proc newOllamaClient*(base_url: string = OLLAMA_BASE_URL, default_model: string = DEFAULT_MODEL): OllamaClient =
  ## Create a new Ollama client
  var client = newHttpClient(timeout = DEFAULT_TIMEOUT)
  return OllamaClient(
    base_url: base_url,
    default_model: default_model,
    timeout: DEFAULT_TIMEOUT,
    http_client: client,
    model_cache: initTable[string, bool]()
  )

proc newOllamaRequest*(model: string, prompt: string, system: Option[string] = none(string)): OllamaRequest =
  ## Create a new Ollama request
  return OllamaRequest(
    model: model,
    prompt: prompt,
    system: system,
    template_name: none(string),
    context: none(seq[int]),
    options: none(JsonNode),
    format: none(string),
    raw: none(bool),
    stream: some(false)
  )

proc newAgentPrompt*(agent_type: AgentType, agent_id: string, system_prompt: string, user_prompt: string): AgentPrompt =
  ## Create a new agent prompt
  return AgentPrompt(
    agent_type: agent_type,
    agent_id: agent_id,
    system_prompt: system_prompt,
    user_prompt: user_prompt,
    context: @[],
    constraints: @[],
    expected_format: "text"
  )

# Core Ollama functions
proc checkModelAvailability*(client: OllamaClient, model: string): bool =
  ## Check if a model is available in Ollama
  if client.model_cache.hasKey(model):
    return client.model_cache[model]
  
  try:
    let request = newOllamaRequest(model, "test")
    
    # Create JSON manually
    var json_request = %*{
      "model": request.model,
      "prompt": request.prompt,
      "stream": false
    }
    
    client.http_client.headers = newHttpHeaders({"Content-Type": "application/json"})
    let response = client.http_client.postContent(
      client.base_url & OLLAMA_GENERATE_ENDPOINT,
      json_request.pretty()
    )
    client.model_cache[model] = true
    return true
  except:
    client.model_cache[model] = false
    return false

proc generateResponse*(client: OllamaClient, request: OllamaRequest): Future[Option[OllamaResponse]] {.async.} =
  ## Generate a response from Ollama (async version)
  try:
    # Create JSON manually
    var json_request = %*{
      "model": request.model,
      "prompt": request.prompt,
      "stream": false
    }
    
    if request.system.isSome:
      json_request["system"] = %request.system.get()
    
    client.http_client.headers = newHttpHeaders({"Content-Type": "application/json"})
    
    # Use async HTTP client
    var async_client = newAsyncHttpClient()
    async_client.headers = newHttpHeaders({"Content-Type": "application/json"})
    
    let response = await async_client.postContent(
      client.base_url & OLLAMA_GENERATE_ENDPOINT,
      json_request.pretty()
    )
    
    let json_response = parseJson(response)
    
    # Parse response manually
    var ollama_response = OllamaResponse(
      model: json_response["model"].getStr,
      created_at: json_response["created_at"].getStr,
      response: json_response["response"].getStr,
      done: json_response["done"].getBool
    )
    
    return some(ollama_response)
  except:
    return none(OllamaResponse)

proc generateAgentResponse*(client: OllamaClient, prompt: AgentPrompt, model: string = ""): Future[Option[string]] {.async.} =
  ## Generate a response for a specific agent (async version)
  let model_to_use = if model.len > 0: model else: client.default_model
  
  if not client.checkModelAvailability(model_to_use):
    return none(string)
  
  let request = newOllamaRequest(
    model_to_use,
    prompt.user_prompt,
    some(prompt.system_prompt)
  )
  
  let response = await client.generateResponse(request)
  if response.isSome():
    return some(response.get().response)
  else:
    return none(string)

# Agent-specific prompt templates
proc createEngineerPrompt*(query: string, context: seq[string] = @[]): AgentPrompt =
  ## Create a prompt for the Engineer agent (mathematical reasoning)
  let system_prompt = """
You are The Engineer, a specialized AI agent for mathematical reasoning and calculations.

Your capabilities:
- Perform precise mathematical calculations
- Analyze mathematical patterns and relationships
- Apply mathematical principles to solve problems
- Provide step-by-step mathematical reasoning
- Work with equations, formulas, and mathematical concepts

Response format:
- Provide clear, step-by-step mathematical reasoning
- Include relevant formulas and calculations
- Explain your mathematical approach
- Be precise and accurate in all calculations
- Use mathematical notation when appropriate

Current context: """ & context.join(", ")
  
  return newAgentPrompt(
    AgentType.engineer,
    "engineer",
    system_prompt,
    query
  )

proc createLinguistPrompt*(query: string, context: seq[string] = @[]): AgentPrompt =
  ## Create a prompt for the Linguist agent
  let system_prompt = """
You are The Linguist, a specialized AI agent for language, vocabulary, translation, and understanding colloquial and idiomatic speech.

Your capabilities:
- Maintain and expand vocabulary
- Translate between languages
- Understand and explain colloquial and idiomatic expressions
- Interpret slang and regional speech
- Provide definitions, synonyms, and paraphrases
- Analyze language usage and meaning

Response format:
- Provide clear explanations of words, phrases, or idioms
- Offer translations or paraphrases as needed
- Explain meaning in context
- Be concise, accurate, and culturally aware

Current context: """ & context.join(", ")
  
  return newAgentPrompt(
    AgentType.linguist,
    "linguist",
    system_prompt,
    query
  )

proc createSkepticPrompt*(query: string, context: seq[string] = @[]): AgentPrompt =
  ## Create a prompt for the Skeptic agent
  let system_prompt = """
You are The Skeptic, a specialized AI agent for logical reasoning and critical analysis.

Your capabilities:
- Apply logical reasoning and critical thinking
- Question assumptions and identify fallacies
- Evaluate evidence and arguments
- Provide balanced, skeptical perspectives
- Identify potential errors or inconsistencies

Response format:
- Apply critical thinking to the query
- Question underlying assumptions
- Evaluate logical consistency
- Identify potential fallacies or errors
- Provide balanced, skeptical analysis
- Suggest alternative perspectives

Current context: """ & context.join(", ")
  
  return newAgentPrompt(
    AgentType.skeptic,
    "skeptic",
    system_prompt,
    query
  )

proc createDreamerPrompt*(query: string, context: seq[string] = @[]): AgentPrompt =
  ## Create a prompt for the Dreamer agent
  let system_prompt = """
You are The Dreamer, a specialized AI agent for creative thinking and imaginative exploration.

Your capabilities:
- Generate creative and innovative ideas
- Explore imaginative possibilities
- Think outside conventional boundaries
- Provide visionary perspectives
- Connect seemingly unrelated concepts

Response format:
- Generate creative and innovative ideas
- Explore imaginative possibilities
- Think beyond conventional boundaries
- Provide visionary perspectives
- Connect seemingly unrelated concepts
- Be imaginative and inspiring

Current context: """ & context.join(", ")
  
  return newAgentPrompt(
    AgentType.dreamer,
    "dreamer",
    system_prompt,
    query
  )

proc createInvestigatorPrompt*(query: string, context: seq[string] = @[]): AgentPrompt =
  ## Create a prompt for the Investigator agent
  let system_prompt = """
You are The Investigator, a specialized AI agent for research and systematic exploration.

Your capabilities:
- Conduct systematic research and analysis
- Explore patterns and connections
- Gather and evaluate information
- Form hypotheses and test them
- Provide thorough investigative insights

Response format:
- Conduct systematic analysis
- Explore patterns and connections
- Gather relevant information
- Form and test hypotheses
- Provide thorough investigative insights
- Be methodical and thorough

Current context: """ & context.join(", ")
  
  return newAgentPrompt(
    AgentType.investigator,
    "investigator",
    system_prompt,
    query
  )

proc createPhilosopherPrompt*(query: string, context: seq[string] = @[]): AgentPrompt =
  ## Create a prompt for the Philosopher agent
  let system_prompt = """
You are The Philosopher, a specialized AI agent for philosophical reasoning and ethical analysis.

Your capabilities:
- Apply philosophical reasoning and analysis
- Explore ethical implications and moral questions
- Consider meaning, purpose, and values
- Provide reflective and thoughtful perspectives
- Connect abstract concepts to practical situations

Response format:
- Apply philosophical reasoning
- Explore ethical implications
- Consider meaning and purpose
- Provide reflective analysis
- Connect abstract to practical
- Be thoughtful and contemplative

Current context: """ & context.join(", ")
  
  return newAgentPrompt(
    AgentType.philosopher,
    "philosopher",
    system_prompt,
    query
  )

proc createArchivistPrompt*(query: string, context: seq[string] = @[]): AgentPrompt =
  ## Create a prompt for the Archivist agent
  let system_prompt = """
You are The Archivist, a specialized AI agent for knowledge preservation and organization.

Your capabilities:
- Organize and categorize information
- Preserve knowledge and context
- Provide historical and contextual insights
- Maintain knowledge hierarchies
- Retrieve and synthesize stored information

Response format:
- Organize information systematically
- Preserve context and relationships
- Provide historical insights
- Maintain knowledge structure
- Retrieve relevant information
- Be thorough and organized

Current context: """ & context.join(", ")
  
  return newAgentPrompt(
    AgentType.archivist,
    "archivist",
    system_prompt,
    query
  )

proc createStageManagerPrompt*(query: string, context: seq[string] = @[]): AgentPrompt =
  ## Create a prompt for the Stage Manager agent
  let system_prompt = """
You are The Stage Manager, a specialized AI agent for coordination and synthesis.

Your capabilities:
- Coordinate multiple perspectives and inputs
- Synthesize information from various sources
- Manage context and flow of information
- Orchestrate complex reasoning processes
- Provide integrative and balanced responses

Response format:
- Coordinate multiple perspectives
- Synthesize diverse information
- Manage context and flow
- Orchestrate reasoning processes
- Provide integrative responses
- Be balanced and comprehensive

Current context: """ & context.join(", ")
  
  return newAgentPrompt(
    AgentType.stage_manager,
    "stage_manager",
    system_prompt,
    query
  )

# Utility functions
proc getRecommendedModel*(agent_type: AgentType): string =
  ## Get recommended Ollama model for agent type
  case agent_type:
  of AgentType.engineer:
    return "llama3"  # Good for precise reasoning
  of AgentType.skeptic:
    return "llama3"  # Good for logical analysis
  of AgentType.dreamer:
    return "mistral"  # Good for creative thinking
  of AgentType.investigator:
    return "llama3"  # Good for systematic analysis
  of AgentType.philosopher:
    return "llama3"  # Good for abstract reasoning
  of AgentType.archivist:
    return "llama3"  # Good for organization
  of AgentType.stage_manager:
    return "llama3"  # Good for coordination
  else:
    return "llama3"  # Default model

proc formatAgentResponse*(agent_type: AgentType, response: string, confidence: float): string =
  ## Format agent response with metadata
  let timestamp = now().format("yyyy-MM-dd HH:mm:ss")
  return """
[Agent: $1 | Time: $2 | Confidence: $3]
$4
""".format($agent_type, timestamp, $confidence, response) 