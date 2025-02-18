//
//  NavigationBackButton.swift
//  FreshNote
//
//  Created by SeokHyun on 11/14/24.
//

import UIKit

final class NavigationBackButton: UIButton {
  // MARK: - LifeCycle
  convenience init() {
    self.init(frame: .zero)
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

extension NavigationBackButton {
  private func setupUI() {
    let image = UIImage(systemName: "chevron.backward")?
      .resized(to: CGSize(width: 16, height: 24))?
      .withRenderingMode(.alwaysTemplate)
    
    self.setImage(image, for: .normal)
    self.tintColor = UIColor(fnColor: .gray3)
  }
}
