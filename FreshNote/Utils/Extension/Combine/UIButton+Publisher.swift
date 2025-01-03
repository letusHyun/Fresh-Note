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
    publisher(for: .touchUpInside)
      .map { _ in }
      .eraseToAnyPublisher()
  }
}
