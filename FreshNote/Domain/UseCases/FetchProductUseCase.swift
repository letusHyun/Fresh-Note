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
}
