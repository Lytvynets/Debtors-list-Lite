
import Foundation
import Observation
import StoreKit

@MainActor
@Observable
final class IAPManager {
    static let premiumProductID = "Debtors.list.premium"

    enum PurchaseOutcome {
        case purchased
        case pending
        case cancelled
        case failed
    }

    private(set) var isPremium: Bool
    private(set) var product: Product?
    private(set) var isLoadingProduct = false
    private(set) var productLoadFailed = false

    @ObservationIgnored private var updatesTask: Task<Void, Never>?

    init() {
        isPremium = UserDefaults.standard.bool(forKey: StorageKey.isPremium)
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                await self?.handleTransactionUpdate(result)
            }
        }
    }


    func loadProduct(forceReload: Bool = false) async {
        guard forceReload || product == nil, !isLoadingProduct else { return }
        isLoadingProduct = true
        productLoadFailed = false
        defer { isLoadingProduct = false }

        do {
            let products = try await Product.products(for: [Self.premiumProductID])
            product = products.first
            productLoadFailed = products.isEmpty
        } catch {
            productLoadFailed = true
            print("⚠️ StoreKit: не вдалося завантажити продукт: \(error)")
        }
    }


    func refreshEntitlements() async {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  transaction.productID == Self.premiumProductID,
                  transaction.revocationDate == nil else { continue }
            setPremium(true)
        }
    }
    

    func handle(purchaseResult: Product.PurchaseResult) async -> PurchaseOutcome {
        switch purchaseResult {
        case .success(let verification):
            switch verification {
            case .verified(let transaction):
                if transaction.productID == Self.premiumProductID {
                    setPremium(true)
                }
                await transaction.finish()
                return .purchased
            case .unverified(_, let error):
                print("⚠️ StoreKit: транзакція не пройшла перевірку: \(error)")
                return .failed
            }
        case .pending:
            return .pending
        case .userCancelled:
            return .cancelled
        @unknown default:
            return .failed
        }
    }

    func restorePurchases() async -> Bool {
        do {
            try await AppStore.sync()
        } catch {
            print("⚠️ StoreKit: AppStore.sync: \(error)")
        }
        await refreshEntitlements()
        return isPremium
    }


    private func handleTransactionUpdate(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = result else { return }
        if transaction.productID == Self.premiumProductID {
            setPremium(transaction.revocationDate == nil)
        }
        await transaction.finish()
    }

    private func setPremium(_ value: Bool) {
        guard isPremium != value else { return }
        isPremium = value
        UserDefaults.standard.set(value, forKey: StorageKey.isPremium)
    }
}
