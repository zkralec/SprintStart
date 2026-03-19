//
//  WelcomeModelView.swift
//  SprintStart
//
//  Created by Zachary Kralec on 7/31/25.
//

import SwiftUI

struct WelcomeModelView: View {
    @Binding var isVisible: Bool
    @EnvironmentObject var appStore: AppSettingsStore
    @Environment(\.colorScheme) private var colorScheme
    @State private var isContinuing = false

    private var themeColor: Color { appStore.settings.theme.accentColor }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 18) {
                    heroSection
                    featureSection
                    privacySection
                }
                .padding(.horizontal, GlassLayout.screenPadding)
                .padding(.top, 24)
                .padding(.bottom, 20)
            }

            VStack(spacing: 10) {
                Button {
                    guard !isContinuing else { return }
                    isContinuing = true
                    UserDefaults.standard.set(true, forKey: "hasLaunched")
                    withAnimation(.easeOut(duration: 0.18)) {
                        isVisible = false
                    }
                } label: {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(LiquidGlassButtonStyle(tint: themeColor))
                .disabled(isContinuing)
                .accessibilityIdentifier("onboardingContinueButton")

                Text("You can change audio, appearance, and timing behavior in Settings any time.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, GlassLayout.screenPadding)
            .padding(.top, 12)
            .padding(.bottom, 16)
        }
        .liquidGlassScreenBackground(theme: appStore.settings.theme)
    }

    private var heroSection: some View {
        VStack(spacing: 16) {
            Image(colorScheme == .dark ? "DarkLogo" : "LightLogo")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 76, height: 76)
                .foregroundStyle(themeColor)

            VStack(spacing: 6) {
                Text("Welcome to SprintStart")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)

                Text("Solo sprint start training with race-style cues, clean timing control, and focused reaction work.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 10) {
                introTag("Random Starts")
                introTag("Reaction Training")
                introTag("Private Data")
            }
        }
        .frame(maxWidth: .infinity)
        .liquidGlassCard()
    }

    private var featureSection: some View {
        VStack(spacing: 0) {
            featureRow(
                systemName: "speaker.wave.3.fill",
                title: "Race-Style Start Cues",
                subtitle: "Use voice, sound, and haptic cues to simulate a clean solo start."
            )

            Divider()
                .padding(.leading, 52)

            featureRow(
                systemName: "timer",
                title: "Simple Timing Control",
                subtitle: "Adjust mark, set, and variability to match your training session."
            )

            Divider()
                .padding(.leading, 52)

            featureRow(
                systemName: "hand.point.up.left.fill",
                title: "Focused Reaction Practice",
                subtitle: "Train release timing and get clear feedback on false starts."
            )
        }
        .liquidGlassCard()
    }

    private var privacySection: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lock.shield.fill")
                .font(.headline)
                .foregroundStyle(themeColor)
                .frame(width: 22)

            Text("All settings and training data stay on your device.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidGlassCard()
    }

    private func featureRow(systemName: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemName)
                .font(.headline)
                .foregroundStyle(themeColor)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 10)
    }

    private func introTag(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: Capsule())
    }
}
