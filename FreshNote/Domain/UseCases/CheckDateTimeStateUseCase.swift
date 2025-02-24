//
//  CheckDateTimeStateUseCase.swift
//  FreshNote
//
//  Created by SeokHyun on 12/20/24.
//

import Combine
import Foundation

/// DateTime 저장 여부를 판별하는 UseCase입니다.
protocol CheckDateTimeStateUseCase {
  func execute() -> AnyPublisher<Bool, any Error>
}

final class DefaultCheckDateTimeStateUseCase: CheckDateTimeStateUseCase {
  private let dateTimeRepository: any DateTimeRepository
  
  init(dateTimeRepository: any DateTimeRepository) {
    self.dateTimeRepository = dateTimeRepository
  }
  
  func execute() -> AnyPublisher<Bool, any Error> {
    return self.dateTimeRepository.isSavedDateTime()
  }
}
