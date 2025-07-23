# RAG System Tests
#
# This module tests the complete RAG (Retrieval Augmented Generation) system.

import std/[unittest, tables, math, strutils, json]
import ../src/rag/types
import ../src/rag/vector_search
import ../src/rag/synthesis
import ../src/rag/rag_engine

suite "RAG Types Tests":
  test "Knowledge Source Creation":
    let source = newKnowledgeSource("test_source", "document", "Test Source", "http://test.com")
    check source.source_id == "test_source"
    check source.source_type == "document"
    check source.name == "Test Source"
    check source.url == "http://test.com"
    check source.is_active == true
    check source.reliability_score == 0.5
  
  test "Vector Embedding Creation":
    let vector = @[1.0, 0.0, 0.0]
    let embedding = newVectorEmbedding("emb1", "entity1", "test text", vector, "test_model")
    check embedding.embedding_id == "emb1"
    check embedding.source_entity_id == "entity1"
    check embedding.source_text == "test text"
    check embedding.vector == vector
    check embedding.embedding_model == "test_model"
    check embedding.confidence == 0.8
  
  test "Knowledge Chunk Creation":
    var chunk = newKnowledgeChunk("chunk1", "source1", "Test content")
    check chunk.chunk_id == "chunk1"
    check chunk.source_id == "source1"
    check chunk.content == "Test content"
    check chunk.confidence == 0.5
    # Note: embedding is Option[VectorEmbedding] and defaults to None
  
  test "Query Context Creation":
    let context = newQueryContext("query1", "What is AI?")
    check context.query_id == "query1"
    check context.query_text == "What is AI?"
    check context.search_parameters.max_results == 10
    check context.search_parameters.similarity_threshold == 0.7
  
  test "Search Parameters Creation":
    let params = newSearchParameters()
    check params.max_results == 10
    check params.similarity_threshold == 0.7
    check params.confidence_threshold == 0.5
    check params.include_metadata == true
  
  test "Knowledge Synthesis Creation":
    let context = newQueryContext("query1", "test")
    let synthesis = newKnowledgeSynthesis("synth1", context)
    check synthesis.synthesis_id == "synth1"
    check synthesis.query_context.query_id == "query1"
    check synthesis.confidence == 0.0
    check synthesis.synthesis_strategy == "summarization"
  
  test "Embedding Model Creation":
    let model = newEmbeddingModel("model1", "Test Model", "sentence_transformers", 768)
    check model.model_id == "model1"
    check model.model_name == "Test Model"
    check model.model_type == "sentence_transformers"
    check model.dimensions == 768
    check model.is_active == true
  
  test "RAG Configuration Creation":
    let config = newRAGConfiguration()
    check config.config_id == "default_rag_config"
    check config.default_embedding_model == "sentence_transformers"
    check config.default_similarity_threshold == 0.7
    check config.cache_enabled == true

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

suite "Knowledge Synthesis Tests":
  test "Summarization Strategy":
    var chunks: seq[KnowledgeChunk]
    chunks.add(newKnowledgeChunk("chunk1", "source1", "Artificial intelligence is a field of computer science."))
    chunks.add(newKnowledgeChunk("chunk2", "source2", "Machine learning is a subset of artificial intelligence."))
    
    let query_context = newQueryContext("query1", "What is AI?")
    let synthesis = synthesizeSummarization(chunks, query_context)
    
    check synthesis.content.len > 0
    check synthesis.confidence > 0.0
    check synthesis.strategy_used == summarization
    check synthesis.sources.len == 2
  
  test "Integration Strategy":
    var chunks: seq[KnowledgeChunk]
    chunks.add(newKnowledgeChunk("chunk1", "source1", "AI is computer science."))
    chunks.add(newKnowledgeChunk("chunk2", "source2", "ML is subset of AI."))
    
    let query_context = newQueryContext("query1", "Explain AI and ML")
    let synthesis = synthesizeIntegration(chunks, query_context)
    
    check contains(synthesis.content, "Integrated information")
    check synthesis.strategy_used == integration
    check synthesis.sources.len == 2
  
  test "Comparison Strategy":
    var chunks: seq[KnowledgeChunk]
    chunks.add(newKnowledgeChunk("chunk1", "source1", "AI is computer science."))
    chunks.add(newKnowledgeChunk("chunk2", "source2", "AI is machine learning."))
    
    let query_context = newQueryContext("query1", "Compare AI definitions")
    let synthesis = synthesizeComparison(chunks, query_context)
    
    check contains(synthesis.content, "Comparison")
    check synthesis.strategy_used == comparison
  
  test "Extraction Strategy":
    var chunks: seq[KnowledgeChunk]
    chunks.add(newKnowledgeChunk("chunk1", "source1", "Artificial intelligence is computer science."))
    
    let query_context = newQueryContext("query1", "What is artificial intelligence?")
    let synthesis = synthesizeExtraction(chunks, query_context)
    
    check contains(synthesis.content, "Extracted")
    check synthesis.strategy_used == extraction
  
  test "Generation Strategy":
    var chunks: seq[KnowledgeChunk]
    chunks.add(newKnowledgeChunk("chunk1", "source1", "AI computer science field."))
    
    let query_context = newQueryContext("query1", "Generate content about AI")
    let synthesis = synthesizeGeneration(chunks, query_context)
    
    check contains(synthesis.content, "Based on the analysis")
    check synthesis.strategy_used == generation
  
  test "Synthesis Pipeline":
    var chunks: seq[KnowledgeChunk]
    chunks.add(newKnowledgeChunk("chunk1", "source1", "AI is computer science."))
    chunks.add(newKnowledgeChunk("chunk2", "source2", "ML is AI subset."))
    
    let query_context = newQueryContext("query1", "Explain AI")
    let syntheses = runSynthesisPipeline(chunks, query_context)
    
    check syntheses.len > 0
    
    let best = selectBestSynthesis(syntheses)
    check best.confidence > 0.0
    check best.content.len > 0
  
  test "Confidence Calculation":
    var chunks: seq[KnowledgeChunk]
    var chunk = newKnowledgeChunk("chunk1", "source1", "Test content")
    chunk.confidence = 0.8
    chunks.add(chunk)
    let confidence = calculateSynthesisConfidence(chunks, summarization)
    check confidence > 0.0
    check confidence <= 1.0
  
  test "Synthesis Validation":
    var chunks: seq[KnowledgeChunk]
    chunks.add(newKnowledgeChunk("chunk1", "source1", "Test content"))
    
    let synthesis = synthesizeKnowledge(chunks, newQueryContext("query1", "test"), summarization)
    let is_valid = validateSynthesis(synthesis, chunks)
    check is_valid == true

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
    
    let queries = @["What is artificial intelligence?", "What is machine learning?"]
    let responses = engine.batchQuery(queries, 5, 0.1)
    
    check responses.len == 2
    check responses[0].query == "What is artificial intelligence?"
    check responses[1].query == "What is machine learning?"
  
  test "Vector Query":
    var engine = newRAGEngine("test_engine")
    
    # Add test embeddings
    let embedding1 = newVectorEmbedding("emb1", "entity1", "AI text", @[1.0, 0.0, 0.0], "test_model")
    let embedding2 = newVectorEmbedding("emb2", "entity2", "ML text", @[0.0, 1.0, 0.0], "test_model")
    
    engine.vector_index.addEmbedding(embedding1)
    engine.vector_index.addEmbedding(embedding2)
    
    let results = engine.vectorQuery(@[1.0, 0.0, 0.0], 5, 0.5)
    check results.len > 0
    check results[0].chunk_id == "entity1"
  
  test "Knowledge Base Export/Import":
    var engine = newRAGEngine("test_engine")
    
    # Add test data
    let source = newKnowledgeSource("source1", "document", "Test Source", "http://test.com")
    engine.addKnowledgeSource(source)
    
    var chunk = newKnowledgeChunk("chunk1", "source1", "Test content")
    engine.addKnowledgeChunk(chunk)
    
    # Export
    let export_data = engine.exportKnowledgeBase()
    check export_data["engine_id"].getStr() == "test_engine"
    check export_data["knowledge_sources"].hasKey("source1")
    check export_data["knowledge_chunks"].hasKey("chunk1")
    
    # Import to new engine
    var new_engine = newRAGEngine("import_engine")
    let import_success = new_engine.importKnowledgeBase(export_data)
    check import_success == true
    check new_engine.knowledge_sources.len == 1
    check new_engine.knowledge_chunks.len == 1

suite "RAG Integration Tests":
  test "Complete RAG Pipeline":
    var engine = newRAGEngine("integration_test")
    
    # Setup knowledge base
    let source1 = newKnowledgeSource("wikipedia", "document", "Wikipedia", "https://wikipedia.org")
    let source2 = newKnowledgeSource("research", "api", "Research Papers", "https://arxiv.org")
    
    engine.addKnowledgeSource(source1)
    engine.addKnowledgeSource(source2)
    
    var chunk1 = newKnowledgeChunk("chunk1", "wikipedia", "Artificial intelligence is a field of computer science that focuses on creating intelligent machines.")
    var chunk2 = newKnowledgeChunk("chunk2", "research", "Machine learning enables computers to learn from data and improve performance.")
    var chunk3 = newKnowledgeChunk("chunk3", "wikipedia", "AI systems can perform tasks requiring human intelligence and reasoning.")
    
    chunk1.confidence = 0.9
    chunk2.confidence = 0.8
    chunk3.confidence = 0.7
    
    engine.addKnowledgeChunk(chunk1)
    engine.addKnowledgeChunk(chunk2)
    engine.addKnowledgeChunk(chunk3)
    
    # Test different synthesis strategies
    let strategies = @[summarization, integration, comparison, extraction, generation]
    
    for strategy in strategies:
      let response = engine.query("What is artificial intelligence?", 5, 0.1, strategy)
      check response.query == "What is artificial intelligence?"
      check response.retrieved_chunks.len > 0
      check response.confidence > 0.0
      check response.synthesis.strategy_used == strategy
  
  test "Multi-Source Knowledge Integration":
    var engine = newRAGEngine("multi_source_test")
    
    # Add multiple sources with different content
    let sources = @[
      ("wikipedia", "Wikipedia", "Artificial intelligence is computer science field."),
      ("research", "Research Papers", "AI involves machine learning algorithms."),
      ("textbook", "Textbook", "Artificial intelligence mimics human cognition.")
    ]
    
    for i, (source_id, name, content) in sources:
      let source = newKnowledgeSource(source_id, "document", name, "http://" & source_id & ".com")
      engine.addKnowledgeSource(source)
      
      var chunk = newKnowledgeChunk("chunk" & $i, source_id, content)
      chunk.confidence = 0.8 - (i.float * 0.1)
      engine.addKnowledgeChunk(chunk)
    
    # Test integration strategy
    let response = engine.query("artificial intelligence", 10, 0.1, integration)
    check response.retrieved_chunks.len >= 2  # At least 2 chunks should match
    check response.synthesis.sources.len >= 2  # At least 2 sources should be used
    check response.confidence > 0.0
  
  test "Confidence Scoring":
    var engine = newRAGEngine("confidence_test")
    
    # Add chunks with varying confidence levels
    let chunks = @[
      ("chunk1", "source1", "High confidence content", 0.9),
      ("chunk2", "source2", "Medium confidence content", 0.6),
      ("chunk3", "source3", "Low confidence content", 0.3)
    ]
    
    for (chunk_id, source_id, content, confidence) in chunks:
      let source = newKnowledgeSource(source_id, "document", "Source " & source_id, "http://" & source_id & ".com")
      engine.addKnowledgeSource(source)
      
      var chunk = newKnowledgeChunk(chunk_id, source_id, content)
      chunk.confidence = confidence
      engine.addKnowledgeChunk(chunk)
    
    let response = engine.query("High confidence content", 5, 0.1)
    check response.confidence > 0.0
    check response.confidence <= 1.0

when isMainModule:
  echo "Running RAG System Tests..." 