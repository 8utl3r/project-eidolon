# Response Format System Test Suite
#
# This module tests the A/B/C response format system including
# external-only, database-only, and synthesis responses.

import std/[times, tables, options, json, strutils, sequtils, unittest]
import ../src/api/response_formats
import ../src/rag/types
import ../src/rag/rag_engine
import ../src/entities/manager
import ../src/types

const RUN_RESPONSE_FORMAT_TESTS* = true  # Set to false for performance

when RUN_RESPONSE_FORMAT_TESTS:
  suite "Response Format System Tests":
    setup:
      # Create mock RAG engine
      var mock_rag = newRAGEngine("test_engine")
      
      # Create mock entity manager
      var mock_entity_manager = newEntityManager()
      
      # Create response formatter
      var formatter = newResponseFormatter(mock_rag, mock_entity_manager)
    
    test "Response Format Enum Values":
      ## Test that response format enum has correct values
      check external_only == ResponseFormat(0)
      check database_only == ResponseFormat(1)
      check synthesis == ResponseFormat(2)
    
    test "Response Formatter Creation":
      ## Test response formatter initialization
      check formatter.confidence_thresholds[external_only] == 0.7
      check formatter.confidence_thresholds[database_only] == 0.8
      check formatter.confidence_thresholds[synthesis] == 0.75
      check formatter.synthesis_rules.len == 4
    
    test "External Response Generation":
      ## Test external-only response format (Format A)
      let query = "What is quantum physics?"
      let response = formatter.getExternalResponse(query)
      
      check response.source_type == "external"
      check response.content.len > 0
      check response.confidence >= 0.0 and response.confidence <= 1.0
      check response.timestamp > now() - 10.seconds
    
    test "Database Response Generation":
      ## Test database-only response format (Format B)
      let query = "Tell me about mathematics"
      let response = formatter.getDatabaseResponse(query)
      
      check response.source_type == "database"
      check response.content.len > 0
      check response.confidence >= 0.0 and response.confidence <= 1.0
      check response.metadata.hasKey("entities_found")
      check response.metadata.hasKey("strain_average")
      check response.metadata.hasKey("response_time")
    
    test "Synthesis Response Generation":
      ## Test synthesis response format (Format C)
      let query = "Explain artificial intelligence"
      let response = formatter.getSynthesisResponse(query)
      
      check response.source_type == "synthesis"
      check response.content.len > 0
      check response.confidence >= 0.0 and response.confidence <= 1.0
      check response.metadata.hasKey("external_confidence")
      check response.metadata.hasKey("database_confidence")
      check response.metadata.hasKey("synthesis_confidence")
    
    test "Formatted Response Creation":
      ## Test complete formatted response creation
      let query = "What is calculus?"
      
      # Test external-only format
      let external_response = formatter.formatResponse(query, external_only)
      check external_response.query == query
      check external_response.format == external_only
      check external_response.sources_used == @["external"]
      check external_response.synthesis_notes.contains("External Sources Only")
      
      # Test database-only format
      let database_response = formatter.formatResponse(query, database_only)
      check database_response.query == query
      check database_response.format == database_only
      check database_response.sources_used == @["database"]
      check database_response.synthesis_notes.contains("Database Only")
      
      # Test synthesis format
      let synthesis_response = formatter.formatResponse(query, synthesis)
      check synthesis_response.query == query
      check synthesis_response.format == synthesis
      check synthesis_response.sources_used == @["external", "database"]
      check synthesis_response.synthesis_notes.contains("Synthesis")
      check synthesis_response.secondary_responses.len == 2
    
    test "Format Preferences":
      ## Test user format preference management
      let user_id = "test_user_123"
      
      # Test default preference
      check formatter.getFormatPreference(user_id) == synthesis
      
      # Test setting preference
      formatter.setFormatPreference(user_id, external_only)
      check formatter.getFormatPreference(user_id) == external_only
      
      # Test changing preference
      formatter.setFormatPreference(user_id, database_only)
      check formatter.getFormatPreference(user_id) == database_only
    
    test "Confidence Thresholds":
      ## Test confidence threshold management
      formatter.setConfidenceThreshold(external_only, 0.8)
      formatter.setConfidenceThreshold(database_only, 0.9)
      formatter.setConfidenceThreshold(synthesis, 0.85)
      
      check formatter.confidence_thresholds[external_only] == 0.8
      check formatter.confidence_thresholds[database_only] == 0.9
      check formatter.confidence_thresholds[synthesis] == 0.85
    
    test "Synthesis Rules":
      ## Test synthesis rule management
      let initial_count = formatter.synthesis_rules.len
      formatter.addSynthesisRule("Test rule for synthesis")
      check formatter.synthesis_rules.len == initial_count + 1
      check formatter.synthesis_rules[^1] == "Test rule for synthesis"
    
    test "Response Summary Generation":
      ## Test response summary creation
      let query = "What is machine learning?"
      let response = formatter.formatResponse(query, synthesis)
      let summary = getResponseSummary(response)
      
      check summary.contains("C (Synthesis)")
      check summary.contains("Confidence:")
      check summary.contains("Response Time:")
      check summary.contains("Sources Used:")
      check summary.contains("external")
      check summary.contains("database")
    
    test "Response Metadata":
      ## Test response metadata structure
      let query = "Explain neural networks"
      let response = formatter.formatResponse(query, synthesis)
      
      # Check primary response metadata
      check response.primary_response.metadata.kind == JObject
      check response.primary_response.timestamp > now() - 10.seconds
      
      # Check secondary responses metadata
      for secondary in response.secondary_responses:
        check secondary.metadata.kind == JObject
        check secondary.timestamp > now() - 10.seconds
    
    test "Response Performance":
      ## Test response generation performance
      let query = "What is the meaning of life?"
      let start_time = getTime()
      
      let response = formatter.formatResponse(query, synthesis)
      
      let end_time = getTime()
      let total_time = (end_time - start_time).inMilliseconds.float / 1000.0
      
      # Response should complete within reasonable time
      check total_time < 5.0  # 5 seconds max
      check response.response_time > 0.0
      check response.response_time < 5.0
    
    test "Empty Query Handling":
      ## Test handling of empty queries
      let empty_query = ""
      let response = formatter.formatResponse(empty_query, synthesis)
      
      check response.query == ""
      check response.primary_response.content.len >= 0
      check response.total_confidence >= 0.0
    
    test "Special Character Handling":
      ## Test handling of queries with special characters
      let special_query = "What is 2+2=? And why does π ≈ 3.14159?"
      let response = formatter.formatResponse(special_query, synthesis)
      
      check response.query == special_query
      check response.primary_response.content.len >= 0
      check response.total_confidence >= 0.0
    
    test "Long Query Handling":
      ## Test handling of very long queries
      let long_query = "This is a very long query that contains many words and should test the system's ability to handle extended input text without breaking or causing performance issues. The query should be processed correctly regardless of its length."
      let response = formatter.formatResponse(long_query, synthesis)
      
      check response.query == long_query
      check response.primary_response.content.len >= 0
      check response.total_confidence >= 0.0
    
    test "Response Consistency":
      ## Test that responses are consistent for the same query
      let query = "What is gravity?"
      
      let response1 = formatter.formatResponse(query, synthesis)
      let response2 = formatter.formatResponse(query, synthesis)
      
      # Responses should have same format and sources
      check response1.format == response2.format
      check response1.sources_used == response2.sources_used
      check response1.synthesis_notes == response2.synthesis_notes
      
      # Content may vary due to external sources, but structure should be consistent
      check response1.primary_response.source_type == response2.primary_response.source_type 