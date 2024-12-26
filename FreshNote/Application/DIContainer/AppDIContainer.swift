//
//  AppDIContainer.swift
//  FreshNote
//
//  Created by SeokHyun on 10/23/24.
//

import UIKit

final class AppDIContainer {
  private func makeMainSceneDIContainer() -> MainSceneDIContainer {
    return MainSceneDIContainer(dependencies: MainSceneDIContainer.Dependencies())
  }
  
  private func makeOnboardingSceneDIContainer() -> OnboardingSceneDIContainer {
    return OnboardingSceneDIContainer(dependencies: OnboardingSceneDIContainer.Dependencies())
  }
  
  private func makeSignInStateRepository() -> any SignInStateRepository {
    return DefaultSignInStateRepository(signInStateStorage: self.makeSignInStateStorage())
  }
  
  private func makeSignInStateStorage() -> any SignInStateStorage {
    return UserDefaultsSignInStateStorage()
  }
}

// MARK: - AppCoordinatorDependencies
extension AppDIContainer: AppCoordinatorDependencies {
   func makeSignInStateUseCase() -> any SignInStateUseCase {
    return DefaultSignInStateUseCase(signInStateRepository: self.makeSignInStateRepository())
  }
  
  func makeOnboardingCoordinator(navigationController: UINavigationController) -> OnboardingCoordinator {
    return OnboardingCoordinator(
      dependencies: self.makeOnboardingSceneDIContainer(),
      navigationController: navigationController
    )
  }
  
  func makeMainCoordinator(tabBarController: UITabBarController) -> MainCoordinator {
    return MainCoordinator(
      dependencies: self.makeMainSceneDIContainer(),
      tabBarController: tabBarController
    )
  }
}
