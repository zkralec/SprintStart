//
//  SettingsView.swift
//  SprintStart
//
//  Created by Zachary Kralec on 6/10/25.
//

import SwiftUI

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
    @State private var voice = ["EN Female", "EN Male", "AUS Female", "AUS Male"]
    @State private var selectedVoice = "EN Female"
    @State private var startSound = ["Starter gun", "Electronic starter", "Whistle", "Clap"]
    @State private var selectedStartSound = "Starter gun"
    @State private var theme = ["Red", "Orange", "Yellow", "Green", "Blue", "Purple"]
    @State private var selectedTheme = "Blue"
    
    var body: some View {
        NavigationStack {
            VStack {
                // Title
                Section {
                    Text("Settings")
                        .font(.title)
                        .fontWeight(.bold)
                }
            }

            VStack {
                // Voice change
                Section {
                    HStack {
                        Text("Change voice")
                        
                        Spacer()
                        
                        Picker("", selection: $selectedVoice) {
                            ForEach(voice, id: \.self) { select in
                                Text(select)
                            }
                        }
                        .onChange(of: selectedVoice) {
                            saveData()
                            print("Saving voice of \(selectedVoice)") // Debug
                        }
                    }
                }
                
                Spacer()
                
                // Starter sound change
                Section {
                    HStack {
                        Text("Starter sound")
                        
                        Spacer()
                        
                        Picker("", selection: $selectedStartSound) {
                            ForEach(startSound, id: \.self) { select in
                                Text(select)
                            }
                        }
                        .onChange(of: selectedStartSound) {
                            saveData()
                            print("Saving start sound of \(selectedStartSound)") // Debug
                        }
                    }
                }
                
                Spacer()
                
                // Dark/Light mode toggle
                Section {
                    Toggle("Dark Mode", isOn: $settings.isDarkMode)
                        .onChange(of: settings.isDarkMode) {
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                                windowScene.windows.first?.overrideUserInterfaceStyle = settings.isDarkMode ? .dark : .light
                            }
                        }
                        .padding(.trailing, 15)
                }
                
                Spacer()
                
                // Theme color change
                Section {
                    HStack {
                        Text("Change theme")
                        
                        Spacer()
                        
                        Picker("", selection: $selectedTheme) {
                            ForEach(theme, id: \.self) { select in
                                Text(select)
                            }
                        }
                        .onChange(of: selectedTheme) {
                            saveData()
                            print("Saving theme of \(selectedTheme)") // Debug
                        }
                    }
                }
                
                Spacer()
            }
            .frame(maxHeight: 200)
            .padding(30)
            .onAppear {
                loadData()
            }
        }
        .onDisappear {
            saveData()
        }
        
        Spacer()
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
        settingsData = SettingsData(voice: selectedVoice, starter: selectedStartSound, theme: selectedTheme)
        if let encoded = try? JSONEncoder().encode(settingsData) {
            UserDefaults.standard.set(encoded, forKey: "settings")
        }
    }
}

#Preview {
    SettingsView()
}
