//
//  AppPurchaseView.swift
//  Debtors-list
//
//  Created by Vlad Lytvynets on 27.06.2024.
//

import Foundation
import UIKit
import StoreKit

class AppPurchaseView: UIView {
    
    var customAlert = CustomAlert()
    
    var headerLabel: UILabel = {
        let label = UILabel()
        label.text = "You will be able to add an unlimited number of debts to the list and without advertising. You will also have the option to enable reminder notifications"
        label.font = UIFont(name: "Futura Medium", size: 15)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    
    private lazy var priceLabel: UILabel = {
        let label = UILabel()
        label.text = "Premium version for _ "
        label.font = UIFont(name: "Futura Medium", size: 15)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    
    private lazy var buyButton: UIButton = {
        let button = UIButton()
        button.setTitle("Buy Premium version", for: .normal)
        button.layer.cornerRadius = 15
        button.layer.borderWidth = 2
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(buyButtonAction), for: .touchUpInside)
        return button
    }()
    
    
    private lazy var resumePurchasesButton: UIButton = {
        let button = UIButton()
        button.setTitle("Restored purchases", for: .normal)
        button.layer.cornerRadius = 15
        button.layer.borderWidth = 2
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(resumePurchasesButtonAction), for: .touchUpInside)
        return button
    }()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(headerLabel)
        addSubview(priceLabel)
        addSubview(buyButton)
        addSubview(resumePurchasesButton)
        addSubview(customAlert)
        colorSettings()
        priceSettings()
        setConstraints()
        customAlert.isHidden = true
        addNotificationCenter()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func addNotificationCenter() {
        NotificationCenter.default.addObserver(self, selector: #selector(restoreCompletedNotification),name: IAPManager.restoreCompletedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(restoreFailedNotification), name: IAPManager.restoreFailedNotification, object: nil)
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(purchaseSuccessfulNotification),name: IAPManager.purchaseSuccessful, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(purchaseFailedNotification), name: IAPManager.purchaseFailed, object: nil)
    }
    
    
    
    private func colorSettings() {
        backgroundColor = SetColors.currentColor.backgroundColor
        headerLabel.textColor = SetColors.currentColor.labelsColor
        priceLabel.textColor = .green
        buyButton.setTitleColor(SetColors.currentColor.labelsColor, for: .normal)
        buyButton.backgroundColor = SetColors.currentColor.backgroundColor
        buyButton.layer.borderColor = SetColors.currentColor.labelsColor.cgColor
        resumePurchasesButton.setTitleColor(SetColors.currentColor.labelsColor, for: .normal)
        resumePurchasesButton.backgroundColor = SetColors.currentColor.backgroundColor
        resumePurchasesButton.layer.borderColor = SetColors.currentColor.labelsColor.cgColor
    }
    
    
    private func priceSettings() {
        guard let product = IAPManager.shared.products.first else { return }
        let price = IAPManager.shared.getPriceString(for: product)
        switch IAPManager.shared.isPremiumUser() {
        case true:
            priceLabel.text = "You already have the premium version"
        case false:
            priceLabel.text = "Premium version for \(price)"
        }
    }
    
    
    private func setConstraints() {
        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 15),
            headerLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            headerLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            headerLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            priceLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 30),
            priceLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            priceLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 25),
            priceLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            buyButton.topAnchor.constraint(equalTo: priceLabel.bottomAnchor, constant: 25),
            buyButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            buyButton.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 1/1.5),
            buyButton.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 1/16),
            resumePurchasesButton.topAnchor.constraint(equalTo: buyButton.bottomAnchor, constant: 20),
            resumePurchasesButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            resumePurchasesButton.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 1/1.5),
            resumePurchasesButton.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 1/16),
            
            customAlert.topAnchor.constraint(equalTo: buyButton.topAnchor, constant: -5),
            customAlert.centerXAnchor.constraint(equalTo: centerXAnchor),
            customAlert.centerYAnchor.constraint(equalTo: centerYAnchor),
            customAlert.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 1/5.5),
            customAlert.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 1/1.5),
        ])
    }
    
    
    func fontSettings() {
        customAlert.headerLabel.font = UIFont(name: "Futura Medium", size: frame.height * 0.02)
        headerLabel.font = UIFont(name: "Futura Medium", size: frame.height * 0.02)
        priceLabel.font = UIFont(name: "Futura Medium", size: frame.height * 0.02)
        buyButton.titleLabel?.font = UIFont(name: "Futura Medium", size: frame.height * 0.02)
        resumePurchasesButton.titleLabel?.font = UIFont(name: "Futura Medium", size: frame.height * 0.02)
    }
    
    
    func showAlert(title: String) {
        UIView.transition(with: customAlert, duration: 0.5,
                          options: .transitionFlipFromTop,
                          animations: {
            self.customAlert.isHidden = false
            self.customAlert.headerLabel.text = title
        })
    }
    
    
    //MARK: - Actions
    @objc private func buyButtonAction() {
        if let product = IAPManager.shared.products.first {
            IAPManager.shared.buyProduct(product: product)
        }
    }
    
    
    @objc private func resumePurchasesButtonAction() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    
    @objc func restoreCompletedNotification() {
        self.showAlert(title: "The restore of purchases was completed successfully")
        self.priceLabel.text = "You already have the premium version"
    }
    
    
    @objc func restoreFailedNotification() {
        self.showAlert(title: "Something is wrong")
    }
    
    
    @objc func purchaseSuccessfulNotification() {
        self.showAlert(title: "The purchase was successful, thank you)")
        self.priceLabel.text = "You already have the premium version"
    }
    
    
    @objc func purchaseFailedNotification() {
        self.showAlert(title: "An error occurred during purchase")
    }
}
