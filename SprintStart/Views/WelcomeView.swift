//
//  WelcomeView.swift
//  SprintStart
//
//  Created by Zachary Kralec on 6/10/25.
//

import SwiftUI

struct WelcomeView: View {
    @State private var welcomeScreen = true
    @State private var showWelcomePopup = false
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var theme: ThemeData
    
    var body: some View {
        Group {
            if welcomeScreen {
                VStack {
                    Spacer()
                    
                    // App logo
                    Image(colorScheme == .dark ? "DarkLogo" : "LightLogo")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                        .foregroundColor(theme.selectedColor)
                        .padding(.bottom)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0.25...0.75)) {
                                withAnimation {
                                    welcomeScreen = false
                                }
                                // Don't show popup if already launched
                                let hasLaunched = UserDefaults.standard.bool(forKey: "hasLaunched")
                                showWelcomePopup = hasLaunched // Remove ! if you want to see pop up
                            }
                        }
                    
                    // Spinning progress indicator
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                    
                    Spacer()
                }
            } else {
                StarterView()
                    .fullScreenCover(isPresented: $showWelcomePopup) {
                        WelcomeModelView(isVisible: $showWelcomePopup)
                            .environmentObject(theme)
                    }
            }
        }
    }
}

#Preview {
    WelcomeView()
}
