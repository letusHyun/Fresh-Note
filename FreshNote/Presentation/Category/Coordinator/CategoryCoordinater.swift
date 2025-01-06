//
//  CategoryCoordinater.swift
//  FreshNote
//
//  Created by SeokHyun on 1/7/25.
//

import UIKit

protocol CategoryCoordinaterDependencies: AnyObject {
  func makeCategoryViewController(actions: CategoryViewModelActions) -> CategoryViewController
//  func makeCategoryDetailCoordinator() -> CategoryDetailCoordinater
}

final class CategoryCoordinater: BaseCoordinator {
  // MARK: - Properties
  private let dependencies: any CategoryCoordinaterDependencies
  
  // MARK: - LifeCycle
  init(navigationController: UINavigationController?, dependencies: CategoryCoordinaterDependencies) {
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
    self.navigationController?.pushViewController(viewController, animated: true)
  }
  
  // MARK: - Private
  private func showCategoryDetail(category: ProductCategory) {
//    let coordinator = self.dependencies.
  }
}

// MARK: - CoordinatorFinishDelegate
extension CategoryCoordinater: CoordinatorFinishDelegate {
  func coordinatorDidFinish(_ childCoordinator: BaseCoordinator) {
    childCoordinator.childCoordinators.removeValue(forKey: childCoordinator.identifier)
  }
}
