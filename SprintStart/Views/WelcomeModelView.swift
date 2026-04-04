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
        GeometryReader { geometry in
            VStack(spacing: 0) {
                VStack(spacing: 14) {
                    heroSection
                    featureSection
                    privacySection
                }
                .padding(.horizontal, GlassLayout.screenPadding)
                .padding(.top, 18)
                .frame(maxWidth: .infinity)

                Spacer(minLength: 10)

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
                .padding(.bottom, max(16, geometry.safeAreaInsets.bottom == 0 ? 16 : geometry.safeAreaInsets.bottom))
            }
        }
        .liquidGlassScreenBackground(theme: appStore.settings.theme)
        .onChange(of: isVisible) {
            if !isVisible {
                isContinuing = false
            }
        }
    }

    private var heroSection: some View {
        VStack(spacing: 12) {
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 68, height: 68)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            VStack(spacing: 4) {
                Text("Welcome to Sprint Start Pro")
                    .font(AppTypography.screenTitle)
                    .multilineTextAlignment(.center)

                Text("Solo sprint start training with clean cues and focused reaction work.")
                    .font(AppTypography.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 8) {
                introTag("Starts")
                introTag("Reaction")
                introTag("Private")
            }
        }
        .frame(maxWidth: .infinity)
        .liquidGlassCard()
    }

    private var featureSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            AppSectionHeader(
                systemName: "sparkles",
                tint: themeColor,
                title: "What You Can Do",
                summary: "Core training tools."
            )

            VStack(spacing: 0) {
                featureRow(
                    systemName: "speaker.wave.3.fill",
                    title: "Race-Style Cues",
                    subtitle: "Voice, sound, and haptics."
                )

                Divider()
                    .padding(.leading, 52)

                featureRow(
                    systemName: "timer",
                    title: "Timing Control",
                    subtitle: "Adjust mark, set, and randomness."
                )

                Divider()
                    .padding(.leading, 52)

                featureRow(
                    systemName: "hand.point.up.left.fill",
                    title: "Reaction Practice",
                    subtitle: "Train release timing and false starts."
                )
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
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
        .padding(.vertical, 7)
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
