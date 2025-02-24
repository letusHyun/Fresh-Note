//
//  AppCoordinator.swift
//  FreshNote
//
//  Created by SeokHyun on 10/23/24.
//

import AuthenticationServices
import Combine
import UIKit

import FirebaseAuth

protocol AppCoordinatorDelegate: AnyObject {
  func setRootViewController(_ viewController: UIViewController)
}

protocol AppCoordinatorDependencies: AnyObject {
  func makeOnboardingCoordinator(navigationController: UINavigationController) -> OnboardingCoordinator
  func makeMainCoordinator(tabBarController: UITabBarController) -> MainCoordinator
  func makeDateTimeSettingCoordinator(navigationController: UINavigationController) -> DateTimeSettingCoordinator
}

enum AppCoordinatorScene {
  case home
  case onboarding
  case dateTimeSetting
}

final class AppCoordinator {
  // MARK: - Properties
  private let appDIContainer: AppDIContainer
  
  var childCoordinator: BaseCoordinator?
  
  weak var delegate: AppCoordinatorDelegate?
  private var subscriptions = Set<AnyCancellable>()
  private let checkInitialStateUseCase: any CheckInitialStateUseCase
  private let signOutUseCase: any SignOutUseCase
  private let saveNotiRestorationStateUseCase: any SaveNotiRestorationStateUseCase
  
  @Published private var error: (any Error)?
  
  // MARK: - LifeCycle
  init(appDIContainer: AppDIContainer) {
    self.appDIContainer = appDIContainer
    self.checkInitialStateUseCase = self.appDIContainer.makeCheckInitialStateUseCase()
    self.signOutUseCase = self.appDIContainer.makeSignOutUseCase()
    self.saveNotiRestorationStateUseCase = self.appDIContainer.makeSaveNotiRestorationStateUseCase()
  }
  
  func start() {
    self.coordinatorScenePublisher()
      .receive(on: DispatchQueue.main)
      .sink { [weak self] completion in
        guard case .failure(let error) = completion else { return }
        self?.error = error
      } receiveValue: { [weak self] scene in
        guard let self else { return }
        switch scene {
        case .home: self.startMainFlow()
        case .dateTimeSetting: self.startDateTimeSettingFlow()
        case .onboarding: self.startOnboardingFlow()
        }
      }
      .store(in: &self.subscriptions)
  }
}

// MARK: - Private
private extension AppCoordinator {
  private func coordinatorScenePublisher() -> AnyPublisher<AppCoordinatorScene, any Error> {
    // 최초 실행 상태에 따른 refreshToken 체크 Publisher 생성
    let refreshTokenPublisher: AnyPublisher<Bool, any Error> =
    self.checkInitialStateUseCase.checkFirstLaunchState()
      .flatMap { [weak self] isFirstLaunch -> AnyPublisher<Bool, any Error> in
        guard let self = self else {
          return Fail(error: CommonError.referenceError).eraseToAnyPublisher()
        }
        if isFirstLaunch {
          // 최초 로그인인 경우 강제 로그아웃 후 refreshToken 상태 체크
          return self.signOutUseCase.signOut()
            .flatMap { _ in self.checkInitialStateUseCase.checkRefreshTokenState() }
            .eraseToAnyPublisher()
        } else {
          // 최초 로그인이 아니라면 바로 refreshToken 상태 체크
          return self.checkInitialStateUseCase.checkRefreshTokenState()
        }
      }
      .eraseToAnyPublisher()
    
    // refreshToken 저장 여부 및 signOut 상태, 날짜 설정에 따른 Scene 결정 Publisher 생성
    return refreshTokenPublisher
      .flatMap { [weak self] isSavedRefreshToken -> AnyPublisher<AppCoordinatorScene, any Error> in
        guard let self = self else {
          return Fail(error: CommonError.referenceError).eraseToAnyPublisher()
        }
        guard isSavedRefreshToken else {
          // refreshToken이 저장되지 않았다면 로그인 화면으로 이동
          return Just(AppCoordinatorScene.onboarding)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
        }
        return self.checkInitialStateUseCase.checkSignOutState()
          .flatMap { [weak self] isSignedOut -> AnyPublisher<AppCoordinatorScene, any Error> in
            guard let self = self else {
              return Fail(error: CommonError.referenceError).eraseToAnyPublisher()
            }
            if isSignedOut {
              // 자동 로그인이 아니라면 로그인 화면으로 이동
              return Just(AppCoordinatorScene.onboarding)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
            } else {
              // 자동 로그인인 경우 알림 복원 상태 저장 후 날짜 설정 여부에 따라 화면 결정
              return self.saveNotiRestorationStateUseCase.execute(shouldRestore: false)
                .flatMap { _ in self.checkInitialStateUseCase.checkDateTimeSetting() }
                .flatMap { isSavedDateTime -> AnyPublisher<AppCoordinatorScene, any Error> in
                  let scene: AppCoordinatorScene = isSavedDateTime ? .home : .dateTimeSetting
                  return Just(scene)
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
            }
          }
          .eraseToAnyPublisher()
      }
      .eraseToAnyPublisher()
  }
  
  func startDateTimeSettingFlow() {
    let navigationController = UINavigationController()
    
    self.delegate?.setRootViewController(navigationController)
    let childCoordinator = self.appDIContainer.makeDateTimeSettingCoordinator(
      navigationController: navigationController
    )
    childCoordinator.finishDelegate = self
    self.childCoordinator = childCoordinator
    childCoordinator.start(mode: .start)
  }
  
  func startOnboardingFlow() {
    let navigationController = UINavigationController()
    navigationController.setupBarAppearance()
    
    self.delegate?.setRootViewController(navigationController)
    let childCoordinator = self.appDIContainer.makeOnboardingCoordinator(navigationController: navigationController)
    childCoordinator.finishDelegate = self
    self.childCoordinator = childCoordinator
    childCoordinator.start()
  }
  
  func startMainFlow() {
    let tabBarController = UITabBarController()
    
    self.delegate?.setRootViewController(tabBarController)
    let childCoordinator = self.appDIContainer.makeMainCoordinator(tabBarController: tabBarController)
    childCoordinator.finishDelegate = self
    self.childCoordinator = childCoordinator
    childCoordinator.start()
  }
}

// MARK: - CoordinatorFinishDelegate
extension AppCoordinator: CoordinatorFinishDelegate {
  func coordinatorDidFinish(_ childCoordinator: BaseCoordinator) {
    if childCoordinator is OnboardingCoordinator {
      self.startMainFlow()
    } else if childCoordinator is MainCoordinator {
      self.startOnboardingFlow()
    } else if childCoordinator is DateTimeSettingCoordinator {
      self.startMainFlow()
    }
  }
}
