//
//  SettingsView.swift
//  SprintStart
//
//  Created by Zachary Kralec on 6/10/25.
//

import SwiftUI
import AVFoundation

struct SettingsView: View {
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
            VStack(spacing: GlassLayout.sectionSpacing) {
                proSection
                audioSection
                appearanceSection
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
        .alert("Sprint Start Pro", isPresented: Binding(
            get: { purchaseMessage != nil },
            set: { if !$0 { purchaseMessage = nil } }
        )) {
            Button("OK") {}
        } message: {
            Text(purchaseMessage ?? "")
        }
    }

    private var proSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Sprint Start Pro")
                    .font(.headline)
                Spacer()
                if purchaseManager.hasPro {
                    Label("Unlocked", systemImage: "checkmark.seal.fill")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                } else {
                    Text(purchaseManager.displayPrice)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

            Text("Unlock reaction time tracking, session history, and advanced randomness.")
                .font(.footnote)
                .foregroundStyle(.secondary)

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
                .buttonStyle(LiquidGlassButtonStyle(tint: controlTint))
            } else {
                Button {
                    paywallFeature = .general
                } label: {
                    Text("Upgrade to Pro")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(LiquidGlassButtonStyle(tint: controlTint))

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
            }
        }
        .liquidGlassCard()
    }

    private var audioSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Audio")
                .font(.headline)

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

            Toggle(isOn: $appStore.settings.playOverSilent) {
                Text("Play Over Silent Mode")
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }
            .tint(controlTint)
                .onChange(of: appStore.settings.playOverSilent) {
                    try? AudioSessionManager.shared.configure(appStore.settings.playOverSilent ? .playOverSilent : .respectsSilent)
                }

            Toggle(isOn: $appStore.settings.hapticsEnabled) {
                Text("Haptics")
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }
            .tint(controlTint)

            Button(soundTestButtonTitle) {
                playStarterSound()
            }
            .buttonStyle(LiquidGlassButtonStyle(tint: controlTint))
            .disabled(soundTestCooldownRemaining > 0)
            .opacity(soundTestCooldownRemaining > 0 ? 0.65 : 1.0)
        }
        .liquidGlassCard()
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Appearance")
                .font(.headline)

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
                Toggle(isOn: $appStore.settings.isDarkMode) {
                    Text("Dark Mode")
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }
                .tint(controlTint)
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
        } catch {
            print("Failed to play sound: \(error)")
        }
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
            purchaseMessage = "Sprint Start Pro has been restored."
        case .nothingToRestore:
            purchaseMessage = "No previous Sprint Start Pro purchase was found."
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

    private func selectorRow(
        title: String,
        value: String,
        showsProBadge: Bool = false
    ) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(value)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if showsProBadge {
                Text("PRO")
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())
            }

            Image(systemName: "chevron.up.chevron.down")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            themeColor.opacity(colorScheme == .dark ? 0.18 : 0.16),
                            themeColor.opacity(colorScheme == .dark ? 0.08 : 0.10)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(themeColor.opacity(colorScheme == .dark ? 0.35 : 0.22), lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(AppSettingsStore())
            .environmentObject(PurchaseManager())
    }
}
