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
        apiDataTransferService: self.makeAPIDataTranferService(),
        firebaseNetworkService: self.makeFirebasNetworkService()
      )
    )
  }
  
  private func makeOnboardingSceneDIContainer() -> OnboardingSceneDIContainer {
    let dependencies = OnboardingSceneDIContainer.Dependencies(
      apiDataTransferService: self.makeAPIDataTranferService(),
      firebaseNetworkService: self.makeFirebasNetworkService()
    )
    
    return OnboardingSceneDIContainer(dependencies: dependencies)
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
  
  private func makeRefreshTokenRepository() -> any RefreshTokenRepository {
    return DefaultRefreshTokenRepository(
      dataTransferService: self.makeAPIDataTranferService(),
      cache: self.makeRefreshTokenStorage()
    )
  }
  
  private func makeRefreshTokenStorage() -> any RefreshTokenStorage {
    return KeychainRefreshTokenStorage()
  }
  
  private func makePushNotiRestorationStateRepository() -> any PushNotiRestorationStateRepository {
    return DefaultPushNotiRestorationStateRepository(restoreStateStorage: self.makePushNotiRestorationStateStorage())
  }
  
  private func makePushNotiRestorationStateStorage() -> any PushNotiRestorationStateStorage {
    return UserDefaultsPushNotiRestorationStateStorage()
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
  
  func makeCheckInitialStateUseCase() -> any CheckInitialStateUseCase {
    return DefaultCheckInitialStateUseCase(
      refreshTokenRepository: self.makeRefreshTokenRepository(),
      authRepository: self.makeFirebaseAuthRepository(),
      dateTimeRepository: self.makeDateTimeRepository(),
      pushNotiRestorationStateRepository: self.makePushNotiRestorationStateRepository()
    )
  }
  
  func makeFirebaseAuthRepository() -> any FirebaseAuthRepository {
    return DefaultFirebaseAuthRepository(
      dateTimeCache: self.makeDateTimeStorage(),
      firebaseNetworkService: self.makeFirebasNetworkService()
    )
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
