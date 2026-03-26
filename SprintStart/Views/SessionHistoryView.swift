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

    private struct ChartPoint: Identifiable {
        let id: UUID
        let attemptNumber: Int
        let date: Date
        let reactionMS: Int
    }

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

    private var chartPoints: [ChartPoint] {
        reactionEntries.enumerated().compactMap { index, entry in
            guard let reactionMS = entry.reactionMS else { return nil }
            return ChartPoint(
                id: entry.id,
                attemptNumber: index + 1,
                date: entry.date,
                reactionMS: reactionMS
            )
        }
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
        .toolbar(.hidden, for: .tabBar)
        .liquidGlassScreenBackground(theme: appStore.settings.theme)
    }

    private var header: some View {
        AppSectionHeader(
            systemName: "chart.line.uptrend.xyaxis",
            tint: appStore.settings.theme.accentColor,
            title: "Session History",
            summary: "Review your sessions."
        )
        .liquidGlassCard()
    }

    private var rangePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            AppSectionHeader(
                systemName: "calendar",
                tint: appStore.settings.theme.accentColor,
                title: "Range",
                summary: "Pick a window."
            )

            Picker("History Range", selection: $selectedRange) {
                ForEach(HistoryRange.allCases) { range in
                    Text(range.title).tag(range)
                }
            }
            .pickerStyle(.segmented)
        }
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
            AppSectionHeader(
                systemName: "waveform.path.ecg",
                tint: appStore.settings.theme.accentColor,
                title: "Reaction Trend",
                summary: "See progress."
            )

            if chartPoints.isEmpty {
                chartPlaceholder(
                    title: "No tracked reps yet",
                    subtitle: "Complete a few Reaction Mode reps and your trend line will appear here."
                )
            } else if chartPoints.count == 1 {
                VStack(alignment: .leading, spacing: 10) {
                    Text("\(chartPoints[0].reactionMS) ms")
                        .font(AppTypography.metricCompact)
                        .foregroundStyle(appStore.settings.theme.accentColor)
                    Text("You need at least two tracked attempts in this range to see a trend line.")
                        .font(AppTypography.secondary)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Chart(chartPoints) { point in
                    LineMark(
                        x: .value("Attempt", point.attemptNumber),
                        y: .value("Reaction Time", point.reactionMS)
                    )
                    .interpolationMethod(.linear)
                    .foregroundStyle(appStore.settings.theme.accentColor)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                    PointMark(
                        x: .value("Attempt", point.attemptNumber),
                        y: .value("Reaction Time", point.reactionMS)
                    )
                    .foregroundStyle(appStore.settings.theme.accentColor)
                    .symbolSize(50)
                }
                .frame(height: 240)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks(values: xAxisValues) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel {
                            if let attemptNumber = value.as(Int.self),
                               let point = chartPoint(for: attemptNumber) {
                                VStack(spacing: 2) {
                                    Text("A\(attemptNumber)")
                                    Text(point.date, format: selectedRange == .day ? .dateTime.hour().minute() : .dateTime.month(.abbreviated).day())
                                }
                                .font(AppTypography.caption)
                                .multilineTextAlignment(.center)
                            }
                        }
                    }
                }
                .chartXAxisLabel("Attempt Order")
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
            AppSectionHeader(
                systemName: "list.bullet.rectangle",
                tint: appStore.settings.theme.accentColor,
                title: "Recent Attempts",
                summary: "Latest reps."
            )

            if filteredEntries.isEmpty {
                Text("No attempts are in this range yet. Try a wider range or complete a few more reps.")
                    .font(AppTypography.secondary)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(filteredEntries.suffix(8).reversed()) { entry in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.falseStart ? "False Start" : "\(entry.reactionMS ?? 0) ms")
                                .font(AppTypography.bodyStrong)
                                .foregroundStyle(entry.falseStart ? .red : .primary)
                            Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                                .font(AppTypography.caption)
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
            AppSectionHeader(
                systemName: "lock.fill",
                tint: appStore.settings.theme.accentColor,
                title: "Unlock Pro",
                summary: "History is part of Pro."
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidGlassCard()
    }

    private func historyStat(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppTypography.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(AppTypography.cardTitle)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .appInsetPanel(tint: appStore.settings.theme.accentColor, cornerRadius: 18)
    }

    private func chartPlaceholder(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(AppTypography.bodyStrong)
            Text(subtitle)
                .font(AppTypography.secondary)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var xAxisValues: [Int] {
        guard let lastAttempt = chartPoints.last?.attemptNumber else { return [] }
        if chartPoints.count <= 4 {
            return chartPoints.map(\.attemptNumber)
        }

        let midpoint = max(2, Int(round(Double(lastAttempt) / 2.0)))
        let quarter = max(2, Int(round(Double(lastAttempt) / 4.0)))
        let threeQuarter = max(3, Int(round(Double(lastAttempt) * 0.75)))

        return Array(Set([1, quarter, midpoint, threeQuarter, lastAttempt])).sorted()
    }

    private func chartPoint(for attemptNumber: Int) -> ChartPoint? {
        chartPoints.first { $0.attemptNumber == attemptNumber }
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
