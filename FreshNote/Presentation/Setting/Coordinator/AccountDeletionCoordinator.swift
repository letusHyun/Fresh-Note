//
//  AccountDeletionCoordinator.swift
//  FreshNote
//
//  Created by SeokHyun on 1/23/25.
//

import UIKit

/// 계정 탈퇴 시 finish를 호출하는 델리게이트입니다.
protocol AccountDeletionCoordinatorFinishDelegate: AnyObject {
  func accountDeletionCoordinatorDidFinish(_ childCoordinator: AccountDeletionCoordinator)
}

protocol AccountDeletionCoordinatorDependencies: AnyObject {
  func makeAccountDeletionViewController(
    actions: AccountDeletionViewModelActions
  ) -> AccountDeletionViewController
}

final class AccountDeletionCoordinator: BaseCoordinator {
  // MARK: - Properties
  private let dependencies: any AccountDeletionCoordinatorDependencies
  weak var accountDeletionFinishDelegate: (any AccountDeletionCoordinatorFinishDelegate)?
  
  // MARK: - LifeCycle
  init(
    navigationController: UINavigationController?,
    dependencies: any AccountDeletionCoordinatorDependencies
  ) {
    self.dependencies = dependencies
    super.init(navigationController: navigationController)
  }
  
  // MARK: - Start
  func start() {
    let actions = AccountDeletionViewModelActions(deletionPop: { [weak self] in
      self?.deletionPop()
    })
    let viewController = self.dependencies.makeAccountDeletionViewController(actions: actions)
    self.navigationController?.pushViewController(viewController, animated: true)
  }
  
  // MARK: - Private
  private func deletionPop() {
    self.navigationController?.popViewController(animated: true)
    self.finish()
  }
  
  // MARK: - Finish
  override func finish() {
    self.accountDeletionFinishDelegate?.accountDeletionCoordinatorDidFinish(self)
  }
}
