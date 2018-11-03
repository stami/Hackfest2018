//
//  Sequence+Arithmetic.swift
//  Hackfest2018
//
//  Created by Samuli Tamminen on 3.11.2018.
//  Copyright © 2018 Samuli Tamminen. All rights reserved.
//

import Foundation

extension Sequence where Self.Iterator.Element: Numeric {
    func sum() -> Self.Iterator.Element {
        return reduce(0, +)
    }
}

extension Collection where Element: BinaryFloatingPoint {
    func average() -> Element {
        return sum() / Element(count)
    }
}
