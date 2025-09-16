//
//  ThemeManager.swift
//  SprintStart
//
//  Created by Zachary Kralec on 6/12/25.
//

import SwiftUI

class ThemeData: ObservableObject {
    @Published var selectedColor: Color = .blue
    
    init() {
        loadTheme()
    }
    
    func loadTheme() {
        if let data = UserDefaults.standard.data(forKey: "settings"),
           let decoded = try? JSONDecoder().decode(SettingsData.self, from: data) {
            selectedColor = ThemeData.colorNames(decoded.theme)
        }
    }
    
    static func colorNames(_ name: String) -> Color {
        switch name {
        case "Red": return .red
        case "Orange": return .orange
        case "Yellow": return .yellow
        case "Green": return .green
        case "Blue": return .blue
        case "Indigo": return .indigo
        case "Pink": return Color(red: 0.99, green: 0.7, blue: 0.9)
        case "Black/White": return .primary
        default: return .blue
        }
    }
}

