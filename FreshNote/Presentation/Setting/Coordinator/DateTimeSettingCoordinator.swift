//
//  DateTimeSettingCoordinator.swift
//  FreshNote
//
//  Created by SeokHyun on 10/27/24.
//

import UIKit

protocol DateTimeSettingCoordinatorDependencies: AnyObject {
  func makeDateTimeSettingViewController(
    actions: DateTimeSettingViewModelActions
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
  func start() {
    let actions = DateTimeSettingViewModelActions { [weak self] in
      self?.showHome()
    }
    let viewController = self.dependencies.makeDateTimeSettingViewController(actions: actions)
    self.navigationController?.pushViewController(viewController, animated: true)
  }
}

// MARK: - Private Helpers
private extension DateTimeSettingCoordinator {
  // todo 로그인 버튼 클릭하면 OnboardingCoordinator까지 제거한 뒤에 AppCoordinator에서 MainCoordinator를 실행해야 함
  func showHome() {
    self.finish()
  }
}
