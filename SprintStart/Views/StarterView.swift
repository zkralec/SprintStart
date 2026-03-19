//
//  StarterView.swift
//  SprintStart
//
//  Created by Zachary Kralec on 6/10/25.
//

import SwiftUI
import AVFoundation
import UIKit

struct StarterView: View {
    @State private var canStart = true
    @State private var started = false
    @State private var onYourMarksRemainingTime: Double = 0
    @State private var timer: Timer?
    @State private var starterSound: AVAudioPlayer?
    @State private var setWork: DispatchWorkItem?
    @State private var startWork: DispatchWorkItem?
    @State private var finishWork: DispatchWorkItem?

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
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: GlassLayout.sectionSpacing) {
                    header

                    CountdownRing(
                        totalTime: Double(appStore.starter.firstDelay),
                        remainingTime: onYourMarksRemainingTime,
                        lineWidth: 12,
                        ringColor: themeColor
                    )
                    .frame(height: 330)
                    .padding(.vertical, 4)

                    TimingControlsView(
                        markDelay: $appStore.starter.firstDelay,
                        startDelay: $appStore.starter.secondDelay,
                        variability: $appStore.starter.variability,
                        timingLocked: $appStore.starter.timingLocked
                    )

                    controlsSection

                    Spacer(minLength: 12)
                }
                .frame(minHeight: geometry.size.height)
                .padding(GlassLayout.screenPadding)
            }
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
        .onDisappear {
            stopCountdownTimer()
            cancelSequence()
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("SprintStart")
                    .font(.title.bold())
                Text("Standard Mode")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "speaker.wave.3.fill")
                .font(.headline.weight(.semibold))
                .foregroundStyle(themeColor)
        }
        .liquidGlassCard()
    }

    private var controlsSection: some View {
        VStack(spacing: 12) {
            Button {
                playStarterSequence()
            } label: {
                Text(started ? "Running..." : "Start")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(LiquidGlassButtonStyle(tint: primaryButtonTint))
            .disabled(!canStart)
            .opacity(!canStart ? 0.5 : 1.0)
            .accessibilityLabel("Start sequence")

            Button {
                stopCountdownTimer()
                cancelSequence()
                onYourMarksRemainingTime = 0
                canStart = true
                started = false
                appStore.resetStarterToDefaults()
            } label: {
                Label("Reset to Defaults", systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(LiquidGlassButtonStyle(tint: .red))
            .disabled(appStore.starter.timingLocked)
            .opacity(appStore.starter.timingLocked ? 0.55 : 1.0)
            .accessibilityLabel("Reset to defaults")
            .accessibilityIdentifier("resetDefaultsButtonStandard")
        }
    }

    private func playStarterSequence() {
        guard canStart else { return }

        canStart = false
        started = true
        cancelSequence()

        try? AudioSessionManager.shared.configure(appStore.settings.playOverSilent ? .playOverSilent : .respectsSilent)

        if let soundURL = Bundle.main.url(forResource: appStore.settings.starter.fileName, withExtension: "mp3") {
            starterSound = try? AVAudioPlayer(contentsOf: soundURL)
            starterSound?.prepareToPlay()
        }

        let startDelay = appStore.starter.variability.randomStartDelay(baseDelay: appStore.starter.secondDelay)

        onYourMarksRemainingTime = Double(appStore.starter.firstDelay)
        startCountdownTimer()

        let mark = AVSpeechUtterance(string: "On your marks")
        mark.voice = AVSpeechSynthesisVoice(language: appStore.settings.voice.languageCode)
        synthesizer.speak(mark)
        if appStore.settings.hapticsEnabled {
            playMarkHaptic()
        }

        let setItem = DispatchWorkItem {
            stopCountdownTimer()

            let set = AVSpeechUtterance(string: "Set")
            set.voice = AVSpeechSynthesisVoice(language: appStore.settings.voice.languageCode)
            synthesizer.speak(set)
            if appStore.settings.hapticsEnabled && !appStore.settings.playOverSilent {
                playSetHaptic()
            }

            let startItem = DispatchWorkItem {
                let duration: TimeInterval
                if let player = starterSound {
                    player.prepareToPlay()
                    player.play()
                    duration = player.duration > 0 ? player.duration : 2.5
                } else {
                    duration = 1.0
                }

                if appStore.settings.hapticsEnabled {
                    playStartHaptic()
                }

                let finishItem = DispatchWorkItem {
                    canStart = true
                    started = false
                }
                finishWork = finishItem
                DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: finishItem)
            }

            startWork = startItem
            DispatchQueue.main.asyncAfter(deadline: .now() + startDelay, execute: startItem)
        }

        setWork = setItem
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(appStore.starter.firstDelay), execute: setItem)
    }

    private func startCountdownTimer() {
        stopCountdownTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if onYourMarksRemainingTime > 0 {
                onYourMarksRemainingTime -= 1
            } else {
                stopCountdownTimer()
            }
        }
    }

    private func stopCountdownTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func cancelSequence() {
        setWork?.cancel()
        startWork?.cancel()
        finishWork?.cancel()
        setWork = nil
        startWork = nil
        finishWork = nil
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
}

private struct CountdownRing: View {
    let totalTime: Double
    let remainingTime: Double
    let lineWidth: CGFloat
    let ringColor: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: lineWidth)
                .opacity(0.25)
                .foregroundColor(ringColor)

            Circle()
                .trim(from: 0.0, to: CGFloat(remainingTime / max(totalTime, 1)))
                .stroke(ringColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.1), value: remainingTime)

            Text("\(Int(remainingTime))")
                .font(.system(size: lineWidth * 2.2, weight: .bold))
                .foregroundColor(ringColor)
        }
        .padding(lineWidth / 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Countdown")
        .accessibilityValue(Text("\(Int(remainingTime)) seconds remaining"))
    }
}
