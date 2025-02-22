//
//  SceneDelegate.swift
//  FreshNote
//
//  Created by SeokHyun on 10/19/24.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  // MARK: - Properties
  var window: UIWindow?
  private var appCoordinator: AppCoordinator?
  private let appDIContainer = AppDIContainer()
  
  // MARK: - LifeCycle
  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    guard let windowScene = (scene as? UIWindowScene) else { return }
    let window = UIWindow(windowScene: windowScene)
    self.window = window
    self.appCoordinator = AppCoordinator(appDIContainer: self.appDIContainer)
    self.appCoordinator?.delegate = self
    self.appCoordinator?.start()
    window.makeKeyAndVisible()
  }
}

// MARK: - AppCoordinatorDelegate
extension SceneDelegate: AppCoordinatorDelegate {
  func setRootViewController(_ viewController: UIViewController) {
    self.window?.rootViewController = viewController
  }
}
