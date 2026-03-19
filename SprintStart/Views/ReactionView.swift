//
//  ReactionView.swift
//  SprintStart
//
//  Created by Assistant on 3/7/26.
//

import SwiftUI
import AVFoundation
import UIKit

struct ReactionView: View {
    @State private var isHolding = false
    @State private var sequenceActive = false
    @State private var falseStart = false
    @State private var reactionMS: Int?
    @State private var startCueTime: CFTimeInterval?
    @State private var starterSound: AVAudioPlayer?

    @State private var setWork: DispatchWorkItem?
    @State private var startWork: DispatchWorkItem?
    @State private var paywallFeature: ProFeature?
    @State private var shouldShowUpgradePrompt = false

    @EnvironmentObject var appStore: AppSettingsStore
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @EnvironmentObject private var reactionHistoryStore: ReactionHistoryStore

    private let synthesizer = AVSpeechSynthesizer()

    private var themeColor: Color { appStore.settings.theme.accentColor }
    private var primaryButtonTint: Color {
        if appStore.settings.theme == .blackWhite {
            return .black
        }
        return themeColor
    }

    var body: some View {
        ScrollView {
            VStack(spacing: GlassLayout.sectionSpacing) {
                header

                ZStack {
                    Color.clear
                        .liquidGlassCard()
                        .overlay(contentOverlay)
                        .overlay(reactionTouchOverlay)
                }
                .frame(height: 338)
                .contentShape(Rectangle())
                .accessibilityLabel("Reaction zone")
                .accessibilityHint(reactionAccessibilityHint)

                TimingControlsView(
                    markDelay: $appStore.starter.firstDelay,
                    startDelay: $appStore.starter.secondDelay,
                    variability: $appStore.starter.variability,
                    timingLocked: $appStore.starter.timingLocked
                )

                VStack(spacing: 12) {
                    Button {
                        cancelSequence()
                        resetUI()
                    } label: {
                        Label("Reset Reaction", systemImage: "arrow.counterclockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(LiquidGlassButtonStyle(tint: primaryButtonTint))

                    Button {
                        cancelSequence()
                        resetUI()
                        appStore.resetStarterToDefaults()
                    } label: {
                        Label("Reset to Defaults", systemImage: "arrow.uturn.backward")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(LiquidGlassButtonStyle(tint: .red))
                    .disabled(appStore.starter.timingLocked)
                    .opacity(appStore.starter.timingLocked ? 0.55 : 1.0)
                    .accessibilityIdentifier("resetDefaultsButtonReaction")
                }

                Spacer(minLength: 8)
            }
            .padding(GlassLayout.screenPadding)
        }
        .scrollDisabled(isHolding || sequenceActive)
        .navigationTitle("SprintStart")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                historyToolbarItem
            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gear")
                        .imageScale(.large)
                        .foregroundStyle(themeColor)
                        .accessibilityLabel("Settings")
                }
                .accessibilityIdentifier("openSettingsButton")
            }
        }
        .liquidGlassScreenBackground(theme: appStore.settings.theme)
        .onAppear {
            try? AudioSessionManager.shared.configure(appStore.settings.playOverSilent ? .playOverSilent : .respectsSilent)
            preloadStarterSound()
        }
        .onDisappear {
            cancelSequence()
        }
        .sheet(item: $paywallFeature) { feature in
            ProPaywallView(feature: feature)
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("SprintStart")
                    .font(.title.bold())
                Text("Reaction Mode")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "hand.point.up.left.fill")
                .font(.headline.weight(.semibold))
                .foregroundStyle(themeColor)
        }
        .liquidGlassCard()
    }

    private var contentOverlay: some View {
        VStack(spacing: 12) {
            if !purchaseManager.hasPro {
                Image(systemName: "lock.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text("Sprint Start Pro")
                    .font(.title2.weight(.semibold))
            } else if let ms = reactionMS {
                Text("Release Reaction: \(ms) ms")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(themeColor)
            } else if falseStart {
                Text("False Start")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(.red)
            } else if isHolding {
                Text("Holding... wait for the start")
                    .font(.title2)
            } else if shouldShowUpgradePrompt, !purchaseManager.hasPro {
                Text("Track each rep with Sprint Start Pro")
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.center)
            } else {
                Text("Press and hold to arm")
                    .font(.title2)
            }

            if !purchaseManager.hasPro && !isHolding {
                Button {
                    paywallFeature = .reactionTracking
                } label: {
                    Label("Unlock reaction time tracking", systemImage: "lock.fill")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            if let instructionText {
                Text(instructionText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if purchaseManager.hasPro {
                Text("Timing is based on the app cue and may vary slightly.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
    }

    @ViewBuilder
    private var reactionTouchOverlay: some View {
        if purchaseManager.hasPro {
            TouchCaptureView { count in
                if count > 0 {
                    if !isHolding {
                        isHolding = true
                        beginArmedSequence()
                    }
                } else if isHolding {
                    isHolding = false
                    handleRelease()
                }
            }
        } else {
            Button {
                paywallFeature = .reactionTracking
            } label: {
                Color.clear
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var historyToolbarItem: some View {
        if purchaseManager.hasPro {
            NavigationLink(destination: SessionHistoryView()) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .imageScale(.large)
                    .foregroundStyle(themeColor)
                    .accessibilityLabel("Session History")
            }
        } else {
            Button {
                paywallFeature = .sessionHistory
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .imageScale(.medium)
                    Text("PRO")
                        .font(.caption2.weight(.bold))
                }
                .foregroundStyle(themeColor)
                .accessibilityLabel("Session History Pro")
            }
        }
    }

    private var instructionText: String? {
        if !purchaseManager.hasPro {
            return nil
        }
        return "Release on the start cue."
    }

    private var reactionAccessibilityHint: String {
        if purchaseManager.hasPro {
            return "Place one or more fingers to arm. Release on the start cue to train your reaction."
        }
        return "Reaction Mode requires Sprint Start Pro."
    }

    private func beginArmedSequence() {
        falseStart = false
        reactionMS = nil
        sequenceActive = true
        startCueTime = nil
        shouldShowUpgradePrompt = false

        speak("On your marks")
        if appStore.settings.hapticsEnabled {
            playMarkHaptic()
        }

        let setItem = DispatchWorkItem {
            guard sequenceActive else { return }
            let setUtterance = AVSpeechUtterance(string: "Set")
            setUtterance.voice = AVSpeechSynthesisVoice(language: appStore.settings.voice.languageCode)
            synthesizer.speak(setUtterance)
            if appStore.settings.hapticsEnabled {
                playSetHaptic()
            }
        }
        setWork = setItem
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(appStore.starter.firstDelay), execute: setItem)

        let startDelay = appStore.starter.variability.randomStartDelay(baseDelay: appStore.starter.secondDelay)
        let startItem = DispatchWorkItem {
            guard sequenceActive else { return }
            startCueTime = CACurrentMediaTime()
            if let player = starterSound {
                player.prepareToPlay()
                player.play()
            }
            if appStore.settings.hapticsEnabled {
                playStartHaptic()
            }
        }
        startWork = startItem
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(appStore.starter.firstDelay) + startDelay, execute: startItem)
    }

    private func handleRelease() {
        guard sequenceActive else { return }
        if let cue = startCueTime {
            let release = CACurrentMediaTime()
            let reactionSeconds = max(0, release - cue)
            let ms = Int(reactionSeconds * 1000.0)
            if reactionSeconds < 0.1 {
                falseStart = true
                reactionMS = nil
                announceFalseStart()
                if purchaseManager.hasPro {
                    reactionHistoryStore.addFalseStart()
                }
                if appStore.settings.hapticsEnabled {
                    playFalseStartHaptic()
                }
            } else {
                if purchaseManager.hasPro {
                    reactionMS = ms
                    reactionHistoryStore.addReaction(milliseconds: ms)
                } else {
                    reactionMS = nil
                    shouldShowUpgradePrompt = true
                }
            }
            sequenceActive = false
            cancelSequence()
        } else {
            falseStart = true
            sequenceActive = false
            announceFalseStart()
            if purchaseManager.hasPro {
                reactionHistoryStore.addFalseStart()
            }
            if appStore.settings.hapticsEnabled {
                playFalseStartHaptic()
            }
            cancelSequence()
        }
    }

    private func cancelSequence() {
        setWork?.cancel()
        startWork?.cancel()
        setWork = nil
        startWork = nil
    }

    private func resetUI() {
        falseStart = false
        reactionMS = nil
        startCueTime = nil
        sequenceActive = false
        shouldShowUpgradePrompt = false
    }

    private func preloadStarterSound() {
        if let url = Bundle.main.url(forResource: appStore.settings.starter.fileName, withExtension: "mp3") {
            starterSound = try? AVAudioPlayer(contentsOf: url)
            starterSound?.prepareToPlay()
        } else {
            starterSound = nil
        }
    }

    private func speak(_ phrase: String) {
        let utterance = AVSpeechUtterance(string: phrase)
        utterance.voice = AVSpeechSynthesisVoice(language: appStore.settings.voice.languageCode)
        synthesizer.speak(utterance)
    }

    private func announceFalseStart() {
        synthesizer.stopSpeaking(at: .immediate)
        speak("False start")
    }

    private func playMarkHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }

    private func playSetHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    private func playStartHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }

    private func playFalseStartHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
    }
}

#Preview {
    NavigationStack {
        ReactionView()
            .environmentObject(AppSettingsStore())
            .environmentObject(PurchaseManager())
            .environmentObject(ReactionHistoryStore())
    }
}
