//
//  IAPManager.swift
//  Debtors-list
//
//  Created by Vlad Lytvynets on 27.06.2024.
//

import Foundation
import StoreKit

class IAPManager: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    
    static let restoreCompletedNotification = Notification.Name("restoreCompletedNotification")
    static let restoreFailedNotification = Notification.Name("restoreFailedNotification")
    static let purchaseSuccessful = Notification.Name("purchaseSuccessful")
    static let purchaseFailed = Notification.Name("purchaseFailed")
    static let shared = IAPManager()
    var products = [SKProduct]()
    
    
    override init() {
        super.init()
        SKPaymentQueue.default().add(self)
    }
    
    
    func getPriceString(for product: SKProduct) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceLocale
        return formatter.string(from: product.price) ?? "\(product.price)"
    }
    
    
    func isPremiumUser() -> Bool {
        return UserDefaults.standard.bool(forKey: "isPremiumUser")
    }
    
    
    func fetchProducts() {
        let productIdentifiers: Set<String> = ["Debtors.list.premium"]
        let request = SKProductsRequest(productIdentifiers: productIdentifiers)
        request.delegate = self
        request.start()
    }
    
    
    func buyProduct(product: SKProduct) {
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        let products = response.products
        self.products = products
    }
    
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                SKPaymentQueue.default().finishTransaction(transaction)
                UserDefaults.standard.set(true, forKey: "isPremiumUser")
                NotificationCenter.default.post(name: IAPManager.purchaseSuccessful, object: self)
            case .failed:
                SKPaymentQueue.default().finishTransaction(transaction)
                NotificationCenter.default.post(name: IAPManager.purchaseFailed, object: self)
            default:
                break
            }
        }
    }
    
    
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        print("paymentQueue Error: \(error.localizedDescription)")
        NotificationCenter.default.post(name: IAPManager.restoreFailedNotification, object: self)
    }
    
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        for transaction in queue.transactions {
            if transaction.transactionState == .restored {
                UserDefaults.standard.set(true, forKey: "isPremiumUser")
                NotificationCenter.default.post(name: IAPManager.restoreCompletedNotification, object: self)
                SKPaymentQueue.default().finishTransaction(transaction)
                print("paymentQueue Finished")
            }
        }
    }
}
