//
//  Constants.swift
//  Hackfest2018
//
//  Created by Samuli Tamminen on 3.11.2018.
//  Copyright © 2018 Samuli Tamminen. All rights reserved.
//

import UIKit

struct Constants {

    struct photo {
        static let width: CGFloat = 500
        static let height: CGFloat = 653

        static let topInset: CGFloat = 56
        static let bottomInset: CGFloat = 96

        /// Get total height (including insets) from face height
        static var totalHeightRatio: CGFloat {
            return height / (height - topInset - bottomInset)
        }

        /// Get width for height retaining the aspect ratio
        static var widthRatio: CGFloat {
            return width / height
        }
    }
}
