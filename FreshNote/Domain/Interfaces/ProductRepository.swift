//
//  ProductRepository.swift
//  FreshNote
//
//  Created by SeokHyun on 11/27/24.
//

import Combine
import Foundation

protocol ProductRepository {
  /// save 및 update기능을 수행합니다.
  func saveProduct(product: Product) -> AnyPublisher<Void, any Error>
  func fetchProducts() -> AnyPublisher<[Product], any Error>
  func fetchProduct(productID: DocumentID) -> AnyPublisher<Product, any Error>
  func deleteProduct(didString: String) -> AnyPublisher<Void, any Error>
  func updateProduct(product: Product) -> AnyPublisher<Product, any Error>
}
