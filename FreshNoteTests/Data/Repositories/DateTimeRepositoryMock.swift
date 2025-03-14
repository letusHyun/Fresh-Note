//
//  DateTimeRepositoryMock.swift
//  FreshNoteTests
//
//  Created by SeokHyun on 3/13/25.
//

@testable import Fresh_Note_Dev
import Combine
import Foundation

final class DateTimeRepositoryMock: DateTimeRepository {
  private(set) var fetchDateTimeCallCount = 0
  private(set) var saveDateTimeCallCount = 0
  private(set) var isSavedDateTimeCallCount = 0
  private(set) var updateDateTimeCallCount = 0
  private(set) var deleteCachedDateTimeCallCount = 0
  
  var fetchDateTimeResult: AnyPublisher<DateTime, any Error>!
  var saveDateTimeResult: AnyPublisher<Void, any Error>!
  var isSavedDateTimeResult: AnyPublisher<Bool, any Error>!
  var updateDateTimeResult: AnyPublisher<Void, any Error>!
  var deleteCachedDateTimeResult: AnyPublisher<Void, any Error>!
  
  func fetchDateTime() -> AnyPublisher<DateTime, any Error> {
    self.fetchDateTimeCallCount += 1
    return self.fetchDateTimeResult
  }
  
  func saveDateTime(dateTime: DateTime) -> AnyPublisher<Void, any Error> {
    self.saveDateTimeCallCount += 1
    return self.saveDateTimeResult
  }
  
  func isSavedDateTime() -> AnyPublisher<Bool, any Error> {
    self.isSavedDateTimeCallCount += 1
    return self.isSavedDateTimeResult
  }
  
  func updateDateTime(dateTime: DateTime) -> AnyPublisher<Void, any Error> {
    self.updateDateTimeCallCount += 1
    return self.updateDateTimeResult
  }
  
  func deleteCachedDateTime() -> AnyPublisher<Void, any Error> {
    self.deleteCachedDateTimeCallCount += 1
    return self.deleteCachedDateTimeResult
  }
} 