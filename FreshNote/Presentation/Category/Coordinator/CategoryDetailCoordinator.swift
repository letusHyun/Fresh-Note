//
//  CategoryDetailCoordinator.swift
//  FreshNote
//
//  Created by SeokHyun on 1/7/25.
//

import UIKit

protocol CategoryDetailCoordinatorDependencies: AnyObject {
  func makeCategoryDetailViewController(actions: CategoryDetailViewModelActions) -> CategoryDetailViewController
  func makeProductCoordinator(
    navigationController: UINavigationController,
    productID: DocumentID
  ) -> ProductCoordinator
}

final class CategoryDetailCoordinator: BaseCoordinator {
  // MARK: - Properties
  private let dependencies: any CategoryDetailCoordinatorDependencies
  
  // MARK: - LifeCycle
  init(
    navigationController: UINavigationController,
    dependencies: any CategoryDetailCoordinatorDependencies
  ) {
    self.dependencies = dependencies
    
    super.init(navigationController: navigationController)
  }
  
  // MARK: - Start
  func start() {
    let actions = CategoryDetailViewModelActions(pop: { [weak self] in
      self?.pop()
    })
    
    let viewController = self.dependencies.makeCategoryDetailViewController(actions: actions)
    self.navigationController?.pushViewController(viewController, animated: true)
  }
  
  // MARK: - Private
  private func pop() {
    self.navigationController?.popViewController(animated: true)
    self.finish()
  }
}

// MARK: - CoordinatorFinishDelegate
extension CategoryDetailCoordinator: CoordinatorFinishDelegate {
  func coordinatorDidFinish(_ childCoordinator: BaseCoordinator) {
    childCoordinators.removeValue(forKey: childCoordinator.identifier)
  }
}
