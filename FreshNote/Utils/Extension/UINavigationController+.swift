//
//  UINavigationController+.swift
//  FreshNote
//
//  Created by SeokHyun on 11/1/24.
//

import UIKit

extension UINavigationController {
  func setupBarAppearance() {
    let appearance = UINavigationBarAppearance()
    appearance.configureWithTransparentBackground()
    appearance.backgroundColor = UIColor(fnColor: .realBack)
    self.navigationBar.standardAppearance = appearance
    self.navigationBar.scrollEdgeAppearance = appearance
    self.navigationBar.scrollEdgeAppearance = appearance
  }
}
