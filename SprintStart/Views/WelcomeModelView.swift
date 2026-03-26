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
                Button(action: continueOnboarding) {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(LiquidGlassButtonStyle(tint: themeColor))
                .contentShape(Capsule())
                .disabled(isContinuing)
                .accessibilityIdentifier("onboardingContinueButton")

                Text("You can change audio, appearance, and timing behavior in Settings any time.")
                    .font(AppTypography.secondary)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, GlassLayout.screenPadding)
            .padding(.top, 12)
            .padding(.bottom, 16)
        }
        .liquidGlassScreenBackground(theme: appStore.settings.theme)
        .onChange(of: isVisible) {
            if !isVisible {
                isContinuing = false
            }
        }
    }

    private var heroSection: some View {
        VStack(spacing: 16) {
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 76, height: 76)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            VStack(spacing: 6) {
                Text("Welcome to Sprint Start Pro")
                    .font(AppTypography.screenTitle)
                    .multilineTextAlignment(.center)

                Text("Solo sprint start training with race-style cues, clean timing control, and focused reaction work.")
                    .font(AppTypography.body)
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
        VStack(alignment: .leading, spacing: 12) {
            AppSectionHeader(
                systemName: "sparkles",
                tint: themeColor,
                title: "What You Can Do",
                summary: "Core training tools."
            )

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
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .appInsetPanel(tint: themeColor, cornerRadius: 20)
        }
        .liquidGlassCard()
    }

    private var privacySection: some View {
        AppSectionHeader(
            systemName: "lock.shield.fill",
            tint: themeColor,
            title: "Private by Default",
            summary: "On-device data."
        )
        .liquidGlassCard()
    }

    private func featureRow(systemName: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemName)
                .font(AppTypography.cardTitle)
                .foregroundStyle(themeColor)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTypography.bodyStrong)
                Text(subtitle)
                    .font(AppTypography.secondary)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 10)
    }

    private func introTag(_ text: String) -> some View {
        Text(text)
            .font(AppTypography.captionStrong)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: Capsule())
    }

    private func continueOnboarding() {
        guard !isContinuing else { return }

        isContinuing = true
        UserDefaults.standard.set(true, forKey: "hasLaunched")

        withAnimation(.easeOut(duration: 0.18)) {
            isVisible = false
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(750))
            if isVisible {
                isContinuing = false
            }
        }
    }
}
