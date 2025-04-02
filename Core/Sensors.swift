//
//  Sensors.swift
//  InertialNavigation
//
//  Created by Michael Shaffer on 4/1/25.
//

import SwiftUI
import CoreMotion



class SensorsModel: ObservableObject {
    @Published var accelX: Double = 0
    @Published var accelY: Double = 0
    @Published var accelZ: Double = 0

    private let motionManager = CMMotionManager()
    
    
    func startAccelerometer() {
        guard motionManager.isAccelerometerAvailable else { return } // Ensure accelerometer is available
        
        motionManager.accelerometerUpdateInterval = 0.1
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in // Collect and deliver data to main thread
            guard let self = self, let motion = motion else { return } // Safely unwrap self ref and motion data
                
            // These acceleration values are in m/s^2 and exclude gravity
            self.accelX = motion.userAcceleration.x * 9.81
            self.accelY = motion.userAcceleration.y * 9.81
            self.accelZ = motion.userAcceleration.z * 9.81
        }
    }
    
    func stopAccelerometer() {
        motionManager.stopAccelerometerUpdates()
    }
    
}
    
struct SensorsView: View {
    @StateObject private var sensorsModel = SensorsModel()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Accelerometer Data").font(.headline)
            Text("x: \(sensorsModel.accelX, specifier: "%.2f")")
            Text("y: \(sensorsModel.accelY, specifier: "%.2f")")
            Text("z: \(sensorsModel.accelZ, specifier: "%.2f")")
        }
        .onAppear { sensorsModel.startAccelerometer() }
        .onDisappear { sensorsModel.stopAccelerometer() }
    }
}

#Preview {
    SensorsView()
}
