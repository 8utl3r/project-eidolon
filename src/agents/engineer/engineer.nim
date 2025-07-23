# Engineer Agent
#
# The Engineer agent specializes in mathematical operations, strain calculations,
# pattern recognition, and quantitative analysis. It provides the mathematical
# foundation for the knowledge graph system.

import std/[times, tables, options, json, strutils, math, sequtils]
import ../../types
import ../../strain/math
import ../../knowledge_graph/operations
import ../../api/types

const RUN_ENGINEER_TESTS* = true

type
  EngineerAgent* = object
    ## The Engineer agent for mathematical operations and strain calculations
    agent_id*: string
    status*: AgentStatusType
    current_task*: Option[string]
    strain_level*: float
    authority_level*: float
    last_active*: DateTime
    mathematical_patterns*: Table[string, float]  # Pattern -> confidence
    calculation_cache*: Table[string, float]      # Query -> result
    strain_models*: seq[StrainModel]              # Mathematical strain models

  StrainModel* = object
    ## Mathematical model for strain calculations
    model_id*: string
    model_type*: string  # "linear", "exponential", "logarithmic", "custom"
    parameters*: Table[string, float]
    confidence*: float
    last_updated*: DateTime
    validation_metrics*: Table[string, float]

  MathematicalOperation* = enum
    ## Types of mathematical operations
    strain_calculation, pattern_analysis, statistical_analysis,
    optimization, prediction, validation, model_fitting

  CalculationResult* = object
    ## Result of a mathematical calculation
    operation_id*: string
    operation_type*: MathematicalOperation
    input_data*: JsonNode
    result*: JsonNode
    confidence*: float
    execution_time*: float
    metadata*: Table[string, string]

# Helper Functions
proc calculateDirection*(source: Entity, target: Entity): Vector3 =
  ## Calculate direction vector from source to target
  # For now, use a simple normalized direction
  return Vector3(x: 1.0, y: 0.0, z: 0.0)

proc calculateCorrelation*(x: seq[float], y: seq[float]): float =
  ## Calculate Pearson correlation coefficient
  if x.len != y.len or x.len < 2:
    return 0.0
  
  let n = x.len.float
  let sum_x = x.sum
  let sum_y = y.sum
  let sum_xy = zip(x, y).mapIt(it[0] * it[1]).sum
  let sum_x2 = x.mapIt(it ^ 2).sum
  let sum_y2 = y.mapIt(it ^ 2).sum
  
  let numerator = n * sum_xy - sum_x * sum_y
  let denominator = sqrt((n * sum_x2 - sum_x ^ 2) * (n * sum_y2 - sum_y ^ 2))
  
  return if denominator > 0: numerator / denominator else: 0.0

# Constructor Functions
proc newEngineerAgent*(agent_id: string = "engineer"): EngineerAgent =
  ## Create a new Engineer agent
  return EngineerAgent(
    agent_id: agent_id,
    status: AgentStatusType.idle,
    current_task: none(string),
    strain_level: 0.0,
    authority_level: 0.8,
    last_active: now(),
    mathematical_patterns: initTable[string, float](),
    calculation_cache: initTable[string, float](),
    strain_models: @[]
  )

proc newStrainModel*(model_id: string, model_type: string): StrainModel =
  ## Create a new strain model
  return StrainModel(
    model_id: model_id,
    model_type: model_type,
    parameters: initTable[string, float](),
    confidence: 0.5,
    last_updated: now(),
    validation_metrics: initTable[string, float]()
  )

proc newCalculationResult*(operation_id: string, operation_type: MathematicalOperation): CalculationResult =
  ## Create a new calculation result
  return CalculationResult(
    operation_id: operation_id,
    operation_type: operation_type,
    input_data: newJObject(),
    result: newJObject(),
    confidence: 0.0,
    execution_time: 0.0,
    metadata: initTable[string, string]()
  )

# Core Mathematical Operations
proc calculateStrainFlow*(agent: var EngineerAgent, source: Entity, target: Entity): StrainData =
  ## Calculate strain flow between two entities using mathematical models
  agent.last_active = now()
  agent.current_task = some("strain_flow_calculation")
  
  let start_time = cpuTime()
  
  # Use the most confident strain model
  var best_model: Option[StrainModel]
  var best_confidence = 0.0
  
  for model in agent.strain_models:
    if model.confidence > best_confidence:
      best_confidence = model.confidence
      best_model = some(model)
  
  # Calculate strain flow using mathematical models
  var strain = newStrainData()
  
  if best_model.isSome:
    let model = best_model.get()
    case model.model_type
    of "linear":
      strain.amplitude = source.strain.amplitude * model.parameters.getOrDefault("flow_factor", 0.5)
      strain.resistance = (source.strain.resistance + target.strain.resistance) / 2.0
    of "exponential":
      let decay_factor = model.parameters.getOrDefault("decay_factor", 0.1)
      strain.amplitude = source.strain.amplitude * exp(-decay_factor * source.strain.frequency.float)
      strain.resistance = source.strain.resistance * (1.0 - decay_factor)
    of "logarithmic":
      let base_factor = model.parameters.getOrDefault("base_factor", 2.0)
      strain.amplitude = source.strain.amplitude * ln(base_factor + source.strain.frequency.float) / ln(base_factor)
      strain.resistance = source.strain.resistance
    else:
      # Default linear model
      strain.amplitude = source.strain.amplitude * 0.5
      strain.resistance = (source.strain.resistance + target.strain.resistance) / 2.0
  
  strain.frequency = source.strain.frequency + 1
  strain.direction = calculateDirection(source, target)
  strain.last_accessed = now()
  strain.access_count = source.strain.access_count + 1
  
  let execution_time = cpuTime() - start_time
  
  # Cache the result
  let cache_key = source.id & "_" & target.id & "_strain_flow"
  agent.calculation_cache[cache_key] = strain.amplitude
  
  agent.current_task = none(string)
  agent.strain_level = min(agent.strain_level + 0.1, 1.0)
  
  return strain

proc analyzePatterns*(agent: var EngineerAgent, entities: seq[Entity]): Table[string, float] =
  ## Analyze mathematical patterns in entity strain data
  agent.last_active = now()
  agent.current_task = some("pattern_analysis")
  
  var patterns: Table[string, float]
  
  # Analyze amplitude patterns
  let amplitudes = entities.mapIt(it.strain.amplitude)
  let amplitude_mean = amplitudes.sum / amplitudes.len.float
  let amplitude_variance = amplitudes.mapIt((it - amplitude_mean) ^ 2).sum / amplitudes.len.float
  let amplitude_std = sqrt(amplitude_variance)
  
  patterns["amplitude_mean"] = amplitude_mean
  patterns["amplitude_variance"] = amplitude_variance
  patterns["amplitude_std"] = amplitude_std
  
  # Analyze resistance patterns
  let resistances = entities.mapIt(it.strain.resistance)
  let resistance_mean = resistances.sum / resistances.len.float
  let resistance_variance = resistances.mapIt((it - resistance_mean) ^ 2).sum / resistances.len.float
  let resistance_std = sqrt(resistance_variance)
  
  patterns["resistance_mean"] = resistance_mean
  patterns["resistance_variance"] = resistance_variance
  patterns["resistance_std"] = resistance_std
  
  # Analyze frequency patterns
  let frequencies = entities.mapIt(it.strain.frequency.float)
  let frequency_mean = frequencies.sum / frequencies.len.float
  let frequency_variance = frequencies.mapIt((it - frequency_mean) ^ 2).sum / frequencies.len.float
  let frequency_std = sqrt(frequency_variance)
  
  patterns["frequency_mean"] = frequency_mean
  patterns["frequency_variance"] = frequency_variance
  patterns["frequency_std"] = frequency_std
  
  # Detect correlations
  if amplitudes.len > 1:
    let amplitude_resistance_corr = calculateCorrelation(amplitudes, resistances)
    patterns["amplitude_resistance_correlation"] = amplitude_resistance_corr
  
  # Update agent patterns
  for pattern, value in patterns:
    agent.mathematical_patterns[pattern] = value
  
  agent.current_task = none(string)
  agent.strain_level = min(agent.strain_level + 0.05, 1.0)
  
  return patterns

proc optimizeStrainModel*(agent: var EngineerAgent, training_data: seq[tuple[input: StrainData, output: float]]): StrainModel =
  ## Optimize strain model parameters using mathematical optimization
  agent.last_active = now()
  agent.current_task = some("model_optimization")
  
  # Create a new optimized model
  var optimized_model = newStrainModel("optimized_" & $now().toTime().toUnix(), "optimized")
  
  if training_data.len < 2:
    optimized_model.confidence = 0.0
    return optimized_model
  
  # Simple linear regression optimization
  var sum_x = 0.0
  var sum_y = 0.0
  var sum_xy = 0.0
  var sum_x2 = 0.0
  
  for (input, output) in training_data:
    let x = input.amplitude
    let y = output
    sum_x += x
    sum_y += y
    sum_xy += x * y
    sum_x2 += x * x
  
  let n = training_data.len.float
  let slope = (n * sum_xy - sum_x * sum_y) / (n * sum_x2 - sum_x * sum_x)
  let intercept = (sum_y - slope * sum_x) / n
  
  optimized_model.parameters["slope"] = slope
  optimized_model.parameters["intercept"] = intercept
  
  # Calculate confidence based on R-squared
  var ss_res = 0.0
  var ss_tot = 0.0
  let y_mean = sum_y / n
  
  for (input, output) in training_data:
    let predicted = slope * input.amplitude + intercept
    ss_res += (output - predicted) ^ 2
    ss_tot += (output - y_mean) ^ 2
  
  let r_squared = if ss_tot > 0: 1.0 - (ss_res / ss_tot) else: 0.0
  optimized_model.confidence = max(0.0, min(1.0, r_squared))
  
  # Add validation metrics
  optimized_model.validation_metrics["r_squared"] = r_squared
  optimized_model.validation_metrics["training_samples"] = training_data.len.float
  
  # Add to agent's models
  agent.strain_models.add(optimized_model)
  
  agent.current_task = none(string)
  agent.strain_level = min(agent.strain_level + 0.15, 1.0)
  
  return optimized_model

proc predictStrain*(agent: var EngineerAgent, entity: Entity, time_horizon: int): seq[StrainData] =
  ## Predict future strain values using mathematical models
  agent.last_active = now()
  agent.current_task = some("strain_prediction")
  
  var predictions: seq[StrainData]
  
  # Use the most confident model for prediction
  var best_model: Option[StrainModel]
  var best_confidence = 0.0
  
  for model in agent.strain_models:
    if model.confidence > best_confidence:
      best_confidence = model.confidence
      best_model = some(model)
  
  if best_model.isSome:
    let model = best_model.get()
    
    for i in 1..time_horizon:
      var predicted_strain = entity.strain
      
      case model.model_type
      of "linear":
        let slope = model.parameters.getOrDefault("slope", 0.0)
        predicted_strain.amplitude = max(0.0, min(1.0, entity.strain.amplitude + slope * i.float))
      of "exponential":
        let decay_factor = model.parameters.getOrDefault("decay_factor", 0.1)
        predicted_strain.amplitude = entity.strain.amplitude * exp(-decay_factor * i.float)
      of "optimized":
        let slope = model.parameters.getOrDefault("slope", 0.0)
        let intercept = model.parameters.getOrDefault("intercept", 0.0)
        predicted_strain.amplitude = max(0.0, min(1.0, slope * entity.strain.amplitude + intercept))
      else:
        # Default: gradual decay
        predicted_strain.amplitude = entity.strain.amplitude * (0.95 ^ i.float)
      
      predicted_strain.frequency = entity.strain.frequency + i
      predicted_strain.last_accessed = now() + initDuration(hours = i)
      predictions.add(predicted_strain)
  
  agent.current_task = none(string)
  agent.strain_level = min(agent.strain_level + 0.1, 1.0)
  
  return predictions

# Agent Status Management
proc activate*(agent: var EngineerAgent) =
  ## Activate the Engineer agent
  agent.status = AgentStatusType.active
  agent.last_active = now()
  agent.strain_level = 0.0

proc deactivate*(agent: var EngineerAgent) =
  ## Deactivate the Engineer agent
  agent.status = AgentStatusType.idle
  agent.current_task = none(string)
  agent.strain_level = 0.0

proc isActive*(agent: EngineerAgent): bool =
  ## Check if the agent is active
  return agent.status == AgentStatusType.active

proc getStatus*(agent: EngineerAgent): AgentStatus =
  ## Get the current status of the agent
  return AgentStatus(
    agent_id: agent.agent_id,
    agent_type: "engineer",
    status: agent.status,
    last_active: agent.last_active,
    current_task: agent.current_task,
    strain_level: agent.strain_level,
    authority_level: agent.authority_level
  )

when RUN_ENGINEER_TESTS:
  import std/unittest
  
  suite "Engineer Agent Tests":
    test "Agent Creation and Status":
      var agent = newEngineerAgent("test_engineer")
      check agent.agent_id == "test_engineer"
      check agent.status == AgentStatusType.idle
      check agent.authority_level == 0.8
      check agent.strain_level == 0.0
      
      agent.activate()
      check agent.status == AgentStatusType.active
      check agent.isActive == true
      
      agent.deactivate()
      check agent.status == AgentStatusType.idle
      check agent.isActive == false
    
    test "Strain Flow Calculation":
      var agent = newEngineerAgent()
      agent.activate()
      
      let source = newEntity("source", "Source entity", concept_type)
      let target = newEntity("target", "Target entity", concept_type)
      
      let strain_flow = agent.calculateStrainFlow(source, target)
      check strain_flow.amplitude >= 0.0
      check strain_flow.amplitude <= 1.0
      check strain_flow.frequency == source.strain.frequency + 1
      check agent.strain_level > 0.0
    
    test "Pattern Analysis":
      var agent = newEngineerAgent()
      agent.activate()
      
      var entities: seq[Entity]
      for i in 1..5:
        var strain = newStrainData()
        strain.amplitude = i.float / 5.0
        strain.resistance = 1.0 - (i.float / 5.0)
        strain.frequency = i
        let entity = newEntity("entity_" & $i, "Test entity " & $i, concept_type, "", strain)
        entities.add(entity)
      
      let patterns = agent.analyzePatterns(entities)
      check patterns.hasKey("amplitude_mean")
      check patterns.hasKey("resistance_mean")
      check patterns.hasKey("frequency_mean")
      check patterns["amplitude_mean"] > 0.0
      check patterns["resistance_mean"] > 0.0
    
    test "Model Optimization":
      var agent = newEngineerAgent()
      agent.activate()
      
      var training_data: seq[tuple[input: StrainData, output: float]]
      for i in 1..10:
        var input = newStrainData()
        input.amplitude = i.float / 10.0
        let output = 2.0 * input.amplitude + 0.1  # Linear relationship with noise
        training_data.add((input, output))
      
      let optimized_model = agent.optimizeStrainModel(training_data)
      check optimized_model.confidence > 0.0
      check optimized_model.parameters.hasKey("slope")
      check optimized_model.parameters.hasKey("intercept")
      check optimized_model.validation_metrics.hasKey("r_squared")
    
    test "Strain Prediction":
      var agent = newEngineerAgent()
      agent.activate()
      
      # Add a simple linear model
      var model = newStrainModel("test_model", "linear")
      model.parameters["slope"] = -0.1
      model.confidence = 0.8
      agent.strain_models.add(model)
      
      var strain = newStrainData()
      strain.amplitude = 0.8
      let entity = newEntity("test_entity", "Test entity", concept_type, "", strain)
      
      let predictions = agent.predictStrain(entity, 3)
      check predictions.len == 3
      check predictions[0].amplitude < entity.strain.amplitude  # Should decrease
      check predictions[0].frequency == entity.strain.frequency + 1
    
    test "Correlation Calculation":
      let x = @[1.0, 2.0, 3.0, 4.0, 5.0]
      let y = @[2.0, 4.0, 6.0, 8.0, 10.0]  # Perfect positive correlation
      
      let correlation = calculateCorrelation(x, y)
      check abs(correlation - 1.0) < 0.001  # Should be very close to 1.0
      
      let y_negative = @[10.0, 8.0, 6.0, 4.0, 2.0]  # Perfect negative correlation
      let correlation_negative = calculateCorrelation(x, y_negative)
      check abs(correlation_negative - (-1.0)) < 0.001  # Should be very close to -1.0 