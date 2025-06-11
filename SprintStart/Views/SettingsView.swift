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
    
    var body: some View {
        VStack {
            // Voice change
            Section {
                Text("Voice change")
            }
            
            Spacer()
            
            // Starter sound change
            Section {
                Text("Starter sound change")
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
            }
            
            Spacer()
        }
        .padding(.horizontal, 30)
    }
}

#Preview {
    SettingsView()
}
