// Sample Strain Graph for Project Eidolon
// Updated for real-time agent visualization

// Clear existing graph
g.V().drop().iterate()

println "Creating Project Eidolon strain graph with agent visualization..."

// Create throne nodes (agent domains)
def throneOfTheEngineer = g.addV('throne')
  .property('name', 'ThroneOfTheEngineer')
  .property('agent', 'The Engineer')
  .property('domain', 'mathematical')
  .property('authority_level', 'triggered')
  .property('strain_amplitude', 0.8)
  .property('is_active', false)
  .property('last_activity', '2025-07-21T21:00:00Z')
  .next()

def throneOfTheSkeptic = g.addV('throne')
  .property('name', 'ThroneOfTheSkeptic')
  .property('agent', 'The Skeptic')
  .property('domain', 'logical')
  .property('authority_level', 'triggered')
  .property('strain_amplitude', 0.7)
  .property('is_active', false)
  .property('last_activity', '2025-07-21T21:00:00Z')
  .next()

def throneOfTheStageManager = g.addV('throne')
  .property('name', 'ThroneOfTheStageManager')
  .property('agent', 'The Stage Manager')
  .property('domain', 'coordination')
  .property('authority_level', 'permanent')
  .property('strain_amplitude', 0.9)
  .property('is_active', true)
  .property('last_activity', '2025-07-21T21:00:00Z')
  .next()

def throneOfTheDreamer = g.addV('throne')
  .property('name', 'ThroneOfTheDreamer')
  .property('agent', 'The Dreamer')
  .property('domain', 'creative')
  .property('authority_level', 'triggered')
  .property('strain_amplitude', 0.6)
  .property('is_active', false)
  .property('last_activity', '2025-07-21T21:00:00Z')
  .next()

def throneOfThePhilosopher = g.addV('throne')
  .property('name', 'ThroneOfThePhilosopher')
  .property('agent', 'The Philosopher')
  .property('domain', 'philosophical')
  .property('authority_level', 'triggered')
  .property('strain_amplitude', 0.7)
  .property('is_active', false)
  .property('last_activity', '2025-07-21T21:00:00Z')
  .next()

def throneOfTheInvestigator = g.addV('throne')
  .property('name', 'ThroneOfTheInvestigator')
  .property('agent', 'The Investigator')
  .property('domain', 'investigative')
  .property('authority_level', 'triggered')
  .property('strain_amplitude', 0.8)
  .property('is_active', false)
  .property('last_activity', '2025-07-21T21:00:00Z')
  .next()

def throneOfTheArchivist = g.addV('throne')
  .property('name', 'ThroneOfTheArchivist')
  .property('agent', 'The Archivist')
  .property('domain', 'archival')
  .property('authority_level', 'permanent')
  .property('strain_amplitude', 0.9)
  .property('is_active', true)
  .property('last_activity', '2025-07-21T21:00:00Z')
  .next()

// Create agent activity nodes (for real-time monitoring)
def engineerActivity = g.addV('agent_activity')
  .property('agent_id', 'engineer')
  .property('agent_type', 'engineer')
  .property('is_active', false)
  .property('current_task', '')
  .property('strain_level', 0.0)
  .property('activity_duration', 0.0)
  .property('ollama_calls', 0)
  .property('nodes_created', 0)
  .property('nodes_modified', 0)
  .property('last_update', '2025-07-21T21:00:00Z')
  .next()

def skepticActivity = g.addV('agent_activity')
  .property('agent_id', 'skeptic')
  .property('agent_type', 'skeptic')
  .property('is_active', false)
  .property('current_task', '')
  .property('strain_level', 0.0)
  .property('activity_duration', 0.0)
  .property('ollama_calls', 0)
  .property('nodes_created', 0)
  .property('nodes_modified', 0)
  .property('last_update', '2025-07-21T21:00:00Z')
  .next()

def stageManagerActivity = g.addV('agent_activity')
  .property('agent_id', 'stage_manager')
  .property('agent_type', 'stage_manager')
  .property('is_active', true)
  .property('current_task', 'System coordination')
  .property('strain_level', 0.9)
  .property('activity_duration', 0.0)
  .property('ollama_calls', 0)
  .property('nodes_created', 0)
  .property('nodes_modified', 0)
  .property('last_update', '2025-07-21T21:00:00Z')
  .next()

def dreamerActivity = g.addV('agent_activity')
  .property('agent_id', 'dreamer')
  .property('agent_type', 'dreamer')
  .property('is_active', false)
  .property('current_task', '')
  .property('strain_level', 0.0)
  .property('activity_duration', 0.0)
  .property('ollama_calls', 0)
  .property('nodes_created', 0)
  .property('nodes_modified', 0)
  .property('last_update', '2025-07-21T21:00:00Z')
  .next()

def philosopherActivity = g.addV('agent_activity')
  .property('agent_id', 'philosopher')
  .property('agent_type', 'philosopher')
  .property('is_active', false)
  .property('current_task', '')
  .property('strain_level', 0.0)
  .property('activity_duration', 0.0)
  .property('ollama_calls', 0)
  .property('nodes_created', 0)
  .property('nodes_modified', 0)
  .property('last_update', '2025-07-21T21:00:00Z')
  .next()

def investigatorActivity = g.addV('agent_activity')
  .property('agent_id', 'investigator')
  .property('agent_type', 'investigator')
  .property('is_active', false)
  .property('current_task', '')
  .property('strain_level', 0.0)
  .property('activity_duration', 0.0)
  .property('ollama_calls', 0)
  .property('nodes_created', 0)
  .property('nodes_modified', 0)
  .property('last_update', '2025-07-21T21:00:00Z')
  .next()

def archivistActivity = g.addV('agent_activity')
  .property('agent_id', 'archivist')
  .property('agent_type', 'archivist')
  .property('is_active', true)
  .property('current_task', 'Knowledge organization')
  .property('strain_level', 0.9)
  .property('activity_duration', 0.0)
  .property('ollama_calls', 0)
  .property('nodes_created', 0)
  .property('nodes_modified', 0)
  .property('last_update', '2025-07-21T21:00:00Z')
  .next()

// Create sample entity nodes
def mathEntity = g.addV('entity')
  .property('name', 'mathematical_analysis')
  .property('entity_type', 'concept')
  .property('strain_amplitude', 0.8)
  .property('strain_resistance', 0.3)
  .property('strain_frequency', 5)
  .property('last_update', '2025-07-21T21:00:00Z')
  .next()

def logicEntity = g.addV('entity')
  .property('name', 'logical_reasoning')
  .property('entity_type', 'concept')
  .property('strain_amplitude', 0.7)
  .property('strain_resistance', 0.4)
  .property('strain_frequency', 4)
  .property('last_update', '2025-07-21T21:00:00Z')
  .next()

def creativeEntity = g.addV('entity')
  .property('name', 'creative_synthesis')
  .property('entity_type', 'concept')
  .property('strain_amplitude', 0.6)
  .property('strain_resistance', 0.5)
  .property('strain_frequency', 3)
  .property('last_update', '2025-07-21T21:00:00Z')
  .next()

// Create authority relationships (throne -> entity)
g.addE('has_authority')
  .from(throneOfTheEngineer)
  .to(mathEntity)
  .property('authority_strength', 0.9)
  .property('strain_amplitude', 0.8)

g.addE('has_authority')
  .from(throneOfTheSkeptic)
  .to(logicEntity)
  .property('authority_strength', 0.8)
  .property('strain_amplitude', 0.7)

g.addE('has_authority')
  .from(throneOfTheDreamer)
  .to(creativeEntity)
  .property('authority_strength', 0.7)
  .property('strain_amplitude', 0.6)

// Create agent activity relationships (agent -> entity)
g.addE('attends_to')
  .from(stageManagerActivity)
  .to(mathEntity)
  .property('strain_flow', 0.8)
  .property('timestamp', '2025-07-21T21:00:00Z')

g.addE('attends_to')
  .from(archivistActivity)
  .to(logicEntity)
  .property('strain_flow', 0.7)
  .property('timestamp', '2025-07-21T21:00:00Z')

// Create agent interaction edges
g.addE('interacts_with')
  .from(stageManagerActivity)
  .to(archivistActivity)
  .property('interaction_type', 'coordination')
  .property('strain_flow', 0.8)
  .property('timestamp', '2025-07-21T21:00:00Z')

// Create entity relationships
g.addE('related_to')
  .from(mathEntity)
  .to(logicEntity)
  .property('relationship_type', 'complements')
  .property('strain_amplitude', 0.7)

g.addE('related_to')
  .from(logicEntity)
  .to(creativeEntity)
  .property('relationship_type', 'enables')
  .property('strain_amplitude', 0.6)

// Create strain flow visualization nodes
def strainSource = g.addV('strain_source')
  .property('name', 'high_strain_source')
  .property('strain_amplitude', 1.0)
  .property('strain_direction', 'outward')
  .property('last_update', '2025-07-21T21:00:00Z')
  .next()

def strainSink = g.addV('strain_sink')
  .property('name', 'low_strain_sink')
  .property('strain_amplitude', 0.1)
  .property('strain_direction', 'inward')
  .property('last_update', '2025-07-21T21:00:00Z')
  .next()

// Create strain flow edges
g.addE('strain_flows_to')
  .from(strainSource)
  .to(mathEntity)
  .property('flow_rate', 0.8)
  .property('timestamp', '2025-07-21T21:00:00Z')

g.addE('strain_flows_to')
  .from(mathEntity)
  .to(logicEntity)
  .property('flow_rate', 0.6)
  .property('timestamp', '2025-07-21T21:00:00Z')

g.addE('strain_flows_to')
  .from(logicEntity)
  .to(strainSink)
  .property('flow_rate', 0.4)
  .property('timestamp', '2025-07-21T21:00:00Z')

println "Graph creation complete!"
println ""

// Display graph statistics
println "Graph Statistics:"
println "=================="
println "Vertices: " + g.V().count().next()
println "Edges: " + g.E().count().next()
println "Throne nodes: " + g.V().hasLabel('throne').count().next()
println "Agent activity nodes: " + g.V().hasLabel('agent_activity').count().next()
println "Entity nodes: " + g.V().hasLabel('entity').count().next()
println "Active agents: " + g.V().hasLabel('agent_activity').has('is_active', true).count().next()
println ""

// Display active agents
println "Active Agents:"
println "=============="
g.V().hasLabel('agent_activity').has('is_active', true).each { agent ->
    println "- " + agent.value('agent_type') + " (strain: " + agent.value('strain_level') + ")"
}
println ""

// Display high strain entities
println "High Strain Entities:"
println "===================="
g.V().hasLabel('entity').has('strain_amplitude', gt(0.7)).each { entity ->
    println "- " + entity.value('name') + " (strain: " + entity.value('strain_amplitude') + ")"
}
println ""

println "Real-time agent visualization ready!"
println "Web interface: http://localhost:3001"
println "TinkerPop graph: http://localhost:8182" 