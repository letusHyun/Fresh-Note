//
//  AccountDeletionCoordinator.swift
//  FreshNote
//
//  Created by SeokHyun on 1/23/25.
//

import UIKit

protocol AccountDeletionCoordinatorDependencies: AnyObject {
  func makeAccountDeletionViewController(
    actions: AccountDeletionViewModelActions
  ) -> AccountDeletionViewController
}

final class AccountDeletionCoordinator: BaseCoordinator {
  // MARK: - Properties
  private let dependencies: any AccountDeletionCoordinatorDependencies
  
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
    let actions = AccountDeletionViewModelActions(pop: { [weak self] in
      self?.pop()
    })
    let viewController = self.dependencies.makeAccountDeletionViewController(actions: actions)
    self.navigationController?.pushViewController(viewController, animated: true)
  }
  
  // MARK: - Private
  private func pop() {
    self.navigationController?.popViewController(animated: true)
    self.finish()
  }
}
