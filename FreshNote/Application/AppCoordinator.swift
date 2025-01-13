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
  ///
  func setRootViewController(_ viewController: UIViewController)
}

protocol AppCoordinatorDependencies: AnyObject {
  func makeOnboardingCoordinator(navigationController: UINavigationController) -> OnboardingCoordinator
  func makeMainCoordinator(tabBarController: UITabBarController) -> MainCoordinator
  func makeSignInStateUseCase() -> any SignInStateUseCase
  func makeCheckDateTimeStateUseCase() -> any CheckDateTimeStateUseCase
  func makeDateTimeSettingCoordinator(navigationController: UINavigationController) -> DateTimeSettingCoordinator
}

final class AppCoordinator {
  // MARK: - Properties
  private let dependencies: any AppCoordinatorDependencies
  
  var childCoordinator: BaseCoordinator?
  
  weak var delegate: AppCoordinatorDelegate?
  
  private var signInStateUseCase: (any SignInStateUseCase)?
  private var checkDateTimeStateUseCase: (any CheckDateTimeStateUseCase)?
  
  private var subscriptions = Set<AnyCancellable>()
  
  // MARK: - LifeCycle
  init(dependencies: any AppCoordinatorDependencies) {
    self.dependencies = dependencies
  }
  
  func start() {
    let signInStateUseCase = self.dependencies.makeSignInStateUseCase()
    let checkDateTimeStateUseCase = self.dependencies.makeCheckDateTimeStateUseCase()
    
    self.signInStateUseCase = signInStateUseCase
    self.checkDateTimeStateUseCase = checkDateTimeStateUseCase
    
    Publishers.CombineLatest(
      signInStateUseCase.checkSignIn(),
      checkDateTimeStateUseCase.execute()
    )
    .receive(on: DispatchQueue.main)
    .sink { completion in
      guard case .failure(let error) = completion else { return }
      print("DEBUG: error -> \(error)")
    } receiveValue: { [weak self] (isSignedIn, hasDateTime) in
      if isSignedIn {
        if hasDateTime {
          self?.startMainFlow()
        } else {
          self?.startDateTimeSettingFlow()
        }
      } else {
        self?.startOnboardingFlow()
      }
    }
    .store(in: &self.subscriptions)
  }
}

// MARK: - Private Helpers
private extension AppCoordinator {
  func startDateTimeSettingFlow() {
    let navigationController = UINavigationController()
    
    self.delegate?.setRootViewController(navigationController)
    let childCoordinator = self.dependencies.makeDateTimeSettingCoordinator(
      navigationController: navigationController
    )
    childCoordinator.finishDelegate = self
    self.childCoordinator = childCoordinator
    childCoordinator.start()
  }
  
  func startOnboardingFlow() {
    let navigationController = UINavigationController()
    navigationController.setupBarAppearance()
    
    self.delegate?.setRootViewController(navigationController)
    let childCoordinator = self.dependencies.makeOnboardingCoordinator(navigationController: navigationController)
    childCoordinator.finishDelegate = self
    self.childCoordinator = childCoordinator
    childCoordinator.start()
  }
  
  func startMainFlow() {
    let tabBarController = UITabBarController()
    
    self.delegate?.setRootViewController(tabBarController)
    let childCoordinator = dependencies.makeMainCoordinator(tabBarController: tabBarController)
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
