//
//  SearchCoordinator.swift
//  FreshNote
//
//  Created by SeokHyun on 11/1/24.
//

import Combine
import UIKit

protocol SearchCoordinatorDependencies: AnyObject {
  func makeSearchViewController(actions: SearchViewModelActions) -> SearchViewController
  func makeProductCoordinator(
    navigationController: UINavigationController?,
    productID: DocumentID
  ) -> ProductCoordinator
}

final class SearchCoordinator: BaseCoordinator {
  // MARK: - Properties
  private let dependencies: any SearchCoordinatorDependencies
  private let updateProductSubject: PassthroughSubject<Product?, Never> = .init()
  
  // MARK: - LifeCycle
  init(
    dependencies: any SearchCoordinatorDependencies,
    navigationController: UINavigationController?
  ) {
    self.dependencies = dependencies
    super.init(navigationController: navigationController)
  }
  
  deinit {
    print("DEBUG: \(Self.self) deinit")
  }
  
  // MARK: - Start
  func start() {
    let actions = SearchViewModelActions(pop: { [weak self] in
      self?.pop()
    }, showProduct: { [weak self] productID in
      self?.showProduct(productID: productID)
    }, updateProductPublisher: self.updateProductSubject.eraseToAnyPublisher())
    
    let viewController = self.dependencies.makeSearchViewController(actions: actions)
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
    
    childCoordinator.popCompletion = { [weak self] product in
      self?.updateProductSubject.send(product)
    }
  }
}

// MARK: - CoordinatorFinishDelegate
extension SearchCoordinator: CoordinatorFinishDelegate {
  func coordinatorDidFinish(_ childCoordinator: BaseCoordinator) {
    self.childCoordinators.removeValue(forKey: childCoordinator.identifier)
  }
}
