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
  }
  
  // MARK: - Properties
  private let dependencies: Dependencies
  
  // MARK: - LifeCycle
  init(dependencies: Dependencies) {
    self.dependencies = dependencies
  }
  
  
  // MARK: - Domain Layer
  func makeSaveDateTimeUseCase() -> any SaveDateTimeUseCase {
    return DefaultSaveDateTimeUseCase(dateTimeRepository: self.makeDateTimeRepository())
  }
  
//  func makeSignInStateUseCase() -> any firebaseAuthRepository {
//    return DefaultSignInStateUseCase(signInStateRepository: self.makeSignInStateRepository())
//  }
  
  func makeSignInUseCase() -> any SignInUseCase {
    return DefaultSignInUseCase(
      firebaseAuthRepository: self.makeFirebaseAuthRepository(),
      refreshTokenRepository: self.makeRefreshTokenRepository()
    )
  }
  
  func makeSaveUserProfileUseCase() -> any SaveUserProfileUseCase {
    return DefaultSaveUserProfileUseCase(
      userProfileRepository: self.makeUserProfileRepository(),
      imageRepository: self.makeImageRepository()
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
  
//  func makeCheckDateTimeStateUseCase() -> any CheckDateTimeStateUseCase {
//    return DefaultCheckDateTimeStateUseCase(dateTimeRepository: self.makeDateTimeRepository())
//  }
  
  func makeFetchDateTimeUseCase() -> any FetchDateTimeUseCase {
    return DefaultFetchDateTimeUseCase(dateTimeRepository: self.makeDateTimeRepository())
  }
  
  func makeUpdateDateTimeUseCase() -> any UpdateDateTimeUseCase {
    return DefaultUpdateTimeUseCase(dateTimeRepository: self.makeDateTimeRepository())
  }
  
  // MARK: - Data Layer
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
  
  func makeUserProfileStorage() -> any UserProfileStorage {
    return CoreDataUserProfileStorage(coreDataStorage: self.makeCoreDataStorage())
  }
  
  func makeUserProfileRepository() -> any UserProfileRepository {
    return DefaultUserProfileRepository(
      userProfileStorage: self.makeUserProfileStorage(),
      firebaseNetworkService: self.dependencies.firebaseNetworkService
    )
  }
  
//  func makeSignInStateStorage() -> any SignInStateStorage {
//    return UserDefaultsSignInStateStorage()
//  }
//  
//  func makeSignInStateRepository() -> any SignInStateRepository {
//    return DefaultSignInStateRepository(signInStateStorage: self.makeSignInStateStorage())
//  }
  
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
      cache: self.makeRefreshTokenStorage()
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
      checkInitialStateUseCase: self.makeCheckInitialStateUseCase(),
      saveUserProfileUseCase: self.makeSaveUserProfileUseCase()
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
