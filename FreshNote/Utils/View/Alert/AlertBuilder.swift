//
//  AlertBuilder.swift
//  FreshNote
//
//  Created by SeokHyun on 2/16/25.
//

import UIKit

class AlertBuilder {
  private weak var presentingViewController: UIViewController?
  private let alertViewController: FNAlertViewController
  
  init(presentingViewController: UIViewController?) {
    self.presentingViewController = presentingViewController
    self.alertViewController = FNAlertViewController()
  }
  
  func setTitle(_ text: String) -> AlertBuilder {
    self.alertViewController.setTitle(text)
    return self
  }
  
  func setMessage(_ text: String) -> AlertBuilder {
    self.alertViewController.setMessage(text)
    return self
  }
  
  func addActionConfirm(_ text: String, action: (() -> Void)? = nil) -> AlertBuilder {
    let alertAction = FNAlertAction(text: text, action: action)
    self.alertViewController.setActionConfirm(alertAction)
    return self
  }
  
  @discardableResult
  func present() -> Self {
    self.alertViewController.modalPresentationStyle = .overFullScreen
    self.alertViewController.modalTransitionStyle = .crossDissolve
    
    self.presentingViewController?.present(self.alertViewController, animated: true)
    return self
  }
}
