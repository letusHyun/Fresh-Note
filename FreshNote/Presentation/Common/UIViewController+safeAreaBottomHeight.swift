//
//  UIViewController+safeAreaBottomHeight.swift
//  FreshNote
//
//  Created by SeokHyun on 11/23/24.
//

import UIKit

extension UIViewController {
  var safeAreaBottomHeight: CGFloat {
    if let window = self.view.window ?? UIApplication.shared.connectedScenes
      .compactMap({ $0 as? UIWindowScene })
      .flatMap({ $0.windows })
      .first(where: { $0.isKeyWindow }) {
      return window.safeAreaInsets.bottom
    }
    return 0
  }
}
