//
//  AdManager.swift
//  MoveMatch
//
//  Google AdMob rewarded video ads
//

import Foundation
import GoogleMobileAds

@MainActor
class AdManager: NSObject, ObservableObject {

    @Published var isAdReady = false

    private var rewardedAd: GADRewardedAd?
    private var adUnitID = "ca-app-pub-3940256099942544/1712485313" // Test ID

    override init() {
        super.init()
        loadRewardedAd()
    }

    // MARK: - Load Ad

    func loadRewardedAd() {
        let request = GADRequest()

        GADRewardedAd.load(
            withAdUnitID: adUnitID,
            request: request
        ) { [weak self] ad, error in
            if let error = error {
                print("❌ Failed to load rewarded ad: \(error)")
                self?.isAdReady = false
                return
            }

            self?.rewardedAd = ad
            self?.rewardedAd?.fullScreenContentDelegate = self
            self?.isAdReady = true

            print("✅ Rewarded ad loaded")
        }
    }

    // MARK: - Show Ad

    func showRewardedAd(
        from viewController: UIViewController,
        onReward: @escaping (Int) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        guard let ad = rewardedAd else {
            print("⚠️ Ad not ready, granting reward anyway (good UX)")
            onReward(0)
            onDismiss()
            return
        }

        ad.present(fromRootViewController: viewController) {
            let reward = ad.adReward
            print("✅ User earned reward: \(reward.amount)")
            onReward(Int(truncating: reward.amount))
        }

        // Store callbacks
        self.onAdReward = onReward
        self.onAdDismissed = onDismiss
    }

    // MARK: - Callbacks

    private var onAdReward: ((Int) -> Void)?
    private var onAdDismissed: (() -> Void)?
}

// MARK: - GADFullScreenContentDelegate

extension AdManager: GADFullScreenContentDelegate {

    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("📱 Ad dismissed")

        onAdDismissed?()
        onAdReward = nil
        onAdDismissed = nil

        // Load next ad
        loadRewardedAd()
    }

    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("❌ Ad failed to present: \(error)")

        onAdDismissed?()
        onAdReward = nil
        onAdDismissed = nil

        // Try to load again
        loadRewardedAd()
    }
}

// MARK: - Helper to get UIViewController

extension AdManager {

    func getRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return nil
        }

        return rootViewController
    }
}
