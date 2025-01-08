//
//  ProductQueryStorage.swift
//  FreshNote
//
//  Created by SeokHyun on 12/10/24.
//

import Combine
import Foundation

protocol ProductQueryStorage {
  func saveQuery(productQuery: ProductQuery) -> AnyPublisher<ProductQuery, any Error>
  func fetchQueries() -> AnyPublisher<[ProductQuery], any Error>
  func deleteQuery(uuidString: String) -> AnyPublisher<Void, any Error>
  func deleteQueries() -> AnyPublisher<Void, any Error>
}
