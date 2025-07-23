# Gravity-Based Strain Calculation Types
# 
# This module defines strain-specific types using gravity metaphors.
# Strain represents cognitive dissonance (contradictory information).
# Node resistance is the summed strain amplitudes from all connections.
# Frequency represents musical notes for pleasant chord formation.

import ../types
import std/tables

type
  MusicalNote* = enum
    ## Musical notes for frequency assignment
    C, C_sharp, D, D_sharp, E, F, F_sharp, G, G_sharp, A, A_sharp, B

  MusicalChord* = enum
    ## Pleasant musical chords for related subjects
    major, minor, diminished, augmented, major_seventh, minor_seventh

  GravityParameters* = object
    ## Global parameters for gravity-based strain calculations
    gravitational_constant*: float    ## G constant for gravity calculations (default: 6.67430e-11)
    mass_unit*: float                 ## Unit mass for entities (default: 1.0)
    distance_unit*: float             ## Unit distance for relationships (default: 1.0)
    dissonance_threshold*: float      ## Threshold for detecting contradictory information (default: 0.1)
    chord_formation_threshold*: float ## Threshold for forming musical chords (default: 0.3)
    strain_update_interval*: float    ## How often to update strain (default: 1.0 seconds)

  GravityFlow* = object
    ## Represents gravitational flow between entities
    force_magnitude*: float  ## Gravitational force magnitude
    direction*: Vector3      ## Direction of gravitational pull
    mass_difference*: float  ## Difference in gravitational mass

  NodeResistance* = object
    ## Node resistance as summed strain amplitudes
    total_strain_amplitude*: float  ## Sum of all incoming strain amplitudes
    connection_count*: int          ## Number of connections contributing
    average_amplitude*: float       ## Average strain amplitude per connection

  MusicalFrequency* = object
    ## Musical frequency assignment for entities
    note*: MusicalNote              ## Musical note assigned
    octave*: int                    ## Octave number (0-8)
    frequency_hz*: float            ## Actual frequency in Hz
    chord_membership*: seq[string]  ## IDs of entities in same chord

# Default gravity parameters
const DEFAULT_GRAVITY_PARAMETERS* = GravityParameters(
  gravitational_constant: 6.67430e-11,
  mass_unit: 1.0,
  distance_unit: 1.0,
  dissonance_threshold: 0.1,
  chord_formation_threshold: 0.3,
  strain_update_interval: 1.0
)

# Musical note frequencies (A4 = 440 Hz)
const NOTE_FREQUENCIES* = {
  C: 261.63, C_sharp: 277.18, D: 293.66, D_sharp: 311.13,
  E: 329.63, F: 349.23, F_sharp: 369.99, G: 392.00,
  G_sharp: 415.30, A: 440.00, A_sharp: 466.16, B: 493.88
}.toTable

# Pleasant chord definitions
const PLEASANT_CHORDS* = {
  major: @[0, 4, 7],           # Root, major third, perfect fifth
  minor: @[0, 3, 7],           # Root, minor third, perfect fifth
  diminished: @[0, 3, 6],      # Root, minor third, diminished fifth
  augmented: @[0, 4, 8],       # Root, major third, augmented fifth
  major_seventh: @[0, 4, 7, 11], # Root, major third, perfect fifth, major seventh
  minor_seventh: @[0, 3, 7, 10]  # Root, minor third, perfect fifth, minor seventh
}.toTable 