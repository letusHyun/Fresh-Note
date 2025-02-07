//
//  SettingCoordinator.swift
//  FreshNote
//
//  Created by SeokHyun on 1/17/25.
//

import Foundation
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
      showDateTime: { [weak self] in
        
      }, showDateTimeSetting: { [weak self] in
        self?.showDateTimeSetting()
      }, showAppGuide: { [weak self] in
        
      }, showInquire: { [weak self] in
        
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
      pop: { [weak self] in
        print("로그아웃 알람 화면 pop!")
        self?.popSignOutAlert()
      }
    )
    let alertViewController = self.dependencies.makeSignOutAlertViewController(actions: actions)
    alertViewController.modalPresentationStyle = .overFullScreen
    alertViewController.modalTransitionStyle = .crossDissolve
    self.navigationController?.present(alertViewController, animated: true)
  }
  
  private func popSignOutAlert() {
    if self.navigationController?.presentedViewController != nil {
      self.navigationController?.dismiss(animated: true)
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
