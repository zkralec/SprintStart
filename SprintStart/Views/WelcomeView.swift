//
//  WelcomeView.swift
//  SprintStart
//
//  Created by Zachary Kralec on 6/10/25.
//

import SwiftUI

struct WelcomeView: View {
    @State private var showWelcomePopup = false
    @State private var didPrepareLaunch = false
    @State private var isShowingLaunchOverlay = true

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var appStore: AppSettingsStore
    @EnvironmentObject private var purchaseManager: PurchaseManager

    private var themeColor: Color { appStore.settings.theme.accentColor }

    var body: some View {
        ZStack {
            MainModesView()
                .opacity(isShowingLaunchOverlay ? 0 : 1)
                .fullScreenCover(isPresented: $showWelcomePopup) {
                    WelcomeModelView(isVisible: $showWelcomePopup)
                        .environmentObject(appStore)
                }

            if isShowingLaunchOverlay {
                splashScreen
            }
        }
        .liquidGlassScreenBackground(theme: appStore.settings.theme)
        .onAppear {
            guard !didPrepareLaunch else { return }
            didPrepareLaunch = true

            let launchArgs = ProcessInfo.processInfo.arguments
            if launchArgs.contains("-resetOnboarding") {
                UserDefaults.standard.removeObject(forKey: "hasLaunched")
            }
            if launchArgs.contains("-markLaunched") {
                UserDefaults.standard.set(true, forKey: "hasLaunched")
            }

            let hasLaunched = UserDefaults.standard.bool(forKey: "hasLaunched")
            showWelcomePopup = !hasLaunched

            if purchaseManager.hasCompletedInitialLoad {
                isShowingLaunchOverlay = false
            }
        }
        .onChange(of: purchaseManager.hasCompletedInitialLoad) {
            if purchaseManager.hasCompletedInitialLoad {
                withAnimation(.easeOut(duration: 0.18)) {
                    isShowingLaunchOverlay = false
                }
            }
        }
    }

    private var splashScreen: some View {
        VStack(spacing: 14) {
            Image(colorScheme == .dark ? "DarkLogo" : "LightLogo")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 110, height: 110)
                .foregroundStyle(themeColor)

            Text("SprintStart")
                .font(.title2.weight(.semibold))

            ProgressView()
                .tint(themeColor)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    WelcomeView()
        .environmentObject(AppSettingsStore())
}
