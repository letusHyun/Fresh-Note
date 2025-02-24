//
//  UIView+.swift
//  FreshNote
//
//  Created by SeokHyun on 11/20/24.
//

import Combine
import UIKit

struct GesturePublisher: Publisher {
  typealias Output = GestureType
  typealias Failure = Never
  
  private let view: UIView
  private let gestureType: GestureType
  
  init(view: UIView, gestureType: GestureType) {
    self.view = view
    self.gestureType = gestureType
  }
  
  func receive<S>(
    subscriber: S
  ) where S : Subscriber, GesturePublisher.Failure == S.Failure, GesturePublisher.Output == S.Input {
    let subscription = GestureSubscription(
      subscriber: subscriber,
      view: self.view,
      gestureType: self.gestureType
    )
    
    subscriber.receive(subscription: subscription)
  }
}

enum GestureType {
  case tap(UITapGestureRecognizer = .init())
  case swipe(UISwipeGestureRecognizer = .init())
  case longPress(UILongPressGestureRecognizer = .init())
  case pan(UIPanGestureRecognizer = .init())
  case pinch(UIPinchGestureRecognizer = .init())
  case edge(UIScreenEdgePanGestureRecognizer = .init())
  
  func get() -> UIGestureRecognizer {
    switch self {
    case let .tap(tapGesture):
      return tapGesture
    case let .swipe(swipeGesture):
      return swipeGesture
    case let .longPress(longPressGesture):
      return longPressGesture
    case let .pan(panGesture):
      return panGesture
    case let .pinch(pinchGesture):
      return pinchGesture
    case let .edge(edgePanGesture):
      return edgePanGesture
    }
  }
}

class GestureSubscription<S: Subscriber>: Subscription where S.Input == GestureType, S.Failure == Never {
  private var subscriber: S?
  private var gestureType: GestureType
  private var view: UIView
  
  
  init(subscriber: S, view: UIView, gestureType: GestureType) {
    self.subscriber = subscriber
    self.view = view
    self.gestureType = gestureType
    self.configureGesture(gestureType)
  }
  
  func request(_ demand: Subscribers.Demand) { }
  
  func cancel() {
    self.subscriber = nil
    self.view.removeGestureRecognizer(gestureType.get())
  }
  
  @objc private func handler() {
    _ = self.subscriber?.receive(gestureType)
  }
  
  private func configureGesture(_ gestureType: GestureType) {
    let gesture = gestureType.get()
    gesture.addTarget(self, action: #selector(handler))
    self.view.addGestureRecognizer(gesture)
  }
}

extension UIView {
  func gesture(_ gestureType: GestureType = .tap()) -> GesturePublisher {
    .init(view: self, gestureType: gestureType)
  }
}
