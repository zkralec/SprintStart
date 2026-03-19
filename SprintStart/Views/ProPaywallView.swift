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
            ScrollView {
                VStack(spacing: GlassLayout.sectionSpacing) {
                    heroSection
                    valueSection
                    trustSection
                    actionSection
                }
                .padding(GlassLayout.screenPadding)
            }
            .navigationTitle("Sprint Start Pro")
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
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sprint Start Pro")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text("Train Like It's Race Day")
                        .font(.title.bold())
                    Text(feature.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "figure.run.circle.fill")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(appStore.settings.theme.accentColor)
            }

            HStack(spacing: 10) {
                tagLabel(feature.title)
                tagLabel("One-time purchase")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidGlassCard()
    }

    private var valueSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What You Unlock")
                .font(.headline)

            VStack(spacing: 14) {
                benefitRow(
                    title: "Reaction time tracking",
                    subtitle: "Record release reaction times and false starts in Reaction Mode."
                )
                benefitRow(
                    title: "Session history",
                    subtitle: "Save recent attempts so you can review each training block."
                )
                benefitRow(
                    title: "Advanced randomness",
                    subtitle: "Add Medium and High presets for more race-like start variation."
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidGlassCard()
    }

    private var trustSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Simple and Native")
                    .font(.headline)
                Text("Sprint Start Pro keeps the app focused while unlocking the training features that benefit from tracking and deeper control.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                detailBlock(title: "Purchase", value: "One-time")
                detailBlock(title: "Price", value: purchaseManager.displayPrice)
                detailBlock(title: "Restore", value: "Included")
            }

            Text("Uses Apple's in-app purchase system. No subscription and no separate account required.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidGlassCard()
    }

    private var actionSection: some View {
        VStack(spacing: 14) {
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

    private func benefitRow(title: String, subtitle: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.primary)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private func detailBlock(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
