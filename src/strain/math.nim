# Gravity-Based Strain Calculation Math Functions
#
# This module contains pure mathematical functions for gravity-based strain calculations.
# Strain represents cognitive dissonance (contradictory information).
# Node resistance is the summed strain amplitudes from all connections.
# All functions are pure and take simple parameters to maximize testability.

import std/[math, tables]
import ../types
import ./types  # Import gravity-based strain types

proc calculateAmplitude*(access_count: int, base_amplitude: float, decay_rate: float, 
                        time_elapsed: float): float =
  ## Calculate strain amplitude based on access count and time decay
  ##
  ## Parameters:
  ## - access_count: Number of times entity was accessed
  ## - base_amplitude: Base amplitude multiplier
  ## - decay_rate: Rate of amplitude decay over time (0.0-1.0)
  ## - time_elapsed: Time elapsed since last access
  ##
  ## Returns: Strain amplitude (0.0-1.0)
  ##
  ## Formula: amplitude = access_count * base_amplitude * (decay_rate ^ time_elapsed)
  let decay_factor = pow(decay_rate, time_elapsed)
  let raw_amplitude = float(access_count) * base_amplitude * decay_factor
  return clamp(raw_amplitude, 0.0, 1.0)

proc calculateResistance*(frequency: int, connection_strength: float, 
                         max_frequency: int, max_connection: float): float =
  ## Calculate resistance based on frequency and connection strength
  ##
  ## Parameters:
  ## - frequency: Current frequency of access
  ## - connection_strength: Strength of connections
  ## - max_frequency: Maximum possible frequency
  ## - max_connection: Maximum possible connection strength
  ##
  ## Returns: Resistance value (0.0-1.0)
  ##
  ## Formula: resistance = (1 - frequency_ratio) * (1 - connection_ratio)
  let frequency_ratio = clamp(float(frequency) / float(max_frequency), 0.0, 1.0)
  let connection_ratio = clamp(connection_strength / max_connection, 0.0, 1.0)
  return (1.0 - frequency_ratio) * (1.0 - connection_ratio)

type
  StrainFlow* = object
    ## Represents strain flow between entities
    flow_amount*: float  ## Amount of strain flowing
    direction*: Vector3  ## Direction of flow

proc calculateStrainFlow*(from_amplitude: float, to_amplitude: float,
                         from_resistance: float, to_resistance: float,
                         distance_resistance: float): StrainFlow =
  ## Calculate strain flow between two entities
  ##
  ## Parameters:
  ## - from_amplitude: Strain amplitude of source entity
  ## - to_amplitude: Strain amplitude of target entity
  ## - from_resistance: Resistance of source entity
  ## - to_resistance: Resistance of target entity
  ## - distance_resistance: Resistance due to distance
  ##
  ## Returns: StrainFlow object with flow amount and direction
  ##
  ## Strain flows from high amplitude to low amplitude
  if from_amplitude <= to_amplitude:
    return StrainFlow(flow_amount: 0.0, direction: Vector3(x: 0.0, y: 0.0, z: 0.0))
  
  let amplitude_difference = from_amplitude - to_amplitude
  let total_resistance = from_resistance + to_resistance + distance_resistance
  
  let flow_amount = if total_resistance > 0: amplitude_difference / total_resistance else: amplitude_difference
  let direction = Vector3(x: 1.0, y: 0.0, z: 0.0)  # Simplified direction
  
  return StrainFlow(flow_amount: flow_amount, direction: direction)

proc calculateInterference*(flow1: StrainFlow, flow2: StrainFlow): float =
  ## Calculate interference between two strain flows
  ##
  ## Parameters:
  ## - flow1: First strain flow
  ## - flow2: Second strain flow
  ##
  ## Returns: Interference amount (0.0-1.0)
  ##
  ## Interference is based on dot product of flow directions
  let dot_product = flow1.direction.x * flow2.direction.x + 
                   flow1.direction.y * flow2.direction.y + 
                   flow1.direction.z * flow2.direction.z
  
  return abs(dot_product) * min(flow1.flow_amount, flow2.flow_amount)

proc calculateGravitationalMass*(access_count: int, time_since_access: float, 
                                base_mass: float = 1.0): float =
  ## Calculate gravitational mass based on access frequency and recency
  ##
  ## Parameters:
  ## - access_count: Number of times entity was accessed
  ## - time_since_access: Time since last access in seconds
  ## - base_mass: Base gravitational mass unit
  ##
  ## Returns: Gravitational mass (unbounded, can grow indefinitely)
  ##
  ## Formula: mass = base_mass * access_count * (1 + 1/time_since_access)
  ## This creates a gravitational well that grows with access and decays with time
  let time_factor = if time_since_access > 0: 1.0 + (1.0 / time_since_access) else: 1.0
  return base_mass * float(access_count) * time_factor

proc calculateNodeResistance*(incoming_strains: seq[float]): NodeResistance =
  ## Calculate node resistance as summed strain amplitudes
  ##
  ## Parameters:
  ## - incoming_strains: Sequence of strain amplitudes from incoming connections
  ##
  ## Returns: NodeResistance object with summed and averaged values
  ##
  ## Formula: resistance = sum of all incoming strain amplitudes
  var total_amplitude = 0.0
  for strain in incoming_strains:
    total_amplitude += strain
  
  let connection_count = incoming_strains.len
  let average_amplitude = if connection_count > 0: total_amplitude / float(connection_count) else: 0.0
  
  return NodeResistance(
    total_strain_amplitude: total_amplitude,
    connection_count: connection_count,
    average_amplitude: average_amplitude
  )

proc calculateGravitationalForce*(mass1: float, mass2: float, distance: float, 
                                 gravitational_constant: float): float =
  ## Calculate gravitational force between two entities
  ##
  ## Parameters:
  ## - mass1: Gravitational mass of first entity
  ## - mass2: Gravitational mass of second entity
  ## - distance: Distance between entities
  ## - gravitational_constant: G constant for gravity calculations
  ##
  ## Returns: Gravitational force magnitude (unbounded)
  ##
  ## Formula: F = G * (m1 * m2) / (distance^2)
  if distance <= 0:
    return 0.0  # Avoid division by zero
  
  return gravitational_constant * mass1 * mass2 / (distance * distance)

proc calculateGravityFlow*(from_mass: float, to_mass: float, distance: float,
                          gravitational_constant: float): GravityFlow =
  ## Calculate gravitational flow between two entities
  ##
  ## Parameters:
  ## - from_mass: Gravitational mass of source entity
  ## - to_mass: Gravitational mass of target entity
  ## - distance: Distance between entities
  ## - gravitational_constant: G constant for gravity calculations
  ##
  ## Returns: GravityFlow object with force magnitude and direction
  ##
  ## Gravitational flow is always attractive (positive force)
  let force_magnitude = calculateGravitationalForce(from_mass, to_mass, distance, gravitational_constant)
  let mass_difference = from_mass - to_mass
  
  # Direction points from source to target (attractive force)
  let direction = Vector3(x: 1.0, y: 0.0, z: 0.0)  # Simplified - would be calculated from actual positions
  
  return GravityFlow(
    force_magnitude: force_magnitude,
    direction: direction,
    mass_difference: mass_difference
  )

proc detectCognitiveDissonance*(entity1_attributes: Table[string, string], 
                               entity2_attributes: Table[string, string],
                               dissonance_threshold: float): float =
  ## Detect cognitive dissonance (contradictory information) between entities
  ##
  ## Parameters:
  ## - entity1_attributes: Attributes of first entity
  ## - entity2_attributes: Attributes of second entity
  ## - dissonance_threshold: Threshold for detecting contradictions
  ##
  ## Returns: Strain amplitude (0.0 if no contradiction, >0.0 if contradiction found)
  ##
  ## Strain only exists when there is contradictory information
  var dissonance_score = 0.0
  var comparison_count = 0
  
  for key, value1 in entity1_attributes:
    if entity2_attributes.hasKey(key):
      let value2 = entity2_attributes[key]
      comparison_count += 1
      
      # Check for contradictions in common attributes
      if value1 != value2:
        dissonance_score += 1.0
  
  # Normalize by number of comparisons
  if comparison_count > 0:
    dissonance_score = dissonance_score / float(comparison_count)
  
  # Only return strain if above threshold (contradiction detected)
  if dissonance_score > dissonance_threshold:
    return dissonance_score
  else:
    return 0.0

proc assignMusicalNote*(entity_id: string, related_entities: seq[string], 
                       existing_assignments: Table[string, MusicalFrequency]): MusicalFrequency =
  ## Assign a musical note to an entity for pleasant chord formation
  ##
  ## Parameters:
  ## - entity_id: ID of entity to assign note to
  ## - related_entities: IDs of related entities
  ## - existing_assignments: Current musical note assignments
  ##
  ## Returns: MusicalFrequency object with assigned note
  ##
  ## Goal: Related subjects form pleasant chords when played simultaneously
  
  # Simple assignment strategy: use entity ID hash to determine note
  var hash_value = 0
  for c in entity_id:
    hash_value += ord(c)
  
  let note_index = hash_value mod 12
  let note = case note_index
    of 0: C
    of 1: C_sharp
    of 2: D
    of 3: D_sharp
    of 4: E
    of 5: F
    of 6: F_sharp
    of 7: G
    of 8: G_sharp
    of 9: A
    of 10: A_sharp
    of 11: B
    else: C
  
  let octave = (hash_value div 12) mod 9  # 0-8 octaves
  let base_frequency = NOTE_FREQUENCIES[note]
  let frequency_hz = base_frequency * pow(2.0, float(octave - 4))  # A4 = 440 Hz is octave 4
  
  # Find related entities in same chord
  var chord_membership: seq[string]
  for related_id in related_entities:
    if existing_assignments.hasKey(related_id):
      chord_membership.add(related_id)
  
  return MusicalFrequency(
    note: note,
    octave: octave,
    frequency_hz: frequency_hz,
    chord_membership: chord_membership
  )

proc calculateChordHarmony*(frequencies: seq[MusicalFrequency]): float =
  ## Calculate harmony score for a group of musical frequencies
  ##
  ## Parameters:
  ## - frequencies: Musical frequencies to evaluate
  ##
  ## Returns: Harmony score (0.0-1.0, higher is more harmonious)
  ##
  ## Evaluates how pleasant the chord sounds when played together
  if frequencies.len < 2:
    return 1.0  # Single note is always harmonious
  
  var harmony_score = 1.0
  
  # Check for pleasant intervals
  for i in 0..<frequencies.len:
    for j in (i+1)..<frequencies.len:
      let freq1 = frequencies[i].frequency_hz
      let freq2 = frequencies[j].frequency_hz
      
      # Calculate interval ratio
      let ratio = if freq1 > freq2: freq1 / freq2 else: freq2 / freq1
      
      # Pleasant intervals (simplified)
      let pleasant_intervals = @[1.0, 1.25, 1.5, 2.0, 2.5, 3.0]  # Unison, major third, perfect fifth, octave, etc.
      
      var interval_harmony = 0.0
      for pleasant_ratio in pleasant_intervals:
        let difference = abs(ratio - pleasant_ratio)
        if difference < 0.1:  # Close to pleasant interval
          interval_harmony = 1.0 - (difference / 0.1)
          break
      
      harmony_score *= interval_harmony
  
  return harmony_score

proc updateStrainFromDissonance*(current_strain: float, dissonance_detected: float,
                                time_elapsed: float, decay_rate: float = 0.95): float =
  ## Update strain based on detected cognitive dissonance
  ##
  ## Parameters:
  ## - current_strain: Current strain amplitude
  ## - dissonance_detected: New dissonance detected (0.0 if none)
  ## - time_elapsed: Time elapsed since last update
  ## - decay_rate: Rate at which strain decays over time
  ##
  ## Returns: Updated strain amplitude
  ##
  ## Strain only exists when there is contradictory information
  if dissonance_detected > 0.0:
    # Add new dissonance to current strain
    return current_strain + dissonance_detected
  else:
    # Decay existing strain over time
    return current_strain * pow(decay_rate, time_elapsed) 