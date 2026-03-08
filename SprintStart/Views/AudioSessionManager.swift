//
//  AudioSessionManager.swift
//  SprintStart
//
//  Created by Assistant on 3/7/26.
//

import AVFAudio

enum AudioRouteMode {
    case respectsSilent
    case playOverSilent
}

final class AudioSessionManager {
    static let shared = AudioSessionManager()
    private init() {}

    func configure(_ mode: AudioRouteMode) throws {
        let session = AVAudioSession.sharedInstance()
        switch mode {
        case .respectsSilent:
            try session.setCategory(.ambient)
        case .playOverSilent:
            try session.setCategory(.playback, options: [.mixWithOthers])
        }
        try session.setActive(true)
    }

    func deactivate() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
