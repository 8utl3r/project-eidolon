# RAG Types
#
# This module defines types for Retrieval Augmented Generation (RAG) system.
# Includes external knowledge sources, vector embeddings, and knowledge synthesis.

import std/[times, tables, options]

type
  KnowledgeSource* = object
    ## External knowledge source configuration
    source_id*: string
    source_type*: string  # "document", "database", "api", "web"
    name*: string
    description*: string
    url*: string
    access_credentials*: Table[string, string]
    last_accessed*: DateTime
    reliability_score*: float  # 0.0-1.0
    update_frequency*: float   # Hours between updates
    is_active*: bool
    created*: DateTime

  VectorEmbedding* = object
    ## Vector embedding for semantic search
    embedding_id*: string
    source_entity_id*: string  # Associated entity ID
    source_text*: string       # Original text that was embedded
    vector*: seq[float]        # Embedding vector
    embedding_model*: string   # Model used for embedding
    confidence*: float         # Confidence in embedding quality
    created*: DateTime
    last_used*: DateTime
    usage_count*: int

  KnowledgeChunk* = object
    ## A chunk of knowledge from external sources
    chunk_id*: string
    source_id*: string         # Knowledge source ID
    content*: string           # Text content
    metadata*: Table[string, string]  # Source-specific metadata
    embedding*: Option[VectorEmbedding]  # Associated embedding
    relevance_score*: float    # Relevance to current query
    confidence*: float         # Confidence in accuracy
    created*: DateTime
    last_accessed*: DateTime

  QueryContext* = object
    ## Context for knowledge retrieval queries
    query_id*: string
    query_text*: string
    query_embedding*: Option[VectorEmbedding]
    context_entities*: seq[string]  # Relevant entity IDs
    search_parameters*: SearchParameters
    timestamp*: DateTime
    user_id*: Option[string]

  SearchParameters* = object
    ## Parameters for knowledge search
    max_results*: int          # Maximum number of results
    similarity_threshold*: float  # Minimum similarity score
    source_filter*: seq[string]   # Specific sources to search
    time_filter*: Option[DateTime]  # Only results after this time
    confidence_threshold*: float    # Minimum confidence score
    include_metadata*: bool         # Include metadata in results

  KnowledgeSynthesis* = object
    ## Result of knowledge synthesis
    synthesis_id*: string
    query_context*: QueryContext
    retrieved_chunks*: seq[KnowledgeChunk]
    synthesized_content*: string
    confidence*: float
    sources_used*: seq[string]
    synthesis_strategy*: string  # "summarization", "integration", "comparison"
    created*: DateTime
    processing_time*: float

  EmbeddingModel* = object
    ## Configuration for embedding models
    model_id*: string
    model_name*: string
    model_type*: string  # "sentence_transformers", "openai", "custom"
    dimensions*: int     # Vector dimensions
    max_tokens*: int     # Maximum input tokens
    api_endpoint*: string
    api_key*: string
    is_active*: bool
    performance_metrics*: Table[string, float]

  RAGConfiguration* = object
    ## Global RAG system configuration
    config_id*: string
    default_embedding_model*: string
    default_similarity_threshold*: float
    max_concurrent_searches*: int
    cache_enabled*: bool
    cache_size*: int
    update_frequency*: float
    reliability_threshold*: float
    created*: DateTime
    last_updated*: DateTime

# Constructor Functions
proc newKnowledgeSource*(source_id: string, source_type: string, name: string, url: string): KnowledgeSource =
  ## Create a new knowledge source
  return KnowledgeSource(
    source_id: source_id,
    source_type: source_type,
    name: name,
    description: "",
    url: url,
    access_credentials: initTable[string, string](),
    last_accessed: now(),
    reliability_score: 0.5,
    update_frequency: 24.0,  # 24 hours default
    is_active: true,
    created: now()
  )

proc newVectorEmbedding*(embedding_id: string, source_entity_id: string, source_text: string, vector: seq[float], model: string): VectorEmbedding =
  ## Create a new vector embedding
  return VectorEmbedding(
    embedding_id: embedding_id,
    source_entity_id: source_entity_id,
    source_text: source_text,
    vector: vector,
    embedding_model: model,
    confidence: 0.8,
    created: now(),
    last_used: now(),
    usage_count: 0
  )

proc newKnowledgeChunk*(chunk_id: string, source_id: string, content: string): KnowledgeChunk =
  ## Create a new knowledge chunk
  return KnowledgeChunk(
    chunk_id: chunk_id,
    source_id: source_id,
    content: content,
    metadata: initTable[string, string](),
    embedding: none(VectorEmbedding),
    relevance_score: 0.0,
    confidence: 0.5,
    created: now(),
    last_accessed: now()
  )

proc newQueryContext*(query_id: string, query_text: string): QueryContext =
  ## Create a new query context
  return QueryContext(
    query_id: query_id,
    query_text: query_text,
    query_embedding: none(VectorEmbedding),
    context_entities: @[],
    search_parameters: SearchParameters(
      max_results: 10,
      similarity_threshold: 0.7,
      source_filter: @[],
      time_filter: none(DateTime),
      confidence_threshold: 0.5,
      include_metadata: true
    ),
    timestamp: now(),
    user_id: none(string)
  )

proc newSearchParameters*(): SearchParameters =
  ## Create default search parameters
  return SearchParameters(
    max_results: 10,
    similarity_threshold: 0.7,
    source_filter: @[],
    time_filter: none(DateTime),
    confidence_threshold: 0.5,
    include_metadata: true
  )

proc newKnowledgeSynthesis*(synthesis_id: string, query_context: QueryContext): KnowledgeSynthesis =
  ## Create a new knowledge synthesis
  return KnowledgeSynthesis(
    synthesis_id: synthesis_id,
    query_context: query_context,
    retrieved_chunks: @[],
    synthesized_content: "",
    confidence: 0.0,
    sources_used: @[],
    synthesis_strategy: "summarization",
    created: now(),
    processing_time: 0.0
  )

proc newEmbeddingModel*(model_id: string, model_name: string, model_type: string, dimensions: int): EmbeddingModel =
  ## Create a new embedding model configuration
  return EmbeddingModel(
    model_id: model_id,
    model_name: model_name,
    model_type: model_type,
    dimensions: dimensions,
    max_tokens: 512,
    api_endpoint: "",
    api_key: "",
    is_active: true,
    performance_metrics: initTable[string, float]()
  )

proc newRAGConfiguration*(): RAGConfiguration =
  ## Create default RAG configuration
  return RAGConfiguration(
    config_id: "default_rag_config",
    default_embedding_model: "sentence_transformers",
    default_similarity_threshold: 0.7,
    max_concurrent_searches: 5,
    cache_enabled: true,
    cache_size: 1000,
    update_frequency: 24.0,
    reliability_threshold: 0.6,
    created: now(),
    last_updated: now()
  ) 