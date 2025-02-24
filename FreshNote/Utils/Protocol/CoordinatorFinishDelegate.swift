//
//  CoordinatorFinishDelegate.swift
//  FreshNote
//
//  Created by SeokHyun on 10/29/24.
//

import Foundation

/// 하위 코디네이터가 존재한다면, 현재 코디네이터에서 해당 델리게이트를 준수해야합니다.
protocol CoordinatorFinishDelegate: AnyObject {
  /// children에서 하위 코디네이터를 제거합니다.
  func coordinatorDidFinish(_ childCoordinator: BaseCoordinator)
}
