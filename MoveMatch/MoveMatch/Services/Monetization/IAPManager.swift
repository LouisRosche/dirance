//
//  IAPManager.swift
//  MoveMatch
//
//  StoreKit 2 In-App Purchases
//

import Foundation
import StoreKit

@MainActor
class IAPManager: ObservableObject {

    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []

    private var transactionListener: Task<Void, Error>?

    init() {
        transactionListener = listenForTransactions()
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Load Products

    func loadProducts() async {
        do {
            let productIDs = IAPProduct.allCases.map { $0.rawValue }
            products = try await Product.products(for: productIDs)

            print("✅ Loaded \(products.count) products")
        } catch {
            print("❌ Failed to load products: \(error)")
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async -> Bool {
        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)

                // Grant entitlement
                await grantEntitlement(for: transaction)

                // Finish transaction
                await transaction.finish()

                await updatePurchasedProducts()

                print("✅ Purchase successful: \(product.id)")
                return true

            case .userCancelled:
                print("⚠️ Purchase cancelled by user")
                return false

            case .pending:
                print("⏳ Purchase pending")
                return false

            @unknown default:
                return false
            }
        } catch {
            print("❌ Purchase failed: \(error)")
            return false
        }
    }

    // MARK: - Restore Purchases

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
            print("✅ Purchases restored")
        } catch {
            print("❌ Failed to restore purchases: \(error)")
        }
    }

    // MARK: - Private Methods

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw IAPError.failedVerification(error)
        case .verified(let safe):
            return safe
        }
    }

    private func grantEntitlement(for transaction: Transaction) async {
        guard let productID = IAPProduct(rawValue: transaction.productID) else {
            print("⚠️ Unknown product ID: \(transaction.productID)")
            return
        }

        switch productID {
        case .gems100:
            // Grant 100 gems
            await grantGems(100)

        case .gems500:
            await grantGems(500)

        case .gems1500:
            await grantGems(1500)

        case .seasonPass:
            await unlockSeasonPass()

        case .vipMonthly:
            await activateVIP()

        case .noAds24h:
            await disableAdsFor(hours: 24)

        case .fitnessPack:
            await unlockFitnessPack()
        }

        // Log analytics
        // Analytics.logEvent("purchase", parameters: ["product_id": productID.rawValue])
    }

    private func grantGems(_ amount: Int) async {
        // This would update user profile in Firebase
        print("✅ Granted \(amount) gems")
        // AppState.shared.currentUser?.addGems(amount)
    }

    private func unlockSeasonPass() async {
        print("✅ Unlocked Season Pass")
        // AppState.shared.currentUser?.hasSeasonPass = true
    }

    private func activateVIP() async {
        print("✅ Activated VIP")
        // AppState.shared.currentUser?.isVIP = true
    }

    private func disableAdsFor(hours: Int) async {
        print("✅ Disabled ads for \(hours) hours")
    }

    private func unlockFitnessPack() async {
        print("✅ Unlocked Fitness Pack")
    }

    private func updatePurchasedProducts() async {
        var purchasedIDs: Set<String> = []

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                continue
            }

            if transaction.revocationDate == nil {
                purchasedIDs.insert(transaction.productID)
            }
        }

        purchasedProductIDs = purchasedIDs
    }

    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else {
                    continue
                }

                await self.grantEntitlement(for: transaction)
                await transaction.finish()
            }
        }
    }
}

// MARK: - Error

enum IAPError: Error {
    case failedVerification(Error)
}
