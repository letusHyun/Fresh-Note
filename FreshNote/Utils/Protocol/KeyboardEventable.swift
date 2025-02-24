//
//  KeyboardEventable.swift
//  FreshNote
//
//  Created by SeokHyun on 11/19/24.
//

import Combine
import UIKit

// 현재 응답받는 UI를 알아내기 위해서 사용됩니다.
extension UIResponder {
  private struct Static {
    static weak var responder: UIResponder?
  }
  
  static fileprivate var currentResponder: UIResponder? {
    Static.responder = nil
    UIApplication.shared.sendAction(#selector(UIResponder._trap), to: nil, from: nil, for: nil)
    return Static.responder
  }
  
  @objc private func _trap() {
    Static.responder = self
  }
}

/// textBox(textField, textView)의 위치를 감지하고 필요시 transformView의 y값을 이동시킵니다.
protocol KeyboardEventable: AnyObject {
  var subscriptions: Set<AnyCancellable> { get set }
  var transformView: UIView { get }
  
  func bindKeyboard()
}

extension KeyboardEventable where Self: UIViewController {
  /// viewDidLoad시점에 keyboard를 bind합니다.
  func bindKeyboard() {
    NotificationCenter.default
      .publisher(for: UIResponder.keyboardWillShowNotification)
      .compactMap { [weak self] notification in
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
              let currentTextInputView = UIResponder.currentResponder as? (UITextInputTraits & UIView)
        else { return nil }
        
        guard let convertedTextFieldFrame = self?.transformView.convert(
          currentTextInputView.frame,
          from: currentTextInputView.superview
        ) else {
          return nil
        }
        
        let keyboardTopY = keyboardFrame.cgRectValue.origin.y
        let textBoxBottomY = convertedTextFieldFrame.origin.y + convertedTextFieldFrame.size.height
        
        if textBoxBottomY > keyboardTopY {
          let newFrameY = -keyboardFrame.cgRectValue.size.height
          return newFrameY
        }
        
        return nil
      }
      .sink { [weak self] newFrameY in
        self?.transformView.frame.origin.y = newFrameY
      }
      .store(in: &self.subscriptions)
    
    NotificationCenter.default
      .publisher(for: UIResponder.keyboardWillHideNotification)
      .sink { [weak self] _ in
        self?.transformView.frame.origin.y = .zero
      }
      .store(in: &self.subscriptions)
  }
}
