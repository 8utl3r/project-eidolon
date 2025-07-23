# Investigator Agent
#
# The Investigator agent specializes in pattern detection, anomaly identification,
# hypothesis generation, and evidence collection. It analyzes the knowledge graph
# to discover hidden patterns and investigate unusual phenomena.

import std/[times, tables, options, json, strutils, math, sequtils]
import ../../types
import ../../strain/math
import ../../knowledge_graph/operations
import ../../api/types

const RUN_INVESTIGATOR_TESTS* = true

type
  InvestigatorAgent* = object
    ## The Investigator agent for pattern detection and anomaly investigation
    agent_id*: string
    status*: AgentStatusType
    current_task*: Option[string]
    strain_level*: float
    authority_level*: float
    last_active*: DateTime
    investigation_history*: seq[Investigation]  # History of investigations
    pattern_database*: Table[string, Pattern]   # Known patterns
    anomaly_thresholds*: Table[string, float]   # Thresholds for anomaly detection
    hypothesis_queue*: seq[Hypothesis]          # Pending hypotheses
    evidence_collection*: Table[string, Evidence] # Collected evidence

  Investigation* = object
    ## An investigation case
    investigation_id*: string
    case_type*: string  # "pattern", "anomaly", "hypothesis", "evidence"
    description*: string
    entities_involved*: seq[string]  # Entity IDs involved
    start_time*: DateTime
    end_time*: Option[DateTime]
    status*: string  # "active", "completed", "suspended"
    findings*: seq[string]
    confidence*: float
    strain_data*: StrainData

  Pattern* = object
    ## A detected pattern
    pattern_id*: string
    pattern_type*: string  # "temporal", "spatial", "semantic", "strain"
    description*: string
    entities*: seq[string]  # Entity IDs in the pattern
    confidence*: float
    frequency*: int
    first_detected*: DateTime
    last_seen*: DateTime
    attributes*: Table[string, string]

  Hypothesis* = object
    ## A generated hypothesis
    hypothesis_id*: string
    title*: string
    description*: string
    entities_involved*: seq[string]
    confidence*: float
    evidence_count*: int
    created*: DateTime
    status*: string  # "pending", "investigating", "confirmed", "rejected"
    priority*: float

  Evidence* = object
    ## Collected evidence
    evidence_id*: string
    evidence_type*: string  # "observation", "measurement", "correlation", "anomaly"
    description*: string
    related_entities*: seq[string]
    confidence*: float
    collected*: DateTime
    source*: string
    data*: JsonNode

  AnomalyReport* = object
    ## Report of detected anomalies
    report_id*: string
    timestamp*: DateTime
    anomalies*: seq[Anomaly]
    severity_level*: string  # "low", "medium", "high", "critical"
    recommendations*: seq[string]

  Anomaly* = object
    ## A detected anomaly
    anomaly_id*: string
    anomaly_type*: string  # "strain_spike", "pattern_break", "unusual_frequency"
    description*: string
    affected_entities*: seq[string]
    severity*: float  # 0.0-1.0
    detected*: DateTime
    confidence*: float

# Constructor Functions
proc newInvestigatorAgent*(agent_id: string = "investigator"): InvestigatorAgent =
  ## Create a new Investigator agent
  return InvestigatorAgent(
    agent_id: agent_id,
    status: AgentStatusType.idle,
    current_task: none(string),
    strain_level: 0.0,
    authority_level: 0.7,
    last_active: now(),
    investigation_history: @[],
    pattern_database: initTable[string, Pattern](),
    anomaly_thresholds: initTable[string, float](),
    hypothesis_queue: @[],
    evidence_collection: initTable[string, Evidence]()
  )

proc newInvestigation*(investigation_id: string, case_type: string, description: string): Investigation =
  ## Create a new investigation
  return Investigation(
    investigation_id: investigation_id,
    case_type: case_type,
    description: description,
    entities_involved: @[],
    start_time: now(),
    end_time: none(DateTime),
    status: "active",
    findings: @[],
    confidence: 0.0,
    strain_data: newStrainData()
  )

proc newPattern*(pattern_id: string, pattern_type: string, description: string): Pattern =
  ## Create a new pattern
  return Pattern(
    pattern_id: pattern_id,
    pattern_type: pattern_type,
    description: description,
    entities: @[],
    confidence: 0.0,
    frequency: 0,
    first_detected: now(),
    last_seen: now(),
    attributes: initTable[string, string]()
  )

proc newHypothesis*(hypothesis_id: string, title: string, description: string): Hypothesis =
  ## Create a new hypothesis
  return Hypothesis(
    hypothesis_id: hypothesis_id,
    title: title,
    description: description,
    entities_involved: @[],
    confidence: 0.0,
    evidence_count: 0,
    created: now(),
    status: "pending",
    priority: 0.5
  )

proc newEvidence*(evidence_id: string, evidence_type: string, description: string): Evidence =
  ## Create new evidence
  return Evidence(
    evidence_id: evidence_id,
    evidence_type: evidence_type,
    description: description,
    related_entities: @[],
    confidence: 0.0,
    collected: now(),
    source: "investigator",
    data: %*{}
  )

proc newAnomaly*(anomaly_id: string, anomaly_type: string, description: string): Anomaly =
  ## Create a new anomaly
  return Anomaly(
    anomaly_id: anomaly_id,
    anomaly_type: anomaly_type,
    description: description,
    affected_entities: @[],
    severity: 0.0,
    detected: now(),
    confidence: 0.0
  )

# Core Operations
proc detectPatterns*(agent: var InvestigatorAgent, entities: seq[Entity]): seq[Pattern] =
  ## Detect patterns in the given entities
  agent.last_active = now()
  agent.current_task = some("pattern_detection")
  
  var detected_patterns: seq[Pattern]
  
  # Detect strain-based patterns
  var strain_groups: Table[string, seq[Entity]]
  for entity in entities:
    let strain_level = if entity.strain.amplitude > 0.7: "high"
                      elif entity.strain.amplitude > 0.4: "medium"
                      else: "low"
    
    if not strain_groups.hasKey(strain_level):
      strain_groups[strain_level] = @[]
    strain_groups[strain_level].add(entity)
  
  # Create patterns for significant groups
  for strain_level, group in strain_groups:
    if group.len >= 3:  # Minimum pattern size
      let pattern_id = "strain_pattern_" & strain_level & "_" & $now().toTime().toUnix()
      var pattern = newPattern(pattern_id, "strain", "Strain-based pattern: " & strain_level & " amplitude")
      
      pattern.entities = group.mapIt(it.id)
      pattern.confidence = group.len.float / entities.len.float
      pattern.frequency = group.len
      
      detected_patterns.add(pattern)
      agent.pattern_database[pattern_id] = pattern
  
  # Detect temporal patterns (entities created around the same time)
  var time_groups: Table[int, seq[Entity]]
  for entity in entities:
    let time_bucket = int(entity.created.toTime().toUnix() / 3600)  # Hourly buckets
    if not time_groups.hasKey(time_bucket):
      time_groups[time_bucket] = @[]
    time_groups[time_bucket].add(entity)
  
  for time_bucket, group in time_groups:
    if group.len >= 2:  # Minimum temporal pattern size
      let pattern_id = "temporal_pattern_" & $time_bucket & "_" & $now().toTime().toUnix()
      var pattern = newPattern(pattern_id, "temporal", "Temporal pattern: " & $group.len & " entities created simultaneously")
      
      pattern.entities = group.mapIt(it.id)
      pattern.confidence = group.len.float / entities.len.float
      pattern.frequency = group.len
      
      detected_patterns.add(pattern)
      agent.pattern_database[pattern_id] = pattern
  
  agent.current_task = none(string)
  agent.strain_level = min(agent.strain_level + 0.15, 1.0)
  
  return detected_patterns

proc identifyAnomalies*(agent: var InvestigatorAgent, entities: seq[Entity]): AnomalyReport =
  ## Identify anomalies in the given entities
  agent.last_active = now()
  agent.current_task = some("anomaly_detection")
  
  var anomalies: seq[Anomaly]
  
  # Set default thresholds if not already set
  if agent.anomaly_thresholds.len == 0:
    agent.anomaly_thresholds["strain_spike"] = 0.8
    agent.anomaly_thresholds["unusual_frequency"] = 20
    agent.anomaly_thresholds["pattern_break"] = 0.3
  
  # Detect strain spikes
  for entity in entities:
    if entity.strain.amplitude > agent.anomaly_thresholds["strain_spike"]:
      let anomaly_id = "strain_spike_" & entity.id & "_" & $now().toTime().toUnix()
      var anomaly = newAnomaly(anomaly_id, "strain_spike", "Unusually high strain amplitude: " & $entity.strain.amplitude)
      
      anomaly.affected_entities = @[entity.id]
      anomaly.severity = entity.strain.amplitude
      anomaly.confidence = 0.8
      
      anomalies.add(anomaly)
  
  # Detect unusual frequency patterns
  for entity in entities:
    if entity.strain.frequency.float > agent.anomaly_thresholds["unusual_frequency"]:
      let anomaly_id = "unusual_freq_" & entity.id & "_" & $now().toTime().toUnix()
      var anomaly = newAnomaly(anomaly_id, "unusual_frequency", "Unusually high frequency: " & $entity.strain.frequency)
      
      anomaly.affected_entities = @[entity.id]
      anomaly.severity = min(entity.strain.frequency.float / 100.0, 1.0)
      anomaly.confidence = 0.7
      
      anomalies.add(anomaly)
  
  # Determine severity level
  var severity_level = "low"
  if anomalies.len > 0:
    let max_severity = anomalies.mapIt(it.severity).max()
    if max_severity > 0.8:
      severity_level = "critical"
    elif max_severity > 0.6:
      severity_level = "high"
    elif max_severity > 0.4:
      severity_level = "medium"
  
  # Generate recommendations
  var recommendations: seq[string]
  if anomalies.len > 0:
    recommendations.add("Investigate " & $anomalies.len & " detected anomalies")
  if severity_level == "critical":
    recommendations.add("Immediate attention required for critical anomalies")
  elif severity_level == "high":
    recommendations.add("Schedule investigation for high-severity anomalies")
  
  let report = AnomalyReport(
    report_id: "anomaly_report_" & $now().toTime().toUnix(),
    timestamp: now(),
    anomalies: anomalies,
    severity_level: severity_level,
    recommendations: recommendations
  )
  
  agent.current_task = none(string)
  agent.strain_level = min(agent.strain_level + 0.2, 1.0)
  
  return report

proc generateHypothesis*(agent: var InvestigatorAgent, entities: seq[Entity], context: string): Hypothesis =
  ## Generate a hypothesis based on entity analysis
  agent.last_active = now()
  agent.current_task = some("hypothesis_generation")
  
  # Analyze entity characteristics
  let avg_strain = entities.mapIt(it.strain.amplitude).sum / entities.len.float
  let avg_frequency = entities.mapIt(it.strain.frequency.float).sum / entities.len.float
  let entity_types = entities.mapIt($it.entity_type).deduplicate()
  
  # Generate hypothesis based on patterns
  var hypothesis_title = ""
  var hypothesis_description = ""
  var confidence = 0.0
  
  if avg_strain > 0.7:
    hypothesis_title = "High Strain Correlation"
    hypothesis_description = "Entities show unusually high strain levels, suggesting strong interconnections"
    confidence = 0.8
  elif avg_frequency > 10:
    hypothesis_title = "High Frequency Pattern"
    hypothesis_description = "Entities appear frequently across contexts, indicating central importance"
    confidence = 0.7
  elif entity_types.len > 2:
    hypothesis_title = "Multi-Type Interaction"
    hypothesis_description = "Entities of different types show similar patterns, suggesting cross-domain relationships"
    confidence = 0.6
  else:
    hypothesis_title = "Standard Pattern"
    hypothesis_description = "Entities follow expected patterns for their type and context"
    confidence = 0.5
  
  let hypothesis_id = "hypothesis_" & $now().toTime().toUnix()
  var hypothesis = newHypothesis(hypothesis_id, hypothesis_title, hypothesis_description)
  
  hypothesis.entities_involved = entities.mapIt(it.id)
  hypothesis.confidence = confidence
  hypothesis.priority = confidence
  
  agent.hypothesis_queue.add(hypothesis)
  
  agent.current_task = none(string)
  agent.strain_level = min(agent.strain_level + 0.1, 1.0)
  
  return hypothesis

proc collectEvidence*(agent: var InvestigatorAgent, target_entity: Entity, context: seq[Entity]): Evidence =
  ## Collect evidence related to a target entity
  agent.last_active = now()
  agent.current_task = some("evidence_collection")
  
  let evidence_id = "evidence_" & target_entity.id & "_" & $now().toTime().toUnix()
  var evidence = newEvidence(evidence_id, "observation", "Evidence collection for " & target_entity.name)
  
  # Collect strain-based evidence
  evidence.related_entities = @[target_entity.id]
  evidence.confidence = target_entity.strain.amplitude
  
  # Add contextual evidence
  var context_entities: seq[string]
  for entity in context:
    if entity.id != target_entity.id:
      context_entities.add(entity.id)
  evidence.related_entities.add(context_entities)
  
  # Store evidence data
  evidence.data = %*{
    "target_entity": {
      "id": target_entity.id,
      "name": target_entity.name,
      "entity_type": $target_entity.entity_type,
      "strain_amplitude": target_entity.strain.amplitude,
      "strain_frequency": target_entity.strain.frequency
    },
    "context_entities": context_entities.len,
    "collection_time": $now(),
    "analysis_notes": "Evidence collected through automated investigation"
  }
  
  agent.evidence_collection[evidence_id] = evidence
  
  agent.current_task = none(string)
  agent.strain_level = min(agent.strain_level + 0.05, 1.0)
  
  return evidence

proc investigateCase*(agent: var InvestigatorAgent, case_description: string, entities: seq[Entity]): Investigation =
  ## Conduct a full investigation on a case
  agent.last_active = now()
  agent.current_task = some("case_investigation")
  
  let investigation_id = "investigation_" & $now().toTime().toUnix()
  var investigation = newInvestigation(investigation_id, "comprehensive", case_description)
  
  investigation.entities_involved = entities.mapIt(it.id)
  
  # Conduct pattern detection
  let patterns = agent.detectPatterns(entities)
  investigation.findings.add("Detected " & $patterns.len & " patterns")
  
  # Conduct anomaly detection
  let anomaly_report = agent.identifyAnomalies(entities)
  investigation.findings.add("Identified " & $anomaly_report.anomalies.len & " anomalies")
  
  # Generate hypotheses
  let hypothesis = agent.generateHypothesis(entities, case_description)
  investigation.findings.add("Generated hypothesis: " & hypothesis.title)
  
  # Collect evidence
  for entity in entities:
    let evidence = agent.collectEvidence(entity, entities)
    investigation.findings.add("Collected evidence for " & entity.name)
  
  # Calculate overall confidence
  let pattern_confidence = patterns.mapIt(it.confidence).sum / max(patterns.len.float, 1.0)
  let anomaly_confidence = anomaly_report.anomalies.mapIt(it.confidence).sum / max(anomaly_report.anomalies.len.float, 1.0)
  investigation.confidence = (pattern_confidence + anomaly_confidence + hypothesis.confidence) / 3.0
  
  investigation.status = "completed"
  investigation.end_time = some(now())
  
  agent.investigation_history.add(investigation)
  
  agent.current_task = none(string)
  agent.strain_level = min(agent.strain_level + 0.25, 1.0)
  
  return investigation

proc getInvestigationReport*(agent: var InvestigatorAgent): JsonNode =
  ## Generate a comprehensive investigation report
  agent.last_active = now()
  agent.current_task = some("report_generation")
  
  var report = %*{
    "report_id": "investigation_report_" & $now().toTime().toUnix(),
    "timestamp": $now(),
    "agent_id": agent.agent_id,
    "investigation_summary": {
      "total_investigations": agent.investigation_history.len,
      "active_patterns": agent.pattern_database.len,
      "pending_hypotheses": agent.hypothesis_queue.len,
      "collected_evidence": agent.evidence_collection.len
    },
    "recent_findings": [],
    "recommendations": []
  }
  
  # Add recent investigation findings
  let recent_investigations = agent.investigation_history[^min(5, agent.investigation_history.len)..^1]
  for investigation in recent_investigations:
    report["recent_findings"].add(%*{
      "investigation_id": investigation.investigation_id,
      "case_type": investigation.case_type,
      "status": investigation.status,
      "confidence": investigation.confidence,
      "findings_count": investigation.findings.len
    })
  
  # Generate recommendations
  if agent.hypothesis_queue.len > 5:
    report["recommendations"].add(%"High number of pending hypotheses - prioritize investigation")
  
  if agent.pattern_database.len > 20:
    report["recommendations"].add(%"Large pattern database - consider pattern consolidation")
  
  if agent.evidence_collection.len > 50:
    report["recommendations"].add(%"Extensive evidence collection - schedule evidence analysis")
  
  agent.current_task = none(string)
  agent.strain_level = min(agent.strain_level + 0.1, 1.0)
  
  return report

# Agent Status Management
proc activate*(agent: var InvestigatorAgent) =
  ## Activate the Investigator agent
  agent.status = AgentStatusType.active
  agent.last_active = now()
  agent.strain_level = 0.0

proc deactivate*(agent: var InvestigatorAgent) =
  ## Deactivate the Investigator agent
  agent.status = AgentStatusType.idle
  agent.current_task = none(string)
  agent.strain_level = 0.0

proc isActive*(agent: InvestigatorAgent): bool =
  ## Check if the agent is active
  return agent.status == AgentStatusType.active

proc getStatus*(agent: InvestigatorAgent): AgentStatus =
  ## Get the current status of the agent
  return AgentStatus(
    agent_id: agent.agent_id,
    agent_type: "investigator",
    status: agent.status,
    last_active: agent.last_active,
    current_task: agent.current_task,
    strain_level: agent.strain_level,
    authority_level: agent.authority_level
  )

when RUN_INVESTIGATOR_TESTS:
  import std/unittest
  
  suite "Investigator Agent Tests":
    test "Agent Creation and Status":
      var agent = newInvestigatorAgent("test_investigator")
      check agent.agent_id == "test_investigator"
      check agent.status == AgentStatusType.idle
      check agent.authority_level == 0.7
      check agent.strain_level == 0.0
      check agent.investigation_history.len == 0
      check agent.pattern_database.len == 0
      
      agent.activate()
      check agent.status == AgentStatusType.active
      check agent.isActive == true
      
      agent.deactivate()
      check agent.status == AgentStatusType.idle
      check agent.isActive == false
    
    test "Pattern Detection":
      var agent = newInvestigatorAgent()
      agent.activate()
      
      # Create test entities with different strain levels
      var entities: seq[Entity]
      for i in 1..5:
        var strain = newStrainData()
        strain.amplitude = 0.8  # High strain for pattern detection
        strain.frequency = i
        let entity = newEntity("entity_" & $i, "Test Entity " & $i, concept_type, "", strain)
        entities.add(entity)
      
      let patterns = agent.detectPatterns(entities)
      check patterns.len > 0
      check agent.pattern_database.len > 0
      check agent.strain_level > 0.0
    
    test "Anomaly Detection":
      var agent = newInvestigatorAgent()
      agent.activate()
      
      # Create test entities with anomalies
      var entities: seq[Entity]
      for i in 1..3:
        var strain = newStrainData()
        strain.amplitude = 0.9  # High strain (anomaly)
        strain.frequency = 25   # High frequency (anomaly)
        let entity = newEntity("entity_" & $i, "Test Entity " & $i, concept_type, "", strain)
        entities.add(entity)
      
      let anomaly_report = agent.identifyAnomalies(entities)
      check anomaly_report.anomalies.len > 0
      check anomaly_report.severity_level in ["medium", "high", "critical"]
      check agent.strain_level > 0.0
    
    test "Hypothesis Generation":
      var agent = newInvestigatorAgent()
      agent.activate()
      
      # Create test entities
      var entities: seq[Entity]
      for i in 1..4:
        var strain = newStrainData()
        strain.amplitude = 0.8
        strain.frequency = 15
        let entity = newEntity("entity_" & $i, "Test Entity " & $i, concept_type, "", strain)
        entities.add(entity)
      
      let hypothesis = agent.generateHypothesis(entities, "Test context")
      check hypothesis.hypothesis_id.startsWith("hypothesis_")
      check hypothesis.confidence > 0.0
      check agent.hypothesis_queue.len > 0
      check agent.strain_level > 0.0
    
    test "Evidence Collection":
      var agent = newInvestigatorAgent()
      agent.activate()
      
      # Create test entities
      var target_entity = newEntity("target", "Target Entity", concept_type)
      var context_entities: seq[Entity]
      for i in 1..3:
        let entity = newEntity("context_" & $i, "Context Entity " & $i, concept_type)
        context_entities.add(entity)
      
      let evidence = agent.collectEvidence(target_entity, context_entities)
      check evidence.evidence_id.startsWith("evidence_")
      check evidence.related_entities.len > 0
      check agent.evidence_collection.len > 0
      check agent.strain_level > 0.0
    
    test "Case Investigation":
      var agent = newInvestigatorAgent()
      agent.activate()
      
      # Create test entities
      var entities: seq[Entity]
      for i in 1..6:
        var strain = newStrainData()
        strain.amplitude = 0.7
        strain.frequency = 10
        let entity = newEntity("entity_" & $i, "Test Entity " & $i, concept_type, "", strain)
        entities.add(entity)
      
      let investigation = agent.investigateCase("Test investigation case", entities)
      check investigation.investigation_id.startsWith("investigation_")
      check investigation.status == "completed"
      check investigation.findings.len > 0
      check agent.investigation_history.len > 0
      check agent.strain_level > 0.0
    
    test "Investigation Report Generation":
      var agent = newInvestigatorAgent()
      agent.activate()
      
      # Add some test data
      agent.investigation_history.add(newInvestigation("test_inv", "test", "Test investigation"))
      agent.pattern_database["test_pattern"] = newPattern("test_pattern", "test", "Test pattern")
      agent.hypothesis_queue.add(newHypothesis("test_hyp", "Test Hypothesis", "Test description"))
      
      let report = agent.getInvestigationReport()
      check report["report_id"].getStr().startsWith("investigation_report_")
      check report["investigation_summary"]["total_investigations"].getInt() > 0
      check agent.strain_level > 0.0

when isMainModule:
  echo "Investigator Agent - Pattern Detection and Anomaly Investigation"
  echo "================================================================"
  
  var agent = newInvestigatorAgent()
  agent.activate()
  
  # Create sample entities for demonstration
  var entities: seq[Entity]
  for i in 1..5:
    var strain = newStrainData()
    strain.amplitude = 0.6 + (i.float / 10.0)
    strain.frequency = i * 3
    let entity = newEntity("demo_entity_" & $i, "Demo Entity " & $i, concept_type, "", strain)
    entities.add(entity)
  
  echo "Conducting investigation on ", entities.len, " entities..."
  let investigation = agent.investigateCase("Demonstration investigation", entities)
  
  echo "Investigation completed:"
  echo "  ID: ", investigation.investigation_id
  echo "  Status: ", investigation.status
  echo "  Confidence: ", investigation.confidence
  echo "  Findings: ", investigation.findings.len, " items"
  
  echo ""
  echo "Investigation findings:"
  for finding in investigation.findings:
    echo "  - ", finding
  
  agent.deactivate()
  echo ""
  echo "Investigator agent demonstration completed." 