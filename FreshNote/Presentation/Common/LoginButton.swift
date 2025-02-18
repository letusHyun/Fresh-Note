//
//  LoginButton.swift
//  FreshNote
//
//  Created by SeokHyun on 10/29/24.
//

import UIKit

final class LoginButton: UIButton {
  // MARK: - Properteis

  
  // MARK: - LifeCycle
  convenience init(title: String, imagePath: String, titleColor: UIColor, backgroundColor: UIColor) {
    self.init(frame: .zero)
    setupConfiguration(title: title, imagePath: imagePath, titleColor: titleColor, backgroundColor: backgroundColor)
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

// MARK: - Private Helpers
private extension LoginButton {
  func setupConfiguration(title: String, imagePath: String, titleColor: UIColor, backgroundColor: UIColor) {
    var titleContainer = AttributeContainer()
    titleContainer.font = UIFont.pretendard(size: 16, weight: ._600)
    
    var configuration = Configuration.filled()
    configuration.baseBackgroundColor = backgroundColor
    configuration.baseForegroundColor = titleColor
    configuration.attributedTitle = AttributedString(title, attributes: titleContainer)
    configuration.image = UIImage(named: imagePath)
    configuration.imagePlacement = .leading
    
    configuration.imagePadding = 100
    configuration.contentInsets = .init(top: 18.5, leading: 13, bottom: 18.5, trailing: 13)
    
    self.configuration = configuration
    layer.cornerRadius = 12
    clipsToBounds = true
  }
}
