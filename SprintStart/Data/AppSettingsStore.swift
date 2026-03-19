//
//  AppSettingsStore.swift
//  SprintStart
//
//  Created by Assistant on 3/8/26.
//

import Foundation

@MainActor
final class AppSettingsStore: ObservableObject {
    @Published var settings: SettingsData {
        didSet { saveSettings() }
    }

    @Published var starter: StarterData {
        didSet { saveStarter() }
    }

    private let defaults: UserDefaults

    private enum Keys {
        static let settings = "settings"
        static let starter = "delay"
        static let legacyDarkMode = "isDarkMode"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.settings = SettingsData.default
        self.starter = StarterData.default

        loadSettings()
        loadStarter()
    }

    func resetStarterToDefaults() {
        starter = .default
    }

    func resetAllToDefaults() {
        settings = .default
        starter = .default
    }

    func enforceFreeTierSettings() {
        settings.voice = .usFemale
        settings.starter = .starterGun
        settings.theme = .blue
        settings.isDarkMode = false
    }

    private func loadSettings() {
        if let data = defaults.data(forKey: Keys.settings),
           let decoded = try? JSONDecoder().decode(SettingsData.self, from: data) {
            settings = decoded
        }

        // Legacy migration path from older build key.
        if defaults.object(forKey: Keys.legacyDarkMode) != nil {
            settings.isDarkMode = defaults.bool(forKey: Keys.legacyDarkMode)
        }
    }

    private func loadStarter() {
        if let data = defaults.data(forKey: Keys.starter),
           let decoded = try? JSONDecoder().decode(StarterData.self, from: data) {
            starter = decoded
        }
    }

    private func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            defaults.set(encoded, forKey: Keys.settings)
        }
        defaults.set(settings.isDarkMode, forKey: Keys.legacyDarkMode)
    }

    private func saveStarter() {
        if let encoded = try? JSONEncoder().encode(starter) {
            defaults.set(encoded, forKey: Keys.starter)
        }
    }
}
