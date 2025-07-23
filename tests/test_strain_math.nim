# Strain Math Function Tests
#
# Tests for pure mathematical functions in the strain calculation system.
# Tests are modular and can be enabled/disabled for performance.

import std/unittest
import ../src/types
import ../src/strain/types
import ../src/strain/math

# Test configuration - set to false to disable tests for performance
const RUN_STRAIN_MATH_TESTS* = true

when RUN_STRAIN_MATH_TESTS:
  suite "Strain Math Function Tests":
    
    test "Clamp Function":
      ## Test the clamp utility function
      check clamp(0.5, 0.0, 1.0) == 0.5
      check clamp(-1.0, 0.0, 1.0) == 0.0
      check clamp(2.0, 0.0, 1.0) == 1.0
      check clamp(0.0, 0.0, 1.0) == 0.0
      check clamp(1.0, 0.0, 1.0) == 1.0
    
    test "Amplitude Calculation":
      ## Test pure amplitude calculation function
      # Test basic calculation
      let result1 = calculateAmplitude(10, 1.1, 0.95, 1.0)
      check result1 > 0.0
      check result1 <= 1.0
      
      # Test decay over time - decay should reduce amplitude
      discard calculateAmplitude(5, 1.0, 0.9, 0.0)  # No time elapsed: 5 * 1.0 * 1.0 = 5.0 -> clamped to 1.0
      discard calculateAmplitude(5, 1.0, 0.9, 1.0) # Time elapsed: 5 * 1.0 * 0.9 = 4.5 -> clamped to 1.0
      
      # Use smaller values to see actual decay
      let result4 = calculateAmplitude(1, 0.5, 0.9, 0.0)  # No time: 1 * 0.5 * 1.0 = 0.5
      let result5 = calculateAmplitude(1, 0.5, 0.9, 1.0) # Time: 1 * 0.5 * 0.9 = 0.45
      check result4 > result5  # With decay rate < 1.0, amplitude decreases over time
      
      # Test edge cases
      check calculateAmplitude(0, 1.1, 0.95, 1.0) == 0.0  # No accesses
      check calculateAmplitude(1000, 1.1, 0.95, 0.0) <= 1.0  # Should be clamped
    
    test "Resistance Calculation":
      ## Test resistance calculation function
      # Test basic calculation
      let result1 = calculateResistance(50, 25.0, 100, 50)
      check result1 >= 0.0
      check result1 <= 1.0
      
      # Test high frequency = low resistance
      let low_freq = calculateResistance(10, 25.0, 100, 50)
      let high_freq = calculateResistance(90, 25.0, 100, 50)
      check low_freq > high_freq
      
      # Test high connection strength = low resistance
      let low_conn = calculateResistance(50, 10.0, 100, 50)
      let high_conn = calculateResistance(50, 40.0, 100, 50)
      check low_conn > high_conn
    
    test "Strain Flow Calculation":
      ## Test strain flow calculation function
      # Test flow from high to low amplitude
      let flow1 = calculateStrainFlow(0.8, 0.2, 0.1, 0.1, 0.1)
      check flow1.flow_amount > 0.0
      check flow1.direction.x == 1.0  # Simple direction
      
      # Test no flow when target has higher amplitude
      let flow2 = calculateStrainFlow(0.2, 0.8, 0.1, 0.1, 0.1)
      check flow2.flow_amount == 0.0
      
      # Test resistance reduces flow
      let flow3 = calculateStrainFlow(0.8, 0.2, 0.0, 0.0, 0.0)  # No resistance
      let flow4 = calculateStrainFlow(0.8, 0.2, 0.9, 0.9, 0.9)  # High resistance
      check flow3.flow_amount > flow4.flow_amount
    
    test "Interference Calculation":
      ## Test interference calculation function
      let flow1 = StrainFlow(flow_amount: 0.5, direction: Vector3(x: 1.0, y: 0.0, z: 0.0))
      let flow2 = StrainFlow(flow_amount: 0.3, direction: Vector3(x: 1.0, y: 0.0, z: 0.0))
      
      # Test parallel flows (high interference)
      let interference1 = calculateInterference(flow1, flow2)
      check interference1 > 0.0
      
      # Test perpendicular flows (low interference)
      let flow3 = StrainFlow(flow_amount: 0.5, direction: Vector3(x: 0.0, y: 1.0, z: 0.0))
      let interference2 = calculateInterference(flow1, flow3)
      check interference2 < interference1
      
      # Test zero flows
      let flow4 = StrainFlow(flow_amount: 0.0, direction: Vector3(x: 1.0, y: 0.0, z: 0.0))
      check calculateInterference(flow1, flow4) == 0.0 