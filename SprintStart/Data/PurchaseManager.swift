//
//  PurchaseManager.swift
//  SprintStart
//
//  Created by Assistant on 3/8/26.
//

import Foundation
import StoreKit

enum ProductLoadState: Equatable {
    case idle
    case loading
    case loaded
    case empty
    case failed(String)
}

@MainActor
final class PurchaseManager: ObservableObject {
    static let productID = "com.sprintstart.pro"

    @Published private(set) var products: [Product] = []
    @Published private(set) var hasPro: Bool
    @Published private(set) var isLoadingProducts = false
    @Published private(set) var isPurchasing = false
    @Published private(set) var hasCompletedInitialLoad = false
    @Published private(set) var productLoadState: ProductLoadState = .idle
    @Published var lastErrorMessage: String?

    private let defaults: UserDefaults
    private let forceFreeTierForUITests: Bool
    private var updatesTask: Task<Void, Never>?

    private enum Keys {
        static let proCache = "hasSprintStartPro"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let launchArguments = ProcessInfo.processInfo.arguments
        self.forceFreeTierForUITests = launchArguments.contains("-forceFreeTierForUITests")
        if launchArguments.contains("-resetProPurchaseState") {
            defaults.removeObject(forKey: Keys.proCache)
        }
        self.hasPro = forceFreeTierForUITests ? false : defaults.bool(forKey: Keys.proCache)

        updatesTask = observeTransactionUpdates()

        Task {
            if !forceFreeTierForUITests {
                await syncEntitlementsAtLaunch()
            }
            await loadProducts()
            hasCompletedInitialLoad = true
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    var proProduct: Product? {
        products.first { $0.id == Self.productID }
    }

    var displayPrice: String {
        proProduct?.displayPrice ?? "App Store price"
    }

    func loadProducts() async {
        let requestedIDs = [Self.productID]
        isLoadingProducts = true
        productLoadState = .loading
        defer { isLoadingProducts = false }

        do {
            let fetchedProducts = try await Product.products(for: requestedIDs)

            if fetchedProducts.isEmpty {
                products = []
                productLoadState = .empty
                let message = "Purchase options are temporarily unavailable for \(Self.productID)."
                lastErrorMessage = message
                return
            }

            products = fetchedProducts
            productLoadState = .loaded
            lastErrorMessage = nil
        } catch {
            products = []
            let friendlyMessage = "Purchase options are temporarily unavailable. Please try again in a moment."
            productLoadState = .failed(friendlyMessage)
            lastErrorMessage = friendlyMessage
        }
    }

    func syncEntitlementsAtLaunch() async {
        await finishUnfinishedTransactions()
        await refreshEntitlements()
    }

    func purchasePro() async -> PurchaseOutcome {
        if proProduct == nil {
            await loadProducts()
        }

        guard let product = proProduct else {
            return .failed("Purchase options are temporarily unavailable. Please try again in a moment.")
        }

        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await refreshEntitlements()
                await transaction.finish()
                return .purchased
            case .userCancelled:
                return .cancelled
            case .pending:
                return .pending
            @unknown default:
                return .failed("Purchase could not be completed.")
            }
        } catch {
            if let purchaseError = error as? PurchaseError, purchaseError == .failedVerification {
                return .failed("Purchase verification failed. Please try again.")
            }
            return .failed("Purchase could not be completed. Please try again.")
        }
    }

    func restorePurchases() async -> RestoreOutcome {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            return hasPro ? .restored : .nothingToRestore
        } catch {
            return .failed("Restore failed. Please try again.")
        }
    }

    private func refreshEntitlements() async {
        if forceFreeTierForUITests {
            hasPro = false
            defaults.set(false, forKey: Keys.proCache)
            return
        }

        var proUnlocked = false

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            guard transaction.productID == Self.productID else { continue }
            guard transaction.revocationDate == nil else { continue }

            proUnlocked = true
        }

        hasPro = proUnlocked
        defaults.set(proUnlocked, forKey: Keys.proCache)
    }

    private func finishUnfinishedTransactions() async {
        for await result in Transaction.unfinished {
            guard let transaction = try? checkVerified(result) else { continue }
            await transaction.finish()
        }
    }

    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task(priority: .background) {
            for await result in Transaction.updates {
                guard let transaction = try? self.checkVerified(result) else { continue }
                await self.refreshEntitlements()
                await transaction.finish()
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified:
            throw PurchaseError.failedVerification
        }
    }
}

enum PurchaseOutcome {
    case purchased
    case cancelled
    case pending
    case failed(String)
}

enum RestoreOutcome {
    case restored
    case nothingToRestore
    case failed(String)
}

enum PurchaseError: Error, Equatable {
    case failedVerification
}
