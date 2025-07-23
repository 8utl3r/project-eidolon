# Vector Search
#
# This module implements vector similarity search for RAG system.
# Includes cosine similarity, nearest neighbor search, and result ranking.

import std/[math, algorithm, tables, times, strutils, sets]
import ./types

const RUN_VECTOR_SEARCH_TESTS* = true

type
  SearchResult* = object
    ## Result of a vector similarity search
    chunk_id*: string
    similarity_score*: float
    rank*: int
    metadata*: Table[string, string]
    confidence*: float

  VectorIndex* = object
    ## Index for efficient vector similarity search
    index_id*: string
    embeddings*: Table[string, VectorEmbedding]
    dimension*: int
    total_vectors*: int
    created*: DateTime
    last_updated*: DateTime

# Vector Operations
proc cosineSimilarity*(vec1, vec2: seq[float]): float =
  ## Calculate cosine similarity between two vectors
  if vec1.len != vec2.len or vec1.len == 0:
    return 0.0
  
  var dot_product = 0.0
  var norm1 = 0.0
  var norm2 = 0.0
  
  for i in 0..<vec1.len:
    dot_product += vec1[i] * vec2[i]
    norm1 += vec1[i] * vec1[i]
    norm2 += vec2[i] * vec2[i]
  
  let denominator = sqrt(norm1) * sqrt(norm2)
  if denominator == 0.0:
    return 0.0
  
  return dot_product / denominator

proc euclideanDistance*(vec1, vec2: seq[float]): float =
  ## Calculate Euclidean distance between two vectors
  if vec1.len != vec2.len or vec1.len == 0:
    return float.high
  
  var sum_squares = 0.0
  for i in 0..<vec1.len:
    let diff = vec1[i] - vec2[i]
    sum_squares += diff * diff
  
  return sqrt(sum_squares)

proc normalizeVector*(vector: seq[float]): seq[float] =
  ## Normalize a vector to unit length
  if vector.len == 0:
    return vector
  
  var norm = 0.0
  for val in vector:
    norm += val * val
  norm = sqrt(norm)
  
  if norm == 0.0:
    return vector
  
  var normalized: seq[float]
  for val in vector:
    normalized.add(val / norm)
  
  return normalized

# Text Relevance Calculation
proc calculateTextRelevance*(query: string, content: string): float =
  ## Calculate text relevance using simple word overlap with improved matching
  let query_words = query.splitWhitespace().toHashSet()
  let content_words = content.splitWhitespace().toHashSet()
  
  if query_words.len == 0:
    return 0.0
  
  var matches = 0.0
  for word in query_words:
    # Check exact match
    if word in content_words:
      matches += 1.0
    # Check partial matches for longer words
    elif word.len > 3:
      for content_word in content_words:
        if content_word.len > 3 and (word in content_word or content_word in word):
          matches += 0.5
          break
    # Check for common abbreviations and synonyms
    elif word == "ai" and ("artificial" in content_words or "artificial" in content):
      matches += 0.8
    elif word == "artificial" and ("ai" in content_words or "ai" in content):
      matches += 0.8
    elif word == "intelligence" and ("ai" in content_words or "artificial" in content_words or "ai" in content or "artificial" in content):
      matches += 0.8
  
  let base_score = matches.float / query_words.len.float
  
  # Boost score for longer content (more comprehensive)
  let content_length_factor = min(1.0, content_words.len.float / 20.0)
  
  # Debug output
  when defined(debug):
    echo "  Query words: ", query_words
    echo "  Content words: ", content_words
    echo "  Matches: ", matches
    echo "  Base score: ", base_score
  
  return min(1.0, base_score * (1.0 + content_length_factor * 0.2))

# Search Operations
proc searchSimilarVectors*(query_vector: seq[float], embeddings: Table[string, VectorEmbedding], 
                          max_results: int = 10, similarity_threshold: float = 0.7): seq[SearchResult] =
  ## Search for similar vectors using cosine similarity
  var results: seq[SearchResult]
  
  for embedding_id, embedding in embeddings:
    let similarity = cosineSimilarity(query_vector, embedding.vector)
    
    if similarity >= similarity_threshold:
      var search_result = SearchResult(
        chunk_id: embedding.source_entity_id,
        similarity_score: similarity,
        rank: 0,
        metadata: initTable[string, string](),
        confidence: embedding.confidence
      )
      results.add(search_result)
  
  # Sort by similarity score (descending)
  results.sort(proc(a, b: SearchResult): int = 
    if a.similarity_score > b.similarity_score: -1
    elif a.similarity_score < b.similarity_score: 1
    else: 0
  )
  
  # Limit results and assign ranks
  var limited_results = results[0..<min(max_results, results.len)]
  for i in 0..<limited_results.len:
    limited_results[i].rank = i + 1
  
  return limited_results

proc searchByQuery*(query_text: string, chunks: seq[KnowledgeChunk], 
                   max_results: int = 10, similarity_threshold: float = 0.7): seq[SearchResult] =
  ## Search knowledge chunks by query text
  var results: seq[SearchResult]
  
  # Simple text-based search (in a real implementation, this would use embeddings)
  let query_lower = query_text.toLowerAscii()
  
  # Remove common question words for better matching
  let clean_query = query_lower.replace("what", "").replace("is", "").replace("are", "").replace("how", "").replace("why", "").replace("when", "").replace("where", "").replace("who", "").strip()
  
  for chunk in chunks:
    let content_lower = chunk.content.toLowerAscii()
    let relevance = calculateTextRelevance(clean_query, content_lower)
    
    # Debug output for integration tests
    when defined(debug):
      echo "Query: ", query_lower
      echo "Content: ", content_lower
      echo "Relevance: ", relevance
      echo "Threshold: ", similarity_threshold
      echo "Match: ", relevance >= similarity_threshold
    
    if relevance >= similarity_threshold:
      var search_result = SearchResult(
        chunk_id: chunk.chunk_id,
        similarity_score: relevance,
        rank: 0,
        metadata: chunk.metadata,
        confidence: chunk.confidence
      )
      results.add(search_result)
  
  # Sort by relevance score (descending)
  results.sort(proc(a, b: SearchResult): int = 
    if a.similarity_score > b.similarity_score: -1
    elif a.similarity_score < b.similarity_score: 1
    else: 0
  )
  
  # Limit results and assign ranks
  var limited_results = results[0..<min(max_results, results.len)]
  for i in 0..<limited_results.len:
    limited_results[i].rank = i + 1
  
  return limited_results

# Vector Index Management
proc newVectorIndex*(index_id: string): VectorIndex =
  ## Create a new vector index
  return VectorIndex(
    index_id: index_id,
    embeddings: initTable[string, VectorEmbedding](),
    dimension: 0,
    total_vectors: 0,
    created: now(),
    last_updated: now()
  )

proc addEmbedding*(index: var VectorIndex, embedding: VectorEmbedding) =
  ## Add an embedding to the index
  index.embeddings[embedding.embedding_id] = embedding
  index.total_vectors += 1
  
  if index.dimension == 0:
    index.dimension = embedding.vector.len
  elif embedding.vector.len != index.dimension:
    # In a real implementation, this would be an error
    discard
  
  index.last_updated = now()

proc removeEmbedding*(index: var VectorIndex, embedding_id: string): bool =
  ## Remove an embedding from the index
  if embedding_id in index.embeddings:
    index.embeddings.del(embedding_id)
    index.total_vectors -= 1
    index.last_updated = now()
    return true
  return false

proc searchIndex*(index: VectorIndex, query_vector: seq[float], 
                 max_results: int = 10, similarity_threshold: float = 0.7): seq[SearchResult] =
  ## Search the vector index for similar vectors
  return searchSimilarVectors(query_vector, index.embeddings, max_results, similarity_threshold)

proc getIndexStats*(index: VectorIndex): Table[string, string] =
  ## Get statistics about the vector index
  var stats = initTable[string, string]()
  stats["total_vectors"] = $index.total_vectors
  stats["dimension"] = $index.dimension
  stats["created"] = $index.created
  stats["last_updated"] = $index.last_updated
  return stats

# Advanced Search Features
proc hybridSearch*(query_text: string, query_vector: seq[float], chunks: seq[KnowledgeChunk],
                  embeddings: Table[string, VectorEmbedding], max_results: int = 10,
                  text_weight: float = 0.3, vector_weight: float = 0.7): seq[SearchResult] =
  ## Perform hybrid search combining text and vector similarity
  var results: seq[SearchResult]
  var chunk_map: Table[string, KnowledgeChunk]
  
  # Create chunk map for easy lookup
  for chunk in chunks:
    chunk_map[chunk.chunk_id] = chunk
  
  # Get vector search results
  let vector_results = searchSimilarVectors(query_vector, embeddings, max_results * 2, 0.5)
  
  # Combine with text search
  for vector_result in vector_results:
    if vector_result.chunk_id in chunk_map:
      let chunk = chunk_map[vector_result.chunk_id]
      let text_relevance = calculateTextRelevance(query_text.toLowerAscii(), chunk.content.toLowerAscii())
      
      # Calculate hybrid score
      let hybrid_score = (text_weight * text_relevance) + (vector_weight * vector_result.similarity_score)
      
      var search_result = SearchResult(
        chunk_id: vector_result.chunk_id,
        similarity_score: hybrid_score,
        rank: 0,
        metadata: chunk.metadata,
        confidence: (chunk.confidence + vector_result.confidence) / 2.0
      )
      results.add(search_result)
  
  # Sort by hybrid score
  results.sort(proc(a, b: SearchResult): int = 
    if a.similarity_score > b.similarity_score: -1
    elif a.similarity_score < b.similarity_score: 1
    else: 0
  )
  
  # Limit results and assign ranks
  var limited_results = results[0..<min(max_results, results.len)]
  for i in 0..<limited_results.len:
    limited_results[i].rank = i + 1
  
  return limited_results

proc filterResults*(results: seq[SearchResult], confidence_threshold: float = 0.5): seq[SearchResult] =
  ## Filter search results by confidence threshold
  var filtered: seq[SearchResult]
  for result in results:
    if result.confidence >= confidence_threshold:
      filtered.add(result)
  return filtered

proc rankResults*(results: seq[SearchResult], ranking_strategy: string = "similarity"): seq[SearchResult] =
  ## Rank search results using different strategies
  var ranked_results = results
  
  case ranking_strategy
  of "similarity":
    # Already sorted by similarity
    discard
  of "confidence":
    ranked_results.sort(proc(a, b: SearchResult): int = 
      if a.confidence > b.confidence: -1
      elif a.confidence < b.confidence: 1
      else: 0
    )
  of "hybrid":
    # Sort by combination of similarity and confidence
    ranked_results.sort(proc(a, b: SearchResult): int = 
      let score_a = (a.similarity_score * 0.7) + (a.confidence * 0.3)
      let score_b = (b.similarity_score * 0.7) + (b.confidence * 0.3)
      if score_a > score_b: -1
      elif score_a < score_b: 1
      else: 0
    )
  else:
    # Default to similarity ranking
    discard
  
  # Update ranks
  for i in 0..<ranked_results.len:
    ranked_results[i].rank = i + 1
  
  return ranked_results

when RUN_VECTOR_SEARCH_TESTS:
  import std/unittest
  
  suite "Vector Search Tests":
    test "Cosine Similarity":
      let vec1 = @[1.0, 0.0, 0.0]
      let vec2 = @[1.0, 0.0, 0.0]
      let vec3 = @[0.0, 1.0, 0.0]
      
      check cosineSimilarity(vec1, vec2) == 1.0
      check cosineSimilarity(vec1, vec3) == 0.0
      check cosineSimilarity(vec1, @[0.5, 0.0, 0.0]) > 0.9
    
    test "Euclidean Distance":
      let vec1 = @[0.0, 0.0, 0.0]
      let vec2 = @[1.0, 1.0, 1.0]
      
      check euclideanDistance(vec1, vec2) == sqrt(3.0)
      check euclideanDistance(vec1, vec1) == 0.0
    
    test "Vector Normalization":
      let vec = @[3.0, 4.0, 0.0]
      let normalized = normalizeVector(vec)
      
      check normalized.len == 3
      check abs(normalized[0] - 0.6) < 0.01
      check abs(normalized[1] - 0.8) < 0.01
      check normalized[2] == 0.0
    
    test "Text Relevance":
      let query = "artificial intelligence"
      let content1 = "This document discusses artificial intelligence and machine learning"
      let content2 = "This document is about cooking recipes"
      
      check calculateTextRelevance(query, content1) > 0.5
      check calculateTextRelevance(query, content2) < 0.5
    
    test "Vector Index Operations":
      var index = newVectorIndex("test_index")
      
      let embedding1 = newVectorEmbedding("emb1", "entity1", "test text", @[1.0, 0.0, 0.0], "test_model")
      let embedding2 = newVectorEmbedding("emb2", "entity2", "test text", @[0.0, 1.0, 0.0], "test_model")
      
      index.addEmbedding(embedding1)
      index.addEmbedding(embedding2)
      
      check index.total_vectors == 2
      check index.dimension == 3
      
      let results = index.searchIndex(@[1.0, 0.0, 0.0], 5, 0.5)
      check results.len > 0
      check results[0].chunk_id == "entity1"
      
      let removed = index.removeEmbedding("emb1")
      check removed == true
      check index.total_vectors == 1
    
    test "Search Result Ranking":
      var results: seq[SearchResult]
      results.add(SearchResult(chunk_id: "1", similarity_score: 0.5, rank: 0, metadata: initTable[string, string](), confidence: 0.8))
      results.add(SearchResult(chunk_id: "2", similarity_score: 0.9, rank: 0, metadata: initTable[string, string](), confidence: 0.6))
      
      let ranked = rankResults(results, "hybrid")
      check ranked.len == 2
      check ranked[0].rank == 1
      check ranked[1].rank == 2

when isMainModule:
  echo "Vector Search - Semantic Similarity and Knowledge Retrieval"
  echo "=========================================================="
  
  # Create test embeddings
  var index = newVectorIndex("demo_index")
  
  let embedding1 = newVectorEmbedding("emb1", "entity1", "artificial intelligence", @[1.0, 0.0, 0.0], "test_model")
  let embedding2 = newVectorEmbedding("emb2", "entity2", "machine learning", @[0.8, 0.2, 0.0], "test_model")
  let embedding3 = newVectorEmbedding("emb3", "entity3", "cooking recipes", @[0.0, 0.0, 1.0], "test_model")
  
  index.addEmbedding(embedding1)
  index.addEmbedding(embedding2)
  index.addEmbedding(embedding3)
  
  echo "Searching for 'AI' related content..."
  let results = index.searchIndex(@[1.0, 0.0, 0.0], 3, 0.5)
  
  echo "Found ", results.len, " results:"
  for result in results:
    echo "  Rank ", result.rank, ": ", result.chunk_id, " (similarity: ", result.similarity_score, ")"
  
  echo ""
  echo "Vector search demonstration completed." 