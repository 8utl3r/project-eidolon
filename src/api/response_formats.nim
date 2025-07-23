# Response Format System
#
# This module implements the A/B/C response format system for Project Eidolon:
# A: External sources only (RAG-style)
# B: Database-only responses
# C: Synthesis of both sources

import std/[times, tables, options, json, strutils, sequtils]
import ../types
import ../rag/types
import ../rag/rag_engine
import ../entities/manager
import ../strain/types

type
  ResponseFormat* = enum
    ## Response format types
    external_only,    # A: External sources only
    database_only,    # B: Database-only responses
    synthesis         # C: Synthesis of both sources

  ResponseSource* = object
    ## Information about a response source
    source_type*: string  # "external", "database", "synthesis"
    content*: string      # The actual response content
    confidence*: float    # Confidence score (0.0-1.0)
    metadata*: JsonNode   # Additional metadata
    timestamp*: DateTime  # When the response was generated

  FormattedResponse* = object
    ## Complete formatted response with all sources
    query*: string
    format*: ResponseFormat
    primary_response*: ResponseSource
    secondary_responses*: seq[ResponseSource]
    synthesis_notes*: string
    total_confidence*: float
    response_time*: float
    sources_used*: seq[string]

  ResponseFormatter* = object
    ## Main response formatter for A/B/C system
    rag_engine*: RAGEngine
    entity_manager*: EntityManager
    format_preferences*: Table[string, ResponseFormat]
    confidence_thresholds*: Table[ResponseFormat, float]
    synthesis_rules*: seq[string]

proc newResponseFormatter*(rag_engine: RAGEngine, entity_manager: EntityManager): ResponseFormatter =
  ## Create a new response formatter
  var formatter = ResponseFormatter(
    rag_engine: rag_engine,
    entity_manager: entity_manager,
    format_preferences: initTable[string, ResponseFormat](),
    confidence_thresholds: initTable[ResponseFormat, float](),
    synthesis_rules: @[]
  )
  
  # Set default confidence thresholds
  formatter.confidence_thresholds[external_only] = 0.7
  formatter.confidence_thresholds[database_only] = 0.8
  formatter.confidence_thresholds[synthesis] = 0.75
  
  # Set default synthesis rules
  formatter.synthesis_rules = @[
    "Prioritize database information when confidence is high",
    "Use external sources to fill gaps in database knowledge",
    "Resolve conflicts by favoring more recent information",
    "Combine complementary information from both sources"
  ]
  
  return formatter

proc getExternalResponse*(formatter: ResponseFormatter, query: string): ResponseSource =
  ## Get response from external sources only (Format A)
  let start_time = getTime()
  
  # Use RAG engine to get external response
  let rag_response = formatter.rag_engine.query(query)
  
  let response_time = (getTime() - start_time).inMilliseconds.float / 1000.0
  
  return ResponseSource(
    source_type: "external",
    content: rag_response.synthesis.content,
    confidence: rag_response.confidence,
    metadata: %*rag_response.metadata,
    timestamp: now()
  )

proc getDatabaseResponse*(formatter: ResponseFormatter, query: string): ResponseSource =
  ## Get response from database only (Format B)
  let start_time = getTime()
  
  # Search knowledge graph for relevant entities
  let entities = formatter.entity_manager.searchEntities(query)
  
  # Build response from database entities
  var content = ""
  var total_confidence = 0.0
  var entity_count = 0
  
  for entity in entities:
    if entity.strain.amplitude > 0.5:  # Only include high-confidence entities
      content.add(entity.name & ": " & entity.description & "\n")
      total_confidence += entity.strain.amplitude
      entity_count += 1
  
  if entity_count > 0:
    total_confidence = total_confidence / entity_count.float
  else:
    content = "No relevant information found in database."
    total_confidence = 0.0
  
  let response_time = (getTime() - start_time).inMilliseconds.float / 1000.0
  
  # Create metadata
  var metadata = %*{
    "entities_found": entity_count,
    "strain_average": total_confidence,
    "response_time": response_time
  }
  
  return ResponseSource(
    source_type: "database",
    content: content,
    confidence: total_confidence,
    metadata: metadata,
    timestamp: now()
  )

proc getSynthesisResponse*(formatter: ResponseFormatter, query: string): ResponseSource =
  ## Get synthesized response from both sources (Format C)
  let start_time = getTime()
  
  # Get responses from both sources
  let external_response = formatter.getExternalResponse(query)
  let database_response = formatter.getDatabaseResponse(query)
  
  # Synthesize the responses
  var synthesis_content = ""
  var synthesis_confidence = 0.0
  
  # Start with database information if it has high confidence
  if database_response.confidence > 0.7:
    synthesis_content.add("Based on our knowledge base:\n")
    synthesis_content.add(database_response.content)
    synthesis_content.add("\n\n")
    synthesis_confidence += database_response.confidence * 0.6
  
  # Add external information to complement or fill gaps
  if external_response.confidence > 0.6:
    synthesis_content.add("Additional information from external sources:\n")
    synthesis_content.add(external_response.content)
    synthesis_confidence += external_response.confidence * 0.4
  
  # If neither source has good confidence, use the better one
  if synthesis_confidence < 0.5:
    if external_response.confidence > database_response.confidence:
      synthesis_content = "External information: " & external_response.content
      synthesis_confidence = external_response.confidence
    else:
      synthesis_content = "Database information: " & database_response.content
      synthesis_confidence = database_response.confidence
  
  let response_time = (getTime() - start_time).inMilliseconds.float / 1000.0
  
  # Create metadata
  var metadata = %*{
    "external_confidence": external_response.confidence,
    "database_confidence": database_response.confidence,
    "synthesis_confidence": synthesis_confidence,
    "response_time": response_time
  }
  
  return ResponseSource(
    source_type: "synthesis",
    content: synthesis_content,
    confidence: synthesis_confidence,
    metadata: metadata,
    timestamp: now()
  )

proc formatResponse*(formatter: ResponseFormatter, query: string, format: ResponseFormat): FormattedResponse =
  ## Format a response according to the specified format
  let start_time = getTime()
  
  var primary_response: ResponseSource
  var secondary_responses: seq[ResponseSource] = @[]
  var synthesis_notes = ""
  
  case format:
  of external_only:
    primary_response = formatter.getExternalResponse(query)
    synthesis_notes = "Response generated using external sources only."
  
  of database_only:
    primary_response = formatter.getDatabaseResponse(query)
    synthesis_notes = "Response generated using database knowledge only."
  
  of synthesis:
    primary_response = formatter.getSynthesisResponse(query)
    # Get individual responses for comparison
    secondary_responses.add(formatter.getExternalResponse(query))
    secondary_responses.add(formatter.getDatabaseResponse(query))
    synthesis_notes = "Response synthesized from both external and database sources."
  
  let response_time = (getTime() - start_time).inMilliseconds.float / 1000.0
  
  # Determine sources used
  var sources_used: seq[string] = @[]
  case format:
  of external_only:
    sources_used.add("external")
  of database_only:
    sources_used.add("database")
  of synthesis:
    sources_used.add("external")
    sources_used.add("database")
  
  return FormattedResponse(
    query: query,
    format: format,
    primary_response: primary_response,
    secondary_responses: secondary_responses,
    synthesis_notes: synthesis_notes,
    total_confidence: primary_response.confidence,
    response_time: response_time,
    sources_used: sources_used
  )

proc setFormatPreference*(formatter: var ResponseFormatter, user_id: string, format: ResponseFormat) =
  ## Set a user's preferred response format
  formatter.format_preferences[user_id] = format

proc getFormatPreference*(formatter: ResponseFormatter, user_id: string): ResponseFormat =
  ## Get a user's preferred response format (defaults to synthesis)
  return formatter.format_preferences.getOrDefault(user_id, synthesis)

proc setConfidenceThreshold*(formatter: var ResponseFormatter, format: ResponseFormat, threshold: float) =
  ## Set confidence threshold for a response format
  formatter.confidence_thresholds[format] = threshold

proc addSynthesisRule*(formatter: var ResponseFormatter, rule: string) =
  ## Add a synthesis rule
  formatter.synthesis_rules.add(rule)

proc getResponseSummary*(response: FormattedResponse): string =
  ## Get a summary of the formatted response
  var summary = "Response Format: "
  
  case response.format:
  of external_only:
    summary.add("A (External Sources Only)")
  of database_only:
    summary.add("B (Database Only)")
  of synthesis:
    summary.add("C (Synthesis)")
  
  summary.add("\nConfidence: " & formatFloat(response.total_confidence, precision = 2))
  summary.add("\nResponse Time: " & formatFloat(response.response_time, precision = 3) & "s")
  summary.add("\nSources Used: " & response.sources_used.join(", "))
  
  return summary 