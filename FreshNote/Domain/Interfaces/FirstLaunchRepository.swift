//
//  FirstLaunchRepository.swift
//  FreshNote
//
//  Created by SeokHyun on 1/20/25.
//

import Combine
import Foundation

protocol FirstLaunchRepository {
  /// 최초 앱 실행 여부를 판별합니다.
  ///
  /// 최초 앱 실행이라면 true, 최초 앱 실행이 아니라면 false를 반환합니다.
  func isFirstLaunched() -> AnyPublisher<Bool, any Error>
}
