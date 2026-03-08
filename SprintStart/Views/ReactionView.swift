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

    @EnvironmentObject var appStore: AppSettingsStore

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
                        .overlay(
                            TouchCaptureView { count in
                                if count > 0 {
                                    if !isHolding {
                                        isHolding = true
                                        beginArmedSequence()
                                    }
                                } else {
                                    if isHolding {
                                        isHolding = false
                                        handleRelease()
                                    }
                                }
                            }
                        )
                }
                .frame(height: 338)
                .contentShape(Rectangle())
                .accessibilityLabel("Reaction zone")
                .accessibilityHint("Place one or more fingers to arm. Release on the start cue to record your reaction time.")

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
        .navigationTitle("SprintStart")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
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
            if let ms = reactionMS {
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
            } else {
                Text("Press and hold to arm")
                    .font(.title2)
            }

            Text("Release on the start cue to record your reaction.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Text("Timing is based on the app cue and may vary slightly.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
    }

    private func beginArmedSequence() {
        falseStart = false
        reactionMS = nil
        sequenceActive = true
        startCueTime = nil

        speak("On your marks")

        let setItem = DispatchWorkItem {
            guard sequenceActive else { return }
            let setUtterance = AVSpeechUtterance(string: "Set")
            setUtterance.voice = AVSpeechSynthesisVoice(language: appStore.settings.voice.languageCode)
            synthesizer.speak(setUtterance)
            if appStore.settings.hapticsEnabled && !appStore.settings.playOverSilent {
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
            if appStore.settings.hapticsEnabled && (!appStore.settings.playOverSilent || starterSound == nil) {
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
                if appStore.settings.hapticsEnabled {
                    playFalseStartHaptic()
                }
            } else {
                reactionMS = ms
            }
            sequenceActive = false
            cancelSequence()
        } else {
            falseStart = true
            sequenceActive = false
            announceFalseStart()
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
    }
}
