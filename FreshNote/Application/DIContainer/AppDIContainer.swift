//
//  AppDIContainer.swift
//  FreshNote
//
//  Created by SeokHyun on 10/23/24.
//

import UIKit

final class AppDIContainer {
  lazy var appConfiguration = AppConfiguration()
  
  // MARK: - Network
  lazy var apiDataTransferService: any DataTransferService = {
    let config = APIDataNetworkConfig(
      baseURL: self.appConfiguration.baseURL
    )
    
    let apiDataNetwork = DefaultNetworkService(config: config)
    return DefaultDataTransferService(networkService: apiDataNetwork)
  }()
  
  lazy var firebaseNetworkService: any FirebaseNetworkService = {
    DefaultFirebaseNetworkService()
  }()
  
  // MARK: - Private
  private func makeMainSceneDIContainer() -> MainSceneDIContainer {
    return MainSceneDIContainer(
      dependencies: MainSceneDIContainer.Dependencies(
        apiDataTransferService: self.apiDataTransferService,
        firebaseNetworkService: self.firebaseNetworkService
      )
    )
  }
  
  private func makeOnboardingSceneDIContainer() -> OnboardingSceneDIContainer {
    let dependencies = OnboardingSceneDIContainer.Dependencies(
      apiDataTransferService: self.apiDataTransferService,
      firebaseNetworkService: self.firebaseNetworkService
    )
    
    return OnboardingSceneDIContainer(dependencies: dependencies)
  }
  
  private func makeDateTimeRepository() -> any DateTimeRepository {
    return DefaultDateTimeRepository(
      firebaseNetworkService: self.firebaseNetworkService,
      dateTimeStorage: self.makeDateTimeStorage()
    )
  }
  
  private func makeDateTimeStorage() -> any DateTimeStorage {
    return CoreDataDateTimeStorage(coreDataStorage: self.makeCoreDataStorage())
  }
  
  private func makeCoreDataStorage() -> any CoreDataStorage {
    return PersistentCoreDataStorage.shared
  }
  
  private func makeRefreshTokenRepository() -> any RefreshTokenRepository {
    return DefaultRefreshTokenRepository(
      dataTransferService: self.apiDataTransferService,
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
  
  func makeFirstLaunchRepository() -> any FirstLaunchRepository {
    return DefaultFirstLaunchRepository(firstLaunchStorage: self.makeFirstLaunchStorage())
  }
  
  func makeFirstLaunchStorage() -> any FirstLaunchStorage {
    return UserDefaultsFirstLaunchStorage()
  }
  
  func makeCheckInitialStateUseCase() -> any CheckInitialStateUseCase {
    return DefaultCheckInitialStateUseCase(
      firstLaunchRepository: self.makeFirstLaunchRepository(),
      refreshTokenRepository: self.makeRefreshTokenRepository(),
      authRepository: self.makeFirebaseAuthRepository(),
      dateTimeRepository: self.makeDateTimeRepository()
    )
  }
  
  func makeFirebaseAuthRepository() -> any FirebaseAuthRepository {
    return DefaultFirebaseAuthRepository(
      dateTimeCache: self.makeDateTimeStorage(),
      firebaseNetworkService: self.firebaseNetworkService
    )
  }
  
  func makeSaveNotiRestorationStateUseCase() -> any SaveNotiRestorationStateUseCase {
    return DefaultSaveNotiRestorationStateUseCase(
      pushNotiRestorationStateRepository: self.makePushNotiRestorationStateRepository()
    )
  }
  
  func makeSignOutUseCase() -> any SignOutUseCase {
    DefaultSignOutUseCase(
      firebaseAuthRepository: self.makeFirebaseAuthRepository(),
      pushNotiRestorationStateRepository: self.makePushNotiRestorationStateRepository()
    )
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
