//
//  UpdateDateTimeUseCase.swift
//  FreshNote
//
//  Created by SeokHyun on 1/17/25.
//

import Combine
import Foundation

protocol UpdateDateTimeUseCase {
  func execute(dateTime: DateTime) -> AnyPublisher<Void, any Error>
}

final class DefaultUpdateTimeUseCase: UpdateDateTimeUseCase {
  private let dateTimeRepository: any DateTimeRepository
  
  init(dateTimeRepository: any DateTimeRepository) {
    self.dateTimeRepository = dateTimeRepository
  }
  
  func execute(dateTime: DateTime) -> AnyPublisher<Void, any Error> {
    self.dateTimeRepository.updateDateTime(dateTime: dateTime)
  }
}
