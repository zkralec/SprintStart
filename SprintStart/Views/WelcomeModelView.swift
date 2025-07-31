//
//  WelcomeModelView.swift
//  SprintStart
//
//  Created by Zachary Kralec on 7/31/25.
//

import SwiftUI

struct WelcomeModelView: View {
    @Binding var isVisible: Bool
    @EnvironmentObject var theme: ThemeData

    var body: some View {
        VStack(spacing: 30) {
            // Title
            Text("Welcome to SprintStart")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
                .padding(.top)

            Text("Train like you race. SprintStart helps you sharpen your reaction time with a clean interface, custom voices, and starter timing.")
                .multilineTextAlignment(.center)
                .font(.body)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            // Features list
            VStack(alignment: .leading, spacing: 24) {
                featureRow(systemName: "mic.fill", title: "Custom voice commands", subtitle: "Hear the starter in your preferred voice.")
                featureRow(systemName: "speaker.wave.2.fill", title: "Starter sound", subtitle: "Choose between a gun, clap, whistle, and more.")
                featureRow(systemName: "paintpalette.fill", title: "Theming", subtitle: "Pick a theme color that matches your style.")
                featureRow(systemName: "timer", title: "Race-day realism", subtitle: "Set your own delays with optional variability.")
            }
            .padding(.horizontal)

            // Privacy note
            Text("🔒 We don’t collect or share your data. Everything stays on your device.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.top)

            Spacer()

            // CTA button
            Button(action: {
                isVisible = false
                UserDefaults.standard.set(true, forKey: "hasLaunched")
            }) {
                Text("Get Started")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(theme.selectedColor)
                    .foregroundColor(.white)
                    .cornerRadius(25)
            }
            .padding(.horizontal)
        }
        .padding(.bottom)
        .background(Color(.systemBackground))
    }

    func featureRow(systemName: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemName)
                .foregroundColor(theme.selectedColor)
                .font(.title2)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .fontWeight(.semibold)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}
