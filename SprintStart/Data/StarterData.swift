//
//  StarterData.swift
//  SprintStart
//
//  Created by Zachary Kralec on 6/10/25.
//

import Foundation

enum VariabilityOption: String, Codable, CaseIterable, Identifiable {
    case none
    case low
    case medium
    case high

    var id: Self { self }

    var displayName: String {
        switch self {
        case .none: return "None (±0 sec)"
        case .low: return "Low (±0.25 sec)"
        case .medium: return "Med (±0.5 sec)"
        case .high: return "High (±0.75 sec)"
        }
    }

    var offsetSeconds: Double {
        switch self {
        case .none: return 0
        case .low: return 0.25
        case .medium: return 0.5
        case .high: return 0.75
        }
    }

    var requiresPro: Bool {
        switch self {
        case .medium, .high:
            return true
        case .none, .low:
            return false
        }
    }

    init(legacyLabel: String) {
        switch legacyLabel {
        case "None (±0 sec)": self = .none
        case "Med (±0.5 sec)": self = .medium
        case "High (±0.75 sec)": self = .high
        default: self = .low
        }
    }

    func randomStartDelay(baseDelay: Double) -> Double {
        let offset = offsetSeconds
        guard offset > 0 else { return max(0.2, baseDelay) }
        return max(0.2, Double.random(in: (baseDelay - offset)...(baseDelay + offset)))
    }
}

struct StarterData: Codable, Equatable {
    var firstDelay: Int
    var secondDelay: Double
    var variability: VariabilityOption
    var timingLocked: Bool

    static let `default` = StarterData(
        firstDelay: 20,
        secondDelay: 2.0,
        variability: .low,
        timingLocked: false
    )

    private enum CodingKeys: String, CodingKey {
        case firstDelay
        case secondDelay
        case variability
        case timingLocked
    }

    init(firstDelay: Int, secondDelay: Double, variability: VariabilityOption, timingLocked: Bool) {
        self.firstDelay = firstDelay
        self.secondDelay = secondDelay
        self.variability = variability
        self.timingLocked = timingLocked
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        firstDelay = try container.decodeIfPresent(Int.self, forKey: .firstDelay) ?? 20
        secondDelay = try container.decodeIfPresent(Double.self, forKey: .secondDelay) ?? 2.0

        if let typedVariability = try? container.decode(VariabilityOption.self, forKey: .variability) {
            variability = typedVariability
        } else if let legacyVariability = try container.decodeIfPresent(String.self, forKey: .variability) {
            variability = VariabilityOption(legacyLabel: legacyVariability)
        } else {
            variability = .low
        }
        timingLocked = try container.decodeIfPresent(Bool.self, forKey: .timingLocked) ?? false
    }
}
