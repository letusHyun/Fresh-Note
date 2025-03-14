//
//  FirebaseDeletionRepositoryMock.swift
//  FreshNoteTests
//
//  Created by SeokHyun on 3/13/25.
//

@testable import Fresh_Note_Dev
import Combine
import Foundation

final class FirebaseDeletionRepositoryMock: FirebaseDeletionRepository {
  private(set) var deleteUserWithAllDataCallCount = 0
  
  var deleteUserWithAllDataResult: AnyPublisher<Void, any Error>!
  
  func deleteUserWithAllData() -> AnyPublisher<Void, any Error> {
    self.deleteUserWithAllDataCallCount += 1
    return self.deleteUserWithAllDataResult
  }
}
