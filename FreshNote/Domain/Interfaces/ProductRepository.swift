//
//  ProductRepository.swift
//  FreshNote
//
//  Created by SeokHyun on 11/27/24.
//

import Combine
import Foundation

protocol ProductRepository {
  func saveProduct(product: Product) -> AnyPublisher<Void, any Error>
  func fetchProducts() -> AnyPublisher<[Product], any Error>
  func fetchProduct(productID: DocumentID) -> AnyPublisher<Product, any Error>
  func deleteProduct(didString: String) -> AnyPublisher<Void, any Error>
  func updateProduct(product: Product) -> AnyPublisher<Product, any Error>
  func fetchPinnedProducts() -> AnyPublisher<[Product], any Error>
  func fetchProduct(category: String) -> AnyPublisher<[Product], any Error>
  func fetchProduct(keyword: String) -> AnyPublisher<[Product], any Error>
  func isSavedProductInLocal() -> AnyPublisher<Bool, any Error>
}
