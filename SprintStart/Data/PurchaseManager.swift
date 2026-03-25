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
    @Published private(set) var lastStoreKitDebugMessage: String = ""
    @Published var lastErrorMessage: String?

    private let defaults: UserDefaults
    private var updatesTask: Task<Void, Never>?

    private enum Keys {
        static let proCache = "hasSprintStartPro"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.hasPro = defaults.bool(forKey: Keys.proCache)

        updatesTask = observeTransactionUpdates()

        Task {
            await syncEntitlementsAtLaunch()
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
        updateDebugMessage("Loading products")
        print("SS_IAP >>> FETCH START")
        print("SS_IAP >>> FETCH REQUEST IDS = \(requestedIDs)")
        defer { isLoadingProducts = false }

        do {
            let fetchedProducts = try await Product.products(for: requestedIDs)
            print("SS_IAP >>> FETCH COUNT = \(fetchedProducts.count)")
            print("SS_IAP >>> FETCH IDS = \(fetchedProducts.map(\.id))")

            if fetchedProducts.isEmpty {
                products = []
                productLoadState = .empty
                let message = "Purchase options are temporarily unavailable for \(Self.productID)."
                lastErrorMessage = message
                updateDebugMessage("Empty product array for \(Self.productID)")
                print("SS_IAP >>> EMPTY ARRAY")
                return
            }

            products = fetchedProducts
            productLoadState = .loaded
            lastErrorMessage = nil
            updateDebugMessage("Loaded \(fetchedProducts.count) product(s)")
        } catch {
            products = []
            let friendlyMessage = "Purchase options are temporarily unavailable. Please try again in a moment."
            productLoadState = .failed(friendlyMessage)
            lastErrorMessage = friendlyMessage
            updateDebugMessage("Fetch failed: \(error.localizedDescription)")
            print("SS_IAP >>> FETCH ERROR = \(error)")
        }
    }

    func syncEntitlementsAtLaunch() async {
        await finishUnfinishedTransactions()
        await refreshEntitlements()
    }

    func purchasePro() async -> PurchaseOutcome {
        print("SS_IAP >>> PURCHASE TAPPED")
        updateDebugMessage("Purchase started")

        if proProduct == nil {
            await loadProducts()
        }

        guard let product = proProduct else {
            print("SS_IAP >>> PURCHASE LOOKUP FAILED AFTER RELOAD")
            updateDebugMessage("Purchase lookup failed after reload")
            return .failed("Purchase options are temporarily unavailable. Please try again in a moment.")
        }

        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                print("SS_IAP >>> PURCHASE RESULT = success")
                let transaction = try checkVerified(verification)
                await refreshEntitlements()
                await transaction.finish()
                return .purchased
            case .userCancelled:
                print("SS_IAP >>> PURCHASE RESULT = userCancelled")
                return .cancelled
            case .pending:
                print("SS_IAP >>> PURCHASE RESULT = pending")
                return .pending
            @unknown default:
                print("SS_IAP >>> PURCHASE RESULT = unknown")
                return .failed("Purchase could not be completed.")
            }
        } catch {
            print("SS_IAP >>> PURCHASE ERROR = \(error)")
            updateDebugMessage("Purchase failed: \(error.localizedDescription)")
            if let purchaseError = error as? PurchaseError, purchaseError == .failedVerification {
                return .failed("Purchase verification failed. Please try again.")
            }
            return .failed("Purchase could not be completed. Please try again.")
        }
    }

    func restorePurchases() async -> RestoreOutcome {
        print("SS_IAP >>> RESTORE START")
        updateDebugMessage("Restore started")
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            print("SS_IAP >>> RESTORE RESULT hasPro = \(hasPro)")
            return hasPro ? .restored : .nothingToRestore
        } catch {
            print("SS_IAP >>> RESTORE ERROR = \(error)")
            updateDebugMessage("Restore failed: \(error.localizedDescription)")
            return .failed("Restore failed. Please try again.")
        }
    }

    private func refreshEntitlements() async {
        var proUnlocked = false

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            guard transaction.productID == Self.productID else { continue }
            guard transaction.revocationDate == nil else { continue }

            proUnlocked = true
        }

        hasPro = proUnlocked
        defaults.set(proUnlocked, forKey: Keys.proCache)
        print("SS_IAP >>> ENTITLEMENTS REFRESH hasPro = \(proUnlocked)")
        updateDebugMessage("Entitlements refreshed: hasPro=\(proUnlocked)")
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
            print("SS_IAP >>> VERIFICATION FAILURE")
            throw PurchaseError.failedVerification
        }
    }

    private func updateDebugMessage(_ message: String) {
        lastStoreKitDebugMessage = message
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
