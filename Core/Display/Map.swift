//
//  Map.swift
//  InertialNavigation
//
//  Created by Michael Shaffer on 4/13/25.
//

import SwiftUI
import MapKit

struct MapView: View {
    @StateObject private var user = User()
    @State private var position = MapCameraPosition.automatic
    
    var body: some View {
        VStack {
            Map(position: $position) {
                
                
                // User location
                Annotation("My Location",
                           coordinate: CLLocationCoordinate2D(latitude: user.latitude, longitude: user.longitude)
                ) {
                    Image(systemName: "location.circle")
                        .foregroundColor(.blue)
                }
                
                // ITE
    
                // Polygon Border
                MapPolygon(coordinates:
                    [CLLocationCoordinate2D(latitude: 41.80630, longitude: -72.25302),
                     CLLocationCoordinate2D(latitude: 41.80661, longitude: -72.25250),
                     CLLocationCoordinate2D(latitude: 41.80665, longitude: -72.25253),
                     CLLocationCoordinate2D(latitude: 41.80668, longitude: -72.25248),
                     CLLocationCoordinate2D(latitude: 41.80678, longitude: -72.25259),
                     CLLocationCoordinate2D(latitude: 41.80675, longitude: -72.25264),
                     CLLocationCoordinate2D(latitude: 41.80679, longitude: -72.25269),
                     CLLocationCoordinate2D(latitude: 41.80647, longitude: -72.25322)]
                )
                .foregroundStyle(Color(red: 0.94, green: 0.9, blue: 0.84).opacity(0.7))
                .stroke(.brown, lineWidth: 3)
                
                // Other Schematic Elements...
                
                
                
                
                
                
                
                
                
            }
            .edgesIgnoringSafeArea(.all)
            .onAppear {
                updateMapPosition()
                user.startTracking()
            }
            .onDisappear { user.stopTracking() }
        }
    }
    
    private func updateMapPosition() {
        position = .region(
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: user.latitude, longitude: user.longitude),
                span: MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001)
            )
        )
    }
}

#Preview {
    MapView()
}
