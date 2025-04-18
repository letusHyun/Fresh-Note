//
//  OnboardingSceneDIContainer.swift
//  FreshNote
//
//  Created by SeokHyun on 10/23/24.
//

import UIKit

final class OnboardingSceneDIContainer {
  struct Dependencies {
    let apiDataTransferService: any DataTransferService
    let firebaseNetworkService: any FirebaseNetworkService
    let buildConfiguration: String
  }
  
  // MARK: - Properties
  private let dependencies: Dependencies
  
  // MARK: - LifeCycle
  init(dependencies: Dependencies) {
    self.dependencies = dependencies
  }
  
  
  // MARK: - Domain Layer
  func makeSaveDateTimeUseCase() -> any SaveDateTimeUseCase {
    return DefaultSaveDateTimeUseCase(
      dateTimeRepository: self.makeDateTimeRepository(),
      restorationStateRepository: self.makePushNotiRestorationStateRepository()
    )
  }
  
  func makeSignInUseCase() -> any SignInUseCase {
    return DefaultSignInUseCase(
      firebaseAuthRepository: self.makeFirebaseAuthRepository(),
      refreshTokenRepository: self.makeRefreshTokenRepository(),
      pushNotiRestorationStateRepository: self.makePushNotiRestorationStateRepository()
    )
  }
  
  func makeCheckInitialStateUseCase() -> any CheckInitialStateUseCase {
    return DefaultCheckInitialStateUseCase(
      firstLaunchRepository: self.makeFirstLaunchRepository(),
      refreshTokenRepository: self.makeRefreshTokenRepository(),
      authRepository: self.makeFirebaseAuthRepository(),
      dateTimeRepository: self.makeDateTimeRepository()
    )
  }
  
  func makeFetchDateTimeUseCase() -> any FetchDateTimeUseCase {
    return DefaultFetchDateTimeUseCase(dateTimeRepository: self.makeDateTimeRepository())
  }
  
  func makeUpdateDateTimeUseCase() -> any UpdateDateTimeUseCase {
    return DefaultUpdateTimeUseCase(dateTimeRepository: self.makeDateTimeRepository())
  }
  
  // MARK: - Data Layer
  func makeFirstLaunchRepository() -> any FirstLaunchRepository {
    DefaultFirstLaunchRepository(firstLaunchStorage: self.makeFirstLaunchStorage())
  }
  
  func makeFirstLaunchStorage() -> any FirstLaunchStorage {
    UserDefaultsFirstLaunchStorage()
  }
  
  func makePushNotiRestorationStateStorage() -> any PushNotiRestorationStateStorage {
    UserDefaultsPushNotiRestorationStateStorage()
  }
  func makePushNotiRestorationStateRepository() -> any PushNotiRestorationStateRepository {
    DefaultPushNotiRestorationStateRepository(restoreStateStorage: self.makePushNotiRestorationStateStorage())
  }
  
  func makeFirebaseAuthRepository() -> any FirebaseAuthRepository {
    return DefaultFirebaseAuthRepository(
      dateTimeCache: self.makeDateTimeStorage(),
      firebaseNetworkService: self.dependencies.firebaseNetworkService
    )
  }
  
  func makeImageRepository() -> any ImageRepository {
    return DefaultImageRepository(firebaseNetworkService: self.dependencies.firebaseNetworkService)
  }
  
  func makeCoreDataStorage() -> any CoreDataStorage {
    return PersistentCoreDataStorage.shared
  }
  
  func makeDateTimeRepository() -> any DateTimeRepository {
    return DefaultDateTimeRepository(
      firebaseNetworkService: self.dependencies.firebaseNetworkService,
      dateTimeStorage: self.makeDateTimeStorage()
    )
  }
  
  func makeDateTimeStorage() -> any DateTimeStorage {
    return CoreDataDateTimeStorage(coreDataStorage: self.makeCoreDataStorage())
  }
  
  func makeRefreshTokenRepository() -> any RefreshTokenRepository {
    return DefaultRefreshTokenRepository(
      dataTransferService: self.dependencies.apiDataTransferService,
      cache: self.makeRefreshTokenStorage(),
      buildConfiguration: self.dependencies.buildConfiguration
    )
  }
  
  func makeRefreshTokenStorage() -> any RefreshTokenStorage {
    return KeychainRefreshTokenStorage()
  }
  
  // MARK: - Presentation Layer
  func makeOnboardingViewModel(
    actions: OnboardingViewModelActions
  ) -> OnboardingViewModel {
    return DefaultOnboardingViewModel(
      actions: actions,
      signInUseCase: self.makeSignInUseCase(),
      checkInitialStateUseCase: self.makeCheckInitialStateUseCase()
    )
  }
  
  func makeDateTimeSettingViewModel(
    actions: DateTimeSettingViewModelActions,
    mode: DateTimeSettingViewModelMode
  ) -> DateTimeSettingViewModel {
    return DefaultDateTimeSettingViewModel(
      actions: actions,
      mode: mode,
      saveDateTimeUseCase: self.makeSaveDateTimeUseCase()
    )
  }
}

// MARK: - OnboardingCoordinatorDependencies
extension OnboardingSceneDIContainer: OnboardingCoordinatorDependencies {
  func makeDateTimeSettingCoordinator(navigationController: UINavigationController?) -> DateTimeSettingCoordinator {
    return DateTimeSettingCoordinator(
      dependencies: self,
      navigationController: navigationController
    )
  }
  
  func makeOnboardingViewController(
    actions: OnboardingViewModelActions
  ) -> OnboardingViewController {
    let viewModel = makeOnboardingViewModel(actions: actions)
    return OnboardingViewController(viewModel: viewModel)
  }
}

// MARK: - DateTimeSettingCoordinatorDependencies
extension OnboardingSceneDIContainer: DateTimeSettingCoordinatorDependencies {
  func makeDateTimeSettingViewController(
    actions: DateTimeSettingViewModelActions,
    mode: DateTimeSettingViewModelMode
  ) -> DateTimeSettingViewController {
    let viewModel = self.makeDateTimeSettingViewModel(actions: actions, mode: mode)
    return DateTimeSettingViewController(viewModel: viewModel, mode: mode)
  }
}
