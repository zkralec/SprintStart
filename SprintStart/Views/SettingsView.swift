//
//  SettingsView.swift
//  SprintStart
//
//  Created by Zachary Kralec on 6/10/25.
//

import SwiftUI
import AVFoundation

class SettingsModel: ObservableObject {
    @Published var isDarkMode: Bool {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
        }
    }
    
    init() {
        self.isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
    }
}

struct SettingsView: View {
    @StateObject private var settings = SettingsModel()
    @State private var settingsData: SettingsData?
    @State private var selectedVoice = "US Female"
    @State private var selectedStartSound = "Starter gun"
    @State private var selectedTheme = "Blue"
    @State private var player: AVAudioPlayer?
    
    @EnvironmentObject var theme: ThemeData
    
    let voices = ["US Female", "GB Male", "AU Female"]
    let starters = ["Starter gun", "Electronic starter", "Whistle", "Clap"]
    let themes = ["Red", "Orange", "Yellow", "Green", "Blue", "Indigo", "Pink", "Black/White"]
    
    var body: some View {
        NavigationStack {
            Form {
                // Audio settings
                Section(header: Text("Audio Settings")) {
                    Picker("Voice", selection: $selectedVoice) {
                        ForEach(voices, id: \.self) { Text($0) }
                    }
                    .onChange(of: selectedVoice) { saveData() }
                    
                    Picker("Starter Sound", selection: $selectedStartSound) {
                        ForEach(starters, id: \.self) { Text($0) }
                    }
                    .onChange(of: selectedStartSound) { saveData() }
                    
                    Button("Test Starter Sound") {
                        playStarterSound()
                    }
                }
                
                // Appearance settings
                Section(header: Text("Appearance")) {
                    Picker("Theme", selection: $selectedTheme) {
                        ForEach(themes, id: \.self) { Text($0) }
                    }
                    .onChange(of: selectedTheme) {
                        saveData()
                        theme.selectedColor = ThemeData.colorNames(selectedTheme)
                    }
                    
                    Toggle("Dark Mode", isOn: $settings.isDarkMode)
                        .onChange(of: settings.isDarkMode) {
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                                windowScene.windows.first?.overrideUserInterfaceStyle = settings.isDarkMode ? .dark : .light
                            }
                        }
                }
                
                // Build notes
                Section {
                    EmptyView()
                } footer: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                        Text("Build \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")")
                        Text("Developer: Zachary Kralec")
                    }
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .tint(theme.selectedColor)
            .id(theme.selectedColor.description)
        }
        .onAppear(perform: loadData)
        .onDisappear(perform: saveData)
    }
    
    // Load the user selections from UserDefaults
    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: "settings"),
           let decoded = try? JSONDecoder().decode(SettingsData.self, from: data) {
            settingsData = decoded
            selectedVoice = decoded.voice
            selectedStartSound = decoded.starter
            selectedTheme = decoded.theme
        }
    }
    
    // Save the user selections to UserDefaults
    private func saveData() {
        let newSettings = SettingsData(
            voice: selectedVoice,
            starter: selectedStartSound,
            theme: selectedTheme
        )
        if let encoded = try? JSONEncoder().encode(newSettings) {
            UserDefaults.standard.set(encoded, forKey: "settings")
        }
    }
    
    // Let users test starter sound
    private func playStarterSound() {
        let fileName = selectedStartSound == "Clap" ? "single_clap" :
        selectedStartSound == "Whistle" ? "short_whistle" :
        selectedStartSound == "Electronic starter" ? "electronic_starter" : "starter_gun"
        
        if let url = Bundle.main.url(forResource: fileName, withExtension: "mp3") {
            do {
                player = try AVAudioPlayer(contentsOf: url)
                player?.prepareToPlay()
                player?.play()
            } catch {
                print("Failed to play sound: \(error)")
            }
        }
    }
}

#Preview {
    SettingsView()
}
