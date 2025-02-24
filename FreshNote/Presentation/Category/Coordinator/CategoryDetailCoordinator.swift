//
//  CategoryDetailCoordinator.swift
//  FreshNote
//
//  Created by SeokHyun on 1/7/25.
//

import UIKit

protocol CategoryDetailCoordinatorDependencies: AnyObject {
  func makeCategoryDetailViewController(
    actions: CategoryDetailViewModelActions,
    category: ProductCategory
  ) -> CategoryDetailViewController
  
  func makeProductCoordinator(
    navigationController: UINavigationController?,
    productID: DocumentID
  ) -> ProductCoordinator
}

final class CategoryDetailCoordinator: BaseCoordinator {
  // MARK: - Properties
  private let dependencies: any CategoryDetailCoordinatorDependencies
  private let category: ProductCategory
  
  // MARK: - LifeCycle
  init(
    navigationController: UINavigationController?,
    category: ProductCategory,
    dependencies: any CategoryDetailCoordinatorDependencies
  ) {
    self.category = category
    self.dependencies = dependencies
    
    super.init(navigationController: navigationController)
  }
  
  // MARK: - Start
  func start() {
    let actions = CategoryDetailViewModelActions(pop: { [weak self] in
      self?.pop()
    }, showProduct: { [weak self] productID in
      self?.showProduct(productID: productID)
    })
    
    let viewController = self.dependencies.makeCategoryDetailViewController(
      actions: actions,
      category: self.category
    )
    self.navigationController?.pushViewController(viewController, animated: true)
  }
  
  // MARK: - Private
  private func pop() {
    self.navigationController?.popViewController(animated: true)
    self.finish()
  }
  
  private func showProduct(productID: DocumentID) {
    let childCoordinator = self.dependencies.makeProductCoordinator(
      navigationController: self.navigationController,
      productID: productID
    )
    childCoordinator.finishDelegate = self
    self.childCoordinators[childCoordinator.identifier] = childCoordinator
    childCoordinator.start()
  }
}

// MARK: - CoordinatorFinishDelegate
extension CategoryDetailCoordinator: CoordinatorFinishDelegate {
  func coordinatorDidFinish(_ childCoordinator: BaseCoordinator) {
    self.childCoordinators.removeValue(forKey: childCoordinator.identifier)
  }
}
