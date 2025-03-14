//
//  FirstLaunchRepositoryMock.swift
//  FreshNoteTests
//
//  Created by SeokHyun on 3/13/25.
//

@testable import Fresh_Note_Dev
import Combine
import Foundation

final class FirstLaunchRepositoryMock: FirstLaunchRepository {
  private(set) var isFirstLaunchedCallCount = 0
  
  var isFirstLaunchedResult: AnyPublisher<Bool, any Error>!
  
  func isFirstLaunched() -> AnyPublisher<Bool, any Error> {
    self.isFirstLaunchedCallCount += 1
    return self.isFirstLaunchedResult
  }
} 