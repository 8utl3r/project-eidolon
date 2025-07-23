# Knowledge Synthesis
#
# This module implements knowledge synthesis algorithms for RAG system.
# Combines retrieved knowledge chunks into coherent responses with confidence scoring.

import std/[strutils, algorithm, tables, sets, times]
import ./types

const RUN_SYNTHESIS_TESTS* = true

type
  SynthesisStrategy* = enum
    summarization
    integration
    comparison
    extraction
    generation

  SynthesisResult* = object
    ## Result of knowledge synthesis
    content*: string
    confidence*: float
    sources*: seq[string]
    strategy_used*: SynthesisStrategy
    processing_time*: float
    metadata*: Table[string, string]

# Forward declarations
proc synthesizeSummarization*(chunks: seq[KnowledgeChunk], query_context: QueryContext): SynthesisResult
proc synthesizeIntegration*(chunks: seq[KnowledgeChunk], query_context: QueryContext): SynthesisResult
proc synthesizeComparison*(chunks: seq[KnowledgeChunk], query_context: QueryContext): SynthesisResult
proc synthesizeExtraction*(chunks: seq[KnowledgeChunk], query_context: QueryContext): SynthesisResult
proc synthesizeGeneration*(chunks: seq[KnowledgeChunk], query_context: QueryContext): SynthesisResult

# Core Synthesis Functions
proc synthesizeKnowledge*(chunks: seq[KnowledgeChunk], query_context: QueryContext, 
                         strategy: SynthesisStrategy = summarization): SynthesisResult =
  ## Synthesize knowledge from retrieved chunks
  let start_time = now()
  
  var synthesis_result = SynthesisResult(
    content: "",
    confidence: 0.0,
    sources: @[],
    strategy_used: strategy,
    processing_time: 0.0,
    metadata: initTable[string, string]()
  )
  
  case strategy
  of summarization:
    synthesis_result = synthesizeSummarization(chunks, query_context)
  of integration:
    synthesis_result = synthesizeIntegration(chunks, query_context)
  of comparison:
    synthesis_result = synthesizeComparison(chunks, query_context)
  of extraction:
    synthesis_result = synthesizeExtraction(chunks, query_context)
  of generation:
    synthesis_result = synthesizeGeneration(chunks, query_context)
  
  synthesis_result.processing_time = (now() - start_time).inSeconds.float
  return synthesis_result

proc synthesizeSummarization*(chunks: seq[KnowledgeChunk], query_context: QueryContext): SynthesisResult =
  ## Create a summary of the retrieved knowledge chunks
  var synthesis_result = SynthesisResult(
    content: "",
    confidence: 0.0,
    sources: @[],
    strategy_used: summarization,
    processing_time: 0.0,
    metadata: initTable[string, string]()
  )
  
  if chunks.len == 0:
    synthesis_result.content = "No relevant information found."
    synthesis_result.confidence = 0.0
    return synthesis_result
  
  # Extract key information from chunks
  var key_points: seq[string]
  var total_confidence = 0.0
  
  for chunk in chunks:
    synthesis_result.sources.add(chunk.source_id)
    total_confidence += chunk.confidence
    
    # Extract key sentences (simple approach)
    let sentences = chunk.content.split(". ")
    for sentence in sentences:
      if sentence.len > 20 and sentence.len < 200:  # Reasonable sentence length
        key_points.add(sentence.strip())
  
  # Create summary
  if key_points.len > 0:
    let summary_length = min(3, key_points.len)  # Top 3 key points
    synthesis_result.content = "Based on the retrieved information:\n\n"
    
    for i in 0..<summary_length:
      synthesis_result.content &= "• " & key_points[i] & ".\n"
    
    synthesis_result.content &= "\nThis information was synthesized from " & $chunks.len & " knowledge sources."
  else:
    synthesis_result.content = "The retrieved information could not be effectively summarized."
  
  synthesis_result.confidence = total_confidence / chunks.len.float
  return synthesis_result

proc synthesizeIntegration*(chunks: seq[KnowledgeChunk], query_context: QueryContext): SynthesisResult =
  ## Integrate information from multiple sources into a coherent response
  var synthesis_result = SynthesisResult(
    content: "",
    confidence: 0.0,
    sources: @[],
    strategy_used: integration,
    processing_time: 0.0,
    metadata: initTable[string, string]()
  )
  
  if chunks.len == 0:
    synthesis_result.content = "No information available for integration."
    synthesis_result.confidence = 0.0
    return synthesis_result
  
  # Group chunks by source for integration
  var source_groups: Table[string, seq[KnowledgeChunk]]
  for chunk in chunks:
    if not source_groups.hasKey(chunk.source_id):
      source_groups[chunk.source_id] = @[]
    source_groups[chunk.source_id].add(chunk)
    synthesis_result.sources.add(chunk.source_id)
  
  # Integrate information from each source
  synthesis_result.content = "Integrated information from multiple sources:\n\n"
  var total_confidence = 0.0
  
  for source_id, source_chunks in source_groups:
    synthesis_result.content &= "**Source: " & source_id & "**\n"
    
    var source_content = ""
    var source_confidence = 0.0
    
    for chunk in source_chunks:
      source_content &= chunk.content & " "
      source_confidence += chunk.confidence
    
    synthesis_result.content &= source_content.strip() & "\n\n"
    total_confidence += source_confidence / source_chunks.len.float
  
  synthesis_result.confidence = total_confidence / source_groups.len.float
  return synthesis_result

proc synthesizeComparison*(chunks: seq[KnowledgeChunk], query_context: QueryContext): SynthesisResult =
  ## Compare and contrast information from different sources
  var synthesis_result = SynthesisResult(
    content: "",
    confidence: 0.0,
    sources: @[],
    strategy_used: comparison,
    processing_time: 0.0,
    metadata: initTable[string, string]()
  )
  
  if chunks.len < 2:
    synthesis_result.content = "Insufficient information for comparison (need at least 2 sources)."
    synthesis_result.confidence = 0.0
    return synthesis_result
  
  # Group by source for comparison
  var source_groups: Table[string, seq[KnowledgeChunk]]
  for chunk in chunks:
    if not source_groups.hasKey(chunk.source_id):
      source_groups[chunk.source_id] = @[]
    source_groups[chunk.source_id].add(chunk)
    synthesis_result.sources.add(chunk.source_id)
  
  synthesis_result.content = "Comparison of information across sources:\n\n"
  var total_confidence = 0.0
  
  for source_id, source_chunks in source_groups:
    synthesis_result.content &= "**" & source_id & ":**\n"
    
    var source_summary = ""
    var source_confidence = 0.0
    
    for chunk in source_chunks:
      source_summary &= chunk.content & " "
      source_confidence += chunk.confidence
    
    synthesis_result.content &= source_summary.strip() & "\n\n"
    total_confidence += source_confidence / source_chunks.len.float
  
  synthesis_result.content &= "**Key Differences:**\n"
  synthesis_result.content &= "• Information varies across " & $source_groups.len & " sources\n"
  synthesis_result.content &= "• Confidence levels range from " & $(total_confidence / source_groups.len.float) & "\n"
  
  synthesis_result.confidence = total_confidence / source_groups.len.float
  return synthesis_result

proc synthesizeExtraction*(chunks: seq[KnowledgeChunk], query_context: QueryContext): SynthesisResult =
  ## Extract specific information based on the query
  var synthesis_result = SynthesisResult(
    content: "",
    confidence: 0.0,
    sources: @[],
    strategy_used: extraction,
    processing_time: 0.0,
    metadata: initTable[string, string]()
  )
  
  if chunks.len == 0:
    synthesis_result.content = "No information available for extraction."
    synthesis_result.confidence = 0.0
    return synthesis_result
  
  # Extract information based on query keywords
  let query_words = query_context.query_text.toLowerAscii().splitWhitespace().toHashSet()
  var extracted_info: seq[string]
  var total_confidence = 0.0
  
  for chunk in chunks:
    synthesis_result.sources.add(chunk.source_id)
    total_confidence += chunk.confidence
    
    let content_lower = chunk.content.toLowerAscii()
    var relevance_score = 0.0
    
    for word in query_words:
      if word in content_lower:
        relevance_score += 1.0
    
    if relevance_score > 0:
      extracted_info.add(chunk.content)
  
  if extracted_info.len > 0:
    synthesis_result.content = "Extracted relevant information:\n\n"
    for info in extracted_info:
      synthesis_result.content &= "• " & info & "\n"
  else:
    synthesis_result.content = "No specific information could be extracted based on the query."
  
  synthesis_result.confidence = total_confidence / chunks.len.float
  return synthesis_result

proc synthesizeGeneration*(chunks: seq[KnowledgeChunk], query_context: QueryContext): SynthesisResult =
  ## Generate new content based on retrieved information
  var synthesis_result = SynthesisResult(
    content: "",
    confidence: 0.0,
    sources: @[],
    strategy_used: generation,
    processing_time: 0.0,
    metadata: initTable[string, string]()
  )
  
  if chunks.len == 0:
    synthesis_result.content = "No information available for content generation."
    synthesis_result.confidence = 0.0
    return synthesis_result
  
  # Generate content based on retrieved information
  var total_confidence = 0.0
  var key_concepts: seq[string]
  
  for chunk in chunks:
    synthesis_result.sources.add(chunk.source_id)
    total_confidence += chunk.confidence
    
    # Extract key concepts (simple approach)
    let words = chunk.content.splitWhitespace()
    for word in words:
      if word.len > 4 and word.len < 15:  # Reasonable word length
        key_concepts.add(word.toLowerAscii())
  
  # Remove duplicates and get most common concepts
  var concept_counts: Table[string, int]
  for concept_word in key_concepts:
    if not concept_counts.hasKey(concept_word):
      concept_counts[concept_word] = 0
    concept_counts[concept_word] += 1
  
  # Generate content based on key concepts
  synthesis_result.content = "Based on the analysis of " & $chunks.len & " knowledge sources:\n\n"
  synthesis_result.content &= "The retrieved information covers the following key areas:\n"
  
  var sorted_concepts: seq[tuple[concept_word: string, count: int]]
  for concept_word, count in concept_counts:
    sorted_concepts.add((concept_word, count))
  
  # Sort by frequency
  sorted_concepts.sort(proc(a, b: tuple[concept_word: string, count: int]): int = 
    if a.count > b.count: -1
    elif a.count < b.count: 1
    else: 0
  )
  
  # Show top concepts
  let top_concepts = sorted_concepts[0..<min(5, sorted_concepts.len)]
  for concept_info in top_concepts:
    synthesis_result.content &= "• " & concept_info.concept_word & " (mentioned " & $concept_info.count & " times)\n"
  
  synthesis_result.content &= "\nThis information provides a foundation for understanding the topic."
  synthesis_result.confidence = total_confidence / chunks.len.float
  return synthesis_result

# Advanced Synthesis Features
proc calculateSynthesisConfidence*(chunks: seq[KnowledgeChunk], strategy: SynthesisStrategy): float =
  ## Calculate confidence in synthesis based on chunk quality and strategy
  if chunks.len == 0:
    return 0.0
  
  var base_confidence = 0.0
  for chunk in chunks:
    base_confidence += chunk.confidence
  
  let avg_confidence = base_confidence / chunks.len.float
  
  # Adjust confidence based on strategy
  case strategy
  of summarization:
    return avg_confidence * 0.9  # Summarization can lose some detail
  of integration:
    return avg_confidence * 0.8  # Integration may introduce inconsistencies
  of comparison:
    return avg_confidence * 0.85  # Comparison is generally reliable
  of extraction:
    return avg_confidence * 0.95  # Extraction is very reliable
  of generation:
    return avg_confidence * 0.7   # Generation introduces more uncertainty

proc validateSynthesis*(synthesis: SynthesisResult, original_chunks: seq[KnowledgeChunk]): bool =
  ## Validate that synthesis is consistent with original chunks
  if synthesis.confidence < 0.3:
    return false
  
  if synthesis.sources.len == 0:
    return false
  
  # Check that all sources in synthesis exist in original chunks
  var chunk_sources: HashSet[string]
  for chunk in original_chunks:
    chunk_sources.incl(chunk.source_id)
  
  for source in synthesis.sources:
    if source notin chunk_sources:
      return false
  
  return true

proc enhanceSynthesis*(synthesis: var SynthesisResult, additional_context: string) =
  ## Enhance synthesis with additional context
  if additional_context.len > 0:
    synthesis.content &= "\n\n**Additional Context:**\n" & additional_context
    synthesis.metadata["enhanced"] = "true"
    synthesis.metadata["additional_context"] = additional_context

# Synthesis Pipeline
proc runSynthesisPipeline*(chunks: seq[KnowledgeChunk], query_context: QueryContext): seq[SynthesisResult] =
  ## Run multiple synthesis strategies and return results
  var results: seq[SynthesisResult]
  
  let strategies = @[summarization, integration, comparison, extraction, generation]
  
  for strategy in strategies:
    let synthesis = synthesizeKnowledge(chunks, query_context, strategy)
    if validateSynthesis(synthesis, chunks):
      results.add(synthesis)
  
  return results

proc selectBestSynthesis*(syntheses: seq[SynthesisResult]): SynthesisResult =
  ## Select the best synthesis based on confidence and content quality
  if syntheses.len == 0:
    return SynthesisResult(
      content: "No valid synthesis available.",
      confidence: 0.0,
      sources: @[],
      strategy_used: summarization,
      processing_time: 0.0,
      metadata: initTable[string, string]()
    )
  
  # Sort by confidence and content length (prefer longer, more confident results)
  var sorted_syntheses = syntheses
  sorted_syntheses.sort(proc(a, b: SynthesisResult): int = 
    let score_a = a.confidence * 0.7 + (a.content.len.float / 1000.0) * 0.3
    let score_b = b.confidence * 0.7 + (b.content.len.float / 1000.0) * 0.3
    if score_a > score_b: -1
    elif score_a < score_b: 1
    else: 0
  )
  
  return sorted_syntheses[0]

when RUN_SYNTHESIS_TESTS:
  import std/unittest
  
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
      
      check synthesis.content.contains("Integrated information")
      check synthesis.strategy_used == integration
      check synthesis.sources.len == 2
    
    test "Comparison Strategy":
      var chunks: seq[KnowledgeChunk]
      chunks.add(newKnowledgeChunk("chunk1", "source1", "AI is computer science."))
      chunks.add(newKnowledgeChunk("chunk2", "source2", "AI is machine learning."))
      
      let query_context = newQueryContext("query1", "Compare AI definitions")
      let synthesis = synthesizeComparison(chunks, query_context)
      
      check synthesis.content.contains("Comparison")
      check synthesis.strategy_used == comparison
    
    test "Extraction Strategy":
      var chunks: seq[KnowledgeChunk]
      chunks.add(newKnowledgeChunk("chunk1", "source1", "Artificial intelligence is computer science."))
      
      let query_context = newQueryContext("query1", "What is artificial intelligence?")
      let synthesis = synthesizeExtraction(chunks, query_context)
      
      check synthesis.content.contains("Extracted")
      check synthesis.strategy_used == extraction
    
    test "Generation Strategy":
      var chunks: seq[KnowledgeChunk]
      chunks.add(newKnowledgeChunk("chunk1", "source1", "AI computer science field."))
      
      let query_context = newQueryContext("query1", "Generate content about AI")
      let synthesis = synthesizeGeneration(chunks, query_context)
      
      check synthesis.content.contains("Based on the analysis")
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
      chunks.add(newKnowledgeChunk("chunk1", "source1", "Test content"))
      chunks[0].confidence = 0.8
      
      let confidence = calculateSynthesisConfidence(chunks, summarization)
      check confidence > 0.0
      check confidence <= 1.0
    
    test "Synthesis Validation":
      var chunks: seq[KnowledgeChunk]
      chunks.add(newKnowledgeChunk("chunk1", "source1", "Test content"))
      
      let synthesis = synthesizeKnowledge(chunks, newQueryContext("query1", "test"), summarization)
      let is_valid = validateSynthesis(synthesis, chunks)
      check is_valid == true

when isMainModule:
  echo "Knowledge Synthesis - Information Integration and Response Generation"
  echo "===================================================================="
  
  # Create test knowledge chunks
  var chunks: seq[KnowledgeChunk]
  chunks.add(newKnowledgeChunk("chunk1", "wikipedia", "Artificial intelligence is a field of computer science that aims to create intelligent machines."))
  chunks.add(newKnowledgeChunk("chunk2", "research_paper", "Machine learning is a subset of artificial intelligence that enables computers to learn without explicit programming."))
  chunks.add(newKnowledgeChunk("chunk3", "textbook", "AI systems can perform tasks that typically require human intelligence, such as visual perception and decision-making."))
  
  # Set confidence scores
  chunks[0].confidence = 0.9
  chunks[1].confidence = 0.8
  chunks[2].confidence = 0.7
  
  let query_context = newQueryContext("demo_query", "What is artificial intelligence?")
  
  echo "Running synthesis pipeline..."
  let syntheses = runSynthesisPipeline(chunks, query_context)
  
  echo "Generated ", syntheses.len, " synthesis results:"
  for i, synthesis in syntheses:
    echo "  ", i+1, ". ", synthesis.strategy_used, " (confidence: ", synthesis.confidence, ")"
    echo "     ", synthesis.content[0..<min(100, synthesis.content.len)], "..."
    echo ""
  
  let best_synthesis = selectBestSynthesis(syntheses)
  echo "Best synthesis (", best_synthesis.strategy_used, "):"
  echo best_synthesis.content
  
  echo ""
  echo "Knowledge synthesis demonstration completed." 