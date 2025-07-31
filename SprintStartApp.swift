//
//  SprintStartApp.swift
//  SprintStart
//
//  Created by Zachary Kralec on 6/10/25.
//

// To Do List:
// Create a popup that appears when the user opens the app for the very first time
    // It should explain what the app is, its features, etc. all in an apple-like documentation style
// Modify the look of the app to make it look like iOS 26
    // Think more fully rounded items and buttons

import SwiftUI

// If not able to start on iPhone (ex. extracting error), restart computer
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
