//
//  ProFeature.swift
//  SprintStart
//
//  Created by Assistant on 3/8/26.
//

import Foundation

enum ProFeature: String, Identifiable {
    case general
    case reactionTracking
    case sessionHistory
    case advancedRandomness

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general:
            return "Sprint Start Pro"
        case .reactionTracking:
            return "Reaction Tracking"
        case .sessionHistory:
            return "Session History"
        case .advancedRandomness:
            return "Advanced Randomness"
        }
    }

    var subtitle: String {
        switch self {
        case .general:
            return "Unlock reaction tracking, session history, and advanced random start settings."
        case .reactionTracking:
            return "Unlock tracked reaction times and false start results."
        case .sessionHistory:
            return "Save and review recent reaction sessions."
        case .advancedRandomness:
            return "Use Medium and High randomness settings for more race-like variation."
        }
    }
}
