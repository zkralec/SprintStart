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
                    if let logo = UIImage(named: colorScheme == .dark ? "DarkLogo" : "LightLogo") {
                        Image(uiImage: logo)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 150, height: 150)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    withAnimation {
                                        welcomeScreen = false
                                    }
                                }
                            }
                    } else {
                        Text("Logo not found")
                            .foregroundColor(.red)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
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
