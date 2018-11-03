//
//  AppCoordinator.swift
//  Hackfest2018
//
//  Created by Samuli Tamminen on 3.11.2018.
//  Copyright © 2018 Samuli Tamminen. All rights reserved.
//

import UIKit

class AppCoordinator {

    let window: UIWindow
    let rootNavigationController: UINavigationController

    init(window: UIWindow) {
        self.window = window
        rootNavigationController = UINavigationController()
        window.rootViewController = rootNavigationController
    }

    func start() {
        showMainScreen()
    }

    func showMainScreen() {
        let viewController = MainViewController()
        rootNavigationController.pushViewController(viewController, animated: false)
    }
}
