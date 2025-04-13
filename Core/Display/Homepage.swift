//
//  Login.swift
//  InertialNavigation
//
//  Created by Michael Shaffer on 4/13/25.
//

import SwiftUI

struct HomeView: View {
    @State private var navigateToMotionView = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Text("Navify")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 50)
                
                Button("Get Started") {
                    navigateToMotionView = true
                }
                .frame(width: 200)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .shadow(radius: 3)
                .padding(.bottom, 50)
            }
            .padding(.horizontal, 30)
            .navigationDestination(isPresented: $navigateToMotionView) {
                MapView()
            }
        }
    }
}

#Preview {
    HomeView()
}
