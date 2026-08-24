//
//  AppPurchaseScreen.swift
//  Debtors-list
//
//  Created by Vlad Lytvynets on 27.06.2024.
//

import Foundation
import UIKit

class AppPurchaseViewController: UIViewController {
    
    var appPurchaseView = AppPurchaseView()
    
    override func loadView() {
        view = appPurchaseView
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        appPurchaseView.fontSettings()
    }
}
