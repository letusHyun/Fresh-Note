//
//  CategoryCoordinator.swift
//  FreshNote
//
//  Created by SeokHyun on 1/7/25.
//

import UIKit

protocol CategoryCoordinatorDependencies: AnyObject {
  func makeCategoryViewController(actions: CategoryViewModelActions) -> CategoryViewController
  func makeCategoryDetailCoordinator(
    navigationController: UINavigationController?,
    category: ProductCategory
  ) -> CategoryDetailCoordinator
}

final class CategoryCoordinator: BaseCoordinator {
  // MARK: - Properties
  private let dependencies: any CategoryCoordinatorDependencies
  
  // MARK: - LifeCycle
  init(navigationController: UINavigationController?, dependencies: CategoryCoordinatorDependencies) {
    self.dependencies = dependencies
    
    super.init(navigationController: navigationController)
  }
  
  // MARK: - Start
  func start() {
    let actions = CategoryViewModelActions(
      showCategoryDetail: { [weak self] category in
        self?.showCategoryDetail(category: category)
      }
    )
    
    let viewController = self.dependencies.makeCategoryViewController(actions: actions)
    self.navigationController?.viewControllers = [viewController]
  }
  
  // MARK: - Private
  private func showCategoryDetail(category: ProductCategory) {
    let childCoordinator = self.dependencies.makeCategoryDetailCoordinator(
      navigationController: self.navigationController,
      category: category
    )
    childCoordinator.finishDelegate = self
    self.childCoordinators[childCoordinator.identifier] = childCoordinator
    childCoordinator.start()
  }
}

// MARK: - CoordinatorFinishDelegate
extension CategoryCoordinator: CoordinatorFinishDelegate {
  func coordinatorDidFinish(_ childCoordinator: BaseCoordinator) {
    self.childCoordinators.removeValue(forKey: childCoordinator.identifier)
  }
}
