//
//  Sensors.swift
//  InertialNavigation
//
//  Created by Michael Shaffer on 4/1/25.
//

import SwiftUI
import CoreMotion
import Charts



class MotionModel: ObservableObject {
    @Published var currentState = MotionState.zero
    @Published var history: [MotionState] = [MotionState.zero]
    
    private let filter = KalmanFilter()
    
    let motionManager = CMMotionManager()
    let maxReadings = 50
    let timeStep = 0.1
    
    
    
    func startTracking() {
        guard motionManager.isDeviceMotionAvailable else { return }
        
        motionManager.deviceMotionUpdateInterval = timeStep
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self = self, let motion = motion else { return }
            
            // Convert acceleration from G's to m/s²
            let rawAccX = motion.userAcceleration.x * 9.81
            let rawAccY = motion.userAcceleration.y * 9.81
            let rawAccZ = motion.userAcceleration.z * 9.81
            
            self.currentState = self.filter.update(
                accX: rawAccX, 
                accY: rawAccY, 
                accZ: rawAccZ, 
                dt: self.timeStep
            )
            
            self.history.append(self.currentState)
            
            // Maintain maximum reading count
            if self.history.count > self.maxReadings {
                self.history.removeFirst(self.history.count - self.maxReadings)
            }
        }
    }
    
    func stopTracking() {
        motionManager.stopDeviceMotionUpdates()
    }
    
    func reset() {
        stopTracking()
        filter.reset()
        currentState = MotionState.zero
        history = [currentState]
        startTracking()
    }
}


// Chart display for testing
struct MotionChartComponent: View {
    let readings: [MotionState]
    let title: String
    let color: Color
    
    var body: some View {
        Chart {
            // Horizontal rule lines
            ForEach([
                    (label: "Zero", value: 0.0, width: 1.0, dash: [] as [CGFloat], opacity: 0.5),
                    (label: "Max", value: 0.5, width: 1.0, dash: [5.0, 5.0], opacity: 0.3),
                    (label: "Min", value: -0.5, width: 1.0, dash: [5.0, 5.0], opacity: 0.3)
                ], id: \.label) { line in
                    RuleMark(y: .value(line.label, line.value))
                        .lineStyle(StrokeStyle(lineWidth: line.width, dash: line.dash))
                        .foregroundStyle(Color.gray.opacity(line.opacity))
                }
            
            // Line chart
            ForEach(readings) { reading in
                LineMark(
                    x: .value("Time", reading.timestamp),
                    y: .value(title, reading.posMagnitude)
                )
                .foregroundStyle(color)
                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                .interpolationMethod(.catmullRom) // Smoother curve
            }
        }
        .chartXAxis {
            AxisMarks(position: .bottom) { value in
                AxisGridLine()
                    .foregroundStyle(.gray.opacity(0.3))
                AxisTick()
                    .foregroundStyle(.gray)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                    .foregroundStyle(.gray.opacity(0.3))
                AxisTick()
                    .foregroundStyle(.gray)
                AxisValueLabel {
                    if let doubleValue = value.as(Double.self) {
                        Text(String(format: "%.1f", doubleValue))
                            .font(.caption)
                    }
                }
            }
        }
        .chartYScale(domain: -1...1)
        .chartLegend(position: .bottom)
        .frame(height: 150)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

struct MotionView: View {
    @StateObject private var model = MotionModel()
    
    var body: some View {
        VStack {
            MotionChartComponent(
                readings: model.history,
                title: "Distance",
                color: .red
            )
            .padding(20)
            
            Button("Clear Data") {
                model.reset()
            }
            .padding()
        }
        .onAppear { model.startTracking() }
        .onDisappear { model.stopTracking() }
    }
}

#Preview {
    MotionView()
}
