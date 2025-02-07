//
//  ProductStorage.swift
//  FreshNote
//
//  Created by SeokHyun on 12/12/24.
//

import Combine
import Foundation

protocol ProductStorage {
  func saveProducts(with products: [Product]) -> AnyPublisher<[Product], any Error>
  func saveProduct(with product: Product) -> AnyPublisher<Void, any Error>
  func updateProduct(with updatedProduct: Product) -> AnyPublisher<Product, any Error>
  func fetchProducts() -> AnyPublisher<[Product], any Error>
  func deleteProduct(uid: String) -> AnyPublisher<Void, any Error>
  /// 제품이 storage에 저장되어있는지 판별합니다.
  func fetchProduct(didString: String) -> AnyPublisher<Product, any Error>
  func fetchPinnedProducts() -> AnyPublisher<[Product], any Error>
  func fetchProduct(category: String) -> AnyPublisher<[Product], any Error>
  func fetchProduct(keyword: String) -> AnyPublisher<[Product], any Error>
  func deleteAll() -> AnyPublisher<Void, any Error>
}
