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
  private let restorationStateRepository: any PushNotiRestorationStateRepository
  
  init(
    dateTimeRepository: any DateTimeRepository,
    restorationStateRepository: any PushNotiRestorationStateRepository
  ) {
    self.dateTimeRepository = dateTimeRepository
    self.restorationStateRepository = restorationStateRepository
  }
  
  func saveDateTime(date: Int, hour: Int, minute: Int) -> AnyPublisher<Void, any Error> {
    let dateTime = DateTime(date: date, hour: hour, minute: minute)
    
    return dateTimeRepository
      .saveDateTime(dateTime: dateTime)
      .flatMap { [weak self] _ -> AnyPublisher<Void, any Error> in
        guard let self else { return Fail(error: CommonError.referenceError).eraseToAnyPublisher() }
        
        /// restoration state 여부를 저장합니다.
        return self.restorationStateRepository
          .saveRestoreState(restorationState: PushNotiRestorationState(shouldRestore: false))
      }
      .eraseToAnyPublisher()
    
  }
}
