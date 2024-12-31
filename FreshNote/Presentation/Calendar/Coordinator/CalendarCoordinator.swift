//
//  CalendarCoordinator.swift
//  FreshNote
//
//  Created by SeokHyun on 10/28/24.
//

import Combine
import UIKit

protocol CalendarCoordinatorDependencies: AnyObject {
  func makeCalendarViewController(actions: CalendarViewModelActions) -> CalendarViewController
  func makeProductCoordinator(navigationController: UINavigationController?, product: Product) -> ProductCoordinator
}

class CalendarCoordinator: BaseCoordinator {
  // MARK: - Properties
  private let dependencies: any CalendarCoordinatorDependencies
  
//  private let productSubject = PassthroughSubject<Product?, Never>()
  
  // MARK: - LifeCycle
  init(navigationController: UINavigationController?, dependencies: any CalendarCoordinatorDependencies) {
    self.dependencies = dependencies
    super.init(navigationController: navigationController)
  }
  
  
  func start() {
    let actions = CalendarViewModelActions(
      showProduct: { [weak self] product in
        self?.showProduct(at: product)
      }
    )
    
    let viewController = self.dependencies.makeCalendarViewController(actions: actions)
    self.navigationController?.pushViewController(viewController, animated: true)
  }
  
  // MARK: - Privates
  private func showProduct(at product: Product) {
    let childCoordinator = self.dependencies.makeProductCoordinator(
      navigationController: self.navigationController,
      product: product
    )
    childCoordinator.finishDelegate = self
    self.childCoordinators[childCoordinator.identifier] = childCoordinator
    childCoordinator.start()
  }
}

extension CalendarCoordinator: CoordinatorFinishDelegate {
  func coordinatorDidFinish(_ childCoordinator: BaseCoordinator) {
    childCoordinator.childCoordinators.removeValue(forKey: childCoordinator.identifier)
  }
}
