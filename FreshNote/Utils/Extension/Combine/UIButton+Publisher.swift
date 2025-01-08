//
//  UIButton+.swift
//  FreshNote
//
//  Created by SeokHyun on 1/2/25.
//

import Combine
import UIKit

public extension UIButton {
  var tapPublisher: AnyPublisher<Void, Never> {
    self.publisher(for: .touchUpInside)
      .receive(on: DispatchQueue.main)
      .map { _ in }
      .eraseToAnyPublisher()
  }
}
