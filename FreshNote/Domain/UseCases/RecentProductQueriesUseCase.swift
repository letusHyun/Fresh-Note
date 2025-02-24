//
//  RecentProductQueriesUseCase.swift
//  FreshNote
//
//  Created by SeokHyun on 12/10/24.
//

import Combine
import Foundation

protocol RecentProductQueriesUseCase {
  func fetchQueries() -> AnyPublisher<[ProductQuery], any Error>
  func saveQuery(keyword: String) -> AnyPublisher<ProductQuery, any Error>
  func deleteQuery(uuidString: String) -> AnyPublisher<Void, any Error>
  func deleteQueries() -> AnyPublisher<Void, any Error>
}

final class DefaultRecentProductQueriesUseCase: RecentProductQueriesUseCase {
  private let productQueriesRepository: any ProductQueriesRepository
  
  init(productQueriesRepository: any ProductQueriesRepository) {
    self.productQueriesRepository = productQueriesRepository
  }
  
  func fetchQueries() -> AnyPublisher<[ProductQuery], any Error> {
    self.productQueriesRepository.fetchQueries()
  }
  
  func saveQuery(keyword: String) -> AnyPublisher<ProductQuery, any Error> {
    let uuidString = UUID().uuidString
    let productQuery = ProductQuery(keyword: keyword, uuidString: uuidString)
    
    return self.productQueriesRepository.saveQuery(productQuery: productQuery)
  }
  
  func deleteQuery(uuidString: String) -> AnyPublisher<Void, any Error> {
    self.productQueriesRepository.deleteQuery(uuidString: uuidString)
  }
  
  func deleteQueries() -> AnyPublisher<Void, any Error> {
    self.productQueriesRepository.deleteQueries()
  }
}
