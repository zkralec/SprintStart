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
    
    var body: some Scene {
        WindowGroup {
            WelcomeView()
                .environmentObject(settings)
                .onAppear {
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                        windowScene.windows.first?.overrideUserInterfaceStyle = settings.isDarkMode ? .dark : .light
                    }
                }
        }
    }
}
