//
//  FetchDateTimeUseCase.swift
//  FreshNote
//
//  Created by SeokHyun on 1/13/25.
//

import Combine
import Foundation

protocol FetchDateTimeUseCase {
  func execute() -> AnyPublisher<DateTime, any Error>
}

final class DefaultFetchDateTimeUseCase: FetchDateTimeUseCase {
  private let dateTimeRepository: any DateTimeRepository
  
  init(dateTimeRepository: any DateTimeRepository) {
    self.dateTimeRepository = dateTimeRepository
  }
  
  func execute() -> AnyPublisher<DateTime, any Error> {
    self.dateTimeRepository.fetchDateTime()
  }
}
