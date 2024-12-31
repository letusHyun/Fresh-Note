//
//  PinCoordinator.swift
//  FreshNote
//
//  Created by SeokHyun on 12/31/24.
//

import UIKit

protocol PinCoordinatorDependencies {
  func makePinViewController(actions: PinViewModelActions) -> PinViewController
  func makeProductCoordinator() -> ProductCoordinator
}

final class PinCoordinator: BaseCoordinator {
  // MARK: - Properties
  private let dependencies: any PinCoordinatorDependencies
  
  // MARK: - LifeCycle
  init(
    navigationController: UINavigationController?,
    dependencies: any PinCoordinatorDependencies
  ) {
    self.dependencies = dependencies
    self.navigationController = navigationController
  }
  
  func start() {
    let actions = PinViewModelActions(showProduct: { [weak self] in
      self?.showProduct()
    })
    
    let viewController = self.dependencies.makePinViewController(actions: actions)
    self.navigationController?.pushViewController(viewController, animated: true)
  }
  
  // MARK: - Private
  private func showProduct() {
    let childCoordinator = self.dependencies.makeProductCoordinator()
    childCoordinator.finishDelegate = self
    self.childCoordinators[childCoordinator.identifier] = childCoordinator
  }
}

// MARK: - CoordinatorFinishDelegate
extension PinCoordinator: CoordinatorFinishDelegate {
  func coordinatorDidFinish(_ childCoordinator: BaseCoordinator) {
    self.childCoordinators.removeValue(forKey: childCoordinator.identifier)
  }
}
