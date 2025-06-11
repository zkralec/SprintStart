//
//  WelcomeView.swift
//  SprintStart
//
//  Created by Zachary Kralec on 6/10/25.
//

import SwiftUI

struct WelcomeView: View {
    @State private var welcomeScreen = true
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Group {
            if welcomeScreen {
                VStack {
                    Spacer()
                    
                    // App logo
                    // Have dark and light in case of future logo change
                    if let logo = UIImage(named: colorScheme == .dark ? "DarkLogo" : "LightLogo") {
                        Image(uiImage: logo)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 150, height: 150)
                            .padding(.bottom)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0.2...0.75)) {
                                    withAnimation {
                                        welcomeScreen = false
                                    }
                                }
                            }
                    } else {
                        Text("Logo not found")
                            .font(.title2)
                            .foregroundColor(.blue)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0.2...0.75)) {
                                    withAnimation {
                                        welcomeScreen = false
                                    }
                                }
                            }
                    }
                    
                    // Spinning progress indicator
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                    
                    Spacer()
                }
            } else {
                withAnimation {
                    StarterView()
                }
            }
        }
    }
}

#Preview {
    WelcomeView()
}
