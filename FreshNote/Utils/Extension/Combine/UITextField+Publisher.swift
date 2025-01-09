//
//  UITextField+.swift
//  FreshNote
//
//  Created by SeokHyun on 1/2/25.
//

import Combine
import UIKit

extension UITextField {
  var textPublisher: AnyPublisher<String, Never> {
    self.publisher(for: .editingChanged)
      .receive(on: DispatchQueue.main)
      .compactMap { $0 as? UITextField }
      .compactMap { $0.text }
      .eraseToAnyPublisher()
  }
  
  var textDebouncePublisher: AnyPublisher<String, Never> {
    self.textPublisher
      .debounce(for: 0.1, scheduler: DispatchQueue.main)
      .removeDuplicates()
      .eraseToAnyPublisher()
  }
}
