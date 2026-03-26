//
//  SettingsView.swift
//  SprintStart
//
//  Created by Zachary Kralec on 6/10/25.
//

import SwiftUI
import AVFoundation

struct SettingsView: View {
    private enum ExternalLink {
        static let privacy = URL(string: "https://zkralec.github.io/sprintstart-site/privacy.html")!
        static let support = URL(string: "https://zkralec.github.io/sprintstart-site/support.html")!
    }

    @EnvironmentObject var appStore: AppSettingsStore
    @EnvironmentObject var purchaseManager: PurchaseManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var player: AVAudioPlayer?
    @State private var paywallFeature: ProFeature?
    @State private var purchaseMessage: String?
    @State private var soundTestCooldownRemaining = 0

    private var themeColor: Color { appStore.settings.theme.accentColor }
    private var controlTint: Color {
        if appStore.settings.theme == .blackWhite && colorScheme == .dark {
            return .black
        }
        return themeColor
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                proSection
                audioSection
                appearanceSection
                infoSection
            }
            .padding(GlassLayout.screenPadding)
        }
        .accessibilityIdentifier("settingsScreen")
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .tint(controlTint)
        .liquidGlassScreenBackground(theme: appStore.settings.theme)
        .onAppear {
            try? AudioSessionManager.shared.configure(appStore.settings.playOverSilent ? .playOverSilent : .respectsSilent)
        }
        .sheet(item: $paywallFeature) { feature in
            ProPaywallView(feature: feature)
                .environmentObject(purchaseManager)
        }
        .alert("Unlock Pro", isPresented: Binding(
            get: { purchaseMessage != nil },
            set: { if !$0 { purchaseMessage = nil } }
        )) {
            Button("OK") {}
        } message: {
            Text(purchaseMessage ?? "")
        }
    }

    private var proSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                AppIconTile(
                    systemName: purchaseManager.hasPro ? "checkmark.seal.fill" : "lock.fill",
                    tint: themeColor,
                    size: 44
                )

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("Unlock Pro")
                            .font(AppTypography.cardTitle)

                        if purchaseManager.hasPro {
                            AppStatusBadge(text: "Active", tint: themeColor)
                        }
                    }

                    Text(proCardSummary)
                        .font(AppTypography.secondary)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                if !purchaseManager.hasPro {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(purchaseManager.displayPrice)
                            .font(AppTypography.bodyStrong)
                            .foregroundStyle(.primary)
                        Text("One-time")
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if !purchaseManager.hasPro {
                HStack(spacing: 8) {
                    AppFeaturePill(text: "Reaction")
                    AppFeaturePill(text: "History")
                    AppFeaturePill(text: "Randomness")
                    AppFeaturePill(text: "Themes")
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }

            if purchaseManager.hasPro {
                Button {
                    Task {
                        let outcome = await purchaseManager.restorePurchases()
                        handleRestoreOutcome(outcome)
                    }
                } label: {
                    Text("Restore Purchases")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            } else {
                HStack(spacing: 10) {
                    Button {
                        paywallFeature = .general
                    } label: {
                        Text("Unlock Pro")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(LiquidGlassButtonStyle(tint: controlTint))
                    .accessibilityIdentifier("settingsUpgradeToProButton")

                    Button {
                        Task {
                            let outcome = await purchaseManager.restorePurchases()
                            handleRestoreOutcome(outcome)
                        }
                    } label: {
                        Text("Restore")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }

        }
        .liquidGlassCard()
    }

    private var proCardSummary: String {
        if purchaseManager.hasPro {
            return "Reaction tracking, history, and extra controls are active."
        }
        return "Reaction tracking, session history, and more control."
    }

    private var audioSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            AppSectionHeader(
                systemName: "speaker.wave.3.fill",
                tint: themeColor,
                title: "Audio",
                summary: "Cues and feedback."
            )

            if purchaseManager.hasPro {
                Menu {
                    ForEach(VoiceOption.allCases) { voice in
                        Button(voice.displayName) {
                            appStore.settings.voice = voice
                        }
                    }
                } label: {
                    selectorRow(title: "Voice", value: appStore.settings.voice.displayName)
                }
                .buttonStyle(.plain)

                Menu {
                    ForEach(StarterSoundOption.allCases) { starter in
                        Button(starter.displayName) {
                            appStore.settings.starter = starter
                        }
                    }
                } label: {
                    selectorRow(title: "Starter Sound", value: appStore.settings.starter.displayName)
                }
                .buttonStyle(.plain)
            } else {
                proLockedRow(title: "Voice", value: appStore.settings.voice.displayName, feature: .general)
                proLockedRow(title: "Starter Sound", value: appStore.settings.starter.displayName, feature: .general)
            }

            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    appStore.settings.playOverSilent.toggle()
                }
                try? AudioSessionManager.shared.configure(appStore.settings.playOverSilent ? .playOverSilent : .respectsSilent)
            } label: {
                toggleRow(
                    title: "Play Over Silent Mode",
                    isOn: appStore.settings.playOverSilent,
                    symbol: appStore.settings.playOverSilent ? "speaker.wave.3.fill" : "speaker.slash.fill"
                )
            }
            .buttonStyle(.plain)

            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    appStore.settings.hapticsEnabled.toggle()
                }
            } label: {
                toggleRow(
                    title: "Haptics",
                    isOn: appStore.settings.hapticsEnabled,
                    symbol: appStore.settings.hapticsEnabled ? "iphone.radiowaves.left.and.right" : "iphone.slash"
                )
            }
            .buttonStyle(.plain)

            Button(soundTestButtonTitle) {
                playStarterSound()
            }
            .buttonStyle(LiquidGlassButtonStyle(tint: controlTint))
            .disabled(soundTestCooldownRemaining > 0)
            .opacity(soundTestCooldownRemaining > 0 ? 0.65 : 1.0)
            .saturation(soundTestCooldownRemaining > 0 ? 0.82 : 1.0)

            noteRow("Best timing accuracy comes from the iPhone speaker or wired audio. Bluetooth audio can add delay.")
        }
        .liquidGlassCard()
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            AppSectionHeader(
                systemName: "paintbrush.pointed.fill",
                tint: themeColor,
                title: "Appearance",
                summary: "Theme and display."
            )

            if purchaseManager.hasPro {
                Menu {
                    ForEach(ThemeOption.allCases) { theme in
                        Button(theme.displayName) {
                            appStore.settings.theme = theme
                        }
                    }
                } label: {
                    selectorRow(title: "Theme", value: appStore.settings.theme.displayName)
                }
                .buttonStyle(.plain)
            } else {
                proLockedRow(title: "Theme", value: themeValueText, feature: .general)
            }

            if purchaseManager.hasPro {
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        appStore.settings.isDarkMode.toggle()
                    }
                } label: {
                    toggleRow(
                        title: "Dark Mode",
                        isOn: appStore.settings.isDarkMode,
                        symbol: appStore.settings.isDarkMode ? "moon.fill" : "sun.max.fill"
                    )
                }
                .buttonStyle(.plain)
            } else {
                proLockedRow(title: "Dark Mode", value: "Included with appearance controls", feature: .general)
            }
        }
        .liquidGlassCard()
    }

    private var themeValueText: String {
        appStore.settings.isDarkMode
            ? "\(appStore.settings.theme.displayName) • Dark"
            : "\(appStore.settings.theme.displayName) • Light"
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            AppSectionHeader(
                systemName: "questionmark.circle.fill",
                tint: themeColor,
                title: "Help & Privacy",
                summary: "Support and policy links."
            )

            VStack(spacing: 10) {
            Link(destination: ExternalLink.privacy) {
                infoLinkRow(title: "Privacy Policy")
            }
            .accessibilityIdentifier("privacyPolicyLink")

            Link(destination: ExternalLink.support) {
                infoLinkRow(title: "Support")
            }
            .accessibilityIdentifier("supportLink")
            }
        }
        .liquidGlassCard()
    }

    private var soundTestButtonTitle: String {
        if soundTestCooldownRemaining > 0 {
            return "Test Starter Sound (\(soundTestCooldownRemaining)s)"
        }
        return "Test Starter Sound"
    }

    private func playStarterSound() {
        guard soundTestCooldownRemaining == 0 else { return }
        guard let url = Bundle.main.url(forResource: appStore.settings.starter.fileName, withExtension: "mp3") else {
            return
        }

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.play()
            beginSoundTestCooldown()
        } catch {}
    }

    private func beginSoundTestCooldown() {
        soundTestCooldownRemaining = 2

        Task {
            while soundTestCooldownRemaining > 0 {
                try? await Task.sleep(for: .seconds(1))
                await MainActor.run {
                    if soundTestCooldownRemaining > 0 {
                        soundTestCooldownRemaining -= 1
                    }
                }
            }
        }
    }

    private func handleRestoreOutcome(_ outcome: RestoreOutcome) {
        switch outcome {
        case .restored:
            purchaseMessage = "Pro has been restored."
        case .nothingToRestore:
            purchaseMessage = "No previous Pro purchase was found."
        case .failed(let errorMessage):
            purchaseMessage = errorMessage
        }
    }

    private func proLockedRow(
        title: String,
        value: String,
        feature: ProFeature
    ) -> some View {
        Button {
            paywallFeature = feature
        } label: {
            selectorRow(title: title, value: value, showsProBadge: true)
        }
        .buttonStyle(.plain)
    }

    private func infoLinkRow(title: String) -> some View {
        HStack(spacing: 10) {
            Text(title)
                .font(AppTypography.secondaryStrong)
                .foregroundStyle(.primary)

            Spacer()

            Image(systemName: "arrow.up.right")
                .font(AppTypography.captionStrong)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .appInsetPanel(tint: themeColor, cornerRadius: 16)
    }

    private func noteRow(_ text: String) -> some View {
        Text(text)
            .font(AppTypography.secondary)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .appInsetPanel(tint: themeColor, cornerRadius: 16)
    }

    private func selectorRow(
        title: String,
        value: String,
        showsProBadge: Bool = false
    ) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTypography.bodyStrong)
                    .foregroundStyle(.primary)
                Text(value)
                    .font(AppTypography.secondary)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if showsProBadge {
                Text("PRO")
                    .font(AppTypography.captionEmphasis)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())
            }

            Image(systemName: "chevron.up.chevron.down")
                .font(AppTypography.captionStrong)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .appInsetPanel(tint: themeColor)
    }

    private func toggleRow(
        title: String,
        isOn: Bool,
        symbol: String
    ) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTypography.bodyStrong)
                    .foregroundStyle(.primary)
                Text(isOn ? "On" : "Off")
                    .font(AppTypography.secondary)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: symbol)
                .font(AppTypography.bodyStrong)
                .foregroundStyle(themeColor)

            Capsule()
                .fill(isOn ? themeColor.opacity(colorScheme == .dark ? 0.9 : 0.78) : Color.secondary.opacity(0.22))
                .frame(width: 46, height: 28)
                .overlay(alignment: isOn ? .trailing : .leading) {
                    Circle()
                        .fill(Color.white.opacity(colorScheme == .dark ? 0.96 : 1.0))
                        .frame(width: 22, height: 22)
                        .padding(3)
                }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .appInsetPanel(tint: themeColor)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(AppSettingsStore())
            .environmentObject(PurchaseManager())
    }
}
