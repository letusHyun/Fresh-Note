//
//  SaveDateTimeUseCase.swift
//  FreshNote
//
//  Created by SeokHyun on 11/13/24.
//

import Combine
import Foundation

protocol SaveDateTimeUseCase {
  func saveDateTime(date: Int, hour: Int, minute: Int) -> AnyPublisher<Void, any Error>
}

final class DefaultSaveDateTimeUseCase: SaveDateTimeUseCase {
  private let dateTimeRepository: any DateTimeRepository
  
  init(dateTimeRepository: any DateTimeRepository) {
    self.dateTimeRepository = dateTimeRepository
  }
  
  func saveDateTime(date: Int, hour: Int, minute: Int) -> AnyPublisher<Void, any Error> {
    return dateTimeRepository.saveDateTime(date: date, hour: hour, minute: minute)
  }
}
