//
//  OnboardingSceneDIContainer.swift
//  FreshNote
//
//  Created by SeokHyun on 10/23/24.
//

import UIKit

final class OnboardingSceneDIContainer {
  struct Dependencies {
//    let apiDataTransferService: DataTransferService
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
  
  func makeSignInStateUseCase() -> any SignInStateUseCase {
    return DefaultSignInStateUseCase(signInStateRepository: self.makeSignInStateRepository())
  }
  
  func makeSignInUseCase() -> any SignInUseCase {
    return DefaultSignInUseCase(appleSignInRepository: self.makeAppleSignInRepository())
  }
  
  func makeSaveUserProfileUseCase() -> any SaveUserProfileUseCase {
    return DefaultSaveUserProfileUseCase(
      userProfileRepository: self.makeUserProfileRepository(),
      imageRepository: self.makeImageRepository()
    )
  }
  
  func makeCheckDateTimeStateUseCase() -> any CheckDateTimeStateUseCase {
    return DefaultCheckDateTimeStateUseCase(dateTimeRepository: self.makeDateTimeRepository())
  }
  
  func makeFetchDateTimeUseCase() -> any FetchDateTimeUseCase {
    return DefaultFetchDateTimeUseCase(dateTimeRepository: self.makeDateTimeRepository())
  }
  
  func makeUpdateDateTimeUseCase() -> any UpdateDateTimeUseCase {
    return DefaultUpdateTimeUseCase(dateTimeRepository: self.makeDateTimeRepository())
  }
  
  // MARK: - Data Layer
  func makeImageRepository() -> any ImageRepository {
    return DefaultImageRepository(firebaseNetworkService: self.makeFirebaseNetworkService())
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
      firebaseNetworkService: self.makeFirebaseNetworkService()
    )
  }
  
  func makeAppleSignInRepository() -> any AppleSignInRepository {
    return DefaultAppleSignInRepository()
  }
  
  func makeSignInStateStorage() -> any SignInStateStorage {
    return UserDefaultsSignInStateStorage()
  }
  
  func makeSignInStateRepository() -> any SignInStateRepository {
    return DefaultSignInStateRepository(signInStateStorage: self.makeSignInStateStorage())
  }
  
  func makeFirebaseNetworkService() -> any FirebaseNetworkService {
    return DefaultFirebaseNetworkService()
  }
  
  func makeDateTimeRepository() -> any DateTimeRepository {
    return DefaultDateTimeRepository(
      firebaseNetworkService: self.makeFirebaseNetworkService(),
      dateTimeStorage: self.makeDateTimeStorage()
    )
  }
  
  func makeDateTimeStorage() -> any DateTimeStorage {
    return CoreDataDateTimeStorage(coreDataStorage: self.makeCoreDataStorage())
  }
  
  // MARK: - Presentation Layer
  func makeOnboardingViewModel(
    actions: OnboardingViewModelActions
  ) -> OnboardingViewModel {
    return DefaultOnboardingViewModel(
      actions: actions,
      signInUseCase: self.makeSignInUseCase(),
      signInStateUseCase: self.makeSignInStateUseCase(),
      checkDateTimeStateUseCase: self.makeCheckDateTimeStateUseCase(),
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
