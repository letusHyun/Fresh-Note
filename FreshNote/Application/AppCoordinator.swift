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

final class AppCoordinator {
  // MARK: - Properties
  private let appDIContainer: AppDIContainer
  
  var childCoordinator: BaseCoordinator?
  
  weak var delegate: AppCoordinatorDelegate?
  private var subscriptions = Set<AnyCancellable>()
  private let checkInitialStateUseCase: any CheckInitialStateUseCase
  
  // MARK: - LifeCycle
  init(appDIContainer: AppDIContainer) {
    self.appDIContainer = appDIContainer
    self.checkInitialStateUseCase = self.appDIContainer.makeCheckInitialStateUseCase()
  }
  
  func start() {
    // restorationsState 저장
    self.checkInitialStateUseCase
      .saveInitRestorationState()
      .flatMap { [weak self] _ -> AnyPublisher<Bool, any Error> in
        guard let self else { return Fail(error: CommonError.referenceError).eraseToAnyPublisher() }
        // refresh token 존재 여부 확인
        return self.checkInitialStateUseCase
          .checkRefreshTokenState()
      }
      .receive(on: DispatchQueue.main)
      .flatMap { [weak self] hasRefreshToken -> AnyPublisher<Bool, any Error> in
        guard let self else { return Fail(error: CommonError.referenceError).eraseToAnyPublisher() }
        
        if !hasRefreshToken { // refresh token 존재하지 않으면
          self.startOnboardingFlow() // 로그인 화면 이동
          return Empty().eraseToAnyPublisher()
        }
        
        return self.checkInitialStateUseCase // refresh token 존재하면
          .checkSignOutState() // 로그아웃 상태 체크
          .setFailureType(to: Error.self)
          .eraseToAnyPublisher()
      }
      .receive(on: DispatchQueue.main)
      .flatMap { [weak self] isSignedOut -> AnyPublisher<Bool, any Error> in
        guard let self else { return Fail(error: CommonError.referenceError).eraseToAnyPublisher() }
        
        if isSignedOut { // 로그아웃 상태라면
          self.startOnboardingFlow() // 로그인 화면 이동
          return Empty().eraseToAnyPublisher()
        }
        
        return self.checkInitialStateUseCase // 로그아웃 상태가 아니라면
          .checkDateTimeSetting() // 날짜 설정 여부 확인
      }
      .receive(on: DispatchQueue.main)
      .sink { completion in
        guard case .failure(let error) = completion else { return }
        print("DEBUG: AppCoordinator의 Error: \(error)")
        
      } receiveValue: { [weak self] isSetDateTime in
        guard let self else { return }
        
        // 날짜 설정 여부에 따라 화면 이동
        isSetDateTime ? self.startMainFlow() : self.startDateTimeSettingFlow()
      }
      .store(in: &self.subscriptions)
  }
}

// MARK: - Private
private extension AppCoordinator {
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
