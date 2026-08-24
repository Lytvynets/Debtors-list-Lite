//
//  CustomAlert.swift
//  Debtors-list
//
//  Created by Vlad Lytvynets on 28.06.2024.
//

import Foundation
import UIKit

class CustomAlert: UIView {
    
    var headerLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textColor = SetColors.currentColor.labelsColor
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    
    private lazy var okButton: UIButton = {
        let button = UIButton()
        button.setTitle("Ok", for: .normal)
        button.setTitleColor(SetColors.currentColor.labelsColor, for: .normal)
        button.layer.cornerRadius = 15
        button.layer.borderWidth = 1
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(dismissAlert), for: .touchUpInside)
        return button
    }()
    
    
    @objc func dismissAlert() {
        self.isHidden = true
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = SetColors.currentColor.backgroundCustomViewColor
        layer.borderWidth = 1
        layer.borderColor = UIColor.systemGray.cgColor
        layer.cornerRadius = 15
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(headerLabel)
        addSubview(okButton)
        setConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private func setConstraints() {
        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            headerLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            headerLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            headerLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            okButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            okButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            okButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            okButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
        ])
    }
}
