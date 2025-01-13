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
  
  private func makeDateTimeRepository() -> any DateTimeRepository {
    return DefaultDateTimeRepository(
      firebaseNetworkService: self.makeFirebasNetworkService(),
      dateTimeStorage: self.makeDateTimeStorage()
    )
  }
  
  private func makeFirebasNetworkService() -> any FirebaseNetworkService {
    return DefaultFirebaseNetworkService()
  }
  
  private func makeDateTimeStorage() -> any DateTimeStorage {
    return CoreDataDateTimeStorage(coreDataStorage: self.makeCoreDataStorage())
  }
  
  private func makeCoreDataStorage() -> any CoreDataStorage {
    return PersistentCoreDataStorage.shared
  }
}

// MARK: - AppCoordinatorDependencies
extension AppDIContainer: AppCoordinatorDependencies {
  func makeDateTimeSettingCoordinator(
    navigationController: UINavigationController
  ) -> DateTimeSettingCoordinator {
    return DateTimeSettingCoordinator(
      dependencies: self.makeOnboardingSceneDIContainer(),
      navigationController: navigationController
    )
  }
  
  func makeCheckDateTimeStateUseCase() -> any CheckDateTimeStateUseCase {
    return DefaultCheckDateTimeStateUseCase(dateTimeRepository: self.makeDateTimeRepository())
  }
  
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
