//
//  KalmanFilter.swift
//  InertialNavigation
//
//  Created by Michael Shaffer on 4/7/25.
//

import Foundation
import SwiftUI
import CoreMotion
import Charts




struct State {
    var position: Double
    var velocity: Double
    var acceleration: Double
}





class KalmanFilter {
    // State vector [position, velocity, acceleration]
    private var x: State
    
    // State covariance matrix (3x3)
    private var P: [[Double]]
    
    // Process noise covariance
    private var Q: [[Double]]
    
    // Measurement noise covariance
    private var R: Double
    
    init() {
        // Initial state
        x = State(position: 0, velocity: 0, acceleration: 0)
        
        // Increase uncertainty for position and velocity states
        P = [
            [20.0, 0.0, 0.0],  // Higher position uncertainty
            [0.0, 10.0, 0.0],   // Higher velocity uncertainty
            [0.0, 0.0, 1.0]    // Regular acceleration uncertainty
        ]

        // Reduce process noise for position, increase for acceleration
        Q = [
            [0.00001, 0.0, 0.0], // Very low position process noise
            [0.0, 0.001, 0.0],  // Low velocity process noise
            [0.0, 0.0, 1.0]    // Higher acceleration process noise
        ]

        // Adjust measurement noise based on accelerometer quality
        // For iPhone accelerometers, between 0.1-0.5 is reasonable
        R = 0.3
    }
    
    func update(acceleration: Double, dt: Double) -> State {
        // Prediction step: x = F*x
        // For constant acceleration model:
        // position += velocity*dt + 0.5*acceleration*dt*dt
        // velocity += acceleration*dt
        // acceleration stays the same
        
        let oldPosition = x.position
        let oldVelocity = x.velocity
        let oldAcceleration = x.acceleration
        
        // Predict next state
        x.position = oldPosition + oldVelocity * dt + 0.5 * oldAcceleration * dt * dt
        x.velocity = oldVelocity + oldAcceleration * dt
        // Acceleration remains unchanged in prediction
        
        // State transition matrix
        let F: [[Double]] = [
            [1.0, dt, 0.5*dt*dt],
            [0.0, 1.0, dt],
            [0.0, 0.0, 1.0]
        ]
        
        // Update covariance: P = F*P*F' + Q
        // (simplified - in a real implementation you'd perform the matrix multiplication)
        // This represents how uncertainty grows during prediction
        P = matrixAdd(matrixMultiply(matrixMultiply(F, P), transpose(F)), Q)
        
        // Measurement update
        // Kalman gain: K = P*H'/(H*P*H' + R)
        // Where H = [0, 0, 1] because we only measure acceleration
        let H: [Double] = [0.0, 0.0, 1.0]
        
        // Calculate Kalman gain (simplified)
        let K = calculateKalmanGain(P, H, R)
        
        // Update state with measurement: x = x + K*(z - H*x)
        // Where z is the measured acceleration
        let innovation = acceleration - x.acceleration
        x.position += K[0] * innovation
        x.velocity += K[1] * innovation
        x.acceleration += K[2] * innovation
        
        // Update covariance: P = (I - K*H)*P
        // (simplified)
        updateCovariance(K, H)
        
        return x
    }
    
    // Matrix operation placeholders
    private func matrixMultiply(_ a: [[Double]], _ b: [[Double]]) -> [[Double]] {
        // Implementation omitted for brevity
        return a // Placeholder
    }
    
    private func transpose(_ a: [[Double]]) -> [[Double]] {
        // Implementation omitted for brevity
        return a // Placeholder
    }
    
    private func matrixAdd(_ a: [[Double]], _ b: [[Double]]) -> [[Double]] {
        // Implementation omitted for brevity
        return a // Placeholder
    }
    
    private func calculateKalmanGain(_ P: [[Double]], _ H: [Double], _ R: Double) -> [Double] {
        // Implementation omitted for brevity
        return [0.1, 0.2, 0.7] // Placeholder values
    }
    
    private func updateCovariance(_ K: [Double], _ H: [Double]) {
        // Implementation omitted for brevity
    }
    
    // Add this to your Kalman filter class
    func detectStationary(accelerationMagnitude: Double) -> Bool {
        return abs(accelerationMagnitude) < 0.05 // Threshold in m/s²
    }
}
