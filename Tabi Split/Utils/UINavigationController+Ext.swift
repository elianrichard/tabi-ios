//
//  UINavigationController+Ext.swift
//  Tabi
//
//  Created by Dharmawan Ruslan on 07/10/24.
//

import Foundation
import SwiftUI

// TEMPORARILY DISABLED: THIS CAN CAUSE EDGE CASES ESPECIALLY AFTER LOGIN
// TODO: Disable this feature for specific view
//extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
//    override open func viewDidLoad() {
//        super.viewDidLoad()
//        interactivePopGestureRecognizer?.delegate = self
//    }
//
//    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
//        return viewControllers.count > 1
//    }
//}
