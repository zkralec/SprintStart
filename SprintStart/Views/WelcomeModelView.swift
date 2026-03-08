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
    @Environment(\.dismiss) private var dismiss
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
                    isVisible = false
                    dismiss()
                } label: {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(themeColor)
                .controlSize(.large)
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
            .background(.ultraThinMaterial)
        }
        .liquidGlassScreenBackground(theme: appStore.settings.theme)
    }

    private var heroSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.run.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(themeColor)

            Text("Welcome to SprintStart")
                .font(.title.bold())
                .multilineTextAlignment(.center)

            Text("Train your block start timing with consistent cues and focused reaction practice.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .liquidGlassCard()
    }

    private var featureSection: some View {
        VStack(spacing: 0) {
            featureRow(
                systemName: "speaker.wave.3.fill",
                title: "Realistic Starter Cues",
                subtitle: "Use voice commands and sound cues to simulate race starts."
            )

            Divider()
                .padding(.leading, 52)

            featureRow(
                systemName: "timer",
                title: "Custom Timing Control",
                subtitle: "Set your delays and apply optional variability for realism."
            )

            Divider()
                .padding(.leading, 52)

            featureRow(
                systemName: "hand.point.up.left.fill",
                title: "Reaction Practice",
                subtitle: "Train release timing and track false starts with clear feedback."
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
}
