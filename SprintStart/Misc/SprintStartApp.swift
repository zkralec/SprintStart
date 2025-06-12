//
//  SprintStartApp.swift
//  SprintStart
//
//  Created by Zachary Kralec on 6/10/25.
//

import SwiftUI

@main
struct SprintStartApp: App {
    @StateObject private var settings = SettingsModel()
    @StateObject private var themeManager = ThemeData()
    
    var body: some Scene {
        WindowGroup {
            WelcomeView()
                .environmentObject(settings)
                .environmentObject(themeManager)
                .tint(themeManager.selectedColor)
                .onAppear {
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                        windowScene.windows.first?.overrideUserInterfaceStyle = settings.isDarkMode ? .dark : .light
                    }
                }
        }
    }
}
