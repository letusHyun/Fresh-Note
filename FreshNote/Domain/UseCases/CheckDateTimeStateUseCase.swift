//
//  CheckDateTimeStateUseCase.swift
//  FreshNote
//
//  Created by SeokHyun on 12/20/24.
//

import Combine
import Foundation

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
