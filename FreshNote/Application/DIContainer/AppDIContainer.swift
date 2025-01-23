//
//  AppDIContainer.swift
//  FreshNote
//
//  Created by SeokHyun on 10/23/24.
//

import UIKit

final class AppDIContainer {
  // MARK: - Private
  private func makeMainSceneDIContainer() -> MainSceneDIContainer {
    return MainSceneDIContainer(
      dependencies: MainSceneDIContainer.Dependencies(
        apiDataTransferService: self.makeAPIDataTranferService()
      )
    )
  }
  
  private func makeOnboardingSceneDIContainer() -> OnboardingSceneDIContainer {
    let dependencies = OnboardingSceneDIContainer
      .Dependencies(apiDataTransferService: self.makeAPIDataTranferService())
    
    return OnboardingSceneDIContainer(dependencies: dependencies)
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
  
  private func makeAPIDataTranferService() -> any DataTransferService {
    let config = APIDataNetworkConfig(
      // TODO: - URLString을 Bundle에서 불러오기
      baseURL: URL(string:"https://us-central1-freshnote-6bee5.cloudfunctions.net")!
    )
    
    let apiDataNetwork = DefaultNetworkService(config: config)
    return DefaultDataTransferService(networkService: apiDataNetwork)
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
