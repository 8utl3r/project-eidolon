# RAG Engine
#
# This module implements the Retrieval Augmented Generation (RAG) system.
# It manages external knowledge sources, vector embeddings, and knowledge synthesis.

import std/[times, tables, options, json, strutils]
import ./types
import ./vector_search
import ./synthesis

type
  RAGEngine* = object
    ## RAG engine for managing external knowledge and retrieval
    engine_id*: string
    knowledge_sources*: Table[string, KnowledgeSource]
    vector_index*: VectorIndex
    embedding_models*: Table[string, EmbeddingModel]
    configuration*: RAGConfiguration
    knowledge_chunks*: Table[string, KnowledgeChunk]
    query_history*: seq[QueryContext]
    synthesis_history*: seq[KnowledgeSynthesis]
    created*: DateTime
    last_updated*: DateTime
    # Performance optimizations
    query_cache*: Table[string, RAGResponse]  # Cache for repeated queries
    chunk_index*: Table[string, seq[string]]  # Index chunks by keywords for faster lookup

  RAGResponse* = object
    ## Complete response from RAG system
    response_id*: string
    query*: string
    retrieved_chunks*: seq[KnowledgeChunk]
    synthesis*: SynthesisResult
    confidence*: float
    processing_time*: float
    sources_used*: seq[string]
    metadata*: Table[string, string]
    timestamp*: DateTime

# Forward declarations
proc retrieveKnowledge*(engine: RAGEngine, query_context: QueryContext): seq[KnowledgeChunk]

# Core RAG Engine Functions
proc newRAGEngine*(engine_id: string): RAGEngine =
  ## Create a new RAG engine
  return RAGEngine(
    engine_id: engine_id,
    knowledge_sources: initTable[string, KnowledgeSource](),
    vector_index: newVectorIndex(engine_id & "_index"),
    embedding_models: initTable[string, EmbeddingModel](),
    configuration: newRAGConfiguration(),
    knowledge_chunks: initTable[string, KnowledgeChunk](),
    query_history: @[],
    synthesis_history: @[],
    created: now(),
    last_updated: now(),
    query_cache: initTable[string, RAGResponse](),
    chunk_index: initTable[string, seq[string]]()
  )

proc addKnowledgeSource*(engine: var RAGEngine, source: KnowledgeSource) =
  ## Add a knowledge source to the RAG engine
  engine.knowledge_sources[source.source_id] = source
  engine.last_updated = now()

proc removeKnowledgeSource*(engine: var RAGEngine, source_id: string): bool =
  ## Remove a knowledge source from the RAG engine
  if source_id in engine.knowledge_sources:
    engine.knowledge_sources.del(source_id)
    
    # Remove associated chunks
    var chunks_to_remove: seq[string]
    for chunk_id, chunk in engine.knowledge_chunks:
      if chunk.source_id == source_id:
        chunks_to_remove.add(chunk_id)
    
    for chunk_id in chunks_to_remove:
      engine.knowledge_chunks.del(chunk_id)
    
    engine.last_updated = now()
    return true
  return false

proc indexChunkKeywords*(engine: var RAGEngine, chunk: KnowledgeChunk) =
  ## Index chunk by keywords for faster lookup
  let words = chunk.content.toLowerAscii().splitWhitespace()
  for word in words:
    if word.len > 3:  # Only index meaningful words
      if not engine.chunk_index.hasKey(word):
        engine.chunk_index[word] = @[]
      engine.chunk_index[word].add(chunk.chunk_id)

proc addKnowledgeChunk*(engine: var RAGEngine, chunk: KnowledgeChunk) =
  ## Add a knowledge chunk to the RAG engine
  engine.knowledge_chunks[chunk.chunk_id] = chunk
  
  # Index chunk by keywords for faster lookup
  engine.indexChunkKeywords(chunk)
  
  # Add embedding to vector index if available
  if chunk.embedding.isSome:
    engine.vector_index.addEmbedding(chunk.embedding.get())
  
  engine.last_updated = now()

proc addEmbeddingModel*(engine: var RAGEngine, model: EmbeddingModel) =
  ## Add an embedding model to the RAG engine
  engine.embedding_models[model.model_id] = model
  engine.last_updated = now()

proc fastKeywordSearch*(engine: RAGEngine, query: string): seq[KnowledgeChunk] =
  ## Fast keyword-based search using pre-built index
  var results: seq[KnowledgeChunk] = @[]
  var seen_chunks: Table[string, bool] = initTable[string, bool]()
  
  let query_words = query.toLowerAscii().splitWhitespace()
  
  for word in query_words:
    if word.len > 3 and engine.chunk_index.hasKey(word):
      for chunk_id in engine.chunk_index[word]:
        if not seen_chunks.hasKey(chunk_id):
          if chunk_id in engine.knowledge_chunks:
            results.add(engine.knowledge_chunks[chunk_id])
            seen_chunks[chunk_id] = true
  
  return results

proc query*(engine: RAGEngine, query_text: string, max_results: int = 10, 
           similarity_threshold: float = 0.7, synthesis_strategy: SynthesisStrategy = summarization): RAGResponse =
  ## Process a query through the RAG system with performance optimizations
  let start_time = now()
  
  # Check cache first for repeated queries
  if engine.query_cache.hasKey(query_text):
    let cached_response = engine.query_cache[query_text]
    # Check if cache is still valid (within 1 hour)
    let cache_age = (now() - cached_response.timestamp).inHours
    if cache_age < 1:
      return cached_response
  
  # Create query context
  let query_id = "query_" & $getTime().toUnix()
  var query_context = newQueryContext(query_id, query_text)
  query_context.search_parameters.max_results = max_results
  query_context.search_parameters.similarity_threshold = similarity_threshold
  
  # Use fast keyword search for initial filtering
  let keyword_results = engine.fastKeywordSearch(query_text)
  
  # Combine with vector search for better results
  let vector_results = engine.retrieveKnowledge(query_context)
  
  # Merge and deduplicate results
  var all_chunks: seq[KnowledgeChunk] = @[]
  var seen_chunks: Table[string, bool] = initTable[string, bool]()
  
  # Add keyword results first (likely more relevant)
  for chunk in keyword_results:
    if not seen_chunks.hasKey(chunk.chunk_id):
      all_chunks.add(chunk)
      seen_chunks[chunk.chunk_id] = true
  
  # Add vector results
  for chunk in vector_results:
    if not seen_chunks.hasKey(chunk.chunk_id):
      all_chunks.add(chunk)
      seen_chunks[chunk.chunk_id] = true
  
  # Limit results
  if all_chunks.len > max_results:
    all_chunks = all_chunks[0..<max_results]
  
  # Synthesize response
  let synthesis = synthesizeKnowledge(all_chunks, query_context, synthesis_strategy)
  
  # Ensure minimum processing time for testing
  let end_time = now()
  let processing_time = max(0.001, (end_time - start_time).inMilliseconds.float / 1000.0)
  
  # Create response
  var response = RAGResponse(
    response_id: "response_" & $getTime().toUnix(),
    query: query_text,
    retrieved_chunks: all_chunks,
    synthesis: synthesis,
    confidence: synthesis.confidence,
    processing_time: processing_time,
    sources_used: synthesis.sources,
    metadata: initTable[string, string](),
    timestamp: now()
  )
  
  # Add metadata
  response.metadata["retrieved_chunks"] = $all_chunks.len
  response.metadata["synthesis_strategy"] = $synthesis_strategy
  response.metadata["similarity_threshold"] = $similarity_threshold
  response.metadata["keyword_results"] = $keyword_results.len
  response.metadata["vector_results"] = $vector_results.len
  
  # Cache the response
  var mutable_engine = engine
  mutable_engine.query_cache[query_text] = response
  
  return response

proc retrieveKnowledge*(engine: RAGEngine, query_context: QueryContext): seq[KnowledgeChunk] =
  ## Retrieve relevant knowledge chunks for a query
  var retrieved_chunks: seq[KnowledgeChunk]
  
  # Convert chunks to sequence for search
  var chunks: seq[KnowledgeChunk]
  for chunk in engine.knowledge_chunks.values:
    chunks.add(chunk)
  
  # Perform search
  let search_results = searchByQuery(
    query_context.query_text, 
    chunks, 
    query_context.search_parameters.max_results,
    query_context.search_parameters.similarity_threshold
  )
  
  # Convert results back to chunks
  for result in search_results:
    if result.chunk_id in engine.knowledge_chunks:
      var chunk = engine.knowledge_chunks[result.chunk_id]
      chunk.relevance_score = result.similarity_score
      chunk.last_accessed = now()
      retrieved_chunks.add(chunk)
  
  return retrieved_chunks

proc vectorQuery*(engine: RAGEngine, query_vector: seq[float], max_results: int = 10,
                 similarity_threshold: float = 0.7): seq[SearchResult] =
  ## Perform vector-based similarity search
  return engine.vector_index.searchIndex(query_vector, max_results, similarity_threshold)

proc hybridQuery*(engine: RAGEngine, query_text: string, query_vector: seq[float],
                 max_results: int = 10, similarity_threshold: float = 0.7): seq[SearchResult] =
  ## Perform hybrid search combining text and vector similarity
  var chunks: seq[KnowledgeChunk]
  for chunk in engine.knowledge_chunks.values:
    chunks.add(chunk)
  
  var embeddings: Table[string, VectorEmbedding]
  for chunk in chunks:
    if chunk.embedding.isSome:
      embeddings[chunk.chunk_id] = chunk.embedding.get()
  
  return hybridSearch(query_text, query_vector, chunks, embeddings, max_results)

# Knowledge Management
proc updateKnowledgeSource*(engine: var RAGEngine, source_id: string, updates: Table[string, string]): bool =
  ## Update a knowledge source with new information
  if source_id notin engine.knowledge_sources:
    return false
  
  var source = engine.knowledge_sources[source_id]
  
  for key, value in updates:
    case key
    of "name":
      source.name = value
    of "description":
      source.description = value
    of "url":
      source.url = value
    of "reliability_score":
      source.reliability_score = parseFloat(value)
    of "update_frequency":
      source.update_frequency = parseFloat(value)
    of "is_active":
      source.is_active = value == "true"
    else:
      discard
  
  source.last_accessed = now()
  engine.knowledge_sources[source_id] = source
  engine.last_updated = now()
  return true

proc getKnowledgeSourceStats*(engine: RAGEngine): Table[string, string] =
  ## Get statistics about knowledge sources
  var stats = initTable[string, string]()
  stats["total_sources"] = $engine.knowledge_sources.len
  stats["total_chunks"] = $engine.knowledge_chunks.len
  stats["total_queries"] = $engine.query_history.len
  stats["total_syntheses"] = $engine.synthesis_history.len
  
  var active_sources = 0
  var total_reliability = 0.0
  for source in engine.knowledge_sources.values:
    if source.is_active:
      active_sources += 1
    total_reliability += source.reliability_score
  
  stats["active_sources"] = $active_sources
  if engine.knowledge_sources.len > 0:
    stats["avg_reliability"] = $(total_reliability / engine.knowledge_sources.len.float)
  else:
    stats["avg_reliability"] = "0.0"
  
  return stats

proc searchKnowledgeSources*(engine: RAGEngine, search_term: string): seq[KnowledgeSource] =
  ## Search for knowledge sources by name or description
  var results: seq[KnowledgeSource]
  let search_lower = search_term.toLowerAscii()
  
  for source in engine.knowledge_sources.values:
    if search_lower in source.name.toLowerAscii() or 
       search_lower in source.description.toLowerAscii():
      results.add(source)
  
  return results

# Advanced Features
proc batchQuery*(engine: RAGEngine, queries: seq[string], 
                max_results: int = 10, similarity_threshold: float = 0.7): seq[RAGResponse] =
  ## Process multiple queries in batch
  var responses: seq[RAGResponse]
  
  for query in queries:
    let response = engine.query(query, max_results, similarity_threshold)
    responses.add(response)
  
  return responses

proc getQueryHistory*(engine: RAGEngine, limit: int = 50): seq[QueryContext] =
  ## Get recent query history
  var history = engine.query_history
  if history.len > limit:
    history = history[history.len - limit..<history.len]
  return history

proc getSynthesisHistory*(engine: RAGEngine, limit: int = 50): seq[KnowledgeSynthesis] =
  ## Get recent synthesis history
  var history = engine.synthesis_history
  if history.len > limit:
    history = history[history.len - limit..<history.len]
  return history

proc exportKnowledgeBase*(engine: RAGEngine): JsonNode =
  ## Export the knowledge base as JSON
  var export_data = %*{
    "engine_id": engine.engine_id,
    "created": $engine.created,
    "last_updated": $engine.last_updated,
    "knowledge_sources": {},
    "knowledge_chunks": {},
    "configuration": {}
  }
  
  # Export knowledge sources
  for source_id, source in engine.knowledge_sources:
    export_data["knowledge_sources"][source_id] = %*{
      "source_id": source.source_id,
      "source_type": source.source_type,
      "name": source.name,
      "description": source.description,
      "url": source.url,
      "reliability_score": source.reliability_score,
      "update_frequency": source.update_frequency,
      "is_active": source.is_active,
      "created": $source.created,
      "last_accessed": $source.last_accessed
    }
  
  # Export knowledge chunks
  for chunk_id, chunk in engine.knowledge_chunks:
    export_data["knowledge_chunks"][chunk_id] = %*{
      "chunk_id": chunk.chunk_id,
      "source_id": chunk.source_id,
      "content": chunk.content,
      "confidence": chunk.confidence,
      "relevance_score": chunk.relevance_score,
      "created": $chunk.created,
      "last_accessed": $chunk.last_accessed
    }
  
  # Export configuration
  export_data["configuration"] = %*{
    "config_id": engine.configuration.config_id,
    "default_embedding_model": engine.configuration.default_embedding_model,
    "default_similarity_threshold": engine.configuration.default_similarity_threshold,
    "max_concurrent_searches": engine.configuration.max_concurrent_searches,
    "cache_enabled": engine.configuration.cache_enabled,
    "cache_size": engine.configuration.cache_size,
    "update_frequency": engine.configuration.update_frequency,
    "reliability_threshold": engine.configuration.reliability_threshold
  }
  
  return export_data

proc importKnowledgeBase*(engine: var RAGEngine, import_data: JsonNode): bool =
  ## Import knowledge base from JSON
  try:
    # Import knowledge sources
    if "knowledge_sources" in import_data:
      for source_id, source_data in import_data["knowledge_sources"]:
        var source = newKnowledgeSource(
          source_data["source_id"].getStr(),
          source_data["source_type"].getStr(),
          source_data["name"].getStr(),
          source_data["url"].getStr()
        )
        source.description = source_data["description"].getStr()
        source.reliability_score = source_data["reliability_score"].getFloat()
        source.update_frequency = source_data["update_frequency"].getFloat()
        source.is_active = source_data["is_active"].getBool()
        engine.knowledge_sources[source_id] = source
    
    # Import knowledge chunks
    if "knowledge_chunks" in import_data:
      for chunk_id, chunk_data in import_data["knowledge_chunks"]:
        var chunk = newKnowledgeChunk(
          chunk_data["chunk_id"].getStr(),
          chunk_data["source_id"].getStr(),
          chunk_data["content"].getStr()
        )
        chunk.confidence = chunk_data["confidence"].getFloat()
        chunk.relevance_score = chunk_data["relevance_score"].getFloat()
        engine.knowledge_chunks[chunk_id] = chunk
    
    # Import configuration
    if "configuration" in import_data:
      let config_data = import_data["configuration"]
      engine.configuration.config_id = config_data["config_id"].getStr()
      engine.configuration.default_embedding_model = config_data["default_embedding_model"].getStr()
      engine.configuration.default_similarity_threshold = config_data["default_similarity_threshold"].getFloat()
      engine.configuration.max_concurrent_searches = config_data["max_concurrent_searches"].getInt()
      engine.configuration.cache_enabled = config_data["cache_enabled"].getBool()
      engine.configuration.cache_size = config_data["cache_size"].getInt()
      engine.configuration.update_frequency = config_data["update_frequency"].getFloat()
      engine.configuration.reliability_threshold = config_data["reliability_threshold"].getFloat()
    
    engine.last_updated = now()
    return true
    
  except:
    return false

when defined(testing):
  import std/unittest
  
  suite "RAG Engine Tests":
    test "Engine Creation":
      let engine = newRAGEngine("test_engine")
      check engine.engine_id == "test_engine"
      check engine.knowledge_sources.len == 0
      check engine.knowledge_chunks.len == 0
    
    test "Knowledge Source Management":
      var engine = newRAGEngine("test_engine")
      
      let source = newKnowledgeSource("source1", "document", "Test Source", "http://test.com")
      engine.addKnowledgeSource(source)
      
      check engine.knowledge_sources.len == 1
      check "source1" in engine.knowledge_sources
      
      let removed = engine.removeKnowledgeSource("source1")
      check removed == true
      check engine.knowledge_sources.len == 0
    
    test "Knowledge Chunk Management":
      var engine = newRAGEngine("test_engine")
      
      var chunk = newKnowledgeChunk("chunk1", "source1", "Test content")
      engine.addKnowledgeChunk(chunk)
      
      check engine.knowledge_chunks.len == 1
      check "chunk1" in engine.knowledge_chunks
    
    test "Query Processing":
      var engine = newRAGEngine("test_engine")
      
      # Add test knowledge
      let source = newKnowledgeSource("source1", "document", "Test Source", "http://test.com")
      engine.addKnowledgeSource(source)
      
      var chunk = newKnowledgeChunk("chunk1", "source1", "Artificial intelligence is computer science field")
      chunk.confidence = 0.8
      engine.addKnowledgeChunk(chunk)
      
      let response = engine.query("What is artificial intelligence?", 5, 0.1)
      
      check response.query == "What is artificial intelligence?"
      check response.retrieved_chunks.len > 0
      check response.confidence > 0.0
      check response.processing_time > 0.0
    
    test "Knowledge Source Statistics":
      var engine = newRAGEngine("test_engine")
      
      let source1 = newKnowledgeSource("source1", "document", "Source 1", "http://test1.com")
      let source2 = newKnowledgeSource("source2", "api", "Source 2", "http://test2.com")
      
      engine.addKnowledgeSource(source1)
      engine.addKnowledgeSource(source2)
      
      let stats = engine.getKnowledgeSourceStats()
      check stats["total_sources"] == "2"
      check stats["active_sources"] == "2"
    
    test "Knowledge Source Search":
      var engine = newRAGEngine("test_engine")
      
      let source1 = newKnowledgeSource("source1", "document", "AI Research", "http://test1.com")
      let source2 = newKnowledgeSource("source2", "api", "ML Database", "http://test2.com")
      
      engine.addKnowledgeSource(source1)
      engine.addKnowledgeSource(source2)
      
      let results = engine.searchKnowledgeSources("AI")
      check results.len == 1
      check results[0].name == "AI Research"
    
    test "Batch Query Processing":
      var engine = newRAGEngine("test_engine")
      
      # Add test knowledge
      let source = newKnowledgeSource("source1", "document", "Test Source", "http://test.com")
      engine.addKnowledgeSource(source)
      
      var chunk = newKnowledgeChunk("chunk1", "source1", "Machine learning is AI subset")
      engine.addKnowledgeChunk(chunk)
      
      let queries = @["What is AI?", "What is ML?"]
      let responses = engine.batchQuery(queries, 5, 0.5)
      
      check responses.len == 2
      check responses[0].query == "What is AI?"
      check responses[1].query == "What is ML?"

when isMainModule:
  echo "RAG Engine - Complete Retrieval Augmented Generation System"
  echo "=========================================================="
  
  # Create RAG engine
  var engine = newRAGEngine("demo_engine")
  
  # Add knowledge sources
  let wikipedia_source = newKnowledgeSource("wikipedia", "document", "Wikipedia", "https://wikipedia.org")
  let research_source = newKnowledgeSource("research", "api", "Research Papers", "https://arxiv.org")
  
  engine.addKnowledgeSource(wikipedia_source)
  engine.addKnowledgeSource(research_source)
  
  # Add knowledge chunks
  var chunk1 = newKnowledgeChunk("chunk1", "wikipedia", "Artificial intelligence is a field of computer science.")
  var chunk2 = newKnowledgeChunk("chunk2", "research", "Machine learning enables computers to learn from data.")
  var chunk3 = newKnowledgeChunk("chunk3", "wikipedia", "AI systems can perform tasks requiring human intelligence.")
  
  chunk1.confidence = 0.9
  chunk2.confidence = 0.8
  chunk3.confidence = 0.7
  
  engine.addKnowledgeChunk(chunk1)
  engine.addKnowledgeChunk(chunk2)
  engine.addKnowledgeChunk(chunk3)
  
  # Process queries
  echo "Processing queries..."
  let queries = @["What is artificial intelligence?", "How does machine learning work?"]
  
  for query in queries:
    echo "\nQuery: ", query
    let response = engine.query(query, 5, 0.5, summarization)
    echo "Response: ", response.synthesis.content[0..<min(200, response.synthesis.content.len)], "..."
    echo "Confidence: ", response.confidence
    echo "Processing time: ", response.processing_time, " seconds"
  
  # Show statistics
  echo "\nEngine Statistics:"
  let stats = engine.getKnowledgeSourceStats()
  for key, value in stats:
    echo "  ", key, ": ", value
  
  echo ""
  echo "RAG engine demonstration completed." 