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
        VStack(spacing: 14) {
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 88, height: 88)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

            VStack(spacing: 6) {
                Text("Sprint Start Pro")
                    .font(AppTypography.screenTitle)

                Text("Solo sprint start training.")
                    .font(AppTypography.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 28)
        .padding(.horizontal, GlassLayout.screenPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func dismissLaunchOverlayIfReady() {
        guard purchaseManager.hasCompletedInitialLoad else { return }
        withAnimation(.easeOut(duration: 0.18)) {
            isShowingLaunchOverlay = false
        }
    }
}

#Preview {
    WelcomeView()
        .environmentObject(AppSettingsStore())
}
