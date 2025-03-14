//
//  DeleteCacheRepositoryMock.swift
//  FreshNoteTests
//
//  Created by SeokHyun on 3/13/25.
//

@testable import Fresh_Note_Dev
import Combine
import Foundation

final class DeleteCacheRepositoryMock: DeleteCacheRepository {
  private(set) var deleteCachesCallCount = 0
  
  var deleteCachesResult: AnyPublisher<[DocumentID], any Error>!
  
  func deleteCaches() -> AnyPublisher<[DocumentID], any Error> {
    self.deleteCachesCallCount += 1
    return self.deleteCachesResult
  }
} 