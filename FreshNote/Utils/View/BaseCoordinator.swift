//
//  BaseCoordinator.swift
//  FreshNote
//
//  Created by SeokHyun on 10/27/24.
//

import UIKit

class BaseCoordinator: NSObject {
  // MARK: - Properties
  /// parentCoordiantor에서 childCoordinator를 생성하면 finishDelegate의 참조를 설정해주어야 합니다.
  weak var finishDelegate: CoordinatorFinishDelegate?
  private(set) var identifier = UUID()
  var childCoordinators: [UUID: BaseCoordinator] = [:]
  /// SceneDelegate의 window가 navigationController를 강한 참조하기 때문에 weak로 설정해야합니다.
  weak var navigationController: UINavigationController?
  
  // MARK: - LifeCycle
  init(navigationController: UINavigationController?) {
    self.navigationController = navigationController
  }
  
  /// 상위 코디네이터에게 현재 코디네이터를 삭제할 것을 요청합니다.
  /// 만약 상위 코디네이터에게 데이터를 전달해야 한다면, finishDelegate 및 finish를 직접 정의해야 합니다.
  func finish() {
    finishDelegate?.coordinatorDidFinish(self)
  }
}
