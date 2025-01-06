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
  }
  
  // MARK: - Helpers
  func start() {
    // TODO: - 나머지 탭들도 구성해야합니다.
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
    
    self.tabBarController?.tabBar.tintColor = UIColor(fnColor: .gray3)
    self.tabBarController?.tabBar.unselectedItemTintColor = UIColor(fnColor: .gray1)
    self.tabBarController?.viewControllers = [
      homeNavigationController,
      calendarNavigationController,
      pinNavigationController
    ]
    
    let homeCoordinator = self.dependencies.makeHomeCoordinator(
      navigationController: homeNavigationController
    )
    self.childCoordinators[homeCoordinator.identifier] = homeCoordinator
    homeCoordinator.start()
    
    let calendarCoordinator = self.dependencies.makeCalendarCoordinator(
      navigationController: calendarNavigationController
    )
    self.childCoordinators[calendarCoordinator.identifier] = calendarCoordinator
    calendarCoordinator.start()
    
    let pinCoordinator = self.dependencies.makePinCoordinator(
      navigationController: pinNavigationController
    )
    self.childCoordinators[pinCoordinator.identifier] = pinCoordinator
    pinCoordinator.start()
  }
  
  // MARK: - Private
  private func makeHomeNavigationController(
    title: String,
    tabBarImage: UIImage?,
    tag: Int
  ) -> UINavigationController {
    let navigationController = UINavigationController()
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
    let appearance = UINavigationBarAppearance()
    appearance.configureWithTransparentBackground()
    appearance.titleTextAttributes = [
      .font: UIFont.pretendard(size: 20, weight: ._700)
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
}
