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
    @State private var variability = ["None (±0 sec)", "Low (±0.25 sec)", "Med (±0.5 sec)", "High (±0.75 sec)"]
    @State private var selectedVariability = "Low (±0.25 sec)"
    @State private var starterData: StarterData?
    @State private var onYourMarksRemainingTime: Double = 0
    @State private var timer: Timer?
    
    private let synthesizer = AVSpeechSynthesizer()
    private var starterGunSound: AVAudioPlayer?
    
    init() {
        // Load starter gun sound
        if let soundURL = Bundle.main.url(forResource: "starter_gun", withExtension: "mp3") {
            starterGunSound = try? AVAudioPlayer(contentsOf: soundURL)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // Settings button
                Section {
                    HStack {
                        ZStack {
                            Text("Sprint Start")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            HStack {
                                NavigationLink {
                                    SettingsView()
                                } label: {
                                    Image(systemName: "gear")
                                }
                                
                                Spacer()
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Timer display section
                Section {
                    VStack {
                        CountdownRing(
                            totalTime: Double(markSeconds),
                            remainingTime: onYourMarksRemainingTime,
                            lineWidth: 10,
                            ringColor: .blue
                        )
                        .padding()
                    }
                }
                
                Spacer()
                
                // Mark delay section
                Section {
                    HStack {
                        Text("Mark to Set Delay")
                        
                        Spacer()
                        
                        Picker("", selection: $markSeconds) {
                            ForEach(5..<31) { sec in
                                Text("\(sec) sec").tag(sec)
                                    .foregroundStyle(Color.primary)
                            }
                        }
                        .onChange(of: markSeconds) {
                            saveData()
                            print("Saving mark delay of \(markSeconds)") // Debug
                        }
                    }
                }
                
                Spacer()
                
                // Start delay section
                Section {
                    HStack {
                        Text("Set to Start Delay")
                        
                        Spacer()
                        
                        Picker("", selection: $startSeconds) {
                            ForEach(Array(stride(from: 1.25, through: 3.0, by: 0.25)), id: \.self) { sec in
                                Text(String(format: "%.2f sec", sec))
                                    .tag(sec)
                                    .foregroundStyle(Color.primary)
                            }
                        }
                        .onChange(of: startSeconds) {
                            saveData()
                            print("Saving start delay of \(startSeconds)") // Debug
                        }
                    }
                }
                
                Spacer()
                
                // Variability section
                Section {
                    HStack {
                        Text("Start Variability")
                        
                        Spacer()
                        
                        Picker("", selection: $selectedVariability) {
                            ForEach(variability, id: \.self) { select in
                                Text(select)
                            }
                        }
                        .onChange(of: selectedVariability) {
                            saveData()
                            print("Saving variability of \(selectedVariability)") // Debug
                        }
                    }
                }
                
                Spacer()
                
                // Start button
                Section {
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            playStarterSequence(canStart: canStart, seconds: markSeconds)
                            canStart = false
                            started = true
                        }) {
                            HStack {
                                Image(systemName: "play.circle")
                                Text("Start")
                            }
                            .foregroundColor(.blue)
                        }
                        
                        Spacer()
                    }
                }
                
                Spacer()
                
                // Reset to default button
                Section {
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            markSeconds = 20
                            startSeconds = 2.00
                            selectedVariability = "Low (±0.25 sec)"
                            saveData()
                            print("Saving all options") // Debug
                        }) {
                            HStack {
                                Image(systemName: "trash.circle")
                                Text("Reset to defaults")
                            }
                            .foregroundColor(.blue)
                        }
                        
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 30)
        }
        .onAppear {
            loadData()
        }
        .onDisappear {
            saveData()
        }
    }
    
    // This plays all the sounds and text that is needed based on user input
    private func playStarterSequence(canStart: Bool, seconds: Int) {
        if canStart {
            var startDelay: Double
            
            if selectedVariability == "Low (±0.25 sec)" {
                startDelay = Double.random(in: (startSeconds - 0.25)...(startSeconds + 0.25))
            } else if selectedVariability == "Med (±0.50 sec)" {
                startDelay = Double.random(in: (startSeconds - 0.5)...(startSeconds + 0.5))
            } else if selectedVariability == "High (±0.75 sec)" {
                startDelay = Double.random(in: (startSeconds - 0.75)...(startSeconds + 0.75))
            } else {
                startDelay = startSeconds
            }
            
            onYourMarksRemainingTime = Double(seconds)
            startCountdownTimer()
            
            // On your mark
            let mark = AVSpeechUtterance(string: "On your marks")
            mark.voice = AVSpeechSynthesisVoice(language: "en-US")
            synthesizer.speak(mark)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(seconds)) {
                stopCountdownTimer()
                
                // Set
                DispatchQueue.main.asyncAfter(deadline: .now()) {
                    let set = AVSpeechUtterance(string: "Set")
                    set.voice = AVSpeechSynthesisVoice(language: "en-US")
                    synthesizer.speak(set)
                    
                    // Bang
                    // let randomDelay = Double.random(in: 1.5...2.25)
                    DispatchQueue.main.asyncAfter(deadline: .now() + startDelay) {
                        self.starterGunSound?.play()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            self.canStart = true
                            self.started = false
                        }
                    }
                }
            }
        }
    }
    
    // Load the user selections from UserDefaults
    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: "firstDelay"),
           let decoded = try? JSONDecoder().decode(StarterData.self, from: data) {
            starterData = decoded
            markSeconds = starterData?.firstDelay ?? 20
            startSeconds = starterData?.secondDelay ?? 1.75
            selectedVariability = starterData?.variability ?? "Low (±0.25 sec)"
        }
    }
    
    // Save the user selections to UserDefaults
    private func saveData() {
        starterData = StarterData(firstDelay: markSeconds, secondDelay: startSeconds, variability: selectedVariability)
        if let encoded = try? JSONEncoder().encode(starterData) {
            UserDefaults.standard.set(encoded, forKey: "firstDelay")
        }
        if let encoded = try? JSONEncoder().encode(starterData) {
            UserDefaults.standard.set(encoded, forKey: "secondDelay")
        }
        if let encoded = try? JSONEncoder().encode(starterData) {
            UserDefaults.standard.set(encoded, forKey: "variability")
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
}

#Preview {
    StarterView()
}
