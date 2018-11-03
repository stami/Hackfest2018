//
//  UIViewController+Alert.swift
//  Hackfest2018
//
//  Created by Samuli Tamminen on 3.11.2018.
//  Copyright © 2018 Samuli Tamminen. All rights reserved.
//

import UIKit

extension UIViewController {

    func showAlert(title: String?, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
}
