//
//  Sensors.swift
//  InertialNavigation
//
//  Created by Michael Shaffer on 4/1/25.
//

import SwiftUI
import CoreMotion
import Charts




// Data structure to hold acceleration readings
struct Reading: Identifiable {
    let id = UUID()
    let timestamp: Date
    let accX: Double
    let velX: Double
    let posX: Double
}



//
class AccelerometerModel: ObservableObject {
    @Published var readings: [Reading] = []
    @Published var accX: Double = 0
    @Published var velX: Double = 0
    @Published var posX: Double = 0
    
    private let kalmanFilter = KalmanFilter()
    let motionManager = CMMotionManager()
    let maxReadings = 50
    let dt = 0.1
    
    
    func startAccelerometer() {
        guard motionManager.isDeviceMotionAvailable else { return }
        
        motionManager.deviceMotionUpdateInterval = dt
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self = self, let motion = motion else { return }
            
            // Get current acceleration in m/s²
            let currentAccX = motion.userAcceleration.x * 9.81
            
            // Update state with Kalman filter
            let state = self.kalmanFilter.update(acceleration: currentAccX, dt: self.dt)
            
            // Update published properties
            self.accX = state.acceleration
            self.velX = state.velocity
            self.posX = state.position
            
            // Add new reading
            self.readings.append(Reading(
                timestamp: Date(),
                accX: self.accX,
                velX: self.velX,
                posX: self.posX
            ))
            
            // Remove oldest readings if needed
            if self.readings.count > self.maxReadings {
                self.readings.removeFirst(self.readings.count - self.maxReadings)
            }
        }
    }
    
    func stopAccelerometer() {
        motionManager.stopAccelerometerUpdates()
    }
    
    func clearReadings() {
        readings.removeAll()
        // self.readings.append(Reading(timestamp: Date(), accX: self.accX, velX: self.velX, posX: self.posX)) // Ensure non-nil reading
        self.readings.append(Reading(timestamp: Date(), accX: 0, velX: 0, posX: 0))
    }
}



//
struct AccelerationChartView: View {
    let readings: [Reading]
    let axis: String
    let valueKeyPath: KeyPath<Reading, Double>
    let color: Color
    
    var body: some View {
        
        Chart {
            ForEach(readings) { reading in
                LineMark(
                    x: .value("Time", reading.timestamp),
                    y: .value(axis, reading[keyPath: valueKeyPath])
                )
                .foregroundStyle(color)
            }
        }
        .chartXAxis {
            AxisMarks { _ in
                AxisGridLine()
                AxisTick()
            }
        }
        .chartYScale(domain: -1...1)
        .chartLegend(position: .bottom)
        .frame(height: 100)
        .padding()
    }
}



struct SensorsView: View {
    @StateObject private var sensorsModel = AccelerometerModel()
    
    var body: some View {
        VStack {

            // X-axis acceleration
            Text("Acceleration")
            AccelerationChartView(
                readings: sensorsModel.readings,
                axis: "X",
                valueKeyPath: \.accX,
                color: .red
            )
            .padding(20)
            
            // X-axis velocity
            Text("Velocity")
            AccelerationChartView(
                readings: sensorsModel.readings,
                axis: "X",
                valueKeyPath: \.velX,
                color: .red
            )
            .padding(20)
            
            // X-axis position
            Text("Position")
            AccelerationChartView(
                readings: sensorsModel.readings,
                axis: "X",
                valueKeyPath: \.posX,
                color: .red
            )
            .padding(20)
            
            Button("Clear Data") {
                sensorsModel.clearReadings()
            }
            .padding()
        }
        .onAppear { sensorsModel.startAccelerometer() }
        .onDisappear { sensorsModel.stopAccelerometer() }
    }
}



#Preview {
    SensorsView()
}
