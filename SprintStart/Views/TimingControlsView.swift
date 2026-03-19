//
//  TimingControlsView.swift
//  SprintStart
//
//  Created by Assistant on 3/8/26.
//

import SwiftUI

struct TimingControlsView: View {
    @Binding var markDelay: Int
    @Binding var startDelay: Double
    @Binding var variability: VariabilityOption
    @Binding var timingLocked: Bool

    @EnvironmentObject private var purchaseManager: PurchaseManager

    @State private var showVariabilityHelp = false
    @State private var paywallFeature: ProFeature?

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Text("Timing")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        timingLocked.toggle()
                    }
                } label: {
                    Image(systemName: timingLocked ? "lock.fill" : "lock.open")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .accessibilityLabel(timingLocked ? "Unlock timing controls" : "Lock timing controls")
                .accessibilityIdentifier("timingLockButton")
            }

            delayAdjuster(
                title: "Mark to Set",
                valueText: "\(markDelay) sec",
                canDecrement: markDelay > 1,
                canIncrement: markDelay < 30,
                decrement: { markDelay = max(1, markDelay - 1) },
                increment: { markDelay = min(30, markDelay + 1) }
            )

            delayAdjuster(
                title: "Set to Start",
                valueText: String(format: "%.2f sec", startDelay),
                canDecrement: startDelay > 1.0,
                canIncrement: startDelay < 5.0,
                decrement: { startDelay = max(1.0, startDelay - 0.25) },
                increment: { startDelay = min(5.0, startDelay + 0.25) }
            )

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Variability")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            showVariabilityHelp.toggle()
                        }
                    } label: {
                        Image(systemName: showVariabilityHelp ? "questionmark.circle.fill" : "questionmark.circle")
                            .font(.subheadline.weight(.semibold))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Variability help")
                }

                Picker("Variability", selection: variabilitySelection) {
                    ForEach(availableVariabilityOptions) { option in
                        Text(variabilityLabel(for: option)).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(timingLocked)

                if showVariabilityHelp {
                    Text(variabilityDescription)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .transition(.opacity)
                }

                if !purchaseManager.hasPro {
                    Button {
                        paywallFeature = .advancedRandomness
                    } label: {
                        Text("Upgrade to Sprint Start Pro for more variability presets.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }
            .opacity(timingLocked ? 0.7 : 1.0)
        }
        .liquidGlassCard()
        .sheet(item: $paywallFeature) { feature in
            ProPaywallView(feature: feature)
        }
        .onAppear {
            enforceFreeVariability()
        }
        .onChange(of: purchaseManager.hasPro) {
            enforceFreeVariability()
        }
    }

    private var variabilityDescription: String {
        switch variability {
        case .none:
            return "No randomization. Start uses exactly the selected Set to Start time."
        case .low:
            return "Low randomization: Set to Start varies by up to ±0.25 sec."
        case .medium:
            return "Medium randomization: Set to Start varies by up to ±0.5 sec."
        case .high:
            return "High randomization: Set to Start varies by up to ±0.75 sec."
        }
    }

    private var variabilitySelection: Binding<VariabilityOption> {
        Binding(
            get: { variability },
            set: { newValue in
                guard !timingLocked else { return }
                variability = newValue
            }
        )
    }

    private var availableVariabilityOptions: [VariabilityOption] {
        if purchaseManager.hasPro {
            return VariabilityOption.allCases
        }
        return [.none, .low]
    }

    private func variabilityLabel(for option: VariabilityOption) -> String {
        switch option {
        case .none:
            return "None"
        case .low:
            return "Low"
        case .medium:
            return "Med"
        case .high:
            return "High"
        }
    }

    private func delayAdjuster(
        title: String,
        valueText: String,
        canDecrement: Bool,
        canIncrement: Bool,
        decrement: @escaping () -> Void,
        increment: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(valueText)
                    .font(.headline)
            }

            Spacer()

            HoldRepeatButton(systemImage: "minus", isDisabled: timingLocked || !canDecrement, action: decrement)
            HoldRepeatButton(systemImage: "plus", isDisabled: timingLocked || !canIncrement, action: increment)
        }
        .opacity(timingLocked ? 0.7 : 1.0)
    }

    private func enforceFreeVariability() {
        guard !purchaseManager.hasPro, variability.requiresPro else { return }
        variability = .low
    }
}

private struct HoldRepeatButton: View {
    let systemImage: String
    let isDisabled: Bool
    let action: () -> Void

    @State private var isPressing = false
    @State private var repeatTimer: Timer?
    @State private var delayedStart: DispatchWorkItem?

    var body: some View {
        Image(systemName: systemImage)
            .font(.callout.weight(.bold))
            .frame(width: 30, height: 30)
            .background(.ultraThinMaterial, in: Circle())
            .overlay(
                Circle()
                    .strokeBorder(Color.white.opacity(isPressing ? 0.45 : 0.25), lineWidth: 1)
            )
            .scaleEffect(isPressing ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.12), value: isPressing)
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard !isDisabled else { return }
                        guard !isPressing else { return }
                        isPressing = true
                        action()
                        scheduleRepeat()
                    }
                    .onEnded { _ in
                        stopRepeating()
                    }
            )
            .onDisappear {
                stopRepeating()
            }
            .opacity(isDisabled ? 0.55 : 1.0)
            .accessibilityAddTraits(.isButton)
    }

    private func scheduleRepeat() {
        let work = DispatchWorkItem {
            guard isPressing else { return }
            repeatTimer = Timer.scheduledTimer(withTimeInterval: 0.09, repeats: true) { _ in
                action()
            }
        }

        delayedStart = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32, execute: work)
    }

    private func stopRepeating() {
        isPressing = false
        delayedStart?.cancel()
        delayedStart = nil
        repeatTimer?.invalidate()
        repeatTimer = nil
    }
}

#Preview {
    TimingControlsView(
        markDelay: .constant(20),
        startDelay: .constant(2.0),
        variability: .constant(.low),
        timingLocked: .constant(false)
    )
    .environmentObject(PurchaseManager())
}
