//
//  SprintStartApp.swift
//  SprintStart
//
//  Created by Zachary Kralec on 6/10/25.
//

import SwiftUI

@main
struct SprintStartApp: App {
    @StateObject private var appStore = AppSettingsStore()
    @StateObject private var purchaseManager = PurchaseManager()
    @StateObject private var reactionHistoryStore = ReactionHistoryStore()

    var body: some Scene {
        WindowGroup {
            WelcomeView()
                .environmentObject(appStore)
                .environmentObject(purchaseManager)
                .environmentObject(reactionHistoryStore)
                .tint(appStore.settings.theme.accentColor)
                .preferredColorScheme(appStore.settings.isDarkMode ? .dark : .light)
                .onAppear {
                    if !purchaseManager.hasPro {
                        appStore.enforceFreeTierSettings()
                    }
                }
                .onChange(of: purchaseManager.hasPro) {
                    if !purchaseManager.hasPro {
                        appStore.enforceFreeTierSettings()
                    }
                }
        }
    }
}
