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
  func makeSignInStateUseCase() -> any SignInStateUseCase
}

final class AppCoordinator {
  // MARK: - Properties
  private let dependencies: any AppCoordinatorDependencies
  
  var childCoordinator: BaseCoordinator?
  
  weak var delegate: AppCoordinatorDelegate?
  
  private var signInStateUseCase: (any SignInStateUseCase)?
  
  private var subscriptions = Set<AnyCancellable>()
  
  // MARK: - LifeCycle
  init(dependencies: any AppCoordinatorDependencies) {
    self.dependencies = dependencies
  }
  
  func start() {
    let signInStateUseCase = self.dependencies.makeSignInStateUseCase()
    self.signInStateUseCase = signInStateUseCase
    
    signInStateUseCase.checkSignIn()
      .receive(on: DispatchQueue.main)
      .sink { completion in
        guard case .failure(let error) = completion else { return }
        // TODO: - 에러 핸들링하기
      } receiveValue: { [weak self] isSignedIn in
        isSignedIn ? self?.startMainFlow() : self?.startOnboardingFlow()
      }
      .store(in: &self.subscriptions)
  }
}

// MARK: - Private Helpers
private extension AppCoordinator {
  func startOnboardingFlow() {
    let navigatonController = UINavigationController()
    navigatonController.setupBarAppearance()
    
    
    self.delegate?.setRootViewController(navigatonController)
    let childCoordinator = self.dependencies.makeOnboardingCoordinator(navigationController: navigatonController)
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
    }
  }
}
