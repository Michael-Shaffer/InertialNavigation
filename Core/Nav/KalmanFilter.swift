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




struct MotionState: Identifiable {
    let id = UUID()
    let timestamp: Date
    
    var posX: Double
    var velX: Double
    var accX: Double
    
    var posY: Double
    var velY: Double
    var accY: Double
    
    var posZ: Double
    var velZ: Double
    var accZ: Double
    
    var posMagnitude: Double {
        return (posX * posX + posY * posY + posZ * posZ).squareRoot()
    }
    
    static var zero: MotionState {
        return MotionState(
            timestamp: Date(),
            posX: 0, velX: 0, accX: 0,
            posY: 0, velY: 0, accY: 0,
            posZ: 0, velZ: 0, accZ: 0
        )
    }
}


class KalmanFilter {
    // Single-axis motion state
    private struct AxisState {
        var pos: Double
        var vel: Double
        var acc: Double
    }
    
    // State vector for each axis
    private var stateX = AxisState(pos: 0, vel: 0, acc: 0)
    private var stateY = AxisState(pos: 0, vel: 0, acc: 0)
    private var stateZ = AxisState(pos: 0, vel: 0, acc: 0)
    
    // State covariance matrix (3x3) for each axis
    private var covX: [[Double]]
    private var covY: [[Double]]
    private var covZ: [[Double]]
    
    // Process noise covariance
    private var procNoise: [[Double]]
    
    // Measurement noise covariance
    private var measNoise: Double
    
    // High-pass filter variables for each axis
    private var prevAccX = 0.0
    private var prevAccY = 0.0
    private var prevAccZ = 0.0
    private var filtAccX = 0.0
    private var filtAccY = 0.0
    private var filtAccZ = 0.0
    private let filterCoeff = 0.8 // Filter coefficient (0.7-0.9)
    
    // Threshold for stationary detection (m/s²)
    private let stationaryThreshold = 0.05
    
    init() {
        // Initial covariance with higher uncertainty for position and velocity
        let initialCov = [
            [10.0, 0.0, 0.0],  // Very High position uncertainty
            [0.0, 5.0, 0.0],   // High velocity uncertainty
            [0.0, 0.0, 1.0]    // Regular acceleration uncertainty
        ]
        
        covX = initialCov
        covY = initialCov
        covZ = initialCov

        // Process noise configuration
        procNoise = [
            [0.01, 0.0, 0.0],  // Very low position process noise
            [0.0, 0.01, 0.0],  // Low velocity process noise
            [0.0, 0.0, 1.0]    // Higher acceleration process noise
        ]

        // Measurement noise (typical for iPhone accelerometers)
        measNoise = 0.3
    }
    

    /// Updates motion state for all axes
    func update(accX: Double, accY: Double, accZ: Double, dt: Double) -> MotionState {
        // Update each axis
        updateAxis(acc: accX, state: &stateX, prevAcc: &prevAccX, filtAcc: &filtAccX, cov: &covX, dt: dt)
        updateAxis(acc: accY, state: &stateY, prevAcc: &prevAccY, filtAcc: &filtAccY, cov: &covY, dt: dt)
        updateAxis(acc: accZ, state: &stateZ, prevAcc: &prevAccZ, filtAcc: &filtAccZ, cov: &covZ, dt: dt)
        
        // Combine all axis states into one MotionState
        return MotionState(
            timestamp: Date(),
            posX: stateX.pos, velX: stateX.vel, accX: stateX.acc,
            posY: stateY.pos, velY: stateY.vel, accY: stateY.acc,
            posZ: stateZ.pos, velZ: stateZ.vel, accZ: stateZ.acc
        )
    }
    
    /// Updates state for one axis
    private func updateAxis(acc: Double, state: inout AxisState, prevAcc: inout Double, filtAcc: inout Double, cov: inout [[Double]], dt: Double) {
        // Apply high-pass filter to remove sensor bias
        filtAcc = filterCoeff * (filtAcc + acc - prevAcc)
        prevAcc = acc
        
        // Check if device is stationary
        let isStationary = abs(filtAcc) < stationaryThreshold
        
        if isStationary {
            // If stationary, reset velocity to prevent drift
            state.vel = 0.0
            // High confidence in zero velocity
            cov[1][1] = 0.001
        } else {
            // Regular prediction step for non-stationary state
            let oldPos = state.pos
            let oldVel = state.vel
            let oldAcc = state.acc
            
            // Predict next state
            state.pos = oldPos + oldVel * dt + 0.5 * oldAcc * dt * dt
            state.vel = oldVel + oldAcc * dt
        }
        
        // State transition matrix
        let stateTransMat: [[Double]] = [
            [1.0, dt, 0.5*dt*dt],
            [0.0, 1.0, dt],
            [0.0, 0.0, 1.0]
        ]
        
        // Update covariance: cov = F*cov*F' + Q
        cov = matrixAdd(
            matrixMultiply(
                matrixMultiply(stateTransMat, cov), 
                transpose(stateTransMat)
            ), 
            procNoise
        )
        
        // Measurement matrix (for acceleration only)
        let measMat: [Double] = [0.0, 0.0, 1.0]
        
        // Calculate Kalman gain
        let gain = calculateGain(cov, measMat, measNoise)
        
        // Innovation: difference between measurement and prediction
        let innovation = filtAcc - state.acc
        
        // Apply innovation
        if !isStationary {
            state.pos += gain[0] * innovation
            state.vel += gain[1] * innovation
        }
        state.acc += gain[2] * innovation
        
        // Update covariance: cov = (I - K*H)*cov
        updateCovariance(gain, measMat, &cov)
    }
    
    /// Resets the filter to initial state
    func reset() {
        stateX = AxisState(pos: 0, vel: 0, acc: 0)
        stateY = AxisState(pos: 0, vel: 0, acc: 0)
        stateZ = AxisState(pos: 0, vel: 0, acc: 0)
        
        filtAccX = 0.0
        filtAccY = 0.0
        filtAccZ = 0.0
        
        prevAccX = 0.0
        prevAccY = 0.0
        prevAccZ = 0.0
    }
    
    // MARK: - Matrix Operations
    
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
    
    private func calculateGain(_ cov: [[Double]], _ measMat: [Double], _ measNoise: Double) -> [Double] {
        // Simplified calculation for H = [0,0,1]
        // S = H*P*H' + R
        let s = cov[2][2] + measNoise
        
        // K = P*H'/S
        return [cov[0][2]/s, cov[1][2]/s, cov[2][2]/s]
    }
    
    private func updateCovariance(_ gain: [Double], _ measMat: [Double], _ cov: inout [[Double]]) {
        // For H = [0,0,1], K*H is a 3x3 matrix with K values in third column
        let identityMinusKH = [
            [1.0, 0.0, -gain[0]],
            [0.0, 1.0, -gain[1]],
            [0.0, 0.0, 1.0-gain[2]]
        ]
        
        // Update cov = (I - K*H)*cov
        cov = matrixMultiply(identityMinusKH, cov)
    }
}
