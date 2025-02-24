//
//  AlertBuilder.swift
//  FreshNote
//
//  Created by SeokHyun on 2/16/25.
//

import UIKit

/// 알림 뷰를 정의하는 빌더입니다.
class AlertBuilder {
  // MARK: - Properties
  private weak var presentingViewController: UIViewController?
  private let alertViewController: FNAlertViewController
  
  // MARK: - LifeCycle
  init(presentingViewController: UIViewController?) {
    self.presentingViewController = presentingViewController
    self.alertViewController = FNAlertViewController()
  }
  
  deinit {
    print("DEBUG: \(Self.self) deinit")
  }
  
  // MARK: - Helpers
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

// MARK: - Error Present
extension AlertBuilder {
  @discardableResult
  static func presentNetworkErrorAlert(
    presentingViewController: UIViewController?
  ) -> AlertBuilder {
    AlertBuilder(presentingViewController: presentingViewController)
      .setTitle("네트워크 오류")
      .setMessage("Wifi나 3G/LTE/5G를 연결 후 재시도해주세요🙏")
      .addActionConfirm("확인")
      .present()
  }
  
  @discardableResult
  static func presentDefaultError(
    presentingViewController: UIViewController?,
    message: String
  ) -> AlertBuilder {
    AlertBuilder(presentingViewController: presentingViewController)
      .setTitle("오류 😨")
      .setMessage(message)
      .addActionConfirm("확인")
      .present()
  }
}
