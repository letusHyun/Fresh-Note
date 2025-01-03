//
//  UITextField+.swift
//  FreshNote
//
//  Created by SeokHyun on 1/2/25.
//

import Combine
import UIKit

extension UITextField {
  var textPublisher: AnyPublisher<String?, Never> {
    self.publisher(for: .editingChanged)
      .compactMap { $0 as? UITextField }
      .map { $0.text }
      .eraseToAnyPublisher()
  }
  
  var textDebouncePublisher: AnyPublisher<String?, Never> {
    self.textPublisher.debounce(for: 0.1, scheduler: RunLoop.main)
      .eraseToAnyPublisher()
  }
  
  var didEndEditingPublisher: AnyPublisher<Void, Never> {
    self.publisher(for: .editingDidEnd)
      .map { _ in }
      .eraseToAnyPublisher()
  }
}
