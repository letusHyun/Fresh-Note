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
  private(set) var deleteUserWithAllDataCalled = false
  
  var deleteUserWithAllDataResult: AnyPublisher<Void, any Error>!
  
  func deleteUserWithAllData() -> AnyPublisher<Void, any Error> {
    self.deleteUserWithAllDataCalled = true
    return self.deleteUserWithAllDataResult
  }
}
