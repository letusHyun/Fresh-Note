//
//  SettingCoordinator.swift
//  FreshNote
//
//  Created by SeokHyun on 1/17/25.
//

import Foundation
import UIKit

protocol SettingCoordinatorDependencies {
  func makeSettingViewController(actions: SettingViewModelActions) -> SettingViewController
  
  func makeDateTimeSettingCoordinator(
    navigationController: UINavigationController?
  ) -> DateTimeSettingCoordinator
  
  // TODO: - 다른 화면에 대한 makeCoordinators..
}

final class SettingCoordinator: BaseCoordinator {
  // MARK: - Properties
  private let dependencies: any SettingCoordinatorDependencies
  
  // MARK: - LifeCycle
  init(
    navigationController: UINavigationController?,
    dependencies: any SettingCoordinatorDependencies
  ) {
    self.dependencies = dependencies
    
    super.init(navigationController: navigationController)
  }
  
  func start() {
    let actions = SettingViewModelActions(
      showDateTime: { [weak self] in
        
      },
      showDateTimeSetting: { [weak self] in
        self?.showDateTimeSetting()
      },
      showAppGuide: { [weak self] in
        
      },
      showInquire: { [weak self] in
        
      }
    )
    
    let viewController = self.dependencies.makeSettingViewController(actions: actions)
    self.navigationController?.viewControllers = [viewController]
  }
  
  // MARK: - Private
  private func showDateTimeSetting() {
    let childCoordinator = self.dependencies.makeDateTimeSettingCoordinator(
      navigationController: self.navigationController
    )
    childCoordinator.finishDelegate = self
    self.childCoordinators[childCoordinator.identifier] = childCoordinator
    childCoordinator.start(mode: .edit)
  }
}

// MARK: - CoordinatorFinishDelegate
extension SettingCoordinator: CoordinatorFinishDelegate {
  func coordinatorDidFinish(_ childCoordinator: BaseCoordinator) {
    self.childCoordinators.removeValue(forKey: childCoordinator.identifier)
  }
}
