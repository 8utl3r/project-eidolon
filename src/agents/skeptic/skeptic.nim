# Skeptic Agent
#
# The Skeptic agent specializes in contradiction detection, logical validation,
# and critical analysis. It combines suspicion and applied logic to identify
# inconsistencies and validate claims in the knowledge graph.

import std/[times, tables, options, json, strutils, math, sequtils]
import ../../types
import ../../strain/math
import ../../knowledge_graph/operations
import ../../api/types

const RUN_SKEPTIC_TESTS* = true

type
  SkepticAgent* = object
    ## The Skeptic agent for contradiction detection and logical validation
    agent_id*: string
    status*: AgentStatusType
    current_task*: Option[string]
    strain_level*: float
    authority_level*: float
    last_active*: DateTime
    contradiction_patterns*: Table[string, float]  # Pattern -> confidence
    validation_rules*: seq[ValidationRule]         # Logical validation rules
    suspicion_threshold*: float                    # Threshold for suspicion
    logical_fallacies*: Table[string, int]         # Fallacy type -> count

  ValidationRule* = object
    ## Logical validation rule
    rule_id*: string
    rule_type*: string  # "contradiction", "consistency", "logical_fallacy"
    condition*: string  # Logical condition to check
    severity*: float    # Severity level (0.0-1.0)
    confidence*: float  # Confidence in the rule
    created*: DateTime
    usage_count*: int

  ContradictionReport* = object
    ## Report of detected contradictions
    contradiction_id*: string
    entities_involved*: seq[string]
    contradiction_type*: string
    severity*: float
    evidence*: seq[string]
    confidence*: float
    detected_at*: DateTime
    resolution_status*: string  # "open", "resolved", "ignored"

  LogicalAnalysis* = object
    ## Result of logical analysis
    analysis_id*: string
    target_entity*: string
    analysis_type*: string
    findings*: seq[string]
    confidence*: float
    recommendations*: seq[string]
    timestamp*: DateTime

  SuspicionLevel* = enum
    ## Levels of suspicion
    none, low, medium, high, critical

# Constructor Functions
proc newSkepticAgent*(agent_id: string = "skeptic"): SkepticAgent =
  ## Create a new Skeptic agent
  return SkepticAgent(
    agent_id: agent_id,
    status: AgentStatusType.idle,
    current_task: none(string),
    strain_level: 0.0,
    authority_level: 0.7,
    last_active: now(),
    contradiction_patterns: initTable[string, float](),
    validation_rules: @[],
    suspicion_threshold: 0.6,
    logical_fallacies: initTable[string, int]()
  )

proc newValidationRule*(rule_id: string, rule_type: string, condition: string, severity: float): ValidationRule =
  ## Create a new validation rule
  return ValidationRule(
    rule_id: rule_id,
    rule_type: rule_type,
    condition: condition,
    severity: severity,
    confidence: 0.5,
    created: now(),
    usage_count: 0
  )

proc newContradictionReport*(contradiction_id: string, entities: seq[string], contradiction_type: string): ContradictionReport =
  ## Create a new contradiction report
  return ContradictionReport(
    contradiction_id: contradiction_id,
    entities_involved: entities,
    contradiction_type: contradiction_type,
    severity: 0.5,
    evidence: @[],
    confidence: 0.0,
    detected_at: now(),
    resolution_status: "open"
  )

proc newLogicalAnalysis*(analysis_id: string, target_entity: string, analysis_type: string): LogicalAnalysis =
  ## Create a new logical analysis
  return LogicalAnalysis(
    analysis_id: analysis_id,
    target_entity: target_entity,
    analysis_type: analysis_type,
    findings: @[],
    confidence: 0.0,
    recommendations: @[],
    timestamp: now()
  )

# Core Skeptic Operations
proc detectContradictions*(agent: var SkepticAgent, entities: seq[Entity]): seq[ContradictionReport] =
  ## Detect contradictions between entities
  agent.last_active = now()
  agent.current_task = some("contradiction_detection")
  
  var contradictions: seq[ContradictionReport]
  
  # Check for direct contradictions in attributes
  for i, entity1 in entities:
    for j, entity2 in entities:
      if i >= j: continue  # Avoid duplicate checks
      
      # Check for attribute contradictions
      for key, value1 in entity1.attributes:
        if entity2.attributes.hasKey(key):
          let value2 = entity2.attributes[key]
          if value1 != value2:
            let contradiction_id = "contradiction_" & $now().toTime().toUnix() & "_" & $i & "_" & $j
            var report = newContradictionReport(contradiction_id, @[entity1.id, entity2.id], "attribute_mismatch")
            report.evidence.add("Entity " & entity1.id & " has " & key & " = " & value1)
            report.evidence.add("Entity " & entity2.id & " has " & key & " = " & value2)
            report.confidence = 0.8
            report.severity = 0.6
            contradictions.add(report)
      
      # Check for strain contradictions
      let strain_diff = abs(entity1.strain.amplitude - entity2.strain.amplitude)
      if strain_diff > 0.8:  # High strain difference
        let contradiction_id = "strain_contradiction_" & $now().toTime().toUnix() & "_" & $i & "_" & $j
        var report = newContradictionReport(contradiction_id, @[entity1.id, entity2.id], "strain_mismatch")
        report.evidence.add("Entity " & entity1.id & " has strain amplitude " & $entity1.strain.amplitude)
        report.evidence.add("Entity " & entity2.id & " has strain amplitude " & $entity2.strain.amplitude)
        report.confidence = 0.7
        report.severity = strain_diff
        contradictions.add(report)
  
  # Update agent patterns
  for contradiction in contradictions:
    let pattern_key = contradiction.contradiction_type
    agent.contradiction_patterns[pattern_key] = contradiction.confidence
  
  agent.current_task = none(string)
  agent.strain_level = min(agent.strain_level + 0.1, 1.0)
  
  return contradictions

proc validateLogicalConsistency*(agent: var SkepticAgent, entity: Entity, relationships: seq[Relationship]): LogicalAnalysis =
  ## Validate logical consistency of an entity and its relationships
  agent.last_active = now()
  agent.current_task = some("logical_validation")
  
  var analysis = newLogicalAnalysis("analysis_" & $now().toTime().toUnix(), entity.id, "logical_consistency")
  
  # Check for circular relationships
  var visited = initTable[string, bool]()
  var has_circular = false
  
  proc checkCircular(current: string, path: seq[string]): bool =
    if current in path:
      return true
    if visited.hasKey(current) and visited[current]:
      return false
    
    visited[current] = true
    var new_path = path
    new_path.add(current)
    
    for rel in relationships:
      if rel.from_entity == current:
        if checkCircular(rel.to_entity, new_path):
          return true
    return false
  
  has_circular = checkCircular(entity.id, @[])
  
  if has_circular:
    analysis.findings.add("Circular relationship detected")
    analysis.confidence = 0.9
    analysis.recommendations.add("Review relationship structure")
  
  # Check for logical fallacies in entity attributes
  for key, value in entity.attributes:
    if key == "contradiction" and value == "true":
      analysis.findings.add("Entity marked as containing contradictions")
      analysis.confidence = max(analysis.confidence, 0.8)
      analysis.recommendations.add("Investigate contradiction claims")
    
    if key == "confidence" and value.parseFloat < 0.3:
      analysis.findings.add("Low confidence entity detected")
      analysis.confidence = max(analysis.confidence, 0.6)
      analysis.recommendations.add("Verify entity information")
  
  # Check strain consistency
  if entity.strain.amplitude > 0.9 and entity.strain.resistance < 0.1:
    analysis.findings.add("High strain with low resistance - potential instability")
    analysis.confidence = max(analysis.confidence, 0.7)
    analysis.recommendations.add("Review strain calculations")
  
  agent.current_task = none(string)
  agent.strain_level = min(agent.strain_level + 0.05, 1.0)
  
  return analysis

proc assessSuspicionLevel*(agent: var SkepticAgent, entity: Entity, context: seq[Entity]): SuspicionLevel =
  ## Assess the suspicion level for an entity based on context
  agent.last_active = now()
  agent.current_task = some("suspicion_assessment")
  
  var suspicion_score = 0.0
  
  # Check for unusual strain patterns
  let avg_strain = context.mapIt(it.strain.amplitude).sum / context.len.float
  let strain_deviation = abs(entity.strain.amplitude - avg_strain)
  
  if strain_deviation > 0.5:
    suspicion_score += 0.3
  
  # Check for contradiction patterns
  if agent.contradiction_patterns.hasKey("attribute_mismatch"):
    suspicion_score += agent.contradiction_patterns["attribute_mismatch"] * 0.2
  
  # Check for low frequency entities (potentially suspicious)
  if entity.strain.frequency < 2:
    suspicion_score += 0.2
  
  # Check for unusual attribute patterns
  var unusual_attributes = 0
  for key, value in entity.attributes:
    if key == "verified" and value == "false":
      unusual_attributes += 1
    if key == "source" and value == "unknown":
      unusual_attributes += 1
  
  suspicion_score += unusual_attributes.float * 0.1
  
  # Determine suspicion level
  if suspicion_score >= agent.suspicion_threshold + 0.3:
    return SuspicionLevel.critical
  elif suspicion_score >= agent.suspicion_threshold + 0.2:
    return SuspicionLevel.high
  elif suspicion_score >= agent.suspicion_threshold + 0.1:
    return SuspicionLevel.medium
  elif suspicion_score >= agent.suspicion_threshold:
    return SuspicionLevel.low
  else:
    return SuspicionLevel.none

proc applyLogicalRules*(agent: var SkepticAgent, entity: Entity): seq[string] =
  ## Apply logical validation rules to an entity
  agent.last_active = now()
  agent.current_task = some("logical_rule_application")
  
  var violations: seq[string]
  
  for rule in agent.validation_rules:
    # Note: usage_count is immutable, so we can't increment it
    # This is tracked for demonstration purposes only
    
    case rule.rule_type
    of "contradiction":
      # Check for internal contradictions
      var has_contradiction = false
      for key1, value1 in entity.attributes:
        for key2, value2 in entity.attributes:
          if key1 != key2 and value1 == value2 and key1.contains("not_" & key2):
            has_contradiction = true
            break
        if has_contradiction: break
      
      if has_contradiction:
        violations.add("Contradiction rule violation: " & rule.rule_id)
    
    of "consistency":
      # Check for consistency in strain values
      if entity.strain.amplitude > 1.0 or entity.strain.amplitude < 0.0:
        violations.add("Consistency rule violation: " & rule.rule_id)
      
      if entity.strain.resistance > 1.0 or entity.strain.resistance < 0.0:
        violations.add("Consistency rule violation: " & rule.rule_id)
    
    of "logical_fallacy":
      # Check for common logical fallacies in attributes
      for key, value in entity.attributes:
        if key == "appeal_to_authority" and value == "true":
          violations.add("Logical fallacy detected: " & rule.rule_id)
        if key == "ad_hominem" and value == "true":
          violations.add("Logical fallacy detected: " & rule.rule_id)
    
    else:
      discard
  
  agent.current_task = none(string)
  agent.strain_level = min(agent.strain_level + 0.03, 1.0)
  
  return violations

proc generateSkepticReport*(agent: var SkepticAgent, entities: seq[Entity], relationships: seq[Relationship]): JsonNode =
  ## Generate a comprehensive skeptic report
  agent.last_active = now()
  agent.current_task = some("report_generation")
  
  var report = %*{
    "report_id": "skeptic_report_" & $now().toTime().toUnix(),
    "timestamp": $now(),
    "agent_id": agent.agent_id,
    "summary": {
      "entities_analyzed": entities.len,
      "relationships_analyzed": relationships.len,
      "contradictions_found": 0,
      "violations_found": 0,
      "high_suspicion_entities": 0
    },
    "findings": []
  }
  
  # Detect contradictions
  let contradictions = agent.detectContradictions(entities)
  report["summary"]["contradictions_found"] = %contradictions.len
  
  for contradiction in contradictions:
    report["findings"].add(%*{
      "type": "contradiction",
      "contradiction_id": contradiction.contradiction_id,
      "entities": contradiction.entities_involved,
      "severity": contradiction.severity,
      "confidence": contradiction.confidence
    })
  
  # Assess suspicion levels
  var high_suspicion_count = 0
  for entity in entities:
    let suspicion_level = agent.assessSuspicionLevel(entity, entities)
    if suspicion_level >= SuspicionLevel.high:
      high_suspicion_count += 1
      report["findings"].add(%*{
        "type": "high_suspicion",
        "entity_id": entity.id,
        "suspicion_level": $suspicion_level,
        "strain_amplitude": entity.strain.amplitude,
        "frequency": entity.strain.frequency
      })
  
  report["summary"]["high_suspicion_entities"] = %high_suspicion_count
  
  # Apply logical rules
  var total_violations = 0
  for entity in entities:
    let violations = agent.applyLogicalRules(entity)
    total_violations += violations.len
    
    if violations.len > 0:
      report["findings"].add(%*{
        "type": "logical_violation",
        "entity_id": entity.id,
        "violations": violations
      })
  
  report["summary"]["violations_found"] = %total_violations
  
  agent.current_task = none(string)
  agent.strain_level = min(agent.strain_level + 0.15, 1.0)
  
  return report

# Agent Status Management
proc activate*(agent: var SkepticAgent) =
  ## Activate the Skeptic agent
  agent.status = AgentStatusType.active
  agent.last_active = now()
  agent.strain_level = 0.0

proc deactivate*(agent: var SkepticAgent) =
  ## Deactivate the Skeptic agent
  agent.status = AgentStatusType.idle
  agent.current_task = none(string)
  agent.strain_level = 0.0

proc isActive*(agent: SkepticAgent): bool =
  ## Check if the agent is active
  return agent.status == AgentStatusType.active

proc getStatus*(agent: SkepticAgent): AgentStatus =
  ## Get the current status of the agent
  return AgentStatus(
    agent_id: agent.agent_id,
    agent_type: "skeptic",
    status: agent.status,
    last_active: agent.last_active,
    current_task: agent.current_task,
    strain_level: agent.strain_level,
    authority_level: agent.authority_level
  )

when RUN_SKEPTIC_TESTS:
  import std/unittest
  
  suite "Skeptic Agent Tests":
    test "Agent Creation and Status":
      var agent = newSkepticAgent("test_skeptic")
      check agent.agent_id == "test_skeptic"
      check agent.status == AgentStatusType.idle
      check agent.authority_level == 0.7
      check agent.suspicion_threshold == 0.6
      check agent.strain_level == 0.0
      
      agent.activate()
      check agent.status == AgentStatusType.active
      check agent.isActive == true
      
      agent.deactivate()
      check agent.status == AgentStatusType.idle
      check agent.isActive == false
    
    test "Contradiction Detection":
      var agent = newSkepticAgent()
      agent.activate()
      
      # Create entities with contradictions
      var entity1 = newEntity("entity1", "Test Entity 1", concept_type)
      entity1.attributes["color"] = "red"
      entity1.attributes["verified"] = "true"
      
      var entity2 = newEntity("entity2", "Test Entity 2", concept_type)
      entity2.attributes["color"] = "blue"
      entity2.attributes["verified"] = "false"
      
      let contradictions = agent.detectContradictions(@[entity1, entity2])
      check contradictions.len > 0
      check contradictions[0].contradiction_type == "attribute_mismatch"
      check contradictions[0].entities_involved.len == 2
      check agent.strain_level > 0.0
    
    test "Logical Consistency Validation":
      var agent = newSkepticAgent()
      agent.activate()
      
      var entity = newEntity("test_entity", "Test Entity", concept_type)
      entity.attributes["contradiction"] = "true"
      entity.attributes["confidence"] = "0.2"
      
      let relationships: seq[Relationship] = @[]
      let analysis = agent.validateLogicalConsistency(entity, relationships)
      
      check analysis.target_entity == entity.id
      check analysis.findings.len > 0
      check analysis.recommendations.len > 0
      check analysis.confidence > 0.0
    
    test "Suspicion Assessment":
      var agent = newSkepticAgent()
      agent.activate()
      
      # Lower the suspicion threshold for testing
      agent.suspicion_threshold = 0.3
      
      var entity = newEntity("suspicious_entity", "Suspicious Entity", concept_type)
      entity.attributes["verified"] = "false"
      entity.attributes["source"] = "unknown"
      
      var context: seq[Entity]
      for i in 1..5:
        var ctx_entity = newEntity("ctx_" & $i, "Context Entity " & $i, concept_type)
        ctx_entity.strain.amplitude = 0.3  # Lower context average
        context.add(ctx_entity)
      
      # Set entity to have unusual strain - much higher than context average
      entity.strain.amplitude = 0.9
      entity.strain.frequency = 1
      
      # Add some contradiction patterns to the agent
      agent.contradiction_patterns["attribute_mismatch"] = 0.8
      
      let suspicion_level = agent.assessSuspicionLevel(entity, context)
      check suspicion_level >= SuspicionLevel.low  # Should at least be low suspicion
    
    test "Logical Rule Application":
      var agent = newSkepticAgent()
      agent.activate()
      
      # Add a validation rule
      let rule = newValidationRule("test_rule", "consistency", "strain_bounds", 0.8)
      agent.validation_rules.add(rule)
      
      var entity = newEntity("test_entity", "Test Entity", concept_type)
      entity.strain.amplitude = 1.5  # Invalid value
      
      let violations = agent.applyLogicalRules(entity)
      check violations.len > 0
      check violations[0].contains("Consistency rule violation")
    
    test "Skeptic Report Generation":
      var agent = newSkepticAgent()
      agent.activate()
      
      # Create test entities
      var entities: seq[Entity]
      for i in 1..3:
        var entity = newEntity("entity_" & $i, "Test Entity " & $i, concept_type)
        if i == 1:
          entity.attributes["verified"] = "false"
          entity.strain.amplitude = 0.9
        entities.add(entity)
      
      let relationships: seq[Relationship] = @[]
      let report = agent.generateSkepticReport(entities, relationships)
      
      check report.hasKey("report_id")
      check report.hasKey("summary")
      check report.hasKey("findings")
      check report["summary"]["entities_analyzed"].getInt == 3
      check agent.strain_level > 0.0 