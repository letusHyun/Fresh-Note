//
//  FetchDateTimeUseCaseMock.swift
//  FreshNoteTests
//
//  Created by SeokHyun on 3/13/25.
//

@testable import Fresh_Note_Dev
import Combine
import Foundation

final class FetchDateTimeUseCaseMock: FetchDateTimeUseCase {
  private(set) var executeCallCount = 0
  
  var executeResult: AnyPublisher<DateTime, any Error>!
  
  func execute() -> AnyPublisher<DateTime, any Error> {
    self.executeCallCount += 1
    return self.executeResult
  }
} 