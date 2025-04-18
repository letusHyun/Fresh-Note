//
//  MainCoordiantor.swift
//  FreshNote
//
//  Created by SeokHyun on 10/27/24.
//

import UIKit

protocol MainCoordinatorDependencies: AnyObject {
  // todo: make각 탭Coordinator
  func makeHomeCoordinator(navigationController: UINavigationController) -> HomeCoordinator
  func makeCalendarCoordinator(navigationController: UINavigationController) -> CalendarCoordinator
  func makePinCoordinator(navigationController: UINavigationController) -> PinCoordinator
  func makeCategoryCoordinator(navigationController: UINavigationController) -> CategoryCoordinator
  func makeSettingCoordinator(navigationController: UINavigationController) -> SettingCoordinator
}

final class MainCoordinator: BaseCoordinator {
  // MARK: - Properties
  private let dependencies: any MainCoordinatorDependencies
  private weak var tabBarController: UITabBarController? // window.rootVC가 강한참조를 하기 때문에 weak 선언
  
  // MARK: - LifeCycle
  init(
    dependencies: any MainCoordinatorDependencies,
    tabBarController: UITabBarController
  ) {
    self.dependencies = dependencies
    // tabBarController는 SceneDelegate에서 생성해서 여기로 주입해주어야 할듯.
    // 이유는 window객체가 SceneDelegate에 있기 때문
    self.tabBarController = tabBarController
    super.init(navigationController: nil)
    
    self.configureTabBarAppearance()
  }
  
  // MARK: - Helpers
  func start() {
    self.configureTabBarControllerChildren()
  }
  
  // MARK: - Private
  private func configureTabBarAppearance() {
    let appearance = UITabBarAppearance()
    appearance.configureWithOpaqueBackground()
    appearance.backgroundColor = UIColor(fnColor: .realBack)
    appearance.shadowColor = nil
    self.tabBarController?.tabBar.standardAppearance = appearance
    self.tabBarController?.tabBar.scrollEdgeAppearance = appearance 
    
    if let tabBarLayer = self.tabBarController?.tabBar.layer {
      tabBarLayer.shadowColor = UIColor.gray.withAlphaComponent(0.3).cgColor
      
      tabBarLayer.shadowOffset = CGSize(width: 0, height: 0)
      tabBarLayer.shadowOpacity = 1.0
      tabBarLayer.shadowRadius = 12 / 2.0
    }
  }
  
  private func configureTabBarControllerChildren() {
    // tabBarController에 들어갈 window에서 알 필요가 없기 때문에 내비컨들은 여기서 만들어주는것이 적합함
    let homeNavigationController = self.makeHomeNavigationController(
      title: "홈",
      tabBarImage: UIImage(systemName: "house"),
      tag: 0
    )
    let calendarNavigationController = self.makeNavigationControllerWithTitle(
      title: "캘린더",
      tabBarImage: UIImage(systemName: "calendar"),
      tag: 1
    )
    let pinNavigationController = self.makeNavigationControllerWithTitle(
      title: "핀",
      tabBarImage: UIImage(systemName: "pin"),
      tag: 2
    )
    let categoryNavigationController = self.makeNavigationControllerWithTitle(
      title: "카테고리",
      tabBarImage: UIImage(systemName: "list.dash"),
      tag: 3
    )
    let settingNavigationController = self.makeNavigationControllerWithTitle(
      title: "마이",
      tabBarImage: UIImage(systemName: "person"),
      tag: 4
    )
    
    self.tabBarController?.tabBar.tintColor = UIColor(fnColor: .gray3)
    self.tabBarController?.tabBar.unselectedItemTintColor = UIColor(fnColor: .gray1)
    self.tabBarController?.viewControllers = [
      homeNavigationController,
      calendarNavigationController,
      pinNavigationController,
      categoryNavigationController,
      settingNavigationController
    ]
    
    let homeCoordinator = self.dependencies.makeHomeCoordinator(
      navigationController: homeNavigationController
    )
    self.childCoordinators[homeCoordinator.identifier] = homeCoordinator
    homeCoordinator.finishDelegate = self
    homeCoordinator.start()
    
    let calendarCoordinator = self.dependencies.makeCalendarCoordinator(
      navigationController: calendarNavigationController
    )
    self.childCoordinators[calendarCoordinator.identifier] = calendarCoordinator
    calendarCoordinator.finishDelegate = self
    calendarCoordinator.start()
    
    let pinCoordinator = self.dependencies.makePinCoordinator(
      navigationController: pinNavigationController
    )
    self.childCoordinators[pinCoordinator.identifier] = pinCoordinator
    pinCoordinator.finishDelegate = self
    pinCoordinator.start()
    
    let categoryCoordinator = self.dependencies.makeCategoryCoordinator(
      navigationController: categoryNavigationController
    )
    self.childCoordinators[categoryCoordinator.identifier] = categoryCoordinator
    categoryCoordinator.finishDelegate = self
    categoryCoordinator.start()
    
    let settingCoordinator = self.dependencies.makeSettingCoordinator(
      navigationController: settingNavigationController
    )
    self.childCoordinators[settingCoordinator.identifier] = settingCoordinator
    settingCoordinator.finishDelegate = self
    settingCoordinator.start()
  }
  
  private func makeHomeNavigationController(
    title: String,
    tabBarImage: UIImage?,
    tag: Int
  ) -> UINavigationController {
    let navigationController = UINavigationController()
    navigationController.navigationBar.tintColor = UIColor(fnColor: .gray3)
    navigationController.setupBarAppearance()
    
    let tabBarItem = UITabBarItem(
      title: title,
      image: tabBarImage,
      tag: tag
    )
    navigationController.tabBarItem = tabBarItem
    
    return navigationController
  }
  
  private func makeNavigationControllerWithTitle(
    title: String,
    tabBarImage: UIImage?,
    tag: Int
  ) -> UINavigationController {
    let navigationController = UINavigationController()
    navigationController.navigationBar.tintColor = UIColor(fnColor: .gray3)
    let appearance = UINavigationBarAppearance()
    appearance.configureWithTransparentBackground()
    appearance.titleTextAttributes = [
      .font: UIFont.pretendard(size: 18, weight: ._700)
    ]
    navigationController.navigationBar.standardAppearance = appearance
    navigationController.navigationBar.scrollEdgeAppearance = appearance
    navigationController.navigationBar.scrollEdgeAppearance = appearance
    
    let tabBarItem = UITabBarItem(
      title: title,
      image: tabBarImage,
      tag: tag
    )
    navigationController.tabBarItem = tabBarItem
    
    return navigationController
  }
  
  private func clearAllNavigationStacks() {
    self.tabBarController?.viewControllers?.forEach { viewController in
      if let navigationController = viewController as? UINavigationController {
        navigationController.viewControllers = []
      }
    }
  }
}

// MARK: - CoordinatorFinishDelegate
extension MainCoordinator: CoordinatorFinishDelegate {
  func coordinatorDidFinish(_ childCoordinator: BaseCoordinator) {
    self.clearAllNavigationStacks() // navigation stack 제거
    // child coordinator 재귀적으로 제거
    self.childCoordinators.values.forEach { childCoordinator in
      childCoordinator.finishAllChildren()
    }
    self.finish()
  }
}
