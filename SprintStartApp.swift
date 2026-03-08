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

@main
struct SprintStartApp: App {
    @StateObject private var appStore = AppSettingsStore()

    var body: some Scene {
        WindowGroup {
            WelcomeView()
                .environmentObject(appStore)
                .tint(appStore.settings.theme.accentColor)
                .preferredColorScheme(appStore.settings.isDarkMode ? .dark : .light)
        }
    }
}
