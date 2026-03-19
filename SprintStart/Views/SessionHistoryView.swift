//
//  SessionHistoryView.swift
//  SprintStart
//
//  Created by Assistant on 3/8/26.
//

import SwiftUI
import Charts

struct SessionHistoryView: View {
    private enum HistoryRange: String, CaseIterable, Identifiable {
        case day
        case week
        case month
        case year
        case all

        var id: Self { self }

        var title: String {
            switch self {
            case .day: return "1D"
            case .week: return "1W"
            case .month: return "1M"
            case .year: return "1Y"
            case .all: return "All"
            }
        }

        func lowerBound(from now: Date) -> Date? {
            let calendar = Calendar.current
            switch self {
            case .day:
                return calendar.date(byAdding: .day, value: -1, to: now)
            case .week:
                return calendar.date(byAdding: .day, value: -7, to: now)
            case .month:
                return calendar.date(byAdding: .month, value: -1, to: now)
            case .year:
                return calendar.date(byAdding: .year, value: -1, to: now)
            case .all:
                return nil
            }
        }
    }

    @EnvironmentObject private var appStore: AppSettingsStore
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @EnvironmentObject private var reactionHistoryStore: ReactionHistoryStore

    @State private var selectedRange: HistoryRange = .month

    private var allEntries: [ReactionHistoryEntry] {
        reactionHistoryStore.entries.sorted { $0.date < $1.date }
    }

    private var filteredEntries: [ReactionHistoryEntry] {
        guard let lowerBound = selectedRange.lowerBound(from: .now) else { return allEntries }
        return allEntries.filter { $0.date >= lowerBound }
    }

    private var reactionEntries: [ReactionHistoryEntry] {
        filteredEntries.filter { !$0.falseStart && $0.reactionMS != nil }
    }

    private var falseStartCount: Int {
        filteredEntries.filter(\.falseStart).count
    }

    private var averageReaction: Int? {
        let results = reactionEntries.compactMap(\.reactionMS)
        guard !results.isEmpty else { return nil }
        return Int(Double(results.reduce(0, +)) / Double(results.count))
    }

    private var bestReaction: Int? {
        reactionEntries.compactMap(\.reactionMS).min()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: GlassLayout.sectionSpacing) {
                header

                if purchaseManager.hasPro {
                    rangePicker
                    statsSection
                    chartSection
                    attemptsSection
                } else {
                    lockedSection
                }
            }
            .padding(GlassLayout.screenPadding)
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .liquidGlassScreenBackground(theme: appStore.settings.theme)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Session History")
                .font(.title2.bold())
            Text("Track reaction trends over time and review recent attempts.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidGlassCard()
    }

    private var rangePicker: some View {
        Picker("History Range", selection: $selectedRange) {
            ForEach(HistoryRange.allCases) { range in
                Text(range.title).tag(range)
            }
        }
        .pickerStyle(.segmented)
        .liquidGlassCard()
    }

    private var statsSection: some View {
        HStack(spacing: 12) {
            historyStat(title: "Best", value: bestReaction.map { "\($0) ms" } ?? "--")
            historyStat(title: "Average", value: averageReaction.map { "\($0) ms" } ?? "--")
            historyStat(title: "False Starts", value: "\(falseStartCount)")
        }
        .liquidGlassCard()
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reaction Trend")
                .font(.headline)

            if reactionEntries.isEmpty {
                chartPlaceholder(
                    title: "No tracked reactions yet",
                    subtitle: "Complete a Reaction Mode attempt to start building your history."
                )
            } else if reactionEntries.count == 1 {
                VStack(alignment: .leading, spacing: 10) {
                    Text("\(reactionEntries[0].reactionMS ?? 0) ms")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(appStore.settings.theme.accentColor)
                    Text("You need at least two tracked attempts in this range to see a trend line.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Chart(reactionEntries) { entry in
                    if let reactionMS = entry.reactionMS {
                        LineMark(
                            x: .value("Attempt Date", entry.date),
                            y: .value("Reaction Time", reactionMS)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(appStore.settings.theme.accentColor)
                        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                        PointMark(
                            x: .value("Attempt Date", entry.date),
                            y: .value("Reaction Time", reactionMS)
                        )
                        .foregroundStyle(appStore.settings.theme.accentColor)
                        .symbolSize(40)
                    }
                }
                .frame(height: 240)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4))
                }
                .chartPlotStyle { content in
                    content
                        .background(.ultraThinMaterial.opacity(0.35))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidGlassCard()
    }

    private var attemptsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Attempts")
                .font(.headline)

            if filteredEntries.isEmpty {
                Text("No attempts are available in this time range.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(filteredEntries.suffix(8).reversed()) { entry in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.falseStart ? "False Start" : "\(entry.reactionMS ?? 0) ms")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(entry.falseStart ? .red : .primary)
                            Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: entry.falseStart ? "xmark.circle.fill" : "checkmark.circle.fill")
                            .foregroundStyle(entry.falseStart ? .red : appStore.settings.theme.accentColor)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidGlassCard()
    }

    private var lockedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Sprint Start Pro")
                .font(.headline)
            Text("Session History is included with Pro so your reaction results and false starts stay organized over time.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidGlassCard()
    }

    private func historyStat(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func chartPlaceholder(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            Text(subtitle)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    NavigationStack {
        SessionHistoryView()
            .environmentObject(AppSettingsStore())
            .environmentObject(PurchaseManager())
            .environmentObject(ReactionHistoryStore())
    }
}
