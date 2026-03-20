//
//  PurchaseManager.swift
//  SprintStart
//
//  Created by Assistant on 3/8/26.
//

import Foundation
import StoreKit

@MainActor
final class PurchaseManager: ObservableObject {
    static let productID = "com.sprintstart.pro"

    @Published private(set) var products: [Product] = []
    @Published private(set) var hasPro: Bool
    @Published private(set) var isLoadingProducts = false
    @Published private(set) var isPurchasing = false
    @Published private(set) var hasCompletedInitialLoad = false
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
            await debugLoadProducts()
            await syncEntitlementsAtLaunch()
            hasCompletedInitialLoad = true
            await loadProducts()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    var proProduct: Product? {
        products.first { $0.id == Self.productID }
    }

    var displayPrice: String {
        proProduct?.displayPrice ?? "$2.99"
    }

    func loadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }

        print("SS_IAP >>> FETCH START")

        do {
            products = try await Product.products(for: [Self.productID])
            print("SS_IAP >>> FETCH COUNT = \(products.count)")
            print("SS_IAP >>> FETCH IDS = \(products.map(\.id))")
            if products.isEmpty {
                print("SS_IAP >>> EMPTY ARRAY")
            }
        } catch {
            print("SS_IAP >>> FETCH ERROR = \(error.localizedDescription)")
            lastErrorMessage = "Unable to load Sprint Start Pro right now."
        }
    }

    func syncEntitlementsAtLaunch() async {
        await finishUnfinishedTransactions()
        await refreshEntitlements()
    }

    func purchasePro() async -> PurchaseOutcome {
        print("SS_IAP >>> PURCHASE TAPPED")

        if proProduct == nil {
            await loadProducts()
        }

        guard let product = proProduct else {
            return .failed("Sprint Start Pro is unavailable right now.")
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
            print("SS_IAP >>> PURCHASE ERROR = \(error.localizedDescription)")
            return .failed(error.localizedDescription)
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

    func debugLoadProducts() async {
        await loadProducts()
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

enum PurchaseError: Error {
    case failedVerification
}
