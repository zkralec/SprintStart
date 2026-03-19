//
//  ProPaywallView.swift
//  SprintStart
//
//  Created by Assistant on 3/8/26.
//

import SwiftUI

struct ProPaywallView: View {
    @EnvironmentObject private var appStore: AppSettingsStore
    @EnvironmentObject var purchaseManager: PurchaseManager
    @Environment(\.dismiss) private var dismiss

    let feature: ProFeature

    @State private var message: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                heroSection
                valueSection
                trustSection
                Spacer(minLength: 0)
                actionSection
            }
            .padding(GlassLayout.screenPadding)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("Close")
                }
            }
        }
        .liquidGlassScreenBackground(theme: appStore.settings.theme)
        .task {
            if purchaseManager.proProduct == nil {
                await purchaseManager.loadProducts()
            }
        }
        .alert("Sprint Start Pro", isPresented: Binding(
            get: { message != nil },
            set: { if !$0 { message = nil } }
        )) {
            Button("OK") {}
        } message: {
            Text(message ?? "")
        }
    }

    private var heroSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "figure.run.circle.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(appStore.settings.theme.accentColor)
                Text("Sprint Start Pro")
                    .font(.headline.weight(.semibold))
            }

            VStack(spacing: 6) {
                Text("Train Like It's Race Day")
                    .font(.title.bold())
                Text("Unlock reaction tracking, session history, and advanced randomness.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 10) {
                tagLabel("One-time purchase")
                tagLabel(purchaseManager.displayPrice)
            }
        }
        .frame(maxWidth: .infinity)
        .liquidGlassCard()
    }

    private var valueSection: some View {
        VStack(spacing: 12) {
            benefitRow("Reaction time tracking")
            benefitRow("Session history")
            benefitRow("Advanced randomness")
            benefitRow("More voice, sound, and theme options")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidGlassCard()
    }

    private var trustSection: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                detailBlock(title: "Purchase", value: "One-time")
                detailBlock(title: "Restore", value: "Included")
                detailBlock(title: "Access", value: "Apple ID")
            }

            Text("Uses Apple's in-app purchase system. No subscription.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .liquidGlassCard()
    }

    private var actionSection: some View {
        VStack(spacing: 12) {
            Button {
                Task {
                    let outcome = await purchaseManager.purchasePro()
                    switch outcome {
                    case .purchased:
                        dismiss()
                    case .cancelled:
                        break
                    case .pending:
                        message = "Purchase is pending approval."
                    case .failed(let errorMessage):
                        message = errorMessage
                    }
                }
            } label: {
                Text("Unlock Sprint Start Pro • \(purchaseManager.displayPrice)")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(LiquidGlassButtonStyle(tint: .black))
            .disabled(purchaseManager.isPurchasing || purchaseManager.isLoadingProducts)
            .opacity((purchaseManager.isPurchasing || purchaseManager.isLoadingProducts) ? 0.6 : 1.0)

            Button {
                Task {
                    let outcome = await purchaseManager.restorePurchases()
                    switch outcome {
                    case .restored:
                        dismiss()
                    case .nothingToRestore:
                        message = "No previous Sprint Start Pro purchase was found."
                    case .failed(let errorMessage):
                        message = errorMessage
                    }
                }
            } label: {
                Text("Restore Purchases")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Text("One-time purchase. No subscription. Restores across your devices with the same Apple Account.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .liquidGlassCard()
    }

    private func benefitRow(_ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.primary)
            Text(text)
                .font(.subheadline.weight(.semibold))
            Spacer()
        }
    }

    private func detailBlock(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
    }

    private func tagLabel(_ text: String) -> some View {
        Text(text)
            .font(.footnote.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: Capsule())
    }
}

#Preview {
    ProPaywallView(feature: .general)
        .environmentObject(AppSettingsStore())
        .environmentObject(PurchaseManager())
}
