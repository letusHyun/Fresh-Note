//
//  DateTimeSettingCoordinator.swift
//  FreshNote
//
//  Created by SeokHyun on 10/27/24.
//

import UIKit

protocol DateTimeSettingCoordinatorDependencies: AnyObject {
  func makeDateTimeSettingViewController(
    actions: DateTimeSettingViewModelActions,
    mode: DateTimeSettingViewModelMode
  ) -> DateTimeSettingViewController
}

final class DateTimeSettingCoordinator: BaseCoordinator {
  private let dependencies: any DateTimeSettingCoordinatorDependencies
  
  // MARK: - LifeCycle
  init(
    dependencies: any DateTimeSettingCoordinatorDependencies,
    navigationController: UINavigationController?
  ) {
    self.dependencies = dependencies
    super.init(navigationController: navigationController)
  }
  
  deinit {
    print("DEBUG: \(Self.self) deinit")
  }
  
  // MARK: - Start
  func start(mode: DateTimeSettingViewModelMode) {
    let actions = DateTimeSettingViewModelActions(showHome: { [weak self] in
      self?.showHome()
    }, pop: { [weak self] in
      self?.pop()
    })
    let viewController = self.dependencies.makeDateTimeSettingViewController(actions: actions, mode: mode)
    self.navigationController?.pushViewController(viewController, animated: true)
  }
  
  // MARK: - Private
  private func showHome() {
    self.finish()
  }
  
  private func pop() {
    self.navigationController?.popViewController(animated: true)
    self.finish()
  }
}
