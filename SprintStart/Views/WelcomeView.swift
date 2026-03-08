//
//  WelcomeView.swift
//  SprintStart
//
//  Created by Zachary Kralec on 6/10/25.
//

import SwiftUI

struct WelcomeView: View {
    @State private var welcomeScreen = true
    @State private var showWelcomePopup = false
    @State private var splashOpacity = 0.0

    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var appStore: AppSettingsStore

    private var themeColor: Color { appStore.settings.theme.accentColor }

    var body: some View {
        Group {
            if welcomeScreen {
                splashScreen
            } else {
                MainModesView()
                    .fullScreenCover(isPresented: $showWelcomePopup) {
                        WelcomeModelView(isVisible: $showWelcomePopup)
                            .environmentObject(appStore)
                    }
            }
        }
        .liquidGlassScreenBackground(theme: appStore.settings.theme)
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
        .opacity(splashOpacity)
        .onAppear {
            let launchArgs = ProcessInfo.processInfo.arguments
            if launchArgs.contains("-resetOnboarding") {
                UserDefaults.standard.removeObject(forKey: "hasLaunched")
            }
            if launchArgs.contains("-markLaunched") {
                UserDefaults.standard.set(true, forKey: "hasLaunched")
            }
            let isUITesting = launchArgs.contains("-uiTesting")
            let skipSplash = launchArgs.contains("-skipSplash")

            if skipSplash {
                splashOpacity = 0
                welcomeScreen = false
                let hasLaunched = UserDefaults.standard.bool(forKey: "hasLaunched")
                showWelcomePopup = !hasLaunched
                return
            }

            withAnimation(.easeIn(duration: 0.2)) {
                splashOpacity = 1
            }

            let delay = isUITesting ? 0.05 : Double.random(in: 0.3...0.7)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeOut(duration: isUITesting ? 0.05 : 0.2)) {
                    splashOpacity = 0
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + (isUITesting ? 0.02 : 0.18)) {
                    welcomeScreen = false
                    let hasLaunched = UserDefaults.standard.bool(forKey: "hasLaunched")
                    showWelcomePopup = !hasLaunched
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    WelcomeView()
        .environmentObject(AppSettingsStore())
}
