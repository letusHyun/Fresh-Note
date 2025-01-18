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
  
  func makeProductCoordinator(
    navigationController: UINavigationController?,
    productID: DocumentID
  ) -> ProductCoordinator
}

class CalendarCoordinator: BaseCoordinator {
  // MARK: - Properties
  private let dependencies: any CalendarCoordinatorDependencies
  
  // MARK: - LifeCycle
  init(navigationController: UINavigationController?, dependencies: any CalendarCoordinatorDependencies) {
    self.dependencies = dependencies
    super.init(navigationController: navigationController)
  }
  
  deinit {
    print("DEBUG: \(Self.self) deinit")
  }
  
  func start() {
    let actions = CalendarViewModelActions(
      showProduct: { [weak self] productID in
        self?.showProduct(at: productID)
      }
    )
    
    let viewController = self.dependencies.makeCalendarViewController(actions: actions)
    self.navigationController?.viewControllers = [viewController]
  }
  
  // MARK: - Privates
  private func showProduct(at productID: DocumentID) {
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
extension CalendarCoordinator: CoordinatorFinishDelegate {
  func coordinatorDidFinish(_ childCoordinator: BaseCoordinator) {
    self.childCoordinators.removeValue(forKey: childCoordinator.identifier)
  }
}
