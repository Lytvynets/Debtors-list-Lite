

import Foundation
import Observation
import GoogleMobileAds


enum AdConfig {
    static var bannerUnitID: String {
        #if DEBUG
        return "ca-app-pub-4749079164629106/9038726773"
        #else
        return "ca-app-pub-4749079164629106/9038726773"
        #endif
    }

    static var rewardedUnitID: String {
        #if DEBUG
        return "ca-app-pub-4749079164629106/8705519785"
        #else
        return "ca-app-pub-4749079164629106/8705519785"
        #endif
    }

    static var interstitialUnitID: String {
        #if DEBUG
        return "ca-app-pub-4749079164629106/8277914103"
        #else
        return "ca-app-pub-4749079164629106/8277914103"
        #endif
    }

  
    static let interstitialEveryNthDebt = 2

    static let minimumSecondsBetweenInterstitials: TimeInterval = 60

    static let debtsSinceInterstitialKey = "debtsSinceInterstitial"
}


@MainActor
@Observable
final class RewardedAdManager: NSObject, FullScreenContentDelegate {
    private(set) var isLoading = false
    private(set) var isReady = false

    @ObservationIgnored private var rewardedAd: RewardedAd?

    func load() async {
        guard rewardedAd == nil, !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let ad = try await RewardedAd.load(with: AdConfig.rewardedUnitID, request: Request())
            ad.fullScreenContentDelegate = self
            rewardedAd = ad
            isReady = true
        } catch {
            print("Rewarded ad failed to load: \(error.localizedDescription)")
        }
    }

    @discardableResult
    func show(onReward: @escaping () -> Void) -> Bool {
        guard let ad = rewardedAd else { return false }
        ad.present(from: nil) {
            onReward()
        }
        return true
    }


    nonisolated func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        Task { @MainActor in
            await self.reset()
        }
    }

    nonisolated func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Rewarded ad failed to present: \(error.localizedDescription)")
        Task { @MainActor in
            await self.reset()
        }
    }

    private func reset() async {
        rewardedAd = nil
        isReady = false
        await load()
    }
}


@MainActor
final class InterstitialAdManager: NSObject, FullScreenContentDelegate {
    private var interstitialAd: InterstitialAd?
    private var isLoading = false
    private var lastShownAt: Date?

    func load() async {
        guard interstitialAd == nil, !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let ad = try await InterstitialAd.load(with: AdConfig.interstitialUnitID, request: Request())
            ad.fullScreenContentDelegate = self
            interstitialAd = ad
        } catch {
            print("Interstitial ad failed to load: \(error.localizedDescription)")
        }
    }

 
    func debtWasAdded() {
        let defaults = UserDefaults.standard
        let count = defaults.integer(forKey: AdConfig.debtsSinceInterstitialKey) + 1

        let isTurn = count >= AdConfig.interstitialEveryNthDebt
        let pauseIsOver = lastShownAt.map {
            Date().timeIntervalSince($0) >= AdConfig.minimumSecondsBetweenInterstitials
        } ?? true

        guard isTurn, pauseIsOver, let ad = interstitialAd else {
            defaults.set(count, forKey: AdConfig.debtsSinceInterstitialKey)
            if interstitialAd == nil {
                Task { await load() }
            }
            return
        }

        defaults.set(0, forKey: AdConfig.debtsSinceInterstitialKey)
        lastShownAt = Date()
        ad.present(from: nil)
    }


    nonisolated func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        Task { @MainActor in
            await self.reset()
        }
    }

    nonisolated func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Interstitial ad failed to present: \(error.localizedDescription)")
        Task { @MainActor in
            await self.reset()
        }
    }

    private func reset() async {
        interstitialAd = nil
        await load()
    }
}
