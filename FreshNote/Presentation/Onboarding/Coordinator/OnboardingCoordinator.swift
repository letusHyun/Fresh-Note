//
//  OnboardingCoordinator.swift
//  FreshNote
//
//  Created by SeokHyun on 10/27/24.
//

import UIKit

protocol OnboardingCoordinatorDependencies {
  func makeOnboardingViewController(actions: OnboardingViewModelActions) -> OnboardingViewController
  func makeDateTimeSettingCoordinator(navigationController: UINavigationController?) -> DateTimeSettingCoordinator
}

final class OnboardingCoordinator: BaseCoordinator {
  // MARK: - Properties
  private let dependencies: any OnboardingCoordinatorDependencies
  
  // MARK: - LifeCycle
  init(dependencies: any OnboardingCoordinatorDependencies, navigationController: UINavigationController?) {
    self.dependencies = dependencies
    super.init(navigationController: navigationController)
  }
  
  deinit {
    print("DEBUG: \(Self.self) deinit")
  }
  
  // MARK: - Start
  func start() {
    let actions = OnboardingViewModelActions(showDateTimeSetting: { [weak self] in
      self?.showDateTimeSetting()
    }, showMain: { [weak self] in
      self?.showMain()
    })
    
    let viewController = dependencies.makeOnboardingViewController(actions: actions)
    navigationController?.viewControllers = [viewController]
  }
}

// MARK: - CoordinatorFinishDelegate
extension OnboardingCoordinator: CoordinatorFinishDelegate {
  func coordinatorDidFinish(_ childCoordinator: BaseCoordinator) {
    self.childCoordinators.removeValue(forKey: childCoordinator.identifier)
    self.finish()
  }
}

// MARK: - Privates
extension OnboardingCoordinator {
  private func showMain() {
    self.finish()
  }
  
  private func showDateTimeSetting() {
    let childCoordinator = dependencies.makeDateTimeSettingCoordinator(navigationController: navigationController)
    childCoordinator.finishDelegate = self
    childCoordinators[childCoordinator.identifier] = childCoordinator
    childCoordinator.start()
  }
}
