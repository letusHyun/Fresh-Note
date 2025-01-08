//
//  DefaultProductQueriesRepository.swift
//  FreshNote
//
//  Created by SeokHyun on 12/10/24.
//

import Combine
import Foundation

final class DefaultProductQueriesRepository: ProductQueriesRepository {
  private let productQueryPersistentStorage: any ProductQueryStorage
  
  init(productQueryPersistentStorage: any ProductQueryStorage) {
    self.productQueryPersistentStorage = productQueryPersistentStorage
  }
  
  func fetchQueries() -> AnyPublisher<[ProductQuery], any Error> {
    self.productQueryPersistentStorage.fetchQueries()
  }
  
  func saveQuery(productQuery: ProductQuery) -> AnyPublisher<ProductQuery, any Error> {
    self.productQueryPersistentStorage.saveQuery(productQuery: productQuery)
  }
  
  func deleteQuery(uuidString: String) -> AnyPublisher<Void, any Error> {
    self.productQueryPersistentStorage.deleteQuery(uuidString: uuidString)
  }
  
  func deleteQueries() -> AnyPublisher<Void, any Error> {
    self.productQueryPersistentStorage.deleteQueries()
  }
}
