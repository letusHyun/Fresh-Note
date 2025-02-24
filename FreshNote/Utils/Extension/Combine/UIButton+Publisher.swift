//
//  UIButton+.swift
//  FreshNote
//
//  Created by SeokHyun on 1/2/25.
//

import Combine
import UIKit

public extension UIButton {
  var tapThrottlePublisher: AnyPublisher<Void, Never> {
    self.publisher(for: .touchUpInside)
      .throttle(for: .seconds(1), scheduler: DispatchQueue.main, latest: false)
      .map { _ in }
      .eraseToAnyPublisher()
  }
  
  var tapPublisher: AnyPublisher<Void, Never> {
    self.publisher(for: .touchUpInside)
      .receive(on: DispatchQueue.main)
      .map { _ in }
      .eraseToAnyPublisher()
  }
}
