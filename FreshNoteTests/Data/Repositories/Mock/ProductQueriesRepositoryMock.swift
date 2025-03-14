//
//  ProductQueriesRepositoryMock.swift
//  FreshNoteTests
//
//  Created by SeokHyun on 3/13/25.
//

@testable import Fresh_Note_Dev
import Combine
import Foundation

final class ProductQueriesRepositoryMock: ProductQueriesRepository {
  private(set) var fetchQueriesCallCount = 0
  private(set) var saveQueryCallCount = 0
  private(set) var deleteQueryCallCount = 0
  private(set) var deleteQueriesCallCount = 0
  
  var fetchQueriesResult: AnyPublisher<[ProductQuery], any Error>!
  var saveQueryResult: AnyPublisher<ProductQuery, any Error>!
  var deleteQueryResult: AnyPublisher<Void, any Error>!
  var deleteQueriesResult: AnyPublisher<Void, any Error>!
  
  func fetchQueries() -> AnyPublisher<[ProductQuery], any Error> {
    self.fetchQueriesCallCount += 1
    return self.fetchQueriesResult
  }
  
  func saveQuery(productQuery: ProductQuery) -> AnyPublisher<ProductQuery, any Error> {
    self.saveQueryCallCount += 1
    return self.saveQueryResult
  }
  
  func deleteQuery(uuidString: String) -> AnyPublisher<Void, any Error> {
    self.deleteQueryCallCount += 1
    return self.deleteQueryResult
  }
  
  func deleteQueries() -> AnyPublisher<Void, any Error> {
    self.deleteQueriesCallCount += 1
    return self.deleteQueriesResult
  }
} 