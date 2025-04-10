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
    
    let accY: Double
    let velY: Double
    let posY: Double
    
    let accZ: Double
    let velZ: Double
    let posZ: Double
}



//
class AccelerometerModel: ObservableObject {
    @Published var readings: [Reading] = []
    
    @Published var accX: Double = 0
    @Published var velX: Double = 0
    @Published var posX: Double = 0
    
    @Published var accY: Double = 0
    @Published var velY: Double = 0
    @Published var posY: Double = 0
    
    @Published var accZ: Double = 0
    @Published var velZ: Double = 0
    @Published var posZ: Double = 0
    
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
            let currentAccY = motion.userAcceleration.y * 9.81
            let currentAccZ = motion.userAcceleration.z * 9.81
            
            // Update state with Kalman filter
            let stateX = self.kalmanFilter.update(acceleration: currentAccX, dt: self.dt)
            let stateY = self.kalmanFilter.update(acceleration: currentAccY, dt: self.dt)
            let stateZ = self.kalmanFilter.update(acceleration: currentAccZ, dt: self.dt)
            
            // Update published properties
            self.accX = stateX.acceleration
            self.velX = stateX.velocity
            self.posX = stateX.position
            
            self.accY = stateY.acceleration
            self.velY = stateY.velocity
            self.posY = stateY.position
            
            self.accZ = stateZ.acceleration
            self.velZ = stateZ.velocity
            self.posZ = stateZ.position
            
            // Add new reading
            self.readings.append(Reading(
                timestamp: Date(),
                accX: self.accX,
                velX: self.velX,
                posX: self.posX,
                accY: self.accY,
                velY: self.velY,
                posY: self.posY,
                accZ: self.accZ,
                velZ: self.velZ,
                posZ: self.posZ
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
        stopAccelerometer()
        self.readings.removeAll()
        self.readings.append(Reading(timestamp: Date(), accX: 0, velX: 0, posX: 0, accY: 0, velY: 0, posY: 0, accZ: 0, velZ: 0, posZ: 0))
        startAccelerometer()
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
                    y: .value(axis, (reading.posX * reading.posX + reading.posY * reading.posY + reading.posZ * reading.posZ).squareRoot())
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

            // X-axis position
            Text("Position")
            AccelerationChartView(
                readings: sensorsModel.readings,
                axis: "Distanct",
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
