//
//  UIControl+.swift
//  FreshNote
//
//  Created by SeokHyun on 11/14/24.
//

import Combine
import UIKit

import UIKit
import Combine

// MARK: - CombineInteraction
extension UIControl {
  
  // MARK: - InteractionSubscription
  class InteractionSubscription<S: Subscriber>: Subscription
  where S.Input == UIControl {
    private var subscriber: S?
    private let control: UIControl
    private let event: UIControl.Event
    
    init(
      subscriber: S,
      control: UIControl,
      event: UIControl.Event
    ) {
      self.subscriber = subscriber
      self.control = control
      self.event = event
      
      self.control.addTarget(self, action: #selector(self.handleEvent), for: event)
    }
    
    @objc func handleEvent(_ sender: UIControl) {
      _=self.subscriber?.receive(self.control)
    }
    
    // MARK: - Subscription
    func request(_ demand: Subscribers.Demand) {}
    
    func cancel() {
      self.subscriber = nil
      self.control.removeTarget(self, action: #selector(self.handleEvent), for: self.event)
    }
  }
  
  // MARK: - InteractionPublihser
  struct InteractionPublihser: Publisher {
    typealias Output = UIControl
    typealias Failure = Never
    
    private let control: UIControl
    private let event: UIControl.Event
    
    init(control: UIControl, event: UIControl.Event) {
      self.control = control
      self.event = event
    }
    
    // MARK: - Publihser
    func receive<S>(subscriber: S) where S: Subscriber, Never == S.Failure, UIControl == S.Input {
      let subscription = InteractionSubscription(
        subscriber: subscriber,
        control: self.control,
        event: self.event)
      
      subscriber.receive(subscription: subscription)
    }
  }
  
  /// A publisher emitting events.
  func publisher(
    for event: UIControl.Event
  ) -> UIControl.InteractionPublihser {
    return InteractionPublihser(control: self, event: event)
  }
}
