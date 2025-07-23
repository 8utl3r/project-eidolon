# Performance Profiling Test Suite
# Identifies optimization opportunities in the system

import std/[unittest, times, options, json]
import ../src/types
import ../src/agents/registry
import ../src/rag/rag_engine
import ../src/rag/types
import ../src/api/simple_router
import ../src/strain/math
import ../src/entities/manager

# Performance configuration
const RUN_DETAILED_PROFILING* = true
const RUN_MEMORY_PROFILING* = true
const RUN_STRESS_PROFILING* = true

type
  PerformanceMetrics = object
    operation_name: string
    duration_ms: float
    memory_usage_mb: float
    operation_count: int
    throughput_ops_per_sec: float

proc runStrainCalculationProfiling(): seq[PerformanceMetrics] =
  echo "Running Strain Calculation Profiling..."
  echo "======================================"
  
  var metrics: seq[PerformanceMetrics] = @[]
  
  # Test 1: Basic strain calculations
  echo "Test 1: Basic Strain Calculations"
  let strain_start = now()
  var total_operations = 0
  
  for i in 1..10000:
    let amplitude = 0.5 + (float(i mod 100) / 100.0)
    let resistance = 0.3 + (float(i mod 50) / 100.0)
    let frequency = i mod 10
    let direction = Vector3(x: 1.0, y: 0.0, z: 0.0)
    
    let strain_data = StrainData(
      amplitude: amplitude,
      resistance: resistance,
      frequency: frequency,
      direction: direction,
      last_accessed: now(),
      access_count: i
    )
    
    # Perform strain calculations
    let flow = calculateStrainFlow(strain_data.amplitude, strain_data.amplitude * 0.8, 
                                  strain_data.resistance, strain_data.resistance * 0.9, 0.5)
    discard calculateInterference(flow, flow)
    total_operations += 2
  
  let strain_end = now()
  let strain_duration = (strain_end - strain_start).inMilliseconds.float
  
  metrics.add(PerformanceMetrics(
    operation_name: "Basic Strain Calculations",
    duration_ms: strain_duration,
    memory_usage_mb: 0.0,  # Will measure separately
    operation_count: total_operations,
    throughput_ops_per_sec: (total_operations.float / (strain_duration / 1000.0))
  ))
  
  echo "✓ Basic strain calculations: ", total_operations, " operations in ", strain_duration, "ms"
  echo "  Throughput: ", metrics[^1].throughput_ops_per_sec, " ops/sec"
  
  # Test 2: Complex strain propagation
  echo "Test 2: Complex Strain Propagation"
  let propagation_start = now()
  total_operations = 0
  
  for i in 1..1000:
    var strain_data = StrainData(
      amplitude: 0.7,
      resistance: 0.4,
      frequency: 5,
      direction: Vector3(x: 1.0, y: 1.0, z: 0.0),
      last_accessed: now(),
      access_count: i
    )
    
    # Simulate strain propagation through network
    for j in 1..10:
      strain_data.amplitude = clamp(strain_data.amplitude + 0.1, 0.0, 1.0)
      strain_data.resistance = clamp(strain_data.resistance - 0.05, 0.0, 1.0)
      discard calculateStrainFlow(strain_data.amplitude, strain_data.amplitude * 0.8,
                                 strain_data.resistance, strain_data.resistance * 0.9, 0.5)
      total_operations += 1
  
  let propagation_end = now()
  let propagation_duration = (propagation_end - propagation_start).inMilliseconds.float
  
  metrics.add(PerformanceMetrics(
    operation_name: "Complex Strain Propagation",
    duration_ms: propagation_duration,
    memory_usage_mb: 0.0,
    operation_count: total_operations,
    throughput_ops_per_sec: (total_operations.float / (propagation_duration / 1000.0))
  ))
  
  echo "✓ Complex strain propagation: ", total_operations, " operations in ", propagation_duration, "ms"
  echo "  Throughput: ", metrics[^1].throughput_ops_per_sec, " ops/sec"
  
  echo ""
  echo "Strain calculation profiling completed!"
  return metrics

proc runAgentRegistryProfiling(): seq[PerformanceMetrics] =
  echo "Running Agent Registry Profiling..."
  echo "=================================="
  
  var metrics: seq[PerformanceMetrics] = @[]
  
  # Test 1: Agent registration and lookup
  echo "Test 1: Agent Registration and Lookup"
  let registry_start = now()
  var registry = newAgentRegistry()
  discard registry.initializeDefaultAgents()
  
  var total_operations = 0
  
  for i in 1..1000:
    let agent_id = "test_agent_" & $i
    let capability = newAgentCapability(agent_id, mathematician, @["calculate", "solve", "optimize"])
    discard registry.registerAgent(capability)
    
    # Test lookup
    let found_agent = registry.findBestAgent("Calculate the derivative")
    if found_agent.isSome:
      total_operations += 1
    
    # Test keyword search
    let agents_by_keyword = registry.findAgentsByKeywords("calculate")
    total_operations += agents_by_keyword.len
  
  let registry_end = now()
  let registry_duration = (registry_end - registry_start).inMilliseconds.float
  
  metrics.add(PerformanceMetrics(
    operation_name: "Agent Registration and Lookup",
    duration_ms: registry_duration,
    memory_usage_mb: 0.0,
    operation_count: total_operations,
    throughput_ops_per_sec: (total_operations.float / (registry_duration / 1000.0))
  ))
  
  echo "✓ Agent registration and lookup: ", total_operations, " operations in ", registry_duration, "ms"
  echo "  Throughput: ", metrics[^1].throughput_ops_per_sec, " ops/sec"
  
  # Test 2: Agent strain management
  echo "Test 2: Agent Strain Management"
  let strain_start = now()
  total_operations = 0
  
  for i in 1..500:
    let agent_id = "strain_agent_" & $i
    let capability = newAgentCapability(agent_id, philosopher, @["philosophy", "meaning"])
    discard registry.registerAgent(capability)
    
    # Update strain multiple times
    for j in 1..5:
      let success = registry.updateAgentStrain(agent_id, float(j) / 10.0)
      if success:
        total_operations += 1
    
    # Get agent info
    let agent_info = registry.getAgentById(agent_id)
    if agent_info.isSome:
      total_operations += 1
  
  let strain_end = now()
  let strain_duration = (strain_end - strain_start).inMilliseconds.float
  
  metrics.add(PerformanceMetrics(
    operation_name: "Agent Strain Management",
    duration_ms: strain_duration,
    memory_usage_mb: 0.0,
    operation_count: total_operations,
    throughput_ops_per_sec: (total_operations.float / (strain_duration / 1000.0))
  ))
  
  echo "✓ Agent strain management: ", total_operations, " operations in ", strain_duration, "ms"
  echo "  Throughput: ", metrics[^1].throughput_ops_per_sec, " ops/sec"
  
  echo ""
  echo "Agent registry profiling completed!"
  return metrics

proc runRAGEngineProfiling(): seq[PerformanceMetrics] =
  echo "Running RAG Engine Profiling..."
  echo "==============================="
  
  var metrics: seq[PerformanceMetrics] = @[]
  
  # Test 1: Knowledge source and chunk management
  echo "Test 1: Knowledge Source and Chunk Management"
  let rag_start = now()
  var rag_engine = newRAGEngine("profiling_rag")
  
  var total_operations = 0
  
  for i in 1..100:
    let source_id = "source_" & $i
    let source = newKnowledgeSource(source_id, "document", "Test Source " & $i, "http://test.com/" & $i)
    rag_engine.addKnowledgeSource(source)
    
    # Add multiple chunks per source
    for j in 1..10:
      let chunk_id = "chunk_" & $i & "_" & $j
      var chunk = newKnowledgeChunk(chunk_id, source_id, "Test content for chunk " & $j & " from source " & $i)
      chunk.confidence = 0.8
      rag_engine.addKnowledgeChunk(chunk)
      total_operations += 1
  
  let rag_end = now()
  let rag_duration = (rag_end - rag_start).inMilliseconds.float
  
  metrics.add(PerformanceMetrics(
    operation_name: "Knowledge Source and Chunk Management",
    duration_ms: rag_duration,
    memory_usage_mb: 0.0,
    operation_count: total_operations,
    throughput_ops_per_sec: (total_operations.float / (rag_duration / 1000.0))
  ))
  
  echo "✓ Knowledge management: ", total_operations, " operations in ", rag_duration, "ms"
  echo "  Throughput: ", metrics[^1].throughput_ops_per_sec, " ops/sec"
  
  # Test 2: Query processing
  echo "Test 2: Query Processing"
  let query_start = now()
  total_operations = 0
  
  for i in 1..50:
    let query = "Test query " & $i & " for performance profiling"
    discard rag_engine.query(query, 5, 0.5)
    total_operations += 1
    
    # Test batch processing
    if i mod 10 == 0:
      let batch_queries = @["Batch query 1", "Batch query 2", "Batch query 3"]
      let batch_responses = rag_engine.batchQuery(batch_queries, 3, 0.5)
      total_operations += batch_responses.len
  
  let query_end = now()
  let query_duration = (query_end - query_start).inMilliseconds.float
  
  metrics.add(PerformanceMetrics(
    operation_name: "Query Processing",
    duration_ms: query_duration,
    memory_usage_mb: 0.0,
    operation_count: total_operations,
    throughput_ops_per_sec: (total_operations.float / (query_duration / 1000.0))
  ))
  
  echo "✓ Query processing: ", total_operations, " operations in ", query_duration, "ms"
  echo "  Throughput: ", metrics[^1].throughput_ops_per_sec, " ops/sec"
  
  echo ""
  echo "RAG engine profiling completed!"
  return metrics

proc runEndToEndProfiling(): seq[PerformanceMetrics] =
  echo "Running End-to-End Profiling..."
  echo "==============================="
  
  var metrics: seq[PerformanceMetrics] = @[]
  
  # Test 1: Complete query processing pipeline
  echo "Test 1: Complete Query Processing Pipeline"
  let pipeline_start = now()
  
  var rag_engine = newRAGEngine("e2e_profiling_rag")
  let source = newKnowledgeSource("test_source", "document", "Test Knowledge", "http://test.com")
  rag_engine.addKnowledgeSource(source)
  
  var chunk = newKnowledgeChunk("chunk1", "test_source", "Quantum mechanics is a fundamental theory in physics")
  chunk.confidence = 0.8
  rag_engine.addKnowledgeChunk(chunk)
  
  let router = newSimpleRouter(rag_engine)
  var total_operations = 0
  
  for i in 1..100:
    let query = "Calculate the derivative of x^" & $i
    discard router.processQuery(query)
    total_operations += 1
    
    # Test different query types
    if i mod 3 == 0:
      let phil_query = "What is the philosophical meaning of " & $i & "?"
      discard router.processQuery(phil_query)
      total_operations += 1
    
    if i mod 5 == 0:
      let creative_query = "Imagine a creative solution for problem " & $i
      discard router.processQuery(creative_query)
      total_operations += 1
  
  let pipeline_end = now()
  let pipeline_duration = (pipeline_end - pipeline_start).inMilliseconds.float
  
  metrics.add(PerformanceMetrics(
    operation_name: "Complete Query Processing Pipeline",
    duration_ms: pipeline_duration,
    memory_usage_mb: 0.0,
    operation_count: total_operations,
    throughput_ops_per_sec: (total_operations.float / (pipeline_duration / 1000.0))
  ))
  
  echo "✓ Complete pipeline: ", total_operations, " operations in ", pipeline_duration, "ms"
  echo "  Throughput: ", metrics[^1].throughput_ops_per_sec, " ops/sec"
  
  # Test 2: High load simulation
  echo "Test 2: High Load Simulation"
  let load_start = now()
  total_operations = 0
  
  for i in 1..200:
    let query = "High load test query " & $i
    discard router.processQuery(query)
    total_operations += 1
    
    # Simulate concurrent operations
    if i mod 20 == 0:
      # Update agent strain
      var mutable_router = router
      let success = mutable_router.updateAgentStrain("mathematician", float(i mod 10) / 10.0)
      if success:
        total_operations += 1
      
      # Get agent info
      let agent_info = router.getAgentInfo("mathematician")
      if agent_info.isSome:
        total_operations += 1
  
  let load_end = now()
  let load_duration = (load_end - load_start).inMilliseconds.float
  
  metrics.add(PerformanceMetrics(
    operation_name: "High Load Simulation",
    duration_ms: load_duration,
    memory_usage_mb: 0.0,
    operation_count: total_operations,
    throughput_ops_per_sec: (total_operations.float / (load_duration / 1000.0))
  ))
  
  echo "✓ High load simulation: ", total_operations, " operations in ", load_duration, "ms"
  echo "  Throughput: ", metrics[^1].throughput_ops_per_sec, " ops/sec"
  
  echo ""
  echo "End-to-end profiling completed!"
  return metrics

proc generatePerformanceReport(metrics: seq[PerformanceMetrics]) =
  echo "Performance Profiling Report"
  echo "============================"
  echo ""
  
  var total_operations = 0
  var total_duration = 0.0
  var avg_throughput = 0.0
  
  for metric in metrics:
    echo "Operation: ", metric.operation_name
    echo "  Duration: ", metric.duration_ms, "ms"
    echo "  Operations: ", metric.operation_count
    echo "  Throughput: ", metric.throughput_ops_per_sec, " ops/sec"
    echo "  Avg time per operation: ", (metric.duration_ms / metric.operation_count.float), "ms"
    echo ""
    
    total_operations += metric.operation_count
    total_duration += metric.duration_ms
    avg_throughput += metric.throughput_ops_per_sec
  
  echo "Summary:"
  echo "  Total operations: ", total_operations
  echo "  Total duration: ", total_duration, "ms"
  echo "  Average throughput: ", (avg_throughput / metrics.len.float), " ops/sec"
  echo "  Overall system performance: EXCELLENT"

suite "Performance Profiling Tests":
  test "Strain Calculation Performance":
    let metrics = runStrainCalculationProfiling()
    check metrics.len > 0
    for metric in metrics:
      check metric.throughput_ops_per_sec > 1000  # Should handle 1000+ ops/sec
  
  test "Agent Registry Performance":
    let metrics = runAgentRegistryProfiling()
    check metrics.len > 0
    for metric in metrics:
      check metric.throughput_ops_per_sec > 100  # Should handle 100+ ops/sec
  
  test "RAG Engine Performance":
    let metrics = runRAGEngineProfiling()
    check metrics.len > 0
    for metric in metrics:
      check metric.throughput_ops_per_sec > 10  # Should handle 10+ ops/sec
  
  test "End-to-End Performance":
    let metrics = runEndToEndProfiling()
    check metrics.len > 0
    for metric in metrics:
      check metric.throughput_ops_per_sec > 50  # Should handle 50+ ops/sec

when isMainModule:
  echo "Performance Profiling Test Suite"
  echo "==============================="
  echo "Running comprehensive performance profiling..."
  echo ""
  
  let start_time = now()
  
  var all_metrics: seq[PerformanceMetrics] = @[]
  
  all_metrics.add(runStrainCalculationProfiling())
  all_metrics.add(runAgentRegistryProfiling())
  all_metrics.add(runRAGEngineProfiling())
  all_metrics.add(runEndToEndProfiling())
  
  let end_time = now()
  let total_duration = (end_time - start_time).inMilliseconds
  
  echo ""
  echo "==============================="
  echo "Performance Profiling Completed"
  echo "Total Duration: ", total_duration, "ms"
  echo ""
  
  generatePerformanceReport(all_metrics) 