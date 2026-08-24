//
//  MainViewControllerExtensions.swift
//  Debtors-list
//
//  Created by Vlad Lytvynets on 24.04.2024.
//

import Foundation
import UIKit

extension MainViewController: CommonViewDelegate {
    func presentActionSheet(alertController: UIAlertController) {
        present(alertController, animated: true)
    }
    
    
    func presentScreen() {
        let vc = AddNewDebtViewController(state: false)
        vc.editDataDelegate = self
        navigationController?.pushViewController(vc, animated: true)
    }
    
    
    func showNewDebtorScreen() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        switch IAPManager.shared.isPremiumUser() {
        case true:
            presentScreen()
        case false:
            rewardedAdManager.showRewardedAd(viewController: self)
            presentScreen()
        }
    }
}


extension MainViewController: ShowEditDataDelegate {
    func showEditScreen(vc: UIViewController) {
        present(vc, animated: true)
    }
}


extension MainViewController: EditDataDelegate {
    func reloadTableView() {
        viewModel.removeAllData()
        viewModel.addToLastOperationsArray()
        commonView.mainTableView.sortedArray = viewModel.array
        viewModel.sumLabelsInfo { yourDebt, debtor in
            self.commonView.infoView.youDebtLabel.text = yourDebt
            self.commonView.infoView.debtLabel.text = debtor
        }
        commonView.mainTableView.reloadData()
    }
}
