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
    private weak var appState: AppState?

    init(appState: AppState? = nil) {
        self.appState = appState
        transactionListener = listenForTransactions()
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    func setAppState(_ appState: AppState) {
        self.appState = appState
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
            ErrorHandler.shared.handle(.iap(.unknownProduct))
            return
        }

        switch productID {
        case .gems100:
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

        AnalyticsManager.shared.trackIAPSuccess(
            productId: productID.rawValue,
            price: 0, // Will be filled by caller with actual price
            revenue: 0
        )
    }

    private func grantGems(_ amount: Int) async {
        guard let appState = appState else {
            ErrorHandler.shared.handle(.iap(.grantFailed))
            return
        }

        guard var user = appState.currentUser else { return }
        user.addGems(amount)
        appState.currentUser = user

        // Save to Firebase
        Task {
            do {
                try await appState.firebaseManager.saveUserProfile(profile: user)
            } catch {
                ErrorHandler.shared.handle(.firebase(.saveDataFailed))
            }
        }
    }

    private func unlockSeasonPass() async {
        guard let appState = appState else {
            ErrorHandler.shared.handle(.iap(.grantFailed))
            return
        }

        guard var user = appState.currentUser else { return }
        user.hasSeasonPass = true
        appState.currentUser = user

        Task {
            do {
                try await appState.firebaseManager.saveUserProfile(profile: user)
            } catch {
                ErrorHandler.shared.handle(.firebase(.saveDataFailed))
            }
        }
    }

    private func activateVIP() async {
        guard let appState = appState else {
            ErrorHandler.shared.handle(.iap(.grantFailed))
            return
        }

        guard var user = appState.currentUser else { return }
        user.isVIP = true
        user.vipExpiry = Calendar.current.date(byAdding: .month, value: 1, to: Date())
        appState.currentUser = user

        Task {
            do {
                try await appState.firebaseManager.saveUserProfile(profile: user)
                AnalyticsManager.shared.trackSubscriptionStarted(plan: "vip_monthly")
            } catch {
                ErrorHandler.shared.handle(.firebase(.saveDataFailed))
            }
        }
    }

    private func disableAdsFor(hours: Int) async {
        guard let appState = appState else {
            ErrorHandler.shared.handle(.iap(.grantFailed))
            return
        }

        guard var user = appState.currentUser else { return }
        user.adFreeUntil = Calendar.current.date(byAdding: .hour, value: hours, to: Date())
        appState.currentUser = user

        Task {
            do {
                try await appState.firebaseManager.saveUserProfile(profile: user)
            } catch {
                ErrorHandler.shared.handle(.firebase(.saveDataFailed))
            }
        }
    }

    private func unlockFitnessPack() async {
        guard let appState = appState else {
            ErrorHandler.shared.handle(.iap(.grantFailed))
            return
        }

        guard var user = appState.currentUser else { return }
        user.hasFitnessPack = true
        appState.currentUser = user

        Task {
            do {
                try await appState.firebaseManager.saveUserProfile(profile: user)
            } catch {
                ErrorHandler.shared.handle(.firebase(.saveDataFailed))
            }
        }
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
