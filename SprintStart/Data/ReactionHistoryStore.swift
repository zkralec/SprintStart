//
//  ReactionHistoryStore.swift
//  SprintStart
//
//  Created by Assistant on 3/8/26.
//

import Foundation

struct ReactionHistoryEntry: Codable, Identifiable, Equatable {
    let id: UUID
    let date: Date
    let reactionMS: Int?
    let falseStart: Bool

    init(date: Date = .now, reactionMS: Int? = nil, falseStart: Bool) {
        self.id = UUID()
        self.date = date
        self.reactionMS = reactionMS
        self.falseStart = falseStart
    }
}

@MainActor
final class ReactionHistoryStore: ObservableObject {
    @Published private(set) var entries: [ReactionHistoryEntry] = [] {
        didSet { save() }
    }

    private let defaults: UserDefaults

    private enum Keys {
        static let history = "reactionHistory"
        static let maxEntries = 5000
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    func addReaction(milliseconds: Int) {
        entries.insert(ReactionHistoryEntry(reactionMS: milliseconds, falseStart: false), at: 0)
        trim()
    }

    func addFalseStart() {
        entries.insert(ReactionHistoryEntry(falseStart: true), at: 0)
        trim()
    }

    private func trim() {
        if entries.count > Keys.maxEntries {
            entries = Array(entries.prefix(Keys.maxEntries))
        }
    }

    private func load() {
        if let data = defaults.data(forKey: Keys.history),
           let decoded = try? JSONDecoder().decode([ReactionHistoryEntry].self, from: data) {
            entries = decoded
        }
    }

    private func save() {
        if let encoded = try? JSONEncoder().encode(entries) {
            defaults.set(encoded, forKey: Keys.history)
        }
    }
}
