//
//  ContentView.swift
//  SprintStart
//
//  Created by Zachary Kralec on 6/10/25.
//

import SwiftUI
import AVFoundation

struct StarterView: View {
    @State private var canStart = true
    @State private var started = false
    @State private var markSeconds = 20
    @State private var startSeconds = 2.00
    @State private var selectedVariability = "Low (±0.25 sec)"
    @State private var onYourMarksRemainingTime: Double = 0
    @State private var timer: Timer?
    @State private var starterSound: AVAudioPlayer?

    @EnvironmentObject var theme: ThemeData
    @Environment(\.colorScheme) var colorScheme

    let variability = ["None (±0 sec)", "Low (±0.25 sec)", "Med (±0.5 sec)", "High (±0.75 sec)"]
    let voices: [String: String] = [
        "US Female": "en-US",
        "GB Male": "en-GB",
        "AU Female": "en-AU"
    ]
    let starters: [String: String] = [
        "Starter gun": "starter_gun",
        "Electronic starter": "electronic_starter",
        "Whistle": "short_whistle",
        "Clap": "single_clap"
    ]
    private let synthesizer = AVSpeechSynthesizer()

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        HStack {
                            Text("Sprint Start")
                                .font(.largeTitle.bold())
                            Spacer()
                            NavigationLink(destination: SettingsView()) {
                                Image(systemName: "gear")
                                    .imageScale(.large)
                            }
                        }
                        .padding(.horizontal)

                        // Countdown Ring
                        CountdownRing(
                            totalTime: Double(markSeconds),
                            remainingTime: onYourMarksRemainingTime,
                            lineWidth: 12,
                            ringColor: theme.selectedColor
                        )
                        .frame(height: 340)
                        .padding(.vertical)

                        // Timing Settings
                        VStack(spacing: 16) {
                            settingRow("Mark to Set Delay") {
                                Picker("", selection: $markSeconds) {
                                    ForEach(5..<31) { sec in
                                        Text("\(sec) sec").tag(sec)
                                    }
                                }
                                .pickerStyle(.menu)
                            }

                            settingRow("Set to Start Delay") {
                                Picker("", selection: $startSeconds) {
                                    ForEach(Array(stride(from: 1.25, through: 3.0, by: 0.25)), id: \.self) {
                                        Text(String(format: "%.2f sec", $0)).tag($0)
                                    }
                                }
                                .pickerStyle(.menu)
                            }

                            settingRow("Start Variability") {
                                Picker("", selection: $selectedVariability) {
                                    ForEach(variability, id: \.self) {
                                        Text($0)
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(14)
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 1)
                        .padding(.horizontal)

                        Spacer(minLength: 40)

                        // Start and reset buttons
                        VStack(spacing: 12) {
                            Button {
                                playStarterSequence()
                                canStart = false
                                started = true
                            } label: {
                                Text("Start")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(theme.selectedColor)
                                    .foregroundColor(.white)
                                    .cornerRadius(25)
                            }
                            .disabled(!canStart)
                            
                            Button {
                                markSeconds = 20
                                startSeconds = 2.00
                                selectedVariability = "Low (±0.25 sec)"
                                saveData()
                            } label: {
                                Label("Reset to Defaults", systemImage: "arrow.counterclockwise")
                                    .font(.subheadline)
                                    .foregroundColor(.red)
                            }
                            .padding(.top, 10)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                    .frame(minHeight: geometry.size.height)
                    .padding(.top)
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .onAppear(perform: loadData)
            .onDisappear(perform: saveData)
        }
    }

    // Setting Row
    func settingRow<T: View>(_ label: String, @ViewBuilder value: () -> T) -> some View {
        HStack {
            Text(label)
            Spacer()
            value()
        }
    }

    // Countdown View
    struct CountdownRing: View {
        let totalTime: Double
        let remainingTime: Double
        let lineWidth: CGFloat
        let ringColor: Color

        var body: some View {
            ZStack {
                Circle()
                    .stroke(lineWidth: lineWidth)
                    .opacity(0.3)
                    .foregroundColor(ringColor)

                Circle()
                    .trim(from: 0.0, to: CGFloat(remainingTime / totalTime))
                    .stroke(ringColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.1), value: remainingTime)

                Text("\(Int(remainingTime))")
                    .font(.system(size: lineWidth * 2, weight: .bold))
                    .foregroundColor(ringColor)
            }
            .padding(lineWidth / 2)
        }
    }

    // Data and logic
    private func playStarterSequence() {
        guard canStart else { return }

        let selectedVoice: String = {
            if let data = UserDefaults.standard.data(forKey: "settings"),
               let decoded = try? JSONDecoder().decode(SettingsData.self, from: data) {
                return voices[decoded.voice] ?? "en-US"
            }
            return "en-US"
        }()

        let selectedStarter: String = {
            if let data = UserDefaults.standard.data(forKey: "settings"),
               let decoded = try? JSONDecoder().decode(SettingsData.self, from: data) {
                return starters[decoded.starter] ?? "starter_gun"
            }
            return "starter_gun"
        }()

        if let soundURL = Bundle.main.url(forResource: selectedStarter, withExtension: "mp3") {
            starterSound = try? AVAudioPlayer(contentsOf: soundURL)
        }

        let startDelay: Double = {
            switch selectedVariability {
            case "Low (±0.25 sec)": return Double.random(in: (startSeconds - 0.25)...(startSeconds + 0.25))
            case "Med (±0.50 sec)": return Double.random(in: (startSeconds - 0.5)...(startSeconds + 0.5))
            case "High (±0.75 sec)": return Double.random(in: (startSeconds - 0.75)...(startSeconds + 0.75))
            default: return startSeconds
            }
        }()

        onYourMarksRemainingTime = Double(markSeconds)
        startCountdownTimer()

        let mark = AVSpeechUtterance(string: "On your marks")
        mark.voice = AVSpeechSynthesisVoice(language: selectedVoice)
        synthesizer.speak(mark)

        DispatchQueue.main.asyncAfter(deadline: .now() + Double(markSeconds)) {
            stopCountdownTimer()

            let set = AVSpeechUtterance(string: "Set")
            set.voice = AVSpeechSynthesisVoice(language: selectedVoice)
            synthesizer.speak(set)

            DispatchQueue.main.asyncAfter(deadline: .now() + startDelay) {
                starterSound?.play()
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    canStart = true
                    started = false
                }
            }
        }
    }

    private func startCountdownTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if onYourMarksRemainingTime > 0 {
                onYourMarksRemainingTime -= 1
            } else {
                timer?.invalidate()
            }
        }
    }

    private func stopCountdownTimer() {
        timer?.invalidate()
    }

    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: "delay"),
           let decoded = try? JSONDecoder().decode(StarterData.self, from: data) {
            markSeconds = decoded.firstDelay
            startSeconds = decoded.secondDelay
            selectedVariability = decoded.variability
        }
    }

    private func saveData() {
        let starterData = StarterData(firstDelay: markSeconds, secondDelay: startSeconds, variability: selectedVariability)
        if let encoded = try? JSONEncoder().encode(starterData) {
            UserDefaults.standard.set(encoded, forKey: "delay")
        }
    }
}
