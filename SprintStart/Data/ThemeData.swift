//
//  ThemeManager.swift
//  SprintStart
//
//  Created by Zachary Kralec on 6/12/25.
//

import SwiftUI

extension ThemeOption {
    var accentColor: Color {
        switch self {
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .blue: return .blue
        case .indigo: return .indigo
        case .pink: return Color(red: 0.99, green: 0.7, blue: 0.9)
        case .blackWhite: return .primary
        }
    }

    var backgroundGradient: LinearGradient {
        switch self {
        case .red:
            return LinearGradient(colors: [Color(red: 0.28, green: 0.07, blue: 0.08), Color(red: 0.53, green: 0.11, blue: 0.13)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .orange:
            return LinearGradient(colors: [Color(red: 0.29, green: 0.13, blue: 0.03), Color(red: 0.56, green: 0.25, blue: 0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .yellow:
            return LinearGradient(colors: [Color(red: 0.25, green: 0.21, blue: 0.05), Color(red: 0.48, green: 0.40, blue: 0.09)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .green:
            return LinearGradient(colors: [Color(red: 0.05, green: 0.20, blue: 0.10), Color(red: 0.08, green: 0.40, blue: 0.19)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .blue:
            return LinearGradient(colors: [Color(red: 0.05, green: 0.13, blue: 0.24), Color(red: 0.11, green: 0.28, blue: 0.47)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .indigo:
            return LinearGradient(colors: [Color(red: 0.11, green: 0.10, blue: 0.28), Color(red: 0.23, green: 0.20, blue: 0.55)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .pink:
            return LinearGradient(colors: [Color(red: 0.25, green: 0.10, blue: 0.20), Color(red: 0.55, green: 0.20, blue: 0.42)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .blackWhite:
            return LinearGradient(colors: [Color(white: 0.10), Color(white: 0.30)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}
