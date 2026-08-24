//
//  PremiumVersionPaywall.swift
//  Debtors-list
//
//  Created by Vlad Lytvynets on 02.10.2024.
//

import Foundation
import UIKit
import StoreKit

class PremiumVersionPaywall: UIViewController {
    
    let screenSize: CGRect = UIScreen.main.bounds
    
    private lazy var headerLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = NSLocalizedString("Premium version", comment: "") //"Premium version"
        label.textColor = .orange
        label.textAlignment = .center
        return label
    }()
    
    
    private lazy var listLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "\(NSLocalizedString("Disables all ads", comment: "")) \n\(NSLocalizedString("Allows you to set up notifications about debts", comment: ""))" //"Disables all ads \nAllows you to set up notifications about debts"
        label.textColor = .white
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    
    private lazy var nameAndPriceLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .darkGray
        label.textAlignment = .center
        return label
    }()
    
    
    private lazy var continueButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(NSLocalizedString("Continue", comment: ""), for: .normal)
        button.backgroundColor = #colorLiteral(red: 0.246193856, green: 0.02283299714, blue: 0.3634002805, alpha: 1)
        button.layer.cornerRadius = 15
        button.addTarget(self, action: #selector(continueButtonAction), for: .touchUpInside)
        return button
    }()
    
    
    private lazy var dismissButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = .darkGray
        button.addTarget(self, action: #selector(dismissButtonAction), for: .touchUpInside)
        return button
    }()
    
    
    private lazy var restoreButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("restore", for: .normal)
        button.addTarget(self, action: #selector(restoreButtonAction), for: .touchUpInside)
        button.setTitleColor(.darkGray, for: .normal)
        return button
    }()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = SetColors.currentColor.backgroundColor
        
        let backgroundImage = UIImageView(frame: UIScreen.main.bounds)
        backgroundImage.image = UIImage(named: "Back")
        backgroundImage.contentMode = .scaleAspectFill
        
        view.insertSubview(backgroundImage, at: 0)
        view.addSubview(dismissButton)
        view.addSubview(continueButton)
        view.addSubview(restoreButton)
        view.addSubview(headerLabel)
        view.addSubview(listLabel)
        view.addSubview(nameAndPriceLabel)
        setConstraints()
        fontSettings()
    }
    
    
    override func viewDidLayoutSubviews() {
        priceSettings()
    }
    
    
    private func setConstraints() {
        NSLayoutConstraint.activate([
            dismissButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),
            dismissButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            
            headerLabel.bottomAnchor.constraint(equalTo: listLabel.topAnchor, constant: -15),
            headerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            headerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
            headerLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),
            
            listLabel.bottomAnchor.constraint(equalTo: nameAndPriceLabel.topAnchor, constant: -15),
            listLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            listLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
            listLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),
            
            nameAndPriceLabel.bottomAnchor.constraint(equalTo: continueButton.topAnchor, constant: -30),
            nameAndPriceLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nameAndPriceLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
            nameAndPriceLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),
            
            continueButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 17),
            continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -17),
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -45),
            continueButton.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 1/15),
            
            
            restoreButton.topAnchor.constraint(equalTo: continueButton.bottomAnchor, constant: 5),
            restoreButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            restoreButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 17),
            restoreButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -17),
            
        ])
    }
    
    
    func fontSettings() {
        headerLabel.font = UIFont(name: "Noteworthy Bold", size: 27)
        listLabel.font = UIFont(name: "Futura Medium", size: 20)
        nameAndPriceLabel.font = UIFont(name: "Futura Medium", size: 15)
        restoreButton.titleLabel?.font = UIFont(name: "Avenir Book", size: 15)
        continueButton.titleLabel?.font = UIFont(name: "Futura Medium", size: 20)
    }
    
    
    @objc private func dismissButtonAction() {
        self.dismiss(animated: true)
    }
    
    @objc private func continueButtonAction() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        if let product = IAPManager.shared.products.first {
            IAPManager.shared.buyProduct(product: product)
        }
    }
    
    @objc private func restoreButtonAction() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        SKPaymentQueue.default().restoreCompletedTransactions()
        self.dismiss(animated: true)
    }
    
    
    private func priceSettings() {
        guard let product = IAPManager.shared.products.first else { return }
        let price = IAPManager.shared.getPriceString(for: product)
        DispatchQueue.main.async {
            self.nameAndPriceLabel.text =  "\(NSLocalizedString("Premium version for", comment: "")) \(price)"
        }
    }
}
