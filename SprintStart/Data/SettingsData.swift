//
//  SettingsData.swift
//  SprintStart
//
//  Created by Zachary Kralec on 6/11/25.
//

import Foundation

enum VoiceOption: String, Codable, CaseIterable, Identifiable {
    case usFemale
    case gbMale
    case auFemale

    var id: Self { self }

    var displayName: String {
        switch self {
        case .usFemale: return "US Female"
        case .gbMale: return "GB Male"
        case .auFemale: return "AU Female"
        }
    }

    var languageCode: String {
        switch self {
        case .usFemale: return "en-US"
        case .gbMale: return "en-GB"
        case .auFemale: return "en-AU"
        }
    }

    init(legacyLabel: String) {
        switch legacyLabel {
        case "GB Male": self = .gbMale
        case "AU Female": self = .auFemale
        default: self = .usFemale
        }
    }
}
enum StarterSoundOption: String, Codable, CaseIterable, Identifiable {
    case starterGun
    case electronicStarter
    case whistle
    case clap

    var id: Self { self }

    var displayName: String {
        switch self {
        case .starterGun: return "Starter gun"
        case .electronicStarter: return "Electronic starter"
        case .whistle: return "Whistle"
        case .clap: return "Clap"
        }
    }

    var fileName: String {
        switch self {
        case .starterGun: return "starter_gun"
        case .electronicStarter: return "electronic_starter"
        case .whistle: return "short_whistle"
        case .clap: return "single_clap"
        }
    }

    init(legacyLabel: String) {
        switch legacyLabel {
        case "Electronic starter": self = .electronicStarter
        case "Whistle": self = .whistle
        case "Clap": self = .clap
        default: self = .starterGun
        }
    }
}

enum ThemeOption: String, Codable, CaseIterable, Identifiable {
    case red
    case orange
    case yellow
    case green
    case blue
    case indigo
    case pink
    case blackWhite

    var id: Self { self }

    var displayName: String {
        switch self {
        case .red: return "Red"
        case .orange: return "Orange"
        case .yellow: return "Yellow"
        case .green: return "Green"
        case .blue: return "Blue"
        case .indigo: return "Indigo"
        case .pink: return "Pink"
        case .blackWhite: return "Black/White"
        }
    }

    init(legacyLabel: String) {
        switch legacyLabel {
        case "Red": self = .red
        case "Orange": self = .orange
        case "Yellow": self = .yellow
        case "Green": self = .green
        case "Indigo": self = .indigo
        case "Pink": self = .pink
        case "Black/White": self = .blackWhite
        default: self = .blue
        }
    }
}

enum AppMode: String, Codable, CaseIterable, Identifiable {
    case standard
    case reaction

    var id: Self { self }

    var title: String {
        switch self {
        case .standard: return "Standard"
        case .reaction: return "Reaction"
        }
    }

    var systemImage: String {
        switch self {
        case .standard: return "speaker.wave.3.fill"
        case .reaction: return "hand.point.up.left.fill"
        }
    }
}

struct SettingsData: Codable, Equatable {
    var voice: VoiceOption
    var starter: StarterSoundOption
    var theme: ThemeOption
    var playOverSilent: Bool
    var hapticsEnabled: Bool
    var isDarkMode: Bool
    var lastMode: AppMode

    static let `default` = SettingsData(
        voice: .usFemale,
        starter: .starterGun,
        theme: .blue,
        playOverSilent: false,
        hapticsEnabled: true,
        isDarkMode: false,
        lastMode: .standard
    )

    private enum CodingKeys: String, CodingKey {
        case voice
        case starter
        case theme
        case playOverSilent
        case hapticsEnabled
        case isDarkMode
        case lastMode
    }

    init(
        voice: VoiceOption,
        starter: StarterSoundOption,
        theme: ThemeOption,
        playOverSilent: Bool,
        hapticsEnabled: Bool,
        isDarkMode: Bool,
        lastMode: AppMode
    ) {
        self.voice = voice
        self.starter = starter
        self.theme = theme
        self.playOverSilent = playOverSilent
        self.hapticsEnabled = hapticsEnabled
        self.isDarkMode = isDarkMode
        self.lastMode = lastMode
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let typedVoice = try? container.decode(VoiceOption.self, forKey: .voice) {
            voice = typedVoice
        } else if let legacyVoice = try container.decodeIfPresent(String.self, forKey: .voice) {
            voice = VoiceOption(legacyLabel: legacyVoice)
        } else {
            voice = .usFemale
        }

        if let typedStarter = try? container.decode(StarterSoundOption.self, forKey: .starter) {
            starter = typedStarter
        } else if let legacyStarter = try container.decodeIfPresent(String.self, forKey: .starter) {
            starter = StarterSoundOption(legacyLabel: legacyStarter)
        } else {
            starter = .starterGun
        }

        if let typedTheme = try? container.decode(ThemeOption.self, forKey: .theme) {
            theme = typedTheme
        } else if let legacyTheme = try container.decodeIfPresent(String.self, forKey: .theme) {
            theme = ThemeOption(legacyLabel: legacyTheme)
        } else {
            theme = .blue
        }

        playOverSilent = try container.decodeIfPresent(Bool.self, forKey: .playOverSilent) ?? false
        hapticsEnabled = try container.decodeIfPresent(Bool.self, forKey: .hapticsEnabled) ?? true
        isDarkMode = try container.decodeIfPresent(Bool.self, forKey: .isDarkMode) ?? false
        lastMode = (try? container.decode(AppMode.self, forKey: .lastMode)) ?? .standard
    }
}
