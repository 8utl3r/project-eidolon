#!/usr/bin/env python3
"""
Project Eidolon Graph Visualizer
A web-based GUI for exploring the strain-based knowledge graph
"""

from flask import Flask, render_template, jsonify, request, Response
import json
import os
import sys
from datetime import datetime
import threading
import time
import queue
import random

app = Flask(__name__)

# Sample data structure (in production, this would connect to TinkerPop)
class GraphVisualizer:
    def __init__(self):
        self.agents = []
        self.entities = []
        self.relationships = []
        self.load_real_data()
    
    def load_real_data(self):
        """Load real Project Eidolon data from the system"""
        try:
            # Load real agents
            self.load_real_agents()
            
            # Try to load entities and relationships from JSON file
            self.load_from_json()
                
        except Exception as e:
            print(f"Error loading real data: {e}")
            print("Falling back to sample data...")
            self.load_sample_data()
    
    def load_from_json(self):
        """Load entities and relationships from JSON file"""
        try:
            import json
            import os
            
            # Try AI-enhanced knowledge first, then comprehensive, then sample data
            ai_enhanced_file = os.path.join(os.path.dirname(__file__), 'comprehensive_knowledge_ai_enhanced.json')
            comprehensive_file = os.path.join(os.path.dirname(__file__), 'comprehensive_knowledge.json')
            sample_file = os.path.join(os.path.dirname(__file__), 'sample_data.json')
            
            if os.path.exists(ai_enhanced_file):
                with open(ai_enhanced_file, 'r') as f:
                    data = json.load(f)
                
                self.entities = data.get('entities', [])
                self.relationships = data.get('relationships', [])
                print(f"✅ Loaded AI-enhanced knowledge base:")
                print(f"   • {len(self.entities)} entities")
                print(f"   • {len(self.relationships)} relationships")
                
                # Count AI-created content
                ai_entities = [e for e in self.entities if 'created_by' in e]
                ai_relationships = [r for r in self.relationships if 'created_by' in r]
                print(f"   • AI-created entities: {len(ai_entities)}")
                print(f"   • AI-created relationships: {len(ai_relationships)}")
                
            elif os.path.exists(comprehensive_file):
                with open(comprehensive_file, 'r') as f:
                    data = json.load(f)
                
                self.entities = data.get('entities', [])
                self.relationships = data.get('relationships', [])
                stats = data.get('statistics', {})
                print(f"✅ Loaded comprehensive knowledge base:")
                print(f"   • {len(self.entities)} entities")
                print(f"   • {len(self.relationships)} relationships")
                if stats:
                    domain_stats = []
                    for k, v in stats.items():
                        if k.startswith(('mathematical', 'logical', 'physical', 'chemical', 'biological', 'computer', 'philosophical', 'psychological')):
                            formatted_key = k.replace('_', ' ').title()
                            domain_stats.append(f"{formatted_key}: {v}")
                    print(f"   • Domains: {', '.join(domain_stats)}")
            elif os.path.exists(sample_file):
                with open(sample_file, 'r') as f:
                    data = json.load(f)
                
                self.entities = data.get('entities', [])
                self.relationships = data.get('relationships', [])
                print(f"✅ Loaded {len(self.entities)} entities and {len(self.relationships)} relationships from sample data")
            else:
                print("No JSON data file found, using sample data")
                self.load_sample_data()
                
        except Exception as e:
            print(f"Error loading from JSON: {e}")
            self.load_sample_data()
        
        # Migrate entities to new field structure
        self.migrate_entities_to_new_structure()
    
    def migrate_entities_to_new_structure(self):
        """Migrate entities from old field names to new gravity-based structure"""
        current_time = time.time()
        
        for entity in self.entities:
            # Convert old strain_resistance to node_resistance
            if 'strain_resistance' in entity and 'node_resistance' not in entity:
                entity['node_resistance'] = entity['strain_resistance']
                del entity['strain_resistance']
            
            # Convert old strain_frequency to musical_frequency
            if 'strain_frequency' in entity and 'musical_frequency' not in entity:
                # Convert frequency to musical note (simplified mapping)
                old_freq = entity['strain_frequency']
                if old_freq <= 5:
                    entity['musical_frequency'] = 261  # C4
                elif old_freq <= 10:
                    entity['musical_frequency'] = 293  # D4
                elif old_freq <= 15:
                    entity['musical_frequency'] = 329  # E4
                elif old_freq <= 20:
                    entity['musical_frequency'] = 349  # F4
                else:
                    entity['musical_frequency'] = 440  # A4
                del entity['strain_frequency']
            
            # Add missing gravity-based fields
            if 'gravitational_mass' not in entity:
                entity['gravitational_mass'] = 1.0
            
            if 'last_accessed' not in entity:
                # Use modified date if available, otherwise current time
                if 'modified' in entity:
                    try:
                        import datetime
                        parsed_date = datetime.datetime.fromisoformat(entity['modified'].replace('Z', '+00:00'))
                        entity['last_accessed'] = parsed_date.timestamp()
                    except:
                        entity['last_accessed'] = current_time
                else:
                    entity['last_accessed'] = current_time
            
            # Ensure strain_amplitude exists
            if 'strain_amplitude' not in entity:
                entity['strain_amplitude'] = 0.0
            
            # Ensure access_count exists
            if 'access_count' not in entity:
                entity['access_count'] = 1
    
    def load_real_agents(self):
        """Load real agent data from the system"""
        try:
            # Define the real agents based on the Project Eidolon architecture
            self.agents = [
                {
                    "id": "engineer",
                    "name": "ThroneOfTheEngineer",
                    "agent": "The Engineer",
                    "domain": "mathematical reasoning and systematic processes",
                    "authority_level": "triggered",
                    "current_strain": 0.3,
                    "max_strain": 1.0,
                    "is_active": True,
                    "keywords": ["mathematics", "proof", "theorem", "calculation", "how do i", "process", "method", "procedure"],
                    "created": "2024-01-01T00:00:00",
                    "last_accessed": "2024-12-21T00:00:00"
                },
                {
                    "id": "skeptic",
                    "name": "ThroneOfTheSkeptic", 
                    "agent": "The Skeptic",
                    "domain": "logical analysis",
                    "authority_level": "triggered",
                    "current_strain": 0.2,
                    "max_strain": 1.0,
                    "is_active": True,
                    "keywords": ["logic", "skepticism", "analysis", "verification"],
                    "created": "2024-01-01T00:00:00",
                    "last_accessed": "2024-12-21T00:00:00"
                },
                {
                    "id": "dreamer",
                    "name": "ThroneOfTheDreamer",
                    "agent": "The Dreamer", 
                    "domain": "creative synthesis",
                    "authority_level": "triggered",
                    "current_strain": 0.4,
                    "max_strain": 1.0,
                    "is_active": True,
                    "keywords": ["creativity", "synthesis", "imagination", "innovation"],
                    "created": "2024-01-01T00:00:00",
                    "last_accessed": "2024-12-21T00:00:00"
                },
                {
                    "id": "philosopher",
                    "name": "ThroneOfThePhilosopher",
                    "agent": "The Philosopher",
                    "domain": "philosophical inquiry",
                    "authority_level": "triggered", 
                    "current_strain": 0.25,
                    "max_strain": 1.0,
                    "is_active": True,
                    "keywords": ["philosophy", "ethics", "metaphysics", "wisdom"],
                    "created": "2024-01-01T00:00:00",
                    "last_accessed": "2024-12-21T00:00:00"
                },
                {
                    "id": "investigator",
                    "name": "ThroneOfTheInvestigator",
                    "agent": "The Investigator",
                    "domain": "research and discovery",
                    "authority_level": "triggered",
                    "current_strain": 0.35,
                    "max_strain": 1.0,
                    "is_active": True,
                    "keywords": ["research", "investigation", "discovery", "evidence"],
                    "created": "2024-01-01T00:00:00",
                    "last_accessed": "2024-12-21T00:00:00"
                },
                {
                    "id": "archivist",
                    "name": "ThroneOfTheArchivist",
                    "agent": "The Archivist",
                    "domain": "knowledge management",
                    "authority_level": "triggered",
                    "current_strain": 0.1,
                    "max_strain": 1.0,
                    "is_active": True,
                    "keywords": ["archiving", "organization", "memory", "cataloging"],
                    "created": "2024-01-01T00:00:00",
                    "last_accessed": "2024-12-21T00:00:00"
                },
                {
                    "id": "stage_manager",
                    "name": "ThroneOfTheStageManager",
                    "agent": "The Stage Manager",
                    "domain": "context coordination",
                    "authority_level": "triggered",
                    "current_strain": 0.15,
                    "max_strain": 1.0,
                    "is_active": True,
                    "keywords": ["coordination", "context", "management", "orchestration"],
                    "created": "2024-01-01T00:00:00",
                    "last_accessed": "2024-12-21T00:00:00"
                }
            ]
            print(f"✅ Loaded {len(self.agents)} real agents")
            
        except Exception as e:
            print(f"Error loading real agents: {e}")
            self.agents = []
    
    def load_sample_data(self):
        """Load sample Project Eidolon data"""
        # Agents (Thrones)
        self.agents = [
            {
                "id": "skeptic",
                "name": "ThroneOfTheSkeptic",
                "agent": "The Skeptic",
                "domain": "skeptic",
                "authority_level": "triggered",
                "current_strain": 0.0,
                "max_strain": 1.0,
                "is_active": True,
                "keywords": ["logic", "validation", "skepticism"]
            },
            {
                "id": "engineer",
                "name": "ThroneOfTheEngineer", 
                "agent": "The Engineer",
                "domain": "engineer",
                "authority_level": "triggered",
                "current_strain": 0.0,
                "max_strain": 1.0,
                "is_active": True,
                "keywords": ["mathematics", "proofs", "calculations", "how do i", "process", "method", "procedure"]
            },
            {
                "id": "dreamer",
                "name": "ThroneOfTheDreamer",
                "agent": "The Dreamer", 
                "domain": "dreamer",
                "authority_level": "triggered",
                "current_strain": 0.0,
                "max_strain": 1.0,
                "is_active": True,
                "keywords": ["creativity", "imagination", "innovation"]
            },
            {
                "id": "philosopher",
                "name": "ThroneOfThePhilosopher",
                "agent": "The Philosopher",
                "domain": "philosopher", 
                "authority_level": "triggered",
                "current_strain": 0.0,
                "max_strain": 1.0,
                "is_active": True,
                "keywords": ["wisdom", "ethics", "metaphysics"]
            },
            {
                "id": "stage_manager",
                "name": "ThroneOfTheStage_manager",
                "agent": "The Stage Manager",
                "domain": "stage_manager",
                "authority_level": "triggered", 
                "current_strain": 0.0,
                "max_strain": 1.0,
                "is_active": True,
                "keywords": ["context", "coordination", "management"]
            },
            {
                "id": "investigator",
                "name": "ThroneOfTheInvestigator",
                "agent": "The Investigator",
                "domain": "investigator",
                "authority_level": "triggered",
                "current_strain": 0.0,
                "max_strain": 1.0,
                "is_active": True,
                "keywords": ["research", "analysis", "discovery"]
            },
            {
                "id": "archivist",
                "name": "ThroneOfTheArchivist",
                "agent": "The Archivist",
                "domain": "archivist",
                "authority_level": "triggered",
                "current_strain": 0.0,
                "max_strain": 1.0,
                "is_active": True,
                "keywords": ["memory", "storage", "retrieval"]
            }
        ]
        
        # Entities - Smallest units of knowledge for maximum connections
        self.entities = [
            {
                "id": "pythagorean",
                "name": "Pythagorean",
                "entity_type": "concept_type",
                "description": "Related to Pythagoras",
                "strain_amplitude": 0.0,  # No cognitive dissonance initially
                "node_resistance": 0.0,   # No incoming strain initially
                "musical_frequency": 440,  # A4
                "gravitational_mass": 1.0,
                "access_count": 5,
                "last_accessed": time.time()
            },
            {
                "id": "theorem",
                "name": "Theorem",
                "entity_type": "concept_type", 
                "description": "Mathematical statement proven true",
                "strain_amplitude": 0.0,
                "node_resistance": 0.0,
                "musical_frequency": 493,  # B4
                "gravitational_mass": 1.0,
                "access_count": 3,
                "last_accessed": time.time()
            },
            {
                "id": "logical_rule", 
                "name": "Modus Ponens",
                "entity_type": "concept_type",
                "description": "If P then Q, P, therefore Q",
                "strain_amplitude": 0.92,
                "strain_resistance": 0.1,
                "strain_frequency": 8,
                "access_count": 8
            },
            {
                "id": "context_info",
                "name": "Quantum Mechanics Context", 
                "entity_type": "concept_type",
                "description": "Physics domain context",
                "strain_amplitude": 0.45,
                "strain_resistance": 0.7,
                "strain_frequency": 3,
                "access_count": 3
            },
            {
                "id": "creative_concept",
                "name": "Neural Network Architecture",
                "entity_type": "concept_type", 
                "description": "AI system design",
                "strain_amplitude": 0.23,
                "strain_resistance": 0.9,
                "strain_frequency": 1,
                "access_count": 1
            },
            {
                "id": "person",
                "name": "Albert Einstein",
                "entity_type": "person",
                "description": "Theoretical physicist",
                "strain_amplitude": 0.78,
                "strain_resistance": 0.4,
                "strain_frequency": 6,
                "access_count": 6
            },
            {
                "id": "place",
                "name": "MIT",
                "entity_type": "place",
                "description": "Massachusetts Institute of Technology",
                "strain_amplitude": 0.65,
                "strain_resistance": 0.6,
                "strain_frequency": 4,
                "access_count": 4
            },
            {
                "id": "event",
                "name": "Quantum Revolution",
                "entity_type": "event",
                "description": "Early 20th century physics",
                "strain_amplitude": 0.89,
                "strain_resistance": 0.2,
                "strain_frequency": 7,
                "access_count": 7
            }
        ]
        
        # Authority Relationships
        self.relationships = [
            {
                "id": "auth_engineer_mathematical_theorem",
"from": "engineer",
                "to": "mathematical_theorem",
                "type": "has_authority",
                "authority_strength": 0.9,
                "strain_amplitude": 0.72
            },
            {
                "id": "auth_skeptic_logical_rule",
                "from": "skeptic", 
                "to": "logical_rule",
                "type": "has_authority",
                "authority_strength": 0.95,
                "strain_amplitude": 0.76
            },
            {
                "id": "auth_stage_manager_context_info",
                "from": "stage_manager",
                "to": "context_info", 
                "type": "has_authority",
                "authority_strength": 0.7,
                "strain_amplitude": 0.56
            },
            {
                "id": "auth_dreamer_creative_concept",
                "from": "dreamer",
                "to": "creative_concept",
                "type": "has_authority",
                "authority_strength": 0.6,
                "strain_amplitude": 0.48
            },
            {
                "id": "auth_philosopher_person",
                "from": "philosopher",
                "to": "person",
                "type": "has_authority", 
                "authority_strength": 0.8,
                "strain_amplitude": 0.64
            },
            {
                "id": "auth_investigator_event",
                "from": "investigator",
                "to": "event",
                "type": "has_authority",
                "authority_strength": 0.85,
                "strain_amplitude": 0.68
            },
            {
                "id": "auth_archivist_place",
                "from": "archivist",
                "to": "place",
                "type": "has_authority",
                "authority_strength": 0.75,
                "strain_amplitude": 0.60
            }
        ]
    
    def get_graph_stats(self):
        """Get graph statistics"""
        return {
            "total_agents": len(self.agents),
            "total_entities": len(self.entities),
            "total_relationships": len(self.relationships),
            "high_strain_entities": len([e for e in self.entities if e.get("strain_amplitude", 0.0) > 0.8]),
            "low_resistance_entities": len([e for e in self.entities if e.get("node_resistance", 0.0) < 0.5]),
            "high_frequency_entities": len([e for e in self.entities if e.get("musical_frequency", 0) > 500])
        }
    
    def get_agents(self):
        """Get all agents"""
        return self.agents
    
    def get_entities(self, strain_threshold=None, entity_type=None):
        """Get entities with optional filtering"""
        entities = self.entities
        
        if strain_threshold:
            entities = [e for e in entities if e["strain_amplitude"] > strain_threshold]
        
        if entity_type:
            entities = [e for e in entities if e["entity_type"] == entity_type]
        
        return entities
    
    def get_relationships(self, agent_id=None):
        """Get relationships with optional filtering"""
        relationships = self.relationships
        
        if agent_id:
            relationships = [r for r in relationships if r["from"] == agent_id]
        
        return relationships
    
    def get_all_nodes(self):
        """Get all nodes (agents + entities) for graph visualization"""
        nodes = []
        
        # Add agents
        for agent in self.agents:
            nodes.append({
                "id": agent["id"],
                "name": agent["agent"],
                "type": "throne",
                "strain": agent["current_strain"],
                "domain": agent["domain"],
                "isAgent": True,
                **agent
            })
        
        # Add entities
        for entity in self.entities:
            nodes.append({
                "id": entity["id"],
                "name": entity["name"],
                "type": "entity",
                "strain": entity.get("strain_amplitude", 0.0),
                "entityType": entity.get("entity_type", "concept_type"),
                "isAgent": False,
                **entity
            })
        
        return nodes
    
    def get_all_relationships(self):
        """Get all relationships for graph visualization"""
        return self.relationships

# Initialize the visualizer
visualizer = GraphVisualizer()

# Real-time update system
update_queue = queue.Queue()
last_update_time = time.time()

def background_updater():
    """Background thread for real-time updates"""
    global last_update_time
    while True:
        try:
            # Simulate real-time updates every 2 seconds
            time.sleep(2)
            current_time = time.time()
            
            # Update gravitational masses based on access patterns
            for agent in visualizer.agents:
                # Initialize missing fields for gravity calculations
                if 'gravitational_mass' not in agent:
                    agent['gravitational_mass'] = 1.0
                if 'last_accessed' not in agent:
                    agent['last_accessed'] = current_time
                if 'access_count' not in agent:
                    agent['access_count'] = 1
                
                # Simulate gravitational mass changes
                current_mass = agent['gravitational_mass']
                
                # Handle date conversion for agents
                try:
                    if isinstance(agent['last_accessed'], str):
                        # Try to parse ISO date string
                        import datetime
                        try:
                            parsed_date = datetime.datetime.fromisoformat(agent['last_accessed'].replace('Z', '+00:00'))
                            last_access = parsed_date.timestamp()
                        except:
                            # If parsing fails, use current time
                            last_access = current_time
                    else:
                        last_access = float(agent['last_accessed'])
                except:
                    last_access = current_time
                
                time_since_access = current_time - last_access
                access_count = int(agent['access_count'])
                
                # Calculate new gravitational mass using gravity formula
                time_factor = 1.0 + (1.0 / max(time_since_access, 1.0))
                new_mass = 1.0 * access_count * time_factor
                agent['gravitational_mass'] = new_mass
                agent['last_accessed'] = current_time
            
            for entity in visualizer.entities:
                # Initialize missing fields for gravity calculations
                if 'gravitational_mass' not in entity:
                    entity['gravitational_mass'] = 1.0
                if 'last_accessed' not in entity:
                    entity['last_accessed'] = current_time
                if 'access_count' not in entity:
                    entity['access_count'] = 1
                if 'strain_amplitude' not in entity:
                    entity['strain_amplitude'] = 0.0
                if 'node_resistance' not in entity:
                    entity['node_resistance'] = 0.0
                if 'musical_frequency' not in entity:
                    entity['musical_frequency'] = 440  # Default to A4
                
                # Handle date conversion for last_accessed
                try:
                    if isinstance(entity['last_accessed'], str):
                        # Try to parse ISO date string
                        import datetime
                        try:
                            parsed_date = datetime.datetime.fromisoformat(entity['last_accessed'].replace('Z', '+00:00'))
                            last_access = parsed_date.timestamp()
                        except:
                            # If parsing fails, use current time
                            last_access = current_time
                    else:
                        last_access = float(entity['last_accessed'])
                except:
                    last_access = current_time
                
                # Update gravitational mass
                current_mass = entity['gravitational_mass']
                time_since_access = current_time - last_access
                access_count = int(entity['access_count'])
                
                # Calculate new gravitational mass
                time_factor = 1.0 + (1.0 / max(time_since_access, 1.0))
                new_mass = 1.0 * access_count * time_factor
                entity['gravitational_mass'] = new_mass
                entity['last_accessed'] = current_time
                
                # Update node resistance as summed strain amplitudes
                # Simulate incoming strain from connections
                incoming_strains = [entity['strain_amplitude']]  # Self-strain
                total_resistance = sum(incoming_strains)
                entity['node_resistance'] = total_resistance
                
                # Decay cognitive dissonance over time (strain only exists when there's contradiction)
                current_strain = entity['strain_amplitude']
                if current_strain > 0.0:
                    # Simulate 5% chance of new contradiction detection
                    if random.random() < 0.05:
                        dissonance = random.uniform(0.1, 0.2)
                        entity['strain_amplitude'] = current_strain + dissonance
                    else:
                        # Decay existing strain
                        entity['strain_amplitude'] = max(0.0, current_strain * 0.98)
            
            last_update_time = current_time
            update_queue.put({
                'type': 'update',
                'timestamp': current_time,
                'data': {
                    'agents': visualizer.agents,
                    'entities': visualizer.entities
                }
            })
            
        except Exception as e:
            print(f"Background updater error: {e}")
            time.sleep(5)

# Start background updater thread
updater_thread = threading.Thread(target=background_updater, daemon=True)
updater_thread.start()

@app.route('/')
def index():
    """Main dashboard"""
    stats = visualizer.get_graph_stats()
    return render_template('dashboard.html', stats=stats)

@app.route('/api/stats')
def api_stats():
    """API endpoint for graph statistics"""
    return jsonify(visualizer.get_graph_stats())

@app.route('/api/agents')
def api_agents():
    """API endpoint for agents"""
    return jsonify(visualizer.get_agents())

@app.route('/api/entities')
def api_entities():
    """API endpoint for entities"""
    strain_threshold = request.args.get('strain_threshold', type=float)
    entity_type = request.args.get('entity_type')
    entities = visualizer.get_entities(strain_threshold, entity_type)
    return jsonify(entities)

@app.route('/api/relationships')
def api_relationships():
    """API endpoint for relationships"""
    agent_id = request.args.get('agent_id')
    relationships = visualizer.get_relationships(agent_id)
    return jsonify(relationships)

@app.route('/api/refresh')
def api_refresh():
    """API endpoint to refresh data from the system"""
    try:
        visualizer.load_real_data()
        return jsonify({
            "status": "success",
            "message": "Data refreshed successfully",
            "stats": visualizer.get_graph_stats()
        })
    except Exception as e:
        return jsonify({
            "status": "error",
            "message": f"Error refreshing data: {str(e)}"
        }), 500

@app.route('/api/graph-data')
def api_graph_data():
    """API endpoint to get complete graph data for the canvas"""
    return jsonify({
        "nodes": visualizer.get_all_nodes(),
        "links": visualizer.get_all_relationships()
    })

@app.route('/api/stream-updates')
def api_stream_updates():
    """Server-sent events endpoint for real-time updates"""
    def generate():
        while True:
            try:
                # Wait for updates with timeout
                try:
                    update = update_queue.get(timeout=5)
                    yield f"data: {json.dumps(update)}\n\n"
                except queue.Empty:
                    # Send heartbeat
                    yield f"data: {json.dumps({'type': 'heartbeat', 'timestamp': time.time()})}\n\n"
            except Exception as e:
                print(f"Stream error: {e}")
                break
    
    return Response(generate(), mimetype='text/event-stream')

@app.route('/api/process-prompt', methods=['POST'])
def api_process_prompt():
    """API endpoint to process user prompts and update the graph"""
    try:
        data = request.get_json()
        prompt = data.get('prompt', '').strip()
        
        if not prompt:
            return jsonify({
                'status': 'error',
                'message': 'No prompt provided'
            }), 400
        
        # Simulate prompt processing
        # In a real implementation, this would connect to the Project Eidolon system
        response = process_prompt(prompt)
        
        # Add the prompt and response to the update queue
        update_queue.put({
            'type': 'prompt_response',
            'timestamp': time.time(),
            'data': {
                'prompt': prompt,
                'response': response,
                'new_entities': response.get('new_entities', []),
                'new_relationships': response.get('new_relationships', [])
            }
        })
        
        return jsonify({
            'status': 'success',
            'message': 'Prompt processed successfully',
            'response': response
        })
        
    except Exception as e:
        return jsonify({
            'status': 'error',
            'message': f'Error processing prompt: {str(e)}'
        }), 500

def process_prompt(prompt):
    """Process a user prompt and return response with new graph elements"""
    # Simulate AI processing
    import random
    
    # Generate a mock response based on the prompt
    response = {
        'processed_prompt': prompt,
        'ai_response': f"Processing: {prompt}",
        'new_entities': [],
        'new_relationships': [],
        'strain_changes': []
    }
    
    # Extract individual words from prompt for granular node creation
    words = prompt.lower().split()
    current_time = time.time()
    
    # Create individual word nodes (smallest units of knowledge)
    for word in words:
        # Skip common words that don't add semantic value
        if word in ['the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of', 'with', 'by']:
            continue
            
        # Check if word node already exists
        existing_entity = next((e for e in visualizer.entities if e['name'].lower() == word), None)
        if existing_entity:
            # Update access count and last accessed time
            existing_entity['access_count'] += 1
            existing_entity['last_accessed'] = current_time
            continue
        
        # Create new word node
        new_entity = {
            'id': f'word_{word}_{int(current_time)}',
            'name': word,
            'entity_type': 'concept_type',
            'description': f'Word: {word}',
            'strain_amplitude': 0.0,  # No cognitive dissonance initially
            'node_resistance': 0.0,   # No incoming strain initially
            'musical_frequency': random.randint(261, 493),  # C4 to B4 range
            'gravitational_mass': 1.0,  # Base mass
            'access_count': 1,
            'last_accessed': current_time
        }
        response['new_entities'].append(new_entity)
        
        # Add to visualizer
        visualizer.entities.append(new_entity)
    
    # Simulate background agents creating connections between related concepts
    # This is where the exponential growth of connections happens
    for i, entity1 in enumerate(visualizer.entities[-len(words):]):  # New entities
        for j, entity2 in enumerate(visualizer.entities):
            if i != j and random.random() < 0.1:  # 10% chance of connection
                # Simulate semantic similarity detection
                relationship = {
                    'id': f'rel_{entity1["id"]}_{entity2["id"]}',
                    'from_entity': entity1['id'],
                    'to_entity': entity2['id'],
                    'relationship_type': 'semantic_similarity',
                    'strength': random.uniform(0.1, 0.9)
                }
                response['new_relationships'].append(relationship)
    
    # Simulate cognitive dissonance detection (only when contradictions exist)
    for entity in visualizer.entities[:5]:  # Check first 5 entities
        old_strain = entity.get('strain_amplitude', 0.0)
        
        # Only create strain if there's contradictory information
        # Simulate contradiction detection (5% chance)
        if random.random() < 0.05:
            dissonance = random.uniform(0.1, 0.2)  # Small cognitive dissonance
            entity['strain_amplitude'] = old_strain + dissonance
            response['strain_changes'].append({
                'entity_id': entity['id'],
                'old_strain': old_strain,
                'new_strain': entity['strain_amplitude'],
                'reason': 'cognitive dissonance detected'
            })
        else:
            # Decay existing strain over time
            entity['strain_amplitude'] = max(0.0, old_strain * 0.98)
    
    return response

@app.route('/agents')
def agents_page():
    """Agents visualization page"""
    return render_template('agents.html')

@app.route('/entities')
def entities_page():
    """Entities visualization page"""
    return render_template('entities.html')

@app.route('/relationships')
def relationships_page():
    """Relationships visualization page"""
    return render_template('relationships.html')

@app.route('/strain-analysis')
def strain_analysis_page():
    """Strain analysis page"""
    return render_template('strain_analysis.html')

@app.route('/graph-canvas')
def graph_canvas_page():
    """Interactive graph canvas page"""
    return render_template('graph_canvas.html')

import socket

def find_free_port(start_port=5000, max_attempts=100):
    """Find an available port starting from start_port"""
    for port in range(start_port, start_port + max_attempts):
        try:
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
                s.bind(('localhost', port))
                return port
        except OSError:
            continue
    raise RuntimeError(f"Could not find a free port in range {start_port}-{start_port + max_attempts}")

if __name__ == '__main__':
    print("Starting Project Eidolon Graph Visualizer...")
    
    # Use a fixed port for consistency
    port = 5002
    print(f"Starting on port: {port}")
    print(f"Open http://localhost:{port} in your browser")
    app.run(debug=True, host='0.0.0.0', port=port) 