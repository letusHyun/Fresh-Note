//
//  UIGestureRecognizer+.swift
//  FreshNote
//
//  Created by SeokHyun on 11/20/24.
//

import Combine
import UIKit

extension UIGestureRecognizer {
  class InteractionSubscription<S: Subscriber>: Subscription where S.Input == UIGestureRecognizer {
    func request(_ demand: Subscribers.Demand) {}
    func cancel() { }

    private let subscriber: S?
    private let view: UIView
    private let gestureRecognizer: UIGestureRecognizer

    init(subscriber: S, view: UIView, gestureRecognizer: UIGestureRecognizer) {
      self.subscriber = subscriber
      self.view = view
      self.gestureRecognizer = gestureRecognizer

      self.gestureRecognizer.addTarget(self, action: #selector(handleEvent))
      view.addGestureRecognizer(self.gestureRecognizer)
    }

    @objc func handleEvent(_ gestureRecognizer: UIGestureRecognizer) {
      _ = subscriber?.receive(gestureRecognizer)
    }
  }

  struct InteractionPublisher: Publisher {
    typealias Output = UIGestureRecognizer
    typealias Failure = Never

    let gestureRecognizer: UIGestureRecognizer
    let view: UIView

    func receive<S>(subscriber: S) where S : Subscriber, Never == S.Failure, UIGestureRecognizer == S.Input {
      let subscription = InteractionSubscription(
        subscriber: subscriber,
        view: self.view,
        gestureRecognizer: self.gestureRecognizer
      )
      subscriber.receive(subscription: subscription)
    }
  }
}
