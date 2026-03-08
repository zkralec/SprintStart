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
    @Environment(\.colorScheme) private var colorScheme
    @State private var player: AVAudioPlayer?

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
                audioSection
                appearanceSection
                aboutSection
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
    }

    private var audioSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Audio")
                .font(.headline)

            Picker("Voice", selection: $appStore.settings.voice) {
                ForEach(VoiceOption.allCases) { voice in
                    Text(voice.displayName).tag(voice)
                }
            }
            .pickerStyle(.menu)

            Picker("Starter Sound", selection: $appStore.settings.starter) {
                ForEach(StarterSoundOption.allCases) { starter in
                    Text(starter.displayName).tag(starter)
                }
            }
            .pickerStyle(.menu)

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

            Button("Test Starter Sound") {
                playStarterSound()
            }
            .buttonStyle(LiquidGlassButtonStyle(tint: controlTint))
        }
        .liquidGlassCard()
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Appearance")
                .font(.headline)

            Picker("Theme", selection: $appStore.settings.theme) {
                ForEach(ThemeOption.allCases) { theme in
                    Text(theme.displayName).tag(theme)
                }
            }
            .pickerStyle(.menu)

            Toggle(isOn: $appStore.settings.isDarkMode) {
                Text("Dark Mode")
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }
            .tint(controlTint)
        }
        .liquidGlassCard()
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
            Text("Build \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")")
            Text("Developer: Zachary Kralec")
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
        .liquidGlassCard()
    }

    private func playStarterSound() {
        guard let url = Bundle.main.url(forResource: appStore.settings.starter.fileName, withExtension: "mp3") else {
            return
        }

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.play()
        } catch {
            print("Failed to play sound: \(error)")
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(AppSettingsStore())
    }
}
