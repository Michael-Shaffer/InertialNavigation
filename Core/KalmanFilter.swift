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
    
    // High-pass filter variables
    private var prevAcceleration = 0.0
    private var filteredAcceleration = 0.0
    private let alpha = 0.8 // Filter coefficient (0.7-0.9)
    
    init() {
        // Initial state
        x = State(position: 0, velocity: 0, acceleration: 0)
        
        // Increase uncertainty for position and velocity states
        P = [
            [10.0, 0.0, 0.0],  // Higher position uncertainty
            [0.0, 5.0, 0.0],   // Higher velocity uncertainty
            [0.0, 0.0, 1.0]    // Regular acceleration uncertainty
        ]

        // Reduce process noise for position, increase for acceleration
        Q = [
            [0.01, 0.0, 0.0], // Very low position process noise
            [0.0, 0.01, 0.0],  // Low velocity process noise
            [0.0, 0.0, 1.0]    // Higher acceleration process noise
        ]

        // Adjust measurement noise based on accelerometer quality
        // For iPhone accelerometers, between 0.1-0.5 is reasonable
        R = 0.3
    }
    
    func update(acceleration: Double, dt: Double) -> State {
        // Apply high-pass filter to remove sensor bias
        filteredAcceleration = alpha * (filteredAcceleration + acceleration - prevAcceleration)
        prevAcceleration = acceleration
        let filteredAcc = filteredAcceleration
        
        // Check if device is stationary
        let isStationary = detectStationary(accelerationMagnitude: filteredAcc)
        
        if isStationary {
            // If stationary, reset velocity to prevent drift
            x.velocity = 0.0
            // High confidence in zero velocity
            P[1][1] = 0.001
        } else {
            // Regular prediction step for non-stationary state
            let oldPosition = x.position
            let oldVelocity = x.velocity
            let oldAcceleration = x.acceleration
            
            // Predict next state
            x.position = oldPosition + oldVelocity * dt + 0.5 * oldAcceleration * dt * dt
            x.velocity = oldVelocity + oldAcceleration * dt
        }
        
        // State transition matrix
        let F: [[Double]] = [
            [1.0, dt, 0.5*dt*dt],
            [0.0, 1.0, dt],
            [0.0, 0.0, 1.0]
        ]
        
        // Update covariance: P = F*P*F' + Q
        P = matrixAdd(matrixMultiply(matrixMultiply(F, P), transpose(F)), Q)
        
        // Measurement update with filtered acceleration
        let H: [Double] = [0.0, 0.0, 1.0]
        
        // Calculate Kalman gain
        let K = calculateKalmanGain(P, H, R)
        
        // Update state with measurement: x = x + K*(z - H*x)
        // Use filtered acceleration for innovation
        let innovation = filteredAcc - x.acceleration
        
        // Apply innovation only if not stationary or for acceleration
        if !isStationary {
            x.position += K[0] * innovation
            x.velocity += K[1] * innovation
        }
        x.acceleration += K[2] * innovation
        
        // Update covariance: P = (I - K*H)*P
        updateCovariance(K, H)
        
        return x
    }
    
    // Proper matrix operations implementation
    private func matrixMultiply(_ a: [[Double]], _ b: [[Double]]) -> [[Double]] {
        let rowsA = a.count
        let colsA = a[0].count
        let colsB = b[0].count
        
        var result = Array(repeating: Array(repeating: 0.0, count: colsB), count: rowsA)
        
        for i in 0..<rowsA {
            for j in 0..<colsB {
                for k in 0..<colsA {
                    result[i][j] += a[i][k] * b[k][j]
                }
            }
        }
        
        return result
    }
    
    private func transpose(_ a: [[Double]]) -> [[Double]] {
        let rows = a.count
        let cols = a[0].count
        
        var result = Array(repeating: Array(repeating: 0.0, count: rows), count: cols)
        
        for i in 0..<rows {
            for j in 0..<cols {
                result[j][i] = a[i][j]
            }
        }
        
        return result
    }
    
    private func matrixAdd(_ a: [[Double]], _ b: [[Double]]) -> [[Double]] {
        let rows = a.count
        let cols = a[0].count
        
        var result = Array(repeating: Array(repeating: 0.0, count: cols), count: rows)
        
        for i in 0..<rows {
            for j in 0..<cols {
                result[i][j] = a[i][j] + b[i][j]
            }
        }
        
        return result
    }
    
    private func calculateKalmanGain(_ P: [[Double]], _ H: [Double], _ R: Double) -> [Double] {
        // This is a simplified calculation for the case where H = [0,0,1]
        // and R is a scalar
        
        // S = H*P*H' + R, which simplifies to P[2][2] + R for H = [0,0,1]
        let S = P[2][2] + R
        
        // K = P*H'/S
        // For H = [0,0,1], P*H' is just the third column of P
        return [P[0][2]/S, P[1][2]/S, P[2][2]/S]
    }
    
    private func updateCovariance(_ K: [Double], _ H: [Double]) {
        // P = (I - K*H)*P
        // For H = [0,0,1], K*H is a 3x3 matrix with the K values in the third column
        
        // Create I - K*H matrix
        let IKH = [
            [1.0, 0.0, -K[0]],
            [0.0, 1.0, -K[1]],
            [0.0, 0.0, 1.0-K[2]]
        ]
        
        // Update P = (I - K*H)*P
        P = matrixMultiply(IKH, P)
    }
    
    func detectStationary(accelerationMagnitude: Double) -> Bool {
        return abs(accelerationMagnitude) < 0.05 // Threshold in m/s²
    }
    
    // Reset method to manually recalibrate when needed
    func reset() {
        x.position = 0.0
        x.velocity = 0.0
        filteredAcceleration = 0.0
        prevAcceleration = 0.0
    }
}
