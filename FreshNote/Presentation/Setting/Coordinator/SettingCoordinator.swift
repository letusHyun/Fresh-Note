//
//  SettingCoordinator.swift
//  FreshNote
//
//  Created by SeokHyun on 1/17/25.
//

import Foundation
import MessageUI
import UIKit

protocol SettingCoordinatorDependencies {
  func makeSettingViewController(actions: SettingViewModelActions) -> SettingViewController
  
  func makeDateTimeSettingCoordinator(
    navigationController: UINavigationController?
  ) -> DateTimeSettingCoordinator
  
  func makeSignOutAlertViewController(actions: SignOutAlertViewModelActions) -> SignOutAlertViewController
  
  func makeAccountDeletionCoordinator(
    navigationController: UINavigationController?
  ) -> AccountDeletionCoordinator
  
  // TODO: - 다른 화면에 대한 makeCoordinators..
}

final class SettingCoordinator: BaseCoordinator {
  // MARK: - Properties
  private let dependencies: any SettingCoordinatorDependencies
  
  // MARK: - LifeCycle
  init(
    navigationController: UINavigationController?,
    dependencies: any SettingCoordinatorDependencies
  ) {
    self.dependencies = dependencies
    
    super.init(navigationController: navigationController)
  }
  
  func start() {
    let actions = SettingViewModelActions(
      showDateTimeSetting: { [weak self] in
        self?.showDateTimeSetting()
      }, presentAppVersion: { [weak self] in
        self?.presentAppVersion()
      }, presentInquire: { [weak self] in
        self?.presentMailCompose()
      }, presentSignOutAlert: { [weak self] in
        self?.presentSignOutAlert()
      }, showAccountDeletion: { [weak self] in
        self?.showAccountDeletion()
      }
    )
    
    let viewController = self.dependencies.makeSettingViewController(actions: actions)
    self.navigationController?.viewControllers = [viewController]
  }
  
  // MARK: - Private
  private func presentAppVersion() {
    AlertBuilder(presentingViewController: self.navigationController?.topViewController)
      .setTitle("앱 버전 정보")
      .setMessage("ver. \(self.getCurrentVersion())")
      .addActionConfirm("확인", action: { [weak self] in
        self?.navigationController?.presentedViewController?.dismiss(animated: true)
      })
      .present()
  }
  
  private func presentMailCompose() {
    guard MFMailComposeViewController.canSendMail() else {
      self.presentSendMailErrorAlert()
      return
    }
    
    let composeViewController = MFMailComposeViewController()
    composeViewController.mailComposeDelegate = self
    let bodyString = """
    여기에 문의할 내용을 작성해 주세요.
    
    
    
    
    ================================
    Device OS : \(UIDevice.current.systemVersion)
    App Version : \(self.getCurrentVersion())
    ================================
    """
    
    composeViewController.setToRecipients(["letushyun@gmail.com"])
    composeViewController.setSubject("<Fresh Note> 문의")
    composeViewController.setMessageBody(bodyString, isHTML: false)
    self.navigationController?.topViewController?.present(composeViewController, animated: true)
    
  }
  
  // 현재 버전 가져오기
  private func getCurrentVersion() -> String {
    guard let dictionary = Bundle.main.infoDictionary,
          let version = dictionary["CFBundleShortVersionString"] as? String else { return "" }
    return version
  }
  
  private func presentSendMailErrorAlert() {
    let alertController = UIAlertController(
      title: "메일 계정 활성화 필요",
      message: "Mail 앱에서 사용자의 Email 계정을 설정해 주세요.",
      preferredStyle: .alert
    )
    
    let alertAction = UIAlertAction(title: "확인", style: .default)
    
    alertController.addAction(alertAction)
    self.navigationController?.topViewController?.present(alertController, animated: true)
  }
  
  private func showDateTimeSetting() {
    let childCoordinator = self.dependencies.makeDateTimeSettingCoordinator(
      navigationController: self.navigationController
    )
    childCoordinator.finishDelegate = self
    self.childCoordinators[childCoordinator.identifier] = childCoordinator
    childCoordinator.start(mode: .edit)
  }
  
  private func presentSignOutAlert() {
    let actions = SignOutAlertViewModelActions(
      dismissSignOutAlert: { [weak self] in
        self?.dismissSignOutAlert()
      }, dismiss: {[weak self] in
        self?.dismiss()
      }
    )
    let alertViewController = self.dependencies.makeSignOutAlertViewController(actions: actions)
    alertViewController.modalPresentationStyle = .overFullScreen
    alertViewController.modalTransitionStyle = .crossDissolve
    self.navigationController?.present(alertViewController, animated: true)
  }
  
  private func dismissSignOutAlert() {
    if self.navigationController?.presentedViewController != nil {
      self.navigationController?.dismiss(animated: true)
      self.finish()
    }
  }
  
  private func showAccountDeletion() {
    let childCoordinator = self.dependencies.makeAccountDeletionCoordinator(
      navigationController: self.navigationController
    )
    childCoordinator.accountDeletionFinishDelegate = self
    self.childCoordinators[childCoordinator.identifier] = childCoordinator
    childCoordinator.start()
  }
  
  private func dismiss() {
    if self.navigationController?.presentedViewController != nil {
      self.navigationController?.dismiss(animated: true)
    }
  }
}

// MARK: - CoordinatorFinishDelegate
extension SettingCoordinator: CoordinatorFinishDelegate {
  func coordinatorDidFinish(_ childCoordinator: BaseCoordinator) {
    self.childCoordinators.removeValue(forKey: childCoordinator.identifier)
  }
}

// MARK: - AccountDeletionCoordinatorFinishDelegate
extension SettingCoordinator: AccountDeletionCoordinatorFinishDelegate {
  func accountDeletionCoordinatorDidFinish(_ childCoordinator: AccountDeletionCoordinator) {
    self.childCoordinators.removeValue(forKey: childCoordinator.identifier)
    self.finish()
  }
}

// MARK: - MFMailComposeViewControllerDelegate
extension SettingCoordinator: MFMailComposeViewControllerDelegate {
  func mailComposeController(
    _ controller: MFMailComposeViewController,
    didFinishWith result: MFMailComposeResult,
    error: (any Error)?
  ) {
    switch result {
    case .sent:
      print("메일 보내기 성공")
    case .cancelled:
      print("메일 보내기 취소")
    case .saved:
      print("메일 임시 저장")
    case .failed:
      print("메일 발송 실패")
    @unknown default: break
    }
    
    controller.dismiss(animated: true)
  }
}
