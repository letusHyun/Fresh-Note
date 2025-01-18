//
//  HomeCoordinator.swift
//  FreshNote
//
//  Created by SeokHyun on 10/28/24.
//

import Combine
import UIKit

protocol HomeCoordinatorDependencies: AnyObject {
  func makeHomeViewController(actions: HomeViewModelActions) -> HomeViewController
  func makeSearchCoordinator(navigationController: UINavigationController?) -> SearchCoordinator
  func makeNotificationCoordinator(navigationController: UINavigationController?) -> NotificationCoordinator
  func makeProductCoordinator(
    navigationController: UINavigationController?,
    mode: ProductViewModelMode
  ) -> ProductCoordinator
}

final class HomeCoordinator: BaseCoordinator {
  // MARK: - Properties
  private let dependencies: any HomeCoordinatorDependencies
  
//  private let productSubject = PassthroughSubject<Product?, Never>()
  
  // MARK: - LifeCycle
  init(navigationController: UINavigationController?, dependencies: any HomeCoordinatorDependencies) {
    self.dependencies = dependencies
    super.init(navigationController: navigationController)
  }
}

// MARK: - Start
extension HomeCoordinator {
  func start() {
    let actions = HomeViewModelActions(
      showNotificationPage: { [weak self] in
        self?.showNotificationPage()
      }, showSearchPage: { [weak self] in
        self?.showSearchPage()
      }, showProductPage: { [weak self] product in
        let mode: ProductViewModelMode = product.map { .edit($0) } ?? .create
        self?.showProductPage(mode: mode)
      }
    )
    
    let homeViewController = self.dependencies.makeHomeViewController(actions: actions)
    self.navigationController?.viewControllers = [homeViewController]
  }
}

// MARK: - Private Helpers
extension HomeCoordinator {
  private func showNotificationPage() {
    let childCoordinator = self.dependencies.makeNotificationCoordinator(
      navigationController: self.navigationController
    )
    childCoordinator.finishDelegate = self
    self.childCoordinators[childCoordinator.identifier] = childCoordinator
    childCoordinator.start()
  }
  
  private func showSearchPage() {
    let childCoordinator = self.dependencies.makeSearchCoordinator(
      navigationController: self.navigationController
    )
    childCoordinator.finishDelegate = self
    self.childCoordinators[childCoordinator.identifier] = childCoordinator
    childCoordinator.start()
  }
  
  private func showProductPage(mode: ProductViewModelMode) {
    let childCoordinator = self.dependencies.makeProductCoordinator(
      navigationController: self.navigationController,
      mode: mode
    )
    
    childCoordinator.finishDelegate = self
    self.childCoordinators[childCoordinator.identifier] = childCoordinator
    childCoordinator.start()
  }
}

// MARK: - CoordinatorFinishDelegate
extension HomeCoordinator: CoordinatorFinishDelegate {
  func coordinatorDidFinish(_ childCoordinator: BaseCoordinator) {
    self.childCoordinators.removeValue(forKey: childCoordinator.identifier)
  }
}
