//
//  DefaultFirstLaunchRepository.swift
//  FreshNote
//
//  Created by SeokHyun on 1/20/25.
//

import Combine
import Foundation

final class DefaultFirstLaunchRepository: FirstLaunchRepository {
  private let firstLaunchStorage: any FirstLaunchStorage
  
  init(firstLaunchStorage: any FirstLaunchStorage) {
    self.firstLaunchStorage = firstLaunchStorage
  }
  
  func isFirstLaunched() -> AnyPublisher<Bool, any Error> {
    self.firstLaunchStorage
      .fetchFirstLaunchState()
      .flatMap { [weak self] isSavedState -> AnyPublisher<Bool, any Error> in
        guard let self else { return Empty().eraseToAnyPublisher() }
        
        return isSavedState
        ? self.handleExistingLaunchState(isSavedState: isSavedState)
        : self.handleFirstLaunchState(isSavedState: isSavedState)
      }
      .eraseToAnyPublisher()
  }
  
  // MARK: - Private
  private func handleExistingLaunchState(isSavedState: Bool) -> AnyPublisher<Bool, any Error> {
    return Just(!isSavedState)
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
  }
  
  /// 최초 실행 여부를 저장하고 true를 반환합니다.
  private func handleFirstLaunchState(isSavedState: Bool) -> AnyPublisher<Bool, any Error> {
    return self.firstLaunchStorage
      .saveFirstLaunchState()
      .map { !isSavedState }
      .eraseToAnyPublisher()
  }
}
