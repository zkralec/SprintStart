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
            if launchArgs.contains("-skipSplash") || launchArgs.contains("-uiTesting") {
                isShowingLaunchOverlay = false
            }

            let hasLaunched = UserDefaults.standard.bool(forKey: "hasLaunched")
            showWelcomePopup = !hasLaunched

            dismissLaunchOverlayIfReady()
        }
        .onChange(of: purchaseManager.hasCompletedInitialLoad) {
            dismissLaunchOverlayIfReady()
        }
    }

    private var splashScreen: some View {
        VStack(spacing: 18) {
            Image(colorScheme == .dark ? "DarkLogo" : "LightLogo")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 96, height: 96)
                .foregroundStyle(themeColor)

            VStack(spacing: 8) {
                Text("SprintStart")
                    .font(.title.weight(.bold))

                Text("Solo sprint start training with race-style cues and focused reaction work.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 10) {
                splashTag("Random Starts")
                splashTag("Reaction Training")
                splashTag("Private Data")
            }
        }
        .padding(.horizontal, GlassLayout.screenPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func dismissLaunchOverlayIfReady() {
        guard purchaseManager.hasCompletedInitialLoad else { return }
        withAnimation(.easeOut(duration: 0.18)) {
            isShowingLaunchOverlay = false
        }
    }

    private func splashTag(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: Capsule())
    }
}

#Preview {
    WelcomeView()
        .environmentObject(AppSettingsStore())
}
