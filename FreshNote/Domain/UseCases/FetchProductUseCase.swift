//
//  FetchProductUseCase.swift
//  FreshNote
//
//  Created by SeokHyun on 11/30/24.
//

import Combine
import Foundation

protocol FetchProductUseCase {
  func fetchProducts() -> AnyPublisher<[Product], any Error>
  func fetchProduct(productID: DocumentID) -> AnyPublisher<Product, any Error>
  func fetchPinnedProducts() -> AnyPublisher<[Product], any Error>
  func fetchProduct(category: ProductCategory) -> AnyPublisher<[Product], any Error>
  func fetchProduct(keyword: String) -> AnyPublisher<[Product], any Error>
}

final class DefaultFetchProductUseCase: FetchProductUseCase {
  private let productRepository: any ProductRepository
  
  init(
    productRepository: any ProductRepository
  ) {
    self.productRepository = productRepository
  }
  
  func fetchProducts() -> AnyPublisher<[Product], any Error> {
    return self.productRepository
      .fetchProducts()
  }
  
  func fetchProduct(productID: DocumentID) -> AnyPublisher<Product, any Error> {
    return self.productRepository
      .fetchProduct(productID: productID)
  }
  
  func fetchPinnedProducts() -> AnyPublisher<[Product], any Error> {
    return self.productRepository
      .fetchPinnedProducts()
  }
  
  func fetchProduct(category: ProductCategory) -> AnyPublisher<[Product], any Error> {
    return productRepository
      .fetchProduct(category: category.rawValue)
  }
  
  func fetchProduct(keyword: String) -> AnyPublisher<[Product], any Error> {
    return productRepository
      .fetchProduct(keyword: keyword)
  }
}
