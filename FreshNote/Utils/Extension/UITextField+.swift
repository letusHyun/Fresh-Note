//
//  UITextField+.swift
//  FreshNote
//
//  Created by SeokHyun on 11/5/24.
//

import Combine
import UIKit

extension UITextField {
  /// textField의 placeholder Color를 변경해줍니다.
  func setPlaceholderColor(_ placeholderColor: UIColor) {
    attributedPlaceholder = NSAttributedString(
      string: placeholder ?? "",
      attributes: [
        .foregroundColor: placeholderColor,
        .font: font
      ].compactMapValues { $0 }
    )
  }
  
//  var textDidChangedPublisher: AnyPublisher<String, Never> {
//    NotificationCenter.default.publisher(for: UITextField.textDidChangeNotification, object: self)
//      .compactMap { ($0.object as? UITextField)?.text }
//      .receive(on: DispatchQueue.main)
//      .eraseToAnyPublisher()
//  }
}
