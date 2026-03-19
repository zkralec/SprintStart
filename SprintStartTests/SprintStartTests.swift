//
//  SprintStartTests.swift
//  SprintStartTests
//
//  Created by Zachary Kralec on 6/10/25.
//

import Foundation
import Testing
@testable import SprintStart

struct SprintStartTests {

    @Test
    func settingsDataDecodesLegacyPayload() throws {
        let legacyJSON = """
        {
          \"voice\": \"GB Male\",
          \"starter\": \"Whistle\",
          \"theme\": \"Indigo\",
          \"playOverSilent\": true
        }
        """

        let data = try #require(legacyJSON.data(using: .utf8))
        let decoded = try JSONDecoder().decode(SettingsData.self, from: data)

        #expect(decoded.voice == .gbMale)
        #expect(decoded.starter == .whistle)
        #expect(decoded.theme == .indigo)
        #expect(decoded.playOverSilent)
        #expect(decoded.hapticsEnabled)
    }

    @Test
    func starterDataDecodesLegacyVariabilityLabel() throws {
        let legacyJSON = """
        {
          \"firstDelay\": 15,
          \"secondDelay\": 2.25,
          \"variability\": \"High (±0.75 sec)\"
        }
        """

        let data = try #require(legacyJSON.data(using: .utf8))
        let decoded = try JSONDecoder().decode(StarterData.self, from: data)

        #expect(decoded.firstDelay == 15)
        #expect(decoded.secondDelay == 2.25)
        #expect(decoded.variability == .high)
        #expect(decoded.timingLocked == false)
    }

    @Test
    func variabilityDelayStaysInsideExpectedRange() {
        let base = 2.0
        let samples = (0..<500).map { _ in
            VariabilityOption.high.randomStartDelay(baseDelay: base)
        }

        #expect(samples.allSatisfy { $0 >= 1.25 && $0 <= 2.75 })
    }

    @Test
    func settingsDataDefaultsToStandardModeWhenMissing() throws {
        let legacyJSON = """
        {
          \"voice\": \"US Female\",
          \"starter\": \"Starter gun\",
          \"theme\": \"Blue\"
        }
        """

        let data = try #require(legacyJSON.data(using: .utf8))
        let decoded = try JSONDecoder().decode(SettingsData.self, from: data)

        #expect(decoded.lastMode == .standard)
    }

    @Test
    func starterDataDecodesTimingLockWhenPresent() throws {
        let json = """
        {
          \"firstDelay\": 12,
          \"secondDelay\": 1.75,
          \"variability\": \"low\",
          \"timingLocked\": true
        }
        """

        let data = try #require(json.data(using: .utf8))
        let decoded = try JSONDecoder().decode(StarterData.self, from: data)

        #expect(decoded.timingLocked == true)
    }

    @Test
    func variabilityProRequirementMatchesProductDesign() {
        #expect(VariabilityOption.none.requiresPro == false)
        #expect(VariabilityOption.low.requiresPro == false)
        #expect(VariabilityOption.medium.requiresPro == true)
        #expect(VariabilityOption.high.requiresPro == true)
    }

    @MainActor
    @Test
    func reactionHistoryStoreTrimsToMostRecentTwentyEntries() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let store = ReactionHistoryStore(defaults: defaults)
        for index in 0..<25 {
            store.addReaction(milliseconds: 100 + index)
        }

        #expect(store.entries.count == 20)
        #expect(store.entries.first?.reactionMS == 124)
        #expect(store.entries.last?.reactionMS == 105)
    }
}
